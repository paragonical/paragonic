--[[
Standalone test runner for Paragonic RPC functionality
Can be run with: nlua test_rpc.lua
--]]

-- Add lua directory to package path
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

-- Mock vim API for standalone testing
vim = {
    notify = function(msg, level)
        local level_str = level == 1 and "INFO" or level == 2 and "WARN" or "ERROR"
        print("[" .. level_str .. "] " .. msg)
    end,
    log = {
        levels = {
            INFO = 1,
            WARN = 2,
            ERROR = 3
        }
    }
}

-- Test results tracking
local test_results = {
    passed = 0,
    failed = 0,
    total = 0
}

-- Helper function to run a test
local function run_test(test_name, test_func)
    test_results.total = test_results.total + 1
    local success, result = pcall(test_func)
    
    if success then
        test_results.passed = test_results.passed + 1
        print("✓ " .. test_name .. " passed")
    else
        test_results.failed = test_results.failed + 1
        print("✗ " .. test_name .. " failed: " .. tostring(result))
    end
end

-- Main test function
local function run_tests()
    print("Running Paragonic RPC tests...")
    
    -- Reset test results
    test_results = { passed = 0, failed = 0, total = 0 }
    
    -- Test 1: RPC client creation
    run_test("RPC client creation", function()
        local rpc_client = require('paragonic.rpc_standalone').new("127.0.0.1:2346")
        assert(rpc_client ~= nil, "RPC client should not be nil")
        assert(type(rpc_client) == "table", "RPC client should be a table")
        return true
    end)
    
    -- Test 2: Server address storage
    run_test("Server address storage", function()
        local rpc_client = require('paragonic.rpc_standalone').new("127.0.0.1:2346")
        assert(rpc_client.server_address == "127.0.0.1:2346", "Server address should be stored correctly")
        return true
    end)
    
    -- Test 3: Hello method call
    run_test("Hello method call", function()
        local rpc_client = require('paragonic.rpc_standalone').new("127.0.0.1:2346")
        local response = rpc_client:hello()
        assert(response == "world", "Hello should return 'world'")
        return true
    end)
    
    -- Test 4: Connection management
    run_test("Connection management", function()
        local rpc_client = require('paragonic.rpc_standalone').new("127.0.0.1:2346")
        local connect_success = rpc_client:connect()
        assert(connect_success == true, "Connect should succeed")
        
        local is_connected = rpc_client:is_connected()
        assert(is_connected == true, "Should be connected after connect")
        
        local disconnect_success = rpc_client:disconnect()
        assert(disconnect_success == true, "Disconnect should succeed")
        
        local is_disconnected = rpc_client:is_connected()
        assert(is_disconnected == false, "Should not be connected after disconnect")
        
        return true
    end)
    
    -- Test 5: Full hello workflow
    run_test("Full hello workflow", function()
        local rpc_client = require('paragonic.rpc_standalone').new("127.0.0.1:2346")
        
        -- Connect
        local connect_success = rpc_client:connect()
        assert(connect_success == true, "Connect should succeed")
        
        -- Send hello
        local response = rpc_client:hello()
        assert(response == "world", "Hello should return 'world'")
        
        -- Disconnect
        local disconnect_success = rpc_client:disconnect()
        assert(disconnect_success == true, "Disconnect should succeed")
        
        return true
    end)
    
    -- Print summary
    local summary = string.format("Tests completed: %d passed, %d failed, %d total", 
        test_results.passed, test_results.failed, test_results.total)
    print(summary)
    
    return test_results
end

-- Run tests if this file is executed directly
if arg and arg[0] and arg[0]:match("test_rpc.lua$") then
    run_tests()
else
    -- Also run tests when loaded as module
    run_tests()
end 