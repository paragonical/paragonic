-- Drop human-driven learning system tables in reverse order

-- 4. Drop human_assistance_requests table
DROP TABLE IF EXISTS human_assistance_requests;

-- 3. Drop practice_sessions table
DROP TABLE IF EXISTS practice_sessions;

-- 2. Drop human_learning_states table
DROP TABLE IF EXISTS human_learning_states;

-- 1. Drop learning_units table
DROP TABLE IF EXISTS learning_units;
