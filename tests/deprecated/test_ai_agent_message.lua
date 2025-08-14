#!/usr/bin/env lua

--[[
Test script for AI Agent Message Function
This tests the AI agent message sending functionality
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Mock vim API for testing
local vim_mock = {
	api = {
		nvim_list_bufs = function()
			return { 1, 2, 3 }
		end,
		nvim_create_buf = function(listed, scratch)
			return 1
		end,
		nvim_buf_set_lines = function(buf, start, end_, strict, lines) end,
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

-- Test function for AI agent message functionality
local function test_ai_agent_message()
	print("Testing AI agent message functionality...")

	-- Test sending message when no session is active
	print("  Testing send_ai_agent_message when no session...")
	local success, error_msg = M.send_ai_agent_message("Hello Neovim")
	assert(not success, "Should not send message when no session is active")
	assert(error_msg:find("No active"), "Should have appropriate error message")
	print("  ✓ Message when no session works")

	-- Start a session
	print("  Testing send_ai_agent_message with active session...")
	local session_id = M.start_ai_agent_session("MessageTestAgent")
	assert(session_id, "Should start session successfully")

	-- Test sending a basic message
	local success, message_id = M.send_ai_agent_message("Hello Neovim")
	assert(success, "Should send message successfully")
	assert(message_id == 1, "Should return correct message ID")
	print("  ✓ Basic message sending works")

	-- Test sending another message
	local success2, message_id2 = M.send_ai_agent_message("How are you?")
	assert(success2, "Should send second message successfully")
	assert(message_id2 == 2, "Should return correct message ID")
	print("  ✓ Multiple message sending works")

	-- Test sending message with custom type
	local success3, message_id3 = M.send_ai_agent_message("Code analysis complete", "analysis")
	assert(success3, "Should send typed message successfully")
	assert(message_id3 == 3, "Should return correct message ID")
	print("  ✓ Typed message sending works")

	-- Test that interactions are tracked in session
	local status = M.get_ai_agent_session_status()
	assert(status.interaction_count == 3, "Should track 3 interactions")
	print("  ✓ Interaction tracking works")

	-- Clean up
	M.stop_ai_agent_session()

	print("✓ All AI agent message tests passed!")
end

-- Main test execution
print("=== AI Agent Message Test ===")
print("Testing AI agent message sending functionality...")

-- Run tests
test_ai_agent_message()

-- Restore original vim
_G.vim = original_vim

print("\n=== Test Complete ===")
print("Note: These tests use mocked vim API calls.")
print("For real testing, run the commands in Neovim:")
print("  :ParagonicAIAgentStart MessageAgent")
print("  :ParagonicAIAgentMessage Hello Neovim")
print("  :ParagonicAIAgentStop")
print("\nAI Agent Message Features:")
print("  ✅ Message Sending: Send messages from AI agents to Neovim")
print("  ✅ Message Types: Support different message types")
print("  ✅ Interaction Tracking: Track all AI agent interactions")
print("  ✅ Context Updates: Update session context with each message")
print("  ✅ User Notifications: Notify users of AI agent messages")
print("  ✅ Error Handling: Proper error handling for invalid states")
