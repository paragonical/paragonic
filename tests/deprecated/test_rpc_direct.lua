--[[
Direct test of RPC client
--]]

package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua'

local socket = require("socket")
local json = require("cjson")

print("=== Direct RPC Test ===")

-- Test direct connection to server
local tcp = socket.tcp()
tcp:settimeout(5)
local success, err = tcp:connect("127.0.0.1", 3000)

if not success then
    print("❌ Connection failed:", err)
    return
end

print("✅ Connected to server")

-- Send hello request
local request = {
    jsonrpc = "2.0",
    method = "hello",
    params = {},
    id = 1
}

local request_json = json.encode(request)
print("📝 Sending request:", request_json)
tcp:send(request_json .. "\n")

-- Try to receive response
print("📝 Waiting for response...")
local response, err = tcp:receive("*l")  -- Try line by line instead
tcp:close()

if not response then
    print("❌ Failed to receive response:", err)
    return
end

print("✅ Received response:", response)

-- Try to parse as JSON
local success, parsed = pcall(json.decode, response)
if success then
    print("✅ Parsed JSON successfully:")
    print(json.encode(parsed, {indent = true}))
else
    print("❌ Failed to parse JSON:", parsed)
end

print("=== Direct test completed ===") 