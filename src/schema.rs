// @generated automatically by Diesel CLI.

pub mod sql_types {
    #[derive(diesel::sql_types::SqlType)]
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

diesel::joinable!(associations -> agents (agent_id));
diesel::joinable!(associations -> organizations (organization_id));
diesel::joinable!(associations -> people (person_id));
diesel::joinable!(content_associations -> knowledge_streams (content_id));
diesel::joinable!(conversations -> agents (agent_id));
diesel::joinable!(conversations -> organizations (organization_id));
diesel::joinable!(goals -> projects (project_id));
diesel::joinable!(isrl_profiles -> people (person_id));
diesel::joinable!(messages -> conversations (conversation_id));
diesel::joinable!(projects -> organizations (organization_id));
diesel::joinable!(tasks -> goals (goal_id));

diesel::allow_tables_to_appear_in_same_query!(
    agents,
    associations,
    content_associations,
    conversations,
    embeddings,
    goals,
    isrl_profiles,
    knowledge_metrics,
    knowledge_streams,
    messages,
    optimization_history,
    organization_hierarchies,
    organizations,
    people,
    projects,
    query_analytics,
    tasks,
);
