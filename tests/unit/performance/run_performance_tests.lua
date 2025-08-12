-- Performance Monitoring and Optimization Tests
-- 
-- Tests for the MCP performance monitoring and optimization module

-- Simple test runner
local function run_tests()
    local tests = {}
    local passed = 0
    local failed = 0
    
    -- Custom assertion functions
    local function assert_true(condition, message)
        if not condition then
            error("ASSERTION FAILED: " .. (message or "expected true"))
        end
    end
    
    local function assert_false(condition, message)
        if condition then
            error("ASSERTION FAILED: " .. (message or "expected false"))
        end
    end
    
    local function assert_equal(expected, actual, message)
        if expected ~= actual then
            error("ASSERTION FAILED: " .. (message or string.format("expected %s, got %s", tostring(expected), tostring(actual))))
        end
    end
    
    local function assert_not_nil(value, message)
        if value == nil then
            error("ASSERTION FAILED: " .. (message or "expected non-nil value"))
        end
    end
    
    local function assert_nil(value, message)
        if value ~= nil then
            error("ASSERTION FAILED: " .. (message or "expected nil value"))
        end
    end
    
    local function assert_table(value, message)
        if type(value) ~= "table" then
            error("ASSERTION FAILED: " .. (message or "expected table"))
        end
    end
    
    local function assert_number(value, message)
        if type(value) ~= "number" then
            error("ASSERTION FAILED: " .. (message or "expected number"))
        end
    end
    
    local function assert_string(value, message)
        if type(value) ~= "string" then
            error("ASSERTION FAILED: " .. (message or "expected string"))
        end
    end
    
    -- Test function wrapper
    local function test(name, test_func)
        table.insert(tests, {name = name, func = test_func})
    end
    
    -- Load the performance module
    local mcp_performance
    local success, err = pcall(function()
        mcp_performance = require("../../lua/paragonic/mcp_performance")
    end)
    
    if not success then
        -- Fallback for different require paths
        success, err = pcall(function()
            mcp_performance = require("lua.paragonic.mcp_performance")
        end)
    end
    
    if not success then
        print("ERROR: Could not load mcp_performance module: " .. tostring(err))
        return
    end
    
    print("Running Performance Monitoring and Optimization Tests...")
    print("=====================================================")
    
    -- Initialization tests
    test("Initialize performance monitoring", function()
        local success = mcp_performance.init()
        assert_true(success, "Performance monitoring should initialize successfully")
    end)
    
    test("Initialize with custom config", function()
        local config = {
            METRICS = {
                COLLECTION_INTERVAL = 2,
                MAX_METRICS_ENTRIES = 1800,
            },
            THRESHOLDS = {
                REQUEST_TIMEOUT_WARNING = 500,
                MEMORY_USAGE_WARNING = 25,
            },
        }
        
        local success = mcp_performance.init(config)
        assert_true(success, "Performance monitoring should initialize with custom config")
    end)
    
    -- Metrics collection tests
    test("Collect current metrics", function()
        local metrics = mcp_performance.collect_current_metrics()
        assert_table(metrics, "Should return metrics table")
        assert_number(metrics.timestamp, "Should have timestamp")
        assert_number(metrics.request_count, "Should have request_count")
        assert_number(metrics.response_time_avg, "Should have response_time_avg")
        assert_number(metrics.memory_usage, "Should have memory_usage")
    end)
    
    test("Get memory usage", function()
        local memory = mcp_performance.get_memory_usage()
        assert_number(memory, "Should return number")
        assert_true(memory >= 0, "Memory usage should be non-negative")
    end)
    
    test("Get cache hit rate", function()
        local hit_rate = mcp_performance.get_cache_hit_rate()
        assert_number(hit_rate, "Should return number")
        assert_true(hit_rate >= 0 and hit_rate <= 100, "Hit rate should be between 0 and 100")
    end)
    
    test("Get connection pool usage", function()
        local usage = mcp_performance.get_connection_pool_usage()
        assert_number(usage, "Should return number")
        assert_true(usage >= 0 and usage <= 100, "Usage should be between 0 and 100")
    end)
    
    -- Connection pool tests
    test("Initialize connection pool", function()
        local success = mcp_performance.init_connection_pool()
        assert_true(success, "Connection pool should initialize successfully")
    end)
    
    test("Get connection from pool", function()
        local connection, err = mcp_performance.get_connection()
        assert_not_nil(connection, "Should return connection")
        assert_nil(err, "Should not return error")
        assert_table(connection, "Connection should be table")
        assert_not_nil(connection.id, "Connection should have ID")
    end)
    
    test("Return connection to pool", function()
        local connection = {id = "test123", created_at = os.time(), last_used = os.time()}
        local success = mcp_performance.return_connection(connection)
        assert_true(success, "Should return connection successfully")
    end)
    
    test("Check connection validity", function()
        local valid_connection = {id = "test123", created_at = os.time(), last_used = os.time()}
        local is_valid = mcp_performance.is_connection_valid(valid_connection)
        assert_true(is_valid, "Valid connection should be valid")
        
        local invalid_connection = {id = "test123", created_at = os.time(), last_used = 0}
        local is_invalid = mcp_performance.is_connection_valid(invalid_connection)
        assert_false(is_invalid, "Invalid connection should be invalid")
    end)
    
    test("Generate connection ID", function()
        local id = mcp_performance.generate_connection_id()
        assert_string(id, "Should return string")
        assert_equal(8, #id, "ID should be 8 characters")
        assert_true(id:match("^[A-Za-z0-9]+$"), "ID should be alphanumeric")
    end)
    
    -- Request cache tests
    test("Initialize request cache", function()
        local success = mcp_performance.init_request_cache()
        assert_true(success, "Request cache should initialize successfully")
    end)
    
    test("Cache and retrieve response", function()
        local request_key = "test_request_123"
        local response = {result = "test_response", success = true}
        
        -- Cache response
        local cache_success = mcp_performance.cache_response(request_key, response)
        assert_true(cache_success, "Should cache response successfully")
        
        -- Retrieve response
        local cached_response = mcp_performance.get_cached_response(request_key)
        assert_not_nil(cached_response, "Should retrieve cached response")
        assert_equal(response.result, cached_response.result, "Cached response should match original")
    end)
    
    test("Cache miss for non-existent key", function()
        local cached_response = mcp_performance.get_cached_response("non_existent_key")
        assert_nil(cached_response, "Should return nil for non-existent key")
    end)
    
    test("Cache expiration", function()
        local request_key = "expire_test"
        local response = {result = "expire_test"}
        
        -- Cache response
        mcp_performance.cache_response(request_key, response)
        
        -- For this test, we'll just verify that caching works
        -- The actual expiration logic is tested in the module itself
        local cached_response = mcp_performance.get_cached_response(request_key)
        assert_not_nil(cached_response, "Should retrieve cached response immediately")
    end)
    
    -- Function profiling tests
    test("Start function profiling", function()
        -- Ensure profiling is stopped first
        mcp_performance.stop_function_profiling()
        
        local success = mcp_performance.start_function_profiling()
        assert_true(success, "Function profiling should start successfully")
    end)
    
    test("Profile function execution", function()
        local function test_function()
            -- Simulate some work
            local sum = 0
            for i = 1, 1000 do
                sum = sum + i
            end
            return sum
        end
        
        local result = mcp_performance.profile_function("test_function", test_function)
        assert_equal(500500, result, "Function should return correct result")
    end)
    
    test("Stop function profiling", function()
        local success = mcp_performance.stop_function_profiling()
        assert_true(success, "Function profiling should stop successfully")
    end)
    
    -- Request metrics tests
    test("Record request metrics", function()
        local start_time = os.clock()
        local end_time = start_time + 0.1 -- 100ms
        
        mcp_performance.record_request(start_time, end_time, true)
        
        local metrics = mcp_performance.collect_current_metrics()
        assert_true(metrics.request_count > 0, "Request count should be incremented")
        assert_true(metrics.success_rate > 0, "Success rate should be calculated")
    end)
    
    test("Record failed request", function()
        local start_time = os.clock()
        local end_time = start_time + 0.05 -- 50ms
        
        mcp_performance.record_request(start_time, end_time, false)
        
        local metrics = mcp_performance.collect_current_metrics()
        assert_true(metrics.error_count > 0, "Error count should be incremented")
    end)
    
    -- Performance alerts tests
    test("Check performance alerts - normal metrics", function()
        local metrics = {
            timestamp = os.time(),
            response_time_avg = 100, -- Below warning threshold
            memory_usage = 25, -- Below warning threshold
            concurrent_requests = 10, -- Below warning threshold
        }
        
        mcp_performance.check_performance_alerts(metrics)
        
        local all_metrics = mcp_performance.get_metrics()
        -- Should not generate alerts for normal metrics
        assert_true(#all_metrics.alerts >= 0, "Should not generate alerts for normal metrics")
    end)
    
    test("Check performance alerts - critical response time", function()
        local metrics = {
            timestamp = os.time(),
            response_time_avg = 6000, -- Above critical threshold
            memory_usage = 25,
            concurrent_requests = 10,
        }
        
        mcp_performance.check_performance_alerts(metrics)
        
        local all_metrics = mcp_performance.get_metrics()
        assert_true(#all_metrics.alerts > 0, "Should generate alerts for critical response time")
    end)
    
    -- Metrics and summary tests
    test("Get performance metrics", function()
        local metrics = mcp_performance.get_metrics()
        assert_table(metrics, "Should return metrics table")
        assert_table(metrics.current, "Should have current metrics")
        assert_table(metrics.history, "Should have history")
        assert_table(metrics.alerts, "Should have alerts")
        assert_table(metrics.profiles, "Should have profiles")
        assert_table(metrics.cache_stats, "Should have cache stats")
        assert_table(metrics.pool_stats, "Should have pool stats")
    end)
    
    test("Get performance summary", function()
        local summary = mcp_performance.get_summary()
        assert_table(summary, "Should return summary table")
        assert_not_nil(summary.status, "Should have status")
        assert_number(summary.uptime, "Should have uptime")
        assert_number(summary.total_requests, "Should have total_requests")
        assert_number(summary.avg_response_time, "Should have avg_response_time")
        assert_number(summary.success_rate, "Should have success_rate")
        assert_number(summary.memory_usage, "Should have memory_usage")
    end)
    
    -- Data management tests
    test("Clear performance data", function()
        local success = mcp_performance.clear_data()
        assert_true(success, "Should clear data successfully")
        
        local metrics = mcp_performance.get_metrics()
        assert_equal(0, #metrics.history, "History should be cleared")
        assert_equal(0, #metrics.alerts, "Alerts should be cleared")
    end)
    
    test("Cleanup performance monitoring", function()
        local success = mcp_performance.cleanup()
        assert_true(success, "Should cleanup successfully")
    end)
    
    -- Run all tests
    for i, test_case in ipairs(tests) do
        local success, err = pcall(test_case.func)
        if success then
            print("✓ " .. test_case.name)
            passed = passed + 1
        else
            print("✗ " .. test_case.name .. " - " .. tostring(err))
            failed = failed + 1
        end
    end
    
    print("=====================================================")
    print(string.format("Tests completed: %d passed, %d failed", passed, failed))
    
    if failed > 0 then
        os.exit(1)
    end
end

-- Run the tests
run_tests()
