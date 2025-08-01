//! JSON-RPC server for Lua-Rust communication
//! 
//! This module provides a JSON-RPC server that exposes Ollama client functions
//! to the Lua Neovim plugin, following MCP standards.

use jsonrpc_core::{IoHandler, Error, ErrorCode};
use jsonrpc_http_server::ServerBuilder;
use serde_json::json;
use std::sync::Arc;
use tokio::runtime::Runtime;

use crate::ollama::OllamaClient;
use crate::error::ParagonicResult;

/// JSON-RPC server for Paragonic
pub struct ParagonicRpcServer {
    ollama_client: Arc<OllamaClient>,
    runtime: Arc<Runtime>,
}

impl ParagonicRpcServer {
    /// Create a new RPC server
    pub fn new(ollama_client: OllamaClient) -> Self {
        let runtime = Arc::new(Runtime::new().expect("Failed to create Tokio runtime"));
        
        Self {
            ollama_client: Arc::new(ollama_client),
            runtime,
        }
    }
    
    /// Start the JSON-RPC server
    pub fn start(&self, addr: &str) -> ParagonicResult<()> {
        let mut io = IoHandler::default();
        
        // Register RPC methods
        let client = self.ollama_client.clone();
        let runtime = self.runtime.clone();
        io.add_method("chat_completion", move |params: serde_json::Value| {
            let client = client.clone();
            let runtime = runtime.clone();
            
            // Parse parameters
            let params = params.as_array()
                .ok_or_else(|| Error::new(ErrorCode::InvalidParams))?;
            
            if params.len() < 2 {
                return Err(Error::new(ErrorCode::InvalidParams));
            }
            
            let message = params[0].as_str()
                .ok_or_else(|| Error::new(ErrorCode::InvalidParams))?
                .to_string();
            let model = params[1].as_str()
                .ok_or_else(|| Error::new(ErrorCode::InvalidParams))?
                .to_string();
            
            // Call Ollama client
            let result = runtime.block_on(async {
                let messages = vec![
                    crate::ollama::ChatMessage {
                        role: "user".to_string(),
                        content: message,
                    }
                ];
                
                client.chat_completion(&model, messages, false).await
            });
            
            match result {
                Ok(response) => Ok(json!(response.message.content)),
                Err(_) => Err(Error::new(ErrorCode::InternalError)),
            }
        });
        
        let client = self.ollama_client.clone();
        let runtime = self.runtime.clone();
        io.add_method("list_models", move |_params: serde_json::Value| {
            let client = client.clone();
            let runtime = runtime.clone();
            
            let result = runtime.block_on(async {
                client.list_models().await
            });
            
            match result {
                Ok(models) => {
                    let model_names: Vec<String> = models.into_iter()
                        .map(|m| m.name)
                        .collect();
                    Ok(json!(model_names))
                },
                Err(_) => Err(Error::new(ErrorCode::InternalError)),
            }
        });
        
        let client = self.ollama_client.clone();
        let runtime = self.runtime.clone();
        io.add_method("model_info", move |params: serde_json::Value| {
            let client = client.clone();
            let runtime = runtime.clone();
            
            let params = params.as_array()
                .ok_or_else(|| Error::new(ErrorCode::InvalidParams))?;
            
            if params.is_empty() {
                return Err(Error::new(ErrorCode::InvalidParams));
            }
            
            let model = params[0].as_str()
                .ok_or_else(|| Error::new(ErrorCode::InvalidParams))?
                .to_string();
            
            let result = runtime.block_on(async {
                client.model_info(&model).await
            });
            
            match result {
                Ok(info) => Ok(json!(info)),
                Err(_) => Err(Error::new(ErrorCode::InternalError)),
            }
        });
        
        let client = self.ollama_client.clone();
        let runtime = self.runtime.clone();
        io.add_method("generate_embedding", move |params: serde_json::Value| {
            let client = client.clone();
            let runtime = runtime.clone();
            
            let params = params.as_array()
                .ok_or_else(|| Error::new(ErrorCode::InvalidParams))?;
            
            if params.len() < 2 {
                return Err(Error::new(ErrorCode::InvalidParams));
            }
            
            let text = params[0].as_str()
                .ok_or_else(|| Error::new(ErrorCode::InvalidParams))?
                .to_string();
            let model = params[1].as_str()
                .ok_or_else(|| Error::new(ErrorCode::InvalidParams))?
                .to_string();
            
            let result = runtime.block_on(async {
                client.generate_embedding(&model, &text).await
            });
            
            match result {
                Ok(embedding) => Ok(json!(embedding.embedding)),
                Err(_) => Err(Error::new(ErrorCode::InternalError)),
            }
        });
        
        // Start HTTP server
        let server = ServerBuilder::new(io)
            .threads(4)
            .start_http(&addr.parse()?)?;
        
        tracing::info!("JSON-RPC server started on {}", addr);
        
        // Keep server running
        server.wait();
        
        Ok(())
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
        let server = ParagonicRpcServer::new(client);
        
        assert!(server.ollama_client.config.base_url.contains("localhost"));
    }
} 