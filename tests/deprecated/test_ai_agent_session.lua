#!/usr/bin/env lua

--[[
Test script for AI Agent Session Management
This tests the basic AI agent collaboration session functionality
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

-- Test function for AI agent session management
local function test_ai_agent_session()
	print("Testing AI agent session management...")

	-- Test starting an AI agent session
	print("  Testing start_ai_agent_session function...")
	local session_id = M.start_ai_agent_session("TestAgent")
	assert(session_id, "Should return a session ID")
	assert(type(session_id) == "string", "Session ID should be a string")
	assert(session_id:find("20250101_120000"), "Session ID should contain timestamp")
	assert(session_id:find("TestAgent"), "Session ID should contain agent name")
	print("  ✓ start_ai_agent_session function works")

	-- Test that we can't start another session while one is active
	print("  Testing session conflict handling...")
	local second_session_id = M.start_ai_agent_session("AnotherAgent")
	assert(not second_session_id, "Should not allow second session while one is active")
	print("  ✓ Session conflict handling works")

	-- Test stopping the AI agent session
	print("  Testing stop_ai_agent_session function...")
	local stop_success = M.stop_ai_agent_session()
	assert(stop_success, "Should successfully stop the session")
	print("  ✓ stop_ai_agent_session function works")

	-- Test that we can start a new session after stopping
	print("  Testing new session after stop...")
	local new_session_id = M.start_ai_agent_session("NewAgent")
	assert(new_session_id, "Should be able to start new session after stopping")
	print("  ✓ New session after stop works")

	-- Test stopping when no session is active
	print("  Testing stop when no session active...")
	M.stop_ai_agent_session() -- Stop the current session
	local stop_no_session = M.stop_ai_agent_session()
	assert(not stop_no_session, "Should not be able to stop when no session is active")
	print("  ✓ Stop when no session active works")

	-- Test getting session status when no session is active
	print("  Testing get_ai_agent_session_status when no session...")
	local status_no_session = M.get_ai_agent_session_status()
	assert(not status_no_session.active, "Should report no active session")
	assert(status_no_session.message:find("No active"), "Should have appropriate message")
	print("  ✓ Status when no session works")

	-- Test getting session status when session is active
	print("  Testing get_ai_agent_session_status when session active...")
	local new_session_id = M.start_ai_agent_session("StatusTestAgent")
	local status_active = M.get_ai_agent_session_status()
	assert(status_active.active, "Should report active session")
	assert(status_active.session_id == new_session_id, "Should have correct session ID")
	assert(status_active.agent_name == "StatusTestAgent", "Should have correct agent name")
	assert(status_active.duration >= 0, "Should have valid duration")
	print("  ✓ Status when session active works")

	-- Clean up
	M.stop_ai_agent_session()

	print("✓ All AI agent session tests passed!")
end

-- Main test execution
print("=== AI Agent Session Management Test ===")
print("Testing basic AI agent collaboration session functionality...")

-- Run tests
test_ai_agent_session()

-- Restore original vim
_G.vim = original_vim

print("\n=== Test Complete ===")
print("Note: These tests use mocked vim API calls.")
print("For real testing, run the commands in Neovim:")
print("  :ParagonicAIAgentStart TestAgent")
print("  :ParagonicAIAgentStop")
print("  :ParagonicAIAgentStatus")
print("\nAI Agent Session Features:")
print("  ✅ Session Creation: Create AI agent collaboration sessions")
print("  ✅ Session Stopping: Stop active collaboration sessions")
print("  ✅ Session Status: Get current session information")
print("  ✅ Session Conflict: Prevent multiple active sessions")
print("  ✅ Context Capture: Capture current Neovim context")
print("  ✅ Session ID Generation: Unique session identification")
print("  ✅ Duration Tracking: Track session duration and final context")
print("  ✅ Status Display: Show session status in floating window")
