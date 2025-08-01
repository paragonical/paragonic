//! Configuration management for Paragonic
//! 
//! This module handles configuration loading from environment variables,
//! TOML files, and default values with proper precedence.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::env;
use tracing::debug;

use crate::error::{ParagonicError, ParagonicResult};

/// Main configuration structure for Paragonic
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Config {
    pub database: DatabaseConfig,
    pub ollama: OllamaConfig,
    pub logging: LoggingConfig,
}

/// Database configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DatabaseConfig {
    pub host: String,
    pub port: u16,
    pub username: String,
    pub password: String,
    pub database: String,
    pub max_connections: u32,
}

/// Ollama configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OllamaConfig {
    pub base_url: String,
    pub timeout_seconds: u64,
}

/// Logging configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoggingConfig {
    pub level: String,
    pub format: String,
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

impl Default for OllamaConfig {
    fn default() -> Self {
        Self {
            base_url: "http://localhost:11434".to_string(),
            timeout_seconds: 30,
        }
    }
}

impl Default for LoggingConfig {
    fn default() -> Self {
        Self {
            level: "info".to_string(),
            format: "json".to_string(),
        }
    }
}

/// Configuration manager that handles loading and overriding configuration
pub struct ConfigManager {
    config: Config,
}

impl ConfigManager {
    /// Create a new configuration manager with default values
    pub fn new() -> Self {
        Self {
            config: Config::default(),
        }
    }

    /// Load configuration from environment variables
    /// 
    /// Environment variables follow the pattern: PARAGONIC_<SECTION>_<KEY>
    /// For example: PARAGONIC_DATABASE_HOST, PARAGONIC_OLLAMA_BASE_URL
    pub fn load_from_env(&mut self) -> ParagonicResult<()> {
        debug!("Loading configuration from environment variables");
        
        let env_vars: HashMap<String, String> = env::vars()
            .filter(|(key, _)| key.starts_with("PARAGONIC_"))
            .collect();

        for (key, value) in env_vars {
            self.apply_env_var(&key, &value)?;
        }

        debug!("Configuration loaded from environment variables");
        Ok(())
    }

    /// Apply a single environment variable to the configuration
    fn apply_env_var(&mut self, key: &str, value: &str) -> ParagonicResult<()> {
        let parts: Vec<&str> = key.split('_').collect();
        if parts.len() < 3 {
            return Ok(()); // Skip malformed keys
        }

        let section = parts[1].to_lowercase();
        let field = parts[2..].join("_").to_lowercase();

        match section.as_str() {
            "database" => self.apply_database_env_var(&field, value)?,
            "ollama" => self.apply_ollama_env_var(&field, value)?,
            "logging" => self.apply_logging_env_var(&field, value)?,
            _ => debug!("Unknown configuration section: {}", section),
        }

        Ok(())
    }

    /// Apply database environment variable
    fn apply_database_env_var(&mut self, field: &str, value: &str) -> ParagonicResult<()> {
        match field {
            "host" => self.config.database.host = value.to_string(),
            "port" => {
                self.config.database.port = value.parse().map_err(|_| {
                    ParagonicError::InvalidInput(format!("Invalid port number: {value}"))
                })?
            }
            "username" => self.config.database.username = value.to_string(),
            "password" => self.config.database.password = value.to_string(),
            "database" => self.config.database.database = value.to_string(),
            "max_connections" => {
                self.config.database.max_connections = value.parse().map_err(|_| {
                    ParagonicError::InvalidInput(format!("Invalid max_connections: {value}"))
                })?
            }
            _ => debug!("Unknown database field: {}", field),
        }
        Ok(())
    }

    /// Apply Ollama environment variable
    fn apply_ollama_env_var(&mut self, field: &str, value: &str) -> ParagonicResult<()> {
        match field {
            "base_url" => self.config.ollama.base_url = value.to_string(),
            "timeout_seconds" => {
                self.config.ollama.timeout_seconds = value.parse().map_err(|_| {
                    ParagonicError::InvalidInput(format!("Invalid timeout_seconds: {value}"))
                })?
            }
            _ => debug!("Unknown ollama field: {}", field),
        }
        Ok(())
    }

    /// Apply logging environment variable
    fn apply_logging_env_var(&mut self, field: &str, value: &str) -> ParagonicResult<()> {
        match field {
            "level" => self.config.logging.level = value.to_string(),
            "format" => self.config.logging.format = value.to_string(),
            _ => debug!("Unknown logging field: {}", field),
        }
        Ok(())
    }

    /// Get the current configuration
    pub fn get_config(&self) -> &Config {
        &self.config
    }

    /// Get a mutable reference to the configuration
    pub fn get_config_mut(&mut self) -> &mut Config {
        &mut self.config
    }
}

impl Default for ConfigManager {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_config_manager_creation() {
        let manager = ConfigManager::new();
        let config = manager.get_config();
        
        assert_eq!(config.database.host, "localhost");
        assert_eq!(config.database.port, 5432);
        assert_eq!(config.ollama.base_url, "http://localhost:11434");
        assert_eq!(config.logging.level, "info");
    }

    #[test]
    fn test_database_host_override() {
        // Clean up any existing environment variables first
        env::remove_var("PARAGONIC_DATABASE_HOST");
        env::remove_var("PARAGONIC_DATABASE_PORT");
        
        let mut manager = ConfigManager::new();
        
        // Set environment variable
        env::set_var("PARAGONIC_DATABASE_HOST", "test-host");
        
        // Load from environment
        manager.load_from_env().unwrap();
        
        // Verify override
        let config = manager.get_config();
        assert_eq!(config.database.host, "test-host");
        
        // Clean up
        env::remove_var("PARAGONIC_DATABASE_HOST");
    }

    #[test]
    fn test_multiple_database_overrides() {
        // Clean up any existing environment variables first
        env::remove_var("PARAGONIC_DATABASE_HOST");
        env::remove_var("PARAGONIC_DATABASE_PORT");
        env::remove_var("PARAGONIC_DATABASE_USERNAME");
        env::remove_var("PARAGONIC_DATABASE_PASSWORD");
        env::remove_var("PARAGONIC_DATABASE_DATABASE");
        env::remove_var("PARAGONIC_DATABASE_MAX_CONNECTIONS");
        
        let mut manager = ConfigManager::new();
        
        // Set multiple environment variables
        env::set_var("PARAGONIC_DATABASE_HOST", "test-host");
        env::set_var("PARAGONIC_DATABASE_PORT", "5433");
        env::set_var("PARAGONIC_DATABASE_USERNAME", "test-user");
        env::set_var("PARAGONIC_DATABASE_PASSWORD", "test-pass");
        env::set_var("PARAGONIC_DATABASE_DATABASE", "test-db");
        env::set_var("PARAGONIC_DATABASE_MAX_CONNECTIONS", "20");
        
        // Load from environment
        manager.load_from_env().unwrap();
        
        // Verify all overrides
        let config = manager.get_config();
        assert_eq!(config.database.host, "test-host");
        assert_eq!(config.database.port, 5433);
        assert_eq!(config.database.username, "test-user");
        assert_eq!(config.database.password, "test-pass");
        assert_eq!(config.database.database, "test-db");
        assert_eq!(config.database.max_connections, 20);
        
        // Clean up
        env::remove_var("PARAGONIC_DATABASE_HOST");
        env::remove_var("PARAGONIC_DATABASE_PORT");
        env::remove_var("PARAGONIC_DATABASE_USERNAME");
        env::remove_var("PARAGONIC_DATABASE_PASSWORD");
        env::remove_var("PARAGONIC_DATABASE_DATABASE");
        env::remove_var("PARAGONIC_DATABASE_MAX_CONNECTIONS");
    }

    #[test]
    fn test_ollama_overrides() {
        // Clean up any existing environment variables first
        env::remove_var("PARAGONIC_OLLAMA_BASE_URL");
        env::remove_var("PARAGONIC_OLLAMA_TIMEOUT_SECONDS");
        env::remove_var("PARAGONIC_DATABASE_PORT");
        
        let mut manager = ConfigManager::new();
        
        // Set Ollama environment variables
        env::set_var("PARAGONIC_OLLAMA_BASE_URL", "http://test-ollama:11435");
        env::set_var("PARAGONIC_OLLAMA_TIMEOUT_SECONDS", "60");
        
        // Load from environment
        manager.load_from_env().unwrap();
        
        // Verify overrides
        let config = manager.get_config();
        assert_eq!(config.ollama.base_url, "http://test-ollama:11435");
        assert_eq!(config.ollama.timeout_seconds, 60);
        
        // Clean up
        env::remove_var("PARAGONIC_OLLAMA_BASE_URL");
        env::remove_var("PARAGONIC_OLLAMA_TIMEOUT_SECONDS");
    }

    #[test]
    fn test_logging_overrides() {
        // Clean up any existing environment variables first
        env::remove_var("PARAGONIC_LOGGING_LEVEL");
        env::remove_var("PARAGONIC_LOGGING_FORMAT");
        env::remove_var("PARAGONIC_DATABASE_PORT");
        
        let mut manager = ConfigManager::new();
        
        // Set logging environment variables
        env::set_var("PARAGONIC_LOGGING_LEVEL", "debug");
        env::set_var("PARAGONIC_LOGGING_FORMAT", "text");
        
        // Load from environment
        manager.load_from_env().unwrap();
        
        // Verify overrides
        let config = manager.get_config();
        assert_eq!(config.logging.level, "debug");
        assert_eq!(config.logging.format, "text");
        
        // Clean up
        env::remove_var("PARAGONIC_LOGGING_LEVEL");
        env::remove_var("PARAGONIC_LOGGING_FORMAT");
    }

    #[test]
    fn test_invalid_port_number() {
        // Clean up any existing environment variables first
        env::remove_var("PARAGONIC_DATABASE_PORT");
        
        let mut manager = ConfigManager::new();
        
        // Set invalid port
        env::set_var("PARAGONIC_DATABASE_PORT", "invalid");
        
        // Load from environment should fail
        let result = manager.load_from_env();
        assert!(result.is_err());
        
        // Clean up
        env::remove_var("PARAGONIC_DATABASE_PORT");
    }

    #[test]
    fn test_ignore_non_paragonic_env_vars() {
        // Clean up any existing environment variables first
        env::remove_var("OTHER_VAR");
        env::remove_var("PARAGONIC_DATABASE_HOST");
        env::remove_var("PARAGONIC_DATABASE_PORT");
        env::remove_var("PARAGONIC_OLLAMA_BASE_URL");
        
        let mut manager = ConfigManager::new();
        
        // Set non-Paragonic environment variable
        env::set_var("OTHER_VAR", "other-value");
        
        // Load from environment
        manager.load_from_env().unwrap();
        
        // Verify default values are unchanged
        let config = manager.get_config();
        assert_eq!(config.database.host, "localhost");
        assert_eq!(config.ollama.base_url, "http://localhost:11434");
        
        // Clean up
        env::remove_var("OTHER_VAR");
    }
} 