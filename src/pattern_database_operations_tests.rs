//! Pattern Database Operations Tests
//!
//! This module contains tests for database operations on pattern-related tables.
//! These tests ensure that all CRUD operations work correctly for the pattern system.

#[cfg(test)]
mod tests {
    use super::*;
    use crate::database::{execute_test_db_operation, initialize_for_testing};
    use crate::error::ParagonicResult;
    use diesel::deserialize::QueryableByName;
    use diesel::prelude::*;
    use diesel::sql_query;
    use serde_json::json;
    use uuid::Uuid;

    /// Test creating a system pattern
    #[tokio::test]
    async fn test_create_system_pattern() -> ParagonicResult<()> {
        // Initialize test database
        let init_result = initialize_for_testing().await;
        if let Err(e) = &init_result {
            println!("Database initialization failed: {:?}", e);
            return Ok(());
        }

        // Test creating a system pattern
        let result = execute_test_db_operation(|conn| {
            // First ensure the table exists
            sql_query(r#"
                CREATE TABLE IF NOT EXISTS system_patterns (
                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    name VARCHAR(255) NOT NULL,
                    description TEXT,
                    pattern_type VARCHAR(100) NOT NULL,
                    template_content TEXT NOT NULL,
                    execution_conditions JSONB,
                    metadata JSONB,
                    is_active BOOLEAN DEFAULT true,
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                )
            "#).execute(conn)?;

            // Insert a test pattern
            let pattern_id = Uuid::new_v4();
            sql_query(r#"
                INSERT INTO system_patterns (id, name, description, pattern_type, template_content, execution_conditions, metadata)
                VALUES ($1, $2, $3, $4, $5, $6, $7)
            "#)
            .bind::<diesel::sql_types::Uuid, _>(pattern_id)
            .bind::<diesel::sql_types::Varchar, _>("test_pattern")
            .bind::<diesel::sql_types::Text, _>("A test pattern for database operations")
            .bind::<diesel::sql_types::Varchar, _>("session_summary")
            .bind::<diesel::sql_types::Text, _>("Generate a summary of the session")
            .bind::<diesel::sql_types::Jsonb, _>(json!({"session_duration_minutes": 30}))
            .bind::<diesel::sql_types::Jsonb, _>(json!({"version": "1.0"}))
            .execute(conn)?;

            Ok(pattern_id)
        }).await?;

        // If database is not available, skip the test
        if result.is_none() {
            println!("Database not available, skipping database operations test");
            return Ok(());
        }

        assert!(result.is_some());
        Ok(())
    }

    /// Test retrieving a system pattern
    #[tokio::test]
    async fn test_retrieve_system_pattern() -> ParagonicResult<()> {
        // Initialize test database
        let init_result = initialize_for_testing().await;
        if let Err(e) = &init_result {
            println!("Database initialization failed: {:?}", e);
            return Ok(());
        }

        // Test retrieving a system pattern
        let result = execute_test_db_operation(|conn| {
            // First ensure the table exists
            sql_query(
                r#"
                CREATE TABLE IF NOT EXISTS system_patterns (
                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    name VARCHAR(255) NOT NULL,
                    description TEXT,
                    pattern_type VARCHAR(100) NOT NULL,
                    template_content TEXT NOT NULL,
                    execution_conditions JSONB,
                    metadata JSONB,
                    is_active BOOLEAN DEFAULT true,
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                )
            "#,
            )
            .execute(conn)?;

            // Insert a test pattern
            let pattern_id = Uuid::new_v4();
            sql_query(
                r#"
                INSERT INTO system_patterns (id, name, description, pattern_type, template_content)
                VALUES ($1, $2, $3, $4, $5)
            "#,
            )
            .bind::<diesel::sql_types::Uuid, _>(pattern_id)
            .bind::<diesel::sql_types::Varchar, _>("retrieve_test_pattern")
            .bind::<diesel::sql_types::Text, _>("A test pattern for retrieval")
            .bind::<diesel::sql_types::Varchar, _>("activity_labeling")
            .bind::<diesel::sql_types::Text, _>("Label the current activity")
            .execute(conn)?;

            // Verify the pattern was inserted by counting
            #[derive(QueryableByName)]
            struct CountRow {
                #[diesel(sql_type = diesel::sql_types::BigInt)]
                count: i64,
            }

            let count: CountRow = sql_query(
                r#"
                SELECT COUNT(*) as count FROM system_patterns WHERE name = 'retrieve_test_pattern'
            "#,
            )
            .get_result(conn)?;

            Ok(count.count)
        })
        .await?;

        // If database is not available, skip the test
        if result.is_none() {
            println!("Database not available, skipping database operations test");
            return Ok(());
        }

        let count = result.unwrap();
        assert_eq!(count, 1);
        Ok(())
    }

    /// Test updating a system pattern
    #[tokio::test]
    async fn test_update_system_pattern() -> ParagonicResult<()> {
        // Initialize test database
        let init_result = initialize_for_testing().await;
        if let Err(e) = &init_result {
            println!("Database initialization failed: {:?}", e);
            return Ok(());
        }

        // Test updating a system pattern
        let result = execute_test_db_operation(|conn| {
            // First ensure the table exists
            sql_query(r#"
                CREATE TABLE IF NOT EXISTS system_patterns (
                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    name VARCHAR(255) NOT NULL,
                    description TEXT,
                    pattern_type VARCHAR(100) NOT NULL,
                    template_content TEXT NOT NULL,
                    execution_conditions JSONB,
                    metadata JSONB,
                    is_active BOOLEAN DEFAULT true,
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                )
            "#).execute(conn)?;

            // Insert a test pattern
            let pattern_id = Uuid::new_v4();
            sql_query(r#"
                INSERT INTO system_patterns (id, name, description, pattern_type, template_content)
                VALUES ($1, $2, $3, $4, $5)
            "#)
            .bind::<diesel::sql_types::Uuid, _>(pattern_id)
            .bind::<diesel::sql_types::Varchar, _>("update_test_pattern")
            .bind::<diesel::sql_types::Text, _>("Original description")
            .bind::<diesel::sql_types::Varchar, _>("self_reflection")
            .bind::<diesel::sql_types::Text, _>("Original template")
            .execute(conn)?;

            // Update the pattern
            sql_query(r#"
                UPDATE system_patterns 
                SET description = $1, template_content = $2, updated_at = NOW()
                WHERE id = $3
            "#)
            .bind::<diesel::sql_types::Text, _>("Updated description")
            .bind::<diesel::sql_types::Text, _>("Updated template content")
            .bind::<diesel::sql_types::Uuid, _>(pattern_id)
            .execute(conn)?;

            // Verify the update by counting updated records
            #[derive(QueryableByName)]
            struct CountRow {
                #[diesel(sql_type = diesel::sql_types::BigInt)]
                count: i64,
            }

            let count: CountRow = sql_query(r#"
                SELECT COUNT(*) as count FROM system_patterns WHERE description = 'Updated description'
            "#)
            .get_result(conn)?;

            Ok(count.count)
        }).await?;

        // If database is not available, skip the test
        if result.is_none() {
            println!("Database not available, skipping database operations test");
            return Ok(());
        }

        let count = result.unwrap();
        assert_eq!(count, 1);
        Ok(())
    }

    /// Test deleting a system pattern
    #[tokio::test]
    async fn test_delete_system_pattern() -> ParagonicResult<()> {
        // Initialize test database
        let init_result = initialize_for_testing().await;
        if let Err(e) = &init_result {
            println!("Database initialization failed: {:?}", e);
            return Ok(());
        }

        // Test deleting a system pattern
        let result = execute_test_db_operation(|conn| {
            // First ensure the table exists
            sql_query(
                r#"
                CREATE TABLE IF NOT EXISTS system_patterns (
                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    name VARCHAR(255) NOT NULL,
                    description TEXT,
                    pattern_type VARCHAR(100) NOT NULL,
                    template_content TEXT NOT NULL,
                    execution_conditions JSONB,
                    metadata JSONB,
                    is_active BOOLEAN DEFAULT true,
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                )
            "#,
            )
            .execute(conn)?;

            // Insert a test pattern
            let pattern_id = Uuid::new_v4();
            sql_query(
                r#"
                INSERT INTO system_patterns (id, name, description, pattern_type, template_content)
                VALUES ($1, $2, $3, $4, $5)
            "#,
            )
            .bind::<diesel::sql_types::Uuid, _>(pattern_id)
            .bind::<diesel::sql_types::Varchar, _>("delete_test_pattern")
            .bind::<diesel::sql_types::Text, _>("A test pattern for deletion")
            .bind::<diesel::sql_types::Varchar, _>("context_condensation")
            .bind::<diesel::sql_types::Text, _>("Condense context information")
            .execute(conn)?;

            // Delete the pattern
            sql_query(
                r#"
                DELETE FROM system_patterns WHERE id = $1
            "#,
            )
            .bind::<diesel::sql_types::Uuid, _>(pattern_id)
            .execute(conn)?;

            // Verify the deletion
            #[derive(QueryableByName)]
            struct CountRow {
                #[diesel(sql_type = diesel::sql_types::BigInt, column_name = "count")]
                count: i64,
            }

            let count: CountRow = sql_query(
                r#"
                SELECT COUNT(*) as count FROM system_patterns WHERE id = $1
            "#,
            )
            .bind::<diesel::sql_types::Uuid, _>(pattern_id)
            .get_result(conn)?;

            Ok(count.count)
        })
        .await?;

        // If database is not available, skip the test
        if result.is_none() {
            println!("Database not available, skipping database operations test");
            return Ok(());
        }

        let count = result.unwrap();
        assert_eq!(count, 0);
        Ok(())
    }

    /// Test pattern execution tracking
    #[tokio::test]
    async fn test_pattern_execution_tracking() -> ParagonicResult<()> {
        // Initialize test database
        let init_result = initialize_for_testing().await;
        if let Err(e) = &init_result {
            println!("Database initialization failed: {:?}", e);
            return Ok(());
        }

        // Test pattern execution tracking
        let result = execute_test_db_operation(|conn| {
            // Create system_patterns table
            sql_query(r#"
                CREATE TABLE IF NOT EXISTS system_patterns (
                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    name VARCHAR(255) NOT NULL,
                    description TEXT,
                    pattern_type VARCHAR(100) NOT NULL,
                    template_content TEXT NOT NULL,
                    execution_conditions JSONB,
                    metadata JSONB,
                    is_active BOOLEAN DEFAULT true,
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                )
            "#).execute(conn)?;

            // Create pattern_executions table
            sql_query(r#"
                CREATE TABLE IF NOT EXISTS pattern_executions (
                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    pattern_id UUID NOT NULL REFERENCES system_patterns(id) ON DELETE CASCADE,
                    session_id UUID,
                    execution_status VARCHAR(50) NOT NULL,
                    input_data JSONB,
                    output_data JSONB,
                    error_message TEXT,
                    execution_time_ms INTEGER,
                    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                    completed_at TIMESTAMP WITH TIME ZONE,
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                )
            "#).execute(conn)?;

            // Insert a test pattern
            let pattern_id = Uuid::new_v4();
            sql_query(r#"
                INSERT INTO system_patterns (id, name, description, pattern_type, template_content)
                VALUES ($1, $2, $3, $4, $5)
            "#)
            .bind::<diesel::sql_types::Uuid, _>(pattern_id)
            .bind::<diesel::sql_types::Varchar, _>("execution_test_pattern")
            .bind::<diesel::sql_types::Text, _>("A test pattern for execution tracking")
            .bind::<diesel::sql_types::Varchar, _>("progress_tracking")
            .bind::<diesel::sql_types::Text, _>("Track progress in the session")
            .execute(conn)?;

            // Create an execution record
            let execution_id = Uuid::new_v4();
            let session_id = Uuid::new_v4();
            sql_query(r#"
                INSERT INTO pattern_executions (id, pattern_id, session_id, execution_status, input_data, output_data, execution_time_ms)
                VALUES ($1, $2, $3, $4, $5, $6, $7)
            "#)
            .bind::<diesel::sql_types::Uuid, _>(execution_id)
            .bind::<diesel::sql_types::Uuid, _>(pattern_id)
            .bind::<diesel::sql_types::Uuid, _>(session_id)
            .bind::<diesel::sql_types::Varchar, _>("completed")
            .bind::<diesel::sql_types::Jsonb, _>(json!({"session_duration": 45}))
            .bind::<diesel::sql_types::Jsonb, _>(json!({"progress_percentage": 75}))
            .bind::<diesel::sql_types::Integer, _>(150)
            .execute(conn)?;

            // Verify the execution record by counting
            #[derive(QueryableByName)]
            struct CountRow {
                #[diesel(sql_type = diesel::sql_types::BigInt)]
                count: i64,
            }

            let count: CountRow = sql_query(r#"
                SELECT COUNT(*) as count FROM pattern_executions WHERE execution_status = 'completed'
            "#)
            .get_result(conn)?;

            Ok(count.count)
        }).await?;

        // If database is not available, skip the test
        if result.is_none() {
            println!("Database not available, skipping database operations test");
            return Ok(());
        }

        let count = result.unwrap();
        assert_eq!(count, 1);
        Ok(())
    }
}
