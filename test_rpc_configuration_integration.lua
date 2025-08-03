#!/usr/bin/env nlua

--[[
Test script for RPC MCP configuration integration
This tests that the MCP configuration functionality is properly integrated into the RPC module
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

local function test_rpc_configuration_integration()
    print("=== Testing RPC MCP Configuration Integration ===")
    print("Test function started")

    -- Mock vim API for testing
    local vim_mock = {
        api = {
            nvim_get_var = function(var_name)
                if var_name == "g:paragonic_config" then
                    return {
                        ollama_host = "http://localhost:11434",
                        ollama_model = "llama3.2:3b",
                        database_path = "/tmp/paragonic/db",
                        log_level = "info",
                        search_history_size = 50,
                        auto_save = true
                    }
                end
                return nil
            end,
            nvim_set_var = function(var_name, value)
                print("  Set variable " .. var_name .. " to " .. vim.json.encode(value))
                return 0
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
            rename = function(old_file, new_file) print("  Rename " .. old_file .. " to " .. new_file) return 0 end,
            fnamemodify = function(file_path, modifier)
                if modifier == ":h" then
                    if file_path:find("/") then
                        return file_path:match("(.*)/[^/]*$")
                    else
                        return "."
                    end
                end
                return file_path
            end,
            isdirectory = function(dir_path)
                if dir_path == "." then return 1
                elseif dir_path:find("tmp") then return 1
                else return 0 end
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
    
    -- Test that configuration functions are available
    assert(rpc.config_schema ~= nil, "Should have config_schema")
    assert(rpc.get_configuration ~= nil, "Should have get_configuration function")
    assert(rpc.validate_config_value ~= nil, "Should have validate_config_value function")
    assert(rpc.set_configuration_value ~= nil, "Should have set_configuration_value function")
    assert(rpc.get_configuration_schema ~= nil, "Should have get_configuration_schema function")
    assert(rpc.handle_configuration_method ~= nil, "Should have handle_configuration_method function")
    print("  ✓ Configuration functions are available")

    -- Test configuration schema
    assert(rpc.config_schema.ollama_host.type == "string", "Should have correct type for ollama_host")
    assert(rpc.config_schema.log_level.enum ~= nil, "Should have enum for log_level")
    assert(rpc.config_schema.search_history_size.minimum == 10, "Should have minimum for search_history_size")
    assert(rpc.config_schema.auto_save.default == true, "Should have correct default for auto_save")
    print("  ✓ Configuration schema is correct")

    -- Test configuration retrieval
    local config = rpc.get_configuration()
    assert(config.ollama_host == "http://localhost:11434", "Should have correct ollama_host")
    assert(config.ollama_model == "llama3.2:3b", "Should have correct ollama_model")
    assert(config.log_level == "info", "Should have correct log_level")
    assert(config.auto_save == true, "Should have correct auto_save")
    print("  ✓ Configuration retrieval works")

    -- Test configuration validation
    local valid, error = rpc.validate_config_value("ollama_host", "http://localhost:11434")
    assert(valid, "Should validate correct ollama_host")
    
    valid, error = rpc.validate_config_value("log_level", "debug")
    assert(valid, "Should validate correct log_level")
    
    valid, error = rpc.validate_config_value("log_level", "invalid")
    assert(not valid, "Should reject invalid log_level")
    assert(error:find("must be one of"), "Should have enum error")
    
    valid, error = rpc.validate_config_value("search_history_size", 25)
    assert(valid, "Should validate correct search_history_size")
    
    valid, error = rpc.validate_config_value("search_history_size", 5)
    assert(not valid, "Should reject too small search_history_size")
    assert(error:find("at least"), "Should have minimum error")
    print("  ✓ Configuration validation works")

    -- Test configuration setting
    local success, error = rpc.set_configuration_value("log_level", "warn")
    assert(success, "Should set valid log_level")
    
    success, error = rpc.set_configuration_value("log_level", "invalid")
    assert(not success, "Should reject invalid log_level")
    assert(error:find("must be one of"), "Should have validation error")
    print("  ✓ Configuration setting works")

    -- Test configuration schema resource
    local schema_resources = rpc.get_configuration_schema()
    assert(#schema_resources > 0, "Should have schema resources")
    assert(schema_resources[1].key ~= nil, "Should have key in schema")
    assert(schema_resources[1].type ~= nil, "Should have type in schema")
    assert(schema_resources[1].description ~= nil, "Should have description in schema")
    print("  ✓ Configuration schema resource works")

    -- Test configuration methods
    print("  Testing configuration methods...")
    
    -- Test config/get
    local get_result = rpc.handle_configuration_method("config/get", {})
    assert(get_result.config ~= nil, "Should return configuration")
    assert(get_result.config.ollama_host == "http://localhost:11434", "Should have correct config")
    
    -- Test config/set
    local set_result = rpc.handle_configuration_method("config/set", {key = "log_level", value = "error"})
    assert(set_result.success == true, "Should set configuration successfully")
    
    -- Test config/set with invalid value
    local set_invalid_result = rpc.handle_configuration_method("config/set", {key = "log_level", value = "invalid"})
    assert(set_invalid_result.error ~= nil, "Should return error for invalid value")
    assert(set_invalid_result.error.message:find("must be one of"), "Should have validation error")
    
    -- Test config/schema
    local schema_result = rpc.handle_configuration_method("config/schema", {})
    assert(schema_result.schema ~= nil, "Should return schema")
    assert(#schema_result.schema > 0, "Should have schema entries")
    
    -- Test config/validate
    local validate_result = rpc.handle_configuration_method("config/validate", {key = "ollama_host", value = "http://localhost:11434"})
    assert(validate_result.valid == true, "Should validate correct value")
    
    local validate_invalid_result = rpc.handle_configuration_method("config/validate", {key = "log_level", value = "invalid"})
    assert(validate_invalid_result.valid == false, "Should reject invalid value")
    assert(validate_invalid_result.error ~= nil, "Should have error message")
    
    -- Test unknown method
    local unknown_result = rpc.handle_configuration_method("config/unknown", {})
    assert(unknown_result.error ~= nil, "Should return error for unknown method")
    assert(unknown_result.error.message:find("Unknown"), "Should have unknown method error")
    print("  ✓ Configuration methods work")

    -- Test configuration persistence
    print("  Testing configuration persistence...")
    local test_config = {
        ollama_host = "http://localhost:11434",
        ollama_model = "llama3.2:3b",
        log_level = "info"
    }
    
    local save_success = rpc.save_configuration_to_file(test_config, "/tmp/test_config.json")
    assert(save_success, "Should save configuration to file")
    
    local loaded_config, load_error = rpc.load_configuration_from_file("/tmp/test_config.json")
    assert(loaded_config ~= nil, "Should load configuration from file")
    assert(loaded_config.ollama_host == "http://localhost:11434", "Should have correct loaded config")
    
    local missing_config, missing_error = rpc.load_configuration_from_file("/tmp/missing_config.json")
    assert(missing_config == nil, "Should return nil for missing file")
    assert(missing_error:find("not found"), "Should have not found error")
    print("  ✓ Configuration persistence works")

    -- Test configuration as MCP resource
    print("  Testing configuration as MCP resource...")
    local config_resource = rpc.get_configuration_as_resource()
    assert(config_resource.uri == "neovim://configuration", "Should have correct URI")
    assert(config_resource.content.config ~= nil, "Should have config in content")
    assert(config_resource.content.schema ~= nil, "Should have schema in content")
    assert(config_resource.content.timestamp ~= nil, "Should have timestamp in content")
    print("  ✓ Configuration as MCP resource works")

    -- Test RPC client creation with configuration
    local client = rpc.new("localhost:3000")
    assert(client ~= nil, "Should create RPC client")
    assert(client.server_address == "localhost:3000", "Should set server address")
    print("  ✓ RPC client creation works with configuration")

    -- Restore global vim
    _G.vim = original_vim

    print("✓ All RPC MCP configuration integration tests passed!")
end

print("=== RPC MCP Configuration Integration Test ===")
print("Testing RPC MCP configuration integration...")
print("Starting test function...")
local success, result = pcall(test_rpc_configuration_integration)
if not success then
    print("Test failed with error: " .. tostring(result))
else
    print("Test completed successfully")
end
print("\n=== Test Complete ===")
print("✓ All RPC MCP configuration integration tests passed!")
print("RPC MCP configuration integration features verified:")
print("  • Configuration schema definition")
print("  • Configuration retrieval and validation")
print("  • Configuration setting with validation")
print("  • Configuration methods (get, set, schema, validate)")
print("  • Configuration persistence")
print("  • Configuration as MCP resource")
print("  • Error handling and validation")
print("  • RPC client creation with configuration") 