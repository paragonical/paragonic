//! Session management for MCP HTTP transport
//!
//! This module provides session management functionality for the MCP
//! Streamable HTTP transport, including session creation, validation,
//! and cleanup.

use std::{
    collections::HashMap,
    sync::Arc,
    time::{Duration, Instant},
};
use tokio::sync::RwLock;
use tracing::{debug, info, warn};
use uuid::Uuid;

/// Session information for MCP HTTP transport
#[derive(Debug, Clone)]
pub struct Session {
    /// Unique session identifier
    pub id: String,
    /// Session creation timestamp
    pub created_at: Instant,
    /// Last activity timestamp
    pub last_activity: Instant,
    /// Client information
    pub client_info: Option<ClientInfo>,
    /// Session state
    pub state: SessionState,
}

/// Client information for MCP sessions
#[derive(Debug, Clone)]
pub struct ClientInfo {
    /// Client name
    pub name: String,
    /// Client version
    pub version: String,
    /// Client capabilities
    pub capabilities: serde_json::Value,
}

/// Session state enumeration
#[derive(Debug, Clone, PartialEq, Copy)]
pub enum SessionState {
    /// Session is being initialized
    Initializing,
    /// Session is active and ready
    Active,
    /// Session is being shut down
    ShuttingDown,
    /// Session has been closed
    Closed,
}

/// Session manager for MCP HTTP transport
#[derive(Debug)]
pub struct SessionManager {
    /// Active sessions
    sessions: Arc<RwLock<HashMap<String, Session>>>,
    /// Session timeout duration
    timeout: Duration,
    /// Maximum number of concurrent sessions
    max_sessions: usize,
}

impl SessionManager {
    /// Create a new session manager
    pub fn new(timeout: Duration, max_sessions: usize) -> Self {
        Self {
            sessions: Arc::new(RwLock::new(HashMap::new())),
            timeout,
            max_sessions,
        }
    }

    /// Create a new session
    pub async fn create_session(
        &self,
        client_info: Option<ClientInfo>,
    ) -> Result<String, SessionError> {
        let mut sessions = self.sessions.write().await;

        // Check if we've reached the maximum number of sessions
        if sessions.len() >= self.max_sessions {
            return Err(SessionError::MaxSessionsReached);
        }

        // Generate a unique session ID
        let session_id = self.generate_session_id();

        // Create the session
        let session = Session {
            id: session_id.clone(),
            created_at: Instant::now(),
            last_activity: Instant::now(),
            client_info,
            state: SessionState::Initializing,
        };

        sessions.insert(session_id.clone(), session);

        info!("Created new MCP session: {}", session_id);
        Ok(session_id)
    }

    /// Get session by ID
    pub async fn get_session(&self, session_id: &str) -> Option<Session> {
        let sessions = self.sessions.read().await;
        sessions.get(session_id).cloned()
    }

    /// Update session activity
    pub async fn update_activity(&self, session_id: &str) -> Result<(), SessionError> {
        let mut sessions = self.sessions.write().await;

        if let Some(session) = sessions.get_mut(session_id) {
            session.last_activity = Instant::now();
            Ok(())
        } else {
            Err(SessionError::SessionNotFound)
        }
    }

    /// Update session state
    pub async fn update_state(
        &self,
        session_id: &str,
        state: SessionState,
    ) -> Result<(), SessionError> {
        let mut sessions = self.sessions.write().await;

        if let Some(session) = sessions.get_mut(session_id) {
            session.state = state.clone();
            session.last_activity = Instant::now();
            debug!("Updated session {} state to {:?}", session_id, state);
            Ok(())
        } else {
            Err(SessionError::SessionNotFound)
        }
    }

    /// Close a session
    pub async fn close_session(&self, session_id: &str) -> Result<(), SessionError> {
        let mut sessions = self.sessions.write().await;

        if sessions.remove(session_id).is_some() {
            info!("Closed MCP session: {}", session_id);
            Ok(())
        } else {
            Err(SessionError::SessionNotFound)
        }
    }

    /// Clean up expired sessions
    pub async fn cleanup_expired(&self) -> usize {
        let mut sessions = self.sessions.write().await;
        let now = Instant::now();
        let initial_count = sessions.len();

        sessions.retain(|_, session| {
            let is_expired = now.duration_since(session.last_activity) > self.timeout;
            if is_expired {
                warn!("Removing expired session: {}", session.id);
            }
            !is_expired
        });

        let removed_count = initial_count - sessions.len();
        if removed_count > 0 {
            info!("Cleaned up {} expired sessions", removed_count);
        }

        removed_count
    }

    /// Get session count
    pub async fn session_count(&self) -> usize {
        self.sessions.read().await.len()
    }

    /// Generate a unique session ID
    fn generate_session_id(&self) -> String {
        Uuid::new_v4().to_string()
    }

    /// Validate session ID format
    pub fn validate_session_id(session_id: &str) -> bool {
        // Session ID should be a valid UUID
        Uuid::parse_str(session_id).is_ok()
    }
}

/// Session-related errors
#[derive(Debug, thiserror::Error)]
pub enum SessionError {
    #[error("Session not found")]
    SessionNotFound,
    #[error("Maximum number of sessions reached")]
    MaxSessionsReached,
    #[error("Invalid session ID")]
    InvalidSessionId,
    #[error("Session is in invalid state: {0:?}")]
    InvalidState(SessionState),
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::Duration;

    #[tokio::test]
    async fn test_create_session() {
        let manager = SessionManager::new(Duration::from_secs(300), 10);

        let session_id = manager.create_session(None).await.unwrap();
        assert!(!session_id.is_empty());
        assert!(SessionManager::validate_session_id(&session_id));

        let session = manager.get_session(&session_id).await.unwrap();
        assert_eq!(session.id, session_id);
        assert_eq!(session.state, SessionState::Initializing);
        assert_eq!(manager.session_count().await, 1);
    }

    #[tokio::test]
    async fn test_create_session_with_client_info() {
        let manager = SessionManager::new(Duration::from_secs(300), 10);

        let client_info = ClientInfo {
            name: "test-client".to_string(),
            version: "1.0.0".to_string(),
            capabilities: serde_json::json!({}),
        };

        let session_id = manager
            .create_session(Some(client_info.clone()))
            .await
            .unwrap();
        let session = manager.get_session(&session_id).await.unwrap();

        assert_eq!(session.client_info.as_ref().unwrap().name, "test-client");
        assert_eq!(session.client_info.as_ref().unwrap().version, "1.0.0");
    }

    #[tokio::test]
    async fn test_update_activity() {
        let manager = SessionManager::new(Duration::from_secs(300), 10);
        let session_id = manager.create_session(None).await.unwrap();

        // Get initial activity time
        let initial_session = manager.get_session(&session_id).await.unwrap();
        let initial_activity = initial_session.last_activity;

        // Wait a bit and update activity
        tokio::time::sleep(Duration::from_millis(10)).await;
        manager.update_activity(&session_id).await.unwrap();

        // Check that activity was updated
        let updated_session = manager.get_session(&session_id).await.unwrap();
        assert!(updated_session.last_activity > initial_activity);
    }

    #[tokio::test]
    async fn test_update_state() {
        let manager = SessionManager::new(Duration::from_secs(300), 10);
        let session_id = manager.create_session(None).await.unwrap();

        // Update state to Active
        manager
            .update_state(&session_id, SessionState::Active)
            .await
            .unwrap();
        let session = manager.get_session(&session_id).await.unwrap();
        assert_eq!(session.state, SessionState::Active);

        // Update state to ShuttingDown
        manager
            .update_state(&session_id, SessionState::ShuttingDown)
            .await
            .unwrap();
        let session = manager.get_session(&session_id).await.unwrap();
        assert_eq!(session.state, SessionState::ShuttingDown);
    }

    #[tokio::test]
    async fn test_close_session() {
        let manager = SessionManager::new(Duration::from_secs(300), 10);
        let session_id = manager.create_session(None).await.unwrap();

        assert_eq!(manager.session_count().await, 1);

        manager.close_session(&session_id).await.unwrap();

        assert_eq!(manager.session_count().await, 0);
        assert!(manager.get_session(&session_id).await.is_none());
    }

    #[tokio::test]
    async fn test_cleanup_expired() {
        let manager = SessionManager::new(Duration::from_millis(50), 10);

        // Create a session
        let session_id = manager.create_session(None).await.unwrap();
        assert_eq!(manager.session_count().await, 1);

        // Wait for session to expire
        tokio::time::sleep(Duration::from_millis(100)).await;

        // Clean up expired sessions
        let removed_count = manager.cleanup_expired().await;
        assert_eq!(removed_count, 1);
        assert_eq!(manager.session_count().await, 0);
    }

    #[tokio::test]
    async fn test_max_sessions_reached() {
        let manager = SessionManager::new(Duration::from_secs(300), 2);

        // Create two sessions (max allowed)
        let session1 = manager.create_session(None).await.unwrap();
        let session2 = manager.create_session(None).await.unwrap();

        // Try to create a third session
        let result = manager.create_session(None).await;
        assert!(matches!(result, Err(SessionError::MaxSessionsReached)));

        // Clean up
        manager.close_session(&session1).await.unwrap();
        manager.close_session(&session2).await.unwrap();
    }

    #[tokio::test]
    async fn test_session_not_found_errors() {
        let manager = SessionManager::new(Duration::from_secs(300), 10);

        // Try to update activity for non-existent session
        let result = manager.update_activity("non-existent").await;
        assert!(matches!(result, Err(SessionError::SessionNotFound)));

        // Try to update state for non-existent session
        let result = manager
            .update_state("non-existent", SessionState::Active)
            .await;
        assert!(matches!(result, Err(SessionError::SessionNotFound)));

        // Try to close non-existent session
        let result = manager.close_session("non-existent").await;
        assert!(matches!(result, Err(SessionError::SessionNotFound)));
    }

    #[test]
    fn test_validate_session_id() {
        // Valid UUID
        assert!(SessionManager::validate_session_id(
            "550e8400-e29b-41d4-a716-446655440000"
        ));

        // Invalid UUIDs
        assert!(!SessionManager::validate_session_id("invalid-uuid"));
        assert!(!SessionManager::validate_session_id(""));
        assert!(!SessionManager::validate_session_id("not-a-uuid"));
    }
}
