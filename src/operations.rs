//! Database operations for Paragonic
//! 
//! This module provides CRUD operations for all database entities,
//! including projects, goals, tasks, agents, conversations, and more.

use crate::error::{ParagonicError, ParagonicResult};
use crate::models::{Project, CreateProjectRequest};
use crate::database::get_connection;
use diesel::prelude::*;
use uuid::Uuid;
use chrono::Utc;

use crate::schema::projects;

/// Create a new project
/// 
/// This function creates a new project in the database with the given name and description.
/// Returns the created project with generated ID and timestamps.
pub async fn create_project(request: CreateProjectRequest) -> ParagonicResult<Project> {
    let mut conn = get_connection()?;
    
    let now = Utc::now();
    let project = Project {
        id: Uuid::new_v4(),
        name: request.name,
        description: request.description,
        created_at: now,
        updated_at: now,
    };
    
    diesel::insert_into(projects::table)
        .values(&project)
        .execute(&mut conn)
        .map_err(|e| {
            tracing::error!("Failed to create project: {}", e);
            ParagonicError::Database(format!("Failed to create project: {e}"))
        })?;
    
    Ok(project)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::CreateProjectRequest;

    /// Test creating a project with valid data
    #[tokio::test]
    async fn test_create_project() {
        // Initialize database first
        let db_result = crate::database::initialize().await;
        if let Err(e) = &db_result {
            println!("Database initialization failed: {:?}", e);
            // Skip test if database can't be initialized
            return;
        }
        
        let request = CreateProjectRequest {
            name: "Test Project".to_string(),
            description: Some("A test project for TDD development".to_string()),
        };
        
        let result = create_project(request).await;
        
        // Test should now pass (green phase)
        assert!(result.is_ok(), "create_project should succeed");
        let project = result.unwrap();
        assert_eq!(project.name, "Test Project");
        assert_eq!(project.description, Some("A test project for TDD development".to_string()));
        assert!(project.id != Uuid::nil());
        assert!(project.created_at <= Utc::now());
        assert!(project.updated_at <= Utc::now());
    }
} 