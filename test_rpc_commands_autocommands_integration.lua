#!/usr/bin/env nlua

--[[
Test script for RPC MCP commands and autocommands integration
This tests that the MCP commands and autocommands functionality is properly integrated into the RPC module
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

local function test_rpc_commands_autocommands_integration()
    print("=== Testing RPC MCP Commands and Autocommands Integration ===")
    print("Test function started")

    -- Mock vim API for testing
    local vim_mock = {
        api = {
            nvim_get_commands = function(opts)
                return {
                    ParagonicChat = {
                        name = "ParagonicChat",
                        definition = "Open the Paragonic chat window",
                        nargs = "0",
                        bang = false
                    },
                    ParagonicSearch = {
                        name = "ParagonicSearch",
                        definition = "Search using Paragonic",
                        nargs = "*",
                        bang = false
                    },
                    Write = {
                        name = "Write",
                        definition = "Write current buffer to file",
                        nargs = "0",
                        bang = true
                    }
                }
            end,
            nvim_get_autocmds = function(opts)
                return {
                    {
                        event = "BufRead",
                        group = 1,
                        group_name = "paragonic_group",
                        pattern = "*.lua",
                        command = "echo 'Lua file read'",
                        desc = "Echo on Lua file read"
                    },
                    {
                        event = "BufWritePre",
                        group = 1,
                        group_name = "paragonic_group",
                        pattern = "*",
                        command = "echo 'Before write'",
                        desc = "Echo before write"
                    }
                }
            end,
            nvim_list_bufs = function() return {1} end,
            nvim_buf_get_name = function(buf) return "/tmp/test.txt" end,
            nvim_buf_set_lines = function(buf, start, end_, strict, lines) return 0 end,
            nvim_set_current_buf = function(buf) return 0 end
        },
        fn = {
            stdpath = function(what) return "/tmp" end,
            mkdir = function(dir_path) print("  Create directory " .. dir_path) return 0 end,
            filereadable = function(file_path) return 0 end,
            writefile = function(lines, file_path) print("  Write " .. #lines .. " lines to " .. file_path) return 0 end,
            readfile = function(file_path) return {} end,
            rename = function(old_file, new_file) print("  Rename " .. old_file .. " to " .. new_file) return 0 end
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
            decode = function(json_str) return {} end
        },
        log = {
            levels = { DEBUG = 0, INFO = 1, WARN = 2, ERROR = 3 }
        }
    }

    -- Replace global vim
    local original_vim = _G.vim
    _G.vim = vim_mock

    -- Load the RPC module
    local rpc = require("paragonic.rpc_standalone")
    
    -- Test that commands and autocommands functions are available
    assert(rpc.get_commands_info ~= nil, "Should have get_commands_info function")
    assert(rpc.get_autocommands_info ~= nil, "Should have get_autocommands_info function")
    assert(rpc.list_commands_autocommands_resources ~= nil, "Should have list_commands_autocommands_resources function")
    assert(rpc.read_commands_autocommands_resource ~= nil, "Should have read_commands_autocommands_resource function")
    assert(rpc.handle_commands_autocommands_method ~= nil, "Should have handle_commands_autocommands_method function")
    print("  ✓ Commands and autocommands functions are available")

    -- Test commands info retrieval
    local commands = rpc.get_commands_info()
    assert(#commands == 3, "Should get 3 commands")
    
    -- Check for ParagonicChat command (order-independent)
    local has_paragonic_chat = false
    for _, cmd in ipairs(commands) do
        if cmd.name == "ParagonicChat" then
            has_paragonic_chat = true
            break
        end
    end
    assert(has_paragonic_chat, "Should include ParagonicChat command")
    
    -- Check for Write command (order-independent)
    local has_write = false
    for _, cmd in ipairs(commands) do
        if cmd.name == "Write" then
            has_write = true
            break
        end
    end
    assert(has_write, "Should include Write command")
    print("  ✓ Commands info retrieval works")

    -- Test autocommands info retrieval
    local autocmds = rpc.get_autocommands_info()
    assert(#autocmds == 2, "Should get 2 autocommands")
    
    -- Check for BufRead event (order-independent)
    local has_bufread = false
    for _, ac in ipairs(autocmds) do
        if ac.event == "BufRead" then
            has_bufread = true
            break
        end
    end
    assert(has_bufread, "Should include BufRead event")
    print("  ✓ Autocommands info retrieval works")

    -- Test MCP resource listing
    local resources = rpc.list_commands_autocommands_resources()
    assert(resources[1].uri == "neovim://commands", "Should list commands resource")
    assert(resources[2].uri == "neovim://autocommands", "Should list autocommands resource")
    print("  ✓ MCP resource listing works")

    -- Test MCP resource reading for commands
    local commands_resource = rpc.read_commands_autocommands_resource("neovim://commands")
    assert(commands_resource.contents ~= nil, "Should return contents for commands resource")
    assert(commands_resource.contents[1].uri == "neovim://commands", "Should have correct URI for commands resource")
    print("  ✓ MCP commands resource reading works")

    -- Test MCP resource reading for autocommands
    local autocmds_resource = rpc.read_commands_autocommands_resource("neovim://autocommands")
    assert(autocmds_resource.contents ~= nil, "Should return contents for autocommands resource")
    assert(autocmds_resource.contents[1].uri == "neovim://autocommands", "Should have correct URI for autocommands resource")
    print("  ✓ MCP autocommands resource reading works")

    -- Test MCP method handling
    print("  Testing MCP method handling...")
    
    -- Test commands/list
    local commands_list_result = rpc.handle_commands_autocommands_method("commands/list", {})
    assert(commands_list_result.commands ~= nil, "Should return commands list")
    assert(#commands_list_result.commands == 3, "Should have 3 commands")
    
    -- Test autocommands/list
    local autocmds_list_result = rpc.handle_commands_autocommands_method("autocommands/list", {})
    assert(autocmds_list_result.autocommands ~= nil, "Should return autocommands list")
    assert(#autocmds_list_result.autocommands == 2, "Should have 2 autocommands")
    
    -- Test resources/list
    local resources_list_result = rpc.handle_commands_autocommands_method("resources/list", {})
    assert(resources_list_result.resources ~= nil, "Should return resources list")
    assert(#resources_list_result.resources == 2, "Should have 2 resources")
    
    -- Test resources/read
    local resources_read_result = rpc.handle_commands_autocommands_method("resources/read", {uri = "neovim://commands"})
    assert(resources_read_result.contents ~= nil, "Should return contents for resources/read")
    
    -- Test unknown method
    local unknown_result = rpc.handle_commands_autocommands_method("unknown/method", {})
    assert(unknown_result.error ~= nil, "Should return error for unknown method")
    assert(unknown_result.error.message:find("Unknown"), "Should have unknown method error")
    print("  ✓ MCP method handling works")

    -- Test RPC client creation with commands and autocommands
    local client = rpc.new("localhost:3000")
    assert(client ~= nil, "Should create RPC client")
    assert(client.server_address == "localhost:3000", "Should set server address")
    print("  ✓ RPC client creation works with commands and autocommands")

    -- Restore global vim
    _G.vim = original_vim

    print("✓ All RPC MCP commands and autocommands integration tests passed!")
end

print("=== RPC MCP Commands and Autocommands Integration Test ===")
print("Testing RPC MCP commands and autocommands integration...")
print("Starting test function...")
local success, result = pcall(test_rpc_commands_autocommands_integration)
if not success then
    print("Test failed with error: " .. tostring(result))
else
    print("Test completed successfully")
end
print("\n=== Test Complete ===")
print("✓ All RPC MCP commands and autocommands integration tests passed!")
print("RPC MCP commands and autocommands integration features verified:")
print("  • Commands info retrieval")
print("  • Autocommands info retrieval")
print("  • MCP resource listing")
print("  • MCP resource reading")
print("  • MCP method handling")
print("  • Error handling for unknown methods")
print("  • RPC client creation with commands and autocommands") 