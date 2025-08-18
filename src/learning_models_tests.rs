//! Unit tests for learning system models
//!
//! This module contains comprehensive tests for the learning system models,
//! including schema validation, data constraints, and model relationships.

use crate::learning_models::*;
use crate::models::Person;
use crate::schema::*;
use diesel::prelude::*;
use diesel::r2d2::{ConnectionManager, Pool};
use diesel::PgConnection;
use serde_json::json;
use uuid::Uuid;

/// Test database connection setup
fn establish_test_connection() -> Pool<ConnectionManager<PgConnection>> {
    let database_url = "postgres://paragonic:paragonic@localhost:5432/paragonic";
    let manager = ConnectionManager::<PgConnection>::new(database_url);
    Pool::builder()
        .build(manager)
        .expect("Failed to create test connection pool")
}

/// Test helper to create a test person
fn create_test_person(conn: &mut PgConnection) -> Person {
    use crate::schema::people::dsl::*;

    let person_id = Uuid::new_v4();
    let now = chrono::Utc::now();

    let person = Person {
        id: person_id,
        name: "Test Person".to_string(),
        email: Some("test@example.com".to_string()),
        bio: None,
        expertise_areas: None,
        location: None,
        timezone: None,
        availability_status: crate::models::AvailabilityStatus::Available,
        created_at: now,
        updated_at: now,
    };

    diesel::insert_into(people)
        .values(&person)
        .execute(conn)
        .expect("Failed to create test person");

    person
}

#[test]
fn test_skill_area_creation_and_validation() {
    let pool = establish_test_connection();
    let mut conn = pool.get().expect("Failed to get connection");

    // Test creating a skill area with valid data
    let difficulty_levels = json!({
        "beginner": 1,
        "intermediate": 2,
        "advanced": 3,
        "expert": 4
    });

    let new_skill_area = NewSkillArea {
        name: "Programming Fundamentals".to_string(),
        category: "Development".to_string(),
        description: Some("Core programming concepts and practices".to_string()),
        difficulty_levels,
        metadata: Some(json!({"tags": ["programming", "fundamentals"]})),
    };

    diesel::insert_into(skill_areas::table)
        .values(&new_skill_area)
        .execute(&mut conn)
        .expect("Failed to insert skill area");

    let skill_area: SkillArea = skill_areas::table
        .find(new_skill_area.id)
        .first(&mut conn)
        .expect("Failed to retrieve skill area");

    // Verify the skill area was created correctly
    assert_eq!(skill_area.name, "Programming Fundamentals");
    assert_eq!(skill_area.category, "Development");
    assert_eq!(skill_area.description, Some("Core programming concepts and practices".to_string()));
    assert!(skill_area.difficulty_levels.is_object());
    assert!(skill_area.metadata.is_some());

    // Test that the skill area can be retrieved
    let retrieved_skill_area: SkillArea = skill_areas::table
        .find(skill_area.id)
        .first(&mut conn)
        .expect("Failed to retrieve skill area");

    assert_eq!(retrieved_skill_area.id, skill_area.id);
    assert_eq!(retrieved_skill_area.name, skill_area.name);

    // Clean up
    diesel::delete(skill_areas::table.find(skill_area.id))
        .execute(&mut conn)
        .expect("Failed to delete test skill area");
}

#[test]
fn test_skill_area_name_uniqueness() {
    let pool = establish_test_connection();
    let mut conn = pool.get().expect("Failed to get connection");

    let difficulty_levels = json!({
        "beginner": 1,
        "intermediate": 2,
        "advanced": 3,
        "expert": 4
    });

    let new_skill_area = NewSkillArea {
        name: "Unique Skill Area".to_string(),
        category: "Development".to_string(),
        description: None,
        difficulty_levels,
        metadata: None,
    };

    // Insert the first skill area
    diesel::insert_into(skill_areas::table)
        .values(&new_skill_area)
        .execute(&mut conn)
        .expect("Failed to insert first skill area");

    let skill_area1: SkillArea = skill_areas::table
        .find(new_skill_area.id)
        .first(&mut conn)
        .expect("Failed to retrieve first skill area");

    // Try to insert another skill area with the same name
    let duplicate_skill_area = NewSkillArea {
        name: "Unique Skill Area".to_string(), // Same name
        category: "Different Category".to_string(),
        description: None,
        difficulty_levels,
        metadata: None,
    };

    let result = diesel::insert_into(skill_areas::table)
        .values(&duplicate_skill_area)
        .get_result::<SkillArea>(&mut conn);

    // Should fail due to unique constraint
    assert!(result.is_err());

    // Clean up
    diesel::delete(skill_areas::table.find(skill_area1.id))
        .execute(&mut conn)
        .expect("Failed to delete test skill area");
}

#[test]
fn test_skill_area_difficulty_levels_validation() {
    let pool = establish_test_connection();
    let mut conn = pool.get().expect("Failed to get connection");

    // Test with valid difficulty levels
    let valid_difficulty_levels = json!({
        "beginner": 1,
        "intermediate": 2,
        "advanced": 3,
        "expert": 4
    });

    let new_skill_area = NewSkillArea {
        name: "Valid Skill Area".to_string(),
        category: "Development".to_string(),
        description: None,
        difficulty_levels: valid_difficulty_levels,
        metadata: None,
    };

    let skill_area: SkillArea = diesel::insert_into(skill_areas::table)
        .values(&new_skill_area)
        .get_result(&mut conn)
        .expect("Failed to insert skill area with valid difficulty levels");

    assert!(skill_area.difficulty_levels.is_object());
    assert_eq!(skill_area.difficulty_levels["beginner"], 1);
    assert_eq!(skill_area.difficulty_levels["expert"], 4);

    // Clean up
    diesel::delete(skill_areas::table.find(skill_area.id))
        .execute(&mut conn)
        .expect("Failed to delete test skill area");
}

#[test]
fn test_practice_item_creation_and_validation() {
    let pool = establish_test_connection();
    let mut conn = pool.get().expect("Failed to get connection");

    // First create a skill area
    let difficulty_levels = json!({
        "beginner": 1,
        "intermediate": 2,
        "advanced": 3,
        "expert": 4
    });

    let new_skill_area = NewSkillArea {
        name: "Test Skill Area".to_string(),
        category: "Development".to_string(),
        description: None,
        difficulty_levels,
        metadata: None,
    };

    let skill_area: SkillArea = diesel::insert_into(skill_areas::table)
        .values(&new_skill_area)
        .get_result(&mut conn)
        .expect("Failed to insert skill area");

    // Create a practice item
    let options = json!([
        "Option A",
        "Option B", 
        "Option C",
        "Option D"
    ]);

    let hints = json!([
        "Think about the basic syntax",
        "Consider the data type"
    ]);

    let new_practice_item = NewPracticeItem {
        skill_area_id: skill_area.id,
        title: "What is a variable?".to_string(),
        content: "Explain what a variable is in programming.".to_string(),
        item_type: "multiple_choice".to_string(),
        difficulty_level: 1,
        correct_answer: Some("A named storage location for data".to_string()),
        options: Some(options),
        hints: Some(hints),
        explanation: Some("A variable is a named storage location that can hold different values during program execution.".to_string()),
        estimated_time_minutes: Some(2),
        tags: Some(json!(["variables", "basics"])),
        metadata: Some(json!({"learning_objective": "Understand variable concept"})),
    };

    diesel::insert_into(practice_items::table)
        .values(&new_practice_item)
        .execute(&mut conn)
        .expect("Failed to insert practice item");

    let practice_item: PracticeItem = practice_items::table
        .find(new_practice_item.id)
        .first(&mut conn)
        .expect("Failed to retrieve practice item");

    // Verify the practice item was created correctly
    assert_eq!(practice_item.title, "What is a variable?");
    assert_eq!(practice_item.skill_area_id, skill_area.id);
    assert_eq!(practice_item.item_type, "multiple_choice");
    assert_eq!(practice_item.difficulty_level, 1);
    assert_eq!(practice_item.correct_answer, Some("A named storage location for data".to_string()));
    assert!(practice_item.options.is_some());
    assert!(practice_item.hints.is_some());
    assert!(practice_item.explanation.is_some());
    assert_eq!(practice_item.estimated_time_minutes, Some(2));

    // Test the relationship with skill area
    let retrieved_practice_item: PracticeItem = practice_items::table
        .find(practice_item.id)
        .first(&mut conn)
        .expect("Failed to retrieve practice item");

    assert_eq!(retrieved_practice_item.skill_area_id, skill_area.id);

    // Clean up
    diesel::delete(practice_items::table.find(practice_item.id))
        .execute(&mut conn)
        .expect("Failed to delete test practice item");
    diesel::delete(skill_areas::table.find(skill_area.id))
        .execute(&mut conn)
        .expect("Failed to delete test skill area");
}

#[test]
fn test_practice_item_difficulty_level_constraints() {
    let pool = establish_test_connection();
    let mut conn = pool.get().expect("Failed to get connection");

    // First create a skill area
    let difficulty_levels = json!({
        "beginner": 1,
        "intermediate": 2,
        "advanced": 3,
        "expert": 4
    });

    let new_skill_area = NewSkillArea {
        name: "Test Skill Area".to_string(),
        category: "Development".to_string(),
        description: None,
        difficulty_levels,
        metadata: None,
    };

    let skill_area: SkillArea = diesel::insert_into(skill_areas::table)
        .values(&new_skill_area)
        .get_result(&mut conn)
        .expect("Failed to insert skill area");

    // Test with valid difficulty level (1-5)
    let valid_practice_item = NewPracticeItem {
        skill_area_id: skill_area.id,
        title: "Valid Practice Item".to_string(),
        content: "Test content".to_string(),
        item_type: "concept_question".to_string(),
        difficulty_level: 3, // Valid level
        correct_answer: None,
        options: None,
        hints: None,
        explanation: None,
        estimated_time_minutes: None,
        tags: None,
        metadata: None,
    };

    let practice_item: PracticeItem = diesel::insert_into(practice_items::table)
        .values(&valid_practice_item)
        .get_result(&mut conn)
        .expect("Failed to insert practice item with valid difficulty level");

    assert_eq!(practice_item.difficulty_level, 3);

    // Clean up
    diesel::delete(practice_items::table.find(practice_item.id))
        .execute(&mut conn)
        .expect("Failed to delete test practice item");
    diesel::delete(skill_areas::table.find(skill_area.id))
        .execute(&mut conn)
        .expect("Failed to delete test skill area");
}

#[test]
fn test_learning_session_creation_and_validation() {
    let pool = establish_test_connection();
    let mut conn = pool.get().expect("Failed to get connection");

    // Create a test person
    let person = create_test_person(&mut conn);

    // Create a learning session
    let skill_areas_targeted = json!([
        "skill-area-1",
        "skill-area-2"
    ]);

    let new_learning_session = NewLearningSession {
        person_id: person.id,
        session_type: "practice".to_string(),
        title: "Programming Fundamentals Practice".to_string(),
        description: Some("Practice session for programming fundamentals".to_string()),
        target_duration_minutes: Some(30),
        status: "in_progress".to_string(),
        difficulty_target: Some(2),
        skill_areas_targeted: Some(skill_areas_targeted),
        metadata: Some(json!({"session_goal": "Improve basic programming skills"})),
    };

    let learning_session: LearningSession = diesel::insert_into(learning_sessions::table)
        .values(&new_learning_session)
        .get_result(&mut conn)
        .expect("Failed to insert learning session");

    // Verify the learning session was created correctly
    assert_eq!(learning_session.person_id, person.id);
    assert_eq!(learning_session.session_type, "practice");
    assert_eq!(learning_session.title, "Programming Fundamentals Practice");
    assert_eq!(learning_session.status, "in_progress");
    assert_eq!(learning_session.target_duration_minutes, Some(30));
    assert_eq!(learning_session.difficulty_target, Some(2));
    assert!(learning_session.skill_areas_targeted.is_some());
    assert!(learning_session.metadata.is_some());

    // Test that the session can be retrieved
    let retrieved_session: LearningSession = learning_sessions::table
        .find(learning_session.id)
        .first(&mut conn)
        .expect("Failed to retrieve learning session");

    assert_eq!(retrieved_session.id, learning_session.id);
    assert_eq!(retrieved_session.person_id, person.id);

    // Clean up
    diesel::delete(learning_sessions::table.find(learning_session.id))
        .execute(&mut conn)
        .expect("Failed to delete test learning session");
    diesel::delete(people::table.find(person.id))
        .execute(&mut conn)
        .expect("Failed to delete test person");
}

#[test]
fn test_session_item_creation_and_validation() {
    let pool = establish_test_connection();
    let mut conn = pool.get().expect("Failed to get connection");

    // Create a test person
    let person = create_test_person(&mut conn);

    // Create a skill area
    let difficulty_levels = json!({
        "beginner": 1,
        "intermediate": 2,
        "advanced": 3,
        "expert": 4
    });

    let new_skill_area = NewSkillArea {
        name: "Test Skill Area".to_string(),
        category: "Development".to_string(),
        description: None,
        difficulty_levels,
        metadata: None,
    };

    let skill_area: SkillArea = diesel::insert_into(skill_areas::table)
        .values(&new_skill_area)
        .get_result(&mut conn)
        .expect("Failed to insert skill area");

    // Create a practice item
    let new_practice_item = NewPracticeItem {
        skill_area_id: skill_area.id,
        title: "Test Practice Item".to_string(),
        content: "Test content".to_string(),
        item_type: "concept_question".to_string(),
        difficulty_level: 2,
        correct_answer: Some("Correct answer".to_string()),
        options: None,
        hints: None,
        explanation: None,
        estimated_time_minutes: None,
        tags: None,
        metadata: None,
    };

    let practice_item: PracticeItem = diesel::insert_into(practice_items::table)
        .values(&new_practice_item)
        .get_result(&mut conn)
        .expect("Failed to insert practice item");

    // Create a learning session
    let new_learning_session = NewLearningSession {
        person_id: person.id,
        session_type: "practice".to_string(),
        title: "Test Session".to_string(),
        description: None,
        target_duration_minutes: None,
        status: "in_progress".to_string(),
        difficulty_target: None,
        skill_areas_targeted: None,
        metadata: None,
    };

    let learning_session: LearningSession = diesel::insert_into(learning_sessions::table)
        .values(&new_learning_session)
        .get_result(&mut conn)
        .expect("Failed to insert learning session");

    // Create a session item
    let new_session_item = NewSessionItem {
        session_id: learning_session.id,
        practice_item_id: practice_item.id,
        order_in_session: 1,
        hints_used: Some(0),
        metadata: Some(json!({"time_spent": 120})),
    };

    diesel::insert_into(session_items::table)
        .values(&new_session_item)
        .execute(&mut conn)
        .expect("Failed to insert session item");

    let session_item: SessionItem = session_items::table
        .find(new_session_item.id)
        .first(&mut conn)
        .expect("Failed to retrieve session item");

    // Verify the session item was created correctly
    assert_eq!(session_item.session_id, learning_session.id);
    assert_eq!(session_item.practice_item_id, practice_item.id);
    assert_eq!(session_item.order_in_session, 1);
    assert_eq!(session_item.hints_used, Some(0));
    assert!(session_item.metadata.is_some());

    // Test the relationships
    let retrieved_session_item: SessionItem = session_items::table
        .find(session_item.id)
        .first(&mut conn)
        .expect("Failed to retrieve session item");

    assert_eq!(retrieved_session_item.session_id, learning_session.id);
    assert_eq!(retrieved_session_item.practice_item_id, practice_item.id);

    // Clean up
    diesel::delete(session_items::table.find(session_item.id))
        .execute(&mut conn)
        .expect("Failed to delete test session item");
    diesel::delete(learning_sessions::table.find(learning_session.id))
        .execute(&mut conn)
        .expect("Failed to delete test learning session");
    diesel::delete(practice_items::table.find(practice_item.id))
        .execute(&mut conn)
        .expect("Failed to delete test practice item");
    diesel::delete(skill_areas::table.find(skill_area.id))
        .execute(&mut conn)
        .expect("Failed to delete test skill area");
    diesel::delete(people::table.find(person.id))
        .execute(&mut conn)
        .expect("Failed to delete test person");
}

#[test]
fn test_skill_assessment_creation_and_validation() {
    let pool = establish_test_connection();
    let mut conn = pool.get().expect("Failed to get connection");

    // Create a test person
    let person = create_test_person(&mut conn);

    // Create a skill area
    let difficulty_levels = json!({
        "beginner": 1,
        "intermediate": 2,
        "advanced": 3,
        "expert": 4
    });

    let new_skill_area = NewSkillArea {
        name: "Test Skill Area".to_string(),
        category: "Development".to_string(),
        description: None,
        difficulty_levels,
        metadata: None,
    };

    let skill_area: SkillArea = diesel::insert_into(skill_areas::table)
        .values(&new_skill_area)
        .get_result(&mut conn)
        .expect("Failed to insert skill area");

    // Create a skill assessment
    let assessment_data = json!({
        "questions": [
            {"id": 1, "correct": true, "time_spent": 30},
            {"id": 2, "correct": false, "time_spent": 45},
            {"id": 3, "correct": true, "time_spent": 25}
        ]
    });

    let new_skill_assessment = NewSkillAssessment {
        person_id: person.id,
        skill_area_id: skill_area.id,
        assessment_type: "initial".to_string(),
        score: Some(6700), // 67.00 scaled by 100
        confidence_level: Some(3),
        difficulty_level: Some(2),
        questions_answered: Some(3),
        questions_correct: Some(2),
        time_spent_minutes: Some(2),
        assessment_data: Some(assessment_data),
        metadata: Some(json!({"assessment_method": "multiple_choice"})),
    };

    let skill_assessment: SkillAssessment = diesel::insert_into(skill_assessments::table)
        .values(&new_skill_assessment)
        .get_result(&mut conn)
        .expect("Failed to insert skill assessment");

    // Verify the skill assessment was created correctly
    assert_eq!(skill_assessment.person_id, person.id);
    assert_eq!(skill_assessment.skill_area_id, skill_area.id);
    assert_eq!(skill_assessment.assessment_type, "initial");
    assert_eq!(skill_assessment.score, Some(67));
    assert_eq!(skill_assessment.confidence_level, Some(3));
    assert_eq!(skill_assessment.difficulty_level, Some(2));
    assert_eq!(skill_assessment.questions_answered, Some(3));
    assert_eq!(skill_assessment.questions_correct, Some(2));
    assert_eq!(skill_assessment.time_spent_minutes, Some(2));
    assert!(skill_assessment.assessment_data.is_some());
    assert!(skill_assessment.metadata.is_some());

    // Clean up
    diesel::delete(skill_assessments::table.find(skill_assessment.id))
        .execute(&mut conn)
        .expect("Failed to delete test skill assessment");
    diesel::delete(skill_areas::table.find(skill_area.id))
        .execute(&mut conn)
        .expect("Failed to delete test skill area");
    diesel::delete(people::table.find(person.id))
        .execute(&mut conn)
        .expect("Failed to delete test person");
}

#[test]
fn test_skill_relationship_creation_and_validation() {
    let pool = establish_test_connection();
    let mut conn = pool.get().expect("Failed to get connection");

    // Create two skill areas
    let difficulty_levels = json!({
        "beginner": 1,
        "intermediate": 2,
        "advanced": 3,
        "expert": 4
    });

    let new_skill_area_1 = NewSkillArea {
        name: "Programming Fundamentals".to_string(),
        category: "Development".to_string(),
        description: None,
        difficulty_levels: difficulty_levels.clone(),
        metadata: None,
    };

    let skill_area_1: SkillArea = diesel::insert_into(skill_areas::table)
        .values(&new_skill_area_1)
        .get_result(&mut conn)
        .expect("Failed to insert first skill area");

    let new_skill_area_2 = NewSkillArea {
        name: "System Design".to_string(),
        category: "Architecture".to_string(),
        description: None,
        difficulty_levels,
        metadata: None,
    };

    let skill_area_2: SkillArea = diesel::insert_into(skill_areas::table)
        .values(&new_skill_area_2)
        .get_result(&mut conn)
        .expect("Failed to insert second skill area");

    // Create a skill relationship
    let new_skill_relationship = NewSkillRelationship {
        source_skill_area_id: skill_area_1.id,
        target_skill_area_id: skill_area_2.id,
        relationship_type: "prerequisite".to_string(),
        relationship_strength: 80, // 0.8 * 100
        learning_path_order: Some(1),
        description: Some("Programming fundamentals are required for effective system design".to_string()),
        metadata: Some(json!({"relationship_reason": "Foundation knowledge"})),
    };

    let skill_relationship: SkillRelationship = diesel::insert_into(skill_relationships::table)
        .values(&new_skill_relationship)
        .get_result(&mut conn)
        .expect("Failed to insert skill relationship");

    // Verify the skill relationship was created correctly
    assert_eq!(skill_relationship.source_skill_area_id, skill_area_1.id);
    assert_eq!(skill_relationship.target_skill_area_id, skill_area_2.id);
    assert_eq!(skill_relationship.relationship_type, "prerequisite");
    assert_eq!(skill_relationship.relationship_strength, 80);
    assert_eq!(skill_relationship.learning_path_order, Some(1));
    assert_eq!(skill_relationship.description, Some("Programming fundamentals are required for effective system design".to_string()));
    assert!(skill_relationship.metadata.is_some());

    // Test the relationships
    let retrieved_relationship: SkillRelationship = skill_relationships::table
        .find(skill_relationship.id)
        .first(&mut conn)
        .expect("Failed to retrieve skill relationship");

    assert_eq!(retrieved_relationship.source_skill_area_id, skill_area_1.id);
    assert_eq!(retrieved_relationship.target_skill_area_id, skill_area_2.id);

    // Clean up
    diesel::delete(skill_relationships::table.find(skill_relationship.id))
        .execute(&mut conn)
        .expect("Failed to delete test skill relationship");
    diesel::delete(skill_areas::table.find(skill_area_2.id))
        .execute(&mut conn)
        .expect("Failed to delete test skill area 2");
    diesel::delete(skill_areas::table.find(skill_area_1.id))
        .execute(&mut conn)
        .expect("Failed to delete test skill area 1");
}

#[test]
fn test_enum_conversions() {
    // Test PracticeItemType conversions
    assert_eq!(PracticeItemType::MultipleChoice.to_string(), "multiple_choice");
    assert_eq!(PracticeItemType::CodingChallenge.to_string(), "coding_challenge");
    assert_eq!(PracticeItemType::ConceptQuestion.to_string(), "concept_question");
    assert_eq!(PracticeItemType::Debugging.to_string(), "debugging");

    assert_eq!("multiple_choice".parse::<PracticeItemType>().unwrap(), PracticeItemType::MultipleChoice);
    assert_eq!("coding_challenge".parse::<PracticeItemType>().unwrap(), PracticeItemType::CodingChallenge);
    assert_eq!("concept_question".parse::<PracticeItemType>().unwrap(), PracticeItemType::ConceptQuestion);
    assert_eq!("debugging".parse::<PracticeItemType>().unwrap(), PracticeItemType::Debugging);

    // Test SessionType conversions
    assert_eq!(SessionType::Practice.to_string(), "practice");
    assert_eq!(SessionType::Assessment.to_string(), "assessment");
    assert_eq!(SessionType::Review.to_string(), "review");
    assert_eq!(SessionType::AdjacentSkill.to_string(), "adjacent_skill");

    assert_eq!("practice".parse::<SessionType>().unwrap(), SessionType::Practice);
    assert_eq!("assessment".parse::<SessionType>().unwrap(), SessionType::Assessment);
    assert_eq!("review".parse::<SessionType>().unwrap(), SessionType::Review);
    assert_eq!("adjacent_skill".parse::<SessionType>().unwrap(), SessionType::AdjacentSkill);

    // Test SessionStatus conversions
    assert_eq!(SessionStatus::InProgress.to_string(), "in_progress");
    assert_eq!(SessionStatus::Completed.to_string(), "completed");
    assert_eq!(SessionStatus::Paused.to_string(), "paused");
    assert_eq!(SessionStatus::Abandoned.to_string(), "abandoned");

    assert_eq!("in_progress".parse::<SessionStatus>().unwrap(), SessionStatus::InProgress);
    assert_eq!("completed".parse::<SessionStatus>().unwrap(), SessionStatus::Completed);
    assert_eq!("paused".parse::<SessionStatus>().unwrap(), SessionStatus::Paused);
    assert_eq!("abandoned".parse::<SessionStatus>().unwrap(), SessionStatus::Abandoned);

    // Test AssessmentType conversions
    assert_eq!(AssessmentType::Initial.to_string(), "initial");
    assert_eq!(AssessmentType::Progress.to_string(), "progress");
    assert_eq!(AssessmentType::Final.to_string(), "final");
    assert_eq!(AssessmentType::AdjacentSkill.to_string(), "adjacent_skill");

    assert_eq!("initial".parse::<AssessmentType>().unwrap(), AssessmentType::Initial);
    assert_eq!("progress".parse::<AssessmentType>().unwrap(), AssessmentType::Progress);
    assert_eq!("final".parse::<AssessmentType>().unwrap(), AssessmentType::Final);
    assert_eq!("adjacent_skill".parse::<AssessmentType>().unwrap(), AssessmentType::AdjacentSkill);

    // Test RelationshipType conversions
    assert_eq!(RelationshipType::Prerequisite.to_string(), "prerequisite");
    assert_eq!(RelationshipType::Complementary.to_string(), "complementary");
    assert_eq!(RelationshipType::Adjacent.to_string(), "adjacent");
    assert_eq!(RelationshipType::Advanced.to_string(), "advanced");

    assert_eq!("prerequisite".parse::<RelationshipType>().unwrap(), RelationshipType::Prerequisite);
    assert_eq!("complementary".parse::<RelationshipType>().unwrap(), RelationshipType::Complementary);
    assert_eq!("adjacent".parse::<RelationshipType>().unwrap(), RelationshipType::Adjacent);
    assert_eq!("advanced".parse::<RelationshipType>().unwrap(), RelationshipType::Advanced);

    // Test MetricType conversions
    assert_eq!(MetricType::Accuracy.to_string(), "accuracy");
    assert_eq!(MetricType::Speed.to_string(), "speed");
    assert_eq!(MetricType::Confidence.to_string(), "confidence");
    assert_eq!(MetricType::Retention.to_string(), "retention");
    assert_eq!(MetricType::AdjacentSkillGrowth.to_string(), "adjacent_skill_growth");

    assert_eq!("accuracy".parse::<MetricType>().unwrap(), MetricType::Accuracy);
    assert_eq!("speed".parse::<MetricType>().unwrap(), MetricType::Speed);
    assert_eq!("confidence".parse::<MetricType>().unwrap(), MetricType::Confidence);
    assert_eq!("retention".parse::<MetricType>().unwrap(), MetricType::Retention);
    assert_eq!("adjacent_skill_growth".parse::<MetricType>().unwrap(), MetricType::AdjacentSkillGrowth);

    // Test TrendDirection conversions
    assert_eq!(TrendDirection::Improving.to_string(), "improving");
    assert_eq!(TrendDirection::Declining.to_string(), "declining");
    assert_eq!(TrendDirection::Stable.to_string(), "stable");

    assert_eq!("improving".parse::<TrendDirection>().unwrap(), TrendDirection::Improving);
    assert_eq!("declining".parse::<TrendDirection>().unwrap(), TrendDirection::Declining);
    assert_eq!("stable".parse::<TrendDirection>().unwrap(), TrendDirection::Stable);
}

#[test]
fn test_enum_error_handling() {
    // Test invalid enum parsing
    assert!("invalid_type".parse::<PracticeItemType>().is_err());
    assert!("invalid_session".parse::<SessionType>().is_err());
    assert!("invalid_status".parse::<SessionStatus>().is_err());
    assert!("invalid_assessment".parse::<AssessmentType>().is_err());
    assert!("invalid_relationship".parse::<RelationshipType>().is_err());
    assert!("invalid_metric".parse::<MetricType>().is_err());
    assert!("invalid_trend".parse::<TrendDirection>().is_err());
}

#[test]
fn test_skill_area_data_structure_validation() {
    // Test SkillArea struct creation and validation with graph-based structure
    let skill_graph = json!({
        "nodes": [
            {"id": "variables", "name": "Variables", "description": "Understanding variables and data types"},
            {"id": "functions", "name": "Functions", "description": "Creating and using functions"},
            {"id": "control_flow", "name": "Control Flow", "description": "Conditionals and loops"},
            {"id": "data_structures", "name": "Data Structures", "description": "Arrays, objects, and collections"}
        ],
        "edges": [
            {"from": "variables", "to": "functions", "type": "prerequisite"},
            {"from": "functions", "to": "control_flow", "type": "prerequisite"},
            {"from": "control_flow", "to": "data_structures", "type": "prerequisite"}
        ],
        "difficulty_weights": {
            "variables": 1,
            "functions": 2,
            "control_flow": 3,
            "data_structures": 4
        }
    });

    let learning_objectives = json!({
        "objectives": [
            "Understand basic programming concepts",
            "Write simple functions and programs",
            "Use control flow effectively",
            "Work with complex data structures"
        ],
        "outcomes": [
            "Ability to solve basic programming problems",
            "Understanding of program structure and flow"
        ]
    });

    let skill_area = SkillArea {
        id: Uuid::new_v4(),
        name: "Programming Fundamentals".to_string(),
        category: "Development".to_string(),
        description: Some("Core programming concepts and practices".to_string()),
        skill_graph,
        learning_objectives: Some(learning_objectives),
        metadata: Some(json!({"tags": ["programming", "fundamentals"]})),
        created_at: chrono::Utc::now(),
        updated_at: chrono::Utc::now(),
    };

    // Test basic validation
    assert_eq!(skill_area.name, "Programming Fundamentals");
    assert_eq!(skill_area.category, "Development");
    assert_eq!(skill_area.description, Some("Core programming concepts and practices".to_string()));
    assert!(skill_area.skill_graph.is_object());
    assert!(skill_area.learning_objectives.is_some());
    assert!(skill_area.metadata.is_some());

    // Test skill graph validation
    let graph_obj = skill_area.skill_graph.as_object().unwrap();
    assert!(graph_obj.contains_key("nodes"));
    assert!(graph_obj.contains_key("edges"));
    assert!(graph_obj.contains_key("difficulty_weights"));

    // Test nodes validation
    let nodes = graph_obj.get("nodes").unwrap().as_array().unwrap();
    assert_eq!(nodes.len(), 4);
    assert_eq!(nodes[0]["id"], "variables");
    assert_eq!(nodes[0]["name"], "Variables");

    // Test edges validation
    let edges = graph_obj.get("edges").unwrap().as_array().unwrap();
    assert_eq!(edges.len(), 3);
    assert_eq!(edges[0]["from"], "variables");
    assert_eq!(edges[0]["to"], "functions");
    assert_eq!(edges[0]["type"], "prerequisite");

    // Test difficulty weights validation
    let weights = graph_obj.get("difficulty_weights").unwrap().as_object().unwrap();
    assert_eq!(weights.get("variables"), Some(&json!(1)));
    assert_eq!(weights.get("data_structures"), Some(&json!(4)));

    // Test learning objectives validation
    let objectives_obj = skill_area.learning_objectives.as_ref().unwrap().as_object().unwrap();
    assert!(objectives_obj.contains_key("objectives"));
    assert!(objectives_obj.contains_key("outcomes"));

    // Test metadata validation
    let metadata_obj = skill_area.metadata.as_ref().unwrap().as_object().unwrap();
    assert_eq!(metadata_obj.get("tags"), Some(&json!(["programming", "fundamentals"])));

    // Test UUID validation
    assert_ne!(skill_area.id, Uuid::nil());

    // Test timestamp validation
    let now = chrono::Utc::now();
    assert!(skill_area.created_at <= now);
    assert!(skill_area.updated_at <= now);
}

#[test]
fn test_skill_area_serialization_deserialization() {
    let skill_graph = json!({
        "nodes": [
            {"id": "data_analysis", "name": "Data Analysis", "description": "Basic data analysis concepts"},
            {"id": "statistics", "name": "Statistics", "description": "Statistical methods and concepts"},
            {"id": "machine_learning", "name": "Machine Learning", "description": "ML algorithms and techniques"}
        ],
        "edges": [
            {"from": "data_analysis", "to": "statistics", "type": "prerequisite"},
            {"from": "statistics", "to": "machine_learning", "type": "prerequisite"}
        ],
        "difficulty_weights": {
            "data_analysis": 1,
            "statistics": 3,
            "machine_learning": 5
        }
    });

    let skill_area = SkillArea {
        id: Uuid::new_v4(),
        name: "Data Science".to_string(),
        category: "Analytics".to_string(),
        description: Some("Data analysis and machine learning".to_string()),
        skill_graph,
        learning_objectives: Some(json!({
            "objectives": ["Understand data analysis", "Apply statistical methods", "Build ML models"],
            "outcomes": ["Proficiency in data science workflows"]
        })),
        metadata: Some(json!({"tags": ["data", "ml", "analytics"]})),
        created_at: chrono::Utc::now(),
        updated_at: chrono::Utc::now(),
    };

    // Test JSON serialization
    let serialized = serde_json::to_string(&skill_area).expect("Failed to serialize SkillArea");
    assert!(serialized.contains("Data Science"));
    assert!(serialized.contains("Analytics"));
    assert!(serialized.contains("data analysis and machine learning"));

    // Test JSON deserialization
    let deserialized: SkillArea = serde_json::from_str(&serialized).expect("Failed to deserialize SkillArea");
    assert_eq!(deserialized.name, skill_area.name);
    assert_eq!(deserialized.category, skill_area.category);
    assert_eq!(deserialized.description, skill_area.description);
    assert_eq!(deserialized.id, skill_area.id);
}

#[test]
fn test_skill_area_validation_rules() {
    // Test that skill area name cannot be empty
    let skill_graph = json!({
        "nodes": [
            {"id": "basic", "name": "Basic Concepts", "description": "Fundamental concepts"},
            {"id": "advanced", "name": "Advanced Concepts", "description": "Advanced concepts"}
        ],
        "edges": [
            {"from": "basic", "to": "advanced", "type": "prerequisite"}
        ],
        "difficulty_weights": {
            "basic": 1,
            "advanced": 3
        }
    });

    // This should be valid
    let valid_skill_area = SkillArea {
        id: Uuid::new_v4(),
        name: "Valid Skill".to_string(),
        category: "Test".to_string(),
        description: None,
        skill_graph: skill_graph.clone(),
        learning_objectives: None,
        metadata: None,
        created_at: chrono::Utc::now(),
        updated_at: chrono::Utc::now(),
    };

    assert!(!valid_skill_area.name.is_empty());
    assert!(!valid_skill_area.category.is_empty());

    // Test that skill graph must be an object
    assert!(valid_skill_area.skill_graph.is_object());

    // Test that skill graph contains required keys
    let graph_obj = valid_skill_area.skill_graph.as_object().unwrap();
    assert!(graph_obj.contains_key("nodes"));
    assert!(graph_obj.contains_key("edges"));
    assert!(graph_obj.contains_key("difficulty_weights"));

    // Test that nodes is an array
    assert!(graph_obj.get("nodes").unwrap().is_array());

    // Test that edges is an array
    assert!(graph_obj.get("edges").unwrap().is_array());

    // Test that difficulty weights is an object
    let weights_obj = graph_obj.get("difficulty_weights").unwrap().as_object().unwrap();
    assert!(weights_obj.contains_key("basic"));
    assert!(weights_obj.contains_key("advanced"));

    // Test that difficulty weight values are numbers
    assert!(weights_obj.get("basic").unwrap().is_number());
    assert!(weights_obj.get("advanced").unwrap().is_number());
}
