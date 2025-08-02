--[[
Test for RPC model management functions - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"

-- Test that model management functions work
local function test_rpc_model_management()
    print("Testing RPC model management functions...")
    
    -- Load the RPC module
    local rpc = require("paragonic.rpc")
    
    -- Create RPC client and connect
    local client = rpc.new("127.0.0.1:3000")
    client:connect()
    
    -- Should be connected
    assert(client:is_connected(), "Client should be connected")
    
    -- Test list_models
    local models_response = client:list_models()
    assert(models_response ~= nil, "Should return models response")
    assert(type(models_response) == "string", "Response should be string")
    assert(models_response:find('"jsonrpc"'), "Should contain jsonrpc field")
    
    -- Test model_info
    local info_response = client:model_info("llama2")
    assert(info_response ~= nil, "Should return model info response")
    assert(type(info_response) == "string", "Response should be string")
    assert(info_response:find('"jsonrpc"'), "Should contain jsonrpc field")
    
    print("✓ RPC model management functions test passed!")
end

-- Run the test
test_rpc_model_management() 