//! Database operations for Paragonic
//! 
//! This module provides CRUD operations for all database entities,
//! including projects, goals, tasks, agents, conversations, and more.

use crate::error::{ParagonicError, ParagonicResult};
use crate::models::{Project, CreateProjectRequest, UpdateProjectRequest, Goal, CreateGoalRequest, UpdateGoalRequest, Task, CreateTaskRequest, UpdateTaskRequest};
use crate::database::get_connection;
use diesel::prelude::*;
use uuid::Uuid;
use chrono::Utc;

use crate::schema::{projects, goals, tasks};

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
        created_at: Some(now),
        updated_at: Some(now),
        organization_id: None, // TODO: Add organization_id support later
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

/// Get a project by ID
/// 
/// This function retrieves a project from the database by its ID.
/// Returns the project if found, or an error if not found.
pub async fn get_project(project_id: Uuid) -> ParagonicResult<Project> {
    let mut conn = get_connection()?;
    
    projects::table
        .filter(projects::id.eq(project_id))
        .first::<Project>(&mut conn)
        .map_err(|e| {
            tracing::error!("Failed to get project {}: {}", project_id, e);
            ParagonicError::Database(format!("Failed to get project: {e}"))
        })
}

/// List all projects
/// 
/// This function retrieves all projects from the database.
/// Returns a vector of all projects, ordered by creation date (newest first).
pub async fn list_projects() -> ParagonicResult<Vec<Project>> {
    let mut conn = get_connection()?;
    
    projects::table
        .order(projects::created_at.desc())
        .load::<Project>(&mut conn)
        .map_err(|e| {
            tracing::error!("Failed to list projects: {}", e);
            ParagonicError::Database(format!("Failed to list projects: {e}"))
        })
}

/// Create a new goal
/// 
/// This function creates a new goal in the database with the given name and description.
/// Returns the created goal with generated ID and timestamps.
pub async fn create_goal(request: CreateGoalRequest) -> ParagonicResult<Goal> {
    let mut conn = get_connection()?;
    
    let now = Utc::now();
    let goal = Goal {
        id: Uuid::new_v4(),
        project_id: Some(request.project_id),
        name: request.name,
        description: request.description,
        status: Some("active".to_string()), // Default to active status
        created_at: Some(now),
        updated_at: Some(now),
    };
    
    diesel::insert_into(goals::table)
        .values(&goal)
        .execute(&mut conn)
        .map_err(|e| {
            tracing::error!("Failed to create goal: {}", e);
            ParagonicError::Database(format!("Failed to create goal: {e}"))
        })?;
    
    Ok(goal)
}

/// Get a goal by ID
/// 
/// This function retrieves a goal from the database by its ID.
/// Returns the goal if found, or an error if not found or database error occurs.
pub async fn get_goal(goal_id: Uuid) -> ParagonicResult<Goal> {
    let mut conn = get_connection()?;
    
    goals::table
        .filter(goals::id.eq(goal_id))
        .first::<Goal>(&mut conn)
        .map_err(|e| {
            tracing::error!("Failed to get goal {}: {}", goal_id, e);
            ParagonicError::Database(format!("Failed to get goal: {e}"))
        })
}

/// List all goals for a project
/// 
/// This function retrieves all goals from the database for a specific project.
/// Returns a vector of goals ordered by creation date (newest first).
pub async fn list_goals(project_id: Uuid) -> ParagonicResult<Vec<Goal>> {
    let mut conn = get_connection()?;
    
    goals::table
        .filter(goals::project_id.eq(project_id))
        .order(goals::created_at.desc())
        .load::<Goal>(&mut conn)
        .map_err(|e| {
            tracing::error!("Failed to list goals for project {}: {}", project_id, e);
            ParagonicError::Database(format!("Failed to list goals: {e}"))
        })
}

/// Create a new task
/// 
/// This function creates a new task in the database with the given name, description, and priority.
/// Returns the created task with generated ID and timestamps.
pub async fn create_task(request: CreateTaskRequest) -> ParagonicResult<Task> {
    let mut conn = get_connection()?;
    
    let now = Utc::now();
    let task = Task {
        id: Uuid::new_v4(),
        goal_id: Some(request.goal_id),
        name: request.name,
        description: request.description,
        status: Some("pending".to_string()), // Default to pending status
        priority: Some(request.priority.unwrap_or(0)), // Default to 0 if not provided
        created_at: Some(now),
        updated_at: Some(now),
    };
    
    diesel::insert_into(tasks::table)
        .values(&task)
        .execute(&mut conn)
        .map_err(|e| {
            tracing::error!("Failed to create task: {}", e);
            ParagonicError::Database(format!("Failed to create task: {e}"))
        })?;
    
    Ok(task)
}

/// Get a task by ID
/// 
/// This function retrieves a task from the database by its ID.
/// Returns the task if found, or an error if not found or database error occurs.
pub async fn get_task(task_id: Uuid) -> ParagonicResult<Task> {
    let mut conn = get_connection()?;
    
    tasks::table
        .filter(tasks::id.eq(task_id))
        .first::<Task>(&mut conn)
        .map_err(|e| {
            tracing::error!("Failed to get task {}: {}", task_id, e);
            ParagonicError::Database(format!("Failed to get task: {e}"))
        })
}

/// List all tasks for a goal
/// 
/// This function retrieves all tasks from the database for a specific goal.
/// Returns a vector of tasks ordered by creation date (newest first).
pub async fn list_tasks(goal_id: Uuid) -> ParagonicResult<Vec<Task>> {
    let mut conn = get_connection()?;
    
    tasks::table
        .filter(tasks::goal_id.eq(goal_id))
        .order(tasks::created_at.desc())
        .load::<Task>(&mut conn)
        .map_err(|e| {
            tracing::error!("Failed to list tasks for goal {}: {}", goal_id, e);
            ParagonicError::Database(format!("Failed to list tasks: {e}"))
        })
}

/// Update a project
/// 
/// This function updates a project in the database with the given fields.
/// Returns the updated project with new timestamps.
pub async fn update_project(project_id: Uuid, request: UpdateProjectRequest) -> ParagonicResult<Project> {
    let mut conn = get_connection()?;
    
    let now = Utc::now();
    
    // Execute the update based on what fields are provided
    match (request.name, request.description) {
        (Some(name), Some(description)) => {
            diesel::update(projects::table.filter(projects::id.eq(project_id)))
                .set((
                    projects::name.eq(name),
                    projects::description.eq(description),
                    projects::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (Some(name), None) => {
            diesel::update(projects::table.filter(projects::id.eq(project_id)))
                .set((
                    projects::name.eq(name),
                    projects::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (None, Some(description)) => {
            diesel::update(projects::table.filter(projects::id.eq(project_id)))
                .set((
                    projects::description.eq(description),
                    projects::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (None, None) => {
            diesel::update(projects::table.filter(projects::id.eq(project_id)))
                .set(projects::updated_at.eq(now))
                .execute(&mut conn)
        }
    }
    .map_err(|e| {
        tracing::error!("Failed to update project {}: {}", project_id, e);
        ParagonicError::Database(format!("Failed to update project: {e}"))
    })?;
    
    // Return the updated project
    projects::table
        .filter(projects::id.eq(project_id))
        .first::<Project>(&mut conn)
        .map_err(|e| {
            tracing::error!("Failed to get updated project {}: {}", project_id, e);
            ParagonicError::Database(format!("Failed to get updated project: {e}"))
        })
}

/// Update a goal
/// 
/// This function updates a goal in the database with the given fields.
/// Returns the updated goal with new timestamps.
pub async fn update_goal(goal_id: Uuid, request: UpdateGoalRequest) -> ParagonicResult<Goal> {
    let mut conn = get_connection()?;
    
    let now = Utc::now();
    
    // Execute the update based on what fields are provided
    match (request.name, request.description, request.status) {
        (Some(name), Some(description), Some(status)) => {
            diesel::update(goals::table.filter(goals::id.eq(goal_id)))
                .set((
                    goals::name.eq(name),
                    goals::description.eq(description),
                    goals::status.eq(status),
                    goals::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (Some(name), Some(description), None) => {
            diesel::update(goals::table.filter(goals::id.eq(goal_id)))
                .set((
                    goals::name.eq(name),
                    goals::description.eq(description),
                    goals::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (Some(name), None, Some(status)) => {
            diesel::update(goals::table.filter(goals::id.eq(goal_id)))
                .set((
                    goals::name.eq(name),
                    goals::status.eq(status),
                    goals::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (Some(name), None, None) => {
            diesel::update(goals::table.filter(goals::id.eq(goal_id)))
                .set((
                    goals::name.eq(name),
                    goals::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (None, Some(description), Some(status)) => {
            diesel::update(goals::table.filter(goals::id.eq(goal_id)))
                .set((
                    goals::description.eq(description),
                    goals::status.eq(status),
                    goals::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (None, Some(description), None) => {
            diesel::update(goals::table.filter(goals::id.eq(goal_id)))
                .set((
                    goals::description.eq(description),
                    goals::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (None, None, Some(status)) => {
            diesel::update(goals::table.filter(goals::id.eq(goal_id)))
                .set((
                    goals::status.eq(status),
                    goals::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (None, None, None) => {
            diesel::update(goals::table.filter(goals::id.eq(goal_id)))
                .set(goals::updated_at.eq(now))
                .execute(&mut conn)
        }
    }
    .map_err(|e| {
        tracing::error!("Failed to update goal {}: {}", goal_id, e);
        ParagonicError::Database(format!("Failed to update goal: {e}"))
    })?;
    
    // Return the updated goal
    goals::table
        .filter(goals::id.eq(goal_id))
        .first::<Goal>(&mut conn)
        .map_err(|e| {
            tracing::error!("Failed to get updated goal {}: {}", goal_id, e);
            ParagonicError::Database(format!("Failed to get updated goal: {e}"))
        })
}

/// Update a task
/// 
/// This function updates a task in the database with the given fields.
/// Returns the updated task with new timestamps.
pub async fn update_task(task_id: Uuid, request: UpdateTaskRequest) -> ParagonicResult<Task> {
    let mut conn = get_connection()?;
    
    let now = Utc::now();
    
    // Execute the update based on what fields are provided
    match (request.name, request.description, request.status, request.priority) {
        (Some(name), Some(description), Some(status), Some(priority)) => {
            diesel::update(tasks::table.filter(tasks::id.eq(task_id)))
                .set((
                    tasks::name.eq(name),
                    tasks::description.eq(description),
                    tasks::status.eq(status),
                    tasks::priority.eq(priority),
                    tasks::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (Some(name), Some(description), Some(status), None) => {
            diesel::update(tasks::table.filter(tasks::id.eq(task_id)))
                .set((
                    tasks::name.eq(name),
                    tasks::description.eq(description),
                    tasks::status.eq(status),
                    tasks::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (Some(name), Some(description), None, Some(priority)) => {
            diesel::update(tasks::table.filter(tasks::id.eq(task_id)))
                .set((
                    tasks::name.eq(name),
                    tasks::description.eq(description),
                    tasks::priority.eq(priority),
                    tasks::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (Some(name), Some(description), None, None) => {
            diesel::update(tasks::table.filter(tasks::id.eq(task_id)))
                .set((
                    tasks::name.eq(name),
                    tasks::description.eq(description),
                    tasks::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (Some(name), None, Some(status), Some(priority)) => {
            diesel::update(tasks::table.filter(tasks::id.eq(task_id)))
                .set((
                    tasks::name.eq(name),
                    tasks::status.eq(status),
                    tasks::priority.eq(priority),
                    tasks::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (Some(name), None, Some(status), None) => {
            diesel::update(tasks::table.filter(tasks::id.eq(task_id)))
                .set((
                    tasks::name.eq(name),
                    tasks::status.eq(status),
                    tasks::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (Some(name), None, None, Some(priority)) => {
            diesel::update(tasks::table.filter(tasks::id.eq(task_id)))
                .set((
                    tasks::name.eq(name),
                    tasks::priority.eq(priority),
                    tasks::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (Some(name), None, None, None) => {
            diesel::update(tasks::table.filter(tasks::id.eq(task_id)))
                .set((
                    tasks::name.eq(name),
                    tasks::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (None, Some(description), Some(status), Some(priority)) => {
            diesel::update(tasks::table.filter(tasks::id.eq(task_id)))
                .set((
                    tasks::description.eq(description),
                    tasks::status.eq(status),
                    tasks::priority.eq(priority),
                    tasks::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (None, Some(description), Some(status), None) => {
            diesel::update(tasks::table.filter(tasks::id.eq(task_id)))
                .set((
                    tasks::description.eq(description),
                    tasks::status.eq(status),
                    tasks::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (None, Some(description), None, Some(priority)) => {
            diesel::update(tasks::table.filter(tasks::id.eq(task_id)))
                .set((
                    tasks::description.eq(description),
                    tasks::priority.eq(priority),
                    tasks::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (None, Some(description), None, None) => {
            diesel::update(tasks::table.filter(tasks::id.eq(task_id)))
                .set((
                    tasks::description.eq(description),
                    tasks::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (None, None, Some(status), Some(priority)) => {
            diesel::update(tasks::table.filter(tasks::id.eq(task_id)))
                .set((
                    tasks::status.eq(status),
                    tasks::priority.eq(priority),
                    tasks::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (None, None, Some(status), None) => {
            diesel::update(tasks::table.filter(tasks::id.eq(task_id)))
                .set((
                    tasks::status.eq(status),
                    tasks::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (None, None, None, Some(priority)) => {
            diesel::update(tasks::table.filter(tasks::id.eq(task_id)))
                .set((
                    tasks::priority.eq(priority),
                    tasks::updated_at.eq(now),
                ))
                .execute(&mut conn)
        }
        (None, None, None, None) => {
            diesel::update(tasks::table.filter(tasks::id.eq(task_id)))
                .set(tasks::updated_at.eq(now))
                .execute(&mut conn)
        }
    }
    .map_err(|e| {
        tracing::error!("Failed to update task {}: {}", task_id, e);
        ParagonicError::Database(format!("Failed to update task: {e}"))
    })?;
    
    // Return the updated task
    tasks::table
        .filter(tasks::id.eq(task_id))
        .first::<Task>(&mut conn)
        .map_err(|e| {
            tracing::error!("Failed to get updated task {}: {}", task_id, e);
            ParagonicError::Database(format!("Failed to get updated task: {e}"))
        })
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
        assert!(project.created_at.is_some());
        assert!(project.updated_at.is_some());
        assert!(project.created_at.unwrap() <= Utc::now());
        assert!(project.updated_at.unwrap() <= Utc::now());
    }
    
    /// Test getting a project by ID
    #[tokio::test]
    async fn test_get_project() {
        // Initialize database first
        let db_result = crate::database::initialize().await;
        if let Err(e) = &db_result {
            println!("Database initialization failed: {:?}", e);
            // Skip test if database can't be initialized
            return;
        }
        
        // First create a project
        let create_request = CreateProjectRequest {
            name: "Test Project for Get".to_string(),
            description: Some("A test project for get operation".to_string()),
        };
        
        let created_project = create_project(create_request).await.unwrap();
        let project_id = created_project.id;
        
        // Now get the project by ID
        let result = get_project(project_id).await;
        
        // Test should now pass (green phase)
        assert!(result.is_ok(), "get_project should succeed");
        let project = result.unwrap();
        assert_eq!(project.id, project_id);
        assert_eq!(project.name, "Test Project for Get");
        assert_eq!(project.description, Some("A test project for get operation".to_string()));
    }
    
    /// Test listing all projects
    #[tokio::test]
    async fn test_list_projects() {
        // Initialize database first
        let db_result = crate::database::initialize().await;
        if let Err(e) = &db_result {
            println!("Database initialization failed: {:?}", e);
            // Skip test if database can't be initialized
            return;
        }
        
        // Create multiple projects
        let project1_request = CreateProjectRequest {
            name: "Project Alpha".to_string(),
            description: Some("First test project".to_string()),
        };
        
        let project2_request = CreateProjectRequest {
            name: "Project Beta".to_string(),
            description: Some("Second test project".to_string()),
        };
        
        let project3_request = CreateProjectRequest {
            name: "Project Gamma".to_string(),
            description: None,
        };
        
        let _project1 = create_project(project1_request).await.unwrap();
        let _project2 = create_project(project2_request).await.unwrap();
        let _project3 = create_project(project3_request).await.unwrap();
        
        // List all projects
        let result = list_projects().await;
        
        // Test should now pass (green phase)
        assert!(result.is_ok(), "list_projects should succeed");
        let projects = result.unwrap();
        
        // Should have at least 3 projects (our test projects)
        assert!(projects.len() >= 3, "Should have at least 3 projects");
        
        // Find our test projects
        let alpha_project = projects.iter().find(|p| p.name == "Project Alpha");
        let beta_project = projects.iter().find(|p| p.name == "Project Beta");
        let gamma_project = projects.iter().find(|p| p.name == "Project Gamma");
        
        assert!(alpha_project.is_some(), "Project Alpha should be found");
        assert!(beta_project.is_some(), "Project Beta should be found");
        assert!(gamma_project.is_some(), "Project Gamma should be found");
        
        assert_eq!(alpha_project.unwrap().description, Some("First test project".to_string()));
        assert_eq!(beta_project.unwrap().description, Some("Second test project".to_string()));
        assert_eq!(gamma_project.unwrap().description, None);
    }
    
    /// Test creating a goal with valid data
    #[tokio::test]
    async fn test_create_goal() {
        // Initialize database first
        let db_result = crate::database::initialize().await;
        if let Err(e) = &db_result {
            println!("Database initialization failed: {:?}", e);
            // Skip test if database can't be initialized
            return;
        }
        
        // First create a project
        let project_request = CreateProjectRequest {
            name: "Test Project for Goal".to_string(),
            description: Some("A test project for goal creation".to_string()),
        };
        let project = create_project(project_request).await.unwrap();
        
        let request = CreateGoalRequest {
            project_id: project.id,
            name: "Test Goal".to_string(),
            description: Some("A test goal for TDD development".to_string()),
        };
        
        let result = create_goal(request).await;
        
        // Test should now pass (green phase)
        assert!(result.is_ok(), "create_goal should succeed");
        let goal = result.unwrap();
        assert_eq!(goal.name, "Test Goal");
        assert_eq!(goal.description, Some("A test goal for TDD development".to_string()));
        assert_eq!(goal.project_id, Some(project.id));
        assert!(goal.id != Uuid::nil());
        assert!(goal.created_at.is_some());
        assert!(goal.updated_at.is_some());
        assert!(goal.created_at.unwrap() <= Utc::now());
        assert!(goal.updated_at.unwrap() <= Utc::now());
    }
    
    /// Test getting a goal by ID
    #[tokio::test]
    async fn test_get_goal() {
        // Initialize database first
        let db_result = crate::database::initialize().await;
        if let Err(e) = &db_result {
            println!("Database initialization failed: {:?}", e);
            // Skip test if database can't be initialized
            return;
        }
        
        // First create a project
        let project_request = CreateProjectRequest {
            name: "Test Project for Get Goal".to_string(),
            description: Some("A test project for get goal operation".to_string()),
        };
        let project = create_project(project_request).await.unwrap();
        
        // Create a goal
        let create_goal_request = CreateGoalRequest {
            project_id: project.id,
            name: "Test Goal for Get".to_string(),
            description: Some("A test goal for get operation".to_string()),
        };
        let created_goal = create_goal(create_goal_request).await.unwrap();
        let goal_id = created_goal.id;
        
        // Now get the goal by ID
        let result = get_goal(goal_id).await;
        
        // Test should now pass (green phase)
        assert!(result.is_ok(), "get_goal should succeed");
        let goal = result.unwrap();
        assert_eq!(goal.id, goal_id);
        assert_eq!(goal.name, "Test Goal for Get");
        assert_eq!(goal.description, Some("A test goal for get operation".to_string()));
        assert_eq!(goal.project_id, Some(project.id));
    }
    
    /// Test listing all goals for a project
    #[tokio::test]
    async fn test_list_goals() {
        // Initialize database first
        let db_result = crate::database::initialize().await;
        if let Err(e) = &db_result {
            println!("Database initialization failed: {:?}", e);
            // Skip test if database can't be initialized
            return;
        }
        
        // First create a project
        let project_request = CreateProjectRequest {
            name: "Test Project for List Goals".to_string(),
            description: Some("A test project for list goals operation".to_string()),
        };
        let project = create_project(project_request).await.unwrap();
        
        // Create multiple goals for this project
        let goal1_request = CreateGoalRequest {
            project_id: project.id,
            name: "Goal Alpha".to_string(),
            description: Some("First test goal".to_string()),
        };
        
        let goal2_request = CreateGoalRequest {
            project_id: project.id,
            name: "Goal Beta".to_string(),
            description: Some("Second test goal".to_string()),
        };
        
        let goal3_request = CreateGoalRequest {
            project_id: project.id,
            name: "Goal Gamma".to_string(),
            description: None,
        };
        
        let _goal1 = create_goal(goal1_request).await.unwrap();
        let _goal2 = create_goal(goal2_request).await.unwrap();
        let _goal3 = create_goal(goal3_request).await.unwrap();
        
        // List all goals for the project
        let result = list_goals(project.id).await;
        
        // Test should now pass (green phase)
        assert!(result.is_ok(), "list_goals should succeed");
        let goals = result.unwrap();
        
        // Should have at least 3 goals (our test goals)
        assert!(goals.len() >= 3, "Should have at least 3 goals");
        
        // Find our test goals
        let alpha_goal = goals.iter().find(|g| g.name == "Goal Alpha");
        let beta_goal = goals.iter().find(|g| g.name == "Goal Beta");
        let gamma_goal = goals.iter().find(|g| g.name == "Goal Gamma");
        
        assert!(alpha_goal.is_some(), "Goal Alpha should be found");
        assert!(beta_goal.is_some(), "Goal Beta should be found");
        assert!(gamma_goal.is_some(), "Goal Gamma should be found");
        
        assert_eq!(alpha_goal.unwrap().description, Some("First test goal".to_string()));
        assert_eq!(beta_goal.unwrap().description, Some("Second test goal".to_string()));
        assert_eq!(gamma_goal.unwrap().description, None);
        
        // All goals should belong to the same project
        assert_eq!(alpha_goal.unwrap().project_id, Some(project.id));
        assert_eq!(beta_goal.unwrap().project_id, Some(project.id));
        assert_eq!(gamma_goal.unwrap().project_id, Some(project.id));
    }
    
    /// Test creating a task with valid data
    #[tokio::test]
    async fn test_create_task() {
        // Initialize database first
        let db_result = crate::database::initialize().await;
        if let Err(e) = &db_result {
            println!("Database initialization failed: {:?}", e);
            // Skip test if database can't be initialized
            return;
        }
        
        // First create a project
        let project_request = CreateProjectRequest {
            name: "Test Project for Task".to_string(),
            description: Some("A test project for task creation".to_string()),
        };
        let project = create_project(project_request).await.unwrap();
        
        // Create a goal
        let goal_request = CreateGoalRequest {
            project_id: project.id,
            name: "Test Goal for Task".to_string(),
            description: Some("A test goal for task creation".to_string()),
        };
        let goal = create_goal(goal_request).await.unwrap();
        
        let request = CreateTaskRequest {
            goal_id: goal.id,
            name: "Test Task".to_string(),
            description: Some("A test task for TDD development".to_string()),
            priority: Some(1),
        };
        
        let result = create_task(request).await;
        
        // Test should now pass (green phase)
        assert!(result.is_ok(), "create_task should succeed");
        let task = result.unwrap();
        assert_eq!(task.name, "Test Task");
        assert_eq!(task.description, Some("A test task for TDD development".to_string()));
        assert_eq!(task.goal_id, Some(goal.id));
        assert_eq!(task.priority, Some(1));
        assert!(task.id != Uuid::nil());
        assert!(task.created_at.is_some());
        assert!(task.updated_at.is_some());
        assert!(task.created_at.unwrap() <= Utc::now());
        assert!(task.updated_at.unwrap() <= Utc::now());
    }
    
    /// Test getting a task by ID
    #[tokio::test]
    async fn test_get_task() {
        // Initialize database first
        let db_result = crate::database::initialize().await;
        if let Err(e) = &db_result {
            println!("Database initialization failed: {:?}", e);
            // Skip test if database can't be initialized
            return;
        }
        
        // First create a project
        let project_request = CreateProjectRequest {
            name: "Test Project for Get Task".to_string(),
            description: Some("A test project for get task operation".to_string()),
        };
        let project = create_project(project_request).await.unwrap();
        
        // Create a goal
        let goal_request = CreateGoalRequest {
            project_id: project.id,
            name: "Test Goal for Get Task".to_string(),
            description: Some("A test goal for get task operation".to_string()),
        };
        let goal = create_goal(goal_request).await.unwrap();
        
        // Create a task
        let create_task_request = CreateTaskRequest {
            goal_id: goal.id,
            name: "Test Task for Get".to_string(),
            description: Some("A test task for get operation".to_string()),
            priority: Some(2),
        };
        let created_task = create_task(create_task_request).await.unwrap();
        let task_id = created_task.id;
        
        // Now get the task by ID
        let result = get_task(task_id).await;
        
        // Test should now pass (green phase)
        assert!(result.is_ok(), "get_task should succeed");
        let task = result.unwrap();
        assert_eq!(task.id, task_id);
        assert_eq!(task.name, "Test Task for Get");
        assert_eq!(task.description, Some("A test task for get operation".to_string()));
        assert_eq!(task.goal_id, Some(goal.id));
        assert_eq!(task.priority, Some(2));
    }
    
    /// Test listing all tasks for a goal
    #[tokio::test]
    async fn test_list_tasks() {
        // Initialize database first
        let db_result = crate::database::initialize().await;
        if let Err(e) = &db_result {
            println!("Database initialization failed: {:?}", e);
            // Skip test if database can't be initialized
            return;
        }
        
        // First create a project
        let project_request = CreateProjectRequest {
            name: "Test Project for List Tasks".to_string(),
            description: Some("A test project for list tasks operation".to_string()),
        };
        let project = create_project(project_request).await.unwrap();
        
        // Create a goal
        let goal_request = CreateGoalRequest {
            project_id: project.id,
            name: "Test Goal for List Tasks".to_string(),
            description: Some("A test goal for list tasks operation".to_string()),
        };
        let goal = create_goal(goal_request).await.unwrap();
        
        // Create multiple tasks for this goal
        let task1_request = CreateTaskRequest {
            goal_id: goal.id,
            name: "Task Alpha".to_string(),
            description: Some("First test task".to_string()),
            priority: Some(1),
        };
        
        let task2_request = CreateTaskRequest {
            goal_id: goal.id,
            name: "Task Beta".to_string(),
            description: Some("Second test task".to_string()),
            priority: Some(2),
        };
        
        let task3_request = CreateTaskRequest {
            goal_id: goal.id,
            name: "Task Gamma".to_string(),
            description: None,
            priority: Some(3),
        };
        
        let _task1 = create_task(task1_request).await.unwrap();
        let _task2 = create_task(task2_request).await.unwrap();
        let _task3 = create_task(task3_request).await.unwrap();
        
        // List all tasks for the goal
        let result = list_tasks(goal.id).await;
        
        // Test should now pass (green phase)
        assert!(result.is_ok(), "list_tasks should succeed");
        let tasks = result.unwrap();
        
        // Should have at least 3 tasks (our test tasks)
        assert!(tasks.len() >= 3, "Should have at least 3 tasks");
        
        // Find our test tasks
        let alpha_task = tasks.iter().find(|t| t.name == "Task Alpha");
        let beta_task = tasks.iter().find(|t| t.name == "Task Beta");
        let gamma_task = tasks.iter().find(|t| t.name == "Task Gamma");
        
        assert!(alpha_task.is_some(), "Task Alpha should be found");
        assert!(beta_task.is_some(), "Task Beta should be found");
        assert!(gamma_task.is_some(), "Task Gamma should be found");
        
        assert_eq!(alpha_task.unwrap().description, Some("First test task".to_string()));
        assert_eq!(beta_task.unwrap().description, Some("Second test task".to_string()));
        assert_eq!(gamma_task.unwrap().description, None);
        
        // All tasks should belong to the same goal
        assert_eq!(alpha_task.unwrap().goal_id, Some(goal.id));
        assert_eq!(beta_task.unwrap().goal_id, Some(goal.id));
        assert_eq!(gamma_task.unwrap().goal_id, Some(goal.id));
    }
    
    /// Test updating a project with valid data
    #[tokio::test]
    async fn test_update_project() {
        // Initialize database first
        let db_result = crate::database::initialize().await;
        if let Err(e) = &db_result {
            println!("Database initialization failed: {:?}", e);
            // Skip test if database can't be initialized
            return;
        }
        
        // First create a project
        let project_request = CreateProjectRequest {
            name: "Original Project Name".to_string(),
            description: Some("Original project description".to_string()),
        };
        let project = create_project(project_request).await.unwrap();
        let project_id = project.id;
        
        // Update the project
        let update_request = UpdateProjectRequest {
            name: Some("Updated Project Name".to_string()),
            description: Some("Updated project description".to_string()),
        };
        
        let result = update_project(project_id, update_request).await;
        
        // Test should now pass (green phase)
        assert!(result.is_ok(), "update_project should succeed");
        let updated_project = result.unwrap();
        assert_eq!(updated_project.id, project_id);
        assert_eq!(updated_project.name, "Updated Project Name");
        assert_eq!(updated_project.description, Some("Updated project description".to_string()));
        assert!(updated_project.updated_at.is_some());
        assert!(updated_project.updated_at.unwrap() > project.updated_at.unwrap());
    }
    
    /// Test updating a goal with valid data
    #[tokio::test]
    async fn test_update_goal() {
        // Initialize database first
        let db_result = crate::database::initialize().await;
        if let Err(e) = &db_result {
            println!("Database initialization failed: {:?}", e);
            // Skip test if database can't be initialized
            return;
        }
        
        // First create a project and goal
        let project_request = CreateProjectRequest {
            name: "Test Project".to_string(),
            description: Some("Test project description".to_string()),
        };
        let project = create_project(project_request).await.unwrap();
        
        let goal_request = CreateGoalRequest {
            project_id: project.id,
            name: "Original Goal Name".to_string(),
            description: Some("Original goal description".to_string()),
        };
        let goal = create_goal(goal_request).await.unwrap();
        let goal_id = goal.id;
        
        // Update the goal
        let update_request = UpdateGoalRequest {
            name: Some("Updated Goal Name".to_string()),
            description: Some("Updated goal description".to_string()),
            status: Some("completed".to_string()),
        };
        
        let result = update_goal(goal_id, update_request).await;
        
        // Test should now pass (green phase)
        assert!(result.is_ok(), "update_goal should succeed");
        let updated_goal = result.unwrap();
        assert_eq!(updated_goal.id, goal_id);
        assert_eq!(updated_goal.name, "Updated Goal Name");
        assert_eq!(updated_goal.description, Some("Updated goal description".to_string()));
        assert_eq!(updated_goal.status, Some("completed".to_string()));
        assert!(updated_goal.updated_at.is_some());
        assert!(updated_goal.updated_at.unwrap() > goal.updated_at.unwrap());
    }
    
    /// Test updating a task with valid data
    #[tokio::test]
    async fn test_update_task() {
        // Initialize database first
        let db_result = crate::database::initialize().await;
        if let Err(e) = &db_result {
            println!("Database initialization failed: {:?}", e);
            // Skip test if database can't be initialized
            return;
        }
        
        // First create a project, goal, and task
        let project_request = CreateProjectRequest {
            name: "Test Project".to_string(),
            description: Some("Test project description".to_string()),
        };
        let project = create_project(project_request).await.unwrap();
        
        let goal_request = CreateGoalRequest {
            project_id: project.id,
            name: "Test Goal".to_string(),
            description: Some("Test goal description".to_string()),
        };
        let goal = create_goal(goal_request).await.unwrap();
        
        let task_request = CreateTaskRequest {
            goal_id: goal.id,
            name: "Original Task Name".to_string(),
            description: Some("Original task description".to_string()),
            priority: Some(1),
        };
        let task = create_task(task_request).await.unwrap();
        let task_id = task.id;
        
        // Update the task
        let update_request = UpdateTaskRequest {
            name: Some("Updated Task Name".to_string()),
            description: Some("Updated task description".to_string()),
            status: Some("in_progress".to_string()),
            priority: Some(5),
        };
        
        let result = update_task(task_id, update_request).await;
        
        // Test should now pass (green phase)
        assert!(result.is_ok(), "update_task should succeed");
        let updated_task = result.unwrap();
        assert_eq!(updated_task.id, task_id);
        assert_eq!(updated_task.name, "Updated Task Name");
        assert_eq!(updated_task.description, Some("Updated task description".to_string()));
        assert_eq!(updated_task.status, Some("in_progress".to_string()));
        assert_eq!(updated_task.priority, Some(5));
        assert!(updated_task.updated_at.is_some());
        assert!(updated_task.updated_at.unwrap() > task.updated_at.unwrap());
    }
} 