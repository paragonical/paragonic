--[[
Debug test for plugin context
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Mock vim functions
vim = {
	json = {
		encode = function(obj)
			if type(obj) == "table" then
				local parts = {}
				for k, v in pairs(obj) do
					local key_str = string.format('"%s"', k)
					local value_str
					if type(v) == "string" then
						value_str = string.format('"%s"', v)
					elseif type(v) == "table" then
						if #v > 0 then
							local array_parts = {}
							for i, val in ipairs(v) do
								if type(val) == "string" then
									table.insert(array_parts, string.format('"%s"', val))
								else
									table.insert(array_parts, tostring(val))
								end
							end
							value_str = "[" .. table.concat(array_parts, ",") .. "]"
						else
							value_str = "[]"
						end
					else
						value_str = tostring(v)
					end
					table.insert(parts, key_str .. ":" .. value_str)
				end
				return "{" .. table.concat(parts, ",") .. "}"
			else
				return tostring(obj)
			end
		end,
		decode = function(str)
			print("DEBUG: Decoding JSON: " .. str)
			-- Use real JSON decoder if available
			if _G.vim and _G.vim.json and _G.vim.json.decode then
				local success, result = pcall(_G.vim.json.decode, str)
				if success then
					return result
				end
			end
			-- Try using cjson if available
			local cjson_ok, cjson = pcall(require, "cjson")
			if cjson_ok then
				local success, result = pcall(cjson.decode, str)
				if success then
					return result
				end
			end
			-- Try using dkjson if available
			local dkjson_ok, dkjson = pcall(require, "dkjson")
			if dkjson_ok then
				local success, result = pcall(dkjson.decode, str)
				if success then
					return result
				end
			end
			-- Fallback to simple parsing for the specific response format
			if str:find('"result"%s*:%s*"') then
				-- Extract the JSON string from the result field
				local result_start = str:find('"result"%s*:%s*"') + 8
				local result_end = str:find('"%s*,%s*"id"', result_start) - 1
				local result_value = str:sub(result_start, result_end)

				-- Remove any leading/trailing whitespace and quotes
				result_value = result_value:gsub('^%s*"*', ""):gsub('"*%s*$', "")

				-- Remove any leading colon if present
				result_value = result_value:gsub("^:", "")

				return {
					jsonrpc = "2.0",
					result = result_value,
					id = 1,
				}
			elseif str:find('"result"') then
				return { result = "test_response" }
			else
				return { error = "parse_error" }
			end
		end,
	},
	api = {
		nvim_list_bufs = function()
			return {}
		end,
		nvim_get_current_buf = function()
			return 1
		end,
		nvim_buf_get_name = function()
			return "test.lua"
		end,
		nvim_buf_get_lines = function()
			return {}
		end,
		nvim_buf_set_lines = function() end,
		nvim_buf_is_valid = function()
			return true
		end,
		nvim_buf_get_option = function()
			return true
		end,
		nvim_set_current_buf = function() end,
		nvim_win_get_cursor = function()
			return { 1, 0 }
		end,
		nvim_win_set_cursor = function() end,
		nvim_list_wins = function()
			return { 1 }
		end,
		nvim_win_get_buf = function()
			return 1
		end,
		nvim_get_mode = function()
			return { mode = "n" }
		end,
		nvim_create_buf = function()
			return 1
		end,
		nvim_buf_set_name = function() end,
		nvim_buf_set_option = function() end,
		nvim_open_win = function()
			return 1
		end,
		nvim_command = function() end,
		nvim_create_user_command = function() end,
	},
	o = {
		columns = 80,
		lines = 24,
	},
	notify = function(msg, level)
		print("NOTIFY [" .. (level or "INFO") .. "]: " .. msg)
	end,
	log = {
		levels = {
			DEBUG = 0,
			INFO = 1,
			WARN = 2,
			ERROR = 3,
		},
	},
	keymap = {
		set = function() end,
	},
	tbl_deep_extend = function(mode, ...)
		local result = {}
		for i = 1, select("#", ...) do
			local tbl = select(i, ...)
			if tbl then
				for k, v in pairs(tbl) do
					result[k] = v
				end
			end
		end
		return result
	end,
	fn = {
		stdpath = function(path)
			return "/tmp/paragonic_test"
		end,
		mkdir = function(dir, mode)
			return 1
		end,
		filereadable = function(file)
			return 0
		end,
		readfile = function(file)
			return {}
		end,
		writefile = function(lines, file)
			return 0
		end,
	},
}

-- Test the plugin initialization and RPC client
local function test_plugin_rpc()
	print("Testing plugin RPC client...")

	local paragonic = require("paragonic")

	-- Initialize the plugin
	paragonic.setup()

	-- Get the RPC client
	local rpc_client = paragonic._get_rpc_client()
	if rpc_client then
		print("✓ RPC client created")
		print("Connected: " .. tostring(rpc_client:is_connected()))

		-- Test hello
		local hello_response = rpc_client:hello()
		print("Hello response: " .. tostring(hello_response))

		-- Test chat completion directly
		local chat_response = rpc_client:chat_completion("llama2", "Hello test")
		print("Chat completion response: " .. tostring(chat_response))

		if chat_response then
			local success, parsed = pcall(vim.json.decode, chat_response)
			if success and parsed then
				print("✓ Chat response parsed successfully")
				print("Response type: " .. type(parsed.result))
				print("Response value: " .. tostring(parsed.result))
			else
				print("✗ Failed to parse chat response")
			end
		else
			print("✗ No chat completion response")
		end
	else
		print("✗ No RPC client available")
	end
end

-- Test the send_message function step by step
local function test_send_message_step_by_step()
	print("\nTesting send_message step by step...")

	local paragonic = require("paragonic")

	-- Get RPC client
	local rpc_client = paragonic._get_rpc_client()
	if not rpc_client then
		print("✗ No RPC client available")
		return
	end

	print("✓ RPC client available")

	-- Call chat completion directly
	local response = rpc_client:chat_completion("llama2", "Hello, this is a test message")
	if not response then
		print("✗ No response from chat completion")
		return
	end

	print("✓ Raw response: " .. tostring(response))

	-- Parse JSON response
	local parsed_response = paragonic.parse_json_response(response)
	if not parsed_response then
		print("✗ Failed to parse JSON response")
		return
	end

	print("✓ Parsed response: " .. tostring(parsed_response))
	print("Result type: " .. type(parsed_response.result))
	print("Result value: " .. tostring(parsed_response.result))

	-- Try to extract content
	if parsed_response.result and type(parsed_response.result) == "string" then
		print("Result is a string, trying to parse it...")
		local success, inner_result = pcall(vim.json.decode, parsed_response.result)
		if success and inner_result then
			print("✓ Inner result parsed: " .. tostring(inner_result))
			if inner_result.message and inner_result.message.content then
				print("SUCCESS! Content: " .. inner_result.message.content)
			else
				print("✗ No message content in inner result")
			end
		else
			print("✗ Failed to parse inner result: " .. tostring(inner_result))
		end
	end
end

-- Run tests
print("=== Plugin Debug Test ===")
test_plugin_rpc()
test_send_message_step_by_step()
print("\n=== Plugin Debug Test Complete ===")
