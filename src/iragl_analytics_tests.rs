//! Tests for IRAGL Analytics and Monitoring System
//!
//! This module contains comprehensive tests for the analytics collector,
//! performance trend analysis, and optimization effectiveness measurement.

use crate::iragl::analytics::*;
use crate::error::ParagonicResult;
use chrono::{DateTime, Duration, Utc};
use serde_json::json;
use uuid::Uuid;

/// Test configuration for analytics tests
const TEST_CONFIG: &str = r#"
{
    "analytics": {
        "collection_interval_seconds": 60,
        "retention_days": 30,
        "batch_size": 100,
        "performance_thresholds": {
            "response_time_ms": 100,
            "optimization_effectiveness": 0.8,
            "user_satisfaction": 0.7
        }
    }
}
"#;

/// Test helper to create sample query analytics data
fn create_sample_query_analytics() -> Vec<QueryAnalyticsData> {
    vec![
        QueryAnalyticsData {
            query_text: "test query 1".to_string(),
            query_context: Some(json!({"project": "test-project"})),
            result_count: 5,
            response_time_ms: 50,
            user_satisfaction_score: Some(0.9),
            optimization_impact: Some(0.1),
            timestamp: Utc::now() - Duration::hours(1),
        },
        QueryAnalyticsData {
            query_text: "test query 2".to_string(),
            query_context: Some(json!({"project": "test-project"})),
            result_count: 10,
            response_time_ms: 75,
            user_satisfaction_score: Some(0.8),
            optimization_impact: Some(0.2),
            timestamp: Utc::now() - Duration::minutes(30),
        },
        QueryAnalyticsData {
            query_text: "test query 3".to_string(),
            query_context: Some(json!({"project": "other-project"})),
            result_count: 3,
            response_time_ms: 120,
            user_satisfaction_score: Some(0.6),
            optimization_impact: Some(0.3),
            timestamp: Utc::now(),
        },
    ]
}

/// Test helper to create sample optimization analytics data
fn create_sample_optimization_analytics() -> Vec<OptimizationAnalyticsData> {
    vec![
        OptimizationAnalyticsData {
            optimization_type: "embedding_update".to_string(),
            content_count: 100,
            performance_improvement: 0.15,
            duration_ms: 5000,
            success: true,
            error_message: None,
            metadata: Some(json!({"model": "test-model"})),
            timestamp: Utc::now() - Duration::hours(2),
        },
        OptimizationAnalyticsData {
            optimization_type: "association_refinement".to_string(),
            content_count: 50,
            performance_improvement: 0.08,
            duration_ms: 3000,
            success: true,
            error_message: None,
            metadata: Some(json!({"threshold": 0.7})),
            timestamp: Utc::now() - Duration::hours(1),
        },
        OptimizationAnalyticsData {
            optimization_type: "geometry_optimization".to_string(),
            content_count: 200,
            performance_improvement: 0.25,
            duration_ms: 8000,
            success: false,
            error_message: Some("Optimization failed due to invalid parameters".to_string()),
            metadata: Some(json!({"algorithm": "differential-geometry"})),
            timestamp: Utc::now(),
        },
    ]
}

/// Test helper to create sample knowledge metrics data
fn create_sample_knowledge_metrics() -> Vec<KnowledgeMetricsData> {
    vec![
        KnowledgeMetricsData {
            metric_name: "ingestion_rate".to_string(),
            metric_value: 25.5,
            metric_unit: Some("items_per_hour".to_string()),
            time_period: "hourly".to_string(),
            period_start: Utc::now() - Duration::hours(1),
            period_end: Utc::now(),
            metadata: Some(json!({"content_types": ["document", "code"]})),
        },
        KnowledgeMetricsData {
            metric_name: "search_performance".to_string(),
            metric_value: 85.2,
            metric_unit: Some("percentage".to_string()),
            time_period: "daily".to_string(),
            period_start: Utc::now() - Duration::days(1),
            period_end: Utc::now(),
            metadata: Some(json!({"avg_response_time": 75})),
        },
        KnowledgeMetricsData {
            metric_name: "optimization_effectiveness".to_string(),
            metric_value: 0.78,
            metric_unit: Some("ratio".to_string()),
            time_period: "weekly".to_string(),
            period_start: Utc::now() - Duration::weeks(1),
            period_end: Utc::now(),
            metadata: Some(json!({"success_rate": 0.92})),
        },
    ]
}

#[cfg(test)]
mod analytics_collector_tests {
    use super::*;

    #[test]
    fn test_analytics_collector_creation() {
        let config = AnalyticsConfig::from_json(TEST_CONFIG).unwrap();
        let collector = AnalyticsCollector::new(config);
        
        assert_eq!(collector.config.collection_interval_seconds, 60);
        assert_eq!(collector.config.retention_days, 30);
        assert_eq!(collector.config.batch_size, 100);
    }

    #[test]
    fn test_analytics_collector_with_default_config() {
        let collector = AnalyticsCollector::default();
        
        assert_eq!(collector.config.collection_interval_seconds, 300); // 5 minutes default
        assert_eq!(collector.config.retention_days, 90); // 90 days default
        assert_eq!(collector.config.batch_size, 50); // 50 items default
    }

    #[test]
    fn test_collect_query_analytics() {
        let collector = AnalyticsCollector::default();
        let query_data = QueryAnalyticsData {
            query_text: "test query".to_string(),
            query_context: Some(json!({"project": "test"})),
            result_count: 5,
            response_time_ms: 100,
            user_satisfaction_score: Some(0.8),
            optimization_impact: Some(0.1),
            timestamp: Utc::now(),
        };

        let result = collector.collect_query_analytics(query_data);
        assert!(result.is_ok());
    }

    #[test]
    fn test_collect_optimization_analytics() {
        let collector = AnalyticsCollector::default();
        let optimization_data = OptimizationAnalyticsData {
            optimization_type: "embedding_update".to_string(),
            content_count: 100,
            performance_improvement: 0.15,
            duration_ms: 5000,
            success: true,
            error_message: None,
            metadata: Some(json!({"model": "test"})),
            timestamp: Utc::now(),
        };

        let result = collector.collect_optimization_analytics(optimization_data);
        assert!(result.is_ok());
    }

    #[test]
    fn test_collect_knowledge_metrics() {
        let collector = AnalyticsCollector::default();
        let metrics_data = KnowledgeMetricsData {
            metric_name: "ingestion_rate".to_string(),
            metric_value: 25.5,
            metric_unit: Some("items_per_hour".to_string()),
            time_period: "hourly".to_string(),
            period_start: Utc::now() - Duration::hours(1),
            period_end: Utc::now(),
            metadata: Some(json!({"content_types": ["document"]})),
        };

        let result = collector.collect_knowledge_metrics(metrics_data);
        assert!(result.is_ok());
    }

    #[test]
    fn test_batch_collection() {
        let collector = AnalyticsCollector::default();
        let query_data = create_sample_query_analytics();
        let optimization_data = create_sample_optimization_analytics();
        let metrics_data = create_sample_knowledge_metrics();

        // Test batch collection
        let result = collector.collect_batch_analytics(query_data, optimization_data, metrics_data);
        assert!(result.is_ok());
    }

    #[test]
    fn test_analytics_collector_thread_safety() {
        use std::sync::Arc;
        use std::thread;
        use std::sync::mpsc;

        let collector = Arc::new(AnalyticsCollector::default());
        let (tx, rx) = mpsc::channel();

        // Spawn multiple threads to test concurrent collection
        for i in 0..5 {
            let collector_clone = Arc::clone(&collector);
            let tx_clone = tx.clone();
            
            thread::spawn(move || {
                let query_data = QueryAnalyticsData {
                    query_text: format!("query from thread {}", i),
                    query_context: Some(json!({"thread": i})),
                    result_count: i,
                    response_time_ms: 50 + i * 10,
                    user_satisfaction_score: Some(0.8),
                    optimization_impact: Some(0.1),
                    timestamp: Utc::now(),
                };

                let result = collector_clone.collect_query_analytics(query_data);
                tx_clone.send(result).unwrap();
            });
        }

        // Collect results
        for _ in 0..5 {
            let result = rx.recv().unwrap();
            assert!(result.is_ok());
        }
    }
}

#[cfg(test)]
mod performance_trend_analysis_tests {
    use super::*;

    #[test]
    fn test_performance_trend_analysis_creation() {
        let analyzer = PerformanceTrendAnalyzer::new();
        assert!(analyzer.is_ok());
    }

    #[test]
    fn test_analyze_response_time_trends() {
        let analyzer = PerformanceTrendAnalyzer::new().unwrap();
        let query_data = create_sample_query_analytics();
        
        let trends = analyzer.analyze_response_time_trends(&query_data);
        assert!(trends.is_ok());
        
        let trends = trends.unwrap();
        assert!(trends.average_response_time > 0.0);
        assert!(trends.trend_direction.is_some());
    }

    #[test]
    fn test_analyze_user_satisfaction_trends() {
        let analyzer = PerformanceTrendAnalyzer::new().unwrap();
        let query_data = create_sample_query_analytics();
        
        let trends = analyzer.analyze_user_satisfaction_trends(&query_data);
        assert!(trends.is_ok());
        
        let trends = trends.unwrap();
        assert!(trends.average_satisfaction >= 0.0 && trends.average_satisfaction <= 1.0);
        assert!(trends.trend_direction.is_some());
    }

    #[test]
    fn test_analyze_optimization_effectiveness() {
        let analyzer = PerformanceTrendAnalyzer::new().unwrap();
        let optimization_data = create_sample_optimization_analytics();
        
        let effectiveness = analyzer.analyze_optimization_effectiveness(&optimization_data);
        assert!(effectiveness.is_ok());
        
        let effectiveness = effectiveness.unwrap();
        assert!(effectiveness.success_rate >= 0.0 && effectiveness.success_rate <= 1.0);
        assert!(effectiveness.average_improvement.is_some());
    }

    #[test]
    fn test_detect_performance_anomalies() {
        let analyzer = PerformanceTrendAnalyzer::new().unwrap();
        let query_data = create_sample_query_analytics();
        
        let anomalies = analyzer.detect_performance_anomalies(&query_data);
        assert!(anomalies.is_ok());
        
        let anomalies = anomalies.unwrap();
        // Should detect the slow query (120ms) as an anomaly
        assert!(!anomalies.is_empty());
    }

    #[test]
    fn test_generate_performance_report() {
        let analyzer = PerformanceTrendAnalyzer::new().unwrap();
        let query_data = create_sample_query_analytics();
        let optimization_data = create_sample_optimization_analytics();
        
        let report = analyzer.generate_performance_report(&query_data, &optimization_data);
        assert!(report.is_ok());
        
        let report = report.unwrap();
        assert!(!report.summary.is_empty());
        assert!(report.recommendations.len() > 0);
    }
}

#[cfg(test)]
mod optimization_effectiveness_tests {
    use super::*;

    #[test]
    fn test_optimization_effectiveness_analyzer_creation() {
        let analyzer = OptimizationEffectivenessAnalyzer::new();
        assert!(analyzer.is_ok());
    }

    #[test]
    fn test_measure_optimization_impact() {
        let analyzer = OptimizationEffectivenessAnalyzer::new().unwrap();
        let optimization_data = create_sample_optimization_analytics();
        
        let impact = analyzer.measure_optimization_impact(&optimization_data);
        assert!(impact.is_ok());
        
        let impact = impact.unwrap();
        assert!(impact.overall_effectiveness >= 0.0);
        assert!(impact.success_rate >= 0.0 && impact.success_rate <= 1.0);
    }

    #[test]
    fn test_analyze_optimization_trends() {
        let analyzer = OptimizationEffectivenessAnalyzer::new().unwrap();
        let optimization_data = create_sample_optimization_analytics();
        
        let trends = analyzer.analyze_optimization_trends(&optimization_data);
        assert!(trends.is_ok());
        
        let trends = trends.unwrap();
        assert!(trends.trend_direction.is_some());
        assert!(trends.consistency_score >= 0.0 && trends.consistency_score <= 1.0);
    }

    #[test]
    fn test_identify_optimization_opportunities() {
        let analyzer = OptimizationEffectivenessAnalyzer::new().unwrap();
        let optimization_data = create_sample_optimization_analytics();
        let query_data = create_sample_query_analytics();
        
        let opportunities = analyzer.identify_optimization_opportunities(&optimization_data, &query_data);
        assert!(opportunities.is_ok());
        
        let opportunities = opportunities.unwrap();
        assert!(!opportunities.is_empty());
    }

    #[test]
    fn test_generate_optimization_recommendations() {
        let analyzer = OptimizationEffectivenessAnalyzer::new().unwrap();
        let optimization_data = create_sample_optimization_analytics();
        let query_data = create_sample_query_analytics();
        
        let recommendations = analyzer.generate_optimization_recommendations(&optimization_data, &query_data);
        assert!(recommendations.is_ok());
        
        let recommendations = recommendations.unwrap();
        assert!(!recommendations.is_empty());
        
        for recommendation in recommendations {
            assert!(!recommendation.description.is_empty());
            assert!(recommendation.priority >= 1 && recommendation.priority <= 5);
        }
    }
}

#[cfg(test)]
mod real_time_monitoring_tests {
    use super::*;

    #[test]
    fn test_real_time_monitor_creation() {
        let monitor = RealTimeMonitor::new();
        assert!(monitor.is_ok());
    }

    #[test]
    fn test_start_monitoring() {
        let monitor = RealTimeMonitor::new().unwrap();
        let result = monitor.start_monitoring();
        assert!(result.is_ok());
    }

    #[test]
    fn test_stop_monitoring() {
        let monitor = RealTimeMonitor::new().unwrap();
        monitor.start_monitoring().unwrap();
        let result = monitor.stop_monitoring();
        assert!(result.is_ok());
    }

    #[test]
    fn test_get_current_metrics() {
        let monitor = RealTimeMonitor::new().unwrap();
        monitor.start_monitoring().unwrap();
        
        let metrics = monitor.get_current_metrics();
        assert!(metrics.is_ok());
        
        let metrics = metrics.unwrap();
        assert!(metrics.is_some());
    }

    #[test]
    fn test_set_alert_thresholds() {
        let monitor = RealTimeMonitor::new().unwrap();
        let thresholds = AlertThresholds {
            response_time_ms: 100,
            error_rate: 0.05,
            optimization_effectiveness: 0.8,
        };
        
        let result = monitor.set_alert_thresholds(thresholds);
        assert!(result.is_ok());
    }

    #[test]
    fn test_check_alerts() {
        let monitor = RealTimeMonitor::new().unwrap();
        monitor.start_monitoring().unwrap();
        
        let alerts = monitor.check_alerts();
        assert!(alerts.is_ok());
        
        let alerts = alerts.unwrap();
        // Should be empty initially
        assert!(alerts.is_empty());
    }
}

#[cfg(test)]
mod historical_analysis_tests {
    use super::*;

    #[test]
    fn test_historical_analyzer_creation() {
        let analyzer = HistoricalAnalyzer::new();
        assert!(analyzer.is_ok());
    }

    #[test]
    fn test_analyze_historical_trends() {
        let analyzer = HistoricalAnalyzer::new().unwrap();
        let query_data = create_sample_query_analytics();
        let optimization_data = create_sample_optimization_analytics();
        
        let trends = analyzer.analyze_historical_trends(&query_data, &optimization_data);
        assert!(trends.is_ok());
        
        let trends = trends.unwrap();
        assert!(!trends.is_empty());
    }

    #[test]
    fn test_generate_historical_report() {
        let analyzer = HistoricalAnalyzer::new().unwrap();
        let query_data = create_sample_query_analytics();
        let optimization_data = create_sample_optimization_analytics();
        let metrics_data = create_sample_knowledge_metrics();
        
        let report = analyzer.generate_historical_report(&query_data, &optimization_data, &metrics_data);
        assert!(report.is_ok());
        
        let report = report.unwrap();
        assert!(!report.summary.is_empty());
        assert!(report.charts.len() > 0);
    }

    #[test]
    fn test_identify_seasonal_patterns() {
        let analyzer = HistoricalAnalyzer::new().unwrap();
        let query_data = create_sample_query_analytics();
        
        let patterns = analyzer.identify_seasonal_patterns(&query_data);
        assert!(patterns.is_ok());
        
        let patterns = patterns.unwrap();
        // Should be empty with small sample data
        assert!(patterns.is_empty());
    }
}

#[cfg(test)]
mod data_retention_tests {
    use super::*;

    #[test]
    fn test_data_retention_manager_creation() {
        let manager = DataRetentionManager::new();
        assert!(manager.is_ok());
    }

    #[test]
    fn test_cleanup_old_data() {
        let manager = DataRetentionManager::new().unwrap();
        let result = manager.cleanup_old_data();
        assert!(result.is_ok());
    }

    #[test]
    fn test_set_retention_policies() {
        let manager = DataRetentionManager::new().unwrap();
        let policies = RetentionPolicies {
            query_analytics_days: 30,
            optimization_history_days: 90,
            knowledge_metrics_days: 365,
        };
        
        let result = manager.set_retention_policies(policies);
        assert!(result.is_ok());
    }

    #[test]
    fn test_get_retention_stats() {
        let manager = DataRetentionManager::new().unwrap();
        let stats = manager.get_retention_stats();
        assert!(stats.is_ok());
        
        let stats = stats.unwrap();
        assert!(stats.total_records >= 0);
    }
}

#[cfg(test)]
mod integration_tests {
    use super::*;

    #[test]
    fn test_full_analytics_workflow() {
        // Create analytics collector
        let collector = AnalyticsCollector::default();
        
        // Create analyzers
        let performance_analyzer = PerformanceTrendAnalyzer::new().unwrap();
        let optimization_analyzer = OptimizationEffectivenessAnalyzer::new().unwrap();
        let historical_analyzer = HistoricalAnalyzer::new().unwrap();
        
        // Create real-time monitor
        let monitor = RealTimeMonitor::new().unwrap();
        
        // Create data retention manager
        let retention_manager = DataRetentionManager::new().unwrap();
        
        // Collect sample data
        let query_data = create_sample_query_analytics();
        let optimization_data = create_sample_optimization_analytics();
        let metrics_data = create_sample_knowledge_metrics();
        
        // Test full workflow
        let batch_result = collector.collect_batch_analytics(
            query_data.clone(),
            optimization_data.clone(),
            metrics_data.clone(),
        );
        assert!(batch_result.is_ok());
        
        // Analyze performance trends
        let performance_trends = performance_analyzer.analyze_response_time_trends(&query_data);
        assert!(performance_trends.is_ok());
        
        // Analyze optimization effectiveness
        let optimization_effectiveness = optimization_analyzer.measure_optimization_impact(&optimization_data);
        assert!(optimization_effectiveness.is_ok());
        
        // Generate historical report
        let historical_report = historical_analyzer.generate_historical_report(
            &query_data,
            &optimization_data,
            &metrics_data,
        );
        assert!(historical_report.is_ok());
        
        // Start real-time monitoring
        let monitor_result = monitor.start_monitoring();
        assert!(monitor_result.is_ok());
        
        // Get current metrics
        let current_metrics = monitor.get_current_metrics();
        assert!(current_metrics.is_ok());
        
        // Test data retention
        let retention_stats = retention_manager.get_retention_stats();
        assert!(retention_stats.is_ok());
        
        // Stop monitoring
        let stop_result = monitor.stop_monitoring();
        assert!(stop_result.is_ok());
    }

    #[test]
    fn test_analytics_with_empty_data() {
        let collector = AnalyticsCollector::default();
        let performance_analyzer = PerformanceTrendAnalyzer::new().unwrap();
        let optimization_analyzer = OptimizationEffectivenessAnalyzer::new().unwrap();
        
        // Test with empty data
        let empty_query_data: Vec<QueryAnalyticsData> = vec![];
        let empty_optimization_data: Vec<OptimizationAnalyticsData> = vec![];
        let empty_metrics_data: Vec<KnowledgeMetricsData> = vec![];
        
        // Should handle empty data gracefully
        let batch_result = collector.collect_batch_analytics(
            empty_query_data.clone(),
            empty_optimization_data.clone(),
            empty_metrics_data.clone(),
        );
        assert!(batch_result.is_ok());
        
        let performance_trends = performance_analyzer.analyze_response_time_trends(&empty_query_data);
        assert!(performance_trends.is_ok());
        
        let optimization_effectiveness = optimization_analyzer.measure_optimization_impact(&empty_optimization_data);
        assert!(optimization_effectiveness.is_ok());
    }
}

/// Test helper functions for common test operations
#[cfg(test)]
pub mod test_helpers {
    use super::*;

    /// Create a test analytics collector with custom configuration
    pub fn create_test_collector() -> AnalyticsCollector {
        let config = AnalyticsConfig {
            collection_interval_seconds: 60,
            retention_days: 7, // Short retention for tests
            batch_size: 10,
            performance_thresholds: PerformanceThresholds {
                response_time_ms: 100,
                optimization_effectiveness: 0.8,
                user_satisfaction: 0.7,
            },
        };
        AnalyticsCollector::new(config)
    }

    /// Create test data with specific characteristics
    pub fn create_test_data_with_trends() -> (Vec<QueryAnalyticsData>, Vec<OptimizationAnalyticsData>) {
        let mut query_data = Vec::new();
        let mut optimization_data = Vec::new();
        
        // Create improving trend in response times
        for i in 0..10 {
            query_data.push(QueryAnalyticsData {
                query_text: format!("query_{}", i),
                query_context: Some(json!({"test": true})),
                result_count: 5,
                response_time_ms: 100 - (i * 5), // Decreasing response time
                user_satisfaction_score: Some(0.7 + (i as f64 * 0.02)), // Increasing satisfaction
                optimization_impact: Some(0.1 + (i as f64 * 0.05)), // Increasing impact
                timestamp: Utc::now() - Duration::hours(10 - i as i64),
            });
        }
        
        // Create successful optimization trend
        for i in 0..5 {
            optimization_data.push(OptimizationAnalyticsData {
                optimization_type: "embedding_update".to_string(),
                content_count: 100 + (i * 20),
                performance_improvement: 0.1 + (i as f64 * 0.05), // Increasing improvement
                duration_ms: 5000,
                success: true,
                error_message: None,
                metadata: Some(json!({"iteration": i})),
                timestamp: Utc::now() - Duration::hours(5 - i as i64),
            });
        }
        
        (query_data, optimization_data)
    }
}
