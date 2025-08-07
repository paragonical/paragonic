-- Test RPC reconnection functionality (standalone version)
-- This test verifies that the RPC client can properly reconnect when the server restarts

-- Mock vim for standalone testing
vim = {
    json = {
        encode = function(obj)
            -- Simple JSON encoder for testing
            if type(obj) == "table" then
                local parts = {}
                for k, v in pairs(obj) do
                    if type(v) == "string" then
                        table.insert(parts, string.format('"%s":"%s"', k, v))
                    else
                        table.insert(parts, string.format('"%s":%s', k, tostring(v)))
                    end
                end
                return "{" .. table.concat(parts, ",") .. "}"
            end
            return tostring(obj)
        end,
        decode = function(str)
            -- Simple JSON decoder for testing
            if str:find('"result"') then
                return {result = "world"}
            end
            return {message = {content = "Hello from mock server"}}
        end
    },
    wait = function(ms)
        -- Mock wait function
        os.execute("sleep " .. (ms / 1000))
    end,
    uv = {
        now = function()
            return os.time() * 1000
        end,
        new_tcp = function()
            -- Mock TCP socket
            local socket = {
                connected = true,
                host = nil,
                port = nil,
                read_callback = nil,
                response_data = '{"jsonrpc":"2.0","result":"world","id":1}'
            }
            
            socket.connect = function(self, host, port)
                self.host = host
                self.port = port
                -- Mock successful connection
                return true
            end
            
            socket.write = function(self, data)
                -- Mock successful write
                return true
            end
            
            socket.read_start = function(self, callback)
                -- Store the callback and simulate response
                self.read_callback = callback
                -- Simulate async response
                callback(nil, self.response_data)
            end
            
            socket.close = function(self)
                self.connected = false
            end
            
            return socket
        end
    },
    g = {
        paragonic_use_real_backend = true
    },
    fn = {
        -- Mock vim.fn functions
    }
}

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
    
    -- Test connection (will use mock since we're not in Neovim)
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
    
    -- Create a client with invalid server address
    local client = rpc.new("127.0.0.1:9999") -- Invalid port
    
    -- Test reconnection to invalid server
    local reconnect_result = client:reconnect()
    assert(reconnect_result == false, "Reconnect should return false for invalid server")
    assert(client.connected == false, "Client should remain disconnected after failed reconnection")
    
    print("✓ Reconnection correctly fails for invalid server")
    
    return true
end

-- Test RPC call with automatic reconnection
local function test_rpc_call_reconnection()
    print("Testing RPC call with automatic reconnection...")
    
    -- Create a new RPC client
    local client = rpc.new("127.0.0.1:3000")
    
    -- Connect first
    local connect_result = client:connect()
    assert(connect_result == true, "Connect should return true on success")
    
    print("✓ Initial connection successful")
    
    -- Test RPC call when connected
    local call_result = client:call("hello", {})
    assert(call_result ~= nil, "RPC call should return a result when connected")
    
    print("✓ RPC call successful when connected")
    
    -- Disconnect and test RPC call (should trigger reconnection)
    client:disconnect()
    local call_result2 = client:call("hello", {})
    assert(call_result2 ~= nil, "RPC call should return a result after automatic reconnection")
    
    print("✓ RPC call automatically reconnects when disconnected")
    
    return true
end

-- Run all tests
local function run_all_tests()
    print("=== Testing RPC Reconnection Functionality (Standalone) ===")
    
    local tests = {
        test_basic_reconnection,
        test_connection_health_check,
        test_automatic_reconnection,
        test_reconnection_failure,
        test_rpc_call_reconnection
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
if arg[0]:match("test_rpc_reconnection_standalone.lua$") then
    run_all_tests()
end

return {
    test_basic_reconnection = test_basic_reconnection,
    test_connection_health_check = test_connection_health_check,
    test_automatic_reconnection = test_automatic_reconnection,
    test_reconnection_failure = test_reconnection_failure,
    test_rpc_call_reconnection = test_rpc_call_reconnection,
    run_all_tests = run_all_tests
}
