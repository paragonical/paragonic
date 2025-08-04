# Database Schema

This is the database schema implementation for the spec detailed in @.agent-os/specs/2025-08-03-iragl-knowledge-management/spec.md

> Created: 2025-08-03
> Version: 1.0.0

## Schema Changes

### New Tables

#### 1. knowledge_streams
Stores all ingested content with embeddings and metadata.

```sql
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

-- Indexes for performance
CREATE INDEX idx_knowledge_streams_content_type ON knowledge_streams(content_type);
CREATE INDEX idx_knowledge_streams_source_entity ON knowledge_streams(source_entity_type, source_entity_id);
CREATE INDEX idx_knowledge_streams_optimization_status ON knowledge_streams(optimization_status);
CREATE INDEX idx_knowledge_streams_created_at ON knowledge_streams(created_at);
CREATE INDEX idx_knowledge_streams_embedding_vector ON knowledge_streams USING ivfflat (embedding_vector vector_cosine_ops);
```

#### 2. content_associations
Links content to organizational entities with association strengths.

```sql
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

-- Indexes for performance
CREATE INDEX idx_content_associations_content_id ON content_associations(content_id);
CREATE INDEX idx_content_associations_entity ON content_associations(entity_type, entity_id);
CREATE INDEX idx_content_associations_strength ON content_associations(association_strength);
```

#### 3. optimization_history
Tracks optimization runs and their effectiveness.

```sql
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

-- Indexes for performance
CREATE INDEX idx_optimization_history_type ON optimization_history(optimization_type);
CREATE INDEX idx_optimization_history_created_at ON optimization_history(created_at);
CREATE INDEX idx_optimization_history_success ON optimization_history(success);
```

#### 4. query_analytics
Tracks search queries and their performance for optimization feedback.

```sql
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

-- Indexes for performance
CREATE INDEX idx_query_analytics_created_at ON query_analytics(created_at);
CREATE INDEX idx_query_analytics_response_time ON query_analytics(response_time_ms);
```

#### 5. knowledge_metrics
Stores aggregated metrics for system performance monitoring.

```sql
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

-- Indexes for performance
CREATE INDEX idx_knowledge_metrics_name ON knowledge_metrics(metric_name);
CREATE INDEX idx_knowledge_metrics_period ON knowledge_metrics(time_period, period_start);
```

### Modifications to Existing Tables

#### Extend embeddings table (if exists)
If the current embeddings table exists, we'll extend it to support the new IRAGL functionality:

```sql
-- Add new columns to existing embeddings table
ALTER TABLE embeddings ADD COLUMN IF NOT EXISTS optimization_status VARCHAR(20) DEFAULT 'pending';
ALTER TABLE embeddings ADD COLUMN IF NOT EXISTS optimization_score FLOAT DEFAULT 0.0;
ALTER TABLE embeddings ADD COLUMN IF NOT EXISTS association_count INTEGER DEFAULT 0;
```

## Data Integrity Rules

### Foreign Key Constraints
- `content_associations.content_id` references `knowledge_streams.id` with CASCADE delete
- `content_associations.entity_id` should reference valid entities in respective tables (organizations, projects, etc.)

### Check Constraints
```sql
-- Ensure association strength is between 0 and 1
ALTER TABLE content_associations ADD CONSTRAINT chk_association_strength 
    CHECK (association_strength >= 0.0 AND association_strength <= 1.0);

-- Ensure confidence score is between 0 and 1
ALTER TABLE content_associations ADD CONSTRAINT chk_confidence_score 
    CHECK (confidence_score >= 0.0 AND confidence_score <= 1.0);

-- Ensure optimization status is valid
ALTER TABLE knowledge_streams ADD CONSTRAINT chk_optimization_status 
    CHECK (optimization_status IN ('pending', 'optimized', 'failed'));

-- Ensure performance improvement is reasonable
ALTER TABLE optimization_history ADD CONSTRAINT chk_performance_improvement 
    CHECK (performance_improvement >= -100.0 AND performance_improvement <= 1000.0);
```

### Triggers for Data Consistency

```sql
-- Update updated_at timestamp on content changes
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_knowledge_streams_updated_at 
    BEFORE UPDATE ON knowledge_streams 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_content_associations_updated_at 
    BEFORE UPDATE ON content_associations 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

## Performance Considerations

### Partitioning Strategy
For large deployments, consider partitioning `knowledge_streams` by `content_type` and `query_analytics` by date:

```sql
-- Example partitioning for knowledge_streams (if needed for very large datasets)
CREATE TABLE knowledge_streams_communications PARTITION OF knowledge_streams
    FOR VALUES IN ('communication');

CREATE TABLE knowledge_streams_documents PARTITION OF knowledge_streams
    FOR VALUES IN ('document');
```

### Query Optimization
- Vector similarity search uses IVFFlat index for efficient approximate nearest neighbor search
- Composite indexes support common query patterns
- Regular VACUUM and ANALYZE for optimal performance

## Migration Strategy

### Phase 1: Schema Creation
1. Create new tables with proper indexes
2. Add constraints and triggers
3. Test with sample data

### Phase 2: Data Migration
1. Migrate existing embeddings to new schema (if applicable)
2. Create initial content associations
3. Validate data integrity

### Phase 3: Optimization
1. Create initial optimization history
2. Set up metrics collection
3. Begin continuous optimization processes

## Backup and Recovery

### Backup Strategy
- Regular PostgreSQL backups including vector data
- Separate backup for optimization history and analytics
- Point-in-time recovery capability

### Recovery Procedures
- Vector index rebuilding after restore
- Optimization history reconstruction
- Metrics recalculation if needed 