--[[
Test for configuration interface integration with RPC backend - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"

-- Test that config interface can load configuration from backend
local function test_config_interface_load_config()
    print("Testing config interface load configuration...")
    
    -- Load the paragonic module
    local paragonic = require("paragonic")
    
    -- Get RPC client (should initialize backend)
    local rpc_client = paragonic._get_rpc_client()
    assert(rpc_client ~= nil, "Should have RPC client")
    assert(rpc_client:is_connected(), "RPC client should be connected")
    
    -- Test that we can get configuration
    local response = paragonic.get_config()
    assert(response ~= nil, "Should get response from get_config")
    assert(type(response) == "string", "Response should be string")
    assert(response:find('"jsonrpc"'), "Should contain jsonrpc field")
    
    print("✓ Config interface load configuration test passed!")
end

-- Test that config interface can save configuration changes
local function test_config_interface_save_config()
    print("Testing config interface save configuration...")
    
    -- Load the paragonic module
    local paragonic = require("paragonic")
    
    -- Get RPC client
    local rpc_client = paragonic._get_rpc_client()
    assert(rpc_client ~= nil, "Should have RPC client")
    
    -- Test that we can save configuration
    local test_config = {
        ollama_host = "127.0.0.1:11434",
        ollama_model = "llama2",
        database_path = "/tmp/test.db",
        log_level = "info"
    }
    
    local response = paragonic.save_config(test_config)
    assert(response ~= nil, "Should get response from save_config")
    assert(type(response) == "string", "Response should be string")
    assert(response:find('"jsonrpc"'), "Should contain jsonrpc field")
    
    print("✓ Config interface save configuration test passed!")
end

-- Run the tests
test_config_interface_load_config()
test_config_interface_save_config() 