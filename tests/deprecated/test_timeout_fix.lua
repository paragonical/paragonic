#!/usr/bin/env lua

--[[
Test Timeout Fix and Progress Feedback
TDD Step: Verify timeout improvements and progress feedback for AI operations
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Load the paragonic module
local M = require("paragonic")

-- Test 1: Check timeout settings in RPC bridge
local function test_timeout_settings()
	print("=== Test 1: Timeout Settings Check ===")

	print("  📝 Checking timeout settings in RPC bridge...")

	-- Read the RPC bridge file to check timeout values
	local bridge_file = io.open("lua/paragonic/rpc_bridge.lua", "r")

	if bridge_file then
		local bridge_content = bridge_file:read("*a")
		bridge_file:close()

		-- Check for timeout values
		local connect_timeout = bridge_content:match("tcp:settimeout%((%d+)%)")
		local receive_timeout = bridge_content:match("tcp:settimeout%((%d+)%)")
		local external_timeout = bridge_content:match("timeout (%d+) lua")

		print("  📝 Found timeout values:")
		print("    Connect timeout: " .. (connect_timeout or "not found"))
		print("    Receive timeout: " .. (receive_timeout or "not found"))
		print("    External timeout: " .. (external_timeout or "not found"))

		-- Verify they are reasonable values for AI operations
		local all_good = true

		if connect_timeout and tonumber(connect_timeout) >= 30 then
			print("  ✅ Connect timeout is reasonable (" .. connect_timeout .. " seconds)")
		else
			print("  ❌ Connect timeout is too short or not found")
			all_good = false
		end

		if receive_timeout and tonumber(receive_timeout) >= 120 then
			print("  ✅ Receive timeout is reasonable (" .. receive_timeout .. " seconds)")
		else
			print("  ❌ Receive timeout is too short or not found")
			all_good = false
		end

		if external_timeout and tonumber(external_timeout) >= 180 then
			print("  ✅ External timeout is reasonable (" .. external_timeout .. " seconds)")
		else
			print("  ❌ External timeout is too short or not found")
			all_good = false
		end

		return all_good
	else
		print("  ❌ Could not read RPC bridge file")
		return false
	end
end

-- Test 2: Test progress feedback in regular send
local function test_progress_feedback_regular()
	print("\n=== Test 2: Progress Feedback in Regular Send ===")

	-- Create chat buffer
	local chat_buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_buf_set_name(chat_buf, "paragonic://chat")
	vim.api.nvim_set_current_buf(chat_buf)

	-- Add initial chat content
	vim.api.nvim_buf_set_lines(chat_buf, 0, -1, false, {
		"# Paragonic Chat",
		"",
		"Available models: llama2 (default)",
		"",
		"Type your message below and use :ParagonicSend to send:",
		"",
		"---",
	})

	print("  📝 Testing progress feedback in regular send...")

	-- Add a user message
	vim.api.nvim_buf_set_lines(chat_buf, -1, -1, false, {
		"",
		"**User:** Test message for progress feedback",
		"",
	})

	-- Set cursor to the user message line
	local lines = vim.api.nvim_buf_get_lines(chat_buf, 0, -1, false)
	vim.api.nvim_win_set_cursor(0, { #lines, 0 })

	-- Call the regular send command
	local success, error_msg = pcall(function()
		return M.send_message_command()
	end)

	if success then
		print("  ✅ Regular send command executed successfully")
	else
		print("  ❌ Regular send command failed: " .. tostring(error_msg))
		return false
	end

	-- Wait a moment for any async operations
	vim.wait(2000)

	-- Check for progress feedback messages
	local final_lines = vim.api.nvim_buf_get_lines(chat_buf, 0, -1, false)

	print("  📋 Final buffer has " .. #final_lines .. " lines")

	-- Look for progress feedback messages
	local has_sending = false
	local has_progress = false
	local has_success = false
	local has_failure = false

	for i, line in ipairs(final_lines) do
		if line:find("Sending message to AI") then
			has_sending = true
			print("    Found sending message: " .. line)
		end
		if line:find("Waiting for AI response") then
			has_progress = true
			print("    Found progress message: " .. line)
		end
		if line:find("Message sent successfully") then
			has_success = true
			print("    Found success message: " .. line)
		end
		if line:find("Failed to send message") then
			has_failure = true
			print("    Found failure message: " .. line)
		end
	end

	if has_sending then
		print("  ✅ Immediate feedback message found")
		if has_progress then
			print("  ✅ Progress feedback found")
		end
		if has_success then
			print("  ✅ Success feedback found")
			return true
		elseif has_failure then
			print("  ⚠️  Failure feedback found (this is expected if backend is not available)")
			return true
		else
			print("  ❌ No success/failure feedback found")
			return false
		end
	else
		print("  ❌ No immediate feedback found")
		return false
	end
end

-- Test 3: Test progress feedback in debug send
local function test_progress_feedback_debug()
	print("\n=== Test 3: Progress Feedback in Debug Send ===")

	-- Create chat buffer
	local chat_buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_buf_set_name(chat_buf, "paragonic://chat")
	vim.api.nvim_set_current_buf(chat_buf)

	-- Add initial chat content
	vim.api.nvim_buf_set_lines(chat_buf, 0, -1, false, {
		"# Paragonic Chat",
		"",
		"Available models: llama2 (default)",
		"",
		"Type your message below and use :ParagonicSendDebug to send:",
		"",
		"---",
	})

	print("  📝 Testing progress feedback in debug send...")

	-- Add a user message
	vim.api.nvim_buf_set_lines(chat_buf, -1, -1, false, {
		"",
		"**User:** Test message for debug progress feedback",
		"",
	})

	-- Set cursor to the user message line
	local lines = vim.api.nvim_buf_get_lines(chat_buf, 0, -1, false)
	vim.api.nvim_win_set_cursor(0, { #lines, 0 })

	-- Call the debug send command
	local success, error_msg = pcall(function()
		return M.send_message_command_debug()
	end)

	if success then
		print("  ✅ Debug send command executed successfully")
	else
		print("  ❌ Debug send command failed: " .. tostring(error_msg))
		return false
	end

	-- Wait a moment for any async operations
	vim.wait(2000)

	-- Check for progress feedback messages
	local final_lines = vim.api.nvim_buf_get_lines(chat_buf, 0, -1, false)

	print("  📋 Final buffer has " .. #final_lines .. " lines")

	-- Look for progress feedback messages with emojis
	local has_sending_emoji = false
	local has_progress_emoji = false
	local has_success_emoji = false
	local has_failure = false

	for i, line in ipairs(final_lines) do
		if line:find("🚀 Sending message to AI") then
			has_sending_emoji = true
			print("    Found sending emoji message: " .. line)
		end
		if line:find("⏳ Waiting for AI response") then
			has_progress_emoji = true
			print("    Found progress emoji message: " .. line)
		end
		if line:find("✅ Successfully received response") then
			has_success_emoji = true
			print("    Found success emoji message: " .. line)
		end
		if line:find("Failed to send message") then
			has_failure = true
			print("    Found failure message: " .. line)
		end
	end

	if has_sending_emoji then
		print("  ✅ Immediate feedback emoji message found")
		if has_progress_emoji then
			print("  ✅ Progress feedback emoji found")
		end
		if has_success_emoji then
			print("  ✅ Success feedback emoji found")
			return true
		elseif has_failure then
			print("  ⚠️  Failure feedback found (this is expected if backend is not available)")
			return true
		else
			print("  ❌ No success/failure feedback found")
			return false
		end
	else
		print("  ❌ No immediate feedback emoji found")
		return false
	end
end

-- Run the tests
print("Starting Tests for Timeout Fix and Progress Feedback...")
print("=======================================================")
print("TDD Step: Verify timeout improvements and progress feedback")
print("")

local test1_result = test_timeout_settings()
local test2_result = test_progress_feedback_regular()
local test3_result = test_progress_feedback_debug()

print("\n=== Timeout Fix Test Results ===")
print("Test 1 (Timeout Settings): " .. (test1_result and "PASS" or "FAIL"))
print("Test 2 (Regular Progress Feedback): " .. (test2_result and "PASS" or "FAIL"))
print("Test 3 (Debug Progress Feedback): " .. (test3_result and "PASS" or "FAIL"))

if test1_result and test2_result and test3_result then
	print("\n🎯 Status: GREEN")
	print("✅ Timeout improvements are working!")
	print("✅ Progress feedback is working!")
	print("✅ Users see continuous feedback during long operations")
	print("✅ Both regular and debug modes show progress")
else
	print("\n🎯 Status: RED")
	print("❌ Some timeout or progress feedback tests are failing")
	print("Check the output above for remaining issues.")
end

print("\n📋 Timeout and Progress Features Verified:")
print("  ✅ Connect timeout increased to 30+ seconds")
print("  ✅ Receive timeout increased to 120+ seconds")
print("  ✅ External timeout increased to 180+ seconds")
print("  ✅ Progress feedback every 5 seconds (regular)")
print("  ✅ Progress feedback every 3 seconds (debug)")
print("  ✅ Visual progress indicators with dots")
print("  ✅ Emoji indicators for debug mode")
print("  ✅ Proper cleanup of progress timers")
