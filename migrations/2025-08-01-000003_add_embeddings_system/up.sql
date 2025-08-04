-- Migration: Add embeddings system for semantic search and context management
-- Created: 2025-08-01

-- Enable pgvector extension for vector operations
CREATE EXTENSION IF NOT EXISTS vector;

-- Create embeddings table for storing vector representations
CREATE TABLE embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_type VARCHAR(50) NOT NULL, -- 'message', 'project', 'task', 'person', etc.
    content_id UUID NOT NULL, -- Reference to the actual content
    content_text TEXT NOT NULL, -- The text that was embedded
    embedding_model VARCHAR(100) NOT NULL, -- e.g., 'nomic-embed-text'
    embedding_vector vector(768), -- Vector representation (768 dimensions for current embedding model)
    metadata JSONB, -- Additional metadata about the embedding
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for efficient vector operations
CREATE INDEX idx_embeddings_content_type ON embeddings(content_type);
CREATE INDEX idx_embeddings_content_id ON embeddings(content_id);
CREATE INDEX idx_embeddings_model ON embeddings(embedding_model);
CREATE INDEX idx_embeddings_vector ON embeddings USING ivfflat (embedding_vector vector_cosine_ops) WITH (lists = 100);

-- Create composite index for content lookups
CREATE INDEX idx_embeddings_content_lookup ON embeddings(content_type, content_id);

-- Create index for metadata searches
CREATE INDEX idx_embeddings_metadata ON embeddings USING gin (metadata);

-- Add comments for documentation
COMMENT ON TABLE embeddings IS 'Stores vector embeddings for semantic search and context retrieval';
COMMENT ON COLUMN embeddings.content_type IS 'Type of content that was embedded (message, project, task, etc.)';
COMMENT ON COLUMN embeddings.content_id IS 'UUID reference to the actual content record';
COMMENT ON COLUMN embeddings.content_text IS 'The original text that was converted to an embedding';
COMMENT ON COLUMN embeddings.embedding_model IS 'The model used to generate the embedding';
COMMENT ON COLUMN embeddings.embedding_vector IS 'Vector representation of the text for similarity search';
COMMENT ON COLUMN embeddings.metadata IS 'Additional metadata about the embedding (tags, categories, etc.)'; 