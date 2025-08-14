--[[
Test for projects interface integration with RPC backend - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"

-- Test that projects interface can load projects from backend
local function test_projects_interface_load_projects()
	print("Testing projects interface load projects...")

	-- Load the paragonic module
	local paragonic = require("paragonic")

	-- Get RPC client (should initialize backend)
	local rpc_client = paragonic._get_rpc_client()
	assert(rpc_client ~= nil, "Should have RPC client")
	assert(rpc_client:is_connected(), "RPC client should be connected")

	-- Test that we can get projects list
	local response = paragonic.get_projects()
	assert(response ~= nil, "Should get response from get_projects")
	assert(type(response) == "string", "Response should be string")
	assert(response:find('"jsonrpc"'), "Should contain jsonrpc field")

	print("✓ Projects interface load projects test passed!")
end

-- Test that projects interface can create new projects
local function test_projects_interface_create_project()
	print("Testing projects interface create project...")

	-- Load the paragonic module
	local paragonic = require("paragonic")

	-- Get RPC client
	local rpc_client = paragonic._get_rpc_client()
	assert(rpc_client ~= nil, "Should have RPC client")

	-- Test that we can create a project
	local response = paragonic.create_project("Test Project", "A test project for development")
	assert(response ~= nil, "Should get response from create_project")
	assert(type(response) == "string", "Response should be string")
	assert(response:find('"jsonrpc"'), "Should contain jsonrpc field")

	print("✓ Projects interface create project test passed!")
end

-- Run the tests
test_projects_interface_load_projects()
test_projects_interface_create_project()
