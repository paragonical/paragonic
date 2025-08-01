-- Down Migration: Drop initial schema
-- Created: 2024-12-19

-- Drop tables in reverse order (respecting foreign key constraints)
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS conversations;
DROP TABLE IF EXISTS agents;
DROP TABLE IF EXISTS tasks;
DROP TABLE IF EXISTS goals;
DROP TABLE IF EXISTS projects; 