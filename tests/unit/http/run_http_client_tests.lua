-- Simple test runner for HTTP client tests
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
local function test_initialization_default_config()
    local success = http_client.init()
    assert_true(success, "init should return true")
    
    local request = http_client.build_request("GET", "/test")
    assert_equal("http://localhost:3000/test", request.url, "default URL should be correct")
end

local function test_initialization_custom_config()
    local config = {
        base_url = "http://test-server:8080",
        timeout = 60,
        retry_attempts = 5,
        retry_delay = 2,
        headers = {
            ["X-Custom-Header"] = "test-value"
        }
    }
    
    local success = http_client.init(config)
    assert_true(success, "init should return true")
    
    local request = http_client.build_request("GET", "/test")
    assert_equal("http://test-server:8080/test", request.url, "custom URL should be set")
    assert_equal("test-value", request.headers["X-Custom-Header"], "custom header should be set")
end

local function test_initialization_invalid_config()
    local success = http_client.init("invalid")
    assert_true(success, "init should handle invalid config gracefully")
end

local function test_session_management()
    http_client.init()
    
    local session_id = "test-session-123"
    local success, err = http_client.set_session_id(session_id)
    assert_true(success, "set_session_id should succeed")
    assert_nil(err, "set_session_id should not return error")
    
    assert_equal(session_id, http_client.get_session_id(), "get_session_id should return set session")
end

local function test_session_management_invalid()
    http_client.init()
    
    local success, err = http_client.set_session_id(nil)
    assert_false(success, "set_session_id should fail with nil")
    assert_equal("Invalid session ID", err, "should return correct error message")
    
    local success2, err2 = http_client.set_session_id(123)
    assert_false(success2, "set_session_id should fail with number")
    assert_equal("Invalid session ID", err2, "should return correct error message")
end

local function test_session_in_requests()
    http_client.init()
    http_client.set_session_id("test-session")
    
    local request = http_client.build_request("GET", "/test")
    assert_equal("test-session", request.headers["Mcp-Session-Id"], "session ID should be in headers")
end

local function test_request_building_get()
    http_client.init()
    
    local request, err = http_client.build_request("GET", "/test")
    assert_nil(err, "build_request should not return error")
    assert_equal("GET", request.method, "method should be GET")
    assert_equal("http://localhost:3000/test", request.url, "URL should be correct")
    assert_nil(request.data, "GET request should not have data")
end

local function test_request_building_post()
    http_client.init()
    
    local data = {key = "value", number = 123}
    local request, err = http_client.build_request("POST", "/test", data)
    assert_nil(err, "build_request should not return error")
    assert_equal("POST", request.method, "method should be POST")
    assert_equal("http://localhost:3000/test", request.url, "URL should be correct")
    assert_not_nil(request.data, "POST request should have data")
    assert_string(request.data, "data should be string")
end

local function test_request_building_url_construction()
    -- Test with trailing slash in base URL
    http_client.init({base_url = "http://localhost:3000/"})
    local request = http_client.build_request("GET", "test")
    assert_equal("http://localhost:3000/test", request.url, "URL should be correct with trailing slash")
    
    -- Test with leading slash in endpoint
    local request2 = http_client.build_request("GET", "/test")
    assert_equal("http://localhost:3000/test", request2.url, "URL should be correct with leading slash")
end

local function test_request_building_custom_headers()
    http_client.init()
    
    local custom_headers = {
        ["X-Test-Header"] = "test-value",
        ["Authorization"] = "Bearer token123"
    }
    
    local request = http_client.build_request("GET", "/test", nil, custom_headers)
    assert_equal("test-value", request.headers["X-Test-Header"], "custom header should be included")
    assert_equal("Bearer token123", request.headers["Authorization"], "authorization header should be included")
end

local function test_request_building_invalid_method()
    http_client.init()
    
    local request, err = http_client.build_request(nil, "/test")
    assert_nil(request, "build_request should return nil for invalid method")
    assert_equal("Invalid HTTP method", err, "should return correct error message")
end

local function test_request_building_invalid_endpoint()
    http_client.init()
    
    local request, err = http_client.build_request("GET", nil)
    assert_nil(request, "build_request should return nil for invalid endpoint")
    assert_equal("Invalid endpoint", err, "should return correct error message")
end

local function test_response_handling_success()
    local success_response = {status_code = 200}
    local created_response = {status_code = 201}
    local no_content_response = {status_code = 204}
    
    assert_true(http_client.is_success(success_response), "200 should be success")
    assert_true(http_client.is_success(created_response), "201 should be success")
    assert_true(http_client.is_success(no_content_response), "204 should be success")
end

local function test_response_handling_client_errors()
    local bad_request = {status_code = 400}
    local unauthorized = {status_code = 401}
    local not_found = {status_code = 404}
    
    assert_true(http_client.is_client_error(bad_request), "400 should be client error")
    assert_true(http_client.is_client_error(unauthorized), "401 should be client error")
    assert_true(http_client.is_client_error(not_found), "404 should be client error")
end

local function test_response_handling_server_errors()
    local internal_error = {status_code = 500}
    local bad_gateway = {status_code = 502}
    local service_unavailable = {status_code = 503}
    
    assert_true(http_client.is_server_error(internal_error), "500 should be server error")
    assert_true(http_client.is_server_error(bad_gateway), "502 should be server error")
    assert_true(http_client.is_server_error(service_unavailable), "503 should be server error")
end

local function test_response_handling_error_messages()
    local response_with_error = {
        status_code = 400,
        body = {error = "Bad request"}
    }
    
    local response_without_error = {
        status_code = 500
    }
    
    local no_response = nil
    
    assert_equal("Bad request", http_client.get_error_message(response_with_error), "should extract error from body")
    assert_equal("HTTP 500", http_client.get_error_message(response_without_error), "should format status code")
    assert_equal("No response received", http_client.get_error_message(no_response), "should handle nil response")
end

local function test_http_methods()
    http_client.init()
    
    -- These should fail in test environment (no server), but the methods should exist
    local response, err = http_client.post("/test", {test = "data"})
    assert_nil(response, "POST should fail without server")
    assert_not_nil(err, "POST should return error without server")
    
    local response2, err2 = http_client.get("/test")
    assert_nil(response2, "GET should fail without server")
    assert_not_nil(err2, "GET should return error without server")
    
    local response3, err3 = http_client.delete("/test")
    assert_nil(response3, "DELETE should fail without server")
    assert_not_nil(err3, "DELETE should return error without server")
end

local function test_error_handling_connection_failure()
    http_client.init({base_url = "http://invalid-server:9999"})
    local response, err = http_client.get("/test")
    
    assert_nil(response, "should fail with invalid server")
    assert_not_nil(err, "should return error with invalid server")
end

local function test_error_handling_timeout()
    http_client.init({timeout = 1})
    local response, err = http_client.get("/test")
    
    assert_nil(response, "should fail with timeout")
    assert_not_nil(err, "should return error with timeout")
end

local function test_cleanup()
    http_client.init()
    http_client.set_session_id("test-session")
    
    -- Verify state is set
    assert_not_nil(http_client.get_session_id(), "session ID should be set")
    
    -- Clean up
    http_client.cleanup()
    
    -- Verify state is reset
    assert_nil(http_client.get_session_id(), "session ID should be cleared after cleanup")
end

-- Run all tests
print("Starting HTTP Client Tests")
print("=========================")

-- Clean up before running tests
http_client.cleanup()
vim.fn.delete("/tmp/paragonic_response")

-- Run tests
run_test("Initialization with default config", test_initialization_default_config)
run_test("Initialization with custom config", test_initialization_custom_config)
run_test("Initialization with invalid config", test_initialization_invalid_config)
run_test("Session management", test_session_management)
run_test("Session management invalid", test_session_management_invalid)
run_test("Session in requests", test_session_in_requests)
run_test("Request building GET", test_request_building_get)
run_test("Request building POST", test_request_building_post)
run_test("Request building URL construction", test_request_building_url_construction)
run_test("Request building custom headers", test_request_building_custom_headers)
run_test("Request building invalid method", test_request_building_invalid_method)
run_test("Request building invalid endpoint", test_request_building_invalid_endpoint)
run_test("Response handling success", test_response_handling_success)
run_test("Response handling client errors", test_response_handling_client_errors)
run_test("Response handling server errors", test_response_handling_server_errors)
run_test("Response handling error messages", test_response_handling_error_messages)
run_test("HTTP methods", test_http_methods)
run_test("Error handling connection failure", test_error_handling_connection_failure)
run_test("Error handling timeout", test_error_handling_timeout)
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
http_client.cleanup()
vim.fn.delete("/tmp/paragonic_response")

-- Exit with appropriate code
if test_results.failed > 0 then
    os.exit(1)
else
    os.exit(0)
end
