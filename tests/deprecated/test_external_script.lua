package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

local M = require("paragonic")

print("=== External Script Test ===")

-- Test the hello method and check what happens
print("📝 Testing hello method...")

-- Create a simple test request
local request = {
	jsonrpc = "2.0",
	method = "hello",
	params = {},
	id = 1,
}

-- Write request to file
local request_file = "/tmp/test_request.json"
local response_file = "/tmp/test_response.json"

local f = io.open(request_file, "w")
if f then
	f:write(vim.json.encode(request))
	f:close()
	print("✅ Request written to", request_file)
else
	print("❌ Failed to write request file")
	return
end

-- Create the external script manually
local script_content = [[
-- External RPC script
package.path = package.path .. "]] .. string.format("%s/lua/?.lua;%s/lua/?/init.lua", vim.fn.getcwd(), vim.fn.getcwd()) .. [["

local socket = require("socket")
local json = require("cjson")

-- Read request
local request_file = "]] .. string.format("%s", request_file) .. [["
local response_file = "]] .. string.format("%s", response_file) .. [["

print("DEBUG: Reading request from", request_file)
local request_content = io.open(request_file, "r"):read("*a")
local request = json.decode(request_content)
print("DEBUG: Request decoded successfully")

-- Parse server address
local server_addr = "]] .. string.format("%s", "127.0.0.1:3000") .. [["
local host, port = server_addr:match("([^:]+):?([0-9]*)")
port = port or "3000"
print("DEBUG: Connecting to", host, "port", port)

-- Connect to server
local tcp = socket.tcp()
tcp:settimeout(5)  -- Shorter timeout
local success, err = tcp:connect(host, tonumber(port))

if not success then
    print("DEBUG: Connection failed:", err)
    local error_response = json.encode({
        jsonrpc = "2.0",
        error = {code = -1, message = "Connection failed: " .. err},
        id = request.id
    })
    io.open(response_file, "w"):write(error_response):close()
    os.exit(1)
end

print("DEBUG: Connected successfully")

-- Send request
local request_json = json.encode(request)
print("DEBUG: Sending request:", request_json)
tcp:send(request_json .. "\n")

-- Receive response with shorter timeout
print("DEBUG: Waiting for response...")
tcp:settimeout(5)  -- 5 second timeout for receive

-- Try to receive response line by line
local response, err = tcp:receive("*l")  -- Receive line by line
tcp:close()

if not response then
    print("DEBUG: Failed to receive response:", err)
    local error_response = json.encode({
        jsonrpc = "2.0",
        error = {code = -1, message = "Failed to receive response: " .. (err or "timeout")},
        id = request.id
    })
    io.open(response_file, "w"):write(error_response):close()
    os.exit(1)
end

print("DEBUG: Received response:", response)

-- Trim any trailing whitespace/newlines
response = response:gsub("%s+$", "")

-- Write response to file
print("DEBUG: Writing response to", response_file)
io.open(response_file, "w"):write(response):close()
print("DEBUG: Script completed successfully")
]]

-- Write script to file
local script_file = "/tmp/debug_script.lua"
local f = io.open(script_file, "w")
if f then
	f:write(script_content)
	f:close()
	print("✅ Debug script written to", script_file)
else
	print("❌ Failed to write debug script")
	return
end

-- Execute with shorter timeout
print("📝 Executing debug script...")
local result = vim.fn.system("lua " .. script_file)
print("Script execution result:", result)

-- Check if response file exists
if vim.fn.filereadable(response_file) == 1 then
	local response_content = vim.fn.readfile(response_file)
	print("✅ Response file found, content:", table.concat(response_content, "\n"))
else
	print("❌ Response file not found")
end

-- Clean up
vim.fn.delete(script_file)
vim.fn.delete(request_file)
vim.fn.delete(response_file)

print("=== External script test completed ===")
