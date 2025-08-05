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
} 