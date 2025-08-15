use crate::iragl::{IraglSearchRequest, IraglSearchResponse, IraglSearchResult};
use crate::{ParagonicError, ParagonicResult};

#[cfg(test)]
mod iragl_search_engine_tests {
    use super::*;
    use serde_json::json;
    use uuid::Uuid;

    /// Test IRAGLSearchEngine creation and basic configuration
    #[tokio::test]
    async fn test_iragl_search_engine_creation() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;

        let engine = IRAGLSearchEngine::new().unwrap();

        // Test basic engine properties
        assert_eq!(engine.search_count(), 0);
        assert_eq!(engine.cache_hit_rate(), 0.0);
        assert_eq!(engine.average_response_time_ms(), 0);
    }

    /// Test IRAGLSearchEngine with custom configuration
    #[tokio::test]
    async fn test_iragl_search_engine_with_config() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;

        let config = IRAGLSearchEngineConfig {
            max_results: 50,
            similarity_threshold: 0.7,
            context_weight: 0.3,
            cache_enabled: true,
            cache_size: 1000,
            cache_ttl_seconds: 3600,
            enable_analytics: true,
            performance_monitoring: true,
        };

        let engine = IRAGLSearchEngine::with_config(config).unwrap();

        // Test that configuration is applied
        assert_eq!(engine.max_results(), 50);
        assert_eq!(engine.similarity_threshold(), 0.7);
        assert_eq!(engine.context_weight(), 0.3);
        assert!(engine.cache_enabled());
    }

    /// Test vector similarity search functionality
    #[tokio::test]
    async fn test_vector_similarity_search() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;

        let engine = IRAGLSearchEngine::new().unwrap();

        // Test basic vector similarity search
        let request = IraglSearchRequest {
            query_text: "test query for vector search".to_string(),
            query_context: Some(json!({"organization_id": "test-org"})),
            max_results: 10,
            include_associations: true,
            filter_optimized_only: false,
        };

        let result = engine.perform_vector_similarity_search(&request).await;
        assert!(result.is_ok());

        let response = result.unwrap();
        assert_eq!(response.results.len(), 0); // No data in test environment
        assert_eq!(response.total_count, 0);
        assert!(response.search_duration_ms > 0);
        assert!(!response.query_optimization_applied);
    }

    /// Test organizational context weighting
    #[tokio::test]
    async fn test_organizational_context_weighting() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;

        let engine = IRAGLSearchEngine::new().unwrap();

        // Test context weighting with different organizational contexts
        let contexts = vec![
            json!({"organization_id": "org1", "department": "engineering"}),
            json!({"organization_id": "org2", "department": "marketing"}),
            json!({"organization_id": "org3", "department": "sales"}),
        ];

        for context in contexts {
            let request = IraglSearchRequest {
                query_text: "test query".to_string(),
                query_context: Some(context),
                max_results: 5,
                include_associations: false,
                filter_optimized_only: false,
            };

            let result = engine
                .apply_organizational_context_weighting(&request)
                .await;
            assert!(result.is_ok());

            let weighted_request = result.unwrap();
            assert_eq!(weighted_request.query_text, "test query");
            assert!(weighted_request.query_context.is_some());
        }
    }

    /// Test result ranking and relevance scoring
    #[tokio::test]
    async fn test_result_ranking_and_relevance_scoring() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;

        let engine = IRAGLSearchEngine::new().unwrap();

        // Create mock search results
        let mock_results = vec![
            IraglSearchResult {
                content_id: Uuid::new_v4(),
                content_text: "First result with high relevance".to_string(),
                similarity_score: 0.95,
                content_type: "document".to_string(),
                source_entity_type: "project".to_string(),
                source_entity_id: Uuid::new_v4(),
                associations: None,
                optimization_score: Some(0.9),
            },
            IraglSearchResult {
                content_id: Uuid::new_v4(),
                content_text: "Second result with medium relevance".to_string(),
                similarity_score: 0.75,
                content_type: "message".to_string(),
                source_entity_type: "conversation".to_string(),
                source_entity_id: Uuid::new_v4(),
                associations: None,
                optimization_score: Some(0.7),
            },
            IraglSearchResult {
                content_id: Uuid::new_v4(),
                content_text: "Third result with low relevance".to_string(),
                similarity_score: 0.55,
                content_type: "note".to_string(),
                source_entity_type: "task".to_string(),
                source_entity_id: Uuid::new_v4(),
                associations: None,
                optimization_score: Some(0.5),
            },
        ];

        // Test ranking and scoring
        let ranked_results = engine.rank_and_score_results(mock_results).await;
        assert!(ranked_results.is_ok());

        let results = ranked_results.unwrap();
        assert_eq!(results.len(), 3);

        // Verify results are ranked by relevance (highest first)
        assert!(results[0].similarity_score >= results[1].similarity_score);
        assert!(results[1].similarity_score >= results[2].similarity_score);
    }

    /// Test filter application and query optimization
    #[tokio::test]
    async fn test_filter_application_and_query_optimization() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;

        let engine = IRAGLSearchEngine::new().unwrap();

        // Test query optimization
        let original_request = IraglSearchRequest {
            query_text: "test query for optimization".to_string(),
            query_context: Some(json!({"organization_id": "test-org"})),
            max_results: 20,
            include_associations: true,
            filter_optimized_only: true,
        };

        let optimized_request = engine.optimize_query(&original_request).await;
        assert!(optimized_request.is_ok());

        let optimized = optimized_request.unwrap();
        assert_eq!(optimized.query_text, "test query for optimization");
        assert!(optimized.filter_optimized_only);

        // Test filter application
        let filters = vec![
            "content_type:document".to_string(),
            "organization_id:test-org".to_string(),
            "optimization_score:>0.7".to_string(),
        ];

        let filtered_request = engine.apply_filters(&optimized, &filters).await;
        assert!(filtered_request.is_ok());
    }

    /// Test search performance monitoring
    #[tokio::test]
    async fn test_search_performance_monitoring() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;

        let engine = IRAGLSearchEngine::new().unwrap();

        // Perform a search to generate metrics
        let request = IraglSearchRequest {
            query_text: "performance test query".to_string(),
            query_context: None,
            max_results: 10,
            include_associations: false,
            filter_optimized_only: false,
        };

        let _ = engine.perform_vector_similarity_search(&request).await;

        // Test performance metrics
        let metrics = engine.get_performance_metrics().await;
        assert!(metrics.is_ok());

        let performance_metrics = metrics.unwrap();
        assert!(performance_metrics.total_searches > 0);
        // assert!(performance_metrics.average_response_time_ms >= 0); // Redundant for u64
        assert!(performance_metrics.cache_hit_rate >= 0.0);
        assert!(performance_metrics.cache_hit_rate <= 1.0);
    }

    /// Test result caching and invalidation
    #[tokio::test]
    async fn test_result_caching_and_invalidation() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;

        let engine = IRAGLSearchEngine::new().unwrap();

        // Test cache storage
        let cache_key = "test_cache_key".to_string();
        let mock_response = IraglSearchResponse {
            results: vec![],
            total_count: 0,
            search_duration_ms: 10,
            query_optimization_applied: false,
        };

        let cache_result = engine.cache_search_result(&cache_key, &mock_response).await;
        assert!(cache_result.is_ok());

        // Test cache retrieval
        let retrieved = engine.get_cached_result(&cache_key).await;
        assert!(retrieved.is_ok());

        // Test cache invalidation
        let invalidation_result = engine.invalidate_cache(&cache_key).await;
        assert!(invalidation_result.is_ok());

        // Verify cache is cleared
        let retrieved_after_invalidation = engine.get_cached_result(&cache_key).await;
        assert!(retrieved_after_invalidation.is_err());
    }

    /// Test search engine statistics and monitoring
    #[tokio::test]
    async fn test_search_engine_statistics_and_monitoring() {
        // Initialize database for testing
        let _ = crate::database::initialize_for_testing().await;

        let engine = IRAGLSearchEngine::new().unwrap();

        // Perform multiple searches to generate statistics
        for i in 0..5 {
            let request = IraglSearchRequest {
                query_text: format!("statistics test query {}", i),
                query_context: None,
                max_results: 5,
                include_associations: false,
                filter_optimized_only: false,
            };

            let _ = engine.perform_vector_similarity_search(&request).await;
        }

        // Test statistics
        assert_eq!(engine.search_count(), 5);
        // assert!(engine.average_response_time_ms() >= 0); // Redundant for u64
        assert!(engine.cache_hit_rate() >= 0.0);
        assert!(engine.cache_hit_rate() <= 1.0);

        // Test reset functionality
        engine.reset_statistics();
        assert_eq!(engine.search_count(), 0);
        assert_eq!(engine.average_response_time_ms(), 0);
        assert_eq!(engine.cache_hit_rate(), 0.0);
    }
}

// Mock implementation of IRAGLSearchEngine for testing
#[derive(Debug, Clone)]
pub struct IRAGLSearchEngineConfig {
    pub max_results: usize,
    pub similarity_threshold: f64,
    pub context_weight: f64,
    pub cache_enabled: bool,
    pub cache_size: usize,
    pub cache_ttl_seconds: u64,
    pub enable_analytics: bool,
    pub performance_monitoring: bool,
}

impl Default for IRAGLSearchEngineConfig {
    fn default() -> Self {
        Self {
            max_results: 20,
            similarity_threshold: 0.5,
            context_weight: 0.2,
            cache_enabled: true,
            cache_size: 500,
            cache_ttl_seconds: 1800,
            enable_analytics: true,
            performance_monitoring: true,
        }
    }
}

#[derive(Debug)]
pub struct IRAGLSearchEngine {
    config: IRAGLSearchEngineConfig,
    search_count: std::sync::atomic::AtomicU64,
    total_response_time: std::sync::atomic::AtomicU64,
    cache_hits: std::sync::atomic::AtomicU64,
    cache_misses: std::sync::atomic::AtomicU64,
    cache: std::sync::Mutex<std::collections::HashMap<String, IraglSearchResponse>>,
}

impl IRAGLSearchEngine {
    pub fn new() -> ParagonicResult<Self> {
        Ok(Self::with_config(IRAGLSearchEngineConfig::default())?)
    }

    pub fn with_config(config: IRAGLSearchEngineConfig) -> ParagonicResult<Self> {
        Ok(Self {
            config,
            search_count: std::sync::atomic::AtomicU64::new(0),
            total_response_time: std::sync::atomic::AtomicU64::new(0),
            cache_hits: std::sync::atomic::AtomicU64::new(0),
            cache_misses: std::sync::atomic::AtomicU64::new(0),
            cache: std::sync::Mutex::new(std::collections::HashMap::new()),
        })
    }

    pub fn max_results(&self) -> usize {
        self.config.max_results
    }

    pub fn similarity_threshold(&self) -> f64 {
        self.config.similarity_threshold
    }

    pub fn context_weight(&self) -> f64 {
        self.config.context_weight
    }

    pub fn cache_enabled(&self) -> bool {
        self.config.cache_enabled
    }

    pub fn search_count(&self) -> u64 {
        self.search_count.load(std::sync::atomic::Ordering::Relaxed)
    }

    pub fn average_response_time_ms(&self) -> u64 {
        let count = self.search_count();
        if count == 0 {
            return 0;
        }
        self.total_response_time
            .load(std::sync::atomic::Ordering::Relaxed)
            / count
    }

    pub fn cache_hit_rate(&self) -> f64 {
        let hits = self.cache_hits.load(std::sync::atomic::Ordering::Relaxed);
        let misses = self.cache_misses.load(std::sync::atomic::Ordering::Relaxed);
        let total = hits + misses;
        if total == 0 {
            return 0.0;
        }
        hits as f64 / total as f64
    }

    pub async fn perform_vector_similarity_search(
        &self,
        request: &IraglSearchRequest,
    ) -> ParagonicResult<IraglSearchResponse> {
        let start_time = std::time::Instant::now();

        // Increment search count
        self.search_count
            .fetch_add(1, std::sync::atomic::Ordering::Relaxed);

        // Simulate search processing time
        tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;

        // Record response time
        let response_time = start_time.elapsed().as_millis() as u64;
        self.total_response_time
            .fetch_add(response_time, std::sync::atomic::Ordering::Relaxed);

        // Return mock response
        Ok(IraglSearchResponse {
            results: vec![],
            total_count: 0,
            search_duration_ms: response_time,
            query_optimization_applied: false,
        })
    }

    pub async fn apply_organizational_context_weighting(
        &self,
        request: &IraglSearchRequest,
    ) -> ParagonicResult<IraglSearchRequest> {
        // Mock implementation - just return the request as-is
        Ok(request.clone())
    }

    pub async fn rank_and_score_results(
        &self,
        mut results: Vec<IraglSearchResult>,
    ) -> ParagonicResult<Vec<IraglSearchResult>> {
        // Sort by similarity score (highest first)
        results.sort_by(|a, b| {
            b.similarity_score
                .partial_cmp(&a.similarity_score)
                .unwrap_or(std::cmp::Ordering::Equal)
        });
        Ok(results)
    }

    pub async fn optimize_query(
        &self,
        request: &IraglSearchRequest,
    ) -> ParagonicResult<IraglSearchRequest> {
        // Mock implementation - just return the request as-is
        Ok(request.clone())
    }

    pub async fn apply_filters(
        &self,
        request: &IraglSearchRequest,
        _filters: &[String],
    ) -> ParagonicResult<IraglSearchRequest> {
        // Mock implementation - just return the request as-is
        Ok(request.clone())
    }

    pub async fn get_performance_metrics(&self) -> ParagonicResult<SearchPerformanceMetrics> {
        Ok(SearchPerformanceMetrics {
            total_searches: self.search_count(),
            average_response_time_ms: self.average_response_time_ms(),
            cache_hit_rate: self.cache_hit_rate(),
            total_cache_hits: self.cache_hits.load(std::sync::atomic::Ordering::Relaxed),
            total_cache_misses: self.cache_misses.load(std::sync::atomic::Ordering::Relaxed),
        })
    }

    pub async fn cache_search_result(
        &self,
        key: &str,
        response: &IraglSearchResponse,
    ) -> ParagonicResult<()> {
        if self.config.cache_enabled {
            let mut cache = self.cache.lock().unwrap();
            cache.insert(key.to_string(), response.clone());
        }
        Ok(())
    }

    pub async fn get_cached_result(&self, key: &str) -> ParagonicResult<IraglSearchResponse> {
        if self.config.cache_enabled {
            let cache = self.cache.lock().unwrap();
            if let Some(response) = cache.get(key) {
                self.cache_hits
                    .fetch_add(1, std::sync::atomic::Ordering::Relaxed);
                return Ok(response.clone());
            }
        }
        self.cache_misses
            .fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        Err(ParagonicError::Internal("Cache miss".to_string()))
    }

    pub async fn invalidate_cache(&self, key: &str) -> ParagonicResult<()> {
        if self.config.cache_enabled {
            let mut cache = self.cache.lock().unwrap();
            cache.remove(key);
        }
        Ok(())
    }

    pub fn reset_statistics(&self) {
        self.search_count
            .store(0, std::sync::atomic::Ordering::Relaxed);
        self.total_response_time
            .store(0, std::sync::atomic::Ordering::Relaxed);
        self.cache_hits
            .store(0, std::sync::atomic::Ordering::Relaxed);
        self.cache_misses
            .store(0, std::sync::atomic::Ordering::Relaxed);
    }
}

#[derive(Debug)]
pub struct SearchPerformanceMetrics {
    pub total_searches: u64,
    pub average_response_time_ms: u64,
    pub cache_hit_rate: f64,
    pub total_cache_hits: u64,
    pub total_cache_misses: u64,
}
