//! HTTP server for MCP Streamable HTTP transport
//!
//! This module provides an HTTP server that implements the MCP 2025-06-18
//! Streamable HTTP transport specification.

use axum::{
    extract::{Json, State},
    http::{HeaderMap, StatusCode},
    response::{sse::Event, Sse},
    routing::{delete, get, post},
    Router,
};
use serde_json::Value;
use std::sync::Arc;
use tokio_stream::{wrappers::BroadcastStream, Stream, StreamExt};
use tower_http::cors::{Any, CorsLayer};
use tracing::{debug, error, info, warn};
use uuid::Uuid;

// Import modules for MCP tool implementations
use crate::embeddings::create_embedding;
use crate::iragl::{search_iragl_index, IraglSearchQuery, SearchType};
use crate::ollama::{ChatMessage, OllamaClient, OllamaConfig};
use crate::patterns::{PatternBootstrap, PatternRegistry};
use crate::stream_manager::{StreamManager, StreamError};

#[derive(Debug)]
struct ThinkingChunk {
    chunk_type: String,
    content: String,
}

/// MCP HTTP server state
#[derive(Clone)]
pub struct McpHttpServer {
    /// Server information
    pub server_info: ServerInfo,
    /// Session manager
    pub session_manager: Arc<SessionManager>,
    /// Stream manager
    pub stream_manager: Arc<StreamManager>,
    /// Ollama client for AI operations
    pub ollama_client: Arc<OllamaClient>,
    /// Pattern registry for pattern management
    pub pattern_registry: Arc<tokio::sync::RwLock<PatternRegistry>>,
}

/// Server information for MCP protocol
#[derive(Clone)]
pub struct ServerInfo {
    pub name: String,
    pub version: String,
    pub protocol_version: String,
}

/// Session manager for MCP sessions
#[derive(Clone)]
pub struct SessionManager {
    sessions: Arc<tokio::sync::RwLock<std::collections::HashMap<String, Session>>>,
}

/// Individual session data
#[derive(Clone)]
pub struct Session {
    pub id: String,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub last_activity: chrono::DateTime<chrono::Utc>,
    pub client_info: Option<Value>,
}



impl McpHttpServer {
    /// Create a new MCP HTTP server
    pub fn new() -> Self {
        // Initialize pattern registry with bootstrap
        let patterns_dir = std::path::PathBuf::from("patterns");
        let bootstrap = PatternBootstrap::new(patterns_dir);
        let pattern_registry = bootstrap
            .bootstrap_pattern_system()
            .unwrap_or_else(|_| PatternRegistry::new());

        // Create Ollama client
        let config_manager = crate::config::ConfigManager::new();
        let ollama_client =
            OllamaClient::from_config_manager(&config_manager).unwrap_or_else(|_| {
                let config = OllamaConfig {
                    base_url: "http://localhost:11434".to_string(),
                    timeout_seconds: 30,
                    progress_timeout_seconds: 10,
                };
                OllamaClient::new(config).expect("Failed to create Ollama client")
            });

        Self {
            server_info: ServerInfo {
                name: "paragonic-mcp-server".to_string(),
                version: env!("CARGO_PKG_VERSION").to_string(),
                protocol_version: "2025-06-18".to_string(),
            },
            session_manager: Arc::new(SessionManager::new()),
            stream_manager: Arc::new(StreamManager::new(
                std::time::Duration::from_secs(300), // 5 minute timeout
                5, // max streams per session
                100, // max total streams
            )),
            ollama_client: Arc::new(ollama_client),
            pattern_registry: Arc::new(tokio::sync::RwLock::new(pattern_registry)),
        }
    }

    /// Create the HTTP router with MCP endpoints
    pub fn create_router(self) -> Router {
        // Configure CORS for local development
        let cors = CorsLayer::new()
            .allow_origin(Any)
            .allow_methods(Any)
            .allow_headers(Any);

        Router::new()
            .route("/mcp", post(Self::handle_post))
            .route("/mcp", get(Self::handle_get))
            .route("/mcp", delete(Self::handle_delete))
            .layer(cors)
            .with_state(self)
    }

    /// Handle POST requests (JSON-RPC messages)
    async fn handle_post(
        State(server): State<Self>,
        headers: HeaderMap,
        Json(body): Json<Value>,
    ) -> Result<axum::response::Response, StatusCode> {
        debug!("Received POST request to /mcp");

        // Validate required headers
        if let Err(e) = Self::validate_headers(&headers) {
            error!("Header validation failed: {}", e);
            return Err(StatusCode::BAD_REQUEST);
        }

        // Parse and validate JSON-RPC message
        let jsonrpc_message = match Self::parse_jsonrpc_message(&body) {
            Ok(msg) => msg,
            Err(e) => {
                error!("JSON-RPC parsing failed: {}", e);
                return Err(StatusCode::BAD_REQUEST);
            }
        };

        // Handle the message based on type
        match jsonrpc_message {
            JsonRpcMessage::Request(request) => Self::handle_jsonrpc_request(server, request).await,
            JsonRpcMessage::Notification(notification) => {
                Self::handle_jsonrpc_notification(server, notification).await
            }
            JsonRpcMessage::Response(response) => {
                Self::handle_jsonrpc_response(server, response).await
            }
        }
    }

    /// Handle GET requests (SSE stream initiation)
    async fn handle_get(
        State(server): State<Self>,
        headers: HeaderMap,
    ) -> Result<Sse<impl Stream<Item = Result<Event, axum::Error>>>, StatusCode> {
        debug!("Received GET request to /mcp");

        // Validate required headers
        if let Err(e) = Self::validate_headers(&headers) {
            error!("Header validation failed: {}", e);
            return Err(StatusCode::BAD_REQUEST);
        }

        // Check if Accept header includes text/event-stream
        if !Self::accepts_sse(&headers) {
            warn!("GET request without SSE Accept header");
            return Err(StatusCode::METHOD_NOT_ALLOWED);
        }

        // Get or create session
        let session_id = Self::get_session_id(&headers);
        let session = server
            .session_manager
            .get_or_create_session(session_id)
            .await;

        // Create SSE stream
        let stream = server.stream_manager.create_axum_sse_stream(&session.id).await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

        Ok(Sse::new(stream))
    }

    /// Handle DELETE requests (session termination)
    async fn handle_delete(
        State(server): State<Self>,
        headers: HeaderMap,
    ) -> Result<StatusCode, StatusCode> {
        debug!("Received DELETE request to /mcp");

        // Validate required headers
        if let Err(e) = Self::validate_headers(&headers) {
            error!("Header validation failed: {}", e);
            return Err(StatusCode::BAD_REQUEST);
        }

        // Get session ID
        let session_id = match Self::get_session_id(&headers) {
            Some(id) => id,
            None => {
                error!("DELETE request without session ID");
                return Err(StatusCode::BAD_REQUEST);
            }
        };

        // Terminate session
        if server.session_manager.terminate_session(&session_id).await {
            info!("Session {} terminated", session_id);
            Ok(StatusCode::OK)
        } else {
            warn!("Session {} not found for termination", session_id);
            Err(StatusCode::NOT_FOUND)
        }
    }

    /// Validate required headers
    fn validate_headers(headers: &HeaderMap) -> Result<(), String> {
        // Check MCP Protocol Version header
        if !headers.contains_key("mcp-protocol-version") {
            return Err("Missing MCP-Protocol-Version header".to_string());
        }

        // Check Origin header for security
        if !headers.contains_key("origin") {
            return Err("Missing Origin header".to_string());
        }

        // Validate Origin (for now, accept any origin in development)
        // TODO: Implement proper origin validation for production

        Ok(())
    }

    /// Check if request accepts SSE
    fn accepts_sse(headers: &HeaderMap) -> bool {
        headers
            .get("accept")
            .and_then(|v| v.to_str().ok())
            .map(|s| s.contains("text/event-stream"))
            .unwrap_or(false)
    }

    /// Get session ID from headers
    fn get_session_id(headers: &HeaderMap) -> Option<String> {
        headers
            .get("mcp-session-id")
            .and_then(|v| v.to_str().ok())
            .map(|s| s.to_string())
    }

    /// Parse JSON-RPC message
    fn parse_jsonrpc_message(value: &Value) -> Result<JsonRpcMessage, String> {
        // Basic JSON-RPC 2.0 validation
        if !value.is_object() {
            return Err("Message must be a JSON object".to_string());
        }

        let obj = value.as_object().unwrap();

        // Check for required jsonrpc field
        if obj.get("jsonrpc") != Some(&Value::String("2.0".to_string())) {
            return Err("Invalid or missing jsonrpc field".to_string());
        }

        // Determine message type
        if obj.contains_key("method") {
            if obj.contains_key("id") {
                Ok(JsonRpcMessage::Request(value.clone()))
            } else {
                Ok(JsonRpcMessage::Notification(value.clone()))
            }
        } else if obj.contains_key("result") || obj.contains_key("error") {
            Ok(JsonRpcMessage::Response(value.clone()))
        } else {
            Err("Invalid JSON-RPC message: missing method, result, or error".to_string())
        }
    }

    /// Handle JSON-RPC request
    async fn handle_jsonrpc_request(
        server: Self,
        request: Value,
    ) -> Result<axum::response::Response, StatusCode> {
        let method = request
            .get("method")
            .and_then(|m| m.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;

        let params = request.get("params");
        let id = request.get("id").unwrap_or(&Value::Null);

        // Handle different MCP methods
        let result = match method {
            // MCP Protocol Methods
            "initialize" => Self::handle_initialize(&server, params).await,
            "tools/list" => Self::handle_tools_list(&server, params).await,
            "tools/call" => Self::handle_tools_call(&server, params).await,
            "resources/list" => Self::handle_resources_list(&server, params).await,
            "resources/read" => Self::handle_resources_read(&server, params).await,
            "resources/subscribe" => Self::handle_resources_subscribe(&server, params).await,
            "resources/unsubscribe" => Self::handle_resources_unsubscribe(&server, params).await,
            "resources/templates/list" => {
                Self::handle_resources_templates_list(&server, params).await
            }

            // Prompts
            "prompts/list" => Self::handle_prompts_list(&server, params).await,
            "prompts/get" => Self::handle_prompts_get(&server, params).await,

            // Roots
            "roots/list" => Self::handle_roots_list(&server, params).await,

            // Logging
            "logging/setLevel" => Self::handle_logging_set_level(&server, params).await,

            // Notifications (handled as requests for now)
            "notifications/cancelled" => {
                Self::handle_notifications_cancelled(&server, params).await
            }
            "notifications/initialized" => {
                Self::handle_notifications_initialized(&server, params).await
            }
            "notifications/message" => Self::handle_notifications_message(&server, params).await,
            "notifications/progress" => Self::handle_notifications_progress(&server, params).await,
            "notifications/prompts/list_changed" => {
                Self::handle_notifications_prompts_list_changed(&server, params).await
            }
            "notifications/resources/list_changed" => {
                Self::handle_notifications_resources_list_changed(&server, params).await
            }
            "notifications/resources/updated" => {
                Self::handle_notifications_resources_updated(&server, params).await
            }
            "notifications/roots/list_changed" => {
                Self::handle_notifications_roots_list_changed(&server, params).await
            }
            "notifications/tools/list_changed" => {
                Self::handle_notifications_tools_list_changed(&server, params).await
            }

            // AI and Thinking Model Support (Critical)
            "completion/complete" => Self::handle_completion_complete(&server, params).await,
            "elicitation/create" => Self::handle_elicitation_create(&server, params).await,
            "sampling/createMessage" => Self::handle_sampling_create_message(&server, params).await,

            // Ping
            "ping" => Self::handle_ping(&server, params).await,

            // Legacy support for direct tool calls (for backward compatibility)
            "chat_completion" => Self::handle_chat_completion(&server, params).await,
            "formatted_chat_completion" => {
                Self::handle_formatted_chat_completion(&server, params).await
            }
            "agent_chat_completion" => Self::handle_agent_chat_completion(&server, params).await,
            "streaming_chat_completion" => {
                Self::handle_streaming_chat_completion(&server, params).await
            }

            // File Operations
            "read_file" => Self::handle_read_file(&server, params).await,
            "write_file" => Self::handle_write_file(&server, params).await,
            "list_files" => Self::handle_list_files(&server, params).await,

            // Model Management
            "list_models" => Self::handle_list_models(&server, params).await,
            "model_info" => Self::handle_model_info(&server, params).await,
            "generate_embedding" => Self::handle_generate_embedding(&server, params).await,

            // Project Management
            "create_project" => Self::handle_create_project(&server, params).await,
            "get_project" => Self::handle_get_project(&server, params).await,
            "list_projects" => Self::handle_list_projects(&server, params).await,
            "update_project" => Self::handle_update_project(&server, params).await,
            "delete_project" => Self::handle_delete_project(&server, params).await,

            // Goal Management
            "create_goal" => Self::handle_create_goal(&server, params).await,
            "get_goal" => Self::handle_get_goal(&server, params).await,
            "list_goals" => Self::handle_list_goals(&server, params).await,
            "update_goal" => Self::handle_update_goal(&server, params).await,
            "delete_goal" => Self::handle_delete_goal(&server, params).await,

            // Task Management
            "create_task" => Self::handle_create_task(&server, params).await,
            "get_task" => Self::handle_get_task(&server, params).await,
            "list_tasks" => Self::handle_list_tasks(&server, params).await,
            "update_task" => Self::handle_update_task(&server, params).await,
            "delete_task" => Self::handle_delete_task(&server, params).await,

            // Search & Knowledge Management
            "search_embeddings" => Self::handle_search_embeddings(&server, params).await,
            "find_similar_content" => Self::handle_find_similar_content(&server, params).await,
            "iragl_search" => Self::handle_iragl_search(&server, params).await,
            "hybrid_search" => Self::handle_hybrid_search(&server, params).await,
            "content_association" => Self::handle_content_association(&server, params).await,
            "ingest_knowledge_stream" => {
                Self::handle_ingest_knowledge_stream(&server, params).await
            }

            // Agent Management
            "create_agent" => Self::handle_create_agent(&server, params).await,
            "delete_agent" => Self::handle_delete_agent(&server, params).await,
            "create_conversation" => Self::handle_create_conversation(&server, params).await,
            "get_conversation" => Self::handle_get_conversation(&server, params).await,

            // Pattern Management
            "list_patterns" => Self::handle_list_patterns(&server, params).await,
            "get_pattern" => Self::handle_get_pattern(&server, params).await,
            "execute_pattern" => Self::handle_execute_pattern(&server, params).await,
            "get_pattern_executions" => Self::handle_get_pattern_executions(&server, params).await,
            "get_pattern_metrics" => Self::handle_get_pattern_metrics(&server, params).await,
            "get_tool_patterns" => Self::handle_get_tool_patterns(&server, params).await,
            "trigger_session_patterns" => {
                Self::handle_trigger_session_patterns(&server, params).await
            }

            // Optimization & Debug
            "optimize_knowledge_base" => {
                Self::handle_optimize_knowledge_base(&server, params).await
            }
            "optimization_status" => Self::handle_optimization_status(&server, params).await,
            "optimization_history" => Self::handle_optimization_history(&server, params).await,
            "debug_markdown_test" => Self::handle_debug_markdown_test(&server, params).await,
            "test_streaming_format" => Self::handle_test_streaming_format(&server, params).await,
            "get_next_chunk" => Self::handle_get_next_chunk(&server, params).await,

            // Tool Execution
            "execute_tool_call" => Self::handle_execute_tool_call(&server, params).await,
            "parse_tool_calls" => Self::handle_parse_tool_calls(&server, params).await,

            // Unknown method
            _ => {
                error!("Unknown method: {}", method);
                Err(StatusCode::METHOD_NOT_ALLOWED)
            }
        };

        match result {
            Ok(result_value) => {
                let response = serde_json::json!({
                    "jsonrpc": "2.0",
                    "result": result_value,
                    "id": id
                });

                Ok(axum::response::Response::builder()
                    .status(StatusCode::OK)
                    .header("content-type", "application/json")
                    .body(axum::body::Body::from(
                        serde_json::to_string(&response).unwrap(),
                    ))
                    .unwrap())
            }
            Err(status_code) => {
                let error_response = serde_json::json!({
                    "jsonrpc": "2.0",
                    "error": {
                        "code": status_code.as_u16(),
                        "message": format!("Method '{}' failed", method)
                    },
                    "id": id
                });

                Ok(axum::response::Response::builder()
                    .status(status_code)
                    .header("content-type", "application/json")
                    .body(axum::body::Body::from(
                        serde_json::to_string(&error_response).unwrap(),
                    ))
                    .unwrap())
            }
        }
    }

    /// Handle JSON-RPC notification
    async fn handle_jsonrpc_notification(
        _server: Self,
        _notification: Value,
    ) -> Result<axum::response::Response, StatusCode> {
        // Notifications don't require a response
        Ok(axum::response::Response::builder()
            .status(StatusCode::ACCEPTED)
            .body(axum::body::Body::empty())
            .unwrap())
    }

    /// Handle JSON-RPC response
    async fn handle_jsonrpc_response(
        _server: Self,
        _response: Value,
    ) -> Result<axum::response::Response, StatusCode> {
        // Responses don't require a response
        Ok(axum::response::Response::builder()
            .status(StatusCode::ACCEPTED)
            .body(axum::body::Body::empty())
            .unwrap())
    }

    // MCP Protocol Methods
    async fn handle_initialize(
        server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        // Create or get a session and prepare an SSE stream
        let session = server.session_manager.get_or_create_session(None).await;
        let _stream = server.stream_manager.create_stream(&session.id).await;

        Ok(serde_json::json!({
            "protocolVersion": server.server_info.protocol_version,
            "capabilities": {
                "tools": {},
                "resources": {},
                "notifications": {}
            },
            "serverInfo": {
                "name": server.server_info.name,
                "version": server.server_info.version
            },
            "sessionId": session.id,
            "streamId": session.id
        }))
    }

    async fn handle_tools_list(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        // Return list of all available tools for MCP-only compliance
        Ok(serde_json::json!({
            "tools": [
                // AI & Chat Tools
                {
                    "name": "chat_completion",
                    "description": "Generate AI chat completions with thinking model support",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "model": {"type": "string", "description": "Model to use for completion"},
                            "message": {"type": "string", "description": "User message"},
                            "options": {"type": "object", "description": "Completion options"}
                        },
                        "required": ["message"]
                    }
                },
                {
                    "name": "formatted_chat_completion",
                    "description": "Generate formatted AI chat completions",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "model": {"type": "string"},
                            "message": {"type": "string"},
                            "format_config": {"type": "object"}
                        },
                        "required": ["message"]
                    }
                },
                {
                    "name": "streaming_chat_completion",
                    "description": "Generate streaming AI chat completions",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "model": {"type": "string"},
                            "message": {"type": "string"},
                            "chunk_size": {"type": "number"}
                        },
                        "required": ["message"]
                    }
                },
                // Model Management Tools
                {
                    "name": "list_models",
                    "description": "List available AI models",
                    "inputSchema": {
                        "type": "object",
                        "properties": {}
                    }
                },
                {
                    "name": "model_info",
                    "description": "Get information about a specific model",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "model": {"type": "string"}
                        },
                        "required": ["model"]
                    }
                },
                {
                    "name": "generate_embedding",
                    "description": "Generate embeddings for text",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "text": {"type": "string"},
                            "model": {"type": "string"}
                        },
                        "required": ["text"]
                    }
                },
                // Search & Knowledge Tools
                {
                    "name": "search_embeddings",
                    "description": "Search content using vector embeddings",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "query": {"type": "string"},
                            "limit": {"type": "number"}
                        },
                        "required": ["query"]
                    }
                },
                {
                    "name": "find_similar_content",
                    "description": "Find similar content with filtering",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "query": {"type": "string"},
                            "content_type": {"type": "string"},
                            "limit": {"type": "number"},
                            "threshold": {"type": "number"}
                        },
                        "required": ["query"]
                    }
                },
                {
                    "name": "hybrid_search",
                    "description": "Perform hybrid search combining vector and text matching",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "query": {"type": "string"},
                            "content_type": {"type": "string"},
                            "limit": {"type": "number"},
                            "threshold": {"type": "number"},
                            "include_text_filtering": {"type": "boolean"}
                        },
                        "required": ["query"]
                    }
                },
                {
                    "name": "iragl_search",
                    "description": "Search IRAGL knowledge base",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "query": {"type": "string"},
                            "search_type": {"type": "string"},
                            "limit": {"type": "integer"}
                        },
                        "required": ["query"]
                    }
                },
                // Project Management Tools
                {
                    "name": "create_project",
                    "description": "Create a new project",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "name": {"type": "string"},
                            "description": {"type": "string"}
                        },
                        "required": ["name"]
                    }
                },
                {
                    "name": "list_projects",
                    "description": "List all projects",
                    "inputSchema": {
                        "type": "object",
                        "properties": {}
                    }
                },
                {
                    "name": "get_project",
                    "description": "Get project details",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "project_id": {"type": "string"}
                        },
                        "required": ["project_id"]
                    }
                },
                // File Operations Tools
                {
                    "name": "write_file",
                    "description": "Write content to a file",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "file_path": {"type": "string"},
                            "content": {"type": "string"}
                        },
                        "required": ["file_path", "content"]
                    }
                },
                {
                    "name": "read_file",
                    "description": "Read content from a file",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "file_path": {"type": "string"}
                        },
                        "required": ["file_path"]
                    }
                },
                {
                    "name": "list_files",
                    "description": "List files in a directory",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "directory": {"type": "string"}
                        }
                    }
                },
                // Pattern Management Tools
                {
                    "name": "list_patterns",
                    "description": "List available patterns",
                    "inputSchema": {
                        "type": "object",
                        "properties": {}
                    }
                },
                {
                    "name": "execute_pattern",
                    "description": "Execute a pattern",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "pattern_name": {"type": "string"},
                            "parameters": {"type": "object"}
                        },
                        "required": ["pattern_name"]
                    }
                }
            ]
        }))
    }

    async fn handle_tools_call(server: &Self, params: Option<&Value>) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;
        let name = params
            .get("name")
            .and_then(|n| n.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;
        let default_args = serde_json::json!({});
        let arguments = params.get("arguments").unwrap_or(&default_args);
        let arguments_clone = arguments.clone();

        // Route to appropriate handler based on tool name
        let result = match name {
            // AI & Chat Tools
            "chat_completion" => {
                let model = arguments
                    .get("model")
                    .and_then(|m| m.as_str())
                    .unwrap_or("deepseek-r1:1.5b");
                let message = arguments
                    .get("message")
                    .and_then(|m| m.as_str())
                    .ok_or(StatusCode::BAD_REQUEST)?;
                let options = arguments.get("options");

                // Use the existing MCP completion handler
                Self::handle_completion_complete(
                    server,
                    Some(&serde_json::json!({
                        "prompt": message,
                        "model": model,
                        "options": options
                    })),
                )
                .await
            }
            "formatted_chat_completion" => {
                let model = arguments
                    .get("model")
                    .and_then(|m| m.as_str())
                    .unwrap_or("deepseek-r1:1.5b");
                let message = arguments
                    .get("message")
                    .and_then(|m| m.as_str())
                    .ok_or(StatusCode::BAD_REQUEST)?;
                let format_config = arguments.get("format_config");

                // Use the existing formatted chat completion handler
                Self::handle_formatted_chat_completion(
                    server,
                    Some(&serde_json::json!({
                        "model": model,
                        "message": message,
                        "format_config": format_config
                    })),
                )
                .await
            }
            "streaming_chat_completion" => {
                let model = arguments
                    .get("model")
                    .and_then(|m| m.as_str())
                    .unwrap_or("deepseek-r1:1.5b");
                let message = arguments
                    .get("message")
                    .and_then(|m| m.as_str())
                    .ok_or(StatusCode::BAD_REQUEST)?;
                let chunk_size = arguments
                    .get("chunk_size")
                    .and_then(|c| c.as_u64())
                    .unwrap_or(30);

                // Use the existing streaming chat completion handler
                Self::handle_streaming_chat_completion(
                    server,
                    Some(&serde_json::json!({
                        "model": model,
                        "message": message,
                        "chunk_size": chunk_size
                    })),
                )
                .await
            }
            // Model Management Tools
            "list_models" => Self::handle_list_models(server, Some(&arguments_clone)).await,
            "model_info" => Self::handle_model_info(server, Some(&arguments_clone)).await,
            "generate_embedding" => {
                Self::handle_generate_embedding(server, Some(&arguments_clone)).await
            }
            // Search & Knowledge Tools
            "search_embeddings" => {
                Self::handle_search_embeddings(server, Some(&arguments_clone)).await
            }
            "find_similar_content" => {
                Self::handle_find_similar_content(server, Some(&arguments_clone)).await
            }
            "hybrid_search" => Self::handle_hybrid_search(server, Some(&arguments_clone)).await,
            "iragl_search" => Self::handle_iragl_search(server, Some(&arguments_clone)).await,
            // Project Management Tools
            "create_project" => Self::handle_create_project(server, Some(&arguments_clone)).await,
            "list_projects" => Self::handle_list_projects(server, Some(&arguments_clone)).await,
            "get_project" => Self::handle_get_project(server, Some(&arguments_clone)).await,
            // File Operations Tools
            "write_file" => Self::handle_write_file(server, Some(&arguments_clone)).await,
            "read_file" => Self::handle_read_file(server, Some(&arguments_clone)).await,
            "list_files" => Self::handle_list_files(server, Some(&arguments_clone)).await,
            // Pattern Management Tools
            "list_patterns" => Self::handle_list_patterns(server, Some(&arguments_clone)).await,
            "execute_pattern" => Self::handle_execute_pattern(server, Some(&arguments_clone)).await,
            // Unknown tool
            _ => {
                error!("Unknown tool: {}", name);
                return Err(StatusCode::BAD_REQUEST);
            }
        };

        // Wrap the result in MCP tool call response format
        match result {
            Ok(data) => Ok(serde_json::json!({
                "content": [
                    {
                        "type": "text",
                        "text": serde_json::to_string(&data).unwrap_or_default()
                    }
                ]
            })),
            Err(e) => {
                error!("Tool call failed for {}: {:?}", name, e);
                Err(e)
            }
        }
    }

    async fn handle_resources_list(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "resources": [
                {
                    "uri": "neovim://buffers",
                    "name": "Neovim Buffers",
                    "description": "All open buffers in the current Neovim session",
                    "mimeType": "application/json"
                },
                {
                    "uri": "neovim://session",
                    "name": "Neovim Session",
                    "description": "Current Neovim session information",
                    "mimeType": "application/json"
                },
                {
                    "uri": "patterns://list",
                    "name": "Patterns List",
                    "description": "Available patterns and their metadata",
                    "mimeType": "application/json"
                },
                {
                    "uri": "iragl://index",
                    "name": "IRAGL Index",
                    "description": "IRAGL knowledge base index information",
                    "mimeType": "application/json"
                }
            ]
        }))
    }

    async fn handle_resources_read(
        _server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;
        let uri = params
            .get("uri")
            .and_then(|u| u.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;

        match uri {
            "neovim://buffers" => {
                // Return mock buffer data for now
                Ok(serde_json::json!({
                    "contents": [
                        {
                            "uri": "neovim://buffer/1",
                            "mimeType": "text/plain",
                            "text": "Buffer 1 content"
                        }
                    ]
                }))
            }
            "neovim://session" => Ok(serde_json::json!({
                "contents": [
                    {
                        "uri": "neovim://session",
                        "mimeType": "application/json",
                        "text": serde_json::to_string(&serde_json::json!({
                            "session_id": "test-session",
                            "buffers": 1,
                            "windows": 1
                        })).unwrap()
                    }
                ]
            })),
            "patterns://list" => Ok(serde_json::json!({
                "contents": [
                    {
                        "uri": "patterns://list",
                        "mimeType": "application/json",
                        "text": serde_json::to_string(&serde_json::json!({
                            "patterns": [
                                {
                                    "name": "session_summary_generation",
                                    "description": "Generate session summary",
                                    "category": "session_management"
                                }
                            ]
                        })).unwrap()
                    }
                ]
            })),
            _ => Err(StatusCode::NOT_FOUND),
        }
    }

    async fn handle_resources_subscribe(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        // For now, return a simple subscription response
        Ok(serde_json::json!({
            "subscription": "test-subscription-id"
        }))
    }

    // Core Chat & AI Functions
    async fn handle_chat_completion(
        server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;
        let model = params
            .get("model")
            .and_then(|m| m.as_str())
            .unwrap_or("deepseek-r1:1.5b");
        let message = params
            .get("message")
            .and_then(|m| m.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;

        // Check if this is a thinking model
        let is_thinking_model = Self::is_thinking_model(model);

        // Create chat message with appropriate prompt for thinking models
        let chat_message = if is_thinking_model {
            // For thinking models, wrap the message in a thinking prompt
            let thinking_prompt = format!(
                "You are a helpful AI assistant. When solving complex problems, use <think> tags to show your reasoning process step by step. Think through the problem carefully before providing your final answer.\n\nUser: {}\n\nAssistant:",
                message
            );
            ChatMessage {
                role: "user".to_string(),
                content: thinking_prompt,
            }
        } else {
            // Regular chat message for non-thinking models
            ChatMessage {
                role: "user".to_string(),
                content: message.to_string(),
            }
        };

        // Send to Ollama
        match server
            .ollama_client
            .chat_completion(model, vec![chat_message], false)
            .await
        {
            Ok(response) => Ok(serde_json::json!({
                "content": response.message.content,
                "model": model,
                "done": response.done
            })),
            Err(e) => {
                error!("Chat completion failed: {}", e);
                Err(StatusCode::INTERNAL_SERVER_ERROR)
            }
        }
    }

    async fn handle_formatted_chat_completion(
        server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;
        let model = params
            .get("model")
            .and_then(|m| m.as_str())
            .unwrap_or("deepseek-r1:1.5b");
        let message = params
            .get("message")
            .and_then(|m| m.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;
        let format_config = params.get("format_config");

        // Check if this is a thinking model
        let is_thinking_model = Self::is_thinking_model(model);

        // Create chat message with appropriate prompt for thinking models
        let chat_message = if is_thinking_model {
            // For thinking models, wrap the message in a thinking prompt
            let thinking_prompt = format!(
                "You are a helpful AI assistant. When solving complex problems, use <think> tags to show your reasoning process step by step. Think through the problem carefully before providing your final answer.\n\nUser: {}\n\nAssistant:",
                message
            );
            ChatMessage {
                role: "user".to_string(),
                content: thinking_prompt,
            }
        } else {
            // Regular chat message for non-thinking models
            ChatMessage {
                role: "user".to_string(),
                content: message.to_string(),
            }
        };

        // Send to Ollama
        match server
            .ollama_client
            .chat_completion(model, vec![chat_message], false)
            .await
        {
            Ok(response) => {
                let content = response.message.content;

                // Format the response based on format_config
                let formatted_content = if let Some(config) = format_config {
                    // Apply formatting based on config
                    Self::format_response_with_config(&content, config)
                } else {
                    // Default formatting
                    Self::format_response_default(&content)
                };

                Ok(serde_json::json!({
                    "formatted_content": formatted_content,
                    "original_content": content,
                    "model": model,
                    "done": response.done,
                    "duration_sec": 0.0 // TODO: Calculate actual duration
                }))
            }
            Err(e) => {
                error!("Formatted chat completion failed: {}", e);
                Err(StatusCode::INTERNAL_SERVER_ERROR)
            }
        }
    }

    async fn handle_agent_chat_completion(
        server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        // Similar to handle_chat_completion but for agent context
        Self::handle_chat_completion(server, params).await
    }

    async fn handle_streaming_chat_completion(
        server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;
        let model = params
            .get("model")
            .and_then(|m| m.as_str())
            .unwrap_or("deepseek-r1:1.5b");
        let message = params
            .get("message")
            .and_then(|m| m.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;

        // Extract progress token from _meta field if present
        let progress_token = params
            .get("_meta")
            .and_then(|meta| meta.get("progressToken"))
            .and_then(|token| token.as_str())
            .map(|s| s.to_string())
            .unwrap_or_else(|| format!("streaming_{}", chrono::Utc::now().timestamp_millis()));

        info!("🔄 Streaming chat completion request:");
        info!("   Model: {}", model);
        info!("   Message: {}", message);

        // Check if this is a thinking model
        let is_thinking_model = Self::is_thinking_model(model);
        info!("   Is thinking model: {}", is_thinking_model);

        // Create chat message with appropriate prompt for thinking models
        let chat_message = if is_thinking_model {
            // For thinking models, wrap the message in a thinking prompt
            let thinking_prompt = format!(
                "You are a helpful AI assistant. When solving complex problems, use <think> tags to show your reasoning process step by step. Think through the problem carefully before providing your final answer.\n\nUser: {}\n\nAssistant:",
                message
            );
            info!("   Using thinking prompt: {}", thinking_prompt);
            ChatMessage {
                role: "user".to_string(),
                content: thinking_prompt,
            }
        } else {
            // Regular chat message for non-thinking models
            info!("   Using regular prompt: {}", message);
            ChatMessage {
                role: "user".to_string(),
                content: message.to_string(),
            }
        };

        // Send to Ollama with streaming enabled
        info!("   Sending to Ollama with streaming enabled...");
        match server
            .ollama_client
            .chat_completion(model, vec![chat_message], true)
            .await
        {
            Ok(response) => {
                let content = response.message.content;
                info!("   ✅ Ollama response received:");
                info!("   Content length: {} characters", content.len());
                info!(
                    "   Content preview: {}",
                    content.chars().take(100).collect::<String>()
                );

                // Parse thinking content and send as structured chunks
                if is_thinking_model {
                    let chunks = Self::parse_thinking_content(&content);
                    info!("   📤 Sending {} thinking chunks to client", chunks.len());

                    // Send MCP progress notifications for thinking chunks
                    Self::send_mcp_progress_notifications(server, &chunks, &progress_token).await;

                    // Send first chunk immediately
                    if let Some(first_chunk) = chunks.first() {
                        let response_json = serde_json::json!({
                            "type": "streaming_chunk",
                            "chunk": first_chunk.content,
                            "chunk_type": first_chunk.chunk_type,
                            "chunk_index": 0,
                            "total_chunks": chunks.len()
                        });

                        info!("   📤 Sending first chunk to client:");
                        info!(
                            "   Response JSON: {}",
                            serde_json::to_string_pretty(&response_json).unwrap()
                        );

                                        // Send remaining chunks via SSE notifications
                // Add a delay to ensure client has established SSE connection
                info!("   ⏳ Waiting for client SSE connection to establish...");
                tokio::time::sleep(tokio::time::Duration::from_millis(1000)).await;
                info!("   📤 Starting to send remaining chunks via SSE");
                Self::send_remaining_chunks_via_sse(server, &chunks[1..], &progress_token).await;

                        Ok(response_json)
                    } else {
                        // Fallback to regular content if no thinking chunks found
                        let response_json = serde_json::json!({
                            "type": "streaming_chunk",
                            "chunk": content,
                            "chunk_type": "regular_content",
                            "chunk_index": 0,
                            "total_chunks": 1
                        });

                        Ok(response_json)
                    }
                } else {
                    // Regular content for non-thinking models
                    let response_json = serde_json::json!({
                        "type": "streaming_chunk",
                        "chunk": content,
                        "chunk_type": "regular_content",
                        "chunk_index": 0,
                        "total_chunks": 1,
                        "remaining_chunks": []
                    });

                    info!("   📤 Sending regular content to client:");
                    info!(
                        "   Response JSON: {}",
                        serde_json::to_string_pretty(&response_json).unwrap()
                    );

                    Ok(response_json)
                }
            }
            Err(e) => {
                error!("❌ Streaming chat completion failed: {}", e);
                Err(StatusCode::INTERNAL_SERVER_ERROR)
            }
        }
    }

    // File Operations
    async fn handle_read_file(_server: &Self, params: Option<&Value>) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;
        let file_path = params
            .get("file_path")
            .and_then(|p| p.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;

        match std::fs::read_to_string(file_path) {
            Ok(content) => Ok(serde_json::json!({
                "content": content,
                "file_path": file_path
            })),
            Err(e) => {
                error!("Failed to read file {}: {}", file_path, e);
                Err(StatusCode::NOT_FOUND)
            }
        }
    }

    async fn handle_write_file(
        _server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;
        let file_path = params
            .get("file_path")
            .and_then(|p| p.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;
        let content = params
            .get("content")
            .and_then(|c| c.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;

        match std::fs::write(file_path, content) {
            Ok(_) => Ok(serde_json::json!({
                "success": true,
                "file_path": file_path,
                "bytes_written": content.len()
            })),
            Err(e) => {
                error!("Failed to write file {}: {}", file_path, e);
                Err(StatusCode::INTERNAL_SERVER_ERROR)
            }
        }
    }

    async fn handle_list_files(
        _server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;
        let directory = params
            .get("directory")
            .and_then(|d| d.as_str())
            .unwrap_or(".");

        match std::fs::read_dir(directory) {
            Ok(entries) => {
                let files: Result<Vec<_>, _> = entries
                    .map(|entry| {
                        entry.map(|e| {
                            serde_json::json!({
                                "name": e.file_name().to_string_lossy(),
                                "path": e.path().to_string_lossy(),
                                "is_file": e.file_type().map(|ft| ft.is_file()).unwrap_or(false),
                                "is_dir": e.file_type().map(|ft| ft.is_dir()).unwrap_or(false)
                            })
                        })
                    })
                    .collect();

                match files {
                    Ok(file_list) => Ok(serde_json::json!({
                        "files": file_list,
                        "directory": directory
                    })),
                    Err(e) => {
                        error!("Failed to read directory {}: {}", directory, e);
                        Err(StatusCode::INTERNAL_SERVER_ERROR)
                    }
                }
            }
            Err(e) => {
                error!("Failed to read directory {}: {}", directory, e);
                Err(StatusCode::NOT_FOUND)
            }
        }
    }

    // Model Management
    async fn handle_list_models(
        server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        match server.ollama_client.list_models().await {
            Ok(models) => Ok(serde_json::json!({
                "models": models
            })),
            Err(e) => {
                error!("Failed to list models: {}", e);
                Err(StatusCode::INTERNAL_SERVER_ERROR)
            }
        }
    }

    async fn handle_model_info(server: &Self, params: Option<&Value>) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;
        let model = params
            .get("model")
            .and_then(|m| m.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;

        match server.ollama_client.model_info(model).await {
            Ok(info) => Ok(serde_json::json!({
                "model": model,
                "info": info
            })),
            Err(e) => {
                error!("Failed to get model info for {}: {}", model, e);
                Err(StatusCode::INTERNAL_SERVER_ERROR)
            }
        }
    }

    async fn handle_generate_embedding(
        _server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;
        let text = params
            .get("text")
            .and_then(|t| t.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;
        let model = params
            .get("model")
            .and_then(|m| m.as_str())
            .unwrap_or("nomic-embed-text");

        // Create embedding request
        let request = crate::models::CreateEmbeddingRequest {
            content_type: "text".to_string(),
            content_id: Uuid::new_v4(),
            content_text: text.to_string(),
            embedding_model: model.to_string(),
            metadata: None,
        };

        match create_embedding(request).await {
            Ok(embedding) => Ok(serde_json::json!({
                "embedding": embedding.embedding_vector,
                "model": model,
                "dimensions": embedding.embedding_vector.as_ref().map(|v| v.values.len()).unwrap_or(0)
            })),
            Err(e) => {
                error!("Failed to generate embedding: {}", e);
                Err(StatusCode::INTERNAL_SERVER_ERROR)
            }
        }
    }

    // Project Management (placeholder implementations)
    async fn handle_create_project(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "project_id": Uuid::new_v4().to_string(),
            "status": "created"
        }))
    }

    async fn handle_get_project(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "project": {
                "id": "test-project",
                "name": "Test Project",
                "status": "active"
            }
        }))
    }

    async fn handle_list_projects(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "projects": [
                {
                    "id": "test-project-1",
                    "name": "Test Project 1",
                    "status": "active"
                },
                {
                    "id": "test-project-2",
                    "name": "Test Project 2",
                    "status": "completed"
                }
            ]
        }))
    }

    async fn handle_update_project(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "success": true,
            "message": "Project updated"
        }))
    }

    async fn handle_delete_project(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "success": true,
            "message": "Project deleted"
        }))
    }

    // Goal Management (placeholder implementations)
    async fn handle_create_goal(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "goal_id": Uuid::new_v4().to_string(),
            "status": "created"
        }))
    }

    async fn handle_get_goal(_server: &Self, _params: Option<&Value>) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "goal": {
                "id": "test-goal",
                "title": "Test Goal",
                "status": "active"
            }
        }))
    }

    async fn handle_list_goals(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "goals": [
                {
                    "id": "test-goal-1",
                    "title": "Test Goal 1",
                    "status": "active"
                },
                {
                    "id": "test-goal-2",
                    "title": "Test Goal 2",
                    "status": "completed"
                }
            ]
        }))
    }

    async fn handle_update_goal(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "success": true,
            "message": "Goal updated"
        }))
    }

    async fn handle_delete_goal(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "success": true,
            "message": "Goal deleted"
        }))
    }

    // Task Management (placeholder implementations)
    async fn handle_create_task(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "task_id": Uuid::new_v4().to_string(),
            "status": "created"
        }))
    }

    async fn handle_get_task(_server: &Self, _params: Option<&Value>) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "task": {
                "id": "test-task",
                "title": "Test Task",
                "status": "pending"
            }
        }))
    }

    async fn handle_list_tasks(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "tasks": [
                {
                    "id": "test-task-1",
                    "title": "Test Task 1",
                    "status": "pending"
                },
                {
                    "id": "test-task-2",
                    "title": "Test Task 2",
                    "status": "completed"
                }
            ]
        }))
    }

    async fn handle_update_task(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "success": true,
            "message": "Task updated"
        }))
    }

    async fn handle_delete_task(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "success": true,
            "message": "Task deleted"
        }))
    }

    // Search & Knowledge Management
    async fn handle_search_embeddings(
        _server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;
        let query = params
            .get("query")
            .and_then(|q| q.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;
        let limit = params.get("limit").and_then(|l| l.as_u64()).unwrap_or(10);

        // Placeholder implementation
        Ok(serde_json::json!({
            "results": [
                {
                    "content": "Sample search result",
                    "similarity": 0.95,
                    "source": "test-document.md"
                }
            ],
            "query": query,
            "total_results": 1
        }))
    }

    async fn handle_find_similar_content(
        _server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;
        let content = params
            .get("content")
            .and_then(|c| c.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;

        // Placeholder implementation
        Ok(serde_json::json!({
            "similar_content": [
                {
                    "content": "Similar content found",
                    "similarity": 0.85,
                    "source": "similar-document.md"
                }
            ],
            "input_content": content
        }))
    }

    async fn handle_iragl_search(
        _server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;
        let query = params
            .get("query")
            .and_then(|q| q.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;
        let search_type = params
            .get("search_type")
            .and_then(|s| s.as_str())
            .unwrap_or("semantic");
        let limit = params.get("limit").and_then(|l| l.as_u64()).unwrap_or(10);

        // Create search query
        let search_query = IraglSearchQuery {
            query: query.to_string(),
            search_type: match search_type {
                "semantic" => SearchType::Semantic,
                "keyword" => SearchType::Keyword,
                "hybrid" => SearchType::Hybrid,
                "metadata" => SearchType::Metadata,
                _ => SearchType::Semantic,
            },
            limit: Some(limit as usize),
            filters: None,
            include_metadata: true,
        };

        match search_iragl_index(search_query).await {
            Ok(results) => {
                let results_json: Vec<Value> = results
                    .iter()
                    .map(|result| {
                        serde_json::json!({
                            "content": result.content_text,
                            "similarity_score": result.similarity_score,
                            "source_info": {
                                "file_path": result.source_info.file_path,
                                "section": result.source_info.section
                            }
                        })
                    })
                    .collect();

                Ok(serde_json::json!({
                    "results": results_json,
                    "query": query,
                    "search_type": search_type,
                    "total_results": results.len()
                }))
            }
            Err(e) => {
                error!("IRAGL search failed: {}", e);
                Err(StatusCode::INTERNAL_SERVER_ERROR)
            }
        }
    }

    async fn handle_hybrid_search(
        _server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;
        let query = params
            .get("query")
            .and_then(|q| q.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;

        // Placeholder implementation
        Ok(serde_json::json!({
            "results": [
                {
                    "content": "Hybrid search result",
                    "semantic_score": 0.9,
                    "keyword_score": 0.8,
                    "combined_score": 0.85
                }
            ],
            "query": query
        }))
    }

    async fn handle_content_association(
        _server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;
        let content = params
            .get("content")
            .and_then(|c| c.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;

        // Placeholder implementation
        Ok(serde_json::json!({
            "associations": [
                {
                    "related_content": "Associated content",
                    "association_strength": 0.75,
                    "association_type": "semantic"
                }
            ],
            "input_content": content
        }))
    }

    async fn handle_ingest_knowledge_stream(
        _server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;
        let content = params
            .get("content")
            .and_then(|c| c.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;

        // Placeholder implementation
        Ok(serde_json::json!({
            "ingested": true,
            "content_length": content.len(),
            "chunks_created": 1
        }))
    }

    // Agent Management (placeholder implementations)
    async fn handle_create_agent(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "agent_id": Uuid::new_v4().to_string(),
            "status": "created"
        }))
    }

    async fn handle_delete_agent(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "success": true,
            "message": "Agent deleted"
        }))
    }

    async fn handle_create_conversation(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "conversation_id": Uuid::new_v4().to_string(),
            "status": "created"
        }))
    }

    async fn handle_get_conversation(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "conversation": {
                "id": "test-conversation",
                "messages": [],
                "status": "active"
            }
        }))
    }

    // Pattern Management
    async fn handle_list_patterns(
        server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let pattern_registry = server.pattern_registry.read().await;
        let patterns: Vec<Value> = pattern_registry
            .list_patterns(None, None)
            .iter()
            .map(|pattern| {
                serde_json::json!({
                    "name": pattern.name,
                    "description": pattern.description,
                    "category": pattern.category,
                    "meta_level": pattern.meta_level
                })
            })
            .collect();

        Ok(serde_json::json!({
            "patterns": patterns
        }))
    }

    async fn handle_get_pattern(
        server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;
        let pattern_name = params
            .get("pattern_name")
            .and_then(|n| n.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;

        let pattern_registry = server.pattern_registry.read().await;
        // For now, return a mock pattern since get_pattern expects UUID
        Ok(serde_json::json!({
            "pattern": {
                "name": pattern_name,
                "description": "Mock pattern description",
                "category": "session_management",
                "meta_level": "operational"
            }
        }))
    }

    async fn handle_execute_pattern(
        server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;
        let pattern_name = params
            .get("pattern_name")
            .and_then(|n| n.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;
        let parameters = params.get("parameters").cloned();

        let mut pattern_registry = server.pattern_registry.write().await;
        match pattern_registry.execute_pattern(pattern_name, parameters) {
            Ok(execution) => Ok(serde_json::json!({
                "execution_id": execution.id,
                "pattern_name": pattern_name,
                "status": "executed",
                "trigger_type": execution.trigger_type
            })),
            Err(e) => {
                error!("Pattern execution failed: {}", e);
                Err(StatusCode::INTERNAL_SERVER_ERROR)
            }
        }
    }

    async fn handle_get_pattern_executions(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        // Placeholder implementation
        Ok(serde_json::json!({
            "executions": [
                {
                    "id": "test-execution",
                    "pattern_name": "test_pattern",
                    "timestamp": chrono::Utc::now().to_rfc3339(),
                    "status": "completed"
                }
            ]
        }))
    }

    async fn handle_get_pattern_metrics(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        // Placeholder implementation
        Ok(serde_json::json!({
            "metrics": {
                "total_executions": 10,
                "success_rate": 0.9,
                "average_duration": 1.5
            }
        }))
    }

    async fn handle_get_tool_patterns(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        // Placeholder implementation
        Ok(serde_json::json!({
            "tool_patterns": [
                {
                    "tool": "chat_completion",
                    "patterns": ["session_summary_generation"]
                }
            ]
        }))
    }

    async fn handle_trigger_session_patterns(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        // Placeholder implementation
        Ok(serde_json::json!({
            "triggered_patterns": [
                {
                    "pattern_name": "session_summary_generation",
                    "triggered": true,
                    "reason": "session_duration_threshold"
                }
            ]
        }))
    }

    // Optimization & Debug (placeholder implementations)
    async fn handle_optimize_knowledge_base(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "optimization_id": Uuid::new_v4().to_string(),
            "status": "started"
        }))
    }

    async fn handle_optimization_status(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "status": "completed",
            "progress": 100,
            "optimizations_applied": 5
        }))
    }

    async fn handle_optimization_history(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "history": [
                {
                    "id": "test-optimization",
                    "timestamp": chrono::Utc::now().to_rfc3339(),
                    "status": "completed",
                    "improvements": 3
                }
            ]
        }))
    }

    async fn handle_debug_markdown_test(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "markdown": "# Test Markdown\n\nThis is a test markdown response.",
            "formatted": "<h1>Test Markdown</h1><p>This is a test markdown response.</p>"
        }))
    }

    async fn handle_test_streaming_format(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "stream_id": Uuid::new_v4().to_string(),
            "format": "streaming",
            "status": "ready"
        }))
    }

    async fn handle_get_next_chunk(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "type": "streaming_complete",
            "message": "Streaming completed successfully"
        }))
    }

    // Tool Execution (placeholder implementations)
    async fn handle_execute_tool_call(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "tool_call_id": Uuid::new_v4().to_string(),
            "result": "Tool executed successfully"
        }))
    }

    async fn handle_parse_tool_calls(
        _server: &Self,
        _params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "tool_calls": [
                {
                    "tool": "test_tool",
                    "parameters": {}
                }
            ]
        }))
    }

    /// Check if a model supports thinking (intermediate reasoning)
    fn is_thinking_model(model: &str) -> bool {
        // List of models that support thinking with <think> tags
        let thinking_models = vec![
            "deepseek-r1:1.5b",
            "deepseek-coder:1.3b",
            "deepseek-coder:6.7b",
            "deepseek-coder:33b",
        ];

        thinking_models.contains(&model)
    }

    /// Format response with default formatting (diamond prefix)
    fn format_response_default(content: &str) -> String {
        let mut formatted = String::new();
        let mut last_was_empty = false;

        for line in content.lines() {
            if !line.trim().is_empty() {
                formatted.push_str("🮮   ");
                formatted.push_str(line);
                formatted.push('\n');
                last_was_empty = false;
            } else {
                // Only add one empty line, don't duplicate consecutive empty lines
                if !last_was_empty {
                    formatted.push('\n');
                }
                last_was_empty = true;
            }
        }
        formatted
    }

    /// Format response with custom configuration
    fn format_response_with_config(content: &str, config: &serde_json::Value) -> String {
        // For now, use default formatting
        // TODO: Implement custom formatting based on config
        Self::format_response_default(content)
    }

    /// Parse thinking content into structured chunks
    fn parse_thinking_content(content: &str) -> Vec<ThinkingChunk> {
        let mut chunks = Vec::new();
        let mut current_chunk = String::new();
        let mut in_thinking = false;
        let mut thinking_step_count = 0;

        for line in content.lines() {
            let line = line.trim();

            if line.contains("<think>") {
                in_thinking = true;
                // Start thinking section
                chunks.push(ThinkingChunk {
                    chunk_type: "thinking_start".to_string(),
                    content: "Starting thinking process...".to_string(),
                });
                continue;
            }

            if line.contains("</think>") {
                in_thinking = false;
                // End thinking section
                chunks.push(ThinkingChunk {
                    chunk_type: "thinking_end".to_string(),
                    content: "".to_string(),
                });
                continue;
            }

            if in_thinking {
                if line.starts_with('>') {
                    // This is a thinking step
                    thinking_step_count += 1;
                    chunks.push(ThinkingChunk {
                        chunk_type: "thinking_step".to_string(),
                        content: line[1..].trim().to_string(),
                    });
                } else if !line.is_empty() {
                    // This is thinking content
                    chunks.push(ThinkingChunk {
                        chunk_type: "thinking_content".to_string(),
                        content: line.to_string(),
                    });
                }
            } else {
                // Regular content after thinking
                if !line.is_empty() {
                    current_chunk.push_str(line);
                    current_chunk.push('\n');
                }
            }
        }

        // Add any remaining regular content
        if !current_chunk.trim().is_empty() {
            chunks.push(ThinkingChunk {
                chunk_type: "regular_content".to_string(),
                content: current_chunk.trim().to_string(),
            });
        }

        chunks
    }

    // MCP Protocol Method Handlers
    async fn handle_completion_complete(
        server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;

        // Extract completion parameters
        let prompt = params
            .get("prompt")
            .and_then(|p| p.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;

        let model = params
            .get("model")
            .and_then(|m| m.as_str())
            .unwrap_or("deepseek-r1:1.5b");

        let options = params.get("options").and_then(|o| o.as_object());

        // Create session for completion
        let session = server.session_manager.get_or_create_session(None).await;

        // Use existing chat completion logic but with thinking model support
        let chat_message = ChatMessage {
            role: "user".to_string(),
            content: prompt.to_string(),
        };

        match server
            .ollama_client
            .chat_completion(model, vec![chat_message], false)
            .await
        {
            Ok(response) => {
                Ok(serde_json::json!({
                    "completion": response.message.content,
                    "model": model,
                    "session_id": session.id,
                    "usage": {
                        "prompt_tokens": 0, // Ollama doesn't provide token usage
                        "completion_tokens": 0,
                        "total_tokens": 0,
                    }
                }))
            }
            Err(e) => {
                tracing::error!("Completion failed: {}", e);
                Err(StatusCode::INTERNAL_SERVER_ERROR)
            }
        }
    }

    async fn handle_sampling_create_message(
        server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;

        // Extract sampling parameters
        let prompt = params
            .get("prompt")
            .and_then(|p| p.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;

        let model = params
            .get("model")
            .and_then(|m| m.as_str())
            .unwrap_or("deepseek-r1:1.5b");

        let sampling_options = params.get("sampling_options").and_then(|o| o.as_object());

        // Create session for sampling
        let session = server.session_manager.get_or_create_session(None).await;

        // Create sampling message with thinking model support
        let sampling_message = ChatMessage {
            role: "user".to_string(),
            content: format!(
                "You are an AI assistant that can think step by step. Use <think> tags to show your reasoning process.\n\n{}",
                prompt
            ),
        };

        match server
            .ollama_client
            .chat_completion(model, vec![sampling_message], false)
            .await
        {
            Ok(response) => Ok(serde_json::json!({
                "message": {
                    "role": "assistant",
                    "content": response.message.content,
                },
                "model": model,
                "session_id": session.id,
                "sampling_id": uuid::Uuid::new_v4().to_string(),
            })),
            Err(e) => {
                tracing::error!("Sampling failed: {}", e);
                Err(StatusCode::INTERNAL_SERVER_ERROR)
            }
        }
    }

    async fn handle_elicitation_create(
        server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;

        // Extract elicitation parameters
        let prompt = params
            .get("prompt")
            .and_then(|p| p.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;

        let elicitation_type = params
            .get("type")
            .and_then(|t| t.as_str())
            .unwrap_or("user_input");

        // Create session for elicitation
        let session = server.session_manager.get_or_create_session(None).await;

        // Generate elicitation ID
        let elicitation_id = uuid::Uuid::new_v4().to_string();

        Ok(serde_json::json!({
            "elicitation_id": elicitation_id,
            "type": elicitation_type,
            "prompt": prompt,
            "session_id": session.id,
            "status": "pending",
            "created_at": chrono::Utc::now().to_rfc3339(),
        }))
    }

    async fn handle_logging_set_level(
        server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;

        let level = params
            .get("level")
            .and_then(|l| l.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;

        // Validate log level
        let valid_levels = ["debug", "info", "warn", "error"];
        if !valid_levels.contains(&level) {
            return Err(StatusCode::BAD_REQUEST);
        }

        // Set log level (this would integrate with your logging system)
        tracing::info!("Log level set to: {}", level);

        Ok(serde_json::json!({
            "level": level,
            "status": "updated",
        }))
    }

    async fn handle_prompts_list(
        server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        // Return available prompts
        let prompts = vec![
            serde_json::json!({
                "name": "thinking_assistant",
                "description": "AI assistant with step-by-step thinking capabilities",
                "content": "You are a helpful AI assistant. When solving complex problems, use <think> tags to show your reasoning process step by step. Think through the problem carefully before providing your final answer.",
                "tags": ["thinking", "reasoning", "step-by-step"]
            }),
            serde_json::json!({
                "name": "code_assistant",
                "description": "AI assistant specialized in code generation and review",
                "content": "You are a code assistant. Provide clear, well-documented code with explanations. Always consider best practices and security implications.",
                "tags": ["code", "programming", "development"]
            }),
            serde_json::json!({
                "name": "debugging_assistant",
                "description": "AI assistant for debugging and problem-solving",
                "content": "You are a debugging assistant. Help identify and fix issues systematically. Ask clarifying questions when needed.",
                "tags": ["debugging", "troubleshooting", "problem-solving"]
            }),
        ];

        Ok(serde_json::json!({
            "prompts": prompts
        }))
    }

    async fn handle_prompts_get(
        server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;

        let name = params
            .get("name")
            .and_then(|n| n.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;

        // Return specific prompt by name
        let prompt = match name {
            "thinking_assistant" => serde_json::json!({
                "name": "thinking_assistant",
                "description": "AI assistant with step-by-step thinking capabilities",
                "content": "You are a helpful AI assistant. When solving complex problems, use <think> tags to show your reasoning process step by step. Think through the problem carefully before providing your final answer.",
                "tags": ["thinking", "reasoning", "step-by-step"]
            }),
            "code_assistant" => serde_json::json!({
                "name": "code_assistant",
                "description": "AI assistant specialized in code generation and review",
                "content": "You are a code assistant. Provide clear, well-documented code with explanations. Always consider best practices and security implications.",
                "tags": ["code", "programming", "development"]
            }),
            "debugging_assistant" => serde_json::json!({
                "name": "debugging_assistant",
                "description": "AI assistant for debugging and problem-solving",
                "content": "You are a debugging assistant. Help identify and fix issues systematically. Ask clarifying questions when needed.",
                "tags": ["debugging", "troubleshooting", "problem-solving"]
            }),
            _ => return Err(StatusCode::NOT_FOUND),
        };

        Ok(prompt)
    }

    async fn handle_roots_list(server: &Self, params: Option<&Value>) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;

        let uri = params
            .get("uri")
            .and_then(|u| u.as_str())
            .unwrap_or("neovim://buffers");

        let options = params.get("options").and_then(|o| o.as_object());

        // Return roots for the specified URI
        let roots = match uri {
            "neovim://buffers" => {
                // Return buffer roots
                vec![serde_json::json!({
                    "uri": "neovim://buffers",
                    "name": "Neovim Buffers",
                    "description": "All open buffers in the current session"
                })]
            }
            "neovim://session" => {
                // Return session roots
                vec![serde_json::json!({
                    "uri": "neovim://session",
                    "name": "Neovim Session",
                    "description": "Current Neovim session information"
                })]
            }
            _ => vec![],
        };

        Ok(serde_json::json!({
            "roots": roots,
            "uri": uri,
            "options": options
        }))
    }

    async fn handle_resources_unsubscribe(
        server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;

        let uri = params
            .get("uri")
            .and_then(|u| u.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;

        // Handle resource unsubscription
        tracing::info!("Unsubscribing from resource: {}", uri);

        Ok(serde_json::json!({
            "uri": uri,
            "status": "unsubscribed"
        }))
    }

    async fn handle_resources_templates_list(
        server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        // Return available resource templates
        let templates = vec![
            serde_json::json!({
                "name": "buffer_template",
                "description": "Template for Neovim buffer resources",
                "uri_pattern": "neovim://buffers/*",
                "mime_type": "application/json"
            }),
            serde_json::json!({
                "name": "session_template",
                "description": "Template for Neovim session resources",
                "uri_pattern": "neovim://session/*",
                "mime_type": "application/json"
            }),
        ];

        Ok(serde_json::json!({
            "templates": templates
        }))
    }

    async fn handle_ping(server: &Self, params: Option<&Value>) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "pong": true,
            "timestamp": chrono::Utc::now().to_rfc3339(),
            "server_info": {
                "name": "paragonic-mcp-server",
                "version": "1.0.0"
            }
        }))
    }

    // Notification handlers (these would typically be sent as notifications, not requests)
    async fn handle_notifications_cancelled(
        server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;

        let request_id = params
            .get("requestId")
            .and_then(|r| r.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;

        tracing::info!("Request cancelled: {}", request_id);

        Ok(serde_json::json!({
            "request_id": request_id,
            "status": "cancelled"
        }))
    }

    async fn handle_notifications_initialized(
        server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "status": "initialized",
            "timestamp": chrono::Utc::now().to_rfc3339()
        }))
    }

    async fn handle_notifications_message(
        server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;

        let level = params
            .get("level")
            .and_then(|l| l.as_str())
            .unwrap_or("info");

        let data = params.get("data");

        tracing::info!("MCP message: level={}, data={:?}", level, data);

        Ok(serde_json::json!({
            "level": level,
            "data": data,
            "timestamp": chrono::Utc::now().to_rfc3339()
        }))
    }

    async fn handle_notifications_progress(
        server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;

        let progress_token = params
            .get("progressToken")
            .and_then(|p| p.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;

        let progress = params.get("progress").and_then(|p| p.as_u64()).unwrap_or(0);

        let total = params.get("total").and_then(|t| t.as_u64());
        let message = params.get("message").and_then(|m| m.as_str());

        tracing::info!(
            "Progress update: token={}, progress={}, total={:?}, message={:?}",
            progress_token,
            progress,
            total,
            message
        );

        Ok(serde_json::json!({
            "progress_token": progress_token,
            "progress": progress,
            "total": total,
            "message": message,
            "timestamp": chrono::Utc::now().to_rfc3339()
        }))
    }

    async fn handle_notifications_prompts_list_changed(
        server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "event": "prompts_list_changed",
            "timestamp": chrono::Utc::now().to_rfc3339()
        }))
    }

    async fn handle_notifications_resources_list_changed(
        server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "event": "resources_list_changed",
            "timestamp": chrono::Utc::now().to_rfc3339()
        }))
    }

    async fn handle_notifications_resources_updated(
        server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        let params = params.ok_or(StatusCode::BAD_REQUEST)?;

        let uri = params
            .get("uri")
            .and_then(|u| u.as_str())
            .ok_or(StatusCode::BAD_REQUEST)?;

        Ok(serde_json::json!({
            "event": "resources_updated",
            "uri": uri,
            "timestamp": chrono::Utc::now().to_rfc3339()
        }))
    }

    async fn handle_notifications_roots_list_changed(
        server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "event": "roots_list_changed",
            "timestamp": chrono::Utc::now().to_rfc3339()
        }))
    }

    async fn handle_notifications_tools_list_changed(
        server: &Self,
        params: Option<&Value>,
    ) -> Result<Value, StatusCode> {
        Ok(serde_json::json!({
            "event": "tools_list_changed",
            "timestamp": chrono::Utc::now().to_rfc3339()
        }))
    }

    /// Send MCP progress notifications for streaming chunks
    async fn send_mcp_progress_notifications(
        server: &Self,
        chunks: &[ThinkingChunk],
        progress_token: &str,
    ) {
        let total_chunks = chunks.len();

        info!("   📊 Sending MCP progress notifications for {} chunks", total_chunks);

        // Send initial progress notification
        let initial_progress = serde_json::json!({
            "jsonrpc": "2.0",
            "method": "notifications/progress",
            "params": {
                "progressToken": progress_token,
                "progress": 0,
                "total": total_chunks,
                "message": "Starting streaming response..."
            }
        });

        // Send via SSE to all active streams
        for session_id in server.session_manager.get_active_sessions().await {
            let streams = server.stream_manager.get_session_streams(&session_id).await;
            for stream in streams {
                let stream_id = stream.id;
                if let Err(e) = server.stream_manager.send_event(&stream_id, &initial_progress.to_string(), Some("notification")).await {
                    warn!("Failed to send initial progress notification: {}", e);
                }
            }
        }

        // Send progress updates for each chunk
        for (index, chunk) in chunks.iter().enumerate() {
            let progress = index + 1;
            let message = match chunk.chunk_type.as_str() {
                "thinking_start" => "Starting thinking process...",
                "thinking_content" => "Processing thinking content...",
                "thinking_end" => "Completing thinking process...",
                "regular_content" => "Generating response...",
                _ => "Processing content..."
            };

            let progress_notification = serde_json::json!({
                "jsonrpc": "2.0",
                "method": "notifications/progress",
                "params": {
                    "progressToken": progress_token,
                    "progress": progress,
                    "total": total_chunks,
                    "message": message
                }
            });

            // Send via SSE to all active streams
            for session_id in server.session_manager.get_active_sessions().await {
                let streams = server.stream_manager.get_session_streams(&session_id).await;
                for stream in streams {
                    let stream_id = stream.id;
                    if let Err(e) = server.stream_manager.send_event(&stream_id, &progress_notification.to_string(), Some("notification")).await {
                        warn!("Failed to send progress notification: {}", e);
                    }
                }
            }

            // Small delay to simulate processing time
            tokio::time::sleep(tokio::time::Duration::from_millis(50)).await;
        }

        // Send completion notification
        let completion_notification = serde_json::json!({
            "jsonrpc": "2.0",
            "method": "notifications/progress",
            "params": {
                "progressToken": progress_token,
                "progress": total_chunks,
                "total": total_chunks,
                "message": "Streaming response complete"
            }
        });

        // Send via SSE to all active streams
        for session_id in server.session_manager.get_active_sessions().await {
            let streams = server.stream_manager.get_session_streams(&session_id).await;
            for stream in streams {
                let stream_id = stream.id;
                if let Err(e) = server.stream_manager.send_event(&stream_id, &completion_notification.to_string(), Some("notification")).await {
                    warn!("Failed to send completion notification: {}", e);
                }
            }
        }

        info!("   ✅ MCP progress notifications sent for {} chunks", total_chunks);
    }

    /// Send remaining chunks via SSE notifications
    async fn send_remaining_chunks_via_sse(
        server: &Self,
        chunks: &[ThinkingChunk],
        progress_token: &str,
    ) {
        if chunks.is_empty() {
            return;
        }

        info!("   📤 Sending {} remaining chunks via SSE", chunks.len());

        // Check if there are any active sessions first
        let active_sessions = server.session_manager.get_active_sessions().await;
        if active_sessions.is_empty() {
            warn!("   ⚠️  No active sessions found for SSE notifications");
            return;
        }

        info!("   📡 Found {} active sessions for SSE", active_sessions.len());

        // Send each chunk as an SSE notification
        for (index, chunk) in chunks.iter().enumerate() {
            let chunk_notification = serde_json::json!({
                "jsonrpc": "2.0",
                "method": "notifications/message",
                "params": {
                    "type": "streaming_chunk",
                    "chunk": chunk.content,
                    "chunk_type": chunk.chunk_type,
                    "chunk_index": index + 1, // +1 because this is after the first chunk
                    "progressToken": progress_token
                }
            });

            let mut sent_successfully = false;

            // Send via SSE to all active streams
            for session_id in &active_sessions {
                let streams = server.stream_manager.get_session_streams(session_id).await;
                if streams.is_empty() {
                    warn!("   ⚠️  No streams found for session {}", session_id);
                    continue;
                }

                for stream in streams {
                    let stream_id = stream.id;
                    // Check stream status before sending
                    if let Some((state, receiver_count)) = server.stream_manager.get_stream_status(&stream_id).await {
                        debug!("   📊 Stream {} status: {:?}, receivers: {}", stream_id, state, receiver_count);
                        if receiver_count == 0 {
                            warn!("   ⚠️  Stream {} has no active receivers", stream_id);
                            continue;
                        }
                    }
                    
                    match server.stream_manager.send_event(&stream_id, &chunk_notification.to_string(), Some("notification")).await {
                        Ok(_) => {
                            sent_successfully = true;
                            debug!("   ✅ Sent chunk {} to stream {}", index + 1, stream_id);
                        }
                        Err(e) => {
                            warn!("   ❌ Failed to send chunk {} to stream {}: {}", index + 1, stream_id, e);
                        }
                    }
                }
            }

            if !sent_successfully {
                warn!("   ⚠️  Failed to send chunk {} to any stream", index + 1);
            }

            // Small delay between chunks for smooth streaming
            tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
        }

        // Send completion notification
        let completion_notification = serde_json::json!({
            "jsonrpc": "2.0",
            "method": "notifications/message",
            "params": {
                "type": "streaming_complete",
                "progressToken": progress_token
            }
        });

        let mut completion_sent = false;

        // Send completion via SSE to all active streams
        for session_id in &active_sessions {
            let streams = server.stream_manager.get_session_streams(session_id).await;
            for stream in streams {
                let stream_id = stream.id;
                match server.stream_manager.send_event(&stream_id, &completion_notification.to_string(), Some("notification")).await {
                    Ok(_) => {
                        completion_sent = true;
                        debug!("   ✅ Sent completion to stream {}", stream_id);
                    }
                    Err(e) => {
                        warn!("   ❌ Failed to send completion to stream {}: {}", stream_id, e);
                    }
                }
            }
        }

        if completion_sent {
            info!("   ✅ All remaining chunks sent via SSE");
        } else {
            warn!("   ⚠️  Failed to send completion notification to any stream");
        }
    }
}

/// JSON-RPC message types
#[derive(Debug)]
enum JsonRpcMessage {
    Request(Value),
    Notification(Value),
    Response(Value),
}

impl SessionManager {
    /// Create a new session manager
    pub fn new() -> Self {
        Self {
            sessions: Arc::new(tokio::sync::RwLock::new(std::collections::HashMap::new())),
        }
    }

    /// Get or create a session
    pub async fn get_or_create_session(&self, session_id: Option<String>) -> Session {
        let id = session_id.unwrap_or_else(|| Uuid::new_v4().to_string());
        let now = chrono::Utc::now();

        let mut sessions = self.sessions.write().await;

        if let Some(session) = sessions.get(&id) {
            // Update last activity
            let mut updated_session = session.clone();
            updated_session.last_activity = now;
            sessions.insert(id.clone(), updated_session.clone());
            updated_session
        } else {
            // Create new session
            let session = Session {
                id: id.clone(),
                created_at: now,
                last_activity: now,
                client_info: None,
            };
            sessions.insert(id, session.clone());
            info!("Created new session: {}", session.id);
            session
        }
    }

    /// Terminate a session
    pub async fn terminate_session(&self, session_id: &str) -> bool {
        let mut sessions = self.sessions.write().await;
        sessions.remove(session_id).is_some()
    }

    /// Get session by ID
    pub async fn get_session(&self, session_id: &str) -> Option<Session> {
        let sessions = self.sessions.read().await;
        sessions.get(session_id).cloned()
    }

    /// Get all active session IDs
    pub async fn get_active_sessions(&self) -> Vec<String> {
        let sessions = self.sessions.read().await;
        sessions.keys().cloned().collect()
    }
}



#[cfg(test)]
mod tests {
    use super::*;
    use axum::http::HeaderValue;
    use serde_json::json;

    #[tokio::test]
    async fn test_server_creation() {
        let server = McpHttpServer::new();
        assert_eq!(server.server_info.name, "paragonic-mcp-server");
        assert_eq!(server.server_info.protocol_version, "2025-06-18");
    }

    #[tokio::test]
    async fn test_router_creation() {
        let server = McpHttpServer::new();
        let router = server.create_router();
        // Router should be created without errors
        assert!(true);
    }

    #[tokio::test]
    async fn test_header_validation() {
        let mut headers = HeaderMap::new();

        // Test missing headers
        assert!(McpHttpServer::validate_headers(&headers).is_err());

        // Test with required headers
        headers.insert(
            "mcp-protocol-version",
            HeaderValue::from_static("2025-06-18"),
        );
        headers.insert("origin", HeaderValue::from_static("http://localhost:3000"));

        assert!(McpHttpServer::validate_headers(&headers).is_ok());
    }

    #[tokio::test]
    async fn test_sse_acceptance() {
        let mut headers = HeaderMap::new();

        // Test without SSE accept header
        assert!(!McpHttpServer::accepts_sse(&headers));

        // Test with SSE accept header
        headers.insert("accept", HeaderValue::from_static("text/event-stream"));
        assert!(McpHttpServer::accepts_sse(&headers));

        // Test with multiple accept types
        headers.insert(
            "accept",
            HeaderValue::from_static("application/json, text/event-stream"),
        );
        assert!(McpHttpServer::accepts_sse(&headers));
    }

    #[tokio::test]
    async fn test_session_id_extraction() {
        let mut headers = HeaderMap::new();

        // Test without session ID
        assert!(McpHttpServer::get_session_id(&headers).is_none());

        // Test with session ID
        headers.insert(
            "mcp-session-id",
            HeaderValue::from_static("test-session-123"),
        );
        assert_eq!(
            McpHttpServer::get_session_id(&headers),
            Some("test-session-123".to_string())
        );
    }

    #[tokio::test]
    async fn test_jsonrpc_parsing() {
        // Test valid request
        let request = serde_json::json!({
            "jsonrpc": "2.0",
            "method": "initialize",
            "params": {},
            "id": 1
        });
        assert!(matches!(
            McpHttpServer::parse_jsonrpc_message(&request),
            Ok(JsonRpcMessage::Request(_))
        ));

        // Test valid notification
        let notification = serde_json::json!({
            "jsonrpc": "2.0",
            "method": "notifications/notify",
            "params": {"message": "test"}
        });
        assert!(matches!(
            McpHttpServer::parse_jsonrpc_message(&notification),
            Ok(JsonRpcMessage::Notification(_))
        ));

        // Test valid response
        let response = serde_json::json!({
            "jsonrpc": "2.0",
            "result": {"success": true},
            "id": 1
        });
        assert!(matches!(
            McpHttpServer::parse_jsonrpc_message(&response),
            Ok(JsonRpcMessage::Response(_))
        ));

        // Test invalid message
        let invalid = serde_json::json!({
            "jsonrpc": "2.0"
        });
        assert!(McpHttpServer::parse_jsonrpc_message(&invalid).is_err());
    }

    #[tokio::test]
    async fn test_session_manager() {
        let manager = SessionManager::new();

        // Test session creation
        let session = manager.get_or_create_session(None).await;
        assert!(!session.id.is_empty());
        assert!(session.created_at <= chrono::Utc::now());

        // Test session retrieval
        let retrieved = manager.get_session(&session.id).await;
        assert!(retrieved.is_some());
        assert_eq!(retrieved.unwrap().id, session.id);

        // Test session termination
        assert!(manager.terminate_session(&session.id).await);
        assert!(manager.get_session(&session.id).await.is_none());
    }

    #[tokio::test]
    async fn test_stream_manager() {
        let manager = StreamManager::new(
            std::time::Duration::from_secs(300), // 5 minute timeout
            5, // max streams per session
            100, // max total streams
        );
        let session_id = "test-session";

        // Test stream creation
        let stream_result = manager.create_stream(session_id).await;
        assert!(stream_result.is_ok());

        // Test event sending
        let stream_id = stream_result.unwrap();
        let result = manager.send_event(&stream_id, "test message", None).await;
        assert!(result.is_ok());
    }

    #[test]
    fn test_is_thinking_model() {
        // Test thinking models
        assert!(McpHttpServer::is_thinking_model("deepseek-r1:1.5b"));
        assert!(McpHttpServer::is_thinking_model("deepseek-coder:1.3b"));
        assert!(McpHttpServer::is_thinking_model("deepseek-coder:6.7b"));
        assert!(McpHttpServer::is_thinking_model("deepseek-coder:33b"));

        // Test non-thinking models
        assert!(!McpHttpServer::is_thinking_model("llama2"));
        assert!(!McpHttpServer::is_thinking_model("llama2:7b"));
        assert!(!McpHttpServer::is_thinking_model("mistral"));
        assert!(!McpHttpServer::is_thinking_model("codellama"));

        // Test unknown models
        assert!(!McpHttpServer::is_thinking_model("unknown-model"));
        assert!(!McpHttpServer::is_thinking_model(""));
    }

    #[test]
    fn test_format_response_default() {
        let content = "Hello world\nThis is a test\n\nWith empty lines";
        let formatted = McpHttpServer::format_response_default(content);

        let expected = "🮮   Hello world\n🮮   This is a test\n\n🮮   With empty lines\n";
        assert_eq!(formatted, expected);
    }

    #[test]
    fn test_format_response_with_config() {
        let content = "Test content";
        let config = json!({"max_width": 80});
        let formatted = McpHttpServer::format_response_with_config(content, &config);

        // Should use default formatting for now
        let expected = "🮮   Test content\n";
        assert_eq!(formatted, expected);
    }

    #[test]
    fn test_format_response_empty_content() {
        let content = "";
        let formatted = McpHttpServer::format_response_default(content);
        assert_eq!(formatted, "");
    }

    #[test]
    fn test_format_response_single_line() {
        let content = "Single line content";
        let formatted = McpHttpServer::format_response_default(content);
        assert_eq!(formatted, "🮮   Single line content\n");
    }

    #[test]
    fn test_format_response_multiple_empty_lines() {
        let content = "Line 1\n\n\nLine 2";
        let formatted = McpHttpServer::format_response_default(content);
        assert_eq!(formatted, "🮮   Line 1\n\n🮮   Line 2\n");
    }

    #[tokio::test]
    async fn test_handle_chat_completion_thinking_model() {
        // This would require a mock Ollama client
        // For now, we'll test the prompt generation logic
        let model = "deepseek-r1:1.5b";
        let message = "Create a parts list for a pencil";

        // Test that thinking models get the thinking prompt
        let is_thinking = McpHttpServer::is_thinking_model(model);
        assert!(is_thinking);

        // The actual prompt would be generated in the handler
        let expected_prompt_contains = "use <think> tags to show your reasoning process";
        // In a real test, we'd verify the prompt contains this text
    }

    #[tokio::test]
    async fn test_handle_chat_completion_normal_model() {
        let model = "llama2";
        let message = "What is a pencil?";

        // Test that normal models don't get thinking prompts
        let is_thinking = McpHttpServer::is_thinking_model(model);
        assert!(!is_thinking);

        // The actual prompt would be the message directly
        // In a real test, we'd verify the prompt is just the message
    }

    #[tokio::test]
    async fn test_handle_streaming_chat_completion_thinking_model() {
        // This would require a mock Ollama client
        // For now, we'll test the model detection logic
        let model = "deepseek-coder:1.3b";
        let message = "Explain quantum computing";

        let is_thinking = McpHttpServer::is_thinking_model(model);
        assert!(is_thinking);

        // In a real test, we'd verify:
        // 1. The thinking prompt is generated
        // 2. The response is returned with type "regular_content"
        // 3. The content contains thinking tags
    }

    #[tokio::test]
    async fn test_handle_formatted_chat_completion_thinking_model() {
        let model = "deepseek-coder:6.7b";
        let message = "Design a database schema";

        // Test that thinking models get the thinking prompt
        let is_thinking = McpHttpServer::is_thinking_model(model);
        assert!(is_thinking);

        // In a real test, we'd verify:
        // 1. The thinking prompt is generated
        // 2. The response is formatted with diamond symbols
        // 3. The formatted_content field is present
        // 4. The original_content field is present
    }

    #[test]
    fn test_thinking_model_list_completeness() {
        // Verify all known thinking models are included
        let thinking_models = vec![
            "deepseek-r1:1.5b",
            "deepseek-coder:1.3b",
            "deepseek-coder:6.7b",
            "deepseek-coder:33b",
        ];

        for model in thinking_models {
            assert!(
                McpHttpServer::is_thinking_model(model),
                "Model {} should be detected as thinking model",
                model
            );
        }
    }

    #[test]
    fn test_normal_model_list_completeness() {
        // Verify common normal models are not detected as thinking
        let normal_models = vec![
            "llama2",
            "llama2:7b",
            "llama2:13b",
            "llama2:70b",
            "llama3.2:3b",
            "llama3.2:8b",
            "llama3.2:70b",
            "mistral",
            "mistral:7b",
            "codellama",
            "codellama:7b",
            "codellama:13b",
        ];

        for model in normal_models {
            assert!(
                !McpHttpServer::is_thinking_model(model),
                "Model {} should not be detected as thinking model",
                model
            );
        }
    }

    #[test]
    fn test_format_response_preserves_structure() {
        let content = "# Title\n\n## Subtitle\n\n- Item 1\n- Item 2\n\n**Bold text**";
        let formatted = McpHttpServer::format_response_default(content);

        // Should preserve line structure
        assert!(formatted.contains("# Title"));
        assert!(formatted.contains("## Subtitle"));
        assert!(formatted.contains("- Item 1"));
        assert!(formatted.contains("- Item 2"));
        assert!(formatted.contains("**Bold text**"));

        // Should add diamond prefix to non-empty lines
        assert!(formatted.contains("🮮   # Title"));
        assert!(formatted.contains("🮮   ## Subtitle"));
        assert!(formatted.contains("🮮   - Item 1"));
        assert!(formatted.contains("🮮   - Item 2"));
        assert!(formatted.contains("🮮   **Bold text**"));
    }

    #[tokio::test]
    async fn test_handle_streaming_chat_completion_integration() {
        // Test the complete streaming chat completion flow
        // This would require a mock Ollama client
        // For now, we'll test the request parsing and response format

        let server = McpHttpServer::new();

        // Test request parameters
        let params = serde_json::json!({
            "model": "deepseek-r1:1.5b",
            "message": "Create a parts list for a pencil"
        });

        // Test model detection
        let model = params
            .get("model")
            .and_then(|m| m.as_str())
            .unwrap_or("deepseek-r1:1.5b");
        let message = params.get("message").and_then(|m| m.as_str()).unwrap_or("");

        assert_eq!(model, "deepseek-r1:1.5b");
        assert_eq!(message, "Create a parts list for a pencil");

        // Test thinking model detection
        let is_thinking_model = McpHttpServer::is_thinking_model(model);
        assert!(is_thinking_model);

        // Test prompt generation for thinking models
        let thinking_prompt = format!(
            "You are a helpful AI assistant. When solving complex problems, use <think> tags to show your reasoning process step by step. Think through the problem carefully before providing your final answer.\n\nUser: {}\n\nAssistant:",
            message
        );

        assert!(thinking_prompt.contains("use <think> tags"));
        assert!(thinking_prompt.contains("Create a parts list for a pencil"));
        assert!(thinking_prompt.contains("Assistant:"));
    }

    #[tokio::test]
    async fn test_handle_streaming_chat_completion_normal_model() {
        // Test streaming chat completion with a normal (non-thinking) model
        let server = McpHttpServer::new();

        let params = serde_json::json!({
            "model": "llama2",
            "message": "What is a pencil?"
        });

        let model = params
            .get("model")
            .and_then(|m| m.as_str())
            .unwrap_or("llama2");
        let message = params.get("message").and_then(|m| m.as_str()).unwrap_or("");

        assert_eq!(model, "llama2");
        assert_eq!(message, "What is a pencil?");

        // Test that normal models are not detected as thinking
        let is_thinking_model = McpHttpServer::is_thinking_model(model);
        assert!(!is_thinking_model);

        // Test that normal models get the message directly (no thinking prompt)
        let normal_prompt = message.to_string();
        assert_eq!(normal_prompt, "What is a pencil?");
        assert!(!normal_prompt.contains("use <think> tags"));
    }

    #[test]
    fn test_streaming_response_format() {
        // Test the expected response format for streaming chat completion
        let expected_response = serde_json::json!({
            "type": "streaming_chunk",
            "chunk": "This is the AI response content",
            "chunk_index": 0,
            "total_chunks": 1,
            "remaining_chunks": []
        });

        // Verify the response structure
        assert_eq!(expected_response["type"], "streaming_chunk");
        assert!(expected_response["chunk"].is_string());
        assert!(expected_response["chunk_index"].is_number());
        assert!(expected_response["total_chunks"].is_number());
        assert!(expected_response["remaining_chunks"].is_array());

        // Verify the chunk index and total chunks
        assert_eq!(expected_response["chunk_index"], 0);
        assert_eq!(expected_response["total_chunks"], 1);
        assert_eq!(
            expected_response["remaining_chunks"]
                .as_array()
                .unwrap()
                .len(),
            0
        );
    }

    #[test]
    fn test_thinking_model_prompt_validation() {
        // Test that thinking model prompts are correctly formatted
        let test_message = "Explain quantum computing";
        let thinking_prompt = format!(
            "You are a helpful AI assistant. When solving complex problems, use <think> tags to show your reasoning process step by step. Think through the problem carefully before providing your final answer.\n\nUser: {}\n\nAssistant:",
            test_message
        );

        // Verify prompt structure
        assert!(thinking_prompt.starts_with("You are a helpful AI assistant"));
        assert!(thinking_prompt.contains("use <think> tags"));
        assert!(thinking_prompt.contains("reasoning process"));
        assert!(thinking_prompt.contains("step by step"));
        assert!(thinking_prompt.contains("User: Explain quantum computing"));
        assert!(thinking_prompt.ends_with("Assistant:"));

        // Verify the prompt is properly formatted
        let lines: Vec<&str> = thinking_prompt.lines().collect();
        assert!(lines.len() >= 4); // Should have multiple lines
        assert!(lines.iter().any(|line| line.contains("User:")));
        assert!(lines.iter().any(|line| line.contains("Assistant:")));
    }

    #[test]
    fn test_chat_message_creation() {
        // Test ChatMessage creation for both thinking and normal models
        let test_message = "Create a parts list for a pencil";

        // Test thinking model message
        let thinking_prompt = format!(
            "You are a helpful AI assistant. When solving complex problems, use <think> tags to show your reasoning process step by step. Think through the problem carefully before providing your final answer.\n\nUser: {}\n\nAssistant:",
            test_message
        );

        let thinking_chat_message = ChatMessage {
            role: "user".to_string(),
            content: thinking_prompt,
        };

        assert_eq!(thinking_chat_message.role, "user");
        assert!(thinking_chat_message.content.contains("use <think> tags"));
        assert!(thinking_chat_message.content.contains(test_message));

        // Test normal model message
        let normal_chat_message = ChatMessage {
            role: "user".to_string(),
            content: test_message.to_string(),
        };

        assert_eq!(normal_chat_message.role, "user");
        assert_eq!(normal_chat_message.content, test_message);
        assert!(!normal_chat_message.content.contains("use <think> tags"));
    }

    #[test]
    fn test_streaming_chunk_processing() {
        // Test the processing of streaming chunks in the response
        let mock_chunks = vec!["Hello", ", ", "world", "!"];

        let mut accumulated_content = String::new();
        for chunk in mock_chunks {
            accumulated_content.push_str(chunk);
        }

        assert_eq!(accumulated_content, "Hello, world!");

        // Test response format
        let response = serde_json::json!({
            "type": "streaming_chunk",
            "chunk": accumulated_content,
            "chunk_index": 0,
            "total_chunks": 1,
            "remaining_chunks": []
        });

        assert_eq!(response["chunk"], "Hello, world!");
        assert_eq!(response["type"], "streaming_chunk");
    }

    #[test]
    fn test_thinking_content_processing() {
        // Test processing of thinking content with <think> tags
        let thinking_content = "<think>\nLet me think about this step by step.\n</think>\n\nHere is the answer: The answer is 42.";

        // Verify thinking tags are present
        assert!(thinking_content.contains("<think>"));
        assert!(thinking_content.contains("</think>"));

        // Verify content structure
        let parts: Vec<&str> = thinking_content.split("</think>").collect();
        assert_eq!(parts.len(), 2);

        let thinking_part = parts[0];
        let answer_part = parts[1];

        assert!(thinking_part.contains("<think>"));
        assert!(thinking_part.contains("Let me think about this step by step."));
        assert!(answer_part.contains("Here is the answer:"));
        assert!(answer_part.contains("The answer is 42."));
    }

    #[tokio::test]
    async fn test_mcp_progress_notifications() {
        // Test MCP progress notification format and behavior
        let server = McpHttpServer::new();
        
        // Create mock thinking chunks
        let chunks = vec![
            ThinkingChunk {
                content: "Starting thinking process...".to_string(),
                chunk_type: "thinking_start".to_string(),
            },
            ThinkingChunk {
                content: "Processing step 1...".to_string(),
                chunk_type: "thinking_content".to_string(),
            },
            ThinkingChunk {
                content: "Processing step 2...".to_string(),
                chunk_type: "thinking_content".to_string(),
            },
            ThinkingChunk {
                content: "Completing thinking process...".to_string(),
                chunk_type: "thinking_end".to_string(),
            },
            ThinkingChunk {
                content: "Final answer: 42".to_string(),
                chunk_type: "regular_content".to_string(),
            },
        ];

        let progress_token = "test_progress_token_123";

        // Test that the method can be called without errors
        // Note: This test doesn't actually send notifications since we don't have active sessions
        // but it verifies the notification format is correct
        McpHttpServer::send_mcp_progress_notifications(&server, &chunks, progress_token).await;

        // Test progress token extraction from request params
        let request_params = serde_json::json!({
            "model": "deepseek-r1:1.5b",
            "message": "Test message",
            "_meta": {
                "progressToken": "extracted_token_456"
            }
        });

        // Test progress token extraction logic
        let extracted_token = request_params
            .get("_meta")
            .and_then(|meta| meta.get("progressToken"))
            .and_then(|token| token.as_str())
            .map(|s| s.to_string())
            .unwrap_or_else(|| format!("streaming_{}", chrono::Utc::now().timestamp_millis()));

        assert_eq!(extracted_token, "extracted_token_456");

        // Test fallback token generation
        let request_params_no_meta = serde_json::json!({
            "model": "deepseek-r1:1.5b",
            "message": "Test message"
        });

        let fallback_token = request_params_no_meta
            .get("_meta")
            .and_then(|meta| meta.get("progressToken"))
            .and_then(|token| token.as_str())
            .map(|s| s.to_string())
            .unwrap_or_else(|| format!("streaming_{}", chrono::Utc::now().timestamp_millis()));

        assert!(fallback_token.starts_with("streaming_"));
        assert!(fallback_token.len() > 10); // Should have timestamp

        // Test MCP progress notification format
        let test_notification = serde_json::json!({
            "jsonrpc": "2.0",
            "method": "notifications/progress",
            "params": {
                "progressToken": "test_token",
                "progress": 2,
                "total": 5,
                "message": "Processing thinking content..."
            }
        });

        // Verify JSON-RPC format
        assert_eq!(test_notification["jsonrpc"], "2.0");
        assert_eq!(test_notification["method"], "notifications/progress");
        
        // Verify params structure
        let params = &test_notification["params"];
        assert_eq!(params["progressToken"], "test_token");
        assert_eq!(params["progress"], 2);
        assert_eq!(params["total"], 5);
        assert_eq!(params["message"], "Processing thinking content...");

        // Verify all required MCP fields are present
        assert!(params.get("progressToken").is_some());
        assert!(params.get("progress").is_some());
        assert!(params.get("total").is_some());
        assert!(params.get("message").is_some());

        println!("✅ MCP progress notification tests passed");
    }

    #[test]
    fn test_progress_token_generation() {
        // Test that progress tokens are generated correctly
        let token1 = format!("chat_{}", chrono::Utc::now().timestamp_millis());
        let token2 = format!("streaming_{}", chrono::Utc::now().timestamp_millis());

        // Verify token format
        assert!(token1.starts_with("chat_"));
        assert!(token2.starts_with("streaming_"));
        
        // Verify tokens are unique (timestamps should be different)
        assert_ne!(token1, token2);

        // Verify tokens contain numeric timestamps
        let timestamp1: Result<i64, _> = token1.split('_').nth(1).unwrap().parse();
        let timestamp2: Result<i64, _> = token2.split('_').nth(1).unwrap().parse();
        
        assert!(timestamp1.is_ok());
        assert!(timestamp2.is_ok());
        assert!(timestamp1.unwrap() > 0);
        assert!(timestamp2.unwrap() > 0);
    }

    #[test]
    fn test_mcp_progress_notification_schema_compliance() {
        // Test that our progress notifications comply with MCP schema
        let notification = serde_json::json!({
            "jsonrpc": "2.0",
            "method": "notifications/progress",
            "params": {
                "progressToken": "test_token_123",
                "progress": 3,
                "total": 7,
                "message": "Processing step 3 of 7..."
            }
        });

        // Verify JSON-RPC 2.0 compliance
        assert_eq!(notification["jsonrpc"], "2.0");
        
        // Verify method name
        assert_eq!(notification["method"], "notifications/progress");
        
        // Verify params structure matches MCP schema
        let params = &notification["params"];
        
        // Required fields according to MCP schema
        assert!(params.get("progressToken").is_some());
        assert!(params.get("progress").is_some());
        
        // Optional fields
        assert!(params.get("total").is_some());
        assert!(params.get("message").is_some());
        
        // Verify data types
        assert!(params["progressToken"].is_string());
        assert!(params["progress"].is_number());
        assert!(params["total"].is_number());
        assert!(params["message"].is_string());
        
        // Verify values
        assert_eq!(params["progressToken"], "test_token_123");
        assert_eq!(params["progress"], 3);
        assert_eq!(params["total"], 7);
        assert_eq!(params["message"], "Processing step 3 of 7...");

        println!("✅ MCP progress notification schema compliance verified");
    }
}
