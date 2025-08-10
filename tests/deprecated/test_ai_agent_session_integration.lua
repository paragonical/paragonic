#!/usr/bin/env lua

--[[
Test AI Agent Session Integration with Real-time Events
TDD Step 4: Connect events to AI agent sessions
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Load the paragonic module
local M = require("paragonic")

-- Test 1: Event Integration with AI Agent Sessions
local function test_event_session_integration()
    print("=== Test 1: Event Integration with AI Agent Sessions ===")
    
    -- Test 1.1: Events should not trigger without active session
    print("\n1.1 Testing events without active session...")
    
    -- Register a test handler
    local event_received = false
    local function test_handler(event)
        event_received = true
        print("  📝 Event received: " .. event.type)
    end
    
    M.register_buffer_change_handler(test_handler)
    
    -- Trigger event without active session
    local success, _ = M.trigger_buffer_change_event(1, "modified")
    
    if not event_received then
        print("  ✅ Correctly blocked event without active session (GREEN)")
    else
        print("  ❌ Event should not trigger without active session")
        return false
    end
    
    -- Test 1.2: Events should trigger with active session
    print("\n1.2 Testing events with active session...")
    
    -- Start AI agent session
    local session_id = M.start_ai_agent_session("EventTestAgent")
    if not session_id then
        print("  ❌ Failed to start AI agent session")
        return false
    end
    print("  ✅ Started AI agent session: " .. session_id)
    
    -- Reset event flag
    event_received = false
    
    -- Trigger event with active session
    local success, _ = M.trigger_buffer_change_event(1, "modified")
    
    if event_received then
        print("  ✅ Event triggered correctly with active session (GREEN)")
    else
        print("  ❌ Event should trigger with active session")
        M.stop_ai_agent_session()
        return false
    end
    
    -- Clean up
    M.stop_ai_agent_session()
    print("  ✅ Stopped AI agent session")
    
    return true
end

-- Test 2: Session-Aware Event Registration
local function test_session_aware_registration()
    print("\n=== Test 2: Session-Aware Event Registration ===")
    
    -- Test 2.1: Register event handler with session context
    print("\n2.1 Testing session-aware event registration...")
    
    -- Test session-aware event registration
    local success, error_msg = M.register_session_aware_handler("buffer_change", function(event)
        print("  📝 Session-aware event: " .. event.type)
    end)
    
    if success then
        print("  ✅ Session-aware handler registered successfully (GREEN)")
        return true
    else
        print("  ❌ Failed to register session-aware handler: " .. error_msg)
        return false
    end
end

-- Test 3: Event Session Tracking
local function test_event_session_tracking()
    print("\n=== Test 3: Event Session Tracking ===")
    
    -- Start AI agent session for testing
    local session_id = M.start_ai_agent_session("TrackingTestAgent")
    if not session_id then
        print("  ❌ Failed to start AI agent session for testing")
        return false
    end
    print("  ✅ Started AI agent session for testing: " .. session_id)
    
    -- Test 3.1: Track events in session
    print("\n3.1 Testing event session tracking...")
    
    -- Test event session tracking
    local success, error_msg = M.track_event_in_session("buffer_change", {buffer_id = 1, change_type = "modified"})
    
    if success then
        print("  ✅ Event tracked in session successfully (GREEN)")
    else
        print("  ❌ Failed to track event in session: " .. error_msg)
        M.stop_ai_agent_session()
        return false
    end
    
    -- Clean up
    M.stop_ai_agent_session()
    print("  ✅ Stopped AI agent session")
    
    return true
end

-- Test 4: Session Event History
local function test_session_event_history()
    print("\n=== Test 4: Session Event History ===")
    
    -- Start AI agent session for testing
    local session_id = M.start_ai_agent_session("HistoryTestAgent")
    if not session_id then
        print("  ❌ Failed to start AI agent session for testing")
        return false
    end
    print("  ✅ Started AI agent session for testing: " .. session_id)
    
    -- Track some events first
    M.track_event_in_session("buffer_change", {buffer_id = 1, change_type = "modified"})
    M.track_event_in_session("cursor_movement", {line = 10, column = 5})
    
    -- Test 4.1: Get session event history
    print("\n4.1 Testing session event history...")
    
    -- Test session event history
    local success, error_msg = M.get_session_event_history()
    
    if success then
        print("  ✅ Session event history retrieved successfully (GREEN)")
        print("    - Found " .. #error_msg .. " events in history")
    else
        print("  ❌ Failed to get session event history: " .. error_msg)
        M.stop_ai_agent_session()
        return false
    end
    
    -- Clean up
    M.stop_ai_agent_session()
    print("  ✅ Stopped AI agent session")
    
    return true
end

-- Run the TDD tests
print("Starting TDD Tests for AI Agent Session Integration...")
print("=====================================================")
print("Following TDD Cycle: RED -> GREEN -> REFACTOR")
print("Step 4: Write failing tests for session integration (RED)")
print("")

local test1_result = test_event_session_integration()
local test2_result = test_session_aware_registration()
local test3_result = test_event_session_tracking()
local test4_result = test_session_event_history()

print("\n=== TDD Test Results ===")
print("Test 1 (Event Session Integration): " .. (test1_result and "PASS" or "FAIL"))
print("Test 2 (Session-Aware Registration): " .. (test2_result and "PASS" or "FAIL"))
print("Test 3 (Event Session Tracking): " .. (test3_result and "PASS" or "FAIL"))
print("Test 4 (Session Event History): " .. (test4_result and "PASS" or "FAIL"))

if test1_result and test2_result and test3_result and test4_result then
    print("\n🎯 TDD Status: GREEN")
    print("All session integration tests are passing! AI agent session integration complete.")
    print("Next step: Add event filtering and throttling (REFACTOR)")
else
    print("\n🎯 TDD Status: PARTIAL")
    print("Some session integration tests are still failing - continue implementation.")
end

print("\n📋 Implemented Functions:")
print("  ✅ M.register_session_aware_handler(event_type, handler)")
print("  ✅ M.track_event_in_session(event_type, event_data)")
print("  ✅ M.get_session_event_history()")
print("\n📋 Next Requirements:")
print("  🔧 Event filtering and throttling")
print("  🔧 User commands for event management")
print("  🔧 Event logging and debugging")
print("  🔧 Performance optimization") 