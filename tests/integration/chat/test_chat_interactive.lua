--[[
Test for chat interface interactive features - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"

-- Test that chat interface has send_message function
local function test_chat_interface_has_send_function()
    print("Testing chat interface has send_message function...")
    
    -- Load the paragonic module
    local paragonic = require("paragonic")
    
    -- Should have send_message function
    assert(type(paragonic.chat.send_message) == "function", "Should have send_message function")
    
    -- Should have get_available_models function
    assert(type(paragonic.backend.get_available_models) == "function", "Should have get_available_models function")
    
    print("✓ Chat interface has send_message function test passed!")
end

-- Test that send_message can communicate with backend
local function test_send_message_communicates_with_backend()
    print("Testing send_message communicates with backend...")
    
    -- Load the paragonic module
    local paragonic = require("paragonic")
    
    -- Test sending a message
    local response = paragonic.chat.send_message("Hello, this is a test message", "llama2")
    assert(response ~= nil, "Should get response from send_message")
    assert(type(response) == "string", "Response should be string")
    
    print("✓ send_message communicates with backend test passed!")
end

-- Run the tests
test_chat_interface_has_send_function()
test_send_message_communicates_with_backend() 