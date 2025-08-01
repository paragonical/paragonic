// @generated automatically by Diesel CLI.

// Custom types will be handled separately

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
    embeddings (id) {
        id -> Uuid,
        #[max_length = 50]
        content_type -> Varchar,
        content_id -> Uuid,
        content_text -> Text,
        #[max_length = 100]
        embedding_model -> Varchar,
        embedding_vector -> Nullable<Bytea>, // Using Bytea for now, will handle vector type separately
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
    conversations,
    embeddings,
    goals,
    isrl_profiles,
    messages,
    organization_hierarchies,
    organizations,
    people,
    projects,
    tasks,
);
