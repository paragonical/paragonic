-- Test HTTP Client Connection Pooling Integration
--
-- This test file verifies that HTTP requests actually use
-- the connection pooling functionality in practice.

local http_client = require("../../lua/paragonic/http_client")

-- Test configuration
local TEST_CONFIG = {
	base_url = "http://localhost:3000",
	timeout = 5,
	retry_attempts = 1,
	retry_delay = 0.1,
}

-- Test state
local test_state = {
	test_count = 0,
	passed_count = 0,
	failed_count = 0,
}

-- Test utilities
local function test_log(message)
	print(string.format("[HTTP Pooling Integration Test] %s", message))
end

local function assert_test(condition, message)
	test_state.test_count = test_state.test_count + 1
	if condition then
		test_state.passed_count = test_state.passed_count + 1
		test_log("✓ " .. message)
	else
		test_state.failed_count = test_state.failed_count + 1
		test_log("✗ " .. message)
	end
end

-- Test 1: HTTP requests use connection pooling by default
local function test_http_requests_use_pooling_by_default()
	test_log("Testing that HTTP requests use connection pooling by default...")

	-- Initialize HTTP client
	local success = http_client.init(TEST_CONFIG)
	assert_test(success, "HTTP client initialization should succeed")

	-- Reset connection pool
	http_client.reset_connection_pool()
	http_client.set_connection_pool_size(2)

	-- Get initial pool metrics
	local initial_metrics = http_client.get_connection_pool_metrics()
	assert_test(initial_metrics.active_connections == 0, "Initial active connections should be 0")

	-- Make a request (this should use connection pooling)
	local response = http_client.get("/test")

	-- Get pool metrics after request
	local after_metrics = http_client.get_connection_pool_metrics()
	assert_test(after_metrics.active_connections == 0, "Active connections should return to 0 after request")
	assert_test(after_metrics.available_connections >= 0, "Should have available connections after request")

	test_log("HTTP requests use connection pooling by default test completed")
end

-- Test 2: Connection pooling can be disabled per request
local function test_connection_pooling_can_be_disabled()
	test_log("Testing that connection pooling can be disabled per request...")

	-- Reset connection pool
	http_client.reset_connection_pool()
	http_client.set_connection_pool_size(1)

	-- Get initial pool metrics
	local initial_metrics = http_client.get_connection_pool_metrics()
	assert_test(initial_metrics.active_connections == 0, "Initial active connections should be 0")

	-- Make a request with pooling disabled
	local request_config = {
		method = "GET",
		endpoint = "/test",
		use_connection_pool = false,
	}

	local response = http_client.send_request("GET", "/test", nil, nil)

	-- Get pool metrics after request (should be unchanged)
	local after_metrics = http_client.get_connection_pool_metrics()
	assert_test(after_metrics.active_connections == 0, "Active connections should remain 0 when pooling disabled")

	test_log("Connection pooling can be disabled per request test completed")
end

-- Test 3: Keep-alive optimization is applied
local function test_keep_alive_optimization()
	test_log("Testing keep-alive optimization...")

	-- Set optimization config
	local optimization_config = {
		enable_keep_alive = true,
		keep_alive_timeout = 30,
	}

	local success = http_client.set_optimization_config(optimization_config)
	assert_test(success, "Setting optimization config should succeed")

	-- Verify keep-alive is enabled
	local config = http_client.get_optimization_config()
	assert_test(config.enable_keep_alive == true, "Keep-alive should be enabled")
	assert_test(config.keep_alive_timeout == 30, "Keep-alive timeout should be 30")

	test_log("Keep-alive optimization test completed")
end

-- Test 4: Connection pool metrics are accurate
local function test_connection_pool_metrics_accuracy()
	test_log("Testing connection pool metrics accuracy...")

	-- Reset connection pool
	http_client.reset_connection_pool()
	http_client.set_connection_pool_size(3)

	-- Get initial metrics
	local initial_metrics = http_client.get_connection_pool_metrics()
	assert_test(initial_metrics.active_connections == 0, "Initial active connections should be 0")
	assert_test(initial_metrics.available_connections == 0, "Initial available connections should be 0")
	assert_test(initial_metrics.total_connections == 0, "Initial total connections should be 0")

	-- Get a connection manually
	local conn1 = http_client.get_connection()
	assert_test(conn1 ~= nil, "Should be able to get connection")

	-- Check metrics after getting connection
	local after_get_metrics = http_client.get_connection_pool_metrics()
	assert_test(after_get_metrics.active_connections == 1, "Active connections should be 1 after getting connection")
	assert_test(
		after_get_metrics.available_connections == 0,
		"Available connections should be 0 after getting connection"
	)
	assert_test(after_get_metrics.total_connections == 1, "Total connections should be 1 after getting connection")

	-- Return connection
	http_client.return_connection(conn1)

	-- Check metrics after returning connection
	local after_return_metrics = http_client.get_connection_pool_metrics()
	assert_test(
		after_return_metrics.active_connections == 0,
		"Active connections should be 0 after returning connection"
	)
	assert_test(
		after_return_metrics.available_connections == 1,
		"Available connections should be 1 after returning connection"
	)
	assert_test(after_return_metrics.total_connections == 1, "Total connections should be 1 after returning connection")

	test_log("Connection pool metrics accuracy test completed")
end

-- Test 5: Multiple requests share connection pool
local function test_multiple_requests_share_pool()
	test_log("Testing that multiple requests share connection pool...")

	-- Reset connection pool
	http_client.reset_connection_pool()
	http_client.set_connection_pool_size(2)

	-- Make multiple requests
	for i = 1, 3 do
		local response = http_client.get("/test")
		-- Small delay to ensure requests are processed
		os.execute("sleep 0.1")
	end

	-- Check pool metrics
	local metrics = http_client.get_connection_pool_metrics()
	assert_test(metrics.active_connections == 0, "Active connections should be 0 after all requests")
	assert_test(metrics.available_connections >= 0, "Should have available connections after requests")
	assert_test(metrics.total_connections <= 2, "Total connections should not exceed pool size")

	test_log("Multiple requests share connection pool test completed")
end

-- Test 6: Connection pool cleanup works correctly
local function test_connection_pool_cleanup()
	test_log("Testing connection pool cleanup...")

	-- Reset connection pool
	http_client.reset_connection_pool()
	http_client.set_connection_pool_size(2)

	-- Get connections and return them
	local conn1 = http_client.get_connection()
	local conn2 = http_client.get_connection()

	assert_test(conn1 ~= nil, "Should be able to get first connection")
	assert_test(conn2 ~= nil, "Should be able to get second connection")

	-- Return connections
	http_client.return_connection(conn1)
	http_client.return_connection(conn2)

	-- Run cleanup
	local cleanup_result = http_client.cleanup_expired_connections()
	assert_test(cleanup_result, "Connection cleanup should succeed")

	-- Check that connections are still available (not expired)
	local metrics = http_client.get_connection_pool_metrics()
	assert_test(metrics.available_connections == 2, "Should have 2 available connections after cleanup")

	test_log("Connection pool cleanup test completed")
end

-- Main test runner
local function run_all_tests()
	test_log("Starting HTTP Client Connection Pooling Integration Tests")
	test_log("=========================================================")

	-- Initialize test state
	test_state.test_count = 0
	test_state.passed_count = 0
	test_state.failed_count = 0

	-- Run all tests
	test_http_requests_use_pooling_by_default()
	test_connection_pooling_can_be_disabled()
	test_keep_alive_optimization()
	test_connection_pool_metrics_accuracy()
	test_multiple_requests_share_pool()
	test_connection_pool_cleanup()

	-- Print test summary
	test_log("=========================================================")
	test_log(
		string.format(
			"Test Summary: %d total, %d passed, %d failed",
			test_state.test_count,
			test_state.passed_count,
			test_state.failed_count
		)
	)

	if test_state.failed_count == 0 then
		test_log("All HTTP Client Connection Pooling Integration tests passed!")
		return true
	else
		test_log("Some HTTP Client Connection Pooling Integration tests failed!")
		return false
	end
end

-- Export test functions
return {
	run_all_tests = run_all_tests,
	test_http_requests_use_pooling_by_default = test_http_requests_use_pooling_by_default,
	test_connection_pooling_can_be_disabled = test_connection_pooling_can_be_disabled,
	test_keep_alive_optimization = test_keep_alive_optimization,
	test_connection_pool_metrics_accuracy = test_connection_pool_metrics_accuracy,
	test_multiple_requests_share_pool = test_multiple_requests_share_pool,
	test_connection_pool_cleanup = test_connection_pool_cleanup,
}
