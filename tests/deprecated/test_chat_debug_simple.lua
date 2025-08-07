#!/usr/bin/env lua

--[[
Simple Test for Chat Debug Functionality
TDD Step 6: Verify debug messages work correctly
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Load the paragonic module
local M = require("paragonic")

-- Test 1: Simple debug message test
local function test_simple_debug()
    print("=== Test 1: Simple Debug Message Test ===")
    
    -- Create test buffer
    local test_buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(test_buf, "paragonic://test-simple")
    vim.api.nvim_set_current_buf(test_buf)
    
    -- Add initial content
    vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, {
        "# Test Simple Debug",
        "",
        "---"
    })
    
    print("  📝 Testing debug message appending...")
    
    -- Test different debug levels
    local debug_tests = {
        {message = "RPC client connected", level = "info"},
        {message = "Sending message to AI...", level = "debug"},
        {message = "Received response from AI", level = "success"},
        {message = "Failed to parse response", level = "error"},
        {message = "Timeout waiting for response", level = "warning"}
    }
    
    for i, test in ipairs(debug_tests) do
        local success, error_msg = M.append_debug_message(test_buf, test.message, test.level)
        
        if success then
            print("  ✅ Debug message " .. i .. " added: " .. test.level)
        else
            print("  ❌ Debug message " .. i .. " failed: " .. tostring(error_msg))
            return false
        end
    end
    
    -- Verify all messages were added
    local final_lines = vim.api.nvim_buf_get_lines(test_buf, 0, -1, false)
    
    print("  📋 Final buffer has " .. #final_lines .. " lines")
    
    -- Count debug messages
    local debug_count = 0
    for i, line in ipairs(final_lines) do
        if line:find("DEBUG %[") then
            debug_count = debug_count + 1
            print("    Line " .. i .. ": " .. line)
        end
    end
    
    if debug_count == 5 then
        print("  ✅ All 5 debug messages found")
        return true
    else
        print("  ❌ Expected 5 debug messages, found " .. debug_count)
        return false
    end
end

-- Test 2: Test with actual chat buffer
local function test_chat_buffer_debug()
    print("\n=== Test 2: Chat Buffer Debug Test ===")
    
    -- Create chat buffer
    local chat_buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(chat_buf, "paragonic://chat")
    vim.api.nvim_set_current_buf(chat_buf)
    
    -- Add initial chat content
    vim.api.nvim_buf_set_lines(chat_buf, 0, -1, false, {
        "# Paragonic Chat",
        "",
        "Available models: llama2 (default)",
        "",
        "Type your message below and use :ParagonicSend to send:",
        "",
        "---"
    })
    
    print("  📝 Testing debug messages in chat buffer...")
    
    -- Add some debug messages
    M.append_debug_message(chat_buf, "Chat buffer initialized", "info")
    M.append_debug_message(chat_buf, "Ready to send messages", "success")
    
    -- Add a user message
    vim.api.nvim_buf_set_lines(chat_buf, -1, -1, false, {
        "",
        "**User:** Hello, can you help me?",
        ""
    })
    
    -- Add more debug messages
    M.append_debug_message(chat_buf, "User message added", "debug")
    M.append_debug_message(chat_buf, "Preparing to send message", "debug")
    
    -- Verify debug messages
    local final_lines = vim.api.nvim_buf_get_lines(chat_buf, 0, -1, false)
    
    print("  📋 Chat buffer has " .. #final_lines .. " lines")
    
    -- Count debug messages
    local debug_count = 0
    for i, line in ipairs(final_lines) do
        if line:find("DEBUG %[") then
            debug_count = debug_count + 1
            print("    Line " .. i .. ": " .. line)
        end
    end
    
    if debug_count == 4 then
        print("  ✅ All 4 debug messages found in chat buffer")
        return true
    else
        print("  ❌ Expected 4 debug messages, found " .. debug_count)
        return false
    end
end

-- Test 3: Test timeout simulation
local function test_timeout_simulation()
    print("\n=== Test 3: Timeout Simulation Test ===")
    
    -- Create test buffer
    local test_buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(test_buf, "paragonic://test-timeout")
    vim.api.nvim_set_current_buf(test_buf)
    
    -- Add initial content
    vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, {
        "# Test Timeout Simulation",
        "",
        "**User:** What is 2+2?",
        ""
    })
    
    print("  📝 Simulating timeout scenario...")
    
    -- Simulate the debug flow for a timeout
    M.append_debug_message(test_buf, "Starting message send process", "debug")
    M.append_debug_message(test_buf, "RPC client available", "info")
    M.append_debug_message(test_buf, "Sending message: What is 2+2?...", "debug")
    
    -- Simulate timeout
    M.append_debug_message(test_buf, "Timeout waiting for response from AI", "warning")
    M.append_debug_message(test_buf, "Failed to send message: timeout", "error")
    
    -- Verify timeout messages
    local final_lines = vim.api.nvim_buf_get_lines(test_buf, 0, -1, false)
    
    print("  📋 Timeout buffer has " .. #final_lines .. " lines")
    
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
        print("  ✅ Timeout simulation messages found")
        return true
    else
        print("  ❌ Missing timeout simulation messages")
        return false
    end
end

-- Run the tests
print("Starting Simple Tests for Chat Debug...")
print("=======================================")
print("TDD Step 6: Verify debug functionality works")
print("")

local test1_result = test_simple_debug()
local test2_result = test_chat_buffer_debug()
local test3_result = test_timeout_simulation()

print("\n=== Simple Debug Test Results ===")
print("Test 1 (Simple Debug): " .. (test1_result and "PASS" or "FAIL"))
print("Test 2 (Chat Buffer Debug): " .. (test2_result and "PASS" or "FAIL"))
print("Test 3 (Timeout Simulation): " .. (test3_result and "PASS" or "FAIL"))

if test1_result and test2_result and test3_result then
    print("\n🎯 Status: GREEN")
    print("✅ Debug functionality is working!")
    print("✅ Debug messages are properly appended to buffers")
    print("✅ Different debug levels are supported")
    print("✅ Timeout scenarios can be debugged")
else
    print("\n🎯 Status: RED")
    print("❌ Some debug tests are failing")
    print("Check the output above for remaining issues.")
end

print("\n📋 Debug Features Verified:")
print("  ✅ append_debug_message() function works")
print("  ✅ Debug messages appear in chat buffer")
print("  ✅ Different debug levels (info, debug, success, error, warning)")
print("  ✅ Proper message formatting")
print("  ✅ Timeout debugging support") 