-- Migration: Add system patterns table
-- Created: 2025-08-08

-- Create system_patterns table
CREATE TABLE system_patterns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    pattern_type VARCHAR(100) NOT NULL,
    template_content TEXT NOT NULL,
    execution_conditions JSONB,
    metadata JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_system_patterns_name ON system_patterns(name);
CREATE INDEX idx_system_patterns_pattern_type ON system_patterns(pattern_type);
CREATE INDEX idx_system_patterns_is_active ON system_patterns(is_active);
CREATE INDEX idx_system_patterns_created_at ON system_patterns(created_at);

-- Add comments for documentation
COMMENT ON TABLE system_patterns IS 'Stores system patterns for AI agent self-awareness and session management';
COMMENT ON COLUMN system_patterns.name IS 'Unique name identifier for the pattern';
COMMENT ON COLUMN system_patterns.description IS 'Human-readable description of the pattern purpose';
COMMENT ON COLUMN system_patterns.pattern_type IS 'Type of pattern (e.g., session_summary, activity_labeling, self_reflection)';
COMMENT ON COLUMN system_patterns.template_content IS 'Template content for pattern execution';
COMMENT ON COLUMN system_patterns.execution_conditions IS 'JSON conditions that determine when this pattern should be executed';
COMMENT ON COLUMN system_patterns.metadata IS 'Additional metadata for the pattern';
COMMENT ON COLUMN system_patterns.is_active IS 'Whether this pattern is currently active and available for execution';
