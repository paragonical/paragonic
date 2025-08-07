-- Basic test for RPC reconnection functionality
-- This test focuses on the core reconnection logic without any socket complexity

-- Mock vim for standalone testing
vim = {
    json = {
        encode = function(obj)
            return '{"jsonrpc":"2.0","result":"world","id":1}'
        end,
        decode = function(str)
            return {result = "world"}
        end
    },
    wait = function(ms)
        -- Mock wait function - just return immediately for testing
    end,
    g = {
        paragonic_use_real_backend = false -- Use mock mode
    }
    -- Note: Not setting vim.fn or vim.uv so it falls through to mock socket path
}

-- Debug: Check the flag value
print("🔧 Debug: vim.g.paragonic_use_real_backend = " .. tostring(vim.g.paragonic_use_real_backend))
print("🔧 Debug: vim.g.paragonic_use_real_backend ~= false = " .. tostring(vim.g.paragonic_use_real_backend ~= false))
print("🔧 Debug: vim.fn = " .. tostring(vim.fn))
print("🔧 Debug: vim.uv = " .. tostring(vim.uv))

-- Load the RPC module
local rpc = require("paragonic.rpc")

-- Test basic reconnection functionality
local function test_basic_reconnection()
    print("Testing basic reconnection functionality...")
    
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

-- Test reconnection with failed attempts
local function test_reconnection_failure()
    print("Testing reconnection with failed attempts...")
    
    -- Create a client with invalid server address
    local client = rpc.new("127.0.0.1:9999") -- Invalid port
    
    -- Test reconnection to invalid server
    local reconnect_result = client:reconnect()
    assert(reconnect_result == false, "Reconnect should return false for invalid server")
    assert(client.connected == false, "Client should remain disconnected after failed reconnection")
    
    print("✓ Reconnection correctly fails for invalid server")
    
    return true
end

-- Test automatic reconnection in is_connected()
local function test_automatic_reconnection()
    print("Testing automatic reconnection in is_connected()...")
    
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

-- Run all tests
local function run_all_tests()
    print("=== Testing RPC Reconnection Functionality (Basic) ===")
    
    local tests = {
        test_basic_reconnection,
        test_reconnection_failure,
        test_automatic_reconnection
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
if arg[0]:match("test_rpc_reconnection_basic.lua$") then
    run_all_tests()
end

return {
    test_basic_reconnection = test_basic_reconnection,
    test_reconnection_failure = test_reconnection_failure,
    test_automatic_reconnection = test_automatic_reconnection,
    run_all_tests = run_all_tests
}
