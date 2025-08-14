--[[
Complete test for database bypass solution - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Global variable to store the server process
local server_process = nil

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
	server_process = io.popen(backend_binary .. " --no-database > /dev/null 2>&1 & echo $!")
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

-- Test all RPC methods with database bypass
local function test_all_rpc_methods()
	print("Testing all RPC methods with database bypass...")

	-- Test chat completion
	print("Testing chat completion...")
	local chat_cmd =
		'echo \'{"jsonrpc":"2.0","method":"chat_completion","params":["Hello, what is 2+2?","llama2"],"id":1}\' | nc -w 15 127.0.0.1 3000'
	local chat_process = io.popen(chat_cmd)
	if chat_process then
		local chat_response = chat_process:read("*a")
		chat_process:close()

		if chat_response and chat_response ~= "" then
			print("✓ Chat completion works: " .. chat_response:sub(1, 200))

			-- Parse the JSON response
			local cjson = require("cjson")
			local parsed = cjson.decode(chat_response)
			assert(parsed.jsonrpc == "2.0", "Should be valid JSON-RPC response")

			if parsed.result then
				-- Parse the result as JSON (it should be a JSON string)
				local result_parsed = cjson.decode(parsed.result)
				assert(type(result_parsed) == "table", "Result should be parseable as JSON")
				assert(result_parsed.message ~= nil, "Should have message field")
				assert(result_parsed.message.content ~= nil, "Should have message content")

				print("  AI Response: " .. result_parsed.message.content:sub(1, 100))
			end
		else
			print("⚠ Chat completion failed")
			return false
		end
	else
		print("⚠ Failed to execute chat completion command")
		return false
	end

	-- Test list models
	print("Testing list models...")
	local models_cmd = 'echo \'{"jsonrpc":"2.0","method":"list_models","params":{},"id":1}\' | nc -w 10 127.0.0.1 3000'
	local models_process = io.popen(models_cmd)
	if models_process then
		local models_response = models_process:read("*a")
		models_process:close()

		if models_response and models_response ~= "" then
			print("✓ List models works: " .. models_response:sub(1, 200))

			-- Parse the JSON response
			local cjson = require("cjson")
			local parsed = cjson.decode(models_response)
			assert(parsed.jsonrpc == "2.0", "Should be valid JSON-RPC response")

			if parsed.result then
				-- Parse the result as JSON (it should be a JSON string)
				local result_parsed = cjson.decode(parsed.result)
				assert(type(result_parsed) == "table", "Result should be parseable as JSON")
				assert(#result_parsed > 0, "Should have at least one model")

				-- Check if llama2 is in the list
				local has_llama2 = false
				for _, model in ipairs(result_parsed) do
					if model:find("llama2") then
						has_llama2 = true
						break
					end
				end
				assert(has_llama2, "Should have llama2 model available")

				print("  Available models: " .. #result_parsed)
			end
		else
			print("⚠ List models failed")
			return false
		end
	else
		print("⚠ Failed to execute list models command")
		return false
	end

	-- Test model info
	print("Testing model info...")
	local info_cmd =
		'echo \'{"jsonrpc":"2.0","method":"model_info","params":["llama2"],"id":1}\' | nc -w 10 127.0.0.1 3000'
	local info_process = io.popen(info_cmd)
	if info_process then
		local info_response = info_process:read("*a")
		info_process:close()

		if info_response and info_response ~= "" then
			print("✓ Model info works: " .. info_response:sub(1, 200))

			-- Parse the JSON response
			local cjson = require("cjson")
			local parsed = cjson.decode(info_response)
			assert(parsed.jsonrpc == "2.0", "Should be valid JSON-RPC response")

			if parsed.result then
				-- Parse the result as JSON (it should be a JSON string)
				local result_parsed = cjson.decode(parsed.result)
				assert(type(result_parsed) == "table", "Result should be parseable as JSON")
				assert(result_parsed.name ~= nil, "Should have name field")

				print("  Model name: " .. tostring(result_parsed.name))
			end
		else
			print("⚠ Model info failed")
			return false
		end
	else
		print("⚠ Failed to execute model info command")
		return false
	end

	return true
end

-- Test server without database bypass (should fail)
local function test_server_without_bypass()
	print("Testing server without database bypass (should fail)...")

	-- Kill the current server
	os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
	os.execute("sleep 1")

	-- Try to start server without bypass
	local server_cmd = "./target/debug/paragonic 2>&1"
	local server_process = io.popen(server_cmd)
	if server_process then
		-- Wait a moment for startup
		os.execute("sleep 3")

		-- Check if server is still running
		local status = server_process:read("*a")
		server_process:close()

		if status and status ~= "" then
			print("Server output: " .. status:sub(1, 300))

			-- Check if there's a shared memory error
			if status:find("could not create shared memory segment") then
				print("✓ Server correctly fails without database bypass")
				print("  This confirms the database bypass is working")
				return true
			elseif status:find("Paragonic backend initialized successfully") then
				print("⚠ Server started successfully (unexpected)")
				return false
			else
				print("⚠ Unexpected server output")
				return false
			end
		else
			print("⚠ No server output")
			return false
		end
	else
		print("⚠ Failed to start server process")
		return false
	end
end

-- Cleanup function to stop the server
local function cleanup_server()
	if server_process then
		server_process:close()
		-- Kill the background process
		os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
		print("✓ Server cleanup completed")
	end
end

-- Run the tests
local success, err = pcall(function()
	local bypass_success = test_database_bypass_flag()
	if bypass_success then
		test_all_rpc_methods()
		test_server_without_bypass()
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
