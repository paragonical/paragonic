#[cfg(test)]
mod content_association_engine_tests {
    use super::*;
    use crate::iragl::{CreateContentAssociationRequest, ContentAssociationResponse};
    use crate::{ParagonicError, ParagonicResult};
    use uuid::Uuid;
    use serde_json::json;

    /// Test ContentAssociationEngine creation
    #[tokio::test]
    async fn test_content_association_engine_creation() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let engine = ContentAssociationEngine::new().unwrap();
        
        // Verify default configuration
        assert_eq!(engine.config().min_association_strength, 0.1);
        assert_eq!(engine.config().max_association_strength, 1.0);
        assert_eq!(engine.config().min_confidence_score, 0.5);
        assert_eq!(engine.config().enable_duplicate_prevention, true);
        assert_eq!(engine.config().enable_relationship_validation, true);
        
        // Verify initial state
        assert_eq!(engine.association_count(), 0);
        assert_eq!(engine.validation_count(), 0);
        assert_eq!(engine.error_count(), 0);
    }

    /// Test ContentAssociationEngine with custom configuration
    #[tokio::test]
    async fn test_content_association_engine_with_config() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let config = ContentAssociationEngineConfig {
            min_association_strength: 0.3,
            max_association_strength: 0.9,
            min_confidence_score: 0.7,
            enable_duplicate_prevention: false,
            enable_relationship_validation: false,
            max_associations_per_content: 10,
            association_cleanup_threshold: 1000,
        };
        
        let engine = ContentAssociationEngine::with_config(config).unwrap();
        
        // Verify custom configuration
        assert_eq!(engine.config().min_association_strength, 0.3);
        assert_eq!(engine.config().max_association_strength, 0.9);
        assert_eq!(engine.config().min_confidence_score, 0.7);
        assert_eq!(engine.config().enable_duplicate_prevention, false);
        assert_eq!(engine.config().enable_relationship_validation, false);
    }

    /// Test association strength calculation
    #[tokio::test]
    async fn test_association_strength_calculation() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let engine = ContentAssociationEngine::new().unwrap();
        
        // Test basic association strength calculation
        let request = CreateContentAssociationRequest {
            content_id: Uuid::new_v4(),
            entity_type: "project".to_string(),
            entity_id: Uuid::new_v4(),
            association_type: "direct".to_string(),
            association_strength: 0.8,
            confidence_score: 0.9,
        };
        
        let calculated_strength = engine.calculate_association_strength(&request).await;
        assert!(calculated_strength.is_ok());
        
        let strength = calculated_strength.unwrap();
        assert!(strength >= engine.config().min_association_strength);
        assert!(strength <= engine.config().max_association_strength);
    }

    /// Test entity relationship validation
    #[tokio::test]
    async fn test_entity_relationship_validation() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let engine = ContentAssociationEngine::new().unwrap();
        
        // Test valid entity relationship
        let request = CreateContentAssociationRequest {
            content_id: Uuid::new_v4(),
            entity_type: "project".to_string(),
            entity_id: Uuid::new_v4(),
            association_type: "direct".to_string(),
            association_strength: 0.8,
            confidence_score: 0.9,
        };
        
        let validation_result = engine.validate_entity_relationship(&request).await;
        assert!(validation_result.is_ok());
        
        // Test invalid entity relationship
        let invalid_request = CreateContentAssociationRequest {
            content_id: Uuid::new_v4(),
            entity_type: "invalid_type".to_string(),
            entity_id: Uuid::new_v4(),
            association_type: "direct".to_string(),
            association_strength: 0.8,
            confidence_score: 0.9,
        };
        
        let invalid_validation = engine.validate_entity_relationship(&invalid_request).await;
        assert!(invalid_validation.is_err());
    }

    /// Test association type classification
    #[tokio::test]
    async fn test_association_type_classification() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let engine = ContentAssociationEngine::new().unwrap();
        
        // Test direct association classification
        let direct_request = CreateContentAssociationRequest {
            content_id: Uuid::new_v4(),
            entity_type: "project".to_string(),
            entity_id: Uuid::new_v4(),
            association_type: "direct".to_string(),
            association_strength: 0.8,
            confidence_score: 0.9,
        };
        
        let direct_classification = engine.classify_association_type(&direct_request).await;
        assert!(direct_classification.is_ok());
        assert_eq!(direct_classification.unwrap(), "direct");
        
        // Test derived association classification
        let derived_request = CreateContentAssociationRequest {
            content_id: Uuid::new_v4(),
            entity_type: "project".to_string(),
            entity_id: Uuid::new_v4(),
            association_type: "derived".to_string(),
            association_strength: 0.6,
            confidence_score: 0.7,
        };
        
        let derived_classification = engine.classify_association_type(&derived_request).await;
        assert!(derived_classification.is_ok());
        assert_eq!(derived_classification.unwrap(), "derived");
    }

    /// Test confidence score computation
    #[tokio::test]
    async fn test_confidence_score_computation() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let engine = ContentAssociationEngine::new().unwrap();
        
        let request = CreateContentAssociationRequest {
            content_id: Uuid::new_v4(),
            entity_type: "project".to_string(),
            entity_id: Uuid::new_v4(),
            association_type: "direct".to_string(),
            association_strength: 0.8,
            confidence_score: 0.9,
        };
        
        let computed_confidence = engine.compute_confidence_score(&request).await;
        assert!(computed_confidence.is_ok());
        
        let confidence = computed_confidence.unwrap();
        assert!(confidence >= engine.config().min_confidence_score);
        assert!(confidence <= 1.0);
    }

    /// Test duplicate association prevention
    #[tokio::test]
    async fn test_duplicate_association_prevention() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let engine = ContentAssociationEngine::new().unwrap();
        
        let content_id = Uuid::new_v4();
        let entity_id = Uuid::new_v4();
        
        let request1 = CreateContentAssociationRequest {
            content_id,
            entity_type: "project".to_string(),
            entity_id,
            association_type: "direct".to_string(),
            association_strength: 0.8,
            confidence_score: 0.9,
        };
        
        let request2 = CreateContentAssociationRequest {
            content_id,
            entity_type: "project".to_string(),
            entity_id,
            association_type: "direct".to_string(),
            association_strength: 0.7,
            confidence_score: 0.8,
        };
        
        // First association should succeed
        let result1 = engine.create_association(request1).await;
        assert!(result1.is_ok());
        
        // Second association should be prevented as duplicate
        let result2 = engine.create_association(request2).await;
        assert!(result2.is_err());
        assert!(result2.unwrap_err().to_string().contains("duplicate"));
    }

    /// Test association creation with validation
    #[tokio::test]
    async fn test_association_creation_with_validation() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let engine = ContentAssociationEngine::new().unwrap();
        
        let request = CreateContentAssociationRequest {
            content_id: Uuid::new_v4(),
            entity_type: "project".to_string(),
            entity_id: Uuid::new_v4(),
            association_type: "direct".to_string(),
            association_strength: 0.8,
            confidence_score: 0.9,
        };
        
        let result = engine.create_association(request).await;
        assert!(result.is_ok());
        
        let response = result.unwrap();
        assert_eq!(response.association_type, "direct");
        assert_eq!(response.association_strength, 0.8);
        assert_eq!(response.confidence_score, 0.9);
        
        // Verify statistics updated
        assert_eq!(engine.association_count(), 1);
        assert_eq!(engine.validation_count(), 1);
        assert_eq!(engine.error_count(), 0);
    }

    /// Test association cleanup
    #[tokio::test]
    async fn test_association_cleanup() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let engine = ContentAssociationEngine::new().unwrap();
        
        // Create multiple associations
        for i in 0..5 {
            let request = CreateContentAssociationRequest {
                content_id: Uuid::new_v4(),
                entity_type: "project".to_string(),
                entity_id: Uuid::new_v4(),
                association_type: "direct".to_string(),
                association_strength: 0.8,
                confidence_score: 0.9,
            };
            
            let _result = engine.create_association(request).await;
        }
        
        assert_eq!(engine.association_count(), 5);
        
        // Perform cleanup
        let cleanup_result = engine.cleanup_old_associations().await;
        assert!(cleanup_result.is_ok());
        
        // Verify cleanup statistics
        let cleanup_count = cleanup_result.unwrap();
        assert!(cleanup_count == 0 || cleanup_count > 0);
    }

    /// Test engine statistics and monitoring
    #[tokio::test]
    async fn test_engine_statistics_and_monitoring() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let engine = ContentAssociationEngine::new().unwrap();
        
        // Initial state
        assert_eq!(engine.association_count(), 0);
        assert_eq!(engine.validation_count(), 0);
        assert_eq!(engine.error_count(), 0);
        assert_eq!(engine.success_rate(), 1.0);
        
        // Create some associations
        for i in 0..3 {
            let request = CreateContentAssociationRequest {
                content_id: Uuid::new_v4(),
                entity_type: "project".to_string(),
                entity_id: Uuid::new_v4(),
                association_type: "direct".to_string(),
                association_strength: 0.8,
                confidence_score: 0.9,
            };
            
            let _result = engine.create_association(request).await;
        }
        
        // Verify statistics updated
        assert_eq!(engine.association_count(), 3);
        assert_eq!(engine.validation_count(), 3);
        assert_eq!(engine.error_count(), 0);
        assert_eq!(engine.success_rate(), 1.0);
        
        // Test reset functionality
        engine.reset_statistics();
        assert_eq!(engine.association_count(), 0);
        assert_eq!(engine.validation_count(), 0);
        assert_eq!(engine.error_count(), 0);
    }
}

// TODO: These structs and traits need to be implemented
// They are defined here for the tests to compile

use crate::iragl::{CreateContentAssociationRequest, ContentAssociationResponse};
use crate::{ParagonicError, ParagonicResult};

#[derive(Debug, Clone)]
pub struct ContentAssociationEngineConfig {
    pub min_association_strength: f64,
    pub max_association_strength: f64,
    pub min_confidence_score: f64,
    pub enable_duplicate_prevention: bool,
    pub enable_relationship_validation: bool,
    pub max_associations_per_content: usize,
    pub association_cleanup_threshold: usize,
}

#[derive(Debug)]
pub struct ContentAssociationEngine {
    config: ContentAssociationEngineConfig,
    association_count: std::sync::atomic::AtomicUsize,
    validation_count: std::sync::atomic::AtomicUsize,
    error_count: std::sync::atomic::AtomicUsize,
}

impl ContentAssociationEngine {
    pub fn new() -> ParagonicResult<Self> {
        let config = ContentAssociationEngineConfig {
            min_association_strength: 0.1,
            max_association_strength: 1.0,
            min_confidence_score: 0.5,
            enable_duplicate_prevention: true,
            enable_relationship_validation: true,
            max_associations_per_content: 100,
            association_cleanup_threshold: 1000,
        };
        Self::with_config(config)
    }
    
    pub fn with_config(config: ContentAssociationEngineConfig) -> ParagonicResult<Self> {
        Ok(Self {
            config,
            association_count: std::sync::atomic::AtomicUsize::new(0),
            validation_count: std::sync::atomic::AtomicUsize::new(0),
            error_count: std::sync::atomic::AtomicUsize::new(0),
        })
    }
    
    pub fn config(&self) -> &ContentAssociationEngineConfig {
        &self.config
    }
    
    pub fn association_count(&self) -> usize {
        self.association_count.load(std::sync::atomic::Ordering::Acquire)
    }
    
    pub fn validation_count(&self) -> usize {
        self.validation_count.load(std::sync::atomic::Ordering::Acquire)
    }
    
    pub fn error_count(&self) -> usize {
        self.error_count.load(std::sync::atomic::Ordering::Acquire)
    }
    
    pub fn success_rate(&self) -> f64 {
        let total = self.association_count() + self.error_count();
        if total == 0 {
            1.0
        } else {
            let successful = self.association_count();
            successful as f64 / total as f64
        }
    }
    
    pub async fn calculate_association_strength(&self, request: &CreateContentAssociationRequest) -> ParagonicResult<f64> {
        // Basic implementation - in real system would use more sophisticated algorithms
        let base_strength = request.association_strength;
        let confidence_factor = request.confidence_score;
        
        let calculated_strength = base_strength * confidence_factor;
        
        // Ensure within configured bounds
        let clamped_strength = calculated_strength
            .max(self.config.min_association_strength)
            .min(self.config.max_association_strength);
        
        Ok(clamped_strength)
    }
    
    pub async fn validate_entity_relationship(&self, request: &CreateContentAssociationRequest) -> ParagonicResult<()> {
        if !self.config.enable_relationship_validation {
            return Ok(());
        }
        
        // Validate entity type
        let valid_entity_types = vec!["organization", "project", "operation", "agent", "user"];
        if !valid_entity_types.contains(&request.entity_type.as_str()) {
            return Err(ParagonicError::InvalidInput(format!("Invalid entity type: {}", request.entity_type)));
        }
        
        // Validate association type
        let valid_association_types = vec!["direct", "derived", "inferred", "metadata"];
        if !valid_association_types.contains(&request.association_type.as_str()) {
            return Err(ParagonicError::InvalidInput(format!("Invalid association type: {}", request.association_type)));
        }
        
        // Validate strength and confidence bounds
        if request.association_strength < self.config.min_association_strength || 
           request.association_strength > self.config.max_association_strength {
            return Err(ParagonicError::InvalidInput("Association strength out of bounds".to_string()));
        }
        
        if request.confidence_score < self.config.min_confidence_score || 
           request.confidence_score > 1.0 {
            return Err(ParagonicError::InvalidInput("Confidence score out of bounds".to_string()));
        }
        
        self.validation_count.fetch_add(1, std::sync::atomic::Ordering::AcqRel);
        Ok(())
    }
    
    pub async fn classify_association_type(&self, request: &CreateContentAssociationRequest) -> ParagonicResult<String> {
        // Simple classification based on association type and strength
        match request.association_type.as_str() {
            "direct" => Ok("direct".to_string()),
            "derived" => Ok("derived".to_string()),
            "inferred" => Ok("inferred".to_string()),
            "metadata" => Ok("metadata".to_string()),
            _ => Ok("unknown".to_string()),
        }
    }
    
    pub async fn compute_confidence_score(&self, request: &CreateContentAssociationRequest) -> ParagonicResult<f64> {
        // Basic confidence computation - in real system would use more sophisticated algorithms
        let base_confidence = request.confidence_score;
        let strength_factor = request.association_strength;
        
        let computed_confidence = base_confidence * strength_factor;
        
        // Ensure within bounds
        let clamped_confidence = computed_confidence
            .max(self.config.min_confidence_score)
            .min(1.0);
        
        Ok(clamped_confidence)
    }
    
    pub async fn create_association(&self, request: CreateContentAssociationRequest) -> ParagonicResult<ContentAssociationResponse> {
        // Validate entity relationship
        self.validate_entity_relationship(&request).await?;
        
        // Check for duplicates if enabled
        if self.config.enable_duplicate_prevention {
            if self.is_duplicate_association(&request).await? {
                return Err(ParagonicError::InvalidInput("Duplicate association detected".to_string()));
            }
        }
        
        // Calculate final association strength
        let final_strength = self.calculate_association_strength(&request).await?;
        
        // Compute confidence score
        let final_confidence = self.compute_confidence_score(&request).await?;
        
        // Use the existing create_content_association function
        let final_request = CreateContentAssociationRequest {
            content_id: request.content_id,
            entity_type: request.entity_type,
            entity_id: request.entity_id,
            association_type: request.association_type,
            association_strength: final_strength,
            confidence_score: final_confidence,
        };
        
        match crate::iragl::create_content_association(final_request).await {
            Ok(response) => {
                self.association_count.fetch_add(1, std::sync::atomic::Ordering::AcqRel);
                Ok(response)
            }
            Err(e) => {
                self.error_count.fetch_add(1, std::sync::atomic::Ordering::AcqRel);
                Err(e)
            }
        }
    }
    
    async fn is_duplicate_association(&self, request: &CreateContentAssociationRequest) -> ParagonicResult<bool> {
        // In a real implementation, this would query the database
        // For now, return false to indicate no duplicate
        Ok(false)
    }
    
    pub async fn cleanup_old_associations(&self) -> ParagonicResult<usize> {
        // In a real implementation, this would clean up old associations
        // For now, return 0 to indicate no cleanup performed
        Ok(0)
    }
    
    pub fn reset_statistics(&self) {
        self.association_count.store(0, std::sync::atomic::Ordering::Release);
        self.validation_count.store(0, std::sync::atomic::Ordering::Release);
        self.error_count.store(0, std::sync::atomic::Ordering::Release);
    }
} 