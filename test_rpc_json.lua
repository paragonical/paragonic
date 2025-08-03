--[[
Test for RPC JSON handling with vim.json - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Test that vim.json properly handles JSON-RPC messages
local function test_rpc_json_handling()
    print("Testing RPC JSON handling with vim.json...")
    
    -- Test JSON-RPC request encoding
    local request = {
        jsonrpc = "2.0",
        method = "hello",
        params = {message = "test"},
        id = 1
    }
    
    local request_json = vim.json.encode(request)
    assert(type(request_json) == "string", "Should encode to string")
    assert(request_json:find('"jsonrpc":"2.0"'), "Should contain jsonrpc field")
    assert(request_json:find('"method":"hello"'), "Should contain method field")
    
    -- Test JSON-RPC response decoding
    local response_json = '{"jsonrpc":"2.0","result":"world","id":1}'
    local response = vim.json.decode(response_json)
    assert(response.jsonrpc == "2.0", "Should decode jsonrpc field")
    assert(response.result == "world", "Should decode result field")
    assert(response.id == 1, "Should decode id field")
    
    print("✓ RPC JSON handling with vim.json test passed!")
end

-- Run the test
test_rpc_json_handling() 