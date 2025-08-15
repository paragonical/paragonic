-- Simple MCP test
local mcp = require("lua.paragonic.mcp_http_transport")

print("🧪 Simple MCP test...")

-- Initialize MCP transport
local success, err = mcp.init({
    base_url = "http://localhost:3000",
    protocol_version = "2025-06-18",
    initialization_timeout = 30,
    request_timeout = 60,
})

if not success then
    print("❌ MCP initialization failed: " .. (err or "unknown error"))
    return
end

print("✅ MCP transport initialized")

-- Test a simple ping request
local ping_request = {
    jsonrpc = "2.0",
    method = "ping",
    id = 1,
    params = {}
}

local response, err = mcp.send_request(ping_request)
if response then
    print("✅ Ping successful")
    print("📤 Response: " .. (response.result and "has result" or "no result"))
else
    print("❌ Ping failed: " .. (err or "unknown error"))
end

print("🔄 Test completed")
