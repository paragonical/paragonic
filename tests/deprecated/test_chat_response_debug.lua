#!/usr/bin/env lua

--[[
Debug Test for Chat Response Format
TDD Step 2: Understand the response format issue
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Load the paragonic module
local M = require("paragonic")

-- Test 1: Debug RPC response format
local function test_rpc_response_format()
	print("=== Test 1: Debug RPC Response Format ===")

	local rpc_client = M._get_rpc_client()
	if not rpc_client then
		print("  ❌ RPC client not available")
		return false
	end

	print("  📝 Testing chat completion with simple message...")

	-- Test with a simple message
	local test_message = "Say hello"
	local response = rpc_client:chat_completion("llama2", test_message)

	if not response then
		print("  ❌ No response from RPC client")
		return false
	end

	print("  📋 Raw response type: " .. type(response))
	print("  📋 Raw response: " .. tostring(response):sub(1, 200) .. "...")

	-- Try to parse the response
	local parsed_response = M.parse_json_response(response)

	if not parsed_response then
		print("  ❌ Failed to parse JSON response")
		return false
	end

	print("  📋 Parsed response type: " .. type(parsed_response))
	print("  📋 Parsed response keys:")
	for key, value in pairs(parsed_response) do
		print("    - " .. key .. ": " .. type(value) .. " = " .. tostring(value):sub(1, 50))
	end

	-- Check specific response structure
	if parsed_response.result then
		print("  📋 Result type: " .. type(parsed_response.result))
		if type(parsed_response.result) == "string" then
			print("  📋 Result string: " .. parsed_response.result:sub(1, 100) .. "...")
		elseif type(parsed_response.result) == "table" then
			print("  📋 Result table keys:")
			for key, value in pairs(parsed_response.result) do
				print("    - " .. key .. ": " .. type(value))
			end
		end
	end

	if parsed_response.message then
		print("  📋 Message type: " .. type(parsed_response.message))
		if type(parsed_response.message) == "table" then
			print("  📋 Message keys:")
			for key, value in pairs(parsed_response.message) do
				print("    - " .. key .. ": " .. type(value))
			end
		end
	end

	return true
end

-- Test 2: Test response extraction logic
local function test_response_extraction()
	print("\n=== Test 2: Test Response Extraction Logic ===")

	-- Test different response formats
	local test_cases = {
		{
			name = "JSON-RPC with string result",
			response = '{"result": "{\\"message\\":{\\"content\\":\\"Hello from AI\\"}}"}',
			expected = "Hello from AI",
		},
		{
			name = "JSON-RPC with table result",
			response = '{"result": {"message": {"content": "Hello from AI"}}}',
			expected = "Hello from AI",
		},
		{
			name = "Direct Ollama response",
			response = '{"message": {"content": "Hello from AI"}}',
			expected = "Hello from AI",
		},
		{
			name = "Direct content",
			response = '{"content": "Hello from AI"}',
			expected = "Hello from AI",
		},
	}

	for i, test_case in ipairs(test_cases) do
		print("  📝 Testing: " .. test_case.name)

		local parsed = M.parse_json_response(test_case.response)
		if not parsed then
			print("    ❌ Failed to parse test response")
			return false
		end

		-- Simulate the extraction logic from send_message
		local extracted_content = nil

		if parsed.result then
			if type(parsed.result) == "string" then
				-- Try vim.json.decode
				local success, inner_result = pcall(vim.json.decode, parsed.result)
				if success and inner_result and inner_result.message then
					extracted_content = inner_result.message.content
				end
			elseif type(parsed.result) == "table" and parsed.result.message then
				extracted_content = parsed.result.message.content
			elseif type(parsed.result) == "table" and parsed.result.content then
				extracted_content = parsed.result.content
			end
		end

		if not extracted_content and parsed.message then
			extracted_content = parsed.message.content
		end

		if not extracted_content and parsed.content then
			extracted_content = parsed.content
		end

		if extracted_content == test_case.expected then
			print("    ✅ Correctly extracted: " .. extracted_content)
		else
			print("    ❌ Failed to extract content. Got: " .. tostring(extracted_content))
			return false
		end
	end

	return true
end

-- Test 3: Test actual send_message with debug
local function test_send_message_debug()
	print("\n=== Test 3: Test send_message with Debug ===")

	local test_message = "Say hello"
	print("  📝 Testing send_message with: " .. test_message)

	-- Call send_message and capture the result
	local response, error_msg = M.send_message(test_message, "llama2")

	if response then
		print("  ✅ send_message succeeded: " .. response:sub(1, 100) .. "...")
		return true
	else
		print("  ❌ send_message failed: " .. tostring(error_msg))

		-- Try to get more debug info
		local rpc_client = M._get_rpc_client()
		if rpc_client then
			local raw_response = rpc_client:chat_completion("llama2", test_message)
			if raw_response then
				print("  📋 Raw RPC response: " .. tostring(raw_response):sub(1, 200) .. "...")
			end
		end

		return false
	end
end

-- Run the debug tests
print("Starting Debug Tests for Chat Response...")
print("=========================================")

local test1_result = test_rpc_response_format()
local test2_result = test_response_extraction()
local test3_result = test_send_message_debug()

print("\n=== Debug Test Results ===")
print("Test 1 (RPC Response Format): " .. (test1_result and "PASS" or "FAIL"))
print("Test 2 (Response Extraction): " .. (test2_result and "PASS" or "FAIL"))
print("Test 3 (send_message Debug): " .. (test3_result and "PASS" or "FAIL"))

if test1_result and test2_result and test3_result then
	print("\n🎯 Status: All debug tests passed")
	print("The issue might be resolved or we have more information.")
else
	print("\n🎯 Status: Debug tests revealed issues")
	print("Check the output above for specific problems.")
end
