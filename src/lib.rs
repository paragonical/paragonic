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

pub use error::{ParagonicError, ParagonicResult};

/// Initialize the Paragonic backend
/// 
/// This function sets up logging, database connections, and other core services.
/// It should be called once when the plugin is loaded.
pub async fn initialize() -> ParagonicResult<()> {
    // Initialize logging
    tracing_subscriber::fmt::init();
    
    // Initialize database
    database::initialize().await?;
    
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