-- Add human-driven learning system tables

-- 1. learning_units table
CREATE TABLE learning_units (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    skill_area_id UUID NOT NULL REFERENCES skill_areas(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    unit_type VARCHAR(50) NOT NULL, -- "concept", "skill", "value", "culture", "procedure"
    difficulty_level INTEGER NOT NULL, -- Scaled by 100 (e.g., 3500 = 35.00)
    estimated_time_minutes INTEGER,
    dependencies JSONB, -- Array of unit IDs that must be mastered first
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_learning_units_skill_area ON learning_units(skill_area_id);
CREATE INDEX idx_learning_units_type ON learning_units(unit_type);
CREATE INDEX idx_learning_units_difficulty ON learning_units(difficulty_level);

-- 2. human_learning_states table
CREATE TABLE human_learning_states (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    learning_unit_id UUID NOT NULL REFERENCES learning_units(id) ON DELETE CASCADE,
    learning_state VARCHAR(50) NOT NULL, -- "not_seen", "forgotten", "recalled"
    current_score INTEGER NOT NULL DEFAULT 0, -- Scaled by 100 (0-10000)
    last_practiced TIMESTAMP WITH TIME ZONE,
    practice_frequency_days INTEGER NOT NULL DEFAULT 1, -- Days between practices based on score
    next_practice_date TIMESTAMP WITH TIME ZONE,
    total_practice_sessions INTEGER NOT NULL DEFAULT 0,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(person_id, learning_unit_id)
);

CREATE INDEX idx_human_learning_states_person ON human_learning_states(person_id);
CREATE INDEX idx_human_learning_states_unit ON human_learning_states(learning_unit_id);
CREATE INDEX idx_human_learning_states_state ON human_learning_states(learning_state);
CREATE INDEX idx_human_learning_states_score ON human_learning_states(current_score);
CREATE INDEX idx_human_learning_states_next_practice ON human_learning_states(next_practice_date);

-- 3. practice_sessions table
CREATE TABLE practice_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    session_type VARCHAR(50) NOT NULL, -- "adaptive_practice", "focused_review", "assessment"
    title VARCHAR(255) NOT NULL,
    description TEXT,
    enrollment_level VARCHAR(50) NOT NULL, -- "light", "moderate", "intensive"
    target_duration_minutes INTEGER,
    actual_duration_minutes INTEGER,
    learning_units JSONB, -- Array of unit IDs in this session
    session_status VARCHAR(50) NOT NULL DEFAULT 'scheduled', -- "scheduled", "in_progress", "completed", "cancelled"
    completion_percentage INTEGER, -- Scaled by 100
    metadata JSONB,
    scheduled_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_practice_sessions_person ON practice_sessions(person_id);
CREATE INDEX idx_practice_sessions_type ON practice_sessions(session_type);
CREATE INDEX idx_practice_sessions_status ON practice_sessions(session_status);
CREATE INDEX idx_practice_sessions_enrollment ON practice_sessions(enrollment_level);
CREATE INDEX idx_practice_sessions_scheduled ON practice_sessions(scheduled_at);

-- 4. human_assistance_requests table
CREATE TABLE human_assistance_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    problem_description TEXT NOT NULL,
    required_skills JSONB NOT NULL, -- Array of required skill areas
    difficulty_level VARCHAR(50) NOT NULL, -- "easy", "medium", "hard", "expert"
    urgency_level VARCHAR(50) NOT NULL, -- "low", "medium", "high", "critical"
    estimated_completion_hours INTEGER,
    available_experts JSONB, -- Array of expert person IDs
    assigned_expert_id UUID REFERENCES people(id) ON DELETE SET NULL,
    request_status VARCHAR(50) NOT NULL DEFAULT 'open', -- "open", "assigned", "in_progress", "completed", "cancelled"
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_human_assistance_requests_requester ON human_assistance_requests(requester_id);
CREATE INDEX idx_human_assistance_requests_expert ON human_assistance_requests(assigned_expert_id);
CREATE INDEX idx_human_assistance_requests_status ON human_assistance_requests(request_status);
CREATE INDEX idx_human_assistance_requests_difficulty ON human_assistance_requests(difficulty_level);
CREATE INDEX idx_human_assistance_requests_urgency ON human_assistance_requests(urgency_level);
