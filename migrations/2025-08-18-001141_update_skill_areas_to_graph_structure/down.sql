-- Revert skill_areas table to original structure
-- Remove graph-based columns and restore difficulty_levels

-- Add back the difficulty_levels column
ALTER TABLE skill_areas 
ADD COLUMN difficulty_levels JSONB NOT NULL DEFAULT '{"beginner": 1, "intermediate": 2, "advanced": 3, "expert": 4}'::jsonb;

-- Migrate skill_graph difficulty_weights back to difficulty_levels
UPDATE skill_areas 
SET difficulty_levels = skill_graph->'difficulty_weights'
WHERE skill_graph IS NOT NULL;

-- Drop the new columns
ALTER TABLE skill_areas DROP COLUMN skill_graph;
ALTER TABLE skill_areas DROP COLUMN learning_objectives;

-- Drop the new indexes
DROP INDEX IF EXISTS idx_skill_areas_graph_nodes;
DROP INDEX IF EXISTS idx_skill_areas_graph_edges;
DROP INDEX IF EXISTS idx_skill_areas_learning_objectives;
