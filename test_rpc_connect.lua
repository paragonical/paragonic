--[[
Test for RPC connect() function - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Test that connect() attempts real socket connection
local function test_rpc_connect_attempts_real_connection()
    print("Testing RPC connect() attempts real connection...")
    
    -- Load the RPC module
    local rpc = require("paragonic.rpc")
    
    -- Create RPC client
    local client = rpc.new("127.0.0.1:3000")
    
    -- Should start disconnected
    assert(not client:is_connected(), "Client should start disconnected")
    assert(client.socket == nil, "Socket should be nil initially")
    
    -- Connect to server (this should attempt real connection)
    local success = client:connect()
    
    -- Should have attempted to create a socket
    assert(client.socket ~= nil, "Connect should create a socket")
    assert(client:is_connected(), "Client should be connected after connect()")
    
    print("✓ RPC connect() attempts real connection test passed!")
end

-- Run the test
test_rpc_connect_attempts_real_connection() 