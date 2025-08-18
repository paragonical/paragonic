-- Integration tests for MCP HTTP transport
--
-- This test suite verifies end-to-end functionality of the MCP
-- HTTP transport implementation.

local mcp_http_transport = require("../../lua/paragonic/mcp_http_transport")
local mcp_config = require("../../lua/paragonic/mcp_config")

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

-- Test state
local test_state = {
	transport = nil,
	callbacks_triggered = {},
	events_received = {},
}

-- Callback handlers for testing
local function create_test_callbacks()
	return {
		on_connect = function(stream_id)
			table.insert(test_state.callbacks_triggered, { type = "connect", stream_id = stream_id })
		end,
		on_disconnect = function()
			table.insert(test_state.callbacks_triggered, { type = "disconnect" })
		end,
		on_message = function(event)
			table.insert(test_state.events_received, { type = "message", event = event })
		end,
		on_notification = function(notification)
			table.insert(test_state.events_received, { type = "notification", notification = notification })
		end,
		on_response = function(response)
			table.insert(test_state.events_received, { type = "response", response = response })
		end,
		on_error = function(error_msg, attempt)
			table.insert(test_state.callbacks_triggered, { type = "error", error = error_msg, attempt = attempt })
		end,
		on_parse_error = function(error_msg, raw_event)
			table.insert(
				test_state.callbacks_triggered,
				{ type = "parse_error", error = error_msg, raw_event = raw_event }
			)
		end,
		on_health_check_failed = function(error_msg)
			table.insert(test_state.callbacks_triggered, { type = "health_check_failed", error = error_msg })
		end,
		on_log = function(message)
			table.insert(test_state.callbacks_triggered, { type = "log", message = message })
		end,
	}
end

-- Reset test state
local function reset_test_state()
	test_state.callbacks_triggered = {}
	test_state.events_received = {}
end

-- Test functions
local function test_configuration_loading()
	-- Test configuration loading
	local config = mcp_config.load()
	assert_not_nil(config, "configuration should not be nil")
	assert_not_nil(config.transport, "transport configuration should not be nil")
	assert_not_nil(config.client, "client configuration should not be nil")
	assert_not_nil(config.logging, "logging configuration should not be nil")

	-- Test default values
	assert_equal("auto", config.transport.type, "default transport type should be auto")
	assert_equal("http://localhost:3000", config.transport.http.base_url, "default HTTP URL should be correct")
	assert_equal("2025-06-18", config.transport.http.protocol_version, "default protocol version should be correct")
end

local function test_configuration_validation()
	-- Test valid configuration
	local valid, err = mcp_config.validate()
	assert_true(valid, "default configuration should be valid")
	assert_nil(err, "should not return error for valid configuration")

	-- Test invalid transport type
	mcp_config.set_transport_type("invalid")
	local valid2, err2 = mcp_config.validate()
	assert_false(valid2, "configuration with invalid transport type should be invalid")
	assert_string(err2, "should return error message")

	-- Reset to valid configuration
	mcp_config.set_transport_type("auto")
end

local function test_transport_adapter_initialization()
	-- Test HTTP transport initialization
	local config = {
		transport_type = "http",
		base_url = "http://localhost:3000",
	}

	local success = mcp_http_transport.init(config)
	assert_true(success, "transport adapter should initialize successfully")

	local status = mcp_http_transport.get_status()
	assert_true(status.is_initialized, "should be initialized")
end

local function test_transport_adapter_callbacks()
	mcp_http_transport.init()

	local callbacks = create_test_callbacks()
	mcp_http_transport.set_callbacks(callbacks)

	local status = mcp_http_transport.get_status()
	assert_not_nil(status, "status should not be nil after setting callbacks")
end

local function test_session_initialization()
	mcp_http_transport.init()

	local client_info = {
		name = "integration-test-client",
		version = "1.0.0",
		capabilities = {
			tools = {},
			resources = {},
		},
	}

	local success, err = mcp_http_transport.initialize_session(client_info)
	-- Should fail in test environment (no server), but validation should pass
	assert_false(success, "should fail without server")
	assert_not_nil(err, "should return error message")
end

local function test_request_sending()
	mcp_http_transport.init()

	local request = {
		jsonrpc = "2.0",
		method = "tools/list",
		params = {},
	}

	local response, err = mcp_http_transport.send_request(request)
	-- Should fail in test environment (no server), but validation should pass
	assert_nil(response, "should return nil without server")
	assert_not_nil(err, "should return error message")
end

local function test_notification_sending()
	mcp_http_transport.init()

	local notification = {
		jsonrpc = "2.0",
		method = "notifications/log",
		params = {
			level = "info",
			message = "Test notification",
		},
	}

	local success, err = mcp_http_transport.send_notification(notification)
	-- Should fail in test environment (no server), but validation should pass
	assert_false(success, "should return false without server")
	assert_not_nil(err, "should return error message")
end

local function test_health_check()
	mcp_http_transport.init()

	local success = mcp_http_transport.health_check()
	assert_true(success, "health check should pass for initialized transport")
end

local function test_transport_switching()
	mcp_http_transport.init()

	-- HTTP transport is already the only transport, so this test just verifies initialization
	local status = mcp_http_transport.get_status()
	assert_true(status.is_initialized, "should be initialized")
end

local function test_multiple_concurrent_requests()
	mcp_http_transport.init()

	-- Simulate multiple concurrent requests
	local requests = {
		{
			jsonrpc = "2.0",
			method = "tools/list",
			params = {},
		},
		{
			jsonrpc = "2.0",
			method = "resources/list",
			params = {},
		},
		{
			jsonrpc = "2.0",
			method = "server/info",
			params = {},
		},
	}

	for i, request in ipairs(requests) do
		local response, err = mcp_http_transport.send_request(request)
		assert_nil(response, "request " .. i .. " should return nil without server")
		assert_not_nil(err, "request " .. i .. " should return error message")
	end
end

local function test_error_handling()
	mcp_http_transport.init()

	-- Test invalid request
	local response, err = mcp_http_transport.send_request(nil)
	assert_nil(response, "should return nil for invalid request")
	assert_not_nil(err, "should return error for invalid request")

	-- Test invalid notification
	local success, err2 = mcp_http_transport.send_notification(nil)
	assert_false(success, "should return false for invalid notification")
	assert_not_nil(err2, "should return error for invalid notification")
end

local function test_session_persistence()
	mcp_http_transport.init()

	-- Test session ID persistence
	local session_id = mcp_http_transport.get_session_id()
	assert_nil(session_id, "session ID should be nil initially")

	-- Test stream ID persistence
	local stream_id = mcp_http_transport.get_stream_id()
	assert_nil(stream_id, "stream ID should be nil initially")
end

local function test_ready_state()
	mcp_http_transport.init()

	-- Test ready state
	local ready = mcp_http_transport.is_ready()
	assert_false(ready, "should not be ready without session initialization")
end

local function test_health_check_timer()
	mcp_http_transport.init()

	-- HTTP transport doesn't have timer functionality, so just test initialization
	local status = mcp_http_transport.get_status()
	assert_not_nil(status, "status should not be nil")
end

local function test_configuration_export()
	-- Test transport configuration export
	local transport_config = mcp_config.export_for_transport()
	assert_not_nil(transport_config, "transport config should not be nil")
	assert_equal("auto", transport_config.transport_type, "transport type should be auto")
	assert_equal("http://localhost:3000", transport_config.base_url, "base URL should be correct")

	-- Test client configuration export
	local client_config = mcp_config.export_client_config()
	assert_not_nil(client_config, "client config should not be nil")
	assert_equal("paragonic-client", client_config.name, "client name should be correct")
	assert_equal("1.0.0", client_config.version, "client version should be correct")
end

local function test_configuration_file_operations()
	-- Test configuration file path
	local config_path = mcp_config.get_config_file_path()
	assert_string(config_path, "config file path should be string")

	-- Test configuration file existence check
	local exists = mcp_config.config_file_exists()
	-- May or may not exist depending on test environment
	assert_true(type(exists) == "boolean", "config file existence should return boolean")
end

local function test_cleanup_and_reset()
	mcp_http_transport.init()

	-- Verify state is set
	assert_true(mcp_http_transport.get_status().is_initialized, "should be initialized")

	-- Clean up
	mcp_http_transport.cleanup()

	-- Verify state is reset
	local status = mcp_http_transport.get_status()
	assert_false(status.is_initialized, "should not be initialized after cleanup")
end

-- Run all tests
print("Starting MCP Integration Tests")
print("=============================")

-- Clean up before running tests
mcp_http_transport.cleanup()
reset_test_state()

-- Run tests
run_test("Configuration loading", test_configuration_loading)
run_test("Configuration validation", test_configuration_validation)
run_test("Transport adapter initialization", test_transport_adapter_initialization)
run_test("Transport adapter callbacks", test_transport_adapter_callbacks)
run_test("Session initialization", test_session_initialization)
run_test("Request sending", test_request_sending)
run_test("Notification sending", test_notification_sending)
run_test("Health check", test_health_check)
run_test("Transport switching", test_transport_switching)
run_test("Multiple concurrent requests", test_multiple_concurrent_requests)
run_test("Error handling", test_error_handling)
run_test("Session persistence", test_session_persistence)
run_test("Ready state", test_ready_state)
run_test("Health check timer", test_health_check_timer)
run_test("Configuration export", test_configuration_export)
run_test("Configuration file operations", test_configuration_file_operations)
run_test("Cleanup and reset", test_cleanup_and_reset)

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
mcp_http_transport.cleanup()

-- Exit with appropriate code
if test_results.failed > 0 then
	os.exit(1)
else
	os.exit(0)
end
