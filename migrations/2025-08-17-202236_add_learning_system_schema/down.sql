-- Learning System Schema Migration Rollback
-- This migration removes all tables added for the human skill building ISRL system

-- Remove learning fields from people table
DROP INDEX IF EXISTS idx_people_learning_stats;
DROP INDEX IF EXISTS idx_people_learning_preferences;
ALTER TABLE people DROP COLUMN IF EXISTS learning_stats;
ALTER TABLE people DROP COLUMN IF EXISTS learning_preferences;

-- Drop tables in reverse order (due to foreign key constraints)
DROP TABLE IF EXISTS skill_relationships;
DROP TABLE IF EXISTS learning_analytics;
DROP TABLE IF EXISTS expertise_profiles;
DROP TABLE IF EXISTS spaced_repetition_schedules;
DROP TABLE IF EXISTS skill_assessments;
DROP TABLE IF EXISTS session_items;
DROP TABLE IF EXISTS learning_sessions;
DROP TABLE IF EXISTS practice_items;
DROP TABLE IF EXISTS skill_areas;
