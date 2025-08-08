-- Migration: Remove tool pattern mappings table
-- Created: 2025-08-08

-- Drop indexes first
DROP INDEX IF EXISTS idx_tool_pattern_mappings_unique;
DROP INDEX IF EXISTS idx_tool_pattern_mappings_created_at;
DROP INDEX IF EXISTS idx_tool_pattern_mappings_success_rate;
DROP INDEX IF EXISTS idx_tool_pattern_mappings_usage_frequency;
DROP INDEX IF EXISTS idx_tool_pattern_mappings_mapping_type;
DROP INDEX IF EXISTS idx_tool_pattern_mappings_pattern_id;
DROP INDEX IF EXISTS idx_tool_pattern_mappings_tool_name;

-- Drop the tool_pattern_mappings table
DROP TABLE IF EXISTS tool_pattern_mappings;
