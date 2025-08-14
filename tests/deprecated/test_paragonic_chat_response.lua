#!/usr/bin/env lua

--[[
Test ParagonicChat AI Response Issue
TDD Step 1: Write failing test for chat response appending
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Load the paragonic module
local M = require("paragonic")

-- Test 1: Chat Response Appending Issue
local function test_chat_response_appending()
	print("=== Test 1: Chat Response Appending Issue ===")

	-- Test 1.1: Open chat and verify initial state
	print("\n1.1 Testing chat buffer creation...")

	M.open_chat()
	local current_buf = vim.api.nvim_get_current_buf()
	local buf_name = vim.api.nvim_buf_get_name(current_buf)

	if buf_name == "paragonic://chat" then
		print("  ✅ Chat buffer created successfully")
	else
		print("  ❌ Failed to create chat buffer")
		return false
	end

	-- Test 1.2: Add user message to buffer
	print("\n1.2 Testing user message addition...")

	local user_message = "Hello, can you help me with coding?"
	local lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
	local insert_line = #lines

	-- Add user message
	vim.api.nvim_buf_set_lines(current_buf, insert_line, insert_line, false, {
		"",
		"**User:** " .. user_message,
	})

	-- Verify user message was added
	lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
	local last_line = lines[#lines]

	if last_line:find(user_message) then
		print("  ✅ User message added to buffer")
	else
		print("  ❌ Failed to add user message to buffer")
		return false
	end

	-- Test 1.3: Test send_message_command function
	print("\n1.3 Testing send_message_command function...")

	-- Set cursor to the user message line
	vim.api.nvim_win_set_cursor(0, { #lines, 0 })

	-- Call send_message_command
	local success, error_msg = pcall(M.send_message_command)

	if success then
		print("  ✅ send_message_command executed without error")
	else
		print("  ❌ send_message_command failed: " .. tostring(error_msg))
		return false
	end

	-- Test 1.4: Check if AI response was appended
	print("\n1.4 Testing AI response appending...")

	-- Wait a moment for async operations
	vim.wait(1000)

	-- Get updated buffer content
	lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)

	-- Look for AI response
	local has_ai_response = false
	local ai_response_line = nil

	for i, line in ipairs(lines) do
		if line:find("**AI Response:**") or line:find("**AI:**") then
			has_ai_response = true
			ai_response_line = i
			break
		end
	end

	if has_ai_response then
		print("  ✅ AI response found in buffer at line " .. ai_response_line)

		-- Check if response content is present
		local response_content = ""
		for i = ai_response_line + 1, #lines do
			local line = lines[i]
			if line:find("^%s*$") or line:find("^---") then
				break
			end
			response_content = response_content .. line .. "\n"
		end

		if response_content:len() > 0 then
			print("  ✅ AI response has content: " .. response_content:sub(1, 50) .. "...")
		else
			print("  ❌ AI response has no content")
			return false
		end
	else
		print("  ❌ No AI response found in buffer")
		print("  📋 Buffer content:")
		for i, line in ipairs(lines) do
			print("    " .. i .. ": " .. line)
		end
		return false
	end

	return true
end

-- Test 2: Message Parsing Issue
local function test_message_parsing()
	print("\n=== Test 2: Message Parsing Issue ===")

	-- Test 2.1: Test send_message function directly
	print("\n2.1 Testing send_message function...")

	local test_message = "What is 2+2?"
	local response, error_msg = M.send_message(test_message, "llama2")

	if response then
		print("  ✅ send_message returned response: " .. response:sub(1, 50) .. "...")
	else
		print("  ❌ send_message failed: " .. tostring(error_msg))
		return false
	end

	return true
end

-- Test 3: Buffer Insertion Issue
local function test_buffer_insertion()
	print("\n=== Test 3: Buffer Insertion Issue ===")

	-- Test 3.1: Test buffer insertion logic
	print("\n3.1 Testing buffer insertion logic...")

	local test_buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_buf_set_name(test_buf, "paragonic://test")
	vim.api.nvim_set_current_buf(test_buf)

	-- Add initial content
	vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, {
		"Line 1",
		"Line 2",
		"Line 3",
	})

	-- Test insertion at specific line
	local insert_line = 2 -- 0-indexed
	local response_lines = {
		"**AI Response:**",
		"This is a test response",
		"---",
	}

	vim.api.nvim_buf_set_lines(test_buf, insert_line, insert_line, false, response_lines)

	-- Verify insertion
	local lines = vim.api.nvim_buf_get_lines(test_buf, 0, -1, false)

	if lines[3] == "**AI Response:**" then
		print("  ✅ Buffer insertion works correctly")
	else
		print("  ❌ Buffer insertion failed")
		print("  📋 Buffer content:")
		for i, line in ipairs(lines) do
			print("    " .. i .. ": " .. line)
		end
		return false
	end

	return true
end

-- Run the TDD tests
print("Starting TDD Tests for ParagonicChat Response Issue...")
print("=====================================================")
print("Following TDD Cycle: RED -> GREEN -> REFACTOR")
print("Step 1: Write failing tests for chat response issue (RED)")
print("")

local test1_result = test_chat_response_appending()
local test2_result = test_message_parsing()
local test3_result = test_buffer_insertion()

print("\n=== TDD Test Results ===")
print("Test 1 (Chat Response Appending): " .. (test1_result and "PASS" or "FAIL"))
print("Test 2 (Message Parsing): " .. (test2_result and "PASS" or "FAIL"))
print("Test 3 (Buffer Insertion): " .. (test3_result and "PASS" or "FAIL"))

if test1_result and test2_result and test3_result then
	print("\n🎯 TDD Status: GREEN")
	print("All chat response tests are passing!")
	print("Next step: Investigate specific failure scenarios")
else
	print("\n🎯 TDD Status: RED")
	print("Chat response tests are failing - identify specific issues.")
	print("Focus on the failing test to understand the root cause.")
end

print("\n📋 Issues Identified:")
print("  🔍 AI response not being appended to buffer")
print("  🔍 Message parsing or RPC communication issues")
print("  🔍 Buffer insertion logic problems")
print("  🔍 Async timing issues")
print("  🔍 Error handling in send_message_command")
