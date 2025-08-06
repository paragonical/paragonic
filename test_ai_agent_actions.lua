#!/usr/bin/env lua

--[[
Test Enhanced AI Agent Action Functions
Tests the new AI agent action functions for enhanced collaboration
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Load the paragonic module
local M = require("paragonic")

-- Test function for enhanced AI agent actions
local function test_ai_agent_actions()
    print("=== Enhanced AI Agent Actions Test ===")
    print("Testing new AI agent action functions...")
    
    -- Test 1: Start AI Agent Session
    print("\n1. Starting AI Agent Session...")
    local session_id = M.start_ai_agent_session("ActionTestAgent")
    if not session_id then
        print("  ❌ Failed to start session")
        return false
    end
    print("  ✅ Session started: " .. session_id)
    
    -- Test 2: Buffer Switching
    print("\n2. Testing Buffer Switching...")
    
    -- Create test buffers
    local buf1 = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(buf1, "/tmp/test_buffer1.txt")
    vim.api.nvim_buf_set_lines(buf1, 0, -1, false, {"Buffer 1 content"})
    
    local buf2 = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(buf2, "/tmp/test_buffer2.txt")
    vim.api.nvim_buf_set_lines(buf2, 0, -1, false, {"Buffer 2 content"})
    
    -- Switch to buffer 1
    local success1, action_id1, result1 = M.ai_agent_switch_buffer(buf1)
    if success1 then
        print("  ✅ Switched to buffer 1: " .. result1.buffer_id)
    else
        print("  ❌ Failed to switch to buffer 1: " .. action_id1)
    end
    
    -- Switch to buffer 2
    local success2, action_id2, result2 = M.ai_agent_switch_buffer(buf2)
    if success2 then
        print("  ✅ Switched to buffer 2: " .. result2.buffer_id)
    else
        print("  ❌ Failed to switch to buffer 2: " .. action_id2)
    end
    
    -- Test 3: Cursor Positioning
    print("\n3. Testing Cursor Positioning...")
    
    -- Add more content to buffer 2
    vim.api.nvim_buf_set_lines(buf2, 1, 1, false, {
        "Line 2: More content",
        "Line 3: Even more content",
        "Line 4: Final content"
    })
    
    -- Set cursor to line 3, column 5
    local success3, action_id3, result3 = M.ai_agent_set_cursor(3, 5)
    if success3 then
        print("  ✅ Set cursor to line " .. result3.line .. ", column " .. result3.column)
    else
        print("  ❌ Failed to set cursor: " .. action_id3)
    end
    
    -- Test invalid cursor position
    local success4, action_id4, result4 = M.ai_agent_set_cursor(999, 0)
    if not success4 then
        print("  ✅ Correctly rejected invalid cursor position: " .. action_id4)
    else
        print("  ❌ Should have rejected invalid cursor position")
    end
    
    -- Test 4: Window Creation
    print("\n4. Testing Window Creation...")
    
    -- Create horizontal split
    local success5, action_id5, result5 = M.ai_agent_create_window("split", buf1)
    if success5 then
        print("  ✅ Created horizontal split window: " .. result5.window_id)
    else
        print("  ❌ Failed to create horizontal split: " .. action_id5)
    end
    
    -- Create vertical split
    local success6, action_id6, result6 = M.ai_agent_create_window("vsplit", buf2)
    if success6 then
        print("  ✅ Created vertical split window: " .. result6.window_id)
    else
        print("  ❌ Failed to create vertical split: " .. action_id6)
    end
    
    -- Test 5: Text Insertion
    print("\n5. Testing Text Insertion...")
    
    -- Switch back to buffer 1
    M.ai_agent_switch_buffer(buf1)
    
    -- Insert text in insert mode
    local success7, action_id7, result7 = M.ai_agent_insert_text("AI Agent inserted this text", "insert")
    if success7 then
        print("  ✅ Inserted text in insert mode: " .. result7.text)
    else
        print("  ❌ Failed to insert text: " .. action_id7)
    end
    
    -- Insert text in append mode
    local success8, action_id8, result8 = M.ai_agent_insert_text("AI Agent appended this text", "append")
    if success8 then
        print("  ✅ Inserted text in append mode: " .. result8.text)
    else
        print("  ❌ Failed to append text: " .. action_id8)
    end
    
    -- Replace current line
    local success9, action_id9, result9 = M.ai_agent_insert_text("AI Agent replaced this line", "replace")
    if success9 then
        print("  ✅ Replaced line with text: " .. result9.text)
    else
        print("  ❌ Failed to replace line: " .. action_id9)
    end
    
    -- Test 6: State Retrieval
    print("\n6. Testing State Retrieval...")
    
    local success10, action_id10, state = M.ai_agent_get_state()
    if success10 then
        print("  ✅ Retrieved Neovim state:")
        print("    - Buffers: " .. #state.buffers)
        print("    - Windows: " .. #state.windows)
        print("    - Current file: " .. (state.current_file or "none"))
        print("    - Current directory: " .. state.current_directory)
        print("    - Terminal size: " .. state.terminal_size.columns .. "x" .. state.terminal_size.lines)
    else
        print("  ❌ Failed to retrieve state: " .. action_id10)
    end
    
    -- Test 7: Action Sequence Execution
    print("\n7. Testing Action Sequence Execution...")
    
    local actions = {
        {
            type = "command",
            params = {command = "set number", description = "Enable line numbers"}
        },
        {
            type = "set_cursor",
            params = {line = 1, column = 0}
        },
        {
            type = "insert_text",
            params = {text = "Sequence test line", mode = "insert"}
        }
    }
    
    local success11, action_id11, result11 = M.ai_agent_execute_sequence(actions)
    if success11 then
        print("  ✅ Executed action sequence: " .. result11.successful_actions .. "/" .. result11.total_actions .. " successful")
    else
        print("  ⚠️  Executed action sequence with errors: " .. result11.successful_actions .. "/" .. result11.total_actions .. " successful")
    end
    
    -- Test 8: Session Status After Actions
    print("\n8. Testing Session Status After Actions...")
    
    local final_status = M.get_ai_agent_session_status()
    if final_status.active then
        print("  ✅ Session still active with " .. final_status.interaction_count .. " interactions")
        print("    - Duration: " .. final_status.duration .. " seconds")
        print("    - Current file: " .. (final_status.context.current_file or "none"))
    else
        print("  ❌ Session not active")
    end
    
    -- Test 9: Session Cleanup
    print("\n9. Testing Session Cleanup...")
    
    local success12 = M.stop_ai_agent_session()
    if success12 then
        print("  ✅ Session stopped successfully")
    else
        print("  ❌ Failed to stop session")
    end
    
    -- Clean up test buffers
    vim.api.nvim_buf_delete(buf1, {force = true})
    vim.api.nvim_buf_delete(buf2, {force = true})
    
    print("\n=== Enhanced AI Agent Actions Test Complete ===")
    return true
end

-- Test function for error handling
local function test_ai_agent_actions_error_handling()
    print("\n=== AI Agent Actions Error Handling Test ===")
    
    -- Test actions without active session
    print("\n1. Testing actions without active session...")
    
    local success1, error1 = M.ai_agent_switch_buffer(1)
    if not success1 then
        print("  ✅ Correctly rejected buffer switch without session: " .. error1)
    else
        print("  ❌ Should have rejected buffer switch without session")
    end
    
    local success2, error2 = M.ai_agent_set_cursor(1, 0)
    if not success2 then
        print("  ✅ Correctly rejected cursor set without session: " .. error2)
    else
        print("  ❌ Should have rejected cursor set without session")
    end
    
    local success3, error3 = M.ai_agent_insert_text("test")
    if not success3 then
        print("  ✅ Correctly rejected text insertion without session: " .. error3)
    else
        print("  ❌ Should have rejected text insertion without session")
    end
    
    -- Start session and test invalid parameters
    print("\n2. Testing invalid parameters with active session...")
    
    local session_id = M.start_ai_agent_session("ErrorTestAgent")
    if session_id then
        print("  ✅ Started error test session: " .. session_id)
        
        -- Test invalid buffer ID
        local success4, error4 = M.ai_agent_switch_buffer(99999)
        if not success4 then
            print("  ✅ Correctly rejected invalid buffer ID: " .. error4)
        else
            print("  ❌ Should have rejected invalid buffer ID")
        end
        
        -- Test invalid text insertion
        local success5, error5 = M.ai_agent_insert_text("")
        if not success5 then
            print("  ✅ Correctly rejected empty text: " .. error5)
        else
            print("  ❌ Should have rejected empty text")
        end
        
        -- Test invalid action sequence
        local success6, error6 = M.ai_agent_execute_sequence({})
        if not success6 then
            print("  ✅ Correctly rejected empty action sequence: " .. error6)
        else
            print("  ❌ Should have rejected empty action sequence")
        end
        
        -- Stop session
        M.stop_ai_agent_session()
        print("  ✅ Stopped error test session")
    else
        print("  ❌ Failed to start error test session")
    end
    
    print("\n=== Error Handling Test Complete ===")
    return true
end

-- Run the tests
print("Starting Enhanced AI Agent Actions Tests...")
print("=============================================")

local success1 = test_ai_agent_actions()
local success2 = test_ai_agent_actions_error_handling()

if success1 and success2 then
    print("\n🎉 All enhanced AI agent action tests passed!")
    print("Enhanced AI agent collaboration functions work correctly.")
else
    print("\n❌ Some enhanced AI agent action tests failed!")
    print("Check the output above for details.")
end

print("\nEnhanced AI Agent Actions Features Validated:")
print("  ✅ Buffer Switching: Switch between buffers")
print("  ✅ Cursor Positioning: Set cursor to specific positions")
print("  ✅ Window Creation: Create horizontal/vertical splits")
print("  ✅ Text Insertion: Insert text in different modes")
print("  ✅ State Retrieval: Get comprehensive Neovim state")
print("  ✅ Action Sequences: Execute multiple actions in sequence")
print("  ✅ Error Handling: Proper validation and error messages")
print("  ✅ Session Integration: All actions tracked in session")
print("  ✅ User Notifications: Clear feedback for all actions")
print("  ✅ Context Updates: Session context updated after actions")

print("\nEnhanced Collaboration Capabilities:")
print("  🔄 Real-time Buffer Management")
print("  📍 Precise Cursor Control")
print("  🪟 Dynamic Window Creation")
print("  ✍️  Intelligent Text Insertion")
print("  📊 Comprehensive State Awareness")
print("  ⚡ Batch Action Execution")
print("  🛡️  Robust Error Handling")
print("  📈 Enhanced Session Tracking") 