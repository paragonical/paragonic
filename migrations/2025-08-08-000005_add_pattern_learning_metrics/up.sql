-- Migration: Add pattern learning metrics table
-- Created: 2025-08-08

-- Create pattern_learning_metrics table
CREATE TABLE pattern_learning_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pattern_id UUID NOT NULL REFERENCES system_patterns(id) ON DELETE CASCADE,
    metric_name VARCHAR(100) NOT NULL,
    metric_value FLOAT NOT NULL,
    metric_unit VARCHAR(50),
    time_period VARCHAR(20) NOT NULL,
    period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_pattern_learning_metrics_pattern_id ON pattern_learning_metrics(pattern_id);
CREATE INDEX idx_pattern_learning_metrics_metric_name ON pattern_learning_metrics(metric_name);
CREATE INDEX idx_pattern_learning_metrics_time_period ON pattern_learning_metrics(time_period);
CREATE INDEX idx_pattern_learning_metrics_period_start ON pattern_learning_metrics(period_start);
CREATE INDEX idx_pattern_learning_metrics_period_end ON pattern_learning_metrics(period_end);
CREATE INDEX idx_pattern_learning_metrics_created_at ON pattern_learning_metrics(created_at);

-- Add unique constraint to prevent duplicate metrics for the same pattern and time period
CREATE UNIQUE INDEX idx_pattern_learning_metrics_unique ON pattern_learning_metrics(pattern_id, metric_name, time_period, period_start, period_end);

-- Add comments for documentation
COMMENT ON TABLE pattern_learning_metrics IS 'Stores learning metrics for pattern performance and adaptation';
COMMENT ON COLUMN pattern_learning_metrics.pattern_id IS 'Reference to the system pattern';
COMMENT ON COLUMN pattern_learning_metrics.metric_name IS 'Name of the metric (e.g., success_rate, execution_time, user_satisfaction)';
COMMENT ON COLUMN pattern_learning_metrics.metric_value IS 'Value of the metric';
COMMENT ON COLUMN pattern_learning_metrics.metric_unit IS 'Unit of measurement for the metric';
COMMENT ON COLUMN pattern_learning_metrics.time_period IS 'Time period for the metric (e.g., daily, weekly, monthly)';
COMMENT ON COLUMN pattern_learning_metrics.period_start IS 'Start of the time period';
COMMENT ON COLUMN pattern_learning_metrics.period_end IS 'End of the time period';
COMMENT ON COLUMN pattern_learning_metrics.metadata IS 'Additional metadata about the metric';
