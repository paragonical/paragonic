//! Learning system models for human skill building with ISRL
//!
//! This module contains the data models for the interleaved spaced repetition
//! learning system that helps humans develop and maintain skills while working
//! with AI agents.

use chrono::{DateTime, Utc};
use diesel::prelude::*;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use uuid::Uuid;

use crate::schema::*;

/// Skill area model representing different areas of expertise as a directed graph
/// where difficulty is determined by prerequisite knowledge and dependencies
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Insertable, Identifiable)]
#[diesel(table_name = skill_areas)]
#[diesel(check_for_backend(diesel::pg::Pg))]
pub struct SkillArea {
    pub id: Uuid,
    pub name: String,
    pub category: String,
    pub description: Option<String>,
    /// Graph structure: nodes are skills, edges are prerequisites
    /// Format: {
    ///   "nodes": [{"id": "skill1", "name": "Variables", "description": "Understanding variables"}],
    ///   "edges": [{"from": "skill1", "to": "skill2", "type": "prerequisite"}],
    ///   "difficulty_weights": {"skill1": 1, "skill2": 3} // based on prerequisite depth
    /// }
    pub skill_graph: Value,
    /// Learning objectives and outcomes for this skill area
    pub learning_objectives: Option<Value>,
    pub metadata: Option<Value>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// New skill area for insertion
#[derive(Debug, Clone, Serialize, Deserialize, Insertable)]
#[diesel(table_name = skill_areas)]
pub struct NewSkillArea {
    pub name: String,
    pub category: String,
    pub description: Option<String>,
    pub skill_graph: Value,
    pub learning_objectives: Option<Value>,
    pub metadata: Option<Value>,
}

/// Practice item model for learning exercises
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Insertable, Identifiable, Associations)]
#[diesel(table_name = practice_items)]
#[diesel(belongs_to(SkillArea))]
#[diesel(check_for_backend(diesel::pg::Pg))]
pub struct PracticeItem {
    pub id: Uuid,
    pub skill_area_id: Uuid,
    pub title: String,
    pub content: String,
    pub item_type: String,
    pub difficulty_level: i32,
    pub correct_answer: Option<String>,
    pub options: Option<Value>,
    pub hints: Option<Value>,
    pub explanation: Option<String>,
    pub estimated_time_minutes: Option<i32>,
    pub tags: Option<Value>,
    pub metadata: Option<Value>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// New practice item for insertion
#[derive(Debug, Clone, Serialize, Deserialize, Insertable)]
#[diesel(table_name = practice_items)]
pub struct NewPracticeItem {
    pub skill_area_id: Uuid,
    pub title: String,
    pub content: String,
    pub item_type: String,
    pub difficulty_level: i32,
    pub correct_answer: Option<String>,
    pub options: Option<Value>,
    pub hints: Option<Value>,
    pub explanation: Option<String>,
    pub estimated_time_minutes: Option<i32>,
    pub tags: Option<Value>,
    pub metadata: Option<Value>,
}

/// Learning session model for tracking practice sessions
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Insertable, Identifiable, Associations)]
#[diesel(table_name = learning_sessions)]
#[diesel(belongs_to(crate::models::Person))]
#[diesel(check_for_backend(diesel::pg::Pg))]
pub struct LearningSession {
    pub id: Uuid,
    pub person_id: Uuid,
    pub session_type: String,
    pub title: String,
    pub description: Option<String>,
    pub target_duration_minutes: Option<i32>,
    pub actual_duration_minutes: Option<i32>,
    pub status: String,
    pub difficulty_target: Option<i32>,
    pub skill_areas_targeted: Option<Value>,
    pub metadata: Option<Value>,
    pub started_at: DateTime<Utc>,
    pub completed_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// New learning session for insertion
#[derive(Debug, Clone, Serialize, Deserialize, Insertable)]
#[diesel(table_name = learning_sessions)]
pub struct NewLearningSession {
    pub person_id: Uuid,
    pub session_type: String,
    pub title: String,
    pub description: Option<String>,
    pub target_duration_minutes: Option<i32>,
    pub status: String,
    pub difficulty_target: Option<i32>,
    pub skill_areas_targeted: Option<Value>,
    pub metadata: Option<Value>,
}

/// Session item model for tracking individual practice items in sessions
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Insertable, Identifiable, Associations)]
#[diesel(table_name = session_items)]
#[diesel(belongs_to(PracticeItem))]
#[diesel(check_for_backend(diesel::pg::Pg))]
pub struct SessionItem {
    pub id: Uuid,
    pub session_id: Uuid,
    pub practice_item_id: Uuid,
    pub order_in_session: i32,
    pub user_answer: Option<String>,
    pub is_correct: Option<bool>,
    pub time_spent_seconds: Option<i32>,
    pub confidence_level: Option<i32>,
    pub hints_used: Option<i32>,
    pub completed_at: Option<DateTime<Utc>>,
    pub metadata: Option<Value>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// New session item for insertion
#[derive(Debug, Clone, Serialize, Deserialize, Insertable)]
#[diesel(table_name = session_items)]
pub struct NewSessionItem {
    pub session_id: Uuid,
    pub practice_item_id: Uuid,
    pub order_in_session: i32,
    pub hints_used: Option<i32>,
    pub metadata: Option<Value>,
}

/// Skill assessment model for tracking skill evaluations
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Insertable, Identifiable, Associations)]
#[diesel(table_name = skill_assessments)]
#[diesel(belongs_to(crate::models::Person))]
#[diesel(belongs_to(SkillArea))]
#[diesel(check_for_backend(diesel::pg::Pg))]
pub struct SkillAssessment {
    pub id: Uuid,
    pub person_id: Uuid,
    pub skill_area_id: Uuid,
    pub assessment_type: String,
    pub score: Option<i32>, // Scaled by 100 (e.g., 67 = 0.67, 8500 = 85.00)
    pub confidence_level: Option<i32>,
    pub difficulty_level: Option<i32>,
    pub questions_answered: Option<i32>,
    pub questions_correct: Option<i32>,
    pub time_spent_minutes: Option<i32>,
    pub assessment_data: Option<Value>,
    pub metadata: Option<Value>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// New skill assessment for insertion
#[derive(Debug, Clone, Serialize, Deserialize, Insertable)]
#[diesel(table_name = skill_assessments)]
pub struct NewSkillAssessment {
    pub person_id: Uuid,
    pub skill_area_id: Uuid,
    pub assessment_type: String,
    pub score: Option<i32>, // Scaled by 100 (e.g., 67 = 0.67, 8500 = 85.00)
    pub confidence_level: Option<i32>,
    pub difficulty_level: Option<i32>,
    pub questions_answered: Option<i32>,
    pub questions_correct: Option<i32>,
    pub time_spent_minutes: Option<i32>,
    pub assessment_data: Option<Value>,
    pub metadata: Option<Value>,
}

/// Spaced repetition schedule model for ISRL algorithm
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Insertable, Identifiable, Associations)]
#[diesel(table_name = spaced_repetition_schedules)]
#[diesel(belongs_to(crate::models::Person))]
#[diesel(belongs_to(PracticeItem))]
#[diesel(belongs_to(SkillArea))]
#[diesel(check_for_backend(diesel::pg::Pg))]
pub struct SpacedRepetitionSchedule {
    pub id: Uuid,
    pub person_id: Uuid,
    pub practice_item_id: Uuid,
    pub skill_area_id: Uuid,
    pub interval_days: i32,
    pub ease_factor: i32, // Scaled by 100 (e.g., 250 = 2.50, 180 = 1.80)
    pub repetition_count: i32,
    pub next_review_date: chrono::NaiveDate,
    pub last_review_date: Option<chrono::NaiveDate>,
    pub last_review_score: Option<i32>,
    pub is_active: bool,
    pub metadata: Option<Value>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// New spaced repetition schedule for insertion
#[derive(Debug, Clone, Serialize, Deserialize, Insertable)]
#[diesel(table_name = spaced_repetition_schedules)]
pub struct NewSpacedRepetitionSchedule {
    pub person_id: Uuid,
    pub practice_item_id: Uuid,
    pub skill_area_id: Uuid,
    pub interval_days: i32,
    pub ease_factor: i32, // Scaled by 100 (e.g., 250 = 2.50, 180 = 1.80)
    pub repetition_count: i32,
    pub next_review_date: chrono::NaiveDate,
    pub is_active: bool,
    pub metadata: Option<Value>,
}

/// Expertise profile model for marketable skill summaries
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Insertable, Identifiable, Associations)]
#[diesel(table_name = expertise_profiles)]
#[diesel(belongs_to(crate::models::Person))]
#[diesel(check_for_backend(diesel::pg::Pg))]
pub struct ExpertiseProfile {
    pub id: Uuid,
    pub person_id: Uuid,
    pub profile_type: String,
    pub title: String,
    pub summary: Option<String>,
    pub skill_summary: Value,
    pub learning_velocity: Option<i32>, // Scaled by 100 (e.g., 1250 = 12.50, 850 = 8.50)
    pub total_practice_time_hours: Option<i32>, // Scaled by 100 (e.g., 1500 = 15.00 hours)
    pub total_sessions_completed: Option<i32>,
    pub average_session_score: Option<i32>, // Scaled by 100 (e.g., 7500 = 75.00)
    pub strongest_skills: Option<Value>,
    pub skills_in_development: Option<Value>,
    pub market_value_indicators: Option<Value>,
    pub is_public: bool,
    pub metadata: Option<Value>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// New expertise profile for insertion
#[derive(Debug, Clone, Serialize, Deserialize, Insertable)]
#[diesel(table_name = expertise_profiles)]
pub struct NewExpertiseProfile {
    pub person_id: Uuid,
    pub profile_type: String,
    pub title: String,
    pub summary: Option<String>,
    pub skill_summary: Value,
    pub learning_velocity: Option<i32>, // Scaled by 100 (e.g., 1250 = 12.50, 850 = 8.50)
    pub total_practice_time_hours: Option<i32>, // Scaled by 100 (e.g., 1500 = 15.00 hours)
    pub total_sessions_completed: Option<i32>,
    pub average_session_score: Option<i32>, // Scaled by 100 (e.g., 7500 = 75.00)
    pub strongest_skills: Option<Value>,
    pub skills_in_development: Option<Value>,
    pub market_value_indicators: Option<Value>,
    pub is_public: bool,
    pub metadata: Option<Value>,
}

/// Learning analytics model for tracking learning metrics
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Insertable, Identifiable, Associations)]
#[diesel(table_name = learning_analytics)]
#[diesel(belongs_to(crate::models::Person))]
#[diesel(belongs_to(SkillArea))]
#[diesel(check_for_backend(diesel::pg::Pg))]
pub struct LearningAnalytics {
    pub id: Uuid,
    pub person_id: Uuid,
    pub skill_area_id: Uuid,
    pub metric_type: String,
    pub metric_value: i32,
    pub measurement_date: chrono::NaiveDate,
    pub session_count: Option<i32>,
    pub practice_time_minutes: Option<i32>,
    pub confidence_interval_lower: Option<i32>,
    pub confidence_interval_upper: Option<i32>,
    pub trend_direction: Option<String>,
    pub metadata: Option<Value>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// New learning analytics for insertion
#[derive(Debug, Clone, Serialize, Deserialize, Insertable)]
#[diesel(table_name = learning_analytics)]
pub struct NewLearningAnalytics {
    pub person_id: Uuid,
    pub skill_area_id: Uuid,
    pub metric_type: String,
    pub metric_value: i32,
    pub measurement_date: chrono::NaiveDate,
    pub session_count: Option<i32>,
    pub practice_time_minutes: Option<i32>,
    pub confidence_interval_lower: Option<i32>,
    pub confidence_interval_upper: Option<i32>,
    pub trend_direction: Option<String>,
    pub metadata: Option<Value>,
}

/// Skill relationship model for adjacent skill intelligence
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Insertable, Identifiable)]
#[diesel(table_name = skill_relationships)]
#[diesel(check_for_backend(diesel::pg::Pg))]
pub struct SkillRelationship {
    pub id: Uuid,
    pub source_skill_area_id: Uuid,
    pub target_skill_area_id: Uuid,
    pub relationship_type: String,
    pub relationship_strength: i32,
    pub learning_path_order: Option<i32>,
    pub description: Option<String>,
    pub metadata: Option<Value>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// New skill relationship for insertion
#[derive(Debug, Clone, Serialize, Deserialize, Insertable)]
#[diesel(table_name = skill_relationships)]
pub struct NewSkillRelationship {
    pub source_skill_area_id: Uuid,
    pub target_skill_area_id: Uuid,
    pub relationship_type: String,
    pub relationship_strength: i32,
    pub learning_path_order: Option<i32>,
    pub description: Option<String>,
    pub metadata: Option<Value>,
}

/// Enum for practice item types
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum PracticeItemType {
    MultipleChoice,
    CodingChallenge,
    ConceptQuestion,
    Debugging,
}

impl std::fmt::Display for PracticeItemType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            PracticeItemType::MultipleChoice => write!(f, "multiple_choice"),
            PracticeItemType::CodingChallenge => write!(f, "coding_challenge"),
            PracticeItemType::ConceptQuestion => write!(f, "concept_question"),
            PracticeItemType::Debugging => write!(f, "debugging"),
        }
    }
}

impl std::str::FromStr for PracticeItemType {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "multiple_choice" => Ok(PracticeItemType::MultipleChoice),
            "coding_challenge" => Ok(PracticeItemType::CodingChallenge),
            "concept_question" => Ok(PracticeItemType::ConceptQuestion),
            "debugging" => Ok(PracticeItemType::Debugging),
            _ => Err(format!("Unknown practice item type: {}", s)),
        }
    }
}

/// Enum for session types
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum SessionType {
    Practice,
    Assessment,
    Review,
    AdjacentSkill,
}

impl std::fmt::Display for SessionType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            SessionType::Practice => write!(f, "practice"),
            SessionType::Assessment => write!(f, "assessment"),
            SessionType::Review => write!(f, "review"),
            SessionType::AdjacentSkill => write!(f, "adjacent_skill"),
        }
    }
}

impl std::str::FromStr for SessionType {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "practice" => Ok(SessionType::Practice),
            "assessment" => Ok(SessionType::Assessment),
            "review" => Ok(SessionType::Review),
            "adjacent_skill" => Ok(SessionType::AdjacentSkill),
            _ => Err(format!("Unknown session type: {}", s)),
        }
    }
}

/// Enum for session status
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum SessionStatus {
    InProgress,
    Completed,
    Paused,
    Abandoned,
}

impl std::fmt::Display for SessionStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            SessionStatus::InProgress => write!(f, "in_progress"),
            SessionStatus::Completed => write!(f, "completed"),
            SessionStatus::Paused => write!(f, "paused"),
            SessionStatus::Abandoned => write!(f, "abandoned"),
        }
    }
}

impl std::str::FromStr for SessionStatus {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "in_progress" => Ok(SessionStatus::InProgress),
            "completed" => Ok(SessionStatus::Completed),
            "paused" => Ok(SessionStatus::Paused),
            "abandoned" => Ok(SessionStatus::Abandoned),
            _ => Err(format!("Unknown session status: {}", s)),
        }
    }
}

/// Enum for assessment types
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum AssessmentType {
    Initial,
    Progress,
    Final,
    AdjacentSkill,
}

impl std::fmt::Display for AssessmentType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            AssessmentType::Initial => write!(f, "initial"),
            AssessmentType::Progress => write!(f, "progress"),
            AssessmentType::Final => write!(f, "final"),
            AssessmentType::AdjacentSkill => write!(f, "adjacent_skill"),
        }
    }
}

impl std::str::FromStr for AssessmentType {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "initial" => Ok(AssessmentType::Initial),
            "progress" => Ok(AssessmentType::Progress),
            "final" => Ok(AssessmentType::Final),
            "adjacent_skill" => Ok(AssessmentType::AdjacentSkill),
            _ => Err(format!("Unknown assessment type: {}", s)),
        }
    }
}

/// Enum for relationship types
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum RelationshipType {
    Prerequisite,
    Complementary,
    Adjacent,
    Advanced,
}

impl std::fmt::Display for RelationshipType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            RelationshipType::Prerequisite => write!(f, "prerequisite"),
            RelationshipType::Complementary => write!(f, "complementary"),
            RelationshipType::Adjacent => write!(f, "adjacent"),
            RelationshipType::Advanced => write!(f, "advanced"),
        }
    }
}

impl std::str::FromStr for RelationshipType {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "prerequisite" => Ok(RelationshipType::Prerequisite),
            "complementary" => Ok(RelationshipType::Complementary),
            "adjacent" => Ok(RelationshipType::Adjacent),
            "advanced" => Ok(RelationshipType::Advanced),
            _ => Err(format!("Unknown relationship type: {}", s)),
        }
    }
}

/// Enum for metric types
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum MetricType {
    Accuracy,
    Speed,
    Confidence,
    Retention,
    AdjacentSkillGrowth,
}

impl std::fmt::Display for MetricType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            MetricType::Accuracy => write!(f, "accuracy"),
            MetricType::Speed => write!(f, "speed"),
            MetricType::Confidence => write!(f, "confidence"),
            MetricType::Retention => write!(f, "retention"),
            MetricType::AdjacentSkillGrowth => write!(f, "adjacent_skill_growth"),
        }
    }
}

impl std::str::FromStr for MetricType {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "accuracy" => Ok(MetricType::Accuracy),
            "speed" => Ok(MetricType::Speed),
            "confidence" => Ok(MetricType::Confidence),
            "retention" => Ok(MetricType::Retention),
            "adjacent_skill_growth" => Ok(MetricType::AdjacentSkillGrowth),
            _ => Err(format!("Unknown metric type: {}", s)),
        }
    }
}

/// Enum for trend directions
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum TrendDirection {
    Improving,
    Declining,
    Stable,
}

impl std::fmt::Display for TrendDirection {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            TrendDirection::Improving => write!(f, "improving"),
            TrendDirection::Declining => write!(f, "declining"),
            TrendDirection::Stable => write!(f, "stable"),
        }
    }
}

impl std::str::FromStr for TrendDirection {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "improving" => Ok(TrendDirection::Improving),
            "declining" => Ok(TrendDirection::Declining),
            "stable" => Ok(TrendDirection::Stable),
            _ => Err(format!("Unknown trend direction: {}", s)),
        }
    }
}

/// Learning unit model - atomic pieces of knowledge/skill
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Insertable, Identifiable, Associations)]
#[diesel(table_name = learning_units)]
#[diesel(belongs_to(SkillArea))]
#[diesel(check_for_backend(diesel::pg::Pg))]
pub struct LearningUnit {
    pub id: Uuid,
    pub skill_area_id: Uuid,
    pub title: String,
    pub content: String,
    pub unit_type: String, // "concept", "skill", "value", "culture", "procedure"
    pub difficulty_level: i32, // Scaled by 100 (e.g., 3500 = 35.00)
    pub estimated_time_minutes: Option<i32>,
    pub dependencies: Option<Value>, // Array of unit IDs that must be mastered first
    pub metadata: Option<Value>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// New learning unit for insertion
#[derive(Debug, Clone, Serialize, Deserialize, Insertable)]
#[diesel(table_name = learning_units)]
pub struct NewLearningUnit {
    pub skill_area_id: Uuid,
    pub title: String,
    pub content: String,
    pub unit_type: String,
    pub difficulty_level: i32, // Scaled by 100 (e.g., 3500 = 35.00)
    pub estimated_time_minutes: Option<i32>,
    pub dependencies: Option<Value>,
    pub metadata: Option<Value>,
}

/// Human learning state for each unit
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Insertable, Identifiable, Associations)]
#[diesel(table_name = human_learning_states)]
#[diesel(belongs_to(crate::models::Person))]
#[diesel(belongs_to(LearningUnit))]
#[diesel(check_for_backend(diesel::pg::Pg))]
pub struct HumanLearningState {
    pub id: Uuid,
    pub person_id: Uuid,
    pub learning_unit_id: Uuid,
    pub learning_state: String, // "not_seen", "forgotten", "recalled"
    pub current_score: i32, // Scaled by 100 (0-10000)
    pub last_practiced: Option<DateTime<Utc>>,
    pub practice_frequency_days: i32, // Days between practices based on score
    pub next_practice_date: Option<DateTime<Utc>>,
    pub total_practice_sessions: i32,
    pub metadata: Option<Value>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// New human learning state for insertion
#[derive(Debug, Clone, Serialize, Deserialize, Insertable)]
#[diesel(table_name = human_learning_states)]
pub struct NewHumanLearningState {
    pub person_id: Uuid,
    pub learning_unit_id: Uuid,
    pub learning_state: String,
    pub current_score: i32, // Scaled by 100 (0-10000)
    pub practice_frequency_days: i32,
    pub next_practice_date: Option<DateTime<Utc>>,
    pub metadata: Option<Value>,
}

/// Completion estimates for learning progress
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CompletionEstimates {
    pub eighty_percent_completion: DateTime<Utc>,
    pub ninety_five_percent_completion: DateTime<Utc>,
    pub current_mastery_percentage: i32,
    pub estimated_remaining_days: i32,
}

/// Practice session model for human-driven learning
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Insertable, Identifiable, Associations)]
#[diesel(table_name = practice_sessions)]
#[diesel(belongs_to(crate::models::Person))]
#[diesel(check_for_backend(diesel::pg::Pg))]
pub struct PracticeSession {
    pub id: Uuid,
    pub person_id: Uuid,
    pub session_type: String, // "adaptive_practice", "focused_review", "assessment"
    pub title: String,
    pub description: Option<String>,
    pub enrollment_level: String, // "light", "moderate", "intensive"
    pub target_duration_minutes: Option<i32>,
    pub actual_duration_minutes: Option<i32>,
    pub learning_units: Option<Value>, // Array of unit IDs in this session
    pub session_status: String, // "scheduled", "in_progress", "completed", "cancelled"
    pub completion_percentage: Option<i32>, // Scaled by 100
    pub metadata: Option<Value>,
    pub scheduled_at: Option<DateTime<Utc>>,
    pub started_at: Option<DateTime<Utc>>,
    pub completed_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// New practice session for insertion
#[derive(Debug, Clone, Serialize, Deserialize, Insertable)]
#[diesel(table_name = practice_sessions)]
pub struct NewPracticeSession {
    pub person_id: Uuid,
    pub session_type: String,
    pub title: String,
    pub description: Option<String>,
    pub enrollment_level: String,
    pub target_duration_minutes: Option<i32>,
    pub learning_units: Option<Value>,
    pub session_status: String,
    pub scheduled_at: Option<DateTime<Utc>>,
    pub metadata: Option<Value>,
}

/// Human assistance request model for AI agents calling upon skilled humans
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Insertable, Identifiable, Associations)]
#[diesel(table_name = human_assistance_requests)]
#[diesel(belongs_to(crate::models::Person))]
#[diesel(check_for_backend(diesel::pg::Pg))]
pub struct HumanAssistanceRequest {
    pub id: Uuid,
    pub requester_id: Uuid, // AI agent or person requesting assistance
    pub problem_description: String,
    pub required_skills: Value, // Array of required skill areas
    pub difficulty_level: String, // "easy", "medium", "hard", "expert"
    pub urgency_level: String, // "low", "medium", "high", "critical"
    pub estimated_completion_hours: Option<i32>,
    pub available_experts: Option<Value>, // Array of expert person IDs
    pub assigned_expert_id: Option<Uuid>,
    pub request_status: String, // "open", "assigned", "in_progress", "completed", "cancelled"
    pub metadata: Option<Value>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// New human assistance request for insertion
#[derive(Debug, Clone, Serialize, Deserialize, Insertable)]
#[diesel(table_name = human_assistance_requests)]
pub struct NewHumanAssistanceRequest {
    pub requester_id: Uuid,
    pub problem_description: String,
    pub required_skills: Value,
    pub difficulty_level: String,
    pub urgency_level: String,
    pub estimated_completion_hours: Option<i32>,
    pub available_experts: Option<Value>,
    pub metadata: Option<Value>,
}
