#!/usr/bin/env lua

--[[
Unit tests for chat text extraction functionality
TDD approach: one-test-one-function for multi-line text extraction
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Mock vim API for testing
local mock_vim_api = {
    buffers = {},
    current_buffer = 1,
    cursor_positions = {}
}

function mock_vim_api.nvim_get_current_buf()
    return mock_vim_api.current_buffer
end

function mock_vim_api.nvim_buf_get_lines(bufnr, start, end_line, strict)
    local buf = mock_vim_api.buffers[bufnr] or {}
    local result = {}
    for i = start + 1, end_line do  -- Lua 1-indexed
        table.insert(result, buf[i] or "")
    end
    return result
end

function mock_vim_api.nvim_win_get_cursor(winnr)
    return mock_vim_api.cursor_positions[winnr] or {1, 0}
end

function mock_vim_api.nvim_buf_line_count(bufnr)
    local buf = mock_vim_api.buffers[bufnr] or {}
    return #buf
end

-- Replace vim.api with our mock
vim = { api = mock_vim_api }

-- Load the chat module
local chat = require("paragonic.chat")

-- Test 1: Extract text backward from cursor to tombstone
local function test_extract_backward_to_tombstone()
    print("=== Test 1: Extract backward from cursor to tombstone ===")
    
    -- Setup mock buffer with content
    mock_vim_api.buffers[1] = {
        "Some previous content",
        "∎",  -- tombstone marker
        "Line 1 of input",
        "Line 2 of input", 
        "Line 3 of input"  -- cursor on this line
    }
    mock_vim_api.cursor_positions[0] = {5, 0}  -- cursor on line 5 (1-indexed)
    
    -- Call the extraction function (we need to expose it for testing)
    -- For now, we'll test the public interface that uses it
    local message = chat._test_extract_backward_to_tombstone(1)
    
    -- Should extract from line 3-5 (after tombstone to cursor)
    local expected = "Line 1 of input\nLine 2 of input\nLine 3 of input"
    assert(message == expected, "Should extract multi-line text from tombstone to cursor")
    
    print("✓ Extract backward to tombstone test passed!")
end

-- Test 2: Extract text forward from cursor to next tombstone
local function test_extract_forward_to_tombstone()
    print("=== Test 2: Extract forward from cursor to next tombstone ===")
    
    -- Setup mock buffer with content
    mock_vim_api.buffers[1] = {
        "Previous content",
        "∎",
        "Line 1 of input",  -- cursor on this line
        "Line 2 of input",
        "Line 3 of input",
        "∎",  -- next tombstone
        "Following content"
    }
    mock_vim_api.cursor_positions[0] = {3, 0}  -- cursor on line 3 (1-indexed)
    
    -- Call the extraction function
    local message = chat._test_extract_forward_to_tombstone(1)
    
    -- Should extract from line 3-5 (cursor to next tombstone)
    local expected = "Line 1 of input\nLine 2 of input\nLine 3 of input"
    assert(message == expected, "Should extract multi-line text from cursor to next tombstone")
    
    print("✓ Extract forward to tombstone test passed!")
end

-- Test 3: Extract text forward from cursor to end of buffer (no tombstone)
local function test_extract_forward_to_end_of_buffer()
    print("=== Test 3: Extract forward from cursor to end of buffer ===")
    
    -- Setup mock buffer with content (no trailing tombstone)
    mock_vim_api.buffers[1] = {
        "Previous content",
        "∎",
        "Line 1 of input",  -- cursor on this line
        "Line 2 of input",
        "Line 3 of input"   -- end of buffer
    }
    mock_vim_api.cursor_positions[0] = {3, 0}  -- cursor on line 3 (1-indexed)
    
    -- Call the extraction function
    local message = chat._test_extract_forward_to_tombstone(1)
    
    -- Should extract from line 3 to end of buffer
    local expected = "Line 1 of input\nLine 2 of input\nLine 3 of input"
    assert(message == expected, "Should extract multi-line text from cursor to end of buffer")
    
    print("✓ Extract forward to end of buffer test passed!")
end

-- Test 4: Extract complete range (backward to previous + forward to next)
local function test_extract_complete_range()
    print("=== Test 4: Extract complete range (backward + forward) ===")
    
    -- Setup mock buffer with content
    mock_vim_api.buffers[1] = {
        "∎",  -- previous tombstone
        "Line 1 of input",
        "Line 2 of input",  -- cursor on this line
        "Line 3 of input",
        "Line 4 of input",
        "∎"   -- next tombstone
    }
    mock_vim_api.cursor_positions[0] = {3, 0}  -- cursor on line 3 (1-indexed)
    
    -- Call the extraction function for complete range
    local message = chat._test_extract_complete_range(1)
    
    -- Should extract from line 2-5 (after previous tombstone to before next tombstone)
    local expected = "Line 1 of input\nLine 2 of input\nLine 3 of input\nLine 4 of input"
    assert(message == expected, "Should extract complete range between tombstones")
    
    print("✓ Extract complete range test passed!")
end

-- Test 5: Handle empty lines and whitespace
local function test_handle_empty_lines_and_whitespace()
    print("=== Test 5: Handle empty lines and whitespace ===")
    
    -- Setup mock buffer with empty lines and whitespace
    mock_vim_api.buffers[1] = {
        "∎",
        "",  -- empty line
        "  Line with leading spaces",
        "",  -- another empty line
        "Line with content",  -- cursor here
        "",
        "∎"
    }
    mock_vim_api.cursor_positions[0] = {5, 0}  -- cursor on line 5 (1-indexed)
    
    -- Call the extraction function
    local message = chat._test_extract_complete_range(1)
    
    -- Should preserve empty lines and leading spaces but trim trailing whitespace
    local expected = "\n  Line with leading spaces\n\nLine with content"
    
    assert(message == expected, "Should handle empty lines and preserve whitespace structure")
    
    print("✓ Handle empty lines and whitespace test passed!")
end

-- Test 6: Handle no tombstones found
local function test_handle_no_tombstones()
    print("=== Test 6: Handle no tombstones found ===")
    
    -- Setup mock buffer without tombstones
    mock_vim_api.buffers[1] = {
        "Line 1 without tombstone",
        "Line 2 without tombstone",  -- cursor here
        "Line 3 without tombstone"
    }
    mock_vim_api.cursor_positions[0] = {2, 0}  -- cursor on line 2 (1-indexed)
    
    -- Call the extraction function
    local message = chat._test_extract_complete_range(1)
    
    -- Should extract entire buffer content
    local expected = "Line 1 without tombstone\nLine 2 without tombstone\nLine 3 without tombstone"
    assert(message == expected, "Should extract entire buffer when no tombstones found")
    
    print("✓ Handle no tombstones test passed!")
end

-- Run tests in order
print("Starting text extraction unit tests...")
print()

-- Note: These tests will fail initially because we need to implement the functions
-- This is the TDD approach - write tests first, then implement
local tests = {
    test_extract_backward_to_tombstone,
    test_extract_forward_to_tombstone,
    test_extract_forward_to_end_of_buffer,
    test_extract_complete_range,
    test_handle_empty_lines_and_whitespace,
    test_handle_no_tombstones
}

local passed = 0
local failed = 0

for i, test_func in ipairs(tests) do
    local success, err = pcall(test_func)
    if success then
        passed = passed + 1
    else
        failed = failed + 1
        print("❌ Test " .. i .. " failed: " .. (err or "unknown error"))
    end
    print()
end

print("=== Test Results ===")
print("Passed: " .. passed)
print("Failed: " .. failed)
print("Total:  " .. (passed + failed))

if failed == 0 then
    print("🎉 All tests passed!")
else
    print("⚠️  Some tests failed. This is expected in TDD - now implement the functions!")
end
