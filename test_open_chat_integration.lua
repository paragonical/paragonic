--[[
Test for open_chat() function integration - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"

-- Test that open_chat() creates buffer with RPC integration
local function test_open_chat_creates_buffer_with_rpc()
    print("Testing open_chat() creates buffer with RPC integration...")
    
    -- Load the paragonic module
    local paragonic = require("paragonic")
    
    -- Count chat buffers before
    local buffers_before = vim.api.nvim_list_bufs()
    local chat_buffers_before = 0
    for _, buf in ipairs(buffers_before) do
        local name = vim.api.nvim_buf_get_name(buf)
        if name == "paragonic://chat" then
            chat_buffers_before = chat_buffers_before + 1
        end
    end
    
    -- Call open_chat
    paragonic.open_chat()
    
    -- Count chat buffers after
    local buffers_after = vim.api.nvim_list_bufs()
    local chat_buffers_after = 0
    for _, buf in ipairs(buffers_after) do
        local name = vim.api.nvim_buf_get_name(buf)
        if name == "paragonic://chat" then
            chat_buffers_after = chat_buffers_after + 1
        end
    end
    
    -- Should have created a chat buffer
    assert(chat_buffers_after > chat_buffers_before, "Should create a chat buffer")
    
    -- Should have RPC client available
    local rpc_client = paragonic._get_rpc_client()
    assert(rpc_client ~= nil, "Should have RPC client available")
    assert(rpc_client:is_connected(), "RPC client should be connected")
    
    print("✓ open_chat() creates buffer with RPC integration test passed!")
end

-- Run the test
test_open_chat_creates_buffer_with_rpc() 