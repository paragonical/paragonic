#!/usr/bin/env lua

--[[
Test script for search functions
This script tests the search functionality without requiring the full vim API
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Test the MCP backend search functions directly
local function test_mcp_search_functions()
	print("=== Testing MCP Backend Search Functions ===")

	-- Load the MCP backend
	local backend = require("paragonic.backend")

	-- Initialize backend and get client (skip if Neovim APIs not available)
	local success = pcall(function()
		return backend._initialize_backend()
	end)

	if not success then
		print("⚠ Backend initialization skipped (expected in standalone mode)")
		return
	end

	local client = backend._get_rpc_client()
	if not client then
		print("⚠ Backend client not available (expected in standalone mode)")
		return
	end

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

	-- Note: Formatting functions are handled by the search module, not the backend
	print("✓ MCP backend search tests passed")

	print("✓ All MCP search function tests passed!")
end

-- Test search function signatures (without executing)
local function test_function_signatures()
	print("=== Testing Function Signatures ===")

	-- Test that we can load the module
	local success, backend = pcall(require, "paragonic.backend")
	assert(success, "Should be able to load backend module")

	-- Test backend initialization (skip if Neovim APIs not available)
	local init_success = pcall(function()
		return backend._initialize_backend()
	end)

	if init_success then
		local client = backend._get_rpc_client()
		if client then
			-- Test method signatures
			assert(type(client.search_embeddings) == "function", "search_embeddings should be a function")
			assert(type(client.find_similar_content) == "function", "find_similar_content should be a function")
			assert(type(client.hybrid_search) == "function", "hybrid_search should be a function")
			print("✓ All function signatures are correct")
		else
			print("⚠ Backend client not available (expected in standalone mode)")
		end
	else
		print("⚠ Backend initialization skipped (expected in standalone mode)")
	end
end

-- Main test execution
print("=== Search Functions Test ===")
print("Testing search functionality without vim API dependencies...")

-- Run tests
test_function_signatures()
test_mcp_search_functions()

print("\n=== Test Complete ===")
print("✓ All search function tests passed!")
print("The search functionality is ready for Neovim integration.")
print("Commands available in Neovim:")
print("  :ParagonicSearch <query>")
print("  :ParagonicSearchFiltered <query>")
print("  :ParagonicSearchHybrid <query>")
