-- Update skill_areas table to use graph-based structure
-- Replace difficulty_levels with skill_graph and add learning_objectives

-- Add new columns
ALTER TABLE skill_areas 
ADD COLUMN skill_graph JSONB NOT NULL DEFAULT '{"nodes": [], "edges": [], "difficulty_weights": {}}'::jsonb,
ADD COLUMN learning_objectives JSONB;

-- Migrate existing difficulty_levels data to skill_graph format
-- This creates a simple linear graph from the old difficulty levels
UPDATE skill_areas 
SET skill_graph = jsonb_build_object(
    'nodes', jsonb_build_array(
        jsonb_build_object('id', 'beginner', 'name', 'Beginner Level', 'description', 'Basic concepts'),
        jsonb_build_object('id', 'intermediate', 'name', 'Intermediate Level', 'description', 'Intermediate concepts'),
        jsonb_build_object('id', 'advanced', 'name', 'Advanced Level', 'description', 'Advanced concepts'),
        jsonb_build_object('id', 'expert', 'name', 'Expert Level', 'description', 'Expert concepts')
    ),
    'edges', jsonb_build_array(
        jsonb_build_object('from', 'beginner', 'to', 'intermediate', 'type', 'prerequisite'),
        jsonb_build_object('from', 'intermediate', 'to', 'advanced', 'type', 'prerequisite'),
        jsonb_build_object('from', 'advanced', 'to', 'expert', 'type', 'prerequisite')
    ),
    'difficulty_weights', difficulty_levels
)
WHERE skill_graph = '{"nodes": [], "edges": [], "difficulty_weights": {}}'::jsonb;

-- Drop the old difficulty_levels column
ALTER TABLE skill_areas DROP COLUMN difficulty_levels;

-- Add indexes for the new graph structure
CREATE INDEX idx_skill_areas_graph_nodes ON skill_areas USING GIN ((skill_graph->'nodes'));
CREATE INDEX idx_skill_areas_graph_edges ON skill_areas USING GIN ((skill_graph->'edges'));
CREATE INDEX idx_skill_areas_learning_objectives ON skill_areas USING GIN (learning_objectives);
