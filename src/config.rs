//! Configuration management for Paragonic
//!
//! This module handles configuration loading from environment variables,
//! TOML files, and default values with proper precedence.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::env;
use std::fs;
use std::path::Path;
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
    pub progress_timeout_seconds: u64,
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
            progress_timeout_seconds: 30,
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

    /// Load configuration from a TOML file
    ///
    /// This function reads a TOML configuration file and merges it with
    /// the current configuration. File values take precedence over defaults
    /// but environment variables will override file values.
    pub fn load_from_toml<P: AsRef<Path>>(&mut self, path: P) -> ParagonicResult<()> {
        debug!("Loading configuration from TOML file: {:?}", path.as_ref());

        let content = fs::read_to_string(path.as_ref()).map_err(|e| {
            ParagonicError::Io(std::io::Error::new(
                std::io::ErrorKind::NotFound,
                format!("Configuration file not found: {e}"),
            ))
        })?;

        // Parse TOML as a generic value first to handle partial configurations
        let toml_value: toml::Value = toml::from_str(&content).map_err(|e| {
            ParagonicError::InvalidInput(format!("Invalid TOML configuration: {e}"))
        })?;

        // Apply TOML values to current configuration
        self.apply_toml_value(&toml_value);

        debug!("Configuration loaded from TOML file");
        Ok(())
    }

    /// Apply TOML values to the current configuration
    fn apply_toml_value(&mut self, toml_value: &toml::Value) {
        if let Some(database) = toml_value.get("database") {
            if let Some(host) = database.get("host").and_then(|v| v.as_str()) {
                self.config.database.host = host.to_string();
            }
            if let Some(port) = database.get("port").and_then(|v| v.as_integer()) {
                self.config.database.port = port as u16;
            }
            if let Some(username) = database.get("username").and_then(|v| v.as_str()) {
                self.config.database.username = username.to_string();
            }
            if let Some(password) = database.get("password").and_then(|v| v.as_str()) {
                self.config.database.password = password.to_string();
            }
            if let Some(database_name) = database.get("database").and_then(|v| v.as_str()) {
                self.config.database.database = database_name.to_string();
            }
            if let Some(max_connections) =
                database.get("max_connections").and_then(|v| v.as_integer())
            {
                self.config.database.max_connections = max_connections as u32;
            }
        }

        if let Some(ollama) = toml_value.get("ollama") {
            if let Some(base_url) = ollama.get("base_url").and_then(|v| v.as_str()) {
                self.config.ollama.base_url = base_url.to_string();
            }
            if let Some(timeout_seconds) =
                ollama.get("timeout_seconds").and_then(|v| v.as_integer())
            {
                self.config.ollama.timeout_seconds = timeout_seconds as u64;
            }
            if let Some(progress_timeout_seconds) = ollama
                .get("progress_timeout_seconds")
                .and_then(|v| v.as_integer())
            {
                self.config.ollama.progress_timeout_seconds = progress_timeout_seconds as u64;
            }
        }

        if let Some(logging) = toml_value.get("logging") {
            if let Some(level) = logging.get("level").and_then(|v| v.as_str()) {
                self.config.logging.level = level.to_string();
            }
            if let Some(format) = logging.get("format").and_then(|v| v.as_str()) {
                self.config.logging.format = format.to_string();
            }
        }
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
            "progress_timeout_seconds" => {
                self.config.ollama.progress_timeout_seconds = value.parse().map_err(|_| {
                    ParagonicError::InvalidInput(format!(
                        "Invalid progress_timeout_seconds: {value}"
                    ))
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

    /// Load configuration from all sources with proper precedence
    ///
    /// This function loads configuration in the following order:
    /// 1. Default values (lowest priority)
    /// 2. TOML configuration file (if exists)
    /// 3. Environment variables (highest priority)
    ///
    /// The precedence order ensures that environment variables can override
    /// file settings, and file settings can override defaults.
    pub fn load_configuration<P: AsRef<Path>>(
        &mut self,
        config_path: Option<P>,
    ) -> ParagonicResult<()> {
        debug!("Loading configuration from all sources");

        // Start with default values (already set in ConfigManager::new())

        // Load from TOML file if provided
        if let Some(path) = config_path {
            if path.as_ref().exists() {
                self.load_from_toml(path)?;
            } else {
                debug!(
                    "Configuration file not found, skipping: {:?}",
                    path.as_ref()
                );
            }
        }

        // Load from environment variables (highest priority)
        self.load_from_env()?;

        debug!("Configuration loaded from all sources successfully");
        Ok(())
    }

    /// Load configuration from standard locations
    ///
    /// This function looks for configuration files in standard locations:
    /// 1. Current directory: `paragonic.toml`
    /// 2. User config directory: `~/.config/paragonic/config.toml`
    /// 3. System config directory: `/etc/paragonic/config.toml`
    pub fn load_from_standard_locations(&mut self) -> ParagonicResult<()> {
        debug!("Loading configuration from standard locations");

        // Try current directory first
        let current_dir_config = std::env::current_dir()
            .map(|dir| dir.join("paragonic.toml"))
            .unwrap_or_else(|_| std::path::PathBuf::from("paragonic.toml"));

        if current_dir_config.exists() {
            debug!(
                "Loading configuration from current directory: {:?}",
                current_dir_config
            );
            self.load_from_toml(&current_dir_config)?;
        }

        // Try user config directory
        if let Some(user_config_dir) = dirs::config_dir() {
            let user_config = user_config_dir.join("paragonic").join("config.toml");
            if user_config.exists() {
                debug!("Loading configuration from user config: {:?}", user_config);
                self.load_from_toml(&user_config)?;
            }
        }

        // Try system config directory (Unix-like systems)
        #[cfg(unix)]
        {
            let system_config = std::path::PathBuf::from("/etc/paragonic/config.toml");
            if system_config.exists() {
                debug!(
                    "Loading configuration from system config: {:?}",
                    system_config
                );
                self.load_from_toml(&system_config)?;
            }
        }

        // Load environment variables (highest priority)
        self.load_from_env()?;

        debug!("Configuration loaded from standard locations");
        Ok(())
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
    use std::env;
    use std::fs;

    /// Clean up all Paragonic environment variables to prevent test interference
    fn cleanup_paragonic_env_vars() {
        env::remove_var("PARAGONIC_DATABASE_HOST");
        env::remove_var("PARAGONIC_DATABASE_PORT");
        env::remove_var("PARAGONIC_DATABASE_USERNAME");
        env::remove_var("PARAGONIC_DATABASE_PASSWORD");
        env::remove_var("PARAGONIC_DATABASE_DATABASE");
        env::remove_var("PARAGONIC_DATABASE_MAX_CONNECTIONS");
        env::remove_var("PARAGONIC_OLLAMA_BASE_URL");
        env::remove_var("PARAGONIC_OLLAMA_TIMEOUT_SECONDS");
        env::remove_var("PARAGONIC_LOGGING_LEVEL");
        env::remove_var("PARAGONIC_LOGGING_FORMAT");
    }

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
    fn test_serialized_environment_tests() {
        // Run all environment-related tests in sequence to prevent conflicts
        test_database_host_override();
        test_multiple_database_overrides();
        test_ollama_overrides();
        test_logging_overrides();
        test_invalid_port_number();
        test_ignore_non_paragonic_env_vars();
        test_toml_and_env_precedence();
        test_load_configuration_with_file_and_env();
        test_load_configuration_without_file();
    }

    #[test]
    #[ignore]
    fn test_database_host_override() {
        // Clean up any existing environment variables first
        cleanup_paragonic_env_vars();

        let mut manager = ConfigManager::new();

        // Set environment variable
        env::set_var("PARAGONIC_DATABASE_HOST", "test-host");

        // Load from environment
        manager.load_from_env().unwrap();

        // Verify override
        let config = manager.get_config();
        assert_eq!(config.database.host, "test-host");

        // Clean up
        cleanup_paragonic_env_vars();
    }

    #[test]
    #[ignore]
    fn test_multiple_database_overrides() {
        // Clean up any existing environment variables first
        cleanup_paragonic_env_vars();

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
        cleanup_paragonic_env_vars();
    }

    #[test]
    #[ignore]
    fn test_ollama_overrides() {
        // Clean up any existing environment variables first
        cleanup_paragonic_env_vars();

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
        cleanup_paragonic_env_vars();
    }

    #[test]
    #[ignore]
    fn test_logging_overrides() {
        // Clean up any existing environment variables first
        cleanup_paragonic_env_vars();

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
        cleanup_paragonic_env_vars();
    }

    #[test]
    #[ignore]
    fn test_invalid_port_number() {
        // Clean up any existing environment variables first
        cleanup_paragonic_env_vars();

        let mut manager = ConfigManager::new();

        // Set invalid port
        env::set_var("PARAGONIC_DATABASE_PORT", "invalid");

        // Load from environment should fail
        let result = manager.load_from_env();
        assert!(result.is_err());

        // Clean up
        cleanup_paragonic_env_vars();
    }

    #[test]
    #[ignore]
    fn test_ignore_non_paragonic_env_vars() {
        // Clean up any existing environment variables first
        env::remove_var("OTHER_VAR");
        cleanup_paragonic_env_vars();

        // Create a fresh manager with default values
        let mut manager = ConfigManager::new();

        // Verify we start with default values
        let config = manager.get_config();
        assert_eq!(config.database.host, "localhost");
        assert_eq!(config.ollama.base_url, "http://localhost:11434");

        // Set non-Paragonic environment variable
        env::set_var("OTHER_VAR", "other-value");

        // Load from environment
        manager.load_from_env().unwrap();

        // Verify default values are still unchanged
        let config = manager.get_config();
        assert_eq!(config.database.host, "localhost");
        assert_eq!(config.ollama.base_url, "http://localhost:11434");

        // Clean up
        env::remove_var("OTHER_VAR");
        cleanup_paragonic_env_vars();
    }

    #[test]
    #[ignore]
    fn test_load_from_toml_file() {
        let mut manager = ConfigManager::new();

        // Create a temporary TOML file
        let toml_content = r#"
[database]
host = "toml-host"
port = 5433
username = "toml-user"
password = "toml-pass"
database = "toml-db"
max_connections = 15

[ollama]
base_url = "http://toml-ollama:11435"
timeout_seconds = 45

[logging]
level = "debug"
format = "text"
"#;

        let temp_dir = std::env::temp_dir();
        let config_path = temp_dir.join("test_config.toml");

        // Write TOML content to file
        fs::write(&config_path, toml_content).unwrap();

        // Load from TOML file
        manager.load_from_toml(&config_path).unwrap();

        // Verify TOML values are loaded
        let config = manager.get_config();
        assert_eq!(config.database.host, "toml-host");
        assert_eq!(config.database.port, 5433);
        assert_eq!(config.database.username, "toml-user");
        assert_eq!(config.database.password, "toml-pass");
        assert_eq!(config.database.database, "toml-db");
        assert_eq!(config.database.max_connections, 15);
        assert_eq!(config.ollama.base_url, "http://toml-ollama:11435");
        assert_eq!(config.ollama.timeout_seconds, 45);
        assert_eq!(config.logging.level, "debug");
        assert_eq!(config.logging.format, "text");

        // Clean up
        let _ = fs::remove_file(&config_path);
    }

    #[test]
    #[ignore]
    fn test_toml_and_env_precedence() {
        // Clean up any existing environment variables first
        cleanup_paragonic_env_vars();

        let mut manager = ConfigManager::new();

        // Create a TOML file with some values
        let toml_content = r#"
[database]
host = "toml-host"
port = 5433
"#;

        let temp_dir = std::env::temp_dir();
        let config_path = temp_dir.join("test_precedence.toml");

        // Write TOML content to file
        fs::write(&config_path, toml_content).unwrap();

        // Load from TOML file first
        manager.load_from_toml(&config_path).unwrap();

        // Verify TOML values are loaded
        let config = manager.get_config();
        assert_eq!(config.database.host, "toml-host");
        assert_eq!(config.database.port, 5433);

        // Set environment variable to override TOML
        env::set_var("PARAGONIC_DATABASE_HOST", "env-host");

        // Load from environment (should override TOML)
        manager.load_from_env().unwrap();

        // Verify environment variable takes precedence
        let config = manager.get_config();
        assert_eq!(config.database.host, "env-host"); // Environment overrides TOML
        assert_eq!(config.database.port, 5433); // TOML value remains for non-overridden field

        // Clean up
        cleanup_paragonic_env_vars();
        let _ = fs::remove_file(&config_path);
    }

    #[test]
    #[ignore]
    fn test_load_configuration_with_file_and_env() {
        // Clean up any existing environment variables first
        cleanup_paragonic_env_vars();

        let mut manager = ConfigManager::new();

        // Create a TOML file
        let toml_content = r#"
[database]
host = "toml-host"
port = 5433
"#;

        let temp_dir = std::env::temp_dir();
        let config_path = temp_dir.join("test_comprehensive.toml");

        // Write TOML content to file
        fs::write(&config_path, toml_content).unwrap();

        // Set environment variable to override TOML
        env::set_var("PARAGONIC_DATABASE_HOST", "env-host");

        // Load configuration from all sources
        manager.load_configuration(Some(&config_path)).unwrap();

        // Verify environment variable takes precedence over TOML
        let config = manager.get_config();
        assert_eq!(config.database.host, "env-host"); // Environment overrides TOML
        assert_eq!(config.database.port, 5433); // TOML value for non-overridden field
        assert_eq!(config.database.username, "paragonic"); // Default value

        // Clean up
        cleanup_paragonic_env_vars();
        let _ = fs::remove_file(&config_path);
    }

    #[test]
    #[ignore]
    fn test_load_configuration_without_file() {
        // Clean up any existing environment variables first
        cleanup_paragonic_env_vars();

        let mut manager = ConfigManager::new();

        // Set environment variable
        env::set_var("PARAGONIC_DATABASE_HOST", "env-only-host");

        // Load configuration without file
        manager
            .load_configuration::<std::path::PathBuf>(None)
            .unwrap();

        // Verify environment variable is applied
        let config = manager.get_config();
        assert_eq!(config.database.host, "env-only-host");
        assert_eq!(config.database.port, 5432); // Default value

        // Clean up
        cleanup_paragonic_env_vars();
    }
}
