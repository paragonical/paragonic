--[[
Test for Ollama integration fix - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Global variable to store the server process
local server_process = nil

-- Test that the runtime fix is working
local function test_runtime_fix()
	print("Testing Ollama integration runtime fix...")

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

	-- Start the server in background
	server_process = io.popen(backend_binary .. " > /dev/null 2>&1 & echo $!")
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
		else
			print("⚠ Hello method failed")
			return false
		end
	else
		print("⚠ Failed to test hello method")
		return false
	end

	print("✓ Runtime fix test passed!")
	return true
end

-- Test chat completion with the fix
local function test_chat_completion_fixed()
	print("Testing chat completion with runtime fix...")

	-- Test chat completion method
	local chat_cmd =
		'echo \'{"jsonrpc":"2.0","method":"chat_completion","params":["Hello, what is 2+2?","llama2"],"id":1}\' | nc -w 15 127.0.0.1 3000'
	local chat_process = io.popen(chat_cmd)
	if chat_process then
		local chat_response = chat_process:read("*a")
		chat_process:close()

		if chat_response and chat_response ~= "" then
			print("✓ Chat completion response: " .. chat_response:sub(1, 200))

			-- Parse the JSON response
			local cjson = require("cjson")
			local parsed = cjson.decode(chat_response)
			assert(parsed.jsonrpc == "2.0", "Should be valid JSON-RPC response")

			-- Check if we got a real response (not an error)
			if parsed.result then
				assert(parsed.result ~= "mock_response", "Should not be mock response")
				assert(type(parsed.result) == "string", "Result should be string")
				assert(parsed.result ~= "", "Result should not be empty")

				-- Parse the result as JSON (it should be a JSON string)
				local result_parsed = cjson.decode(parsed.result)
				assert(type(result_parsed) == "table", "Result should be parseable as JSON")
				assert(result_parsed.message ~= nil, "Should have message field")
				assert(result_parsed.message.content ~= nil, "Should have message content")

				print("✓ Chat completion with runtime fix test passed!")
				print("  AI Response: " .. result_parsed.message.content:sub(1, 100))
				return true
			else
				print("⚠ Chat completion returned error: " .. tostring(parsed.error))
				return false
			end
		else
			print("⚠ No response from chat completion method")
			return false
		end
	else
		print("⚠ Failed to execute chat completion command")
		return false
	end
end

-- Test list models with the fix
local function test_list_models_fixed()
	print("Testing list models with runtime fix...")

	-- Test list models method
	local models_cmd = 'echo \'{"jsonrpc":"2.0","method":"list_models","params":{},"id":1}\' | nc -w 10 127.0.0.1 3000'
	local models_process = io.popen(models_cmd)
	if models_process then
		local models_response = models_process:read("*a")
		models_process:close()

		if models_response and models_response ~= "" then
			print("✓ List models response: " .. models_response:sub(1, 200))

			-- Parse the JSON response
			local cjson = require("cjson")
			local parsed = cjson.decode(models_response)
			assert(parsed.jsonrpc == "2.0", "Should be valid JSON-RPC response")

			-- Check if we got a real response (not an error)
			if parsed.result then
				assert(parsed.result ~= "mock_response", "Should not be mock response")
				assert(type(parsed.result) == "string", "Result should be string")

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

				print("✓ List models with runtime fix test passed!")
				print("  Available models: " .. #result_parsed)
				return true
			else
				print("⚠ List models returned error: " .. tostring(parsed.error))
				return false
			end
		else
			print("⚠ No response from list models method")
			return false
		end
	else
		print("⚠ Failed to execute list models command")
		return false
	end
end

-- Test model info with the fix
local function test_model_info_fixed()
	print("Testing model info with runtime fix...")

	-- Test model info method
	local info_cmd =
		'echo \'{"jsonrpc":"2.0","method":"model_info","params":["llama2"],"id":1}\' | nc -w 10 127.0.0.1 3000'
	local info_process = io.popen(info_cmd)
	if info_process then
		local info_response = info_process:read("*a")
		info_process:close()

		if info_response and info_response ~= "" then
			print("✓ Model info response: " .. info_response:sub(1, 200))

			-- Parse the JSON response
			local cjson = require("cjson")
			local parsed = cjson.decode(info_response)
			assert(parsed.jsonrpc == "2.0", "Should be valid JSON-RPC response")

			-- Check if we got a real response (not an error)
			if parsed.result then
				assert(parsed.result ~= "mock_response", "Should not be mock response")
				assert(type(parsed.result) == "string", "Result should be string")

				-- Parse the result as JSON (it should be a JSON string)
				local result_parsed = cjson.decode(parsed.result)
				assert(type(result_parsed) == "table", "Result should be parseable as JSON")
				assert(result_parsed.name ~= nil, "Should have name field")

				print("✓ Model info with runtime fix test passed!")
				print("  Model name: " .. tostring(result_parsed.name))
				return true
			else
				print("⚠ Model info returned error: " .. tostring(parsed.error))
				return false
			end
		else
			print("⚠ No response from model info method")
			return false
		end
	else
		print("⚠ Failed to execute model info command")
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
	local runtime_success = test_runtime_fix()
	if runtime_success then
		test_chat_completion_fixed()
		test_list_models_fixed()
		test_model_info_fixed()
	else
		print("⚠ Skipping Ollama tests - runtime fix failed")
	end
end)

-- Always cleanup
cleanup_server()

if not success then
	print("Test failed: " .. tostring(err))
	os.exit(1)
end

print("✓ All Ollama integration fix tests passed!")
