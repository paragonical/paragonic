#!/usr/bin/env lua

-- Test script to verify vim.uv TCP communication
print("=== Testing vim.uv TCP communication ===")

-- Check if vim.uv is available
if not vim.uv then
    print("❌ vim.uv not available")
    return
end

if not vim.uv.new_tcp then
    print("❌ vim.uv.new_tcp not available")
    return
end

print("✅ vim.uv.new_tcp available")

-- Create TCP socket
local socket = vim.uv.new_tcp()
if not socket then
    print("❌ Failed to create TCP socket")
    return
end

print("✅ TCP socket created")

-- Try to connect
local success, err = socket:connect("127.0.0.1", 3000)
if not success then
    print("❌ Failed to connect: " .. tostring(err))
    socket:close()
    return
end

print("✅ Connected to backend")

-- Test communication
local request = {
    jsonrpc = "2.0",
    method = "hello",
    params = {},
    id = 1
}

local request_json = vim.json.encode(request)
local message = request_json .. "\n"

print("Sending request:", message)

-- Synchronous communication test
local response_received = false
local response_data = nil
local response_error = nil

-- Set up read callback
socket:read_start(function(err, data)
    if err then
        response_error = "Failed to receive response: " .. tostring(err)
        response_received = true
    elseif data then
        response_data = data
        response_received = true
    end
end)

-- Send the request
local send_success, send_err = socket:write(message)
if not send_success then
    print("❌ Failed to send request: " .. tostring(send_err))
    socket:close()
    return
end

print("✅ Request sent")

-- Wait for response
local timeout = 10 -- 10 seconds timeout
local start_time = vim.uv.now()

while not response_received do
    if vim.uv.now() - start_time > timeout * 1000 then
        print("❌ Timeout waiting for response")
        socket:close()
        return
    end
    vim.wait(100) -- Wait 100ms
end

if response_error then
    print("❌ Response error: " .. response_error)
else
    print("✅ Response received: " .. response_data)
end

socket:close()
print("=== Test Complete ===") 