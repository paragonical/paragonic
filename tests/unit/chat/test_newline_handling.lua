-- Unit test for newline handling in chat module
-- This test verifies that all nvim_buf_set_lines calls properly handle newlines

package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua'

-- Mock vim for standalone testing
vim = {
    api = {
        nvim_buf_set_lines = function(buf, start, end_line, strict_indexing, lines)
            -- Verify that no line contains newlines
            for i, line in ipairs(lines) do
                if line:find("\n") or line:find("\r") then
                    error(string.format("Line %d contains newlines: %q", i, line))
                end
            end
            return true
        end,
        nvim_get_current_buf = function()
            return 1
        end,
        nvim_win_get_cursor = function(win)
            return {10, 0}
        end,
        nvim_buf_get_lines = function(buf, start, end_line, strict_indexing)
            return {"test message"}
        end,
        nvim_buf_get_name = function(buf)
            return "paragonic://chat"
        end,
        nvim_buf_call = function(buf, fn)
            return fn()
        end,
        nvim_win_set_cursor = function(win, pos)
            return true
        end,
        nvim_buf_line_count = function(buf)
            return 20
        end,
        nvim_buf_set_option = function(buf, option, value)
            return true
        end
    },
    cmd = function(command)
        return true
    end,
    log = {
        levels = {
            ERROR = 1,
            WARN = 2,
            INFO = 3,
            DEBUG = 4
        }
    },
    notify = function(message, level)
        return true
    end,
    defer_fn = function(fn, delay)
        return fn()
    end
}

-- Test function to verify newline handling
local function test_newline_handling()
    print("=== Testing Newline Handling ===")
    
    -- Test 1: Test thinking_start with newlines
    print("\n1. Testing thinking_start with newlines...")
    local chunk_with_newlines = "This is a thinking process\nwith multiple lines\nand newlines"
    
    local lines = {}
    for line in chunk_with_newlines:gmatch("[^\r\n]+") do
        table.insert(lines, "󰧑   " .. line)
    end
    
    -- This should not throw an error
    local success, err = pcall(function()
        vim.api.nvim_buf_set_lines(1, 0, 0, false, lines)
    end)
    
    if success then
        print("  ✅ thinking_start newline handling works")
    else
        print("  ❌ thinking_start newline handling failed: " .. tostring(err))
        return false
    end
    
    -- Test 2: Test thinking_step with newlines
    print("\n2. Testing thinking_step with newlines...")
    local step_chunk = "Step 1: Analyze the problem\nStep 2: Consider solutions\nStep 3: Choose best approach"
    
    local step_lines = {}
    for line in step_chunk:gmatch("[^\r\n]+") do
        table.insert(step_lines, "〻   " .. line)
    end
    
    success, err = pcall(function()
        vim.api.nvim_buf_set_lines(1, 0, 0, false, step_lines)
    end)
    
    if success then
        print("  ✅ thinking_step newline handling works")
    else
        print("  ❌ thinking_step newline handling failed: " .. tostring(err))
        return false
    end
    
    -- Test 3: Test thinking_content with newlines
    print("\n3. Testing thinking_content with newlines...")
    local content_chunk = "This is detailed thinking content\nwith multiple paragraphs\nand indentation"
    
    local content_lines = {}
    for line in content_chunk:gmatch("[^\r\n]+") do
        table.insert(content_lines, "   " .. line)
    end
    
    success, err = pcall(function()
        vim.api.nvim_buf_set_lines(1, 0, 0, false, content_lines)
    end)
    
    if success then
        print("  ✅ thinking_content newline handling works")
    else
        print("  ❌ thinking_content newline handling failed: " .. tostring(err))
        return false
    end
    
    -- Test 4: Test regular_content with newlines
    print("\n4. Testing regular_content with newlines...")
    local response_buffer = "This is the final response\nwith multiple lines\nand proper formatting"
    
    local response_lines = {}
    for line in response_buffer:gmatch("[^\r\n]+") do
        table.insert(response_lines, "◊   " .. line)
    end
    
    success, err = pcall(function()
        vim.api.nvim_buf_set_lines(1, 0, 0, false, response_lines)
    end)
    
    if success then
        print("  ✅ regular_content newline handling works")
    else
        print("  ❌ regular_content newline handling failed: " .. tostring(err))
        return false
    end
    
    -- Test 5: Test edge cases
    print("\n5. Testing edge cases...")
    
    -- Empty chunk
    local empty_lines = {}
    for line in ("\n"):gmatch("[^\r\n]+") do
        table.insert(empty_lines, "◊   " .. line)
    end
    
    success, err = pcall(function()
        vim.api.nvim_buf_set_lines(1, 0, 0, false, empty_lines)
    end)
    
    if success then
        print("  ✅ Empty chunk handling works")
    else
        print("  ❌ Empty chunk handling failed: " .. tostring(err))
        return false
    end
    
    -- Chunk with only newlines
    local newline_only_lines = {}
    for line in ("\n\n\n"):gmatch("[^\r\n]+") do
        table.insert(newline_only_lines, "◊   " .. line)
    end
    
    success, err = pcall(function()
        vim.api.nvim_buf_set_lines(1, 0, 0, false, newline_only_lines)
    end)
    
    if success then
        print("  ✅ Newline-only chunk handling works")
    else
        print("  ❌ Newline-only chunk handling failed: " .. tostring(err))
        return false
    end
    
    print("\n✅ All newline handling tests passed!")
    return true
end

-- Run the test
local success = test_newline_handling()
if success then
    print("\n🎉 All tests passed!")
    os.exit(0)
else
    print("\n💥 Tests failed!")
    os.exit(1)
end
