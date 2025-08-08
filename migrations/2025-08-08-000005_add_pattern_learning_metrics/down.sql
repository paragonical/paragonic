-- Migration: Remove pattern learning metrics table
-- Created: 2025-08-08

-- Drop indexes first
DROP INDEX IF EXISTS idx_pattern_learning_metrics_unique;
DROP INDEX IF EXISTS idx_pattern_learning_metrics_created_at;
DROP INDEX IF EXISTS idx_pattern_learning_metrics_period_end;
DROP INDEX IF EXISTS idx_pattern_learning_metrics_period_start;
DROP INDEX IF EXISTS idx_pattern_learning_metrics_time_period;
DROP INDEX IF EXISTS idx_pattern_learning_metrics_metric_name;
DROP INDEX IF EXISTS idx_pattern_learning_metrics_pattern_id;

-- Drop the pattern_learning_metrics table
DROP TABLE IF EXISTS pattern_learning_metrics;
