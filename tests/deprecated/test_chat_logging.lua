#!/usr/bin/env lua

--[[
Test Chat Logging
Simple test to verify server logging for chat completion requests
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

print("Testing chat completion with server logging...")

-- Load the paragonic module
local M = require("paragonic")

print("Module loaded successfully")

-- Test a simple chat completion request
print("Sending chat completion request...")
local response, err = M.send_message("Write a short poem about debugging", "llama2")

if response then
	print("✅ Chat completion successful!")
	print("📝 Response length: " .. #response .. " characters")
	print("📝 Response preview: " .. response:sub(1, 100) .. "...")
else
	print("❌ Chat completion failed: " .. tostring(err))
end

print("Test completed. Check server logs for RPC request/response logging.")
