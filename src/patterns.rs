use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use uuid::Uuid;
use chrono::{DateTime, Utc};
use crate::error::{ParagonicError, ParagonicResult};
use tera::{Tera, Context};
use std::path::PathBuf;

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

/// Types of pattern relationships
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum RelationshipType {
    DependsOn,
    Triggers,
    Enhances,
    ConflictsWith,
    SimilarTo,
}

/// Represents a relationship between two system patterns
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PatternRelationship {
    pub id: Uuid,
    pub source_pattern_id: Uuid,
    pub target_pattern_id: Uuid,
    pub relationship_type: RelationshipType,
    pub description: String,
    pub strength: f64, // 0.0 to 1.0
    pub created_at: DateTime<Utc>,
}

impl PatternRelationship {
    /// Creates a new pattern relationship
    pub fn new(
        source_pattern_id: Uuid,
        target_pattern_id: Uuid,
        relationship_type: RelationshipType,
        description: String,
        strength: f64,
    ) -> ParagonicResult<Self> {
        // Validate that source and target are different
        if source_pattern_id == target_pattern_id {
            return Err(ParagonicError::InvalidInput(
                "Source and target pattern IDs must be different".to_string()
            ));
        }
        
        // Validate strength is between 0.0 and 1.0
        if strength < 0.0 || strength > 1.0 {
            return Err(ParagonicError::InvalidInput(
                "Strength must be between 0.0 and 1.0".to_string()
            ));
        }
        
        // Validate description is not empty
        if description.trim().is_empty() {
            return Err(ParagonicError::InvalidInput(
                "Description cannot be empty".to_string()
            ));
        }
        
        Ok(Self {
            id: Uuid::new_v4(),
            source_pattern_id,
            target_pattern_id,
            relationship_type,
            description,
            strength,
            created_at: Utc::now(),
        })
    }
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

    /// Starts execution tracking for a pattern
    pub fn start_execution(&mut self) -> ParagonicResult<()> {
        // Check if execution is already in progress
        if self.success {
            return Err(ParagonicError::InvalidInput(
                "Cannot start execution that is already completed".to_string()
            ));
        }
        
        // Check if execution is already started
        if self.execution_duration_ms.is_some() {
            return Err(ParagonicError::InvalidInput(
                "Execution is already in progress".to_string()
            ));
        }
        
        // Mark execution as started by setting a placeholder duration
        self.execution_duration_ms = Some(0);
        Ok(())
    }

    /// Completes execution tracking and records results
    pub fn complete_execution(&mut self, success: bool, output_result: Option<Value>, error_message: Option<String>) -> ParagonicResult<()> {
        // Check if execution has been started
        if self.execution_duration_ms.is_none() {
            return Err(ParagonicError::InvalidInput(
                "Cannot complete execution that has not been started".to_string()
            ));
        }
        
        // Check if execution is already completed
        if self.success {
            return Err(ParagonicError::InvalidInput(
                "Execution is already completed".to_string()
            ));
        }
        
        // Set execution results
        self.success = success;
        self.output_result = output_result;
        self.error_message = error_message;
        
        // Calculate execution duration (placeholder for now)
        self.execution_duration_ms = Some(100); // Mock duration
        
        Ok(())
    }

    /// Updates execution with intermediate results
    pub fn update_execution(&mut self, output_result: Option<Value>, error_message: Option<String>) -> ParagonicResult<()> {
        // Check if execution has been started
        if self.execution_duration_ms.is_none() {
            return Err(ParagonicError::InvalidInput(
                "Cannot update execution that has not been started".to_string()
            ));
        }
        
        // Check if execution is already completed
        if self.success {
            return Err(ParagonicError::InvalidInput(
                "Cannot update execution that is already completed".to_string()
            ));
        }
        
        // Update output and error message
        self.output_result = output_result;
        self.error_message = error_message;
        
        Ok(())
    }

    /// Returns the current execution status
    pub fn get_execution_status(&self) -> ExecutionStatus {
        if self.success {
            ExecutionStatus::Completed
        } else if self.execution_duration_ms.is_some() {
            ExecutionStatus::InProgress
        } else {
            ExecutionStatus::NotStarted
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub enum ExecutionStatus {
    NotStarted,
    InProgress,
    Completed,
}

/// Represents a pattern template
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PatternTemplate {
    pub id: Uuid,
    pub name: String,
    pub description: String,
    pub template_content: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl PatternTemplate {
    /// Creates a new PatternTemplate with validation
    pub fn new(
        name: String,
        description: String,
        template_content: String,
    ) -> ParagonicResult<Self> {
        if name.trim().is_empty() {
            return Err(ParagonicError::InvalidInput("Pattern template name cannot be empty".to_string()));
        }
        if description.trim().is_empty() {
            return Err(ParagonicError::InvalidInput("Pattern template description cannot be empty".to_string()));
        }
        if template_content.trim().is_empty() {
            return Err(ParagonicError::InvalidInput("Pattern template content cannot be empty".to_string()));
        }

        let now = Utc::now();
        Ok(Self {
            id: Uuid::new_v4(),
            name,
            description,
            template_content,
            created_at: now,
            updated_at: now,
        })
    }

    /// Renders the template with the provided context
    pub fn render(&self, context: &serde_json::Value) -> ParagonicResult<String> {
        let mut tera = Tera::default();
        
        // Add the template to Tera
        let template_name = "pattern_template";
        tera.add_raw_template(template_name, &self.template_content)
            .map_err(|e| ParagonicError::InvalidInput(
                format!("Failed to parse template: {}", e)
            ))?;
        
        // Create Tera context from JSON
        let tera_context = Context::from_serialize(context)
            .map_err(|e| ParagonicError::InvalidInput(
                format!("Failed to create template context: {}", e)
            ))?;
        
        // Render the template
        Ok(tera.render(template_name, &tera_context)
            .map_err(|e| ParagonicError::InvalidInput(
                format!("Failed to render template: {}", e)
            ))?)
    }

    /// Validates the template syntax without rendering
    pub fn validate_syntax(&self) -> ParagonicResult<()> {
        let mut tera = Tera::default();
        
        // Try to add the template to Tera - this will fail if syntax is invalid
        let template_name = "validation_template";
        tera.add_raw_template(template_name, &self.template_content)
            .map_err(|e| ParagonicError::InvalidInput(
                format!("Invalid template syntax: {}", e)
            ))?;
        
        Ok(())
    }
}

/// Registry for managing system patterns
pub struct PatternRegistry {
    patterns: Vec<SystemPattern>,
    relationships: Vec<PatternRelationship>,
}

impl PatternRegistry {
    /// Creates a new empty PatternRegistry
    pub fn new() -> Self {
        Self {
            patterns: Vec::new(),
            relationships: Vec::new(),
        }
    }

    /// Registers a new system pattern
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

    /// Retrieves a system pattern by its ID
    pub fn get_pattern(&self, id: Uuid) -> Option<&SystemPattern> {
        self.patterns.iter().find(|p| p.id == id)
    }

    /// Retrieves a system pattern by its name
    pub fn get_pattern_by_name(&self, name: &str) -> Option<&SystemPattern> {
        self.patterns.iter().find(|p| p.name == name)
    }

    /// Lists all patterns with optional filtering
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

    /// Removes a pattern by its ID
    pub fn remove_pattern(&mut self, id: Uuid) -> ParagonicResult<()> {
        let initial_len = self.patterns.len();
        self.patterns.retain(|p| p.id != id);
        
        if self.patterns.len() == initial_len {
            return Err(ParagonicError::InvalidInput(
                format!("Pattern with id '{}' not found", id)
            ));
        }
        
        Ok(())
    }

    /// Adds a relationship between two patterns
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

    /// Removes a relationship by its ID
    pub fn remove_relationship(&mut self, id: Uuid) -> ParagonicResult<()> {
        let initial_len = self.relationships.len();
        self.relationships.retain(|r| r.id != id);
        
        if self.relationships.len() == initial_len {
            return Err(ParagonicError::InvalidInput(
                format!("Relationship with id '{}' not found", id)
            ));
        }
        
        Ok(())
    }

    /// Executes a pattern with the given context
    pub fn execute_pattern(&mut self, pattern_name: &str, context: Option<Value>) -> ParagonicResult<PatternExecution> {
        // Find the pattern by name
        let pattern = self.get_pattern_by_name(pattern_name)
            .ok_or_else(|| ParagonicError::InvalidInput(
                format!("Pattern '{}' not found", pattern_name)
            ))?;
        
        // Create a new execution
        let mut execution = PatternExecution::new(
            pattern.id,
            None, // session_id will be set by caller if needed
            TriggerType::Manual,
            context,
        )?;
        
        // Start execution
        execution.start_execution()?;
        
        // For now, we'll just mark it as completed with a basic result
        // In a full implementation, this would execute the actual pattern logic
        execution.complete_execution(
            true,
            Some(json!({
                "pattern_name": pattern_name,
                "executed_at": chrono::Utc::now().to_rfc3339(),
                "status": "completed"
            })),
            None
        )?;
        
        Ok(execution)
    }

    /// Returns execution history for a specific pattern
    pub fn get_execution_history(&self, pattern_name: &str) -> ParagonicResult<Vec<&PatternExecution>> {
        // Find the pattern by name
        let pattern = self.get_pattern_by_name(pattern_name)
            .ok_or_else(|| ParagonicError::InvalidInput(
                format!("Pattern '{}' not found", pattern_name)
            ))?;
        
        // For now, we'll return an empty vector since we don't store executions yet
        // In a full implementation, this would query a database or storage
        Ok(Vec::new())
    }

    /// Returns statistics for a specific pattern
    pub fn get_pattern_statistics(&self, pattern_name: &str) -> ParagonicResult<PatternStatistics> {
        // Find the pattern by name
        let _pattern = self.get_pattern_by_name(pattern_name)
            .ok_or_else(|| ParagonicError::InvalidInput(
                format!("Pattern '{}' not found", pattern_name)
            ))?;
        
        // For now, we'll return default statistics since we don't store executions yet
        // In a full implementation, this would calculate from execution history
        Ok(PatternStatistics {
            total_executions: 0,
            successful_executions: 0,
            failed_executions: 0,
            average_execution_time_ms: 0.0,
            last_executed: None,
            success_rate: 0.0,
        })
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct PatternStatistics {
    pub total_executions: u32,
    pub successful_executions: u32,
    pub failed_executions: u32,
    pub average_execution_time_ms: f64,
    pub last_executed: Option<DateTime<Utc>>,
    pub success_rate: f64,
}

/// Bootstrap loader for patterns from repository files
pub struct PatternBootstrap {
    patterns_dir: PathBuf,
}

impl PatternBootstrap {
    /// Creates a new PatternBootstrap instance
    pub fn new(patterns_dir: PathBuf) -> Self {
        Self { patterns_dir }
    }

    /// Load core patterns from repository files
    pub fn load_core_patterns(&self) -> ParagonicResult<Vec<SystemPattern>> {
        let core_patterns_file = self.patterns_dir.join("bootstrap/core_patterns.json");
        let content = std::fs::read_to_string(core_patterns_file)
            .map_err(|e| ParagonicError::InvalidInput(
                format!("Failed to read core patterns file: {}", e)
            ))?;
        
        let data: serde_json::Value = serde_json::from_str(&content)
            .map_err(|e| ParagonicError::InvalidInput(
                format!("Failed to parse core patterns JSON: {}", e)
            ))?;
        
        // Parse and validate patterns
        let patterns = self.parse_patterns(data)?;
        Ok(patterns)
    }

    /// Parse patterns from JSON data
    fn parse_patterns(&self, data: serde_json::Value) -> ParagonicResult<Vec<SystemPattern>> {
        let patterns_array = data.get("patterns")
            .ok_or_else(|| ParagonicError::InvalidInput(
                "Missing 'patterns' field in JSON data".to_string()
            ))?
            .as_array()
            .ok_or_else(|| ParagonicError::InvalidInput(
                "'patterns' field must be an array".to_string()
            ))?;
        
        let mut patterns = Vec::new();
        for pattern_data in patterns_array {
            let pattern = self.parse_single_pattern(pattern_data)?;
            patterns.push(pattern);
        }
        
        Ok(patterns)
    }

    /// Parse a single pattern from JSON data
    fn parse_single_pattern(&self, pattern_data: &serde_json::Value) -> ParagonicResult<SystemPattern> {
        let name = pattern_data.get("name")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ParagonicError::InvalidInput(
                "Pattern missing 'name' field".to_string()
            ))?
            .to_string();
        
        let category_str = pattern_data.get("category")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ParagonicError::InvalidInput(
                "Pattern missing 'category' field".to_string()
            ))?;
        
        let category = match category_str {
            "SessionManagement" => PatternCategory::SessionManagement,
            "SelfReflection" => PatternCategory::SelfReflection,
            "ContextSummarization" => PatternCategory::ContextSummarization,
            "ActivityLabeling" => PatternCategory::ActivityLabeling,
            "ProgressTracking" => PatternCategory::ProgressTracking,
            "KnowledgeExtraction" => PatternCategory::KnowledgeExtraction,
            _ => return Err(ParagonicError::InvalidInput(
                format!("Invalid category: {}", category_str)
            )),
        };
        
        let meta_level_str = pattern_data.get("meta_level")
            .and_then(|v| v.as_str())
            .unwrap_or("System");
        
        let meta_level = match meta_level_str {
            "System" => MetaLevel::System,
            "User" => MetaLevel::User,
            "Hybrid" => MetaLevel::Hybrid,
            _ => return Err(ParagonicError::InvalidInput(
                format!("Invalid meta_level: {}", meta_level_str)
            )),
        };
        
        let description = pattern_data.get("description")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ParagonicError::InvalidInput(
                "Pattern missing 'description' field".to_string()
            ))?
            .to_string();
        
        let workflow_steps = pattern_data.get("workflow_steps")
            .ok_or_else(|| ParagonicError::InvalidInput(
                "Pattern missing 'workflow_steps' field".to_string()
            ))?
            .clone();
        
        let output_format = pattern_data.get("output_format")
            .ok_or_else(|| ParagonicError::InvalidInput(
                "Pattern missing 'output_format' field".to_string()
            ))?
            .clone();
        
        let trigger_conditions = pattern_data.get("trigger_conditions").cloned();
        let success_criteria = pattern_data.get("success_criteria").cloned();
        
        SystemPattern::new(
            name,
            category,
            meta_level,
            description,
            workflow_steps,
            output_format,
            trigger_conditions,
            success_criteria,
        )
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

    #[test]
    fn test_pattern_relationship_creation_with_valid_data() {
        let source_id = Uuid::new_v4();
        let target_id = Uuid::new_v4();
        let relationship = PatternRelationship::new(
            source_id,
            target_id,
            RelationshipType::DependsOn,
            "Test relationship description".to_string(),
            0.8,
        ).unwrap();
        
        assert_eq!(relationship.source_pattern_id, source_id);
        assert_eq!(relationship.target_pattern_id, target_id);
        assert_eq!(relationship.relationship_type, RelationshipType::DependsOn);
        assert!(!relationship.description.is_empty());
        assert!(relationship.strength >= 0.0 && relationship.strength <= 1.0);
    }

    #[test]
    fn test_pattern_relationship_creation_with_same_ids() {
        let source_id = Uuid::new_v4();
        let result = PatternRelationship::new(
            source_id,
            source_id,
            RelationshipType::DependsOn,
            "Self-dependency is not allowed".to_string(),
            0.5,
        );
        
        assert!(result.is_err());
        match result {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert_eq!(msg, "Source and target pattern IDs must be different");
            }
            _ => panic!("Expected InvalidInput error for same IDs"),
        }
    }

    #[test]
    fn test_pattern_relationship_creation_with_invalid_strength() {
        let source_id = Uuid::new_v4();
        let target_id = Uuid::new_v4();
        let result = PatternRelationship::new(
            source_id,
            target_id,
            RelationshipType::DependsOn,
            "Invalid strength".to_string(),
            1.5,
        );
        
        assert!(result.is_err());
        match result {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert_eq!(msg, "Strength must be between 0.0 and 1.0");
            }
            _ => panic!("Expected InvalidInput error for invalid strength"),
        }
    }

    #[test]
    fn test_pattern_relationship_creation_with_empty_description() {
        let source_id = Uuid::new_v4();
        let target_id = Uuid::new_v4();
        let result = PatternRelationship::new(
            source_id,
            target_id,
            RelationshipType::DependsOn,
            "".to_string(),
            0.7,
        );
        
        assert!(result.is_err());
        match result {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert_eq!(msg, "Description cannot be empty");
            }
            _ => panic!("Expected InvalidInput error for empty description"),
        }
    }

    #[test]
    fn test_pattern_template_creation_with_valid_data() {
        let template = PatternTemplate::new(
            "Test Template".to_string(),
            "This is a test template for pattern execution".to_string(),
            "{{ pattern_name }} - {{ session_id }}".to_string(),
        ).unwrap();

        assert_eq!(template.name, "Test Template");
        assert_eq!(template.description, "This is a test template for pattern execution");
        assert!(!template.template_content.is_empty());
    }

    #[test]
    fn test_pattern_template_creation_with_empty_name() {
        let result = PatternTemplate::new(
            "".to_string(),
            "Description".to_string(),
            "Content".to_string(),
        );

        assert!(result.is_err());
        match result {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert_eq!(msg, "Pattern template name cannot be empty");
            }
            _ => panic!("Expected InvalidInput error"),
        }
    }

    #[test]
    fn test_pattern_template_creation_with_empty_description() {
        let result = PatternTemplate::new(
            "Name".to_string(),
            "".to_string(),
            "Content".to_string(),
        );

        assert!(result.is_err());
        match result {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert_eq!(msg, "Pattern template description cannot be empty");
            }
            _ => panic!("Expected InvalidInput error"),
        }
    }

    #[test]
    fn test_pattern_template_creation_with_empty_content() {
        let result = PatternTemplate::new(
            "Name".to_string(),
            "Description".to_string(),
            "".to_string(),
        );

        assert!(result.is_err());
        match result {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert_eq!(msg, "Pattern template content cannot be empty");
            }
            _ => panic!("Expected InvalidInput error"),
        }
    }

    #[test]
    fn test_pattern_template_render() {
        let template = PatternTemplate::new(
            "Test Template".to_string(),
            "This is a test template for pattern execution".to_string(),
            "{{ pattern_name }} - {{ session_id }}".to_string(),
        ).unwrap();

        let context = json!({
            "pattern_name": "My Pattern",
            "session_id": "123e4567-e89b-12d3-a456-426614174000"
        });

        let rendered_output = template.render(&context).unwrap();
        assert_eq!(rendered_output, "My Pattern - 123e4567-e89b-12d3-a456-426614174000");
    }

    #[test]
    fn test_pattern_template_render_with_invalid_context() {
        let template = PatternTemplate::new(
            "Test Template".to_string(),
            "This is a test template for pattern execution".to_string(),
            "{{ pattern_name }} - {{ session_id }}".to_string(),
        ).unwrap();

        // Create an invalid context with a non-serializable value
        let context = json!({
            "pattern_name": "My Pattern",
            "session_id": null // This should work fine with Tera
        });

        // The test should pass since null is valid in Tera
        let result = template.render(&context);
        assert!(result.is_ok());
        let rendered = result.unwrap();
        assert_eq!(rendered, "My Pattern - ");
    }

    #[test]
    fn test_pattern_template_render_with_invalid_syntax() {
        let template = PatternTemplate::new(
            "Test Template".to_string(),
            "This is a test template with invalid syntax".to_string(),
            "{{ pattern_name } - {{ session_id }}".to_string(), // Missing closing brace
        ).unwrap();

        let context = json!({
            "pattern_name": "My Pattern",
            "session_id": "123e4567-e89b-12d3-a456-426614174000"
        });

        let result = template.render(&context);
        assert!(result.is_err());
        match result {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert!(msg.contains("Failed to parse template"));
            }
            _ => panic!("Expected InvalidInput error for invalid template syntax"),
        }
    }

    #[test]
    fn test_pattern_template_validate_syntax() {
        let template = PatternTemplate::new(
            "Valid Template".to_string(),
            "This template has valid syntax".to_string(),
            "{{ pattern_name }} - {{ session_id }}".to_string(),
        ).unwrap();

        let result = template.validate_syntax();
        assert!(result.is_ok());
    }

    #[test]
    fn test_pattern_template_validate_syntax_with_invalid_syntax() {
        let template = PatternTemplate::new(
            "Invalid Template".to_string(),
            "This template has invalid syntax".to_string(),
            "{{ pattern_name } - {{ session_id }}".to_string(), // Missing closing brace
        ).unwrap();

        let result = template.validate_syntax();
        assert!(result.is_err());
        match result {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert!(msg.contains("Invalid template syntax"));
            }
            _ => panic!("Expected InvalidInput error for invalid template syntax"),
        }
    }

    #[test]
    fn test_pattern_execution_start_execution() {
        let mut execution = PatternExecution::new(
            Uuid::new_v4(),
            Some(Uuid::new_v4()),
            TriggerType::Manual,
            Some(json!({"test": "data"})),
        ).unwrap();

        let result = execution.start_execution();
        assert!(result.is_ok());
        assert_eq!(execution.execution_duration_ms, Some(0));
    }

    #[test]
    fn test_pattern_execution_start_execution_already_started() {
        let mut execution = PatternExecution::new(
            Uuid::new_v4(),
            Some(Uuid::new_v4()),
            TriggerType::Manual,
            Some(json!({"test": "data"})),
        ).unwrap();

        // Start execution first time
        execution.start_execution().unwrap();
        
        // Try to start again
        let result = execution.start_execution();
        assert!(result.is_err());
        match result {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert_eq!(msg, "Execution is already in progress");
            }
            _ => panic!("Expected InvalidInput error for already started execution"),
        }
    }

    #[test]
    fn test_pattern_execution_start_execution_already_completed() {
        let mut execution = PatternExecution::new(
            Uuid::new_v4(),
            Some(Uuid::new_v4()),
            TriggerType::Manual,
            Some(json!({"test": "data"})),
        ).unwrap();

        // Mark as completed
        execution.success = true;
        
        // Try to start execution
        let result = execution.start_execution();
        assert!(result.is_err());
        match result {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert_eq!(msg, "Cannot start execution that is already completed");
            }
            _ => panic!("Expected InvalidInput error for completed execution"),
        }
    }

    #[test]
    fn test_pattern_execution_complete_execution_success() {
        let mut execution = PatternExecution::new(
            Uuid::new_v4(),
            Some(Uuid::new_v4()),
            TriggerType::Manual,
            Some(json!({"test": "data"})),
        ).unwrap();

        // Start execution
        execution.start_execution().unwrap();

        // Complete execution with success
        let result = execution.complete_execution(true, Some(json!({"result": "success"})), None);
        assert!(result.is_ok());
        assert_eq!(execution.success, true);
        assert!(execution.output_result.is_some());
        assert_eq!(execution.output_result.unwrap(), json!({"result": "success"}));
        assert!(execution.execution_duration_ms.is_some());
        assert_eq!(execution.execution_duration_ms.unwrap(), 100);
        assert!(execution.error_message.is_none());
    }

    #[test]
    fn test_pattern_execution_complete_execution_failure() {
        let mut execution = PatternExecution::new(
            Uuid::new_v4(),
            Some(Uuid::new_v4()),
            TriggerType::Manual,
            Some(json!({"test": "data"})),
        ).unwrap();

        // Start execution
        execution.start_execution().unwrap();

        // Complete execution with failure
        let result = execution.complete_execution(false, Some(json!({"result": "failure"})), Some("Error message".to_string()));
        assert!(result.is_ok());
        assert_eq!(execution.success, false);
        assert!(execution.output_result.is_some());
        assert_eq!(execution.output_result.unwrap(), json!({"result": "failure"}));
        assert!(execution.execution_duration_ms.is_some());
        assert_eq!(execution.execution_duration_ms.unwrap(), 100);
        assert!(execution.error_message.is_some());
        assert_eq!(execution.error_message.unwrap(), "Error message".to_string());
    }

    #[test]
    fn test_pattern_execution_complete_execution_not_started() {
        let mut execution = PatternExecution::new(
            Uuid::new_v4(),
            Some(Uuid::new_v4()),
            TriggerType::Manual,
            Some(json!({"test": "data"})),
        ).unwrap();

        // Try to complete execution without starting it first
        let result = execution.complete_execution(true, Some(json!({"result": "success"})), None);
        assert!(result.is_err());
        match result {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert_eq!(msg, "Cannot complete execution that has not been started");
            }
            _ => panic!("Expected InvalidInput error for not started execution"),
        }
    }

    #[test]
    fn test_pattern_execution_complete_execution_already_completed() {
        let mut execution = PatternExecution::new(
            Uuid::new_v4(),
            Some(Uuid::new_v4()),
            TriggerType::Manual,
            Some(json!({"test": "data"})),
        ).unwrap();

        // Start execution
        execution.start_execution().unwrap();
        // Complete execution
        execution.complete_execution(true, Some(json!({"result": "success"})), None).unwrap();

        // Try to complete again
        let result = execution.complete_execution(false, Some(json!({"result": "failure"})), Some("Error message".to_string()));
        assert!(result.is_err());
        match result {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert_eq!(msg, "Execution is already completed");
            }
            _ => panic!("Expected InvalidInput error for already completed execution"),
        }
    }

    #[test]
    fn test_pattern_execution_update_execution() {
        let mut execution = PatternExecution::new(
            Uuid::new_v4(),
            Some(Uuid::new_v4()),
            TriggerType::Manual,
            Some(json!({"test": "data"})),
        ).unwrap();

        // Start execution
        execution.start_execution().unwrap();

        // Update with intermediate results
        let result = execution.update_execution(
            Some(json!({"progress": "50%", "step": "processing"})),
            None
        );
        assert!(result.is_ok());
        assert!(execution.output_result.is_some());
        assert_eq!(execution.output_result.as_ref().unwrap(), &json!({"progress": "50%", "step": "processing"}));
        assert!(execution.error_message.is_none());

        // Update with error message
        let result = execution.update_execution(
            None,
            Some("Warning: Slow processing detected".to_string())
        );
        assert!(result.is_ok());
        assert!(execution.error_message.is_some());
        assert_eq!(execution.error_message.as_ref().unwrap(), "Warning: Slow processing detected");
    }

    #[test]
    fn test_pattern_execution_update_execution_not_started() {
        let mut execution = PatternExecution::new(
            Uuid::new_v4(),
            Some(Uuid::new_v4()),
            TriggerType::Manual,
            Some(json!({"test": "data"})),
        ).unwrap();

        // Try to update execution without starting it first
        let result = execution.update_execution(
            Some(json!({"progress": "50%"})),
            None
        );
        assert!(result.is_err());
        match result {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert_eq!(msg, "Cannot update execution that has not been started");
            }
            _ => panic!("Expected InvalidInput error for not started execution"),
        }
    }

    #[test]
    fn test_pattern_execution_update_execution_already_completed() {
        let mut execution = PatternExecution::new(
            Uuid::new_v4(),
            Some(Uuid::new_v4()),
            TriggerType::Manual,
            Some(json!({"test": "data"})),
        ).unwrap();

        // Start execution
        execution.start_execution().unwrap();
        // Complete execution
        execution.complete_execution(true, Some(json!({"result": "success"})), None).unwrap();

        // Try to update completed execution
        let result = execution.update_execution(
            Some(json!({"progress": "100%"})),
            None
        );
        assert!(result.is_err());
        match result {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert_eq!(msg, "Cannot update execution that is already completed");
            }
            _ => panic!("Expected InvalidInput error for completed execution"),
        }
    }

    #[test]
    fn test_pattern_execution_get_execution_status() {
        let mut execution = PatternExecution::new(
            Uuid::new_v4(),
            Some(Uuid::new_v4()),
            TriggerType::Manual,
            Some(json!({"test": "data"})),
        ).unwrap();

        assert_eq!(execution.get_execution_status(), ExecutionStatus::NotStarted);

        execution.start_execution().unwrap();
        assert_eq!(execution.get_execution_status(), ExecutionStatus::InProgress);

        execution.complete_execution(true, Some(json!({"result": "success"})), None).unwrap();
        assert_eq!(execution.get_execution_status(), ExecutionStatus::Completed);
    }

    #[test]
    fn test_pattern_registry_execute_pattern() {
        let mut registry = PatternRegistry::new();
        
        // Create and register a pattern
        let pattern = SystemPattern::new(
            "Test Pattern".to_string(),
            PatternCategory::SessionManagement,
            MetaLevel::System,
            "A test pattern for execution".to_string(),
            json!([{"step": "test", "action": "execute"}]),
            json!({"result": "string", "status": "boolean"}),
            None,
            None,
        ).unwrap();
        
        registry.register_pattern(pattern).unwrap();
        
        // Execute the pattern
        let context = json!({
            "user_id": "123",
            "session_data": {"key": "value"}
        });
        
        let result = registry.execute_pattern("Test Pattern", Some(context));
        assert!(result.is_ok());
        
        let execution = result.unwrap();
        assert_eq!(execution.get_execution_status(), ExecutionStatus::Completed);
        assert!(execution.success);
        assert!(execution.output_result.is_some());
        
        let output = execution.output_result.as_ref().unwrap();
        assert_eq!(output["pattern_name"], "Test Pattern");
        assert_eq!(output["status"], "completed");
    }

    #[test]
    fn test_pattern_registry_execute_nonexistent_pattern() {
        let mut registry = PatternRegistry::new();
        
        let result = registry.execute_pattern("Nonexistent Pattern", None);
        assert!(result.is_err());
        match result {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert!(msg.contains("Pattern 'Nonexistent Pattern' not found"));
            }
            _ => panic!("Expected InvalidInput error for nonexistent pattern"),
        }
    }

    #[test]
    fn test_pattern_registry_add_relationship() {
        let mut registry = PatternRegistry::new();
        
        // Create two patterns first
        let pattern1 = SystemPattern::new(
            "Source Pattern".to_string(),
            PatternCategory::SessionManagement,
            MetaLevel::System,
            "Source pattern for relationship".to_string(),
            json!([{"step": 1, "action": "source_action", "description": "source_desc"}]),
            json!({"summary": "source_summary"}),
            None,
            None,
        ).unwrap();
        
        let pattern2 = SystemPattern::new(
            "Target Pattern".to_string(),
            PatternCategory::SelfReflection,
            MetaLevel::User,
            "Target pattern for relationship".to_string(),
            json!([{"step": 1, "action": "target_action", "description": "target_desc"}]),
            json!({"summary": "target_summary"}),
            None,
            None,
        ).unwrap();
        
        registry.register_pattern(pattern1.clone()).unwrap();
        registry.register_pattern(pattern2.clone()).unwrap();
        
        // Create and add relationship
        let relationship = PatternRelationship::new(
            pattern1.id,
            pattern2.id,
            RelationshipType::DependsOn,
            "Source depends on target".to_string(),
            0.8,
        ).unwrap();
        
        let result = registry.add_relationship(relationship);
        assert!(result.is_ok());
        assert_eq!(registry.relationships.len(), 1);
    }

    #[test]
    fn test_pattern_registry_add_relationship_with_nonexistent_pattern() {
        let mut registry = PatternRegistry::new();
        
        // Create only one pattern
        let pattern1 = SystemPattern::new(
            "Source Pattern".to_string(),
            PatternCategory::SessionManagement,
            MetaLevel::System,
            "Source pattern for relationship".to_string(),
            json!([{"step": 1, "action": "source_action", "description": "source_desc"}]),
            json!({"summary": "source_summary"}),
            None,
            None,
        ).unwrap();
        
        registry.register_pattern(pattern1.clone()).unwrap();
        
        // Try to create relationship with non-existent target pattern
        let nonexistent_id = Uuid::new_v4();
        let relationship = PatternRelationship::new(
            pattern1.id,
            nonexistent_id,
            RelationshipType::DependsOn,
            "Source depends on non-existent target".to_string(),
            0.8,
        ).unwrap();
        
        let result = registry.add_relationship(relationship);
        assert!(result.is_err());
        match result {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert!(msg.contains("does not exist"));
            }
            _ => panic!("Expected InvalidInput error for non-existent pattern"),
        }
    }

    #[test]
    fn test_pattern_registry_remove_relationship() {
        let mut registry = PatternRegistry::new();
        
        // Create two patterns first
        let pattern1 = SystemPattern::new(
            "Source Pattern".to_string(),
            PatternCategory::SessionManagement,
            MetaLevel::System,
            "Source pattern for relationship".to_string(),
            json!([{"step": 1, "action": "source_action", "description": "source_desc"}]),
            json!({"summary": "source_summary"}),
            None,
            None,
        ).unwrap();
        
        let pattern2 = SystemPattern::new(
            "Target Pattern".to_string(),
            PatternCategory::SelfReflection,
            MetaLevel::User,
            "Target pattern for relationship".to_string(),
            json!([{"step": 1, "action": "target_action", "description": "target_desc"}]),
            json!({"summary": "target_summary"}),
            None,
            None,
        ).unwrap();
        
        registry.register_pattern(pattern1.clone()).unwrap();
        registry.register_pattern(pattern2.clone()).unwrap();
        
        // Create and add relationship
        let relationship = PatternRelationship::new(
            pattern1.id,
            pattern2.id,
            RelationshipType::DependsOn,
            "Source depends on target".to_string(),
            0.8,
        ).unwrap();
        
        registry.add_relationship(relationship.clone()).unwrap();
        assert_eq!(registry.relationships.len(), 1);
        
        // Remove the relationship
        let result = registry.remove_relationship(relationship.id);
        assert!(result.is_ok());
        assert_eq!(registry.relationships.len(), 0);
    }

    #[test]
    fn test_pattern_registry_remove_nonexistent_relationship() {
        let mut registry = PatternRegistry::new();
        let nonexistent_id = Uuid::new_v4();
        
        let result = registry.remove_relationship(nonexistent_id);
        assert!(result.is_err());
        match result {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert!(msg.contains("not found"));
            }
            _ => panic!("Expected InvalidInput error for non-existent relationship"),
        }
    }

    #[test]
    fn test_pattern_registry_creation() {
        let registry = PatternRegistry::new();
        assert_eq!(registry.patterns.len(), 0);
    }

    #[test]
    fn test_pattern_registry_register_pattern() {
        let mut registry = PatternRegistry::new();
        let pattern = SystemPattern::new(
            "Test Session Summary".to_string(),
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
        ).unwrap();
        
        let result = registry.register_pattern(pattern.clone());
        assert!(result.is_ok());
        assert_eq!(registry.patterns.len(), 1);
        
        let retrieved = registry.get_pattern(pattern.id);
        assert!(retrieved.is_some());
        assert_eq!(retrieved.unwrap().name, pattern.name);
    }

    #[test]
    fn test_pattern_registry_register_duplicate_pattern() {
        let mut registry = PatternRegistry::new();
        let pattern1 = SystemPattern::new(
            "Duplicate Pattern".to_string(),
            PatternCategory::SessionManagement,
            MetaLevel::System,
            "Description 1".to_string(),
            json!([{"step": 1, "action": "action1", "description": "desc1"}]),
            json!({"summary": "sum1"}),
            None,
            None,
        ).unwrap();
        let pattern2 = SystemPattern::new(
            "Duplicate Pattern".to_string(),
            PatternCategory::SessionManagement,
            MetaLevel::System,
            "Description 2".to_string(),
            json!([{"step": 1, "action": "action2", "description": "desc2"}]),
            json!({"summary": "sum2"}),
            None,
            None,
        ).unwrap();

        let result1 = registry.register_pattern(pattern1);
        assert!(result1.is_ok());

        let result2 = registry.register_pattern(pattern2);
        assert!(result2.is_err());
        match result2 {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert!(msg.contains("Duplicate Pattern"));
            }
            _ => panic!("Expected InvalidInput error for duplicate pattern"),
        }
    }

    #[test]
    fn test_pattern_registry_get_pattern_by_name() {
        let mut registry = PatternRegistry::new();
        let pattern = SystemPattern::new(
            "Test Pattern Name".to_string(),
            PatternCategory::SessionManagement,
            MetaLevel::System,
            "Test pattern description".to_string(),
            json!([{"step": 1, "action": "test_action", "description": "test_desc"}]),
            json!({"summary": "test_summary"}),
            None,
            None,
        ).unwrap();
        
        registry.register_pattern(pattern.clone()).unwrap();
        
        let retrieved = registry.get_pattern_by_name("Test Pattern Name");
        assert!(retrieved.is_some());
        assert_eq!(retrieved.unwrap().name, "Test Pattern Name");
        assert_eq!(retrieved.unwrap().description, "Test pattern description");
        
        let not_found = registry.get_pattern_by_name("Non-existent Pattern");
        assert!(not_found.is_none());
    }

    #[test]
    fn test_pattern_registry_list_patterns() {
        let mut registry = PatternRegistry::new();
        
        let pattern1 = SystemPattern::new(
            "Session Summary".to_string(),
            PatternCategory::SessionManagement,
            MetaLevel::System,
            "Session summary pattern".to_string(),
            json!([{"step": 1, "action": "summarize", "description": "Summarize session"}]),
            json!({"summary": "string"}),
            None,
            None,
        ).unwrap();
        
        let pattern2 = SystemPattern::new(
            "Activity Label".to_string(),
            PatternCategory::ActivityLabeling,
            MetaLevel::System,
            "Activity labeling pattern".to_string(),
            json!([{"step": 1, "action": "label", "description": "Label activity"}]),
            json!({"label": "string"}),
            None,
            None,
        ).unwrap();
        
        let pattern3 = SystemPattern::new(
            "User Reflection".to_string(),
            PatternCategory::SelfReflection,
            MetaLevel::User,
            "User reflection pattern".to_string(),
            json!([{"step": 1, "action": "reflect", "description": "User reflection"}]),
            json!({"reflection": "string"}),
            None,
            None,
        ).unwrap();
        
        registry.register_pattern(pattern1).unwrap();
        registry.register_pattern(pattern2).unwrap();
        registry.register_pattern(pattern3).unwrap();
        
        // Test listing all patterns
        let all_patterns = registry.list_patterns(None, None);
        assert_eq!(all_patterns.len(), 3);
        
        // Test filtering by category
        let session_patterns = registry.list_patterns(Some(PatternCategory::SessionManagement), None);
        assert_eq!(session_patterns.len(), 1);
        assert_eq!(session_patterns[0].name, "Session Summary");
        
        // Test filtering by meta_level
        let system_patterns = registry.list_patterns(None, Some(MetaLevel::System));
        assert_eq!(system_patterns.len(), 2);
        
        // Test filtering by both category and meta_level
        let user_reflection_patterns = registry.list_patterns(Some(PatternCategory::SelfReflection), Some(MetaLevel::User));
        assert_eq!(user_reflection_patterns.len(), 1);
        assert_eq!(user_reflection_patterns[0].name, "User Reflection");
    }

    #[test]
    fn test_pattern_registry_list_patterns_with_filtering() {
        let mut registry = PatternRegistry::new();
        
        let pattern1 = SystemPattern::new(
            "Session Pattern".to_string(),
            PatternCategory::SessionManagement,
            MetaLevel::System,
            "Session management pattern".to_string(),
            json!([{"step": 1, "action": "session_action", "description": "session_desc"}]),
            json!({"summary": "session_summary"}),
            None,
            None,
        ).unwrap();
        
        let pattern2 = SystemPattern::new(
            "Reflection Pattern".to_string(),
            PatternCategory::SelfReflection,
            MetaLevel::User,
            "Self reflection pattern".to_string(),
            json!([{"step": 1, "action": "reflection_action", "description": "reflection_desc"}]),
            json!({"summary": "reflection_summary"}),
            None,
            None,
        ).unwrap();
        
        registry.register_pattern(pattern1.clone()).unwrap();
        registry.register_pattern(pattern2.clone()).unwrap();
        
        // Test filtering by category
        let session_patterns = registry.list_patterns(Some(PatternCategory::SessionManagement), None);
        assert_eq!(session_patterns.len(), 1);
        assert_eq!(session_patterns[0].name, "Session Pattern");
        
        // Test filtering by meta level
        let system_patterns = registry.list_patterns(None, Some(MetaLevel::System));
        assert_eq!(system_patterns.len(), 1);
        assert_eq!(system_patterns[0].name, "Session Pattern");
        
        // Test filtering by both
        let filtered_patterns = registry.list_patterns(Some(PatternCategory::SelfReflection), Some(MetaLevel::User));
        assert_eq!(filtered_patterns.len(), 1);
        assert_eq!(filtered_patterns[0].name, "Reflection Pattern");
        
        // Test no filtering
        let all_patterns = registry.list_patterns(None, None);
        assert_eq!(all_patterns.len(), 2);
    }

    #[test]
    fn test_pattern_registry_remove_pattern() {
        let mut registry = PatternRegistry::new();
        let pattern = SystemPattern::new(
            "Pattern to Remove".to_string(),
            PatternCategory::SessionManagement,
            MetaLevel::System,
            "Pattern that will be removed".to_string(),
            json!([{"step": 1, "action": "remove_action", "description": "remove_desc"}]),
            json!({"summary": "remove_summary"}),
            None,
            None,
        ).unwrap();
        
        let pattern_id = pattern.id;
        registry.register_pattern(pattern).unwrap();
        assert_eq!(registry.patterns.len(), 1);
        
        let result = registry.remove_pattern(pattern_id);
        assert!(result.is_ok());
        assert_eq!(registry.patterns.len(), 0);
    }

    #[test]
    fn test_pattern_registry_remove_nonexistent_pattern() {
        let mut registry = PatternRegistry::new();
        let nonexistent_id = Uuid::new_v4();
        
        let result = registry.remove_pattern(nonexistent_id);
        assert!(result.is_err());
        match result {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert!(msg.contains("not found"));
            }
            _ => panic!("Expected InvalidInput error"),
        }
    }

    #[test]
    fn test_pattern_registry_get_execution_history() {
        let mut registry = PatternRegistry::new();
        
        // Create and register a pattern
        let pattern = SystemPattern::new(
            "Test Pattern".to_string(),
            PatternCategory::SessionManagement,
            MetaLevel::System,
            "A test pattern for execution history".to_string(),
            json!([{"step": "test", "action": "execute"}]),
            json!({"result": "string", "status": "boolean"}),
            None,
            None,
        ).unwrap();
        
        registry.register_pattern(pattern).unwrap();
        
        // Get execution history
        let result = registry.get_execution_history("Test Pattern");
        assert!(result.is_ok());
        
        let history = result.unwrap();
        assert_eq!(history.len(), 0); // Empty for now since we don't store executions yet
    }

    #[test]
    fn test_pattern_registry_get_execution_history_nonexistent_pattern() {
        let registry = PatternRegistry::new();
        
        let result = registry.get_execution_history("Nonexistent Pattern");
        assert!(result.is_err());
        match result {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert!(msg.contains("Pattern 'Nonexistent Pattern' not found"));
            }
            _ => panic!("Expected InvalidInput error for nonexistent pattern"),
        }
    }

    #[test]
    fn test_pattern_registry_get_pattern_statistics() {
        let mut registry = PatternRegistry::new();
        
        // Create and register a pattern
        let pattern = SystemPattern::new(
            "Test Pattern".to_string(),
            PatternCategory::SessionManagement,
            MetaLevel::System,
            "A test pattern for statistics".to_string(),
            json!([{"step": "test", "action": "execute"}]),
            json!({"result": "string", "status": "boolean"}),
            None,
            None,
        ).unwrap();
        
        registry.register_pattern(pattern).unwrap();
        
        // Get statistics for the pattern
        let result = registry.get_pattern_statistics("Test Pattern");
        assert!(result.is_ok());
        
        let stats = result.unwrap();
        assert_eq!(stats.total_executions, 0);
        assert_eq!(stats.successful_executions, 0);
        assert_eq!(stats.failed_executions, 0);
        assert_eq!(stats.average_execution_time_ms, 0.0);
        assert!(stats.last_executed.is_none());
        assert_eq!(stats.success_rate, 0.0);
    }

    #[test]
    fn test_pattern_registry_get_pattern_statistics_nonexistent_pattern() {
        let registry = PatternRegistry::new();
        
        let result = registry.get_pattern_statistics("Nonexistent Pattern");
        assert!(result.is_err());
        match result {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert!(msg.contains("Pattern 'Nonexistent Pattern' not found"));
            }
            _ => panic!("Expected InvalidInput error for nonexistent pattern"),
        }
    }

    #[test]
    fn test_pattern_bootstrap_new() {
        let patterns_dir = PathBuf::from("patterns");
        let bootstrap = PatternBootstrap::new(patterns_dir.clone());
        
        assert_eq!(bootstrap.patterns_dir, patterns_dir);
    }

    #[test]
    fn test_pattern_bootstrap_load_core_patterns() {
        let patterns_dir = PathBuf::from("patterns");
        let bootstrap = PatternBootstrap::new(patterns_dir);
        
        let result = bootstrap.load_core_patterns();
        assert!(result.is_ok());
        
        let patterns = result.unwrap();
        assert_eq!(patterns.len(), 1);
        
        let pattern = &patterns[0];
        assert_eq!(pattern.name, "Session Summary Generation");
        assert_eq!(pattern.category, PatternCategory::SessionManagement);
        assert_eq!(pattern.meta_level, MetaLevel::System);
        assert!(pattern.description.contains("comprehensive summary"));
    }

    #[test]
    fn test_pattern_bootstrap_load_core_patterns_missing_file() {
        let patterns_dir = PathBuf::from("nonexistent");
        let bootstrap = PatternBootstrap::new(patterns_dir);
        
        let result = bootstrap.load_core_patterns();
        assert!(result.is_err());
        match result {
            Err(ParagonicError::InvalidInput(msg)) => {
                assert!(msg.contains("Failed to read core patterns file"));
            }
            _ => panic!("Expected InvalidInput error for missing file"),
        }
    }
}
