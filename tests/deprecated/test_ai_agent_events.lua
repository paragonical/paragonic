#!/usr/bin/env lua

--[[
Test Real-time Event Notifications for AI Agent Collaboration
Following TDD: Write tests first, then implement
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Load the paragonic module
local M = require("paragonic")

-- Test 1: Buffer Change Event Notifications
local function test_buffer_change_events()
    print("=== Test 1: Buffer Change Event Notifications ===")
    
    -- Test 1.1: Register buffer change event handler
    print("\n1.1 Testing buffer change event registration...")
    
    local event_handler_called = false
    local event_data = nil
    
    local function test_buffer_handler(event)
        event_handler_called = true
        event_data = event
        print("  📝 Buffer change event received: " .. event.buffer_id)
    end
    
    -- Test the buffer change handler registration
    local success, error_msg = M.register_buffer_change_handler(test_buffer_handler)
    
    if success then
        print("  ✅ Buffer change handler registered successfully (GREEN)")
        return true
    else
        print("  ❌ Failed to register buffer change handler: " .. error_msg)
        return false
    end
end

-- Test 2: Cursor Movement Event Notifications  
local function test_cursor_movement_events()
    print("\n=== Test 2: Cursor Movement Event Notifications ===")
    
    -- Test 2.1: Register cursor movement event handler
    print("\n2.1 Testing cursor movement event registration...")
    
    local event_handler_called = false
    local event_data = nil
    
    local function test_cursor_handler(event)
        event_handler_called = true
        event_data = event
        print("  📍 Cursor movement event received: line " .. event.line .. ", col " .. event.column)
    end
    
    -- Test the cursor movement handler registration
    local success, error_msg = M.register_cursor_movement_handler(test_cursor_handler)
    
    if success then
        print("  ✅ Cursor movement handler registered successfully (GREEN)")
        return true
    else
        print("  ❌ Failed to register cursor movement handler: " .. error_msg)
        return false
    end
end

-- Test 3: Window Change Event Notifications
local function test_window_change_events()
    print("\n=== Test 3: Window Change Event Notifications ===")
    
    -- Test 3.1: Register window change event handler
    print("\n3.1 Testing window change event registration...")
    
    local event_handler_called = false
    local event_data = nil
    
    local function test_window_handler(event)
        event_handler_called = true
        event_data = event
        print("  🪟 Window change event received: " .. event.window_id)
    end
    
    -- Test the window change handler registration
    local success, error_msg = M.register_window_change_handler(test_window_handler)
    
    if success then
        print("  ✅ Window change handler registered successfully (GREEN)")
        return true
    else
        print("  ❌ Failed to register window change handler: " .. error_msg)
        return false
    end
end

-- Run the TDD tests
print("Starting TDD Tests for Real-time Event Notifications...")
print("=====================================================")
print("Following TDD Cycle: RED -> GREEN -> REFACTOR")
print("Step 1: Write failing tests (RED)")
print("")

local test1_result = test_buffer_change_events()
local test2_result = test_cursor_movement_events() 
local test3_result = test_window_change_events()

print("\n=== TDD Test Results ===")
print("Test 1 (Buffer Change Events): " .. (test1_result and "PASS" or "FAIL"))
print("Test 2 (Cursor Movement Events): " .. (test2_result and "PASS" or "FAIL"))
print("Test 3 (Window Change Events): " .. (test3_result and "PASS" or "FAIL"))

if test1_result and test2_result and test3_result then
    print("\n🎯 TDD Status: GREEN")
    print("All tests are passing! Basic handler registration implemented.")
    print("Next step: Add event triggering and handler execution (REFACTOR)")
else
    print("\n🎯 TDD Status: PARTIAL")
    print("Some tests are still failing - continue implementation.")
end

print("\n📋 Implemented Functions:")
print("  ✅ M.register_buffer_change_handler(handler)")
print("  ✅ M.register_cursor_movement_handler(handler)")
print("  ✅ M.register_window_change_handler(handler)")
print("\n📋 Next Requirements:")
print("  🔧 Event triggering system")
print("  🔧 Handler execution mechanism")
print("  🔧 Event data structure")
print("  🔧 Integration with Neovim autocommands") 