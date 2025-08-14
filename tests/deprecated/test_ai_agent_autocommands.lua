#!/usr/bin/env lua

--[[
Test Neovim Autocommand Integration for AI Agent Collaboration
TDD Step 3: Real-time event detection via autocommands
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Load the paragonic module
local M = require("paragonic")

-- Enable event registration for testing
local function enable_event_registration()
	-- Register a dummy handler to enable event registration
	local dummy_handler = function(event) end
	M.register_buffer_change_handler(dummy_handler)
end

-- Test 1: Buffer Change Autocommand Integration
local function test_buffer_change_autocommands()
	print("=== Test 1: Buffer Change Autocommand Integration ===")

	-- Enable event registration
	enable_event_registration()

	-- Test 1.1: Setup buffer change autocommands
	print("\n1.1 Testing buffer change autocommand setup...")

	-- Test buffer change autocommand setup
	local success, error_msg = M.setup_buffer_change_autocommands()

	if success then
		print("  ✅ Buffer change autocommands setup successfully (GREEN)")
		return true
	else
		print("  ❌ Failed to setup buffer change autocommands: " .. error_msg)
		return false
	end
end

-- Test 2: Cursor Movement Autocommand Integration
local function test_cursor_movement_autocommands()
	print("\n=== Test 2: Cursor Movement Autocommand Integration ===")

	-- Enable event registration
	enable_event_registration()

	-- Test 2.1: Setup cursor movement autocommands
	print("\n2.1 Testing cursor movement autocommand setup...")

	-- Test cursor movement autocommand setup
	local success, error_msg = M.setup_cursor_movement_autocommands()

	if success then
		print("  ✅ Cursor movement autocommands setup successfully (GREEN)")
		return true
	else
		print("  ❌ Failed to setup cursor movement autocommands: " .. error_msg)
		return false
	end
end

-- Test 3: Window Change Autocommand Integration
local function test_window_change_autocommands()
	print("\n=== Test 3: Window Change Autocommand Integration ===")

	-- Enable event registration
	enable_event_registration()

	-- Test 3.1: Setup window change autocommands
	print("\n3.1 Testing window change autocommand setup...")

	-- Test window change autocommand setup
	local success, error_msg = M.setup_window_change_autocommands()

	if success then
		print("  ✅ Window change autocommands setup successfully (GREEN)")
		return true
	else
		print("  ❌ Failed to setup window change autocommands: " .. error_msg)
		return false
	end
end

-- Test 4: Complete Autocommand Integration
local function test_complete_autocommand_integration()
	print("\n=== Test 4: Complete Autocommand Integration ===")

	-- Enable event registration
	enable_event_registration()

	-- Test 4.1: Setup all autocommands
	print("\n4.1 Testing complete autocommand setup...")

	-- Test complete autocommand setup
	local success, error_msg = M.setup_all_event_autocommands()

	if success then
		print("  ✅ All event autocommands setup successfully (GREEN)")
		return true
	else
		print("  ❌ Failed to setup all event autocommands: " .. error_msg)
		return false
	end
end

-- Run the TDD tests
print("Starting TDD Tests for Neovim Autocommand Integration...")
print("=======================================================")
print("Following TDD Cycle: RED -> GREEN -> REFACTOR")
print("Step 3: Write failing tests for autocommand integration (RED)")
print("")

local test1_result = test_buffer_change_autocommands()
local test2_result = test_cursor_movement_autocommands()
local test3_result = test_window_change_autocommands()
local test4_result = test_complete_autocommand_integration()

print("\n=== TDD Test Results ===")
print("Test 1 (Buffer Change Autocommands): " .. (test1_result and "PASS" or "FAIL"))
print("Test 2 (Cursor Movement Autocommands): " .. (test2_result and "PASS" or "FAIL"))
print("Test 3 (Window Change Autocommands): " .. (test3_result and "PASS" or "FAIL"))
print("Test 4 (Complete Integration): " .. (test4_result and "PASS" or "FAIL"))

if test1_result and test2_result and test3_result and test4_result then
	print("\n🎯 TDD Status: GREEN")
	print("All autocommand tests are passing! Real-time event detection implemented.")
	print("Next step: Add AI agent session integration (REFACTOR)")
else
	print("\n🎯 TDD Status: PARTIAL")
	print("Some autocommand tests are still failing - continue implementation.")
end

print("\n📋 Implemented Functions:")
print("  ✅ M.setup_buffer_change_autocommands()")
print("  ✅ M.setup_cursor_movement_autocommands()")
print("  ✅ M.setup_window_change_autocommands()")
print("  ✅ M.setup_all_event_autocommands()")
print("\n📋 Next Requirements:")
print("  🔧 AI agent session integration")
print("  🔧 Event filtering and throttling")
print("  🔧 User commands for event management")
print("  🔧 Event logging and debugging")
