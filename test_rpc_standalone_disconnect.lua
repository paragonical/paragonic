--[[
Test for implementing proper disconnect method in rpc_standalone.lua - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Test that disconnect method exists and works properly
local function test_disconnect_method_exists()
    print("Testing that disconnect method exists...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:3000")
    
    -- Test that disconnect method exists
    assert(type(client.disconnect) == "function", "disconnect method should exist and be a function")
    
    print("✓ disconnect method exists")
    return true
end

-- Test disconnect method implementation
local function test_disconnect_method_implementation()
    print("Testing disconnect method implementation...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:3000")
    
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
    
    -- Connect to server
    local connect_result = client:connect()
    assert(connect_result == true, "Should connect successfully")
    assert(client:is_connected() == true, "Should be connected after connect")
    
    -- Test disconnect functionality
    print("Testing disconnect functionality...")
    local disconnect_result = client:disconnect()
    
    assert(disconnect_result == true, "disconnect should return true")
    assert(client:is_connected() == false, "Should not be connected after disconnect")
    
    print("✓ disconnect method works correctly")
    
    -- Test that we can't make requests after disconnect
    print("Testing that requests fail after disconnect...")
    local hello_result = client:hello()
    assert(hello_result == nil, "hello should fail when disconnected")
    
    print("✓ Requests correctly fail after disconnect")
    
    -- Test that we can reconnect after disconnect
    print("Testing reconnection after disconnect...")
    local reconnect_result = client:connect()
    assert(reconnect_result == true, "Should be able to reconnect")
    assert(client:is_connected() == true, "Should be connected after reconnection")
    
    -- Test that requests work after reconnection
    local hello_result2 = client:hello()
    assert(hello_result2 == "world", "hello should work after reconnection")
    
    print("✓ Reconnection works correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test disconnect without connection
local function test_disconnect_without_connection()
    print("Testing disconnect without connection...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:3000")
    
    -- Test disconnect when not connected
    local disconnect_result = client:disconnect()
    
    assert(disconnect_result == true, "disconnect should return true even when not connected")
    assert(client:is_connected() == false, "Should remain disconnected")
    
    print("✓ disconnect without connection works correctly")
    
    return true
end

-- Test multiple disconnect calls
local function test_multiple_disconnect_calls()
    print("Testing multiple disconnect calls...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:3000")
    
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
    
    -- Connect to server
    local connect_result = client:connect()
    assert(connect_result == true, "Should connect successfully")
    
    -- Test multiple disconnect calls
    local disconnect_result1 = client:disconnect()
    local disconnect_result2 = client:disconnect()
    local disconnect_result3 = client:disconnect()
    
    assert(disconnect_result1 == true, "First disconnect should return true")
    assert(disconnect_result2 == true, "Second disconnect should return true")
    assert(disconnect_result3 == true, "Third disconnect should return true")
    assert(client:is_connected() == false, "Should remain disconnected after multiple calls")
    
    print("✓ Multiple disconnect calls work correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test disconnect with active operations
local function test_disconnect_with_active_operations()
    print("Testing disconnect with active operations...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:3000")
    
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
    
    -- Connect to server
    local connect_result = client:connect()
    assert(connect_result == true, "Should connect successfully")
    
    -- Make some requests to establish connection
    local hello_result = client:hello()
    assert(hello_result == "world", "hello should work")
    
    -- Test disconnect with active connection
    local disconnect_result = client:disconnect()
    assert(disconnect_result == true, "disconnect should return true")
    assert(client:is_connected() == false, "Should be disconnected")
    
    -- Test that subsequent requests fail
    local hello_result2 = client:hello()
    assert(hello_result2 == nil, "hello should fail after disconnect")
    
    print("✓ disconnect with active operations works correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test disconnect error handling
local function test_disconnect_error_handling()
    print("Testing disconnect error handling...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a client with invalid server address
    local client = rpc_standalone.new("127.0.0.1:9999") -- Invalid port
    
    -- Test disconnect with invalid server (should not crash)
    local disconnect_result = client:disconnect()
    
    -- Should handle gracefully
    assert(disconnect_result == true, "disconnect should return true even with invalid server")
    assert(client:is_connected() == false, "Should remain disconnected")
    
    print("✓ disconnect error handling works correctly")
    
    return true
end

-- Run the tests
local success, err = pcall(function()
    test_disconnect_method_exists()
    test_disconnect_method_implementation()
    test_disconnect_without_connection()
    test_multiple_disconnect_calls()
    test_disconnect_with_active_operations()
    test_disconnect_error_handling()
end)

if not success then
    print("Test failed: " .. tostring(err))
    os.exit(1)
end

print("✓ All rpc_standalone disconnect tests passed!") 