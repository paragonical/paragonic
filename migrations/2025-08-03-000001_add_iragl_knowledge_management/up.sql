-- Migration: Add IRAGL Knowledge Management System
-- Created: 2025-08-03

-- Ensure pgvector extension is available
CREATE EXTENSION IF NOT EXISTS vector;

-- Create knowledge_streams table for storing ingested content
CREATE TABLE knowledge_streams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_type VARCHAR(50) NOT NULL, -- 'communication', 'document', 'code', 'conversation'
    content_text TEXT NOT NULL,
    source_entity_type VARCHAR(50) NOT NULL, -- 'organization', 'project', 'operation', 'agent'
    source_entity_id UUID NOT NULL,
    metadata JSONB DEFAULT '{}',
    embedding_vector VECTOR(1536), -- Using standard embedding dimension
    embedding_model VARCHAR(100) NOT NULL,
    optimization_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'optimized', 'failed'
    optimization_score FLOAT DEFAULT 0.0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_knowledge_streams_content_type ON knowledge_streams(content_type);
CREATE INDEX idx_knowledge_streams_source_entity ON knowledge_streams(source_entity_type, source_entity_id);
CREATE INDEX idx_knowledge_streams_optimization_status ON knowledge_streams(optimization_status);
CREATE INDEX idx_knowledge_streams_created_at ON knowledge_streams(created_at);
CREATE INDEX idx_knowledge_streams_embedding_vector ON knowledge_streams USING ivfflat (embedding_vector vector_cosine_ops);

-- Create content_associations table for linking content to organizational entities
CREATE TABLE content_associations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id UUID NOT NULL REFERENCES knowledge_streams(id) ON DELETE CASCADE,
    entity_type VARCHAR(50) NOT NULL, -- 'organization', 'project', 'operation', 'goal', 'task'
    entity_id UUID NOT NULL,
    association_strength FLOAT DEFAULT 1.0, -- 0.0 to 1.0, where 1.0 is strongest
    association_type VARCHAR(50) DEFAULT 'direct', -- 'direct', 'derived', 'inferred'
    confidence_score FLOAT DEFAULT 1.0, -- Confidence in the association
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure unique associations
    UNIQUE(content_id, entity_type, entity_id)
);

-- Create indexes for performance
CREATE INDEX idx_content_associations_content_id ON content_associations(content_id);
CREATE INDEX idx_content_associations_entity ON content_associations(entity_type, entity_id);
CREATE INDEX idx_content_associations_strength ON content_associations(association_strength);

-- Create optimization_history table for tracking optimization runs
CREATE TABLE optimization_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    optimization_type VARCHAR(50) NOT NULL, -- 'embedding_update', 'association_refinement', 'geometry_optimization'
    content_count INTEGER NOT NULL,
    performance_improvement FLOAT, -- Percentage improvement in search performance
    duration_ms INTEGER NOT NULL,
    success BOOLEAN DEFAULT true,
    error_message TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_optimization_history_type ON optimization_history(optimization_type);
CREATE INDEX idx_optimization_history_created_at ON optimization_history(created_at);
CREATE INDEX idx_optimization_history_success ON optimization_history(success);

-- Create query_analytics table for tracking search queries
CREATE TABLE query_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    query_text TEXT NOT NULL,
    query_context JSONB DEFAULT '{}', -- Organizational context, filters, etc.
    result_count INTEGER NOT NULL,
    response_time_ms INTEGER NOT NULL,
    user_satisfaction_score FLOAT, -- Optional user feedback score
    optimization_impact FLOAT, -- How much optimization affected this query
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_query_analytics_created_at ON query_analytics(created_at);
CREATE INDEX idx_query_analytics_response_time ON query_analytics(response_time_ms);

-- Create knowledge_metrics table for aggregated metrics
CREATE TABLE knowledge_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_name VARCHAR(100) NOT NULL, -- 'ingestion_rate', 'search_performance', 'optimization_effectiveness'
    metric_value FLOAT NOT NULL,
    metric_unit VARCHAR(20), -- 'items_per_hour', 'milliseconds', 'percentage'
    time_period VARCHAR(20) NOT NULL, -- 'hourly', 'daily', 'weekly'
    period_start TIMESTAMPTZ NOT NULL,
    period_end TIMESTAMPTZ NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure unique metrics per time period
    UNIQUE(metric_name, time_period, period_start)
);

-- Create indexes for performance
CREATE INDEX idx_knowledge_metrics_name ON knowledge_metrics(metric_name);
CREATE INDEX idx_knowledge_metrics_period ON knowledge_metrics(time_period, period_start);

-- Add check constraints for data integrity
ALTER TABLE content_associations ADD CONSTRAINT chk_association_strength 
    CHECK (association_strength >= 0.0 AND association_strength <= 1.0);

ALTER TABLE content_associations ADD CONSTRAINT chk_confidence_score 
    CHECK (confidence_score >= 0.0 AND confidence_score <= 1.0);

ALTER TABLE knowledge_streams ADD CONSTRAINT chk_optimization_status 
    CHECK (optimization_status IN ('pending', 'optimized', 'failed'));

ALTER TABLE optimization_history ADD CONSTRAINT chk_performance_improvement 
    CHECK (performance_improvement >= -100.0 AND performance_improvement <= 1000.0);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for automatic updated_at updates
CREATE TRIGGER update_knowledge_streams_updated_at 
    BEFORE UPDATE ON knowledge_streams 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_content_associations_updated_at 
    BEFORE UPDATE ON content_associations 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Add comments for documentation
COMMENT ON TABLE knowledge_streams IS 'Stores ingested content from organizational activities with embeddings and optimization status';
COMMENT ON TABLE content_associations IS 'Links content to organizational entities with association strengths and confidence scores';
COMMENT ON TABLE optimization_history IS 'Tracks optimization runs and their effectiveness for continuous improvement';
COMMENT ON TABLE query_analytics IS 'Tracks search queries and their performance for optimization feedback';
COMMENT ON TABLE knowledge_metrics IS 'Stores aggregated metrics for system performance monitoring'; 