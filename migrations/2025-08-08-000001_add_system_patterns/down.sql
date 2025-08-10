-- Migration: Remove system patterns table
-- Created: 2025-08-08

-- Drop indexes first
DROP INDEX IF EXISTS idx_system_patterns_created_at;
DROP INDEX IF EXISTS idx_system_patterns_is_active;
DROP INDEX IF EXISTS idx_system_patterns_pattern_type;
DROP INDEX IF EXISTS idx_system_patterns_name;

-- Drop the system_patterns table
DROP TABLE IF EXISTS system_patterns;
