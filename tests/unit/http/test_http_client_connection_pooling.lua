-- Test HTTP Client Connection Pooling and Optimization
--
-- This test file implements comprehensive testing for HTTP client
-- connection pooling and optimization features as part of task 9.5.

local http_client = require("../../lua/paragonic/http_client")

-- Test configuration
local TEST_CONFIG = {
	base_url = "http://localhost:3000",
	timeout = 5,
	retry_attempts = 2,
	retry_delay = 0.1,
}

-- Test state
local test_state = {
	initialized = false,
	test_count = 0,
	passed_count = 0,
	failed_count = 0,
}

-- Test utilities
local function test_log(message)
	print(string.format("[HTTP Connection Pooling Test] %s", message))
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

-- Test 1: Connection pooling initialization
local function test_connection_pooling_initialization()
	test_log("Testing connection pooling initialization...")

	-- Initialize HTTP client with connection pooling
	local success = http_client.init(TEST_CONFIG)
	assert_test(success, "HTTP client initialization should succeed")

	-- Test that connection pooling is available
	local pool_config = http_client.get_connection_pool_config()
	assert_test(pool_config ~= nil, "Connection pool config should be available")
	assert_test(type(pool_config.pool_size) == "number", "Pool size should be a number")
	assert_test(pool_config.pool_size > 0, "Pool size should be positive")

	test_log("Connection pooling initialization test completed")
end

-- Test 2: Connection pool configuration
local function test_connection_pool_configuration()
	test_log("Testing connection pool configuration...")

	-- Test setting pool size
	local success = http_client.set_connection_pool_size(5)
	assert_test(success, "Setting pool size to 5 should succeed")

	local config = http_client.get_connection_pool_config()
	assert_test(config.pool_size == 5, "Pool size should be set to 5")

	-- Test invalid pool sizes
	local invalid_success = http_client.set_connection_pool_size(0)
	assert_test(not invalid_success, "Setting pool size to 0 should fail")

	local invalid_success2 = http_client.set_connection_pool_size(-1)
	assert_test(not invalid_success2, "Setting negative pool size should fail")

	test_log("Connection pool configuration test completed")
end

-- Test 3: Connection acquisition and release
local function test_connection_acquisition_and_release()
	test_log("Testing connection acquisition and release...")

	-- Set small pool size for testing
	http_client.set_connection_pool_size(2)

	-- Get connections from pool
	local conn1 = http_client.get_connection()
	assert_test(conn1 ~= nil, "Should be able to get first connection")

	local conn2 = http_client.get_connection()
	assert_test(conn2 ~= nil, "Should be able to get second connection")

	-- Try to get third connection (should fail)
	local conn3 = http_client.get_connection()
	assert_test(conn3 == nil, "Should not be able to get third connection when pool is full")

	-- Return connections to pool
	local release1 = http_client.return_connection(conn1)
	assert_test(release1, "Should be able to return first connection")

	local release2 = http_client.return_connection(conn2)
	assert_test(release2, "Should be able to return second connection")

	-- Should be able to get connection again after release
	local conn4 = http_client.get_connection()
	assert_test(conn4 ~= nil, "Should be able to get connection after release")

	test_log("Connection acquisition and release test completed")
end

-- Test 4: Connection reuse optimization
local function test_connection_reuse_optimization()
	test_log("Testing connection reuse optimization...")

	-- Set pool size to 1 for testing reuse
	http_client.set_connection_pool_size(1)

	-- Get connection and check its properties
	local conn1 = http_client.get_connection()
	assert_test(conn1 ~= nil, "Should be able to get connection")
	assert_test(conn1.id ~= nil, "Connection should have an ID")
	assert_test(conn1.created_at ~= nil, "Connection should have creation timestamp")

	-- Return connection
	http_client.return_connection(conn1)

	-- Get connection again (should be the same one)
	local conn2 = http_client.get_connection()
	assert_test(conn2 ~= nil, "Should be able to get connection again")
	assert_test(conn2.id == conn1.id, "Should reuse the same connection")

	test_log("Connection reuse optimization test completed")
end

-- Test 5: Connection validation and cleanup
local function test_connection_validation_and_cleanup()
	test_log("Testing connection validation and cleanup...")

	-- Reset pool state
	http_client.reset_connection_pool()

	-- Set pool size and get connection
	http_client.set_connection_pool_size(1)
	local conn = http_client.get_connection()
	assert_test(conn ~= nil, "Should be able to get connection")

	-- Test connection validation (before returning to pool)
	local is_valid = http_client.is_connection_valid(conn)
	assert_test(is_valid, "Fresh connection should be valid")

	-- Return connection
	http_client.return_connection(conn)

	-- Test cleanup of expired connections
	local cleanup_result = http_client.cleanup_expired_connections()
	assert_test(cleanup_result, "Connection cleanup should succeed")

	test_log("Connection validation and cleanup test completed")
end

-- Test 6: Concurrent connection handling
local function test_concurrent_connection_handling()
	test_log("Testing concurrent connection handling...")

	-- Reset pool state
	http_client.reset_connection_pool()

	-- Set pool size to 3 (explicitly set it)
	http_client.set_connection_pool_size(3)

	-- Simulate concurrent connection requests
	local connections = {}
	for i = 1, 3 do
		local conn = http_client.get_connection()
		assert_test(conn ~= nil, string.format("Should be able to get connection %d", i))
		connections[i] = conn
	end

	-- Try to get one more (should fail)
	local extra_conn = http_client.get_connection()
	assert_test(extra_conn == nil, "Should not be able to get extra connection when pool is full")

	-- Return all connections
	for i, conn in ipairs(connections) do
		local success = http_client.return_connection(conn)
		assert_test(success, string.format("Should be able to return connection %d", i))
	end

	test_log("Concurrent connection handling test completed")
end

-- Test 7: Performance metrics for connection pooling
local function test_connection_pooling_performance_metrics()
	test_log("Testing connection pooling performance metrics...")

	-- Get performance metrics
	local metrics = http_client.get_connection_pool_metrics()
	assert_test(metrics ~= nil, "Connection pool metrics should be available")
	assert_test(type(metrics.active_connections) == "number", "Active connections should be a number")
	assert_test(type(metrics.available_connections) == "number", "Available connections should be a number")
	assert_test(type(metrics.total_connections) == "number", "Total connections should be a number")
	assert_test(type(metrics.usage_percentage) == "number", "Usage percentage should be a number")

	-- Test that metrics are within reasonable bounds
	assert_test(metrics.active_connections >= 0, "Active connections should be non-negative")
	assert_test(metrics.available_connections >= 0, "Available connections should be non-negative")
	assert_test(metrics.total_connections >= 0, "Total connections should be non-negative")
	assert_test(
		metrics.usage_percentage >= 0 and metrics.usage_percentage <= 100,
		"Usage percentage should be between 0 and 100"
	)

	test_log("Connection pooling performance metrics test completed")
end

-- Test 8: Connection pooling with HTTP requests
local function test_connection_pooling_with_http_requests()
	test_log("Testing connection pooling with HTTP requests...")

	-- Set pool size
	http_client.set_connection_pool_size(2)

	-- Test that HTTP requests use connection pooling
	local request_config = {
		method = "GET",
		endpoint = "/test",
		use_connection_pool = true,
	}

	-- This would normally make an actual HTTP request
	-- For testing, we'll just verify the configuration is set correctly
	local success = http_client.configure_request_pooling(request_config)
	assert_test(success, "Request pooling configuration should succeed")

	test_log("Connection pooling with HTTP requests test completed")
end

-- Test 9: Connection pool optimization settings
local function test_connection_pool_optimization_settings()
	test_log("Testing connection pool optimization settings...")

	-- Test optimization settings
	local optimization_config = {
		enable_keep_alive = true,
		keep_alive_timeout = 30,
		max_idle_connections = 5,
		connection_timeout = 10,
	}

	local success = http_client.set_optimization_config(optimization_config)
	assert_test(success, "Setting optimization config should succeed")

	-- Get optimization config
	local config = http_client.get_optimization_config()
	assert_test(config ~= nil, "Optimization config should be available")
	assert_test(config.enable_keep_alive == true, "Keep alive should be enabled")
	assert_test(config.keep_alive_timeout == 30, "Keep alive timeout should be 30")
	assert_test(config.max_idle_connections == 5, "Max idle connections should be 5")
	assert_test(config.connection_timeout == 10, "Connection timeout should be 10")

	test_log("Connection pool optimization settings test completed")
end

-- Test 10: Connection pool error handling
local function test_connection_pool_error_handling()
	test_log("Testing connection pool error handling...")

	-- Test invalid connection return
	local invalid_return = http_client.return_connection(nil)
	assert_test(not invalid_return, "Returning nil connection should fail")

	-- Test invalid connection validation
	local invalid_validation = http_client.is_connection_valid(nil)
	assert_test(not invalid_validation, "Validating nil connection should fail")

	-- Test invalid pool size
	local invalid_pool_size = http_client.set_connection_pool_size("invalid")
	assert_test(not invalid_pool_size, "Setting invalid pool size should fail")

	test_log("Connection pool error handling test completed")
end

-- Main test runner
local function run_all_tests()
	test_log("Starting HTTP Client Connection Pooling Tests")
	test_log("=============================================")

	-- Initialize test state
	test_state.test_count = 0
	test_state.passed_count = 0
	test_state.failed_count = 0

	-- Run all tests
	test_connection_pooling_initialization()
	test_connection_pool_configuration()
	test_connection_acquisition_and_release()
	test_connection_reuse_optimization()
	test_connection_validation_and_cleanup()
	test_concurrent_connection_handling()
	test_connection_pooling_performance_metrics()
	test_connection_pooling_with_http_requests()
	test_connection_pool_optimization_settings()
	test_connection_pool_error_handling()

	-- Print test summary
	test_log("=============================================")
	test_log(
		string.format(
			"Test Summary: %d total, %d passed, %d failed",
			test_state.test_count,
			test_state.passed_count,
			test_state.failed_count
		)
	)

	if test_state.failed_count == 0 then
		test_log("All HTTP Client Connection Pooling tests passed!")
		return true
	else
		test_log("Some HTTP Client Connection Pooling tests failed!")
		return false
	end
end

-- Export test functions
return {
	run_all_tests = run_all_tests,
	test_connection_pooling_initialization = test_connection_pooling_initialization,
	test_connection_pool_configuration = test_connection_pool_configuration,
	test_connection_acquisition_and_release = test_connection_acquisition_and_release,
	test_connection_reuse_optimization = test_connection_reuse_optimization,
	test_connection_validation_and_cleanup = test_connection_validation_and_cleanup,
	test_concurrent_connection_handling = test_concurrent_connection_handling,
	test_connection_pooling_performance_metrics = test_connection_pooling_performance_metrics,
	test_connection_pooling_with_http_requests = test_connection_pooling_with_http_requests,
	test_connection_pool_optimization_settings = test_connection_pool_optimization_settings,
	test_connection_pool_error_handling = test_connection_pool_error_handling,
}
