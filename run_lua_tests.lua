#!/usr/bin/env lua

--[[
Paragonic Lua Test Runner
Comprehensive test suite runner for the Paragonic Lua components
--]]

-- Test configuration
local TEST_CONFIG = {
    verbose = true,
    stop_on_failure = false,
    categories = {
        unit = {
            name = "Unit Tests",
            description = "Basic functionality tests (no external dependencies)",
            tests = {
                "test_rpc_json.lua",
                "test_simple.lua"
            }
        },
        standalone = {
            name = "Standalone Tests", 
            description = "Tests using standalone RPC client (no socket deps)",
            tests = {
                "test_rpc_standalone.lua"
            }
        },
        search = {
            name = "Search Tests",
            description = "Search functionality integration tests",
            tests = {
                "test_lua_search_integration.lua"
            }
        },
        integration = {
            name = "Integration Tests",
            description = "Full integration tests (requires backend)",
            tests = {
                "test_rpc_standalone_model_info.lua",
                "test_rpc_standalone_chat_completion.lua", 
                "test_rpc_standalone_generate_embedding.lua"
            }
        }
    }
}

-- Parse command line arguments first
local args = {...}
if #args > 0 then
    if args[1] == "--help" or args[1] == "-h" then
        print("Paragonic Lua Test Runner")
        print("Usage: nlua run_lua_tests.lua [options]")
        print("")
        print("Options:")
        print("  --help, -h     Show this help message")
        print("  --verbose      Enable verbose output")
        print("  --stop-on-failure  Stop on first test failure")
        print("")
        print("Test Categories:")
        for category_name, category_config in pairs(TEST_CONFIG.categories) do
            print("  " .. category_name .. ": " .. category_config.description)
        end
        os.exit(0)
    elseif args[1] == "--verbose" then
        TEST_CONFIG.verbose = true
    elseif args[1] == "--stop-on-failure" then
        TEST_CONFIG.stop_on_failure = true
    end
end

-- Test results tracking
local TestResults = {
    total = 0,
    passed = 0,
    failed = 0,
    skipped = 0,
    errors = {}
}

-- Helper functions
local function print_header(title)
    print("\n" .. string.rep("=", 60))
    print(" " .. title)
    print(string.rep("=", 60))
end

local function print_section(title)
    print("\n" .. string.rep("-", 40))
    print(" " .. title)
    print(string.rep("-", 40))
end

local function run_test(test_file)
    local success, result = pcall(function()
        -- Set up package path for the test
        package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
        
        -- Run the test file
        dofile(test_file)
        return true
    end)
    
    if success then
        TestResults.passed = TestResults.passed + 1
        if TEST_CONFIG.verbose then
            print("  ✓ " .. test_file .. " passed")
        end
        return true
    else
        TestResults.failed = TestResults.failed + 1
        local error_msg = "  ✗ " .. test_file .. " failed: " .. tostring(result)
        print(error_msg)
        table.insert(TestResults.errors, {file = test_file, error = result})
        
        if TEST_CONFIG.stop_on_failure then
            error("Test failed: " .. test_file)
        end
        return false
    end
end

local function run_test_category(category_name, category_config)
    print_section(category_config.name)
    print(category_config.description)
    print("")
    
    local category_passed = 0
    local category_total = 0
    
    for _, test_file in ipairs(category_config.tests) do
        TestResults.total = TestResults.total + 1
        category_total = category_total + 1
        
        if run_test(test_file) then
            category_passed = category_passed + 1
        end
    end
    
    print("")
    print(string.format("Category Results: %d/%d passed", category_passed, category_total))
    
    return category_passed == category_total
end

local function print_summary()
    print_header("Test Summary")
    
    print(string.format("Total Tests: %d", TestResults.total))
    print(string.format("Passed: %d", TestResults.passed))
    print(string.format("Failed: %d", TestResults.failed))
    print(string.format("Skipped: %d", TestResults.skipped))
    
    if TestResults.failed > 0 then
        print("\nFailed Tests:")
        for _, error_info in ipairs(TestResults.errors) do
            print("  " .. error_info.file .. ": " .. error_info.error)
        end
    end
    
    local success_rate = TestResults.total > 0 and (TestResults.passed / TestResults.total) * 100 or 0
    print(string.format("\nSuccess Rate: %.1f%%", success_rate))
    
    if TestResults.failed == 0 then
        print("\n🎉 All tests passed!")
        return true
    else
        print("\n❌ Some tests failed!")
        return false
    end
end

-- Main test execution
local function main()
    print_header("Paragonic Lua Test Suite")
    print("Running comprehensive test suite...")
    print("Using nlua (Neovim Lua) for testing")
    
    local start_time = os.time()
    
    -- Run test categories
    for category_name, category_config in pairs(TEST_CONFIG.categories) do
        local success = run_test_category(category_name, category_config)
        if not success and TEST_CONFIG.stop_on_failure then
            break
        end
    end
    
    local end_time = os.time()
    local duration = end_time - start_time
    
    print_header("Test Execution Complete")
    print(string.format("Duration: %d seconds", duration))
    
    local all_passed = print_summary()
    
    -- Exit with appropriate code
    if all_passed then
        os.exit(0)
    else
        os.exit(1)
    end
end

-- Run the test suite (only if not showing help)
local should_run_tests = true
if #args > 0 and (args[1] == "--help" or args[1] == "-h") then
    should_run_tests = false
end

if should_run_tests then
    main()
end 