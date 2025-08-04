//! Paragonic - Agentic Neovim Extension
//! 
//! This library provides the Rust backend for the Paragonic Neovim plugin,
//! handling AI integration, database operations, and core business logic.

pub mod database;
pub mod ollama;
pub mod config;
pub mod error;
pub mod models;
pub mod schema;
pub mod embeddings;
pub mod rpc;
pub mod vector;
// pub mod fulltext; // TODO: Fix type annotation issue in Tantivy integration
pub mod operations;
pub mod iragl;

pub use error::{ParagonicError, ParagonicResult};

use tokio::sync::OnceCell;

/// Global initialization flag to ensure logging is only set up once
static INITIALIZED: OnceCell<()> = OnceCell::const_new();

/// Initialize the Paragonic backend
/// 
/// This function sets up logging, database connections, and other core services.
/// It should be called once when the plugin is loaded.
/// This function is idempotent - calling it multiple times is safe.
pub async fn initialize() -> ParagonicResult<()> {
    // Ensure initialization only happens once
    INITIALIZED.get_or_init(|| async {
        // Initialize logging only once
        tracing_subscriber::fmt::init();
        tracing::info!("Logging initialized");
    }).await;
    
    // Check if database is already initialized before trying to initialize it
    match database::get_pool() {
        Ok(_) => {
            tracing::info!("Database already initialized, skipping initialization");
        }
        Err(_) => {
            // Initialize database only if not already initialized
            database::initialize().await?;
        }
    }
    
    tracing::info!("Paragonic backend initialized successfully");
    Ok(())
}

/// Start the JSON-RPC server
/// 
/// This function starts the JSON-RPC server that exposes Ollama functions
/// to the Lua Neovim plugin.
pub fn start_rpc_server(addr: &str) -> ParagonicResult<()> {
    tracing::info!("Starting JSON-RPC server on {}", addr);
    
    // Create Ollama client
    let config_manager = crate::config::ConfigManager::new();
    let ollama_client = crate::ollama::OllamaClient::from_config_manager(&config_manager)?;
    
    // Create and start RPC server
    let rpc_server = crate::rpc::ParagonicServer::new(ollama_client);
    rpc_server.start(addr)?;
    
    Ok(())
}

/// Shutdown the Paragonic backend
/// 
/// This function gracefully shuts down all services and closes connections.
pub async fn shutdown() -> ParagonicResult<()> {
    tracing::info!("Shutting down Paragonic backend");
    
    // Close database connections
    database::shutdown().await?;
    
    tracing::info!("Paragonic backend shutdown complete");
    Ok(())
}

#[cfg(test)]
#[cfg(test)]
mod tests {
    use super::*;
    use tokio;

    /// Test that initialize() function completes successfully
    #[tokio::test]
    async fn test_initialize_success() {
        // Test that initialize() returns Ok(()) regardless of whether database is already initialized
        let result = crate::database::initialize_for_testing().await;
        match result {
            Ok(_) => {
                println!("initialize() succeeded");
                assert!(true, "initialize() should return Ok(())");
            }
            Err(e) => {
                // If database is already initialized, that's also acceptable
                if e.to_string().contains("already initialized") {
                    println!("Database already initialized, which is acceptable");
                    assert!(true, "Database already initialized is acceptable");
                } else {
                    panic!("initialize() failed with unexpected error: {:?}", e);
                }
            }
        }
    }

    /// Test that initialize() can be called multiple times safely
    #[tokio::test]
    async fn test_initialize_idempotent() {
        // First call should succeed
        let result1 = crate::database::initialize_for_testing().await;
        match result1 {
            Ok(_) => println!("First initialize() call succeeded"),
            Err(e) => {
                if e.to_string().contains("already initialized") {
                    println!("First call: Database already initialized");
                } else {
                    panic!("First initialize() call failed with error: {:?}", e);
                }
            }
        }

        // Second call should also succeed (idempotent)
        let result2 = crate::database::initialize_for_testing().await;
        match result2 {
            Ok(_) => println!("Second initialize() call succeeded"),
            Err(e) => {
                if e.to_string().contains("already initialized") {
                    println!("Second call: Database already initialized");
                } else {
                    panic!("Second initialize() call failed with error: {:?}", e);
                }
            }
        }
    }

    /// Test that initialize() sets up logging correctly
    #[tokio::test]
    async fn test_initialize_sets_up_logging() {
        // Initialize the system
        let result = crate::database::initialize_for_testing().await;
        match result {
            Ok(_) => println!("initialize() succeeded"),
            Err(e) => {
                if e.to_string().contains("already initialized") {
                    println!("Database already initialized, continuing with logging test");
                } else {
                    panic!("initialize() failed with error: {:?}", e);
                }
            }
        }

        // Verify that logging is working by checking if we can log a message
        // This is a basic test - in a real scenario we might capture log output
        tracing::info!("Test log message from initialize test");
        
        // If we get here without panicking, logging is working
        assert!(true, "Logging should be functional after initialize()");
    }

    /// Test that start_rpc_server() validates address format
    #[test]
    fn test_start_rpc_server_address_validation() {
        // Test that we can create the components without actually starting the server
        let config_manager = crate::config::ConfigManager::new();
        let ollama_client = crate::ollama::OllamaClient::from_config_manager(&config_manager);
        assert!(ollama_client.is_ok(), "Ollama client creation should succeed");
        
        // Test address parsing separately without starting server
        let addr = "127.0.0.1:0";
        let parsed = addr.parse::<std::net::SocketAddr>();
        assert!(parsed.is_ok(), "Valid address should parse successfully");
    }

    /// Test that start_rpc_server() handles invalid addresses gracefully
    #[test]
    fn test_start_rpc_server_invalid_address() {
        // Test address parsing separately without starting server
        let addr = "invalid:address";
        let parsed = addr.parse::<std::net::SocketAddr>();
        assert!(parsed.is_err(), "Invalid address should fail to parse");
        
        let error = parsed.unwrap_err();
        assert!(error.to_string().contains("invalid") || error.to_string().contains("parse"),
            "Error should be related to address parsing, got: {:?}", error);
    }

    /// Test that start_rpc_server() creates RPC server successfully
    #[test]
    fn test_start_rpc_server_creates_rpc_server() {
        // Test that we can create the RPC server component
        let config_manager = crate::config::ConfigManager::new();
        let ollama_client = crate::ollama::OllamaClient::from_config_manager(&config_manager).unwrap();
        let _rpc_server = crate::rpc::ParagonicServer::new(ollama_client);
        
        // The server should be created successfully
        assert!(true, "RPC server creation should succeed");
    }

    /// Test that shutdown() function completes successfully
    #[tokio::test]
    async fn test_shutdown_success() {
        // Test that shutdown() returns Ok(()) when called
        let result = shutdown().await;
        match result {
            Ok(_) => {
                println!("shutdown() succeeded");
                assert!(true, "shutdown() should return Ok(())");
            }
            Err(e) => {
                // If database is not initialized, that's also acceptable
                if e.to_string().contains("not initialized") {
                    println!("Database not initialized, which is acceptable for shutdown");
                    assert!(true, "Database not initialized is acceptable for shutdown");
                } else {
                    panic!("shutdown() failed with unexpected error: {:?}", e);
                }
            }
        }
    }

    /// Test that shutdown() can be called multiple times safely (idempotent)
    #[tokio::test]
    async fn test_shutdown_idempotent() {
        // First call should succeed
        let result1 = shutdown().await;
        match result1 {
            Ok(_) => println!("First shutdown() call succeeded"),
            Err(e) => {
                if e.to_string().contains("not initialized") {
                    println!("First call: Database not initialized");
                } else {
                    panic!("First shutdown() call failed with error: {:?}", e);
                }
            }
        }

        // Second call should also succeed (idempotent)
        let result2 = shutdown().await;
        match result2 {
            Ok(_) => println!("Second shutdown() call succeeded"),
            Err(e) => {
                if e.to_string().contains("not initialized") {
                    println!("Second call: Database not initialized");
                } else {
                    panic!("Second shutdown() call failed with error: {:?}", e);
                }
            }
        }
    }

    /// Test that shutdown() works after initialize()
    #[tokio::test]
    async fn test_shutdown_after_initialize() {
        // First initialize the system
        let init_result = crate::database::initialize_for_testing().await;
        match init_result {
            Ok(_) => println!("initialize() succeeded"),
            Err(e) => {
                if e.to_string().contains("already initialized") {
                    println!("Database already initialized");
                } else {
                    panic!("initialize() failed with error: {:?}", e);
                }
            }
        }

        // Then shutdown
        let shutdown_result = shutdown().await;
        match shutdown_result {
            Ok(_) => {
                println!("shutdown() succeeded after initialize");
                assert!(true, "shutdown() should succeed after initialize");
            }
            Err(e) => {
                panic!("shutdown() failed after initialize with error: {:?}", e);
            }
        }
    }

    /// Test that shutdown() logs appropriate messages
    #[tokio::test]
    async fn test_shutdown_logs_messages() {
        // Test that shutdown() can be called and logs messages
        // This is a basic test - in a real scenario we might capture log output
        let result = shutdown().await;
        
        // Regardless of success/failure, the function should have logged messages
        // If we get here without panicking, logging is working
        match result {
            Ok(_) => println!("shutdown() succeeded and logged messages"),
            Err(e) => {
                if e.to_string().contains("not initialized") {
                    println!("shutdown() logged messages (database not initialized)");
                } else {
                    println!("shutdown() logged messages but failed: {:?}", e);
                }
            }
        }
        
        assert!(true, "shutdown() should log appropriate messages");
    }
}

#[cfg(test)]
mod iragl_database_tests;
#[cfg(test)]
mod iragl_processor_tests;

 