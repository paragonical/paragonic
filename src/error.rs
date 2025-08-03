//! Error handling for the Paragonic project
//! 
//! This module defines custom error types and provides a unified error handling
//! approach across the entire application.

use thiserror::Error;

/// Custom error type for Paragonic operations
#[derive(Error, Debug)]
pub enum ParagonicError {
    #[error("Database error: {0}")]
    Database(String),
    
    #[error("Ollama API error: {0}")]
    Ollama(String),
    
    #[error("HTTP request error: {0}")]
    Http(#[from] reqwest::Error),
    
    #[error("Configuration error: {0}")]
    Config(#[from] config::ConfigError),
    
    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),
    
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    
    #[error("Invalid input: {0}")]
    InvalidInput(String),
    
    #[error("Not found: {0}")]
    NotFound(String),
    
    #[error("Unauthorized: {0}")]
    Unauthorized(String),
    
    #[error("Internal error: {0}")]
    Internal(String),
}

/// Result type for Paragonic operations
pub type ParagonicResult<T> = Result<T, ParagonicError>;

impl From<anyhow::Error> for ParagonicError {
    fn from(err: anyhow::Error) -> Self {
        ParagonicError::Internal(err.to_string())
    }
}

impl From<r2d2::Error> for ParagonicError {
    fn from(err: r2d2::Error) -> Self {
        ParagonicError::Database(format!("Connection pool error: {err}"))
    }
}

impl From<std::net::AddrParseError> for ParagonicError {
    fn from(err: std::net::AddrParseError) -> Self {
        ParagonicError::Internal(format!("Address parse error: {err}"))
    }
}

impl From<tantivy::TantivyError> for ParagonicError {
    fn from(err: tantivy::TantivyError) -> Self {
        ParagonicError::Internal(format!("Tantivy error: {err}"))
    }
}

impl From<tantivy::query::QueryParserError> for ParagonicError {
    fn from(err: tantivy::query::QueryParserError) -> Self {
        ParagonicError::Internal(format!("Query parser error: {err}"))
    }
}

impl From<uuid::Error> for ParagonicError {
    fn from(err: uuid::Error) -> Self {
        ParagonicError::Internal(format!("UUID parse error: {err}"))
    }
}

impl From<chrono::ParseError> for ParagonicError {
    fn from(err: chrono::ParseError) -> Self {
        ParagonicError::Internal(format!("Chrono parse error: {err}"))
    }
} 