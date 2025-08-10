-- Migration: Update ai_agent_sessions table with pattern fields
-- Created: 2025-08-08

-- First, create the ai_agent_sessions table if it doesn't exist
CREATE TABLE IF NOT EXISTS ai_agent_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_name VARCHAR(255),
    session_type VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add pattern-related columns to ai_agent_sessions table
ALTER TABLE ai_agent_sessions 
ADD COLUMN IF NOT EXISTS active_patterns JSONB DEFAULT '[]',
ADD COLUMN IF NOT EXISTS pattern_execution_history JSONB DEFAULT '[]',
ADD COLUMN IF NOT EXISTS last_pattern_execution TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS pattern_learning_enabled BOOLEAN DEFAULT true;

-- Create indexes for the new pattern-related columns
CREATE INDEX IF NOT EXISTS idx_ai_agent_sessions_active_patterns ON ai_agent_sessions USING GIN (active_patterns);
CREATE INDEX IF NOT EXISTS idx_ai_agent_sessions_pattern_execution_history ON ai_agent_sessions USING GIN (pattern_execution_history);
CREATE INDEX IF NOT EXISTS idx_ai_agent_sessions_last_pattern_execution ON ai_agent_sessions(last_pattern_execution);
CREATE INDEX IF NOT EXISTS idx_ai_agent_sessions_pattern_learning_enabled ON ai_agent_sessions(pattern_learning_enabled);

-- Add comments for documentation
COMMENT ON COLUMN ai_agent_sessions.active_patterns IS 'JSON array of currently active pattern IDs for this session';
COMMENT ON COLUMN ai_agent_sessions.pattern_execution_history IS 'JSON array of pattern execution history for this session';
COMMENT ON COLUMN ai_agent_sessions.last_pattern_execution IS 'Timestamp of the last pattern execution in this session';
COMMENT ON COLUMN ai_agent_sessions.pattern_learning_enabled IS 'Whether pattern learning is enabled for this session';
