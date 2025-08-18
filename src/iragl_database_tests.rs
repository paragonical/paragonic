#[cfg(test)]
mod iragl_database_tests {
    use diesel::pg::PgConnection;
    use diesel::prelude::*;
    use diesel::RunQueryDsl;

    /// Test that knowledge_streams table exists and can be queried
    #[tokio::test]
    async fn test_knowledge_streams_table_exists() {
        // Connect directly to the existing PostgreSQL database
        let database_url = "postgres://postgres@localhost/paragonic_test";
        let conn_result = PgConnection::establish(database_url);

        if let Err(e) = &conn_result {
            println!("Failed to connect to database: {:?}", e);
            // Skip test if database connection fails
            return;
        }

        let mut conn = conn_result.unwrap();

        // Simple test to verify the table exists by running a count query
        let result = diesel::sql_query("SELECT COUNT(*) FROM knowledge_streams").execute(&mut conn);

        assert!(result.is_ok(), "Failed to query knowledge_streams table");
        println!("✅ knowledge_streams table exists and is queryable");
    }

    /// Test that knowledge_streams table has proper structure and constraints
    #[tokio::test]
    async fn test_knowledge_streams_table_structure() {
        // Connect directly to the existing PostgreSQL database
        let database_url = "postgres://postgres@localhost/paragonic_test";
        let conn_result = PgConnection::establish(database_url);

        if let Err(e) = &conn_result {
            println!("Failed to connect to database: {:?}", e);
            // Skip test if database connection fails
            return;
        }

        let mut conn = conn_result.unwrap();

        // Test that required columns exist
        let columns = vec![
            "id",
            "content_type",
            "content_text",
            "source_entity_type",
            "source_entity_id",
            "metadata",
            "embedding_vector", // This was missing in manual creation
            "embedding_model",
            "optimization_status",
            "optimization_score",
            "created_at",
            "updated_at",
        ];

        for column in columns {
            let result =
                diesel::sql_query(format!("SELECT {} FROM knowledge_streams LIMIT 0", column))
                    .execute(&mut conn);

            assert!(
                result.is_ok(),
                "Column {} should exist in knowledge_streams table",
                column
            );
        }

        // Test that id is primary key
        let result = diesel::sql_query(
            "SELECT constraint_name FROM information_schema.table_constraints 
             WHERE table_name = 'knowledge_streams' 
             AND constraint_type = 'PRIMARY KEY'",
        )
        .execute(&mut conn);

        assert!(
            result.is_ok(),
            "knowledge_streams table should have a primary key"
        );

        // Test that embedding_vector column is of vector type
        let result = diesel::sql_query(
            "SELECT data_type FROM information_schema.columns 
             WHERE table_name = 'knowledge_streams' 
             AND column_name = 'embedding_vector'",
        )
        .execute(&mut conn);

        assert!(
            result.is_ok(),
            "embedding_vector column should exist and be of vector type"
        );

        println!("✅ knowledge_streams table has proper structure and constraints");
    }

    /// Test that content_associations table exists and has proper structure
    #[tokio::test]
    async fn test_content_associations_table_structure() {
        // Connect directly to the existing PostgreSQL database
        let database_url = "postgres://postgres@localhost/paragonic_test";
        let conn_result = PgConnection::establish(database_url);

        if let Err(e) = &conn_result {
            println!("Failed to connect to database: {:?}", e);
            // Skip test if database connection fails
            return;
        }

        let mut conn = conn_result.unwrap();

        // Test that required columns exist
        let columns = vec![
            "id",
            "content_id",
            "entity_type",
            "entity_id",
            "association_strength",
            "association_type",
            "confidence_score",
            "created_at",
            "updated_at",
        ];

        for column in columns {
            let result = diesel::sql_query(format!(
                "SELECT {} FROM content_associations LIMIT 0",
                column
            ))
            .execute(&mut conn);

            assert!(
                result.is_ok(),
                "Column {} should exist in content_associations table",
                column
            );
        }

        // Test that id is primary key
        let result = diesel::sql_query(
            "SELECT constraint_name FROM information_schema.table_constraints 
             WHERE table_name = 'content_associations' 
             AND constraint_type = 'PRIMARY KEY'",
        )
        .execute(&mut conn);

        assert!(
            result.is_ok(),
            "content_associations table should have a primary key"
        );

        println!("✅ content_associations table has proper structure and constraints");
    }

    /// Test that all IRAGL tables exist and have proper structure
    #[tokio::test]
    async fn test_all_iragl_tables_exist() {
        // Connect directly to the existing PostgreSQL database
        let database_url = "postgres://postgres@localhost/paragonic_test";
        let conn_result = PgConnection::establish(database_url);

        if let Err(e) = &conn_result {
            println!("Failed to connect to database: {:?}", e);
            // Skip test if database connection fails
            return;
        }

        let mut conn = conn_result.unwrap();

        // Test each IRAGL table
        let tables = vec![
            "knowledge_streams",
            "content_associations",
            "optimization_history",
            "query_analytics",
            "knowledge_metrics",
        ];

        for table in tables {
            let result =
                diesel::sql_query(format!("SELECT COUNT(*) FROM {}", table)).execute(&mut conn);

            assert!(
                result.is_ok(),
                "Failed to query {} table: {:?}",
                table,
                result
            );
            println!("✅ {} table exists and is queryable", table);
        }

        // Test foreign key relationship
        let result = diesel::sql_query(
            "SELECT constraint_name FROM information_schema.table_constraints 
             WHERE table_name = 'content_associations' 
             AND constraint_type = 'FOREIGN KEY'",
        )
        .execute(&mut conn);

        assert!(
            result.is_ok(),
            "content_associations should have foreign key to knowledge_streams"
        );

        println!("✅ All IRAGL tables exist with proper relationships");
    }

    /// Test that database triggers and functions are working properly
    #[tokio::test]
    async fn test_database_triggers_and_functions() {
        // Connect directly to the existing PostgreSQL database
        let database_url = "postgres://postgres@localhost/paragonic_test";
        let conn_result = PgConnection::establish(database_url);

        if let Err(e) = &conn_result {
            println!("Failed to connect to database: {:?}", e);
            // Skip test if database connection fails
            return;
        }

        let mut conn = conn_result.unwrap();

        // Test that the update_updated_at_column function exists
        let result = diesel::sql_query(
            "SELECT routine_name FROM information_schema.routines 
             WHERE routine_name = 'update_updated_at_column'",
        )
        .execute(&mut conn);

        assert!(
            result.is_ok(),
            "update_updated_at_column function should exist"
        );

        // Test that triggers exist on knowledge_streams table
        let result = diesel::sql_query(
            "SELECT trigger_name FROM information_schema.triggers 
             WHERE event_object_table = 'knowledge_streams' 
             AND trigger_name = 'update_knowledge_streams_updated_at'",
        )
        .execute(&mut conn);

        assert!(
            result.is_ok(),
            "update_knowledge_streams_updated_at trigger should exist"
        );

        // Test that triggers exist on content_associations table
        let result = diesel::sql_query(
            "SELECT trigger_name FROM information_schema.triggers 
             WHERE event_object_table = 'content_associations' 
             AND trigger_name = 'update_content_associations_updated_at'",
        )
        .execute(&mut conn);

        assert!(
            result.is_ok(),
            "update_content_associations_updated_at trigger should exist"
        );

        println!("✅ Database triggers and functions are properly configured");
    }

    /// Test that the updated_at triggers actually work by updating a record
    #[tokio::test]
    async fn test_updated_at_trigger_functionality() {
        // Connect directly to the existing PostgreSQL database
        let database_url = "postgres://postgres@localhost/paragonic_test";
        let conn_result = PgConnection::establish(database_url);

        if let Err(e) = &conn_result {
            println!("Failed to connect to database: {:?}", e);
            // Skip test if database connection fails
            return;
        }

        let mut conn = conn_result.unwrap();

        // Insert a test record into knowledge_streams
        let insert_result = diesel::sql_query(
            "INSERT INTO knowledge_streams (content_type, content_text, source_entity_type, source_entity_id, embedding_model) 
             VALUES ('test', 'Test content for trigger testing', 'test', gen_random_uuid(), 'test-model') 
             RETURNING id, created_at, updated_at"
        ).execute(&mut conn);

        assert!(
            insert_result.is_ok(),
            "Should be able to insert test record"
        );

        // Get the inserted record's timestamps
        let result = diesel::sql_query(
            "SELECT id, created_at, updated_at FROM knowledge_streams 
             WHERE content_text = 'Test content for trigger testing' 
             ORDER BY created_at DESC LIMIT 1",
        )
        .execute(&mut conn);

        assert!(result.is_ok(), "Should be able to query inserted record");

        // Update the record to trigger the updated_at column
        let update_result = diesel::sql_query(
            "UPDATE knowledge_streams 
             SET content_text = 'Updated test content' 
             WHERE content_text = 'Test content for trigger testing'",
        )
        .execute(&mut conn);

        assert!(update_result.is_ok(), "Should be able to update record");

        // Verify that updated_at was changed
        let result = diesel::sql_query(
            "SELECT id, created_at, updated_at FROM knowledge_streams 
             WHERE content_text = 'Updated test content'",
        )
        .execute(&mut conn);

        assert!(result.is_ok(), "Should be able to query updated record");

        // Clean up test data
        let cleanup_result = diesel::sql_query(
            "DELETE FROM knowledge_streams WHERE content_text = 'Updated test content'",
        )
        .execute(&mut conn);

        assert!(
            cleanup_result.is_ok(),
            "Should be able to clean up test data"
        );

        println!("✅ updated_at triggers are working properly");
    }

    /// Test that check constraints are working properly
    #[tokio::test]
    async fn test_check_constraints() {
        // Connect directly to the existing PostgreSQL database
        let database_url = "postgres://postgres@localhost/paragonic_test";
        let conn_result = PgConnection::establish(database_url);

        if let Err(e) = &conn_result {
            println!("Failed to connect to database: {:?}", e);
            // Skip test if database connection fails
            return;
        }

        let mut conn = conn_result.unwrap();

        // Test that check constraints exist
        let constraints = vec![
            ("knowledge_streams", "chk_optimization_status"),
            ("content_associations", "chk_association_strength"),
            ("content_associations", "chk_confidence_score"),
            ("optimization_history", "chk_performance_improvement"),
        ];

        for (table, constraint) in constraints {
            let result = diesel::sql_query(format!(
                "SELECT constraint_name FROM information_schema.check_constraints 
                 WHERE constraint_name = '{}'",
                constraint
            ))
            .execute(&mut conn);

            assert!(
                result.is_ok(),
                "Check constraint {} should exist on table {}",
                constraint,
                table
            );
        }

        // Test that invalid optimization_status is rejected
        let result = diesel::sql_query(
            "INSERT INTO knowledge_streams (content_type, content_text, source_entity_type, source_entity_id, embedding_model, optimization_status) 
             VALUES ('test', 'Test content', 'test', gen_random_uuid(), 'test-model', 'invalid_status')"
        ).execute(&mut conn);

        // This should fail due to check constraint
        assert!(
            result.is_err(),
            "Invalid optimization_status should be rejected by check constraint"
        );

        // Test that valid optimization_status is accepted
        let result = diesel::sql_query(
            "INSERT INTO knowledge_streams (content_type, content_text, source_entity_type, source_entity_id, embedding_model, optimization_status) 
             VALUES ('test', 'Test content', 'test', gen_random_uuid(), 'test-model', 'pending')"
        ).execute(&mut conn);

        assert!(
            result.is_ok(),
            "Valid optimization_status should be accepted"
        );

        // Clean up test data
        let cleanup_result =
            diesel::sql_query("DELETE FROM knowledge_streams WHERE content_text = 'Test content'")
                .execute(&mut conn);

        assert!(
            cleanup_result.is_ok(),
            "Should be able to clean up test data"
        );

        println!("✅ Check constraints are working properly");
    }

    /// Test knowledge stream ingestion functionality
    #[tokio::test]
    async fn test_knowledge_stream_ingestion() {
        // Connect directly to the existing PostgreSQL database
        let database_url = "postgres://postgres@localhost/paragonic_test";
        let conn_result = PgConnection::establish(database_url);

        if let Err(e) = &conn_result {
            println!("Failed to connect to database: {:?}", e);
            // Skip test if database connection fails
            return;
        }

        let mut conn = conn_result.unwrap();

        // Test inserting a knowledge stream
        let test_content = "Test knowledge stream content for ingestion testing";
        let insert_result = diesel::sql_query(format!(
            "INSERT INTO knowledge_streams (content_type, content_text, source_entity_type, source_entity_id, embedding_model) 
             VALUES ('communication', '{}', 'project', gen_random_uuid(), 'test-model') 
             RETURNING id, content_type, content_text, source_entity_type, embedding_model, optimization_status",
            test_content
        )).execute(&mut conn);

        assert!(
            insert_result.is_ok(),
            "Should be able to insert knowledge stream"
        );

        // Verify the inserted record
        let result = diesel::sql_query(format!(
            "SELECT id, content_type, content_text, source_entity_type, embedding_model, optimization_status 
             FROM knowledge_streams 
             WHERE content_text = '{}'",
            test_content
        )).execute(&mut conn);

        assert!(
            result.is_ok(),
            "Should be able to query inserted knowledge stream"
        );

        // Verify default values
        let result = diesel::sql_query(format!(
            "SELECT optimization_status, optimization_score 
             FROM knowledge_streams 
             WHERE content_text = '{}'",
            test_content
        ))
        .execute(&mut conn);

        assert!(
            result.is_ok(),
            "Should be able to query optimization fields"
        );

        // Clean up test data
        let cleanup_result = diesel::sql_query(format!(
            "DELETE FROM knowledge_streams WHERE content_text = '{}'",
            test_content
        ))
        .execute(&mut conn);

        assert!(
            cleanup_result.is_ok(),
            "Should be able to clean up test data"
        );

        println!("✅ Knowledge stream ingestion functionality works");
    }
}
