//! Database operations for Paragonic
//! 
//! This module handles all database operations using PostgreSQL Embedded
//! with Diesel ORM for local development and data persistence.


use diesel::pg::PgConnection;
use diesel::prelude::*;
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

/// Initialize the database connection pool with configuration from config manager
/// 
/// This function sets up the PostgreSQL Embedded database and creates
/// the connection pool for the application using the provided configuration.
pub async fn initialize_with_config(config_manager: &crate::config::ConfigManager) -> ParagonicResult<()> {
    // Initialize embedded database first
    initialize_embedded_db().await?;
    
    let config = get_database_config_from_manager(config_manager);
    
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
    
    info!("Database initialized successfully with custom configuration");
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

/// Get database configuration from config manager
/// 
/// Converts the database configuration from the config module
/// to the database module's DatabaseConfig structure.
pub fn get_database_config_from_manager(config_manager: &crate::config::ConfigManager) -> DatabaseConfig {
    let config = config_manager.get_config();
    
    let mut data_dir = std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
    data_dir.push(".paragonic");
    data_dir.push("db");
    
    DatabaseConfig {
        host: config.database.host.clone(),
        port: config.database.port,
        username: config.database.username.clone(),
        password: config.database.password.clone(),
        database: config.database.database.clone(),
        max_connections: config.database.max_connections,
        data_dir,
    }
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
    use crate::config::ConfigManager;

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

    /// Test database configuration from config module
    #[test]
    fn test_database_config_from_config_module() {
        let config_manager = ConfigManager::new();
        let config = config_manager.get_config();
        
        // Verify that the database config from the config module matches our expectations
        assert_eq!(config.database.host, "localhost");
        assert_eq!(config.database.port, 5432);
        assert_eq!(config.database.username, "paragonic");
        assert_eq!(config.database.password, "paragonic");
        assert_eq!(config.database.database, "paragonic");
        assert_eq!(config.database.max_connections, 10);
    }

    /// Test database initialization with custom configuration
    #[test]
    fn test_database_initialization_with_config() {
        let config_manager = ConfigManager::new();
        let config = config_manager.get_config();
        
        // Test that we can create a database config from the config module
        let db_config = DatabaseConfig {
            host: config.database.host.clone(),
            port: config.database.port,
            username: config.database.username.clone(),
            password: config.database.password.clone(),
            database: config.database.database.clone(),
            max_connections: config.database.max_connections,
            data_dir: DatabaseConfig::default().data_dir,
        };
        
        assert_eq!(db_config.host, "localhost");
        assert_eq!(db_config.port, 5432);
        assert_eq!(db_config.max_connections, 10);
    }

    /// Test database initialization with config manager
    #[test]
    fn test_database_initialization_with_config_manager() {
        let config_manager = ConfigManager::new();
        
        // Test that we can get database config from config manager
        let db_config = get_database_config_from_manager(&config_manager);
        
        assert_eq!(db_config.host, "localhost");
        assert_eq!(db_config.port, 5432);
        assert_eq!(db_config.max_connections, 10);
    }

    /// Test database initialization with custom config manager
    #[test]
    fn test_database_initialization_with_custom_config() {
        let mut config_manager = ConfigManager::new();
        
        // Set custom database configuration
        config_manager.get_config_mut().database.host = "custom-host".to_string();
        config_manager.get_config_mut().database.port = 5433;
        config_manager.get_config_mut().database.max_connections = 20;
        
        // Test that the custom config is used
        let db_config = get_database_config_from_manager(&config_manager);
        
        assert_eq!(db_config.host, "custom-host");
        assert_eq!(db_config.port, 5433);
        assert_eq!(db_config.max_connections, 20);
    }

    /// Test database initialization with config manager parameter
    #[test]
    fn test_initialize_with_config_manager_configuration() {
        let config_manager = ConfigManager::new();
        
        // Test that we can get the configuration correctly
        let db_config = get_database_config_from_manager(&config_manager);
        
        // Verify the configuration is correct
        assert_eq!(db_config.host, "localhost");
        assert_eq!(db_config.port, 5432);
        assert_eq!(db_config.username, "paragonic");
        assert_eq!(db_config.password, "paragonic");
        assert_eq!(db_config.database, "paragonic");
        assert_eq!(db_config.max_connections, 10);
        
        // Test that the connection string would be correct
        let connection_string = format!(
            "postgresql://{}:{}@{}:{}/{}",
            db_config.username, db_config.password, db_config.host, db_config.port, db_config.database
        );
        
        assert_eq!(
            connection_string,
            "postgresql://paragonic:paragonic@localhost:5432/paragonic"
        );
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

    /// Test database initialization
    #[tokio::test]
    async fn test_database_initialization() {
        // This test verifies that the database can be initialized
        // and that the connection pool is created successfully
        let result = initialize().await;
        assert!(result.is_ok());
        
        // Test that we can get a connection from the pool
        let pool_result = get_pool();
        assert!(pool_result.is_ok());
        
        // Test that we can get a connection
        let connection_result = get_connection();
        assert!(connection_result.is_ok());
    }

    /// Test embeddings migration
    #[tokio::test]
    async fn test_embeddings_migration() {
        // Initialize database first
        let result = initialize().await;
        assert!(result.is_ok());
        
        // Get a connection to verify the embeddings table exists
        let pool = get_pool().unwrap();
        let mut conn = pool.get().unwrap();
        
        // Check if embeddings table exists
        #[derive(QueryableByName)]
        struct TableExists {
            #[diesel(sql_type = diesel::sql_types::Bool)]
            exists: bool,
        }
        
        let table_exists: TableExists = diesel::sql_query(
            "SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_name = 'embeddings'
            ) as exists"
        )
        .get_result(&mut conn)
        .unwrap();
        
        assert!(table_exists.exists, "Embeddings table should exist after migration");
        
        // Check if pgvector extension is enabled
        #[derive(QueryableByName)]
        struct ExtensionExists {
            #[diesel(sql_type = diesel::sql_types::Bool)]
            exists: bool,
        }
        
        let extension_exists: ExtensionExists = diesel::sql_query(
            "SELECT EXISTS (
                SELECT FROM pg_extension 
                WHERE extname = 'vector'
            ) as exists"
        )
        .get_result(&mut conn)
        .unwrap();
        
        assert!(extension_exists.exists, "pgvector extension should be enabled");
    }
} 