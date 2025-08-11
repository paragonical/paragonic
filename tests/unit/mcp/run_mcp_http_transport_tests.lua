-- Simple test runner for MCP HTTP transport tests
local mcp_http_transport = require("../../lua/paragonic/mcp_http_transport")

-- Test utilities
local function assert_equal(expected, actual, message)
    if expected ~= actual then
        error(string.format("Assertion failed: %s (expected %s, got %s)", 
            message or "values not equal", tostring(expected), tostring(actual)))
    end
end

local function assert_true(value, message)
    if not value then
        error(string.format("Assertion failed: %s (expected true, got %s)", 
            message or "value should be true", tostring(value)))
    end
end

local function assert_false(value, message)
    if value then
        error(string.format("Assertion failed: %s (expected false, got %s)", 
            message or "value should be false", tostring(value)))
    end
end

local function assert_nil(value, message)
    if value ~= nil then
        error(string.format("Assertion failed: %s (expected nil, got %s)", 
            message or "value should be nil", tostring(value)))
    end
end

local function assert_not_nil(value, message)
    if value == nil then
        error(string.format("Assertion failed: %s (expected non-nil value)", 
            message or "value should not be nil"))
    end
end

local function assert_table(value, message)
    if type(value) ~= "table" then
        error(string.format("Assertion failed: %s (expected table, got %s)", 
            message or "value should be table", type(value)))
    end
end

local function assert_string(value, message)
    if type(value) ~= "string" then
        error(string.format("Assertion failed: %s (expected string, got %s)", 
            message or "value should be string", type(value)))
    end
end

-- Test results
local test_results = {
    passed = 0,
    failed = 0,
    errors = {}
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
        table.insert(test_results.errors, {name = test_name, error = err})
    end
end

-- Test functions
local function test_initialization_default_config()
    local success = mcp_http_transport.init()
    assert_true(success, "init should return true")
    
    local status = mcp_http_transport.get_status()
    assert_equal("http://localhost:3000", status.base_url, "default URL should be correct")
    assert_equal("2025-06-18", status.protocol_version, "default protocol version should be correct")
    assert_true(status.is_initialized, "should be initialized")
    assert_false(status.is_connected, "should not be connected initially")
end

local function test_initialization_custom_config()
    local config = {
        base_url = "http://test-server:8080",
        protocol_version = "2025-01-01",
        initialization_timeout = 60,
        request_timeout = 120,
        reconnect_delay = 2,
        max_reconnect_attempts = 10,
        event_buffer_size = 200,
    }
    
    local success = mcp_http_transport.init(config)
    assert_true(success, "init should return true")
    
    local status = mcp_http_transport.get_status()
    assert_equal("http://test-server:8080", status.base_url, "custom URL should be set")
    assert_equal("2025-01-01", status.protocol_version, "custom protocol version should be set")
end

local function test_initialization_invalid_config()
    local success = mcp_http_transport.init("invalid")
    assert_true(success, "init should handle invalid config gracefully")
end

local function test_message_id_generation()
    mcp_http_transport.init()
    
    local id1 = mcp_http_transport.generate_message_id()
    local id2 = mcp_http_transport.generate_message_id()
    local id3 = mcp_http_transport.generate_message_id()
    
    assert_string(id1, "message ID should be string")
    assert_string(id2, "message ID should be string")
    assert_string(id3, "message ID should be string")
    
    assert_equal("1", id1, "first message ID should be 1")
    assert_equal("2", id2, "second message ID should be 2")
    assert_equal("3", id3, "third message ID should be 3")
end

local function test_callback_setting()
    mcp_http_transport.init()
    
    local callbacks = {
        on_connect = function() end,
        on_message = function() end,
        on_error = function() end,
    }
    
    mcp_http_transport.set_callbacks(callbacks)
    
    local status = mcp_http_transport.get_status()
    assert_not_nil(status, "status should not be nil")
end

local function test_request_validation()
    mcp_http_transport.init()
    
    -- Test invalid request (nil)
    local response, err = mcp_http_transport.send_request(nil)
    assert_nil(response, "should return nil for nil request")
    assert_equal("invalid_message", err, "should return correct error")
    
    -- Test invalid request (not table)
    local response2, err2 = mcp_http_transport.send_request("invalid")
    assert_nil(response2, "should return nil for non-table request")
    assert_equal("invalid_message", err2, "should return correct error")
    
    -- Test invalid request (missing jsonrpc)
    local response3, err3 = mcp_http_transport.send_request({
        method = "test",
        params = {}
    })
    assert_nil(response3, "should return nil for request without jsonrpc")
    assert_equal("protocol_error", err3, "should return correct error")
    
    -- Test invalid request (wrong jsonrpc version)
    local response4, err4 = mcp_http_transport.send_request({
        jsonrpc = "1.0",
        method = "test",
        params = {}
    })
    assert_nil(response4, "should return nil for wrong jsonrpc version")
    assert_equal("protocol_error", err4, "should return correct error")
    
    -- Test invalid request (missing method)
    local response5, err5 = mcp_http_transport.send_request({
        jsonrpc = "2.0",
        params = {}
    })
    assert_nil(response5, "should return nil for request without method")
    assert_equal("invalid_message", err5, "should return correct error")
end

local function test_notification_validation()
    mcp_http_transport.init()
    
    -- Test invalid notification (nil)
    local success, err = mcp_http_transport.send_notification(nil)
    assert_false(success, "should return false for nil notification")
    assert_equal("invalid_message", err, "should return correct error")
    
    -- Test invalid notification (not table)
    local success2, err2 = mcp_http_transport.send_notification("invalid")
    assert_false(success2, "should return false for non-table notification")
    assert_equal("invalid_message", err2, "should return correct error")
    
    -- Test invalid notification (missing jsonrpc)
    local success3, err3 = mcp_http_transport.send_notification({
        method = "test",
        params = {}
    })
    assert_false(success3, "should return false for notification without jsonrpc")
    assert_equal("protocol_error", err3, "should return correct error")
    
    -- Test invalid notification (wrong jsonrpc version)
    local success4, err4 = mcp_http_transport.send_notification({
        jsonrpc = "1.0",
        method = "test",
        params = {}
    })
    assert_false(success4, "should return false for wrong jsonrpc version")
    assert_equal("protocol_error", err4, "should return correct error")
    
    -- Test invalid notification (missing method)
    local success5, err5 = mcp_http_transport.send_notification({
        jsonrpc = "2.0",
        params = {}
    })
    assert_false(success5, "should return false for notification without method")
    assert_equal("invalid_message", err5, "should return correct error")
    
    -- Test invalid notification (has ID)
    local success6, err6 = mcp_http_transport.send_notification({
        jsonrpc = "2.0",
        id = "123",
        method = "test",
        params = {}
    })
    assert_false(success6, "should return false for notification with ID")
    assert_equal("invalid_message", err6, "should return correct error")
end

local function test_session_initialization_validation()
    -- Test initialization without init
    mcp_http_transport.cleanup() -- Ensure clean state
    
    local client_info = {
        name = "test-client",
        version = "1.0.0",
        capabilities = {}
    }
    
    local success, err = mcp_http_transport.initialize_session(client_info)
    assert_false(success, "should fail when not initialized")
    assert_equal("not_initialized", err, "should return correct error")
end

local function test_status_retrieval()
    mcp_http_transport.init()
    
    local status = mcp_http_transport.get_status()
    assert_table(status, "get_status should return table")
    assert_true(status.is_initialized, "should be initialized")
    assert_false(status.is_connected, "should not be connected initially")
    assert_nil(status.session_id, "session ID should be nil initially")
    assert_nil(status.stream_id, "stream ID should be nil initially")
    assert_equal("2025-06-18", status.protocol_version, "protocol version should be correct")
    assert_equal("http://localhost:3000", status.base_url, "base URL should be correct")
    assert_equal(0, status.message_id_counter, "message ID counter should start at 0")
end

local function test_ready_check()
    mcp_http_transport.init()
    
    assert_false(mcp_http_transport.is_ready(), "should not be ready initially")
end

local function test_session_id_getter()
    mcp_http_transport.init()
    
    assert_nil(mcp_http_transport.get_session_id(), "session ID should be nil initially")
end

local function test_stream_id_getter()
    mcp_http_transport.init()
    
    assert_nil(mcp_http_transport.get_stream_id(), "stream ID should be nil initially")
end

local function test_shutdown_validation()
    -- Test shutdown without init
    mcp_http_transport.cleanup() -- Ensure clean state
    
    local success, err = mcp_http_transport.shutdown()
    assert_false(success, "should fail when not initialized")
    assert_equal("not_initialized", err, "should return correct error")
end

local function test_cleanup()
    mcp_http_transport.init()
    
    -- Verify state is set
    assert_true(mcp_http_transport.get_status().is_initialized, "should be initialized")
    
    -- Clean up
    mcp_http_transport.cleanup()
    
    -- Verify state is reset
    local status = mcp_http_transport.get_status()
    assert_false(status.is_initialized, "should not be initialized after cleanup")
    assert_false(status.is_connected, "should not be connected after cleanup")
    assert_nil(status.session_id, "session ID should be nil after cleanup")
    assert_nil(status.stream_id, "stream ID should be nil after cleanup")
    assert_equal(0, status.message_id_counter, "message ID counter should be reset")
end

-- Run all tests
print("Starting MCP HTTP Transport Tests")
print("=================================")

-- Clean up before running tests
mcp_http_transport.cleanup()

-- Run tests
run_test("Initialization with default config", test_initialization_default_config)
run_test("Initialization with custom config", test_initialization_custom_config)
run_test("Initialization with invalid config", test_initialization_invalid_config)
run_test("Message ID generation", test_message_id_generation)
run_test("Callback setting", test_callback_setting)
run_test("Request validation", test_request_validation)
run_test("Notification validation", test_notification_validation)
run_test("Session initialization validation", test_session_initialization_validation)
run_test("Status retrieval", test_status_retrieval)
run_test("Ready check", test_ready_check)
run_test("Session ID getter", test_session_id_getter)
run_test("Stream ID getter", test_stream_id_getter)
run_test("Shutdown validation", test_shutdown_validation)
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
mcp_http_transport.cleanup()

-- Exit with appropriate code
if test_results.failed > 0 then
    os.exit(1)
else
    os.exit(0)
end
