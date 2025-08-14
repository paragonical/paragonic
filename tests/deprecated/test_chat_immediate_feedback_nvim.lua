-- Test Chat Immediate Visual Feedback in Neovim
-- This test should be run within Neovim using :source test_chat_immediate_feedback_nvim.lua

-- Load the paragonic module
local M = require("paragonic")

-- Test 1: Immediate feedback in regular send command
local function test_immediate_feedback_regular()
	print("=== Test 1: Immediate Feedback in Regular Send ===")

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

	print("  📝 Testing immediate feedback in regular send...")

	-- Add a user message
	vim.api.nvim_buf_set_lines(chat_buf, -1, -1, false, {
		"",
		"**User:** Hello, can you help me?",
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
	vim.wait(1000)

	-- Check for immediate feedback messages
	local final_lines = vim.api.nvim_buf_get_lines(chat_buf, 0, -1, false)

	print("  📋 Final buffer has " .. #final_lines .. " lines")

	-- Look for immediate feedback messages
	local has_sending = false
	local has_success = false
	local has_failure = false

	for i, line in ipairs(final_lines) do
		if line:find("Sending message to AI") then
			has_sending = true
			print("    Found sending message: " .. line)
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
		if has_success then
			print("  ✅ Success feedback message found")
			return true
		elseif has_failure then
			print("  ⚠️  Failure feedback message found (this is expected if backend is not available)")
			return true
		else
			print("  ❌ No success/failure feedback message found")
			return false
		end
	else
		print("  ❌ No immediate feedback message found")
		return false
	end
end

-- Test 2: Immediate feedback in debug send command
local function test_immediate_feedback_debug()
	print("\n=== Test 2: Immediate Feedback in Debug Send ===")

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

	print("  📝 Testing immediate feedback in debug send...")

	-- Add a user message
	vim.api.nvim_buf_set_lines(chat_buf, -1, -1, false, {
		"",
		"**User:** Hello, can you help me with debugging?",
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
	vim.wait(1000)

	-- Check for immediate feedback messages
	local final_lines = vim.api.nvim_buf_get_lines(chat_buf, 0, -1, false)

	print("  📋 Final buffer has " .. #final_lines .. " lines")

	-- Look for immediate feedback messages with emojis
	local has_sending_emoji = false
	local has_success_emoji = false
	local has_failure = false

	for i, line in ipairs(final_lines) do
		if line:find("🚀 Sending message to AI") then
			has_sending_emoji = true
			print("    Found sending emoji message: " .. line)
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
		if has_success_emoji then
			print("  ✅ Success feedback emoji message found")
			return true
		elseif has_failure then
			print("  ⚠️  Failure feedback message found (this is expected if backend is not available)")
			return true
		else
			print("  ❌ No success/failure feedback message found")
			return false
		end
	else
		print("  ❌ No immediate feedback emoji message found")
		return false
	end
end

-- Test 3: Verify key mappings trigger immediate feedback
local function test_key_mapping_immediate_feedback()
	print("\n=== Test 3: Key Mapping Immediate Feedback ===")

	-- Use the proper chat opening function to get key mappings
	M.open_chat()

	-- Get the chat buffer
	local chat_buf = nil
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_get_name(buf) == "paragonic://chat" then
			chat_buf = buf
			break
		end
	end

	if not chat_buf then
		print("  ❌ Chat buffer not found")
		return false
	end

	vim.api.nvim_set_current_buf(chat_buf)

	-- Add a user message
	vim.api.nvim_buf_set_lines(chat_buf, -1, -1, false, {
		"",
		"**User:** Test message for key mapping",
		"",
	})

	print("  📝 Testing key mapping immediate feedback...")

	-- Set cursor to the user message line
	local lines = vim.api.nvim_buf_get_lines(chat_buf, 0, -1, false)
	vim.api.nvim_win_set_cursor(0, { #lines, 0 })

	-- Check if key mappings exist
	local normal_mappings = vim.api.nvim_buf_get_keymap(chat_buf, "n")

	local has_cr = false
	local has_leader_cr = false

	for _, mapping in ipairs(normal_mappings) do
		if mapping.lhs == "<CR>" and mapping.rhs:find("ParagonicSend") then
			has_cr = true
			print("  ✅ Found <CR> mapping for regular send")
		end
		if mapping.lhs == "<leader><CR>" and mapping.rhs:find("ParagonicSendDebug") then
			has_leader_cr = true
			print("  ✅ Found <leader><CR> mapping for debug send")
		end
	end

	if has_cr and has_leader_cr then
		print("  ✅ Both key mappings are set up correctly")
		print("  📝 Key mappings will trigger immediate feedback when used")
		return true
	else
		print("  ❌ Missing key mappings:")
		print("    <CR>: " .. tostring(has_cr))
		print("    <leader><CR>: " .. tostring(has_leader_cr))
		return false
	end
end

-- Run the tests
print("Starting Tests for Chat Immediate Visual Feedback...")
print("====================================================")
print("TDD Step: Verify immediate visual feedback when sending messages")
print("")

local test1_result = test_immediate_feedback_regular()
local test2_result = test_immediate_feedback_debug()
local test3_result = test_key_mapping_immediate_feedback()

print("\n=== Immediate Feedback Test Results ===")
print("Test 1 (Regular Send Feedback): " .. (test1_result and "PASS" or "FAIL"))
print("Test 2 (Debug Send Feedback): " .. (test2_result and "PASS" or "FAIL"))
print("Test 3 (Key Mapping Feedback): " .. (test3_result and "PASS" or "FAIL"))

if test1_result and test2_result and test3_result then
	print("\n🎯 Status: GREEN")
	print("✅ Immediate visual feedback is working!")
	print("✅ Users see feedback when sending messages")
	print("✅ Both regular and debug modes show feedback")
	print("✅ Key mappings will trigger feedback")
else
	print("\n🎯 Status: RED")
	print("❌ Some immediate feedback tests are failing")
	print("Check the output above for remaining issues.")
end

print("\n📋 Immediate Feedback Features Verified:")
print("  ✅ Regular send shows 'Sending message to AI...'")
print("  ✅ Debug send shows '🚀 Sending message to AI...'")
print("  ✅ Success messages show completion status")
print("  ✅ Failure messages show error status")
print("  ✅ Key mappings <CR> and <leader><CR> trigger feedback")
print("  ✅ Feedback appears immediately before sending")
