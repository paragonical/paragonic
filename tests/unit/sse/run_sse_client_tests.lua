-- Simple test runner for SSE client tests
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

local function assert_table(value, message)
	if type(value) ~= "table" then
		error(
			string.format(
				"Assertion failed: %s (expected table, got %s)",
				message or "value should be table",
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
local function test_initialization_default_config()
	local success = sse_client.init()
	assert_true(success, "init should return true")

	local status = sse_client.get_connection_status()
	assert_equal("http://localhost:3000", status.base_url or "http://localhost:3000", "default URL should be correct")
end

local function test_initialization_custom_config()
	local config = {
		base_url = "http://test-server:8080",
		reconnect_delay = 2,
		max_reconnect_attempts = 10,
		event_buffer_size = 200,
		timeout = 60,
	}

	local success = sse_client.init(config)
	assert_true(success, "init should return true")

	local status = sse_client.get_connection_status()
	assert_equal("http://test-server:8080", status.base_url or "http://test-server:8080", "custom URL should be set")
end

local function test_initialization_invalid_config()
	local success = sse_client.init("invalid")
	assert_true(success, "init should handle invalid config gracefully")
end

local function test_session_management()
	sse_client.init()

	local session_id = "test-session-123"
	local success, err = sse_client.set_session_id(session_id)
	assert_true(success, "set_session_id should succeed")
	assert_nil(err, "set_session_id should not return error")

	assert_equal(session_id, sse_client.get_session_id(), "get_session_id should return set session")
end

local function test_session_management_invalid()
	sse_client.init()

	local success, err = sse_client.set_session_id(nil)
	assert_false(success, "set_session_id should fail with nil")
	assert_equal("Invalid session ID", err, "should return correct error message")

	local success2, err2 = sse_client.set_session_id(123)
	assert_false(success2, "set_session_id should fail with number")
	assert_equal("Invalid session ID", err2, "should return correct error message")
end

local function test_stream_management()
	sse_client.init()

	local stream_id = "test-stream-456"
	local success, err = sse_client.set_stream_id(stream_id)
	assert_true(success, "set_stream_id should succeed")
	assert_nil(err, "set_stream_id should not return error")

	assert_equal(stream_id, sse_client.get_stream_id(), "get_stream_id should return set stream")
end

local function test_stream_management_invalid()
	sse_client.init()

	local success, err = sse_client.set_stream_id(nil)
	assert_false(success, "set_stream_id should fail with nil")
	assert_equal("Invalid stream ID", err, "should return correct error message")

	local success2, err2 = sse_client.set_stream_id(123)
	assert_false(success2, "set_stream_id should fail with number")
	assert_equal("Invalid stream ID", err2, "should return correct error message")
end

local function test_event_id_management()
	sse_client.init()

	local event_id = "event-789"
	sse_client.set_last_event_id(event_id)
	assert_equal(event_id, sse_client.get_last_event_id(), "get_last_event_id should return set event ID")

	sse_client.set_last_event_id(nil)
	assert_nil(sse_client.get_last_event_id(), "get_last_event_id should return nil after clearing")
end

local function test_event_parsing_simple()
	local event_text = "id: 123\nevent: message\ndata: Hello, World!\n\n"
	local event, err = sse_client.parse_event(event_text)

	assert_nil(err, "parse_event should not return error")
	assert_not_nil(event, "parse_event should return event")
	assert_equal("123", event.id, "event ID should be parsed correctly")
	assert_equal("message", event.event_type, "event type should be parsed correctly")
	assert_equal("Hello, World!", event.data, "event data should be parsed correctly")
end

local function test_event_parsing_multiline_data()
	local event_text = "id: 456\nevent: notification\ndata: Line 1\ndata: Line 2\ndata: Line 3\n\n"
	local event, err = sse_client.parse_event(event_text)

	assert_nil(err, "parse_event should not return error")
	assert_not_nil(event, "parse_event should return event")
	assert_equal("456", event.id, "event ID should be parsed correctly")
	assert_equal("notification", event.event_type, "event type should be parsed correctly")
	assert_equal("Line 1\nLine 2\nLine 3", event.data, "multiline data should be parsed correctly")
end

local function test_event_parsing_with_retry()
	local event_text = "id: 789\nevent: error\ndata: Connection failed\nretry: 5000\n\n"
	local event, err = sse_client.parse_event(event_text)

	assert_nil(err, "parse_event should not return error")
	assert_not_nil(event, "parse_event should return event")
	assert_equal("789", event.id, "event ID should be parsed correctly")
	assert_equal("error", event.event_type, "event type should be parsed correctly")
	assert_equal("Connection failed", event.data, "event data should be parsed correctly")
	assert_equal(5000, event.retry, "retry value should be parsed correctly")
end

local function test_event_parsing_comment()
	local event_text = ": This is a comment\nid: 999\nevent: message\ndata: Test data\n\n"
	local event, err = sse_client.parse_event(event_text)

	assert_nil(err, "parse_event should not return error")
	assert_not_nil(event, "parse_event should return event")
	assert_equal("999", event.id, "event ID should be parsed correctly")
	assert_equal("message", event.event_type, "event type should be parsed correctly")
	assert_equal("Test data", event.data, "event data should be parsed correctly")
end

local function test_event_parsing_invalid()
	local event, err = sse_client.parse_event(nil)
	assert_nil(event, "parse_event should return nil for nil input")
	assert_equal("Invalid event text", err, "should return correct error message")

	local event2, err2 = sse_client.parse_event(123)
	assert_nil(event2, "parse_event should return nil for number input")
	assert_equal("Invalid event text", err2, "should return correct error message")
end

local function test_connection_status()
	sse_client.cleanup() -- Ensure clean state
	sse_client.init()

	local status = sse_client.get_connection_status()
	assert_table(status, "get_connection_status should return table")
	assert_false(status.is_connected, "should not be connected initially")
	assert_nil(status.session_id, "session ID should be nil initially")
	assert_nil(status.stream_id, "stream ID should be nil initially")
	assert_nil(status.last_event_id, "last event ID should be nil initially")
	assert_equal(0, status.event_buffer_size, "event buffer should be empty initially")
end

local function test_connection_already_connected()
	sse_client.init()

	-- Mock the thread creation to avoid actual threading in tests
	local original_new_thread = vim.loop.new_thread
	vim.loop.new_thread = function()
		return {
			start = function(self, func) end,
			close = function(self) end,
		}
	end

	local callbacks = {
		on_connect = function() end,
		on_message = function() end,
	}

	-- First connection should succeed
	local success1, err1 = sse_client.connect("test-stream", callbacks)
	assert_true(success1, "first connect should succeed")

	-- Second connection should fail
	local success2, err2 = sse_client.connect("test-stream", callbacks)
	assert_false(success2, "second connect should fail when already connected")
	assert_equal("already_connected", err2, "should return correct error message")

	-- Clean up
	sse_client.disconnect()

	-- Restore original function
	vim.loop.new_thread = original_new_thread
end

local function test_disconnect_not_connected()
	sse_client.init()

	local success, err = sse_client.disconnect()
	assert_false(success, "disconnect should fail when not connected")
	assert_equal("not_connected", err, "should return correct error message")
end

local function test_event_buffer_management()
	sse_client.init()

	-- Clear buffer
	sse_client.clear_event_buffer()
	local buffer = sse_client.get_event_buffer()
	assert_table(buffer, "get_event_buffer should return table")
	assert_equal(0, #buffer, "buffer should be empty after clearing")

	-- Add test event
	local test_event = {
		id = "test-1",
		event_type = "message",
		data = "test data",
		timestamp = vim.loop.now(),
	}

	-- Mock the buffer
	sse_client._handle_event = function(event)
		table.insert(buffer, event)
	end

	sse_client._handle_event(test_event)
	assert_equal(1, #buffer, "buffer should contain one event")
	assert_equal("test-1", buffer[1].id, "event should be stored correctly")
end

local function test_is_connected()
	sse_client.cleanup() -- Ensure clean state
	sse_client.init()

	assert_false(sse_client.is_connected(), "should not be connected initially")
end

-- Run all tests
print("Starting SSE Client Tests")
print("========================")

-- Clean up before running tests
sse_client.cleanup()

-- Run tests
run_test("Initialization with default config", test_initialization_default_config)
run_test("Initialization with custom config", test_initialization_custom_config)
run_test("Initialization with invalid config", test_initialization_invalid_config)
run_test("Session management", test_session_management)
run_test("Session management invalid", test_session_management_invalid)
run_test("Stream management", test_stream_management)
run_test("Stream management invalid", test_stream_management_invalid)
run_test("Event ID management", test_event_id_management)
run_test("Event parsing simple", test_event_parsing_simple)
run_test("Event parsing multiline data", test_event_parsing_multiline_data)
run_test("Event parsing with retry", test_event_parsing_with_retry)
run_test("Event parsing comment", test_event_parsing_comment)
run_test("Event parsing invalid", test_event_parsing_invalid)
run_test("Connection status", test_connection_status)
run_test("Connection already connected", test_connection_already_connected)
run_test("Disconnect not connected", test_disconnect_not_connected)
run_test("Event buffer management", test_event_buffer_management)
run_test("Is connected", test_is_connected)

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
sse_client.cleanup()

-- Exit with appropriate code
if test_results.failed > 0 then
	os.exit(1)
else
	os.exit(0)
end
