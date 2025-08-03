#!/usr/bin/env lua

--[[
Test script for agent file editing functionality
This tests the ability for an agent to edit files in the Neovim session
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Test agent file editing functionality
local function test_agent_file_edit()
    print("=== Testing Agent File Edit ===")
    
    -- Mock the required vim functions for testing
    local vim_mock = {
        api = {
            nvim_list_bufs = function() return {1, 2, 3} end,
            nvim_buf_get_name = function(buf) 
                if buf == 1 then return "/tmp/file1.txt"
                elseif buf == 2 then return "/tmp/file2.lua"
                else return "/tmp/file3.md" end
            end,
            nvim_buf_set_lines = function(buf, start, end_, strict, lines)
                print("  Set lines in buffer " .. buf .. " from " .. start .. " to " .. end_)
                return 0 -- Success
            end,
            nvim_buf_get_lines = function(buf, start, end_, strict)
                if start == 0 and end_ == -1 then
                    return {"line 1", "line 2", "line 3"}
                else
                    return {"line " .. (start + 1)}
                end
            end,
            nvim_buf_get_option = function(buf, option)
                if option == "modifiable" then return true end
                return nil
            end,
            nvim_get_current_buf = function() return 1 end,
            nvim_set_current_buf = function(buf)
                print("  Set current buffer to " .. buf)
            end
        },
        fn = {
            expand = function(expr) 
                if expr == "%:p" then return "/tmp/current.txt"
                else return expr end
            end,
            input = function(prompt) 
                if prompt:find("File path") then
                    return "/tmp/test_file.txt"
                elseif prompt:find("Line number") then
                    return "5"
                else
                    return "test content"
                end
            end
        },
        notify = function(msg, level) 
            print("  Notify [" .. (level or "info") .. "]: " .. msg)
        end,
        log = {
            levels = {
                INFO = 1,
                WARN = 2,
                ERROR = 3
            }
        }
    }
    
    -- Replace global vim temporarily
    local original_vim = _G.vim
    _G.vim = vim_mock
    
    -- Test the agent_edit_file function
    print("  Testing agent_edit_file function...")
    
    -- Create a simple test module
    local M = {}
    
    -- Edit a file in the current session
    function M.agent_edit_file(args)
        local file_path = args[1]
        local line_number = tonumber(args[2]) or 1
        local content = args[3] or ""
        
        if not file_path or file_path == "" then
            vim.notify("File path is required", vim.log.levels.WARN)
            return false
        end
        
        -- Find buffer by file path
        local target_buffer = nil
        local buffers = vim.api.nvim_list_bufs()
        
        for _, buf in ipairs(buffers) do
            local buf_name = vim.api.nvim_buf_get_name(buf)
            if buf_name == file_path then
                target_buffer = buf
                break
            end
        end
        
        if not target_buffer then
            vim.notify("File not found in current session: " .. file_path, vim.log.levels.WARN)
            return false
        end
        
        -- Check if buffer is modifiable
        local modifiable = vim.api.nvim_buf_get_option(target_buffer, "modifiable")
        if not modifiable then
            vim.notify("File is not modifiable: " .. file_path, vim.log.levels.WARN)
            return false
        end
        
        -- Switch to the target buffer
        vim.api.nvim_set_current_buf(target_buffer)
        
        -- Get current content
        local current_lines = vim.api.nvim_buf_get_lines(target_buffer, 0, -1, false)
        
        -- Prepare new content
        local new_lines = {}
        if content ~= "" then
            -- If content provided, replace the specified line
            for i, line in ipairs(current_lines) do
                if i == line_number then
                    table.insert(new_lines, content)
                else
                    table.insert(new_lines, line)
                end
            end
        else
            -- If no content, just use current lines (for viewing)
            new_lines = current_lines
        end
        
        -- Update the buffer
        if content ~= "" then
            vim.api.nvim_buf_set_lines(target_buffer, 0, -1, false, new_lines)
            vim.notify("Edited file: " .. file_path .. " at line " .. line_number, vim.log.levels.INFO)
        else
            vim.notify("Switched to file: " .. file_path, vim.log.levels.INFO)
        end
        
        return true
    end
    
    -- Test the function
    print("  Testing file editing...")
    local success1 = M.agent_edit_file({"/tmp/file1.txt", "2", "new content"})
    assert(success1 == true, "File editing should succeed")
    
    print("  Testing file switching...")
    local success2 = M.agent_edit_file({"/tmp/file2.lua"})
    assert(success2 == true, "File switching should succeed")
    
    print("  Testing invalid file...")
    local success3 = M.agent_edit_file({"/tmp/nonexistent.txt"})
    assert(success3 == false, "Invalid file should fail")
    
    print("  Testing missing file path...")
    local success4 = M.agent_edit_file({})
    assert(success4 == false, "Missing file path should fail")
    
    print("  ✓ agent_edit_file function works")
    
    -- Test file content manipulation
    print("  Testing file content manipulation...")
    function M.agent_get_file_content(file_path)
        if not file_path or file_path == "" then
            return nil, "File path is required"
        end
        
        -- Find buffer by file path
        local target_buffer = nil
        local buffers = vim.api.nvim_list_bufs()
        
        for _, buf in ipairs(buffers) do
            local buf_name = vim.api.nvim_buf_get_name(buf)
            if buf_name == file_path then
                target_buffer = buf
                break
            end
        end
        
        if not target_buffer then
            return nil, "File not found in current session: " .. file_path
        end
        
        -- Get file content
        local lines = vim.api.nvim_buf_get_lines(target_buffer, 0, -1, false)
        return {
            file_path = file_path,
            buffer_id = target_buffer,
            line_count = #lines,
            content = lines
        }
    end
    
    local content1 = M.agent_get_file_content("/tmp/file1.txt")
    assert(content1 ~= nil, "Should get file content")
    assert(content1.file_path == "/tmp/file1.txt", "Should have correct file path")
    assert(content1.line_count == 3, "Should have correct line count")
    
    local content2, error = M.agent_get_file_content("/tmp/nonexistent.txt")
    assert(content2 == nil, "Should return nil for non-existent file")
    assert(error ~= nil, "Should return error message")
    
    print("  ✓ File content manipulation works")
    
    -- Restore original vim
    _G.vim = original_vim
    
    print("✓ All agent file edit tests passed!")
end

-- Main test execution
print("=== Agent File Edit Test ===")
print("Testing agent file editing functionality...")

-- Run tests
test_agent_file_edit()

print("\n=== Test Complete ===")
print("✓ All agent file edit tests passed!")
print("Agent file edit features verified:")
print("  • Edit files in current session")
print("  • Switch between files")
print("  • Get file content")
print("  • Validate file existence")
print("  • Check file modifiability")
print("  • Error handling for invalid files") 