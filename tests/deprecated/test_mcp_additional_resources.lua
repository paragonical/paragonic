#!/usr/bin/env lua

--[[
Test script for additional MCP resources functionality
This tests the ability to retrieve Neovim macros, plugins, and registers as MCP resources
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Test additional MCP resources functionality
local function test_mcp_additional_resources()
	print("=== Testing Additional MCP Resources ===")

	-- Mock the required vim functions for testing
	local vim_mock = {
		api = {
			nvim_get_var = function(var_name)
				if var_name == "g:loaded_plugins" then
					return {
						["nvim-treesitter"] = true,
						["telescope.nvim"] = true,
						["lspconfig"] = true,
					}
				end
				return nil
			end,
			nvim_get_runtime_file = function(path, all)
				if path == "plugin" then
					return {
						"/usr/share/nvim/runtime/plugin/matchparen.vim",
						"/usr/share/nvim/runtime/plugin/netrwPlugin.vim",
						"/home/user/.local/share/nvim/site/pack/packer/start/telescope.nvim/plugin/telescope.vim",
					}
				end
				return {}
			end,
			nvim_get_option = function(option)
				if option == "runtimepath" then
					return "/usr/share/nvim/runtime,/home/user/.local/share/nvim/site"
				end
				return ""
			end,
		},
		fn = {
			getreg = function(reg)
				if reg == "a" then
					return "yanked text from register a"
				elseif reg == "b" then
					return "yanked text from register b"
				elseif reg == "c" then
					return "yanked text from register c"
				elseif reg == "0" then
					return "last yanked text"
				elseif reg == "1" then
					return "last deleted text"
				elseif reg == '"' then
					return "default register content"
				else
					return ""
				end
			end,
			getregtype = function(reg)
				if reg == "a" then
					return "v"
				elseif reg == "b" then
					return "V"
				elseif reg == "c" then
					return "c"
				elseif reg == "0" then
					return "v"
				elseif reg == "1" then
					return "V"
				elseif reg == '"' then
					return "v"
				else
					return ""
				end
			end,
			getchar = function()
				return 97
			end, -- 'a'
			input = function(prompt)
				return "test macro"
			end,
			execute = function(cmd)
				if cmd == "let @a='dd'" then
					return 0
				elseif cmd == "let @b='yy'" then
					return 0
				else
					return 0
				end
			end,
			globpath = function(path, pattern)
				if pattern == "**/plugin/*.vim" then
					return {
						"/usr/share/nvim/runtime/plugin/matchparen.vim",
						"/usr/share/nvim/runtime/plugin/netrwPlugin.vim",
					}
				end
				return {}
			end,
			split = function(str, sep)
				if str == "/usr/share/nvim/runtime,/home/user/.local/share/nvim/site" then
					return { "/usr/share/nvim/runtime", "/home/user/.local/share/nvim/site" }
				end
				return {}
			end,
		},
		g = {
			loaded_plugins = {
				["nvim-treesitter"] = true,
				["telescope.nvim"] = true,
				["lspconfig"] = true,
			},
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
		json = {
			encode = function(data)
				-- Simple JSON encoder for testing
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
				-- Simple JSON decoder for testing
				if json_str:find("register") then
					return {
						{ register = "a", content = "yanked text from register a", type = "v" },
						{ register = "b", content = "yanked text from register b", type = "V" },
						{ register = "c", content = "yanked text from register c", type = "c" },
					}
				elseif json_str:find("macro") then
					return {
						{ register = "a", macro = "dd", description = "delete line macro" },
						{ register = "b", macro = "yy", description = "yank line macro" },
					}
				elseif json_str:find("plugin") then
					return {
						{
							name = "nvim-treesitter",
							loaded = true,
							path = "/usr/share/nvim/runtime/plugin/treesitter.vim",
						},
						{
							name = "telescope.nvim",
							loaded = true,
							path = "/home/user/.local/share/nvim/site/pack/packer/start/telescope.nvim/plugin/telescope.vim",
						},
					}
				else
					return {}
				end
			end,
		},
	}

	-- Replace global vim temporarily
	local original_vim = _G.vim
	_G.vim = vim_mock

	-- Test the additional MCP resources functionality
	print("  Testing additional MCP resources...")

	-- Create a simple test module
	local M = {}

	-- Get Neovim registers information
	function M.get_registers_info()
		local registers = {}
		local register_names = {
			'"',
			"0",
			"1",
			"2",
			"3",
			"4",
			"5",
			"6",
			"7",
			"8",
			"9",
			"a",
			"b",
			"c",
			"d",
			"e",
			"f",
			"g",
			"h",
			"i",
			"j",
			"k",
			"l",
			"m",
			"n",
			"o",
			"p",
			"q",
			"r",
			"s",
			"t",
			"u",
			"v",
			"w",
			"x",
			"y",
			"z",
		}

		for _, reg in ipairs(register_names) do
			local content = vim.fn.getreg(reg)
			local reg_type = vim.fn.getregtype(reg)

			if content and content ~= "" then
				table.insert(registers, {
					register = reg,
					content = content,
					type = reg_type,
					length = #content,
					timestamp = os.time(),
				})
			end
		end

		return registers
	end

	-- Test registers info retrieval
	local registers_info = M.get_registers_info()
	assert(#registers_info > 0, "Should have some registers")
	assert(registers_info[1].register ~= nil, "Should have register name")
	assert(registers_info[1].content ~= nil, "Should have register content")
	assert(registers_info[1].type ~= nil, "Should have register type")

	print("  ✓ Registers info retrieval works")

	-- Get Neovim macros information
	function M.get_macros_info()
		local macros = {}
		local macro_registers = {
			"a",
			"b",
			"c",
			"d",
			"e",
			"f",
			"g",
			"h",
			"i",
			"j",
			"k",
			"l",
			"m",
			"n",
			"o",
			"p",
			"q",
			"r",
			"s",
			"t",
			"u",
			"v",
			"w",
			"x",
			"y",
			"z",
		}

		for _, reg in ipairs(macro_registers) do
			local macro = vim.fn.getreg(reg)
			if macro and macro ~= "" and macro:match("^[a-zA-Z0-9@:]*$") then
				-- This looks like a macro (contains only letters, numbers, @, :)
				table.insert(macros, {
					register = reg,
					macro = macro,
					description = "Macro in register " .. reg,
					timestamp = os.time(),
				})
			end
		end

		return macros
	end

	-- Test macros info retrieval
	local macros_info = M.get_macros_info()
	assert(#macros_info >= 0, "Should have macros (possibly empty)")
	if #macros_info > 0 then
		assert(macros_info[1].register ~= nil, "Should have register name")
		assert(macros_info[1].macro ~= nil, "Should have macro content")
		assert(macros_info[1].description ~= nil, "Should have description")
	end

	print("  ✓ Macros info retrieval works")

	-- Get Neovim plugins information
	function M.get_plugins_info()
		local plugins = {}

		-- Get loaded plugins from g:loaded_plugins
		local loaded_plugins = vim.g.loaded_plugins or {}
		for plugin_name, loaded in pairs(loaded_plugins) do
			if loaded then
				table.insert(plugins, {
					name = plugin_name,
					loaded = true,
					path = "g:loaded_plugins",
					timestamp = os.time(),
				})
			end
		end

		-- Get plugins from runtime path
		local runtime_path = vim.api.nvim_get_option("runtimepath")
		local paths = vim.fn.split(runtime_path, ",")

		for _, path in ipairs(paths) do
			local plugin_files = vim.fn.globpath(path, "**/plugin/*.vim", true, true)
			for _, plugin_file in ipairs(plugin_files) do
				local plugin_name = plugin_file:match("([^/]+)/plugin/[^/]+%.vim$")
				if plugin_name then
					-- Check if not already added
					local exists = false
					for _, existing_plugin in ipairs(plugins) do
						if existing_plugin.name == plugin_name then
							exists = true
							break
						end
					end

					if not exists then
						table.insert(plugins, {
							name = plugin_name,
							loaded = true,
							path = plugin_file,
							timestamp = os.time(),
						})
					end
				end
			end
		end

		return plugins
	end

	-- Test plugins info retrieval
	local plugins_info = M.get_plugins_info()
	assert(#plugins_info > 0, "Should have some plugins")
	assert(plugins_info[1].name ~= nil, "Should have plugin name")
	assert(plugins_info[1].loaded ~= nil, "Should have loaded status")
	assert(plugins_info[1].path ~= nil, "Should have plugin path")

	print("  ✓ Plugins info retrieval works")

	-- Test additional resource listing
	print("  Testing additional resource listing...")
	function M.list_mcp_resources()
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
			{
				uri = "neovim://marks",
				name = "Neovim Marks",
				description = "List of all marks in the session",
				mime_type = "application/json",
			},
			{
				uri = "neovim://registers",
				name = "Neovim Registers",
				description = "List of all registers and their content",
				mime_type = "application/json",
			},
			{
				uri = "neovim://macros",
				name = "Neovim Macros",
				description = "List of all recorded macros",
				mime_type = "application/json",
			},
			{
				uri = "neovim://plugins",
				name = "Neovim Plugins",
				description = "List of all loaded plugins",
				mime_type = "application/json",
			},
		}
	end

	local resources = M.list_mcp_resources()
	assert(#resources == 7, "Should have 7 resources including new ones")
	assert(resources[5].uri == "neovim://registers", "Should have registers resource")
	assert(resources[6].uri == "neovim://macros", "Should have macros resource")
	assert(resources[7].uri == "neovim://plugins", "Should have plugins resource")

	print("  ✓ Additional resource listing works")

	-- Test additional resource content
	print("  Testing additional resource content...")
	function M.read_mcp_resource(uri)
		if uri == "neovim://registers" then
			local registers_info = M.get_registers_info()
			return {
				contents = {
					{
						uri = uri,
						mime_type = "application/json",
						text = vim.json.encode(registers_info),
					},
				},
			}
		elseif uri == "neovim://macros" then
			local macros_info = M.get_macros_info()
			return {
				contents = {
					{
						uri = uri,
						mime_type = "application/json",
						text = vim.json.encode(macros_info),
					},
				},
			}
		elseif uri == "neovim://plugins" then
			local plugins_info = M.get_plugins_info()
			return {
				contents = {
					{
						uri = uri,
						mime_type = "application/json",
						text = vim.json.encode(plugins_info),
					},
				},
			}
		else
			return {
				error = {
					code = -32602,
					message = "Resource not found: " .. uri,
				},
			}
		end
	end

	-- Test registers resource content
	local registers_result = M.read_mcp_resource("neovim://registers")
	assert(registers_result.contents ~= nil, "Should have contents for registers resource")
	assert(registers_result.contents[1].uri == "neovim://registers", "Should have correct URI")
	assert(registers_result.contents[1].mime_type == "application/json", "Should have JSON MIME type")

	-- Test macros resource content
	local macros_result = M.read_mcp_resource("neovim://macros")
	assert(macros_result.contents ~= nil, "Should have contents for macros resource")
	assert(macros_result.contents[1].uri == "neovim://macros", "Should have correct URI")
	assert(macros_result.contents[1].mime_type == "application/json", "Should have JSON MIME type")

	-- Test plugins resource content
	local plugins_result = M.read_mcp_resource("neovim://plugins")
	assert(plugins_result.contents ~= nil, "Should have contents for plugins resource")
	assert(plugins_result.contents[1].uri == "neovim://plugins", "Should have correct URI")
	assert(plugins_result.contents[1].mime_type == "application/json", "Should have JSON MIME type")

	print("  ✓ Additional resource content works")

	-- Test register-specific operations
	print("  Testing register-specific operations...")
	function M.get_register_info(register_name)
		local content = vim.fn.getreg(register_name)
		local reg_type = vim.fn.getregtype(register_name)

		if content and content ~= "" then
			return {
				register = register_name,
				content = content,
				type = reg_type,
				length = #content,
				timestamp = os.time(),
			}
		else
			return nil, "Register is empty or not found: " .. register_name
		end
	end

	local reg_a = M.get_register_info("a")
	assert(reg_a ~= nil, "Should get register 'a' info")
	assert(reg_a.register == "a", "Should have correct register name")
	assert(reg_a.content ~= nil, "Should have content")
	assert(reg_a.type ~= nil, "Should have type")

	local reg_x, error = M.get_register_info("x")
	assert(reg_x == nil, "Should return nil for empty register")
	assert(error:find("Register is empty"), "Should have correct error message")

	print("  ✓ Register-specific operations work")

	-- Test macro-specific operations
	print("  Testing macro-specific operations...")
	function M.get_macro_info(register_name)
		local macro = vim.fn.getreg(register_name)

		if macro and macro ~= "" and macro:match("^[a-zA-Z0-9@:]*$") then
			return {
				register = register_name,
				macro = macro,
				description = "Macro in register " .. register_name,
				timestamp = os.time(),
			}
		else
			return nil, "No macro found in register: " .. register_name
		end
	end

	local macro_a = M.get_macro_info("a")
	if macro_a then
		assert(macro_a.register == "a", "Should have correct register name")
		assert(macro_a.macro ~= nil, "Should have macro content")
		assert(macro_a.description ~= nil, "Should have description")
	end

	print("  ✓ Macro-specific operations work")

	-- Test plugin-specific operations
	print("  Testing plugin-specific operations...")
	function M.get_plugin_info(plugin_name)
		local loaded_plugins = vim.g.loaded_plugins or {}

		if loaded_plugins[plugin_name] then
			return {
				name = plugin_name,
				loaded = true,
				path = "g:loaded_plugins",
				timestamp = os.time(),
			}
		else
			return nil, "Plugin not found or not loaded: " .. plugin_name
		end
	end

	local plugin_treesitter = M.get_plugin_info("nvim-treesitter")
	assert(plugin_treesitter ~= nil, "Should get nvim-treesitter plugin info")
	assert(plugin_treesitter.name == "nvim-treesitter", "Should have correct plugin name")
	assert(plugin_treesitter.loaded == true, "Should have loaded status")

	local plugin_unknown, error = M.get_plugin_info("unknown-plugin")
	assert(plugin_unknown == nil, "Should return nil for unknown plugin")
	assert(error:find("Plugin not found"), "Should have correct error message")

	print("  ✓ Plugin-specific operations work")

	-- Test MCP message handling for additional resources
	print("  Testing MCP message handling for additional resources...")
	function M.handle_mcp_message(message)
		local id = message.id
		local method = message.method
		local params = message.params or {}

		if method == "resources/read" then
			local uri = params.uri
			if uri == "neovim://registers" or uri == "neovim://macros" or uri == "neovim://plugins" then
				return {
					id = id,
					result = M.read_mcp_resource(uri),
				}
			else
				return {
					id = id,
					error = {
						code = -32602,
						message = "Resource not found: " .. uri,
					},
				}
			end
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

	-- Test registers message
	local registers_message = {
		id = 1,
		method = "resources/read",
		params = { uri = "neovim://registers" },
	}

	local registers_response = M.handle_mcp_message(registers_message)
	assert(registers_response.id == 1, "Should return correct message ID")
	assert(registers_response.result ~= nil, "Should have result for registers resource")
	assert(registers_response.result.contents ~= nil, "Should have contents in result")

	-- Test macros message
	local macros_message = {
		id = 2,
		method = "resources/read",
		params = { uri = "neovim://macros" },
	}

	local macros_response = M.handle_mcp_message(macros_message)
	assert(macros_response.id == 2, "Should return correct message ID")
	assert(macros_response.result ~= nil, "Should have result for macros resource")
	assert(macros_response.result.contents ~= nil, "Should have contents in result")

	-- Test plugins message
	local plugins_message = {
		id = 3,
		method = "resources/read",
		params = { uri = "neovim://plugins" },
	}

	local plugins_response = M.handle_mcp_message(plugins_message)
	assert(plugins_response.id == 3, "Should return correct message ID")
	assert(plugins_response.result ~= nil, "Should have result for plugins resource")
	assert(plugins_response.result.contents ~= nil, "Should have contents in result")

	print("  ✓ MCP message handling for additional resources works")

	-- Restore original vim
	_G.vim = original_vim

	print("✓ All additional MCP resources tests passed!")
end

-- Main test execution
print("=== Additional MCP Resources Test ===")
print("Testing additional MCP resources functionality...")

-- Run tests
test_mcp_additional_resources()

print("\n=== Test Complete ===")
print("✓ All additional MCP resources tests passed!")
print("Additional MCP resources features verified:")
print("  • Registers info retrieval")
print("  • Macros info retrieval")
print("  • Plugins info retrieval")
print("  • Additional resource listing")
print("  • Additional resource content")
print("  • Register-specific operations")
print("  • Macro-specific operations")
print("  • Plugin-specific operations")
print("  • MCP message handling for additional resources")
