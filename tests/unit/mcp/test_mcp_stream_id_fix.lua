-- Test MCP Stream ID Fix
-- Tests the fix for "Invalid stream ID" errors during MCP initialization

local mcp_http_transport = require("../../lua/paragonic/mcp_http_transport")
local sse_client = require("../../lua/paragonic/sse_client")

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

-- Test 1: SSE client should accept nil stream_id in connect()
local function test_sse_connect_with_nil_stream_id()
	print("Testing SSE client connect with nil stream_id...")

	sse_client.cleanup()
	sse_client.init()

	-- Test that connect() accepts nil stream_id without error
	local success, err = sse_client.connect(nil, {})
	assert_true(success, "connect should succeed with nil stream_id")
	assert_nil(err, "connect should not return error with nil stream_id")

	-- Verify connection status
	local status = sse_client.get_connection_status()
	assert_true(status.is_connected, "should be connected after successful connect")
end

-- Test 2: SSE client should handle nil stream_id in debug messages
local function test_sse_debug_messages_with_nil_stream_id()
	print("Testing SSE client debug messages with nil stream_id...")

	sse_client.cleanup()
	sse_client.init()

	-- Set up a mock debug function to capture messages
	local captured_messages = {}
	local original_debug_print = require("paragonic.debug").debug_print_safe
	require("paragonic.debug").debug_print_safe = function(message, level)
		table.insert(captured_messages, { message = message, level = level })
	end

	-- Test connection with nil stream_id
	local success, err = sse_client.connect(nil, {})
	assert_true(success, "connect should succeed")

	-- Check that debug messages don't contain "nil" for stream_id
	for _, msg in ipairs(captured_messages) do
		assert_false(msg.message:find("stream: nil"), "debug message should not contain 'stream: nil'")
		assert_false(msg.message:find("stream: " .. tostring(nil)), "debug message should not contain nil stream_id")
	end

	-- Restore original debug function
	require("paragonic.debug").debug_print_safe = original_debug_print
end

-- Test 3: MCP transport should handle session initialization without stream_id errors
local function test_mcp_initialization_without_stream_id_errors()
	print("Testing MCP transport initialization without stream_id errors...")

	mcp_http_transport.cleanup()

	-- Initialize MCP transport
	local success, err = mcp_http_transport.init({
		base_url = "http://localhost:3000",
		protocol_version = "2025-06-18",
		initialization_timeout = 30,
		request_timeout = 60,
	})

	-- This should succeed even if the server is not running
	-- The key is that it shouldn't fail with "Invalid stream ID"
	assert_true(success, "MCP init should succeed")
	assert_nil(err, "MCP init should not return error")

	-- Test session initialization (this will fail due to no server, but shouldn't be stream_id related)
	local session_success, session_err = mcp_http_transport.initialize_session({
		name = "test-client",
		version = "1.0.0",
		capabilities = { tools = {}, resources = {}, notifications = {} },
	})

	-- The session initialization will likely fail due to no server running,
	-- but it should NOT fail with "Invalid stream ID"
	if not session_success then
		assert_false(
			session_err:find("Invalid stream ID"),
			"Session initialization should not fail with 'Invalid stream ID'"
		)
		assert_false(
			session_err:find("stream_id"),
			"Session initialization should not fail with stream_id related errors"
		)
	end
end

-- Test 4: SSE client should handle nil stream_id in callback functions
local function test_sse_callbacks_with_nil_stream_id()
	print("Testing SSE client callbacks with nil stream_id...")

	sse_client.cleanup()
	sse_client.init()

	local callback_called = false
	local callback_stream_id = nil

	local callbacks = {
		on_connect = function(stream_id)
			callback_called = true
			callback_stream_id = stream_id
		end,
	}

	-- Connect with nil stream_id
	local success, err = sse_client.connect(nil, callbacks)
	assert_true(success, "connect should succeed")

	-- Check that callback was called with a default value
	assert_true(callback_called, "on_connect callback should be called")
	assert_not_nil(callback_stream_id, "callback should receive a stream_id value")
	assert_equal("default", callback_stream_id, "callback should receive 'default' as stream_id")
end

-- Test 5: Verify that stream_id validation is properly relaxed
local function test_stream_id_validation_relaxed()
	print("Testing that stream_id validation is properly relaxed...")

	sse_client.cleanup()
	sse_client.init()

	-- Test that connect() accepts nil stream_id
	local success1, err1 = sse_client.connect(nil, {})
	assert_true(success1, "connect should accept nil stream_id")
	assert_nil(err1, "connect should not error with nil stream_id")

	sse_client.cleanup()
	sse_client.init()

	-- Test that connect() still accepts valid string stream_id
	local success2, err2 = sse_client.connect("test-stream-123", {})
	assert_true(success2, "connect should accept valid string stream_id")
	assert_nil(err2, "connect should not error with valid string stream_id")

	sse_client.cleanup()
	sse_client.init()

	-- Test that connect() still rejects invalid types
	local success3, err3 = sse_client.connect(123, {})
	assert_false(success3, "connect should reject number stream_id")
	assert_not_nil(err3, "connect should error with number stream_id")
	assert_equal("Invalid stream ID", err3, "should return correct error message")
end

-- Run all tests
print("=== Testing MCP Stream ID Fix ===")
print("")

run_test("SSE connect with nil stream_id", test_sse_connect_with_nil_stream_id)
run_test("SSE debug messages with nil stream_id", test_sse_debug_messages_with_nil_stream_id)
run_test("MCP initialization without stream_id errors", test_mcp_initialization_without_stream_id_errors)
run_test("SSE callbacks with nil stream_id", test_sse_callbacks_with_nil_stream_id)
run_test("Stream ID validation relaxed", test_stream_id_validation_relaxed)

-- Print results
print("")
print("=== Test Results ===")
print("Passed: " .. test_results.passed)
print("Failed: " .. test_results.failed)

if test_results.failed > 0 then
	print("")
	print("=== Failed Tests ===")
	for _, error_info in ipairs(test_results.errors) do
		print("  " .. error_info.name .. ": " .. tostring(error_info.error))
	end
	os.exit(1)
else
	print("")
	print("🎉 All MCP Stream ID Fix tests passed!")
end
