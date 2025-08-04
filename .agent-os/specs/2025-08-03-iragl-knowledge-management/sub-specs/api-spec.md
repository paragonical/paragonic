# API Specification

This is the API specification for the spec detailed in @.agent-os/specs/2025-08-03-iragl-knowledge-management/spec.md

> Created: 2025-08-03
> Version: 1.0.0

## Endpoints

### POST /rpc/ingest_knowledge_stream

**Purpose:** Ingest new content from organizational activities into the knowledge base
**Parameters:** 
```json
{
  "content_type": "communication|document|code|conversation",
  "content_text": "string",
  "source_entity_type": "organization|project|operation|agent",
  "source_entity_id": "uuid",
  "metadata": "object (optional)",
  "embedding_model": "string"
}
```
**Response:** 
```json
{
  "success": true,
  "knowledge_stream_id": "uuid",
  "embedding_generated": true,
  "associations_created": 3,
  "optimization_triggered": true
}
```
**Errors:** 
- `INVALID_CONTENT_TYPE`: Content type not supported
- `EMBEDDING_GENERATION_FAILED`: Failed to generate embedding
- `ASSOCIATION_FAILED`: Failed to create content associations

### POST /rpc/associate_content

**Purpose:** Manually link content to organizational entities with specified strength
**Parameters:** 
```json
{
  "content_id": "uuid",
  "associations": [
    {
      "entity_type": "organization|project|operation|goal|task",
      "entity_id": "uuid",
      "association_strength": 0.0-1.0,
      "association_type": "direct|derived|inferred",
      "confidence_score": 0.0-1.0
    }
  ]
}
```
**Response:** 
```json
{
  "success": true,
  "associations_created": 2,
  "associations_updated": 1,
  "total_associations": 5
}
```
**Errors:** 
- `CONTENT_NOT_FOUND`: Specified content ID does not exist
- `INVALID_ENTITY`: Entity type or ID is invalid
- `DUPLICATE_ASSOCIATION`: Association already exists

### POST /rpc/optimize_knowledge_base

**Purpose:** Trigger manual optimization of the knowledge base
**Parameters:** 
```json
{
  "optimization_type": "embedding_update|association_refinement|geometry_optimization|full",
  "content_filter": {
    "content_type": "string (optional)",
    "optimization_status": "pending|optimized|failed (optional)",
    "date_range": {
      "start": "iso_date (optional)",
      "end": "iso_date (optional)"
    }
  },
  "force_optimization": false
}
```
**Response:** 
```json
{
  "success": true,
  "optimization_id": "uuid",
  "content_count": 1500,
  "estimated_duration_ms": 30000,
  "optimization_type": "full"
}
```
**Errors:** 
- `OPTIMIZATION_IN_PROGRESS`: Another optimization is already running
- `NO_CONTENT_TO_OPTIMIZE`: No content matches the filter criteria
- `INVALID_OPTIMIZATION_TYPE`: Specified optimization type not supported

### POST /rpc/iragl_search

**Purpose:** Enhanced search with organizational context awareness
**Parameters:** 
```json
{
  "query": "string",
  "context": {
    "organization_id": "uuid (optional)",
    "project_id": "uuid (optional)",
    "operation_id": "uuid (optional)",
    "entity_weights": {
      "organization": 1.0,
      "project": 0.8,
      "operation": 0.6
    }
  },
  "filters": {
    "content_type": ["communication", "document"],
    "date_range": {
      "start": "iso_date (optional)",
      "end": "iso_date (optional)"
    },
    "association_strength_min": 0.5
  },
  "limit": 10,
  "include_metadata": true
}
```
**Response:** 
```json
{
  "success": true,
  "results": [
    {
      "id": "uuid",
      "content_type": "communication",
      "content_text": "string",
      "source_entity_type": "project",
      "source_entity_id": "uuid",
      "similarity_score": 0.85,
      "context_relevance": 0.92,
      "associations": [
        {
          "entity_type": "project",
          "entity_id": "uuid",
          "association_strength": 0.9
        }
      ],
      "metadata": "object",
      "created_at": "iso_date"
    }
  ],
  "total_results": 45,
  "query_time_ms": 125,
  "optimization_impact": 0.15
}
```
**Errors:** 
- `INVALID_QUERY`: Query is empty or malformed
- `SEARCH_FAILED`: Internal search error
- `CONTEXT_NOT_FOUND`: Specified context entities not found

### GET /rpc/knowledge_analytics

**Purpose:** Retrieve analytics and performance metrics for the knowledge base
**Parameters:** 
```json
{
  "metric_types": ["ingestion_rate", "search_performance", "optimization_effectiveness"],
  "time_period": "hourly|daily|weekly",
  "date_range": {
    "start": "iso_date",
    "end": "iso_date"
  },
  "include_details": false
}
```
**Response:** 
```json
{
  "success": true,
  "metrics": {
    "ingestion_rate": {
      "value": 45.2,
      "unit": "items_per_hour",
      "trend": "increasing",
      "change_percent": 12.5
    },
    "search_performance": {
      "value": 89.3,
      "unit": "milliseconds",
      "trend": "improving",
      "change_percent": -8.2
    },
    "optimization_effectiveness": {
      "value": 15.7,
      "unit": "percentage",
      "trend": "stable",
      "change_percent": 2.1
    }
  },
  "period": {
    "start": "iso_date",
    "end": "iso_date"
  }
}
```
**Errors:** 
- `INVALID_METRIC_TYPE`: Specified metric type not supported
- `INVALID_TIME_PERIOD`: Time period not supported
- `NO_DATA_AVAILABLE`: No data available for specified period

### GET /rpc/optimization_status

**Purpose:** Get current status of optimization processes
**Parameters:** 
```json
{
  "include_history": false,
  "limit": 10
}
```
**Response:** 
```json
{
  "success": true,
  "current_status": {
    "is_running": false,
    "last_optimization": {
      "id": "uuid",
      "type": "full",
      "started_at": "iso_date",
      "completed_at": "iso_date",
      "success": true,
      "performance_improvement": 12.5
    },
    "next_scheduled": "iso_date"
  },
  "recent_history": [
    {
      "id": "uuid",
      "type": "embedding_update",
      "started_at": "iso_date",
      "duration_ms": 25000,
      "success": true,
      "content_count": 1200
    }
  ]
}
```
**Errors:** 
- `STATUS_UNAVAILABLE`: Unable to retrieve optimization status

### POST /rpc/query_feedback

**Purpose:** Submit feedback on search query results for optimization
**Parameters:** 
```json
{
  "query_id": "uuid (optional)",
  "query_text": "string",
  "satisfaction_score": 1-5,
  "feedback_type": "positive|negative|neutral",
  "details": "string (optional)",
  "result_ids": ["uuid"]
}
```
**Response:** 
```json
{
  "success": true,
  "feedback_id": "uuid",
  "optimization_triggered": false
}
```
**Errors:** 
- `INVALID_SCORE`: Satisfaction score must be 1-5
- `QUERY_NOT_FOUND`: Query ID not found

## Controllers

### IRAGLController

**Purpose:** Main controller for IRAGL functionality
**Business Logic:**
- Validate input parameters and entity relationships
- Coordinate between ingestion, optimization, and search components
- Handle error conditions and provide meaningful error messages
- Track performance metrics for all operations

**Error Handling:**
- Graceful degradation when optimization processes fail
- Retry mechanisms for transient failures
- Detailed error logging for debugging
- User-friendly error messages

### KnowledgeStreamController

**Purpose:** Handle knowledge stream ingestion and processing
**Business Logic:**
- Validate content and source entity relationships
- Generate embeddings using configured models
- Create automatic content associations
- Trigger optimization processes when appropriate

### OptimizationController

**Purpose:** Manage knowledge base optimization processes
**Business Logic:**
- Coordinate different optimization types
- Prevent concurrent optimization runs
- Track optimization performance and effectiveness
- Schedule background optimization tasks

### SearchController

**Purpose:** Handle IRAGL-enhanced search operations
**Business Logic:**
- Apply organizational context weighting
- Combine vector similarity with association strength
- Track query performance and user feedback
- Provide result ranking and relevance scoring

## Integration with Existing RPC

### Extend ParagonicServer

Add new methods to the existing `ParagonicServer` struct:

```rust
impl ParagonicServer {
    // New IRAGL methods
    pub fn handle_ingest_knowledge_stream(&self, params: &Option<Value>) -> Result<String, RpcError>;
    pub fn handle_associate_content(&self, params: &Option<Value>) -> Result<String, RpcError>;
    pub fn handle_optimize_knowledge_base(&self, params: &Option<Value>) -> Result<String, RpcError>;
    pub fn handle_iragl_search(&self, params: &Option<Value>) -> Result<String, RpcError>;
    pub fn handle_knowledge_analytics(&self, params: &Option<Value>) -> Result<String, RpcError>;
    pub fn handle_optimization_status(&self, params: &Option<Value>) -> Result<String, RpcError>;
    pub fn handle_query_feedback(&self, params: &Option<Value>) -> Result<String, RpcError>;
}
```

### Update RPC Method Mapping

Extend the `rpc()` method to include new IRAGL endpoints:

```rust
fn rpc(&self, ctl: &ServerCtl, method: &str, params: &Option<Value>) -> Option<Self::RpcCallResult> {
    match method {
        // Existing methods...
        
        // New IRAGL methods
        "ingest_knowledge_stream" => Some(self.handle_ingest_knowledge_stream(params)),
        "associate_content" => Some(self.handle_associate_content(params)),
        "optimize_knowledge_base" => Some(self.handle_optimize_knowledge_base(params)),
        "iragl_search" => Some(self.handle_iragl_search(params)),
        "knowledge_analytics" => Some(self.handle_knowledge_analytics(params)),
        "optimization_status" => Some(self.handle_optimization_status(params)),
        "query_feedback" => Some(self.handle_query_feedback(params)),
        
        _ => None
    }
}
```

## Performance Considerations

### Response Time Targets
- **Ingestion:** < 5 seconds for typical content batches
- **Search:** < 100ms for standard queries
- **Analytics:** < 500ms for aggregated metrics
- **Optimization Status:** < 50ms for current status

### Caching Strategy
- Cache optimization status for 30 seconds
- Cache analytics results for 5 minutes
- Cache search results for 1 minute (if appropriate)

### Rate Limiting
- Limit optimization triggers to once per 10 minutes
- Limit analytics queries to 100 per minute
- Limit feedback submissions to 50 per minute

## Security and Validation

### Input Validation
- Validate all UUID parameters
- Sanitize text inputs
- Validate numeric ranges (association strength, scores)
- Check entity existence before creating associations

### Access Control
- Leverage existing authentication mechanisms
- Validate user permissions for organizational context
- Audit all optimization and ingestion activities

### Data Privacy
- Ensure all content remains within organizational boundaries
- Log access patterns for security monitoring
- Encrypt sensitive metadata if required 