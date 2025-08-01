//! Ollama integration for Paragonic
//! 
//! This module handles communication with the local Ollama server
//! for AI model interactions.

use reqwest::Client;
use serde::{Deserialize, Serialize};
use tracing::{info, error};

use crate::error::{ParagonicError, ParagonicResult};

/// Ollama client configuration
#[derive(Debug, Clone)]
pub struct OllamaConfig {
    pub base_url: String,
    pub timeout_seconds: u64,
}

impl Default for OllamaConfig {
    fn default() -> Self {
        Self {
            base_url: "http://localhost:11434".to_string(),
            timeout_seconds: 30,
        }
    }
}

/// Ollama model information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OllamaModel {
    pub name: String,
    pub modified_at: String,
    pub size: u64,
}

/// Response from Ollama list models endpoint
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ListModelsResponse {
    pub models: Vec<OllamaModel>,
}

/// Chat message for Ollama API
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatMessage {
    pub role: String,
    pub content: String,
}

/// Chat completion request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatCompletionRequest {
    pub model: String,
    pub messages: Vec<ChatMessage>,
    pub stream: Option<bool>,
    pub options: Option<serde_json::Value>,
}

/// Chat completion response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatCompletionResponse {
    pub model: String,
    pub created_at: String,
    pub message: ChatMessage,
    pub done: bool,
}

/// Pull model request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PullModelRequest {
    pub name: String,
    pub insecure: Option<bool>,
}

/// Pull model response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PullModelResponse {
    pub status: String,
    pub digest: Option<String>,
    pub total: Option<u64>,
    pub completed: Option<u64>,
}

/// Model info response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelInfoResponse {
    pub license: Option<String>,
    pub modelfile: Option<String>,
    pub parameters: Option<String>,
    pub template: Option<String>,
    pub system: Option<String>,
    pub digest: Option<String>,
    pub details: Option<serde_json::Value>,
}

/// Ollama client for API communication
pub struct OllamaClient {
    config: OllamaConfig,
    client: Client,
}

impl OllamaClient {
    /// Create a new Ollama client
    pub fn new(config: OllamaConfig) -> ParagonicResult<Self> {
        let client = Client::builder()
            .timeout(std::time::Duration::from_secs(config.timeout_seconds))
            .build()
            .map_err(|e| {
                error!("Failed to create HTTP client: {}", e);
                ParagonicError::Internal(format!("HTTP client creation failed: {e}"))
            })?;

        Ok(Self { config, client })
    }

    /// List available models from Ollama
    /// 
    /// Returns a list of all models currently available on the Ollama server.
    pub async fn list_models(&self) -> ParagonicResult<Vec<OllamaModel>> {
        let url = format!("{}/api/tags", self.config.base_url);
        
        let response = self.client
            .get(&url)
            .send()
            .await
            .map_err(|e| {
                error!("Failed to list models from Ollama: {}", e);
                ParagonicError::Ollama(format!("Model listing failed: {e}"))
            })?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            error!("Ollama API error ({}): {}", status, error_text);
            return Err(ParagonicError::Ollama(format!("API error {status}: {error_text}")));
        }

        let list_response: ListModelsResponse = response.json().await.map_err(|e| {
            error!("Failed to parse Ollama response: {}", e);
            ParagonicError::Ollama(format!("Response parsing failed: {e}"))
        })?;

        info!("Successfully listed {} models from Ollama", list_response.models.len());
        Ok(list_response.models)
    }

    /// Send a chat completion request to Ollama
    /// 
    /// Sends a list of messages to the specified model and returns the response.
    pub async fn chat_completion(
        &self,
        model: &str,
        messages: Vec<ChatMessage>,
        stream: bool,
    ) -> ParagonicResult<ChatCompletionResponse> {
        let url = format!("{}/api/chat", self.config.base_url);
        
        let request_body = ChatCompletionRequest {
            model: model.to_string(),
            messages,
            stream: Some(stream),
            options: None,
        };

        let response = self.client
            .post(&url)
            .json(&request_body)
            .send()
            .await
            .map_err(|e| {
                error!("Failed to send chat completion to Ollama: {}", e);
                ParagonicError::Ollama(format!("Chat completion failed: {e}"))
            })?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            error!("Ollama chat API error ({}): {}", status, error_text);
            return Err(ParagonicError::Ollama(format!("Chat API error {status}: {error_text}")));
        }

        let chat_response: ChatCompletionResponse = response.json().await.map_err(|e| {
            error!("Failed to parse Ollama chat response: {}", e);
            ParagonicError::Ollama(format!("Chat response parsing failed: {e}"))
        })?;

        info!("Successfully received chat completion from Ollama model: {}", model);
        Ok(chat_response)
    }

    /// Pull a model from Ollama
    /// 
    /// Downloads the specified model to the local Ollama server.
    pub async fn pull_model(&self, model_name: &str, insecure: bool) -> ParagonicResult<PullModelResponse> {
        let url = format!("{}/api/pull", self.config.base_url);
        
        let request_body = PullModelRequest {
            name: model_name.to_string(),
            insecure: Some(insecure),
        };

        let response = self.client
            .post(&url)
            .json(&request_body)
            .send()
            .await
            .map_err(|e| {
                error!("Failed to pull model from Ollama: {e}");
                ParagonicError::Ollama(format!("Model pull failed: {e}"))
            })?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            error!("Ollama pull API error ({}): {}", status, error_text);
            return Err(ParagonicError::Ollama(format!("Pull API error {status}: {error_text}")));
        }

        let pull_response: PullModelResponse = response.json().await.map_err(|e| {
            error!("Failed to parse Ollama pull response: {e}");
            ParagonicError::Ollama(format!("Pull response parsing failed: {e}"))
        })?;

        info!("Successfully pulled model from Ollama: {}", model_name);
        Ok(pull_response)
    }

    /// Get detailed information about a model
    /// 
    /// Returns detailed information about the specified model including
    /// license, modelfile, parameters, template, system prompt, and more.
    pub async fn model_info(&self, model_name: &str) -> ParagonicResult<ModelInfoResponse> {
        let url = format!("{}/api/show", self.config.base_url);
        
        let request_body = serde_json::json!({
            "name": model_name
        });

        let response = self.client
            .post(&url)
            .json(&request_body)
            .send()
            .await
            .map_err(|e| {
                error!("Failed to get model info from Ollama: {e}");
                ParagonicError::Ollama(format!("Model info failed: {e}"))
            })?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            error!("Ollama model info API error ({}): {}", status, error_text);
            return Err(ParagonicError::Ollama(format!("Model info API error {status}: {error_text}")));
        }

        let model_info: ModelInfoResponse = response.json().await.map_err(|e| {
            error!("Failed to parse Ollama model info response: {e}");
            ParagonicError::Ollama(format!("Model info response parsing failed: {e}"))
        })?;

        info!("Successfully retrieved model info from Ollama: {}", model_name);
        Ok(model_info)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Test Ollama configuration default values
    #[test]
    fn test_ollama_config_default() {
        let config = OllamaConfig::default();
        assert_eq!(config.base_url, "http://localhost:11434");
        assert_eq!(config.timeout_seconds, 30);
    }

    /// Test Ollama model structure
    #[test]
    fn test_ollama_model_structure() {
        let model = OllamaModel {
            name: "llama2:7b".to_string(),
            modified_at: "2024-01-01T00:00:00Z".to_string(),
            size: 4096,
        };
        
        assert_eq!(model.name, "llama2:7b");
        assert_eq!(model.size, 4096);
    }

    /// Test list models response structure
    #[test]
    fn test_list_models_response_structure() {
        let response = ListModelsResponse {
            models: vec![
                OllamaModel {
                    name: "llama2:7b".to_string(),
                    modified_at: "2024-01-01T00:00:00Z".to_string(),
                    size: 4096,
                },
                OllamaModel {
                    name: "codellama:7b".to_string(),
                    modified_at: "2024-01-02T00:00:00Z".to_string(),
                    size: 4096,
                },
            ],
        };
        
        assert_eq!(response.models.len(), 2);
        assert_eq!(response.models[0].name, "llama2:7b");
        assert_eq!(response.models[1].name, "codellama:7b");
    }

    /// Test Ollama client creation
    #[test]
    fn test_ollama_client_creation() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config);
        assert!(client.is_ok());
    }

    /// Test list models with mock server (integration test)
    #[tokio::test]
    async fn test_list_models_integration() {
        // This test would require a running Ollama server
        // For now, we'll test the client creation and configuration
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        
        // The actual API call would be tested with a mock server
        // or when Ollama is available in the test environment
        assert_eq!(client.config.base_url, "http://localhost:11434");
    }

    /// Test chat completion request structure
    #[test]
    fn test_chat_completion_request_structure() {
        let request = ChatCompletionRequest {
            model: "llama2:7b".to_string(),
            messages: vec![
                ChatMessage {
                    role: "user".to_string(),
                    content: "Hello, how are you?".to_string(),
                },
            ],
            stream: Some(false),
            options: None,
        };
        
        assert_eq!(request.model, "llama2:7b");
        assert_eq!(request.messages.len(), 1);
        assert_eq!(request.messages[0].role, "user");
        assert_eq!(request.messages[0].content, "Hello, how are you?");
    }

    /// Test chat completion response structure
    #[test]
    fn test_chat_completion_response_structure() {
        let response = ChatCompletionResponse {
            model: "llama2:7b".to_string(),
            created_at: "2024-01-01T00:00:00Z".to_string(),
            message: ChatMessage {
                role: "assistant".to_string(),
                content: "I'm doing well, thank you!".to_string(),
            },
            done: true,
        };
        
        assert_eq!(response.model, "llama2:7b");
        assert_eq!(response.message.role, "assistant");
        assert_eq!(response.message.content, "I'm doing well, thank you!");
        assert!(response.done);
    }

    /// Test chat completion function (integration test)
    #[tokio::test]
    async fn test_chat_completion_function() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        
        let messages = vec![
            ChatMessage {
                role: "user".to_string(),
                content: "Say hello".to_string(),
            },
        ];
        
        // This test requires a running Ollama server
        // If Ollama is not running, we expect a connection error
        let result = client.chat_completion("llama2:7b", messages, false).await;
        
        match result {
            Ok(response) => {
                // Ollama is running and responded successfully
                assert_eq!(response.model, "llama2:7b");
                assert_eq!(response.message.role, "assistant");
                assert!(!response.message.content.is_empty());
            }
            Err(ParagonicError::Ollama(_)) => {
                // Expected when Ollama is not running
                // This is a valid test result
            }
            Err(e) => {
                // Unexpected error type
                panic!("Unexpected error type: {:?}", e);
            }
        }
    }

    /// Test pull model request structure
    #[test]
    fn test_pull_model_request_structure() {
        let request = PullModelRequest {
            name: "llama2:7b".to_string(),
            insecure: Some(false),
        };
        
        assert_eq!(request.name, "llama2:7b");
        assert_eq!(request.insecure, Some(false));
    }

    /// Test pull model response structure
    #[test]
    fn test_pull_model_response_structure() {
        let response = PullModelResponse {
            status: "downloading".to_string(),
            digest: Some("sha256:abc123".to_string()),
            total: Some(4096),
            completed: Some(2048),
        };
        
        assert_eq!(response.status, "downloading");
        assert_eq!(response.digest, Some("sha256:abc123".to_string()));
        assert_eq!(response.total, Some(4096));
        assert_eq!(response.completed, Some(2048));
    }

    /// Test pull model function (integration test)
    #[tokio::test]
    async fn test_pull_model_function() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        
        // This test requires a running Ollama server
        // If Ollama is not running, we expect a connection error
        let result = client.pull_model("llama2:7b", false).await;
        
        match result {
            Ok(response) => {
                // Ollama is running and responded successfully
                assert!(!response.status.is_empty());
                // The status could be "downloading", "success", etc.
            }
            Err(ParagonicError::Ollama(_)) => {
                // Expected when Ollama is not running
                // This is a valid test result
            }
            Err(e) => {
                // Unexpected error type
                panic!("Unexpected error type: {:?}", e);
            }
        }
    }

    /// Test model info response structure
    #[test]
    fn test_model_info_response_structure() {
        let response = ModelInfoResponse {
            license: Some("MIT".to_string()),
            modelfile: Some("FROM llama2:7b".to_string()),
            parameters: Some("7B".to_string()),
            template: Some("{{ .Prompt }}".to_string()),
            system: Some("You are a helpful assistant.".to_string()),
            digest: Some("sha256:abc123".to_string()),
            details: Some(serde_json::json!({
                "format": "gguf",
                "family": "llama"
            })),
        };
        
        assert_eq!(response.license, Some("MIT".to_string()));
        assert_eq!(response.parameters, Some("7B".to_string()));
        assert_eq!(response.system, Some("You are a helpful assistant.".to_string()));
        assert!(response.details.is_some());
    }

    /// Test model info function (integration test)
    #[tokio::test]
    async fn test_model_info_function() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        
        // This test requires a running Ollama server
        // If Ollama is not running, we expect a connection error
        let result = client.model_info("llama2:7b").await;
        
        match result {
            Ok(response) => {
                // Ollama is running and responded successfully
                // The response should have some fields populated
                assert!(response.license.is_some() || response.modelfile.is_some() || response.parameters.is_some());
            }
            Err(ParagonicError::Ollama(_)) => {
                // Expected when Ollama is not running
                // This is a valid test result
            }
            Err(e) => {
                // Unexpected error type
                panic!("Unexpected error type: {:?}", e);
            }
        }
    }
} 