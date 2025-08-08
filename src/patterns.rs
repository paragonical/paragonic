use serde::{Deserialize, Serialize};
use serde_json::Value;
use uuid::Uuid;
use chrono::{DateTime, Utc};
use crate::error::{ParagonicError, ParagonicResult};

/// Represents a system pattern that can be executed by AI agents
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SystemPattern {
    pub id: Uuid,
    pub name: String,
    pub category: PatternCategory,
    pub meta_level: MetaLevel,
    pub description: String,
    pub workflow_steps: Value,
    pub output_format: Value,
    pub trigger_conditions: Option<Value>,
    pub success_criteria: Option<Value>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Categories for system patterns
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum PatternCategory {
    SessionManagement,
    SelfReflection,
    ContextSummarization,
    ActivityLabeling,
    ProgressTracking,
    KnowledgeExtraction,
}

/// Meta levels for patterns
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum MetaLevel {
    System,
    User,
    Hybrid,
}

/// Represents a pattern execution instance
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PatternExecution {
    pub id: Uuid,
    pub pattern_id: Uuid,
    pub session_id: Option<Uuid>,
    pub trigger_type: TriggerType,
    pub input_context: Option<Value>,
    pub output_result: Option<Value>,
    pub execution_duration_ms: Option<u64>,
    pub success: bool,
    pub error_message: Option<String>,
    pub created_at: DateTime<Utc>,
}

/// Types of pattern triggers
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum TriggerType {
    Automatic,
    Manual,
    Scheduled,
}

/// Represents a relationship between patterns
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PatternRelationship {
    pub id: Uuid,
    pub source_pattern_id: Uuid,
    pub target_pattern_id: Uuid,
    pub relationship_type: RelationshipType,
    pub description: Option<String>,
    pub confidence_score: f32,
    pub created_at: DateTime<Utc>,
}

/// Types of pattern relationships
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum RelationshipType {
    Prerequisite,
    Alternative,
    Sequence,
    Dependency,
}

/// Registry for managing system patterns
pub struct PatternRegistry {
    patterns: Vec<SystemPattern>,
    relationships: Vec<PatternRelationship>,
}

impl PatternRegistry {
    pub fn new() -> Self {
        Self {
            patterns: Vec::new(),
            relationships: Vec::new(),
        }
    }

    pub fn register_pattern(&mut self, pattern: SystemPattern) -> ParagonicResult<()> {
        // Validate pattern name uniqueness
        if self.patterns.iter().any(|p| p.name == pattern.name) {
            return Err(ParagonicError::InvalidInput(
                format!("Pattern with name '{}' already exists", pattern.name)
            ));
        }
        
        self.patterns.push(pattern);
        Ok(())
    }

    pub fn get_pattern(&self, id: Uuid) -> Option<&SystemPattern> {
        self.patterns.iter().find(|p| p.id == id)
    }

    pub fn get_pattern_by_name(&self, name: &str) -> Option<&SystemPattern> {
        self.patterns.iter().find(|p| p.name == name)
    }

    pub fn list_patterns(&self, category: Option<PatternCategory>, meta_level: Option<MetaLevel>) -> Vec<&SystemPattern> {
        self.patterns.iter()
            .filter(|p| {
                if let Some(ref cat) = category {
                    if p.category != *cat {
                        return false;
                    }
                }
                if let Some(ref level) = meta_level {
                    if p.meta_level != *level {
                        return false;
                    }
                }
                true
            })
            .collect()
    }

    pub fn add_relationship(&mut self, relationship: PatternRelationship) -> ParagonicResult<()> {
        // Validate that both patterns exist
        if !self.patterns.iter().any(|p| p.id == relationship.source_pattern_id) {
            return Err(ParagonicError::InvalidInput(
                format!("Source pattern with id '{}' does not exist", relationship.source_pattern_id)
            ));
        }
        if !self.patterns.iter().any(|p| p.id == relationship.target_pattern_id) {
            return Err(ParagonicError::InvalidInput(
                format!("Target pattern with id '{}' does not exist", relationship.target_pattern_id)
            ));
        }

        // Check for duplicate relationships
        if self.relationships.iter().any(|r| {
            r.source_pattern_id == relationship.source_pattern_id &&
            r.target_pattern_id == relationship.target_pattern_id &&
            r.relationship_type == relationship.relationship_type
        }) {
            return Err(ParagonicError::InvalidInput(
                "Relationship already exists".to_string()
            ));
        }

        self.relationships.push(relationship);
        Ok(())
    }

    pub fn get_relationships(&self, pattern_id: Uuid) -> Vec<&PatternRelationship> {
        self.relationships.iter()
            .filter(|r| r.source_pattern_id == pattern_id || r.target_pattern_id == pattern_id)
            .collect()
    }
}

impl Default for PatternRegistry {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    fn create_test_pattern() -> SystemPattern {
        SystemPattern {
            id: Uuid::new_v4(),
            name: "Test Session Summary".to_string(),
            category: PatternCategory::SessionManagement,
            meta_level: MetaLevel::System,
            description: "Test pattern for session summarization".to_string(),
            workflow_steps: json!([
                {"step": 1, "action": "analyze_session", "description": "Analyze session data"},
                {"step": 2, "action": "generate_summary", "description": "Generate summary"}
            ]),
            output_format: json!({
                "summary": "string",
                "key_points": ["string"]
            }),
            trigger_conditions: Some(json!({"session_duration_minutes": 30})),
            success_criteria: Some(json!({"summary_length": ">100"})),
            created_at: Utc::now(),
            updated_at: Utc::now(),
        }
    }

    fn create_test_execution(pattern_id: Uuid) -> PatternExecution {
        PatternExecution {
            id: Uuid::new_v4(),
            pattern_id,
            session_id: Some(Uuid::new_v4()),
            trigger_type: TriggerType::Automatic,
            input_context: Some(json!({"session_duration": 3600})),
            output_result: Some(json!({
                "summary": "Test session summary",
                "key_points": ["Point 1", "Point 2"]
            })),
            execution_duration_ms: Some(1500),
            success: true,
            error_message: None,
            created_at: Utc::now(),
        }
    }

    fn create_test_relationship(source_id: Uuid, target_id: Uuid) -> PatternRelationship {
        PatternRelationship {
            id: Uuid::new_v4(),
            source_pattern_id: source_id,
            target_pattern_id: target_id,
            relationship_type: RelationshipType::Prerequisite,
            description: Some("Test relationship".to_string()),
            confidence_score: 0.8,
            created_at: Utc::now(),
        }
    }

    #[test]
    fn test_system_pattern_creation() {
        let pattern = create_test_pattern();
        
        assert_eq!(pattern.name, "Test Session Summary");
        assert_eq!(pattern.category, PatternCategory::SessionManagement);
        assert_eq!(pattern.meta_level, MetaLevel::System);
        assert!(!pattern.description.is_empty());
        assert!(pattern.workflow_steps.is_array());
        assert!(pattern.output_format.is_object());
    }

    #[test]
    fn test_system_pattern_serialization() {
        let pattern = create_test_pattern();
        let serialized = serde_json::to_string(&pattern).unwrap();
        let deserialized: SystemPattern = serde_json::from_str(&serialized).unwrap();
        
        assert_eq!(pattern.id, deserialized.id);
        assert_eq!(pattern.name, deserialized.name);
        assert_eq!(pattern.category, deserialized.category);
        assert_eq!(pattern.meta_level, deserialized.meta_level);
    }

    #[test]
    fn test_pattern_execution_creation() {
        let pattern_id = Uuid::new_v4();
        let execution = create_test_execution(pattern_id);
        
        assert_eq!(execution.pattern_id, pattern_id);
        assert_eq!(execution.trigger_type, TriggerType::Automatic);
        assert!(execution.success);
        assert!(execution.input_context.is_some());
        assert!(execution.output_result.is_some());
    }

    #[test]
    fn test_pattern_execution_serialization() {
        let pattern_id = Uuid::new_v4();
        let execution = create_test_execution(pattern_id);
        let serialized = serde_json::to_string(&execution).unwrap();
        let deserialized: PatternExecution = serde_json::from_str(&serialized).unwrap();
        
        assert_eq!(execution.id, deserialized.id);
        assert_eq!(execution.pattern_id, deserialized.pattern_id);
        assert_eq!(execution.trigger_type, deserialized.trigger_type);
        assert_eq!(execution.success, deserialized.success);
    }

    #[test]
    fn test_pattern_registry_creation() {
        let registry = PatternRegistry::new();
        assert_eq!(registry.patterns.len(), 0);
        assert_eq!(registry.relationships.len(), 0);
    }

    #[test]
    fn test_pattern_registry_register_pattern() {
        let mut registry = PatternRegistry::new();
        let pattern = create_test_pattern();
        
        let result = registry.register_pattern(pattern.clone());
        assert!(result.is_ok());
        assert_eq!(registry.patterns.len(), 1);
        
        let retrieved = registry.get_pattern(pattern.id);
        assert!(retrieved.is_some());
        assert_eq!(retrieved.unwrap().name, pattern.name);
    }

    #[test]
    fn test_pattern_registry_duplicate_name_rejection() {
        let mut registry = PatternRegistry::new();
        let pattern1 = create_test_pattern();
        let mut pattern2 = create_test_pattern();
        pattern2.id = Uuid::new_v4(); // Different ID but same name
        
        registry.register_pattern(pattern1).unwrap();
        let result = registry.register_pattern(pattern2);
        
        assert!(result.is_err());
        assert_eq!(registry.patterns.len(), 1);
    }

    #[test]
    fn test_pattern_registry_filtering() {
        let mut registry = PatternRegistry::new();
        
        let pattern1 = create_test_pattern();
        let mut pattern2 = create_test_pattern();
        pattern2.id = Uuid::new_v4();
        pattern2.name = "Test Activity Label".to_string();
        pattern2.category = PatternCategory::ActivityLabeling;
        
        registry.register_pattern(pattern1).unwrap();
        registry.register_pattern(pattern2).unwrap();
        
        // Test category filtering
        let session_patterns = registry.list_patterns(Some(PatternCategory::SessionManagement), None);
        assert_eq!(session_patterns.len(), 1);
        
        let activity_patterns = registry.list_patterns(Some(PatternCategory::ActivityLabeling), None);
        assert_eq!(activity_patterns.len(), 1);
        
        // Test meta_level filtering
        let system_patterns = registry.list_patterns(None, Some(MetaLevel::System));
        assert_eq!(system_patterns.len(), 2);
    }

    #[test]
    fn test_pattern_relationship_creation() {
        let mut registry = PatternRegistry::new();
        let pattern1 = create_test_pattern();
        let mut pattern2 = create_test_pattern();
        pattern2.id = Uuid::new_v4();
        pattern2.name = "Test Activity Label".to_string();
        
        registry.register_pattern(pattern1.clone()).unwrap();
        registry.register_pattern(pattern2.clone()).unwrap();
        
        let relationship = create_test_relationship(pattern1.id, pattern2.id);
        let result = registry.add_relationship(relationship.clone());
        
        assert!(result.is_ok());
        assert_eq!(registry.relationships.len(), 1);
        
        let relationships = registry.get_relationships(pattern1.id);
        assert_eq!(relationships.len(), 1);
        assert_eq!(relationships[0].relationship_type, RelationshipType::Prerequisite);
    }

    #[test]
    fn test_pattern_relationship_validation() {
        let mut registry = PatternRegistry::new();
        let pattern1 = create_test_pattern();
        let pattern2_id = Uuid::new_v4();
        
        registry.register_pattern(pattern1.clone()).unwrap();
        
        // Try to create relationship with non-existent target pattern
        let relationship = create_test_relationship(pattern1.id, pattern2_id);
        let result = registry.add_relationship(relationship);
        
        assert!(result.is_err());
        assert_eq!(registry.relationships.len(), 0);
    }

    #[test]
    fn test_pattern_relationship_duplicate_rejection() {
        let mut registry = PatternRegistry::new();
        let pattern1 = create_test_pattern();
        let mut pattern2 = create_test_pattern();
        pattern2.id = Uuid::new_v4();
        pattern2.name = "Test Activity Label".to_string();
        
        registry.register_pattern(pattern1.clone()).unwrap();
        registry.register_pattern(pattern2.clone()).unwrap();
        
        let relationship1 = create_test_relationship(pattern1.id, pattern2.id);
        let relationship2 = create_test_relationship(pattern1.id, pattern2.id);
        
        registry.add_relationship(relationship1).unwrap();
        let result = registry.add_relationship(relationship2);
        
        assert!(result.is_err());
        assert_eq!(registry.relationships.len(), 1);
    }
}
