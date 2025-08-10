-- Quick test to verify streaming methods are available
local M = {}

function M.test_streaming_methods()
    print("=== Testing Streaming Methods ===")
    
    local backend = require("paragonic.backend")
    local rpc_client = backend._get_rpc_client()
    
    if not rpc_client then
        print("❌ RPC client not available")
        return false
    end
    
    print("✅ RPC client available")
    
    -- Test if streaming methods exist
    if rpc_client.streaming_chat_completion then
        print("✅ streaming_chat_completion method exists")
    else
        print("❌ streaming_chat_completion method missing")
        return false
    end
    
    if rpc_client.get_next_chunk then
        print("✅ get_next_chunk method exists")
    else
        print("❌ get_next_chunk method missing")
        return false
    end
    
    -- Test calling the method
    local response = rpc_client:streaming_chat_completion({
        model = "deepseek-r1:1.5b",
        message = "Test message",
        chunk_size = 50
    })
    
    if response then
        print("✅ streaming_chat_completion call successful")
        print("Response length:", #response)
    else
        print("❌ streaming_chat_completion call failed")
        return false
    end
    
    return true
end

return M
