-- Migration: Remove pattern fields from ai_agent_sessions table
-- Created: 2025-08-08

-- Drop indexes for pattern-related columns
DROP INDEX IF EXISTS idx_ai_agent_sessions_pattern_learning_enabled;
DROP INDEX IF EXISTS idx_ai_agent_sessions_last_pattern_execution;
DROP INDEX IF EXISTS idx_ai_agent_sessions_pattern_execution_history;
DROP INDEX IF EXISTS idx_ai_agent_sessions_active_patterns;

-- Remove pattern-related columns from ai_agent_sessions table
ALTER TABLE ai_agent_sessions 
DROP COLUMN IF EXISTS active_patterns,
DROP COLUMN IF EXISTS pattern_execution_history,
DROP COLUMN IF EXISTS last_pattern_execution,
DROP COLUMN IF EXISTS pattern_learning_enabled;
