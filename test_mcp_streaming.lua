-- Test streaming functionality directly with MCP HTTP transport
local mcp = require("lua.paragonic.mcp_http_transport")

print("🧪 Testing MCP streaming functionality...")

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

print("✅ Session initialized")

-- Test streaming chat completion
local function test_streaming()
    print("🚀 Testing streaming chat completion...")
    
    local request = {
        jsonrpc = "2.0",
        method = "tools/call",
        id = 1,
        params = {
            name = "streaming_chat_completion",
            arguments = {
                message = "hello world",
                model = "deepseek-r1:1.5b"
            },
            _meta = {
                progressToken = "test_mcp_streaming_123"
            }
        }
    }
    
    local response, err = mcp.send_request(request)
    if response then
        print("✅ Streaming request sent successfully")
        print("📤 Response: " .. (response.result and "has result" or "no result"))
    else
        print("❌ Streaming request failed: " .. (err or "unknown error"))
    end
end

-- Wait a moment for initialization to complete, then test
vim.defer_fn(test_streaming, 1000)

-- Keep the test running for a while to receive streaming events
vim.defer_fn(function()
    print("🔄 Test completed")
    mcp.shutdown()
end, 15000) -- 15 seconds
