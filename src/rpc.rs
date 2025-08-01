//! JSON-RPC server for Lua-Rust communication and MCP
//! 
//! This module provides a JSON-RPC server that exposes Ollama client functions
//! to the Lua Neovim plugin, following MCP standards.

use tokio_jsonrpc::{Server, ServerCtl, RpcError, Endpoint, LineCodec};
use tokio_core::reactor::Core;
use tokio_core::net::TcpListener;
use futures::stream::Stream;
use serde_json::{json, Value};
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
            let (client, _) = Endpoint::new(stream.framed(LineCodec::new()), server.clone())
                .start(&handle);
            Ok(())
        });
        
        tracing::info!("JSON-RPC server started on {}", addr);
        core.run(connections)?;
        
        Ok(())
    }
    
    /// Handle chat completion request
    fn handle_chat_completion(&self, params: &Option<Value>) -> Result<String, RpcError> {
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
        
        // For now, return a mock response
        // TODO: Implement actual Ollama call
        Ok(format!("Mock response to: {}", message))
    }
    
    /// Handle list models request
    fn handle_list_models(&self) -> Result<String, RpcError> {
        // For now, return a mock response
        // TODO: Implement actual Ollama call
        Ok(json!(["llama3.2:3b", "nomic-embed-text"]).to_string())
    }
    
    /// Handle model info request
    fn handle_model_info(&self, params: &Option<Value>) -> Result<String, RpcError> {
        let params = params.as_ref()
            .and_then(|p| p.as_array())
            .ok_or_else(|| RpcError::InvalidParams)?;
        
        if params.is_empty() {
            return Err(RpcError::InvalidParams);
        }
        
        let model = params[0].as_str()
            .ok_or_else(|| RpcError::InvalidParams)?
            .to_string();
        
        // For now, return a mock response
        // TODO: Implement actual Ollama call
        Ok(json!({"name": model, "size": 0}).to_string())
    }
    
    /// Handle generate embedding request
    fn handle_generate_embedding(&self, params: &Option<Value>) -> Result<String, RpcError> {
        let params = params.as_ref()
            .and_then(|p| p.as_array())
            .ok_or_else(|| RpcError::InvalidParams)?;
        
        if params.len() < 2 {
            return Err(RpcError::InvalidParams);
        }
        
        let text = params[0].as_str()
            .ok_or_else(|| RpcError::InvalidParams)?
            .to_string();
        let model = params[1].as_str()
            .ok_or_else(|| RpcError::InvalidParams)?
            .to_string();
        
        // For now, return a mock response
        // TODO: Implement actual Ollama call
        Ok(json!([0.1, 0.2, 0.3]).to_string())
    }
}

impl Server for ParagonicServer {
    type Success = String;
    type RpcCallResult = Result<String, RpcError>;
    type NotificationResult = Result<(), ()>;
    
    fn rpc(&self, _ctl: &ServerCtl, method: &str, params: &Option<Value>) 
        -> Option<Self::RpcCallResult> {
        match method {
            "chat_completion" => Some(self.handle_chat_completion(params)),
            "list_models" => Some(self.handle_list_models()),
            "model_info" => Some(self.handle_model_info(params)),
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
    
    #[test]
    fn test_rpc_server_creation() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test that server can handle chat completion
        let params = Some(json!(["Hello", "llama3.2:3b"]));
        let result = server.handle_chat_completion(&params);
        assert!(result.is_ok());
        assert!(result.unwrap().contains("Mock response"));
    }
} 