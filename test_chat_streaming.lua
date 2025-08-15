-- Test streaming chat functionality using the backend client
local backend = require("lua.paragonic.backend")

print("🧪 Testing streaming chat functionality...")

-- Initialize the backend
local success = backend.initialize_backend()

if not success then
    print("❌ Backend initialization failed")
    return
end

print("✅ Backend initialized successfully")

-- Test streaming chat completion
local function test_streaming_chat()
    print("🚀 Testing streaming chat completion...")
    
    local on_chunk = function(chunk, index, total, chunk_type)
        print("📦 Chunk " .. index .. "/" .. total .. " (" .. chunk_type .. "): " .. chunk)
    end
    
    local on_complete = function()
        print("✅ Streaming completed")
    end
    
    local result, err = backend.streaming_chat_completion({
        message = "hello world",
        model = "deepseek-r1:1.5b"
    }, on_chunk, on_complete)
    
    if result then
        print("✅ Streaming request successful")
    else
        print("❌ Streaming request failed: " .. (err or "unknown error"))
    end
end

-- Wait a moment for initialization to complete, then test
vim.defer_fn(test_streaming_chat, 1000)

-- Keep the test running for a while to receive streaming events
vim.defer_fn(function()
    print("🔄 Test completed")
end, 20000) -- 20 seconds
