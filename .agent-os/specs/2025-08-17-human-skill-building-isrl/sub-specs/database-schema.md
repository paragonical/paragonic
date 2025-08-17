# Database Schema

This is the database schema implementation for the spec detailed in @.agent-os/specs/2025-08-17-human-skill-building-isrl/spec.md

> Created: 2025-08-17
> Version: 1.0.0

## Schema Changes

### New Tables

#### 1. skill_areas

```sql
CREATE TABLE skill_areas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    category VARCHAR(100) NOT NULL,
    description TEXT,
    difficulty_levels JSONB NOT NULL, -- Array of difficulty levels with descriptions
    learning_objectives JSONB, -- Array of learning objectives for this skill
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_skill_areas_category ON skill_areas(category);
CREATE INDEX idx_skill_areas_name ON skill_areas(name);
```

**Purpose:** Define skill areas and their characteristics for learning tracking and assessment.

#### 2. practice_items

```sql
CREATE TABLE practice_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    skill_area_id UUID NOT NULL REFERENCES skill_areas(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    difficulty_level INTEGER NOT NULL, -- 1-10 scale
    item_type VARCHAR(50) NOT NULL, -- 'question', 'exercise', 'challenge', 'review'
    correct_answer TEXT,
    hints JSONB, -- Array of hints for the practice item
    metadata JSONB, -- Additional metadata (tags, related concepts, etc.)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_practice_items_skill_area ON practice_items(skill_area_id);
CREATE INDEX idx_practice_items_difficulty ON practice_items(difficulty_level);
CREATE INDEX idx_practice_items_type ON practice_items(item_type);
```

**Purpose:** Store practice items for different skill areas with varying difficulty levels.

#### 3. learning_sessions

```sql
CREATE TABLE learning_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    session_type VARCHAR(50) NOT NULL, -- 'practice', 'assessment', 'review'
    status VARCHAR(50) NOT NULL DEFAULT 'active', -- 'active', 'completed', 'paused'
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    total_items INTEGER DEFAULT 0,
    completed_items INTEGER DEFAULT 0,
    correct_items INTEGER DEFAULT 0,
    session_duration_minutes INTEGER,
    metadata JSONB, -- Session-specific metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_learning_sessions_user ON learning_sessions(user_id);
CREATE INDEX idx_learning_sessions_status ON learning_sessions(status);
CREATE INDEX idx_learning_sessions_started_at ON learning_sessions(started_at);
```

**Purpose:** Track individual learning sessions and their completion status.

#### 4. session_items

```sql
CREATE TABLE session_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES learning_sessions(id) ON DELETE CASCADE,
    practice_item_id UUID NOT NULL REFERENCES practice_items(id) ON DELETE CASCADE,
    order_index INTEGER NOT NULL, -- Order within the session
    user_answer TEXT,
    is_correct BOOLEAN,
    response_time_seconds INTEGER,
    difficulty_rating INTEGER, -- User's rating of difficulty (1-5)
    confidence_rating INTEGER, -- User's confidence rating (1-5)
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_session_items_session ON session_items(session_id);
CREATE INDEX idx_session_items_practice_item ON session_items(practice_item_id);
CREATE INDEX idx_session_items_order ON session_items(order_index);
```

**Purpose:** Track individual practice items within learning sessions.

#### 5. skill_assessments

```sql
CREATE TABLE skill_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    skill_area_id UUID NOT NULL REFERENCES skill_areas(id) ON DELETE CASCADE,
    assessment_type VARCHAR(50) NOT NULL, -- 'initial', 'progress', 'mastery'
    skill_level DECIMAL(3,2) NOT NULL, -- 0.00 to 1.00 scale
    confidence_interval DECIMAL(3,2), -- Confidence in the assessment
    assessment_data JSONB, -- Detailed assessment results
    assessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_skill_assessments_user ON skill_assessments(user_id);
CREATE INDEX idx_skill_assessments_skill_area ON skill_assessments(skill_area_id);
CREATE INDEX idx_skill_assessments_type ON skill_assessments(assessment_type);
CREATE INDEX idx_skill_assessments_assessed_at ON skill_assessments(assessed_at);
```

**Purpose:** Track skill level assessments for users across different skill areas.

#### 6. spaced_repetition_schedules

```sql
CREATE TABLE spaced_repetition_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    practice_item_id UUID NOT NULL REFERENCES practice_items(id) ON DELETE CASCADE,
    current_interval_days INTEGER NOT NULL DEFAULT 1,
    next_review_date TIMESTAMP WITH TIME ZONE NOT NULL,
    ease_factor DECIMAL(3,2) NOT NULL DEFAULT 2.5, -- SuperMemo ease factor
    repetition_count INTEGER NOT NULL DEFAULT 0,
    consecutive_correct INTEGER NOT NULL DEFAULT 0,
    last_review_date TIMESTAMP WITH TIME ZONE,
    last_review_result BOOLEAN, -- True if correct, False if incorrect
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_spaced_repetition_user ON spaced_repetition_schedules(user_id);
CREATE INDEX idx_spaced_repetition_next_review ON spaced_repetition_schedules(next_review_date);
CREATE INDEX idx_spaced_repetition_practice_item ON spaced_repetition_schedules(practice_item_id);
```

**Purpose:** Implement spaced repetition scheduling for optimal learning retention.

#### 7. expertise_profiles

```sql
CREATE TABLE expertise_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    profile_name VARCHAR(255) NOT NULL,
    profile_type VARCHAR(50) NOT NULL, -- 'public', 'private', 'organization'
    skill_summary JSONB NOT NULL, -- Summary of all skill levels
    learning_velocity DECIMAL(5,2), -- Rate of skill improvement
    total_learning_hours INTEGER DEFAULT 0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    metadata JSONB, -- Additional profile information
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_expertise_profiles_user ON expertise_profiles(user_id);
CREATE INDEX idx_expertise_profiles_type ON expertise_profiles(profile_type);
CREATE INDEX idx_expertise_profiles_active ON expertise_profiles(is_active);
```

**Purpose:** Store marketable expertise profiles for the fractional organization network.

#### 8. learning_analytics

```sql
CREATE TABLE learning_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(10,4) NOT NULL,
    metric_unit VARCHAR(50),
    time_period VARCHAR(20) NOT NULL, -- 'daily', 'weekly', 'monthly'
    period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_learning_analytics_user ON learning_analytics(user_id);
CREATE INDEX idx_learning_analytics_metric ON learning_analytics(metric_name);
CREATE INDEX idx_learning_analytics_period ON learning_analytics(time_period);
CREATE INDEX idx_learning_analytics_period_start ON learning_analytics(period_start);
```

**Purpose:** Track comprehensive learning analytics for performance analysis and insights.

#### 9. skill_relationships

```sql
CREATE TABLE skill_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_skill_area_id UUID NOT NULL REFERENCES skill_areas(id) ON DELETE CASCADE,
    target_skill_area_id UUID NOT NULL REFERENCES skill_areas(id) ON DELETE CASCADE,
    relationship_type VARCHAR(50) NOT NULL, -- 'prerequisite', 'complementary', 'adjacent', 'advanced'
    relationship_strength DECIMAL(3,2) NOT NULL DEFAULT 0.5, -- 0.0 to 1.0
    learning_path_order INTEGER, -- Order in recommended learning path
    description TEXT,
    metadata JSONB, -- Additional relationship information
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(source_skill_area_id, target_skill_area_id, relationship_type)
);

CREATE INDEX idx_skill_relationships_source ON skill_relationships(source_skill_area_id);
CREATE INDEX idx_skill_relationships_target ON skill_relationships(target_skill_area_id);
CREATE INDEX idx_skill_relationships_type ON skill_relationships(relationship_type);
CREATE INDEX idx_skill_relationships_strength ON skill_relationships(relationship_strength);
```

**Purpose:** Define relationships between skill areas to enable adjacent skill recommendations and learning path optimization.

### Modified Tables

#### 1. people

```sql
-- Add learning-related fields to existing table
ALTER TABLE people ADD COLUMN learning_preferences JSONB;
ALTER TABLE people ADD COLUMN current_learning_goals JSONB;
ALTER TABLE people ADD COLUMN last_learning_session_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE people ADD COLUMN total_learning_hours INTEGER DEFAULT 0;

CREATE INDEX idx_people_learning_session ON people(last_learning_session_at);
```

**Purpose:** Enhance user profiles with learning preferences and progress tracking.

## Data Integrity Rules

1. **Skill Area Uniqueness**: Skill area names must be unique across the system
2. **Practice Item Validation**: Practice items must reference valid skill areas
3. **Session Integrity**: Session items must reference valid sessions and practice items
4. **Assessment Consistency**: Skill assessments must have valid skill levels (0.00-1.00)
5. **Spaced Repetition Logic**: Spaced repetition schedules must have valid intervals and dates
6. **Profile Uniqueness**: Users can have only one active profile per type
7. **Skill Relationship Consistency**: Skill relationships must reference valid skill areas and have valid relationship types

## Performance Considerations

1. **Indexing Strategy**: Indexes on frequently queried fields (user_id, skill_area_id, dates)
2. **JSONB Usage**: Use JSONB for flexible schema fields (metadata, assessment_data)
3. **Partitioning**: Consider partitioning learning_analytics by date for large-scale deployments
4. **Caching**: Cache frequently accessed skill assessments and profiles

## Migration Strategy

1. **Phase 1**: Create new tables without foreign key constraints
2. **Phase 2**: Add foreign key constraints and indexes
3. **Phase 3**: Migrate existing user data to include learning fields
4. **Phase 4**: Populate initial skill areas and practice items

## Initial Data Population

### Core Skill Areas

```sql
-- Programming Fundamentals
INSERT INTO skill_areas (name, category, description, difficulty_levels) VALUES (
    'Programming Fundamentals',
    'Development',
    'Core programming concepts and best practices',
    '[
        {"level": 1, "description": "Basic syntax and concepts"},
        {"level": 2, "description": "Control structures and functions"},
        {"level": 3, "description": "Object-oriented programming"},
        {"level": 4, "description": "Design patterns and architecture"},
        {"level": 5, "description": "Advanced programming concepts"}
    ]'::jsonb
);

-- AI Collaboration
INSERT INTO skill_areas (name, category, description, difficulty_levels) VALUES (
    'AI Collaboration',
    'AI Integration',
    'Effective collaboration with AI agents and tools',
    '[
        {"level": 1, "description": "Basic AI tool usage"},
        {"level": 2, "description": "Effective prompt engineering"},
        {"level": 3, "description": "AI workflow optimization"},
        {"level": 4, "description": "Advanced AI integration"},
        {"level": 5, "description": "AI system design and management"}
    ]'::jsonb
);
```

### Sample Practice Items

```sql
-- Sample practice items for programming fundamentals
INSERT INTO practice_items (skill_area_id, title, content, difficulty_level, item_type) 
SELECT id, 'Variable Scope Understanding', 'What is the output of this code snippet?', 2, 'question'
FROM skill_areas WHERE name = 'Programming Fundamentals';

INSERT INTO practice_items (skill_area_id, title, content, difficulty_level, item_type)
SELECT id, 'Function Optimization', 'Optimize this function for better performance', 3, 'exercise'
FROM skill_areas WHERE name = 'Programming Fundamentals';
```

### Sample Skill Relationships

```sql
-- Define relationships between skill areas
INSERT INTO skill_relationships (source_skill_area_id, target_skill_area_id, relationship_type, relationship_strength, description) 
SELECT 
    (SELECT id FROM skill_areas WHERE name = 'Programming Fundamentals'),
    (SELECT id FROM skill_areas WHERE name = 'AI Collaboration'),
    'adjacent',
    0.7,
    'Programming fundamentals provide the foundation for effective AI collaboration'
WHERE EXISTS (SELECT 1 FROM skill_areas WHERE name = 'Programming Fundamentals')
  AND EXISTS (SELECT 1 FROM skill_areas WHERE name = 'AI Collaboration');

-- Add more adjacent skill relationships
INSERT INTO skill_relationships (source_skill_area_id, target_skill_area_id, relationship_type, relationship_strength, description)
SELECT 
    (SELECT id FROM skill_areas WHERE name = 'Programming Fundamentals'),
    (SELECT id FROM skill_areas WHERE name = 'System Design'),
    'prerequisite',
    0.8,
    'Strong programming fundamentals are required for effective system design'
WHERE EXISTS (SELECT 1 FROM skill_areas WHERE name = 'Programming Fundamentals')
  AND EXISTS (SELECT 1 FROM skill_areas WHERE name = 'System Design');
```
