#!/usr/bin/env lua

--[[
Test script for Neovim search integration
This script tests the search functionality integrated into the Neovim plugin
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
        nvim_command = function(cmd) end,
        nvim_set_current_buf = function(buf) end,
        nvim_get_current_buf = function() return 1 end,
        nvim_win_get_cursor = function(win) return {1, 0} end,
        nvim_buf_get_lines = function(buf, start, end_, strict) return {"test line"} end,
        nvim_buf_line_count = function(buf) return 10 end,
        nvim_open_win = function(buf, enter, config) return 1 end,
        nvim_win_set_cursor = function(win, pos) end,
        nvim_buf_set_keymap = function(buf, mode, lhs, rhs, opts) end
    },
    fn = {
        input = function(prompt) 
            if prompt:find("Search query") then
                return "machine learning project"
            elseif prompt:find("Limit") then
                return "5"
            elseif prompt:find("Content type") then
                return "project"
            elseif prompt:find("Threshold") then
                return "0.3"
            elseif prompt:find("Include text filtering") then
                return "y"
            else
                return "test"
            end
        end,
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
    end
}

-- Replace global vim with mock
_G.vim = vim_mock

-- Test function for search integration
local function test_search_integration()
    print("Testing Neovim search integration...")
    
    -- Load the paragonic module
    local paragonic = require("paragonic")
    
    -- Test that search functions exist
    print("  Testing search function existence...")
    assert(type(paragonic.search_embeddings) == "function", "search_embeddings function should exist")
    assert(type(paragonic.find_similar_content) == "function", "find_similar_content function should exist")
    assert(type(paragonic.hybrid_search) == "function", "hybrid_search function should exist")
    assert(type(paragonic.search_command) == "function", "search_command function should exist")
    assert(type(paragonic.search_filtered_command) == "function", "search_filtered_command function should exist")
    assert(type(paragonic.search_hybrid_command) == "function", "search_hybrid_command function should exist")
    assert(type(paragonic.display_search_results) == "function", "display_search_results function should exist")
    print("  ✓ All search functions exist")
    
    -- Test search command with arguments
    print("  Testing search command with arguments...")
    paragonic.search_command({"machine", "learning"})
    print("  ✓ Search command with arguments works")
    
    -- Test search command without arguments (uses input)
    print("  Testing search command without arguments...")
    paragonic.search_command({})
    print("  ✓ Search command without arguments works")
    
    -- Test filtered search command
    print("  Testing filtered search command...")
    paragonic.search_filtered_command({"AI", "neural", "network"})
    print("  ✓ Filtered search command works")
    
    -- Test hybrid search command
    print("  Testing hybrid search command...")
    paragonic.search_hybrid_command({"artificial", "intelligence"})
    print("  ✓ Hybrid search command works")
    
    -- Test display search results function
    print("  Testing display search results...")
    local mock_results = {
        results = {
            {
                embedding = {
                    content_text = "Test project content",
                    content_type = "project"
                },
                similarity_score = 0.85
            },
            {
                embedding = {
                    content_text = "Test task content",
                    content_type = "task"
                },
                similarity_score = 0.72
            }
        }
    }
    paragonic.display_search_results(mock_results, "Test Search Results")
    print("  ✓ Display search results works")
    
    print("✓ All search integration tests passed!")
end

-- Test function for command creation
local function test_command_creation()
    print("Testing command creation...")
    
    -- Load the paragonic module
    local paragonic = require("paragonic")
    
    -- Test setup function
    print("  Testing setup function...")
    paragonic.setup()
    print("  ✓ Setup function works")
    
    print("✓ Command creation tests passed!")
end

-- Main test execution
print("=== Neovim Search Integration Test ===")
print("Testing search functionality integration into Neovim plugin...")

-- Run tests
test_command_creation()
test_search_integration()

print("\n=== Test Complete ===")
print("Note: These tests use mocked vim API calls.")
print("For real testing, run the commands in Neovim:")
print("  :ParagonicSearch <query>")
print("  :ParagonicSearchFiltered <query>")
print("  :ParagonicSearchHybrid <query>") 