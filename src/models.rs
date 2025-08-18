//! Data models for Paragonic
//!
//! This module defines the core data structures used throughout the application,
//! including projects, goals, tasks, agents, and conversations.

use crate::vector::Vector;
use chrono::{DateTime, Utc};
use diesel::prelude::*;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::schema::*;

/// Project model representing a high-level project
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable, Insertable)]
#[diesel(table_name = projects)]
pub struct Project {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
    pub organization_id: Option<Uuid>,
}

/// Goal model representing objectives within a project
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable, Insertable)]
#[diesel(table_name = goals)]
pub struct Goal {
    pub id: Uuid,
    pub project_id: Option<Uuid>,
    pub name: String,
    pub description: Option<String>,
    pub status: Option<String>, // Store as string in database, convert to enum in application
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

/// Goal status enumeration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum GoalStatus {
    Active,
    Completed,
    Paused,
    Cancelled,
}

/// Task model representing individual work items
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable, Insertable)]
#[diesel(table_name = tasks)]
pub struct Task {
    pub id: Uuid,
    pub goal_id: Option<Uuid>,
    pub name: String,
    pub description: Option<String>,
    pub status: Option<String>, // Store as string in database, convert to enum in application
    pub priority: Option<i32>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

/// Task status enumeration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum TaskStatus {
    Pending,
    InProgress,
    Completed,
    Blocked,
    Cancelled,
}

/// Agent model representing AI agents
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable, Insertable)]
#[diesel(table_name = agents)]
pub struct Agent {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub model_name: String,
    pub configuration: Option<serde_json::Value>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

/// Conversation model representing chat sessions
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable, Insertable)]
#[diesel(table_name = conversations)]
pub struct Conversation {
    pub id: Uuid,
    pub agent_id: Option<Uuid>,
    pub title: Option<String>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
    pub organization_id: Option<Uuid>,
}

/// Message model representing individual messages in conversations
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable, Insertable)]
#[diesel(table_name = messages)]
pub struct Message {
    pub id: Uuid,
    pub conversation_id: Option<Uuid>,
    pub role: String, // Store as string in database, convert to enum in application
    pub content: String,
    pub created_at: Option<DateTime<Utc>>,
}

/// Message role enumeration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum MessageRole {
    User,
    Assistant,
    System,
}

impl std::fmt::Display for MessageRole {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            MessageRole::User => write!(f, "user"),
            MessageRole::Assistant => write!(f, "assistant"),
            MessageRole::System => write!(f, "system"),
        }
    }
}

/// Request/Response models for API operations
///
/// Create project request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateProjectRequest {
    pub name: String,
    pub description: Option<String>,
    pub organization_id: Option<Uuid>,
}

/// Update project request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateProjectRequest {
    pub name: Option<String>,
    pub description: Option<String>,
}

/// Create goal request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateGoalRequest {
    pub project_id: Uuid,
    pub name: String,
    pub description: Option<String>,
}

/// Update goal request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateGoalRequest {
    pub name: Option<String>,
    pub description: Option<String>,
    pub status: Option<String>,
}

/// Create task request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateTaskRequest {
    pub goal_id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub priority: Option<i32>,
}

/// Update task request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateTaskRequest {
    pub name: Option<String>,
    pub description: Option<String>,
    pub status: Option<String>,
    pub priority: Option<i32>,
}

/// Create agent request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateAgentRequest {
    pub name: String,
    pub description: Option<String>,
    pub model_name: String,
    pub configuration: serde_json::Value,
}

/// Create conversation request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateConversationRequest {
    pub agent_id: Uuid,
    pub title: Option<String>,
    pub organization_id: Option<Uuid>,
}

/// Update conversation request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateConversationRequest {
    pub title: Option<String>,
}

/// Send message request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SendMessageRequest {
    pub conversation_id: Uuid,
    pub content: String,
}

/// Response models
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProjectResponse {
    pub project: Project,
    pub goals: Vec<Goal>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GoalResponse {
    pub goal: Goal,
    pub tasks: Vec<Task>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConversationResponse {
    pub conversation: Conversation,
    pub messages: Vec<Message>,
}

// Organizational Structure Models

/// Organization model representing distinct entities
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable)]
#[diesel(table_name = organizations)]
pub struct Organization {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub domain: Option<String>,
    pub industry: Option<String>,
    pub size: Option<String>,
    pub status: OrganizationStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Organization status enumeration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum OrganizationStatus {
    Active,
    Inactive,
    Pending,
    Suspended,
}

/// Person model representing human experts
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable)]
#[diesel(table_name = people)]
pub struct Person {
    pub id: Uuid,
    pub name: String,
    pub email: Option<String>,
    pub bio: Option<String>,
    pub expertise_areas: Option<Vec<String>>,
    pub location: Option<String>,
    pub timezone: Option<String>,
    pub availability_status: AvailabilityStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Availability status enumeration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum AvailabilityStatus {
    Available,
    Busy,
    Away,
    Unavailable,
}

/// ISRL Profile model for learning and expertise tracking
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable)]
#[diesel(table_name = isrl_profiles)]
pub struct IsrlProfile {
    pub id: Uuid,
    pub person_id: Uuid,
    pub skill_name: String,
    pub skill_category: Option<String>,
    pub proficiency_level: i32,
    pub last_reviewed: DateTime<Utc>,
    pub next_review: Option<DateTime<Utc>>,
    pub review_interval_days: i32,
    pub total_reviews: i32,
    pub success_rate: rust_decimal::Decimal,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Association model for managing relationships
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable)]
#[diesel(table_name = associations)]
pub struct Association {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub person_id: Option<Uuid>,
    pub agent_id: Option<Uuid>,
    pub role: String,
    pub permissions: Option<serde_json::Value>,
    pub start_date: Option<chrono::NaiveDate>,
    pub end_date: Option<chrono::NaiveDate>,
    pub status: AssociationStatus,
    pub allocation_percentage: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Association status enumeration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum AssociationStatus {
    Active,
    Inactive,
    Pending,
    Terminated,
}

/// Organization Hierarchy model for parent-child relationships
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable)]
#[diesel(table_name = organization_hierarchies)]
pub struct OrganizationHierarchy {
    pub id: Uuid,
    pub parent_organization_id: Uuid,
    pub child_organization_id: Uuid,
    pub relationship_type: OrganizationRelationshipType,
    pub created_at: DateTime<Utc>,
}

/// Organizational relationship type enumeration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum OrganizationRelationshipType {
    Subsidiary,
    Division,
    Project,
    Department,
    Team,
}

/// Embedding model for storing vector representations
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Embedding {
    pub id: Uuid,
    pub content_type: String,
    pub content_id: Uuid,
    pub content_text: String,
    pub embedding_model: String,
    pub embedding_vector: Option<Vector>,
    pub metadata: Option<serde_json::Value>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Create embedding request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateEmbeddingRequest {
    pub content_type: String,
    pub content_id: Uuid,
    pub content_text: String,
    pub embedding_model: String,
    pub metadata: Option<serde_json::Value>,
}

/// Search embeddings request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchEmbeddingsRequest {
    pub query_text: String,
    pub embedding_model: String,
    pub content_types: Option<Vec<String>>,
    pub limit: Option<i32>,
    pub similarity_threshold: Option<f32>,
}

/// Search result with similarity score
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EmbeddingSearchResult {
    pub embedding: Embedding,
    pub similarity_score: f32,
}

// Temporarily commented out IRAGL models until Vector type issues are resolved
/*
/// Knowledge stream model for storing ingested content
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Insertable, Identifiable)]
#[diesel(table_name = knowledge_streams)]
pub struct KnowledgeStream {
    pub id: Uuid,
    pub content_type: String,
    pub content_text: String,
    pub source_entity_type: String,
    pub source_entity_id: Uuid,
    pub metadata: Option<Value>,
    pub embedding_vector: Option<Vector>,
    pub embedding_model: String,
    pub optimization_status: Option<String>,
    pub optimization_score: Option<f64>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

/// New knowledge stream for insertion (without id and timestamps)
#[derive(Debug, Clone, Serialize, Deserialize, Insertable)]
#[diesel(table_name = knowledge_streams)]
pub struct NewKnowledgeStream {
    pub content_type: String,
    pub content_text: String,
    pub source_entity_type: String,
    pub source_entity_id: Uuid,
    pub metadata: Option<Value>,
    pub embedding_vector: Option<Vector>,
    pub embedding_model: String,
    pub optimization_status: Option<String>,
    pub optimization_score: Option<f64>,
}

/// Content association model for linking content to organizational entities
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Insertable, Identifiable)]
#[diesel(table_name = content_associations)]
pub struct ContentAssociation {
    pub id: Uuid,
    pub content_id: Uuid,
    pub entity_type: String,
    pub entity_id: Uuid,
    pub association_strength: Option<f64>,
    pub association_type: Option<String>,
    pub confidence_score: Option<f64>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

/// New content association for insertion (without id and timestamps)
#[derive(Debug, Clone, Serialize, Deserialize, Insertable)]
#[diesel(table_name = content_associations)]
pub struct NewContentAssociation {
    pub content_id: Uuid,
    pub entity_type: String,
    pub entity_id: Uuid,
    pub association_strength: Option<f64>,
    pub association_type: Option<String>,
    pub confidence_score: Option<f64>,
}

/// Optimization history model for tracking optimization runs
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Insertable, Identifiable)]
#[diesel(table_name = optimization_history)]
pub struct OptimizationHistory {
    pub id: Uuid,
    pub optimization_type: String,
    pub content_count: i32,
    pub performance_improvement: Option<f64>,
    pub duration_ms: i32,
    pub success: bool,
    pub error_message: Option<String>,
    pub metadata: Option<Value>,
    pub created_at: Option<DateTime<Utc>>,
}

/// New optimization history for insertion (without id and timestamp)
#[derive(Debug, Clone, Serialize, Deserialize, Insertable)]
#[diesel(table_name = optimization_history)]
pub struct NewOptimizationHistory {
    pub optimization_type: String,
    pub content_count: i32,
    pub performance_improvement: Option<f64>,
    pub duration_ms: i32,
    pub success: bool,
    pub error_message: Option<String>,
    pub metadata: Option<Value>,
}

/// Query analytics model for tracking search queries
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Insertable, Identifiable)]
#[diesel(table_name = query_analytics)]
pub struct QueryAnalytics {
    pub id: Uuid,
    pub query_text: String,
    pub query_context: Option<Value>,
    pub result_count: i32,
    pub response_time_ms: i32,
    pub user_satisfaction_score: Option<f64>,
    pub optimization_impact: Option<f64>,
    pub created_at: Option<DateTime<Utc>>,
}

/// New query analytics for insertion (without id and timestamp)
#[derive(Debug, Clone, Serialize, Deserialize, Insertable)]
#[diesel(table_name = query_analytics)]
pub struct NewQueryAnalytics {
    pub query_text: String,
    pub query_context: Option<Value>,
    pub result_count: i32,
    pub response_time_ms: i32,
    pub user_satisfaction_score: Option<f64>,
    pub optimization_impact: Option<f64>,
}

/// Knowledge metrics model for aggregated metrics
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Insertable, Identifiable)]
#[diesel(table_name = knowledge_metrics)]
pub struct KnowledgeMetrics {
    pub id: Uuid,
    pub metric_name: String,
    pub metric_value: f64,
    pub metric_unit: Option<String>,
    pub time_period: String,
    pub period_start: DateTime<Utc>,
    pub period_end: DateTime<Utc>,
    pub metadata: Option<Value>,
    pub created_at: Option<DateTime<Utc>>,
}

/// New knowledge metrics for insertion (without id and timestamp)
#[derive(Debug, Clone, Serialize, Deserialize, Insertable)]
#[diesel(table_name = knowledge_metrics)]
pub struct NewKnowledgeMetrics {
    pub metric_name: String,
    pub metric_value: f64,
    pub metric_unit: Option<String>,
    pub time_period: String,
    pub period_start: DateTime<Utc>,
    pub period_end: DateTime<Utc>,
    pub metadata: Option<Value>,
}
*/

// ============================================================================
// Pattern System Models
// ============================================================================

/// System pattern model representing a pattern for AI agent self-awareness
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable, Insertable)]
#[diesel(table_name = system_patterns)]
pub struct SystemPattern {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub pattern_type: String,
    pub template_content: String,
    pub execution_conditions: Option<serde_json::Value>,
    pub metadata: Option<serde_json::Value>,
    pub is_active: Option<bool>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

/// Pattern execution model representing the execution history of patterns
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable, Insertable)]
#[diesel(table_name = pattern_executions)]
pub struct PatternExecution {
    pub id: Uuid,
    pub pattern_id: Uuid,
    pub session_id: Option<Uuid>,
    pub execution_status: String,
    pub input_data: Option<serde_json::Value>,
    pub output_data: Option<serde_json::Value>,
    pub error_message: Option<String>,
    pub execution_time_ms: Option<i32>,
    pub started_at: Option<DateTime<Utc>>,
    pub completed_at: Option<DateTime<Utc>>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

/// Pattern relationship model representing relationships between patterns
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable, Insertable)]
#[diesel(table_name = pattern_relationships)]
pub struct PatternRelationship {
    pub id: Uuid,
    pub source_pattern_id: Uuid,
    pub target_pattern_id: Uuid,
    pub relationship_type: String, // Stored as string in database
    pub relationship_strength: Option<f64>,
    pub metadata: Option<serde_json::Value>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

impl PatternRelationship {
    pub fn get_relationship_type(&self) -> Option<PatternRelationshipType> {
        PatternRelationshipType::from_str(&self.relationship_type)
    }

    pub fn set_relationship_type(&mut self, relationship_type: PatternRelationshipType) {
        self.relationship_type = relationship_type.as_str().to_string();
    }
}

/// Tool pattern mapping model representing mappings between MCP tools and patterns
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable, Insertable)]
#[diesel(table_name = tool_pattern_mappings)]
pub struct ToolPatternMapping {
    pub id: Uuid,
    pub tool_name: String,
    pub pattern_id: Uuid,
    pub mapping_type: String,
    pub usage_frequency: Option<i32>,
    pub success_rate: Option<f64>,
    pub metadata: Option<serde_json::Value>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

/// Pattern learning metrics model representing learning data for patterns
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable, Insertable)]
#[diesel(table_name = pattern_learning_metrics)]
pub struct PatternLearningMetrics {
    pub id: Uuid,
    pub pattern_id: Uuid,
    pub metric_name: String,
    pub metric_value: f64,
    pub metric_unit: Option<String>,
    pub time_period: String,
    pub period_start: DateTime<Utc>,
    pub period_end: DateTime<Utc>,
    pub metadata: Option<serde_json::Value>,
    pub created_at: Option<DateTime<Utc>>,
}

/// AI Agent Session model with pattern-related fields
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable, Insertable)]
#[diesel(table_name = ai_agent_sessions)]
pub struct AiAgentSession {
    pub id: Uuid,
    pub session_name: Option<String>,
    pub session_type: Option<String>,
    pub active_patterns: Option<serde_json::Value>,
    pub pattern_execution_history: Option<serde_json::Value>,
    pub last_pattern_execution: Option<DateTime<Utc>>,
    pub pattern_learning_enabled: Option<bool>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

// ============================================================================
// Pattern System Enums
// ============================================================================

/// Pattern type enumeration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum PatternType {
    SessionSummary,
    ActivityLabeling,
    SelfReflection,
    ContextCondensation,
    ProgressTracking,
    KnowledgeExtraction,
}

/// Execution status enumeration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ExecutionStatus {
    Pending,
    Running,
    Completed,
    Failed,
    Cancelled,
}

/// Pattern relationship type enumeration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum PatternRelationshipType {
    DependsOn,
    Triggers,
    Enhances,
    Conflicts,
    Replaces,
}

impl PatternRelationshipType {
    pub fn as_str(&self) -> &'static str {
        match self {
            PatternRelationshipType::DependsOn => "depends_on",
            PatternRelationshipType::Triggers => "triggers",
            PatternRelationshipType::Enhances => "enhances",
            PatternRelationshipType::Conflicts => "conflicts",
            PatternRelationshipType::Replaces => "replaces",
        }
    }

    pub fn from_str(s: &str) -> Option<Self> {
        match s {
            "depends_on" => Some(PatternRelationshipType::DependsOn),
            "triggers" => Some(PatternRelationshipType::Triggers),
            "enhances" => Some(PatternRelationshipType::Enhances),
            "conflicts" => Some(PatternRelationshipType::Conflicts),
            "replaces" => Some(PatternRelationshipType::Replaces),
            _ => None,
        }
    }
}

/// Mapping type enumeration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum MappingType {
    Input,
    Output,
    Trigger,
    Enhance,
    Validate,
}

// ============================================================================
// Pattern System Request/Response Models
// ============================================================================

/// Request to create a new system pattern
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateSystemPatternRequest {
    pub name: String,
    pub description: Option<String>,
    pub pattern_type: String,
    pub template_content: String,
    pub execution_conditions: Option<serde_json::Value>,
    pub metadata: Option<serde_json::Value>,
    pub is_active: Option<bool>,
}

/// Request to update a system pattern
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateSystemPatternRequest {
    pub name: Option<String>,
    pub description: Option<String>,
    pub pattern_type: Option<String>,
    pub template_content: Option<String>,
    pub execution_conditions: Option<serde_json::Value>,
    pub metadata: Option<serde_json::Value>,
    pub is_active: Option<bool>,
}

/// Request to create a pattern execution
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreatePatternExecutionRequest {
    pub pattern_id: Uuid,
    pub session_id: Option<Uuid>,
    pub input_data: Option<serde_json::Value>,
}

/// Request to update a pattern execution
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdatePatternExecutionRequest {
    pub execution_status: Option<String>,
    pub output_data: Option<serde_json::Value>,
    pub error_message: Option<String>,
    pub execution_time_ms: Option<i32>,
    pub completed_at: Option<DateTime<Utc>>,
}

/// Request to create a pattern relationship
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreatePatternRelationshipRequest {
    pub source_pattern_id: Uuid,
    pub target_pattern_id: Uuid,
    pub relationship_type: PatternRelationshipType,
    pub relationship_strength: Option<f64>,
    pub metadata: Option<serde_json::Value>,
}

impl CreatePatternRelationshipRequest {
    pub fn to_pattern_relationship(&self) -> PatternRelationship {
        PatternRelationship {
            id: Uuid::new_v4(),
            source_pattern_id: self.source_pattern_id,
            target_pattern_id: self.target_pattern_id,
            relationship_type: self.relationship_type.as_str().to_string(),
            relationship_strength: self.relationship_strength,
            metadata: self.metadata.clone(),
            created_at: Some(Utc::now()),
            updated_at: Some(Utc::now()),
        }
    }
}

/// Request to create a tool pattern mapping
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateToolPatternMappingRequest {
    pub tool_name: String,
    pub pattern_id: Uuid,
    pub mapping_type: String,
    pub usage_frequency: Option<i32>,
    pub success_rate: Option<f64>,
    pub metadata: Option<serde_json::Value>,
}

/// Request to create pattern learning metrics
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreatePatternLearningMetricsRequest {
    pub pattern_id: Uuid,
    pub metric_name: String,
    pub metric_value: f64,
    pub metric_unit: Option<String>,
    pub time_period: String,
    pub period_start: DateTime<Utc>,
    pub period_end: DateTime<Utc>,
    pub metadata: Option<serde_json::Value>,
}

/// Response containing a system pattern with its relationships
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SystemPatternResponse {
    pub pattern: SystemPattern,
    pub relationships: Vec<PatternRelationship>,
    pub tool_mappings: Vec<ToolPatternMapping>,
    pub recent_executions: Vec<PatternExecution>,
}

/// Response containing pattern execution with pattern details
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PatternExecutionResponse {
    pub execution: PatternExecution,
    pub pattern: SystemPattern,
}

/// Response containing pattern learning metrics
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PatternLearningMetricsResponse {
    pub metrics: Vec<PatternLearningMetrics>,
    pub pattern: SystemPattern,
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Test project creation
    #[test]
    fn test_project_creation() {
        let project = Project {
            id: Uuid::new_v4(),
            name: "Test Project".to_string(),
            description: Some("A test project".to_string()),
            created_at: Some(Utc::now()),
            updated_at: Some(Utc::now()),
            organization_id: None,
        };

        assert_eq!(project.name, "Test Project");
        assert_eq!(project.description, Some("A test project".to_string()));
    }

    /// Test goal status serialization
    #[test]
    fn test_goal_status_serialization() {
        let status = GoalStatus::Active;
        let serialized = serde_json::to_string(&status).unwrap();
        assert_eq!(serialized, "\"active\"");

        let deserialized: GoalStatus = serde_json::from_str(&serialized).unwrap();
        matches!(deserialized, GoalStatus::Active);
    }

    /// Test task priority
    #[test]
    fn test_task_priority() {
        let task = Task {
            id: Uuid::new_v4(),
            goal_id: Some(Uuid::new_v4()),
            name: "Test Task".to_string(),
            description: None,
            status: Some("pending".to_string()),
            priority: Some(5),
            created_at: Some(Utc::now()),
            updated_at: Some(Utc::now()),
        };

        assert_eq!(task.priority, Some(5));
        assert_eq!(task.status, Some("pending".to_string()));
    }

    /// Test message role
    #[test]
    fn test_message_role() {
        let message = Message {
            id: Uuid::new_v4(),
            conversation_id: Some(Uuid::new_v4()),
            role: MessageRole::User.to_string(),
            content: "Hello, world!".to_string(),
            created_at: Some(Utc::now()),
        };

        assert_eq!(message.role, MessageRole::User.to_string());
        assert_eq!(message.content, "Hello, world!");
    }

    /// Test create project request
    #[test]
    fn test_create_project_request() {
        let request = CreateProjectRequest {
            name: "New Project".to_string(),
            description: Some("A new project".to_string()),
            organization_id: None,
        };

        assert_eq!(request.name, "New Project");
        assert_eq!(request.description, Some("A new project".to_string()));
        assert_eq!(request.organization_id, None);
    }

    /// Test organization creation
    #[test]
    fn test_organization_creation() {
        let org = Organization {
            id: Uuid::new_v4(),
            name: "Test Organization".to_string(),
            description: Some("A test organization".to_string()),
            domain: Some("test.com".to_string()),
            industry: Some("Technology".to_string()),
            size: Some("Medium".to_string()),
            status: OrganizationStatus::Active,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };

        assert_eq!(org.name, "Test Organization");
        assert_eq!(org.domain, Some("test.com".to_string()));
        matches!(org.status, OrganizationStatus::Active);
    }

    /// Test person creation
    #[test]
    fn test_person_creation() {
        let person = Person {
            id: Uuid::new_v4(),
            name: "John Doe".to_string(),
            email: Some("john@example.com".to_string()),
            bio: Some("Expert developer".to_string()),
            expertise_areas: Some(vec!["Rust".to_string(), "AI".to_string()]),
            location: Some("San Francisco".to_string()),
            timezone: Some("PST".to_string()),
            availability_status: AvailabilityStatus::Available,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };

        assert_eq!(person.name, "John Doe");
        assert_eq!(person.email, Some("john@example.com".to_string()));
        assert_eq!(
            person.expertise_areas,
            Some(vec!["Rust".to_string(), "AI".to_string()])
        );
        matches!(person.availability_status, AvailabilityStatus::Available);
    }

    /// Test ISRL profile creation
    #[test]
    fn test_isrl_profile_creation() {
        use rust_decimal::Decimal;

        let profile = IsrlProfile {
            id: Uuid::new_v4(),
            person_id: Uuid::new_v4(),
            skill_name: "Rust Programming".to_string(),
            skill_category: Some("Programming".to_string()),
            proficiency_level: 7,
            last_reviewed: Utc::now(),
            next_review: Some(Utc::now() + chrono::Duration::days(30)),
            review_interval_days: 30,
            total_reviews: 15,
            success_rate: Decimal::new(85, 2), // 0.85
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };

        assert_eq!(profile.skill_name, "Rust Programming");
        assert_eq!(profile.proficiency_level, 7);
        assert_eq!(profile.success_rate, Decimal::new(85, 2));
    }

    /// Test association creation
    #[test]
    fn test_association_creation() {
        let association = Association {
            id: Uuid::new_v4(),
            organization_id: Uuid::new_v4(),
            person_id: Some(Uuid::new_v4()),
            agent_id: None,
            role: "Senior Developer".to_string(),
            permissions: Some(serde_json::json!({"read": true, "write": true})),
            start_date: Some(chrono::NaiveDate::from_ymd_opt(2025, 1, 1).unwrap()),
            end_date: None,
            status: AssociationStatus::Active,
            allocation_percentage: 75,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };

        assert_eq!(association.role, "Senior Developer");
        assert_eq!(association.allocation_percentage, 75);
        assert!(association.person_id.is_some());
        assert!(association.agent_id.is_none());
        matches!(association.status, AssociationStatus::Active);
    }

    /// Test embedding creation
    #[test]
    fn test_embedding_creation() {
        let embedding = Embedding {
            id: Uuid::new_v4(),
            content_type: "message".to_string(),
            content_id: Uuid::new_v4(),
            content_text: "Hello, world!".to_string(),
            embedding_model: "nomic-embed-text".to_string(),
            embedding_vector: Some(Vector::new(vec![0.0, 0.0])), // 2 f32 values
            metadata: Some(serde_json::json!({"conversation_id": "123"})),
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };

        assert_eq!(embedding.content_type, "message");
        assert_eq!(embedding.content_text, "Hello, world!");
        assert_eq!(embedding.embedding_model, "nomic-embed-text");
        assert_eq!(embedding.embedding_vector.as_ref().unwrap().values.len(), 2);
        assert!(embedding.metadata.is_some());
    }
}
