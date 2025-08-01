--[[
nlua test file for Paragonic RPC functionality
Following TDD principles: write test first, then implement
--]]

local M = {}

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
        vim.notify("✓ " .. test_name .. " passed", vim.log.levels.INFO)
    else
        test_results.failed = test_results.failed + 1
        vim.notify("✗ " .. test_name .. " failed: " .. tostring(result), vim.log.levels.ERROR)
    end
end

-- Test helper function that can be called from Neovim
function M.run_tests()
    vim.notify("Running Paragonic RPC tests...", vim.log.levels.INFO)
    
    -- Reset test results
    test_results = { passed = 0, failed = 0, total = 0 }
    
    -- Test 1: RPC client creation
    run_test("RPC client creation", function()
        local rpc_client = require('paragonic.rpc').new("127.0.0.1:2346")
        assert(rpc_client ~= nil, "RPC client should not be nil")
        assert(type(rpc_client) == "table", "RPC client should be a table")
        return true
    end)
    
    -- Test 2: Server address storage
    run_test("Server address storage", function()
        local rpc_client = require('paragonic.rpc').new("127.0.0.1:2346")
        assert(rpc_client.server_address == "127.0.0.1:2346", "Server address should be stored correctly")
        return true
    end)
    
    -- Test 3: Hello method call
    run_test("Hello method call", function()
        local rpc_client = require('paragonic.rpc').new("127.0.0.1:2346")
        local response = rpc_client:hello()
        assert(response == "world", "Hello should return 'world'")
        return true
    end)
    
    -- Test 4: Connection management
    run_test("Connection management", function()
        local rpc_client = require('paragonic.rpc').new("127.0.0.1:2346")
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
        local rpc_client = require('paragonic.rpc').new("127.0.0.1:2346")
        
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
    
    -- Test 6: Error handling
    run_test("Error handling for invalid connection", function()
        local rpc_client = require('paragonic.rpc').new("127.0.0.1:9999") -- Invalid port
        local success, result = pcall(function()
            return rpc_client:hello()
        end)
        assert(success == false, "Should fail with invalid connection")
        assert(type(result) == "string", "Should return error message string")
        return true
    end)
    
    -- Print summary
    local summary = string.format("Tests completed: %d passed, %d failed, %d total", 
        test_results.passed, test_results.failed, test_results.total)
    vim.notify(summary, vim.log.levels.INFO)
    
    return test_results
end

-- Command to run tests from Neovim
vim.api.nvim_create_user_command('ParagonicTestRPC', function()
    M.run_tests()
end, { desc = 'Run Paragonic RPC tests' })

return M 