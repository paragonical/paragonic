#!/usr/bin/env lua

--[[
Test Parse JSON Response Fix
TDD Step 3: Fix parse_json_response to handle tables and strings
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Load the paragonic module
local M = require("paragonic")

-- Test 1: Current parse_json_response behavior (RED)
local function test_current_parse_json_response()
    print("=== Test 1: Current parse_json_response Behavior (RED) ===")
    
    -- Test 1.1: Test with JSON string (should work)
    print("\n1.1 Testing with JSON string...")
    local json_string = '{"result": "Hello", "message": {"content": "Test"}}'
    local parsed = M.parse_json_response(json_string)
    
    if parsed and parsed.result then
        print("  ✅ JSON string parsing works")
    else
        print("  ❌ JSON string parsing failed")
        return false
    end
    
    -- Test 1.2: Test with table (should fail - RED)
    print("\n1.2 Testing with table (should fail)...")
    local table_data = {result = "Hello", message = {content = "Test"}}
    local parsed_table = M.parse_json_response(table_data)
    
    if not parsed_table then
        print("  ✅ Table parsing correctly fails (RED)")
        print("  📋 This is the expected failure - parse_json_response only handles strings")
    else
        print("  ❌ Table parsing unexpectedly succeeded")
        return false
    end
    
    return true
end

-- Test 2: Enhanced parse_json_response function (GREEN)
local function test_enhanced_parse_json_response()
    print("\n=== Test 2: Enhanced parse_json_response Function (GREEN) ===")
    
    -- Test 2.1: Test enhanced function with JSON string
    print("\n2.1 Testing enhanced function with JSON string...")
    local json_string = '{"result": "Hello", "message": {"content": "Test"}}'
    local parsed = M.parse_json_response_enhanced(json_string)
    
    if parsed and parsed.result then
        print("  ✅ Enhanced JSON string parsing works")
    else
        print("  ❌ Enhanced JSON string parsing failed")
        return false
    end
    
    -- Test 2.2: Test enhanced function with table (should work - GREEN)
    print("\n2.2 Testing enhanced function with table...")
    local table_data = {result = "Hello", message = {content = "Test"}}
    local parsed_table = M.parse_json_response_enhanced(table_data)
    
    if parsed_table and parsed_table.result then
        print("  ✅ Enhanced table parsing works (GREEN)")
    else
        print("  ❌ Enhanced table parsing failed")
        return false
    end
    
    -- Test 2.3: Test enhanced function with nil
    print("\n2.3 Testing enhanced function with nil...")
    local parsed_nil = M.parse_json_response_enhanced(nil)
    
    if not parsed_nil then
        print("  ✅ Enhanced nil handling works")
    else
        print("  ❌ Enhanced nil handling failed")
        return false
    end
    
    return true
end

-- Test 3: Integration with send_message
local function test_send_message_integration()
    print("\n=== Test 3: Integration with send_message ===")
    
    -- Test 3.1: Test send_message with enhanced parsing
    print("\n3.1 Testing send_message with enhanced parsing...")
    
    local test_message = "Say hello"
    local response, error_msg = M.send_message_enhanced(test_message, "llama2")
    
    if response then
        print("  ✅ send_message_enhanced succeeded: " .. response:sub(1, 50) .. "...")
        return true
    else
        print("  ❌ send_message_enhanced failed: " .. tostring(error_msg))
        return false
    end
end

-- Run the TDD tests
print("Starting TDD Tests for Parse JSON Response Fix...")
print("=================================================")
print("Following TDD Cycle: RED -> GREEN -> REFACTOR")
print("Step 3: Fix parse_json_response to handle tables and strings")
print("")

local test1_result = test_current_parse_json_response()
local test2_result = test_enhanced_parse_json_response()
local test3_result = test_send_message_integration()

print("\n=== TDD Test Results ===")
print("Test 1 (Current Behavior): " .. (test1_result and "PASS" or "FAIL"))
print("Test 2 (Enhanced Function): " .. (test2_result and "PASS" or "FAIL"))
print("Test 3 (Integration): " .. (test3_result and "PASS" or "FAIL"))

if test1_result and test2_result and test3_result then
    print("\n🎯 TDD Status: GREEN")
    print("All parse_json_response tests are passing!")
    print("Next step: Replace original function with enhanced version")
else
    print("\n🎯 TDD Status: RED")
    print("Some parse_json_response tests are failing.")
    print("Focus on implementing the enhanced function.")
end

print("\n📋 Implementation Requirements:")
print("  🔧 M.parse_json_response_enhanced() - handle both strings and tables")
print("  🔧 M.send_message_enhanced() - use enhanced parsing")
print("  🔧 Backward compatibility with existing string parsing")
print("  🔧 Proper error handling for invalid inputs") 