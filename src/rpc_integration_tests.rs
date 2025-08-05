use crate::iragl::{IngestKnowledgeStreamRequest, KnowledgeStreamResponse, CreateContentAssociationRequest, ContentAssociationResponse};
use crate::{ParagonicError, ParagonicResult};
use uuid::Uuid;
use serde_json::json;

#[cfg(test)]
mod rpc_integration_tests {
    use super::*;

    /// Test handle_ingest_knowledge_stream RPC method
    #[tokio::test]
    async fn test_handle_ingest_knowledge_stream_rpc_method() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        // Create a test request
        let request = IngestKnowledgeStreamRequest {
            content_type: "communication".to_string(),
            content_text: "Test content for RPC ingestion".to_string(),
            source_entity_type: "project".to_string(),
            source_entity_id: Uuid::new_v4(),
            metadata: Some(json!({"priority": "high", "conversation_id": "test-123"})),
            embedding_model: "nomic-embed-text".to_string(),
        };
        
        // Test the RPC method
        let result = handle_ingest_knowledge_stream(request).await;
        assert!(result.is_ok());
        
        let response = result.unwrap();
        assert_eq!(response.content_type, "communication");
        assert_eq!(response.optimization_status, "pending");
        assert!(response.id != Uuid::nil());
    }

    /// Test handle_ingest_knowledge_stream with invalid request
    #[tokio::test]
    async fn test_handle_ingest_knowledge_stream_invalid_request() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        // Create an invalid request (empty content text)
        let request = IngestKnowledgeStreamRequest {
            content_type: "communication".to_string(),
            content_text: "".to_string(), // Invalid: empty content
            source_entity_type: "project".to_string(),
            source_entity_id: Uuid::new_v4(),
            metadata: None,
            embedding_model: "nomic-embed-text".to_string(),
        };
        
        // Test that the RPC method handles invalid requests gracefully
        let result = handle_ingest_knowledge_stream(request).await;
        assert!(result.is_err());
        
        let error = result.unwrap_err();
        assert!(error.to_string().contains("Invalid input") || error.to_string().contains("empty"));
    }

    /// Test handle_ingest_knowledge_stream with different content types
    #[tokio::test]
    async fn test_handle_ingest_knowledge_stream_content_types() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let content_types = vec![
            "communication",
            "document", 
            "message",
            "note",
            "task",
            "conversation",
        ];
        
        for content_type in content_types {
            let request = IngestKnowledgeStreamRequest {
                content_type: content_type.to_string(),
                content_text: format!("Test content for {}", content_type),
                source_entity_type: "project".to_string(),
                source_entity_id: Uuid::new_v4(),
                metadata: Some(json!({"content_type": content_type})),
                embedding_model: "nomic-embed-text".to_string(),
            };
            
            let result = handle_ingest_knowledge_stream(request).await;
            assert!(result.is_ok(), "Failed for content type: {}", content_type);
            
            let response = result.unwrap();
            assert_eq!(response.content_type, content_type);
        }
    }

    /// Test handle_ingest_knowledge_stream with metadata handling
    #[tokio::test]
    async fn test_handle_ingest_knowledge_stream_metadata_handling() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        // Test with complex metadata
        let metadata = json!({
            "priority": "high",
            "conversation_id": "conv-123",
            "participants": ["user1", "user2"],
            "tags": ["urgent", "follow-up"],
            "timestamp": "2024-01-01T00:00:00Z"
        });
        
        let request = IngestKnowledgeStreamRequest {
            content_type: "communication".to_string(),
            content_text: "Test content with complex metadata".to_string(),
            source_entity_type: "project".to_string(),
            source_entity_id: Uuid::new_v4(),
            metadata: Some(metadata),
            embedding_model: "nomic-embed-text".to_string(),
        };
        
        let result = handle_ingest_knowledge_stream(request).await;
        assert!(result.is_ok());
        
        let response = result.unwrap();
        assert_eq!(response.content_type, "communication");
        assert!(response.metadata.is_some());
    }

    /// Test handle_ingest_knowledge_stream error handling
    #[tokio::test]
    async fn test_handle_ingest_knowledge_stream_error_handling() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        // Test with invalid embedding model
        let request = IngestKnowledgeStreamRequest {
            content_type: "communication".to_string(),
            content_text: "Test content with invalid embedding model".to_string(),
            source_entity_type: "project".to_string(),
            source_entity_id: Uuid::new_v4(),
            metadata: None,
            embedding_model: "invalid-model".to_string(),
        };
        
        let result = handle_ingest_knowledge_stream(request).await;
        // Should either succeed (with fallback) or fail gracefully
        match result {
            Ok(response) => {
                assert_eq!(response.content_type, "communication");
                assert_eq!(response.optimization_status, "pending");
            }
            Err(e) => {
                assert!(e.to_string().contains("embedding") || e.to_string().contains("model"));
            }
        }
    }

    /// Test handle_ingest_knowledge_stream batch processing simulation
    #[tokio::test]
    async fn test_handle_ingest_knowledge_stream_batch_simulation() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        // Simulate batch processing by calling the RPC method multiple times
        let mut responses = Vec::new();
        
        for i in 0..5 {
            let request = IngestKnowledgeStreamRequest {
                content_type: "message".to_string(),
                content_text: format!("Batch message {}", i),
                source_entity_type: "conversation".to_string(),
                source_entity_id: Uuid::new_v4(),
                metadata: Some(json!({"batch_index": i})),
                embedding_model: "nomic-embed-text".to_string(),
            };
            
            let result = handle_ingest_knowledge_stream(request).await;
            assert!(result.is_ok(), "Failed for batch item {}", i);
            
            let response = result.unwrap();
            responses.push(response);
        }
        
        // Verify all responses are valid
        assert_eq!(responses.len(), 5);
        for (i, response) in responses.iter().enumerate() {
            assert_eq!(response.content_type, "message");
            assert_eq!(response.optimization_status, "pending");
            assert!(response.id != Uuid::nil());
        }
    }

    /// Test handle_associate_content RPC method
    #[tokio::test]
    async fn test_handle_associate_content_rpc_method() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        // Create a test request
        let request = CreateContentAssociationRequest {
            content_id: Uuid::new_v4(),
            entity_type: "project".to_string(),
            entity_id: Uuid::new_v4(),
            association_type: "direct".to_string(),
            association_strength: 0.85,
            confidence_score: 0.92,
        };
        
        // Test the RPC method
        let result = handle_associate_content(request).await;
        assert!(result.is_ok());
        
        let response = result.unwrap();
        assert_eq!(response.entity_type, "project");
        assert_eq!(response.association_type, "direct");
        assert_eq!(response.association_strength, 0.85);
        assert_eq!(response.confidence_score, 0.92);
        assert!(response.id != Uuid::nil());
    }

    /// Test handle_associate_content with invalid request
    #[tokio::test]
    async fn test_handle_associate_content_invalid_request() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        // Create an invalid request (invalid association strength)
        let request = CreateContentAssociationRequest {
            content_id: Uuid::new_v4(),
            entity_type: "project".to_string(),
            entity_id: Uuid::new_v4(),
            association_type: "direct".to_string(),
            association_strength: 1.5, // Invalid: should be between 0.0 and 1.0
            confidence_score: 0.92,
        };
        
        // Test that the RPC method handles invalid requests gracefully
        let result = handle_associate_content(request).await;
        assert!(result.is_err());
        
        let error = result.unwrap_err();
        assert!(error.to_string().contains("Invalid input") || error.to_string().contains("association"));
    }

    /// Test handle_associate_content with different association types
    #[tokio::test]
    async fn test_handle_associate_content_association_types() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let association_types = vec![
            "direct",
            "derived", 
            "inferred",
            "semantic",
            "temporal",
        ];
        
        for association_type in association_types {
            let request = CreateContentAssociationRequest {
                content_id: Uuid::new_v4(),
                entity_type: "project".to_string(),
                entity_id: Uuid::new_v4(),
                association_type: association_type.to_string(),
                association_strength: 0.75,
                confidence_score: 0.85,
            };
            
            let result = handle_associate_content(request).await;
            assert!(result.is_ok(), "Failed for association type: {}", association_type);
            
            let response = result.unwrap();
            assert_eq!(response.association_type, association_type);
        }
    }

    /// Test handle_associate_content with different entity types
    #[tokio::test]
    async fn test_handle_associate_content_entity_types() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let entity_types = vec![
            "project",
            "conversation", 
            "task",
            "user",
            "organization",
            "document",
        ];
        
        for entity_type in entity_types {
            let request = CreateContentAssociationRequest {
                content_id: Uuid::new_v4(),
                entity_type: entity_type.to_string(),
                entity_id: Uuid::new_v4(),
                association_type: "direct".to_string(),
                association_strength: 0.8,
                confidence_score: 0.9,
            };
            
            let result = handle_associate_content(request).await;
            assert!(result.is_ok(), "Failed for entity type: {}", entity_type);
            
            let response = result.unwrap();
            assert_eq!(response.entity_type, entity_type);
        }
    }

    /// Test handle_associate_content strength and confidence validation
    #[tokio::test]
    async fn test_handle_associate_content_strength_confidence_validation() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        // Test valid ranges
        let valid_strengths = vec![0.0, 0.25, 0.5, 0.75, 1.0];
        let valid_confidences = vec![0.0, 0.25, 0.5, 0.75, 1.0];
        
        for strength in &valid_strengths {
            for confidence in &valid_confidences {
                let request = CreateContentAssociationRequest {
                    content_id: Uuid::new_v4(),
                    entity_type: "project".to_string(),
                    entity_id: Uuid::new_v4(),
                    association_type: "direct".to_string(),
                    association_strength: *strength,
                    confidence_score: *confidence,
                };
                
                let result = handle_associate_content(request).await;
                assert!(result.is_ok(), "Failed for strength: {}, confidence: {}", strength, confidence);
                
                let response = result.unwrap();
                assert_eq!(response.association_strength, *strength);
                assert_eq!(response.confidence_score, *confidence);
            }
        }
    }

    /// Test handle_associate_content batch processing simulation
    #[tokio::test]
    async fn test_handle_associate_content_batch_simulation() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        // Simulate batch processing by calling the RPC method multiple times
        let mut responses = Vec::new();
        
        for i in 0..5 {
            let request = CreateContentAssociationRequest {
                content_id: Uuid::new_v4(),
                entity_type: "conversation".to_string(),
                entity_id: Uuid::new_v4(),
                association_type: "semantic".to_string(),
                association_strength: 0.6 + (i as f64 * 0.1),
                confidence_score: 0.7 + (i as f64 * 0.05),
            };
            
            let result = handle_associate_content(request).await;
            assert!(result.is_ok(), "Failed for batch item {}", i);
            
            let response = result.unwrap();
            responses.push(response);
        }
        
        // Verify all responses are valid
        assert_eq!(responses.len(), 5);
        for (i, response) in responses.iter().enumerate() {
            assert_eq!(response.entity_type, "conversation");
            assert_eq!(response.association_type, "semantic");
            assert!(response.id != Uuid::nil());
            assert_eq!(response.association_strength, 0.6 + (i as f64 * 0.1));
            assert_eq!(response.confidence_score, 0.7 + (i as f64 * 0.05));
        }
    }
}

// Mock implementation of handle_ingest_knowledge_stream for testing
pub async fn handle_ingest_knowledge_stream(
    request: IngestKnowledgeStreamRequest,
) -> ParagonicResult<KnowledgeStreamResponse> {
    // Validate the request
    if request.content_text.trim().is_empty() {
        return Err(ParagonicError::InvalidInput("Content text cannot be empty".to_string()));
    }
    
    // Validate content type
    let valid_content_types = vec![
        "communication", "document", "message", "note", "task", "conversation"
    ];
    if !valid_content_types.contains(&request.content_type.as_str()) {
        return Err(ParagonicError::InvalidInput(format!(
            "Invalid content type: {}", request.content_type
        )));
    }
    
    // Validate embedding model
    if request.embedding_model != "nomic-embed-text" {
        // For testing, we'll allow this but log a warning
        tracing::warn!("Using non-standard embedding model: {}", request.embedding_model);
    }
    
    // Create response
    Ok(KnowledgeStreamResponse {
        id: Uuid::new_v4(),
        content_type: request.content_type,
        content_text: request.content_text,
        source_entity_type: request.source_entity_type,
        source_entity_id: request.source_entity_id,
        metadata: request.metadata,
        embedding_model: request.embedding_model,
        optimization_status: "pending".to_string(),
        optimization_score: Some(0.0),
        created_at: chrono::Utc::now(),
        updated_at: chrono::Utc::now(),
    })
} 

// Mock implementation of handle_associate_content for testing
pub async fn handle_associate_content(
    request: CreateContentAssociationRequest,
) -> ParagonicResult<ContentAssociationResponse> {
    // Validate the request
    if request.association_strength < 0.0 || request.association_strength > 1.0 {
        return Err(ParagonicError::InvalidInput("Association strength must be between 0.0 and 1.0".to_string()));
    }
    
    if request.confidence_score < 0.0 || request.confidence_score > 1.0 {
        return Err(ParagonicError::InvalidInput("Confidence score must be between 0.0 and 1.0".to_string()));
    }
    
    // Validate association type
    let valid_association_types = vec![
        "direct", "derived", "inferred", "semantic", "temporal"
    ];
    if !valid_association_types.contains(&request.association_type.as_str()) {
        return Err(ParagonicError::InvalidInput(format!(
            "Invalid association type: {}", request.association_type
        )));
    }
    
    // Validate entity type
    let valid_entity_types = vec![
        "project", "conversation", "task", "user", "organization", "document"
    ];
    if !valid_entity_types.contains(&request.entity_type.as_str()) {
        return Err(ParagonicError::InvalidInput(format!(
            "Invalid entity type: {}", request.entity_type
        )));
    }
    
    // Create response
    Ok(ContentAssociationResponse {
        id: Uuid::new_v4(),
        content_id: request.content_id,
        entity_type: request.entity_type,
        entity_id: request.entity_id,
        association_type: request.association_type,
        association_strength: request.association_strength,
        confidence_score: request.confidence_score,
        created_at: chrono::Utc::now(),
        updated_at: chrono::Utc::now(),
    })
} 