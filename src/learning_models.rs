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

/// Skill assessment system for comprehensive skill evaluation
pub struct SkillAssessmentEngine {
    /// Assessment history for statistical analysis
    pub assessment_history: Vec<SkillAssessment>,
    /// Confidence level for statistical calculations (0.95 = 95%)
    pub confidence_level: f64,
    /// Minimum sample size for reliable assessment
    pub min_sample_size: usize,
}

impl SkillAssessmentEngine {
    /// Create a new skill assessment engine
    pub fn new(confidence_level: f64, min_sample_size: usize) -> Self {
        Self {
            assessment_history: Vec::new(),
            confidence_level,
            min_sample_size,
        }
    }

    /// Add an assessment to the history
    pub fn add_assessment(&mut self, assessment: SkillAssessment) {
        self.assessment_history.push(assessment);
    }

    /// Calculate comprehensive skill score with confidence intervals
    pub fn calculate_skill_score(&self, skill_area_id: &Uuid) -> SkillScoreResult {
        let relevant_assessments: Vec<&SkillAssessment> = self.assessment_history
            .iter()
            .filter(|a| a.skill_area_id == *skill_area_id)
            .collect();

        if relevant_assessments.len() < self.min_sample_size {
            return SkillScoreResult {
                skill_area_id: *skill_area_id,
                overall_score: 0,
                confidence_interval_lower: 0,
                confidence_interval_upper: 0,
                sample_size: relevant_assessments.len(),
                reliability_score: 0,
                trend_direction: TrendDirection::Stable,
                assessment_count: relevant_assessments.len(),
            };
        }

        // Calculate mean score
        let scores: Vec<i32> = relevant_assessments
            .iter()
            .filter_map(|a| a.score)
            .collect();
        
        let mean_score = scores.iter().sum::<i32>() as f64 / scores.len() as f64;
        
        // Calculate standard deviation
        let variance = scores.iter()
            .map(|&score| {
                let diff = score as f64 - mean_score;
                diff * diff
            })
            .sum::<f64>() / scores.len() as f64;
        let std_dev = variance.sqrt();
        
        // Calculate confidence interval using t-distribution
        let t_value = self.get_t_value(scores.len());
        let margin_of_error = t_value * std_dev / (scores.len() as f64).sqrt();
        
        let confidence_lower = (mean_score - margin_of_error).max(0.0).min(10000.0);
        let confidence_upper = (mean_score + margin_of_error).max(0.0).min(10000.0);
        
        // Calculate reliability score based on consistency
        let reliability = self.calculate_reliability_score(&scores);
        
        // Determine trend direction
        let trend = self.calculate_trend_direction(&relevant_assessments);
        
        SkillScoreResult {
            skill_area_id: *skill_area_id,
            overall_score: mean_score.round() as i32,
            confidence_interval_lower: confidence_lower.round() as i32,
            confidence_interval_upper: confidence_upper.round() as i32,
            sample_size: scores.len(),
            reliability_score: reliability,
            trend_direction: trend,
            assessment_count: relevant_assessments.len(),
        }
    }

    /// Calculate multi-dimensional skill measurement
    pub fn calculate_multi_dimensional_score(&self, skill_area_id: &Uuid) -> MultiDimensionalScore {
        let relevant_assessments: Vec<&SkillAssessment> = self.assessment_history
            .iter()
            .filter(|a| a.skill_area_id == *skill_area_id)
            .collect();

        // Calculate different dimensions
        let accuracy_score = self.calculate_accuracy_dimension(&relevant_assessments);
        let speed_score = self.calculate_speed_dimension(&relevant_assessments);
        let confidence_score = self.calculate_confidence_dimension(&relevant_assessments);
        let retention_score = self.calculate_retention_dimension(&relevant_assessments);

        MultiDimensionalScore {
            skill_area_id: *skill_area_id,
            accuracy_score,
            speed_score,
            confidence_score,
            retention_score,
            overall_composite_score: (accuracy_score + speed_score + confidence_score + retention_score) / 4,
            dimension_weights: vec![0.3, 0.2, 0.2, 0.3], // Accuracy, Speed, Confidence, Retention
        }
    }

    /// Identify skill gaps based on target proficiency levels
    pub fn identify_skill_gaps(&self, person_id: &Uuid, target_proficiencies: &[(Uuid, i32)]) -> Vec<SkillGap> {
        let mut skill_gaps = Vec::new();
        
        for (skill_area_id, target_score) in target_proficiencies {
            let current_score = self.calculate_skill_score(skill_area_id);
            let gap_size = *target_score - current_score.overall_score;
            
            if gap_size > 0 {
                skill_gaps.push(SkillGap {
                    skill_area_id: *skill_area_id,
                    current_score: current_score.overall_score,
                    target_score: *target_score,
                    gap_size,
                    priority_level: self.calculate_gap_priority(gap_size, current_score.reliability_score),
                    recommended_actions: self.generate_recommendations(gap_size, current_score.trend_direction),
                });
            }
        }
        
        // Sort by priority level (highest first)
        skill_gaps.sort_by(|a, b| b.priority_level.partial_cmp(&a.priority_level).unwrap_or(std::cmp::Ordering::Equal));
        skill_gaps
    }

    /// Calculate assessment accuracy and reliability
    pub fn calculate_assessment_quality(&self, skill_area_id: &Uuid) -> AssessmentQuality {
        let relevant_assessments: Vec<&SkillAssessment> = self.assessment_history
            .iter()
            .filter(|a| a.skill_area_id == *skill_area_id)
            .collect();

        if relevant_assessments.is_empty() {
            return AssessmentQuality {
                skill_area_id: *skill_area_id,
                reliability_score: 0,
                validity_score: 0,
                consistency_score: 0,
                sample_size: 0,
                quality_level: "insufficient_data".to_string(),
            };
        }

        let reliability = self.calculate_reliability_score_from_assessments(&relevant_assessments);
        let validity = self.calculate_validity_score(&relevant_assessments);
        let consistency = self.calculate_consistency_score(&relevant_assessments);

        let quality_level = if reliability > 8000 && validity > 8000 && consistency > 8000 {
            "excellent"
        } else if reliability > 6000 && validity > 6000 && consistency > 6000 {
            "good"
        } else if reliability > 4000 && validity > 4000 && consistency > 4000 {
            "fair"
        } else {
            "poor"
        };

        AssessmentQuality {
            skill_area_id: *skill_area_id,
            reliability_score: reliability,
            validity_score: validity,
            consistency_score: consistency,
            sample_size: relevant_assessments.len(),
            quality_level: quality_level.to_string(),
        }
    }

    /// Track skill progression over time
    pub fn track_skill_progression(&self, skill_area_id: &Uuid, time_period_days: i32) -> SkillProgression {
        let cutoff_date = chrono::Utc::now() - chrono::Duration::days(time_period_days as i64);
        
        let recent_assessments: Vec<&SkillAssessment> = self.assessment_history
            .iter()
            .filter(|a| a.skill_area_id == *skill_area_id && a.created_at >= cutoff_date)
            .collect();

        let older_assessments: Vec<&SkillAssessment> = self.assessment_history
            .iter()
            .filter(|a| a.skill_area_id == *skill_area_id && a.created_at < cutoff_date)
            .collect();

        let recent_avg = if !recent_assessments.is_empty() {
            recent_assessments.iter()
                .filter_map(|a| a.score)
                .sum::<i32>() as f64 / recent_assessments.len() as f64
        } else {
            0.0
        };

        let older_avg = if !older_assessments.is_empty() {
            older_assessments.iter()
                .filter_map(|a| a.score)
                .sum::<i32>() as f64 / older_assessments.len() as f64
        } else {
            0.0
        };

        let improvement_rate = if older_avg > 0.0 {
            ((recent_avg - older_avg) / older_avg) * 100.0
        } else {
            0.0
        };

        SkillProgression {
            skill_area_id: *skill_area_id,
            time_period_days,
            initial_score: older_avg.round() as i32,
            current_score: recent_avg.round() as i32,
            improvement_rate: improvement_rate.round() as i32,
            assessment_frequency: recent_assessments.len() as f64 / (time_period_days as f64 / 30.0), // per month
            trend_strength: self.calculate_trend_strength(&recent_assessments),
        }
    }

    // Helper methods
    fn get_t_value(&self, sample_size: usize) -> f64 {
        // Simplified t-value lookup for common confidence levels
        // In a real implementation, this would use a proper t-distribution table
        match (self.confidence_level, sample_size) {
            (0.95, n) if n >= 30 => 1.96,
            (0.95, n) if n >= 20 => 2.09,
            (0.95, n) if n >= 10 => 2.26,
            (0.95, _) => 2.78,
            (0.90, n) if n >= 30 => 1.65,
            (0.90, n) if n >= 20 => 1.73,
            (0.90, n) if n >= 10 => 1.81,
            (0.90, _) => 2.13,
            _ => 2.0, // Default fallback
        }
    }

    fn calculate_reliability_score(&self, scores: &[i32]) -> i32 {
        if scores.len() < 2 {
            return 0;
        }

        // Calculate coefficient of variation (lower is more reliable)
        let mean = scores.iter().sum::<i32>() as f64 / scores.len() as f64;
        let variance = scores.iter()
            .map(|&score| {
                let diff = score as f64 - mean;
                diff * diff
            })
            .sum::<f64>() / scores.len() as f64;
        let std_dev = variance.sqrt();
        
        let coefficient_of_variation = if mean > 0.0 { std_dev / mean } else { 0.0 };
        
        // Convert to reliability score (0-10000)
        let reliability = (1.0 - coefficient_of_variation.min(1.0)) * 10000.0;
        reliability.round() as i32
    }

    fn calculate_trend_direction(&self, assessments: &[&SkillAssessment]) -> TrendDirection {
        if assessments.len() < 3 {
            return TrendDirection::Stable;
        }

        // Sort by creation date
        let mut sorted_assessments = assessments.to_vec();
        sorted_assessments.sort_by(|a, b| a.created_at.cmp(&b.created_at));

        // Calculate linear trend
        let scores: Vec<i32> = sorted_assessments.iter()
            .filter_map(|a| a.score)
            .collect();

        if scores.len() < 3 {
            return TrendDirection::Stable;
        }

        let n = scores.len() as f64;
        let x_sum: f64 = (0..scores.len()).map(|i| i as f64).sum();
        let y_sum: f64 = scores.iter().map(|&s| s as f64).sum();
        let xy_sum: f64 = scores.iter().enumerate().map(|(i, &s)| i as f64 * s as f64).sum();
        let x2_sum: f64 = (0..scores.len()).map(|i| (i as f64).powi(2)).sum();

        let slope = (n * xy_sum - x_sum * y_sum) / (n * x2_sum - x_sum * x_sum);

        if slope > 100.0 {
            TrendDirection::Improving
        } else if slope < -100.0 {
            TrendDirection::Declining
        } else {
            TrendDirection::Stable
        }
    }

    fn calculate_accuracy_dimension(&self, assessments: &[&SkillAssessment]) -> i32 {
        assessments.iter()
            .filter_map(|a| a.score)
            .sum::<i32>() / assessments.len().max(1) as i32
    }

    fn calculate_speed_dimension(&self, assessments: &[&SkillAssessment]) -> i32 {
        let speed_scores: Vec<i32> = assessments.iter()
            .filter_map(|a| a.time_spent_minutes)
            .map(|time| {
                // Convert time to speed score (faster = higher score)
                if time <= 5 { 10000 } // Very fast
                else if time <= 10 { 8000 } // Fast
                else if time <= 20 { 6000 } // Moderate
                else if time <= 30 { 4000 } // Slow
                else { 2000 } // Very slow
            })
            .collect();

        if speed_scores.is_empty() { 5000 } else {
            speed_scores.iter().sum::<i32>() / speed_scores.len() as i32
        }
    }

    fn calculate_confidence_dimension(&self, assessments: &[&SkillAssessment]) -> i32 {
        assessments.iter()
            .filter_map(|a| a.confidence_level)
            .sum::<i32>() / assessments.len().max(1) as i32
    }

    fn calculate_retention_dimension(&self, assessments: &[&SkillAssessment]) -> i32 {
        // Calculate retention based on performance consistency over time
        let scores: Vec<i32> = assessments.iter()
            .filter_map(|a| a.score)
            .collect();

        if scores.len() < 2 {
            return 5000; // Default middle score
        }

        // Higher consistency = better retention
        let mean = scores.iter().sum::<i32>() as f64 / scores.len() as f64;
        let variance = scores.iter()
            .map(|&score| {
                let diff = score as f64 - mean;
                diff * diff
            })
            .sum::<f64>() / scores.len() as f64;
        let std_dev = variance.sqrt();

        // Convert to retention score (lower std dev = higher retention)
        let retention = (1.0 - (std_dev / 10000.0).min(1.0)) * 10000.0;
        retention.round() as i32
    }

    fn calculate_gap_priority(&self, gap_size: i32, reliability: i32) -> f64 {
        // Priority = gap_size * reliability_factor
        let reliability_factor = reliability as f64 / 10000.0;
        gap_size as f64 * reliability_factor
    }

    fn generate_recommendations(&self, gap_size: i32, trend: TrendDirection) -> Vec<String> {
        let mut recommendations = Vec::new();
        
        if gap_size > 3000 {
            recommendations.push("Intensive focused practice recommended".to_string());
            recommendations.push("Consider seeking expert guidance".to_string());
        } else if gap_size > 1000 {
            recommendations.push("Regular practice sessions recommended".to_string());
            recommendations.push("Review foundational concepts".to_string());
        } else {
            recommendations.push("Light maintenance practice sufficient".to_string());
        }

        match trend {
            TrendDirection::Improving => {
                recommendations.push("Current learning approach is effective".to_string());
            },
            TrendDirection::Declining => {
                recommendations.push("Consider changing learning strategy".to_string());
                recommendations.push("Review recent practice methods".to_string());
            },
            TrendDirection::Stable => {
                recommendations.push("Maintain current practice routine".to_string());
            }
        }

        recommendations
    }

    fn calculate_reliability_score_from_assessments(&self, assessments: &[&SkillAssessment]) -> i32 {
        let scores: Vec<i32> = assessments.iter()
            .filter_map(|a| a.score)
            .collect();
        self.calculate_reliability_score(&scores)
    }

    fn calculate_validity_score(&self, assessments: &[&SkillAssessment]) -> i32 {
        // Simplified validity calculation based on assessment consistency
        // In a real implementation, this would compare against external criteria
        let scores: Vec<i32> = assessments.iter()
            .filter_map(|a| a.score)
            .collect();

        if scores.len() < 2 {
            return 5000; // Default middle score
        }

        // Calculate how well scores correlate with difficulty levels
        let difficulty_correlations: Vec<f64> = assessments.iter()
            .filter_map(|a| {
                a.score.and_then(|s| a.difficulty_level.map(|d| (s as f64, d as f64)))
            })
            .map(|(score, difficulty)| {
                // Higher scores should correlate with higher difficulty
                if difficulty > 0.0 { score / difficulty } else { 0.0 }
            })
            .collect();

        if difficulty_correlations.is_empty() {
            return 5000;
        }

        let avg_correlation = difficulty_correlations.iter().sum::<f64>() / difficulty_correlations.len() as f64;
        let validity = (avg_correlation / 1000.0).min(1.0) * 10000.0; // Normalize to 0-10000
        validity.round() as i32
    }

    fn calculate_consistency_score(&self, assessments: &[&SkillAssessment]) -> i32 {
        let scores: Vec<i32> = assessments.iter()
            .filter_map(|a| a.score)
            .collect();
        
        if scores.len() < 2 {
            return 5000;
        }

        // Calculate coefficient of variation
        let mean = scores.iter().sum::<i32>() as f64 / scores.len() as f64;
        let variance = scores.iter()
            .map(|&score| {
                let diff = score as f64 - mean;
                diff * diff
            })
            .sum::<f64>() / scores.len() as f64;
        let std_dev = variance.sqrt();
        
        let coefficient_of_variation = if mean > 0.0 { std_dev / mean } else { 0.0 };
        
        // Convert to consistency score (lower CV = higher consistency)
        let consistency = (1.0 - coefficient_of_variation.min(1.0)) * 10000.0;
        consistency.round() as i32
    }

    fn calculate_trend_strength(&self, assessments: &[&SkillAssessment]) -> i32 {
        if assessments.len() < 3 {
            return 0;
        }

        let scores: Vec<i32> = assessments.iter()
            .filter_map(|a| a.score)
            .collect();

        if scores.len() < 3 {
            return 0;
        }

        // Calculate R-squared value for trend strength
        let n = scores.len() as f64;
        let x_sum: f64 = (0..scores.len()).map(|i| i as f64).sum();
        let y_sum: f64 = scores.iter().map(|&s| s as f64).sum();
        let xy_sum: f64 = scores.iter().enumerate().map(|(i, &s)| i as f64 * s as f64).sum();
        let x2_sum: f64 = (0..scores.len()).map(|i| (i as f64).powi(2)).sum();
        let y2_sum: f64 = scores.iter().map(|&s| (s as f64).powi(2)).sum();

        let slope = (n * xy_sum - x_sum * y_sum) / (n * x2_sum - x_sum * x_sum);
        let intercept = (y_sum - slope * x_sum) / n;

        let ss_res: f64 = scores.iter().enumerate()
            .map(|(i, &score)| {
                let predicted = slope * i as f64 + intercept;
                let residual = score as f64 - predicted;
                residual * residual
            })
            .sum();

        let ss_tot: f64 = {
            let mean = y_sum / n;
            scores.iter()
                .map(|&score| {
                    let diff = score as f64 - mean;
                    diff * diff
                })
                .sum()
        };

        let r_squared = if ss_tot > 0.0 { 1.0 - (ss_res / ss_tot) } else { 0.0 };
        (r_squared * 10000.0).round() as i32
    }
}

/// Result of comprehensive skill assessment
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SkillScoreResult {
    pub skill_area_id: Uuid,
    pub overall_score: i32,
    pub confidence_interval_lower: i32,
    pub confidence_interval_upper: i32,
    pub sample_size: usize,
    pub reliability_score: i32,
    pub trend_direction: TrendDirection,
    pub assessment_count: usize,
}

/// Multi-dimensional skill measurement
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MultiDimensionalScore {
    pub skill_area_id: Uuid,
    pub accuracy_score: i32,
    pub speed_score: i32,
    pub confidence_score: i32,
    pub retention_score: i32,
    pub overall_composite_score: i32,
    pub dimension_weights: Vec<f64>,
}

/// Skill gap identification
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SkillGap {
    pub skill_area_id: Uuid,
    pub current_score: i32,
    pub target_score: i32,
    pub gap_size: i32,
    pub priority_level: f64,
    pub recommended_actions: Vec<String>,
}

/// Assessment quality metrics
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AssessmentQuality {
    pub skill_area_id: Uuid,
    pub reliability_score: i32,
    pub validity_score: i32,
    pub consistency_score: i32,
    pub sample_size: usize,
    pub quality_level: String,
}

/// Skill progression tracking
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SkillProgression {
    pub skill_area_id: Uuid,
    pub time_period_days: i32,
    pub initial_score: i32,
    pub current_score: i32,
    pub improvement_rate: i32,
    pub assessment_frequency: f64,
    pub trend_strength: i32,
}

/// Binary search skill evaluation system that leverages skill graph dependencies
/// to efficiently assess knowledge without redundant testing of prerequisites
pub struct BinarySearchSkillEvaluator {
    /// Skill graph structure for dependency analysis
    pub skill_graph: Value,
    /// Confidence threshold for inferring prerequisite knowledge
    pub inference_threshold: i32,
    /// Maximum depth for dependency inference
    pub max_inference_depth: usize,
}

impl BinarySearchSkillEvaluator {
    /// Create a new binary search skill evaluator
    pub fn new(skill_graph: Value, inference_threshold: i32, max_inference_depth: usize) -> Self {
        Self {
            skill_graph,
            inference_threshold,
            max_inference_depth,
        }
    }

    /// Perform binary search evaluation along skill graph paths
    pub fn evaluate_skill_path(&self, skill_area_id: &Uuid, person_id: &Uuid, conn: &mut diesel::PgConnection) -> SkillPathEvaluation {
        use crate::schema::{human_learning_states, learning_units};
        
        // Get all learning units for this skill area
        let learning_units = learning_units::table
            .filter(learning_units::skill_area_id.eq(skill_area_id))
            .load::<LearningUnit>(conn)
            .unwrap_or_default();

        if learning_units.is_empty() {
            return SkillPathEvaluation {
                skill_area_id: *skill_area_id,
                evaluated_units: Vec::new(),
                inferred_units: Vec::new(),
                total_units: 0,
                evaluation_efficiency: 0.0,
                confidence_score: 0,
                skill_mastery_percentage: 0,
            };
        }

        // Build dependency graph for this skill area
        let dependency_graph = self.build_dependency_graph(&learning_units);
        
        // Find entry points (units with no dependencies)
        let entry_points = self.find_entry_points(&dependency_graph);
        
        // Perform binary search evaluation starting from entry points
        let mut evaluated_units = Vec::new();
        let mut inferred_units = Vec::new();
        
        for entry_point in entry_points {
            let path_evaluation = self.evaluate_skill_path_recursive(
                &entry_point,
                &dependency_graph,
                person_id,
                conn,
                0
            );
            evaluated_units.extend(path_evaluation.evaluated);
            inferred_units.extend(path_evaluation.inferred);
        }

        // Calculate evaluation efficiency
        let total_units = learning_units.len();
        let evaluation_efficiency = if total_units > 0 {
            evaluated_units.len() as f64 / total_units as f64
        } else {
            0.0
        };

        // Calculate overall skill mastery
        let total_score = evaluated_units.iter().map(|u| u.score).sum::<i32>() +
                         inferred_units.iter().map(|u| u.score).sum::<i32>();
        let total_units_scored = evaluated_units.len() + inferred_units.len();
        let skill_mastery_percentage = if total_units_scored > 0 {
            total_score / total_units_scored as i32
        } else {
            0
        };

        // Calculate confidence based on evaluation coverage
        let confidence_score = (evaluation_efficiency * 10000.0).round() as i32;

        SkillPathEvaluation {
            skill_area_id: *skill_area_id,
            evaluated_units,
            inferred_units,
            total_units,
            evaluation_efficiency,
            confidence_score,
            skill_mastery_percentage,
        }
    }

    /// Recursively evaluate a skill path using binary search
    fn evaluate_skill_path_recursive(
        &self,
        unit_id: &Uuid,
        dependency_graph: &std::collections::HashMap<Uuid, Vec<Uuid>>,
        person_id: &Uuid,
        conn: &mut diesel::PgConnection,
        depth: usize
    ) -> PathEvaluationResult {
        use crate::schema::human_learning_states;
        
        if depth > self.max_inference_depth {
            return PathEvaluationResult {
                evaluated: Vec::new(),
                inferred: Vec::new(),
            };
        }

        // Check if we already have a learning state for this unit
        let existing_state = human_learning_states::table
            .filter(human_learning_states::person_id.eq(person_id))
            .filter(human_learning_states::learning_unit_id.eq(unit_id))
            .first::<HumanLearningState>(conn);

        match existing_state {
            Ok(state) => {
                // We have existing data - use it
                let unit_evaluation = UnitEvaluation {
                    unit_id: *unit_id,
                    score: state.current_score,
                    evaluation_type: "existing".to_string(),
                    confidence: state.current_score, // Use score as confidence
                    dependencies_verified: true,
                };

                // Check if we can infer knowledge of dependent units
                let dependents = self.get_dependent_units(unit_id, dependency_graph);
                let mut inferred = Vec::new();
                
                for dependent_id in dependents {
                    if state.current_score >= self.inference_threshold {
                        // High score suggests mastery - infer knowledge of dependents
                        let inferred_score = self.calculate_inferred_score(&state, &dependent_id);
                        inferred.push(UnitEvaluation {
                            unit_id: dependent_id,
                            score: inferred_score,
                            evaluation_type: "inferred".to_string(),
                            confidence: (inferred_score as f64 * 0.8).round() as i32, // Lower confidence for inferred
                            dependencies_verified: true,
                        });
                    }
                }

                PathEvaluationResult {
                    evaluated: vec![unit_evaluation],
                    inferred,
                }
            },
            Err(_) => {
                // No existing data - need to evaluate this unit
                let unit_evaluation = self.evaluate_unit_directly(unit_id, person_id, conn);
                
                // If this unit shows high mastery, infer knowledge of dependents
                let mut inferred = Vec::new();
                if unit_evaluation.score >= self.inference_threshold {
                    let dependents = self.get_dependent_units(unit_id, dependency_graph);
                    for dependent_id in dependents {
                        let inferred_score = self.calculate_inferred_score_from_evaluation(&unit_evaluation, &dependent_id);
                        inferred.push(UnitEvaluation {
                            unit_id: dependent_id,
                            score: inferred_score,
                            evaluation_type: "inferred".to_string(),
                            confidence: (inferred_score as f64 * 0.8).round() as i32,
                            dependencies_verified: true,
                        });
                    }
                }

                PathEvaluationResult {
                    evaluated: vec![unit_evaluation],
                    inferred,
                }
            }
        }
    }

    /// Evaluate a unit directly (simulated assessment)
    fn evaluate_unit_directly(&self, unit_id: &Uuid, person_id: &Uuid, conn: &mut diesel::PgConnection) -> UnitEvaluation {
        // In a real implementation, this would present the unit to the user for assessment
        // For now, we'll simulate an assessment based on unit difficulty
        use crate::schema::learning_units;
        
        let unit = learning_units::table
            .find(unit_id)
            .first::<LearningUnit>(conn)
            .unwrap_or_else(|_| LearningUnit {
                id: *unit_id,
                skill_area_id: uuid::Uuid::new_v4(),
                title: "Unknown Unit".to_string(),
                content: "".to_string(),
                unit_type: "concept".to_string(),
                difficulty_level: 5000, // Default middle difficulty
                estimated_time_minutes: None,
                dependencies: None,
                metadata: None,
                created_at: Some(chrono::Utc::now()),
                updated_at: Some(chrono::Utc::now()),
            });

        // Simulate assessment score based on difficulty and some randomness
        let base_score = 10000 - unit.difficulty_level; // Easier units get higher base scores
        let random_factor = (rand::random::<f64>() * 2000.0) as i32 - 1000; // ±1000 random variation
        let simulated_score = (base_score + random_factor).max(0).min(10000);

        UnitEvaluation {
            unit_id: *unit_id,
            score: simulated_score,
            evaluation_type: "direct".to_string(),
            confidence: 9000, // High confidence for direct evaluation
            dependencies_verified: true,
        }
    }

    /// Calculate inferred score for a dependent unit
    pub fn calculate_inferred_score(&self, source_state: &HumanLearningState, dependent_unit_id: &Uuid) -> i32 {
        // Base the inferred score on the source unit's score with some degradation
        let base_score = source_state.current_score;
        
        // Apply degradation factor based on dependency distance
        // Closer dependencies get higher scores
        let degradation_factor = 0.9; // 10% degradation per dependency level
        
        let inferred_score = (base_score as f64 * degradation_factor).round() as i32;
        inferred_score.max(0).min(10000)
    }

    /// Calculate inferred score from a direct evaluation
    fn calculate_inferred_score_from_evaluation(&self, source_evaluation: &UnitEvaluation, dependent_unit_id: &Uuid) -> i32 {
        let base_score = source_evaluation.score;
        let degradation_factor = 0.9;
        let inferred_score = (base_score as f64 * degradation_factor).round() as i32;
        inferred_score.max(0).min(10000)
    }

    /// Build dependency graph from learning units
    fn build_dependency_graph(&self, learning_units: &[LearningUnit]) -> std::collections::HashMap<Uuid, Vec<Uuid>> {
        let mut graph = std::collections::HashMap::new();
        
        for unit in learning_units {
            let mut dependencies = Vec::new();
            if let Some(deps) = &unit.dependencies {
                if let Ok(dep_ids) = serde_json::from_value::<Vec<String>>(deps.clone()) {
                    // Convert string IDs to UUIDs (simplified - in real implementation would use proper ID mapping)
                    for dep_id_str in dep_ids {
                        if let Ok(dep_uuid) = uuid::Uuid::parse_str(&dep_id_str) {
                            dependencies.push(dep_uuid);
                        }
                    }
                }
            }
            graph.insert(unit.id, dependencies);
        }
        
        graph
    }

    /// Find entry points (units with no dependencies)
    pub fn find_entry_points(&self, dependency_graph: &std::collections::HashMap<Uuid, Vec<Uuid>>) -> Vec<Uuid> {
        dependency_graph.iter()
            .filter(|(_, deps)| deps.is_empty())
            .map(|(unit, _)| *unit)
            .collect()
    }

    /// Get units that depend on the given unit
    pub fn get_dependent_units(&self, unit_id: &Uuid, dependency_graph: &std::collections::HashMap<Uuid, Vec<Uuid>>) -> Vec<Uuid> {
        dependency_graph.iter()
            .filter(|(_, deps)| deps.contains(unit_id))
            .map(|(unit, _)| *unit)
            .collect()
    }

    /// Optimize learning path by identifying redundant units
    pub fn optimize_learning_path(&self, skill_area_id: &Uuid, person_id: &Uuid, conn: &mut diesel::PgConnection) -> OptimizedLearningPath {
        let evaluation = self.evaluate_skill_path(skill_area_id, person_id, conn);
        
        // Identify units that need direct evaluation vs can be inferred
        let units_needing_evaluation = evaluation.evaluated_units.iter()
            .filter(|u| u.evaluation_type == "direct")
            .map(|u| u.unit_id)
            .collect();

        let units_can_infer = evaluation.inferred_units.iter()
            .map(|u| u.unit_id)
            .collect();

        let skipped_units = evaluation.total_units - evaluation.evaluated_units.len() - evaluation.inferred_units.len();

        OptimizedLearningPath {
            skill_area_id: *skill_area_id,
            units_needing_evaluation,
            units_can_infer,
            skipped_units,
            efficiency_gain: evaluation.evaluation_efficiency,
            estimated_time_saved_minutes: (skipped_units as f64 * 15.0) as i32, // Assume 15 min per unit
        }
    }

    /// Validate inference accuracy by spot-checking inferred units
    pub fn validate_inferences(&self, skill_area_id: &Uuid, person_id: &Uuid, conn: &mut diesel::PgConnection) -> InferenceValidation {
        let evaluation = self.evaluate_skill_path(skill_area_id, person_id, conn);
        
        // Sample some inferred units for validation
        let inferred_units = &evaluation.inferred_units;
        let sample_size = (inferred_units.len() as f64 * 0.2).round() as usize; // 20% sample
        let sample_size = sample_size.max(1).min(inferred_units.len());
        
        let mut validation_results = Vec::new();
        let mut total_accuracy = 0.0;
        
        for i in 0..sample_size {
            let inferred_unit = &inferred_units[i];
            let actual_score = self.evaluate_unit_directly(&inferred_unit.unit_id, person_id, conn).score;
            let accuracy = 1.0 - ((inferred_unit.score - actual_score).abs() as f64 / 10000.0);
            
            validation_results.push(InferenceValidationResult {
                unit_id: inferred_unit.unit_id,
                inferred_score: inferred_unit.score,
                actual_score,
                accuracy,
            });
            
            total_accuracy += accuracy;
        }

        let average_accuracy = if sample_size > 0 {
            total_accuracy / sample_size as f64
        } else {
            0.0
        };

        InferenceValidation {
            skill_area_id: *skill_area_id,
            validation_results,
            average_accuracy,
            sample_size,
            total_inferred_units: inferred_units.len(),
        }
    }
}

/// Result of binary search skill path evaluation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SkillPathEvaluation {
    pub skill_area_id: Uuid,
    pub evaluated_units: Vec<UnitEvaluation>,
    pub inferred_units: Vec<UnitEvaluation>,
    pub total_units: usize,
    pub evaluation_efficiency: f64,
    pub confidence_score: i32,
    pub skill_mastery_percentage: i32,
}

/// Individual unit evaluation result
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UnitEvaluation {
    pub unit_id: Uuid,
    pub score: i32,
    pub evaluation_type: String, // "direct", "inferred", "existing"
    pub confidence: i32,
    pub dependencies_verified: bool,
}

/// Result of recursive path evaluation
#[derive(Debug, Clone)]
struct PathEvaluationResult {
    evaluated: Vec<UnitEvaluation>,
    inferred: Vec<UnitEvaluation>,
}

/// Optimized learning path with redundant units identified
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OptimizedLearningPath {
    pub skill_area_id: Uuid,
    pub units_needing_evaluation: Vec<Uuid>,
    pub units_can_infer: Vec<Uuid>,
    pub skipped_units: usize,
    pub efficiency_gain: f64,
    pub estimated_time_saved_minutes: i32,
}

/// Validation of inference accuracy
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InferenceValidation {
    pub skill_area_id: Uuid,
    pub validation_results: Vec<InferenceValidationResult>,
    pub average_accuracy: f64,
    pub sample_size: usize,
    pub total_inferred_units: usize,
}

/// Individual inference validation result
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InferenceValidationResult {
    pub unit_id: Uuid,
    pub inferred_score: i32,
    pub actual_score: i32,
    pub accuracy: f64,
}
