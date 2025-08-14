--[[
Test for RPC chat_completion() function - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"

-- Test that chat_completion() sends JSON-RPC request to server
local function test_rpc_chat_completion_sends_request()
	print("Testing RPC chat_completion() sends request...")

	-- Load the RPC module
	local rpc = require("paragonic.rpc")

	-- Create RPC client and connect
	local client = rpc.new("127.0.0.1:3000")
	client:connect()

	-- Should be connected before calling chat_completion
	assert(client:is_connected(), "Client should be connected")

	-- Call chat_completion method with test parameters
	local response = client:chat_completion("llama2", "Hello, how are you?")

	-- Should return a JSON-RPC response
	assert(response ~= nil, "Should return a response")
	assert(type(response) == "string", "Response should be a string")

	-- Should contain JSON-RPC structure
	assert(response:find('"jsonrpc"'), "Should contain jsonrpc field")
	assert(response:find('"result"'), "Should contain result field")

	print("✓ RPC chat_completion() sends request test passed!")
end

-- Run the test
test_rpc_chat_completion_sends_request()
