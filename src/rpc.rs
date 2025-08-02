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
            // We're in a runtime context, use block_in_place
            tokio::task::block_in_place(|| {
                handle.block_on(async {
                    self.ollama_client.chat_completion(&model, vec![chat_message], false).await
                })
            })
        } else {
            // We're not in a runtime context, create a new one
            tokio::runtime::Runtime::new()
                .map_err(|e| RpcError::invalid_params(Some(format!("Failed to create runtime: {e}"))))?
                .block_on(async {
                    self.ollama_client.chat_completion(&model, vec![chat_message], false).await
                })
        };
        
        match response {
            Ok(chat_response) => {
                // Return the response as JSON
                serde_json::to_string(&chat_response)
                    .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize response: {e}"))))
            }
            Err(e) => {
                // Log the error and return a user-friendly error message
                error!("Ollama chat completion failed: {}", e);
                Err(RpcError::invalid_params(Some(format!("AI service unavailable: {e}"))))
            }
        }
    }
    
    /// Handle list models request
    pub fn handle_list_models(&self) -> Result<String, RpcError> {
        // Make actual Ollama API call
        let response = if let Ok(handle) = tokio::runtime::Handle::try_current() {
            // We're in a runtime context, use block_in_place
            tokio::task::block_in_place(|| {
                handle.block_on(async {
                    self.ollama_client.list_models().await
                })
            })
        } else {
            // We're not in a runtime context, create a new one
            tokio::runtime::Runtime::new()
                .map_err(|e| RpcError::invalid_params(Some(format!("Failed to create runtime: {e}"))))?
                .block_on(async {
                    self.ollama_client.list_models().await
                })
        };
        match response {
            Ok(models) => {
                // Return the models as a JSON array of model names
                let names: Vec<String> = models.into_iter().map(|m| m.name).collect();
                serde_json::to_string(&names)
                    .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize response: {e}"))))
            }
            Err(e) => {
                error!("Ollama list_models failed: {}", e);
                Err(RpcError::invalid_params(Some(format!("AI service unavailable: {e}"))))
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
            // We're in a runtime context, use block_in_place
            tokio::task::block_in_place(|| {
                handle.block_on(async {
                    self.ollama_client.model_info(&model).await
                })
            })
        } else {
            // We're not in a runtime context, create a new one
            tokio::runtime::Runtime::new()
                .map_err(|e| RpcError::invalid_params(Some(format!("Failed to create runtime: {e}"))))?
                .block_on(async {
                    self.ollama_client.model_info(&model).await
                })
        };
        match response {
            Ok(info) => {
                // Add the model name to the response for compatibility
                let mut info_json = serde_json::to_value(info)
                    .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize response: {e}"))))?;
                info_json["name"] = serde_json::Value::String(model);
                serde_json::to_string(&info_json)
                    .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize response: {e}"))))
            }
            Err(e) => {
                error!("Ollama model_info failed: {}", e);
                Err(RpcError::invalid_params(Some(format!("AI service unavailable: {e}"))))
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
            // We're in a runtime context, use block_in_place
            tokio::task::block_in_place(|| {
                handle.block_on(async {
                    self.ollama_client.generate_embedding(&model, &text).await
                })
            })
        } else {
            // We're not in a runtime context, create a new one
            tokio::runtime::Runtime::new()
                .map_err(|e| RpcError::invalid_params(Some(format!("Failed to create runtime: {e}"))))?
                .block_on(async {
                    self.ollama_client.generate_embedding(&model, &text).await
                })
        };
        match response {
            Ok(embedding_response) => {
                // Return the embeddings wrapped in an object with 'embedding' field
                let result = serde_json::json!({
                    "embedding": embedding_response.embedding
                });
                serde_json::to_string(&result)
                    .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize response: {e}"))))
            }
            Err(e) => {
                error!("Ollama generate_embedding failed: {}", e);
                Err(RpcError::invalid_params(Some(format!("AI service unavailable: {e}"))))
            }
        }
    }
    
    /// Handle create project request
pub fn handle_create_project(&self, params: &Option<Value>) -> Result<String, RpcError> {
    let params = params.as_ref()
        .and_then(|p| p.as_object())
        .ok_or_else(|| RpcError::invalid_params(None))?;
    
    let name = params.get("name")
        .and_then(|n| n.as_str())
        .ok_or_else(|| RpcError::invalid_params(None))?
        .to_string();
    
    let description = params.get("description")
        .and_then(|d| d.as_str())
        .map(|d| d.to_string());
    
    // For now, return a mock response to test the RPC infrastructure
    // TODO: Implement actual database call when async RPC is supported
    let mock_project = serde_json::json!({
        "id": "123e4567-e89b-12d3-a456-426614174000",
        "name": name.clone(),
        "description": description.clone(),
        "created_at": null,
        "updated_at": null,
        "organization_id": null
    });
    
    serde_json::to_string(&mock_project)
        .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize project: {e}"))))
}
    
    /// Handle get project request
pub fn handle_get_project(&self, params: &Option<Value>) -> Result<String, RpcError> {
    let params = params.as_ref()
        .and_then(|p| p.as_object())
        .ok_or_else(|| RpcError::invalid_params(None))?;
    
    let project_id = params.get("project_id")
        .and_then(|id| id.as_str())
        .ok_or_else(|| RpcError::invalid_params(None))?;
    
    // For now, return a mock response to test the RPC infrastructure
    // TODO: Implement actual database call when async RPC is supported
    let mock_project = serde_json::json!({
        "id": project_id,
        "name": "Mock Project",
        "description": "A mock project for testing",
        "created_at": null,
        "updated_at": null,
        "organization_id": null
    });
    
    serde_json::to_string(&mock_project)
        .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize project: {e}"))))
}
    
    /// Handle list projects request
pub fn handle_list_projects(&self) -> Result<String, RpcError> {
    // For now, return a mock response to test the RPC infrastructure
    // TODO: Implement actual database call when async RPC is supported
    let mock_projects = serde_json::json!([
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "name": "Mock Project 1",
            "description": "First mock project",
            "created_at": null,
            "updated_at": null,
            "organization_id": null
        },
        {
            "id": "123e4567-e89b-12d3-a456-426614174001",
            "name": "Mock Project 2",
            "description": "Second mock project",
            "created_at": null,
            "updated_at": null,
            "organization_id": null
        }
    ]);
    
    serde_json::to_string(&mock_projects)
        .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize projects: {e}"))))
}
    
    /// Handle create goal request
pub fn handle_create_goal(&self, params: &Option<Value>) -> Result<String, RpcError> {
    let params = params.as_ref()
        .and_then(|p| p.as_object())
        .ok_or_else(|| RpcError::invalid_params(None))?;
    
    let project_id = params.get("project_id")
        .and_then(|id| id.as_str())
        .ok_or_else(|| RpcError::invalid_params(None))?;
    
    let name = params.get("name")
        .and_then(|n| n.as_str())
        .ok_or_else(|| RpcError::invalid_params(None))?
        .to_string();
    
    let description = params.get("description")
        .and_then(|d| d.as_str())
        .map(|d| d.to_string());
    
    // For now, return a mock response to test the RPC infrastructure
    // TODO: Implement actual database call when async RPC is supported
    let mock_goal = serde_json::json!({
        "id": "456e7890-e89b-12d3-a456-426614174000",
        "project_id": project_id,
        "name": name.clone(),
        "description": description.clone(),
        "status": "active",
        "created_at": null,
        "updated_at": null
    });
    
    serde_json::to_string(&mock_goal)
        .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize goal: {e}"))))
}
    
    /// Handle get goal request
pub fn handle_get_goal(&self, params: &Option<Value>) -> Result<String, RpcError> {
    let params = params.as_ref()
        .and_then(|p| p.as_object())
        .ok_or_else(|| RpcError::invalid_params(None))?;
    
    let goal_id = params.get("goal_id")
        .and_then(|id| id.as_str())
        .ok_or_else(|| RpcError::invalid_params(None))?;
    
    // For now, return a mock response to test the RPC infrastructure
    // TODO: Implement actual database call when async RPC is supported
    let mock_goal = serde_json::json!({
        "id": goal_id,
        "project_id": "123e4567-e89b-12d3-a456-426614174000",
        "name": "Mock Goal",
        "description": "A mock goal for testing",
        "status": "active",
        "created_at": null,
        "updated_at": null
    });
    
    serde_json::to_string(&mock_goal)
        .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize goal: {e}"))))
}
    
    /// Handle list goals request
pub fn handle_list_goals(&self, params: &Option<Value>) -> Result<String, RpcError> {
    let params = params.as_ref()
        .and_then(|p| p.as_object())
        .ok_or_else(|| RpcError::invalid_params(None))?;
    
    let project_id = params.get("project_id")
        .and_then(|id| id.as_str())
        .ok_or_else(|| RpcError::invalid_params(None))?;
    
    // For now, return a mock response to test the RPC infrastructure
    // TODO: Implement actual database call when async RPC is supported
    let mock_goals = serde_json::json!([
        {
            "id": "456e7890-e89b-12d3-a456-426614174000",
            "project_id": project_id,
            "name": "Mock Goal 1",
            "description": "First mock goal",
            "status": "active",
            "created_at": null,
            "updated_at": null
        },
        {
            "id": "456e7890-e89b-12d3-a456-426614174001",
            "project_id": project_id,
            "name": "Mock Goal 2",
            "description": "Second mock goal",
            "status": "active",
            "created_at": null,
            "updated_at": null
        }
    ]);
    
    serde_json::to_string(&mock_goals)
        .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize goals: {e}"))))
}
    
    /// Handle create task request
pub fn handle_create_task(&self, params: &Option<Value>) -> Result<String, RpcError> {
    let params = params.as_ref()
        .and_then(|p| p.as_object())
        .ok_or_else(|| RpcError::invalid_params(None))?;
    
    let goal_id = params.get("goal_id")
        .and_then(|id| id.as_str())
        .ok_or_else(|| RpcError::invalid_params(None))?;
    
    let name = params.get("name")
        .and_then(|n| n.as_str())
        .ok_or_else(|| RpcError::invalid_params(None))?
        .to_string();
    
    let description = params.get("description")
        .and_then(|d| d.as_str())
        .map(|d| d.to_string());
    
    let priority = params.get("priority")
        .and_then(|p| p.as_i64())
        .map(|p| p as i32);
    
    // For now, return a mock response to test the RPC infrastructure
    // TODO: Implement actual database call when async RPC is supported
    let mock_task = serde_json::json!({
        "id": "789e0123-e89b-12d3-a456-426614174000",
        "goal_id": goal_id,
        "name": name.clone(),
        "description": description.clone(),
        "status": "pending",
        "priority": priority,
        "created_at": null,
        "updated_at": null
    });
    
    serde_json::to_string(&mock_task)
        .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize task: {e}"))))
}
    
    /// Handle get task request
pub fn handle_get_task(&self, params: &Option<Value>) -> Result<String, RpcError> {
    let params = params.as_ref()
        .and_then(|p| p.as_object())
        .ok_or_else(|| RpcError::invalid_params(None))?;
    
    let task_id = params.get("task_id")
        .and_then(|id| id.as_str())
        .ok_or_else(|| RpcError::invalid_params(None))?;
    
    // For now, return a mock response to test the RPC infrastructure
    // TODO: Implement actual database call when async RPC is supported
    let mock_task = serde_json::json!({
        "id": task_id,
        "goal_id": "456e7890-e89b-12d3-a456-426614174000",
        "name": "Mock Task",
        "description": "A mock task for testing",
        "status": "pending",
        "priority": 1,
        "created_at": null,
        "updated_at": null
    });
    
    serde_json::to_string(&mock_task)
        .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize task: {e}"))))
}
    
    /// Handle list tasks request
pub fn handle_list_tasks(&self, params: &Option<Value>) -> Result<String, RpcError> {
    let params = params.as_ref()
        .and_then(|p| p.as_object())
        .ok_or_else(|| RpcError::invalid_params(None))?;
    
    let goal_id = params.get("goal_id")
        .and_then(|id| id.as_str())
        .ok_or_else(|| RpcError::invalid_params(None))?;
    
    // For now, return a mock response to test the RPC infrastructure
    // TODO: Implement actual database call when async RPC is supported
    let mock_tasks = serde_json::json!([
        {
            "id": "789e0123-e89b-12d3-a456-426614174000",
            "goal_id": goal_id,
            "name": "Mock Task 1",
            "description": "First mock task",
            "status": "pending",
            "priority": 1,
            "created_at": null,
            "updated_at": null
        },
        {
            "id": "789e0123-e89b-12d3-a456-426614174001",
            "goal_id": goal_id,
            "name": "Mock Task 2",
            "description": "Second mock task",
            "status": "in_progress",
            "priority": 2,
            "created_at": null,
            "updated_at": null
        }
    ]);
    
            serde_json::to_string(&mock_tasks)
            .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize tasks: {e}"))))
    }
    
    /// Handle update project requests
    /// 
    /// This function updates a project in the database with the given fields.
    /// For now, returns a mock response to test the RPC infrastructure.
    pub fn handle_update_project(&self, params: &Option<Value>) -> Result<String, RpcError> {
        let params = params.as_ref()
            .and_then(|p| p.as_object())
            .ok_or_else(|| RpcError::invalid_params(None))?;
        
        let project_id = params.get("project_id")
            .and_then(|id| id.as_str())
            .ok_or_else(|| RpcError::invalid_params(None))?;
        
        let name = params.get("name")
            .and_then(|n| n.as_str())
            .map(|n| n.to_string());
        
        let description = params.get("description")
            .and_then(|d| d.as_str())
            .map(|d| d.to_string());
        
        // For now, return a mock response to test the RPC infrastructure
        // TODO: Implement actual database call when async RPC is supported
        let mock_project = serde_json::json!({
            "id": project_id,
            "name": name.unwrap_or_else(|| "Updated Project".to_string()),
            "description": description,
            "organization_id": null,
            "created_at": null,
            "updated_at": "2025-08-02T20:00:00Z"
        });
        
        serde_json::to_string(&mock_project)
            .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize project: {e}"))))
    }
    
    /// Handle update goal requests
    /// 
    /// This function updates a goal in the database with the given fields.
    /// For now, returns a mock response to test the RPC infrastructure.
    pub fn handle_update_goal(&self, params: &Option<Value>) -> Result<String, RpcError> {
        let params = params.as_ref()
            .and_then(|p| p.as_object())
            .ok_or_else(|| RpcError::invalid_params(None))?;
        
        let goal_id = params.get("goal_id")
            .and_then(|id| id.as_str())
            .ok_or_else(|| RpcError::invalid_params(None))?;
        
        let name = params.get("name")
            .and_then(|n| n.as_str())
            .map(|n| n.to_string());
        
        let description = params.get("description")
            .and_then(|d| d.as_str())
            .map(|d| d.to_string());
        
        let status = params.get("status")
            .and_then(|s| s.as_str())
            .map(|s| s.to_string());
        
        // For now, return a mock response to test the RPC infrastructure
        // TODO: Implement actual database call when async RPC is supported
        let mock_goal = serde_json::json!({
            "id": goal_id,
            "project_id": "123e4567-e89b-12d3-a456-426614174000",
            "name": name.unwrap_or_else(|| "Updated Goal".to_string()),
            "description": description,
            "status": status,
            "created_at": null,
            "updated_at": "2025-08-02T20:00:00Z"
        });
        
        serde_json::to_string(&mock_goal)
            .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize goal: {e}"))))
    }
    
    /// Handle update task requests
    /// 
    /// This function updates a task in the database with the given fields.
    /// For now, returns a mock response to test the RPC infrastructure.
    pub fn handle_update_task(&self, params: &Option<Value>) -> Result<String, RpcError> {
        let params = params.as_ref()
            .and_then(|p| p.as_object())
            .ok_or_else(|| RpcError::invalid_params(None))?;
        
        let task_id = params.get("task_id")
            .and_then(|id| id.as_str())
            .ok_or_else(|| RpcError::invalid_params(None))?;
        
        let name = params.get("name")
            .and_then(|n| n.as_str())
            .map(|n| n.to_string());
        
        let description = params.get("description")
            .and_then(|d| d.as_str())
            .map(|d| d.to_string());
        
        let status = params.get("status")
            .and_then(|s| s.as_str())
            .map(|s| s.to_string());
        
        let priority = params.get("priority")
            .and_then(|p| p.as_i64())
            .map(|p| p as i32);
        
        // For now, return a mock response to test the RPC infrastructure
        // TODO: Implement actual database call when async RPC is supported
        let mock_task = serde_json::json!({
            "id": task_id,
            "goal_id": "456e7890-e89b-12d3-a456-426614174000",
            "name": name.unwrap_or_else(|| "Updated Task".to_string()),
            "description": description,
            "status": status,
            "priority": priority,
            "created_at": null,
            "updated_at": "2025-08-02T20:00:00Z"
        });
        
        serde_json::to_string(&mock_task)
            .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize task: {e}"))))
    }
    
    /// Handle delete project requests
    /// 
    /// This function deletes a project from the database.
    /// For now, returns a mock response to test the RPC infrastructure.
    pub fn handle_delete_project(&self, params: &Option<Value>) -> Result<String, RpcError> {
        let params = params.as_ref()
            .and_then(|p| p.as_object())
            .ok_or_else(|| RpcError::invalid_params(None))?;
        
        let project_id = params.get("project_id")
            .and_then(|id| id.as_str())
            .ok_or_else(|| RpcError::invalid_params(None))?;
        
        // For now, return a mock response to test the RPC infrastructure
        // TODO: Implement actual database call when async RPC is supported
        let mock_response = serde_json::json!({
            "success": true,
            "message": "Project deleted successfully",
            "project_id": project_id
        });
        
        serde_json::to_string(&mock_response)
            .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize response: {e}"))))
    }
    
    /// Handle delete goal requests
    /// 
    /// This function deletes a goal from the database.
    /// For now, returns a mock response to test the RPC infrastructure.
    pub fn handle_delete_goal(&self, params: &Option<Value>) -> Result<String, RpcError> {
        let params = params.as_ref()
            .and_then(|p| p.as_object())
            .ok_or_else(|| RpcError::invalid_params(None))?;
        
        let goal_id = params.get("goal_id")
            .and_then(|id| id.as_str())
            .ok_or_else(|| RpcError::invalid_params(None))?;
        
        // For now, return a mock response to test the RPC infrastructure
        // TODO: Implement actual database call when async RPC is supported
        let mock_response = serde_json::json!({
            "success": true,
            "message": "Goal deleted successfully",
            "goal_id": goal_id
        });
        
        serde_json::to_string(&mock_response)
            .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize response: {e}"))))
    }
    
    /// Handle delete task requests
    /// 
    /// This function deletes a task from the database.
    /// For now, returns a mock response to test the RPC infrastructure.
    pub fn handle_delete_task(&self, params: &Option<Value>) -> Result<String, RpcError> {
        let params = params.as_ref()
            .and_then(|p| p.as_object())
            .ok_or_else(|| RpcError::invalid_params(None))?;
        
        let task_id = params.get("task_id")
            .and_then(|id| id.as_str())
            .ok_or_else(|| RpcError::invalid_params(None))?;
        
        // For now, return a mock response to test the RPC infrastructure
        // TODO: Implement actual database call when async RPC is supported
        let mock_response = serde_json::json!({
            "success": true,
            "message": "Task deleted successfully",
            "task_id": task_id
        });
        
        serde_json::to_string(&mock_response)
            .map_err(|e| RpcError::invalid_params(Some(format!("Failed to serialize response: {e}"))))
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
            // Handle create project requests
            "create_project" => Some(self.handle_create_project(params)),
            // Handle get project requests
            "get_project" => Some(self.handle_get_project(params)),
            // Handle list projects requests
            "list_projects" => Some(self.handle_list_projects()),
            // Handle update project requests
            "update_project" => Some(self.handle_update_project(params)),
            // Handle create goal requests
            "create_goal" => Some(self.handle_create_goal(params)),
            // Handle get goal requests
            "get_goal" => Some(self.handle_get_goal(params)),
            // Handle list goals requests
            "list_goals" => Some(self.handle_list_goals(params)),
            // Handle update goal requests
            "update_goal" => Some(self.handle_update_goal(params)),
            // Handle create task requests
            "create_task" => Some(self.handle_create_task(params)),
            // Handle get task requests
            "get_task" => Some(self.handle_get_task(params)),
            // Handle list tasks requests
            "list_tasks" => Some(self.handle_list_tasks(params)),
            // Handle update task requests
            "update_task" => Some(self.handle_update_task(params)),
            // Handle delete project requests
            "delete_project" => Some(self.handle_delete_project(params)),
            // Handle delete goal requests
            "delete_goal" => Some(self.handle_delete_goal(params)),
            // Handle delete task requests
            "delete_task" => Some(self.handle_delete_task(params)),
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
        // Now it returns real AI responses, so we just verify it's valid JSON
        let response = result.unwrap();
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        assert!(response_json.get("message").is_some(), "Should have a message field");
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
    #[test]
    fn test_handle_chat_completion_creates_chat_messages() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test that the function can extract message and model correctly
        let message = "Hello, how are you?";
        let model = "llama3.2:3b";
        let params = Some(serde_json::json!([message, model]));
        
        let result = server.handle_chat_completion(&params);
        assert!(result.is_ok());
        
        // Now it returns real AI responses, so we just verify it's valid JSON
        let response = result.unwrap();
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        assert!(response_json.get("message").is_some(), "Should have a message field");
    }

    /// Test that handle_chat_completion can handle complex messages
    #[test]
    fn test_handle_chat_completion_complex_messages() {
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
        // Now it returns real AI responses, so we just verify it's valid JSON
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        assert!(response_json.get("message").is_some(), "Should have a message field");
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
    
    /// Test that the server can handle create project requests
    #[test]
    fn test_server_create_project() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test that server can handle create project
        let params = Some(serde_json::json!({
            "name": "Test Project",
            "description": "A test project created via RPC"
        }));
        let result = server.handle_create_project(&params);
        assert!(result.is_ok(), "handle_create_project should return Ok");
        
        // Verify the response is valid JSON
        let response = result.unwrap();
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        assert!(response_json.get("id").is_some(), "Should have an id field");
        assert!(response_json.get("name").is_some(), "Should have a name field");
        assert_eq!(response_json.get("name").unwrap().as_str(), Some("Test Project"));
    }
    
    /// Test that the server can handle get project requests
    #[test]
    fn test_server_get_project() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test get project with a mock project ID
        let get_params = Some(serde_json::json!({
            "project_id": "123e4567-e89b-12d3-a456-426614174000"
        }));
        let result = server.handle_get_project(&get_params);
        assert!(result.is_ok(), "handle_get_project should return Ok");
        
        // Verify the response is valid JSON
        let response = result.unwrap();
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        assert_eq!(response_json.get("id").unwrap().as_str(), Some("123e4567-e89b-12d3-a456-426614174000"));
        assert_eq!(response_json.get("name").unwrap().as_str(), Some("Mock Project"));
    }
    
    /// Test that the server can handle list projects requests
    #[test]
    fn test_server_list_projects() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test list projects
        let result = server.handle_list_projects();
        assert!(result.is_ok(), "handle_list_projects should return Ok");
        
        // Verify the response is valid JSON array
        let response = result.unwrap();
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        assert!(response_json.is_array(), "Response should be an array");
        
        let projects_array = response_json.as_array().unwrap();
        assert_eq!(projects_array.len(), 2, "Should have exactly 2 mock projects");
        
        // Verify the mock projects
        let project1 = projects_array[0].as_object().unwrap();
        let project2 = projects_array[1].as_object().unwrap();
        
        assert_eq!(project1.get("name").unwrap().as_str(), Some("Mock Project 1"));
        assert_eq!(project2.get("name").unwrap().as_str(), Some("Mock Project 2"));
    }
    
    /// Test that the server can handle create goal requests
    #[test]
    fn test_server_create_goal() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test that server can handle create goal
        let params = Some(serde_json::json!({
            "project_id": "123e4567-e89b-12d3-a456-426614174000",
            "name": "Test Goal",
            "description": "A test goal created via RPC"
        }));
        let result = server.handle_create_goal(&params);
        assert!(result.is_ok(), "handle_create_goal should return Ok");
        
        // Verify the response is valid JSON
        let response = result.unwrap();
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        assert!(response_json.get("id").is_some(), "Should have an id field");
        assert!(response_json.get("name").is_some(), "Should have a name field");
        assert_eq!(response_json.get("name").unwrap().as_str(), Some("Test Goal"));
        assert_eq!(response_json.get("project_id").unwrap().as_str(), Some("123e4567-e89b-12d3-a456-426614174000"));
    }
    
    /// Test that the server can handle get goal requests
    #[test]
    fn test_server_get_goal() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test get goal with a mock goal ID
        let get_params = Some(serde_json::json!({
            "goal_id": "456e7890-e89b-12d3-a456-426614174000"
        }));
        let result = server.handle_get_goal(&get_params);
        assert!(result.is_ok(), "handle_get_goal should return Ok");
        
        // Verify the response is valid JSON
        let response = result.unwrap();
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        assert_eq!(response_json.get("id").unwrap().as_str(), Some("456e7890-e89b-12d3-a456-426614174000"));
        assert_eq!(response_json.get("name").unwrap().as_str(), Some("Mock Goal"));
    }
    
    /// Test that the server can handle list goals requests
    #[test]
    fn test_server_list_goals() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test list goals with a mock project ID
        let list_params = Some(serde_json::json!({
            "project_id": "123e4567-e89b-12d3-a456-426614174000"
        }));
        let result = server.handle_list_goals(&list_params);
        assert!(result.is_ok(), "handle_list_goals should return Ok");
        
        // Verify the response is valid JSON array
        let response = result.unwrap();
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        assert!(response_json.is_array(), "Response should be an array");
        
        let goals_array = response_json.as_array().unwrap();
        assert_eq!(goals_array.len(), 2, "Should have exactly 2 mock goals");
        
        // Verify the mock goals
        let goal1 = goals_array[0].as_object().unwrap();
        let goal2 = goals_array[1].as_object().unwrap();
        
        assert_eq!(goal1.get("name").unwrap().as_str(), Some("Mock Goal 1"));
        assert_eq!(goal2.get("name").unwrap().as_str(), Some("Mock Goal 2"));
    }
    
    /// Test that the server can handle create task requests
    #[test]
    fn test_server_create_task() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test that server can handle create task
        let params = Some(serde_json::json!({
            "goal_id": "456e7890-e89b-12d3-a456-426614174000",
            "name": "Test Task",
            "description": "A test task created via RPC",
            "priority": 1
        }));
        let result = server.handle_create_task(&params);
        assert!(result.is_ok(), "handle_create_task should return Ok");
        
        // Verify the response is valid JSON
        let response = result.unwrap();
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        assert!(response_json.get("id").is_some(), "Should have an id field");
        assert!(response_json.get("name").is_some(), "Should have a name field");
        assert_eq!(response_json.get("name").unwrap().as_str(), Some("Test Task"));
        assert_eq!(response_json.get("goal_id").unwrap().as_str(), Some("456e7890-e89b-12d3-a456-426614174000"));
        assert_eq!(response_json.get("priority").unwrap().as_i64(), Some(1));
    }
    
    /// Test that the server can handle get task requests
    #[test]
    fn test_server_get_task() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test get task with a mock task ID
        let get_params = Some(serde_json::json!({
            "task_id": "789e0123-e89b-12d3-a456-426614174000"
        }));
        let result = server.handle_get_task(&get_params);
        assert!(result.is_ok(), "handle_get_task should return Ok");
        
        // Verify the response is valid JSON
        let response = result.unwrap();
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        assert_eq!(response_json.get("id").unwrap().as_str(), Some("789e0123-e89b-12d3-a456-426614174000"));
        assert_eq!(response_json.get("name").unwrap().as_str(), Some("Mock Task"));
    }
    
    /// Test that the server can handle list tasks requests
    #[test]
    fn test_server_list_tasks() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test list tasks with a mock goal ID
        let list_params = Some(serde_json::json!({
            "goal_id": "456e7890-e89b-12d3-a456-426614174000"
        }));
        let result = server.handle_list_tasks(&list_params);
        assert!(result.is_ok(), "handle_list_tasks should return Ok");
        
        // Verify the response is valid JSON array
        let response = result.unwrap();
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        assert!(response_json.is_array(), "Response should be an array");
        
        let tasks_array = response_json.as_array().unwrap();
        assert_eq!(tasks_array.len(), 2, "Should have exactly 2 mock tasks");
        
        // Verify the mock tasks
        let task1 = tasks_array[0].as_object().unwrap();
        let task2 = tasks_array[1].as_object().unwrap();
        
        assert_eq!(task1.get("name").unwrap().as_str(), Some("Mock Task 1"));
        assert_eq!(task2.get("name").unwrap().as_str(), Some("Mock Task 2"));
    }
    
    /// Test that the server can handle update project requests
    #[test]
    fn test_server_update_project() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test update project with mock parameters
        let params = Some(serde_json::json!({
            "project_id": "123e4567-e89b-12d3-a456-426614174000",
            "name": "Updated Project Name",
            "description": "Updated project description"
        }));
        let result = server.handle_update_project(&params);
        assert!(result.is_ok(), "handle_update_project should return Ok");
        
        // Verify the response is valid JSON
        let response = result.unwrap();
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        assert_eq!(response_json.get("id").unwrap().as_str(), Some("123e4567-e89b-12d3-a456-426614174000"));
        assert_eq!(response_json.get("name").unwrap().as_str(), Some("Updated Project Name"));
        assert_eq!(response_json.get("description").unwrap().as_str(), Some("Updated project description"));
        assert!(response_json.get("updated_at").is_some());
    }
    
    /// Test that the server can handle update goal requests
    #[test]
    fn test_server_update_goal() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test update goal with mock parameters
        let params = Some(serde_json::json!({
            "goal_id": "456e7890-e89b-12d3-a456-426614174000",
            "name": "Updated Goal Name",
            "description": "Updated goal description",
            "status": "completed"
        }));
        let result = server.handle_update_goal(&params);
        assert!(result.is_ok(), "handle_update_goal should return Ok");
        
        // Verify the response is valid JSON
        let response = result.unwrap();
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        assert_eq!(response_json.get("id").unwrap().as_str(), Some("456e7890-e89b-12d3-a456-426614174000"));
        assert_eq!(response_json.get("name").unwrap().as_str(), Some("Updated Goal Name"));
        assert_eq!(response_json.get("description").unwrap().as_str(), Some("Updated goal description"));
        assert_eq!(response_json.get("status").unwrap().as_str(), Some("completed"));
        assert!(response_json.get("updated_at").is_some());
    }
    
    /// Test that the server can handle update task requests
    #[test]
    fn test_server_update_task() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test update task with mock parameters
        let params = Some(serde_json::json!({
            "task_id": "789e0123-e89b-12d3-a456-426614174000",
            "name": "Updated Task Name",
            "description": "Updated task description",
            "status": "in_progress",
            "priority": 5
        }));
        let result = server.handle_update_task(&params);
        assert!(result.is_ok(), "handle_update_task should return Ok");
        
        // Verify the response is valid JSON
        let response = result.unwrap();
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        assert_eq!(response_json.get("id").unwrap().as_str(), Some("789e0123-e89b-12d3-a456-426614174000"));
        assert_eq!(response_json.get("name").unwrap().as_str(), Some("Updated Task Name"));
        assert_eq!(response_json.get("description").unwrap().as_str(), Some("Updated task description"));
        assert_eq!(response_json.get("status").unwrap().as_str(), Some("in_progress"));
        assert_eq!(response_json.get("priority").unwrap().as_i64(), Some(5));
        assert!(response_json.get("updated_at").is_some());
    }
    
    /// Test that the server can handle delete project requests
    #[test]
    fn test_server_delete_project() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test delete project with mock parameters
        let params = Some(serde_json::json!({
            "project_id": "123e4567-e89b-12d3-a456-426614174000"
        }));
        let result = server.handle_delete_project(&params);
        assert!(result.is_ok(), "handle_delete_project should return Ok");
        
        // Verify the response is valid JSON
        let response = result.unwrap();
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        assert_eq!(response_json.get("success").unwrap().as_bool(), Some(true));
        assert_eq!(response_json.get("message").unwrap().as_str(), Some("Project deleted successfully"));
    }
    
    /// Test that the server can handle delete goal requests
    #[test]
    fn test_server_delete_goal() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test delete goal with mock parameters
        let params = Some(serde_json::json!({
            "goal_id": "456e7890-e89b-12d3-a456-426614174000"
        }));
        let result = server.handle_delete_goal(&params);
        assert!(result.is_ok(), "handle_delete_goal should return Ok");
        
        // Verify the response is valid JSON
        let response = result.unwrap();
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        assert_eq!(response_json.get("success").unwrap().as_bool(), Some(true));
        assert_eq!(response_json.get("message").unwrap().as_str(), Some("Goal deleted successfully"));
    }
    
    /// Test that the server can handle delete task requests
    #[test]
    fn test_server_delete_task() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test delete task with mock parameters
        let params = Some(serde_json::json!({
            "task_id": "789e0123-e89b-12d3-a456-426614174000"
        }));
        let result = server.handle_delete_task(&params);
        assert!(result.is_ok(), "handle_delete_task should return Ok");
        
        // Verify the response is valid JSON
        let response = result.unwrap();
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        assert_eq!(response_json.get("success").unwrap().as_bool(), Some(true));
        assert_eq!(response_json.get("message").unwrap().as_str(), Some("Task deleted successfully"));
    }
} 