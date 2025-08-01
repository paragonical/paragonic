//! Data models for Paragonic
//! 
//! This module defines the core data structures used throughout the application,
//! including projects, goals, tasks, agents, and conversations.

use serde::{Deserialize, Serialize};
use diesel::prelude::*;
use uuid::Uuid;
use chrono::{DateTime, Utc};

use crate::schema::*;

/// Project model representing a high-level project
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable)]
#[diesel(table_name = projects)]
pub struct Project {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Goal model representing objectives within a project
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable)]
#[diesel(table_name = goals)]
pub struct Goal {
    pub id: Uuid,
    pub project_id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub status: GoalStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
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
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable)]
#[diesel(table_name = tasks)]
pub struct Task {
    pub id: Uuid,
    pub goal_id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub status: TaskStatus,
    pub priority: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
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
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable)]
#[diesel(table_name = agents)]
pub struct Agent {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub model_name: String,
    pub configuration: serde_json::Value,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Conversation model representing chat sessions
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable)]
#[diesel(table_name = conversations)]
pub struct Conversation {
    pub id: Uuid,
    pub agent_id: Uuid,
    pub title: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Message model representing individual messages in conversations
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable)]
#[diesel(table_name = messages)]
pub struct Message {
    pub id: Uuid,
    pub conversation_id: Uuid,
    pub role: MessageRole,
    pub content: String,
    pub created_at: DateTime<Utc>,
}

/// Message role enumeration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum MessageRole {
    User,
    Assistant,
    System,
}

/// Request/Response models for API operations
///
/// Create project request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateProjectRequest {
    pub name: String,
    pub description: Option<String>,
}

/// Create goal request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateGoalRequest {
    pub project_id: Uuid,
    pub name: String,
    pub description: Option<String>,
}

/// Create task request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateTaskRequest {
    pub goal_id: Uuid,
    pub name: String,
    pub description: Option<String>,
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
    pub relationship_type: RelationshipType,
    pub created_at: DateTime<Utc>,
}

/// Relationship type enumeration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum RelationshipType {
    Subsidiary,
    Division,
    Project,
    Department,
    Team,
}

/// Embedding model for storing vector representations
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Selectable, Insertable)]
#[diesel(table_name = embeddings)]
pub struct Embedding {
    pub id: Uuid,
    pub content_type: String,
    pub content_id: Uuid,
    pub content_text: String,
    pub embedding_model: String,
    pub embedding_vector: Option<Vec<u8>>,
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
            created_at: Utc::now(),
            updated_at: Utc::now(),
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
            goal_id: Uuid::new_v4(),
            name: "Test Task".to_string(),
            description: None,
            status: TaskStatus::Pending,
            priority: 5,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };
        
        assert_eq!(task.priority, 5);
        matches!(task.status, TaskStatus::Pending);
    }

    /// Test message role
    #[test]
    fn test_message_role() {
        let message = Message {
            id: Uuid::new_v4(),
            conversation_id: Uuid::new_v4(),
            role: MessageRole::User,
            content: "Hello, world!".to_string(),
            created_at: Utc::now(),
        };
        
        matches!(message.role, MessageRole::User);
        assert_eq!(message.content, "Hello, world!");
    }

    /// Test create project request
    #[test]
    fn test_create_project_request() {
        let request = CreateProjectRequest {
            name: "New Project".to_string(),
            description: Some("A new project".to_string()),
        };
        
        assert_eq!(request.name, "New Project");
        assert_eq!(request.description, Some("A new project".to_string()));
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
        assert_eq!(person.expertise_areas, Some(vec!["Rust".to_string(), "AI".to_string()]));
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
            embedding_vector: Some(vec![0, 0, 0, 0, 0, 0, 0, 0]), // 2 f32 values as bytes
            metadata: Some(serde_json::json!({"conversation_id": "123"})),
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };
        
        assert_eq!(embedding.content_type, "message");
        assert_eq!(embedding.content_text, "Hello, world!");
        assert_eq!(embedding.embedding_model, "nomic-embed-text");
        assert_eq!(embedding.embedding_vector.as_ref().unwrap().len(), 8);
        assert!(embedding.metadata.is_some());
    }
} 