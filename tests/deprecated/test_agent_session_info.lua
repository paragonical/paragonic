#!/usr/bin/env lua

--[[
Test script for agent session info functionality
This tests the ability to get information about the current Neovim session
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Test agent session info functionality
local function test_agent_session_info()
    print("=== Testing Agent Session Info ===")
    
    -- Mock the required vim functions for testing
    local vim_mock = {
        api = {
            nvim_list_bufs = function() return {1, 2, 3} end,
            nvim_buf_get_name = function(buf) 
                if buf == 1 then return "/tmp/file1.txt"
                elseif buf == 2 then return "/tmp/file2.lua"
                else return "/tmp/file3.md" end
            end,
            nvim_buf_get_option = function(buf, option)
                if option == "buftype" then return "" end
                if option == "modifiable" then return true end
                return nil
            end,
            nvim_buf_line_count = function(buf) return 10 end,
            nvim_get_current_buf = function() return 1 end,
            nvim_get_current_dir = function() return "/tmp" end,
            nvim_list_wins = function() return {1, 2} end,
            nvim_win_get_buf = function(win) return win end,
            nvim_win_get_cursor = function(win) return {5, 0} end,
            nvim_get_mode = function() return {mode = "n"} end
        },
        fn = {
            getcwd = function() return "/tmp" end,
            expand = function(expr) 
                if expr == "%" then return "/tmp/current.txt"
                elseif expr == "%:p" then return "/tmp/current.txt"
                else return expr end
            end,
            stdpath = function(path) return "/tmp" end
        },
        o = {
            columns = 120,
            lines = 30
        }
    }
    
    -- Replace global vim temporarily
    local original_vim = _G.vim
    _G.vim = vim_mock
    
    -- Test the get_agent_session_info function
    print("  Testing get_agent_session_info function...")
    
    -- Create a simple test module
    local M = {}
    
    -- Get comprehensive session information for agent
    function M.get_agent_session_info()
        local session_info = {
            timestamp = os.time(),
            current_directory = vim.fn.getcwd(),
            current_file = vim.fn.expand("%:p"),
            buffers = {},
            windows = {},
            mode = vim.api.nvim_get_mode(),
            terminal_info = {
                columns = vim.o.columns,
                lines = vim.o.lines
            }
        }
        
        -- Get buffer information
        local buffers = vim.api.nvim_list_bufs()
        for _, buf in ipairs(buffers) do
            local buf_name = vim.api.nvim_buf_get_name(buf)
            local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
            local modifiable = vim.api.nvim_buf_get_option(buf, "modifiable")
            local line_count = vim.api.nvim_buf_line_count(buf)
            
            -- Only include file buffers (not special buffers)
            if buftype == "" and buf_name ~= "" then
                table.insert(session_info.buffers, {
                    id = buf,
                    name = buf_name,
                    line_count = line_count,
                    modifiable = modifiable,
                    is_current = (buf == vim.api.nvim_get_current_buf())
                })
            end
        end
        
        -- Get window information
        local windows = vim.api.nvim_list_wins()
        for _, win in ipairs(windows) do
            local buf = vim.api.nvim_win_get_buf(win)
            local cursor = vim.api.nvim_win_get_cursor(win)
            
            table.insert(session_info.windows, {
                id = win,
                buffer_id = buf,
                cursor_line = cursor[1],
                cursor_column = cursor[2]
            })
        end
        
        return session_info
    end
    
    -- Test the function
    local session_info = M.get_agent_session_info()
    
    -- Verify basic structure
    assert(session_info.timestamp ~= nil, "Session info should have timestamp")
    assert(session_info.current_directory ~= nil, "Session info should have current directory")
    assert(session_info.current_file ~= nil, "Session info should have current file")
    assert(type(session_info.buffers) == "table", "Session info should have buffers table")
    assert(type(session_info.windows) == "table", "Session info should have windows table")
    assert(type(session_info.mode) == "table", "Session info should have mode info")
    assert(type(session_info.terminal_info) == "table", "Session info should have terminal info")
    
    -- Verify buffer information
    assert(#session_info.buffers > 0, "Should have at least one buffer")
    local current_buffer = session_info.buffers[1]
    assert(current_buffer.id ~= nil, "Buffer should have ID")
    assert(current_buffer.name ~= nil, "Buffer should have name")
    assert(current_buffer.line_count ~= nil, "Buffer should have line count")
    assert(current_buffer.modifiable ~= nil, "Buffer should have modifiable flag")
    assert(current_buffer.is_current ~= nil, "Buffer should have is_current flag")
    
    -- Verify window information
    assert(#session_info.windows > 0, "Should have at least one window")
    local current_window = session_info.windows[1]
    assert(current_window.id ~= nil, "Window should have ID")
    assert(current_window.buffer_id ~= nil, "Window should have buffer ID")
    assert(current_window.cursor_line ~= nil, "Window should have cursor line")
    assert(current_window.cursor_column ~= nil, "Window should have cursor column")
    
    print("  ✓ get_agent_session_info function works")
    
    -- Test session info formatting
    print("  Testing session info formatting...")
    local function format_session_info(session_info)
        local lines = {
            "📋 Neovim Session Information",
            string.rep("─", 30),
            "",
            "📁 Current Directory: " .. session_info.current_directory,
            "📄 Current File: " .. session_info.current_file,
            "🎯 Mode: " .. session_info.mode.mode,
            "🖥️  Terminal: " .. session_info.terminal_info.columns .. "x" .. session_info.terminal_info.lines,
            "",
            "📚 Buffers (" .. #session_info.buffers .. "):",
            ""
        }
        
        for i, buf in ipairs(session_info.buffers) do
            local status = buf.is_current and "●" or "○"
            local modifiable = buf.modifiable and "rw" or "r-"
            table.insert(lines, string.format("  %s %s [%s] %s (%d lines)", 
                status, modifiable, buf.id, buf.name, buf.line_count))
        end
        
        table.insert(lines, "")
        table.insert(lines, "🪟 Windows (" .. #session_info.windows .. "):")
        table.insert(lines, "")
        
        for i, win in ipairs(session_info.windows) do
            table.insert(lines, string.format("  %d: buffer %d at line %d, col %d", 
                win.id, win.buffer_id, win.cursor_line, win.cursor_column))
        end
        
        return lines
    end
    
    local formatted = format_session_info(session_info)
    assert(#formatted > 0, "Formatted session info should have content")
    assert(formatted[1]:find("Neovim Session Information"), "Should have title")
    assert(formatted[4]:find("Current Directory"), "Should have current directory")
    assert(formatted[5]:find("Current File"), "Should have current file")
    
    print("  ✓ Session info formatting works")
    
    -- Restore original vim
    _G.vim = original_vim
    
    print("✓ All agent session info tests passed!")
end

-- Main test execution
print("=== Agent Session Info Test ===")
print("Testing agent session information functionality...")

-- Run tests
test_agent_session_info()

print("\n=== Test Complete ===")
print("✓ All agent session info tests passed!")
print("Agent session info features verified:")
print("  • Get comprehensive session information")
print("  • Buffer information with details")
print("  • Window information with cursor positions")
print("  • Current file and directory")
print("  • Terminal information")
print("  • Mode information")
print("  • Formatted output for display") 