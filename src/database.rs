//! Database operations for Paragonic
//! 
//! This module handles all database operations using PostgreSQL Embedded
//! for local development and data persistence.

use sqlx::{PgPool, postgres::PgPoolOptions};
use std::sync::Arc;
use tokio::sync::OnceCell;
use tracing::{info, error};

use crate::error::{ParagonicError, ParagonicResult};

/// Global database connection pool
static DB_POOL: OnceCell<Arc<PgPool>> = OnceCell::const_new();

/// Database configuration
#[derive(Debug, Clone)]
pub struct DatabaseConfig {
    pub host: String,
    pub port: u16,
    pub username: String,
    pub password: String,
    pub database: String,
    pub max_connections: u32,
}

impl Default for DatabaseConfig {
    fn default() -> Self {
        Self {
            host: "localhost".to_string(),
            port: 5432,
            username: "paragonic".to_string(),
            password: "paragonic".to_string(),
            database: "paragonic".to_string(),
            max_connections: 10,
        }
    }
}

/// Initialize the database connection pool
/// 
/// This function sets up the PostgreSQL Embedded database and creates
/// the connection pool for the application.
pub async fn initialize() -> ParagonicResult<()> {
    let config = DatabaseConfig::default();
    
    // Create connection string
    let connection_string = format!(
        "postgresql://{}:{}@{}:{}/{}",
        config.username, config.password, config.host, config.port, config.database
    );
    
    // Create connection pool
    let pool = PgPoolOptions::new()
        .max_connections(config.max_connections)
        .connect(&connection_string)
        .await
        .map_err(|e| {
            error!("Failed to connect to database: {}", e);
            ParagonicError::Database(e)
        })?;
    
    // Store pool globally
    DB_POOL.set(Arc::new(pool)).map_err(|_| {
        ParagonicError::Internal("Database pool already initialized".to_string())
    })?;
    
    // Run migrations
    run_migrations().await?;
    
    info!("Database initialized successfully");
    Ok(())
}

/// Get the database connection pool
/// 
/// Returns a reference to the global database pool.
pub fn get_pool() -> ParagonicResult<Arc<PgPool>> {
    DB_POOL.get().cloned().ok_or_else(|| {
        ParagonicError::Internal("Database not initialized".to_string())
    })
}

/// Run database migrations
/// 
/// This function creates the initial database schema for the application.
async fn run_migrations() -> ParagonicResult<()> {
    let pool = get_pool()?;
    
    // Create initial schema
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS projects (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(255) NOT NULL,
            description TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        CREATE TABLE IF NOT EXISTS goals (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
            name VARCHAR(255) NOT NULL,
            description TEXT,
            status VARCHAR(50) DEFAULT 'active',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        CREATE TABLE IF NOT EXISTS tasks (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            goal_id UUID REFERENCES goals(id) ON DELETE CASCADE,
            name VARCHAR(255) NOT NULL,
            description TEXT,
            status VARCHAR(50) DEFAULT 'pending',
            priority INTEGER DEFAULT 0,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        CREATE TABLE IF NOT EXISTS agents (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(255) NOT NULL,
            description TEXT,
            model_name VARCHAR(255) NOT NULL,
            configuration JSONB,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        CREATE TABLE IF NOT EXISTS conversations (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            agent_id UUID REFERENCES agents(id) ON DELETE CASCADE,
            title VARCHAR(255),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        CREATE TABLE IF NOT EXISTS messages (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
            role VARCHAR(50) NOT NULL,
            content TEXT NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        "#
    )
    .execute(pool.as_ref())
    .await
    .map_err(|e| {
        error!("Failed to run migrations: {}", e);
        ParagonicError::Database(e)
    })?;
    
    info!("Database migrations completed successfully");
    Ok(())
}

/// Shutdown the database connection pool
/// 
/// This function gracefully closes all database connections.
pub async fn shutdown() -> ParagonicResult<()> {
    if let Some(pool) = DB_POOL.get() {
        pool.close().await;
        info!("Database connections closed");
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::Row;
    use uuid::Uuid;

    /// Test database initialization
    #[tokio::test]
    async fn test_database_initialization() {
        // This test would require a test database setup
        // For now, we'll test the configuration
        let config = DatabaseConfig::default();
        assert_eq!(config.host, "localhost");
        assert_eq!(config.port, 5432);
        assert_eq!(config.database, "paragonic");
    }

    /// Test database configuration
    #[test]
    fn test_database_config_default() {
        let config = DatabaseConfig::default();
        assert_eq!(config.host, "localhost");
        assert_eq!(config.port, 5432);
        assert_eq!(config.username, "paragonic");
        assert_eq!(config.password, "paragonic");
        assert_eq!(config.database, "paragonic");
        assert_eq!(config.max_connections, 10);
    }

    /// Test connection string generation
    #[test]
    fn test_connection_string_generation() {
        let config = DatabaseConfig::default();
        let connection_string = format!(
            "postgresql://{}:{}@{}:{}/{}",
            config.username, config.password, config.host, config.port, config.database
        );
        
        assert_eq!(
            connection_string,
            "postgresql://paragonic:paragonic@localhost:5432/paragonic"
        );
    }

    /// Test error handling for uninitialized database
    #[test]
    fn test_get_pool_uninitialized() {
        let result = get_pool();
        assert!(result.is_err());
        match result {
            Err(ParagonicError::Internal(msg)) => {
                assert_eq!(msg, "Database not initialized");
            }
            _ => panic!("Expected Internal error"),
        }
    }
} 