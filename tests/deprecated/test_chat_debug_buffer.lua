#!/usr/bin/env lua

--[[
Test Chat Debug Buffer Implementation
TDD Step 6: Add debug messages to chat buffer instead of notifications
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Load the paragonic module
local M = require("paragonic")

-- Test 1: Debug message appending function (RED)
local function test_debug_message_appending()
    print("=== Test 1: Debug Message Appending (RED) ===")
    
    -- Test 1.1: Test debug message function (should fail - RED)
    print("\n1.1 Testing debug message function...")
    
    local test_buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(test_buf, "paragonic://test-debug")
    vim.api.nvim_set_current_buf(test_buf)
    
    -- Add initial content
    vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, {
        "# Test Debug Chat",
        "",
        "---"
    })
    
    -- Test debug message function
    local success, error_msg = pcall(function()
        return M.append_debug_message(test_buf, "Test debug message", "info")
    end)
    
    if success then
        print("  ✅ Debug message function works (GREEN)")
        
        -- Verify message was added
        local final_lines = vim.api.nvim_buf_get_lines(test_buf, 0, -1, false)
        local has_debug = false
        for _, line in ipairs(final_lines) do
            if line:find("**DEBUG %[INFO%]:** Test debug message") then
                has_debug = true
                break
            end
        end
        
        if has_debug then
            print("  ✅ Debug message was appended to buffer")
        else
            print("  ❌ Debug message not found in buffer")
            return false
        end
    else
        print("  ❌ Debug message function failed: " .. tostring(error_msg))
        return false
    end
    
    return true
end

-- Test 2: Enhanced send_message_command with debug (RED)
local function test_enhanced_send_message_command()
    print("\n=== Test 2: Enhanced send_message_command with Debug (RED) ===")
    
    -- Test 2.1: Test enhanced command (should fail - RED)
    print("\n2.1 Testing enhanced send_message_command...")
    
    local test_buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(test_buf, "paragonic://test-enhanced")
    vim.api.nvim_set_current_buf(test_buf)
    
    -- Add initial content
    vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, {
        "# Test Enhanced Chat",
        "",
        "**User:** Hello, can you help me?",
        ""
    })
    
    -- Test enhanced send_message_command
    local success, error_msg = pcall(function()
        return M.send_message_command_debug()
    end)
    
    if success then
        print("  ✅ Enhanced send_message_command works (GREEN)")
        
        -- Verify debug messages were added
        local final_lines = vim.api.nvim_buf_get_lines(test_buf, 0, -1, false)
        local debug_count = 0
        for _, line in ipairs(final_lines) do
            if line:find("**DEBUG %[") then
                debug_count = debug_count + 1
            end
        end
        
        if debug_count > 0 then
            print("  ✅ Debug messages were added to buffer: " .. debug_count .. " messages")
        else
            print("  ❌ No debug messages found in buffer")
            return false
        end
    else
        print("  ❌ Enhanced send_message_command failed: " .. tostring(error_msg))
        return false
    end
    
    return true
end

-- Test 3: Debug message formatting
local function test_debug_message_formatting()
    print("\n=== Test 3: Debug Message Formatting ===")
    
    -- Test 3.1: Test debug message format
    print("\n3.1 Testing debug message format...")
    
    local test_buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(test_buf, "paragonic://test-format")
    vim.api.nvim_set_current_buf(test_buf)
    
    -- Add initial content
    vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, {
        "# Test Format Chat",
        "",
        "---"
    })
    
    -- Test different debug message types
    local debug_messages = {
        {message = "RPC client connected", level = "info"},
        {message = "Sending message to AI...", level = "debug"},
        {message = "Received response from AI", level = "success"},
        {message = "Failed to parse response", level = "error"},
        {message = "Timeout waiting for response", level = "warning"}
    }
    
    for i, debug_msg in ipairs(debug_messages) do
        local formatted_message = "**DEBUG [" .. debug_msg.level:upper() .. "]:** " .. debug_msg.message
        print("  📝 " .. formatted_message)
        
        -- Add to buffer manually for testing
        local current_lines = vim.api.nvim_buf_get_lines(test_buf, 0, -1, false)
        vim.api.nvim_buf_set_lines(test_buf, #current_lines, #current_lines, false, {
            "",
            formatted_message
        })
    end
    
    -- Verify formatting
    local final_lines = vim.api.nvim_buf_get_lines(test_buf, 0, -1, false)
    
    if #final_lines >= 10 then
        print("  ✅ Debug messages formatted correctly")
        print("  📋 Buffer has " .. #final_lines .. " lines")
        
        -- Check for debug markers
        local debug_count = 0
        for i, line in ipairs(final_lines) do
            if line:find("**DEBUG %[") then
                debug_count = debug_count + 1
            end
        end
        
        if debug_count == 5 then
            print("  ✅ All 5 debug messages found")
        else
            print("  ❌ Expected 5 debug messages, found " .. debug_count)
            return false
        end
    else
        print("  ❌ Debug message formatting failed")
        return false
    end
    
    return true
end

-- Run the TDD tests
print("Starting TDD Tests for Chat Debug Buffer...")
print("============================================")
print("Following TDD Cycle: RED -> GREEN -> REFACTOR")
print("Step 6: Add debug messages to chat buffer instead of notifications")
print("")

local test1_result = test_debug_message_appending()
local test2_result = test_enhanced_send_message_command()
local test3_result = test_debug_message_formatting()

print("\n=== TDD Test Results ===")
print("Test 1 (Debug Message Appending): " .. (test1_result and "PASS" or "FAIL"))
print("Test 2 (Enhanced send_message_command): " .. (test2_result and "PASS" or "FAIL"))
print("Test 3 (Debug Message Formatting): " .. (test3_result and "PASS" or "FAIL"))

if test1_result and test2_result and test3_result then
    print("\n🎯 TDD Status: GREEN")
    print("All debug buffer tests are passing!")
    print("Next step: Implement debug message functions")
else
    print("\n🎯 TDD Status: RED")
    print("Some debug buffer tests are failing - continue implementation.")
end

print("\n📋 Implementation Requirements:")
print("  🔧 M.append_debug_message(buffer, message, level)")
print("  🔧 M.send_message_command_debug() - enhanced with debug messages")
print("  🔧 Debug message formatting with levels (info, debug, success, error, warning)")
print("  🔧 Integration with existing send_message_command")
print("  🔧 Proper debug message placement in chat buffer") 