-- Migration: Remove pattern executions table
-- Created: 2025-08-08

-- Drop indexes first
DROP INDEX IF EXISTS idx_pattern_executions_created_at;
DROP INDEX IF EXISTS idx_pattern_executions_started_at;
DROP INDEX IF EXISTS idx_pattern_executions_execution_status;
DROP INDEX IF EXISTS idx_pattern_executions_session_id;
DROP INDEX IF EXISTS idx_pattern_executions_pattern_id;

-- Drop the pattern_executions table
DROP TABLE IF EXISTS pattern_executions;
