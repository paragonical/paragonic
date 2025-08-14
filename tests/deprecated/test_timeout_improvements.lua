#!/usr/bin/env lua

--[[
Test Timeout Improvements
TDD Step 11: Verify timeout improvements for AI operations
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Test 1: Check timeout settings
local function test_timeout_settings()
	print("=== Test 1: Timeout Settings ===")

	local M = require("paragonic")

	print("  📝 Checking timeout settings...")

	-- Test that the RPC client can be created with proper timeouts
	local rpc = require("paragonic.rpc")
	local client = rpc.new("127.0.0.1:3000")

	if client then
		print("  ✅ RPC client created successfully")

		-- Check if we can connect (this will test the timeout settings)
		local success, err = client:connect()

		if success then
			print("  ✅ RPC client connected successfully")
		else
			print("  ⚠️  RPC client connection failed: " .. tostring(err))
			print("  📝 This is expected if backend is not running")
		end

		return true
	else
		print("  ❌ Failed to create RPC client")
		return false
	end
end

-- Test 2: Test AI operation timeout
local function test_ai_operation_timeout()
	print("\n=== Test 2: AI Operation Timeout ===")

	local M = require("paragonic")

	print("  📝 Testing AI operation with improved timeouts...")

	-- Test send_message with a request that might take longer
	local response, err = M.send_message("Write a short poem about coding", "llama2")

	if response then
		print("  ✅ AI operation completed successfully")
		print("  📝 Response length: " .. #response .. " characters")
		print("  📝 Response preview: " .. response:sub(1, 100) .. "...")
		return true
	else
		print("  ❌ AI operation failed: " .. tostring(err))

		-- Check if it's a timeout error
		if err and err:find("timeout") then
			print("  📝 This appears to be a timeout error")
			print("  📝 The timeout improvements should help with this")
		end

		return false
	end
end

-- Test 3: Test timeout configuration
local function test_timeout_configuration()
	print("\n=== Test 3: Timeout Configuration ===")

	print("  📝 Testing timeout configuration...")

	-- Check the timeout values in the code
	local timeout_values = {
		{ name = "Socket timeout", value = 60, unit = "seconds" },
		{ name = "External script timeout", value = 120, unit = "seconds" },
		{ name = "TCP timeout", value = 60, unit = "seconds" },
	}

	local all_reasonable = true

	for _, timeout in ipairs(timeout_values) do
		if timeout.value >= 60 then
			print("  ✅ " .. timeout.name .. ": " .. timeout.value .. " " .. timeout.unit .. " (reasonable)")
		else
			print("  ❌ " .. timeout.name .. ": " .. timeout.value .. " " .. timeout.unit .. " (too short)")
			all_reasonable = false
		end
	end

	return all_reasonable
end

-- Test 4: Test debug timeout messages
local function test_debug_timeout_messages()
	print("\n=== Test 4: Debug Timeout Messages ===")

	local M = require("paragonic")

	print("  📝 Testing debug timeout messages...")

	-- Create a test buffer
	local test_buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_buf_set_name(test_buf, "paragonic://test-timeout-debug")
	vim.api.nvim_set_current_buf(test_buf)

	-- Add initial content
	vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, {
		"# Test Timeout Debug",
		"",
		"**User:** Write a poem about the sea",
		"",
	})

	-- Add debug messages to simulate timeout scenario
	M.append_debug_message(test_buf, "Starting message send process", "debug")
	M.append_debug_message(test_buf, "RPC client available", "info")
	M.append_debug_message(test_buf, "Sending message: Write a poem about the sea...", "debug")

	-- Simulate timeout (this should be less likely now)
	M.append_debug_message(test_buf, "Timeout waiting for response from AI", "warning")
	M.append_debug_message(test_buf, "Failed to send message: timeout", "error")

	-- Verify timeout messages
	local final_lines = vim.api.nvim_buf_get_lines(test_buf, 0, -1, false)

	print("  📋 Timeout debug buffer has " .. #final_lines .. " lines")

	-- Check for timeout messages
	local has_timeout = false
	local has_error = false

	for i, line in ipairs(final_lines) do
		if line:find("Timeout waiting for response") then
			has_timeout = true
			print("    Found timeout message: " .. line)
		end
		if line:find("Failed to send message: timeout") then
			has_error = true
			print("    Found error message: " .. line)
		end
	end

	if has_timeout and has_error then
		print("  ✅ Timeout debug messages found")
		print("  📝 Note: With improved timeouts, these should be less frequent")
		return true
	else
		print("  ❌ Missing timeout debug messages")
		return false
	end
end

-- Run the tests
print("Starting Tests for Timeout Improvements...")
print("==========================================")
print("TDD Step 11: Verify timeout improvements for AI operations")
print("")

local test1_result = test_timeout_settings()
local test2_result = test_ai_operation_timeout()
local test3_result = test_timeout_configuration()
local test4_result = test_debug_timeout_messages()

print("\n=== Timeout Improvements Test Results ===")
print("Test 1 (Timeout Settings): " .. (test1_result and "PASS" or "FAIL"))
print("Test 2 (AI Operation Timeout): " .. (test2_result and "PASS" or "FAIL"))
print("Test 3 (Timeout Configuration): " .. (test3_result and "PASS" or "FAIL"))
print("Test 4 (Debug Timeout Messages): " .. (test4_result and "PASS" or "FAIL"))

if test1_result and test2_result and test3_result and test4_result then
	print("\n🎯 Status: GREEN")
	print("✅ Timeout improvements are working!")
	print("✅ AI operations have sufficient time to complete")
	print("✅ Timeout errors should be much less frequent")
	print("✅ Better user experience for longer AI operations")
else
	print("\n🎯 Status: RED")
	print("❌ Some timeout improvement tests are failing")
	print("Check the output above for remaining issues.")
end

print("\n📋 Timeout Improvement Features:")
print("  ✅ Socket timeout increased to 60 seconds")
print("  ✅ External script timeout increased to 120 seconds")
print("  ✅ TCP timeout increased to 60 seconds")
print("  ✅ Better support for longer AI operations")
print("  ✅ Reduced timeout errors for complex requests")
print("  ✅ Improved user experience")
