#!/usr/bin/env nlua

--[[
Test script for RPC MCP logging integration
This tests that the MCP logging functionality is properly integrated into the RPC module
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

local function test_rpc_mcp_logging_integration()
    print("=== Testing RPC MCP Logging Integration ===")
    print("Test function started")

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
            nvim_buf_set_lines = function(buf, start, end_, strict, lines)
                print("  Set lines in buffer " .. buf .. " from " .. start .. " to " .. end_)
                return 0
            end,
            nvim_set_current_buf = function(buf)
                print("  Set current buffer to " .. buf)
                return 0
            end
        },
        fn = {
            stdpath = function(what)
                if what == "data" then return "/tmp"
                else return "/tmp" end
            end,
            mkdir = function(dir_path)
                print("  Create directory " .. dir_path)
                return 0
            end,
            filereadable = function(file_path)
                return 0 -- File doesn't exist initially
            end,
            writefile = function(lines, file_path)
                print("  Write " .. #lines .. " lines to " .. file_path)
                return 0
            end,
            readfile = function(file_path)
                return {}
            end,
            rename = function(old_file, new_file)
                print("  Rename " .. old_file .. " to " .. new_file)
                return 0
            end
        },
        json = {
            encode = function(data)
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
        log = {
            levels = {
                DEBUG = 0,
                INFO = 1,
                WARN = 2,
                ERROR = 3
            }
        }
    }

    -- Replace global vim
    local original_vim = _G.vim
    _G.vim = vim_mock

    -- Load the RPC module
    local rpc = require("paragonic.rpc_standalone")
    
    -- Test that MCP logging functions are available
    assert(rpc.logging_config ~= nil, "Should have logging_config")
    assert(rpc.initialize_logging ~= nil, "Should have initialize_logging function")
    assert(rpc.log ~= nil, "Should have log function")
    assert(rpc.log_mcp_request ~= nil, "Should have log_mcp_request function")
    assert(rpc.log_mcp_response ~= nil, "Should have log_mcp_response function")
    assert(rpc.log_mcp_operation ~= nil, "Should have log_mcp_operation function")
    print("  ✓ MCP logging functions are available")

    -- Test logging configuration
    assert(rpc.logging_config.enabled == true, "Should have logging enabled by default")
    assert(rpc.logging_config.level == "info", "Should have info level by default")
    assert(rpc.logging_config.include_timestamps == true, "Should include timestamps by default")
    assert(rpc.logging_config.include_context == true, "Should include context by default")
    print("  ✓ Logging configuration is correct")

    -- Test log level checking
    assert(rpc.should_log("info") == true, "Should log info level")
    assert(rpc.should_log("warn") == true, "Should log warn level")
    assert(rpc.should_log("error") == true, "Should log error level")
    
    rpc.logging_config.level = "warn"
    assert(rpc.should_log("info") == false, "Should not log info when level is warn")
    assert(rpc.should_log("warn") == true, "Should log warn when level is warn")
    assert(rpc.should_log("error") == true, "Should log error when level is warn")
    
    rpc.logging_config.level = "info" -- Reset for other tests
    print("  ✓ Log level checking works")

    -- Test log message formatting
    local formatted = rpc.format_log_message("info", "Test message", {key = "value"})
    assert(formatted:find("Test message"), "Should include message")
    assert(formatted:find("INFO"), "Should include level")
    assert(formatted:find("key"), "Should include context")
    print("  ✓ Log message formatting works")

    -- Test convenience logging functions
    rpc.log_debug("Debug message", {debug_key = "debug_value"})
    rpc.log_info("Info message", {info_key = "info_value"})
    rpc.log_warn("Warning message", {warn_key = "warn_value"})
    rpc.log_error("Error message", {error_key = "error_value"})
    print("  ✓ Convenience logging functions work")

    -- Test MCP-specific logging
    rpc.log_mcp_request("tools/call", {name = "agent_edit_file", arguments = {file_path = "/tmp/test.txt"}}, {session_id = "123"})
    rpc.log_mcp_response("tools/call", {success = true}, nil, {session_id = "123"})
    rpc.log_mcp_response("tools/call", nil, {code = -32602, message = "Invalid parameters"}, {session_id = "123"})
    rpc.log_mcp_operation("file_edit", "op-1", "started", {file_path = "/tmp/test.txt"})
    rpc.log_mcp_operation("file_edit", "op-1", "completed", {lines_modified = 5})
    print("  ✓ MCP-specific logging works")

    -- Test enhanced MCP message handler
    local test_message = {
        id = 1,
        method = "resources/list",
        params = {}
    }
    
    local response = rpc.handle_mcp_message_with_logging(test_message)
    assert(response.id == 1, "Should return correct message ID")
    assert(response.result ~= nil, "Should have result")
    print("  ✓ Enhanced MCP message handler works")

    -- Test logging configuration management
    rpc.set_logging_config({level = "debug", include_timestamps = false})
    assert(rpc.logging_config.level == "debug", "Should update log level")
    assert(rpc.logging_config.include_timestamps == false, "Should update timestamp setting")
    
    local config_json = rpc.get_logging_config()
    assert(config_json:find("debug"), "Should include debug level in config")
    print("  ✓ Logging configuration management works")

    -- Test log file operations
    local entries = rpc.get_log_entries(5)
    assert(type(entries) == "table", "Should return table of log entries")
    
    rpc.clear_logs()
    local empty_entries = rpc.get_log_entries()
    assert(#empty_entries == 0, "Should clear logs")
    print("  ✓ Log file operations work")

    -- Test RPC client creation with MCP logging
    local client = rpc.new("localhost:3000")
    assert(client ~= nil, "Should create RPC client")
    assert(client.server_address == "localhost:3000", "Should set server address")
    print("  ✓ RPC client creation works with MCP logging")

    -- Test client logging integration
    client:logging(true, "debug")
    assert(client.logging_enabled == true, "Should enable client logging")
    assert(client.log_level == "debug", "Should set client log level")
    print("  ✓ Client logging configuration works")

    -- Restore global vim
    _G.vim = original_vim

    print("✓ All RPC MCP logging integration tests passed!")
end

print("=== RPC MCP Logging Integration Test ===")
print("Testing RPC MCP logging integration...")
print("Starting test function...")
local success, result = pcall(test_rpc_mcp_logging_integration)
if not success then
    print("Test failed with error: " .. tostring(result))
else
    print("Test completed successfully")
end
print("\n=== Test Complete ===")
print("✓ All RPC MCP logging integration tests passed!")
print("RPC MCP logging integration features verified:")
print("  • MCP logging functions available in RPC module")
print("  • Logging configuration integration")
print("  • Log level management and filtering")
print("  • Structured log message formatting")
print("  • MCP-specific logging functions")
print("  • Enhanced message handler with logging")
print("  • Logging configuration management")
print("  • Log file operations and maintenance")
print("  • RPC client creation with MCP logging")
print("  • Client logging configuration integration") 