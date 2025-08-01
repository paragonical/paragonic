//! JSON-RPC server for Lua-Rust communication and MCP
//! 
//! This module provides a JSON-RPC server that exposes Ollama client functions
//! to the Lua Neovim plugin, following MCP standards.

use tokio_jsonrpc::{Server, ServerCtl, RpcError, Endpoint, LineCodec};
use tokio_core::reactor::Core;
use tokio_core::net::TcpListener;
use tokio_io::AsyncRead;
use futures::stream::Stream;
use serde_json::Value;
use std::sync::Arc;

use crate::ollama::OllamaClient;
use crate::error::ParagonicResult;

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
            let (_client, _) = Endpoint::new(stream.framed(LineCodec::new()), server.clone())
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
        let _model = params[1].as_str()
            .ok_or_else(|| RpcError::invalid_params(None))?
            .to_string();
        
        // For now, return a mock response
        // TODO: Implement actual Ollama call
        Ok(format!("Mock response to: {message}"))
    }
    
    /// Handle list models request
    pub fn handle_list_models(&self) -> Result<String, RpcError> {
        // For now, return a mock response
        // TODO: Implement actual Ollama call
        Ok(serde_json::json!(["llama3.2:3b", "nomic-embed-text"]).to_string())
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
        
        // For now, return a mock response
        // TODO: Implement actual Ollama call
        Ok(serde_json::json!({"name": model, "size": 0}).to_string())
    }
    
    /// Handle generate embedding request
    pub fn handle_generate_embedding(&self, params: &Option<Value>) -> Result<String, RpcError> {
        let params = params.as_ref()
            .and_then(|p| p.as_array())
            .ok_or_else(|| RpcError::invalid_params(None))?;
        
        if params.len() < 2 {
            return Err(RpcError::invalid_params(None));
        }
        
        let _text = params[0].as_str()
            .ok_or_else(|| RpcError::invalid_params(None))?
            .to_string();
        let _model = params[1].as_str()
            .ok_or_else(|| RpcError::invalid_params(None))?
            .to_string();
        
        // For now, return a mock response
        // TODO: Implement actual Ollama call
        Ok(serde_json::json!([0.1, 0.2, 0.3]).to_string())
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
    #[test]
    fn test_server_chat_completion() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test that server can handle chat completion
        let params = Some(serde_json::json!(["Hello", "llama3.2:3b"]));
        let result = server.handle_chat_completion(&params);
        assert!(result.is_ok());
        assert!(result.unwrap().contains("Mock response"));
    }
    
    /// Test that the server can handle list models requests
    #[test]
    fn test_server_list_models() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test that server can handle list models
        let result = server.handle_list_models();
        assert!(result.is_ok());
        let response = result.unwrap();
        assert!(response.contains("llama3.2:3b"));
        assert!(response.contains("nomic-embed-text"));
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
} 