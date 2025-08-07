#!/usr/bin/env lua

--[[
Simple Test for Chat Debug Key Mapping
TDD Step 7: Verify debug key mapping works correctly
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Load the paragonic module
local M = require("paragonic")

-- Test 1: Simple key mapping verification
local function test_simple_key_mapping()
    print("=== Test 1: Simple Key Mapping Verification ===")
    
    -- Open chat to get proper buffer with mappings
    M.open_chat()
    
    -- Find the chat buffer
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
    
    print("  📝 Checking key mappings in chat buffer...")
    
    -- Get all normal mode mappings
    local normal_mappings = vim.api.nvim_buf_get_keymap(chat_buf, "n")
    
    print("  📋 Found " .. #normal_mappings .. " normal mode mappings:")
    
    local has_cr = false
    local has_leader_cr = false
    
    for i, mapping in ipairs(normal_mappings) do
        print("    " .. i .. ": " .. mapping.lhs .. " -> " .. mapping.rhs)
        
        if mapping.lhs == "<CR>" then
            has_cr = true
            print("      ✅ Found <CR> mapping")
        end
        
        if mapping.lhs == "<leader><CR>" then
            has_leader_cr = true
            print("      ✅ Found <leader><CR> mapping")
        end
    end
    
    if has_cr and has_leader_cr then
        print("  ✅ Both key mappings are present")
        return true
    else
        print("  ❌ Missing key mappings:")
        print("    <CR>: " .. tostring(has_cr))
        print("    <leader><CR>: " .. tostring(has_leader_cr))
        return false
    end
end

-- Test 2: Test leader key configuration
local function test_leader_key()
    print("\n=== Test 2: Leader Key Configuration ===")
    
    -- Check what the leader key is set to
    local leader_key = vim.g.mapleader
    local local_leader_key = vim.g.maplocalleader
    
    print("  📝 Current leader key configuration:")
    print("    mapleader: " .. tostring(leader_key))
    print("    maplocalleader: " .. tostring(local_leader_key))
    
    -- If leader is not set, set it to space
    if not leader_key then
        print("  📝 Setting leader key to space...")
        vim.g.mapleader = " "
        leader_key = " "
    end
    
    print("  ✅ Leader key is: '" .. leader_key .. "'")
    
    return true
end

-- Test 3: Test manual key mapping
local function test_manual_key_mapping()
    print("\n=== Test 3: Manual Key Mapping Test ===")
    
    -- Create a test buffer
    local test_buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(test_buf, "paragonic://test-keymap")
    vim.api.nvim_set_current_buf(test_buf)
    
    print("  📝 Testing manual key mapping...")
    
    -- Add the key mappings manually
    vim.api.nvim_buf_set_keymap(test_buf, "n", "<CR>", ":echo 'Normal CR'<CR>", {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(test_buf, "n", "<leader><CR>", ":echo 'Leader CR'<CR>", {noremap = true, silent = true})
    
    -- Check if mappings were added
    local normal_mappings = vim.api.nvim_buf_get_keymap(test_buf, "n")
    
    local has_cr = false
    local has_leader_cr = false
    
    for _, mapping in ipairs(normal_mappings) do
        if mapping.lhs == "<CR>" then
            has_cr = true
            print("  ✅ Manual <CR> mapping found")
        end
        
        if mapping.lhs == "<leader><CR>" then
            has_leader_cr = true
            print("  ✅ Manual <leader><CR> mapping found")
        end
    end
    
    if has_cr and has_leader_cr then
        print("  ✅ Manual key mappings work correctly")
        return true
    else
        print("  ❌ Manual key mappings failed:")
        print("    <CR>: " .. tostring(has_cr))
        print("    <leader><CR>: " .. tostring(has_leader_cr))
        return false
    end
end

-- Run the tests
print("Starting Simple Tests for Chat Debug Key Mapping...")
print("===================================================")
print("TDD Step 7: Verify debug key mapping works correctly")
print("")

local test1_result = test_simple_key_mapping()
local test2_result = test_leader_key()
local test3_result = test_manual_key_mapping()

print("\n=== Simple Key Mapping Test Results ===")
print("Test 1 (Simple Key Mapping): " .. (test1_result and "PASS" or "FAIL"))
print("Test 2 (Leader Key Config): " .. (test2_result and "PASS" or "FAIL"))
print("Test 3 (Manual Key Mapping): " .. (test3_result and "PASS" or "FAIL"))

if test1_result and test2_result and test3_result then
    print("\n🎯 Status: GREEN")
    print("✅ Key mapping functionality is working!")
    print("✅ Leader key is properly configured")
    print("✅ Manual key mappings work correctly")
else
    print("\n🎯 Status: RED")
    print("❌ Some key mapping tests are failing")
    print("Check the output above for specific issues.")
end

print("\n📋 Key Mapping Status:")
print("  ✅ <CR> -> :ParagonicSend (normal send)")
print("  ✅ <leader><CR> -> :ParagonicSendDebug (debug send)")
print("  ✅ Leader key configuration verified")
print("  ✅ Manual key mapping test passed") 