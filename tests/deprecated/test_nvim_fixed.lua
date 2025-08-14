-- Test the fixed RPC client in Neovim
local file = io.open("/tmp/nvim_fixed.log", "w")
if file then
	file:write("Testing fixed RPC client in Neovim...\n")

	-- Add lua directory to package path
	package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
	file:write("Package path updated\n")

	-- Load the plugin
	local success, paragonic = pcall(require, "paragonic")
	if success then
		file:write("Plugin loaded successfully\n")

		-- Setup the plugin
		paragonic.setup()
		file:write("Plugin setup completed\n")

		-- Get RPC client directly
		local rpc_client = paragonic._get_rpc_client()
		if rpc_client then
			file:write("RPC client available\n")
			file:write("RPC client connected: " .. tostring(rpc_client:is_connected()) .. "\n")

			-- Test hello method
			file:write("Testing hello method...\n")
			local hello_response = rpc_client:hello()
			file:write("Hello response: " .. tostring(hello_response) .. "\n")

			-- Test chat completion
			file:write("Testing chat completion...\n")
			local chat_response = rpc_client:chat_completion("llama2", "Hello, this is a test message")
			file:write("Chat response: " .. tostring(chat_response) .. "\n")

			-- Check if responses are different
			if hello_response == chat_response then
				file:write("⚠️ WARNING: Hello and chat responses are the same!\n")
				file:write("This indicates the RPC client is using mock responses.\n")
			else
				file:write("✓ Hello and chat responses are different.\n")
			end

			-- Test send_message function
			file:write("Testing send_message function...\n")
			local result, err = paragonic.send_message("Hello, this is a test message")
			file:write("Send message result: " .. tostring(result) .. "\n")
			file:write("Send message error: " .. tostring(err) .. "\n")

			if result then
				file:write("✓ Chat functionality is working!\n")
			else
				file:write("✗ Chat functionality failed: " .. tostring(err) .. "\n")
			end
		else
			file:write("RPC client not available\n")
		end
	else
		file:write("Failed to load plugin: " .. tostring(paragonic) .. "\n")
	end

	file:write("=== Fixed RPC Client Test Complete ===\n")
	file:close()
end
