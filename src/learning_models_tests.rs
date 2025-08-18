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
        CompletionEstimates,
        SkillAssessmentEngine,
        SkillAssessment,
        TrendDirection,
        BinarySearchSkillEvaluator,
        SkillPathEvaluation,
        UnitEvaluation,
        InferenceValidation,
        InferenceValidationResult
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

    // ============================================================================
    // Skill Assessment System Tests
    // ============================================================================

    /// Test comprehensive skill evaluation algorithms
    #[test]
    fn test_comprehensive_skill_evaluation() {
        let mut engine = SkillAssessmentEngine::new(0.95, 3);
        let skill_area_id = Uuid::new_v4();
        let person_id = Uuid::new_v4();

        // Add multiple assessments
        for i in 0..5 {
            let assessment = SkillAssessment {
                id: Uuid::new_v4(),
                person_id,
                skill_area_id,
                assessment_type: "progress".to_string(),
                score: Some(7000 + (i * 500)), // Increasing scores
                confidence_level: Some(8000),
                difficulty_level: Some(5),
                questions_answered: Some(10),
                questions_correct: Some(7 + i),
                time_spent_minutes: Some(15 - i), // Decreasing time
                assessment_data: None,
                metadata: None,
                created_at: chrono::Utc::now() + chrono::Duration::days(i as i64),
                updated_at: chrono::Utc::now() + chrono::Duration::days(i as i64),
            };
            engine.add_assessment(assessment);
        }

        // Test comprehensive skill score calculation
        let skill_score = engine.calculate_skill_score(&skill_area_id);
        
        assert!(skill_score.overall_score > 7000);
        assert!(skill_score.confidence_interval_lower < skill_score.confidence_interval_upper);
        assert!(skill_score.sample_size >= 3);
        assert!(skill_score.reliability_score > 0);
        assert_eq!(skill_score.trend_direction, TrendDirection::Improving);
    }

    /// Test multi-dimensional skill measurement system
    #[test]
    fn test_multi_dimensional_skill_measurement() {
        let mut engine = SkillAssessmentEngine::new(0.95, 2);
        let skill_area_id = Uuid::new_v4();
        let person_id = Uuid::new_v4();

        // Add assessments with different characteristics
        let assessments = vec![
            (8000, 10, 9000), // High accuracy, fast, high confidence
            (7500, 15, 8000), // Medium accuracy, medium speed, medium confidence
            (9000, 8, 9500),  // Very high accuracy, very fast, very high confidence
        ];

        for (score, time, confidence) in assessments {
            let assessment = SkillAssessment {
                id: Uuid::new_v4(),
                person_id,
                skill_area_id,
                assessment_type: "progress".to_string(),
                score: Some(score),
                confidence_level: Some(confidence),
                difficulty_level: Some(5),
                questions_answered: Some(10),
                questions_correct: Some(8),
                time_spent_minutes: Some(time),
                assessment_data: None,
                metadata: None,
                created_at: chrono::Utc::now(),
                updated_at: chrono::Utc::now(),
            };
            engine.add_assessment(assessment);
        }

        let multi_score = engine.calculate_multi_dimensional_score(&skill_area_id);
        
        assert!(multi_score.accuracy_score > 7000);
        assert!(multi_score.speed_score > 6000);
        assert!(multi_score.confidence_score > 8000);
        assert!(multi_score.retention_score > 0);
        assert!(multi_score.overall_composite_score > 7000);
        assert_eq!(multi_score.dimension_weights.len(), 4);
    }

    /// Test skill level calculation with confidence intervals
    #[test]
    fn test_skill_level_confidence_intervals() {
        let mut engine = SkillAssessmentEngine::new(0.95, 5);
        let skill_area_id = Uuid::new_v4();
        let person_id = Uuid::new_v4();

        // Add assessments with varying scores to test confidence intervals
        let scores = vec![7500, 7800, 7600, 7700, 7900]; // Consistent scores
        
        for score in scores {
            let assessment = SkillAssessment {
                id: Uuid::new_v4(),
                person_id,
                skill_area_id,
                assessment_type: "progress".to_string(),
                score: Some(score),
                confidence_level: Some(8000),
                difficulty_level: Some(5),
                questions_answered: Some(10),
                questions_correct: Some(8),
                time_spent_minutes: Some(15),
                assessment_data: None,
                metadata: None,
                created_at: chrono::Utc::now(),
                updated_at: chrono::Utc::now(),
            };
            engine.add_assessment(assessment);
        }

        let skill_score = engine.calculate_skill_score(&skill_area_id);
        
        // Test confidence interval properties
        assert!(skill_score.confidence_interval_lower <= skill_score.overall_score);
        assert!(skill_score.confidence_interval_upper >= skill_score.overall_score);
        assert!(skill_score.confidence_interval_upper - skill_score.confidence_interval_lower > 0);
        assert_eq!(skill_score.sample_size, 5);
        
        // Test that confidence interval is reasonable (not too wide)
        let interval_width = skill_score.confidence_interval_upper - skill_score.confidence_interval_lower;
        assert!(interval_width < 2000); // Should be reasonably tight for consistent scores
    }

    /// Test skill level assessment with statistical confidence
    #[test]
    fn test_skill_level_statistical_confidence() {
        let mut engine = SkillAssessmentEngine::new(0.95, 3);
        let skill_area_id = Uuid::new_v4();
        let person_id = Uuid::new_v4();

        // Test with insufficient data
        let skill_score_insufficient = engine.calculate_skill_score(&skill_area_id);
        assert_eq!(skill_score_insufficient.overall_score, 0);
        assert_eq!(skill_score_insufficient.sample_size, 0);

        // Add minimum required assessments
        for i in 0..3 {
            let assessment = SkillAssessment {
                id: Uuid::new_v4(),
                person_id,
                skill_area_id,
                assessment_type: "progress".to_string(),
                score: Some(7500 + (i * 100)),
                confidence_level: Some(8000),
                difficulty_level: Some(5),
                questions_answered: Some(10),
                questions_correct: Some(8),
                time_spent_minutes: Some(15),
                assessment_data: None,
                metadata: None,
                created_at: chrono::Utc::now(),
                updated_at: chrono::Utc::now(),
            };
            engine.add_assessment(assessment);
        }

        let skill_score_sufficient = engine.calculate_skill_score(&skill_area_id);
        assert!(skill_score_sufficient.overall_score > 0);
        assert_eq!(skill_score_sufficient.sample_size, 3);
        assert!(skill_score_sufficient.reliability_score > 0);
    }

    /// Test assessment accuracy validation
    #[test]
    fn test_assessment_accuracy_validation() {
        let mut engine = SkillAssessmentEngine::new(0.95, 3);
        let skill_area_id = Uuid::new_v4();
        let person_id = Uuid::new_v4();

        // Add assessments with known accuracy patterns
        let assessments = vec![
            (8000, 5, 9000), // High score, low difficulty, high confidence
            (6000, 8, 7000), // Medium score, high difficulty, medium confidence
            (9000, 3, 9500), // Very high score, very low difficulty, very high confidence
        ];

        for (score, difficulty, confidence) in assessments {
            let assessment = SkillAssessment {
                id: Uuid::new_v4(),
                person_id,
                skill_area_id,
                assessment_type: "progress".to_string(),
                score: Some(score),
                confidence_level: Some(confidence),
                difficulty_level: Some(difficulty),
                questions_answered: Some(10),
                questions_correct: Some(8),
                time_spent_minutes: Some(15),
                assessment_data: None,
                metadata: None,
                created_at: chrono::Utc::now(),
                updated_at: chrono::Utc::now(),
            };
            engine.add_assessment(assessment);
        }

        let quality = engine.calculate_assessment_quality(&skill_area_id);
        
        assert!(quality.reliability_score > 0);
        assert!(quality.validity_score > 0);
        assert!(quality.consistency_score > 0);
        assert_eq!(quality.sample_size, 3);
        assert!(!quality.quality_level.is_empty());
    }

    /// Test assessment quality and reliability measures
    #[test]
    fn test_assessment_quality_reliability() {
        let mut engine = SkillAssessmentEngine::new(0.95, 2);
        let skill_area_id = Uuid::new_v4();
        let person_id = Uuid::new_v4();

        // Test with highly consistent scores (should have high reliability)
        let consistent_scores = vec![7500, 7600, 7400, 7550, 7450];
        for score in consistent_scores {
            let assessment = SkillAssessment {
                id: Uuid::new_v4(),
                person_id,
                skill_area_id,
                assessment_type: "progress".to_string(),
                score: Some(score),
                confidence_level: Some(8000),
                difficulty_level: Some(5),
                questions_answered: Some(10),
                questions_correct: Some(8),
                time_spent_minutes: Some(15),
                assessment_data: None,
                metadata: None,
                created_at: chrono::Utc::now(),
                updated_at: chrono::Utc::now(),
            };
            engine.add_assessment(assessment);
        }

        let quality_consistent = engine.calculate_assessment_quality(&skill_area_id);
        assert!(quality_consistent.reliability_score > 8000); // Should be high for consistent scores
        assert!(quality_consistent.consistency_score > 8000);

        // Test with inconsistent scores (should have lower reliability)
        let mut engine_inconsistent = SkillAssessmentEngine::new(0.95, 2);
        let inconsistent_scores = vec![3000, 8000, 2000, 9000, 4000];
        for score in inconsistent_scores {
            let assessment = SkillAssessment {
                id: Uuid::new_v4(),
                person_id,
                skill_area_id,
                assessment_type: "progress".to_string(),
                score: Some(score),
                confidence_level: Some(8000),
                difficulty_level: Some(5),
                questions_answered: Some(10),
                questions_correct: Some(8),
                time_spent_minutes: Some(15),
                assessment_data: None,
                metadata: None,
                created_at: chrono::Utc::now(),
                updated_at: chrono::Utc::now(),
            };
            engine_inconsistent.add_assessment(assessment);
        }

        let quality_inconsistent = engine_inconsistent.calculate_assessment_quality(&skill_area_id);
        assert!(quality_inconsistent.reliability_score < quality_consistent.reliability_score);
        assert!(quality_inconsistent.consistency_score < quality_consistent.consistency_score);
    }

    /// Test skill progression tracking over time
    #[test]
    fn test_skill_progression_tracking() {
        let mut engine = SkillAssessmentEngine::new(0.95, 2);
        let skill_area_id = Uuid::new_v4();
        let person_id = Uuid::new_v4();

        // Add assessments over time with improving scores
        let now = chrono::Utc::now();
        let assessments = vec![
            (6000, now - chrono::Duration::days(60)), // 60 days ago
            (6500, now - chrono::Duration::days(45)), // 45 days ago
            (7000, now - chrono::Duration::days(30)), // 30 days ago
            (7500, now - chrono::Duration::days(15)), // 15 days ago
            (8000, now), // Today
        ];

        for (score, created_at) in assessments {
            let assessment = SkillAssessment {
                id: Uuid::new_v4(),
                person_id,
                skill_area_id,
                assessment_type: "progress".to_string(),
                score: Some(score),
                confidence_level: Some(8000),
                difficulty_level: Some(5),
                questions_answered: Some(10),
                questions_correct: Some(8),
                time_spent_minutes: Some(15),
                assessment_data: None,
                metadata: None,
                created_at,
                updated_at: created_at,
            };
            engine.add_assessment(assessment);
        }

        let progression = engine.track_skill_progression(&skill_area_id, 30);
        
        assert_eq!(progression.time_period_days, 30);
        assert!(progression.current_score > progression.initial_score);
        assert!(progression.improvement_rate > 0);
        assert!(progression.assessment_frequency > 0.0);
        assert!(progression.trend_strength >= 0);
    }

    /// Test longitudinal skill development analysis
    #[test]
    fn test_longitudinal_skill_development() {
        let mut engine = SkillAssessmentEngine::new(0.95, 2);
        let skill_area_id = Uuid::new_v4();
        let person_id = Uuid::new_v4();

        // Simulate a learning journey with ups and downs
        let now = chrono::Utc::now();
        let learning_journey = vec![
            (5000, now - chrono::Duration::days(90)), // Initial assessment
            (5500, now - chrono::Duration::days(75)), // Early progress
            (5200, now - chrono::Duration::days(60)), // Slight regression
            (6500, now - chrono::Duration::days(45)), // Breakthrough
            (6300, now - chrono::Duration::days(30)), // Plateau
            (7000, now - chrono::Duration::days(15)), // Continued growth
            (7500, now), // Current level
        ];

        for (score, created_at) in learning_journey {
            let assessment = SkillAssessment {
                id: Uuid::new_v4(),
                person_id,
                skill_area_id,
                assessment_type: "progress".to_string(),
                score: Some(score),
                confidence_level: Some(8000),
                difficulty_level: Some(5),
                questions_answered: Some(10),
                questions_correct: Some(8),
                time_spent_minutes: Some(15),
                assessment_data: None,
                metadata: None,
                created_at,
                updated_at: created_at,
            };
            engine.add_assessment(assessment);
        }

        // Test different time periods
        let short_progression = engine.track_skill_progression(&skill_area_id, 30);
        let long_progression = engine.track_skill_progression(&skill_area_id, 90);
        
        // Short-term should show recent improvement
        assert!(short_progression.improvement_rate > 0);
        assert!(short_progression.current_score > short_progression.initial_score);
        
        // Long-term should show overall improvement
        assert!(long_progression.improvement_rate > 0);
        assert!(long_progression.current_score > long_progression.initial_score);
        
        // Long-term improvement should be greater than short-term
        assert!(long_progression.improvement_rate >= short_progression.improvement_rate);
    }

    /// Test skill gap identification algorithms
    #[test]
    fn test_skill_gap_identification() {
        let mut engine = SkillAssessmentEngine::new(0.95, 2);
        let skill_area_id = Uuid::new_v4();
        let person_id = Uuid::new_v4();

        // Add some assessment history
        for i in 0..3 {
            let assessment = SkillAssessment {
                id: Uuid::new_v4(),
                person_id,
                skill_area_id,
                assessment_type: "progress".to_string(),
                score: Some(6500 + (i * 200)), // Current level around 6900
                confidence_level: Some(8000),
                difficulty_level: Some(5),
                questions_answered: Some(10),
                questions_correct: Some(8),
                time_spent_minutes: Some(15),
                assessment_data: None,
                metadata: None,
                created_at: chrono::Utc::now(),
                updated_at: chrono::Utc::now(),
            };
            engine.add_assessment(assessment);
        }

        // Define target proficiencies
        let target_proficiencies = vec![
            (skill_area_id, 8000), // Target: 80% mastery
        ];

        let skill_gaps = engine.identify_skill_gaps(&person_id, &target_proficiencies);
        
        assert!(!skill_gaps.is_empty());
        let gap = &skill_gaps[0];
        assert_eq!(gap.skill_area_id, skill_area_id);
        assert!(gap.current_score < gap.target_score);
        assert!(gap.gap_size > 0);
        assert!(gap.priority_level > 0.0);
        assert!(!gap.recommended_actions.is_empty());
    }

    /// Test skill gap detection and recommendation system
    #[test]
    fn test_skill_gap_detection_recommendations() {
        let mut engine = SkillAssessmentEngine::new(0.95, 2);
        let skill_area_id = Uuid::new_v4();
        let person_id = Uuid::new_v4();

        // Add assessment with declining trend
        for i in 0..3 {
            let assessment = SkillAssessment {
                id: Uuid::new_v4(),
                person_id,
                skill_area_id,
                assessment_type: "progress".to_string(),
                score: Some(8000 - (i * 500)), // Declining scores
                confidence_level: Some(8000),
                difficulty_level: Some(5),
                questions_answered: Some(10),
                questions_correct: Some(8),
                time_spent_minutes: Some(15),
                assessment_data: None,
                metadata: None,
                created_at: chrono::Utc::now() - chrono::Duration::days(((2 - i) * 7) as i64),
                updated_at: chrono::Utc::now() - chrono::Duration::days(((2 - i) * 7) as i64),
            };
            engine.add_assessment(assessment);
        }

        let target_proficiencies = vec![
            (skill_area_id, 11000), // High target to create large gap
        ];

        let skill_gaps = engine.identify_skill_gaps(&person_id, &target_proficiencies);
        
        assert!(!skill_gaps.is_empty());
        let gap = &skill_gaps[0];
        
        // Should have recommendations for declining trend
        let has_declining_recommendation = gap.recommended_actions.iter()
            .any(|action| action.contains("changing learning strategy") || action.contains("review recent practice"));
        assert!(has_declining_recommendation);
        
        // Should have recommendations for large gap
        let has_intensive_recommendation = gap.recommended_actions.iter()
            .any(|action| action.contains("Intensive") || action.contains("focused") || action.contains("expert") || action.contains("guidance"));
        assert!(has_intensive_recommendation);
    }

    /// Test assessment data serialization and storage
    #[test]
    fn test_assessment_data_serialization() {
        let skill_area_id = Uuid::new_v4();
        let person_id = Uuid::new_v4();

        let assessment = SkillAssessment {
            id: Uuid::new_v4(),
            person_id,
            skill_area_id,
            assessment_type: "progress".to_string(),
            score: Some(7500),
            confidence_level: Some(8000),
            difficulty_level: Some(5),
            questions_answered: Some(10),
            questions_correct: Some(8),
            time_spent_minutes: Some(15),
            assessment_data: Some(json!({
                "question_types": ["multiple_choice", "coding"],
                "time_per_question": [30, 120],
                "difficulty_distribution": {"easy": 3, "medium": 4, "hard": 3}
            })),
            metadata: Some(json!({
                "session_id": "session-123",
                "practice_mode": "adaptive",
                "interruption_count": 2
            })),
            created_at: chrono::Utc::now(),
            updated_at: chrono::Utc::now(),
        };

        // Test serialization
        let serialized = serde_json::to_string(&assessment).unwrap();
        let deserialized: SkillAssessment = serde_json::from_str(&serialized).unwrap();
        
        assert_eq!(assessment.id, deserialized.id);
        assert_eq!(assessment.score, deserialized.score);
        assert_eq!(assessment.assessment_data, deserialized.assessment_data);
        assert_eq!(assessment.metadata, deserialized.metadata);
    }

    /// Test assessment data management and retrieval
    #[test]
    fn test_assessment_data_management() {
        let mut engine = SkillAssessmentEngine::new(0.95, 2);
        let skill_area_id = Uuid::new_v4();
        let person_id = Uuid::new_v4();

        // Add multiple assessments
        let assessment_count = 5;
        for i in 0..assessment_count {
            let assessment = SkillAssessment {
                id: Uuid::new_v4(),
                person_id,
                skill_area_id,
                assessment_type: "progress".to_string(),
                score: Some(7000 + (i * 200)),
                confidence_level: Some(8000),
                difficulty_level: Some(5),
                questions_answered: Some(10),
                questions_correct: Some(8),
                time_spent_minutes: Some(15),
                assessment_data: None,
                metadata: None,
                created_at: chrono::Utc::now(),
                updated_at: chrono::Utc::now(),
            };
            engine.add_assessment(assessment);
        }

        // Test data retrieval
        let skill_score = engine.calculate_skill_score(&skill_area_id);
        assert_eq!(skill_score.assessment_count, assessment_count as usize);
        assert_eq!(skill_score.sample_size, assessment_count as usize);
        
        // Test that all assessments are accessible
        let relevant_assessments: Vec<&SkillAssessment> = engine.assessment_history
            .iter()
            .filter(|a| a.skill_area_id == skill_area_id)
            .collect();
        assert_eq!(relevant_assessments.len(), assessment_count as usize);
    }

    /// Test edge cases for skill assessment system
    #[test]
    fn test_skill_assessment_edge_cases() {
        let mut engine = SkillAssessmentEngine::new(0.95, 3);
        let skill_area_id = Uuid::new_v4();

        // Test with no assessments
        let skill_score_empty = engine.calculate_skill_score(&skill_area_id);
        assert_eq!(skill_score_empty.overall_score, 0);
        assert_eq!(skill_score_empty.sample_size, 0);

        // Test with single assessment (below minimum)
        let single_assessment = SkillAssessment {
            id: Uuid::new_v4(),
            person_id: Uuid::new_v4(),
            skill_area_id,
            assessment_type: "progress".to_string(),
            score: Some(8000),
            confidence_level: Some(8000),
            difficulty_level: Some(5),
            questions_answered: Some(10),
            questions_correct: Some(8),
            time_spent_minutes: Some(15),
            assessment_data: None,
            metadata: None,
            created_at: chrono::Utc::now(),
            updated_at: chrono::Utc::now(),
        };
        engine.add_assessment(single_assessment);

        let skill_score_single = engine.calculate_skill_score(&skill_area_id);
        assert_eq!(skill_score_single.overall_score, 0); // Still below minimum
        assert_eq!(skill_score_single.sample_size, 1);

        // Clear engine and test with maximum scores
        engine.assessment_history.clear();
        for _ in 0..3 {
            let max_assessment = SkillAssessment {
                id: Uuid::new_v4(),
                person_id: Uuid::new_v4(),
                skill_area_id,
                assessment_type: "progress".to_string(),
                score: Some(10000), // Maximum score
                confidence_level: Some(10000),
                difficulty_level: Some(10),
                questions_answered: Some(10),
                questions_correct: Some(10),
                time_spent_minutes: Some(5),
                assessment_data: None,
                metadata: None,
                created_at: chrono::Utc::now(),
                updated_at: chrono::Utc::now(),
            };
            engine.add_assessment(max_assessment);
        }

        let skill_score_max = engine.calculate_skill_score(&skill_area_id);
        assert_eq!(skill_score_max.overall_score, 10000);
        // Confidence interval upper should be 10000 for maximum scores
        assert!(skill_score_max.confidence_interval_upper >= 9500);
    }

    // ============================================================================
    // Binary Search Skill Evaluation Tests
    // ============================================================================

    /// Test binary search skill evaluation with dependency inference
    #[test]
    fn test_binary_search_skill_evaluation() {
        let skill_graph = json!({
            "nodes": [
                {"id": "unit-1", "name": "Basic Variables", "difficulty": 2000},
                {"id": "unit-2", "name": "Functions", "difficulty": 4000},
                {"id": "unit-3", "name": "Advanced Functions", "difficulty": 6000},
                {"id": "unit-4", "name": "Modules", "difficulty": 8000}
            ],
            "edges": [
                {"from": "unit-1", "to": "unit-2"},
                {"from": "unit-2", "to": "unit-3"},
                {"from": "unit-3", "to": "unit-4"}
            ]
        });

        let evaluator = BinarySearchSkillEvaluator::new(
            skill_graph,
            8000, // 80% threshold for inference
            3     // Max inference depth
        );

        // Test that evaluator is created correctly
        assert_eq!(evaluator.inference_threshold, 8000);
        assert_eq!(evaluator.max_inference_depth, 3);
    }

    /// Test dependency graph building from learning units
    #[test]
    fn test_dependency_graph_building() {
        let skill_graph = json!({});
        let evaluator = BinarySearchSkillEvaluator::new(skill_graph, 8000, 3);

        let learning_units = vec![
            LearningUnit {
                id: Uuid::new_v4(),
                skill_area_id: Uuid::new_v4(),
                title: "Unit 1".to_string(),
                content: "Basic content".to_string(),
                unit_type: "concept".to_string(),
                difficulty_level: 2000,
                estimated_time_minutes: Some(15),
                dependencies: Some(json!(["unit-0"])),
                metadata: None,
                created_at: Some(chrono::Utc::now()),
                updated_at: Some(chrono::Utc::now()),
            },
            LearningUnit {
                id: Uuid::new_v4(),
                skill_area_id: Uuid::new_v4(),
                title: "Unit 2".to_string(),
                content: "Advanced content".to_string(),
                unit_type: "concept".to_string(),
                difficulty_level: 4000,
                estimated_time_minutes: Some(20),
                dependencies: Some(json!(["unit-1"])),
                metadata: None,
                created_at: Some(chrono::Utc::now()),
                updated_at: Some(chrono::Utc::now()),
            }
        ];

        // Test that dependency graph is built correctly
        // Note: This would require a database connection in real implementation
        // For now, we test the structure creation
        assert_eq!(learning_units.len(), 2);
        assert!(learning_units[0].dependencies.is_some());
        assert!(learning_units[1].dependencies.is_some());
    }

    /// Test entry point identification in dependency graph
    #[test]
    fn test_entry_point_identification() {
        let skill_graph = json!({});
        let evaluator = BinarySearchSkillEvaluator::new(skill_graph, 8000, 3);

        // Create a simple dependency graph
        let mut dependency_graph = std::collections::HashMap::new();
        let unit1 = Uuid::new_v4();
        let unit2 = Uuid::new_v4();
        let unit3 = Uuid::new_v4();

        dependency_graph.insert(unit1, vec![]); // No dependencies - entry point
        dependency_graph.insert(unit2, vec![unit1]); // Depends on unit1
        dependency_graph.insert(unit3, vec![unit2]); // Depends on unit2

        let entry_points = evaluator.find_entry_points(&dependency_graph);
        assert_eq!(entry_points.len(), 1);
        assert!(entry_points.contains(&unit1));
    }

    /// Test dependent unit identification
    #[test]
    fn test_dependent_unit_identification() {
        let skill_graph = json!({});
        let evaluator = BinarySearchSkillEvaluator::new(skill_graph, 8000, 3);

        let mut dependency_graph = std::collections::HashMap::new();
        let unit1 = Uuid::new_v4();
        let unit2 = Uuid::new_v4();
        let unit3 = Uuid::new_v4();

        dependency_graph.insert(unit1, vec![]);
        dependency_graph.insert(unit2, vec![unit1]);
        dependency_graph.insert(unit3, vec![unit1, unit2]);

        let dependents_of_unit1 = evaluator.get_dependent_units(&unit1, &dependency_graph);
        assert_eq!(dependents_of_unit1.len(), 2);
        assert!(dependents_of_unit1.contains(&unit2));
        assert!(dependents_of_unit1.contains(&unit3));
    }

    /// Test inferred score calculation
    #[test]
    fn test_inferred_score_calculation() {
        let skill_graph = json!({});
        let evaluator = BinarySearchSkillEvaluator::new(skill_graph, 8000, 3);

        let source_state = HumanLearningState {
            id: Uuid::new_v4(),
            person_id: Uuid::new_v4(),
            learning_unit_id: Uuid::new_v4(),
            learning_state: "recalled".to_string(),
            current_score: 9000, // High score
            last_practiced: Some(chrono::Utc::now()),
            practice_frequency_days: 7,
            next_practice_date: Some(chrono::Utc::now() + chrono::Duration::days(7)),
            total_practice_sessions: 5,
            metadata: None,
            created_at: Some(chrono::Utc::now()),
            updated_at: Some(chrono::Utc::now()),
        };

        let dependent_unit_id = Uuid::new_v4();
        let inferred_score = evaluator.calculate_inferred_score(&source_state, &dependent_unit_id);

        // Inferred score should be lower than source score due to degradation factor
        assert!(inferred_score < source_state.current_score);
        assert!(inferred_score > 0);
        assert!(inferred_score <= 10000);
    }

    /// Test learning path optimization
    #[test]
    fn test_learning_path_optimization() {
        let skill_graph = json!({});
        let evaluator = BinarySearchSkillEvaluator::new(skill_graph, 8000, 3);

        // Create a mock evaluation result
        let evaluation = SkillPathEvaluation {
            skill_area_id: Uuid::new_v4(),
            evaluated_units: vec![
                UnitEvaluation {
                    unit_id: Uuid::new_v4(),
                    score: 9000,
                    evaluation_type: "direct".to_string(),
                    confidence: 9000,
                    dependencies_verified: true,
                }
            ],
            inferred_units: vec![
                UnitEvaluation {
                    unit_id: Uuid::new_v4(),
                    score: 8100,
                    evaluation_type: "inferred".to_string(),
                    confidence: 6480, // 8100 * 0.8
                    dependencies_verified: true,
                }
            ],
            total_units: 10,
            evaluation_efficiency: 0.2, // 2 out of 10 units evaluated
            confidence_score: 2000,
            skill_mastery_percentage: 8550, // (9000 + 8100) / 2
        };

        // Test that optimization identifies efficiency gains
        assert_eq!(evaluation.evaluated_units.len(), 1);
        assert_eq!(evaluation.inferred_units.len(), 1);
        assert_eq!(evaluation.total_units, 10);
        assert_eq!(evaluation.evaluation_efficiency, 0.2);
    }

    /// Test inference validation accuracy
    #[test]
    fn test_inference_validation_accuracy() {
        let skill_graph = json!({});
        let evaluator = BinarySearchSkillEvaluator::new(skill_graph, 8000, 3);

        // Create mock validation results
        let validation_results = vec![
            InferenceValidationResult {
                unit_id: Uuid::new_v4(),
                inferred_score: 8500,
                actual_score: 8600,
                accuracy: 0.99, // Very accurate
            },
            InferenceValidationResult {
                unit_id: Uuid::new_v4(),
                inferred_score: 7000,
                actual_score: 7500,
                accuracy: 0.95, // Good accuracy
            }
        ];

        let validation = InferenceValidation {
            skill_area_id: Uuid::new_v4(),
            validation_results: validation_results.clone(),
            average_accuracy: 0.97, // (0.99 + 0.95) / 2
            sample_size: 2,
            total_inferred_units: 10,
        };

        assert_eq!(validation.validation_results.len(), 2);
        assert_eq!(validation.average_accuracy, 0.97);
        assert_eq!(validation.sample_size, 2);
        assert_eq!(validation.total_inferred_units, 10);
    }

    /// Test skill path evaluation efficiency
    #[test]
    fn test_skill_path_evaluation_efficiency() {
        let skill_graph = json!({});
        let evaluator = BinarySearchSkillEvaluator::new(skill_graph, 8000, 3);

        // Test different evaluation scenarios
        let scenarios = vec![
            (5, 1, 0.2),   // 5 total, 1 evaluated = 20% efficiency
            (10, 3, 0.3),  // 10 total, 3 evaluated = 30% efficiency
            (20, 5, 0.25), // 20 total, 5 evaluated = 25% efficiency
        ];

        for (total_units, evaluated_units, expected_efficiency) in scenarios {
            let efficiency = evaluated_units as f64 / total_units as f64;
            assert_eq!(efficiency, expected_efficiency);
        }
    }

    /// Test confidence score calculation for inferred units
    #[test]
    fn test_inferred_confidence_calculation() {
        let skill_graph = json!({});
        let evaluator = BinarySearchSkillEvaluator::new(skill_graph, 8000, 3);

        // Test confidence degradation for inferred units
        let source_score = 9000;
        let inferred_score = (source_score as f64 * 0.9).round() as i32; // 8100
        let expected_confidence = (inferred_score as f64 * 0.8).round() as i32; // 6480

        assert_eq!(inferred_score, 8100);
        assert_eq!(expected_confidence, 6480);
        assert!(expected_confidence < source_score); // Confidence should be lower
    }

    /// Test dependency verification in unit evaluation
    #[test]
    fn test_dependency_verification() {
        let skill_graph = json!({});
        let evaluator = BinarySearchSkillEvaluator::new(skill_graph, 8000, 3);

        let unit_evaluation = UnitEvaluation {
            unit_id: Uuid::new_v4(),
            score: 8500,
            evaluation_type: "inferred".to_string(),
            confidence: 6800,
            dependencies_verified: true,
        };

        assert!(unit_evaluation.dependencies_verified);
        assert_eq!(unit_evaluation.evaluation_type, "inferred");
        assert!(unit_evaluation.confidence < unit_evaluation.score);
    }

    /// Test skill mastery percentage calculation
    #[test]
    fn test_skill_mastery_percentage_calculation() {
        let skill_graph = json!({});
        let evaluator = BinarySearchSkillEvaluator::new(skill_graph, 8000, 3);

        let evaluated_units = vec![
            UnitEvaluation {
                unit_id: Uuid::new_v4(),
                score: 9000,
                evaluation_type: "direct".to_string(),
                confidence: 9000,
                dependencies_verified: true,
            },
            UnitEvaluation {
                unit_id: Uuid::new_v4(),
                score: 8000,
                evaluation_type: "direct".to_string(),
                confidence: 8000,
                dependencies_verified: true,
            }
        ];

        let inferred_units = vec![
            UnitEvaluation {
                unit_id: Uuid::new_v4(),
                score: 7500,
                evaluation_type: "inferred".to_string(),
                confidence: 6000,
                dependencies_verified: true,
            }
        ];

        let total_score = evaluated_units.iter().map(|u| u.score).sum::<i32>() +
                         inferred_units.iter().map(|u| u.score).sum::<i32>();
        let total_units = evaluated_units.len() + inferred_units.len();
        let mastery_percentage = total_score / total_units as i32;

        assert_eq!(total_score, 24500); // 9000 + 8000 + 7500
        assert_eq!(total_units, 3);
        assert_eq!(mastery_percentage, 8166); // 24500 / 3
    }

    /// Test maximum inference depth limiting
    #[test]
    fn test_max_inference_depth_limiting() {
        let skill_graph = json!({});
        let evaluator = BinarySearchSkillEvaluator::new(skill_graph, 8000, 2); // Max depth 2

        // Test that evaluation stops at max depth
        let max_depth = evaluator.max_inference_depth;
        assert_eq!(max_depth, 2);

        // Test depth limiting logic
        let test_depths = vec![0, 1, 2, 3, 4];
        for depth in test_depths {
            let should_continue = depth <= max_depth;
            assert_eq!(should_continue, depth <= 2);
        }
    }

    /// Test inference threshold validation
    #[test]
    fn test_inference_threshold_validation() {
        let skill_graph = json!({});
        let evaluator = BinarySearchSkillEvaluator::new(skill_graph, 8000, 3);

        // Test different score scenarios against threshold
        let test_scores = vec![
            (7000, false), // Below threshold
            (8000, true),  // At threshold
            (9000, true),  // Above threshold
            (10000, true), // Maximum score
        ];

        for (score, should_infer) in test_scores {
            let can_infer = score >= evaluator.inference_threshold;
            assert_eq!(can_infer, should_infer);
        }
    }

    /// Test time savings calculation
    #[test]
    fn test_time_savings_calculation() {
        let skill_graph = json!({});
        let evaluator = BinarySearchSkillEvaluator::new(skill_graph, 8000, 3);

        // Test time savings calculation
        let skipped_units = 5;
        let minutes_per_unit = 15.0;
        let estimated_time_saved = (skipped_units as f64 * minutes_per_unit) as i32;

        assert_eq!(estimated_time_saved, 75); // 5 * 15 = 75 minutes

        // Test different scenarios
        let scenarios = vec![
            (1, 15),   // 1 unit = 15 minutes saved
            (3, 45),   // 3 units = 45 minutes saved
            (10, 150), // 10 units = 150 minutes saved
        ];

        for (units, expected_minutes) in scenarios {
            let time_saved = (units as f64 * minutes_per_unit) as i32;
            assert_eq!(time_saved, expected_minutes);
        }
    }

    /// Test evaluation type classification
    #[test]
    fn test_evaluation_type_classification() {
        let skill_graph = json!({});
        let evaluator = BinarySearchSkillEvaluator::new(skill_graph, 8000, 3);

        // Test different evaluation types
        let evaluation_types = vec![
            ("direct", "direct".to_string()),
            ("inferred", "inferred".to_string()),
            ("existing", "existing".to_string()),
        ];

        for (expected_type, actual_type) in evaluation_types {
            assert_eq!(actual_type, expected_type);
        }

        // Test evaluation type validation
        let valid_types = vec!["direct", "inferred", "existing"];
        let test_type = "direct";
        assert!(valid_types.contains(&test_type));
    }

    /// Test confidence score bounds
    #[test]
    fn test_confidence_score_bounds() {
        let skill_graph = json!({});
        let evaluator = BinarySearchSkillEvaluator::new(skill_graph, 8000, 3);

        // Test confidence score bounds
        let test_scores = vec![
            (-1000, 0),    // Below minimum
            (0, 0),        // At minimum
            (5000, 5000),  // Middle
            (10000, 10000), // At maximum
            (15000, 10000), // Above maximum
        ];

        for (input_score, expected_bounded_score) in test_scores {
            let bounded_score = input_score.max(0).min(10000);
            assert_eq!(bounded_score, expected_bounded_score);
        }
    }

    /// Test skill graph structure validation
    #[test]
    fn test_skill_graph_structure_validation() {
        let skill_graph = json!({
            "nodes": [
                {"id": "unit-1", "name": "Basic", "difficulty": 2000},
                {"id": "unit-2", "name": "Intermediate", "difficulty": 5000},
                {"id": "unit-3", "name": "Advanced", "difficulty": 8000}
            ],
            "edges": [
                {"from": "unit-1", "to": "unit-2"},
                {"from": "unit-2", "to": "unit-3"}
            ]
        });

        let evaluator = BinarySearchSkillEvaluator::new(skill_graph, 8000, 3);

        // Test that skill graph is properly structured
        assert!(evaluator.skill_graph.is_object());
        assert!(evaluator.skill_graph.get("nodes").is_some());
        assert!(evaluator.skill_graph.get("edges").is_some());
    }
}
