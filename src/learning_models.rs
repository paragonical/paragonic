//! Learning system models for human skill building with ISRL
//!
//! This module contains the data models for the interleaved spaced repetition
//! learning system that helps humans develop and maintain skills while working
//! with AI agents.

use chrono::{DateTime, Utc};
use diesel::prelude::*;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use uuid::Uuid;

use crate::schema::*;
use crate::error::ParagonicResult;

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
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
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
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
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
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Insertable, Identifiable)]
#[diesel(table_name = practice_sessions)]
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
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
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
#[derive(Debug, Clone, Serialize, Deserialize, Queryable, Insertable, Identifiable)]
#[diesel(table_name = human_assistance_requests)]
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
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
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

// ============================================================================
// Core Learning Algorithms
// ============================================================================

/// SuperMemo 2 algorithm implementation with interleaving modifications
/// Based on the original SuperMemo 2 algorithm with enhancements for mixed skill areas
pub struct SuperMemo2Engine {
    /// E-Factor: measures how well the item is remembered
    /// Starts at 2.5, increases with successful recalls, decreases with failures
    pub e_factor: f64,
    /// Current interval in days
    pub interval: i32,
    /// Number of repetitions completed
    pub repetitions: i32,
    /// Quality of the last response (0-5 scale)
    pub quality: i32,
}

impl SuperMemo2Engine {
    /// Create a new SuperMemo 2 engine instance
    pub fn new() -> Self {
        Self {
            e_factor: 2.5,
            interval: 1,
            repetitions: 0,
            quality: 0,
        }
    }

    /// Process a response and calculate the next interval
    /// Quality should be 0-5: 0=total blackout, 5=perfect response
    pub fn process_response(&mut self, quality: i32) -> i32 {
        self.quality = quality;
        self.repetitions += 1;

        // SuperMemo 2 algorithm
        if quality < 3 {
            // Failed recall - reset interval and decrease E-Factor
            self.interval = 1;
            self.e_factor = (self.e_factor - 0.2).max(1.3);
        } else {
            // Successful recall - increase interval and potentially increase E-Factor
            if self.repetitions == 1 {
                self.interval = 6;
            } else if self.repetitions == 2 {
                self.interval = (self.interval as f64 * self.e_factor).round() as i32;
            } else {
                self.interval = (self.interval as f64 * self.e_factor).round() as i32;
            }

            // Update E-Factor based on quality
            let qf = 5.0 - quality as f64;
            self.e_factor = self.e_factor + (0.1 - qf * (0.08 + qf * 0.02));
            self.e_factor = self.e_factor.max(1.3);
        }

        self.interval
    }

    /// Apply interleaving modifications to reduce interval for mixed skill areas
    /// This helps prevent interference between different skills
    pub fn apply_interleaving_modification(&self, base_interval: i32, skill_mastery: f64) -> i32 {
        // Interleaving factor: 0.8 for low mastery, 0.95 for high mastery
        let interleaving_factor = 0.8 + (skill_mastery * 0.15);
        (base_interval as f64 * interleaving_factor).round() as i32
    }

    /// Calculate optimal interval based on forgetting curve
    pub fn calculate_optimal_interval(&self, target_retention: f64, forgetting_rate: f64) -> i32 {
        // Optimal interval = -ln(target_retention) / forgetting_rate
        // For target_retention = 0.8 and forgetting_rate = 0.1:
        // -ln(0.8) / 0.1 = -(-0.223) / 0.1 = 0.223 / 0.1 = 2.23 ≈ 2
        let optimal_interval = (-target_retention.ln() / forgetting_rate).round() as i32;
        optimal_interval.max(1)
    }

    /// Get current learning state
    pub fn get_state(&self) -> (f64, i32, i32) {
        (self.e_factor, self.interval, self.repetitions)
    }

    /// Reset the engine for a new learning item
    pub fn reset(&mut self) {
        self.e_factor = 2.5;
        self.interval = 1;
        self.repetitions = 0;
        self.quality = 0;
    }
}

/// Adaptive difficulty scaling based on performance
pub struct AdaptiveDifficultyScaler {
    /// Base difficulty level
    pub base_difficulty: i32,
    /// Performance history (0.0 to 1.0)
    pub performance_history: Vec<f64>,
    /// Target performance level
    pub target_performance: f64,
}

impl AdaptiveDifficultyScaler {
    /// Create a new adaptive difficulty scaler
    pub fn new(base_difficulty: i32, target_performance: f64) -> Self {
        Self {
            base_difficulty,
            performance_history: Vec::new(),
            target_performance,
        }
    }

    /// Add a performance result and calculate new difficulty
    pub fn add_performance(&mut self, performance: f64) -> i32 {
        self.performance_history.push(performance);
        
        // Keep only last 10 performances
        if self.performance_history.len() > 10 {
            self.performance_history.remove(0);
        }

        // Calculate average performance
        let avg_performance = self.performance_history.iter().sum::<f64>() / self.performance_history.len() as f64;
        
        // Adjust difficulty based on performance
        let difficulty_change = if avg_performance > self.target_performance + 0.1 {
            // Too easy - increase difficulty
            1
        } else if avg_performance < self.target_performance - 0.1 {
            // Too hard - decrease difficulty
            -1
        } else {
            // Just right - no adjustment
            0
        };

        self.base_difficulty = (self.base_difficulty + difficulty_change).max(1).min(10);
        self.base_difficulty
    }

    /// Get current difficulty level
    pub fn get_difficulty(&self) -> i32 {
        self.base_difficulty
    }
}

/// Practice session generator with mixed skill areas
pub struct PracticeSessionGenerator {
    /// Available skill areas
    pub skill_areas: Vec<String>,
    /// Target session size
    pub session_size: usize,
    /// Target average difficulty
    pub target_difficulty: f64,
}

impl PracticeSessionGenerator {
    /// Create a new practice session generator
    pub fn new(skill_areas: Vec<String>, session_size: usize, target_difficulty: f64) -> Self {
        Self {
            skill_areas,
            session_size,
            target_difficulty,
        }
    }

    /// Generate an interleaved practice session
    pub fn generate_session(&self) -> Vec<String> {
        let mut session_items = Vec::new();
        
        for i in 0..self.session_size {
            let skill_index = i % self.skill_areas.len();
            session_items.push(self.skill_areas[skill_index].clone());
        }
        
        session_items
    }

    /// Balance difficulty across skill areas
    pub fn balance_difficulty(&self, skill_difficulties: &mut Vec<i32>) -> Vec<i32> {
        let current_avg = skill_difficulties.iter().sum::<i32>() as f64 / skill_difficulties.len() as f64;
        
        // Adjust difficulties to balance
        for difficulty in skill_difficulties.iter_mut() {
            if *difficulty < self.target_difficulty as i32 {
                *difficulty += 1; // Increase easy items
            } else if *difficulty > self.target_difficulty as i32 {
                *difficulty -= 1; // Decrease hard items
            }
        }
        
        skill_difficulties.clone()
    }
}

/// Learning retention measurement
pub struct RetentionMeasurer {
    /// Initial score
    pub initial_score: i32,
    /// Retention rate per day
    pub retention_rate: f64,
}

impl RetentionMeasurer {
    /// Create a new retention measurer
    pub fn new(initial_score: i32, retention_rate: f64) -> Self {
        Self {
            initial_score,
            retention_rate,
        }
    }

    /// Calculate expected retention after given days
    pub fn calculate_retention(&self, days: i32) -> i32 {
        let expected_retention = self.initial_score as f64 * self.retention_rate.powi(days);
        expected_retention.round() as i32
    }

    /// Calculate retention rate from two measurements
    pub fn calculate_retention_rate(initial_score: i32, final_score: i32, days: i32) -> f64 {
        if days == 0 || initial_score == 0 {
            return 1.0;
        }
        (final_score as f64 / initial_score as f64).powf(1.0 / days as f64)
    }
}

/// Transfer learning assessment
pub struct TransferLearningAssessor {
    /// Primary skill score
    pub primary_skill_score: i32,
    /// Transfer factors for different skill distances
    pub transfer_factors: Vec<f64>,
}

impl TransferLearningAssessor {
    /// Create a new transfer learning assessor
    pub fn new(primary_skill_score: i32) -> Self {
        Self {
            primary_skill_score,
            transfer_factors: vec![0.3, 0.2, 0.1, 0.05], // Transfer to related, adjacent, distant, very distant
        }
    }

    /// Calculate transferred score for a related skill
    pub fn calculate_transferred_score(&self, skill_distance: usize) -> i32 {
        let transfer_factor = self.transfer_factors.get(skill_distance).unwrap_or(&0.0);
        (self.primary_skill_score as f64 * transfer_factor).round() as i32
    }

    /// Get all transferred scores for different skill distances
    pub fn get_all_transferred_scores(&self) -> Vec<i32> {
        self.transfer_factors.iter()
            .map(|factor| (self.primary_skill_score as f64 * factor).round() as i32)
            .collect()
    }
}

/// Calculate next practice interval based on human judgment and current score
pub fn calculate_next_practice_interval(
    current_score: i32,
    human_judgment: &str,
    base_frequency_days: i32
) -> i32 {
    match human_judgment {
        "not_seen" => {
            // First encounter - schedule for tomorrow
            1
        },
        "forgotten" => {
            // Almost recalled - decrease interval, increase frequency
            let reduction_factor = (10000 - current_score) as f64 / 10000.0;
            (base_frequency_days as f64 * reduction_factor * 0.5).max(1.0) as i32
        },
        "recalled" => {
            // Successful recall - increase interval based on current score
            let score_factor = current_score as f64 / 10000.0;
            let increase_factor = 1.0 + (score_factor * 2.0); // Up to 3x longer intervals
            (base_frequency_days as f64 * increase_factor).max(1.0) as i32
        },
        _ => base_frequency_days // Default fallback
    }
}

/// Update learning state based on human judgment
pub fn update_learning_state(
    current_state: &mut HumanLearningState,
    human_judgment: &str,
    base_frequency_days: i32
) {
    let now = chrono::Utc::now();
    
    // Update learning state
    current_state.learning_state = human_judgment.to_string();
    current_state.last_practiced = Some(now);
    current_state.total_practice_sessions += 1;
    
    // Calculate new score based on judgment
    let score_change = match human_judgment {
        "not_seen" => 0, // No change for first encounter
        "forgotten" => {
            // Decrease score based on how much was forgotten
            let current_score = current_state.current_score as f64;
            let decrease = (current_score * 0.2).min(2000.0); // Max 20% decrease
            -(decrease as i32)
        },
        "recalled" => {
            // Increase score based on current level
            let current_score = current_state.current_score as f64;
            let increase = (10000.0 - current_score) * 0.15; // 15% of remaining potential
            increase as i32
        },
        _ => 0
    };
    
    current_state.current_score = (current_state.current_score + score_change)
        .max(0)
        .min(10000);
    
    // Calculate new practice frequency
    let new_interval = calculate_next_practice_interval(
        current_state.current_score,
        human_judgment,
        base_frequency_days
    );
    
    current_state.practice_frequency_days = new_interval;
    current_state.next_practice_date = Some(now + chrono::Duration::days(new_interval as i64));
}

/// Check if unit is ready for presentation based on dependencies
pub fn is_unit_ready_for_presentation(
    unit_id: &Uuid,
    person_id: &Uuid,
    conn: &mut diesel::PgConnection
) -> ParagonicResult<bool> {
    use crate::schema::{learning_units, human_learning_states};
    
    // Get unit dependencies
    let unit = learning_units::table
        .find(unit_id)
        .first::<LearningUnit>(conn)?;
    
    if let Some(dependencies) = unit.dependencies {
        let dependency_ids: Vec<Uuid> = serde_json::from_value(dependencies)?;
        
        // Check if all dependencies have minimum score (e.g., 7000 = 70%)
        for dep_id in dependency_ids {
            let dep_state = human_learning_states::table
                .filter(human_learning_states::person_id.eq(person_id))
                .filter(human_learning_states::learning_unit_id.eq(dep_id))
                .first::<HumanLearningState>(conn);
            
            match dep_state {
                Ok(state) if state.current_score < 7000 => return Ok(false),
                Err(_) => return Ok(false), // Dependency not started
                _ => continue
            }
        }
    }
    
    Ok(true)
}

/// Estimate completion dates for 80% and 95% mastery
pub fn estimate_completion_dates(
    person_id: &Uuid,
    skill_area_id: &Uuid,
    conn: &mut diesel::PgConnection
) -> ParagonicResult<CompletionEstimates> {
    use crate::schema::{human_learning_states, learning_units};
    
    // Get all learning units for the skill area
    let learning_units = learning_units::table
        .filter(learning_units::skill_area_id.eq(skill_area_id))
        .load::<LearningUnit>(conn)?;
    
    let total_units = learning_units.len();
    if total_units == 0 {
        return Ok(CompletionEstimates {
            eighty_percent_completion: chrono::Utc::now(),
            ninety_five_percent_completion: chrono::Utc::now(),
            current_mastery_percentage: 0,
            estimated_remaining_days: 0,
        });
    }
    
    // Get learning states for this person and skill area
    let learning_states = human_learning_states::table
        .filter(human_learning_states::person_id.eq(person_id))
        .filter(human_learning_states::learning_unit_id.eq_any(
            learning_units.iter().map(|u| u.id)
        ))
        .load::<HumanLearningState>(conn)?;
    
    // Calculate current mastery
    let mastered_units = learning_states.iter()
        .filter(|state| state.current_score >= 8000) // 80% mastery threshold
        .count();
    
    let current_mastery_rate = mastered_units as f64 / total_units as f64;
    
    // Calculate average practice frequency
    let avg_practice_frequency = if !learning_states.is_empty() {
        learning_states.iter()
            .map(|state| state.practice_frequency_days as f64)
            .sum::<f64>() / learning_states.len() as f64
    } else {
        7.0 // Default to weekly practice
    };
    
    // Calculate remaining units and estimated time
    let units_to_80_percent = ((total_units as f64 * 0.8) - mastered_units as f64).max(0.0);
    let units_to_95_percent = ((total_units as f64 * 0.95) - mastered_units as f64).max(0.0);
    
    let days_to_80_percent = (units_to_80_percent * avg_practice_frequency).ceil() as i32;
    let days_to_95_percent = (units_to_95_percent * avg_practice_frequency).ceil() as i32;
    
    Ok(CompletionEstimates {
        eighty_percent_completion: chrono::Utc::now() + chrono::Duration::days(days_to_80_percent as i64),
        ninety_five_percent_completion: chrono::Utc::now() + chrono::Duration::days(days_to_95_percent as i64),
        current_mastery_percentage: (current_mastery_rate * 100.0).round() as i32,
        estimated_remaining_days: days_to_95_percent
    })
}

/// Calculate unit priority for practice session generation
pub fn calculate_unit_priority(
    state: &HumanLearningState,
    enrollment_level: &str
) -> f64 {
    let base_priority = match state.learning_state.as_str() {
        "not_seen" => 1.0,
        "forgotten" => 0.8,
        "recalled" => 0.3,
        _ => 0.5
    };
    
    // Adjust based on score (lower scores = higher priority)
    let score_factor = 1.0 - (state.current_score as f64 / 10000.0);
    
    // Adjust based on enrollment level
    let enrollment_factor = match enrollment_level {
        "light" => 0.7,
        "moderate" => 1.0,
        "intensive" => 1.3,
        _ => 1.0
    };
    
    // Adjust based on time since last practice
    let time_factor = if let Some(last_practiced) = state.last_practiced {
        let days_since = (chrono::Utc::now() - last_practiced).num_days() as f64;
        let expected_interval = state.practice_frequency_days as f64;
        if days_since > expected_interval {
            1.5 // Overdue for practice
        } else {
            1.0
        }
    } else {
        1.0
    };
    
    base_priority * score_factor * enrollment_factor * time_factor
}

/// Generate adaptive practice session based on human enrollment and readiness
pub fn generate_practice_session(
    person_id: &Uuid,
    skill_area_id: &Uuid,
    enrollment_level: &str,
    session_duration_minutes: i32,
    conn: &mut diesel::PgConnection
) -> ParagonicResult<PracticeSession> {
    use crate::schema::{human_learning_states, learning_units};
    
    // Get all learning units for the skill area
    let learning_units = learning_units::table
        .filter(learning_units::skill_area_id.eq(skill_area_id))
        .load::<LearningUnit>(conn)?;
    
    // Get learning states for this person
    let learning_states = human_learning_states::table
        .filter(human_learning_states::person_id.eq(person_id))
        .filter(human_learning_states::learning_unit_id.eq_any(
            learning_units.iter().map(|u| u.id)
        ))
        .load::<HumanLearningState>(conn)?;
    
    // Filter units ready for practice based on dependencies
    let mut ready_units = Vec::new();
    for unit in &learning_units {
        if is_unit_ready_for_presentation(&unit.id, person_id, conn)? {
            // Find corresponding learning state or create default
            let state = learning_states.iter()
                .find(|s| s.learning_unit_id == unit.id)
                .cloned()
                .unwrap_or_else(|| HumanLearningState {
                    id: Uuid::new_v4(),
                    person_id: *person_id,
                    learning_unit_id: unit.id,
                    learning_state: "not_seen".to_string(),
                    current_score: 0,
                    last_practiced: None,
                    practice_frequency_days: 7,
                    next_practice_date: None,
                    total_practice_sessions: 0,
                    metadata: None,
                                created_at: Some(chrono::Utc::now()),
            updated_at: Some(chrono::Utc::now()),
                });
            
            ready_units.push((unit.clone(), state));
        }
    }
    
    // Prioritize units based on score and enrollment level
    ready_units.sort_by(|(_, a_state), (_, b_state)| {
        let a_priority = calculate_unit_priority(a_state, enrollment_level);
        let b_priority = calculate_unit_priority(b_state, enrollment_level);
        b_priority.partial_cmp(&a_priority).unwrap_or(std::cmp::Ordering::Equal)
    });
    
    // Select units for session based on enrollment level
    let units_per_session = match enrollment_level {
        "light" => 3,
        "moderate" => 5,
        "intensive" => 8,
        _ => 5, // Default to moderate
    };
    
    let selected_units: Vec<Uuid> = ready_units.iter()
        .take(units_per_session)
        .map(|(unit, _)| unit.id)
        .collect();
    
    // Get completion estimates
    let completion_estimates = estimate_completion_dates(person_id, skill_area_id, conn)?;
    
    Ok(PracticeSession {
        id: Uuid::new_v4(),
        person_id: *person_id,
        session_type: "adaptive_practice".to_string(),
        title: format!("{} Practice Session", enrollment_level),
        description: Some(format!("Adaptive practice session with {} learning units", selected_units.len())),
        enrollment_level: enrollment_level.to_string(),
        target_duration_minutes: Some(session_duration_minutes),
        actual_duration_minutes: None,
        learning_units: Some(json!(selected_units)),
        session_status: "scheduled".to_string(),
        completion_percentage: None,
        metadata: Some(json!({
            "enrollment_level": enrollment_level,
            "units_count": selected_units.len(),
            "estimated_completion_80_percent": completion_estimates.eighty_percent_completion,
            "estimated_completion_95_percent": completion_estimates.ninety_five_percent_completion,
            "current_mastery_percentage": completion_estimates.current_mastery_percentage
        })),
        scheduled_at: Some(chrono::Utc::now()),
        started_at: None,
        completed_at: None,
        created_at: Some(chrono::Utc::now()),
        updated_at: Some(chrono::Utc::now()),
    })
}

/// Process human learning judgment and update state
pub fn process_human_judgment(
    person_id: &Uuid,
    learning_unit_id: &Uuid,
    human_judgment: &str,
    conn: &mut diesel::PgConnection
) -> ParagonicResult<HumanLearningState> {
    use crate::schema::human_learning_states;
    
    // Find or create learning state
    let mut learning_state = human_learning_states::table
        .filter(human_learning_states::person_id.eq(person_id))
        .filter(human_learning_states::learning_unit_id.eq(learning_unit_id))
        .first::<HumanLearningState>(conn)
        .unwrap_or_else(|_| HumanLearningState {
            id: Uuid::new_v4(),
            person_id: *person_id,
            learning_unit_id: *learning_unit_id,
            learning_state: "not_seen".to_string(),
            current_score: 0,
            last_practiced: None,
            practice_frequency_days: 7,
            next_practice_date: None,
            total_practice_sessions: 0,
            metadata: None,
                                created_at: Some(chrono::Utc::now()),
                    updated_at: Some(chrono::Utc::now()),
        });
    
    // Update learning state based on judgment
    update_learning_state(&mut learning_state, human_judgment, 7);
    
    // Save to database
    if learning_state.id == Uuid::nil() {
        // New state - insert
        let new_state = NewHumanLearningState {
            person_id: learning_state.person_id,
            learning_unit_id: learning_state.learning_unit_id,
            learning_state: learning_state.learning_state.clone(),
            current_score: learning_state.current_score,
            practice_frequency_days: learning_state.practice_frequency_days,
            next_practice_date: learning_state.next_practice_date,
            metadata: learning_state.metadata.clone(),
        };
        
        diesel::insert_into(human_learning_states::table)
            .values(&new_state)
            .execute(conn)?;
        
        // Fetch the inserted record
        human_learning_states::table
            .filter(human_learning_states::person_id.eq(learning_state.person_id))
            .filter(human_learning_states::learning_unit_id.eq(learning_state.learning_unit_id))
            .first::<HumanLearningState>(conn)
            .map_err(|e| crate::error::ParagonicError::Database(e.to_string()))
    } else {
        // Existing state - update
        diesel::update(human_learning_states::table.find(learning_state.id))
            .set((
                human_learning_states::learning_state.eq(&learning_state.learning_state),
                human_learning_states::current_score.eq(learning_state.current_score),
                human_learning_states::last_practiced.eq(learning_state.last_practiced),
                human_learning_states::practice_frequency_days.eq(learning_state.practice_frequency_days),
                human_learning_states::next_practice_date.eq(learning_state.next_practice_date),
                human_learning_states::total_practice_sessions.eq(learning_state.total_practice_sessions),
                human_learning_states::updated_at.eq(chrono::Utc::now()),
            ))
            .execute(conn)?;
        
        // Fetch the updated record
        human_learning_states::table.find(learning_state.id)
            .first::<HumanLearningState>(conn)
            .map_err(|e| crate::error::ParagonicError::Database(e.to_string()))
    }
}

/// Find humans with specific expertise for AI assistance requests
pub fn find_humans_with_expertise(
    required_skills: &[String],
    minimum_score: i32,
    conn: &mut diesel::PgConnection
) -> ParagonicResult<Vec<Uuid>> {
    use crate::schema::{human_learning_states, learning_units, skill_areas};
    
    // Get skill area IDs for required skills
    let skill_area_ids = skill_areas::table
        .filter(skill_areas::name.eq_any(required_skills))
        .select(skill_areas::id)
        .load::<Uuid>(conn)?;
    
    // Find humans with high scores in these skill areas
    let expert_humans = human_learning_states::table
        .filter(human_learning_states::learning_unit_id.eq_any(
            learning_units::table
                .filter(learning_units::skill_area_id.eq_any(skill_area_ids))
                .select(learning_units::id)
        ))
        .filter(human_learning_states::current_score.ge(minimum_score))
        .select(human_learning_states::person_id)
        .distinct()
        .load::<Uuid>(conn)?;
    
    Ok(expert_humans)
}

/// Create human assistance request for AI agents calling upon skilled humans
pub fn create_human_assistance_request(
    requester_id: &Uuid,
    problem_description: &str,
    required_skills: &[String],
    difficulty_level: &str,
    urgency_level: &str,
    estimated_completion_hours: Option<i32>,
    conn: &mut diesel::PgConnection
) -> ParagonicResult<HumanAssistanceRequest> {
    use crate::schema::human_assistance_requests;
    
    // Find available experts
    let available_experts = find_humans_with_expertise(required_skills, 8500, conn)?; // 85% mastery threshold
    
    let new_request = NewHumanAssistanceRequest {
        requester_id: *requester_id,
        problem_description: problem_description.to_string(),
        required_skills: json!(required_skills),
        difficulty_level: difficulty_level.to_string(),
        urgency_level: urgency_level.to_string(),
        estimated_completion_hours,
        available_experts: Some(json!(available_experts)),
        metadata: None,
    };
    
    diesel::insert_into(human_assistance_requests::table)
        .values(&new_request)
        .execute(conn)?;
    
    // Fetch the inserted record
    human_assistance_requests::table
        .filter(human_assistance_requests::requester_id.eq(requester_id))
        .filter(human_assistance_requests::problem_description.eq(problem_description))
        .order(human_assistance_requests::created_at.desc())
        .first::<HumanAssistanceRequest>(conn)
        .map_err(|e| crate::error::ParagonicError::Database(e.to_string()))
}
