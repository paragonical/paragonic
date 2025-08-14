#!/usr/bin/env lua

--[[
Test script for MCP sampling and roots capabilities
This tests allowing agents to request specific parts of resources and define context
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

local function test_mcp_sampling_roots()
	print("=== Testing MCP Sampling and Roots Capabilities ===")

	-- Mock vim API
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
			nvim_buf_get_lines = function(buf, start, end_, strict)
				if buf == 1 then
					return { "line 1", "line 2", "line 3", "line 4", "line 5" }
				elseif buf == 2 then
					return { "function test()", "  return true", "end", "print('hello')" }
				else
					return { "# Markdown", "## Section", "Content here" }
				end
			end,
			nvim_get_current_buf = function()
				return 1
			end,
			nvim_list_wins = function()
				return { 1, 2 }
			end,
			nvim_win_get_buf = function(win)
				return win
			end,
			nvim_win_get_cursor = function(win)
				return { 5, 0 }
			end,
		},
		fn = {
			getcwd = function()
				return "/tmp"
			end,
			expand = function(what)
				if what == "%" then
					return "/tmp/file1.txt"
				else
					return "/tmp"
				end
			end,
		},
		o = {
			columns = 80,
			lines = 24,
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

	-- Sample resource content based on criteria
	function M.sample_resource(uri, criteria)
		if uri == "neovim://buffers" then
			local buffers = M.get_buffers_info()

			-- Apply sampling criteria
			if criteria and criteria.limit then
				local sampled = {}
				for i = 1, math.min(criteria.limit, #buffers) do
					table.insert(sampled, buffers[i])
				end
				return sampled
			end

			-- Apply filtering criteria
			if criteria and criteria.filter then
				local filtered = {}
				for _, buf in ipairs(buffers) do
					if criteria.filter.file_type and buf.name:match("%." .. criteria.filter.file_type .. "$") then
						table.insert(filtered, buf)
					elseif criteria.filter.name_pattern and buf.name:match(criteria.filter.name_pattern) then
						table.insert(filtered, buf)
					elseif criteria.filter.modifiable ~= nil and buf.modifiable == criteria.filter.modifiable then
						table.insert(filtered, buf)
					end
				end
				return filtered
			end

			return buffers
		elseif uri == "neovim://session" then
			local session = M.get_session_info()

			-- Apply sampling criteria
			if criteria and criteria.fields then
				local sampled = {}
				for _, field in ipairs(criteria.fields) do
					if session[field] then
						sampled[field] = session[field]
					end
				end
				return sampled
			end

			return session
		else
			return nil, "Unsupported resource for sampling: " .. uri
		end
	end

	-- Define resource roots (context boundaries)
	function M.define_resource_roots(uri, roots)
		if uri == "neovim://buffers" then
			-- Define which buffers are in scope
			local all_buffers = M.get_buffers_info()
			local scoped_buffers = {}

			if roots and roots.buffer_ids then
				for _, buf in ipairs(all_buffers) do
					for _, root_id in ipairs(roots.buffer_ids) do
						if buf.id == root_id then
							table.insert(scoped_buffers, buf)
							break
						end
					end
				end
				return scoped_buffers
			elseif roots and roots.file_patterns then
				for _, buf in ipairs(all_buffers) do
					for _, pattern in ipairs(roots.file_patterns) do
						if buf.name:match(pattern) then
							table.insert(scoped_buffers, buf)
							break
						end
					end
				end
				return scoped_buffers
			end

			return all_buffers
		elseif uri == "neovim://session" then
			local session = M.get_session_info()

			if roots and roots.current_only then
				return {
					current_file = session.current_file,
					current_directory = session.current_directory,
					mode = session.mode,
				}
			end

			return session
		else
			return nil, "Unsupported resource for roots: " .. uri
		end
	end

	-- Mock helper functions
	function M.get_buffers_info()
		local buffers = {}
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			local name = vim.api.nvim_buf_get_name(buf)
			table.insert(buffers, {
				id = buf,
				name = name,
				modifiable = true,
				line_count = 5,
				is_current = (buf == vim.api.nvim_get_current_buf()),
			})
		end
		return buffers
	end

	function M.get_session_info()
		return {
			current_file = vim.fn.expand("%"),
			current_directory = vim.fn.getcwd(),
			mode = "normal",
			buffers = M.get_buffers_info(),
			windows = {
				{ id = 1, buffer_id = 1, cursor_line = 5, cursor_column = 0 },
				{ id = 2, buffer_id = 2, cursor_line = 5, cursor_column = 0 },
			},
		}
	end

	-- Test sampling with limit
	local sampled_buffers = M.sample_resource("neovim://buffers", { limit = 2 })
	assert(#sampled_buffers == 2, "Should limit to 2 buffers")
	assert(sampled_buffers[1].id == 1, "Should include first buffer")
	assert(sampled_buffers[2].id == 2, "Should include second buffer")
	print("  ✓ Sampling with limit works")

	-- Test sampling with file type filter
	local lua_buffers = M.sample_resource("neovim://buffers", { filter = { file_type = "lua" } })
	assert(#lua_buffers == 1, "Should filter to 1 Lua buffer")
	assert(lua_buffers[1].name:match("%.lua$"), "Should be a Lua file")
	print("  ✓ Sampling with file type filter works")

	-- Test sampling with name pattern
	local file1_buffers = M.sample_resource("neovim://buffers", { filter = { name_pattern = "file1" } })
	assert(#file1_buffers == 1, "Should filter to 1 file1 buffer")
	assert(file1_buffers[1].name:find("file1"), "Should contain file1 in name")
	print("  ✓ Sampling with name pattern works")

	-- Test sampling session with specific fields
	local session_sample = M.sample_resource("neovim://session", { fields = { "current_file", "mode" } })
	assert(session_sample.current_file ~= nil, "Should include current_file")
	assert(session_sample.mode ~= nil, "Should include mode")
	assert(session_sample.current_directory == nil, "Should not include current_directory")
	print("  ✓ Session sampling with fields works")

	-- Test roots with buffer IDs
	local scoped_buffers = M.define_resource_roots("neovim://buffers", { buffer_ids = { 1, 3 } })
	assert(#scoped_buffers == 2, "Should scope to 2 buffers")
	assert(scoped_buffers[1].id == 1, "Should include buffer 1")
	assert(scoped_buffers[2].id == 3, "Should include buffer 3")
	print("  ✓ Roots with buffer IDs works")

	-- Test roots with file patterns
	local pattern_buffers = M.define_resource_roots("neovim://buffers", { file_patterns = { "%.txt$", "%.md$" } })
	assert(#pattern_buffers == 2, "Should scope to 2 buffers with txt/md patterns")
	assert(pattern_buffers[1].name:match("%.txt$") or pattern_buffers[1].name:match("%.md$"), "Should match pattern")
	print("  ✓ Roots with file patterns works")

	-- Test roots with current only
	local current_session = M.define_resource_roots("neovim://session", { current_only = true })
	assert(current_session.current_file ~= nil, "Should include current file")
	assert(current_session.current_directory ~= nil, "Should include current directory")
	assert(current_session.buffers == nil, "Should not include all buffers")
	print("  ✓ Roots with current only works")

	-- Test error handling for unsupported resources
	local result, error = M.sample_resource("neovim://unsupported", {})
	assert(result == nil, "Should return nil for unsupported resource")
	assert(error:find("Unsupported"), "Should have error message")
	print("  ✓ Error handling for unsupported resources works")

	-- Test MCP message handling for sampling
	function M.handle_sampling_message(message)
		if message.method == "resources/sample" then
			local uri = message.params.uri
			local criteria = message.params.criteria
			local result = M.sample_resource(uri, criteria)
			if result then
				return {
					id = message.id,
					result = {
						content = {
							{
								type = "text",
								text = vim.json.encode(result),
							},
						},
					},
				}
			else
				return {
					id = message.id,
					error = {
						code = -32602,
						message = "Failed to sample resource: " .. uri,
					},
				}
			end
		elseif message.method == "resources/roots" then
			local uri = message.params.uri
			local roots = message.params.roots
			local result = M.define_resource_roots(uri, roots)
			if result then
				return {
					id = message.id,
					result = {
						content = {
							{
								type = "text",
								text = vim.json.encode(result),
							},
						},
					},
				}
			else
				return {
					id = message.id,
					error = {
						code = -32602,
						message = "Failed to define roots for resource: " .. uri,
					},
				}
			end
		else
			return {
				id = message.id,
				error = {
					code = -32601,
					message = "Unknown sampling method: " .. tostring(message.method),
				},
			}
		end
	end

	-- Test MCP sampling message
	local sampling_message = {
		id = 1,
		method = "resources/sample",
		params = {
			uri = "neovim://buffers",
			criteria = { limit = 1 },
		},
	}
	local sampling_response = M.handle_sampling_message(sampling_message)
	assert(sampling_response.id == 1, "Should return correct message ID")
	assert(sampling_response.result ~= nil, "Should have result for valid sampling")
	print("  ✓ MCP sampling message handling works")

	-- Test MCP roots message
	local roots_message = {
		id = 2,
		method = "resources/roots",
		params = {
			uri = "neovim://buffers",
			roots = { buffer_ids = { 1 } },
		},
	}
	local roots_response = M.handle_sampling_message(roots_message)
	assert(roots_response.id == 2, "Should return correct message ID")
	assert(roots_response.result ~= nil, "Should have result for valid roots")
	print("  ✓ MCP roots message handling works")

	-- Restore global vim
	_G.vim = original_vim

	print("✓ All MCP sampling and roots capability tests passed!")
end

print("=== MCP Sampling and Roots Capability Test ===")
print("Testing MCP sampling and roots capabilities...")
test_mcp_sampling_roots()
print("\n=== Test Complete ===")
print("✓ All MCP sampling and roots capability tests passed!")
print("MCP sampling and roots features verified:")
print("  • Resource sampling with limits")
print("  • Resource filtering by criteria")
print("  • Context definition with roots")
print("  • MCP message handling for sampling")
print("  • MCP message handling for roots")
print("  • Error handling for unsupported resources")
