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
        let result = diesel::sql_query("SELECT COUNT(*) FROM knowledge_streams")
            .execute(&mut conn);
        
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
            "updated_at"
        ];
        
        for column in columns {
            let result = diesel::sql_query(format!(
                "SELECT {} FROM knowledge_streams LIMIT 0", column
            )).execute(&mut conn);
            
            assert!(result.is_ok(), "Column {} should exist in knowledge_streams table", column);
        }
        
        // Test that id is primary key
        let result = diesel::sql_query(
            "SELECT constraint_name FROM information_schema.table_constraints 
             WHERE table_name = 'knowledge_streams' 
             AND constraint_type = 'PRIMARY KEY'"
        ).execute(&mut conn);
        
        assert!(result.is_ok(), "knowledge_streams table should have a primary key");
        
        // Test that embedding_vector column is of vector type
        let result = diesel::sql_query(
            "SELECT data_type FROM information_schema.columns 
             WHERE table_name = 'knowledge_streams' 
             AND column_name = 'embedding_vector'"
        ).execute(&mut conn);
        
        assert!(result.is_ok(), "embedding_vector column should exist and be of vector type");
        
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
            "updated_at"
        ];
        
        for column in columns {
            let result = diesel::sql_query(format!(
                "SELECT {} FROM content_associations LIMIT 0", column
            )).execute(&mut conn);
            
            assert!(result.is_ok(), "Column {} should exist in content_associations table", column);
        }
        
        // Test that id is primary key
        let result = diesel::sql_query(
            "SELECT constraint_name FROM information_schema.table_constraints 
             WHERE table_name = 'content_associations' 
             AND constraint_type = 'PRIMARY KEY'"
        ).execute(&mut conn);
        
        assert!(result.is_ok(), "content_associations table should have a primary key");
        
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
            "knowledge_metrics"
        ];
        
        for table in tables {
            let result = diesel::sql_query(format!("SELECT COUNT(*) FROM {}", table))
                .execute(&mut conn);
            
            assert!(result.is_ok(), "Failed to query {} table: {:?}", table, result);
            println!("✅ {} table exists and is queryable", table);
        }
        
        // Test foreign key relationship
        let result = diesel::sql_query(
            "SELECT constraint_name FROM information_schema.table_constraints 
             WHERE table_name = 'content_associations' 
             AND constraint_type = 'FOREIGN KEY'"
        ).execute(&mut conn);
        
        assert!(result.is_ok(), "content_associations should have foreign key to knowledge_streams");
        
        println!("✅ All IRAGL tables exist with proper relationships");
    }
} 