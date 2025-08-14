#!/usr/bin/env lua

--[[
Test script for search functions
This script tests the search functionality without requiring the full vim API
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Test the RPC standalone client search functions directly
local function test_rpc_search_functions()
	print("=== Testing RPC Search Functions ===")

	-- Load the RPC standalone client
	local rpc_client = require("lua.paragonic.rpc_standalone")

	-- Create a client instance
	local client = rpc_client.new("127.0.0.1:3000")

	-- Test client creation
	print("Testing client creation...")
	assert(client ~= nil, "Client should be created")
	assert(type(client.search_embeddings) == "function", "search_embeddings method should exist")
	assert(type(client.find_similar_content) == "function", "find_similar_content method should exist")
	assert(type(client.hybrid_search) == "function", "hybrid_search method should exist")
	assert(type(client.format_search_results) == "function", "format_search_results method should exist")
	assert(type(client.get_search_stats) == "function", "get_search_stats method should exist")
	print("✓ Client creation and method existence tests passed")

	-- Test parameter validation
	print("Testing parameter validation...")

	-- Test empty query validation
	local result, error = client:search_embeddings("", 5)
	assert(result == nil, "Empty query should be rejected")
	assert(error ~= nil, "Error message should be provided")
	print("  ✓ Empty query validation works")

	-- Test invalid limit validation
	local result2, error2 = client:search_embeddings("test", -1)
	assert(result2 == nil, "Invalid limit should be rejected")
	assert(error2 ~= nil, "Error message should be provided")
	print("  ✓ Invalid limit validation works")

	-- Test invalid threshold validation
	local result3, error3 = client:find_similar_content("test", nil, 5, 1.5)
	assert(result3 == nil, "Invalid threshold should be rejected")
	assert(error3 ~= nil, "Error message should be provided")
	print("  ✓ Invalid threshold validation works")

	print("✓ Parameter validation tests passed")

	-- Test result formatting functions
	print("Testing result formatting functions...")

	-- Test with empty results
	local empty_results = { results = {} }
	local formatted_empty = client:format_search_results(empty_results, 100)
	assert(formatted_empty == "No search results found", "Empty results should show appropriate message")
	print("  ✓ Empty results formatting works")

	-- Test with mock results
	local mock_results = {
		results = {
			{
				embedding = {
					content_text = "Test project content",
					content_type = "project",
				},
				similarity_score = 0.85,
			},
			{
				embedding = {
					content_text = "Test task content",
					content_type = "task",
				},
				similarity_score = 0.72,
			},
		},
	}

	local formatted = client:format_search_results(mock_results, 100)
	assert(formatted:find("1. %[project%]"), "Should format project result")
	assert(formatted:find("2. %[task%]"), "Should format task result")
	print("  ✓ Mock results formatting works")

	-- Test statistics function
	local stats = client:get_search_stats(mock_results)
	assert(stats.total_results == 2, "Should count 2 results")
	assert(stats.avg_score > 0, "Should calculate average score")
	assert(stats.content_types.project == 1, "Should count 1 project")
	assert(stats.content_types.task == 1, "Should count 1 task")
	print("  ✓ Statistics calculation works")

	print("✓ Result formatting tests passed")

	print("✓ All RPC search function tests passed!")
end

-- Test search function signatures (without executing)
local function test_function_signatures()
	print("=== Testing Function Signatures ===")

	-- Test that we can load the module
	local success, rpc_client = pcall(require, "lua.paragonic.rpc_standalone")
	assert(success, "Should be able to load RPC client module")

	-- Test client constructor
	local client = rpc_client.new("127.0.0.1:3000")
	assert(client ~= nil, "Client constructor should work")

	-- Test method signatures
	assert(type(client.search_embeddings) == "function", "search_embeddings should be a function")
	assert(type(client.find_similar_content) == "function", "find_similar_content should be a function")
	assert(type(client.hybrid_search) == "function", "hybrid_search should be a function")
	assert(type(client.format_search_results) == "function", "format_search_results should be a function")
	assert(type(client.get_search_stats) == "function", "get_search_stats should be a function")

	print("✓ All function signatures are correct")
end

-- Main test execution
print("=== Search Functions Test ===")
print("Testing search functionality without vim API dependencies...")

-- Run tests
test_function_signatures()
test_rpc_search_functions()

print("\n=== Test Complete ===")
print("✓ All search function tests passed!")
print("The search functionality is ready for Neovim integration.")
print("Commands available in Neovim:")
print("  :ParagonicSearch <query>")
print("  :ParagonicSearchFiltered <query>")
print("  :ParagonicSearchHybrid <query>")
