-- Test SSE streaming with actual streaming request
local sse_client = require("lua.paragonic.sse_client")
local http_client = require("lua.paragonic.http_client")

-- Initialize clients
sse_client.init({
    base_url = "http://localhost:3000"
})
http_client.init({
    base_url = "http://localhost:3000"
})

print("🧪 Testing SSE streaming...")

-- Set up SSE callbacks
local callbacks = {
    on_connect = function(stream_id)
        print("✅ SSE connected to stream: " .. stream_id)
        
        -- After SSE connection is established, trigger a streaming request
        vim.defer_fn(function()
            print("🚀 Triggering streaming request...")
            
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
                        progressToken = "test_streaming_123"
                    }
                }
            }
            
            local response = http_client.post("/mcp", request)
            if response then
                print("📤 Streaming request sent, response: " .. (response.status or "no status"))
            else
                print("❌ Failed to send streaming request")
            end
        end, 1000) -- Wait 1 second for SSE connection to stabilize
    end,
    on_disconnect = function()
        print("❌ SSE disconnected")
    end,
    on_message = function(event)
        print("📨 SSE message: " .. (event.data or "no data"))
    end,
    on_notification = function(event)
        print("🔔 SSE notification: " .. (event.data or "no data"))
    end,
    on_error = function(error_msg, attempt)
        print("⚠️ SSE error: " .. error_msg .. " (attempt " .. attempt .. ")")
    end
}

-- Connect to SSE
local success, err = sse_client.connect("test-streaming", callbacks)
if success then
    print("✅ SSE connection initiated successfully")
    
    -- Keep connection alive for longer to receive streaming events
    vim.defer_fn(function()
        print("🔄 Disconnecting SSE...")
        sse_client.disconnect()
        print("✅ Test completed")
    end, 15000) -- 15 seconds to allow time for streaming
else
    print("❌ SSE connection failed: " .. (err or "unknown error"))
end
