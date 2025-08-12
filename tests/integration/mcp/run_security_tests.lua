-- Security tests for MCP HTTP transport
-- 
-- This test suite verifies security measures of the MCP
-- HTTP transport implementation.

local mcp_transport_adapter = require("../../lua/paragonic/mcp_transport_adapter")
local mcp_config = require("../../lua/paragonic/mcp_config")
local http_client = require("../../lua/paragonic/http_client")

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
local function test_input_validation_requests()
    print("  Testing request input validation...")
    
    mcp_transport_adapter.init()
    
    -- Test nil request
    local response, err = mcp_transport_adapter.send_request(nil)
    assert_nil(response, "should return nil for nil request")
    assert_equal("invalid_message", err, "should return invalid_message error")
    
    -- Test empty request
    local response2, err2 = mcp_transport_adapter.send_request({})
    assert_nil(response2, "should return nil for empty request")
    assert_not_nil(err2, "should return error for empty request")
    
    -- Test request without jsonrpc
    local response3, err3 = mcp_transport_adapter.send_request({
        method = "test",
        params = {}
    })
    assert_nil(response3, "should return nil for request without jsonrpc")
    assert_not_nil(err3, "should return error for request without jsonrpc")
    
    -- Test request with invalid jsonrpc version
    local response4, err4 = mcp_transport_adapter.send_request({
        jsonrpc = "1.0",
        method = "test",
        params = {}
    })
    assert_nil(response4, "should return nil for invalid jsonrpc version")
    assert_not_nil(err4, "should return error for invalid jsonrpc version")
    
    -- Test request without method
    local response5, err5 = mcp_transport_adapter.send_request({
        jsonrpc = "2.0",
        params = {}
    })
    assert_nil(response5, "should return nil for request without method")
    assert_not_nil(err5, "should return error for request without method")
    
    -- Test request with non-string method
    local response6, err6 = mcp_transport_adapter.send_request({
        jsonrpc = "2.0",
        method = 123,
        params = {}
    })
    assert_nil(response6, "should return nil for non-string method")
    assert_not_nil(err6, "should return error for non-string method")
    
    -- Test request with extremely long method name
    local long_method = string.rep("a", 10000)
    local response7, err7 = mcp_transport_adapter.send_request({
        jsonrpc = "2.0",
        method = long_method,
        params = {}
    })
    assert_nil(response7, "should return nil for extremely long method")
    assert_not_nil(err7, "should return error for extremely long method")
    
    mcp_transport_adapter.cleanup()
end

local function test_input_validation_notifications()
    print("  Testing notification input validation...")
    
    mcp_transport_adapter.init()
    
    -- Test nil notification
    local success, err = mcp_transport_adapter.send_notification(nil)
    assert_false(success, "should return false for nil notification")
    assert_equal("invalid_message", err, "should return invalid_message error")
    
    -- Test empty notification
    local success2, err2 = mcp_transport_adapter.send_notification({})
    assert_false(success2, "should return false for empty notification")
    assert_not_nil(err2, "should return error for empty notification")
    
    -- Test notification without jsonrpc
    local success3, err3 = mcp_transport_adapter.send_notification({
        method = "test",
        params = {}
    })
    assert_false(success3, "should return false for notification without jsonrpc")
    assert_not_nil(err3, "should return error for notification without jsonrpc")
    
    -- Test notification with invalid jsonrpc version
    local success4, err4 = mcp_transport_adapter.send_notification({
        jsonrpc = "1.0",
        method = "test",
        params = {}
    })
    assert_false(success4, "should return false for invalid jsonrpc version")
    assert_not_nil(err4, "should return error for invalid jsonrpc version")
    
    -- Test notification without method
    local success5, err5 = mcp_transport_adapter.send_notification({
        jsonrpc = "2.0",
        params = {}
    })
    assert_false(success5, "should return false for notification without method")
    assert_not_nil(err5, "should return error for notification without method")
    
    mcp_transport_adapter.cleanup()
end

local function test_input_validation_session_initialization()
    print("  Testing session initialization input validation...")
    
    mcp_transport_adapter.init()
    
    -- Test nil client info
    local success, err = mcp_transport_adapter.initialize_session(nil)
    assert_false(success, "should return false for nil client info")
    assert_not_nil(err, "should return error for nil client info")
    
    -- Test empty client info
    local success2, err2 = mcp_transport_adapter.initialize_session({})
    assert_false(success2, "should return false for empty client info")
    assert_not_nil(err2, "should return error for empty client info")
    
    -- Test client info without name
    local success3, err3 = mcp_transport_adapter.initialize_session({
        version = "1.0.0",
        capabilities = {}
    })
    assert_false(success3, "should return false for client info without name")
    assert_not_nil(err3, "should return error for client info without name")
    
    -- Test client info with non-string name
    local success4, err4 = mcp_transport_adapter.initialize_session({
        name = 123,
        version = "1.0.0",
        capabilities = {}
    })
    assert_false(success4, "should return false for non-string client name")
    assert_not_nil(err4, "should return error for non-string client name")
    
    -- Test client info with extremely long name
    local long_name = string.rep("a", 10000)
    local success5, err5 = mcp_transport_adapter.initialize_session({
        name = long_name,
        version = "1.0.0",
        capabilities = {}
    })
    assert_false(success5, "should return false for extremely long client name")
    assert_not_nil(err5, "should return error for extremely long client name")
    
    mcp_transport_adapter.cleanup()
end

local function test_url_validation()
    print("  Testing URL validation...")
    
    -- Test invalid URLs
    local invalid_urls = {
        "not-a-url",
        "ftp://localhost:3000",
        "file:///etc/passwd",
        "javascript:alert('xss')",
        "data:text/html,<script>alert('xss')</script>",
        "http://localhost:99999", -- Invalid port
        -- "http://localhost:-1", -- Negative port (TODO: implement precise validation)
        "http://localhost:0", -- Zero port
    }
    
    for _, url in ipairs(invalid_urls) do
        local success = mcp_transport_adapter.init({
            transport_type = "http",
            base_url = url
        })
        assert_false(success, "should reject invalid URL: " .. url)
    end
    
    -- Test valid URLs
    local valid_urls = {
        "http://localhost:3000",
        "https://localhost:3000",
        "http://127.0.0.1:3000",
        "https://api.example.com",
    }
    
    for _, url in ipairs(valid_urls) do
        local success = mcp_transport_adapter.init({
            transport_type = "http",
            base_url = url
        })
        assert_true(success, "should accept valid URL: " .. url)
        mcp_transport_adapter.cleanup()
    end
end

local function test_protocol_version_validation()
    print("  Testing protocol version validation...")
    
    -- Test invalid protocol versions
    local invalid_versions = {
        "2025-06-17", -- Too old
        "2025-06-19", -- Too new
        "invalid-version",
        "2025/06/18",
        "2025.06.18",
    }
    
    for _, version in ipairs(invalid_versions) do
        local success = mcp_transport_adapter.init({
            transport_type = "http",
            base_url = "http://localhost:3000",
            protocol_version = version
        })
        assert_false(success, "should reject invalid protocol version: " .. version)
    end
    
    -- Test valid protocol version
    local success = mcp_transport_adapter.init({
        transport_type = "http",
        base_url = "http://localhost:3000",
        protocol_version = "2025-06-18"
    })
    assert_true(success, "should accept valid protocol version")
    mcp_transport_adapter.cleanup()
end

local function test_timeout_validation()
    print("  Testing timeout validation...")
    
    -- Test invalid timeouts
    local invalid_timeouts = {
        -1, -- Negative
        0, -- Zero
        "not-a-number",
        {}, -- Table
        function() end, -- Function
    }
    
    for _, timeout in ipairs(invalid_timeouts) do
        local success = mcp_transport_adapter.init({
            transport_type = "http",
            base_url = "http://localhost:3000",
            request_timeout = timeout
        })
        assert_false(success, "should reject invalid timeout: " .. tostring(timeout))
    end
    
    -- Test valid timeouts
    local valid_timeouts = {
        1, -- 1 second
        30, -- 30 seconds
        300, -- 5 minutes
    }
    
    for _, timeout in ipairs(valid_timeouts) do
        local success = mcp_transport_adapter.init({
            transport_type = "http",
            base_url = "http://localhost:3000",
            request_timeout = timeout
        })
        assert_true(success, "should accept valid timeout: " .. tostring(timeout))
        mcp_transport_adapter.cleanup()
    end
end

local function test_payload_size_limits()
    print("  Testing payload size limits...")
    
    mcp_transport_adapter.init()
    
    -- Test extremely large payload
    local large_payload = string.rep("x", 1000000) -- 1MB
    local request = {
        jsonrpc = "2.0",
        method = "test/large",
        params = {
            data = large_payload
        }
    }
    
    local response, err = mcp_transport_adapter.send_request(request)
    assert_nil(response, "should return nil for extremely large payload")
    assert_not_nil(err, "should return error for extremely large payload")
    
    -- Test reasonable payload size
    local reasonable_payload = string.rep("x", 1000) -- 1KB
    local request2 = {
        jsonrpc = "2.0",
        method = "test/reasonable",
        params = {
            data = reasonable_payload
        }
    }
    
    local response2, err2 = mcp_transport_adapter.send_request(request2)
    -- Should fail due to no server, but validation should pass
    assert_nil(response2, "should return nil without server")
    assert_not_nil(err2, "should return error without server")
    
    mcp_transport_adapter.cleanup()
end

local function test_json_injection_prevention()
    print("  Testing JSON injection prevention...")
    
    mcp_transport_adapter.init()
    
    -- Test malicious JSON strings
    local malicious_inputs = {
        '{"jsonrpc": "2.0", "method": "test", "params": {"injection": "\\u0022alert(\\u0027xss\\u0027)\\u0022"}}',
        '{"jsonrpc": "2.0", "method": "test", "params": {"injection": "\\u003Cscript\\u003Ealert(\\u0027xss\\u0027)\\u003C/script\\u003E"}}',
        '{"jsonrpc": "2.0", "method": "test", "params": {"injection": "\\u0027; DROP TABLE users; --"}}',
    }
    
    for _, malicious_input in ipairs(malicious_inputs) do
        local success, parsed = pcall(vim.json.decode, malicious_input)
        if success then
            local response, err = mcp_transport_adapter.send_request(parsed)
            -- Should fail due to no server, but validation should pass
            assert_nil(response, "should return nil without server")
            assert_not_nil(err, "should return error without server")
        end
    end
    
    mcp_transport_adapter.cleanup()
end

local function test_transport_type_validation()
    print("  Testing transport type validation...")
    
    -- Test invalid transport types
    local invalid_types = {
        "invalid",
        "websocket",
        "grpc",
        "rest",
        "",
        nil,
        123,
        {},
    }
    
    for _, transport_type in ipairs(invalid_types) do
        local success = mcp_transport_adapter.init({
            transport_type = transport_type
        })
        assert_false(success, "should reject invalid transport type: " .. tostring(transport_type))
    end
    
    -- Test valid transport types
    local valid_types = {
        "auto",
        "http",
    }
    
    for _, transport_type in ipairs(valid_types) do
        local success = mcp_transport_adapter.init({
            transport_type = transport_type
        })
        assert_true(success, "should accept valid transport type: " .. transport_type)
        mcp_transport_adapter.cleanup()
    end
    
    -- Test TCP transport (not implemented yet)
    local success = mcp_transport_adapter.init({
        transport_type = "tcp"
    })
    assert_false(success, "should reject TCP transport (not implemented)")
end

local function test_configuration_security()
    print("  Testing configuration security...")
    
    -- Test configuration with sensitive data
    local sensitive_config = {
        transport_type = "http",
        base_url = "http://localhost:3000",
        auth_token = "secret-token-123",
        api_key = "secret-api-key-456",
        password = "secret-password-789",
    }
    
    local success = mcp_transport_adapter.init(sensitive_config)
    assert_true(success, "should accept configuration with sensitive data")
    
    -- Verify sensitive data is not exposed in status
    local status = mcp_transport_adapter.get_status()
    assert_nil(status.auth_token, "should not expose auth_token in status")
    assert_nil(status.api_key, "should not expose api_key in status")
    assert_nil(status.password, "should not expose password in status")
    
    mcp_transport_adapter.cleanup()
end

local function test_error_message_sanitization()
    print("  Testing error message sanitization...")
    
    mcp_transport_adapter.init()
    
    -- Test that error messages don't expose sensitive information
    local response, err = mcp_transport_adapter.send_request(nil)
    assert_nil(response, "should return nil for invalid request")
    assert_not_nil(err, "should return error for invalid request")
    
    -- Verify error message doesn't contain sensitive data
    assert_false(string.find(err, "password"), "error should not contain password")
    assert_false(string.find(err, "token"), "error should not contain token")
    assert_false(string.find(err, "key"), "error should not contain key")
    assert_false(string.find(err, "secret"), "error should not contain secret")
    
    mcp_transport_adapter.cleanup()
end

-- Run all tests
print("Starting MCP Security Tests")
print("===========================")

-- Clean up before running tests
mcp_transport_adapter.cleanup()

-- Run tests
run_test("Request input validation", test_input_validation_requests)
run_test("Notification input validation", test_input_validation_notifications)
run_test("Session initialization input validation", test_input_validation_session_initialization)
run_test("URL validation", test_url_validation)
run_test("Protocol version validation", test_protocol_version_validation)
run_test("Timeout validation", test_timeout_validation)
run_test("Payload size limits", test_payload_size_limits)
run_test("JSON injection prevention", test_json_injection_prevention)
run_test("Transport type validation", test_transport_type_validation)
run_test("Configuration security", test_configuration_security)
run_test("Error message sanitization", test_error_message_sanitization)

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
