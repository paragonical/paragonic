//! Error handling for the Paragonic project
//! 
//! This module defines custom error types and provides a unified error handling
//! approach across the entire application.

use std::net::AddrParseError;
use std::time::SystemTimeError;

#[derive(Debug, thiserror::Error)]
pub enum ParagonicError {
    #[error("Database error: {0}")]
    Database(String),
    
    #[error("Configuration error: {0}")]
    Config(String),
    
    #[error("Invalid input: {0}")]
    InvalidInput(String),
    
    #[error("Internal error: {0}")]
    Internal(String),
    
    #[error("Network error: {0}")]
    Network(String),
    
    #[error("Serialization error: {0}")]
    Serialization(String),
    
    #[error("Embedding error: {0}")]
    Embedding(String),
    
    #[error("Search error: {0}")]
    Search(String),
    
    #[error("RPC error: {0}")]
    Rpc(String),
    
    #[error("File error: {0}")]
    File(String),
    
    #[error("System time error: {0}")]
    SystemTime(#[from] SystemTimeError),
    
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    
    #[error("Ollama API error: {0}")]
    Ollama(String),
    
    #[error("Not found: {0}")]
    NotFound(String),
    
    #[error("Unauthorized: {0}")]
    Unauthorized(String),
    
    #[error("Timeout: {0}")]
    Timeout(String),
}

pub type ParagonicResult<T> = Result<T, ParagonicError>;

impl From<AddrParseError> for ParagonicError {
    fn from(err: AddrParseError) -> Self {
        ParagonicError::Network(format!("Address parse error: {}", err))
    }
}

impl From<ConfigError> for ParagonicError {
    fn from(err: ConfigError) -> Self {
        ParagonicError::Config(format!("Configuration error: {}", err))
    }
}

impl From<QueryParserError> for ParagonicError {
    fn from(err: QueryParserError) -> Self {
        ParagonicError::Search(format!("Query parser error: {}", err))
    }
}

impl From<TantivyError> for ParagonicError {
    fn from(err: TantivyError) -> Self {
        ParagonicError::Search(format!("Tantivy error: {}", err))
    }
}

impl From<anyhow::Error> for ParagonicError {
    fn from(err: anyhow::Error) -> Self {
        ParagonicError::Internal(format!("Anyhow error: {}", err))
    }
}

impl From<chrono::ParseError> for ParagonicError {
    fn from(err: chrono::ParseError) -> Self {
        ParagonicError::Serialization(format!("Chrono parse error: {}", err))
    }
}

impl From<r2d2::Error> for ParagonicError {
    fn from(err: r2d2::Error) -> Self {
        ParagonicError::Database(format!("R2D2 error: {}", err))
    }
}

impl From<reqwest::Error> for ParagonicError {
    fn from(err: reqwest::Error) -> Self {
        ParagonicError::Network(format!("Reqwest error: {}", err))
    }
}

impl From<serde_json::Error> for ParagonicError {
    fn from(err: serde_json::Error) -> Self {
        ParagonicError::Serialization(format!("Serde JSON error: {}", err))
    }
}

impl From<diesel::result::Error> for ParagonicError {
    fn from(err: diesel::result::Error) -> Self {
        ParagonicError::Database(format!("Diesel error: {}", err))
    }
}

impl From<diesel::ConnectionError> for ParagonicError {
    fn from(err: diesel::ConnectionError) -> Self {
        ParagonicError::Database(format!("Diesel connection error: {}", err))
    }
}

// Placeholder types for compilation
pub struct ConfigError;
impl std::fmt::Display for ConfigError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "Config error")
    }
}

pub struct QueryParserError;
impl std::fmt::Display for QueryParserError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "Query parser error")
    }
}

pub struct TantivyError;
impl std::fmt::Display for TantivyError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "Tantivy error")
    }
} 