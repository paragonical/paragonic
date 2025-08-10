-- Simple test for RPC simple module
local M = {}

function M.test_simple_rpc()
    print("=== Testing Simple RPC Module ===")
    
    -- Test requiring the module
    local success, rpc_simple = pcall(require, "paragonic.rpc_simple")
    if not success then
        print("❌ Failed to require paragonic.rpc_simple:", rpc_simple)
        return false
    end
    
    print("✅ paragonic.rpc_simple module loaded")
    
    -- Test creating a client
    local client = rpc_simple.new("127.0.0.1:3000")
    if not client then
        print("❌ Failed to create RPC client")
        return false
    end
    
    print("✅ RPC client created")
    
    -- Test connecting
    local connect_success = client:connect()
    if not connect_success then
        print("❌ Failed to connect")
        return false
    end
    
    print("✅ RPC client connected")
    
    -- Test if streaming methods exist
    if client.streaming_chat_completion then
        print("✅ streaming_chat_completion method exists")
    else
        print("❌ streaming_chat_completion method missing")
        return false
    end
    
    if client.get_next_chunk then
        print("✅ get_next_chunk method exists")
    else
        print("❌ get_next_chunk method missing")
        return false
    end
    
    -- Test calling streaming method
    local response = client:streaming_chat_completion({
        model = "deepseek-r1:1.5b",
        message = "Test message",
        chunk_size = 50
    })
    
    if response then
        print("✅ streaming_chat_completion call successful")
        print("Response length:", #response)
        
        -- Try to parse the response
        local success2, parsed = pcall(vim.json.decode, response)
        if success2 then
            print("✅ Response parsed successfully")
            if parsed.result and parsed.result.type == "streaming_chunk" then
                print("✅ Response has correct streaming_chunk type")
            else
                print("❌ Response doesn't have correct type")
                return false
            end
        else
            print("❌ Failed to parse response:", parsed)
            return false
        end
    else
        print("❌ streaming_chat_completion call failed")
        return false
    end
    
    print("✅ All tests passed!")
    return true
end

return M
