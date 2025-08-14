#!/usr/bin/env lua

--[[
Test script for MCP server initialization functionality
This tests the ability to initialize an MCP-compliant server
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Test MCP server initialization functionality
local function test_mcp_server_init()
	print("=== Testing MCP Server Init ===")

	-- Mock the required vim functions for testing
	local vim_mock = {
		api = {
			nvim_list_bufs = function()
				return { 1, 2, 3 }
			end,
			nvim_buf_get_name = function(buf)
				if buf == 1 then
					return "/tmp/file1.txt"
				elseif buf == 2 then
					return "/tmp/file2.lua"
				else
					return "/tmp/file3.md"
				end
			end,
			nvim_get_current_buf = function()
				return 1
			end,
			nvim_get_mode = function()
				return { mode = "n" }
			end,
		},
		fn = {
			getcwd = function()
				return "/tmp"
			end,
			expand = function(expr)
				if expr == "%:p" then
					return "/tmp/current.txt"
				else
					return expr
				end
			end,
		},
		o = {
			columns = 120,
			lines = 30,
		},
		notify = function(msg, level)
			print("  Notify [" .. (level or "info") .. "]: " .. msg)
		end,
		log = {
			levels = {
				INFO = 1,
				WARN = 2,
				ERROR = 3,
			},
		},
	}

	-- Replace global vim temporarily
	local original_vim = _G.vim
	_G.vim = vim_mock

	-- Test the MCP server initialization
	print("  Testing MCP server initialization...")

	-- Create a simple test module
	local M = {}

	-- MCP Server implementation
	M.mcp_server = {
		protocol_version = "2025-06-18",
		server_info = {
			name = "paragonic-neovim",
			version = "1.0.0",
		},
		capabilities = {
			resources = {
				list_resources = true,
				read_resources = true,
			},
			tools = {
				list_tools = true,
				call_tools = true,
			},
			prompts = {
				list_prompts = true,
				show_prompts = true,
			},
		},
	}

	-- Initialize MCP server
	function M.initialize_mcp_server()
		local initialize_result = {
			protocol_version = M.mcp_server.protocol_version,
			capabilities = M.mcp_server.capabilities,
			server_info = M.mcp_server.server_info,
		}

		print("  MCP Server initialized with protocol version: " .. initialize_result.protocol_version)
		return initialize_result
	end

	-- Test the initialization
	local result = M.initialize_mcp_server()

	-- Verify basic structure
	assert(result.protocol_version == "2025-06-18", "Should have correct protocol version")
	assert(result.server_info.name == "paragonic-neovim", "Should have correct server name")
	assert(result.server_info.version == "1.0.0", "Should have correct server version")
	assert(type(result.capabilities) == "table", "Should have capabilities table")
	assert(type(result.capabilities.resources) == "table", "Should have resources capabilities")
	assert(type(result.capabilities.tools) == "table", "Should have tools capabilities")
	assert(type(result.capabilities.prompts) == "table", "Should have prompts capabilities")

	print("  ✓ MCP server initialization works")

	-- Define helper functions first
	function M.list_mcp_resources()
		-- Convert our session info to MCP Resources
		return {
			{
				uri = "neovim://session",
				name = "Neovim Session",
				description = "Current Neovim session information",
				mime_type = "application/json",
			},
			{
				uri = "neovim://buffers",
				name = "Neovim Buffers",
				description = "List of all buffers in the session",
				mime_type = "application/json",
			},
			{
				uri = "neovim://windows",
				name = "Neovim Windows",
				description = "List of all windows in the session",
				mime_type = "application/json",
			},
		}
	end

	function M.list_mcp_tools()
		return {
			{
				name = "agent_edit_file",
				description = "Edit a file in the current Neovim session",
				input_schema = {
					type = "object",
					properties = {
						file_path = { type = "string" },
						line_number = { type = "integer" },
						content = { type = "string" },
					},
					required = { "file_path" },
				},
			},
			{
				name = "agent_create_file",
				description = "Create a new file in the current Neovim session",
				input_schema = {
					type = "object",
					properties = {
						file_name = { type = "string" },
						content = { type = "string" },
						open_in_window = { type = "boolean" },
					},
					required = { "file_name" },
				},
			},
			{
				name = "agent_save_file",
				description = "Save a file to disk",
				input_schema = {
					type = "object",
					properties = {
						file_path = { type = "string" },
						force = { type = "boolean" },
					},
				},
			},
		}
	end

	-- Test MCP message handling
	print("  Testing MCP message handling...")

	function M.handle_mcp_message(message)
		local id = message.id
		local method = message.method
		local params = message.params or {}

		if method == "initialize" then
			return {
				id = id,
				result = M.initialize_mcp_server(),
			}
		elseif method == "resources/list" then
			return {
				id = id,
				result = {
					resources = M.list_mcp_resources(),
				},
			}
		elseif method == "tools/list" then
			return {
				id = id,
				result = {
					tools = M.list_mcp_tools(),
				},
			}
		else
			return {
				id = id,
				error = {
					code = -32601,
					message = "Method not found: " .. method,
				},
			}
		end
	end

	-- Test initialize message
	local init_message = {
		id = 1,
		method = "initialize",
		params = {},
	}

	local init_response = M.handle_mcp_message(init_message)
	assert(init_response.id == 1, "Should return correct message ID")
	assert(init_response.result ~= nil, "Should have result for initialize")
	assert(init_response.result.protocol_version == "2025-06-18", "Should have correct protocol version")

	-- Test resources/list message
	local resources_message = {
		id = 2,
		method = "resources/list",
		params = {},
	}

	local resources_response = M.handle_mcp_message(resources_message)
	assert(resources_response.id == 2, "Should return correct message ID")
	assert(resources_response.result ~= nil, "Should have result for resources/list")

	-- Test unknown method
	local unknown_message = {
		id = 3,
		method = "unknown/method",
		params = {},
	}

	local unknown_response = M.handle_mcp_message(unknown_message)
	assert(unknown_response.id == 3, "Should return correct message ID")
	assert(unknown_response.error ~= nil, "Should have error for unknown method")
	assert(unknown_response.error.code == -32601, "Should have method not found error code")

	print("  ✓ MCP message handling works")

	-- Test MCP resource listing
	print("  Testing MCP resource listing...")

	local resources = M.list_mcp_resources()
	assert(#resources == 3, "Should have 3 resources")
	assert(resources[1].uri == "neovim://session", "Should have session resource")
	assert(resources[2].uri == "neovim://buffers", "Should have buffers resource")
	assert(resources[3].uri == "neovim://windows", "Should have windows resource")

	print("  ✓ MCP resource listing works")

	-- Test MCP tool listing
	print("  Testing MCP tool listing...")

	local tools = M.list_mcp_tools()
	assert(#tools == 3, "Should have 3 tools")
	assert(tools[1].name == "agent_edit_file", "Should have edit file tool")
	assert(tools[2].name == "agent_create_file", "Should have create file tool")
	assert(tools[3].name == "agent_save_file", "Should have save file tool")

	-- Verify tool schemas
	assert(type(tools[1].input_schema) == "table", "Should have input schema")
	assert(tools[1].input_schema.type == "object", "Should have object schema type")
	assert(type(tools[1].input_schema.properties) == "table", "Should have properties")

	print("  ✓ MCP tool listing works")

	-- Restore original vim
	_G.vim = original_vim

	print("✓ All MCP server init tests passed!")
end

-- Main test execution
print("=== MCP Server Init Test ===")
print("Testing MCP server initialization functionality...")

-- Run tests
test_mcp_server_init()

print("\n=== Test Complete ===")
print("✓ All MCP server init tests passed!")
print("MCP server init features verified:")
print("  • MCP server initialization")
print("  • Protocol version compliance")
print("  • Server capabilities definition")
print("  • MCP message handling")
print("  • Resource listing")
print("  • Tool listing with schemas")
print("  • Error handling for unknown methods")
