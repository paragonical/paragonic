use serde::{Deserialize, Serialize};
use serde_json::Value;
use uuid::Uuid;
use chrono::{DateTime, Utc};
use crate::error::{ParagonicError, ParagonicResult};

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

/// Types of pattern triggers
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum TriggerType {
    Automatic,
    Manual,
    Scheduled,
}

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

impl SystemPattern {
    /// Creates a new SystemPattern with validation
    pub fn new(
        name: String,
        category: PatternCategory,
        meta_level: MetaLevel,
        description: String,
        workflow_steps: Value,
        output_format: Value,
        trigger_conditions: Option<Value>,
        success_criteria: Option<Value>,
    ) -> ParagonicResult<Self> {
        // Validate required fields
        if name.trim().is_empty() {
            return Err(ParagonicError::InvalidInput("Pattern name cannot be empty".to_string()));
        }
        
        if description.trim().is_empty() {
            return Err(ParagonicError::InvalidInput("Pattern description cannot be empty".to_string()));
        }
        
        if !workflow_steps.is_array() {
            return Err(ParagonicError::InvalidInput("Workflow steps must be an array".to_string()));
        }
        
        if !output_format.is_object() {
            return Err(ParagonicError::InvalidInput("Output format must be an object".to_string()));
        }
        
        let now = Utc::now();
        Ok(Self {
            id: Uuid::new_v4(),
            name,
            category,
            meta_level,
            description,
            workflow_steps,
            output_format,
            trigger_conditions,
            success_criteria,
            created_at: now,
            updated_at: now,
        })
    }
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

impl PatternExecution {
    /// Creates a new PatternExecution with validation
    pub fn new(
        pattern_id: Uuid,
        session_id: Option<Uuid>,
        trigger_type: TriggerType,
        input_context: Option<Value>,
    ) -> ParagonicResult<Self> {
        // Validate that pattern_id is not null
        if pattern_id.is_nil() {
            return Err(ParagonicError::InvalidInput("Pattern ID cannot be null".to_string()));
        }
        
        let now = Utc::now();
        Ok(Self {
            id: Uuid::new_v4(),
            pattern_id,
            session_id,
            trigger_type,
            input_context,
            output_result: None,
            execution_duration_ms: None,
            success: false,
            error_message: None,
            created_at: now,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn test_system_pattern_creation_with_valid_data() {
        let pattern = SystemPattern::new(
            "Test Session Summary".to_string(),
            PatternCategory::SessionManagement,
            MetaLevel::System,
            "Test pattern for session summarization".to_string(),
            json!([
                {"step": 1, "action": "analyze_session", "description": "Analyze session data"},
                {"step": 2, "action": "generate_summary", "description": "Generate summary"}
            ]),
            json!({
                "summary": "string",
                "key_points": ["string"]
            }),
            Some(json!({"session_duration_minutes": 30})),
            Some(json!({"summary_length": ">100"})),
        ).unwrap();
        
        assert_eq!(pattern.name, "Test Session Summary");
        assert_eq!(pattern.category, PatternCategory::SessionManagement);
        assert_eq!(pattern.meta_level, MetaLevel::System);
        assert!(!pattern.description.is_empty());
        assert!(pattern.workflow_steps.is_array());
        assert!(pattern.output_format.is_object());
        assert!(pattern.trigger_conditions.is_some());
        assert!(pattern.success_criteria.is_some());
    }

    #[test]
    fn test_system_pattern_creation_with_empty_name() {
        let result = SystemPattern::new(
            "".to_string(),
            PatternCategory::SessionManagement,
            MetaLevel::System,
            "Test pattern for session summarization".to_string(),
            json!([
                {"step": 1, "action": "analyze_session", "description": "Analyze session data"}
            ]),
            json!({
                "summary": "string"
            }),
            None,
            None,
        );
        
        assert!(result.is_err());
        match result {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert_eq!(msg, "Pattern name cannot be empty");
            }
            _ => panic!("Expected InvalidInput error"),
        }
    }

    #[test]
    fn test_pattern_execution_creation_with_valid_data() {
        let pattern_id = Uuid::new_v4();
        let session_id = Uuid::new_v4();
        let execution = PatternExecution::new(
            pattern_id,
            Some(session_id),
            TriggerType::Automatic,
            Some(json!({"session_duration": 3600})),
        ).unwrap();
        
        assert_eq!(execution.pattern_id, pattern_id);
        assert_eq!(execution.session_id, Some(session_id));
        assert_eq!(execution.trigger_type, TriggerType::Automatic);
        assert!(execution.input_context.is_some());
        assert!(execution.output_result.is_none());
        assert!(execution.execution_duration_ms.is_none());
        assert!(!execution.success);
        assert!(execution.error_message.is_none());
    }

    #[test]
    fn test_pattern_execution_creation_with_null_pattern_id() {
        let result = PatternExecution::new(
            Uuid::nil(),
            None,
            TriggerType::Manual,
            None,
        );
        
        assert!(result.is_err());
        match result {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert_eq!(msg, "Pattern ID cannot be null");
            }
            _ => panic!("Expected InvalidInput error"),
        }
    }
}
