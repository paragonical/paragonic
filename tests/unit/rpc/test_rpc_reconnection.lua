-- Test RPC reconnection functionality
-- This test verifies that the neovim client can properly reconnect when the server restarts

local M = require("paragonic")

-- Test basic reconnection functionality
local function test_basic_reconnection()
    print("Testing basic reconnection functionality...")
    
    -- Load the RPC module
    local rpc = require("paragonic.rpc")
    
    -- Create a new RPC client
    local client = rpc.new("127.0.0.1:3000")
    
    -- Test initial state
    assert(client.connected == false, "Client should start disconnected")
    assert(client.server_address == "127.0.0.1:3000", "Server address should be set correctly")
    
    print("✓ Initial client state is correct")
    
    -- Test connection
    local connect_result = client:connect()
    assert(connect_result == true, "Connect should return true on success")
    assert(client.connected == true, "Client should be marked as connected")
    
    print("✓ Initial connection successful")
    
    -- Test that we can communicate
    local hello_result = client:hello()
    assert(hello_result ~= nil, "Hello should return a result")
    
    print("✓ Communication test passed")
    
    -- Test disconnection
    local disconnect_result = client:disconnect()
    assert(disconnect_result == true, "Disconnect should return true")
    assert(client.connected == false, "Client should be marked as disconnected")
    
    print("✓ Disconnection successful")
    
    -- Test reconnection
    local reconnect_result = client:reconnect()
    assert(reconnect_result == true, "Reconnect should return true on success")
    assert(client.connected == true, "Client should be marked as connected after reconnect")
    
    print("✓ Reconnection successful")
    
    -- Test communication after reconnection
    local hello_result2 = client:hello()
    assert(hello_result2 ~= nil, "Hello should return a result after reconnection")
    
    print("✓ Communication after reconnection passed")
    
    return true
end

-- Test connection health checking
local function test_connection_health_check()
    print("Testing connection health checking...")
    
    -- Load the RPC module
    local rpc = require("paragonic.rpc")
    
    -- Create a new RPC client
    local client = rpc.new("127.0.0.1:3000")
    
    -- Connect first
    local connect_result = client:connect()
    assert(connect_result == true, "Connect should return true on success")
    
    print("✓ Initial connection successful")
    
    -- Test health check when connected
    local health_result = client:check_connection_health()
    assert(health_result == true, "Health check should return true when connected")
    
    print("✓ Health check passed when connected")
    
    -- Disconnect and test health check
    client:disconnect()
    local health_result2 = client:check_connection_health()
    assert(health_result2 == false, "Health check should return false when disconnected")
    
    print("✓ Health check correctly detects disconnection")
    
    return true
end

-- Test automatic reconnection in is_connected()
local function test_automatic_reconnection()
    print("Testing automatic reconnection in is_connected()...")
    
    -- Load the RPC module
    local rpc = require("paragonic.rpc")
    
    -- Create a new RPC client
    local client = rpc.new("127.0.0.1:3000")
    
    -- Connect first
    local connect_result = client:connect()
    assert(connect_result == true, "Connect should return true on success")
    
    print("✓ Initial connection successful")
    
    -- Test is_connected when connected
    local is_connected = client:is_connected()
    assert(is_connected == true, "is_connected should return true when connected")
    
    print("✓ is_connected returns true when connected")
    
    -- Disconnect and test is_connected (should trigger reconnection)
    client:disconnect()
    local is_connected2 = client:is_connected()
    assert(is_connected2 == true, "is_connected should return true after automatic reconnection")
    
    print("✓ is_connected automatically reconnects when disconnected")
    
    return true
end

-- Test reconnection with failed attempts
local function test_reconnection_failure()
    print("Testing reconnection with failed attempts...")
    
    -- Load the RPC module
    local rpc = require("paragonic.rpc")
    
    -- Create a client with invalid server address
    local client = rpc.new("127.0.0.1:9999") -- Invalid port
    
    -- Test reconnection to invalid server
    local reconnect_result = client:reconnect()
    assert(reconnect_result == false, "Reconnect should return false for invalid server")
    assert(client.connected == false, "Client should remain disconnected after failed reconnection")
    
    print("✓ Reconnection correctly fails for invalid server")
    
    return true
end

-- Test force reconnection from main module
local function test_force_reconnection()
    print("Testing force reconnection from main module...")
    
    -- Initialize the backend first
    local init_result = M.initialize_backend()
    assert(init_result == true, "Backend initialization should succeed")
    
    print("✓ Backend initialization successful")
    
    -- Test force reconnection
    local force_reconnect_result = M.force_reconnect()
    assert(force_reconnect_result == true, "Force reconnection should succeed")
    
    print("✓ Force reconnection successful")
    
    -- Test that we can still communicate after force reconnection
    local rpc_client = M._get_rpc_client()
    assert(rpc_client ~= nil, "RPC client should be available after force reconnection")
    
    local hello_result = rpc_client:hello()
    assert(hello_result ~= nil, "Hello should return a result after force reconnection")
    
    print("✓ Communication works after force reconnection")
    
    return true
end

-- Test reconnection in _get_rpc_client
local function test_get_rpc_client_reconnection()
    print("Testing reconnection in _get_rpc_client...")
    
    -- Initialize the backend first
    local init_result = M.initialize_backend()
    assert(init_result == true, "Backend initialization should succeed")
    
    print("✓ Backend initialization successful")
    
    -- Get RPC client
    local rpc_client = M._get_rpc_client()
    assert(rpc_client ~= nil, "RPC client should be available")
    
    print("✓ RPC client retrieved successfully")
    
    -- Test communication
    local hello_result = rpc_client:hello()
    assert(hello_result ~= nil, "Hello should return a result")
    
    print("✓ Communication test passed")
    
    -- Disconnect the client
    rpc_client:disconnect()
    
    -- Get RPC client again (should trigger reconnection)
    local rpc_client2 = M._get_rpc_client()
    assert(rpc_client2 ~= nil, "RPC client should be available after reconnection")
    
    print("✓ RPC client reconnected automatically")
    
    -- Test communication after reconnection
    local hello_result2 = rpc_client2:hello()
    assert(hello_result2 ~= nil, "Hello should return a result after reconnection")
    
    print("✓ Communication works after automatic reconnection")
    
    return true
end

-- Run all tests
local function run_all_tests()
    print("=== Testing RPC Reconnection Functionality ===")
    
    local tests = {
        test_basic_reconnection,
        test_connection_health_check,
        test_automatic_reconnection,
        test_reconnection_failure,
        test_force_reconnection,
        test_get_rpc_client_reconnection
    }
    
    local passed = 0
    local failed = 0
    
    for i, test in ipairs(tests) do
        print("\n--- Test " .. i .. " ---")
        local success, err = pcall(test)
        if success then
            print("✓ Test " .. i .. " PASSED")
            passed = passed + 1
        else
            print("❌ Test " .. i .. " FAILED: " .. tostring(err))
            failed = failed + 1
        end
    end
    
    print("\n=== Test Results ===")
    print("Passed: " .. passed)
    print("Failed: " .. failed)
    print("Total: " .. (passed + failed))
    
    if failed == 0 then
        print("🎉 All tests passed!")
        return true
    else
        print("❌ Some tests failed!")
        return false
    end
end

-- Run tests if this file is executed directly
if arg[0]:match("test_rpc_reconnection.lua$") then
    run_all_tests()
end

return {
    test_basic_reconnection = test_basic_reconnection,
    test_connection_health_check = test_connection_health_check,
    test_automatic_reconnection = test_automatic_reconnection,
    test_reconnection_failure = test_reconnection_failure,
    test_force_reconnection = test_force_reconnection,
    test_get_rpc_client_reconnection = test_get_rpc_client_reconnection,
    run_all_tests = run_all_tests
}
