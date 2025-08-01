//! Data models for Paragonic
//! 
//! This module defines the core data structures used throughout the application,
//! including projects, goals, tasks, agents, and conversations.

use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;
use chrono::{DateTime, Utc};

/// Project model representing a high-level project
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Project {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Goal model representing objectives within a project
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
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
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "VARCHAR", rename_all = "lowercase")]
#[serde(rename_all = "lowercase")]
pub enum GoalStatus {
    Active,
    Completed,
    Paused,
    Cancelled,
}

/// Task model representing individual work items
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
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
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "VARCHAR", rename_all = "lowercase")]
#[serde(rename_all = "lowercase")]
pub enum TaskStatus {
    Pending,
    InProgress,
    Completed,
    Blocked,
    Cancelled,
}

/// Agent model representing AI agents
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
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
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Conversation {
    pub id: Uuid,
    pub agent_id: Uuid,
    pub title: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Message model representing individual messages in conversations
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Message {
    pub id: Uuid,
    pub conversation_id: Uuid,
    pub role: MessageRole,
    pub content: String,
    pub created_at: DateTime<Utc>,
}

/// Message role enumeration
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "VARCHAR", rename_all = "lowercase")]
#[serde(rename_all = "lowercase")]
pub enum MessageRole {
    User,
    Assistant,
    System,
}

/// Request/Response models for API operations

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
} 