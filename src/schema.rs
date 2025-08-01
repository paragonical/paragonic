// @generated automatically by Diesel CLI.

diesel::table! {
    agents (id) {
        id -> Uuid,
        name -> Varchar,
        description -> Nullable<Text>,
        model_name -> Varchar,
        configuration -> Nullable<Jsonb>,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

diesel::table! {
    associations (id) {
        id -> Uuid,
        organization_id -> Uuid,
        person_id -> Nullable<Uuid>,
        agent_id -> Nullable<Uuid>,
        role -> Varchar,
        permissions -> Nullable<Jsonb>,
        start_date -> Nullable<Date>,
        end_date -> Nullable<Date>,
        status -> Varchar,
        allocation_percentage -> Int4,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

diesel::table! {
    conversations (id) {
        id -> Uuid,
        agent_id -> Uuid,
        title -> Nullable<Varchar>,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
        organization_id -> Nullable<Uuid>,
    }
}

diesel::table! {
    goals (id) {
        id -> Uuid,
        project_id -> Uuid,
        name -> Varchar,
        description -> Nullable<Text>,
        status -> Varchar,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

diesel::table! {
    isrl_profiles (id) {
        id -> Uuid,
        person_id -> Uuid,
        skill_name -> Varchar,
        skill_category -> Nullable<Varchar>,
        proficiency_level -> Int4,
        last_reviewed -> Timestamptz,
        next_review -> Nullable<Timestamptz>,
        review_interval_days -> Int4,
        total_reviews -> Int4,
        success_rate -> Numeric,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

diesel::table! {
    messages (id) {
        id -> Uuid,
        conversation_id -> Uuid,
        role -> Varchar,
        content -> Text,
        created_at -> Timestamptz,
    }
}

diesel::table! {
    organizations (id) {
        id -> Uuid,
        name -> Varchar,
        description -> Nullable<Text>,
        domain -> Nullable<Varchar>,
        industry -> Nullable<Varchar>,
        size -> Nullable<Varchar>,
        status -> Varchar,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

diesel::table! {
    organization_hierarchies (id) {
        id -> Uuid,
        parent_organization_id -> Uuid,
        child_organization_id -> Uuid,
        relationship_type -> Varchar,
        created_at -> Timestamptz,
    }
}

diesel::table! {
    people (id) {
        id -> Uuid,
        name -> Varchar,
        email -> Nullable<Varchar>,
        bio -> Nullable<Text>,
        expertise_areas -> Nullable<Array<Text>>,
        location -> Nullable<Varchar>,
        timezone -> Nullable<Varchar>,
        availability_status -> Varchar,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

diesel::table! {
    projects (id) {
        id -> Uuid,
        name -> Varchar,
        description -> Nullable<Text>,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
        organization_id -> Nullable<Uuid>,
    }
}

diesel::table! {
    tasks (id) {
        id -> Uuid,
        goal_id -> Uuid,
        name -> Varchar,
        description -> Nullable<Text>,
        status -> Varchar,
        priority -> Int4,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
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
// Note: Organization hierarchies have self-referential relationships
// These are handled manually in queries rather than through joinable macros
diesel::joinable!(projects -> organizations (organization_id));
diesel::joinable!(tasks -> goals (goal_id));

diesel::allow_tables_to_appear_in_same_query!(
    agents,
    associations,
    conversations,
    goals,
    isrl_profiles,
    messages,
    organizations,
    organization_hierarchies,
    people,
    projects,
    tasks,
); 