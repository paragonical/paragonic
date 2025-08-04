-- Down Migration: Remove organizational structure
-- Created: 2025-08-01

-- Remove organization_id from existing tables
ALTER TABLE conversations DROP COLUMN IF EXISTS organization_id;
ALTER TABLE projects DROP COLUMN IF EXISTS organization_id;

-- Drop tables in reverse order (respecting foreign key constraints)
DROP TABLE IF EXISTS organization_hierarchies;
DROP TABLE IF EXISTS associations;
DROP TABLE IF EXISTS isrl_profiles;
DROP TABLE IF EXISTS people;
DROP TABLE IF EXISTS organizations; 