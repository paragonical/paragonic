--[[
Test JSON parsing in Neovim environment
--]]

-- Test JSON parsing with the real response format
local test_json =
	'{"jsonrpc":"2.0","result":"{\\"model\\":\\"llama2\\",\\"message\\":{\\"role\\":\\"assistant\\",\\"content\\":\\"Hello!\\"}}","id":1}'

print("Testing JSON parsing in Neovim...")
print("Test JSON:", test_json)

-- Parse the outer JSON
local success, result = pcall(vim.json.decode, test_json)
if success then
	print("✓ Outer JSON parsed successfully")
	print("Result type:", type(result.result))
	print("Result value:", result.result)

	-- Parse the inner JSON string
	if type(result.result) == "string" then
		local inner_success, inner_result = pcall(vim.json.decode, result.result)
		if inner_success then
			print("✓ Inner JSON parsed successfully")
			print("Inner result:", inner_result)
			if inner_result.message and inner_result.message.content then
				print("✓ Message content:", inner_result.message.content)
			else
				print("✗ No message content in inner result")
			end
		else
			print("✗ Failed to parse inner JSON:", inner_result)
		end
	end
else
	print("✗ Failed to parse outer JSON:", result)
end

print("=== Neovim JSON Test Complete ===")
