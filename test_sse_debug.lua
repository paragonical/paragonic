-- Test SSE connection debugging
local sse_client = require("lua.paragonic.sse_client")

-- Initialize SSE client
sse_client.init({
    base_url = "http://localhost:3000",
    timeout = 30,
})

-- Set up callbacks
local callbacks = {
    on_connect = function(stream_id)
        print("🟢 SSE Connected to stream: " .. stream_id)
    end,
    on_message = function(event)
        print("📨 SSE Message: " .. (event.data or "no data"))
    end,
    on_notification = function(event)
        print("🔔 SSE Notification: " .. (event.data or "no data"))
    end,
    on_error = function(error_msg, attempt)
        print("❌ SSE Error: " .. error_msg .. " (attempt " .. attempt .. ")")
    end,
    on_disconnect = function()
        print("🔴 SSE Disconnected")
    end,
    on_parse_error = function(error_msg, raw_event)
        print("⚠️ SSE Parse Error: " .. error_msg)
        print("Raw event: " .. (raw_event or "none"))
    end,
}

-- Try to connect
print("🔗 Attempting SSE connection...")
local success, err = sse_client.connect("test-debug", callbacks)

if success then
    print("✅ SSE connection initiated successfully")
    
    -- Keep the connection alive for a bit
    vim.defer_fn(function()
        print("🔄 Disconnecting SSE...")
        sse_client.disconnect()
        print("✅ Test complete")
    end, 10000) -- 10 seconds
else
    print("❌ SSE connection failed: " .. (err or "unknown error"))
end
