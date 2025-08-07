#!/usr/bin/env lua

--[[
Test script for AI Agent Buffer Content Function
This tests the AI agent buffer content retrieval functionality
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Mock vim API for testing
local vim_mock = {
    api = {
        nvim_list_bufs = function()
            return {1, 2, 3}
        end,
        nvim_get_current_buf = function()
            return 1
        end,
        nvim_buf_is_valid = function(buf)
            return buf >= 1 and buf <= 3
        end,
        nvim_buf_get_name = function(buf)
            local names = {
                [1] = "/tmp/file1.txt",
                [2] = "/tmp/file2.lua", 
                [3] = "/tmp/file3.md"
            }
            return names[buf] or ""
        end,
        nvim_buf_get_lines = function(buf, start, end_, strict)
            local contents = {
                [1] = {"Line 1 of file1", "Line 2 of file1", "Line 3 of file1"},
                [2] = {"function test()", "  return true", "end"},
                [3] = {"# Markdown file", "", "Some content here"}
            }
            local lines = contents[buf] or {}
            if start == 0 and end_ == -1 then
                return lines
            else
                return vim.list_slice(lines, start + 1, end_)
            end
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
    list_slice = function(list, start, finish)
        local result = {}
        for i = start, finish do
            if list[i] then
                table.insert(result, list[i])
            end
        end
        return result
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

-- Test function for AI agent buffer content functionality
local function test_ai_agent_buffer()
    print("Testing AI agent buffer content functionality...")
    
    -- Test getting buffer content when no session is active
    print("  Testing get_ai_agent_buffer_content when no session...")
    local success, error_msg = M.get_ai_agent_buffer_content(1)
    assert(not success, "Should not get buffer content when no session is active")
    assert(error_msg:find("No active"), "Should have appropriate error message")
    print("  ✓ Buffer when no session works")
    
    -- Start a session
    print("  Testing get_ai_agent_buffer_content with active session...")
    local session_id = M.start_ai_agent_session("BufferTestAgent")
    assert(session_id, "Should start session successfully")
    
    -- Test getting current buffer content (no buffer_id specified)
    print("  Testing get_ai_agent_buffer_content with current buffer...")
    local success, action_id, result = M.get_ai_agent_buffer_content()
    assert(success, "Should get current buffer content successfully")
    assert(action_id == 1, "Should return correct action ID")
    assert(result.buffer_id == 1, "Should return current buffer ID")
    assert(result.line_count == 3, "Should return correct line count")
    assert(#result.content == 3, "Should return correct content")
    print("  ✓ Current buffer content works")
    
    -- Test getting specific buffer content
    print("  Testing get_ai_agent_buffer_content with specific buffer...")
    local success2, action_id2, result2 = M.get_ai_agent_buffer_content(2)
    assert(success2, "Should get specific buffer content successfully")
    assert(action_id2 == 2, "Should return correct action ID")
    assert(result2.buffer_id == 2, "Should return correct buffer ID")
    assert(result2.line_count == 3, "Should return correct line count")
    print("  ✓ Specific buffer content works")
    
    -- Test getting buffer content with line range
    print("  Testing get_ai_agent_buffer_content with line range...")
    local success3, action_id3, result3 = M.get_ai_agent_buffer_content(1, 1, 2)
    assert(success3, "Should get buffer content with line range successfully")
    assert(action_id3 == 3, "Should return correct action ID")
    assert(result3.line_count == 2, "Should return correct line count for range")
    assert(result3.start_line == 1, "Should return correct start line")
    assert(result3.end_line == 2, "Should return correct end line")
    print("  ✓ Line range content works")
    
    -- Test getting invalid buffer
    print("  Testing get_ai_agent_buffer_content with invalid buffer...")
    local success4, error_msg4 = M.get_ai_agent_buffer_content(999)
    assert(not success4, "Should fail to get invalid buffer content")
    assert(error_msg4:find("Invalid buffer ID"), "Should have appropriate error message")
    print("  ✓ Invalid buffer handling works")
    
    -- Test that interactions are tracked in session
    local status = M.get_ai_agent_session_status()
    assert(status.interaction_count == 3, "Should track 3 interactions")
    print("  ✓ Interaction tracking works")
    
    -- Clean up
    M.stop_ai_agent_session()
    
    print("✓ All AI agent buffer content tests passed!")
end

-- Main test execution
print("=== AI Agent Buffer Content Test ===")
print("Testing AI agent buffer content retrieval functionality...")

-- Run tests
test_ai_agent_buffer()

-- Restore original vim
_G.vim = original_vim

print("\n=== Test Complete ===")
print("Note: These tests use mocked vim API calls.")
print("For real testing, run the commands in Neovim:")
print("  :ParagonicAIAgentStart BufferAgent")
print("  :ParagonicAIAgentBuffer")
print("  :ParagonicAIAgentBuffer 2")
print("  :ParagonicAIAgentBuffer 1 1 2")
print("  :ParagonicAIAgentStop")
print("\nAI Agent Buffer Features:")
print("  ✅ Buffer Reading: Read buffer content from AI agents")
print("  ✅ Current Buffer: Default to current buffer if not specified")
print("  ✅ Line Ranges: Support reading specific line ranges")
print("  ✅ Buffer Validation: Validate buffer existence")
print("  ✅ Action Tracking: Track all buffer read operations")
print("  ✅ Context Updates: Update session context with each read")
print("  ✅ User Notifications: Notify users of buffer read operations")
print("  ✅ Result Reporting: Return detailed buffer information")
print("  ✅ Error Handling: Handle invalid buffers and errors") 