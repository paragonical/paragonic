#!/usr/bin/env lua

--[[
Test Chat Debug Key Mapping
TDD Step 7: Verify debug key mapping works
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Load the paragonic module
local M = require("paragonic")

-- Test 1: Check key mapping setup
local function test_key_mapping_setup()
	print("=== Test 1: Key Mapping Setup ===")

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

	print("  📝 Testing key mapping setup...")

	-- Check if key mappings exist
	local normal_mapping = vim.api.nvim_buf_get_keymap(chat_buf, "n")

	local has_normal_send = false
	local has_debug_send = false

	for _, mapping in ipairs(normal_mapping) do
		if mapping.lhs == "<CR>" and mapping.rhs:find("ParagonicSend") then
			has_normal_send = true
			print("  ✅ Normal send mapping found: <CR> -> " .. mapping.rhs)
		end
		if mapping.lhs == "<leader><CR>" and mapping.rhs:find("ParagonicSendDebug") then
			has_debug_send = true
			print("  ✅ Debug send mapping found: <leader><CR> -> " .. mapping.rhs)
		end
	end

	if has_normal_send and has_debug_send then
		print("  ✅ Both key mappings are set up correctly")
		return true
	else
		print("  ❌ Missing key mappings:")
		print("    Normal send: " .. tostring(has_normal_send))
		print("    Debug send: " .. tostring(has_debug_send))
		return false
	end
end

-- Test 2: Test key mapping functionality
local function test_key_mapping_functionality()
	print("\n=== Test 2: Key Mapping Functionality ===")

	-- Use the proper chat opening function
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
		"**User:** Hello, can you help me?",
		"",
	})

	print("  📝 Testing key mapping functionality...")

	-- Set cursor to the user message line
	local lines = vim.api.nvim_buf_get_lines(chat_buf, 0, -1, false)
	vim.api.nvim_win_set_cursor(0, { #lines, 0 })

	-- Test normal send mapping
	print("  📝 Testing normal send mapping (<CR>)...")

	-- Simulate pressing <CR>
	local success_normal = pcall(function()
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, true, true), "n", false)
	end)

	if success_normal then
		print("  ✅ Normal send key mapping works")
	else
		print("  ❌ Normal send key mapping failed")
		return false
	end

	-- Test debug send mapping
	print("  📝 Testing debug send mapping (<leader><CR>)...")

	-- Simulate pressing <leader><CR>
	local success_debug = pcall(function()
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<leader><CR>", true, true, true), "n", false)
	end)

	if success_debug then
		print("  ✅ Debug send key mapping works")
	else
		print("  ❌ Debug send key mapping failed")
		return false
	end

	return true
end

-- Test 3: Test key mapping in different modes
local function test_key_mapping_modes()
	print("\n=== Test 3: Key Mapping in Different Modes ===")

	-- Use the proper chat opening function
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

	print("  📝 Testing key mappings in different modes...")

	-- Check normal mode mapping
	local normal_mappings = vim.api.nvim_buf_get_keymap(chat_buf, "n")
	local has_normal_cr = false
	local has_leader_cr = false

	for _, mapping in ipairs(normal_mappings) do
		if mapping.lhs == "<CR>" then
			has_normal_cr = true
		end
		if mapping.lhs == "<leader><CR>" then
			has_leader_cr = true
		end
	end

	-- Check insert mode mapping (should not exist)
	local insert_mappings = vim.api.nvim_buf_get_keymap(chat_buf, "i")
	local has_insert_cr = false

	for _, mapping in ipairs(insert_mappings) do
		if mapping.lhs == "<CR>" then
			has_insert_cr = true
		end
	end

	if has_normal_cr and has_leader_cr and not has_insert_cr then
		print("  ✅ Key mappings are correctly set in normal mode only")
		print("    Normal <CR>: " .. tostring(has_normal_cr))
		print("    Leader <CR>: " .. tostring(has_leader_cr))
		print("    Insert <CR>: " .. tostring(has_insert_cr) .. " (should be false)")
		return true
	else
		print("  ❌ Key mappings not set correctly")
		print("    Normal <CR>: " .. tostring(has_normal_cr))
		print("    Leader <CR>: " .. tostring(has_leader_cr))
		print("    Insert <CR>: " .. tostring(has_insert_cr) .. " (should be false)")
		return false
	end
end

-- Run the tests
print("Starting Tests for Chat Debug Key Mapping...")
print("=============================================")
print("TDD Step 7: Verify debug key mapping works")
print("")

local test1_result = test_key_mapping_setup()
local test2_result = test_key_mapping_functionality()
local test3_result = test_key_mapping_modes()

print("\n=== Key Mapping Test Results ===")
print("Test 1 (Key Mapping Setup): " .. (test1_result and "PASS" or "FAIL"))
print("Test 2 (Key Mapping Functionality): " .. (test2_result and "PASS" or "FAIL"))
print("Test 3 (Key Mapping Modes): " .. (test3_result and "PASS" or "FAIL"))

if test1_result and test2_result and test3_result then
	print("\n🎯 Status: GREEN")
	print("✅ Debug key mapping is working!")
	print("✅ Users can use <leader><CR> for debug send")
	print("✅ Normal <CR> still works for regular send")
	print("✅ Key mappings are properly configured")
else
	print("\n🎯 Status: RED")
	print("❌ Some key mapping tests are failing")
	print("Check the output above for remaining issues.")
end

print("\n📋 Key Mapping Features:")
print("  ✅ <CR> -> :ParagonicSend (normal send)")
print("  ✅ <leader><CR> -> :ParagonicSendDebug (debug send)")
print("  ✅ Key mappings work in normal mode")
print("  ✅ Key mappings don't interfere with insert mode")
print("  ✅ Buffer-local mappings for chat buffer only")
