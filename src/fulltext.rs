//! Full-text search functionality using Tantivy
//! 
//! This module provides full-text search capabilities using the Tantivy search engine.
//! It integrates with our existing embedding system to provide hybrid search functionality.

use tantivy::{
    collector::TopDocs,
    doc,
    query::QueryParser,
    schema::{Field, IndexRecordOption, Schema, SchemaBuilder, TextFieldIndexing, TextOptions, STORED, STRING},
    Index, IndexReader, IndexWriter, Term, Document,
};
use std::path::Path;
use std::sync::Arc;
use tokio::sync::RwLock;
use uuid::Uuid;
use chrono::{DateTime, Utc};
use serde_json::Value;

use crate::error::ParagonicResult;

/// Document structure for full-text search
#[derive(Debug, Clone)]
pub struct SearchDocument {
    pub id: Uuid,
    pub content_type: String,
    pub content_id: Uuid,
    pub content_text: String,
    pub title: Option<String>,
    pub metadata: Option<Value>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Search result from full-text search
#[derive(Debug, Clone)]
pub struct FullTextSearchResult {
    pub document: SearchDocument,
    pub score: f32,
}

/// Full-text search engine using Tantivy
pub struct FullTextSearchEngine {
    index: Index,
    reader: IndexReader,
    writer: Arc<RwLock<IndexWriter>>,
    schema: Schema,
    id_field: Field,
    content_type_field: Field,
    content_id_field: Field,
    content_text_field: Field,
    title_field: Field,
    metadata_field: Field,
    created_at_field: Field,
    updated_at_field: Field,
}

impl FullTextSearchEngine {
    /// Create a new full-text search engine
    pub fn new(index_path: &Path) -> ParagonicResult<Self> {
        // Create schema
        let mut schema_builder = SchemaBuilder::new();
        
        // Define fields
        let id_field = schema_builder.add_text_field("id", STRING | STORED);
        let content_type_field = schema_builder.add_text_field("content_type", STRING | STORED);
        let content_id_field = schema_builder.add_text_field("content_id", STRING | STORED);
        
        // Content text field with full-text indexing
        let text_options = TextOptions::default()
            .set_indexing_options(
                TextFieldIndexing::default()
                    .set_tokenizer("default")
                    .set_index_option(IndexRecordOption::WithFreqsAndPositions)
            )
            .set_stored();
        let content_text_field = schema_builder.add_text_field("content_text", text_options);
        
        // Title field with full-text indexing
        let title_options = TextOptions::default()
            .set_indexing_options(
                TextFieldIndexing::default()
                    .set_tokenizer("default")
                    .set_index_option(IndexRecordOption::WithFreqsAndPositions)
            )
            .set_stored();
        let title_field = schema_builder.add_text_field("title", title_options);
        
        let metadata_field = schema_builder.add_text_field("metadata", STORED);
        let created_at_field = schema_builder.add_text_field("created_at", STRING | STORED);
        let updated_at_field = schema_builder.add_text_field("updated_at", STRING | STORED);
        
        let schema = schema_builder.build();
        
        // Create or open index
        let index = if index_path.exists() {
            Index::open_in_dir(index_path)?
        } else {
            std::fs::create_dir_all(index_path)?;
            Index::create_in_dir(index_path, schema.clone())?
        };
        
        // Create reader and writer
        let reader = index.reader()?;
        let writer = Arc::new(RwLock::new(index.writer(50_000_000)?)); // 50MB buffer
        
        Ok(Self {
            index,
            reader,
            writer,
            schema,
            id_field,
            content_type_field,
            content_id_field,
            content_text_field,
            title_field,
            metadata_field,
            created_at_field,
            updated_at_field,
        })
    }
    
    /// Add a document to the search index
    pub async fn add_document(&self, document: SearchDocument) -> ParagonicResult<()> {
        let mut writer = self.writer.write().await;
        
        let doc = doc!(
            self.id_field => document.id.to_string(),
            self.content_type_field => document.content_type.clone(),
            self.content_id_field => document.content_id.to_string(),
            self.content_text_field => document.content_text.clone(),
            self.title_field => document.title.clone().unwrap_or_default(),
            self.metadata_field => document.metadata.as_ref().map(|v| v.to_string()).unwrap_or_default(),
            self.created_at_field => document.created_at.to_rfc3339(),
            self.updated_at_field => document.updated_at.to_rfc3339(),
        );
        
        writer.add_document(doc)?;
        writer.commit()?;
        
        Ok(())
    }
    
    /// Remove a document from the search index
    pub async fn remove_document(&self, document_id: Uuid) -> ParagonicResult<()> {
        let mut writer = self.writer.write().await;
        
        let term = Term::from_field_text(self.id_field, &document_id.to_string());
        writer.delete_term(term);
        writer.commit()?;
        
        Ok(())
    }
    
    /// Search for documents using full-text search
    pub async fn search(
        &self,
        query: &str,
        content_type: Option<&str>,
        limit: usize,
    ) -> ParagonicResult<Vec<FullTextSearchResult>> {
        let searcher = self.reader.searcher();
        
        // Create query parser
        let query_parser = QueryParser::for_index(&self.index, vec![
            self.content_text_field,
            self.title_field,
        ]);
        
        // Parse the query
        let parsed_query = query_parser.parse_query(query)?;
        
        // Execute search
        let top_docs: Vec<(f32, tantivy::DocAddress)> = searcher.search(&parsed_query, &TopDocs::with_limit(limit))?;
        
        // Convert results
        let mut results = Vec::new();
        for (score, doc_address) in top_docs {
            let doc = searcher.doc(doc_address)?;
            
            let document = SearchDocument {
                id: Uuid::parse_str(&doc.get_first(self.id_field).unwrap().as_text().unwrap())?,
                content_type: doc.get_first(self.content_type_field).unwrap().as_text().unwrap().to_string(),
                content_id: Uuid::parse_str(&doc.get_first(self.content_id_field).unwrap().as_text().unwrap())?,
                content_text: doc.get_first(self.content_text_field).unwrap().as_text().unwrap().to_string(),
                title: Some(doc.get_first(self.title_field).unwrap().as_text().unwrap().to_string()),
                metadata: serde_json::from_str(&doc.get_first(self.metadata_field).unwrap().as_text().unwrap()).ok(),
                created_at: DateTime::parse_from_rfc3339(&doc.get_first(self.created_at_field).unwrap().as_text().unwrap())?.with_timezone(&Utc),
                updated_at: DateTime::parse_from_rfc3339(&doc.get_first(self.updated_at_field).unwrap().as_text().unwrap())?.with_timezone(&Utc),
            };
            
            // Apply content type filter if specified
            if let Some(target_type) = content_type {
                if document.content_type != target_type {
                    continue;
                }
            }
            
            results.push(FullTextSearchResult {
                document,
                score,
            });
        }
        
        Ok(results)
    }
    
    /// Get total number of documents in the index
    pub fn document_count(&self) -> ParagonicResult<u64> {
        let searcher = self.reader.searcher();
        Ok(searcher.num_docs())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;
    
    #[tokio::test]
    async fn test_fulltext_search_engine_creation() {
        let temp_dir = tempdir().unwrap();
        let engine = FullTextSearchEngine::new(temp_dir.path());
        assert!(engine.is_ok());
    }
    
    #[tokio::test]
    async fn test_add_and_search_document() {
        let temp_dir = tempdir().unwrap();
        let engine = FullTextSearchEngine::new(temp_dir.path()).unwrap();
        
        // Add a test document
        let document = SearchDocument {
            id: Uuid::new_v4(),
            content_type: "project".to_string(),
            content_id: Uuid::new_v4(),
            content_text: "This is a test project about machine learning and artificial intelligence".to_string(),
            title: Some("Test ML Project".to_string()),
            metadata: Some(serde_json::json!({"tags": ["ml", "ai"]})),
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };
        
        engine.add_document(document.clone()).await.unwrap();
        
        // Search for the document
        let results = engine.search("machine learning", None, 10).await.unwrap();
        assert!(!results.is_empty());
        assert_eq!(results[0].document.id, document.id);
        
        // Test content type filtering
        let results = engine.search("machine learning", Some("project"), 10).await.unwrap();
        assert!(!results.is_empty());
        assert_eq!(results[0].document.content_type, "project");
        
        // Test with non-matching content type
        let results = engine.search("machine learning", Some("task"), 10).await.unwrap();
        assert!(results.is_empty());
    }
    
    #[tokio::test]
    async fn test_remove_document() {
        let temp_dir = tempdir().unwrap();
        let engine = FullTextSearchEngine::new(temp_dir.path()).unwrap();
        
        // Add a test document
        let document = SearchDocument {
            id: Uuid::new_v4(),
            content_type: "project".to_string(),
            content_id: Uuid::new_v4(),
            content_text: "This is a test project".to_string(),
            title: Some("Test Project".to_string()),
            metadata: None,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };
        
        engine.add_document(document.clone()).await.unwrap();
        
        // Verify document exists
        let results = engine.search("test", None, 10).await.unwrap();
        assert!(!results.is_empty());
        
        // Remove document
        engine.remove_document(document.id).await.unwrap();
        
        // Verify document is removed
        let results = engine.search("test", None, 10).await.unwrap();
        assert!(results.is_empty());
    }
} 