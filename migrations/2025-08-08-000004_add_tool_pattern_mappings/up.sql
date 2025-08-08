-- Migration: Add tool pattern mappings table
-- Created: 2025-08-08

-- Create tool_pattern_mappings table
CREATE TABLE tool_pattern_mappings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tool_name VARCHAR(255) NOT NULL,
    pattern_id UUID NOT NULL REFERENCES system_patterns(id) ON DELETE CASCADE,
    mapping_type VARCHAR(100) NOT NULL,
    usage_frequency INTEGER DEFAULT 0,
    success_rate FLOAT DEFAULT 0.0,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_tool_pattern_mappings_tool_name ON tool_pattern_mappings(tool_name);
CREATE INDEX idx_tool_pattern_mappings_pattern_id ON tool_pattern_mappings(pattern_id);
CREATE INDEX idx_tool_pattern_mappings_mapping_type ON tool_pattern_mappings(mapping_type);
CREATE INDEX idx_tool_pattern_mappings_usage_frequency ON tool_pattern_mappings(usage_frequency);
CREATE INDEX idx_tool_pattern_mappings_success_rate ON tool_pattern_mappings(success_rate);
CREATE INDEX idx_tool_pattern_mappings_created_at ON tool_pattern_mappings(created_at);

-- Add unique constraint to prevent duplicate mappings
CREATE UNIQUE INDEX idx_tool_pattern_mappings_unique ON tool_pattern_mappings(tool_name, pattern_id, mapping_type);

-- Add comments for documentation
COMMENT ON TABLE tool_pattern_mappings IS 'Maps MCP tools to system patterns for intelligent tool usage';
COMMENT ON COLUMN tool_pattern_mappings.tool_name IS 'Name of the MCP tool';
COMMENT ON COLUMN tool_pattern_mappings.pattern_id IS 'Reference to the system pattern';
COMMENT ON COLUMN tool_pattern_mappings.mapping_type IS 'Type of mapping (e.g., input, output, trigger, enhance)';
COMMENT ON COLUMN tool_pattern_mappings.usage_frequency IS 'How often this tool is used with this pattern';
COMMENT ON COLUMN tool_pattern_mappings.success_rate IS 'Success rate of this tool-pattern combination (0.0 to 1.0)';
COMMENT ON COLUMN tool_pattern_mappings.metadata IS 'Additional metadata about the tool-pattern relationship';
