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
    conversations (id) {
        id -> Uuid,
        agent_id -> Uuid,
        title -> Nullable<Varchar>,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
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
    messages (id) {
        id -> Uuid,
        conversation_id -> Uuid,
        role -> Varchar,
        content -> Text,
        created_at -> Timestamptz,
    }
}

diesel::table! {
    projects (id) {
        id -> Uuid,
        name -> Varchar,
        description -> Nullable<Text>,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
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

diesel::joinable!(conversations -> agents (agent_id));
diesel::joinable!(goals -> projects (project_id));
diesel::joinable!(messages -> conversations (conversation_id));
diesel::joinable!(tasks -> goals (goal_id));

diesel::allow_tables_to_appear_in_same_query!(
    agents,
    conversations,
    goals,
    messages,
    projects,
    tasks,
); 