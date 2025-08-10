--[[
Test for chat interface integration with RPC backend - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"

-- Test that chat interface can send messages via RPC
local function test_chat_interface_send_message()
    print("Testing chat interface send message...")
    
    -- Load the paragonic module
    local paragonic = require("paragonic")
    
    -- Initialize backend to get RPC client
    local success = paragonic.backend.initialize_backend()
    assert(success, "Backend initialization should succeed")
    
    -- Get RPC client (should be available after initialization)
    local rpc_client = paragonic.backend._get_rpc_client()
    assert(rpc_client ~= nil, "Should have RPC client")
    assert(rpc_client:is_connected(), "RPC client should be connected")
    
    -- Test that we can send a chat message
    local response = rpc_client:chat_completion("llama2", "Hello, this is a test message")
    assert(response ~= nil, "Should get response from chat completion")
    assert(type(response) == "string", "Response should be string")
    assert(response:find('"jsonrpc"'), "Should contain jsonrpc field")
    
    print("✓ Chat interface send message test passed!")
end

-- Test that chat interface can list models
local function test_chat_interface_list_models()
    print("Testing chat interface list models...")
    
    -- Load the paragonic module
    local paragonic = require("paragonic")
    
    -- Initialize backend to get RPC client
    local success = paragonic.backend.initialize_backend()
    assert(success, "Backend initialization should succeed")
    
    -- Get RPC client
    local rpc_client = paragonic.backend._get_rpc_client()
    assert(rpc_client ~= nil, "Should have RPC client")
    
    -- Test that we can list models
    local response = rpc_client:list_models()
    assert(response ~= nil, "Should get response from list_models")
    assert(type(response) == "string", "Response should be string")
    assert(response:find('"jsonrpc"'), "Should contain jsonrpc field")
    
    print("✓ Chat interface list models test passed!")
end

-- Run the tests
test_chat_interface_send_message()
test_chat_interface_list_models() 