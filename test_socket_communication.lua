--[[
Test for real socket communication functionality - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Test that socket communication uses real TCP sockets
local function test_socket_communication_real_tcp()
    print("Testing socket communication real TCP...")
    
    -- Load the RPC module
    local rpc = require("paragonic.rpc")
    
    -- Create RPC client
    local client = rpc.new("127.0.0.1:3000")
    
    -- Should start disconnected
    assert(not client:is_connected(), "Client should start disconnected")
    
    -- Connect to server (this should attempt real TCP connection)
    local success = client:connect()
    
    -- Should have attempted to create a real TCP socket
    assert(client.socket ~= nil, "Connect should create a socket")
    assert(client:is_connected(), "Client should be connected after connect()")
    
    -- Socket should be a real TCP socket, not a mock
    assert(client.socket.send ~= nil, "Socket should have send method")
    assert(client.socket.receive ~= nil, "Socket should have receive method")
    assert(client.socket.close ~= nil, "Socket should have close method")
    
    -- Test that socket can actually send and receive data
    local test_message = "test"
    local send_success = client.socket:send(test_message)
    assert(send_success ~= nil, "Socket should be able to send data")
    
    print("✓ Socket communication real TCP test passed!")
end

-- Test that socket communication can handle connection failures
local function test_socket_communication_connection_failure()
    print("Testing socket communication connection failure...")
    
    -- Load the RPC module
    local rpc = require("paragonic.rpc")
    
    -- Create RPC client with invalid address
    local client = rpc.new("127.0.0.1:9999")  -- Port that shouldn't be listening
    
    -- Should start disconnected
    assert(not client:is_connected(), "Client should start disconnected")
    
    -- Connect should fail gracefully
    local success, err = client:connect()
    assert(not success, "Connect should fail with invalid address")
    assert(err ~= nil, "Should return error message")
    assert(not client:is_connected(), "Client should remain disconnected")
    
    print("✓ Socket communication connection failure test passed!")
end

-- Run the tests
test_socket_communication_real_tcp()
test_socket_communication_connection_failure() 