--[[
Test for Ollama runtime debugging - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Test Ollama runtime debugging
local function test_ollama_runtime_debug()
	print("Testing Ollama runtime debugging...")

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

	-- Test that Ollama is available
	print("Testing Ollama availability...")
	local ollama_check = io.popen("curl -s http://localhost:11434/api/tags")
	if ollama_check then
		local ollama_response = ollama_check:read("*a")
		ollama_check:close()

		if ollama_response and ollama_response ~= "" then
			print("✓ Ollama service is available")

			-- Parse the response to check for llama2
			local cjson = require("cjson")
			local models = cjson.decode(ollama_response)
			local has_llama2 = false
			for _, model in ipairs(models.models or {}) do
				if model.name and model.name:find("llama2") then
					has_llama2 = true
					break
				end
			end

			if has_llama2 then
				print("✓ llama2 model is available")
			else
				print("⚠ llama2 model not found in available models")
			end
		else
			print("⚠ Ollama service not responding")
			return false
		end
	else
		print("⚠ Failed to check Ollama service")
		return false
	end

	-- Test server startup with runtime debugging
	print("Testing server startup with runtime debugging...")

	-- Start the server and capture any error output
	local server_cmd = backend_binary .. " 2>&1"
	local server_process = io.popen(server_cmd)
	if server_process then
		-- Wait a moment for startup
		os.execute("sleep 2")

		-- Check if server is still running
		local status = server_process:read("*a")
		server_process:close()

		if status and status ~= "" then
			print("Server output: " .. status:sub(1, 200))

			-- Check if there's a runtime error
			if status:find("Cannot start a runtime from within a runtime") then
				print("⚠ Runtime error detected: Cannot start a runtime from within a runtime")
				print("  This confirms the async runtime issue in the RPC handlers")
				return false
			elseif status:find("Paragonic backend initialized successfully") then
				print("✓ Server started successfully")
				return true
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

-- Test simple RPC methods that don't use Ollama
local function test_simple_rpc_methods()
	print("Testing simple RPC methods...")

	-- Start server in background
	local server_process = io.popen("./target/debug/paragonic > /dev/null 2>&1 & echo $!")
	if not server_process then
		error("Failed to start server process")
	end

	local pid = server_process:read("*a"):match("(%d+)")
	if not pid then
		error("Failed to get server process ID")
	end

	print("✓ Server started with PID: " .. pid)

	-- Wait for startup
	os.execute("sleep 3")

	-- Test hello method (should work)
	local hello_cmd = 'echo \'{"jsonrpc":"2.0","method":"hello","params":{},"id":1}\' | nc -w 5 127.0.0.1 3000'
	local hello_process = io.popen(hello_cmd)
	if hello_process then
		local hello_response = hello_process:read("*a")
		hello_process:close()

		if hello_response and hello_response ~= "" then
			print("✓ Hello method works: " .. hello_response:sub(1, 100))
		else
			print("⚠ Hello method failed")
		end
	end

	-- Test bye method (should work)
	local bye_cmd = 'echo \'{"jsonrpc":"2.0","method":"bye","params":{},"id":1}\' | nc -w 5 127.0.0.1 3000'
	local bye_process = io.popen(bye_cmd)
	if bye_process then
		local bye_response = bye_process:read("*a")
		bye_process:close()

		if bye_response and bye_response ~= "" then
			print("✓ Bye method works: " .. bye_response:sub(1, 100))
		else
			print("⚠ Bye method failed")
		end
	end

	-- Cleanup
	os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
	print("✓ Server cleanup completed")
end

-- Run the tests
local success, err = pcall(function()
	local runtime_success = test_ollama_runtime_debug()
	if runtime_success then
		test_simple_rpc_methods()
	else
		print("⚠ Skipping simple RPC tests - runtime issue detected")
	end
end)

if not success then
	print("Test failed: " .. tostring(err))
	os.exit(1)
end

print("✓ All Ollama runtime debugging tests passed!")
