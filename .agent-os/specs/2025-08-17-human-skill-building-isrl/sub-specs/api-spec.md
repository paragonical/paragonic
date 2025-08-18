# API Specification

This is the API specification for the spec detailed in @.agent-os/specs/2025-08-17-human-skill-building-isrl/spec.md

> Created: 2025-08-17
> Version: 1.0.0

## API Overview

The Human Skill Building ISRL API provides endpoints for managing learning sessions, skill assessments, practice items, and expertise profiles. All endpoints follow RESTful conventions and return JSON responses.

## Authentication

All API endpoints require authentication via session token in the Authorization header:
```
Authorization: Bearer <session_token>
```

## Endpoints

### Skill Areas Management

#### GET /api/skill-areas

**Purpose:** Retrieve all available skill areas
**Parameters:** 
- `category` (optional): Filter by skill category
- `limit` (optional): Number of results to return (default: 50)
- `offset` (optional): Number of results to skip (default: 0)

**Response:**
```json
{
  "skill_areas": [
    {
      "id": "uuid",
      "name": "Programming Fundamentals",
      "category": "Development",
      "description": "Core programming concepts and best practices",
      "difficulty_levels": [
        {"level": 1, "description": "Basic syntax and concepts"}
      ],
      "created_at": "2025-08-17T10:00:00Z"
    }
  ],
  "total_count": 10,
  "limit": 50,
  "offset": 0
}
```

#### GET /api/skill-areas/{skill_area_id}

**Purpose:** Retrieve a specific skill area by ID
**Parameters:** None

**Response:**
```json
{
  "skill_area": {
    "id": "uuid",
    "name": "Programming Fundamentals",
    "category": "Development",
    "description": "Core programming concepts and best practices",
    "difficulty_levels": [...],
    "learning_objectives": [...],
    "created_at": "2025-08-17T10:00:00Z",
    "updated_at": "2025-08-17T10:00:00Z"
  }
}
```

### Practice Items Management

#### GET /api/practice-items

**Purpose:** Retrieve practice items with filtering options
**Parameters:**
- `skill_area_id` (optional): Filter by skill area
- `difficulty_level` (optional): Filter by difficulty level (1-10)
- `item_type` (optional): Filter by item type
- `limit` (optional): Number of results to return (default: 20)
- `offset` (optional): Number of results to skip (default: 0)

**Response:**
```json
{
  "practice_items": [
    {
      "id": "uuid",
      "skill_area_id": "uuid",
      "title": "Variable Scope Understanding",
      "content": "What is the output of this code snippet?",
      "difficulty_level": 2,
      "item_type": "question",
      "hints": ["Consider variable scope rules"],
      "created_at": "2025-08-17T10:00:00Z"
    }
  ],
  "total_count": 100,
  "limit": 20,
  "offset": 0
}
```

#### POST /api/practice-items

**Purpose:** Create a new practice item
**Request Body:**
```json
{
  "skill_area_id": "uuid",
  "title": "New Practice Item",
  "content": "Practice item content",
  "difficulty_level": 3,
  "item_type": "exercise",
  "correct_answer": "Expected answer",
  "hints": ["Hint 1", "Hint 2"],
  "metadata": {"tags": ["programming", "basics"]}
}
```

**Response:**
```json
{
  "practice_item": {
    "id": "uuid",
    "skill_area_id": "uuid",
    "title": "New Practice Item",
    "content": "Practice item content",
    "difficulty_level": 3,
    "item_type": "exercise",
    "created_at": "2025-08-17T10:00:00Z"
  }
}
```

### Learning Sessions Management

#### POST /api/learning-sessions

**Purpose:** Create a new learning session
**Request Body:**
```json
{
  "session_type": "practice",
  "skill_areas": ["uuid1", "uuid2"],
  "difficulty_range": {"min": 1, "max": 5},
  "session_length": 15
}
```

**Response:**
```json
{
  "session": {
    "id": "uuid",
    "user_id": "uuid",
    "session_type": "practice",
    "status": "active",
    "started_at": "2025-08-17T10:00:00Z",
    "total_items": 10,
    "completed_items": 0,
    "correct_items": 0
  },
  "session_items": [
    {
      "id": "uuid",
      "practice_item_id": "uuid",
      "order_index": 1,
      "practice_item": {
        "title": "Practice Item Title",
        "content": "Practice item content"
      }
    }
  ]
}
```

#### GET /api/learning-sessions/{session_id}

**Purpose:** Retrieve a specific learning session
**Parameters:** None

**Response:**
```json
{
  "session": {
    "id": "uuid",
    "user_id": "uuid",
    "session_type": "practice",
    "status": "completed",
    "started_at": "2025-08-17T10:00:00Z",
    "completed_at": "2025-08-17T10:15:00Z",
    "total_items": 10,
    "completed_items": 10,
    "correct_items": 8,
    "session_duration_minutes": 15
  },
  "session_items": [...]
}
```

#### PUT /api/learning-sessions/{session_id}/complete

**Purpose:** Complete a learning session
**Request Body:**
```json
{
  "session_items": [
    {
      "session_item_id": "uuid",
      "user_answer": "User's answer",
      "is_correct": true,
      "response_time_seconds": 45,
      "difficulty_rating": 3,
      "confidence_rating": 4
    }
  ]
}
```

**Response:**
```json
{
  "session": {
    "id": "uuid",
    "status": "completed",
    "completed_at": "2025-08-17T10:15:00Z",
    "total_items": 10,
    "completed_items": 10,
    "correct_items": 8
  },
  "skill_updates": [
    {
      "skill_area_id": "uuid",
      "skill_area_name": "Programming Fundamentals",
      "previous_level": 0.65,
      "new_level": 0.68,
      "improvement": 0.03
    }
  ]
}
```

### Skill Assessments

#### GET /api/skill-assessments

**Purpose:** Retrieve skill assessments for the current user
**Parameters:**
- `skill_area_id` (optional): Filter by skill area
- `assessment_type` (optional): Filter by assessment type
- `limit` (optional): Number of results to return (default: 20)

**Response:**
```json
{
  "skill_assessments": [
    {
      "id": "uuid",
      "skill_area_id": "uuid",
      "skill_area_name": "Programming Fundamentals",
      "assessment_type": "progress",
      "skill_level": 0.68,
      "confidence_interval": 0.05,
      "assessed_at": "2025-08-17T10:15:00Z"
    }
  ]
}
```

#### POST /api/skill-assessments

**Purpose:** Create a new skill assessment
**Request Body:**
```json
{
  "skill_area_id": "uuid",
  "assessment_type": "progress",
  "skill_level": 0.68,
  "confidence_interval": 0.05,
  "assessment_data": {
    "test_results": [...],
    "performance_metrics": {...}
  }
}
```

### Spaced Repetition Management

#### GET /api/spaced-repetition/due-items

**Purpose:** Retrieve practice items due for review
**Parameters:**
- `limit` (optional): Number of items to return (default: 10)

**Response:**
```json
{
  "due_items": [
    {
      "id": "uuid",
      "practice_item_id": "uuid",
      "current_interval_days": 7,
      "next_review_date": "2025-08-17T10:00:00Z",
      "ease_factor": 2.5,
      "repetition_count": 3,
      "practice_item": {
        "title": "Practice Item Title",
        "content": "Practice item content"
      }
    }
  ]
}
```

#### PUT /api/spaced-repetition/{schedule_id}/review

**Purpose:** Update spaced repetition schedule after review
**Request Body:**
```json
{
  "is_correct": true,
  "difficulty_rating": 3,
  "confidence_rating": 4
}
```

**Response:**
```json
{
  "schedule": {
    "id": "uuid",
    "current_interval_days": 14,
    "next_review_date": "2025-08-31T10:00:00Z",
    "ease_factor": 2.6,
    "repetition_count": 4,
    "consecutive_correct": 2
  }
}
```

### Expertise Profiles

#### GET /api/expertise-profiles

**Purpose:** Retrieve expertise profiles for the current user
**Parameters:**
- `profile_type` (optional): Filter by profile type

**Response:**
```json
{
  "expertise_profiles": [
    {
      "id": "uuid",
      "profile_name": "Senior Developer Profile",
      "profile_type": "public",
      "skill_summary": {
        "Programming Fundamentals": 0.85,
        "AI Collaboration": 0.72
      },
      "learning_velocity": 0.15,
      "total_learning_hours": 120,
      "last_updated": "2025-08-17T10:00:00Z"
    }
  ]
}
```

#### POST /api/expertise-profiles

**Purpose:** Create a new expertise profile
**Request Body:**
```json
{
  "profile_name": "Senior Developer Profile",
  "profile_type": "public",
  "metadata": {
    "bio": "Experienced developer with AI collaboration expertise",
    "specializations": ["Rust", "AI Integration"]
  }
}
```

#### PUT /api/expertise-profiles/{profile_id}

**Purpose:** Update an expertise profile
**Request Body:**
```json
{
  "profile_name": "Updated Profile Name",
  "metadata": {
    "bio": "Updated bio",
    "specializations": ["Rust", "AI Integration", "Machine Learning"]
  }
}
```

### Adjacent Skills Management

#### GET /api/adjacent-skills

**Purpose:** Retrieve adjacent skills recommendations for the current user
**Parameters:**
- `skill_area_id` (optional): Filter by specific skill area
- `relationship_type` (optional): Filter by relationship type (adjacent, prerequisite, complementary)
- `min_strength` (optional): Minimum relationship strength (0.0-1.0)
- `limit` (optional): Number of recommendations to return (default: 10)

**Response:**
```json
{
  "adjacent_skills": [
    {
      "skill_area": {
        "id": "uuid",
        "name": "System Design",
        "category": "Architecture",
        "description": "Design scalable and maintainable systems"
      },
      "relationship_type": "adjacent",
      "relationship_strength": 0.8,
      "learning_path_order": 1,
      "description": "Programming fundamentals provide the foundation for effective system design",
      "recommended_difficulty": 3,
      "estimated_learning_hours": 20
    }
  ]
}
```

#### POST /api/adjacent-skills/recommendations

**Purpose:** Generate personalized adjacent skill recommendations
**Request Body:**
```json
{
  "current_skills": ["uuid1", "uuid2"],
  "learning_goals": ["career_advancement", "project_specific"],
  "time_availability": "moderate",
  "preferred_categories": ["Development", "Architecture"]
}
```

**Response:**
```json
{
  "recommendations": [
    {
      "skill_area": {
        "id": "uuid",
        "name": "System Design",
        "category": "Architecture"
      },
      "recommendation_reason": "Builds on your strong programming fundamentals",
      "learning_path": [
        {"skill_id": "uuid", "order": 1, "estimated_hours": 10},
        {"skill_id": "uuid", "order": 2, "estimated_hours": 15}
      ],
      "market_value_impact": 0.25,
      "completion_estimate": "6-8 weeks"
    }
  ]
}
```

### Learning Analytics

#### GET /api/learning-analytics

**Purpose:** Retrieve learning analytics for the current user
**Parameters:**
- `metric_name` (optional): Filter by metric name
- `time_period` (optional): Filter by time period (daily, weekly, monthly)
- `start_date` (optional): Start date for analytics range
- `end_date` (optional): End date for analytics range

**Response:**
```json
{
  "analytics": [
    {
      "metric_name": "learning_velocity",
      "metric_value": 0.15,
      "metric_unit": "skills_per_week",
      "time_period": "weekly",
      "period_start": "2025-08-10T00:00:00Z",
      "period_end": "2025-08-17T23:59:59Z"
    }
  ]
}
```

#### GET /api/learning-analytics/summary

**Purpose:** Retrieve learning analytics summary
**Parameters:** None

**Response:**
```json
{
  "summary": {
    "total_learning_hours": 120,
    "average_session_length": 15,
    "total_sessions": 48,
    "current_streak_days": 7,
    "skill_areas_count": 5,
    "learning_velocity": 0.15,
    "retention_rate": 0.85
  }
}
```

## Error Responses

All endpoints may return the following error responses:

### 400 Bad Request
```json
{
  "error": "validation_error",
  "message": "Invalid request parameters",
  "details": {
    "field": "skill_area_id",
    "issue": "Invalid UUID format"
  }
}
```

### 401 Unauthorized
```json
{
  "error": "authentication_error",
  "message": "Invalid or missing authentication token"
}
```

### 404 Not Found
```json
{
  "error": "not_found",
  "message": "Resource not found",
  "resource": "skill_area",
  "id": "uuid"
}
```

### 500 Internal Server Error
```json
{
  "error": "internal_error",
  "message": "An unexpected error occurred"
}
```

## Rate Limiting

API endpoints are rate-limited to:
- 100 requests per minute per user for read operations
- 20 requests per minute per user for write operations
- 5 requests per minute per user for analytics endpoints

Rate limit headers are included in responses:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```
