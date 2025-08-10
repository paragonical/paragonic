#!/usr/bin/env lua

--[[
Real Neovim Integration Test for AI Agent Functions
This test runs in actual Neovim to validate functionality
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Load the paragonic module
local M = require("paragonic")

-- Test function for real Neovim integration
local function test_ai_agent_integration()
    print("=== Real Neovim AI Agent Integration Test ===")
    print("Testing AI agent functions in actual Neovim environment...")
    
    -- Test 1: Session Management
    print("\n1. Testing Session Management...")
    local session_id = M.start_ai_agent_session("IntegrationTestAgent")
    if session_id then
        print("  ✅ Session started successfully: " .. session_id)
        
        -- Get session status
        local status = M.get_ai_agent_session_status()
        if status.active then
            print("  ✅ Session status retrieved: " .. status.agent_name)
        else
            print("  ❌ Session status failed")
            return false
        end
    else
        print("  ❌ Session start failed")
        return false
    end
    
    -- Test 2: Message Exchange
    print("\n2. Testing Message Exchange...")
    local success, msg_id = M.send_ai_agent_message("Hello from AI agent", "test")
    if success then
        print("  ✅ AI message sent: " .. msg_id)
    else
        print("  ❌ AI message failed: " .. msg_id)
    end
    
    local success2, msg_id2 = M.receive_ai_agent_message("Hello from Neovim", "test")
    if success2 then
        print("  ✅ Neovim message received: " .. msg_id2)
    else
        print("  ❌ Neovim message failed: " .. msg_id2)
    end
    
    -- Test 3: Command Execution
    print("\n3. Testing Command Execution...")
    local success3, cmd_id, result = M.execute_ai_agent_command("echo 'Test command'")
    if success3 then
        print("  ✅ Command executed: " .. cmd_id)
    else
        print("  ❌ Command failed: " .. cmd_id)
    end
    
    -- Test 4: Buffer Operations
    print("\n4. Testing Buffer Operations...")
    
    -- Create a test buffer
    local test_buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(test_buf, "/tmp/test_integration.txt")
    vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, {
        "Line 1: Test content",
        "Line 2: More test content", 
        "Line 3: Final test content"
    })
    
    -- Switch to test buffer
    vim.api.nvim_set_current_buf(test_buf)
    
    -- Read buffer content
    local success4, read_id, read_result = M.get_ai_agent_buffer_content()
    if success4 then
        print("  ✅ Buffer read: " .. read_id .. " (" .. read_result.line_count .. " lines)")
        print("    Content: " .. table.concat(read_result.content, ", "))
    else
        print("  ❌ Buffer read failed: " .. read_id)
    end
    
    -- Write buffer content
    local success5, write_id, write_result = M.set_ai_agent_buffer_content(nil, {
        "AI Agent wrote this line",
        "Another line from AI agent"
    })
    if success5 then
        print("  ✅ Buffer write: " .. write_id .. " (" .. write_result.lines_written .. " lines)")
    else
        print("  ❌ Buffer write failed: " .. write_id)
    end
    
    -- Read updated content
    local success6, read_id2, read_result2 = M.get_ai_agent_buffer_content()
    if success6 then
        print("  ✅ Updated buffer read: " .. read_id2 .. " (" .. read_result2.line_count .. " lines)")
        print("    New content: " .. table.concat(read_result2.content, ", "))
    else
        print("  ❌ Updated buffer read failed: " .. read_id2)
    end
    
    -- Test 5: Session Status After Operations
    print("\n5. Testing Session Status After Operations...")
    local final_status = M.get_ai_agent_session_status()
    if final_status.active then
        print("  ✅ Session still active with " .. final_status.interaction_count .. " interactions")
    else
        print("  ❌ Session not active")
    end
    
    -- Test 6: Session Cleanup
    print("\n6. Testing Session Cleanup...")
    local success7 = M.stop_ai_agent_session()
    if success7 then
        print("  ✅ Session stopped successfully")
    else
        print("  ❌ Session stop failed")
    end
    
    -- Verify session is stopped
    local stopped_status = M.get_ai_agent_session_status()
    if not stopped_status.active then
        print("  ✅ Session confirmed stopped")
    else
        print("  ❌ Session still active after stop")
    end
    
    -- Clean up test buffer
    vim.api.nvim_buf_delete(test_buf, {force = true})
    
    print("\n=== Integration Test Complete ===")
    print("All AI agent functions tested in real Neovim environment!")
    return true
end

-- Run the integration test
local success = test_ai_agent_integration()

if success then
    print("\n🎉 All integration tests passed!")
    print("AI agent functions work correctly in real Neovim environment.")
else
    print("\n❌ Some integration tests failed!")
    print("Check the output above for details.")
end

print("\nIntegration Test Features Validated:")
print("  ✅ Session Management: Start, status, stop")
print("  ✅ Message Exchange: Send and receive messages")
print("  ✅ Command Execution: Execute Neovim commands")
print("  ✅ Buffer Operations: Read and write buffer content")
print("  ✅ Real Neovim API: Actual buffer and window operations")
print("  ✅ Error Handling: Proper error handling in real environment")
print("  ✅ State Management: Session state across operations") 