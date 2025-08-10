-- Test RPC fallback mechanism
local M = {}

function M.test_rpc_fallback()
    print("=== Testing RPC Fallback Mechanism ===")
    
    local chat = require("paragonic.chat")
    
    -- Test thinking streaming with fallback
    print("Testing send_message_thinking_streaming with fallback...")
    
    local success, err = chat.send_message_thinking_streaming(
        "Create a parts list for a Stirling engine.",
        "deepseek-r1:1.5b",
        function(chunk, chunk_index, total_chunks, chunk_type)
            print(string.format("Chunk received: type=%s, index=%d, total=%d, length=%d", 
                chunk_type or "unknown", chunk_index or 0, total_chunks or 0, #chunk))
        end,
        function()
            print("Streaming completed")
        end
    )
    
    if not success then
        print("❌ send_message_thinking_streaming failed:", err)
        return false
    end
    
    print("✅ send_message_thinking_streaming with fallback successful")
    
    -- Test regular streaming with fallback
    print("Testing send_message_streaming with fallback...")
    
    local success2, err2 = chat.send_message_streaming(
        "What is a Stirling engine?",
        "llama2",
        function(chunk, chunk_index, total_chunks)
            print(string.format("Chunk received: index=%d, total=%d, length=%d", 
                chunk_index or 0, total_chunks or 0, #chunk))
        end,
        function()
            print("Streaming completed")
        end
    )
    
    if not success2 then
        print("❌ send_message_streaming failed:", err2)
        return false
    end
    
    print("✅ send_message_streaming with fallback successful")
    
    -- Test smart send with fallback
    print("Testing send_message_smart with fallback...")
    
    local success3, err3 = chat.send_message_smart(
        "Explain quantum computing.",
        "deepseek-r1:1.5b"
    )
    
    if not success3 then
        print("❌ send_message_smart failed:", err3)
        return false
    end
    
    print("✅ send_message_smart with fallback successful")
    
    print("✅ All RPC fallback tests passed!")
    return true
end

return M
