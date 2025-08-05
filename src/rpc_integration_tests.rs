use crate::rpc::ParagonicServer;
use crate::ollama::OllamaClient;
use crate::ollama::OllamaConfig;
use serde_json::json;
use tokio_jsonrpc::RpcError;

#[cfg(test)]
mod rpc_integration_tests {
    use super::*;

    /// Test handle_iragl_search with valid parameters
    #[tokio::test(flavor = "multi_thread")]
    async fn test_handle_iragl_search_valid_params() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test with valid search parameters
        let params = Some(json!({
            "query": "test search query",
            "max_results": 10,
            "include_associations": true,
            "filter_optimized_only": false
        }));
        
        let result = server.handle_iragl_search(&params);
        if let Err(e) = &result {
            println!("IRAGL search failed with error: {:?}", e);
        }
        assert!(result.is_ok(), "handle_iragl_search should return Ok");
        
        // Verify the response is valid JSON
        let response = result.unwrap();
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        
        // Check that response has expected structure
        assert!(response_json.get("results").is_some(), "Should have results field");
        assert!(response_json.get("total_count").is_some(), "Should have total_count field");
        assert!(response_json.get("search_duration_ms").is_some(), "Should have search_duration_ms field");
        assert!(response_json.get("query_optimization_applied").is_some(), "Should have query_optimization_applied field");
        
        // Verify results is an array
        let results = response_json["results"].as_array().expect("Results should be an array");
        assert!(results.len() <= 10, "Should not exceed max_results limit");
    }

    /// Test handle_iragl_search with organizational context
    #[tokio::test(flavor = "multi_thread")]
    async fn test_handle_iragl_search_with_context() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test with organizational context
        let params = Some(json!({
            "query": "project management",
            "query_context": {
                "organization_id": "123e4567-e89b-12d3-a456-426614174000",
                "project_id": "456e7890-e89b-12d3-a456-426614174000",
                "user_role": "developer"
            },
            "max_results": 5,
            "include_associations": true,
            "filter_optimized_only": true
        }));
        
        let result = server.handle_iragl_search(&params);
        assert!(result.is_ok(), "handle_iragl_search should return Ok with context");
        
        // Verify the response structure
        let response = result.unwrap();
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        
        assert!(response_json.get("results").is_some(), "Should have results field");
        assert!(response_json.get("query_context").is_some(), "Should include query context in response");
    }

    /// Test handle_iragl_search with missing required parameters
    #[tokio::test(flavor = "multi_thread")]
    async fn test_handle_iragl_search_missing_params() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test with missing query
        let params = Some(json!({
            "max_results": 10,
            "include_associations": true
        }));
        
        let result = server.handle_iragl_search(&params);
        assert!(result.is_err(), "Should return error for missing query");
        
        // Test with empty query
        let params = Some(json!({
            "query": "",
            "max_results": 10
        }));
        
        let result = server.handle_iragl_search(&params);
        assert!(result.is_err(), "Should return error for empty query");
        
        // Test with None parameters
        let result = server.handle_iragl_search(&None);
        assert!(result.is_err(), "Should return error for None parameters");
    }

    /// Test handle_iragl_search with invalid parameter types
    #[tokio::test(flavor = "multi_thread")]
    async fn test_handle_iragl_search_invalid_param_types() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test with non-string query
        let params = Some(json!({
            "query": 123,
            "max_results": 10
        }));
        
        let result = server.handle_iragl_search(&params);
        assert!(result.is_err(), "Should return error for non-string query");
        
        // Test with non-number max_results
        let params = Some(json!({
            "query": "test query",
            "max_results": "invalid"
        }));
        
        let result = server.handle_iragl_search(&params);
        assert!(result.is_err(), "Should return error for non-number max_results");
    }

    /// Test handle_iragl_search performance validation
    #[tokio::test(flavor = "multi_thread")]
    async fn test_handle_iragl_search_performance() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        let params = Some(json!({
            "query": "performance test query",
            "max_results": 20
        }));
        
        let start_time = std::time::Instant::now();
        let result = server.handle_iragl_search(&params);
        let duration = start_time.elapsed();
        
        assert!(result.is_ok(), "handle_iragl_search should complete successfully");
        assert!(duration.as_millis() < 1000, "Search should complete within 1 second");
        
        // Verify response includes performance metrics
        let response = result.unwrap();
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        
        let search_duration = response_json["search_duration_ms"].as_u64()
            .expect("Should have search_duration_ms field");
        assert!(search_duration < 1000, "Search duration should be less than 1000ms");
    }

    /// Test handle_iragl_search with different result limits
    #[tokio::test(flavor = "multi_thread")]
    async fn test_handle_iragl_search_result_limits() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test with small limit
        let params = Some(json!({
            "query": "test query",
            "max_results": 1
        }));
        
        let result = server.handle_iragl_search(&params);
        assert!(result.is_ok(), "Should handle small result limit");
        
        let response = result.unwrap();
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        
        let results = response_json["results"].as_array().expect("Results should be an array");
        assert!(results.len() <= 1, "Should respect max_results limit");
        
        // Test with large limit
        let params = Some(json!({
            "query": "test query",
            "max_results": 100
        }));
        
        let result = server.handle_iragl_search(&params);
        assert!(result.is_ok(), "Should handle large result limit");
        
        let response = result.unwrap();
        let response_json: serde_json::Value = serde_json::from_str(&response)
            .expect("Response should be valid JSON");
        
        let results = response_json["results"].as_array().expect("Results should be an array");
        assert!(results.len() <= 100, "Should respect max_results limit");
    }

    /// Test handle_iragl_search error handling
    #[tokio::test(flavor = "multi_thread")]
    async fn test_handle_iragl_search_error_handling() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test with malformed JSON
        let params = Some(json!({
            "query": "test query",
            "invalid_field": "invalid_value"
        }));
        
        let result = server.handle_iragl_search(&params);
        // Should still work as we ignore unknown fields
        assert!(result.is_ok(), "Should handle unknown fields gracefully");
        
        // Test with very long query
        let long_query = "a".repeat(10000);
        let params = Some(json!({
            "query": long_query,
            "max_results": 10
        }));
        
        let result = server.handle_iragl_search(&params);
        assert!(result.is_ok(), "Should handle long queries");
    }

    /// Test handle_optimize_knowledge_base with valid parameters
    #[tokio::test(flavor = "multi_thread")]
    async fn test_handle_optimize_knowledge_base_valid_params() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test with valid optimization parameters
        let params = Some(json!({
            "strategy": "incremental",
            "max_iterations": 10,
            "convergence_threshold": 0.001,
            "enable_parallel_processing": true
        }));
        
        let result = server.handle_optimize_knowledge_base(&params);
        if let Err(e) = &result {
            println!("Knowledge base optimization failed with error: {:?}", e);
        }
        assert!(result.is_ok(), "handle_optimize_knowledge_base should return Ok");
        
        let response = result.unwrap();
        let response_data: serde_json::Value = serde_json::from_str(&response).unwrap();
        
        // Verify response structure
        assert!(response_data.get("optimization_id").is_some());
        assert!(response_data.get("status").is_some());
        assert!(response_data.get("estimated_duration_ms").is_some());
    }

    /// Test handle_optimize_knowledge_base with different strategies
    #[tokio::test(flavor = "multi_thread")]
    async fn test_handle_optimize_knowledge_base_strategies() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        let strategies = ["incremental", "batch", "selective", "full"];
        
        for strategy in strategies {
            let params = Some(json!({
                "strategy": strategy,
                "max_iterations": 5,
                "convergence_threshold": 0.01
            }));
            
            let result = server.handle_optimize_knowledge_base(&params);
            assert!(result.is_ok(), "Optimization should work with strategy: {}", strategy);
        }
    }

    /// Test handle_optimize_knowledge_base with missing required parameters
    #[tokio::test(flavor = "multi_thread")]
    async fn test_handle_optimize_knowledge_base_missing_params() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test with missing parameters
        let params = Some(json!({}));
        
        let result = server.handle_optimize_knowledge_base(&params);
        assert!(result.is_err(), "Should return error for missing parameters");
    }

    /// Test handle_optimize_knowledge_base with invalid parameter types
    #[tokio::test(flavor = "multi_thread")]
    async fn test_handle_optimize_knowledge_base_invalid_param_types() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test with invalid parameter types
        let params = Some(json!({
            "strategy": "invalid_strategy",
            "max_iterations": "invalid_number",
            "convergence_threshold": "invalid_threshold"
        }));
        
        let result = server.handle_optimize_knowledge_base(&params);
        assert!(result.is_err(), "Should return error for invalid parameter types");
    }

    /// Test handle_optimize_knowledge_base performance validation
    #[tokio::test(flavor = "multi_thread")]
    async fn test_handle_optimize_knowledge_base_performance() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        let start_time = std::time::Instant::now();
        
        let params = Some(json!({
            "strategy": "incremental",
            "max_iterations": 1,
            "convergence_threshold": 0.1
        }));
        
        let result = server.handle_optimize_knowledge_base(&params);
        assert!(result.is_ok(), "Optimization should complete successfully");
        
        let duration = start_time.elapsed();
        assert!(duration.as_millis() < 5000, "Optimization should complete within 5 seconds");
    }

    /// Test handle_optimize_knowledge_base with different iteration limits
    #[tokio::test(flavor = "multi_thread")]
    async fn test_handle_optimize_knowledge_base_iteration_limits() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        let iteration_limits = [1, 5, 10, 50];
        
        for limit in iteration_limits {
            let params = Some(json!({
                "strategy": "incremental",
                "max_iterations": limit,
                "convergence_threshold": 0.01
            }));
            
            let result = server.handle_optimize_knowledge_base(&params);
            assert!(result.is_ok(), "Optimization should work with iteration limit: {}", limit);
        }
    }

    /// Test handle_optimize_knowledge_base error handling
    #[tokio::test(flavor = "multi_thread")]
    async fn test_handle_optimize_knowledge_base_error_handling() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test with invalid field (should be ignored)
        let params = Some(json!({
            "strategy": "incremental",
            "max_iterations": 10,
            "invalid_field": "should_be_ignored"
        }));
        
        let result = server.handle_optimize_knowledge_base(&params);
        assert!(result.is_ok(), "Should handle unknown fields gracefully");
    }

    /// Test handle_optimization_status with valid optimization ID
    #[tokio::test(flavor = "multi_thread")]
    async fn test_handle_optimization_status_valid_id() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // First, start an optimization to get a valid ID
        let optimize_params = Some(json!({
            "strategy": "incremental",
            "max_iterations": 5,
            "convergence_threshold": 0.01
        }));
        
        let optimize_result = server.handle_optimize_knowledge_base(&optimize_params);
        assert!(optimize_result.is_ok(), "Should be able to start optimization");
        
        let optimize_response = optimize_result.unwrap();
        let optimize_data: serde_json::Value = serde_json::from_str(&optimize_response).unwrap();
        let optimization_id = optimize_data.get("optimization_id").unwrap().as_str().unwrap();
        
        // Now check the status
        let status_params = Some(json!({
            "optimization_id": optimization_id
        }));
        
        let result = server.handle_optimization_status(&status_params);
        if let Err(e) = &result {
            println!("Optimization status check failed with error: {:?}", e);
        }
        assert!(result.is_ok(), "handle_optimization_status should return Ok");
        
        let response = result.unwrap();
        let response_data: serde_json::Value = serde_json::from_str(&response).unwrap();
        
        // Verify response structure
        assert!(response_data.get("optimization_id").is_some());
        assert!(response_data.get("status").is_some());
        assert!(response_data.get("progress_percentage").is_some());
    }

    /// Test handle_optimization_status with missing optimization ID
    #[tokio::test(flavor = "multi_thread")]
    async fn test_handle_optimization_status_missing_id() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test with missing optimization ID
        let params = Some(json!({}));
        
        let result = server.handle_optimization_status(&params);
        assert!(result.is_err(), "Should return error for missing optimization ID");
    }

    /// Test handle_optimization_status with invalid optimization ID
    #[tokio::test(flavor = "multi_thread")]
    async fn test_handle_optimization_status_invalid_id() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test with invalid optimization ID
        let params = Some(json!({
            "optimization_id": "invalid-uuid-format"
        }));
        
        let result = server.handle_optimization_status(&params);
        assert!(result.is_err(), "Should return error for invalid optimization ID");
    }

    /// Test handle_optimization_status with non-existent optimization ID
    #[tokio::test(flavor = "multi_thread")]
    async fn test_handle_optimization_status_nonexistent_id() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test with non-existent optimization ID
        let params = Some(json!({
            "optimization_id": "123e4567-e89b-12d3-a456-426614174000"
        }));
        
        let result = server.handle_optimization_status(&params);
        assert!(result.is_ok(), "Should handle non-existent ID gracefully");
        
        let response = result.unwrap();
        let response_data: serde_json::Value = serde_json::from_str(&response).unwrap();
        
        // Should return "not_found" status
        let status = response_data.get("status").unwrap().as_str().unwrap();
        assert_eq!(status, "not_found");
    }

    /// Test handle_optimization_status performance validation
    #[tokio::test(flavor = "multi_thread")]
    async fn test_handle_optimization_status_performance() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        let start_time = std::time::Instant::now();
        
        // First, start an optimization
        let optimize_params = Some(json!({
            "strategy": "incremental",
            "max_iterations": 1,
            "convergence_threshold": 0.1
        }));
        
        let optimize_result = server.handle_optimize_knowledge_base(&optimize_params);
        assert!(optimize_result.is_ok(), "Should be able to start optimization");
        
        let optimize_response = optimize_result.unwrap();
        let optimize_data: serde_json::Value = serde_json::from_str(&optimize_response).unwrap();
        let optimization_id = optimize_data.get("optimization_id").unwrap().as_str().unwrap();
        
        // Check status
        let status_params = Some(json!({
            "optimization_id": optimization_id
        }));
        
        let result = server.handle_optimization_status(&status_params);
        assert!(result.is_ok(), "Status check should complete successfully");
        
        let duration = start_time.elapsed();
        assert!(duration.as_millis() < 2000, "Status check should complete within 2 seconds");
    }

    /// Test handle_optimization_status with multiple status checks
    #[tokio::test(flavor = "multi_thread")]
    async fn test_handle_optimization_status_multiple_checks() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;
        
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Start an optimization
        let optimize_params = Some(json!({
            "strategy": "incremental",
            "max_iterations": 3,
            "convergence_threshold": 0.01
        }));
        
        let optimize_result = server.handle_optimize_knowledge_base(&optimize_params);
        assert!(optimize_result.is_ok(), "Should be able to start optimization");
        
        let optimize_response = optimize_result.unwrap();
        let optimize_data: serde_json::Value = serde_json::from_str(&optimize_response).unwrap();
        let optimization_id = optimize_data.get("optimization_id").unwrap().as_str().unwrap();
        
        // Check status multiple times
        let status_params = Some(json!({
            "optimization_id": optimization_id
        }));
        
        for i in 0..3 {
            let result = server.handle_optimization_status(&status_params);
            assert!(result.is_ok(), "Status check {} should succeed", i);
            
            let response = result.unwrap();
            let response_data: serde_json::Value = serde_json::from_str(&response).unwrap();
            
            // Verify the optimization ID matches
            let returned_id = response_data.get("optimization_id").unwrap().as_str().unwrap();
            assert_eq!(returned_id, optimization_id);
        }
    }

    /// Test handle_optimization_status error handling
    #[tokio::test(flavor = "multi_thread")]
    async fn test_handle_optimization_status_error_handling() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        let server = ParagonicServer::new(client);
        
        // Test with invalid field (should be ignored)
        let params = Some(json!({
            "optimization_id": "123e4567-e89b-12d3-a456-426614174000",
            "invalid_field": "should_be_ignored"
        }));
        
        let result = server.handle_optimization_status(&params);
        assert!(result.is_ok(), "Should handle unknown fields gracefully");
    }
} 