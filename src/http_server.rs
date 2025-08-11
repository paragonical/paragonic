//! HTTP server for MCP Streamable HTTP transport
//! 
//! This module provides an HTTP server that implements the MCP 2025-06-18
//! Streamable HTTP transport specification.

use axum::{
    extract::{Json, State},
    http::{HeaderMap, StatusCode},
    response::{sse::Event, Sse},
    routing::{get, post, delete},
    Router,
};
use serde_json::Value;
use std::sync::Arc;
use tokio_stream::{wrappers::BroadcastStream, Stream, StreamExt};
use tower_http::cors::{Any, CorsLayer};
use tracing::{debug, error, info, warn};
use uuid::Uuid;

/// MCP HTTP server state
#[derive(Clone)]
pub struct McpHttpServer {
    /// Server information
    pub server_info: ServerInfo,
    /// Session manager
    pub session_manager: Arc<SessionManager>,
    /// Stream manager
    pub stream_manager: Arc<StreamManager>,
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

/// Stream manager for SSE streams
#[derive(Clone)]
pub struct StreamManager {
    streams: Arc<tokio::sync::RwLock<std::collections::HashMap<String, tokio::sync::broadcast::Sender<Value>>>>,
}

impl McpHttpServer {
    /// Create a new MCP HTTP server
    pub fn new() -> Self {
        Self {
            server_info: ServerInfo {
                name: "paragonic-mcp-server".to_string(),
                version: env!("CARGO_PKG_VERSION").to_string(),
                protocol_version: "2025-06-18".to_string(),
            },
            session_manager: Arc::new(SessionManager::new()),
            stream_manager: Arc::new(StreamManager::new()),
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
            JsonRpcMessage::Request(request) => {
                Self::handle_jsonrpc_request(server, request).await
            }
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
        let session = server.session_manager.get_or_create_session(session_id).await;

        // Create SSE stream
        let stream = server.stream_manager.create_stream(&session.id).await;
        
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
        // For now, return a simple response
        // TODO: Implement proper MCP request handling
        let response = serde_json::json!({
            "jsonrpc": "2.0",
            "result": {
                "protocolVersion": server.server_info.protocol_version,
                "capabilities": {},
                "serverInfo": {
                    "name": server.server_info.name,
                    "version": server.server_info.version
                }
            },
            "id": request.get("id").unwrap_or(&Value::Null)
        });

        Ok(axum::response::Response::builder()
            .status(StatusCode::OK)
            .header("content-type", "application/json")
            .body(axum::body::Body::from(serde_json::to_string(&response).unwrap()))
            .unwrap())
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
}

impl StreamManager {
    /// Create a new stream manager
    pub fn new() -> Self {
        Self {
            streams: Arc::new(tokio::sync::RwLock::new(std::collections::HashMap::new())),
        }
    }

    /// Create a new SSE stream for a session
    pub async fn create_stream(&self, session_id: &str) -> impl Stream<Item = Result<Event, axum::Error>> {
        let (tx, rx) = tokio::sync::broadcast::channel(100);
        
        {
            let mut streams = self.streams.write().await;
            streams.insert(session_id.to_string(), tx);
        }

        let stream = BroadcastStream::new(rx);
        stream.map(|result| {
            result
                .map(|value| {
                    Event::default()
                        .id(Uuid::new_v4().to_string())
                        .data(serde_json::to_string(&value).unwrap())
                })
                .map_err(|e| axum::Error::new(e))
        })
    }

    /// Send a message to a session's stream
    pub async fn send_message(&self, session_id: &str, message: Value) -> bool {
        let streams = self.streams.read().await;
        if let Some(tx) = streams.get(session_id) {
            tx.send(message).is_ok()
        } else {
            false
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::http::HeaderValue;

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
        headers.insert("mcp-protocol-version", HeaderValue::from_static("2025-06-18"));
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
        headers.insert("accept", HeaderValue::from_static("application/json, text/event-stream"));
        assert!(McpHttpServer::accepts_sse(&headers));
    }

    #[tokio::test]
    async fn test_session_id_extraction() {
        let mut headers = HeaderMap::new();
        
        // Test without session ID
        assert!(McpHttpServer::get_session_id(&headers).is_none());
        
        // Test with session ID
        headers.insert("mcp-session-id", HeaderValue::from_static("test-session-123"));
        assert_eq!(McpHttpServer::get_session_id(&headers), Some("test-session-123".to_string()));
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
        let manager = StreamManager::new();
        let session_id = "test-session";
        
        // Test stream creation
        let _stream = manager.create_stream(session_id).await;
        
        // Test message sending
        let message = serde_json::json!({"test": "message"});
        assert!(manager.send_message(session_id, message).await);
    }
}
