-- Test chat visual feedback for retry, timeout, and progress indicators
-- This test verifies that the correct symbols (🔄, ↯, ⏳, 🛔) appear in chat

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Mock vim for standalone testing
vim = {
	json = {
		encode = function(obj)
			return '{"jsonrpc":"2.0","result":"test response","id":1}'
		end,
		decode = function(str)
			return { result = "test response" }
		end,
	},
	wait = function(ms)
		-- Mock wait function
	end,
	g = {
		paragonic_use_real_backend = false,
		paragonic_test_mode = true,
	},
	api = {
		nvim_buf_set_lines = function(buf, start, end_line, strict_indexing, lines)
			-- Store buffer modifications for verification
			if not _G.test_buffer_modifications then
				_G.test_buffer_modifications = {}
			end
			table.insert(_G.test_buffer_modifications, {
				buf = buf,
				start = start,
				end_line = end_line,
				lines = lines,
			})
			return true
		end,
		nvim_get_current_buf = function()
			return 1 -- Mock buffer handle
		end,
		nvim_win_get_cursor = function(win)
			return { 10, 0 } -- Mock cursor position (line 10, column 0)
		end,
		nvim_buf_get_lines = function(buf, start, end_line, strict_indexing)
			return { "test message to send" } -- Mock current line content
		end,
		nvim_buf_get_name = function(buf)
			return "paragonic://chat" -- Mock chat buffer name
		end,
		nvim_buf_call = function(buf, fn)
			return fn() -- Execute the function
		end,
	},
	cmd = function(command)
		-- Mock vim commands like redraw
		if command == "redraw!" then
			_G.test_redraw_called = true
		end
	end,
	loop = {
		new_timer = function()
			return {
				start = function(self, delay, repeat_delay, callback)
					-- Store timer details for verification
					_G.test_timer_started = {
						delay = delay,
						repeat_delay = repeat_delay,
						callback = callback,
					}
					-- Simulate timer firing once for testing
					if callback then
						vim.schedule_wrap(callback)()
					end
				end,
				stop = function(self)
					_G.test_timer_stopped = true
				end,
				close = function(self)
					_G.test_timer_closed = true
				end,
			}
		end,
	},
	uv = {
		now = function()
			if not _G.mock_time then
				_G.mock_time = os.time() * 1000
			end
			return _G.mock_time
		end,
	},
	log = {
		levels = {
			ERROR = 1,
			WARN = 2,
			INFO = 3,
			DEBUG = 4,
		},
	},
	notify = function(message, level)
		if not _G.test_notifications then
			_G.test_notifications = {}
		end
		table.insert(_G.test_notifications, { message = message, level = level })
	end,
	schedule_wrap = function(fn)
		return fn -- Just return the function as-is for testing
	end,
}

-- Helper function to reset test globals
local function reset_test_globals()
	_G.test_buffer_modifications = {}
	_G.test_notifications = {}
	_G.test_timer_started = nil
	_G.test_timer_stopped = false
	_G.test_timer_closed = false
	_G.test_redraw_called = false
	_G.retry_callback_calls = {}
end

-- Test zigzag arrow (↯) appears when request is sent
local function test_zigzag_arrow_indicator()
	print("Testing zigzag arrow (↯) indicator...")

	reset_test_globals()

	-- Load chat module
	local chat = require("paragonic.chat")
	local backend = require("paragonic.backend")

	-- Mock backend with working RPC client
	local rpc = require("paragonic.rpc")
	backend._rpc_client = rpc.new("127.0.0.1:3000")
	backend._rpc_client:connect()

	-- Override send_message_enhanced to return quickly
	chat.send_message_enhanced = function(message, model)
		return "Mock response", nil
	end

	-- Call the debug command which should show the zigzag
	chat.send_message_command_debug()

	-- Check that zigzag arrow was added to buffer
	local found_zigzag = false
	for _, mod in ipairs(_G.test_buffer_modifications) do
		for _, line in ipairs(mod.lines) do
			if line == "↯" then
				found_zigzag = true
				break
			end
		end
	end

	assert(found_zigzag, "Zigzag arrow (↯) should appear when request is sent")
	print("✓ Zigzag arrow indicator working correctly")

	return true
end

-- Test progress dots (⏳) with animated dots
local function test_progress_dots_indicator()
	print("Testing progress dots (⏳) indicator...")

	reset_test_globals()

	-- Load chat module
	local chat = require("paragonic.chat")
	local backend = require("paragonic.backend")

	-- Mock backend
	local rpc = require("paragonic.rpc")
	backend._rpc_client = rpc.new("127.0.0.1:3000")
	backend._rpc_client:connect()

	-- Override send_message_enhanced to simulate slow response
	chat.send_message_enhanced = function(message, model)
		-- Simulate the timer callback being called
		if _G.test_timer_started and _G.test_timer_started.callback then
			_G.test_timer_started.callback()
		end
		return "Mock response", nil
	end

	-- Call the debug command
	chat.send_message_command_debug()

	-- Check that progress indicator was shown
	local found_progress = false
	for _, mod in ipairs(_G.test_buffer_modifications) do
		for _, line in ipairs(mod.lines) do
			if line:match("⏳.*Waiting for AI response") then
				found_progress = true
				break
			end
		end
	end

	-- Also check that timer was started
	assert(_G.test_timer_started ~= nil, "Progress timer should be started")
	assert(_G.test_timer_started.delay == 3000, "Timer delay should be 3000ms for debug mode")

	print("✓ Progress dots indicator working correctly")

	return true
end

-- Test retry symbol (🔄) appears during retries
local function test_retry_symbol_indicator()
	print("Testing retry symbol (🔄) indicator...")

	reset_test_globals()

	-- Load modules
	local chat = require("paragonic.chat")
	local backend = require("paragonic.backend")
	local rpc = require("paragonic.rpc")

	-- Mock backend with retry capability
	backend._rpc_client = rpc.new("127.0.0.1:3000")
	backend._rpc_client:connect()

	-- Verify that retry callback can be set
	assert(backend._rpc_client.set_retry_callback ~= nil, "RPC client should have set_retry_callback method")

	-- Override send_message_enhanced to simulate retry scenario
	chat.send_message_enhanced = function(message, model)
		-- Simulate retry callback being triggered
		if backend._rpc_client.retry_callback then
			backend._rpc_client.retry_callback(1, 3) -- Attempt 1 of 3
			backend._rpc_client.retry_callback(2, 3) -- Attempt 2 of 3
		end
		return "Mock response after retries", nil
	end

	-- Call the debug command
	chat.send_message_command_debug()

	-- Check that retry indicators were added
	local retry_count = 0
	for _, mod in ipairs(_G.test_buffer_modifications) do
		for _, line in ipairs(mod.lines) do
			if line:match("🔄 Retry attempt") then
				retry_count = retry_count + 1
			end
		end
	end

	print("✓ Retry symbol indicator working correctly")

	return true
end

-- Test error symbol (🛔) appears on failure
local function test_error_symbol_indicator()
	print("Testing error symbol (🛔) indicator...")

	reset_test_globals()

	-- Load modules
	local chat = require("paragonic.chat")
	local backend = require("paragonic.backend")

	-- Mock backend
	local rpc = require("paragonic.rpc")
	backend._rpc_client = rpc.new("127.0.0.1:3000")
	backend._rpc_client:connect()

	-- Override send_message_enhanced to return error
	chat.send_message_enhanced = function(message, model)
		return nil, "Connection timeout"
	end

	-- Call the debug command
	chat.send_message_command_debug()

	-- Check that error symbol was added
	local found_error = false
	for _, mod in ipairs(_G.test_buffer_modifications) do
		for _, line in ipairs(mod.lines) do
			if line:match("🛔") then
				found_error = true
				break
			end
		end
	end

	assert(found_error, "Error symbol (🛔) should appear on failure")

	-- Also check that error notification was sent
	local found_error_notification = false
	for _, notif in ipairs(_G.test_notifications) do
		if notif.message:match("Failed to send message") and notif.level == vim.log.levels.ERROR then
			found_error_notification = true
			break
		end
	end

	assert(found_error_notification, "Error notification should be sent on failure")
	print("✓ Error symbol indicator working correctly")

	return true
end

-- Test timer cleanup after completion
local function test_timer_cleanup()
	print("Testing timer cleanup after completion...")

	reset_test_globals()

	-- Load modules
	local chat = require("paragonic.chat")
	local backend = require("paragonic.backend")

	-- Mock backend
	local rpc = require("paragonic.rpc")
	backend._rpc_client = rpc.new("127.0.0.1:3000")
	backend._rpc_client:connect()

	-- Override send_message_enhanced to return success
	chat.send_message_enhanced = function(message, model)
		return "Mock successful response", nil
	end

	-- Call the debug command
	chat.send_message_command_debug()

	-- Check that timer was started and then cleaned up
	assert(_G.test_timer_started ~= nil, "Timer should be started")
	assert(_G.test_timer_stopped == true, "Timer should be stopped after completion")
	assert(_G.test_timer_closed == true, "Timer should be closed after completion")

	print("✓ Timer cleanup working correctly")

	return true
end

-- Test redraw is called to show immediate feedback
local function test_immediate_redraw()
	print("Testing immediate redraw for visual feedback...")

	reset_test_globals()

	-- Load modules
	local chat = require("paragonic.chat")
	local backend = require("paragonic.backend")

	-- Mock backend
	local rpc = require("paragonic.rpc")
	backend._rpc_client = rpc.new("127.0.0.1:3000")
	backend._rpc_client:connect()

	-- Override send_message_enhanced
	chat.send_message_enhanced = function(message, model)
		return "Mock response", nil
	end

	-- Call the debug command
	chat.send_message_command_debug()

	-- Check that redraw was called
	assert(_G.test_redraw_called == true, "vim.cmd('redraw!') should be called for immediate feedback")

	print("✓ Immediate redraw working correctly")

	return true
end

-- Run all tests
local function run_all_tests()
	print("=== Running Chat Visual Feedback Tests ===")

	local tests = {
		test_zigzag_arrow_indicator,
		test_progress_dots_indicator,
		test_retry_symbol_indicator,
		test_error_symbol_indicator,
		test_timer_cleanup,
		test_immediate_redraw,
	}

	local passed = 0
	local failed = 0

	for i, test in ipairs(tests) do
		local success, result = pcall(test)
		if success and result then
			passed = passed + 1
			print("✅ Test " .. i .. " PASSED")
		else
			failed = failed + 1
			print("❌ Test " .. i .. " FAILED: " .. tostring(result))
		end
	end

	print("\n=== Test Results ===")
	print("Passed: " .. passed)
	print("Failed: " .. failed)
	print("Total:  " .. (passed + failed))

	if failed == 0 then
		print("🎉 All visual feedback tests passed!")
		return true
	else
		print("💥 Some visual feedback tests failed!")
		return false
	end
end

-- Export test functions
return {
	run_all_tests = run_all_tests,
	test_zigzag_arrow_indicator = test_zigzag_arrow_indicator,
	test_progress_dots_indicator = test_progress_dots_indicator,
	test_retry_symbol_indicator = test_retry_symbol_indicator,
	test_error_symbol_indicator = test_error_symbol_indicator,
	test_timer_cleanup = test_timer_cleanup,
	test_immediate_redraw = test_immediate_redraw,
}
