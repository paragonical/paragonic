-- Test Memory Usage and Resource Cleanup for MCP HTTP Transport
-- Task 9.4 of MCP Streamable HTTP Refit spec

-- Check if we're running in Neovim environment
local is_neovim = pcall(function() return vim ~= nil end)

-- Load modules with error handling
local mcp_http_transport, http_client, sse_client, mcp_performance

if is_neovim then
    mcp_http_transport = require("paragonic.mcp_http_transport")
    http_client = require("paragonic.http_client")
    sse_client = require("paragonic.sse_client")
    mcp_performance = require("paragonic.mcp_performance")
else
    -- Create mock modules for standalone testing
    mcp_http_transport = {
        init = function() return true end,
        cleanup = function() return true end,
        send_request = function() return nil, "mock_error" end,
        get_status = function() return {is_initialized = false, is_connected = false} end
    }
    http_client = {
        init = function() return true end,
        cleanup = function() return true end,
        post = function() return nil, "mock_error" end
    }
    sse_client = {
        init = function() return true end,
        cleanup = function() return true end,
        _handle_event = function() return true end
    }
    mcp_performance = {
        init = function() return true end,
        cleanup = function() return true end,
        record_metric = function() return true end,
        record_operation_time = function() return true end
    }
end

-- Test state
local test_results = {
    passed = 0,
    failed = 0,
    errors = {}
}

-- Helper function to run a test
local function run_test(name, test_func)
    print("  Testing: " .. name)
    local success, err = pcall(test_func)
    if success then
        print("    ✓ " .. name .. " passed")
        test_results.passed = test_results.passed + 1
    else
        print("    ✗ " .. name .. " failed: " .. tostring(err))
        test_results.failed = test_results.failed + 1
        table.insert(test_results.errors, {name = name, error = tostring(err)})
    end
end

-- Helper function to measure memory usage
local function measure_memory_usage()
    -- Try Neovim API first
    local success, info = pcall(function()
        if vim and vim.loop and vim.loop.getrusage then
            return vim.loop.getrusage()
        end
        return nil
    end)
    
    if success and info and info.ru_maxrss then
        return info.ru_maxrss -- Resident set size in KB
    else
        -- Fallback: use collectgarbage for Lua memory
        collectgarbage("collect")
        return collectgarbage("count") -- Memory usage in KB
    end
end

-- Helper function to measure time
local function measure_time(func)
    local start_time
    local success = pcall(function()
        if vim and vim.loop and vim.loop.hrtime then
            start_time = vim.loop.hrtime() / 1000000
        else
            start_time = os.clock() * 1000
        end
    end)
    
    if not success then
        start_time = os.clock() * 1000
    end
    
    func()
    
    local end_time
    success = pcall(function()
        if vim and vim.loop and vim.loop.hrtime then
            end_time = vim.loop.hrtime() / 1000000
        else
            end_time = os.clock() * 1000
        end
    end)
    
    if not success then
        end_time = os.clock() * 1000
    end
    
    return end_time - start_time
end

-- Helper function to create test data
local function create_test_data(size_kb)
    local data = {}
    for i = 1, size_kb do
        table.insert(data, string.rep("x", 1024)) -- 1KB per entry
    end
    return table.concat(data)
end

-- Test 1: Memory usage during initialization
local function test_memory_usage_initialization()
    local initial_memory = measure_memory_usage()
    
    -- Initialize MCP HTTP transport
    mcp_http_transport.init()
    
    local after_init_memory = measure_memory_usage()
    local init_memory_increase = after_init_memory - initial_memory
    
    print(string.format("    Memory before init: %d KB", initial_memory))
    print(string.format("    Memory after init: %d KB", after_init_memory))
    print(string.format("    Memory increase: %d KB", init_memory_increase))
    
    -- Clean up
    mcp_http_transport.cleanup()
    
    local after_cleanup_memory = measure_memory_usage()
    local cleanup_memory_decrease = after_init_memory - after_cleanup_memory
    
    print(string.format("    Memory after cleanup: %d KB", after_cleanup_memory))
    print(string.format("    Memory decrease: %d KB", cleanup_memory_decrease))
    
    -- Assertions
    assert_true(init_memory_increase < 5000, "Initialization should use less than 5MB")
    assert_true(cleanup_memory_decrease > 0, "Cleanup should reduce memory usage")
    assert_true(after_cleanup_memory <= initial_memory + 100, "Memory should return to near initial state")
end

-- Test 2: Memory usage during multiple request cycles
local function test_memory_usage_request_cycles()
    local initial_memory = measure_memory_usage()
    
    mcp_http_transport.init()
    
    local cycle_memory_usage = {}
    
    -- Run multiple request cycles
    for cycle = 1, 10 do
        local cycle_start_memory = measure_memory_usage()
        
        -- Simulate multiple requests
        for i = 1, 5 do
            local request = {
                jsonrpc = "2.0",
                method = "test/memory_cycle",
                params = { cycle = cycle, request = i, data = create_test_data(1) }
            }
            
            local response, err = mcp_http_transport.send_request(request)
            -- Expected to fail without server, but we're measuring memory
        end
        
        local cycle_end_memory = measure_memory_usage()
        table.insert(cycle_memory_usage, cycle_end_memory - cycle_start_memory)
        
        print(string.format("    Cycle %d memory change: %d KB", cycle, cycle_end_memory - cycle_start_memory))
    end
    
    local final_memory = measure_memory_usage()
    local total_memory_increase = final_memory - initial_memory
    
    print(string.format("    Total memory increase: %d KB", total_memory_increase))
    
    -- Calculate average memory change per cycle
    local total_cycle_change = 0
    for _, change in ipairs(cycle_memory_usage) do
        total_cycle_change = total_cycle_change + change
    end
    local avg_cycle_change = total_cycle_change / #cycle_memory_usage
    
    print(string.format("    Average memory change per cycle: %d KB", avg_cycle_change))
    
    -- Clean up
    mcp_http_transport.cleanup()
    
    local after_cleanup_memory = measure_memory_usage()
    local cleanup_memory_decrease = final_memory - after_cleanup_memory
    
    print(string.format("    Memory after cleanup: %d KB", after_cleanup_memory))
    print(string.format("    Memory decrease after cleanup: %d KB", cleanup_memory_decrease))
    
    -- Assertions
    assert_true(total_memory_increase < 10000, "Total memory increase should be less than 10MB")
    assert_true(avg_cycle_change < 1000, "Average memory change per cycle should be less than 1MB")
    assert_true(cleanup_memory_decrease > 0, "Cleanup should reduce memory usage")
end

-- Test 3: Memory usage with large data payloads
local function test_memory_usage_large_payloads()
    local initial_memory = measure_memory_usage()
    
    mcp_http_transport.init()
    
    local payload_sizes = {1, 10, 50, 100} -- KB
    local memory_usage_by_size = {}
    
    for _, size_kb in ipairs(payload_sizes) do
        local before_memory = measure_memory_usage()
        
        -- Create large payload
        local large_data = create_test_data(size_kb)
        
        -- Simulate request with large payload
        local request = {
            jsonrpc = "2.0",
            method = "test/large_payload",
            params = { data = large_data, size_kb = size_kb }
        }
        
        local response, err = mcp_http_transport.send_request(request)
        
        local after_memory = measure_memory_usage()
        local memory_change = after_memory - before_memory
        
        memory_usage_by_size[size_kb] = memory_change
        
        print(string.format("    %d KB payload memory change: %d KB", size_kb, memory_change))
        
        -- Clear the large data
        large_data = nil
        collectgarbage("collect")
    end
    
    local final_memory = measure_memory_usage()
    local total_memory_increase = final_memory - initial_memory
    
    print(string.format("    Total memory increase: %d KB", total_memory_increase))
    
    -- Clean up
    mcp_http_transport.cleanup()
    
    local after_cleanup_memory = measure_memory_usage()
    local cleanup_memory_decrease = final_memory - after_cleanup_memory
    
    print(string.format("    Memory after cleanup: %d KB", after_cleanup_memory))
    print(string.format("    Memory decrease after cleanup: %d KB", cleanup_memory_decrease))
    
    -- Assertions
    assert_true(total_memory_increase < 15000, "Total memory increase should be less than 15MB")
    assert_true(cleanup_memory_decrease > 0, "Cleanup should reduce memory usage")
    
    -- Check that memory usage scales reasonably with payload size
    for size_kb, memory_change in pairs(memory_usage_by_size) do
        assert_true(memory_change < size_kb * 2, string.format("Memory change for %d KB payload should be less than %d KB", size_kb, size_kb * 2))
    end
end

-- Test 4: Resource cleanup during session management
local function test_resource_cleanup_session_management()
    local initial_memory = measure_memory_usage()
    
    -- Test multiple session initializations and cleanups
    for session = 1, 5 do
        print(string.format("    Testing session %d", session))
        
        local session_start_memory = measure_memory_usage()
        
        mcp_http_transport.init()
        
        -- Simulate session activity
        for i = 1, 3 do
            local request = {
                jsonrpc = "2.0",
                method = "test/session_activity",
                params = { session = session, activity = i }
            }
            
            local response, err = mcp_http_transport.send_request(request)
        end
        
        local session_end_memory = measure_memory_usage()
        local session_memory_increase = session_end_memory - session_start_memory
        
        print(string.format("      Session %d memory increase: %d KB", session, session_memory_increase))
        
        -- Clean up session
        mcp_http_transport.cleanup()
        
        local after_cleanup_memory = measure_memory_usage()
        local cleanup_memory_decrease = session_end_memory - after_cleanup_memory
        
        print(string.format("      Session %d cleanup decrease: %d KB", session, cleanup_memory_decrease))
        
        -- Assertions for each session
        assert_true(session_memory_increase < 2000, string.format("Session %d memory increase should be less than 2MB", session))
        assert_true(cleanup_memory_decrease > 0, string.format("Session %d cleanup should reduce memory", session))
    end
    
    local final_memory = measure_memory_usage()
    local total_memory_increase = final_memory - initial_memory
    
    print(string.format("    Total memory increase across all sessions: %d KB", total_memory_increase))
    
    -- Assertions
    assert_true(total_memory_increase < 1000, "Total memory increase should be minimal after all sessions")
end

-- Test 5: Memory usage during concurrent operations
local function test_memory_usage_concurrent_operations()
    local initial_memory = measure_memory_usage()
    
    mcp_http_transport.init()
    
    local concurrent_operations = 10
    local operation_memory_changes = {}
    
    -- Simulate concurrent operations
    for op = 1, concurrent_operations do
        local op_start_memory = measure_memory_usage()
        
        -- Simulate concurrent request
        local request = {
            jsonrpc = "2.0",
            method = "test/concurrent_operation",
            params = { operation = op, data = create_test_data(5) }
        }
        
        local response, err = mcp_http_transport.send_request(request)
        
        local op_end_memory = measure_memory_usage()
        local op_memory_change = op_end_memory - op_start_memory
        
        table.insert(operation_memory_changes, op_memory_change)
        
        print(string.format("    Operation %d memory change: %d KB", op, op_memory_change))
    end
    
    local final_memory = measure_memory_usage()
    local total_memory_increase = final_memory - initial_memory
    
    print(string.format("    Total memory increase: %d KB", total_memory_increase))
    
    -- Calculate statistics
    local total_change = 0
    local max_change = 0
    for _, change in ipairs(operation_memory_changes) do
        total_change = total_change + change
        if change > max_change then
            max_change = change
        end
    end
    local avg_change = total_change / #operation_memory_changes
    
    print(string.format("    Average memory change per operation: %d KB", avg_change))
    print(string.format("    Maximum memory change: %d KB", max_change))
    
    -- Clean up
    mcp_http_transport.cleanup()
    
    local after_cleanup_memory = measure_memory_usage()
    local cleanup_memory_decrease = final_memory - after_cleanup_memory
    
    print(string.format("    Memory after cleanup: %d KB", after_cleanup_memory))
    print(string.format("    Memory decrease after cleanup: %d KB", cleanup_memory_decrease))
    
    -- Assertions
    assert_true(total_memory_increase < 8000, "Total memory increase should be less than 8MB")
    assert_true(avg_change < 1000, "Average memory change per operation should be less than 1MB")
    assert_true(max_change < 2000, "Maximum memory change should be less than 2MB")
    assert_true(cleanup_memory_decrease > 0, "Cleanup should reduce memory usage")
end

-- Test 6: Memory leak detection over time
local function test_memory_leak_detection()
    local initial_memory = measure_memory_usage()
    local memory_readings = {}
    
    -- Run operations over time to detect memory leaks
    for iteration = 1, 20 do
        local iteration_start_memory = measure_memory_usage()
        
        mcp_http_transport.init()
        
        -- Simulate typical usage pattern
        for i = 1, 3 do
            local request = {
                jsonrpc = "2.0",
                method = "test/memory_leak_detection",
                params = { iteration = iteration, request = i, data = create_test_data(2) }
            }
            
            local response, err = mcp_http_transport.send_request(request)
        end
        
        mcp_http_transport.cleanup()
        
        local iteration_end_memory = measure_memory_usage()
        local iteration_memory_change = iteration_end_memory - iteration_start_memory
        
        table.insert(memory_readings, iteration_end_memory)
        
        if iteration % 5 == 0 then
            print(string.format("    Iteration %d memory: %d KB (change: %d KB)", 
                iteration, iteration_end_memory, iteration_memory_change))
        end
    end
    
    local final_memory = measure_memory_usage()
    local total_memory_increase = final_memory - initial_memory
    
    print(string.format("    Total memory increase over 20 iterations: %d KB", total_memory_increase))
    
    -- Analyze memory trend
    local first_quarter = memory_readings[5] or memory_readings[#memory_readings]
    local last_quarter = memory_readings[#memory_readings]
    local trend_change = last_quarter - first_quarter
    
    print(string.format("    Memory trend change (first 5 to last): %d KB", trend_change))
    
    -- Assertions
    assert_true(total_memory_increase < 2000, "Total memory increase should be less than 2MB over 20 iterations")
    assert_true(trend_change < 1000, "Memory trend should not show significant growth")
    assert_true(final_memory <= initial_memory + 1000, "Final memory should be close to initial")
end

-- Test 7: HTTP client memory usage
local function test_http_client_memory_usage()
    local initial_memory = measure_memory_usage()
    
    http_client.init()
    
    local client_memory_usage = {}
    
    -- Test HTTP client operations
    for i = 1, 10 do
        local before_memory = measure_memory_usage()
        
        -- Simulate HTTP request
        local request = {
            method = "POST",
            endpoint = "/test",
            headers = { ["Content-Type"] = "application/json" },
            body = create_test_data(1)
        }
        
        local response, err = http_client.post("/test", request.headers, request.body)
        
        local after_memory = measure_memory_usage()
        local memory_change = after_memory - before_memory
        
        table.insert(client_memory_usage, memory_change)
        
        if i % 3 == 0 then
            print(string.format("    HTTP request %d memory change: %d KB", i, memory_change))
        end
    end
    
    local final_memory = measure_memory_usage()
    local total_memory_increase = final_memory - initial_memory
    
    print(string.format("    Total HTTP client memory increase: %d KB", total_memory_increase))
    
    -- Clean up
    http_client.cleanup()
    
    local after_cleanup_memory = measure_memory_usage()
    local cleanup_memory_decrease = final_memory - after_cleanup_memory
    
    print(string.format("    Memory after HTTP client cleanup: %d KB", after_cleanup_memory))
    print(string.format("    Memory decrease after cleanup: %d KB", cleanup_memory_decrease))
    
    -- Assertions
    assert_true(total_memory_increase < 3000, "HTTP client memory increase should be less than 3MB")
    assert_true(cleanup_memory_decrease > 0, "HTTP client cleanup should reduce memory usage")
end

-- Test 8: SSE client memory usage
local function test_sse_client_memory_usage()
    local initial_memory = measure_memory_usage()
    
    sse_client.init("http://localhost:3000")
    
    local sse_memory_usage = {}
    
    -- Test SSE client operations
    for i = 1, 10 do
        local before_memory = measure_memory_usage()
        
        -- Simulate SSE connection and event processing
        local event_data = {
            id = tostring(i),
            event = "test_event",
            data = create_test_data(1)
        }
        
        -- Simulate event processing (without actual connection)
        local success, err = pcall(function()
            sse_client._handle_event(event_data)
        end)
        
        local after_memory = measure_memory_usage()
        local memory_change = after_memory - before_memory
        
        table.insert(sse_memory_usage, memory_change)
        
        if i % 3 == 0 then
            print(string.format("    SSE event %d memory change: %d KB", i, memory_change))
        end
    end
    
    local final_memory = measure_memory_usage()
    local total_memory_increase = final_memory - initial_memory
    
    print(string.format("    Total SSE client memory increase: %d KB", total_memory_increase))
    
    -- Clean up
    sse_client.cleanup()
    
    local after_cleanup_memory = measure_memory_usage()
    local cleanup_memory_decrease = final_memory - after_cleanup_memory
    
    print(string.format("    Memory after SSE client cleanup: %d KB", after_cleanup_memory))
    print(string.format("    Memory decrease after cleanup: %d KB", cleanup_memory_decrease))
    
    -- Assertions
    assert_true(total_memory_increase < 2000, "SSE client memory increase should be less than 2MB")
    assert_true(cleanup_memory_decrease > 0, "SSE client cleanup should reduce memory usage")
end

-- Test 9: Performance monitoring memory usage
local function test_performance_monitoring_memory_usage()
    local initial_memory = measure_memory_usage()
    
    mcp_performance.init()
    
    local perf_memory_usage = {}
    
    -- Test performance monitoring operations
    for i = 1, 50 do
        local before_memory = measure_memory_usage()
        
        -- Record performance metrics
        mcp_performance.record_metric("test_metric", i * 10)
        mcp_performance.record_operation_time("test_operation", i * 0.1)
        
        local after_memory = measure_memory_usage()
        local memory_change = after_memory - before_memory
        
        table.insert(perf_memory_usage, memory_change)
        
        if i % 10 == 0 then
            print(string.format("    Performance metric %d memory change: %d KB", i, memory_change))
        end
    end
    
    local final_memory = measure_memory_usage()
    local total_memory_increase = final_memory - initial_memory
    
    print(string.format("    Total performance monitoring memory increase: %d KB", total_memory_increase))
    
    -- Clean up
    mcp_performance.cleanup()
    
    local after_cleanup_memory = measure_memory_usage()
    local cleanup_memory_decrease = final_memory - after_cleanup_memory
    
    print(string.format("    Memory after performance cleanup: %d KB", after_cleanup_memory))
    print(string.format("    Memory decrease after cleanup: %d KB", cleanup_memory_decrease))
    
    -- Assertions
    assert_true(total_memory_increase < 1000, "Performance monitoring memory increase should be less than 1MB")
    assert_true(cleanup_memory_decrease > 0, "Performance monitoring cleanup should reduce memory usage")
end

-- Test 10: Comprehensive resource cleanup verification
local function test_comprehensive_resource_cleanup()
    local initial_memory = measure_memory_usage()
    
    print("    Testing comprehensive resource cleanup...")
    
    -- Initialize all components
    mcp_http_transport.init()
    http_client.init()
    sse_client.init("http://localhost:3000")
    mcp_performance.init()
    
    local after_init_memory = measure_memory_usage()
    local init_memory_increase = after_init_memory - initial_memory
    
    print(string.format("    Memory after all initializations: %d KB (increase: %d KB)", 
        after_init_memory, init_memory_increase))
    
    -- Simulate heavy usage
    for i = 1, 20 do
        -- MCP transport operations
        local request = {
            jsonrpc = "2.0",
            method = "test/comprehensive",
            params = { iteration = i, data = create_test_data(2) }
        }
        local response, err = mcp_http_transport.send_request(request)
        
        -- HTTP client operations
        local http_response, http_err = http_client.post("/test", {}, create_test_data(1))
        
        -- SSE client operations
        local sse_success, sse_err = pcall(function()
            sse_client._handle_event({id = tostring(i), data = create_test_data(1)})
        end)
        
        -- Performance monitoring
        mcp_performance.record_metric("comprehensive_test", i)
        mcp_performance.record_operation_time("comprehensive_operation", i * 0.05)
    end
    
    local after_usage_memory = measure_memory_usage()
    local usage_memory_increase = after_usage_memory - after_init_memory
    
    print(string.format("    Memory after heavy usage: %d KB (increase: %d KB)", 
        after_usage_memory, usage_memory_increase))
    
    -- Clean up all components
    mcp_http_transport.cleanup()
    http_client.cleanup()
    sse_client.cleanup()
    mcp_performance.cleanup()
    
    local after_cleanup_memory = measure_memory_usage()
    local total_cleanup_decrease = after_usage_memory - after_cleanup_memory
    local final_memory_increase = after_cleanup_memory - initial_memory
    
    print(string.format("    Memory after comprehensive cleanup: %d KB", after_cleanup_memory))
    print(string.format("    Total cleanup decrease: %d KB", total_cleanup_decrease))
    print(string.format("    Final memory increase: %d KB", final_memory_increase))
    
    -- Assertions
    assert_true(init_memory_increase < 8000, "Initialization should use less than 8MB")
    assert_true(usage_memory_increase < 5000, "Heavy usage should use less than 5MB additional")
    assert_true(total_cleanup_decrease > 0, "Comprehensive cleanup should reduce memory")
    assert_true(final_memory_increase < 500, "Final memory should be close to initial state")
end

-- Run all tests
print("Starting MCP Memory Usage and Resource Cleanup Tests")
print("====================================================")

-- Clean up before running tests
mcp_http_transport.cleanup()
http_client.cleanup()
sse_client.cleanup()
mcp_performance.cleanup()

-- Run tests
run_test("Memory usage during initialization", test_memory_usage_initialization)
run_test("Memory usage during multiple request cycles", test_memory_usage_request_cycles)
run_test("Memory usage with large data payloads", test_memory_usage_large_payloads)
run_test("Resource cleanup during session management", test_resource_cleanup_session_management)
run_test("Memory usage during concurrent operations", test_memory_usage_concurrent_operations)
run_test("Memory leak detection over time", test_memory_leak_detection)
run_test("HTTP client memory usage", test_http_client_memory_usage)
run_test("SSE client memory usage", test_sse_client_memory_usage)
run_test("Performance monitoring memory usage", test_performance_monitoring_memory_usage)
run_test("Comprehensive resource cleanup verification", test_comprehensive_resource_cleanup)

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
    os.exit(1)
else
    print("\n✓ All memory usage and resource cleanup tests passed!")
    print("The MCP HTTP transport system demonstrates good memory management and proper resource cleanup.")
end
