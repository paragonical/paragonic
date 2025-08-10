#!/usr/bin/env lua

--[[
Test RPC Connection
Simple test to verify RPC connection and debug chat completion
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

print("Testing RPC connection...")

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

-- Test hello method first
print("Testing hello method...")
local rpc_client = M._get_rpc_client()
if rpc_client then
    print("✅ RPC client available")
    
    local hello_response = rpc_client:hello()
    if hello_response then
        print("✅ Hello method works: " .. tostring(hello_response))
    else
        print("❌ Hello method failed")
    end
else
    print("❌ RPC client not available")
    return
end

-- Test chat completion with debug logging
print("Testing chat completion method...")
local response, err = M.send_message("Test message", "llama2")

if response then
    print("✅ Chat completion successful!")
    print("📝 Response length: " .. #response .. " characters")
    print("📝 Response preview: " .. response:sub(1, 100) .. "...")
else
    print("❌ Chat completion failed: " .. tostring(err))
end

print("Test completed. Check server logs for RPC request/response logging.") 