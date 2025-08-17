-- Learning System Schema Migration
-- This migration adds all tables needed for the human skill building ISRL system

-- 1. skill_areas table
CREATE TABLE skill_areas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    category VARCHAR(100) NOT NULL,
    description TEXT,
    difficulty_levels JSONB NOT NULL DEFAULT '{"beginner": 1, "intermediate": 2, "advanced": 3, "expert": 4}'::jsonb,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_skill_areas_name ON skill_areas(name);
CREATE INDEX idx_skill_areas_category ON skill_areas(category);
CREATE INDEX idx_skill_areas_created_at ON skill_areas(created_at);

-- 2. practice_items table
CREATE TABLE practice_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    skill_area_id UUID NOT NULL REFERENCES skill_areas(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    item_type VARCHAR(50) NOT NULL, -- 'multiple_choice', 'coding_challenge', 'concept_question', 'debugging'
    difficulty_level INTEGER NOT NULL CHECK (difficulty_level >= 1 AND difficulty_level <= 5),
    correct_answer TEXT,
    options JSONB, -- For multiple choice questions
    hints JSONB, -- Array of hints
    explanation TEXT,
    estimated_time_minutes INTEGER DEFAULT 5,
    tags JSONB,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_practice_items_skill_area ON practice_items(skill_area_id);
CREATE INDEX idx_practice_items_difficulty ON practice_items(difficulty_level);
CREATE INDEX idx_practice_items_type ON practice_items(item_type);
CREATE INDEX idx_practice_items_created_at ON practice_items(created_at);

-- 3. learning_sessions table
CREATE TABLE learning_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    session_type VARCHAR(50) NOT NULL, -- 'practice', 'assessment', 'review', 'adjacent_skill'
    title VARCHAR(255) NOT NULL,
    description TEXT,
    target_duration_minutes INTEGER,
    actual_duration_minutes INTEGER,
    status VARCHAR(50) NOT NULL DEFAULT 'in_progress', -- 'in_progress', 'completed', 'paused', 'abandoned'
    difficulty_target INTEGER,
    skill_areas_targeted JSONB, -- Array of skill area IDs
    metadata JSONB,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_learning_sessions_person ON learning_sessions(person_id);
CREATE INDEX idx_learning_sessions_status ON learning_sessions(status);
CREATE INDEX idx_learning_sessions_started_at ON learning_sessions(started_at);
CREATE INDEX idx_learning_sessions_type ON learning_sessions(session_type);

-- 4. session_items table
CREATE TABLE session_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES learning_sessions(id) ON DELETE CASCADE,
    practice_item_id UUID NOT NULL REFERENCES practice_items(id) ON DELETE CASCADE,
    order_in_session INTEGER NOT NULL,
    user_answer TEXT,
    is_correct BOOLEAN,
    time_spent_seconds INTEGER,
    confidence_level INTEGER CHECK (confidence_level >= 1 AND confidence_level <= 5),
    hints_used INTEGER DEFAULT 0,
    completed_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_session_items_session ON session_items(session_id);
CREATE INDEX idx_session_items_practice_item ON session_items(practice_item_id);
CREATE INDEX idx_session_items_order ON session_items(order_in_session);
CREATE INDEX idx_session_items_completed_at ON session_items(completed_at);

-- 5. skill_assessments table
CREATE TABLE skill_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    skill_area_id UUID NOT NULL REFERENCES skill_areas(id) ON DELETE CASCADE,
    assessment_type VARCHAR(50) NOT NULL, -- 'initial', 'progress', 'final', 'adjacent_skill'
    score DECIMAL(5,2) CHECK (score >= 0 AND score <= 100),
    confidence_level INTEGER CHECK (confidence_level >= 1 AND confidence_level <= 5),
    difficulty_level INTEGER CHECK (difficulty_level >= 1 AND difficulty_level <= 5),
    questions_answered INTEGER DEFAULT 0,
    questions_correct INTEGER DEFAULT 0,
    time_spent_minutes INTEGER,
    assessment_data JSONB, -- Detailed assessment results
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_skill_assessments_person ON skill_assessments(person_id);
CREATE INDEX idx_skill_assessments_skill_area ON skill_assessments(skill_area_id);
CREATE INDEX idx_skill_assessments_type ON skill_assessments(assessment_type);
CREATE INDEX idx_skill_assessments_created_at ON skill_assessments(created_at);

-- 6. spaced_repetition_schedules table
CREATE TABLE spaced_repetition_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    practice_item_id UUID NOT NULL REFERENCES practice_items(id) ON DELETE CASCADE,
    skill_area_id UUID NOT NULL REFERENCES skill_areas(id) ON DELETE CASCADE,
    interval_days INTEGER NOT NULL DEFAULT 1,
    ease_factor DECIMAL(3,2) NOT NULL DEFAULT 2.5,
    repetition_count INTEGER NOT NULL DEFAULT 0,
    next_review_date DATE NOT NULL,
    last_review_date DATE,
    last_review_score INTEGER CHECK (last_review_score >= 0 AND last_review_score <= 5),
    is_active BOOLEAN NOT NULL DEFAULT true,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_spaced_repetition_person ON spaced_repetition_schedules(person_id);
CREATE INDEX idx_spaced_repetition_practice_item ON spaced_repetition_schedules(practice_item_id);
CREATE INDEX idx_spaced_repetition_skill_area ON spaced_repetition_schedules(skill_area_id);
CREATE INDEX idx_spaced_repetition_next_review ON spaced_repetition_schedules(next_review_date);
CREATE INDEX idx_spaced_repetition_active ON spaced_repetition_schedules(is_active);

-- 7. expertise_profiles table
CREATE TABLE expertise_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    profile_type VARCHAR(50) NOT NULL, -- 'public', 'private', 'fractional_network'
    title VARCHAR(255) NOT NULL,
    summary TEXT,
    skill_summary JSONB NOT NULL, -- Aggregated skill levels and metrics
    learning_velocity DECIMAL(5,2), -- Skills improvement rate
    total_practice_time_hours DECIMAL(8,2) DEFAULT 0,
    total_sessions_completed INTEGER DEFAULT 0,
    average_session_score DECIMAL(5,2),
    strongest_skills JSONB, -- Top 5 skills with levels
    skills_in_development JSONB, -- Skills currently being learned
    market_value_indicators JSONB, -- Skills with high market demand
    is_public BOOLEAN NOT NULL DEFAULT false,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(person_id, profile_type)
);

CREATE INDEX idx_expertise_profiles_person ON expertise_profiles(person_id);
CREATE INDEX idx_expertise_profiles_type ON expertise_profiles(profile_type);
CREATE INDEX idx_expertise_profiles_public ON expertise_profiles(is_public);
CREATE INDEX idx_expertise_profiles_created_at ON expertise_profiles(created_at);

-- 8. learning_analytics table
CREATE TABLE learning_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    skill_area_id UUID NOT NULL REFERENCES skill_areas(id) ON DELETE CASCADE,
    metric_type VARCHAR(50) NOT NULL, -- 'accuracy', 'speed', 'confidence', 'retention', 'adjacent_skill_growth'
    metric_value DECIMAL(8,4) NOT NULL,
    measurement_date DATE NOT NULL,
    session_count INTEGER DEFAULT 1,
    practice_time_minutes INTEGER DEFAULT 0,
    confidence_interval_lower DECIMAL(8,4),
    confidence_interval_upper DECIMAL(8,4),
    trend_direction VARCHAR(20), -- 'improving', 'declining', 'stable'
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_learning_analytics_person ON learning_analytics(person_id);
CREATE INDEX idx_learning_analytics_skill_area ON learning_analytics(skill_area_id);
CREATE INDEX idx_learning_analytics_metric_type ON learning_analytics(metric_type);
CREATE INDEX idx_learning_analytics_measurement_date ON learning_analytics(measurement_date);
CREATE INDEX idx_learning_analytics_trend ON learning_analytics(trend_direction);

-- 9. skill_relationships table
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

-- Add learning field to people table
ALTER TABLE people ADD COLUMN learning_preferences JSONB DEFAULT '{"preferred_session_duration": 30, "difficulty_preference": "adaptive", "adjacent_skill_interest": true}'::jsonb;
ALTER TABLE people ADD COLUMN learning_stats JSONB DEFAULT '{"total_practice_time_hours": 0, "sessions_completed": 0, "average_score": 0}'::jsonb;

-- Create indexes for the new people columns
CREATE INDEX idx_people_learning_preferences ON people USING GIN(learning_preferences);
CREATE INDEX idx_people_learning_stats ON people USING GIN(learning_stats);
