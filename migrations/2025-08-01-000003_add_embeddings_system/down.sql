-- Migration: Remove embeddings system
-- Created: 2025-08-01

-- Drop indexes
DROP INDEX IF EXISTS idx_embeddings_metadata;
DROP INDEX IF EXISTS idx_embeddings_content_lookup;
DROP INDEX IF EXISTS idx_embeddings_vector;
DROP INDEX IF EXISTS idx_embeddings_model;
DROP INDEX IF EXISTS idx_embeddings_content_id;
DROP INDEX IF EXISTS idx_embeddings_content_type;

-- Drop embeddings table
DROP TABLE IF EXISTS embeddings;

-- Note: We don't drop the pgvector extension as it might be used by other parts of the system 