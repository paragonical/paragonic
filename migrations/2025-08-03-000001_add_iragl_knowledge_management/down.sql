-- Down Migration: Remove IRAGL Knowledge Management System
-- Created: 2025-08-03

-- Drop triggers first
DROP TRIGGER IF EXISTS update_content_associations_updated_at ON content_associations;
DROP TRIGGER IF EXISTS update_knowledge_streams_updated_at ON knowledge_streams;

-- Drop function
DROP FUNCTION IF EXISTS update_updated_at_column();

-- Drop tables in reverse order (due to foreign key constraints)
DROP TABLE IF EXISTS knowledge_metrics;
DROP TABLE IF EXISTS query_analytics;
DROP TABLE IF EXISTS optimization_history;
DROP TABLE IF EXISTS content_associations;
DROP TABLE IF EXISTS knowledge_streams; 