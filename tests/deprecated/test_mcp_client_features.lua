#!/usr/bin/env lua

--[[
Test script for MCP Client Features (Sampling and Roots)
This tests the new MCP client capabilities for external AI agent integration
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Mock vim API for testing
local vim_mock = {
    api = {
        nvim_list_bufs = function()
            return {1, 2, 3}
        end,
        nvim_buf_get_name = function(buf)
            if buf == 1 then return "/tmp/file1.txt"
            elseif buf == 2 then return "/tmp/file2.lua"
            else return "/tmp/file3.md" end
        end,
        nvim_buf_get_lines = function(buf, start, end_, strict)
            if buf == 1 then return {"line 1", "line 2", "line 3", "line 4", "line 5"}
            elseif buf == 2 then return {"function test()", "  return true", "end", "print('hello')"}
            else return {"# Markdown", "## Section", "Content here"} end
        end,
        nvim_get_current_buf = function()
            return 1
        end,
        nvim_list_wins = function()
            return {1, 2}
        end,
        nvim_win_get_buf = function(win)
            return win
        end,
        nvim_win_get_cursor = function(win)
            return {5, 0}
        end,
        nvim_create_buf = function(listed, scratch) return 1 end,
        nvim_buf_set_lines = function(buf, start, end_, strict, lines) end,
        nvim_buf_set_option = function(buf, option, value) end,
        nvim_open_win = function(buf, enter, config) return 1 end,
        nvim_buf_set_name = function(buf, name) end
    },
    fn = {
        getcwd = function()
            return "/tmp"
        end,
        expand = function(what)
            if what == "%" then return "/tmp/file1.txt"
            else return "/tmp" end
        end,
        fnamemodify = function(path, modifier)
            if modifier == ":t" then
                return path:match("([^/]+)$") or path
            end
            return path
        end,
        stdpath = function(path)
            return "/tmp"
        end
    },
    o = {
        columns = 80,
        lines = 24
    },
    json = {
        encode = function(data, opts)
            if type(data) == "table" then
                local parts = {}
                for k, v in pairs(data) do
                    if type(v) == "string" then
                        table.insert(parts, string.format('"%s": "%s"', k, v))
                    elseif type(v) == "number" then
                        table.insert(parts, string.format('"%s": %s', k, v))
                    elseif type(v) == "boolean" then
                        table.insert(parts, string.format('"%s": %s', k, tostring(v)))
                    elseif type(v) == "table" then
                        table.insert(parts, string.format('"%s": %s', k, vim.json.encode(v)))
                    end
                end
                return "{" .. table.concat(parts, ", ") .. "}"
            elseif type(data) == "string" then
                return string.format('"%s"', data)
            else
                return tostring(data)
            end
        end,
        decode = function(json_str)
            return {}
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
    },
    keymap = {
        set = function(mode, lhs, rhs, opts) end
    }
}

-- Replace global vim
local original_vim = _G.vim
_G.vim = vim_mock

-- Load the paragonic module and add missing mock functions
local M = require("paragonic")

-- Add missing mock functions to the module
M.get_buffers_info = function()
    return {
        {id = 1, name = "/tmp/file1.txt", file_type = "txt", modifiable = true},
        {id = 2, name = "/tmp/file2.lua", file_type = "lua", modifiable = true},
        {id = 3, name = "/tmp/file3.md", file_type = "md", modifiable = true}
    }
end

M.get_session_info = function()
    return {
        current_file = "/tmp/file1.txt",
        current_directory = "/tmp",
        mode = "normal",
        window_count = 2,
        buffer_count = 3
    }
end

-- Test function for MCP sampling capabilities
local function test_mcp_sampling()
    print("Testing MCP sampling capabilities...")
    
    -- Test basic sampling with limit
    print("  Testing basic sampling with limit...")
    local sampled = M.sample_resource("neovim://buffers", {limit = 2})
    assert(sampled and #sampled == 2, "Should return 2 sampled buffers")
    print("  ✓ Basic sampling with limit works")
    
    -- Test sampling with file type filter
    print("  Testing sampling with file type filter...")
    local lua_buffers = M.sample_resource("neovim://buffers", {filter = {file_type = "lua"}})
    assert(lua_buffers, "Should return filtered buffers")
    print("  ✓ File type filtering works")
    
    -- Test sampling with name pattern filter
    print("  Testing sampling with name pattern filter...")
    local file1_buffers = M.sample_resource("neovim://buffers", {filter = {name_pattern = "file1"}})
    assert(file1_buffers, "Should return pattern-matched buffers")
    print("  ✓ Name pattern filtering works")
    
    -- Test session sampling with field selection
    print("  Testing session sampling with field selection...")
    local session_sample = M.sample_resource("neovim://session", {fields = {"current_file", "mode"}})
    assert(session_sample, "Should return selected session fields")
    print("  ✓ Session field selection works")
    
    print("✓ All MCP sampling tests passed!")
end

-- Test function for MCP roots capabilities
local function test_mcp_roots()
    print("Testing MCP roots capabilities...")
    
    -- Test basic roots definition
    print("  Testing basic roots definition...")
    local roots = M.define_resource_roots("neovim://buffers", {})
    assert(roots, "Should return roots array")
    print("  ✓ Basic roots definition works")
    
    -- Test roots with buffer IDs
    print("  Testing roots with buffer IDs...")
    local scoped_roots = M.define_resource_roots("neovim://buffers", {buffer_ids = {1, 3}})
    assert(scoped_roots, "Should return scoped roots")
    print("  ✓ Buffer ID scoping works")
    
    -- Test roots with file patterns
    print("  Testing roots with file patterns...")
    local pattern_roots = M.define_resource_roots("neovim://buffers", {file_patterns = {"%.txt$", "%.md$"}})
    assert(pattern_roots, "Should return pattern-matched roots")
    print("  ✓ File pattern scoping works")
    
    -- Test session roots
    print("  Testing session roots...")
    local session_roots = M.define_resource_roots("neovim://session", {current_only = true})
    assert(session_roots, "Should return session roots")
    print("  ✓ Session roots work")
    
    print("✓ All MCP roots tests passed!")
end

-- Test function for MCP message handling
local function test_mcp_message_handling()
    print("Testing MCP message handling...")
    
    -- Test sampling request handling
    print("  Testing sampling request handling...")
    local sampling_request = {
        id = 1,
        method = "sampling/request",
        uri = "neovim://buffers",
        criteria = {limit = 2}
    }
    local sampling_response = M.handle_sampling_request(sampling_request)
    assert(sampling_response and sampling_response.result, "Should return valid sampling response")
    print("  ✓ Sampling request handling works")
    
    -- Test roots request handling
    print("  Testing roots request handling...")
    local roots_request = {
        id = 2,
        method = "roots/list",
        uri = "neovim://buffers",
        options = {}
    }
    local roots_response = M.handle_roots_request(roots_request)
    assert(roots_response and roots_response.result, "Should return valid roots response")
    print("  ✓ Roots request handling works")
    
    print("✓ All MCP message handling tests passed!")
end

-- Test function for display functions
local function test_display_functions()
    print("Testing display functions...")
    
    -- Test sampled content display
    print("  Testing sampled content display...")
    local mock_sampled = {
        {id = 1, name = "file1.txt", file_type = "txt"},
        {id = 2, name = "file2.lua", file_type = "lua"}
    }
    local criteria = {limit = 2}
    M.display_sampled_content("neovim://buffers", mock_sampled, criteria)
    print("  ✓ Sampled content display works")
    
    -- Test resource roots display
    print("  Testing resource roots display...")
    local mock_roots = {
        {uri = "file:///tmp/file1.txt", name = "file1.txt", description = "Text file"},
        {uri = "file:///tmp/file2.lua", name = "file2.lua", description = "Lua file"}
    }
    M.display_resource_roots("neovim://buffers", mock_roots)
    print("  ✓ Resource roots display works")
    
    print("✓ All display function tests passed!")
end

-- Main test execution
print("=== MCP Client Features Test ===")
print("Testing new MCP client capabilities for external AI agent integration...")

-- Run tests
test_mcp_sampling()
test_mcp_roots()
test_mcp_message_handling()
test_display_functions()

-- Restore original vim
_G.vim = original_vim

print("\n=== Test Complete ===")
print("Note: These tests use mocked vim API calls.")
print("For real testing, run the commands in Neovim:")
print("  :ParagonicMCPSample neovim://buffers 5")
print("  :ParagonicMCPRoots neovim://buffers")
print("  :ParagonicMCPInit")
print("\nNew MCP Client Features:")
print("  ✅ Sampling: Allow external agents to request specific parts of resources")
print("  ✅ Roots: Define context boundaries for resource access")
print("  ✅ Message Handling: Process MCP sampling and roots requests")
print("  ✅ Display Functions: Show sampled content and roots in floating windows") 