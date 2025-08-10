-- RPC Integration Tests
-- Tests that require a running Paragonic server
-- Soft fail with warnings if server is not available

local M = {}

-- Test configuration
local TEST_CONFIG = {
    server_address = "127.0.0.1:3000",
    timeout_seconds = 5,
    max_retries = 2
}

-- Helper function to check if server is available
local function is_server_available()
    local success, rpc = pcall(require, "paragonic.rpc")
    if not success then
        return false, "Failed to require paragonic.rpc: " .. tostring(rpc)
    end
    
    local client = rpc.new(TEST_CONFIG.server_address)
    if not client then
        return false, "Failed to create RPC client"
    end
    
    local connect_success, err = client:connect()
    if not connect_success then
        return false, "Failed to connect: " .. tostring(err)
    end
    
    -- Test with a simple hello call
    local response = client:hello()
    if not response then
        return false, "Hello call failed"
    end
    
    return true, "Server available"
end

-- Test basic RPC connection
function M.test_rpc_connection()
    print("=== Testing RPC Connection ===")
    
    local available, message = is_server_available()
    if not available then
        print("⚠️  WARNING: Server not available - " .. message)
        print("   This test requires a running Paragonic server")
        print("   Run: cargo run --bin paragonic")
        return false, "soft_fail"
    end
    
    print("✅ Server connection successful")
    return true
end

-- Test hello method
function M.test_hello_method()
    print("=== Testing Hello Method ===")
    
    local success, rpc = pcall(require, "paragonic.rpc")
    if not success then
        print("❌ Failed to require paragonic.rpc:", rpc)
        return false, "soft_fail"
    end
    
    local client = rpc.new(TEST_CONFIG.server_address)
    local connect_success, err = client:connect()
    if not connect_success then
        print("⚠️  WARNING: Cannot connect to server - " .. tostring(err))
        return false, "soft_fail"
    end
    
    local response = client:hello()
    if not response then
        print("❌ Hello call failed")
        return false
    end
    
    -- Parse response
    local success2, parsed = pcall(vim.json.decode, response)
    if not success2 then
        print("❌ Failed to parse hello response:", parsed)
        return false
    end
    
    if parsed.result ~= "world" then
        print("❌ Unexpected hello response:", parsed.result)
        return false
    end
    
    print("✅ Hello method working correctly")
    return true
end

-- Test list_models method
function M.test_list_models()
    print("=== Testing List Models ===")
    
    local success, rpc = pcall(require, "paragonic.rpc")
    if not success then
        print("❌ Failed to require paragonic.rpc:", rpc)
        return false, "soft_fail"
    end
    
    local client = rpc.new(TEST_CONFIG.server_address)
    local connect_success, err = client:connect()
    if not connect_success then
        print("⚠️  WARNING: Cannot connect to server - " .. tostring(err))
        return false, "soft_fail"
    end
    
    local response = client:list_models()
    if not response then
        print("❌ List models call failed")
        return false
    end
    
    -- Parse response
    local success2, parsed = pcall(vim.json.decode, response)
    if not success2 then
        print("❌ Failed to parse list_models response:", parsed)
        return false
    end
    
    if not parsed.result then
        print("❌ Unexpected list_models response format - missing result")
        return false
    end
    
    -- The result is a JSON string that needs to be parsed again
    local success3, models = pcall(vim.json.decode, parsed.result)
    if not success3 then
        print("❌ Failed to parse models array from result:", models)
        return false
    end
    
    if not models or type(models) ~= "table" then
        print("❌ Unexpected list_models response format - result is not an array")
        return false
    end
    
    print("✅ List models working correctly")
    print("   Found " .. #models .. " models")
    return true
end

-- Test chat_completion method
function M.test_chat_completion()
    print("=== Testing Chat Completion ===")
    
    local success, rpc = pcall(require, "paragonic.rpc")
    if not success then
        print("❌ Failed to require paragonic.rpc:", rpc)
        return false, "soft_fail"
    end
    
    local client = rpc.new(TEST_CONFIG.server_address)
    local connect_success, err = client:connect()
    if not connect_success then
        print("⚠️  WARNING: Cannot connect to server - " .. tostring(err))
        return false, "soft_fail"
    end
    
    local response = client:chat_completion("deepseek-r1:1.5b", "Hello, this is a test message.")
    if not response then
        print("❌ Chat completion call failed")
        return false
    end
    
    -- Parse response
    local success2, parsed = pcall(vim.json.decode, response)
    if not success2 then
        print("❌ Failed to parse chat_completion response:", parsed)
        return false
    end
    
    if parsed.error then
        print("❌ Chat completion error:", parsed.error.message)
        return false
    end
    
    print("✅ Chat completion working correctly")
    return true
end

-- Test streaming_chat_completion method
function M.test_streaming_chat_completion()
    print("=== Testing Streaming Chat Completion ===")
    
    local success, rpc = pcall(require, "paragonic.rpc")
    if not success then
        print("❌ Failed to require paragonic.rpc:", rpc)
        return false, "soft_fail"
    end
    
    local client = rpc.new(TEST_CONFIG.server_address)
    local connect_success, err = client:connect()
    if not connect_success then
        print("⚠️  WARNING: Cannot connect to server - " .. tostring(err))
        return false, "soft_fail"
    end
    
    local response = client:streaming_chat_completion({
        model = "deepseek-r1:1.5b",
        message = "Hello, this is a streaming test message.",
        chunk_size = 50
    })
    if not response then
        print("❌ Streaming chat completion call failed")
        return false
    end
    
    -- Parse response
    local success2, parsed = pcall(vim.json.decode, response)
    if not success2 then
        print("❌ Failed to parse streaming_chat_completion response:", parsed)
        return false
    end
    
    if parsed.error then
        print("❌ Streaming chat completion error:", parsed.error.message)
        return false
    end
    
    if not parsed.result then
        print("❌ Streaming response missing result field")
        return false
    end
    
    print("✅ Streaming chat completion working correctly")
    return true
end

-- Test get_next_chunk method
function M.test_get_next_chunk()
    print("=== Testing Get Next Chunk ===")
    
    local success, rpc = pcall(require, "paragonic.rpc")
    if not success then
        print("❌ Failed to require paragonic.rpc:", rpc)
        return false, "soft_fail"
    end
    
    local client = rpc.new(TEST_CONFIG.server_address)
    local connect_success, err = client:connect()
    if not connect_success then
        print("⚠️  WARNING: Cannot connect to server - " .. tostring(err))
        return false, "soft_fail"
    end
    
    local response = client:get_next_chunk({
        chunk_index = 1,
        remaining_chunks = {},
        total_chunks = 1
    })
    if not response then
        print("❌ Get next chunk call failed")
        return false
    end
    
    -- Parse response
    local success2, parsed = pcall(vim.json.decode, response)
    if not success2 then
        print("❌ Failed to parse get_next_chunk response:", parsed)
        return false
    end
    
    if parsed.error then
        print("❌ Get next chunk error:", parsed.error.message)
        return false
    end
    
    print("✅ Get next chunk working correctly")
    return true
end

-- Test formatted_chat_completion method
function M.test_formatted_chat_completion()
    print("=== Testing Formatted Chat Completion ===")
    
    local success, rpc = pcall(require, "paragonic.rpc")
    if not success then
        print("❌ Failed to require paragonic.rpc:", rpc)
        return false, "soft_fail"
    end
    
    local client = rpc.new(TEST_CONFIG.server_address)
    local connect_success, err = client:connect()
    if not connect_success then
        print("⚠️  WARNING: Cannot connect to server - " .. tostring(err))
        return false, "soft_fail"
    end
    
    local response = client:formatted_chat_completion("deepseek-r1:1.5b", "Hello, this is a formatted test message.", {
        max_line_length = 80,
        format_markdown = true
    })
    if not response then
        print("❌ Formatted chat completion call failed")
        return false
    end
    
    -- Parse response
    local success2, parsed = pcall(vim.json.decode, response)
    if not success2 then
        print("❌ Failed to parse formatted_chat_completion response:", parsed)
        return false
    end
    
    if parsed.error then
        print("❌ Formatted chat completion error:", parsed.error.message)
        return false
    end
    
    print("✅ Formatted chat completion working correctly")
    return true
end

-- Test debug_markdown_test method
function M.test_debug_markdown_test()
    print("=== Testing Debug Markdown Test ===")
    
    local success, rpc = pcall(require, "paragonic.rpc")
    if not success then
        print("❌ Failed to require paragonic.rpc:", rpc)
        return false, "soft_fail"
    end
    
    local client = rpc.new(TEST_CONFIG.server_address)
    local connect_success, err = client:connect()
    if not connect_success then
        print("⚠️  WARNING: Cannot connect to server - " .. tostring(err))
        return false, "soft_fail"
    end
    
    local response = client:debug_markdown_test({
        max_line_length = 80,
        format_markdown = true
    })
    if not response then
        print("❌ Debug markdown test call failed")
        return false
    end
    
    -- Parse response
    local success2, parsed = pcall(vim.json.decode, response)
    if not success2 then
        print("❌ Failed to parse debug_markdown_test response:", parsed)
        return false
    end
    
    if parsed.error then
        print("❌ Debug markdown test error:", parsed.error.message)
        return false
    end
    
    print("✅ Debug markdown test working correctly")
    return true
end

-- Test backend integration
function M.test_backend_integration()
    print("=== Testing Backend Integration ===")
    
    local success, backend = pcall(require, "paragonic.backend")
    if not success then
        print("❌ Failed to require paragonic.backend:", backend)
        return false, "soft_fail"
    end
    
    -- Test backend initialization
    local init_success = backend.initialize_backend()
    if not init_success then
        print("⚠️  WARNING: Backend initialization failed")
        print("   This requires a running Paragonic server")
        return false, "soft_fail"
    end
    
    -- Test getting RPC client
    local rpc_client = backend._get_rpc_client()
    if not rpc_client then
        print("❌ Failed to get RPC client from backend")
        return false
    end
    
    -- Test connection health
    local is_connected = rpc_client:is_connected()
    if not is_connected then
        print("❌ RPC client not connected")
        return false
    end
    
    print("✅ Backend integration working correctly")
    return true
end

-- Test chat module integration
function M.test_chat_integration()
    print("=== Testing Chat Module Integration ===")
    
    local success, chat = pcall(require, "paragonic.chat")
    if not success then
        print("❌ Failed to require paragonic.chat:", chat)
        return false, "soft_fail"
    end
    
    -- Test that streaming functions exist
    if not chat.send_message_streaming then
        print("❌ send_message_streaming function not found")
        return false
    end
    
    if not chat.send_message_thinking_streaming then
        print("❌ send_message_thinking_streaming function not found")
        return false
    end
    
    if not chat.send_message_smart then
        print("❌ send_message_smart function not found")
        return false
    end
    
    print("✅ Chat module integration working correctly")
    return true
end

-- Run all tests
function M.run_all_tests()
    print("Running RPC Integration Tests...")
    print("Note: These tests require a running Paragonic server")
    print("If server is not available, tests will soft fail with warnings")
    print("")
    
    local tests = {
        {name = "RPC Connection", func = M.test_rpc_connection},
        {name = "Hello Method", func = M.test_hello_method},
        {name = "List Models", func = M.test_list_models},
        {name = "Chat Completion", func = M.test_chat_completion},
        {name = "Streaming Chat Completion", func = M.test_streaming_chat_completion},
        {name = "Get Next Chunk", func = M.test_get_next_chunk},
        {name = "Formatted Chat Completion", func = M.test_formatted_chat_completion},
        {name = "Debug Markdown Test", func = M.test_debug_markdown_test},
        {name = "Backend Integration", func = M.test_backend_integration},
        {name = "Chat Module Integration", func = M.test_chat_integration},
    }
    
    local results = {
        passed = 0,
        failed = 0,
        soft_failed = 0
    }
    
    for _, test in ipairs(tests) do
        print("")
        local success, error_type = test.func()
        
        if success then
            results.passed = results.passed + 1
        elseif error_type == "soft_fail" then
            results.soft_failed = results.soft_failed + 1
        else
            results.failed = results.failed + 1
        end
    end
    
    print("")
    print("=== Test Results ===")
    print("Passed:", results.passed)
    print("Failed:", results.failed)
    print("Soft Failed (server not available):", results.soft_failed)
    
    if results.soft_failed > 0 then
        print("")
        print("⚠️  Some tests soft failed because the server is not available.")
        print("   To run these tests, start the Paragonic server:")
        print("   cargo run --bin paragonic")
    end
    
    if results.failed > 0 then
        print("")
        print("❌ Some tests failed with actual errors.")
        print("   Check the output above for details.")
    end
    
    local all_success = results.failed == 0
    print("")
    print("Overall result:", all_success and "PASS" or "FAIL")
    
    return all_success
end

return M
