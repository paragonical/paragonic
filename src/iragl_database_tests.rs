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
} 