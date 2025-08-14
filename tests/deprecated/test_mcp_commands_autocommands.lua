#!/usr/bin/env lua

--[[
Test script for MCP commands and autocommands resources
This tests exposing Neovim commands and autocommands as MCP resources
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

local function test_mcp_commands_autocommands()
	print("=== Testing MCP Commands and Autocommands Resources ===")

	-- Mock vim API
	local vim_mock = {
		api = {
			nvim_get_commands = function(opts)
				return {
					ParagonicChat = {
						name = "ParagonicChat",
						definition = "Open the Paragonic chat window",
						nargs = "0",
						bang = false,
					},
					ParagonicSearch = {
						name = "ParagonicSearch",
						definition = "Search using Paragonic",
						nargs = "*",
						bang = false,
					},
					Write = {
						name = "Write",
						definition = "Write current buffer to file",
						nargs = "0",
						bang = true,
					},
				}
			end,
			nvim_get_autocmds = function(opts)
				return {
					{
						event = "BufRead",
						group = 1,
						group_name = "paragonic_group",
						pattern = "*.lua",
						command = "echo 'Lua file read'",
						desc = "Echo on Lua file read",
					},
					{
						event = "BufWritePre",
						group = 1,
						group_name = "paragonic_group",
						pattern = "*",
						command = "echo 'Before write'",
						desc = "Echo before write",
					},
				}
			end,
		},
		json = {
			encode = function(data)
				if type(data) == "table" then
					local parts = {}
					for k, v in pairs(data) do
						if type(v) == "string" then
							table.insert(parts, string.format('"%s": "%s"', k, v))
						elseif type(v) == "number" then
							table.insert(parts, string.format('"%s": %s', k, v))
						elseif type(v) == "boolean" then
							table.insert(parts, string.format('"%s": %s', k, tostring(v)))
						elseif type(v) == "table" then
							table.insert(parts, string.format('"%s": %s', k, vim.json.encode(v)))
						end
					end
					return "{" .. table.concat(parts, ", ") .. "}"
				elseif type(data) == "string" then
					return string.format('"%s"', data)
				else
					return tostring(data)
				end
			end,
			decode = function(json_str)
				return {}
			end,
		},
	}

	-- Replace global vim
	local original_vim = _G.vim
	_G.vim = vim_mock

	local M = {}

	-- Implement resource readers
	function M.get_commands_info()
		local commands = vim.api.nvim_get_commands({})
		local result = {}
		for name, cmd in pairs(commands) do
			table.insert(result, {
				name = name,
				definition = cmd.definition,
				nargs = cmd.nargs,
				bang = cmd.bang,
			})
		end
		return result
	end

	function M.get_autocommands_info()
		local autocmds = vim.api.nvim_get_autocmds({})
		local result = {}
		for _, ac in ipairs(autocmds) do
			table.insert(result, {
				event = ac.event,
				group = ac.group,
				group_name = ac.group_name,
				pattern = ac.pattern,
				command = ac.command,
				desc = ac.desc,
			})
		end
		return result
	end

	-- Test commands info
	local commands = M.get_commands_info()
	assert(#commands == 3, "Should get 3 commands")

	-- Check for ParagonicChat command (order-independent)
	local has_paragonic_chat = false
	for _, cmd in ipairs(commands) do
		if cmd.name == "ParagonicChat" then
			has_paragonic_chat = true
			break
		end
	end
	assert(has_paragonic_chat, "Should include ParagonicChat command")

	-- Check for Write command (order-independent)
	local has_write = false
	for _, cmd in ipairs(commands) do
		if cmd.name == "Write" then
			has_write = true
			break
		end
	end
	assert(has_write, "Should include Write command")
	print("  ✓ Commands info retrieval works")

	-- Test autocommands info
	local autocmds = M.get_autocommands_info()
	assert(#autocmds == 2, "Should get 2 autocommands")
	assert(autocmds[1].event == "BufRead" or autocmds[2].event == "BufRead", "Should include BufRead event")
	assert(
		autocmds[1].desc == "Echo on Lua file read" or autocmds[2].desc == "Echo on Lua file read",
		"Should include correct description"
	)
	print("  ✓ Autocommands info retrieval works")

	-- Simulate MCP resource listing
	function M.list_mcp_resources()
		return {
			{
				uri = "neovim://commands",
				name = "Neovim Commands",
				description = "List of all available commands",
				mime_type = "application/json",
			},
			{
				uri = "neovim://autocommands",
				name = "Neovim Autocommands",
				description = "List of all autocommands",
				mime_type = "application/json",
			},
		}
	end

	-- Simulate MCP resource reading
	function M.read_mcp_resource(uri)
		if uri == "neovim://commands" then
			return {
				contents = {
					{
						uri = uri,
						mime_type = "application/json",
						text = vim.json.encode(M.get_commands_info()),
					},
				},
			}
		elseif uri == "neovim://autocommands" then
			return {
				contents = {
					{
						uri = uri,
						mime_type = "application/json",
						text = vim.json.encode(M.get_autocommands_info()),
					},
				},
			}
		else
			return { error = { code = -32601, message = "Unknown resource URI: " .. tostring(uri) } }
		end
	end

	-- Test MCP resource listing
	local resources = M.list_mcp_resources()
	assert(resources[1].uri == "neovim://commands", "Should list commands resource")
	assert(resources[2].uri == "neovim://autocommands", "Should list autocommands resource")
	print("  ✓ MCP resource listing works")

	-- Test MCP resource reading for commands
	local commands_resource = M.read_mcp_resource("neovim://commands")
	assert(commands_resource.contents ~= nil, "Should return contents for commands resource")
	assert(commands_resource.contents[1].uri == "neovim://commands", "Should have correct URI for commands resource")
	print("  ✓ MCP commands resource reading works")

	-- Test MCP resource reading for autocommands
	local autocmds_resource = M.read_mcp_resource("neovim://autocommands")
	assert(autocmds_resource.contents ~= nil, "Should return contents for autocommands resource")
	assert(
		autocmds_resource.contents[1].uri == "neovim://autocommands",
		"Should have correct URI for autocommands resource"
	)
	print("  ✓ MCP autocommands resource reading works")

	-- Restore global vim
	_G.vim = original_vim

	print("✓ All MCP commands and autocommands resource tests passed!")
end

print("=== MCP Commands and Autocommands Resource Test ===")
print("Testing MCP commands and autocommands resources...")
test_mcp_commands_autocommands()
print("\n=== Test Complete ===")
print("✓ All MCP commands and autocommands resource tests passed!")
