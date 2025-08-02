--[[
Test for implementing actual connection logic in rpc_standalone.lua - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Test that current mock implementation fails (red phase)
local function test_mock_implementation_fails()
    print("Testing that current mock implementation fails (red phase)...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:3000")
    
    -- Test that connect() currently just returns true without real connection
    local connect_result = client:connect()
    
    -- This should fail because we want real connection logic
    -- The mock implementation just returns true, but we want it to actually test the connection
    assert(connect_result == false, "Connect should fail with mock implementation")
    assert(client.connected == false, "Client should remain disconnected with mock implementation")
    
    print("✓ Mock implementation correctly fails (red phase)")
    return true
end

-- Test actual connection logic implementation
local function test_actual_connection_logic()
    print("Testing actual connection logic implementation...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:3000")
    
    -- Test initial state
    assert(client.connected == false, "Client should start disconnected")
    assert(client.server_address == "127.0.0.1:3000", "Server address should be set correctly")
    
    print("✓ Initial client state is correct")
    
    -- Test connection attempt
    print("Testing connection attempt...")
    
    -- Start the Rust backend server with database bypass
    local server_cmd = "./target/debug/paragonic --no-database > /dev/null 2>&1 & echo $!"
    local server_process = io.popen(server_cmd)
    if not server_process then
        error("Failed to start server process")
    end
    
    local pid = server_process:read("*a"):match("(%d+)")
    if not pid then
        error("Failed to get server process ID")
    end
    
    print("✓ Server started with PID: " .. pid)
    
    -- Wait for server to start
    os.execute("sleep 3")
    
    -- Test the connect method
    local connect_result = client:connect()
    
    -- Verify connection result
    assert(connect_result == true, "Connect should return true on success")
    assert(client.connected == true, "Client should be marked as connected")
    
    print("✓ Connection logic works correctly")
    
    -- Test that we can actually communicate with the server
    print("Testing actual communication...")
    
    local hello_result = client:hello()
    assert(hello_result ~= nil, "Hello should return a result")
    assert(hello_result == "world", "Hello should return 'world' from server")
    
    print("✓ Communication test passed")
    
    -- Test disconnection
    print("Testing disconnection...")
    
    local disconnect_result = client:disconnect()
    assert(disconnect_result == true, "Disconnect should return true on success")
    assert(client.connected == false, "Client should be marked as disconnected")
    
    print("✓ Disconnection logic works correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test connection error handling
local function test_connection_error_handling()
    print("Testing connection error handling...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a client with invalid server address
    local client = rpc_standalone.new("127.0.0.1:9999") -- Invalid port
    
    -- Test connection to invalid server
    local connect_result = client:connect()
    
    -- Should handle the error gracefully
    assert(connect_result == false, "Connection to invalid server should fail")
    assert(client.connected == false, "Client should remain disconnected")
    
    print("✓ Connection error handling works correctly")
    
    return true
end

-- Test server availability check
local function test_server_availability_check()
    print("Testing server availability check...")
    
    -- Test with server not running
    local check_cmd = 'echo \'{"jsonrpc":"2.0","method":"hello","params":{},"id":1}\' | nc -w 2 127.0.0.1:3000 2>/dev/null || echo "connection_failed"'
    local check_process = io.popen(check_cmd)
    if check_process then
        local result = check_process:read("*a")
        check_process:close()
        
        if result:find("connection_failed") then
            print("✓ Server availability check works (server not running)")
        else
            print("⚠ Server is running unexpectedly")
        end
    else
        print("⚠ Failed to check server availability")
    end
    
    return true
end

-- Run the tests
local success, err = pcall(function()
    test_server_availability_check()
    test_mock_implementation_fails()
    test_actual_connection_logic()
    test_connection_error_handling()
end)

if not success then
    print("Test failed: " .. tostring(err))
    os.exit(1)
end

print("✓ All rpc_standalone connection tests passed!") 