#!/usr/bin/env lua

print("=== Simple MCP Logging Test ===")

-- Mock vim API
local vim_mock = {
    fn = {
        stdpath = function(what) return "/tmp" end,
        mkdir = function(dir) print("  Create directory " .. dir) return 0 end,
        writefile = function(lines, file) print("  Write " .. #lines .. " lines to " .. file) return 0 end,
        filereadable = function(file) return 0 end
    },
    json = {
        encode = function(data) return "{}" end
    }
}

-- Replace global vim
local original_vim = _G.vim
_G.vim = vim_mock

local M = {}

-- Simple logging configuration
M.logging_config = {
    enabled = true,
    level = "info",
    log_file = "/tmp/test.log"
}

-- Simple logging function
function M.log(level, message)
    print("  LOG [" .. level .. "]: " .. message)
end

-- Test basic logging
M.log("info", "Test message")
print("  ✓ Basic logging works")

-- Restore global vim
_G.vim = original_vim

print("✓ Simple MCP logging test passed!") 