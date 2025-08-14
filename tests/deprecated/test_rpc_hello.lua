--[[
Test for RPC hello() function - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"

-- Test that hello() sends JSON-RPC request to server
local function test_rpc_hello_sends_jsonrpc_request()
	print("Testing RPC hello() sends JSON-RPC request...")

	-- Load the RPC module
	local rpc = require("paragonic.rpc")

	-- Create RPC client and connect
	local client = rpc.new("127.0.0.1:3000")
	client:connect()

	-- Should be connected before calling hello
	assert(client:is_connected(), "Client should be connected")
	assert(client.socket ~= nil, "Socket should exist")

	-- Call hello method
	local response = client:hello()

	-- Should return a JSON-RPC response, not just "world"
	assert(response ~= "world", "Should not return mock response")
	assert(type(response) == "string", "Response should be a string")

	print("✓ RPC hello() sends JSON-RPC request test passed!")
end

-- Run the test
test_rpc_hello_sends_jsonrpc_request()
