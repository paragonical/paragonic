-- Debug test for send_message response format
local file = io.open("/tmp/nvim_debug3.log", "w")
if file then
	file:write("Starting send_message debug test...\n")

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

			-- Test chat completion directly
			file:write("Testing chat completion directly...\n")
			local response = rpc_client:chat_completion("llama2", "Hello, this is a test message")
			file:write("Raw response: " .. tostring(response) .. "\n")

			-- Parse the response
			local parsed_response = paragonic.parse_json_response(response)
			file:write("Parsed response type: " .. type(parsed_response) .. "\n")
			file:write("Parsed response: " .. tostring(parsed_response) .. "\n")

			if parsed_response then
				file:write("Response keys:\n")
				for k, v in pairs(parsed_response) do
					file:write("  " .. k .. ": " .. type(v) .. " = " .. tostring(v) .. "\n")
				end

				if parsed_response.result then
					file:write("Result type: " .. type(parsed_response.result) .. "\n")
					file:write("Result value: " .. tostring(parsed_response.result) .. "\n")

					if type(parsed_response.result) == "string" then
						file:write("Result is a string, trying to parse it...\n")
						local inner_success, inner_result = pcall(vim.json.decode, parsed_response.result)
						if inner_success then
							file:write("✓ Inner result parsed: " .. tostring(inner_result) .. "\n")
							if inner_result.message and inner_result.message.content then
								file:write("✓ Message content: " .. inner_result.message.content .. "\n")
							else
								file:write("✗ No message content in inner result\n")
							end
						else
							file:write("✗ Failed to parse inner result: " .. tostring(inner_result) .. "\n")
						end
					end
				end
			end
		else
			file:write("RPC client not available\n")
		end
	else
		file:write("Failed to load plugin: " .. tostring(paragonic) .. "\n")
	end

	file:write("=== Send Message Debug Test Complete ===\n")
	file:close()
end
