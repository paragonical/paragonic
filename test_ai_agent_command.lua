#!/usr/bin/env lua

--[[
Test script for AI Agent Command Execution Function
This tests the AI agent command execution functionality
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Mock vim API for testing
local vim_mock = {
    api = {
        nvim_list_bufs = function()
            return {1, 2, 3}
        end,
        nvim_create_buf = function(listed, scratch) return 1 end,
        nvim_buf_set_lines = function(buf, start, end_, strict, lines) end,
        nvim_buf_set_option = function(buf, option, value) end,
        nvim_open_win = function(buf, enter, config) return 1 end,
        nvim_buf_set_name = function(buf, name) end
    },
    fn = {
        strftime = function(format)
            return "20250101_120000"
        end,
        expand = function(what)
            if what == "%" then return "/tmp/test.txt"
            else return "/tmp" end
        end,
        getcwd = function()
            return "/tmp"
        end,
        mode = function()
            return "n"
        end,
        stdpath = function(path)
            return "/tmp"
        end
    },
    o = {
        columns = 80,
        lines = 24
    },
    notify = function(msg, level) 
        print("  Notify [" .. (level or "info") .. "]: " .. msg)
    end,
    log = {
        levels = {
            INFO = 1,
            WARN = 2,
            ERROR = 3
        }
    },
    keymap = {
        set = function(mode, lhs, rhs, opts) end
    },
    cmd = function(command)
        -- Mock command execution
        if command == "echo 'test'" then
            return true
        elseif command == "invalid_command" then
            error("E492: Not an editor command: invalid_command")
        else
            return true
        end
    end
}

-- Replace global vim
local original_vim = _G.vim
_G.vim = vim_mock

-- Load the paragonic module and add missing mock functions
local M = require("paragonic")

-- Add missing mock functions to the module
M.get_buffers_info = function()
    return {
        {id = 1, name = "/tmp/file1.txt", file_type = "txt", modifiable = true},
        {id = 2, name = "/tmp/file2.lua", file_type = "lua", modifiable = true},
        {id = 3, name = "/tmp/file3.md", file_type = "md", modifiable = true}
    }
end

M.get_session_info = function()
    return {
        current_file = "/tmp/file1.txt",
        current_directory = "/tmp",
        mode = "normal",
        window_count = 2,
        buffer_count = 3
    }
end

-- Test function for AI agent command execution functionality
local function test_ai_agent_command()
    print("Testing AI agent command execution functionality...")
    
    -- Test executing command when no session is active
    print("  Testing execute_ai_agent_command when no session...")
    local success, error_msg = M.execute_ai_agent_command("echo 'test'")
    assert(not success, "Should not execute command when no session is active")
    assert(error_msg:find("No active"), "Should have appropriate error message")
    print("  ✓ Command when no session works")
    
    -- Test executing empty command
    print("  Testing execute_ai_agent_command with empty command...")
    local session_id = M.start_ai_agent_session("CommandTestAgent")
    assert(session_id, "Should start session successfully")
    
    local success, error_msg = M.execute_ai_agent_command("")
    assert(not success, "Should not execute empty command")
    assert(error_msg:find("Command is required"), "Should have appropriate error message")
    print("  ✓ Empty command handling works")
    
    -- Test executing a valid command
    print("  Testing execute_ai_agent_command with valid command...")
    local success, action_id, result = M.execute_ai_agent_command("echo 'test'")
    assert(success, "Should execute valid command successfully")
    assert(action_id == 1, "Should return correct action ID")
    assert(result:find("successfully"), "Should return success result")
    print("  ✓ Valid command execution works")
    
    -- Test executing another command
    local success2, action_id2, result2 = M.execute_ai_agent_command("set number")
    assert(success2, "Should execute second command successfully")
    assert(action_id2 == 2, "Should return correct action ID")
    print("  ✓ Multiple command execution works")
    
    -- Test executing command with description
    local success3, action_id3, result3 = M.execute_ai_agent_command("set wrap", "Enable line wrapping")
    assert(success3, "Should execute command with description successfully")
    assert(action_id3 == 3, "Should return correct action ID")
    print("  ✓ Command with description works")
    
    -- Test executing invalid command
    local success4, action_id4, result4 = M.execute_ai_agent_command("invalid_command")
    assert(not success4, "Should fail to execute invalid command")
    assert(action_id4 == 4, "Should return correct action ID")
    assert(result4:find("failed"), "Should return failure result")
    print("  ✓ Invalid command handling works")
    
    -- Test that interactions are tracked in session
    local status = M.get_ai_agent_session_status()
    assert(status.interaction_count == 4, "Should track 4 interactions")
    print("  ✓ Interaction tracking works")
    
    -- Clean up
    M.stop_ai_agent_session()
    
    print("✓ All AI agent command execution tests passed!")
end

-- Main test execution
print("=== AI Agent Command Execution Test ===")
print("Testing AI agent command execution functionality...")

-- Run tests
test_ai_agent_command()

-- Restore original vim
_G.vim = original_vim

print("\n=== Test Complete ===")
print("Note: These tests use mocked vim API calls.")
print("For real testing, run the commands in Neovim:")
print("  :ParagonicAIAgentStart CommandAgent")
print("  :ParagonicAIAgentCommand echo 'Hello World'")
print("  :ParagonicAIAgentStop")
print("\nAI Agent Command Features:")
print("  ✅ Command Execution: Execute Neovim commands from AI agents")
print("  ✅ Command Validation: Validate command input")
print("  ✅ Error Handling: Handle command execution failures")
print("  ✅ Action Tracking: Track all command executions")
print("  ✅ Context Updates: Update session context with each command")
print("  ✅ User Notifications: Notify users of command execution results")
print("  ✅ Status Icons: Visual indicators for success/failure")
print("  ✅ Result Reporting: Return execution results and status") 