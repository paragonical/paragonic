//! Stream management for MCP HTTP Server-Sent Events (SSE)
//!
//! This module provides SSE stream management functionality for the MCP
//! Streamable HTTP transport, including stream creation, event management,
//! and lifecycle handling.

use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
    time::{Duration, Instant},
};
use tokio::sync::{broadcast, RwLock};
use tokio_stream::Stream;
use tracing::{debug, error, info, warn};
use uuid::Uuid;
use tokio::task::JoinHandle;

/// SSE stream information
#[derive(Debug, Clone)]
pub struct SseStream {
    /// Unique stream identifier
    pub id: String,
    /// Associated session ID
    pub session_id: String,
    /// Stream creation timestamp
    pub created_at: Instant,
    /// Last activity timestamp
    pub last_activity: Instant,
    /// Current event ID counter
    pub event_id: u64,
    /// Stream state
    pub state: StreamState,
    /// Broadcast sender for this stream
    pub sender: Arc<broadcast::Sender<SseEvent>>,
    /// Heartbeat task handle
    pub heartbeat_task: Arc<Mutex<Option<JoinHandle<()>>>>,
}

/// SSE event data
#[derive(Debug, Clone)]
pub struct SseEvent {
    /// Event ID for stream resumption
    pub id: String,
    /// Event type (optional)
    pub event_type: Option<String>,
    /// Event data (JSON-RPC message)
    pub data: String,
    /// Timestamp when event was created
    pub timestamp: Instant,
}

/// Stream state enumeration
#[derive(Debug, Clone, PartialEq, Copy)]
pub enum StreamState {
    /// Stream is being initialized
    Initializing,
    /// Stream is active and sending events
    Active,
    /// Stream is paused (for resumption)
    Paused,
    /// Stream is being closed
    Closing,
    /// Stream has been closed
    Closed,
}

/// Stream manager for MCP HTTP SSE transport
#[derive(Debug)]
pub struct StreamManager {
    /// Active streams
    streams: Arc<RwLock<HashMap<String, SseStream>>>,
    /// Stream timeout duration
    timeout: Duration,
    /// Maximum number of concurrent streams per session
    max_streams_per_session: usize,
    /// Maximum number of total streams
    max_total_streams: usize,
    /// Cleanup task handle
    cleanup_task: Arc<Mutex<Option<JoinHandle<()>>>>,
}

impl StreamManager {
    /// Create a new stream manager
    pub fn new(
        timeout: Duration,
        max_streams_per_session: usize,
        max_total_streams: usize,
    ) -> Self {
        let manager = Self {
            streams: Arc::new(RwLock::new(HashMap::new())),
            timeout,
            max_streams_per_session,
            max_total_streams,
            cleanup_task: Arc::new(Mutex::new(None)),
        };
        
        // Start the periodic cleanup task
        manager.start_cleanup_task();
        
        manager
    }

    /// Create a new SSE stream for a session
    pub async fn create_stream(&self, session_id: &str) -> Result<String, StreamError> {
        let mut streams = self.streams.write().await;

        // Check if we've reached the maximum number of total streams
        if streams.len() >= self.max_total_streams {
            return Err(StreamError::MaxStreamsReached);
        }

        // Check if the session has reached its stream limit
        let session_stream_count = streams
            .values()
            .filter(|stream| stream.session_id == session_id)
            .count();

        if session_stream_count >= self.max_streams_per_session {
            return Err(StreamError::MaxStreamsPerSessionReached);
        }

        // Generate a unique stream ID
        let stream_id = self.generate_stream_id();

        // Create broadcast channel for this stream
        let (sender, _) = broadcast::channel(100); // Buffer size of 100 events

        // Create the stream
        let stream = SseStream {
            id: stream_id.clone(),
            session_id: session_id.to_string(),
            created_at: Instant::now(),
            last_activity: Instant::now(),
            event_id: 0,
            state: StreamState::Initializing,
            sender: Arc::new(sender),
            heartbeat_task: Arc::new(Mutex::new(None)),
        };

        streams.insert(stream_id.clone(), stream);

        info!(
            "Created new SSE stream: {} for session: {}",
            stream_id, session_id
        );
        Ok(stream_id)
    }

    /// Create an Axum-compatible SSE stream for a session
    pub async fn create_axum_sse_stream(&self, session_id: &str) -> Result<impl Stream<Item = Result<axum::response::sse::Event, axum::Error>>, StreamError> {
        use axum::response::sse::Event;
        use tokio_stream::wrappers::BroadcastStream;
        use tokio_stream::StreamExt;

        // Create the stream first
        let stream_id = self.create_stream(session_id).await?;
        
        // Start heartbeat for this stream
        self.start_heartbeat(&stream_id).await?;
        
        // Get the stream to access its sender
        let stream = self.get_stream(&stream_id).await.ok_or(StreamError::StreamNotFound)?;
        
        // Create a receiver from the sender
        let receiver = stream.sender.subscribe();
        
        // Create the Axum SSE stream
        let sse_stream = BroadcastStream::new(receiver)
            .map(|result| {
                result
                    .map(|event| {
                        Event::default()
                            .id(event.id)
                            .event(event.event_type.unwrap_or_else(|| "message".to_string()))
                            .data(event.data)
                    })
                    .map_err(|e| axum::Error::new(e))
            });

        Ok(sse_stream)
    }

    /// Start heartbeat for a stream
    pub async fn start_heartbeat(&self, stream_id: &str) -> Result<(), StreamError> {
        let mut streams = self.streams.write().await;
        
        if let Some(stream) = streams.get_mut(stream_id) {
            // Don't start heartbeat if already running
            let mut heartbeat_guard = stream.heartbeat_task.lock().unwrap();
            if heartbeat_guard.is_some() {
                return Ok(());
            }
            
            let sender = stream.sender.clone();
            let stream_id_clone = stream_id.to_string();
            
            // Spawn heartbeat task with exponential backoff
            let heartbeat_task = tokio::spawn(async move {
                Self::heartbeat_loop(sender, stream_id_clone).await;
            });
            
            *heartbeat_guard = Some(heartbeat_task);
            debug!("Started heartbeat for stream: {}", stream_id);
            Ok(())
        } else {
            Err(StreamError::StreamNotFound)
        }
    }

    /// Heartbeat loop with exponential backoff
    async fn heartbeat_loop(sender: Arc<broadcast::Sender<SseEvent>>, stream_id: String) {
        let mut delay = Duration::from_secs(1); // Start with 1 second
        let max_delay = Duration::from_secs(128); // Max 128 seconds
        
        loop {
            // Wait for the current delay
            tokio::time::sleep(delay).await;
            
            // Create heartbeat event using MCP notifications/message format
            let heartbeat_event = SseEvent {
                id: format!("heartbeat_{}", chrono::Utc::now().timestamp_millis()),
                event_type: Some("notification".to_string()),
                data: serde_json::json!({
                    "jsonrpc": "2.0",
                    "method": "notifications/message",
                    "params": {
                        "type": "heartbeat",
                        "timestamp": chrono::Utc::now().to_rfc3339(),
                        "stream_id": stream_id,
                        "message": "SSE connection heartbeat"
                    }
                }).to_string(),
                timestamp: Instant::now(),
            };
            
            // Send heartbeat
            match sender.send(heartbeat_event) {
                Ok(_) => {
                    debug!("Sent heartbeat for stream: {}", stream_id);
                    // Exponential backoff: double the delay, but cap at max_delay
                    delay = std::cmp::min(delay * 2, max_delay);
                }
                Err(_) => {
                    // No receivers, stop heartbeat
                    debug!("No receivers for heartbeat, stopping for stream: {}", stream_id);
                    break;
                }
            }
        }
    }

    /// Stop heartbeat for a stream
    pub async fn stop_heartbeat(&self, stream_id: &str) -> Result<(), StreamError> {
        let mut streams = self.streams.write().await;
        
        if let Some(stream) = streams.get_mut(stream_id) {
            let mut heartbeat_guard = stream.heartbeat_task.lock().unwrap();
            if let Some(task) = heartbeat_guard.take() {
                task.abort();
                debug!("Stopped heartbeat for stream: {}", stream_id);
            }
            Ok(())
        } else {
            Err(StreamError::StreamNotFound)
        }
    }

    /// Get stream by ID
    pub async fn get_stream(&self, stream_id: &str) -> Option<SseStream> {
        let streams = self.streams.read().await;
        streams.get(stream_id).cloned()
    }

    /// Get all streams for a session
    pub async fn get_session_streams(&self, session_id: &str) -> Vec<SseStream> {
        let streams = self.streams.read().await;
        streams
            .values()
            .filter(|stream| stream.session_id == session_id)
            .cloned()
            .collect()
    }

    /// Get stream status information
    pub async fn get_stream_status(&self, stream_id: &str) -> Option<(StreamState, usize)> {
        let streams = self.streams.read().await;
        streams.get(stream_id).map(|stream| (stream.state, stream.sender.receiver_count()))
    }

    /// Send an event to a stream
    pub async fn send_event(
        &self,
        stream_id: &str,
        event_data: &str,
        event_type: Option<&str>,
    ) -> Result<(), StreamError> {
        let mut streams = self.streams.write().await;

        if let Some(stream) = streams.get_mut(stream_id) {
            // Check if stream is in a valid state for sending events
            if stream.state != StreamState::Active && stream.state != StreamState::Initializing {
                return Err(StreamError::StreamNotActive);
            }

            // Increment event ID
            stream.event_id += 1;
            stream.last_activity = Instant::now();

            // Create the event
            let event = SseEvent {
                id: stream.event_id.to_string(),
                event_type: event_type.map(|s| s.to_string()),
                data: event_data.to_string(),
                timestamp: Instant::now(),
            };

            // Send the event
            if let Err(e) = stream.sender.send(event) {
                warn!("Failed to send event to stream {}: {} (receiver count: {})", stream_id, e, stream.sender.receiver_count());
                return Err(StreamError::SendFailed);
            }

            // Update stream state to Active if it was Initializing
            if stream.state == StreamState::Initializing {
                stream.state = StreamState::Active;
            }

            debug!("Sent event {} to stream {}", stream.event_id, stream_id);
            Ok(())
        } else {
            Err(StreamError::StreamNotFound)
        }
    }

    /// Update stream state
    pub async fn update_stream_state(
        &self,
        stream_id: &str,
        state: StreamState,
    ) -> Result<(), StreamError> {
        let mut streams = self.streams.write().await;

        if let Some(stream) = streams.get_mut(stream_id) {
            stream.state = state;
            stream.last_activity = Instant::now();
            debug!("Updated stream {} state to {:?}", stream_id, state);
            Ok(())
        } else {
            Err(StreamError::StreamNotFound)
        }
    }

    /// Pause a stream (for resumption)
    pub async fn pause_stream(&self, stream_id: &str) -> Result<(), StreamError> {
        self.update_stream_state(stream_id, StreamState::Paused)
            .await
    }

    /// Resume a stream
    pub async fn resume_stream(&self, stream_id: &str) -> Result<(), StreamError> {
        self.update_stream_state(stream_id, StreamState::Active)
            .await
    }

    /// Close a stream
    pub async fn close_stream(&self, stream_id: &str) -> Result<(), StreamError> {
        let mut streams = self.streams.write().await;

        if let Some(stream) = streams.get_mut(stream_id) {
            stream.state = StreamState::Closing;
            stream.last_activity = Instant::now();
            
            // Stop heartbeat
            let mut heartbeat_guard = stream.heartbeat_task.lock().unwrap();
            if let Some(task) = heartbeat_guard.take() {
                task.abort();
                debug!("Stopped heartbeat for stream: {}", stream_id);
            }
        }

        // Remove the stream
        if streams.remove(stream_id).is_some() {
            info!("Closed SSE stream: {}", stream_id);
            Ok(())
        } else {
            Err(StreamError::StreamNotFound)
        }
    }

    /// Close all streams for a session
    pub async fn close_session_streams(&self, session_id: &str) -> usize {
        let mut streams = self.streams.write().await;
        let initial_count = streams.len();

        streams.retain(|_, stream| {
            if stream.session_id == session_id {
                info!("Closing stream {} for session {}", stream.id, session_id);
                false
            } else {
                true
            }
        });

        let closed_count = initial_count - streams.len();
        if closed_count > 0 {
            info!("Closed {} streams for session {}", closed_count, session_id);
        }

        closed_count
    }

    /// Clean up expired streams
    pub async fn cleanup_expired(&self) -> usize {
        let mut streams = self.streams.write().await;
        let now = Instant::now();
        let initial_count = streams.len();

        streams.retain(|_, stream| {
            let is_expired = now.duration_since(stream.last_activity) > self.timeout;
            if is_expired {
                warn!("Removing expired stream: {}", stream.id);
            }
            !is_expired
        });

        let removed_count = initial_count - streams.len();
        if removed_count > 0 {
            info!("Cleaned up {} expired streams", removed_count);
        }

        removed_count
    }

    /// Get stream count
    pub async fn stream_count(&self) -> usize {
        self.streams.read().await.len()
    }

    /// Get stream count for a session
    pub async fn session_stream_count(&self, session_id: &str) -> usize {
        let streams = self.streams.read().await;
        streams
            .values()
            .filter(|stream| stream.session_id == session_id)
            .count()
    }

    /// Generate a unique stream ID
    fn generate_stream_id(&self) -> String {
        Uuid::new_v4().to_string()
    }

    /// Validate stream ID format
    pub fn validate_stream_id(stream_id: &str) -> bool {
        Uuid::parse_str(stream_id).is_ok()
    }

    /// Start the periodic cleanup task
    fn start_cleanup_task(&self) {
        let streams = Arc::clone(&self.streams);
        let timeout = self.timeout;
        
        let cleanup_task = tokio::spawn(async move {
            let mut interval = tokio::time::interval(Duration::from_secs(60)); // Run every minute
            
            loop {
                interval.tick().await;
                
                let mut streams_guard = streams.write().await;
                let now = Instant::now();
                let initial_count = streams_guard.len();

                // Collect expired streams first
                let expired_streams: Vec<String> = streams_guard
                    .iter()
                    .filter(|(_, stream)| now.duration_since(stream.last_activity) > timeout)
                    .map(|(stream_id, _)| stream_id.clone())
                    .collect();

                // Send expiration notifications
                for stream_id in &expired_streams {
                    if let Some(stream) = streams_guard.get(stream_id) {
                        // Try to send expiration notification
                        let _ = stream.sender.send(SseEvent {
                            id: format!("expiration_{}", chrono::Utc::now().timestamp_millis()),
                            event_type: Some("notification".to_string()),
                            data: serde_json::json!({
                                "jsonrpc": "2.0",
                                "method": "notifications/message",
                                "params": {
                                    "type": "stream_expired",
                                    "stream_id": stream_id,
                                    "message": "Stream expired due to inactivity. Please request a new stream.",
                                    "timestamp": chrono::Utc::now().to_rfc3339(),
                                    "reconnect_required": true
                                }
                            }).to_string(),
                            timestamp: Instant::now(),
                        });
                        warn!("Sent expiration notification for stream: {} (inactive for {:?})", stream_id, timeout);
                    }
                }

                // Remove expired streams
                streams_guard.retain(|stream_id, _| {
                    let is_expired = expired_streams.contains(stream_id);
                    if is_expired {
                        warn!("Auto-removing expired stream: {} (inactive for {:?})", stream_id, timeout);
                    }
                    !is_expired
                });

                let removed_count = initial_count - streams_guard.len();
                if removed_count > 0 {
                    info!("Auto-cleanup: removed {} expired streams", removed_count);
                }
            }
        });
        
        // Store the task handle
        if let Ok(mut guard) = self.cleanup_task.lock() {
            *guard = Some(cleanup_task);
        }
    }

    /// Stop the cleanup task
    pub async fn stop_cleanup_task(&self) {
        if let Ok(mut guard) = self.cleanup_task.lock() {
            if let Some(task) = guard.take() {
                task.abort();
                info!("Stopped stream cleanup task");
            }
        }
    }

    /// Send stream expiration notification to client
    pub async fn send_stream_expiration_notification(&self, stream_id: &str) -> Result<(), StreamError> {
        let expiration_event = SseEvent {
            id: format!("expiration_{}", chrono::Utc::now().timestamp_millis()),
            event_type: Some("notification".to_string()),
            data: serde_json::json!({
                "jsonrpc": "2.0",
                "method": "notifications/message",
                "params": {
                    "type": "stream_expired",
                    "stream_id": stream_id,
                    "message": "Stream expired due to inactivity. Please request a new stream.",
                    "timestamp": chrono::Utc::now().to_rfc3339(),
                    "reconnect_required": true
                }
            }).to_string(),
            timestamp: Instant::now(),
        };

        self.send_event(stream_id, &expiration_event.data, expiration_event.event_type.as_deref()).await
    }
}

/// Stream-related errors
#[derive(Debug, thiserror::Error)]
pub enum StreamError {
    #[error("Stream not found")]
    StreamNotFound,
    #[error("Maximum number of streams reached")]
    MaxStreamsReached,
    #[error("Maximum number of streams per session reached")]
    MaxStreamsPerSessionReached,
    #[error("Stream is not active")]
    StreamNotActive,
    #[error("Failed to send event")]
    SendFailed,
    #[error("Invalid stream ID")]
    InvalidStreamId,
    #[error("Stream is in invalid state: {0:?}")]
    InvalidState(StreamState),
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::Duration;

    #[tokio::test]
    async fn test_create_stream() {
        let manager = StreamManager::new(Duration::from_secs(300), 5, 10);

        let stream_id = manager.create_stream("test-session").await.unwrap();
        assert!(!stream_id.is_empty());
        assert!(StreamManager::validate_stream_id(&stream_id));

        let stream = manager.get_stream(&stream_id).await.unwrap();
        assert_eq!(stream.id, stream_id);
        assert_eq!(stream.session_id, "test-session");
        assert_eq!(stream.state, StreamState::Initializing);
        assert_eq!(manager.stream_count().await, 1);
    }

    #[tokio::test]
    async fn test_send_event() {
        let manager = StreamManager::new(Duration::from_secs(300), 5, 10);
        let stream_id = manager.create_stream("test-session").await.unwrap();

        // Get the stream to access its sender
        let stream = manager.get_stream(&stream_id).await.unwrap();
        let mut receiver = stream.sender.subscribe();

        // Send an event
        let event_data = r#"{"jsonrpc": "2.0", "method": "test", "params": {}}"#;
        manager
            .send_event(&stream_id, event_data, None)
            .await
            .unwrap();

        // Verify the event was sent
        let received_event = receiver.recv().await.unwrap();
        assert_eq!(received_event.id, "1");
        assert_eq!(received_event.data, event_data);
        assert!(received_event.event_type.is_none());

        let stream = manager.get_stream(&stream_id).await.unwrap();
        assert_eq!(stream.event_id, 1);
        assert_eq!(stream.state, StreamState::Active);
    }

    #[tokio::test]
    async fn test_send_event_with_type() {
        let manager = StreamManager::new(Duration::from_secs(300), 5, 10);
        let stream_id = manager.create_stream("test-session").await.unwrap();

        // Get the stream to access its sender
        let stream = manager.get_stream(&stream_id).await.unwrap();
        let mut receiver = stream.sender.subscribe();

        // Send an event with type
        let event_data = r#"{"jsonrpc": "2.0", "method": "test", "params": {}}"#;
        manager
            .send_event(&stream_id, event_data, Some("notification"))
            .await
            .unwrap();

        // Verify the event was sent
        let received_event = receiver.recv().await.unwrap();
        assert_eq!(received_event.id, "1");
        assert_eq!(received_event.data, event_data);
        assert_eq!(received_event.event_type.as_deref(), Some("notification"));

        let stream = manager.get_stream(&stream_id).await.unwrap();
        assert_eq!(stream.event_id, 1);
    }

    #[tokio::test]
    async fn test_update_stream_state() {
        let manager = StreamManager::new(Duration::from_secs(300), 5, 10);
        let stream_id = manager.create_stream("test-session").await.unwrap();

        // Update state to Paused
        manager
            .update_stream_state(&stream_id, StreamState::Paused)
            .await
            .unwrap();
        let stream = manager.get_stream(&stream_id).await.unwrap();
        assert_eq!(stream.state, StreamState::Paused);

        // Resume stream
        manager.resume_stream(&stream_id).await.unwrap();
        let stream = manager.get_stream(&stream_id).await.unwrap();
        assert_eq!(stream.state, StreamState::Active);
    }

    #[tokio::test]
    async fn test_close_stream() {
        let manager = StreamManager::new(Duration::from_secs(300), 5, 10);
        let stream_id = manager.create_stream("test-session").await.unwrap();

        assert_eq!(manager.stream_count().await, 1);

        manager.close_stream(&stream_id).await.unwrap();

        assert_eq!(manager.stream_count().await, 0);
        assert!(manager.get_stream(&stream_id).await.is_none());
    }

    #[tokio::test]
    async fn test_close_session_streams() {
        let manager = StreamManager::new(Duration::from_secs(300), 5, 10);

        // Create multiple streams for the same session
        let stream1 = manager.create_stream("test-session").await.unwrap();
        let stream2 = manager.create_stream("test-session").await.unwrap();
        let stream3 = manager.create_stream("other-session").await.unwrap();

        assert_eq!(manager.stream_count().await, 3);

        // Close all streams for test-session
        let closed_count = manager.close_session_streams("test-session").await;
        assert_eq!(closed_count, 2);
        assert_eq!(manager.stream_count().await, 1);

        // Verify other session's stream is still there
        assert!(manager.get_stream(&stream3).await.is_some());
    }

    #[tokio::test]
    async fn test_cleanup_expired() {
        let manager = StreamManager::new(Duration::from_millis(50), 5, 10);

        // Create a stream
        let stream_id = manager.create_stream("test-session").await.unwrap();
        assert_eq!(manager.stream_count().await, 1);

        // Wait for stream to expire
        tokio::time::sleep(Duration::from_millis(100)).await;

        // Clean up expired streams
        let removed_count = manager.cleanup_expired().await;
        assert_eq!(removed_count, 1);
        assert_eq!(manager.stream_count().await, 0);
    }

    #[tokio::test]
    async fn test_max_streams_reached() {
        let manager = StreamManager::new(Duration::from_secs(300), 5, 2);

        // Create two streams (max allowed)
        let stream1 = manager.create_stream("test-session").await.unwrap();
        let stream2 = manager.create_stream("test-session").await.unwrap();

        // Try to create a third stream
        let result = manager.create_stream("test-session").await;
        assert!(matches!(result, Err(StreamError::MaxStreamsReached)));

        // Clean up
        manager.close_stream(&stream1).await.unwrap();
        manager.close_stream(&stream2).await.unwrap();
    }

    #[tokio::test]
    async fn test_max_streams_per_session_reached() {
        let manager = StreamManager::new(Duration::from_secs(300), 2, 10);

        // Create two streams for the same session (max allowed)
        let stream1 = manager.create_stream("test-session").await.unwrap();
        let stream2 = manager.create_stream("test-session").await.unwrap();

        // Try to create a third stream for the same session
        let result = manager.create_stream("test-session").await;
        assert!(matches!(
            result,
            Err(StreamError::MaxStreamsPerSessionReached)
        ));

        // But we can create a stream for a different session
        let stream3 = manager.create_stream("other-session").await.unwrap();
        assert_eq!(manager.stream_count().await, 3);

        // Clean up
        manager.close_stream(&stream1).await.unwrap();
        manager.close_stream(&stream2).await.unwrap();
        manager.close_stream(&stream3).await.unwrap();
    }

    #[tokio::test]
    async fn test_send_event_to_inactive_stream() {
        let manager = StreamManager::new(Duration::from_secs(300), 5, 10);
        let stream_id = manager.create_stream("test-session").await.unwrap();

        // Pause the stream
        manager.pause_stream(&stream_id).await.unwrap();

        // Try to send an event to paused stream
        let event_data = r#"{"jsonrpc": "2.0", "method": "test", "params": {}}"#;
        let result = manager.send_event(&stream_id, event_data, None).await;
        assert!(matches!(result, Err(StreamError::StreamNotActive)));
    }

    #[tokio::test]
    async fn test_stream_not_found_errors() {
        let manager = StreamManager::new(Duration::from_secs(300), 5, 10);

        // Try to send event to non-existent stream
        let result = manager.send_event("non-existent", "data", None).await;
        assert!(matches!(result, Err(StreamError::StreamNotFound)));

        // Try to update state for non-existent stream
        let result = manager
            .update_stream_state("non-existent", StreamState::Active)
            .await;
        assert!(matches!(result, Err(StreamError::StreamNotFound)));

        // Try to close non-existent stream
        let result = manager.close_stream("non-existent").await;
        assert!(matches!(result, Err(StreamError::StreamNotFound)));
    }

    #[tokio::test]
    async fn test_get_session_streams() {
        let manager = StreamManager::new(Duration::from_secs(300), 5, 10);

        // Create streams for different sessions
        let stream1 = manager.create_stream("session1").await.unwrap();
        let stream2 = manager.create_stream("session1").await.unwrap();
        let stream3 = manager.create_stream("session2").await.unwrap();

        // Get streams for session1
        let session1_streams = manager.get_session_streams("session1").await;
        assert_eq!(session1_streams.len(), 2);
        assert!(session1_streams.iter().all(|s| s.session_id == "session1"));

        // Get streams for session2
        let session2_streams = manager.get_session_streams("session2").await;
        assert_eq!(session2_streams.len(), 1);
        assert!(session2_streams.iter().all(|s| s.session_id == "session2"));

        // Clean up
        manager.close_stream(&stream1).await.unwrap();
        manager.close_stream(&stream2).await.unwrap();
        manager.close_stream(&stream3).await.unwrap();
    }

    #[test]
    fn test_validate_stream_id() {
        // Valid UUID
        assert!(StreamManager::validate_stream_id(
            "550e8400-e29b-41d4-a716-446655440000"
        ));

        // Invalid UUIDs
        assert!(!StreamManager::validate_stream_id("invalid-uuid"));
        assert!(!StreamManager::validate_stream_id(""));
        assert!(!StreamManager::validate_stream_id("not-a-uuid"));
    }
}
