-- Test script to verify Paragonic plugin installation
-- Run this in Neovim to test if the plugin loads correctly

print("=== Testing Paragonic Plugin Installation ===")

-- Try to load the plugin
local success, paragonic = pcall(require, 'paragonic')

if success then
    print("✅ Plugin loaded successfully!")
    
    -- Test basic functionality
    print("\n🧪 Testing basic functionality...")
    
    -- Test session start
    local session_id = paragonic.start_ai_agent_session("TestAgent")
    if session_id then
        print("  ✅ Session started: " .. session_id)
        
        -- Test session status
        local status = paragonic.get_ai_agent_session_status()
        if status.active then
            print("  ✅ Session status: " .. status.agent_name)
        else
            print("  ❌ Session status failed")
        end
        
        -- Test message sending
        local msg_success, msg_id = paragonic.send_ai_agent_message("Test message")
        if msg_success then
            print("  ✅ Message sent: " .. msg_id)
        else
            print("  ❌ Message failed: " .. msg_id)
        end
        
        -- Test command execution
        local cmd_success, cmd_id = paragonic.execute_ai_agent_command("echo 'Test command'")
        if cmd_success then
            print("  ✅ Command executed: " .. cmd_id)
        else
            print("  ❌ Command failed: " .. cmd_id)
        end
        
        -- Test buffer operations
        local buf_success, buf_id, buf_result = paragonic.get_ai_agent_buffer_content()
        if buf_success then
            print("  ✅ Buffer read: " .. buf_id .. " (" .. buf_result.line_count .. " lines)")
        else
            print("  ❌ Buffer read failed: " .. buf_id)
        end
        
        -- Stop session
        paragonic.stop_ai_agent_session()
        print("  ✅ Session stopped")
        
    else
        print("  ❌ Session start failed")
    end
    
    print("\n🎉 All tests passed! Plugin is working correctly.")
    
else
    print("❌ Failed to load plugin: " .. tostring(paragonic))
    print("\n📝 Troubleshooting:")
    print("   1. Make sure the plugin is installed correctly")
    print("   2. Check that 'require(\"paragonic\")' is in your Neovim config")
    print("   3. Verify the lua/paragonic/ directory exists")
    print("   4. Check for any Lua errors in :messages")
end

print("\n=== Installation Test Complete ===") 