# Database Schema

This is the database schema implementation for the spec detailed in @.agent-os/specs/2025-08-08-system-pattern-catalog/spec.md

> Created: 2025-08-08
> Version: 1.0.0

## Schema Changes

### New Tables

#### 1. system_patterns

```sql
CREATE TABLE system_patterns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    category VARCHAR(50) NOT NULL,
    meta_level VARCHAR(20) NOT NULL DEFAULT 'system',
    description TEXT NOT NULL,
    workflow_steps JSONB NOT NULL,
    output_format JSONB NOT NULL,
    trigger_conditions JSONB,
    success_criteria JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_system_patterns_category ON system_patterns(category);
CREATE INDEX idx_system_patterns_meta_level ON system_patterns(meta_level);
```

**Purpose:** Store system pattern definitions with their execution workflows and expected outputs.

#### 2. pattern_executions

```sql
CREATE TABLE pattern_executions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pattern_id UUID NOT NULL REFERENCES system_patterns(id) ON DELETE CASCADE,
    session_id UUID REFERENCES ai_agent_sessions(id) ON DELETE SET NULL,
    trigger_type VARCHAR(50) NOT NULL, -- 'automatic', 'manual', 'scheduled'
    input_context JSONB,
    output_result JSONB,
    execution_duration_ms INTEGER,
    success BOOLEAN NOT NULL,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_pattern_executions_pattern_id ON pattern_executions(pattern_id);
CREATE INDEX idx_pattern_executions_session_id ON pattern_executions(session_id);
CREATE INDEX idx_pattern_executions_created_at ON pattern_executions(created_at);
```

**Purpose:** Track all pattern executions with their inputs, outputs, and success metrics.

#### 3. pattern_relationships

```sql
CREATE TABLE pattern_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_pattern_id UUID NOT NULL REFERENCES system_patterns(id) ON DELETE CASCADE,
    target_pattern_id UUID NOT NULL REFERENCES system_patterns(id) ON DELETE CASCADE,
    relationship_type VARCHAR(50) NOT NULL, -- 'prerequisite', 'alternative', 'sequence', 'dependency'
    description TEXT,
    confidence_score DECIMAL(3,2) DEFAULT 0.5,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(source_pattern_id, target_pattern_id, relationship_type)
);

CREATE INDEX idx_pattern_relationships_source ON pattern_relationships(source_pattern_id);
CREATE INDEX idx_pattern_relationships_target ON pattern_relationships(target_pattern_id);
```

**Purpose:** Define relationships between patterns to help AI agents understand pattern dependencies and alternatives.

#### 4. tool_pattern_mappings

```sql
CREATE TABLE tool_pattern_mappings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tool_name VARCHAR(255) NOT NULL,
    pattern_id UUID NOT NULL REFERENCES system_patterns(id) ON DELETE CASCADE,
    usage_frequency INTEGER DEFAULT 0,
    success_rate DECIMAL(3,2) DEFAULT 0.0,
    last_used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tool_name, pattern_id)
);

CREATE INDEX idx_tool_pattern_mappings_tool ON tool_pattern_mappings(tool_name);
CREATE INDEX idx_tool_pattern_mappings_pattern ON tool_pattern_mappings(pattern_id);
```

**Purpose:** Map MCP tools to system patterns to enhance tool descriptions with pattern awareness.

#### 5. pattern_learning_metrics

```sql
CREATE TABLE pattern_learning_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pattern_id UUID NOT NULL REFERENCES system_patterns(id) ON DELETE CASCADE,
    metric_type VARCHAR(50) NOT NULL, -- 'success_rate', 'execution_time', 'user_satisfaction'
    metric_value DECIMAL(10,4) NOT NULL,
    sample_size INTEGER NOT NULL,
    confidence_interval DECIMAL(10,4),
    measured_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_pattern_learning_metrics_pattern ON pattern_learning_metrics(pattern_id);
CREATE INDEX idx_pattern_learning_metrics_type ON pattern_learning_metrics(metric_type);
```

**Purpose:** Track learning metrics for patterns to enable adaptive behavior and optimization.

### Modified Tables

#### 1. ai_agent_sessions

```sql
-- Add pattern-related fields to existing table
ALTER TABLE ai_agent_sessions ADD COLUMN activity_label VARCHAR(255);
ALTER TABLE ai_agent_sessions ADD COLUMN session_summary TEXT;
ALTER TABLE ai_agent_sessions ADD COLUMN pattern_executions_count INTEGER DEFAULT 0;
ALTER TABLE ai_agent_sessions ADD COLUMN last_pattern_execution_at TIMESTAMP WITH TIME ZONE;

CREATE INDEX idx_ai_agent_sessions_activity_label ON ai_agent_sessions(activity_label);
```

**Purpose:** Enhance session tracking with pattern-generated metadata.

## Data Integrity Rules

1. **Pattern Uniqueness**: Pattern names must be unique across the system
2. **Relationship Consistency**: Pattern relationships must reference valid patterns
3. **Execution Tracking**: All pattern executions must be tracked with success/failure status
4. **Tool Mapping**: Tool-pattern mappings must reference valid tools and patterns
5. **Learning Metrics**: Metrics must have positive sample sizes and valid confidence intervals

## Performance Considerations

1. **Indexing Strategy**: Indexes on frequently queried fields (category, session_id, created_at)
2. **JSONB Usage**: Use JSONB for flexible schema fields (workflow_steps, output_format)
3. **Partitioning**: Consider partitioning pattern_executions by date for large-scale deployments
4. **Caching**: Cache frequently accessed patterns in application memory

## Migration Strategy

1. **Phase 1**: Create new tables without foreign key constraints
2. **Phase 2**: Add foreign key constraints and indexes
3. **Phase 3**: Migrate existing session data to include pattern fields
4. **Phase 4**: Populate initial system patterns and relationships

## Initial Data Population

### Core System Patterns

```sql
-- Session Summary Generation Pattern
INSERT INTO system_patterns (name, category, description, workflow_steps, output_format) VALUES (
    'Session Summary Generation',
    'SessionManagement',
    'Create a comprehensive summary of the current session for future reference',
    '[
        {"step": 1, "action": "analyze_session_history", "description": "Analyze session history and interactions"},
        {"step": 2, "action": "extract_key_decisions", "description": "Extract key decisions and actions taken"},
        {"step": 3, "action": "identify_files_changed", "description": "Identify important files and changes made"},
        {"step": 4, "action": "summarize_goals", "description": "Summarize user goals and progress"},
        {"step": 5, "action": "generate_summary", "description": "Generate session summary document"}
    ]'::jsonb,
    '{
        "session_summary": "string",
        "key_decisions": ["string"],
        "files_modified": ["string"],
        "goals_achieved": ["string"],
        "next_steps": ["string"],
        "session_duration": "duration",
        "complexity_score": "float"
    }'::jsonb
);

-- Activity Labeling Pattern
INSERT INTO system_patterns (name, category, description, workflow_steps, output_format) VALUES (
    'One-Line Activity Description',
    'ActivityLabeling',
    'Generate a concise, descriptive label for the current session activity',
    '[
        {"step": 1, "action": "analyze_context", "description": "Analyze current session context"},
        {"step": 2, "action": "identify_activity_type", "description": "Identify primary activity type"},
        {"step": 3, "action": "extract_technologies", "description": "Extract key technologies or concepts"},
        {"step": 4, "action": "determine_scope", "description": "Determine scope and complexity"},
        {"step": 5, "action": "generate_label", "description": "Generate descriptive label"}
    ]'::jsonb,
    '{
        "activity_label": "string",
        "activity_type": "enum",
        "technologies": ["string"],
        "scope": "enum",
        "complexity": "enum"
    }'::jsonb
);
```

### Tool-Pattern Mappings

```sql
-- Map existing MCP tools to patterns
INSERT INTO tool_pattern_mappings (tool_name, pattern_id) 
SELECT 'agent_edit_file', id FROM system_patterns WHERE name = 'Session Summary Generation';

INSERT INTO tool_pattern_mappings (tool_name, pattern_id)
SELECT 'agent_create_file', id FROM system_patterns WHERE name = 'One-Line Activity Description';
```
