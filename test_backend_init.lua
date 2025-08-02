--[[
Test for _initialize_backend() function - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"

-- Test that _initialize_backend() establishes RPC connection
local function test_backend_init_establishes_rpc_connection()
    print("Testing _initialize_backend() establishes RPC connection...")
    
    -- Load the paragonic module
    local paragonic = require("paragonic")
    
    -- Check if backend is initialized before
    local rpc_client_before = paragonic._rpc_client
    
    -- Call _initialize_backend
    paragonic._initialize_backend()
    
    -- Should have created an RPC client
    local rpc_client_after = paragonic._rpc_client
    assert(rpc_client_after ~= nil, "Should create RPC client")
    assert(rpc_client_after ~= rpc_client_before, "Should create new RPC client")
    
    -- RPC client should be connected
    assert(rpc_client_after:is_connected(), "RPC client should be connected")
    
    print("✓ _initialize_backend() establishes RPC connection test passed!")
end

-- Run the test
test_backend_init_establishes_rpc_connection() 