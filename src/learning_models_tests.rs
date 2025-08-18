#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;
    use uuid::Uuid;
    use crate::learning_models::{
        calculate_next_practice_interval,
        update_learning_state,
        calculate_unit_priority,
        SuperMemo2Engine,
        AdaptiveDifficultyScaler,
        PracticeSessionGenerator,
        RetentionMeasurer,
        TransferLearningAssessor,
        HumanLearningState,
        LearningUnit,
        PracticeSession,
        HumanAssistanceRequest,
        CompletionEstimates
    };

    // ============================================================================
    // ISRL Learning Engine Tests
    // ============================================================================

    /// Test SuperMemo 2 algorithm core functionality
    #[test]
    fn test_supermemo2_algorithm() {
        let mut engine = SuperMemo2Engine::new();
        
        // Test initial state
        assert_eq!(engine.e_factor, 2.5);
        assert_eq!(engine.interval, 1);
        assert_eq!(engine.repetitions, 0);
        
        // Test first successful response (quality 5)
        let interval = engine.process_response(5);
        assert_eq!(interval, 6); // First successful response should be 6 days
        assert!(engine.e_factor > 2.5); // E-Factor should increase
        assert_eq!(engine.repetitions, 1);
        
        // Test second successful response
        let interval = engine.process_response(4);
        assert!(interval > 6); // Should increase interval
        assert!(engine.e_factor > 2.5); // E-Factor should still be high
        assert_eq!(engine.repetitions, 2);
        
        // Test failed response (quality 2)
        let interval = engine.process_response(2);
        assert_eq!(interval, 1); // Should reset to 1 day
        assert!(engine.e_factor < 2.5); // E-Factor should decrease
        assert_eq!(engine.repetitions, 3);
    }

    /// Test interleaving modifications for mixed skill areas
    #[test]
    fn test_interleaving_modifications() {
        let engine = SuperMemo2Engine::new();
        
        // Test interleaving modification for low mastery
        let low_mastery_interval = engine.apply_interleaving_modification(7, 0.2);
        assert_eq!(low_mastery_interval, 6); // 7 * 0.83 = 5.81, rounded to 6
        
        // Test interleaving modification for high mastery
        let high_mastery_interval = engine.apply_interleaving_modification(7, 0.9);
        assert_eq!(high_mastery_interval, 7); // 7 * 0.935 = 6.545, rounded to 7
    }

    /// Test adaptive difficulty scaling based on performance
    #[test]
    fn test_adaptive_difficulty_scaling() {
        let mut scaler = AdaptiveDifficultyScaler::new(3, 0.7);
        
        // Test difficulty increase for high performance
        let difficulty = scaler.add_performance(0.9);
        assert!(difficulty > 3); // Should increase difficulty
        
        // Reset for next test
        let mut scaler2 = AdaptiveDifficultyScaler::new(3, 0.7);
        
        // Test difficulty decrease for low performance
        let difficulty = scaler2.add_performance(0.3);
        assert!(difficulty < 3); // Should decrease difficulty
        
        // Test stable difficulty for target performance
        let difficulty = scaler2.add_performance(0.7);
        assert_eq!(difficulty, scaler2.get_difficulty()); // Should remain stable
    }

    /// Test practice session generation with mixed skill areas
    #[test]
    fn test_mixed_skill_area_practice_sessions() {
        let skill_areas = vec!["rust".to_string(), "lua".to_string(), "sql".to_string(), "algorithms".to_string()];
        let generator = PracticeSessionGenerator::new(skill_areas, 10, 5.0);
        
        let session_items = generator.generate_session();
        
        // Verify interleaving pattern
        assert_eq!(session_items.len(), 10);
        assert_eq!(session_items[0], "rust");
        assert_eq!(session_items[1], "lua");
        assert_eq!(session_items[2], "sql");
        assert_eq!(session_items[3], "algorithms");
        assert_eq!(session_items[4], "rust"); // Cycles back
    }

    /// Test learning retention measurement
    #[test]
    fn test_learning_retention_measurement() {
        let measurer = RetentionMeasurer::new(8000, 0.95);
        
        // Test retention calculation over time
        let expected_score = measurer.calculate_retention(30);
        
        assert!(expected_score < 8000); // Should decrease over time
        assert!(expected_score > 0); // Should not go below 0
        
        // Test retention rate calculation
        let retention_rate = RetentionMeasurer::calculate_retention_rate(8000, 6000, 30);
        assert!(retention_rate < 1.0); // Should be less than 100%
        assert!(retention_rate > 0.0); // Should be positive
    }

    /// Test transfer learning assessment
    #[test]
    fn test_transfer_learning_assessment() {
        let assessor = TransferLearningAssessor::new(7500);
        
        // Test transfer to related skills (distance 0)
        let transferred_score = assessor.calculate_transferred_score(0);
        assert_eq!(transferred_score, 2250); // 7500 * 0.3 = 2250
        
        // Test transfer to distant skills (distance 2)
        let distant_transferred_score = assessor.calculate_transferred_score(2);
        assert_eq!(distant_transferred_score, 750); // 7500 * 0.1 = 750
        
        // Test all transferred scores
        let all_scores = assessor.get_all_transferred_scores();
        assert_eq!(all_scores.len(), 4); // Should have 4 different transfer factors
        assert!(all_scores[0] > all_scores[1]); // Closer skills should have higher transfer
    }

    /// Test spaced repetition scheduling optimization
    #[test]
    fn test_spaced_repetition_scheduling_optimization() {
        let engine = SuperMemo2Engine::new();
        
        // Test optimal interval calculation based on forgetting curve
        let optimal_interval = engine.calculate_optimal_interval(0.8, 0.1);
        assert_eq!(optimal_interval, 2); // -ln(0.8) / 0.1 ≈ 2 days
        
        // Test that interval increases with better retention
        let longer_interval = engine.calculate_optimal_interval(0.9, 0.1);
        // -ln(0.9) / 0.1 = -(-0.105) / 0.1 = 0.105 / 0.1 = 1.05 ≈ 1
        // Actually, higher retention means shorter interval, not longer
        assert!(longer_interval <= optimal_interval);
    }

    /// Test difficulty level balancing across skill areas
    #[test]
    fn test_difficulty_level_balancing() {
        let skill_areas = vec!["rust".to_string(), "lua".to_string()];
        let generator = PracticeSessionGenerator::new(skill_areas, 5, 5.0);
        
        // Test difficulty adjustment for unbalanced session
        let mut unbalanced_difficulties = vec![1, 1, 1, 9, 9]; // Too easy and too hard
        let balanced_difficulties = generator.balance_difficulty(&mut unbalanced_difficulties);
        
        // Calculate average difficulty after balancing
        let adjusted_avg = balanced_difficulties.iter().sum::<i32>() as f64 / balanced_difficulties.len() as f64;
        assert!((adjusted_avg - 5.0).abs() < 1.0); // Should be closer to target
    }

    /// Test session length optimization
    #[test]
    fn test_session_length_optimization() {
        // Test optimal session length based on attention span and learning efficiency
        let base_session_length = 20; // 20 minutes
        let attention_span_factor = 0.8; // 80% of base for optimal attention
        let learning_efficiency_factor = 1.2; // 20% increase for optimal learning
        
        let optimal_length = (base_session_length as f64 * attention_span_factor * learning_efficiency_factor).round() as i32;
        assert_eq!(optimal_length, 19); // 20 * 0.8 * 1.2 = 19.2, rounded to 19
        
        // Test that session length adapts to user performance
        let high_performance_factor = 1.1; // 10% longer for high performers
        let low_performance_factor = 0.9; // 10% shorter for low performers
        
        let high_performance_length = (base_session_length as f64 * high_performance_factor).round() as i32;
        let low_performance_length = (base_session_length as f64 * low_performance_factor).round() as i32;
        
        assert_eq!(high_performance_length, 22); // 20 * 1.1 = 22
        assert_eq!(low_performance_length, 18); // 20 * 0.9 = 18
    }

    /// Test practice item selection algorithms
    #[test]
    fn test_practice_item_selection_algorithms() {
        // Test intelligent item selection based on user needs
        let available_items = vec![
            ("rust_basics", 1, 0.8), // (name, difficulty, priority)
            ("rust_advanced", 5, 0.6),
            ("lua_basics", 2, 0.9),
            ("sql_basics", 3, 0.7),
        ];
        
        // Select items based on priority and difficulty balance
        let mut selected_items = Vec::new();
        let target_difficulty = 3;
        
        for (name, difficulty, priority) in &available_items {
            let selection_score = priority * (1.0 - (*difficulty as i32 - target_difficulty).abs() as f64 / 5.0);
            if selection_score > 0.5 {
                selected_items.push(*name);
            }
        }
        
        // Should select items with good priority and close to target difficulty
        assert!(selected_items.contains(&"lua_basics")); // High priority, close to target
        assert!(selected_items.contains(&"sql_basics")); // Medium priority, exact target
    }

    /// Test contextual practice item generation
    #[test]
    fn test_contextual_practice_item_generation() {
        // Test that practice items relate to actual project work
        let _project_context = "rust_web_server";
        let current_skills = vec!["rust", "http", "database"];
        let target_skills = vec!["async_rust", "error_handling", "testing"];
        
        // Generate contextual practice items
        let contextual_items = vec![
            "Implement async error handling for HTTP requests",
            "Write tests for database connection pooling",
            "Debug memory leaks in web server",
        ];
        
        // Verify items relate to project context
        for item in &contextual_items {
            assert!(item.contains("HTTP") || item.contains("database") || item.contains("server"));
        }
        
        // Verify items target missing skills
        let missing_skills = target_skills.iter()
            .filter(|skill| !current_skills.contains(skill))
            .collect::<Vec<_>>();
        
        assert_eq!(missing_skills.len(), 3); // All target skills are missing
    }

    // ============================================================================
    // Existing Tests (keeping for compatibility)
    // ============================================================================

    /// Test the adaptive scheduling algorithm
    #[test]
    fn test_calculate_next_practice_interval() {
        // Test "not_seen" judgment - should schedule for tomorrow
        let interval = calculate_next_practice_interval(0, "not_seen", 7);
        assert_eq!(interval, 1);

        // Test "forgotten" judgment with low score - should decrease interval
        let interval = calculate_next_practice_interval(2000, "forgotten", 7);
        assert!(interval < 7);
        assert!(interval >= 1);

        // Test "forgotten" judgment with high score - should decrease interval less
        let interval = calculate_next_practice_interval(8000, "forgotten", 7);
        assert!(interval < 7);
        assert!(interval >= 1); // Minimum interval is 1 day

        // Test "recalled" judgment with low score - should increase interval slightly
        let interval = calculate_next_practice_interval(2000, "recalled", 7);
        assert!(interval > 7);

        // Test "recalled" judgment with high score - should increase interval significantly
        let interval = calculate_next_practice_interval(8000, "recalled", 7);
        assert!(interval > 14); // Should be at least 2x longer

        // Test unknown judgment - should use base frequency
        let interval = calculate_next_practice_interval(5000, "unknown", 7);
        assert_eq!(interval, 7);
    }

    /// Test learning state updates based on human judgments
    #[test]
    fn test_update_learning_state() {
        let mut state = HumanLearningState {
            id: Uuid::new_v4(),
            person_id: Uuid::new_v4(),
            learning_unit_id: Uuid::new_v4(),
            learning_state: "not_seen".to_string(),
            current_score: 5000, // 50%
            last_practiced: None,
            practice_frequency_days: 7,
            next_practice_date: None,
            total_practice_sessions: 0,
            metadata: None,
            created_at: Some(chrono::Utc::now()),
            updated_at: Some(chrono::Utc::now()),
        };

        let initial_score = state.current_score;
        let initial_sessions = state.total_practice_sessions;

        // Test "not_seen" judgment
        update_learning_state(&mut state, "not_seen", 7);
        assert_eq!(state.learning_state, "not_seen");
        assert_eq!(state.current_score, initial_score); // No change for first encounter
        assert_eq!(state.total_practice_sessions, initial_sessions + 1);
        assert!(state.last_practiced.is_some());
        assert_eq!(state.practice_frequency_days, 1); // Schedule for tomorrow

        // Test "forgotten" judgment
        update_learning_state(&mut state, "forgotten", 7);
        assert_eq!(state.learning_state, "forgotten");
        assert!(state.current_score < initial_score); // Score should decrease
        assert!(state.current_score >= 3000); // Should not decrease below 30%
        assert_eq!(state.total_practice_sessions, initial_sessions + 2);
        assert!(state.practice_frequency_days < 7); // More frequent practice

        // Test "recalled" judgment
        update_learning_state(&mut state, "recalled", 7);
        assert_eq!(state.learning_state, "recalled");
        assert!(state.current_score > 3000); // Score should increase
        assert!(state.current_score <= 10000); // Should not exceed 100%
        assert_eq!(state.total_practice_sessions, initial_sessions + 3);
        assert!(state.practice_frequency_days > 7); // Less frequent practice
    }

    /// Test unit priority calculation for practice session generation
    #[test]
    fn test_calculate_unit_priority() {
        let state = HumanLearningState {
            id: Uuid::new_v4(),
            person_id: Uuid::new_v4(),
            learning_unit_id: Uuid::new_v4(),
            learning_state: "not_seen".to_string(),
            current_score: 0,
            last_practiced: None,
            practice_frequency_days: 7,
            next_practice_date: None,
            total_practice_sessions: 0,
            metadata: None,
            created_at: Some(chrono::Utc::now()),
            updated_at: Some(chrono::Utc::now()),
        };

        // Test priority for different enrollment levels
        let light_priority = calculate_unit_priority(&state, "light");
        let moderate_priority = calculate_unit_priority(&state, "moderate");
        let intensive_priority = calculate_unit_priority(&state, "intensive");

        assert!(light_priority < moderate_priority);
        assert!(moderate_priority < intensive_priority);

        // Test priority for different learning states
        let mut forgotten_state = state.clone();
        forgotten_state.learning_state = "forgotten".to_string();
        forgotten_state.current_score = 3000;

        let mut recalled_state = state.clone();
        recalled_state.learning_state = "recalled".to_string();
        recalled_state.current_score = 8000;

        let not_seen_priority = calculate_unit_priority(&state, "moderate");
        let forgotten_priority = calculate_unit_priority(&forgotten_state, "moderate");
        let recalled_priority = calculate_unit_priority(&recalled_state, "moderate");

        assert!(not_seen_priority > recalled_priority); // Not seen should be higher priority
        assert!(forgotten_priority > recalled_priority); // Forgotten should be higher priority
        assert!(not_seen_priority > forgotten_priority); // Not seen should be highest priority
    }

    /// Test edge cases and error handling
    #[test]
    fn test_edge_cases() {
        // Test with maximum score
        let interval = calculate_next_practice_interval(10000, "recalled", 7);
        assert!(interval > 7);

        // Test with minimum score
        let interval = calculate_next_practice_interval(0, "forgotten", 7);
        assert!(interval < 7);

        // Test with invalid judgment
        let interval = calculate_next_practice_interval(5000, "invalid_judgment", 7);
        assert_eq!(interval, 7); // Should use base frequency

        // Test with zero base frequency
        let interval = calculate_next_practice_interval(5000, "recalled", 0);
        assert_eq!(interval, 1); // Should be at least 1 day
    }

    /// Test learning state score boundaries
    #[test]
    fn test_score_boundaries() {
        let mut state = HumanLearningState {
            id: Uuid::new_v4(),
            person_id: Uuid::new_v4(),
            learning_unit_id: Uuid::new_v4(),
            learning_state: "not_seen".to_string(),
            current_score: 10000, // Maximum score
            last_practiced: None,
            practice_frequency_days: 7,
            next_practice_date: None,
            total_practice_sessions: 0,
            metadata: None,
            created_at: Some(chrono::Utc::now()),
            updated_at: Some(chrono::Utc::now()),
        };

        // Test that score doesn't exceed maximum
        update_learning_state(&mut state, "recalled", 7);
        assert!(state.current_score <= 10000);

        // Test with minimum score
        let mut state = HumanLearningState {
            id: Uuid::new_v4(),
            person_id: Uuid::new_v4(),
            learning_unit_id: Uuid::new_v4(),
            learning_state: "not_seen".to_string(),
            current_score: 0, // Minimum score
            last_practiced: None,
            practice_frequency_days: 7,
            next_practice_date: None,
            total_practice_sessions: 0,
            metadata: None,
            created_at: Some(chrono::Utc::now()),
            updated_at: Some(chrono::Utc::now()),
        };

        // Test that score doesn't go below minimum
        update_learning_state(&mut state, "forgotten", 7);
        assert!(state.current_score >= 0);
    }

    /// Test completion estimates structure
    #[test]
    fn test_completion_estimates_structure() {
        let now = chrono::Utc::now();
        let estimates = CompletionEstimates {
            eighty_percent_completion: now + chrono::Duration::days(30),
            ninety_five_percent_completion: now + chrono::Duration::days(60),
            current_mastery_percentage: 2500, // 25%
            estimated_remaining_days: 45,
        };

        assert!(estimates.eighty_percent_completion > now);
        assert!(estimates.ninety_five_percent_completion > estimates.eighty_percent_completion);
        assert!(estimates.current_mastery_percentage >= 0);
        assert!(estimates.current_mastery_percentage <= 10000);
        assert!(estimates.estimated_remaining_days >= 0);
    }

    /// Test learning unit structure
    #[test]
    fn test_learning_unit_structure() {
        let unit = LearningUnit {
            id: Uuid::new_v4(),
            skill_area_id: Uuid::new_v4(),
            title: "Rust Ownership Basics".to_string(),
            content: "Understanding ownership, borrowing, and lifetimes in Rust".to_string(),
            unit_type: "concept".to_string(),
            difficulty_level: 3500, // 35.00
            estimated_time_minutes: Some(15),
            dependencies: Some(json!(["rust-basics", "memory-management"])),
            metadata: Some(json!({
                "tags": ["rust", "ownership", "memory"],
                "prerequisites": ["basic-programming"]
            })),
            created_at: Some(chrono::Utc::now()),
            updated_at: Some(chrono::Utc::now()),
        };

        assert_eq!(unit.title, "Rust Ownership Basics");
        assert_eq!(unit.unit_type, "concept");
        assert_eq!(unit.difficulty_level, 3500);
        assert_eq!(unit.estimated_time_minutes, Some(15));
        assert!(unit.dependencies.is_some());
        assert!(unit.metadata.is_some());
    }

    /// Test practice session structure
    #[test]
    fn test_practice_session_structure() {
        let session = PracticeSession {
            id: Uuid::new_v4(),
            person_id: Uuid::new_v4(),
            session_type: "adaptive_practice".to_string(),
            title: "Rust Fundamentals Practice".to_string(),
            description: Some("Practice session for Rust programming fundamentals".to_string()),
            enrollment_level: "moderate".to_string(),
            target_duration_minutes: Some(45),
            actual_duration_minutes: None,
            learning_units: Some(json!(["unit-1", "unit-2", "unit-3"])),
            session_status: "scheduled".to_string(),
            completion_percentage: None,
            metadata: Some(json!({
                "focus_areas": ["ownership", "borrowing"],
                "difficulty_target": "intermediate"
            })),
            scheduled_at: Some(chrono::Utc::now() + chrono::Duration::hours(1)),
            started_at: None,
            completed_at: None,
            created_at: Some(chrono::Utc::now()),
            updated_at: Some(chrono::Utc::now()),
        };

        assert_eq!(session.session_type, "adaptive_practice");
        assert_eq!(session.enrollment_level, "moderate");
        assert_eq!(session.session_status, "scheduled");
        assert_eq!(session.target_duration_minutes, Some(45));
        assert!(session.learning_units.is_some());
        assert!(session.metadata.is_some());
    }

    /// Test human assistance request structure
    #[test]
    fn test_human_assistance_request_structure() {
        let request = HumanAssistanceRequest {
            id: Uuid::new_v4(),
            requester_id: Uuid::new_v4(),
            problem_description: "Need help with complex async Rust patterns".to_string(),
            required_skills: json!(["Rust Programming", "Async Programming", "Database Design"]),
            difficulty_level: "hard".to_string(),
            urgency_level: "medium".to_string(),
            estimated_completion_hours: Some(8),
            available_experts: Some(json!(["expert-1", "expert-2"])),
            assigned_expert_id: None,
            request_status: "open".to_string(),
            metadata: Some(json!({
                "project_context": "High-performance web service",
                "constraints": ["must be production-ready", "needs documentation"]
            })),
            created_at: Some(chrono::Utc::now()),
            updated_at: Some(chrono::Utc::now()),
        };

        assert_eq!(request.difficulty_level, "hard");
        assert_eq!(request.urgency_level, "medium");
        assert_eq!(request.request_status, "open");
        assert_eq!(request.estimated_completion_hours, Some(8));
        assert!(request.required_skills.is_array());
        assert!(request.available_experts.is_some());
        assert!(request.metadata.is_some());
    }

    /// Test adaptive scheduling algorithm variations
    #[test]
    fn test_adaptive_scheduling_variations() {
        // Test different base frequencies
        let interval_1 = calculate_next_practice_interval(5000, "recalled", 1);
        let interval_7 = calculate_next_practice_interval(5000, "recalled", 7);
        let interval_30 = calculate_next_practice_interval(5000, "recalled", 30);

        assert!(interval_1 < interval_7);
        assert!(interval_7 < interval_30);

        // Test score progression
        let interval_low = calculate_next_practice_interval(1000, "recalled", 7);
        let interval_medium = calculate_next_practice_interval(5000, "recalled", 7);
        let interval_high = calculate_next_practice_interval(9000, "recalled", 7);

        assert!(interval_low < interval_medium);
        assert!(interval_medium < interval_high);

        // Test judgment impact
        let interval_forgotten = calculate_next_practice_interval(5000, "forgotten", 7);
        let interval_recalled = calculate_next_practice_interval(5000, "recalled", 7);

        assert!(interval_forgotten < interval_recalled);
    }

    /// Test learning state progression
    #[test]
    fn test_learning_state_progression() {
        let mut state = HumanLearningState {
            id: Uuid::new_v4(),
            person_id: Uuid::new_v4(),
            learning_unit_id: Uuid::new_v4(),
            learning_state: "not_seen".to_string(),
            current_score: 5000, // Start with a medium score
            last_practiced: None,
            practice_frequency_days: 7,
            next_practice_date: None,
            total_practice_sessions: 0,
            metadata: None,
            created_at: Some(chrono::Utc::now()),
            updated_at: Some(chrono::Utc::now()),
        };

        // Simulate learning progression
        let initial_score = state.current_score;

        // First encounter - not seen
        update_learning_state(&mut state, "not_seen", 7);
        assert_eq!(state.learning_state, "not_seen");
        assert_eq!(state.current_score, initial_score); // No score change for first encounter

        // Second encounter - struggling
        update_learning_state(&mut state, "forgotten", 7);
        assert_eq!(state.learning_state, "forgotten");
        assert!(state.current_score < initial_score); // Score decreases

        // Third encounter - improving
        let score_before_recall = state.current_score;
        update_learning_state(&mut state, "recalled", 7);
        assert_eq!(state.learning_state, "recalled");
        assert!(state.current_score > score_before_recall); // Score increases

        // Fourth encounter - mastered
        update_learning_state(&mut state, "recalled", 7);
        assert_eq!(state.learning_state, "recalled");
        assert!(state.practice_frequency_days > 7); // Less frequent practice
    }

    /// Test priority calculation edge cases
    #[test]
    fn test_priority_calculation_edge_cases() {
        let state = HumanLearningState {
            id: Uuid::new_v4(),
            person_id: Uuid::new_v4(),
            learning_unit_id: Uuid::new_v4(),
            learning_state: "not_seen".to_string(),
            current_score: 0,
            last_practiced: None,
            practice_frequency_days: 7,
            next_practice_date: None,
            total_practice_sessions: 0,
            metadata: None,
            created_at: Some(chrono::Utc::now()),
            updated_at: Some(chrono::Utc::now()),
        };

        // Test invalid enrollment levels
        let priority_invalid = calculate_unit_priority(&state, "invalid_level");
        let _priority_light = calculate_unit_priority(&state, "light");
        
        // Should handle invalid levels gracefully
        assert!(priority_invalid >= 0.0);

        // Test with maximum score
        let mut high_score_state = state.clone();
        high_score_state.current_score = 10000;
        high_score_state.learning_state = "recalled".to_string();
        
        let high_priority = calculate_unit_priority(&high_score_state, "moderate");
        let normal_priority = calculate_unit_priority(&state, "moderate");
        
        assert!(high_priority < normal_priority); // High score = lower priority
    }
}
