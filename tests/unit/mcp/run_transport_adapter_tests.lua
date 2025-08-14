-- Simple test runner for transport adapter tests
local mcp_transport_adapter = require("../../lua/paragonic/mcp_transport_adapter")

-- Test utilities
local function assert_equal(expected, actual, message)
	if expected ~= actual then
		error(
			string.format(
				"Assertion failed: %s (expected %s, got %s)",
				message or "values not equal",
				tostring(expected),
				tostring(actual)
			)
		)
	end
end

local function assert_true(value, message)
	if not value then
		error(
			string.format(
				"Assertion failed: %s (expected true, got %s)",
				message or "value should be true",
				tostring(value)
			)
		)
	end
end

local function assert_false(value, message)
	if value then
		error(
			string.format(
				"Assertion failed: %s (expected false, got %s)",
				message or "value should be false",
				tostring(value)
			)
		)
	end
end

local function assert_nil(value, message)
	if value ~= nil then
		error(
			string.format(
				"Assertion failed: %s (expected nil, got %s)",
				message or "value should be nil",
				tostring(value)
			)
		)
	end
end

local function assert_not_nil(value, message)
	if value == nil then
		error(string.format("Assertion failed: %s (expected non-nil value)", message or "value should not be nil"))
	end
end

local function assert_string(value, message)
	if type(value) ~= "string" then
		error(
			string.format(
				"Assertion failed: %s (expected string, got %s)",
				message or "value should be string",
				type(value)
			)
		)
	end
end

-- Test results
local test_results = {
	passed = 0,
	failed = 0,
	errors = {},
}

local function run_test(test_name, test_func)
	print("Running test: " .. test_name)
	local success, err = pcall(test_func)
	if success then
		print("  ✓ PASSED")
		test_results.passed = test_results.passed + 1
	else
		print("  ✗ FAILED: " .. tostring(err))
		test_results.failed = test_results.failed + 1
		table.insert(test_results.errors, { name = test_name, error = err })
	end
end

-- Test functions
local function test_initialization_http_transport()
	local config = {
		transport_type = "http",
		base_url = "http://localhost:3000",
	}

	local success = mcp_transport_adapter.init(config)
	assert_true(success, "init should return true for HTTP transport")

	local status = mcp_transport_adapter.get_status()
	assert_equal("http", status.transport_type, "transport type should be HTTP")
	assert_equal("http", status.current_transport, "current transport should be HTTP")
	assert_true(status.is_initialized, "should be initialized")
end

local function test_initialization_tcp_transport()
	local config = {
		transport_type = "tcp",
	}

	local success, err = mcp_transport_adapter.init(config)
	assert_false(success, "init should fail for TCP transport (not implemented)")
	assert_string(err, "should return error message")
end

local function test_initialization_auto_transport()
	local config = {
		transport_type = "auto",
		base_url = "http://localhost:3000",
	}

	local success = mcp_transport_adapter.init(config)
	assert_true(success, "init should return true for auto transport (HTTP fallback)")

	local status = mcp_transport_adapter.get_status()
	assert_equal("auto", status.transport_type, "transport type should be auto")
	assert_equal("http", status.current_transport, "current transport should be HTTP")
	assert_true(status.is_initialized, "should be initialized")
end

local function test_initialization_invalid_transport()
	local config = {
		transport_type = "invalid",
	}

	local success, err = mcp_transport_adapter.init(config)
	assert_false(success, "init should fail for invalid transport type")
	assert_string(err, "should return error message")
end

local function test_initialization_default_config()
	local success = mcp_transport_adapter.init()
	assert_true(success, "init should return true with default config")

	local status = mcp_transport_adapter.get_status()
	assert_equal("auto", status.transport_type, "default transport type should be auto")
	assert_equal(5, status.fallback_timeout, "default fallback timeout should be 5")
	assert_equal(30, status.health_check_interval, "default health check interval should be 30")
end

local function test_callback_setting()
	mcp_transport_adapter.init()

	local callbacks = {
		on_connect = function() end,
		on_message = function() end,
		on_error = function() end,
		on_log = function() end,
	}

	mcp_transport_adapter.set_callbacks(callbacks)

	local status = mcp_transport_adapter.get_status()
	assert_not_nil(status, "status should not be nil")
end

local function test_session_initialization_validation()
	-- Test initialization without init
	mcp_transport_adapter.cleanup() -- Ensure clean state

	local client_info = {
		name = "test-client",
		version = "1.0.0",
		capabilities = {},
	}

	local success, err = mcp_transport_adapter.initialize_session(client_info)
	assert_false(success, "should fail when not initialized")
	assert_equal("not_initialized", err, "should return correct error")
end

local function test_request_validation()
	mcp_transport_adapter.init()

	-- Test request without initialization
	local request = {
		jsonrpc = "2.0",
		method = "test",
		params = {},
	}

	local response, err = mcp_transport_adapter.send_request(request)
	-- Should fail in test environment (no server), but the validation should pass
	assert_nil(response, "should return nil without server")
	assert_not_nil(err, "should return error without server")
end

local function test_notification_validation()
	mcp_transport_adapter.init()

	local notification = {
		jsonrpc = "2.0",
		method = "test",
		params = {},
	}

	local success, err = mcp_transport_adapter.send_notification(notification)
	-- Should fail in test environment (no server), but the validation should pass
	assert_false(success, "should return false without server")
	assert_not_nil(err, "should return error without server")
end

local function test_health_check()
	mcp_transport_adapter.init()

	local success = mcp_transport_adapter.health_check()
	assert_true(success, "health check should pass for initialized HTTP transport")
end

local function test_health_check_not_initialized()
	mcp_transport_adapter.cleanup() -- Ensure clean state

	local success, err = mcp_transport_adapter.health_check()
	assert_false(success, "health check should fail when not initialized")
	assert_equal("not_initialized", err, "should return correct error")
end

local function test_transport_switching()
	mcp_transport_adapter.init()

	-- Switch to HTTP transport
	local success = mcp_transport_adapter.switch_transport("http", {
		base_url = "http://localhost:3000",
	})
	assert_true(success, "should successfully switch to HTTP transport")

	local status = mcp_transport_adapter.get_status()
	assert_equal("http", status.current_transport, "current transport should be HTTP")
end

local function test_transport_switching_invalid()
	mcp_transport_adapter.init()

	local success, err = mcp_transport_adapter.switch_transport("invalid", {})
	assert_false(success, "should fail to switch to invalid transport")
	assert_string(err, "should return error message")
end

local function test_status_retrieval()
	mcp_transport_adapter.init()

	local status = mcp_transport_adapter.get_status()
	assert_equal("auto", status.transport_type, "transport type should be auto")
	assert_equal("http", status.current_transport, "current transport should be HTTP")
	assert_true(status.is_initialized, "should be initialized")
	assert_false(status.is_connected, "should not be connected initially")
	assert_equal(5, status.fallback_timeout, "fallback timeout should be correct")
	assert_equal(30, status.health_check_interval, "health check interval should be correct")
	assert_not_nil(status.transport_status, "transport status should not be nil")
end

local function test_ready_check()
	mcp_transport_adapter.init()

	assert_false(mcp_transport_adapter.is_ready(), "should not be ready initially")
end

local function test_session_id_getter()
	mcp_transport_adapter.init()

	assert_nil(mcp_transport_adapter.get_session_id(), "session ID should be nil initially")
end

local function test_stream_id_getter()
	mcp_transport_adapter.init()

	assert_nil(mcp_transport_adapter.get_stream_id(), "stream ID should be nil initially")
end

local function test_health_check_timer()
	mcp_transport_adapter.init()

	-- Start health check timer
	mcp_transport_adapter.start_health_check()

	local status = mcp_transport_adapter.get_status()
	assert_not_nil(status, "status should not be nil after starting timer")

	-- Stop health check timer
	mcp_transport_adapter.stop_health_check()
end

local function test_cleanup()
	mcp_transport_adapter.init()

	-- Verify state is set
	assert_true(mcp_transport_adapter.get_status().is_initialized, "should be initialized")

	-- Clean up
	mcp_transport_adapter.cleanup()

	-- Verify state is reset
	local status = mcp_transport_adapter.get_status()
	assert_false(status.is_initialized, "should not be initialized after cleanup")
	assert_false(status.is_connected, "should not be connected after cleanup")
	assert_nil(status.current_transport, "current transport should be nil after cleanup")
end

-- Run all tests
print("Starting Transport Adapter Tests")
print("================================")

-- Clean up before running tests
mcp_transport_adapter.cleanup()

-- Run tests
run_test("Initialization HTTP transport", test_initialization_http_transport)
run_test("Initialization TCP transport", test_initialization_tcp_transport)
run_test("Initialization auto transport", test_initialization_auto_transport)
run_test("Initialization invalid transport", test_initialization_invalid_transport)
run_test("Initialization default config", test_initialization_default_config)
run_test("Callback setting", test_callback_setting)
run_test("Session initialization validation", test_session_initialization_validation)
run_test("Request validation", test_request_validation)
run_test("Notification validation", test_notification_validation)
run_test("Health check", test_health_check)
run_test("Health check not initialized", test_health_check_not_initialized)
run_test("Transport switching", test_transport_switching)
run_test("Transport switching invalid", test_transport_switching_invalid)
run_test("Status retrieval", test_status_retrieval)
run_test("Ready check", test_ready_check)
run_test("Session ID getter", test_session_id_getter)
run_test("Stream ID getter", test_stream_id_getter)
run_test("Health check timer", test_health_check_timer)
run_test("Cleanup", test_cleanup)

-- Print results
print("\nTest Results")
print("============")
print(string.format("Passed: %d", test_results.passed))
print(string.format("Failed: %d", test_results.failed))
print(string.format("Total: %d", test_results.passed + test_results.failed))

if test_results.failed > 0 then
	print("\nFailed Tests:")
	for _, error_info in ipairs(test_results.errors) do
		print(string.format("  - %s: %s", error_info.name, error_info.error))
	end
end

-- Clean up after tests
mcp_transport_adapter.cleanup()

-- Exit with appropriate code
if test_results.failed > 0 then
	os.exit(1)
else
	os.exit(0)
end
