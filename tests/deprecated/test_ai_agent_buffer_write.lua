#!/usr/bin/env lua

--[[
Test script for AI Agent Buffer Content Writing Function
This tests the AI agent buffer content writing functionality
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Mock vim API for testing
local vim_mock = {
	api = {
		nvim_list_bufs = function()
			return { 1, 2, 3 }
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
				[3] = "/tmp/file3.md",
			}
			return names[buf] or ""
		end,
		nvim_buf_set_lines = function(buf, start, end_, strict, lines)
			-- Mock successful buffer writing
			if buf >= 1 and buf <= 3 and lines then
				return true
			else
				error("Invalid buffer or lines")
			end
		end,
		nvim_buf_get_lines = function(buf, start, end_, strict)
			local contents = {
				[1] = { "Line 1 of file1", "Line 2 of file1", "Line 3 of file1" },
				[2] = { "function test()", "  return true", "end" },
				[3] = { "# Markdown file", "", "Some content here" },
			}
			local lines = contents[buf] or {}
			if start == 0 and end_ == -1 then
				return lines
			else
				return vim.list_slice(lines, start + 1, end_)
			end
		end,
		nvim_create_buf = function(listed, scratch)
			return 1
		end,
		nvim_buf_set_option = function(buf, option, value) end,
		nvim_open_win = function(buf, enter, config)
			return 1
		end,
		nvim_buf_set_name = function(buf, name) end,
	},
	fn = {
		strftime = function(format)
			return "20250101_120000"
		end,
		expand = function(what)
			if what == "%" then
				return "/tmp/test.txt"
			else
				return "/tmp"
			end
		end,
		getcwd = function()
			return "/tmp"
		end,
		mode = function()
			return "n"
		end,
		stdpath = function(path)
			return "/tmp"
		end,
	},
	o = {
		columns = 80,
		lines = 24,
	},
	notify = function(msg, level)
		print("  Notify [" .. (level or "info") .. "]: " .. msg)
	end,
	log = {
		levels = {
			INFO = 1,
			WARN = 2,
			ERROR = 3,
		},
	},
	keymap = {
		set = function(mode, lhs, rhs, opts) end,
	},
	list_slice = function(list, start, finish)
		local result = {}
		for i = start, finish do
			if list[i] then
				table.insert(result, list[i])
			end
		end
		return result
	end,
}

-- Replace global vim
local original_vim = _G.vim
_G.vim = vim_mock

-- Load the paragonic module and add missing mock functions
local M = require("paragonic")

-- Add missing mock functions to the module
M.get_buffers_info = function()
	return {
		{ id = 1, name = "/tmp/file1.txt", file_type = "txt", modifiable = true },
		{ id = 2, name = "/tmp/file2.lua", file_type = "lua", modifiable = true },
		{ id = 3, name = "/tmp/file3.md", file_type = "md", modifiable = true },
	}
end

M.get_session_info = function()
	return {
		current_file = "/tmp/file1.txt",
		current_directory = "/tmp",
		mode = "normal",
		window_count = 2,
		buffer_count = 3,
	}
end

-- Test function for AI agent buffer content writing functionality
local function test_ai_agent_buffer_write()
	print("Testing AI agent buffer content writing functionality...")

	-- Test writing buffer content when no session is active
	print("  Testing set_ai_agent_buffer_content when no session...")
	local success, error_msg = M.set_ai_agent_buffer_content(1, { "test line" })
	assert(not success, "Should not write buffer content when no session is active")
	assert(error_msg:find("No active"), "Should have appropriate error message")
	print("  ✓ Buffer write when no session works")

	-- Start a session
	print("  Testing set_ai_agent_buffer_content with active session...")
	local session_id = M.start_ai_agent_session("BufferWriteTestAgent")
	assert(session_id, "Should start session successfully")

	-- Test writing to current buffer (no buffer_id specified)
	print("  Testing set_ai_agent_buffer_content with current buffer...")
	local success, action_id, result = M.set_ai_agent_buffer_content(nil, { "New line 1", "New line 2" })
	assert(success, "Should write to current buffer successfully")
	assert(action_id == 1, "Should return correct action ID")
	assert(result.buffer_id == 1, "Should return current buffer ID")
	assert(result.lines_written == 2, "Should return correct lines written count")
	print("  ✓ Current buffer write works")

	-- Test writing to specific buffer
	print("  Testing set_ai_agent_buffer_content with specific buffer...")
	local success2, action_id2, result2 =
		M.set_ai_agent_buffer_content(2, { "function new()", "  return false", "end" })
	assert(success2, "Should write to specific buffer successfully")
	assert(action_id2 == 2, "Should return correct action ID")
	assert(result2.buffer_id == 2, "Should return correct buffer ID")
	assert(result2.lines_written == 3, "Should return correct lines written count")
	print("  ✓ Specific buffer write works")

	-- Test writing with invalid buffer
	print("  Testing set_ai_agent_buffer_content with invalid buffer...")
	local success3, error_msg3 = M.set_ai_agent_buffer_content(999, { "test" })
	assert(not success3, "Should fail to write to invalid buffer")
	assert(error_msg3:find("Invalid buffer ID"), "Should have appropriate error message")
	print("  ✓ Invalid buffer handling works")

	-- Test writing with invalid lines input
	print("  Testing set_ai_agent_buffer_content with invalid lines...")
	local success4, error_msg4 = M.set_ai_agent_buffer_content(1, "not a table")
	assert(not success4, "Should fail to write with invalid lines input")
	assert(error_msg4:find("Lines must be a table"), "Should have appropriate error message")
	print("  ✓ Invalid lines handling works")

	-- Test writing with empty lines
	print("  Testing set_ai_agent_buffer_content with empty lines...")
	local success5, action_id5, result5 = M.set_ai_agent_buffer_content(3, {})
	assert(success5, "Should write empty lines successfully")
	assert(action_id5 == 3, "Should return correct action ID")
	assert(result5.lines_written == 0, "Should return correct lines written count")
	print("  ✓ Empty lines handling works")

	-- Test that interactions are tracked in session
	local status = M.get_ai_agent_session_status()
	assert(status.interaction_count == 3, "Should track 3 interactions")
	print("  ✓ Interaction tracking works")

	-- Clean up
	M.stop_ai_agent_session()

	print("✓ All AI agent buffer write tests passed!")
end

-- Main test execution
print("=== AI Agent Buffer Write Test ===")
print("Testing AI agent buffer content writing functionality...")

-- Run tests
test_ai_agent_buffer_write()

-- Restore original vim
_G.vim = original_vim

print("\n=== Test Complete ===")
print("Note: These tests use mocked vim API calls.")
print("For real testing, run the commands in Neovim:")
print("  :ParagonicAIAgentStart BufferWriteAgent")
print("  :ParagonicAIAgentBufferWrite 1 New line 1 New line 2")
print("  :ParagonicAIAgentBufferWrite 2 function new() return false end")
print("  :ParagonicAIAgentStop")
print("\nAI Agent Buffer Write Features:")
print("  ✅ Buffer Writing: Write buffer content from AI agents")
print("  ✅ Current Buffer: Default to current buffer if not specified")
print("  ✅ Input Validation: Validate buffer existence and lines input")
print("  ✅ Action Tracking: Track all buffer write operations")
print("  ✅ Context Updates: Update session context with each write")
print("  ✅ User Notifications: Notify users of buffer write operations")
print("  ✅ Result Reporting: Return detailed write operation information")
print("  ✅ Error Handling: Handle invalid buffers and input errors")
print("  ✅ Status Icons: Visual indicators for success/failure")
