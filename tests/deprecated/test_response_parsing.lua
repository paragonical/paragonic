package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

print("=== Response Parsing Test ===")

-- Test the response that was successfully written by the external script
local response_json = '{"jsonrpc":"2.0","result":"world","id":1}'
print("📝 Testing response JSON:", response_json)

-- Try to parse with vim.json.decode
local success, response = pcall(vim.json.decode, response_json)
if success then
	print("✅ vim.json.decode successful:")
	print("Response type:", type(response))
	print("Response result:", response.result)
	print("Response id:", response.id)
else
	print("❌ vim.json.decode failed:", response)
end

-- Try to parse with cjson
local cjson_ok, cjson = pcall(require, "cjson")
if cjson_ok then
	local success2, response2 = pcall(cjson.decode, response_json)
	if success2 then
		print("✅ cjson.decode successful:")
		print("Response type:", type(response2))
		print("Response result:", response2.result)
		print("Response id:", response2.id)
	else
		print("❌ cjson.decode failed:", response2)
	end
else
	print("❌ cjson not available")
end

print("=== Response parsing test completed ===")
