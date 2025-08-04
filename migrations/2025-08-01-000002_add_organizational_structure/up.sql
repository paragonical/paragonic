-- Migration: Add organizational structure for fractional organization network
-- Created: 2025-08-01

-- Create organizations table
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    domain VARCHAR(255),
    industry VARCHAR(100),
    size VARCHAR(50),
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create people table for human experts
CREATE TABLE people (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    bio TEXT,
    expertise_areas TEXT[],
    location VARCHAR(255),
    timezone VARCHAR(50),
    availability_status VARCHAR(50) DEFAULT 'available',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create ISRL profiles for learning and expertise tracking
CREATE TABLE isrl_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id UUID REFERENCES people(id) ON DELETE CASCADE,
    skill_name VARCHAR(255) NOT NULL,
    skill_category VARCHAR(100),
    proficiency_level INTEGER DEFAULT 1, -- 1-10 scale
    last_reviewed TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    next_review TIMESTAMP WITH TIME ZONE,
    review_interval_days INTEGER DEFAULT 30,
    total_reviews INTEGER DEFAULT 0,
    success_rate DECIMAL(5,4) DEFAULT 0.0, -- 0.0000 to 1.0000
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create associations table to manage relationships between people, agents, and organizations
CREATE TABLE associations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    person_id UUID REFERENCES people(id) ON DELETE SET NULL,
    agent_id UUID REFERENCES agents(id) ON DELETE SET NULL,
    role VARCHAR(100) NOT NULL,
    permissions JSONB,
    start_date DATE,
    end_date DATE,
    status VARCHAR(50) DEFAULT 'active',
    allocation_percentage INTEGER DEFAULT 100, -- For fractional work (0-100)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- Ensure at least one of person_id or agent_id is set
    CONSTRAINT check_association_target CHECK (person_id IS NOT NULL OR agent_id IS NOT NULL)
);

-- Create organization hierarchies for parent-child relationships
CREATE TABLE organization_hierarchies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    child_organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    relationship_type VARCHAR(50) DEFAULT 'subsidiary', -- subsidiary, division, project, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(parent_organization_id, child_organization_id)
);

-- Create indexes for better performance
CREATE INDEX idx_organizations_status ON organizations(status);
CREATE INDEX idx_organizations_industry ON organizations(industry);
CREATE INDEX idx_people_email ON people(email);
CREATE INDEX idx_people_availability ON people(availability_status);
CREATE INDEX idx_isrl_profiles_person_id ON isrl_profiles(person_id);
CREATE INDEX idx_isrl_profiles_skill_name ON isrl_profiles(skill_name);
CREATE INDEX idx_isrl_profiles_next_review ON isrl_profiles(next_review);
CREATE INDEX idx_associations_organization_id ON associations(organization_id);
CREATE INDEX idx_associations_person_id ON associations(person_id);
CREATE INDEX idx_associations_agent_id ON associations(agent_id);
CREATE INDEX idx_associations_status ON associations(status);
CREATE INDEX idx_organization_hierarchies_parent ON organization_hierarchies(parent_organization_id);
CREATE INDEX idx_organization_hierarchies_child ON organization_hierarchies(child_organization_id);

-- Add organization_id to existing tables for organizational context
ALTER TABLE projects ADD COLUMN organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE;
CREATE INDEX idx_projects_organization_id ON projects(organization_id);

ALTER TABLE conversations ADD COLUMN organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE;
CREATE INDEX idx_conversations_organization_id ON conversations(organization_id); 