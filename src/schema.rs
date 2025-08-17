// @generated automatically by Diesel CLI.

pub mod sql_types {
    #[derive(diesel_derive_enum, diesel::sql_types::SqlType)]
    #[diesel(postgres_type(name = "vector"))]
    pub struct Vector;
}

diesel::table! {
    agents (id) {
        id -> Uuid,
        #[max_length = 255]
        name -> Varchar,
        description -> Nullable<Text>,
        #[max_length = 255]
        model_name -> Varchar,
        configuration -> Nullable<Jsonb>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    ai_agent_sessions (id) {
        id -> Uuid,
        #[max_length = 255]
        session_name -> Nullable<Varchar>,
        #[max_length = 100]
        session_type -> Nullable<Varchar>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
        active_patterns -> Nullable<Jsonb>,
        pattern_execution_history -> Nullable<Jsonb>,
        last_pattern_execution -> Nullable<Timestamptz>,
        pattern_learning_enabled -> Nullable<Bool>,
    }
}

diesel::table! {
    associations (id) {
        id -> Uuid,
        organization_id -> Nullable<Uuid>,
        person_id -> Nullable<Uuid>,
        agent_id -> Nullable<Uuid>,
        #[max_length = 100]
        role -> Varchar,
        permissions -> Nullable<Jsonb>,
        start_date -> Nullable<Date>,
        end_date -> Nullable<Date>,
        #[max_length = 50]
        status -> Nullable<Varchar>,
        allocation_percentage -> Nullable<Int4>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    content_associations (id) {
        id -> Uuid,
        content_id -> Uuid,
        #[max_length = 50]
        entity_type -> Varchar,
        entity_id -> Uuid,
        association_strength -> Nullable<Float8>,
        #[max_length = 50]
        association_type -> Nullable<Varchar>,
        confidence_score -> Nullable<Float8>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    conversations (id) {
        id -> Uuid,
        agent_id -> Nullable<Uuid>,
        #[max_length = 255]
        title -> Nullable<Varchar>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
        organization_id -> Nullable<Uuid>,
    }
}

diesel::table! {
    use diesel::sql_types::*;
    use super::sql_types::Vector;

    embeddings (id) {
        id -> Uuid,
        #[max_length = 50]
        content_type -> Varchar,
        content_id -> Uuid,
        content_text -> Text,
        #[max_length = 100]
        embedding_model -> Varchar,
        embedding_vector -> Nullable<Vector>,
        metadata -> Nullable<Jsonb>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    expertise_profiles (id) {
        id -> Uuid,
        person_id -> Uuid,
        #[max_length = 50]
        profile_type -> Varchar,
        #[max_length = 255]
        title -> Varchar,
        summary -> Nullable<Text>,
        skill_summary -> Jsonb,
        learning_velocity -> Nullable<Numeric>,
        total_practice_time_hours -> Nullable<Numeric>,
        total_sessions_completed -> Nullable<Int4>,
        average_session_score -> Nullable<Numeric>,
        strongest_skills -> Nullable<Jsonb>,
        skills_in_development -> Nullable<Jsonb>,
        market_value_indicators -> Nullable<Jsonb>,
        is_public -> Bool,
        metadata -> Nullable<Jsonb>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    goals (id) {
        id -> Uuid,
        project_id -> Nullable<Uuid>,
        #[max_length = 255]
        name -> Varchar,
        description -> Nullable<Text>,
        #[max_length = 50]
        status -> Nullable<Varchar>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    isrl_profiles (id) {
        id -> Uuid,
        person_id -> Nullable<Uuid>,
        #[max_length = 255]
        skill_name -> Varchar,
        #[max_length = 100]
        skill_category -> Nullable<Varchar>,
        proficiency_level -> Nullable<Int4>,
        last_reviewed -> Nullable<Timestamptz>,
        next_review -> Nullable<Timestamptz>,
        review_interval_days -> Nullable<Int4>,
        total_reviews -> Nullable<Int4>,
        success_rate -> Nullable<Numeric>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    knowledge_metrics (id) {
        id -> Uuid,
        #[max_length = 100]
        metric_name -> Varchar,
        metric_value -> Float8,
        #[max_length = 20]
        metric_unit -> Nullable<Varchar>,
        #[max_length = 20]
        time_period -> Varchar,
        period_start -> Timestamptz,
        period_end -> Timestamptz,
        metadata -> Nullable<Jsonb>,
        created_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    use diesel::sql_types::*;
    use super::sql_types::Vector;

    knowledge_streams (id) {
        id -> Uuid,
        #[max_length = 50]
        content_type -> Varchar,
        content_text -> Text,
        #[max_length = 50]
        source_entity_type -> Varchar,
        source_entity_id -> Uuid,
        metadata -> Nullable<Jsonb>,
        embedding_vector -> Nullable<Vector>,
        #[max_length = 100]
        embedding_model -> Varchar,
        #[max_length = 20]
        optimization_status -> Nullable<Varchar>,
        optimization_score -> Nullable<Float8>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    learning_analytics (id) {
        id -> Uuid,
        person_id -> Uuid,
        skill_area_id -> Uuid,
        #[max_length = 50]
        metric_type -> Varchar,
        metric_value -> Numeric,
        measurement_date -> Date,
        session_count -> Nullable<Int4>,
        practice_time_minutes -> Nullable<Int4>,
        confidence_interval_lower -> Nullable<Numeric>,
        confidence_interval_upper -> Nullable<Numeric>,
        #[max_length = 20]
        trend_direction -> Nullable<Varchar>,
        metadata -> Nullable<Jsonb>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    learning_sessions (id) {
        id -> Uuid,
        person_id -> Uuid,
        #[max_length = 50]
        session_type -> Varchar,
        #[max_length = 255]
        title -> Varchar,
        description -> Nullable<Text>,
        target_duration_minutes -> Nullable<Int4>,
        actual_duration_minutes -> Nullable<Int4>,
        #[max_length = 50]
        status -> Varchar,
        difficulty_target -> Nullable<Int4>,
        skill_areas_targeted -> Nullable<Jsonb>,
        metadata -> Nullable<Jsonb>,
        started_at -> Nullable<Timestamptz>,
        completed_at -> Nullable<Timestamptz>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    messages (id) {
        id -> Uuid,
        conversation_id -> Nullable<Uuid>,
        #[max_length = 50]
        role -> Varchar,
        content -> Text,
        created_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    optimization_history (id) {
        id -> Uuid,
        #[max_length = 50]
        optimization_type -> Varchar,
        content_count -> Int4,
        performance_improvement -> Nullable<Float8>,
        duration_ms -> Int4,
        success -> Nullable<Bool>,
        error_message -> Nullable<Text>,
        metadata -> Nullable<Jsonb>,
        created_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    organization_hierarchies (id) {
        id -> Uuid,
        parent_organization_id -> Nullable<Uuid>,
        child_organization_id -> Nullable<Uuid>,
        #[max_length = 50]
        relationship_type -> Nullable<Varchar>,
        created_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    organizations (id) {
        id -> Uuid,
        #[max_length = 255]
        name -> Varchar,
        description -> Nullable<Text>,
        #[max_length = 255]
        domain -> Nullable<Varchar>,
        #[max_length = 100]
        industry -> Nullable<Varchar>,
        #[max_length = 50]
        size -> Nullable<Varchar>,
        #[max_length = 50]
        status -> Nullable<Varchar>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    pattern_executions (id) {
        id -> Uuid,
        pattern_id -> Uuid,
        session_id -> Nullable<Uuid>,
        #[max_length = 50]
        execution_status -> Varchar,
        input_data -> Nullable<Jsonb>,
        output_data -> Nullable<Jsonb>,
        error_message -> Nullable<Text>,
        execution_time_ms -> Nullable<Int4>,
        started_at -> Nullable<Timestamptz>,
        completed_at -> Nullable<Timestamptz>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    pattern_learning_metrics (id) {
        id -> Uuid,
        pattern_id -> Uuid,
        #[max_length = 100]
        metric_name -> Varchar,
        metric_value -> Float8,
        #[max_length = 50]
        metric_unit -> Nullable<Varchar>,
        #[max_length = 20]
        time_period -> Varchar,
        period_start -> Timestamptz,
        period_end -> Timestamptz,
        metadata -> Nullable<Jsonb>,
        created_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    pattern_relationships (id) {
        id -> Uuid,
        source_pattern_id -> Uuid,
        target_pattern_id -> Uuid,
        #[max_length = 100]
        relationship_type -> Varchar,
        relationship_strength -> Nullable<Float8>,
        metadata -> Nullable<Jsonb>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    people (id) {
        id -> Uuid,
        #[max_length = 255]
        name -> Varchar,
        #[max_length = 255]
        email -> Nullable<Varchar>,
        bio -> Nullable<Text>,
        expertise_areas -> Nullable<Array<Nullable<Text>>>,
        #[max_length = 255]
        location -> Nullable<Varchar>,
        #[max_length = 50]
        timezone -> Nullable<Varchar>,
        #[max_length = 50]
        availability_status -> Nullable<Varchar>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
        learning_preferences -> Nullable<Jsonb>,
        learning_stats -> Nullable<Jsonb>,
    }
}

diesel::table! {
    practice_items (id) {
        id -> Uuid,
        skill_area_id -> Uuid,
        #[max_length = 255]
        title -> Varchar,
        content -> Text,
        #[max_length = 50]
        item_type -> Varchar,
        difficulty_level -> Int4,
        correct_answer -> Nullable<Text>,
        options -> Nullable<Jsonb>,
        hints -> Nullable<Jsonb>,
        explanation -> Nullable<Text>,
        estimated_time_minutes -> Nullable<Int4>,
        tags -> Nullable<Jsonb>,
        metadata -> Nullable<Jsonb>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    projects (id) {
        id -> Uuid,
        #[max_length = 255]
        name -> Varchar,
        description -> Nullable<Text>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
        organization_id -> Nullable<Uuid>,
    }
}

diesel::table! {
    query_analytics (id) {
        id -> Uuid,
        query_text -> Text,
        query_context -> Nullable<Jsonb>,
        result_count -> Int4,
        response_time_ms -> Int4,
        user_satisfaction_score -> Nullable<Float8>,
        optimization_impact -> Nullable<Float8>,
        created_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    session_items (id) {
        id -> Uuid,
        session_id -> Uuid,
        practice_item_id -> Uuid,
        order_in_session -> Int4,
        user_answer -> Nullable<Text>,
        is_correct -> Nullable<Bool>,
        time_spent_seconds -> Nullable<Int4>,
        confidence_level -> Nullable<Int4>,
        hints_used -> Nullable<Int4>,
        completed_at -> Nullable<Timestamptz>,
        metadata -> Nullable<Jsonb>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    skill_areas (id) {
        id -> Uuid,
        #[max_length = 255]
        name -> Varchar,
        #[max_length = 100]
        category -> Varchar,
        description -> Nullable<Text>,
        difficulty_levels -> Jsonb,
        metadata -> Nullable<Jsonb>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    skill_assessments (id) {
        id -> Uuid,
        person_id -> Uuid,
        skill_area_id -> Uuid,
        #[max_length = 50]
        assessment_type -> Varchar,
        score -> Nullable<Numeric>,
        confidence_level -> Nullable<Int4>,
        difficulty_level -> Nullable<Int4>,
        questions_answered -> Nullable<Int4>,
        questions_correct -> Nullable<Int4>,
        time_spent_minutes -> Nullable<Int4>,
        assessment_data -> Nullable<Jsonb>,
        metadata -> Nullable<Jsonb>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    skill_relationships (id) {
        id -> Uuid,
        source_skill_area_id -> Uuid,
        target_skill_area_id -> Uuid,
        #[max_length = 50]
        relationship_type -> Varchar,
        relationship_strength -> Numeric,
        learning_path_order -> Nullable<Int4>,
        description -> Nullable<Text>,
        metadata -> Nullable<Jsonb>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    spaced_repetition_schedules (id) {
        id -> Uuid,
        person_id -> Uuid,
        practice_item_id -> Uuid,
        skill_area_id -> Uuid,
        interval_days -> Int4,
        ease_factor -> Numeric,
        repetition_count -> Int4,
        next_review_date -> Date,
        last_review_date -> Nullable<Date>,
        last_review_score -> Nullable<Int4>,
        is_active -> Bool,
        metadata -> Nullable<Jsonb>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    system_patterns (id) {
        id -> Uuid,
        #[max_length = 255]
        name -> Varchar,
        description -> Nullable<Text>,
        #[max_length = 100]
        pattern_type -> Varchar,
        template_content -> Text,
        execution_conditions -> Nullable<Jsonb>,
        metadata -> Nullable<Jsonb>,
        is_active -> Nullable<Bool>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    tasks (id) {
        id -> Uuid,
        goal_id -> Nullable<Uuid>,
        #[max_length = 255]
        name -> Varchar,
        description -> Nullable<Text>,
        #[max_length = 50]
        status -> Nullable<Varchar>,
        priority -> Nullable<Int4>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
    }
}

diesel::table! {
    tool_pattern_mappings (id) {
        id -> Uuid,
        #[max_length = 255]
        tool_name -> Varchar,
        pattern_id -> Uuid,
        #[max_length = 100]
        mapping_type -> Varchar,
        usage_frequency -> Nullable<Int4>,
        success_rate -> Nullable<Float8>,
        metadata -> Nullable<Jsonb>,
        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,
    }
}

diesel::joinable!(associations -> agents (agent_id));
diesel::joinable!(associations -> organizations (organization_id));
diesel::joinable!(associations -> people (person_id));
diesel::joinable!(content_associations -> knowledge_streams (content_id));
diesel::joinable!(conversations -> agents (agent_id));
diesel::joinable!(conversations -> organizations (organization_id));
diesel::joinable!(expertise_profiles -> people (person_id));
diesel::joinable!(goals -> projects (project_id));
diesel::joinable!(isrl_profiles -> people (person_id));
diesel::joinable!(learning_analytics -> people (person_id));
diesel::joinable!(learning_analytics -> skill_areas (skill_area_id));
diesel::joinable!(learning_sessions -> people (person_id));
diesel::joinable!(messages -> conversations (conversation_id));
diesel::joinable!(pattern_executions -> system_patterns (pattern_id));
diesel::joinable!(pattern_learning_metrics -> system_patterns (pattern_id));
diesel::joinable!(practice_items -> skill_areas (skill_area_id));
diesel::joinable!(projects -> organizations (organization_id));
diesel::joinable!(session_items -> learning_sessions (session_id));
diesel::joinable!(session_items -> practice_items (practice_item_id));
diesel::joinable!(skill_assessments -> people (person_id));
diesel::joinable!(skill_assessments -> skill_areas (skill_area_id));
diesel::joinable!(spaced_repetition_schedules -> people (person_id));
diesel::joinable!(spaced_repetition_schedules -> practice_items (practice_item_id));
diesel::joinable!(spaced_repetition_schedules -> skill_areas (skill_area_id));
diesel::joinable!(tasks -> goals (goal_id));
diesel::joinable!(tool_pattern_mappings -> system_patterns (pattern_id));

diesel::allow_tables_to_appear_in_same_query!(
    agents,
    ai_agent_sessions,
    associations,
    content_associations,
    conversations,
    embeddings,
    expertise_profiles,
    goals,
    isrl_profiles,
    knowledge_metrics,
    knowledge_streams,
    learning_analytics,
    learning_sessions,
    messages,
    optimization_history,
    organization_hierarchies,
    organizations,
    pattern_executions,
    pattern_learning_metrics,
    pattern_relationships,
    people,
    practice_items,
    projects,
    query_analytics,
    session_items,
    skill_areas,
    skill_assessments,
    skill_relationships,
    spaced_repetition_schedules,
    system_patterns,
    tasks,
    tool_pattern_mappings,
);
