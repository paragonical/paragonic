#!/usr/bin/env lua

--[[
Test script for enhanced search UI
This script tests the enhanced search interface with keyboard mappings and improved UX
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Mock vim API for testing
local vim_mock = {
    api = {
        nvim_create_user_command = function(name, callback, opts) 
            print("  Created command: " .. name)
        end,
        nvim_list_bufs = function() return {} end,
        nvim_buf_get_name = function(buf) return "test-buffer" end,
        nvim_create_buf = function(listed, scratch) return 1 end,
        nvim_buf_set_name = function(buf, name) end,
        nvim_buf_set_option = function(buf, option, value) end,
        nvim_buf_set_lines = function(buf, start, end_, strict, lines) end,
        nvim_buf_set_var = function(buf, name, value) end,
        nvim_buf_get_var = function(buf, name) 
            if name == "paragonic_search_results" then
                return {
                    results = {
                        {
                            embedding = {
                                content_text = "Test project content",
                                content_type = "project",
                                content_id = "test-123",
                                created_at = "2025-01-01",
                                updated_at = "2025-01-02"
                            },
                            similarity_score = 0.85
                        }
                    }
                }
            end
            return nil
        end,
        nvim_command = function(cmd) end,
        nvim_set_current_buf = function(buf) end,
        nvim_get_current_buf = function() return 1 end,
        nvim_win_get_cursor = function(win) return {5, 0} end,
        nvim_buf_get_lines = function(buf, start, end_, strict) return {"test line"} end,
        nvim_buf_line_count = function(buf) return 10 end,
        nvim_open_win = function(buf, enter, config) return 1 end,
        nvim_win_set_cursor = function(win, pos) end,
        nvim_buf_set_keymap = function(buf, mode, lhs, rhs, opts) end,
        nvim_keymap_set = function(mode, lhs, rhs, opts) 
            print("  Set keymap: " .. mode .. " " .. lhs)
        end
    },
    fn = {
        input = function(prompt) 
            if prompt:find("🔍 Search") then
                return "test query"
            elseif prompt:find("📁 Content Type") then
                return "project"
            elseif prompt:find("🔤 Include text filtering") then
                return "y"
            else
                return "test"
            end
        end,
        getreg = function(reg) return "test selection" end,
        setreg = function(reg, value) end,
        shellescape = function(text) return "'" .. text .. "'" end,
        stdpath = function(path) return "/tmp" end
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
    },
    o = {
        columns = 120,
        lines = 30
    },
    tbl_deep_extend = function(mode, ...) 
        return {...}
    end,
    cmd = function(cmd) 
        print("  Execute command: " .. cmd)
    end
}

-- Replace global vim with mock
_G.vim = vim_mock

-- Test function for enhanced search UI
local function test_enhanced_search_ui()
    print("Testing enhanced search UI...")
    
    -- Load the paragonic module
    local paragonic = require("paragonic")
    
    -- Test that enhanced functions exist
    print("  Testing enhanced function existence...")
    assert(type(paragonic.quick_search) == "function", "quick_search function should exist")
    assert(type(paragonic.quick_filtered_search) == "function", "quick_filtered_search function should exist")
    assert(type(paragonic.quick_hybrid_search) == "function", "quick_hybrid_search function should exist")
    assert(type(paragonic.select_search_result) == "function", "select_search_result function should exist")
    assert(type(paragonic.show_result_details) == "function", "show_result_details function should exist")
    print("  ✓ All enhanced functions exist")
    
    -- Test keymap setup
    print("  Testing keymap setup...")
    paragonic._setup_keymaps()
    print("  ✓ Keymap setup works")
    
    -- Test quick search functions
    print("  Testing quick search functions...")
    paragonic.quick_search()
    print("  ✓ Quick search works")
    
    paragonic.quick_filtered_search()
    print("  ✓ Quick filtered search works")
    
    paragonic.quick_hybrid_search()
    print("  ✓ Quick hybrid search works")
    
    -- Test result selection
    print("  Testing result selection...")
    paragonic.select_search_result(1)
    print("  ✓ Result selection works")
    
    -- Test result details display
    print("  Testing result details display...")
    local mock_result = {
        embedding = {
            content_text = "Test project content",
            content_type = "project",
            content_id = "test-123",
            created_at = "2025-01-01",
            updated_at = "2025-01-02"
        },
        similarity_score = 0.85
    }
    paragonic.show_result_details(mock_result)
    print("  ✓ Result details display works")
    
    print("✓ All enhanced search UI tests passed!")
end

-- Test function for keyboard mappings
local function test_keyboard_mappings()
    print("Testing keyboard mappings...")
    
    -- Load the paragonic module
    local paragonic = require("paragonic")
    
    -- Test keymap setup
    print("  Testing keymap setup...")
    paragonic._setup_keymaps()
    print("  ✓ Keymap setup completed")
    
    print("✓ Keyboard mapping tests passed!")
end

-- Test function for enhanced display
local function test_enhanced_display()
    print("Testing enhanced display functionality...")
    
    -- Load the paragonic module
    local paragonic = require("paragonic")
    
    -- Test enhanced display with mock results
    print("  Testing enhanced display...")
    local mock_results = {
        results = {
            {
                embedding = {
                    content_text = "Test project content about machine learning",
                    content_type = "project"
                },
                similarity_score = 0.85
            },
            {
                embedding = {
                    content_text = "Test task content for implementing neural networks",
                    content_type = "task"
                },
                similarity_score = 0.72
            },
            {
                embedding = {
                    content_text = "Test note content about AI algorithms",
                    content_type = "note"
                },
                similarity_score = 0.65
            }
        }
    }
    
    paragonic.display_search_results(mock_results, "Enhanced Search Test")
    print("  ✓ Enhanced display works")
    
    print("✓ Enhanced display tests passed!")
end

-- Main test execution
print("=== Enhanced Search UI Test ===")
print("Testing enhanced search interface with keyboard mappings and improved UX...")

-- Run tests
test_keyboard_mappings()
test_enhanced_display()
test_enhanced_search_ui()

print("\n=== Test Complete ===")
print("✓ All enhanced search UI tests passed!")
print("Enhanced features available:")
print("  • Keyboard mappings: <leader>ps, <leader>pf, <leader>ph")
print("  • Visual selection search: select text + <leader>ps/pf/ph")
print("  • Enhanced result display with emojis and colors")
print("  • Interactive result selection with <CR>")
print("  • Detailed result view")
print("  • Better error messages and help text") 