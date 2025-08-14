--[[
Test for implementing chat_completion method in rpc_standalone.lua - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Test that chat_completion method exists
local function test_chat_completion_method_exists()
	print("Testing that chat_completion method exists...")

	-- Load the rpc_standalone module
	local rpc_standalone = require("paragonic.rpc_standalone")

	-- Create a new RPC client
	local client = rpc_standalone.new("127.0.0.1:2346")

	-- Test that chat_completion method exists
	assert(type(client.chat_completion) == "function", "chat_completion method should exist and be a function")

	print("✓ chat_completion method exists")
	return true
end

-- Test chat_completion method implementation
local function test_chat_completion_method_implementation()
	print("Testing chat_completion method implementation...")

	-- Load the rpc_standalone module
	local rpc_standalone = require("paragonic.rpc_standalone")

	-- Create a new RPC client
	local client = rpc_standalone.new("127.0.0.1:2346")

	-- Start the Rust backend server with database bypass
	local server_cmd = "./target/debug/paragonic --no-database > /dev/null 2>&1 & echo $!"
	local server_process = io.popen(server_cmd)
	if not server_process then
		error("Failed to start server process")
	end

	local pid = server_process:read("*a"):match("(%d+)")
	if not pid then
		error("Failed to get server process ID")
	end

	print("✓ Server started with PID: " .. pid)

	-- Wait for server to start
	os.execute("sleep 3")

	-- Connect to server
	local connect_result = client:connect()
	assert(connect_result == true, "Should connect successfully")

	-- Test that chat_completion method exists
	assert(type(client.chat_completion) == "function", "chat_completion should be a function")

	-- Test chat_completion with simple message
	print("Testing chat_completion with simple message...")
	local result = client:chat_completion("llama2", "Hello, what is 2+2?")

	assert(result ~= nil, "chat_completion should return a result")
	assert(type(result) == "string", "chat_completion should return a string")

	print("✓ chat_completion method works: " .. result:sub(1, 100))

	-- Test chat_completion with different model
	print("Testing chat_completion with different message...")
	local result2 = client:chat_completion("llama2", "What is the capital of France?")

	assert(result2 ~= nil, "Second chat_completion should return a result")
	assert(type(result2) == "string", "Second chat_completion should return a string")
	assert(result2 ~= result, "Different messages should return different results")

	print("✓ Second chat_completion method works: " .. result2:sub(1, 100))

	-- Test chat_completion without connection
	print("Testing chat_completion without connection...")
	client:disconnect()
	local result3 = client:chat_completion("llama2", "This should fail")

	assert(result3 == nil, "chat_completion should fail when not connected")

	print("✓ chat_completion correctly fails when not connected")

	-- Cleanup
	os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
	print("✓ Server cleanup completed")

	return true
end

-- Test chat_completion error handling
local function test_chat_completion_error_handling()
	print("Testing chat_completion error handling...")

	-- Load the rpc_standalone module
	local rpc_standalone = require("paragonic.rpc_standalone")

	-- Create a client with invalid server address
	local client = rpc_standalone.new("127.0.0.1:9999") -- Invalid port

	-- Test chat_completion with invalid server
	local result = client:chat_completion("llama2", "This should fail")

	-- Should handle the error gracefully
	assert(result == nil, "chat_completion should fail with invalid server")

	print("✓ chat_completion error handling works correctly")

	return true
end

-- Test chat_completion parameter validation
local function test_chat_completion_parameter_validation()
	print("Testing chat_completion parameter validation...")

	-- Load the rpc_standalone module
	local rpc_standalone = require("paragonic.rpc_standalone")

	-- Create a new RPC client
	local client = rpc_standalone.new("127.0.0.1:2346")

	-- Start the Rust backend server with database bypass
	local server_cmd = "./target/debug/paragonic --no-database > /dev/null 2>&1 & echo $!"
	local server_process = io.popen(server_cmd)
	if not server_process then
		error("Failed to start server process")
	end

	local pid = server_process:read("*a"):match("(%d+)")
	if not pid then
		error("Failed to get server process ID")
	end

	print("✓ Server started with PID: " .. pid)

	-- Wait for server to start
	os.execute("sleep 3")

	-- Connect to server
	local connect_result = client:connect()
	assert(connect_result == true, "Should connect successfully")

	-- Test with nil parameters
	local result1 = client:chat_completion(nil, "test message")
	assert(result1 == nil, "chat_completion should fail with nil model")

	local result2 = client:chat_completion("llama2", nil)
	assert(result2 == nil, "chat_completion should fail with nil message")

	-- Test with empty parameters
	local result3 = client:chat_completion("", "test message")
	assert(result3 == nil, "chat_completion should fail with empty model")

	local result4 = client:chat_completion("llama2", "")
	assert(result4 == nil, "chat_completion should fail with empty message")

	print("✓ chat_completion parameter validation works correctly")

	-- Cleanup
	os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
	print("✓ Server cleanup completed")

	return true
end

-- Run the tests
local success, err = pcall(function()
	test_chat_completion_method_exists()
	test_chat_completion_method_implementation()
	test_chat_completion_error_handling()
	test_chat_completion_parameter_validation()
end)

if not success then
	print("Test failed: " .. tostring(err))
	os.exit(1)
end

print("✓ All rpc_standalone chat_completion tests passed!")
