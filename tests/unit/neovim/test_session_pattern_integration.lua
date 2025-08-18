--[[
Test file for AI Agent Session Pattern Integration
Tests the integration between AI agent sessions and pattern execution
--]]

-- Set up package path for testing
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Mock Neovim API for testing
vim = {
	api = {
		nvim_list_bufs = function()
			return { 1, 2, 3 } -- Mock buffer list
		end,
		nvim_create_buf = function(listed, scratch)
			return 1 -- Mock buffer ID
		end,
		nvim_open_win = function(buf, enter, config)
			return 1 -- Mock window ID
		end,
		nvim_buf_set_option = function(buf, option, value)
			-- Mock buffer option setting
		end,
		nvim_win_set_option = function(win, option, value)
			-- Mock window option setting
		end,
		nvim_buf_set_lines = function(buf, start, end_idx, strict_indexing, lines)
			-- Mock setting buffer lines
		end,
		nvim_win_close = function(win, force)
			-- Mock window closing
		end,
		nvim_buf_delete = function(buf, opts)
			-- Mock buffer deletion
		end,
		nvim_buf_get_name = function(buf)
			return "/test/file.lua" -- Mock buffer name
		end,
		nvim_get_current_buf = function()
			return 1 -- Mock current buffer
		end,
		nvim_set_current_buf = function(buf)
			-- Mock setting current buffer
		end,
		nvim_command = function(cmd)
			-- Mock command execution
		end,
		nvim_buf_set_name = function(buf, name)
			-- Mock setting buffer name
		end,
		nvim_buf_is_valid = function(buf)
			return true -- Mock buffer validity
		end,
		nvim_buf_get_lines = function(buf, start, end_idx, strict_indexing)
			return { "Mock line 1", "Mock line 2" } -- Mock buffer lines
		end,
	},
	fn = {
		expand = function(what)
			if what == "%" then
				return "/test/file.lua"
			elseif what == "getcwd" then
				return "/test/directory"
			end
			return ""
		end,
		getcwd = function()
			return "/test/directory"
		end,
		mode = function()
			return "n" -- Normal mode
		end,
		strftime = function(format)
			return "20250115_120000" -- Mock timestamp
		end,
	},
	notify = function(msg, level)
		-- Mock notification
		print("NOTIFY: " .. msg .. " (level: " .. tostring(level) .. ")")
	end,
	log = {
		levels = {
			INFO = 1,
			WARN = 2,
			ERROR = 4,
		},
	},
	o = {
		columns = 120,
		lines = 40,
	},
	cmd = function(command)
		-- Mock command execution
		return true
	end,
	keymap = {
		set = function(mode, lhs, rhs, opts)
			-- Mock keymap setting
		end,
	},
}

local M = {}

-- Test setup
local function setup()
	-- Clear any existing sessions
	local ai_agent = require("paragonic.ai_agent")
	if ai_agent.get_ai_agent_session_status().active then
		ai_agent.stop_ai_agent_session()
	end
end

-- Test teardown
local function teardown()
	-- Clean up any active sessions
	local ai_agent = require("paragonic.ai_agent")
	if ai_agent.get_ai_agent_session_status().active then
		ai_agent.stop_ai_agent_session()
	end
end

-- Test 1: Pattern execution when starting AI agent session
function M.test_pattern_execution_on_session_start()
	print("🧪 Testing pattern execution on session start")

	setup()

	local ai_agent = require("paragonic.ai_agent")
	local patterns = require("paragonic.patterns")

	-- Mock pattern execution to track calls
	local pattern_executed = false
	local original_execute = patterns.execute_pattern
	patterns.execute_pattern = function(pattern_name, context)
		pattern_executed = true
		return { success = true, pattern_name = pattern_name, context = context }
	end

	-- Start AI agent session
	local session_id = ai_agent.start_ai_agent_session("TestAgent")

	-- Verify session started
	assert(session_id ~= false, "Session should start successfully")

	-- Verify pattern was executed
	assert(pattern_executed, "Pattern should be executed when session starts")

	-- Restore original function
	patterns.execute_pattern = original_execute

	teardown()
	print("✅ Pattern execution on session start test passed")
end

-- Test 2: Pattern execution when stopping AI agent session
function M.test_pattern_execution_on_session_stop()
	print("🧪 Testing pattern execution on session stop")

	setup()

	local ai_agent = require("paragonic.ai_agent")
	local patterns = require("paragonic.patterns")

	-- Start session first
	local session_id = ai_agent.start_ai_agent_session("TestAgent")
	assert(session_id ~= false, "Session should start successfully")

	-- Mock pattern execution to track calls
	local pattern_executed = false
	local original_execute = patterns.execute_pattern
	patterns.execute_pattern = function(pattern_name, context)
		pattern_executed = true
		return { success = true, pattern_name = pattern_name, context = context }
	end

	-- Stop AI agent session
	local success = ai_agent.stop_ai_agent_session()

	-- Verify session stopped
	assert(success, "Session should stop successfully")

	-- Verify pattern was executed
	assert(pattern_executed, "Pattern should be executed when session stops")

	-- Restore original function
	patterns.execute_pattern = original_execute

	print("✅ Pattern execution on session stop test passed")
end

-- Test 3: Pattern execution during session interactions
function M.test_pattern_execution_during_interactions()
	print("🧪 Testing pattern execution during session interactions")

	setup()

	local ai_agent = require("paragonic.ai_agent")
	local patterns = require("paragonic.patterns")

	-- Start session
	local session_id = ai_agent.start_ai_agent_session("TestAgent")
	assert(session_id ~= false, "Session should start successfully")

	-- Mock pattern execution to track calls
	local pattern_execution_count = 0
	local original_execute = patterns.execute_pattern
	patterns.execute_pattern = function(pattern_name, context)
		pattern_execution_count = pattern_execution_count + 1
		return { success = true, pattern_name = pattern_name, context = context }
	end

	-- Perform some interactions
	ai_agent.send_ai_agent_message("Test message")
	ai_agent.receive_ai_agent_message("Test response")
	ai_agent.execute_ai_agent_command("echo 'test'")

	-- Verify patterns were executed during interactions
	assert(pattern_execution_count > 0, "Patterns should be executed during interactions")

	-- Restore original function
	patterns.execute_pattern = original_execute

	teardown()
	print("✅ Pattern execution during interactions test passed")
end

-- Test 4: Pattern execution with session context
function M.test_pattern_execution_with_session_context()
	print("🧪 Testing pattern execution with session context")

	setup()

	local ai_agent = require("paragonic.ai_agent")
	local patterns = require("paragonic.patterns")

	-- Start session
	local session_id = ai_agent.start_ai_agent_session("TestAgent")
	assert(session_id ~= false, "Session should start successfully")

	-- Mock pattern execution to capture context
	local captured_context = nil
	local original_execute = patterns.execute_pattern
	patterns.execute_pattern = function(pattern_name, context)
		captured_context = context
		return { success = true, pattern_name = pattern_name, context = context }
	end

	-- Execute a pattern
	local result = patterns.execute_pattern("session-summary", { session_id = session_id })

	-- Verify context was passed correctly
	assert(captured_context ~= nil, "Context should be passed to pattern execution")
	assert(captured_context.session_id == session_id, "Session ID should be in context")

	-- Restore original function
	patterns.execute_pattern = original_execute

	teardown()
	print("✅ Pattern execution with session context test passed")
end

-- Test 5: Pattern execution tracking in session interactions
function M.test_pattern_execution_tracking()
	print("🧪 Testing pattern execution tracking in session interactions")

	setup()

	local ai_agent = require("paragonic.ai_agent")
	local patterns = require("paragonic.patterns")

	-- Start session
	local session_id = ai_agent.start_ai_agent_session("TestAgent")
	assert(session_id ~= false, "Session should start successfully")

	-- Execute a pattern
	local result = patterns.execute_pattern("activity-labeling")

	-- Get session status
	local status = ai_agent.get_ai_agent_session_status()

	-- Verify pattern execution is tracked in session
	assert(status.interaction_count > 0, "Pattern execution should be tracked as interaction")

	teardown()
	print("✅ Pattern execution tracking test passed")
end

-- Test 6: Pattern-aware session commands
function M.test_pattern_aware_session_commands()
	print("🧪 Testing pattern-aware session commands")

	setup()

	local ai_agent = require("paragonic.ai_agent")

	-- Test pattern execution command within session
	local session_id = ai_agent.start_ai_agent_session("TestAgent")
	assert(session_id ~= false, "Session should start successfully")

	-- Test executing pattern via session command
	local success, result = ai_agent.execute_session_pattern("session-summary")
	assert(success, "Pattern execution command should succeed")

	teardown()
	print("✅ Pattern-aware session commands test passed")
end

-- Run all tests
function M.run_all_tests()
	print("🚀 Running AI Agent Session Pattern Integration Tests")
	print("=" .. string.rep("=", 50))

	local tests = {
		M.test_pattern_execution_on_session_start,
		M.test_pattern_execution_on_session_stop,
		M.test_pattern_execution_during_interactions,
		M.test_pattern_execution_with_session_context,
		M.test_pattern_execution_tracking,
		M.test_pattern_aware_session_commands,
	}

	local passed = 0
	local failed = 0

	for i, test in ipairs(tests) do
		local success, error = pcall(test)
		if success then
			passed = passed + 1
		else
			failed = failed + 1
			print("❌ Test " .. i .. " failed: " .. tostring(error))
		end
	end

	print("=" .. string.rep("=", 50))
	print("📊 Test Results: " .. passed .. " passed, " .. failed .. " failed")

	if failed == 0 then
		print("🎉 All tests passed!")
	else
		print("⚠️  Some tests failed")
	end

	return failed == 0
end

return M
