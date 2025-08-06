package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua'

local socket = require("socket")
local json = require("cjson")

print("=== Server Response Test ===")

-- Connect to server
local tcp = socket.tcp()
tcp:settimeout(10)
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

-- Receive response
print("📝 Waiting for response...")
local response, err = tcp:receive("*a")
tcp:close()

if not response then
    print("❌ Failed to receive response:", err)
    return
end

print("✅ Received response:")
print("Raw response:", response)
print("Response length:", #response)
print("Response bytes:", string.byte(response, 1, math.min(50, #response)))

-- Try to parse as JSON
local success, parsed = pcall(json.decode, response)
if success then
    print("✅ Parsed JSON successfully:")
    print(json.encode(parsed, {indent = true}))
else
    print("❌ Failed to parse JSON:", parsed)
end

print("=== Test completed ===") 