--[[
Test for chat interface backend communication - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"

-- Test that chat interface can communicate with backend
local function test_chat_interface_backend_communication()
	print("Testing chat interface backend communication...")

	-- Load the paragonic module
	local paragonic = require("paragonic")

	-- Initialize backend to get RPC client
	local success = paragonic.backend.initialize_backend()
	assert(success, "Backend initialization should succeed")

	-- Get RPC client (should be available after initialization)
	local rpc_client = paragonic.backend._get_rpc_client()
	assert(rpc_client ~= nil, "Should have RPC client")
	assert(rpc_client:is_connected(), "RPC client should be connected")

	-- Test that we can make a call to the backend
	local response = rpc_client:hello()
	assert(response ~= nil, "Should get response from backend")
	assert(type(response) == "string", "Response should be string")

	print("✓ Chat interface backend communication test passed!")
end

-- Run the test
test_chat_interface_backend_communication()
