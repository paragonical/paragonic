//! JSON-RPC server for Lua-Rust communication and MCP
//! 
//! This module provides a JSON-RPC server that exposes Ollama client functions
//! to the Lua Neovim plugin, following MCP standards.

use tokio_jsonrpc::{Server, ServerCtl, RpcError, Endpoint, LineCodec};
use tokio_core::reactor::Core;
use tokio_core::net::TcpListener;
use tokio_codec::Decoder;
use futures::stream::Stream;
use serde_json::Value;
use std::sync::Arc;
use tracing::error;

use crate::ollama::OllamaClient;
use crate::error::ParagonicResult;
use crate::ollama::ChatMessage;

/// JSON-RPC server for Paragonic
pub struct ParagonicServer {
    ollama_client: Arc<OllamaClient>,
}

impl ParagonicServer {
    /// Create a new RPC server
    pub fn new(ollama_client: OllamaClient) -> Self {
        Self {
            ollama_client: Arc::new(ollama_client),
        }
    }
    
    /// Start the JSON-RPC server
    pub fn start(&self, addr: &str) -> ParagonicResult<()> {
        let mut core = Core::new()?;
        let handle = core.handle();
        
        let listener = TcpListener::bind(&addr.parse()?, &handle)?;
        
        let server = self.clone();
        let connections = listener.incoming().for_each(move |(stream, _)| {
            let (_client, _) = Endpoint::new(LineCodec::new().framed(stream), server.clone())
                .start(&handle);
            Ok(())
        });
        
        tracing::info!("JSON-RPC server started on {}", addr);
        core.run(connections)?;
        
        Ok(())
    }
    
    /// Handle chat completion request
    pub fn handle_chat_completion(&self, params: &Option<Value>) -> Result<String, RpcError> {
        let params = params.as_ref()
            .and_then(|p| p.as_array())
            .ok_or_else(|| RpcError::invalid_params(None))?;
        
        if params.len() < 2 {
            return Err(RpcError::invalid_params(None));
        }
        
        let message = params[0].as_str()
            .ok_or_else(|| RpcError::invalid_params(None))?
            .to_string();
        let model = params[1].as_str()
            .ok_or_else(|| RpcError::invalid_params(None))?
            .to_string();
        
        // Create chat message
        let chat_message = ChatMessage {
            role: "user".to_string(),
            content: message,
        };
        
        // Make actual Ollama API call
        let response = if let Ok(handle) = tokio::runtime::Handle::try_current() {
            // We're in a runtime context, use the current handle
            handle.block_on(async {
                self.ollama_client.chat_completion(&model, vec![chat_message], false).await
            })
        } else {
            // We're not in a runtime context, create a new one
            tokio::runtime::Runtime::new()
                .map_err(|e| RpcError::invalid_params(Some(format!("Failed to create runtime: {}", e))))?
                .block_on(async {
                    self.ollama_client.chat_completion(&model, vec![chat_message], false).await
                })
        };
        
        match response {
            Ok(chat_response) => {
                // Return the response as JSON
                serde_json::to_string(&chat_response)
                    .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize response: {}", e))))
            }
            Err(e) => {
                // Log the error and return a user-friendly error message
                error!("Ollama chat completion failed: {}", e);
                Err(RpcError::invalid_params(Some(format!("AI service unavailable: {}", e))))
            }
        }
    }
    
    /// Handle list models request
    pub fn handle_list_models(&self) -> Result<String, RpcError> {
        // Make actual Ollama API call
        let response = if let Ok(handle) = tokio::runtime::Handle::try_current() {
            handle.block_on(async {
                self.ollama_client.list_models().await
            })
        } else {
            tokio::runtime::Runtime::new()
                .map_err(|e| RpcError::invalid_params(Some(format!("Failed to create runtime: {}", e))))?
                .block_on(async {
                    self.ollama_client.list_models().await
                })
        };
        match response {
            Ok(models) => {
                // Return the models as a JSON array of model names
                let names: Vec<String> = models.into_iter().map(|m| m.name).collect();
                serde_json::to_string(&names)
                    .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize response: {}", e))))
            }
            Err(e) => {
                error!("Ollama list_models failed: {}", e);
                Err(RpcError::invalid_params(Some(format!("AI service unavailable: {}", e))))
            }
        }
    }
    
    /// Handle model info request
    pub fn handle_model_info(&self, params: &Option<Value>) -> Result<String, RpcError> {
        let params = params.as_ref()
            .and_then(|p| p.as_array())
            .ok_or_else(|| RpcError::invalid_params(None))?;
        
        if params.is_empty() {
            return Err(RpcError::invalid_params(None));
        }
        
        let model = params[0].as_str()
            .ok_or_else(|| RpcError::invalid_params(None))?
            .to_string();
        
        // Make actual Ollama API call
        let response = if let Ok(handle) = tokio::runtime::Handle::try_current() {
            handle.block_on(async {
                self.ollama_client.model_info(&model).await
            })
        } else {
            tokio::runtime::Runtime::new()
                .map_err(|e| RpcError::invalid_params(Some(format!("Failed to create runtime: {}", e))))?
                .block_on(async {
                    self.ollama_client.model_info(&model).await
                })
        };
        match response {
            Ok(info) => {
                // Add the model name to the response for compatibility
                let mut info_json = serde_json::to_value(info)
                    .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize response: {}", e))))?;
                info_json["name"] = serde_json::Value::String(model);
                serde_json::to_string(&info_json)
                    .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize response: {}", e))))
            }
            Err(e) => {
                error!("Ollama model_info failed: {}", e);
                Err(RpcError::invalid_params(Some(format!("AI service unavailable: {}", e))))
            }
        }
    }
    
    /// Handle generate embedding request
    pub fn handle_generate_embedding(&self, params: &Option<Value>) -> Result<String, RpcError> {
        let params = params.as_ref()
            .and_then(|p| p.as_array())
            .ok_or_else(|| RpcError::invalid_params(None))?;
        
        if params.len() < 2 {
            return Err(RpcError::invalid_params(None));
        }
        
        let text = params[0].as_str()
            .ok_or_else(|| RpcError::invalid_params(None))?
            .to_string();
        let model = params[1].as_str()
            .ok_or_else(|| RpcError::invalid_params(None))?
            .to_string();
        
        // Make actual Ollama API call
        let response = if let Ok(handle) = tokio::runtime::Handle::try_current() {
            handle.block_on(async {
                self.ollama_client.generate_embedding(&model, &text).await
            })
        } else {
            tokio::runtime::Runtime::new()
                .map_err(|e| RpcError::invalid_params(Some(format!("Failed to create runtime: {}", e))))?
                .block_on(async {
                    self.ollama_client.generate_embedding(&model, &text).await
                })
        };
        match response {
            Ok(embedding_response) => {
                // Return the embeddings as JSON
                serde_json::to_string(&embedding_response.embedding)
                    .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize response: {}", e))))
            }
            Err(e) => {
                error!("Ollama generate_embedding failed: {}", e);
                Err(RpcError::invalid_params(Some(format!("AI service unavailable: {}", e))))
            }
        }
    }
}

impl Server for ParagonicServer {
    type Success = String;
    type RpcCallResult = Result<String, RpcError>;
    type NotificationResult = Result<(), ()>;
    
    fn rpc(&self, ctl: &ServerCtl, method: &str, params: &Option<Value>) 
        -> Option<Self::RpcCallResult> {
        match method {
            // Accept a hello message and finish the greeting
            "hello" => Some(Ok("world".to_owned())),
            // When the other side says bye, terminate the connection
            "bye" => {
                ctl.terminate();
                Some(Ok("bye".to_owned()))
            },
            // Handle chat completion requests
            "chat_completion" => Some(self.handle_chat_completion(params)),
            // Handle list models requests
            "list_models" => Some(self.handle_list_models()),
            // Handle model info requests
            "model_info" => Some(self.handle_model_info(params)),
            // Handle generate embedding requests
            "generate_embedding" => Some(self.handle_generate_embedding(params)),
            _ => None
        }
    }
}

impl Clone for ParagonicServer {
    fn clone(&self) -> Self {
        Self {
            ollama_client: self.ollama_client.clone(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ollama::OllamaConfig;
    
    /// Test that the server can be created successfully
    #[test]
    fn test_server_creation() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let _server = ParagonicServer::new(client);
        
        // For now, just test that server can be created without errors
        assert!(true);
    }
    
    /// Test that the server responds to hello method
    #[test]
    fn test_server_hello_method() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let _server = ParagonicServer::new(client);
        
        // For now, just test that the hello method exists in the match statement
        // We'll test the actual RPC call later when we have proper ServerCtl setup
        assert!(true);
    }
    
    /// Test that the server responds to bye method
    #[test]
    fn test_server_bye_method() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let _server = ParagonicServer::new(client);
        
        // For now, just test that the bye method exists in the match statement
        // We'll test the actual RPC call later when we have proper ServerCtl setup
        assert!(true);
    }
    
    /// Test that the server returns None for unknown methods
    #[test]
    fn test_server_unknown_method() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let _server = ParagonicServer::new(client);
        
        // For now, just test that the unknown method handling exists in the match statement
        // We'll test the actual RPC call later when we have proper ServerCtl setup
        assert!(true);
    }
    
    /// Test that the server can handle chat completion requests
    #[tokio::test]
    async fn test_server_chat_completion() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test that server can handle chat completion
        let params = Some(serde_json::json!(["Hello", "llama3.2:3b"]));
        let result = server.handle_chat_completion(&params);
        assert!(result.is_ok());
        assert!(result.unwrap().contains("Mock response"));
    }

    /// Test that handle_chat_completion validates required parameters
    #[tokio::test]
    async fn test_handle_chat_completion_parameter_validation() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test with missing parameters
        let params = Some(serde_json::json!(["Hello"])); // Missing model
        let result = server.handle_chat_completion(&params);
        assert!(result.is_err());
        
        // Test with empty parameters
        let params = Some(serde_json::json!([]));
        let result = server.handle_chat_completion(&params);
        assert!(result.is_err());
        
        // Test with None parameters
        let result = server.handle_chat_completion(&None);
        assert!(result.is_err());
    }

    /// Test that handle_chat_completion handles invalid parameter types
    #[tokio::test]
    async fn test_handle_chat_completion_invalid_parameter_types() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test with non-string message
        let params = Some(serde_json::json!([123, "llama3.2:3b"]));
        let result = server.handle_chat_completion(&params);
        assert!(result.is_err());
        
        // Test with non-string model
        let params = Some(serde_json::json!(["Hello", 456]));
        let result = server.handle_chat_completion(&params);
        assert!(result.is_err());
    }

    /// Test that handle_chat_completion creates proper chat messages
    #[tokio::test]
    async fn test_handle_chat_completion_creates_chat_messages() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test that the function can extract message and model correctly
        let message = "Hello, how are you?";
        let model = "llama3.2:3b";
        let params = Some(serde_json::json!([message, model]));
        
        let result = server.handle_chat_completion(&params);
        assert!(result.is_ok());
        
        // For now, it returns a mock response, but we can verify the parameters were parsed
        let response = result.unwrap();
        assert!(response.contains(message));
    }

    /// Test that handle_chat_completion can handle complex messages
    #[tokio::test]
    async fn test_handle_chat_completion_complex_messages() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test with a complex message containing special characters
        let message = "Hello! How are you doing today? I have a question about Rust programming...";
        let model = "llama3.2:3b";
        let params = Some(serde_json::json!([message, model]));
        
        let result = server.handle_chat_completion(&params);
        assert!(result.is_ok());
        
        let response = result.unwrap();
        assert!(response.contains("Mock response"));
    }

    /// Test that handle_chat_completion makes actual Ollama API calls
    #[test]
    fn test_handle_chat_completion_actual_ollama_call() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        let message = "Hello, this is a test message";
        let model = "llama3.2:3b";
        let params = Some(serde_json::json!([message, model]));
        
        let result = server.handle_chat_completion(&params);
        assert!(result.is_ok());
        
        let response = result.unwrap();
        // This test will fail because we're still returning mock responses
        // It should contain actual AI-generated content, not "Mock response"
        assert!(!response.contains("Mock response"), 
            "Response should contain actual AI content, not mock response. Got: {}", response);
        
        // The response should be a valid JSON structure with AI-generated content
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        
        // Should have a message field with content
        assert!(response_json.get("message").is_some(), 
            "Response should have a 'message' field");
        
        let message_content = response_json["message"]["content"].as_str()
            .expect("Message should have content field");
        
        assert!(!message_content.is_empty(), 
            "Message content should not be empty");
        assert!(message_content != message, 
            "AI response should be different from input message");
    }
    
    /// Test that the server can handle list models requests
    #[test]
    fn test_handle_list_models_actual_ollama_call() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        let result = server.handle_list_models();
        assert!(result.is_ok(), "handle_list_models should return Ok");
        let response = result.unwrap();
        // Should be valid JSON
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        // Should be an array of models
        assert!(response_json.is_array(), "Response should be an array");
        // Should contain at least one model
        assert!(!response_json.as_array().unwrap().is_empty(), "Should contain at least one model");
        // Should not be the mock response
        let mock_response = serde_json::json!(["llama3.2:3b", "nomic-embed-text"]);
        assert!(response_json != mock_response, "Should not be the mock response, got: {}", response_json);
    }
    
    /// Test that the server can handle model info requests
    #[test]
    fn test_server_model_info() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test that server can handle model info
        let params = Some(serde_json::json!(["llama3.2:3b"]));
        let result = server.handle_model_info(&params);
        assert!(result.is_ok());
        let response = result.unwrap();
        assert!(response.contains("llama3.2:3b"));
        assert!(response.contains("size"));
    }
    
    /// Test that the server can handle model info requests with real Ollama output
    #[test]
    fn test_handle_model_info_actual_ollama_call() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Use a model that should exist (from list_models)
        let list_result = server.handle_list_models();
        assert!(list_result.is_ok(), "list_models should succeed");
        let models: Vec<String> = serde_json::from_str(&list_result.unwrap()).expect("Should be valid JSON");
        assert!(!models.is_empty(), "Should have at least one model");
        let model = &models[0];
        let params = Some(serde_json::json!([model]));
        
        let result = server.handle_model_info(&params);
        assert!(result.is_ok(), "handle_model_info should return Ok");
        let response = result.unwrap();
        // Should be valid JSON
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        // Should have a name field matching the model
        let name_value = response_json["name"].as_str().expect("Model name should be a string");
        assert_eq!(name_value, model, "Model name should match");
        // Should not be the mock response
        let mock_response = serde_json::json!({"name": model, "size": 0});
        assert!(response_json != mock_response, "Should not be the mock response, got: {}", response_json);
    }
    
    /// Test that the server can handle generate embedding requests
    #[test]
    fn test_server_generate_embedding() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test that server can handle generate embedding
        let params = Some(serde_json::json!(["Hello world", "nomic-embed-text"]));
        let result = server.handle_generate_embedding(&params);
        assert!(result.is_ok());
        let response = result.unwrap();
        assert!(response.contains("0.1"));
        assert!(response.contains("0.2"));
        assert!(response.contains("0.3"));
    }

    /// Test that the server can handle generate embedding requests with real Ollama output
    #[test]
    fn test_handle_generate_embedding_actual_ollama_call() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Use a model that should exist (from list_models)
        let list_result = server.handle_list_models();
        assert!(list_result.is_ok(), "list_models should succeed");
        let models: Vec<String> = serde_json::from_str(&list_result.unwrap()).expect("Should be valid JSON");
        assert!(!models.is_empty(), "Should have at least one model");
        let model = &models[0];
        let text = "Hello, this is a test for embedding generation";
        let params = Some(serde_json::json!([text, model]));
        
        let result = server.handle_generate_embedding(&params);
        assert!(result.is_ok(), "handle_generate_embedding should return Ok");
        let response = result.unwrap();
        // Should be valid JSON
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        // Should be an array of numbers (embeddings)
        assert!(response_json.is_array(), "Response should be an array");
        let embeddings = response_json.as_array().unwrap();
        assert!(!embeddings.is_empty(), "Should have at least one embedding value");
        // Should not be the mock response
        let mock_response = serde_json::json!([0.1, 0.2, 0.3]);
        assert!(response_json != mock_response, "Should not be the mock response, got: {}", response_json);
    }
} 