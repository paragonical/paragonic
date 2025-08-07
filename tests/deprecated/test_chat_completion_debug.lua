#!/usr/bin/env lua

--[[
Test Chat Completion Debug
Simple test to debug the chat completion hanging issue
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

print("Testing chat completion debug...")

-- Load the paragonic module
local M = require("paragonic")

print("Module loaded successfully")

-- Explicitly initialize the backend
print("Initializing backend...")
local init_success = M.initialize_backend()
if not init_success then
    print("❌ Backend initialization failed")
    return
end

print("✅ Backend initialized successfully")

-- Get RPC client
local rpc_client = M._get_rpc_client()
if not rpc_client then
    print("❌ RPC client not available")
    return
end

print("✅ RPC client available")

-- Test hello method first (we know this works)
print("Testing hello method...")
local hello_response = rpc_client:hello()
if hello_response then
    print("✅ Hello method works: " .. tostring(hello_response))
else
    print("❌ Hello method failed")
    return
end

-- Test chat completion method directly
print("Testing chat completion method directly...")
print("  📝 Calling rpc_client:chat_completion('llama2', 'Test message')...")

local chat_response = rpc_client:chat_completion("llama2", "Test message")
print("  📝 Chat completion call completed")

if chat_response then
    print("✅ Chat completion successful!")
    print("📝 Response type: " .. type(chat_response))
    print("📝 Response length: " .. #tostring(chat_response) .. " characters")
    print("📝 Response preview: " .. tostring(chat_response):sub(1, 100) .. "...")
else
    print("❌ Chat completion failed or returned nil")
end

print("Test completed.") 