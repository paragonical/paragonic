--[[
Test using real JSON parsing modules
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Try to load real JSON modules
local cjson_ok, cjson = pcall(require, "cjson")
local dkjson_ok, dkjson = pcall(require, "dkjson")

print("cjson available:", cjson_ok)
print("dkjson available:", dkjson_ok)

-- Use the first available JSON module
local json_decode
if cjson_ok then
	json_decode = cjson.decode
	print("Using cjson for JSON parsing")
elseif dkjson_ok then
	json_decode = dkjson.decode
	print("Using dkjson for JSON parsing")
else
	print("No JSON parsing module available!")
	os.exit(1)
end

-- Test JSON parsing
local test_json =
	'{"jsonrpc":"2.0","result":"{\\"model\\":\\"llama2\\",\\"message\\":{\\"role\\":\\"assistant\\",\\"content\\":\\"Hello!\\"}}","id":1}'
print("Testing JSON parsing with:", test_json)

local success, result = pcall(json_decode, test_json)
if success then
	print("✓ JSON parsed successfully")
	print("Result type:", type(result.result))
	print("Result value:", result.result)

	-- Parse the inner JSON string
	if type(result.result) == "string" then
		local inner_success, inner_result = pcall(json_decode, result.result)
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
	print("✗ Failed to parse JSON:", result)
end

print("=== Real JSON Test Complete ===")
