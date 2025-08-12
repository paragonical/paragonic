-- HTTP Connection Pooling Test Runner
-- 
-- This script runs all HTTP connection pooling tests to verify
-- the implementation of task 9.5.

local test_log = function(message)
    print(string.format("[HTTP Connection Pooling Test Runner] %s", message))
end

local function run_all_connection_pooling_tests()
    test_log("Starting HTTP Connection Pooling Test Suite")
    test_log("===========================================")
    
    local total_tests = 0
    local total_passed = 0
    local total_failed = 0
    
    -- Test 1: Basic connection pooling functionality
    test_log("Running basic connection pooling tests...")
    local basic_tests = dofile("tests/unit/http/test_http_client_connection_pooling.lua")
    local basic_result = basic_tests.run_all_tests()
    
    if basic_result then
        test_log("✓ Basic connection pooling tests passed")
        total_passed = total_passed + 1
    else
        test_log("✗ Basic connection pooling tests failed")
        total_failed = total_failed + 1
    end
    total_tests = total_tests + 1
    
    -- Test 2: Integration tests
    test_log("Running connection pooling integration tests...")
    local integration_tests = dofile("tests/unit/http/test_http_client_pooling_integration.lua")
    local integration_result = integration_tests.run_all_tests()
    
    if integration_result then
        test_log("✓ Connection pooling integration tests passed")
        total_passed = total_passed + 1
    else
        test_log("✗ Connection pooling integration tests failed")
        total_failed = total_failed + 1
    end
    total_tests = total_tests + 1
    
    -- Print final summary
    test_log("===========================================")
    test_log(string.format("Final Test Summary: %d test suites, %d passed, %d failed", 
        total_tests, total_passed, total_failed))
    
    if total_failed == 0 then
        test_log("🎉 All HTTP Connection Pooling tests passed!")
        test_log("✅ Task 9.5: Connection pooling and optimization implementation complete")
        return true
    else
        test_log("❌ Some HTTP Connection Pooling tests failed!")
        return false
    end
end

-- Run tests if this script is executed directly
if arg and arg[0] and arg[0]:match("run_http_connection_pooling_tests.lua$") then
    run_all_connection_pooling_tests()
end

return {
    run_all_connection_pooling_tests = run_all_connection_pooling_tests,
}
