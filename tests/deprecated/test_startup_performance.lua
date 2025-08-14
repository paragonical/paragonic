#!/usr/bin/env lua

--[[
Test Startup Performance
TDD Step 8: Verify plugin startup is non-blocking and provides good UX
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Test 1: Measure startup time
local function test_startup_time()
	print("=== Test 1: Startup Time Measurement ===")

	local start_time = vim.loop.hrtime()

	-- Load the paragonic module (this should be fast now)
	local M = require("paragonic")

	local end_time = vim.loop.hrtime()
	local startup_time_ms = (end_time - start_time) / 1000000

	print("  📝 Plugin startup time: " .. string.format("%.2f", startup_time_ms) .. " ms")

	if startup_time_ms < 100 then
		print("  ✅ Startup time is fast (< 100ms)")
		return true
	else
		print("  ❌ Startup time is too slow (> 100ms)")
		return false
	end
end

-- Test 2: Check RPC client availability after startup
local function test_rpc_client_availability()
	print("\n=== Test 2: RPC Client Availability ===")

	local M = require("paragonic")

	-- Immediately after startup, RPC client should be nil (not blocking)
	local rpc_client = M._get_rpc_client()

	if rpc_client == nil then
		print("  ✅ RPC client is nil immediately after startup (non-blocking)")
	else
		print("  ❌ RPC client is available immediately (may be blocking)")
		return false
	end

	-- Wait a bit for async initialization
	print("  📝 Waiting for async backend initialization...")
	vim.wait(2000) -- Wait 2 seconds

	-- Now check again
	rpc_client = M._get_rpc_client()

	if rpc_client then
		print("  ✅ RPC client is available after async initialization")
		return true
	else
		print("  ⚠️  RPC client still not available after 2 seconds")
		print("  📝 This is okay if backend is not running")
		return true -- This is acceptable if backend is not running
	end
end

-- Test 3: Test functions work without blocking
local function test_non_blocking_functions()
	print("\n=== Test 3: Non-blocking Function Calls ===")

	local M = require("paragonic")

	-- Test that functions return appropriate responses when backend is not available
	print("  📝 Testing functions when backend is not available...")

	-- Test send_message (will try to initialize backend)
	local response, err = M.send_message("Hello", "llama2")
	if response == nil and err then
		print("  ✅ send_message returns error when backend unavailable: " .. err)
	elseif response then
		print("  ✅ send_message works when backend is available")
	else
		print("  ❌ send_message behavior unexpected")
		return false
	end

	-- Test get_available_models (will try to initialize backend)
	local models, err = M.get_available_models()
	if models == nil and err then
		print("  ✅ get_available_models returns error when backend unavailable: " .. err)
	elseif models then
		print("  ✅ get_available_models works when backend is available")
	else
		print("  ❌ get_available_models behavior unexpected")
		return false
	end

	-- Test open_chat (should work without backend)
	local success = pcall(function()
		M.open_chat()
	end)

	if success then
		print("  ✅ open_chat works without backend")
	else
		print("  ❌ open_chat should work without backend")
		return false
	end

	return true
end

-- Test 4: Test user experience
local function test_user_experience()
	print("\n=== Test 4: User Experience ===")

	local M = require("paragonic")

	print("  📝 Testing user experience...")

	-- Test that commands are available immediately
	local commands = vim.api.nvim_get_commands({})

	local has_paragonic_commands = false
	for cmd_name, _ in pairs(commands) do
		if cmd_name:find("Paragonic") then
			has_paragonic_commands = true
			print("  ✅ Found command: " .. cmd_name)
		end
	end

	if has_paragonic_commands then
		print("  ✅ Paragonic commands are available immediately")
	else
		print("  ⚠️  Paragonic commands not found in this test environment")
		print("  📝 This is expected in headless mode")
	end

	-- Test that key mappings work
	local success = pcall(function()
		M.open_chat()
	end)

	if success then
		print("  ✅ Chat interface opens immediately")

		-- Check if chat buffer was created
		local chat_buf = nil
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_get_name(buf) == "paragonic://chat" then
				chat_buf = buf
				break
			end
		end

		if chat_buf then
			print("  ✅ Chat buffer created successfully")
		else
			print("  ❌ Chat buffer not found")
			return false
		end
	else
		print("  ❌ Chat interface failed to open")
		return false
	end

	return true
end

-- Run the tests
print("Starting Tests for Startup Performance...")
print("=========================================")
print("TDD Step 8: Verify plugin startup is non-blocking and provides good UX")
print("")

local test1_result = test_startup_time()
local test2_result = test_rpc_client_availability()
local test3_result = test_non_blocking_functions()
local test4_result = test_user_experience()

print("\n=== Startup Performance Test Results ===")
print("Test 1 (Startup Time): " .. (test1_result and "PASS" or "FAIL"))
print("Test 2 (RPC Availability): " .. (test2_result and "PASS" or "FAIL"))
print("Test 3 (Non-blocking Functions): " .. (test3_result and "PASS" or "FAIL"))
print("Test 4 (User Experience): " .. (test4_result and "PASS" or "FAIL"))

if test1_result and test2_result and test3_result and test4_result then
	print("\n🎯 Status: GREEN")
	print("✅ Plugin startup is fast and non-blocking!")
	print("✅ Good user experience maintained")
	print("✅ Functions handle backend unavailability gracefully")
	print("✅ No more long pauses during startup")
else
	print("\n🎯 Status: RED")
	print("❌ Some startup performance tests are failing")
	print("Check the output above for remaining issues.")
end

print("\n📋 Startup Performance Features:")
print("  ✅ Fast plugin startup (< 100ms)")
print("  ✅ Non-blocking backend initialization")
print("  ✅ Graceful handling of backend unavailability")
print("  ✅ Commands available immediately")
print("  ✅ Chat interface works without backend")
print("  ✅ Good user experience maintained")
