--[[
Test for JSON response parsing functionality - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"

-- Test that JSON parsing can decode RPC responses
local function test_json_parsing_decode_rpc_responses()
	print("Testing JSON parsing decode RPC responses...")

	-- Load the paragonic module
	local paragonic = require("paragonic")

	-- Test parsing chat completion response
	local chat_response =
		'{"jsonrpc":"2.0","result":{"message":{"role":"assistant","content":"Hello! How can I help you today?"}},"id":1}'
	local parsed_chat = paragonic.utils.parse_json_response(chat_response)
	assert(parsed_chat ~= nil, "Should parse chat response")
	assert(parsed_chat.result ~= nil, "Should have result field")
	assert(parsed_chat.result.message ~= nil, "Should have message field")
	assert(parsed_chat.result.message.content ~= nil, "Should have content field")

	-- Test parsing models list response
	local models_response =
		'{"jsonrpc":"2.0","result":{"models":[{"name":"llama2","size":"3.8GB"},{"name":"mistral","size":"4.1GB"}]},"id":1}'
	local parsed_models = paragonic.utils.parse_json_response(models_response)
	assert(parsed_models ~= nil, "Should parse models response")
	assert(parsed_models.result ~= nil, "Should have result field")
	assert(parsed_models.result.models ~= nil, "Should have models field")
	assert(#parsed_models.result.models == 2, "Should have 2 models")

	-- Test parsing projects list response
	local projects_response =
		'{"jsonrpc":"2.0","result":{"projects":[{"id":"1","name":"Test Project","description":"A test project"}]},"id":1}'
	local parsed_projects = paragonic.utils.parse_json_response(projects_response)
	assert(parsed_projects ~= nil, "Should parse projects response")
	assert(parsed_projects.result ~= nil, "Should have result field")
	assert(parsed_projects.result.projects ~= nil, "Should have projects field")
	assert(#parsed_projects.result.projects == 1, "Should have 1 project")

	print("✓ JSON parsing decode RPC responses test passed!")
end

-- Test that JSON parsing handles errors gracefully
local function test_json_parsing_error_handling()
	print("Testing JSON parsing error handling...")

	-- Load the paragonic module
	local paragonic = require("paragonic")

	-- Test parsing invalid JSON
	local invalid_json = '{"jsonrpc":"2.0","error":{"code":-32601,"message":"Method not found"},"id":1}'
	local parsed_error = paragonic.utils.parse_json_response(invalid_json)
	assert(parsed_error ~= nil, "Should parse error response")
	assert(parsed_error.error ~= nil, "Should have error field")
	assert(parsed_error.error.code ~= nil, "Should have error code")
	assert(parsed_error.error.message ~= nil, "Should have error message")

	-- Test parsing malformed JSON
	local malformed_json = '{"jsonrpc":"2.0","result":'
	local parsed_malformed = paragonic.utils.parse_json_response(malformed_json)
	assert(parsed_malformed == nil, "Should return nil for malformed JSON")

	print("✓ JSON parsing error handling test passed!")
end

-- Run the tests
test_json_parsing_decode_rpc_responses()
test_json_parsing_error_handling()
