-- Test MCP connection fix
local mcp = require("lua.paragonic.mcp_http_transport")

print("🧪 Testing MCP connection fix...")

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

-- Initialize session
local session_success, session_err = mcp.initialize_session({
    name = "paragonic.nvim",
    version = "1.0.0",
    capabilities = { tools = {}, resources = {}, notifications = {} },
})

if not session_success then
    print("❌ Session initialization failed: " .. (session_err or "unknown error"))
    return
end

print("✅ Session initialized successfully!")

-- Test a simple request
local response, err = mcp.send_request({
    jsonrpc = "2.0",
    method = "tools/list",
    id = 1,
    params = {}
})

if response then
    print("✅ Tools list request successful")
    print("📋 Response: " .. (response.result and "has result" or "no result"))
else
    print("❌ Tools list request failed: " .. (err or "unknown error"))
end

print("🎉 MCP connection test completed!")
