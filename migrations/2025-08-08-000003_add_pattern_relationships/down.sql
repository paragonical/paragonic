-- Migration: Remove pattern relationships table
-- Created: 2025-08-08

-- Drop indexes first
DROP INDEX IF EXISTS idx_pattern_relationships_unique;
DROP INDEX IF EXISTS idx_pattern_relationships_created_at;
DROP INDEX IF EXISTS idx_pattern_relationships_relationship_type;
DROP INDEX IF EXISTS idx_pattern_relationships_target_pattern_id;
DROP INDEX IF EXISTS idx_pattern_relationships_source_pattern_id;

-- Drop the pattern_relationships table
DROP TABLE IF EXISTS pattern_relationships;
