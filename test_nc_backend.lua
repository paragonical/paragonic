#!/usr/bin/env lua

-- Test script to verify nc communication with backend
print("=== Testing nc communication with backend ===")

-- Test the nc command that would be used
local request = {
    jsonrpc = "2.0",
    method = "hello",
    params = {},
    id = 1
}

local request_json = vim.json.encode(request)
local message = request_json .. "\n"

print("Request JSON:", request_json)
print("Message:", message)

-- Test the nc command
local host, port = "127.0.0.1", "3000"
local nc_command = string.format("echo '%s' | nc %s %s", message:gsub("'", "'\"'\"'"), host, port)

print("NC command:", nc_command)

-- Execute the command
local result = vim.fn.system(nc_command)
local exit_code = vim.v.shell_error

print("Exit code:", exit_code)
print("Result:", result)

if exit_code == 0 then
    print("✅ Successfully communicated with backend via nc")
else
    print("❌ Failed to communicate with backend via nc")
end

print("=== Test Complete ===") 