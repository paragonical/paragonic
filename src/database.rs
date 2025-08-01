//! Database operations for Paragonic
//! 
//! This module handles all database operations using PostgreSQL Embedded
//! with Diesel ORM for local development and data persistence.


use diesel::pg::PgConnection;
use diesel::r2d2::{self, ConnectionManager, Pool};
use diesel_migrations::{embed_migrations, EmbeddedMigrations, MigrationHarness};
use postgresql_embedded::PostgreSQL;
use std::path::PathBuf;
use std::sync::Arc;
use tokio::sync::OnceCell;
use tracing::{info, error};

use crate::error::{ParagonicError, ParagonicResult};

/// Embedded migrations
pub const MIGRATIONS: EmbeddedMigrations = embed_migrations!("migrations");

/// Global database connection pool
static DB_POOL: OnceCell<Arc<Pool<ConnectionManager<PgConnection>>>> = OnceCell::const_new();

/// Global embedded PostgreSQL instance
static EMBEDDED_DB: OnceCell<Arc<PostgreSQL>> = OnceCell::const_new();

/// Database configuration
#[derive(Debug, Clone)]
pub struct DatabaseConfig {
    pub host: String,
    pub port: u16,
    pub username: String,
    pub password: String,
    pub database: String,
    pub max_connections: u32,
    pub data_dir: PathBuf,
}

impl Default for DatabaseConfig {
    fn default() -> Self {
        let mut data_dir = std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
        data_dir.push(".paragonic");
        data_dir.push("db");
        
        Self {
            host: "localhost".to_string(),
            port: 5432,
            username: "paragonic".to_string(),
            password: "paragonic".to_string(),
            database: "paragonic".to_string(),
            max_connections: 10,
            data_dir,
        }
    }
}

/// Initialize the embedded PostgreSQL database
/// 
/// This function sets up the PostgreSQL Embedded database and starts it.
async fn initialize_embedded_db() -> ParagonicResult<()> {
    let config = DatabaseConfig::default();
    
    // Create data directory if it doesn't exist
    std::fs::create_dir_all(&config.data_dir).map_err(|e| {
        error!("Failed to create database directory: {}", e);
        ParagonicError::Io(e)
    })?;
    
    // Create and setup PostgreSQL
    let mut postgres = PostgreSQL::default();
    
    // Setup PostgreSQL
    postgres.setup().await.map_err(|e| {
        error!("Failed to setup PostgreSQL: {}", e);
        ParagonicError::Internal(format!("PostgreSQL setup failed: {e}"))
    })?;
    
    // Start PostgreSQL
    postgres.start().await.map_err(|e| {
        error!("Failed to start PostgreSQL: {}", e);
        ParagonicError::Internal(format!("PostgreSQL start failed: {e}"))
    })?;
    
    // Create database if it doesn't exist
    if !postgres.database_exists(&config.database).await.map_err(|e| {
        error!("Failed to check database existence: {}", e);
        ParagonicError::Internal(format!("Database check failed: {e}"))
    })? {
        postgres.create_database(&config.database).await.map_err(|e| {
            error!("Failed to create database: {}", e);
            ParagonicError::Internal(format!("Database creation failed: {e}"))
        })?;
    }
    
    // Store PostgreSQL instance globally
    EMBEDDED_DB.set(Arc::new(postgres)).map_err(|_| {
        ParagonicError::Internal("Embedded database already initialized".to_string())
    })?;
    
    info!("Embedded PostgreSQL started successfully");
    Ok(())
}

/// Initialize the database connection pool
/// 
/// This function sets up the PostgreSQL Embedded database and creates
/// the connection pool for the application.
pub async fn initialize() -> ParagonicResult<()> {
    // Initialize embedded database first
    initialize_embedded_db().await?;
    
    let config = DatabaseConfig::default();
    
    // Create connection string
    let connection_string = format!(
        "postgresql://{}:{}@{}:{}/{}",
        config.username, config.password, config.host, config.port, config.database
    );
    
    // Create connection manager
    let manager = ConnectionManager::<PgConnection>::new(&connection_string);
    
    // Create connection pool
    let pool = Pool::builder()
        .max_size(config.max_connections)
        .build(manager)
        .map_err(|e| {
            error!("Failed to create database pool: {}", e);
            ParagonicError::Internal(format!("Database pool creation failed: {e}"))
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
pub fn get_pool() -> ParagonicResult<Arc<Pool<ConnectionManager<PgConnection>>>> {
    DB_POOL.get().cloned().ok_or_else(|| {
        ParagonicError::Internal("Database not initialized".to_string())
    })
}

/// Get a database connection from the pool
/// 
/// Returns a connection that can be used for database operations.
pub fn get_connection() -> ParagonicResult<r2d2::PooledConnection<ConnectionManager<PgConnection>>> {
    let pool = get_pool()?;
    pool.get().map_err(|e| {
        error!("Failed to get database connection: {}", e);
        ParagonicError::Internal(format!("Database connection failed: {e}"))
    })
}

/// Run database migrations using Diesel
/// 
/// This function runs all embedded migrations to set up the database schema.
async fn run_migrations() -> ParagonicResult<()> {
    let conn = &mut get_connection()?;
    
    // Run embedded migrations
    conn.run_pending_migrations(MIGRATIONS).map_err(|e| {
        error!("Failed to run migrations: {}", e);
        ParagonicError::Internal(format!("Migration failed: {e}"))
    })?;
    
    info!("Database migrations completed successfully");
    Ok(())
}

/// Shutdown the database connection pool and embedded database
/// 
/// This function gracefully closes all database connections and stops
/// the embedded PostgreSQL instance.
pub async fn shutdown() -> ParagonicResult<()> {
    // Close connection pool
    if let Some(_pool) = DB_POOL.get() {
        info!("Database connections will be closed on pool drop");
    }
    
    // Stop embedded database
    if let Some(postgres) = EMBEDDED_DB.get() {
        postgres.stop().await.map_err(|e| {
            error!("Failed to stop PostgreSQL: {}", e);
            ParagonicError::Internal(format!("PostgreSQL stop failed: {e}"))
        })?;
        info!("Embedded PostgreSQL stopped successfully");
    }
    
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

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
        assert!(config.data_dir.ends_with(".paragonic/db"));
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

    /// Test error handling for uninitialized database connection
    #[test]
    fn test_get_connection_uninitialized() {
        let result = get_connection();
        assert!(result.is_err());
        match result {
            Err(ParagonicError::Internal(msg)) => {
                assert!(msg.contains("Database not initialized") || msg.contains("Database connection failed"));
            }
            _ => panic!("Expected Internal error"),
        }
    }

    /// Test database initialization (mock test)
    #[tokio::test]
    async fn test_database_initialization() {
        // This test would require a test database setup
        // For now, we'll test the configuration
        let config = DatabaseConfig::default();
        assert_eq!(config.host, "localhost");
        assert_eq!(config.port, 5432);
        assert_eq!(config.database, "paragonic");
    }
} 