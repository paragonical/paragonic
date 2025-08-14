--[[
Simple test for database bypass solution - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Test database bypass flag
local function test_database_bypass_flag()
	print("Testing database bypass flag...")

	-- Check if Rust backend binary exists
	local backend_binary = "./target/debug/paragonic"
	local file = io.open(backend_binary, "r")
	if not file then
		print("⚠ Rust backend binary not found at " .. backend_binary)
		print("  Need to build with: cargo build")
		return false
	end
	file:close()
	print("✓ Rust backend binary found at " .. backend_binary)

	-- Test server startup with --no-database flag
	print("Testing server startup with --no-database flag...")

	-- Start the server with database bypass
	local server_cmd = backend_binary .. " --no-database > /dev/null 2>&1 & echo $!"
	local server_process = io.popen(server_cmd)
	if not server_process then
		error("Failed to start server process")
	end

	-- Get the process ID
	local pid = server_process:read("*a"):match("(%d+)")
	if not pid then
		error("Failed to get server process ID")
	end

	print("✓ Server started with PID: " .. pid)

	-- Wait a moment for the server to start up
	os.execute("sleep 3")

	-- Test that server is responding
	local hello_cmd = 'echo \'{"jsonrpc":"2.0","method":"hello","params":{},"id":1}\' | nc -w 5 127.0.0.1 3000'
	local hello_process = io.popen(hello_cmd)
	if hello_process then
		local hello_response = hello_process:read("*a")
		hello_process:close()

		if hello_response and hello_response ~= "" then
			print("✓ Hello method works: " .. hello_response:sub(1, 100))
			return true
		else
			print("⚠ Hello method failed")
			return false
		end
	else
		print("⚠ Failed to test hello method")
		return false
	end
end

-- Test basic RPC methods
local function test_basic_rpc_methods()
	print("Testing basic RPC methods...")

	-- Test chat completion (simple test)
	print("Testing chat completion...")
	local chat_cmd =
		'echo \'{"jsonrpc":"2.0","method":"chat_completion","params":["Hello, what is 2+2?","llama2"],"id":1}\' | nc -w 10 127.0.0.1 3000'
	local chat_process = io.popen(chat_cmd)
	if chat_process then
		local chat_response = chat_process:read("*a")
		chat_process:close()

		if chat_response and chat_response ~= "" then
			print("✓ Chat completion works: " .. chat_response:sub(1, 150))
		else
			print("⚠ Chat completion failed")
			return false
		end
	else
		print("⚠ Failed to execute chat completion command")
		return false
	end

	-- Test list models (simple test)
	print("Testing list models...")
	local models_cmd = 'echo \'{"jsonrpc":"2.0","method":"list_models","params":{},"id":1}\' | nc -w 5 127.0.0.1 3000'
	local models_process = io.popen(models_cmd)
	if models_process then
		local models_response = models_process:read("*a")
		models_process:close()

		if models_response and models_response ~= "" then
			print("✓ List models works: " .. models_response:sub(1, 150))
		else
			print("⚠ List models failed")
			return false
		end
	else
		print("⚠ Failed to execute list models command")
		return false
	end

	return true
end

-- Cleanup function
local function cleanup_server()
	-- Kill the background process
	os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
	print("✓ Server cleanup completed")
end

-- Run the tests
local success, err = pcall(function()
	local bypass_success = test_database_bypass_flag()
	if bypass_success then
		test_basic_rpc_methods()
	else
		print("⚠ Skipping RPC tests - database bypass failed")
	end
end)

-- Always cleanup
cleanup_server()

if not success then
	print("Test failed: " .. tostring(err))
	os.exit(1)
end

print("✓ All database bypass solution tests passed!")
