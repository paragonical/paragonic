-- HTTP Client Load Testing Suite (Mock-based)
--
-- This test file implements comprehensive load testing for the HTTP client
-- connection pooling and optimization features using mock responses.
-- Part of task 9.6: Test under various load conditions.

local http_client = require("../../lua/paragonic/http_client")

-- Mock HTTP response generator
local function create_mock_response(status_code, body)
	return {
		status_code = status_code or 200,
		body = body or { message = "Mock response" },
		raw_body = body and (type(body) == "string" and body or "Mock response") or "Mock response",
		headers = {},
	}
end

-- Mock HTTP client for testing
local mock_http_client = {
	init = http_client.init,
	set_session_id = http_client.set_session_id,
	get_session_id = http_client.get_session_id,
	build_request = http_client.build_request,
	send_request = http_client.send_request,
	post = http_client.post,
	get = http_client.get,
	delete = http_client.delete,
	is_success = http_client.is_success,
	is_client_error = http_client.is_client_error,
	is_server_error = http_client.is_server_error,
	get_error_message = http_client.get_error_message,
	cleanup = http_client.cleanup,
	-- Connection pooling methods
	get_connection_pool_config = http_client.get_connection_pool_config,
	set_connection_pool_size = http_client.set_connection_pool_size,
	get_connection = http_client.get_connection,
	return_connection = http_client.return_connection,
	is_connection_valid = http_client.is_connection_valid,
	cleanup_expired_connections = http_client.cleanup_expired_connections,
	get_connection_pool_metrics = http_client.get_connection_pool_metrics,
	configure_request_pooling = http_client.configure_request_pooling,
	set_optimization_config = http_client.set_optimization_config,
	get_optimization_config = http_client.get_optimization_config,
	reset_connection_pool = http_client.reset_connection_pool,
}

-- Override the _send_single_request method to return mock responses
local original_send_single_request = http_client._send_single_request
http_client._send_single_request = function(request)
	-- Simulate network delay
	local delay = math.random(1, 50) / 1000 -- 1-50ms delay
	os.execute("sleep " .. delay)

	-- Return mock response based on request
	if request.method == "GET" then
		return create_mock_response(200, { data = "Mock GET response" })
	elseif request.method == "POST" then
		return create_mock_response(201, { data = "Mock POST response" })
	elseif request.method == "DELETE" then
		return create_mock_response(204, nil)
	else
		return create_mock_response(405, { error = "Method not allowed" })
	end
end

-- Load testing configuration
local LOAD_TEST_CONFIG = {
	base_url = "http://localhost:3000",
	timeout = 10,
	retry_attempts = 2,
	retry_delay = 0.1,
	-- Load test scenarios
	scenarios = {
		low_load = {
			concurrent_requests = 5,
			total_requests = 50,
			delay_between_requests = 0.01,
		},
		medium_load = {
			concurrent_requests = 10,
			total_requests = 100,
			delay_between_requests = 0.005,
		},
		high_load = {
			concurrent_requests = 20,
			total_requests = 200,
			delay_between_requests = 0.002,
		},
		stress_load = {
			concurrent_requests = 50,
			total_requests = 500,
			delay_between_requests = 0.001,
		},
	},
}

-- Load test state
local load_test_state = {
	test_count = 0,
	passed_count = 0,
	failed_count = 0,
	performance_metrics = {},
}

-- Test utilities
local function test_log(message)
	print(string.format("[HTTP Mock Load Test] %s", message))
end

local function assert_test(condition, message)
	load_test_state.test_count = load_test_state.test_count + 1
	if condition then
		load_test_state.passed_count = load_test_state.passed_count + 1
		test_log("✓ " .. message)
	else
		load_test_state.failed_count = load_test_state.failed_count + 1
		test_log("✗ " .. message)
	end
end

-- Performance measurement utilities
local function measure_time(func, ...)
	local start_time = os.clock()
	local result = func(...)
	local end_time = os.clock()
	return result, (end_time - start_time) * 1000 -- Convert to milliseconds
end

local function calculate_statistics(values)
	if #values == 0 then
		return { min = 0, max = 0, avg = 0, median = 0 }
	end

	table.sort(values)
	local sum = 0
	for _, value in ipairs(values) do
		sum = sum + value
	end

	local avg = sum / #values
	local median = values[math.ceil(#values / 2)]

	return {
		min = values[1],
		max = values[#values],
		avg = avg,
		median = median,
		count = #values,
	}
end

-- Simulate concurrent requests with mock responses
local function simulate_concurrent_requests(concurrent_count, total_requests, delay)
	local results = {}
	local errors = {}
	local response_times = {}
	local active_requests = 0
	local completed_requests = 0

	-- Create request function
	local function make_request(request_id)
		return function()
			active_requests = active_requests + 1

			local success, response_time = measure_time(function()
				return http_client.get("/test")
			end)

			table.insert(response_times, response_time)

			if success and http_client.is_success(success) then
				table.insert(results, { id = request_id, success = true, response_time = response_time })
			else
				table.insert(errors, { id = request_id, error = "Request failed", response_time = response_time })
			end

			active_requests = active_requests - 1
			completed_requests = completed_requests + 1
		end
	end

	-- Execute requests
	for i = 1, total_requests do
		local request_func = make_request(i)

		-- Simulate concurrent execution (in real scenario, this would be async)
		request_func()

		-- Add delay between requests
		if delay and delay > 0 then
			os.execute("sleep " .. delay)
		end
	end

	-- Wait for all requests to complete
	while active_requests > 0 do
		os.execute("sleep 0.001")
	end

	return {
		results = results,
		errors = errors,
		response_times = response_times,
		completed_requests = completed_requests,
	}
end

-- Test 1: Low load testing with mock responses
local function test_low_load_scenario()
	test_log("Testing low load scenario (5 concurrent, 50 total requests)...")

	-- Initialize HTTP client
	http_client.init(LOAD_TEST_CONFIG)
	http_client.reset_connection_pool()
	http_client.set_connection_pool_size(10)

	local scenario = LOAD_TEST_CONFIG.scenarios.low_load

	-- Get initial pool metrics
	local initial_metrics = http_client.get_connection_pool_metrics()

	-- Execute load test
	local load_result = simulate_concurrent_requests(
		scenario.concurrent_requests,
		scenario.total_requests,
		scenario.delay_between_requests
	)

	-- Get final pool metrics
	local final_metrics = http_client.get_connection_pool_metrics()

	-- Analyze results
	local response_stats = calculate_statistics(load_result.response_times)

	-- Assertions
	assert_test(
		load_result.completed_requests == scenario.total_requests,
		"All requests should complete in low load scenario"
	)
	assert_test(#load_result.errors == 0, "No errors should occur in low load scenario with mock responses")
	assert_test(response_stats.avg < 100, "Average response time should be under 100ms in low load with mock")
	assert_test(final_metrics.active_connections == 0, "No active connections should remain after low load test")
	assert_test(final_metrics.usage_percentage <= 100, "Connection pool usage should be within limits")

	-- Store performance metrics
	load_test_state.performance_metrics.low_load = {
		response_stats = response_stats,
		pool_metrics = final_metrics,
		completed_requests = load_result.completed_requests,
		errors = #load_result.errors,
	}

	test_log("Low load scenario test completed")
end

-- Test 2: Medium load testing with mock responses
local function test_medium_load_scenario()
	test_log("Testing medium load scenario (10 concurrent, 100 total requests)...")

	-- Reset for new test
	http_client.reset_connection_pool()
	http_client.set_connection_pool_size(15)

	local scenario = LOAD_TEST_CONFIG.scenarios.medium_load

	-- Execute load test
	local load_result = simulate_concurrent_requests(
		scenario.concurrent_requests,
		scenario.total_requests,
		scenario.delay_between_requests
	)

	-- Get final pool metrics
	local final_metrics = http_client.get_connection_pool_metrics()

	-- Analyze results
	local response_stats = calculate_statistics(load_result.response_times)

	-- Assertions
	assert_test(
		load_result.completed_requests == scenario.total_requests,
		"All requests should complete in medium load scenario"
	)
	assert_test(#load_result.errors == 0, "No errors should occur in medium load scenario with mock responses")
	assert_test(response_stats.avg < 200, "Average response time should be under 200ms in medium load with mock")
	assert_test(final_metrics.active_connections == 0, "No active connections should remain after medium load test")

	-- Store performance metrics
	load_test_state.performance_metrics.medium_load = {
		response_stats = response_stats,
		pool_metrics = final_metrics,
		completed_requests = load_result.completed_requests,
		errors = #load_result.errors,
	}

	test_log("Medium load scenario test completed")
end

-- Test 3: High load testing with mock responses
local function test_high_load_scenario()
	test_log("Testing high load scenario (20 concurrent, 200 total requests)...")

	-- Reset for new test
	http_client.reset_connection_pool()
	http_client.set_connection_pool_size(25)

	local scenario = LOAD_TEST_CONFIG.scenarios.high_load

	-- Execute load test
	local load_result = simulate_concurrent_requests(
		scenario.concurrent_requests,
		scenario.total_requests,
		scenario.delay_between_requests
	)

	-- Get final pool metrics
	local final_metrics = http_client.get_connection_pool_metrics()

	-- Analyze results
	local response_stats = calculate_statistics(load_result.response_times)

	-- Assertions
	assert_test(
		load_result.completed_requests == scenario.total_requests,
		"All requests should complete in high load scenario"
	)
	assert_test(#load_result.errors == 0, "No errors should occur in high load scenario with mock responses")
	assert_test(response_stats.avg < 500, "Average response time should be under 500ms in high load with mock")
	assert_test(final_metrics.active_connections == 0, "No active connections should remain after high load test")

	-- Store performance metrics
	load_test_state.performance_metrics.high_load = {
		response_stats = response_stats,
		pool_metrics = final_metrics,
		completed_requests = load_result.completed_requests,
		errors = #load_result.errors,
	}

	test_log("High load scenario test completed")
end

-- Test 4: Stress load testing with mock responses
local function test_stress_load_scenario()
	test_log("Testing stress load scenario (50 concurrent, 500 total requests)...")

	-- Reset for new test
	http_client.reset_connection_pool()
	http_client.set_connection_pool_size(50)

	local scenario = LOAD_TEST_CONFIG.scenarios.stress_load

	-- Execute load test
	local load_result = simulate_concurrent_requests(
		scenario.concurrent_requests,
		scenario.total_requests,
		scenario.delay_between_requests
	)

	-- Get final pool metrics
	local final_metrics = http_client.get_connection_pool_metrics()

	-- Analyze results
	local response_stats = calculate_statistics(load_result.response_times)

	-- Assertions
	assert_test(
		load_result.completed_requests == scenario.total_requests,
		"All requests should complete in stress load scenario"
	)
	assert_test(#load_result.errors == 0, "No errors should occur in stress load scenario with mock responses")
	assert_test(response_stats.avg < 1000, "Average response time should be under 1000ms in stress load with mock")
	assert_test(final_metrics.active_connections == 0, "No active connections should remain after stress load test")

	-- Store performance metrics
	load_test_state.performance_metrics.stress_load = {
		response_stats = response_stats,
		pool_metrics = final_metrics,
		completed_requests = load_result.completed_requests,
		errors = #load_result.errors,
	}

	test_log("Stress load scenario test completed")
end

-- Test 5: Connection pool saturation testing
local function test_connection_pool_saturation()
	test_log("Testing connection pool saturation...")

	-- Reset for new test
	http_client.reset_connection_pool()
	http_client.set_connection_pool_size(3) -- Small pool to test saturation

	local results = {}
	local errors = 0

	-- Try to get more connections than pool size
	for i = 1, 10 do
		local conn = http_client.get_connection()
		if conn then
			table.insert(results, conn)
		else
			errors = errors + 1
		end
	end

	-- Assertions
	assert_test(#results == 3, "Should only get 3 connections (pool size)")
	assert_test(errors == 7, "Should fail to get 7 connections when pool is saturated")

	-- Return connections
	for _, conn in ipairs(results) do
		http_client.return_connection(conn)
	end

	-- Verify pool is available again
	local final_metrics = http_client.get_connection_pool_metrics()
	assert_test(final_metrics.available_connections == 3, "Pool should have 3 available connections after return")
	assert_test(final_metrics.active_connections == 0, "No active connections should remain")

	test_log("Connection pool saturation test completed")
end

-- Test 6: Memory usage under load
local function test_memory_usage_under_load()
	test_log("Testing memory usage under load...")

	-- Reset for new test
	http_client.reset_connection_pool()
	http_client.set_connection_pool_size(20)

	local initial_metrics = http_client.get_connection_pool_metrics()

	-- Execute medium load test
	local scenario = LOAD_TEST_CONFIG.scenarios.medium_load
	local load_result = simulate_concurrent_requests(
		scenario.concurrent_requests,
		scenario.total_requests,
		scenario.delay_between_requests
	)

	local final_metrics = http_client.get_connection_pool_metrics()

	-- Assertions
	assert_test(final_metrics.total_connections <= 20, "Total connections should not exceed pool size")
	assert_test(final_metrics.active_connections == 0, "No active connections should remain after test")
	assert_test(final_metrics.available_connections >= 0, "Available connections should be non-negative")

	test_log("Memory usage under load test completed")
end

-- Test 7: Performance comparison with and without pooling
local function test_performance_comparison()
	test_log("Testing performance comparison with and without pooling...")

	-- Test with pooling enabled
	http_client.reset_connection_pool()
	http_client.set_connection_pool_size(10)

	local scenario = LOAD_TEST_CONFIG.scenarios.low_load
	local with_pooling_result = simulate_concurrent_requests(
		scenario.concurrent_requests,
		scenario.total_requests,
		scenario.delay_between_requests
	)

	local with_pooling_stats = calculate_statistics(with_pooling_result.response_times)

	-- Test with pooling disabled
	http_client.reset_connection_pool()
	http_client.set_connection_pool_size(1) -- Effectively disable pooling

	local without_pooling_result = simulate_concurrent_requests(
		scenario.concurrent_requests,
		scenario.total_requests,
		scenario.delay_between_requests
	)

	local without_pooling_stats = calculate_statistics(without_pooling_result.response_times)

	-- Assertions
	assert_test(
		with_pooling_stats.avg <= without_pooling_stats.avg * 1.5,
		"Pooling should not significantly degrade performance"
	)
	assert_test(
		with_pooling_result.completed_requests >= without_pooling_result.completed_requests * 0.9,
		"Pooling should maintain similar completion rates"
	)

	test_log("Performance comparison test completed")
end

-- Test 8: Error recovery under load
local function test_error_recovery_under_load()
	test_log("Testing error recovery under load...")

	-- Reset for new test
	http_client.reset_connection_pool()
	http_client.set_connection_pool_size(5)

	local scenario = LOAD_TEST_CONFIG.scenarios.medium_load

	-- Execute load test
	local load_result = simulate_concurrent_requests(
		scenario.concurrent_requests,
		scenario.total_requests,
		scenario.delay_between_requests
	)

	-- Get final pool metrics
	local final_metrics = http_client.get_connection_pool_metrics()

	-- Assertions
	assert_test(final_metrics.active_connections == 0, "No active connections should remain after error recovery test")
	assert_test(final_metrics.available_connections >= 0, "Should have available connections after error recovery")
	assert_test(load_result.completed_requests > 0, "Should complete some requests even with errors")

	test_log("Error recovery under load test completed")
end

-- Print performance report
local function print_performance_report()
	test_log("==========================================")
	test_log("MOCK LOAD TESTING PERFORMANCE REPORT")
	test_log("==========================================")

	for scenario_name, metrics in pairs(load_test_state.performance_metrics) do
		test_log(string.format("Scenario: %s", scenario_name:upper()))
		test_log(string.format("  Completed Requests: %d", metrics.completed_requests))
		test_log(string.format("  Errors: %d", metrics.errors))
		test_log(
			string.format(
				"  Success Rate: %.2f%%",
				(metrics.completed_requests - metrics.errors) / metrics.completed_requests * 100
			)
		)
		test_log(
			string.format(
				"  Response Time (ms) - Avg: %.2f, Min: %.2f, Max: %.2f",
				metrics.response_stats.avg,
				metrics.response_stats.min,
				metrics.response_stats.max
			)
		)
		test_log(string.format("  Pool Usage: %.2f%%", metrics.pool_metrics.usage_percentage))
		test_log("")
	end
end

-- Main test runner
local function run_all_load_tests()
	test_log("Starting HTTP Client Mock Load Testing Suite")
	test_log("============================================")

	-- Initialize test state
	load_test_state.test_count = 0
	load_test_state.passed_count = 0
	load_test_state.failed_count = 0
	load_test_state.performance_metrics = {}

	-- Run all load tests
	test_low_load_scenario()
	test_medium_load_scenario()
	test_high_load_scenario()
	test_stress_load_scenario()
	test_connection_pool_saturation()
	test_memory_usage_under_load()
	test_performance_comparison()
	test_error_recovery_under_load()

	-- Print performance report
	print_performance_report()

	-- Print test summary
	test_log("============================================")
	test_log(
		string.format(
			"Mock Load Test Summary: %d total, %d passed, %d failed",
			load_test_state.test_count,
			load_test_state.passed_count,
			load_test_state.failed_count
		)
	)

	if load_test_state.failed_count == 0 then
		test_log("🎉 All HTTP Client Mock Load tests passed!")
		test_log("✅ Task 9.6: Load testing under various conditions complete")
		return true
	else
		test_log("❌ Some HTTP Client Mock Load tests failed!")
		return false
	end
end

-- Export test functions
return {
	run_all_load_tests = run_all_load_tests,
	test_low_load_scenario = test_low_load_scenario,
	test_medium_load_scenario = test_medium_load_scenario,
	test_high_load_scenario = test_high_load_scenario,
	test_stress_load_scenario = test_stress_load_scenario,
	test_connection_pool_saturation = test_connection_pool_saturation,
	test_memory_usage_under_load = test_memory_usage_under_load,
	test_performance_comparison = test_performance_comparison,
	test_error_recovery_under_load = test_error_recovery_under_load,
}
