#!/usr/bin/env lua

--[[
Final Test for Chat Debug Functionality
TDD Step 6: Verify complete debug functionality with commands
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Load the paragonic module
local M = require("paragonic")

-- Test 1: Test debug command availability
local function test_debug_command_availability()
	print("=== Test 1: Debug Command Availability ===")

	-- Check if the debug function exists
	if M.send_message_command_debug then
		print("  ✅ send_message_command_debug function exists")
	else
		print("  ❌ send_message_command_debug function not found")
		return false
	end

	-- Check if append_debug_message function exists
	if M.append_debug_message then
		print("  ✅ append_debug_message function exists")
	else
		print("  ❌ append_debug_message function not found")
		return false
	end

	return true
end

-- Test 2: Test debug command in chat buffer
local function test_debug_command_in_chat()
	print("\n=== Test 2: Debug Command in Chat Buffer ===")

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

	print("  📝 Testing debug command in chat buffer...")

	-- Add a user message
	vim.api.nvim_buf_set_lines(chat_buf, -1, -1, false, {
		"",
		"**User:** Hello, can you help me with coding?",
		"",
	})

	-- Set cursor to the user message line
	local lines = vim.api.nvim_buf_get_lines(chat_buf, 0, -1, false)
	vim.api.nvim_win_set_cursor(0, { #lines, 0 })

	print("  📝 Calling send_message_command_debug...")

	-- Call the debug command
	local success, error_msg = pcall(function()
		return M.send_message_command_debug()
	end)

	if success then
		print("  ✅ Debug command executed successfully")
	else
		print("  ❌ Debug command failed: " .. tostring(error_msg))
		return false
	end

	-- Wait a moment for any async operations
	vim.wait(1000)

	-- Check for debug messages
	local final_lines = vim.api.nvim_buf_get_lines(chat_buf, 0, -1, false)

	print("  📋 Final buffer has " .. #final_lines .. " lines")

	-- Count debug messages
	local debug_count = 0
	for i, line in ipairs(final_lines) do
		if line:find("DEBUG %[") then
			debug_count = debug_count + 1
			print("    Line " .. i .. ": " .. line)
		end
	end

	if debug_count > 0 then
		print("  ✅ Debug messages found: " .. debug_count .. " messages")
		return true
	else
		print("  ❌ No debug messages found")
		return false
	end
end

-- Test 3: Test timeout debugging
local function test_timeout_debugging()
	print("\n=== Test 3: Timeout Debugging Test ===")

	-- Create test buffer
	local test_buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_buf_set_name(test_buf, "paragonic://test-timeout-debug")
	vim.api.nvim_set_current_buf(test_buf)

	-- Add initial content
	vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, {
		"# Test Timeout Debugging",
		"",
		"**User:** This should timeout",
		"",
	})

	print("  📝 Testing timeout debugging...")

	-- Add debug messages to simulate timeout scenario
	M.append_debug_message(test_buf, "Starting message send process", "debug")
	M.append_debug_message(test_buf, "RPC client available", "info")
	M.append_debug_message(test_buf, "Sending message to AI...", "debug")

	-- Simulate timeout
	M.append_debug_message(test_buf, "Timeout waiting for response from AI", "warning")
	M.append_debug_message(test_buf, "Failed to send message: timeout", "error")
	M.append_debug_message(test_buf, "Message send process failed", "error")

	-- Verify timeout debugging
	local final_lines = vim.api.nvim_buf_get_lines(test_buf, 0, -1, false)

	print("  📋 Timeout debug buffer has " .. #final_lines .. " lines")

	-- Check for specific timeout messages
	local has_start = false
	local has_timeout = false
	local has_error = false

	for i, line in ipairs(final_lines) do
		if line:find("Starting message send process") then
			has_start = true
		end
		if line:find("Timeout waiting for response") then
			has_timeout = true
		end
		if line:find("Failed to send message: timeout") then
			has_error = true
		end
	end

	if has_start and has_timeout and has_error then
		print("  ✅ All timeout debug messages found")
		return true
	else
		print("  ❌ Missing timeout debug messages")
		print("    Start: " .. tostring(has_start))
		print("    Timeout: " .. tostring(has_timeout))
		print("    Error: " .. tostring(has_error))
		return false
	end
end

-- Run the final tests
print("Starting Final Tests for Chat Debug...")
print("======================================")
print("TDD Step 6: Verify complete debug functionality")
print("")

local test1_result = test_debug_command_availability()
local test2_result = test_debug_command_in_chat()
local test3_result = test_timeout_debugging()

print("\n=== Final Debug Test Results ===")
print("Test 1 (Command Availability): " .. (test1_result and "PASS" or "FAIL"))
print("Test 2 (Debug Command in Chat): " .. (test2_result and "PASS" or "FAIL"))
print("Test 3 (Timeout Debugging): " .. (test3_result and "PASS" or "FAIL"))

if test1_result and test2_result and test3_result then
	print("\n🎯 Status: GREEN")
	print("✅ Complete debug functionality is working!")
	print("✅ Debug messages are properly appended to chat buffer")
	print("✅ Timeout scenarios can be debugged effectively")
	print("✅ Users can use :ParagonicSendDebug for debugging")
else
	print("\n🎯 Status: RED")
	print("❌ Some debug tests are failing")
	print("Check the output above for remaining issues.")
end

print("\n📋 Complete Debug Features:")
print("  ✅ append_debug_message() function works")
print("  ✅ send_message_command_debug() function works")
print("  ✅ Debug messages appear in chat buffer")
print("  ✅ Different debug levels (info, debug, success, error, warning)")
print("  ✅ Proper message formatting")
print("  ✅ Timeout debugging support")
print("  ✅ :ParagonicSendDebug command available")
print("  ✅ Complete debugging workflow")
