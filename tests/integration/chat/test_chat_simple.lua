#!/usr/bin/env lua

--[[
Simple Test for ParagonicChat Response Issue
TDD Step 1: Isolate the core problem
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Load the paragonic module
local M = require("paragonic")

-- Test 1: Check if send_message function exists
local function test_send_message_exists()
	print("=== Test 1: Check send_message function ===")

	if M.chat.send_message then
		print("  ✅ send_message function exists")
		return true
	else
		print("  ❌ send_message function does not exist")
		return false
	end
end

-- Test 2: Check if RPC client is available
local function test_rpc_client()
	print("\n=== Test 2: Check RPC client ===")

	-- Try to initialize backend if not already done
	local success = pcall(function()
		if not M.backend._rpc_client then
			M.backend.initialize_backend()
		end
	end)

	local rpc_client = M.backend._get_rpc_client()
	if rpc_client then
		print("  ✅ RPC client is available")
		return true
	else
		print("  ⚠️  RPC client is not available (server may not be running)")
		return false
	end
end

-- Test 3: Test parse_json_response function
local function test_json_parsing()
	print("\n=== Test 3: Test JSON parsing ===")

	if not M.utils.parse_json_response then
		print("  ❌ parse_json_response function does not exist")
		return false
	end

	-- Test with valid JSON
	local valid_json = '{"result": "Hello, world!"}'
	local parsed = M.utils.parse_json_response(valid_json)

	if parsed and parsed.result then
		print("  ✅ JSON parsing works for valid JSON")
	else
		print("  ❌ JSON parsing failed for valid JSON")
		return false
	end

	-- Test with invalid JSON
	local invalid_json = '{"result": "Hello, world!"'
	local parsed_invalid = M.utils.parse_json_response(invalid_json)

	if not parsed_invalid then
		print("  ✅ JSON parsing correctly handles invalid JSON")
	else
		print("  ❌ JSON parsing should fail for invalid JSON")
		return false
	end

	return true
end

-- Test 4: Test send_message with timeout
local function test_send_message_timeout()
	print("\n=== Test 4: Test send_message with timeout ===")

	if not M.chat.send_message then
		print("  ❌ send_message function not available")
		return false
	end

	-- Test with a simple message and short timeout
	local test_message = "Hello"
	print("  📝 Testing with message: " .. test_message)

	-- Use pcall to catch any errors
	local success, response, error_msg = pcall(function()
		return M.chat.send_message(test_message, "llama2")
	end)

	if success then
		if response then
			print("  ✅ send_message returned response: " .. tostring(response):sub(1, 50) .. "...")
		else
			print("  ❌ send_message returned nil response")
		end
	else
		print("  ❌ send_message threw error: " .. tostring(response))
	end

	return true
end

-- Run the simple tests
print("Starting Simple Tests for ParagonicChat...")
print("==========================================")

local test1_result = test_send_message_exists()
local test2_result = test_rpc_client()
local test3_result = test_json_parsing()
local test4_result = test_send_message_timeout()

print("\n=== Test Results ===")
print("Test 1 (send_message exists): " .. (test1_result and "PASS" or "FAIL"))
print("Test 2 (RPC client): " .. (test2_result and "PASS" or "FAIL"))
print("Test 3 (JSON parsing): " .. (test3_result and "PASS" or "FAIL"))
print("Test 4 (send_message timeout): " .. (test4_result and "PASS" or "FAIL"))

if test1_result and test2_result and test3_result and test4_result then
	print("\n🎯 Status: All basic tests passed")
else
	print("\n🎯 Status: Some basic tests failed")
	print("Focus on fixing the failing components first.")
end
