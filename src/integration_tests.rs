#[cfg(test)]
mod integration_tests {
    use super::*;
    use crate::iragl::{
        IraglSearchRequest, IraglSearchResponse, DifferentialGeometryOptimizationRequest,
        OptimizationResult, CreateContentAssociationRequest, ContentAssociationResponse
    };
    use crate::http_server::McpHttpServer;
    use crate::ollama::OllamaClient;
    use crate::ollama::OllamaConfig;
    use serde_json::json;
    use uuid::Uuid;
    use std::sync::Arc;

    /// Test complete knowledge stream workflow from ingestion to search
    #[tokio::test(flavor = "multi_thread")]
    async fn test_complete_knowledge_stream_workflow() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = McpHttpServer::new(client);
        
        // Step 1: Ingest knowledge stream
        let ingest_params = Some(json!({
            "content_type": "document",
            "content_text": "Machine learning optimization using differential geometry approaches for knowledge representation and retrieval.",
            "source_entity_type": "project",
            "source_entity_id": "550e8400-e29b-41d4-a716-446655440000",
            "metadata": {
                "author": "AI Research Team",
                "version": "1.0",
                "tags": ["machine-learning", "optimization", "differential-geometry"]
            },
            "embedding_model": "nomic-embed-text"
        }));
        
        let ingest_result = server.handle_ingest_knowledge_stream(&server, &ingest_params).await;
        assert!(ingest_result.is_ok(), "Knowledge stream ingestion should succeed");
        
        let ingest_response = ingest_result.unwrap();
        let content_id = ingest_response["id"].as_str().unwrap();
        
        // Step 2: Create content association
        let association_params = Some(json!({
            "content_id": content_id,
            "associated_content_id": "550e8400-e29b-41d4-a716-446655440001",
            "association_type": "related",
            "association_strength": 0.85,
            "metadata": {
                "relationship": "complements",
                "confidence": 0.92
            }
        }));
        
        let association_result = server.handle_content_association(&server, &association_params).await;
        assert!(association_result.is_ok(), "Content association should succeed");
        
        // Step 3: Perform IRAGL search
        let search_params = Some(json!({
            "query": "machine learning optimization differential geometry",
            "max_results": 10,
            "include_associations": true,
            "filter_optimized_only": false,
            "query_context": {
                "user_id": "user123",
                "project_id": "project456"
            }
        }));
        
        let search_result = server.handle_iragl_search(&server, &search_params).await;
        assert!(search_result.is_ok(), "IRAGL search should succeed");
        
        let search_response = search_result.unwrap();
        assert!(search_response["results"].as_array().unwrap().len() > 0, "Should return search results");
        
        // Step 4: Perform hybrid search
        let hybrid_params = Some(json!({
            "query": "optimization algorithms",
            "max_results": 5,
            "semantic_weight": 0.7,
            "keyword_weight": 0.3,
            "include_metadata": true
        }));
        
        let hybrid_result = server.handle_hybrid_search(&server, &hybrid_params).await;
        assert!(hybrid_result.is_ok(), "Hybrid search should succeed");
        
        let hybrid_response = hybrid_result.unwrap();
        assert!(hybrid_response["results"].as_array().unwrap().len() > 0, "Should return hybrid results");
        
        // Step 5: Optimize knowledge base
        let optimize_params = Some(json!({
            "strategy": "incremental",
            "max_iterations": 5,
            "convergence_threshold": 0.01,
            "enable_parallel_processing": true
        }));
        
        let optimize_result = server.handle_optimize_knowledge_base(&server, &optimize_params).await;
        assert!(optimize_result.is_ok(), "Knowledge base optimization should succeed");
        
        // Step 6: Check optimization status
        let status_params = Some(json!({
            "optimization_id": optimize_result.unwrap()["optimization_id"].as_str().unwrap()
        }));
        
        let status_result = server.handle_optimization_status(&server, &status_params).await;
        assert!(status_result.is_ok(), "Optimization status check should succeed");
        
        // Step 7: Get optimization history
        let history_params = Some(json!({
            "limit": 10,
            "include_details": true
        }));
        
        let history_result = server.handle_optimization_history(&server, &history_params).await;
        assert!(history_result.is_ok(), "Optimization history should succeed");
    }

    /// Test search and retrieval system with multiple content types
    #[tokio::test(flavor = "multi_thread")]
    async fn test_search_and_retrieval_system() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = McpHttpServer::new(client);
        
        // Ingest multiple content types
        let content_items = vec![
            json!({
                "content_type": "document",
                "content_text": "Technical specification for the IRAGL knowledge management system.",
                "source_entity_type": "project",
                "source_entity_id": "550e8400-e29b-41d4-a716-446655440000",
                "metadata": {"category": "technical", "priority": "high"}
            }),
            json!({
                "content_type": "code_snippet",
                "content_text": "def perform_iragl_search(query):\n    return search_knowledge_base(query)",
                "source_entity_type": "file",
                "source_entity_id": "550e8400-e29b-41d4-a716-446655440001",
                "metadata": {"language": "python", "function": "search"}
            }),
            json!({
                "content_type": "meeting_notes",
                "content_text": "Discussion about implementing differential geometry optimization for knowledge representation.",
                "source_entity_type": "meeting",
                "source_entity_id": "550e8400-e29b-41d4-a716-446655440002",
                "metadata": {"participants": ["Alice", "Bob"], "date": "2024-01-15"}
            })
        ];
        
        // Ingest all content items
        for content in content_items {
            let ingest_params = Some(content);
            let result = server.handle_ingest_knowledge_stream(&server, &ingest_params).await;
            assert!(result.is_ok(), "Content ingestion should succeed");
        }
        
        // Test semantic search
        let semantic_params = Some(json!({
            "query": "IRAGL knowledge management system",
            "max_results": 5,
            "include_associations": false
        }));
        
        let semantic_result = server.handle_iragl_search(&server, &semantic_params).await;
        assert!(semantic_result.is_ok(), "Semantic search should succeed");
        
        let semantic_response = semantic_result.unwrap();
        assert!(semantic_response["results"].as_array().unwrap().len() > 0, "Should return semantic results");
        
        // Test hybrid search with content type filtering
        let hybrid_params = Some(json!({
            "query": "optimization implementation",
            "max_results": 10,
            "semantic_weight": 0.6,
            "keyword_weight": 0.4,
            "filter_by_content_type": ["document", "code_snippet"],
            "include_metadata": true
        }));
        
        let hybrid_result = server.handle_hybrid_search(&server, &hybrid_params).await;
        assert!(hybrid_result.is_ok(), "Hybrid search should succeed");
        
        let hybrid_response = hybrid_result.unwrap();
        let results = hybrid_response["results"].as_array().unwrap();
        assert!(results.len() > 0, "Should return hybrid results");
        
        // Note: Content type filtering is not yet implemented in the underlying IRAGL search
        // The filter_by_content_type parameter is parsed but not applied to results
        // TODO: Implement content type filtering in perform_iragl_search
    }

    /// Test optimization pipeline with multiple strategies
    #[tokio::test(flavor = "multi_thread")]
    async fn test_optimization_pipeline() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = McpHttpServer::new(client);
        
        // Ingest test content for optimization
        let ingest_params = Some(json!({
            "content_type": "document",
            "content_text": "Comprehensive guide to machine learning optimization techniques including gradient descent, genetic algorithms, and differential geometry approaches.",
            "source_entity_type": "project",
            "source_entity_id": "550e8400-e29b-41d4-a716-446655440000",
            "metadata": {"complexity": "high", "topics": ["ml", "optimization"]}
        }));
        
        let ingest_result = server.handle_ingest_knowledge_stream(&server, &ingest_params).await;
        assert!(ingest_result.is_ok(), "Content ingestion should succeed");
        
        // Test incremental optimization
        let incremental_params = Some(json!({
            "strategy": "incremental",
            "max_iterations": 3,
            "convergence_threshold": 0.05
        }));
        
        let incremental_result = server.handle_optimize_knowledge_base(&server, &incremental_params).await;
        assert!(incremental_result.is_ok(), "Incremental optimization should succeed");
        
        let incremental_response = incremental_result.unwrap();
        let incremental_id = incremental_response["optimization_id"].as_str().unwrap();
        
        // Check incremental optimization status
        let status_params = Some(json!({
            "optimization_id": incremental_id
        }));
        
        let status_result = server.handle_optimization_status(&server, &status_params).await;
        assert!(status_result.is_ok(), "Status check should succeed");
        
        let status_response = status_result.unwrap();
        assert_eq!(status_response["status"].as_str().unwrap(), "completed", "Optimization should be successful");
        
        // Test batch optimization
        let batch_params = Some(json!({
            "strategy": "batch",
            "max_iterations": 2,
            "convergence_threshold": 0.1
        }));
        
        let batch_result = server.handle_optimize_knowledge_base(&server, &batch_params).await;
        assert!(batch_result.is_ok(), "Batch optimization should succeed");
        
        // Get optimization history
        let history_params = Some(json!({
            "limit": 5,
            "include_metadata": true
        }));
        
        let history_result = server.handle_optimization_history(&server, &history_params).await;
        assert!(history_result.is_ok(), "History retrieval should succeed");
        
        let history_response = history_result.unwrap();
        let optimizations = history_response["optimizations"].as_array().unwrap();
        assert!(optimizations.len() >= 2, "Should have at least 2 optimization records");
        
        // Verify optimization types
        let optimization_types: Vec<&str> = optimizations
            .iter()
            .map(|opt| opt["optimization_type"].as_str().unwrap())
            .collect();
        
        assert!(optimization_types.contains(&"differential_geometry"), "Should include differential geometry optimization");
        assert!(optimization_types.contains(&"embedding_update"), "Should include embedding update optimization");
    }

    /// Test system resilience and error recovery
    #[tokio::test(flavor = "multi_thread")]
    async fn test_system_resilience_and_recovery() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = McpHttpServer::new(client);
        
        // Test handling of invalid parameters
        let invalid_search_params = Some(json!({
            "query": "", // Empty query should fail
            "max_results": 10
        }));
        
        let invalid_search_result = server.handle_iragl_search(&server, &invalid_search_params).await;
        assert!(invalid_search_result.is_err(), "Empty query should return error");
        
        // Test handling of invalid optimization parameters
        let invalid_optimize_params = Some(json!({
            "strategy": "invalid_strategy",
            "max_iterations": 0 // Invalid iterations
        }));
        
        let invalid_optimize_result = server.handle_optimize_knowledge_base(&server, &invalid_optimize_params).await;
        assert!(invalid_optimize_result.is_err(), "Invalid parameters should return error");
        
        // Test handling of missing required parameters
        let missing_params = Some(json!({
            "max_results": 10
            // Missing query
        }));
        
        let missing_result = server.handle_iragl_search(&server, &missing_params).await;
        assert!(missing_result.is_err(), "Missing required parameters should return error");
        
        // Test handling of invalid UUIDs
        let invalid_uuid_params = Some(json!({
            "optimization_id": "invalid-uuid"
        }));
        
        let invalid_uuid_result = server.handle_optimization_status(&server, &invalid_uuid_params).await;
        assert!(invalid_uuid_result.is_err(), "Invalid UUID should return error");
        
        // Test handling of very large parameters
        let large_params = Some(json!({
            "query": "test",
            "max_results": 10000 // Too large
        }));
        
        let large_result = server.handle_iragl_search(&server, &large_params).await;
        assert!(large_result.is_err(), "Too large max_results should return error");
    }

    /// Test multi-user and multi-organization scenarios
    #[tokio::test(flavor = "multi_thread")]
    async fn test_multi_user_multi_organization_scenarios() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = McpHttpServer::new(client);
        
        // Simulate multiple organizations
        let organizations = vec![
            "550e8400-e29b-41d4-a716-446655440000",
            "550e8400-e29b-41d4-a716-446655440001",
            "550e8400-e29b-41d4-a716-446655440002"
        ];
        
        // Ingest content for each organization
        for (i, org_id) in organizations.iter().enumerate() {
            let ingest_params = Some(json!({
                "content_type": "document",
                "content_text": format!("Organization {} specific knowledge content", i + 1),
                "source_entity_type": "organization",
                "source_entity_id": org_id,
                "metadata": {
                    "organization_id": org_id,
                    "user_id": format!("user_{}", i + 1),
                    "access_level": "private"
                }
            }));
            
            let result = server.handle_ingest_knowledge_stream(&server, &ingest_params).await;
            assert!(result.is_ok(), "Content ingestion should succeed for each organization");
        }
        
        // Test search with organization context
        for (i, org_id) in organizations.iter().enumerate() {
            let search_params = Some(json!({
                "query": "knowledge content",
                "max_results": 5,
                "query_context": {
                    "organization_id": org_id,
                    "user_id": format!("user_{}", i + 1)
                }
            }));
            
            let result = server.handle_iragl_search(&server, &search_params).await;
            assert!(result.is_ok(), "Search should succeed for each organization");
            
            let response = result.unwrap();
            assert!(response["results"].as_array().unwrap().len() > 0, "Should return results for each organization");
        }
        
        // Test optimization with organization-specific parameters
        for org_id in organizations.iter() {
            let optimize_params = Some(json!({
                "strategy": "incremental",
                "max_iterations": 2,
                "convergence_threshold": 0.1,
                "organization_context": {
                    "organization_id": org_id,
                    "optimization_scope": "organization_specific"
                }
            }));
            
            let result = server.handle_optimize_knowledge_base(&server, &optimize_params).await;
            assert!(result.is_ok(), "Optimization should succeed for each organization");
        }
    }
} 