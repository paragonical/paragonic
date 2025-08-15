-- Test SSE connection
local sse_client = require("lua.paragonic.sse_client")

-- Initialize SSE client
sse_client.init({
    base_url = "http://localhost:3000"
})

print("🧪 Testing SSE connection...")

-- Set up callbacks
local callbacks = {
    on_connect = function(stream_id)
        print("✅ SSE connected to stream: " .. stream_id)
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

-- Try to connect
local success, err = sse_client.connect("test-stream", callbacks)
if success then
    print("✅ SSE connection initiated successfully")
    
    -- Keep connection alive for a few seconds
    vim.defer_fn(function()
        print("🔄 Disconnecting SSE...")
        sse_client.disconnect()
        print("✅ Test completed")
    end, 5000)
else
    print("❌ SSE connection failed: " .. (err or "unknown error"))
end
