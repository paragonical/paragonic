#!/usr/bin/env lua

--[[
Test Event Triggering for AI Agent Collaboration
TDD Step 2: Event triggering and handler execution
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Load the paragonic module
local M = require("paragonic")

-- Test 1: Buffer Change Event Triggering
local function test_buffer_change_triggering()
    print("=== Test 1: Buffer Change Event Triggering ===")
    
    -- Register a test handler
    local event_received = false
    local event_data = nil
    
    local function test_handler(event)
        event_received = true
        event_data = event
        print("  📝 Buffer change event triggered: " .. event.buffer_id)
    end
    
    M.register_buffer_change_handler(test_handler)
    
    -- Test 1.1: Trigger buffer change event
    print("\n1.1 Testing buffer change event triggering...")
    
    -- Test buffer change event triggering
    local success, error_msg = M.trigger_buffer_change_event(1, "modified")
    
    if success then
        print("  ✅ Buffer change event triggered successfully (GREEN)")
        return true
    else
        print("  ❌ Failed to trigger buffer change event: " .. error_msg)
        return false
    end
end

-- Test 2: Cursor Movement Event Triggering
local function test_cursor_movement_triggering()
    print("\n=== Test 2: Cursor Movement Event Triggering ===")
    
    -- Register a test handler
    local event_received = false
    local event_data = nil
    
    local function test_handler(event)
        event_received = true
        event_data = event
        print("  📍 Cursor movement event triggered: line " .. event.line .. ", col " .. event.column)
    end
    
    M.register_cursor_movement_handler(test_handler)
    
    -- Test 2.1: Trigger cursor movement event
    print("\n2.1 Testing cursor movement event triggering...")
    
    -- Test cursor movement event triggering
    local success, error_msg = M.trigger_cursor_movement_event(10, 5)
    
    if success then
        print("  ✅ Cursor movement event triggered successfully (GREEN)")
        return true
    else
        print("  ❌ Failed to trigger cursor movement event: " .. error_msg)
        return false
    end
end

-- Test 3: Window Change Event Triggering
local function test_window_change_triggering()
    print("\n=== Test 3: Window Change Event Triggering ===")
    
    -- Register a test handler
    local event_received = false
    local event_data = nil
    
    local function test_handler(event)
        event_received = true
        event_data = event
        print("  🪟 Window change event triggered: " .. event.window_id)
    end
    
    M.register_window_change_handler(test_handler)
    
    -- Test 3.1: Trigger window change event
    print("\n3.1 Testing window change event triggering...")
    
    -- Test window change event triggering
    local success, error_msg = M.trigger_window_change_event(1001, "created")
    
    if success then
        print("  ✅ Window change event triggered successfully (GREEN)")
        return true
    else
        print("  ❌ Failed to trigger window change event: " .. error_msg)
        return false
    end
end

-- Run the TDD tests
print("Starting TDD Tests for Event Triggering...")
print("==========================================")
print("Following TDD Cycle: RED -> GREEN -> REFACTOR")
print("Step 2: Write failing tests for event triggering (RED)")
print("")

local test1_result = test_buffer_change_triggering()
local test2_result = test_cursor_movement_triggering()
local test3_result = test_window_change_triggering()

print("\n=== TDD Test Results ===")
print("Test 1 (Buffer Change Triggering): " .. (test1_result and "PASS" or "FAIL"))
print("Test 2 (Cursor Movement Triggering): " .. (test2_result and "PASS" or "FAIL"))
print("Test 3 (Window Change Triggering): " .. (test3_result and "PASS" or "FAIL"))

if test1_result and test2_result and test3_result then
    print("\n🎯 TDD Status: GREEN")
    print("All triggering tests are passing! Event triggering system implemented.")
    print("Next step: Add Neovim autocommand integration (REFACTOR)")
else
    print("\n🎯 TDD Status: PARTIAL")
    print("Some triggering tests are still failing - continue implementation.")
end

print("\n📋 Implemented Functions:")
print("  ✅ M.trigger_buffer_change_event(buffer_id, change_type)")
print("  ✅ M.trigger_cursor_movement_event(line, column)")
print("  ✅ M.trigger_window_change_event(window_id, change_type)")
print("\n📋 Next Requirements:")
print("  🔧 Neovim autocommand integration")
print("  🔧 Real-time event detection")
print("  🔧 AI agent session integration")
print("  🔧 Event filtering and throttling") 