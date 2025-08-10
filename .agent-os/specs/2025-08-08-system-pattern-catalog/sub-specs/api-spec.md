# API Specification

This is the API specification for the spec detailed in @.agent-os/specs/2025-08-08-system-pattern-catalog/spec.md

> Created: 2025-08-08
> Version: 1.0.0

## Endpoints

### GET /api/patterns

**Purpose:** Retrieve all system patterns with optional filtering
**Parameters:** 
- `category` (optional): Filter by pattern category
- `meta_level` (optional): Filter by meta level (system, user, hybrid)
- `limit` (optional): Maximum number of patterns to return
- `offset` (optional): Number of patterns to skip

**Response:**
```json
{
  "patterns": [
    {
      "id": "uuid",
      "name": "string",
      "category": "string",
      "meta_level": "string",
      "description": "string",
      "workflow_steps": "json",
      "output_format": "json",
      "trigger_conditions": "json",
      "success_criteria": "json",
      "created_at": "timestamp",
      "updated_at": "timestamp"
    }
  ],
  "total_count": "integer",
  "limit": "integer",
  "offset": "integer"
}
```

**Errors:**
- `400 Bad Request`: Invalid filter parameters
- `500 Internal Server Error`: Database error

### GET /api/patterns/{pattern_id}

**Purpose:** Retrieve a specific system pattern by ID
**Parameters:** 
- `pattern_id` (path): UUID of the pattern to retrieve

**Response:**
```json
{
  "id": "uuid",
  "name": "string",
  "category": "string",
  "meta_level": "string",
  "description": "string",
  "workflow_steps": "json",
  "output_format": "json",
  "trigger_conditions": "json",
  "success_criteria": "json",
  "relationships": [
    {
      "id": "uuid",
      "target_pattern_id": "uuid",
      "target_pattern_name": "string",
      "relationship_type": "string",
      "description": "string",
      "confidence_score": "decimal"
    }
  ],
  "tool_mappings": [
    {
      "tool_name": "string",
      "usage_frequency": "integer",
      "success_rate": "decimal",
      "last_used_at": "timestamp"
    }
  ],
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

**Errors:**
- `404 Not Found`: Pattern not found
- `500 Internal Server Error`: Database error

### POST /api/patterns/{pattern_id}/execute

**Purpose:** Execute a system pattern with given context
**Parameters:** 
- `pattern_id` (path): UUID of the pattern to execute
- `session_id` (optional): UUID of the AI agent session
- `input_context` (optional): JSON context for pattern execution
- `trigger_type` (optional): Type of trigger (manual, automatic, scheduled)

**Response:**
```json
{
  "execution_id": "uuid",
  "pattern_id": "uuid",
  "pattern_name": "string",
  "session_id": "uuid",
  "trigger_type": "string",
  "input_context": "json",
  "output_result": "json",
  "execution_duration_ms": "integer",
  "success": "boolean",
  "error_message": "string",
  "created_at": "timestamp"
}
```

**Errors:**
- `404 Not Found`: Pattern not found
- `400 Bad Request`: Invalid execution parameters
- `422 Unprocessable Entity`: Pattern execution failed
- `500 Internal Server Error`: Database error

### GET /api/patterns/{pattern_id}/executions

**Purpose:** Retrieve execution history for a specific pattern
**Parameters:** 
- `pattern_id` (path): UUID of the pattern
- `limit` (optional): Maximum number of executions to return
- `offset` (optional): Number of executions to skip
- `success` (optional): Filter by success status

**Response:**
```json
{
  "executions": [
    {
      "id": "uuid",
      "pattern_id": "uuid",
      "session_id": "uuid",
      "trigger_type": "string",
      "input_context": "json",
      "output_result": "json",
      "execution_duration_ms": "integer",
      "success": "boolean",
      "error_message": "string",
      "created_at": "timestamp"
    }
  ],
  "total_count": "integer",
  "limit": "integer",
  "offset": "integer"
}
```

**Errors:**
- `404 Not Found`: Pattern not found
- `400 Bad Request`: Invalid filter parameters
- `500 Internal Server Error`: Database error

### GET /api/patterns/{pattern_id}/metrics

**Purpose:** Retrieve learning metrics for a specific pattern
**Parameters:** 
- `pattern_id` (path): UUID of the pattern
- `metric_type` (optional): Filter by metric type
- `days` (optional): Number of days to look back

**Response:**
```json
{
  "pattern_id": "uuid",
  "pattern_name": "string",
  "metrics": [
    {
      "metric_type": "string",
      "metric_value": "decimal",
      "sample_size": "integer",
      "confidence_interval": "decimal",
      "measured_at": "timestamp"
    }
  ],
  "summary": {
    "total_executions": "integer",
    "success_rate": "decimal",
    "average_execution_time_ms": "decimal",
    "last_execution_at": "timestamp"
  }
}
```

**Errors:**
- `404 Not Found`: Pattern not found
- `400 Bad Request`: Invalid filter parameters
- `500 Internal Server Error`: Database error

### GET /api/tools/{tool_name}/patterns

**Purpose:** Retrieve patterns associated with a specific MCP tool
**Parameters:** 
- `tool_name` (path): Name of the MCP tool

**Response:**
```json
{
  "tool_name": "string",
  "patterns": [
    {
      "pattern_id": "uuid",
      "pattern_name": "string",
      "category": "string",
      "description": "string",
      "usage_frequency": "integer",
      "success_rate": "decimal",
      "last_used_at": "timestamp"
    }
  ]
}
```

**Errors:**
- `404 Not Found`: Tool not found
- `500 Internal Server Error`: Database error

### POST /api/sessions/{session_id}/patterns/trigger

**Purpose:** Trigger automatic pattern execution for a session
**Parameters:** 
- `session_id` (path): UUID of the AI agent session
- `pattern_categories` (optional): Array of pattern categories to trigger

**Response:**
```json
{
  "session_id": "uuid",
  "triggered_patterns": [
    {
      "pattern_id": "uuid",
      "pattern_name": "string",
      "execution_id": "uuid",
      "success": "boolean",
      "result": "json"
    }
  ],
  "total_triggered": "integer",
  "total_successful": "integer"
}
```

**Errors:**
- `404 Not Found`: Session not found
- `400 Bad Request`: Invalid trigger parameters
- `500 Internal Server Error`: Database error

## Controllers

### PatternController

**Actions:**
- `index()`: List patterns with filtering
- `show(pattern_id)`: Get specific pattern details
- `execute(pattern_id)`: Execute a pattern
- `executions(pattern_id)`: Get pattern execution history
- `metrics(pattern_id)`: Get pattern learning metrics

**Business Logic:**
- Pattern validation and retrieval
- Execution context preparation
- Result processing and storage
- Error handling and logging

### ToolPatternController

**Actions:**
- `tool_patterns(tool_name)`: Get patterns for a specific tool
- `update_mapping(tool_name, pattern_id)`: Update tool-pattern mapping

**Business Logic:**
- Tool-pattern relationship management
- Usage frequency tracking
- Success rate calculation

### SessionPatternController

**Actions:**
- `trigger_automatic(session_id)`: Trigger automatic patterns for session
- `session_patterns(session_id)`: Get patterns executed in session

**Business Logic:**
- Automatic trigger condition evaluation
- Session context analysis
- Pattern execution coordination

## Error Handling

### Standard Error Response Format

```json
{
  "error": {
    "code": "string",
    "message": "string",
    "details": "json",
    "timestamp": "timestamp"
  }
}
```

### Common Error Codes

- `PATTERN_NOT_FOUND`: Requested pattern does not exist
- `INVALID_EXECUTION_CONTEXT`: Pattern execution context is invalid
- `EXECUTION_FAILED`: Pattern execution failed with specific error
- `TOOL_NOT_FOUND`: Requested MCP tool does not exist
- `SESSION_NOT_FOUND`: Requested session does not exist
- `INVALID_TRIGGER_CONDITIONS`: Automatic trigger conditions are invalid

## Integration with Existing APIs

### MCP Tool Enhancement

The existing MCP tool endpoints will be enhanced to include pattern information:

```json
{
  "name": "agent_edit_file",
  "description": "Edit a file in the current Neovim session",
  "input_schema": {...},
  "patterns": [
    {
      "pattern_id": "uuid",
      "pattern_name": "Session Summary Generation",
      "usage_frequency": 15,
      "success_rate": 0.93
    }
  ]
}
```

### AI Agent Session Enhancement

The existing AI agent session endpoints will include pattern execution data:

```json
{
  "session_id": "uuid",
  "agent_name": "string",
  "status": "active",
  "activity_label": "Refactoring user authentication system",
  "session_summary": "Completed authentication refactor...",
  "pattern_executions_count": 5,
  "last_pattern_execution_at": "timestamp"
}
```
