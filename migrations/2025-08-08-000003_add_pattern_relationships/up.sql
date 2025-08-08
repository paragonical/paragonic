-- Migration: Add pattern relationships table
-- Created: 2025-08-08

-- Create pattern_relationships table
CREATE TABLE pattern_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_pattern_id UUID NOT NULL REFERENCES system_patterns(id) ON DELETE CASCADE,
    target_pattern_id UUID NOT NULL REFERENCES system_patterns(id) ON DELETE CASCADE,
    relationship_type VARCHAR(100) NOT NULL,
    relationship_strength FLOAT DEFAULT 1.0,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_pattern_relationships_source_pattern_id ON pattern_relationships(source_pattern_id);
CREATE INDEX idx_pattern_relationships_target_pattern_id ON pattern_relationships(target_pattern_id);
CREATE INDEX idx_pattern_relationships_relationship_type ON pattern_relationships(relationship_type);
CREATE INDEX idx_pattern_relationships_created_at ON pattern_relationships(created_at);

-- Add unique constraint to prevent duplicate relationships
CREATE UNIQUE INDEX idx_pattern_relationships_unique ON pattern_relationships(source_pattern_id, target_pattern_id, relationship_type);

-- Add comments for documentation
COMMENT ON TABLE pattern_relationships IS 'Defines relationships between system patterns';
COMMENT ON COLUMN pattern_relationships.source_pattern_id IS 'The source pattern in the relationship';
COMMENT ON COLUMN pattern_relationships.target_pattern_id IS 'The target pattern in the relationship';
COMMENT ON COLUMN pattern_relationships.relationship_type IS 'Type of relationship (e.g., depends_on, triggers, enhances)';
COMMENT ON COLUMN pattern_relationships.relationship_strength IS 'Strength of the relationship (0.0 to 1.0)';
COMMENT ON COLUMN pattern_relationships.metadata IS 'Additional metadata about the relationship';
