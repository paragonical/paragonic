//! Paragonic - Agentic Neovim Extension
//! 
//! This library provides the Rust backend for the Paragonic Neovim plugin,
//! handling AI integration, database operations, and core business logic.

pub mod database;
// pub mod ollama;
// pub mod config;
pub mod error;
pub mod models;
pub mod schema;

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