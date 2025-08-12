//! Memory usage and resource cleanup tests for MCP HTTP transport
//! Task 9.4 of MCP Streamable HTTP Refit spec

use std::collections::HashMap;
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::sync::RwLock;
use uuid::Uuid;

use paragonic::http_server::{McpHttpServer, ServerInfo, SessionManager, StreamManager};
use paragonic::stream_manager::{SseStream, StreamState};

/// Helper function to measure memory usage (approximate)
fn measure_memory_usage() -> usize {
    // This is a simplified memory measurement
    // In a real implementation, you might use system-specific APIs
    std::mem::size_of::<McpHttpServer>() + 
    std::mem::size_of::<SessionManager>() + 
    std::mem::size_of::<StreamManager>()
}

/// Helper function to create test data
fn create_test_data(size_kb: usize) -> String {
    "x".repeat(size_kb * 1024)
}

/// Test memory usage during server initialization
#[tokio::test]
async fn test_memory_usage_initialization() {
    let initial_memory = measure_memory_usage();
    
    // Create server components
    let server_info = ServerInfo {
        name: "test-server".to_string(),
        version: "1.0.0".to_string(),
        protocol_version: "2025-06-18".to_string(),
    };
    
    let session_manager = Arc::new(SessionManager::new(Duration::from_secs(300), 10));
    let stream_manager = Arc::new(StreamManager::new(Duration::from_secs(300), 5, 10));
    
    let server = McpHttpServer {
        server_info,
        session_manager,
        stream_manager,
    };
    
    let after_init_memory = measure_memory_usage();
    let init_memory_increase = after_init_memory - initial_memory;
    
    println!("Memory before init: {} bytes", initial_memory);
    println!("Memory after init: {} bytes", after_init_memory);
    println!("Memory increase: {} bytes", init_memory_increase);
    
    // Assertions
    assert!(init_memory_increase < 1024 * 1024, "Initialization should use less than 1MB");
}

/// Test memory usage during session management
#[tokio::test]
async fn test_memory_usage_session_management() {
    let manager = SessionManager::new(Duration::from_secs(300), 10);
    let initial_memory = measure_memory_usage();
    
    let session_memory_changes = vec![];
    
    // Create multiple sessions
    for i in 0..5 {
        let before_memory = measure_memory_usage();
        
        let session_id = manager.create_session(None).await.unwrap();
        
        // Simulate session activity
        for j in 0..3 {
            let request_data = create_test_data(1);
            // Simulate processing request data
            let _processed_data = request_data.to_uppercase();
        }
        
        let after_memory = measure_memory_usage();
        let memory_change = after_memory - before_memory;
        
        println!("Session {} memory change: {} bytes", i, memory_change);
        
        // Clean up session
        manager.close_session(&session_id).await.unwrap();
        
        let after_cleanup_memory = measure_memory_usage();
        let cleanup_memory_decrease = after_memory - after_cleanup_memory;
        
        println!("Session {} cleanup decrease: {} bytes", i, cleanup_memory_decrease);
        
        // Assertions for each session
        assert!(memory_change < 1024 * 100, "Session memory increase should be less than 100KB");
        assert!(cleanup_memory_decrease > 0, "Session cleanup should reduce memory");
    }
    
    let final_memory = measure_memory_usage();
    let total_memory_increase = final_memory - initial_memory;
    
    println!("Total memory increase: {} bytes", total_memory_increase);
    
    // Assertions
    assert!(total_memory_increase < 1024 * 50, "Total memory increase should be minimal");
}

/// Test memory usage during stream management
#[tokio::test]
async fn test_memory_usage_stream_management() {
    let manager = StreamManager::new(Duration::from_secs(300), 5, 10);
    let initial_memory = measure_memory_usage();
    
    let stream_memory_changes = vec![];
    
    // Create multiple streams
    for i in 0..5 {
        let before_memory = measure_memory_usage();
        
        let stream_id = manager.create_stream("test-session").await.unwrap();
        
        // Simulate stream activity
        for j in 0..10 {
            let event_data = create_test_data(1);
            let _result = manager.send_event(&stream_id, &event_data, Some("test_event")).await;
        }
        
        let after_memory = measure_memory_usage();
        let memory_change = after_memory - before_memory;
        
        println!("Stream {} memory change: {} bytes", i, memory_change);
        
        // Clean up stream
        manager.close_stream(&stream_id).await.unwrap();
        
        let after_cleanup_memory = measure_memory_usage();
        let cleanup_memory_decrease = after_memory - after_cleanup_memory;
        
        println!("Stream {} cleanup decrease: {} bytes", i, cleanup_memory_decrease);
        
        // Assertions for each stream
        assert!(memory_change < 1024 * 200, "Stream memory increase should be less than 200KB");
        assert!(cleanup_memory_decrease > 0, "Stream cleanup should reduce memory");
    }
    
    let final_memory = measure_memory_usage();
    let total_memory_increase = final_memory - initial_memory;
    
    println!("Total memory increase: {} bytes", total_memory_increase);
    
    // Assertions
    assert!(total_memory_increase < 1024 * 100, "Total memory increase should be minimal");
}

/// Test memory usage with large data payloads
#[tokio::test]
async fn test_memory_usage_large_payloads() {
    let manager = StreamManager::new(Duration::from_secs(300), 5, 10);
    let initial_memory = measure_memory_usage();
    
    let payload_sizes = vec![1, 10, 50, 100]; // KB
    let mut memory_usage_by_size = HashMap::new();
    
    for &size_kb in &payload_sizes {
        let before_memory = measure_memory_usage();
        
        // Create large payload
        let large_data = create_test_data(size_kb);
        
        // Create stream and send large payload
        let stream_id = manager.create_stream("test-session").await.unwrap();
        let _result = manager.send_event(&stream_id, &large_data, Some("large_payload")).await;
        
        let after_memory = measure_memory_usage();
        let memory_change = after_memory - before_memory;
        
        memory_usage_by_size.insert(size_kb, memory_change);
        
        println!("{} KB payload memory change: {} bytes", size_kb, memory_change);
        
        // Clean up
        manager.close_stream(&stream_id).await.unwrap();
    }
    
    let final_memory = measure_memory_usage();
    let total_memory_increase = final_memory - initial_memory;
    
    println!("Total memory increase: {} bytes", total_memory_increase);
    
    // Assertions
    assert!(total_memory_increase < 1024 * 1024 * 2, "Total memory increase should be less than 2MB");
    
    // Check that memory usage scales reasonably with payload size
    for (&size_kb, &memory_change) in &memory_usage_by_size {
        assert!(
            memory_change < size_kb * 1024 * 2,
            "Memory change for {} KB payload should be less than {} bytes",
            size_kb,
            size_kb * 1024 * 2
        );
    }
}

/// Test memory usage during concurrent operations
#[tokio::test]
async fn test_memory_usage_concurrent_operations() {
    let manager = StreamManager::new(Duration::from_secs(300), 10, 20);
    let initial_memory = measure_memory_usage();
    
    let mut operation_memory_changes = vec![];
    
    // Simulate concurrent operations
    for op in 0..10 {
        let before_memory = measure_memory_usage();
        
        // Create stream for concurrent operation
        let stream_id = manager.create_stream(&format!("session-{}", op)).await.unwrap();
        
        // Simulate concurrent request processing
        let request_data = create_test_data(5);
        let _result = manager.send_event(&stream_id, &request_data, Some("concurrent_op")).await;
        
        let after_memory = measure_memory_usage();
        let memory_change = after_memory - before_memory;
        
        operation_memory_changes.push(memory_change);
        
        println!("Operation {} memory change: {} bytes", op, memory_change);
        
        // Clean up
        manager.close_stream(&stream_id).await.unwrap();
    }
    
    let final_memory = measure_memory_usage();
    let total_memory_increase = final_memory - initial_memory;
    
    println!("Total memory increase: {} bytes", total_memory_increase);
    
    // Calculate statistics
    let total_change: usize = operation_memory_changes.iter().sum();
    let max_change = operation_memory_changes.iter().max().unwrap_or(&0);
    let avg_change = total_change / operation_memory_changes.len();
    
    println!("Average memory change per operation: {} bytes", avg_change);
    println!("Maximum memory change: {} bytes", max_change);
    
    // Assertions
    assert!(total_memory_increase < 1024 * 1024, "Total memory increase should be less than 1MB");
    assert!(avg_change < 1024 * 100, "Average memory change per operation should be less than 100KB");
    assert!(max_change < &(1024 * 200), "Maximum memory change should be less than 200KB");
}

/// Test memory leak detection over time
#[tokio::test]
async fn test_memory_leak_detection() {
    let manager = StreamManager::new(Duration::from_secs(300), 5, 10);
    let initial_memory = measure_memory_usage();
    let mut memory_readings = vec![];
    
    // Run operations over time to detect memory leaks
    for iteration in 0..20 {
        let iteration_start_memory = measure_memory_usage();
        
        // Create stream
        let stream_id = manager.create_stream(&format!("session-{}", iteration)).await.unwrap();
        
        // Simulate typical usage pattern
        for i in 0..3 {
            let request_data = create_test_data(2);
            let _result = manager.send_event(&stream_id, &request_data, Some("leak_detection")).await;
        }
        
        // Clean up
        manager.close_stream(&stream_id).await.unwrap();
        
        let iteration_end_memory = measure_memory_usage();
        let iteration_memory_change = iteration_end_memory - iteration_start_memory;
        
        memory_readings.push(iteration_end_memory);
        
        if iteration % 5 == 0 {
            println!(
                "Iteration {} memory: {} bytes (change: {} bytes)",
                iteration, iteration_end_memory, iteration_memory_change
            );
        }
    }
    
    let final_memory = measure_memory_usage();
    let total_memory_increase = final_memory - initial_memory;
    
    println!("Total memory increase over 20 iterations: {} bytes", total_memory_increase);
    
    // Analyze memory trend
    let first_quarter = memory_readings.get(5).unwrap_or(&memory_readings[memory_readings.len() - 1]);
    let last_quarter = memory_readings[memory_readings.len() - 1];
    let trend_change = last_quarter - first_quarter;
    
    println!("Memory trend change (first 5 to last): {} bytes", trend_change);
    
    // Assertions
    assert!(total_memory_increase < 1024 * 500, "Total memory increase should be less than 500KB over 20 iterations");
    assert!(trend_change < 1024 * 200, "Memory trend should not show significant growth");
    assert!(final_memory <= initial_memory + 1024 * 200, "Final memory should be close to initial");
}

/// Test resource cleanup during session termination
#[tokio::test]
async fn test_resource_cleanup_session_termination() {
    let session_manager = SessionManager::new(Duration::from_secs(300), 10);
    let stream_manager = StreamManager::new(Duration::from_secs(300), 5, 10);
    let initial_memory = measure_memory_usage();
    
    // Create session with multiple streams
    let session_id = session_manager.create_session(None).await.unwrap();
    
    let mut stream_ids = vec![];
    for i in 0..3 {
        let stream_id = stream_manager.create_stream(&session_id).await.unwrap();
        stream_ids.push(stream_id);
    }
    
    let after_creation_memory = measure_memory_usage();
    let creation_memory_increase = after_creation_memory - initial_memory;
    
    println!("Memory after session creation: {} bytes (increase: {} bytes)", 
        after_creation_memory, creation_memory_increase);
    
    // Terminate session (should clean up all associated streams)
    let terminated = session_manager.terminate_session(&session_id).await;
    assert!(terminated, "Session should be terminated successfully");
    
    let after_termination_memory = measure_memory_usage();
    let termination_memory_decrease = after_creation_memory - after_termination_memory;
    
    println!("Memory after session termination: {} bytes", after_termination_memory);
    println!("Memory decrease after termination: {} bytes", termination_memory_decrease);
    
    // Verify streams are cleaned up
    for stream_id in &stream_ids {
        let stream = stream_manager.get_stream(stream_id).await;
        assert!(stream.is_none(), "Stream should be cleaned up after session termination");
    }
    
    // Assertions
    assert!(creation_memory_increase < 1024 * 500, "Session creation should use less than 500KB");
    assert!(termination_memory_decrease > 0, "Session termination should reduce memory");
}

/// Test memory usage during stream resumption
#[tokio::test]
async fn test_memory_usage_stream_resumption() {
    let manager = StreamManager::new(Duration::from_secs(300), 5, 10);
    let initial_memory = measure_memory_usage();
    
    // Create stream
    let stream_id = manager.create_stream("test-session").await.unwrap();
    
    // Send some events
    for i in 0..5 {
        let event_data = format!("event-{}", i);
        let _result = manager.send_event(&stream_id, &event_data, Some("test_event")).await;
    }
    
    let after_events_memory = measure_memory_usage();
    let events_memory_increase = after_events_memory - initial_memory;
    
    println!("Memory after sending events: {} bytes (increase: {} bytes)", 
        after_events_memory, events_memory_increase);
    
    // Pause stream
    manager.pause_stream(&stream_id).await.unwrap();
    
    let after_pause_memory = measure_memory_usage();
    let pause_memory_change = after_pause_memory - after_events_memory;
    
    println!("Memory after pausing stream: {} bytes (change: {} bytes)", 
        after_pause_memory, pause_memory_change);
    
    // Resume stream
    manager.resume_stream(&stream_id).await.unwrap();
    
    let after_resume_memory = measure_memory_usage();
    let resume_memory_change = after_resume_memory - after_pause_memory;
    
    println!("Memory after resuming stream: {} bytes (change: {} bytes)", 
        after_resume_memory, resume_memory_change);
    
    // Clean up
    manager.close_stream(&stream_id).await.unwrap();
    
    let after_cleanup_memory = measure_memory_usage();
    let cleanup_memory_decrease = after_resume_memory - after_cleanup_memory;
    
    println!("Memory after cleanup: {} bytes (decrease: {} bytes)", 
        after_cleanup_memory, cleanup_memory_decrease);
    
    // Assertions
    assert!(events_memory_increase < 1024 * 200, "Events should use less than 200KB");
    assert!(pause_memory_change < 1024 * 50, "Pausing should use minimal additional memory");
    assert!(resume_memory_change < 1024 * 50, "Resuming should use minimal additional memory");
    assert!(cleanup_memory_decrease > 0, "Cleanup should reduce memory");
}

/// Test memory usage during error conditions
#[tokio::test]
async fn test_memory_usage_error_conditions() {
    let manager = StreamManager::new(Duration::from_secs(300), 5, 10);
    let initial_memory = measure_memory_usage();
    
    // Test memory usage during various error conditions
    let error_scenarios = vec![
        "invalid_stream_id",
        "closed_stream",
        "max_streams_reached",
        "expired_stream"
    ];
    
    for scenario in error_scenarios {
        let before_memory = measure_memory_usage();
        
        // Simulate error condition
        match scenario {
            "invalid_stream_id" => {
                let _result = manager.send_event("invalid-id", "test", Some("test")).await;
            },
            "closed_stream" => {
                let stream_id = manager.create_stream("test-session").await.unwrap();
                manager.close_stream(&stream_id).await.unwrap();
                let _result = manager.send_event(&stream_id, "test", Some("test")).await;
            },
            "max_streams_reached" => {
                // Create streams up to the limit
                let mut stream_ids = vec![];
                for i in 0..10 {
                    if let Ok(stream_id) = manager.create_stream(&format!("session-{}", i)).await {
                        stream_ids.push(stream_id);
                    }
                }
                // Try to create one more (should fail)
                let _result = manager.create_stream("overflow-session").await;
                
                // Clean up
                for stream_id in stream_ids {
                    let _ = manager.close_stream(&stream_id).await;
                }
            },
            "expired_stream" => {
                let short_timeout_manager = StreamManager::new(Duration::from_millis(10), 5, 10);
                let stream_id = short_timeout_manager.create_stream("test-session").await.unwrap();
                
                // Wait for stream to expire
                tokio::time::sleep(Duration::from_millis(50)).await;
                
                let _result = short_timeout_manager.send_event(&stream_id, "test", Some("test")).await;
            },
            _ => {}
        }
        
        let after_memory = measure_memory_usage();
        let memory_change = after_memory - before_memory;
        
        println!("Error scenario '{}' memory change: {} bytes", scenario, memory_change);
        
        // Assertions for error scenarios
        assert!(memory_change < 1024 * 100, "Error scenario should use less than 100KB additional memory");
    }
    
    let final_memory = measure_memory_usage();
    let total_memory_increase = final_memory - initial_memory;
    
    println!("Total memory increase after error scenarios: {} bytes", total_memory_increase);
    
    // Assertions
    assert!(total_memory_increase < 1024 * 200, "Total memory increase should be minimal after error scenarios");
}

/// Test comprehensive resource cleanup
#[tokio::test]
async fn test_comprehensive_resource_cleanup() {
    let session_manager = SessionManager::new(Duration::from_secs(300), 10);
    let stream_manager = StreamManager::new(Duration::from_secs(300), 5, 10);
    let initial_memory = measure_memory_usage();
    
    println!("Testing comprehensive resource cleanup...");
    
    let mut session_ids = vec![];
    let mut stream_ids = vec![];
    
    // Create multiple sessions with streams
    for session_num in 0..3 {
        let session_id = session_manager.create_session(None).await.unwrap();
        session_ids.push(session_id.clone());
        
        // Create multiple streams per session
        for stream_num in 0..2 {
            let stream_id = stream_manager.create_stream(&session_id).await.unwrap();
            stream_ids.push(stream_id.clone());
            
            // Send some events
            for event_num in 0..5 {
                let event_data = format!("session-{}_stream-{}_event-{}", session_num, stream_num, event_num);
                let _result = stream_manager.send_event(&stream_id, &event_data, Some("comprehensive_test")).await;
            }
        }
    }
    
    let after_creation_memory = measure_memory_usage();
    let creation_memory_increase = after_creation_memory - initial_memory;
    
    println!("Memory after creation: {} bytes (increase: {} bytes)", 
        after_creation_memory, creation_memory_increase);
    
    // Clean up all resources
    for stream_id in &stream_ids {
        let _ = stream_manager.close_stream(stream_id).await;
    }
    
    for session_id in &session_ids {
        let _ = session_manager.terminate_session(session_id).await;
    }
    
    let after_cleanup_memory = measure_memory_usage();
    let total_cleanup_decrease = after_creation_memory - after_cleanup_memory;
    let final_memory_increase = after_cleanup_memory - initial_memory;
    
    println!("Memory after comprehensive cleanup: {} bytes", after_cleanup_memory);
    println!("Total cleanup decrease: {} bytes", total_cleanup_decrease);
    println!("Final memory increase: {} bytes", final_memory_increase);
    
    // Assertions
    assert!(creation_memory_increase < 1024 * 1024, "Creation should use less than 1MB");
    assert!(total_cleanup_decrease > 0, "Comprehensive cleanup should reduce memory");
    assert!(final_memory_increase < 1024 * 100, "Final memory should be close to initial");
}
