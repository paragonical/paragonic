--[[
Paragonic Chat Module
Handles chat interface and message sending functionality
--]]

local M = {}

-- Disable debug notifications by default to reduce noise
local debug = require("paragonic.debug")
debug.disable_notifications()

-- Shared on_chunk handler for streaming responses
-- @param current_buf number - The buffer to write to
-- @param line_num number - The line number to start writing from
-- @param chat_window_id number - The window ID for safe cursor positioning
-- @param enable_debug boolean - Whether to enable debug output
-- @return function - The on_chunk callback function
local function create_shared_on_chunk_handler(current_buf, line_num, chat_window_id, enable_debug)
	local response_content = ""
	local response_lines = {}
	local start_time = vim.uv.now()
	
	return function(chunk, chunk_index, total_chunks, chunk_type)
		-- Add chunk to response content
		response_content = response_content .. chunk
		
		-- Debug output if enabled
		if enable_debug then
			local chunk_index_str = chunk_index and tostring(chunk_index) or "unknown"
			local total_chunks_str = total_chunks and tostring(total_chunks) or "unknown"
			vim.notify("CALLBACK: Processing chunk " .. chunk_index_str .. " (type: " .. chunk_type .. ")", vim.log.levels.INFO)
			
			local ok, debug = pcall(require, "paragonic.debug")
			if ok then
				debug.debug_print("🔄 Processing chunk " .. chunk_index_str .. " of " .. total_chunks_str .. " (type: " .. chunk_type .. ")", "debug")
			end
		end
		
		-- Process thinking content with proper formatting
		if chunk_type == "thinking_start" then
			-- Start thinking section
			table.insert(response_lines, "🧠  <think>")
			if enable_debug then
				local ok, debug = pcall(require, "paragonic.debug")
				if ok then
					debug.debug_print("🧠 Added thinking_start line", "debug")
				end
			end
		elseif chunk_type == "thinking_content" then
			-- Add thinking step with proper wrapping and zigzag prefix
			local utils = require("paragonic.utils")
			-- Safely get buffer width from the stored window ID
			local full_buffer_width = 80 -- Default width
			if chat_window_id and vim.api.nvim_win_is_valid(chat_window_id) then
				full_buffer_width = vim.api.nvim_win_get_width(chat_window_id)
			end
			local base_width = math.floor(full_buffer_width * 0.7)
			if base_width < 20 then base_width = 20 end
			
			-- Debug: Check if chunk is valid
			if enable_debug then
				local ok, debug = pcall(require, "paragonic.debug")
				if ok then
					debug.debug_print("🧠 Processing thinking_content chunk: " .. string.format("%q", chunk), "debug")
				end
			end
			
			local wrapped_lines = utils.wrap_text_with_zigzag(chunk, base_width)
			for _, line in ipairs(wrapped_lines) do
				table.insert(response_lines, line)
			end
			if enable_debug then
				local ok, debug = pcall(require, "paragonic.debug")
				if ok then
					debug.debug_print("🧠 Added " .. #wrapped_lines .. " thinking_content lines", "debug")
				end
			end
		elseif chunk_type == "thinking_end" then
			-- End thinking section
			table.insert(response_lines, "󱦟  </think>")
			if enable_debug then
				local ok, debug = pcall(require, "paragonic.debug")
				if ok then
					debug.debug_print("🧠 Added thinking_end line", "debug")
				end
			end
		elseif chunk_type == "regular_content" then
			-- Add regular content with single diamond prefix (only first line gets diamond)
			local utils = require("paragonic.utils")
			-- Safely get buffer width from the stored window ID
			local full_buffer_width = 80 -- Default width
			if chat_window_id and vim.api.nvim_win_is_valid(chat_window_id) then
				full_buffer_width = vim.api.nvim_win_get_width(chat_window_id)
			end
			local base_width = math.floor(full_buffer_width * 0.7)
			if base_width < 20 then base_width = 20 end
			
			-- Debug: Check if chunk is valid
			if enable_debug then
				local ok, debug = pcall(require, "paragonic.debug")
				if ok then
					debug.debug_print("◊ Processing regular_content chunk: " .. string.format("%q", chunk), "debug")
				end
			end
			
			local wrapped_lines = utils.wrap_text_with_single_diamond(chunk, base_width)
			for _, line in ipairs(wrapped_lines) do
				table.insert(response_lines, line)
			end
			if enable_debug then
				local ok, debug = pcall(require, "paragonic.debug")
				if ok then
					debug.debug_print("◊ Added " .. #wrapped_lines .. " regular_content lines", "debug")
				end
			end
		else
			-- Default chunk handling - treat as regular content with single diamond
			local utils = require("paragonic.utils")
			-- Safely get buffer width from the stored window ID
			local full_buffer_width = 80 -- Default width
			if chat_window_id and vim.api.nvim_win_is_valid(chat_window_id) then
				full_buffer_width = vim.api.nvim_win_get_width(chat_window_id)
			end
			local base_width = math.floor(full_buffer_width * 0.7)
			if base_width < 20 then base_width = 20 end
			
			local wrapped_lines = utils.wrap_text_with_single_diamond(chunk, base_width)
			for _, line in ipairs(wrapped_lines) do
				table.insert(response_lines, line)
			end
			if enable_debug then
				local ok, debug = pcall(require, "paragonic.debug")
				if ok then
					debug.debug_print("◊ Added " .. #wrapped_lines .. " default content lines", "debug")
				end
			end
		end
		
		-- Update the buffer in real-time
		local current_response_lines = {}
		for _, line in ipairs(response_lines) do
			table.insert(current_response_lines, line)
		end
		
		-- Add timing placeholder
		table.insert(current_response_lines, " ⏱️   ...")
		table.insert(current_response_lines, "∎")
		
		-- Insert/update response in buffer
		vim.api.nvim_buf_set_lines(current_buf, line_num + 2, line_num + 2 + #current_response_lines, false, current_response_lines)
		
		-- Force redraw for smooth animation
		vim.cmd("redraw!")
		
		-- Move cursor to the end of the buffer (safely handle window changes)
		local buffer_line_count = vim.api.nvim_buf_line_count(current_buf)
		-- Check if the chat window still exists and is valid
		local window_exists = pcall(function()
			return vim.api.nvim_win_is_valid(chat_window_id)
		end)
		
		if window_exists and vim.api.nvim_win_is_valid(chat_window_id) then
			-- Check if the window is still showing the chat buffer
			local window_buf = vim.api.nvim_win_get_buf(chat_window_id)
			if window_buf == current_buf then
				vim.api.nvim_win_set_cursor(chat_window_id, { buffer_line_count, 0 })
			end
		else
			-- Fallback to current window
			vim.api.nvim_win_set_cursor(0, { buffer_line_count, 0 })
		end
	end, function() -- on_complete callback
		-- Calculate timing information
		local end_time = vim.uv.now()
		local duration_ms = end_time - start_time
		local duration_sec = duration_ms / 1000
		
		-- Update timing in the last response
		local final_response_lines = {}
		for _, line in ipairs(response_lines) do
			table.insert(final_response_lines, line)
		end
		
		-- Add timing information
		table.insert(final_response_lines, "")
		table.insert(final_response_lines, " ⏱️   " .. string.format("%.2fs", duration_sec))
		table.insert(final_response_lines, "")
		table.insert(final_response_lines, "∎")
		
		-- Update buffer with final response
		vim.api.nvim_buf_set_lines(current_buf, line_num + 2, line_num + 2 + #final_response_lines, false, final_response_lines)
		
		-- Move cursor to the end of the buffer (safely handle window changes)
		local buffer_line_count = vim.api.nvim_buf_line_count(current_buf)
		-- Check if the chat window still exists and is valid
		local window_exists = pcall(function()
			return vim.api.nvim_win_is_valid(chat_window_id)
		end)
		
		if window_exists and vim.api.nvim_win_is_valid(chat_window_id) then
			-- Check if the window is still showing the chat buffer
			local window_buf = vim.api.nvim_win_get_buf(chat_window_id)
			if window_buf == current_buf then
				vim.api.nvim_win_set_cursor(chat_window_id, { buffer_line_count, 0 })
			end
		else
			-- Fallback to current window
			vim.api.nvim_win_set_cursor(0, { buffer_line_count, 0 })
		end
		
		-- Debug success notification
		if enable_debug then
			vim.notify("Thinking streaming completed successfully", vim.log.levels.INFO)
		end
		
		-- Auto-fold thinking content when complete
		M.fold_thinking_content(current_buf, line_num)
	end
end

-- Command to toggle debug notifications
function M.toggle_debug_notifications()
	local config = debug.get_debug_config()
	if config.show_notifications then
		debug.disable_notifications()
		vim.notify("Debug notifications disabled", vim.log.levels.INFO)
	else
		debug.enable_notifications()
		vim.notify("Debug notifications enabled", vim.log.levels.INFO)
	end
end

-- Helper function to extract text backward from cursor to previous tombstone
-- This enables multi-line input by capturing all lines from the cursor
-- position back to the previous ∎ tombstone marker
local function extract_backward_to_tombstone(current_buf)
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local cursor_line = cursor_pos[1] - 1 -- Convert to 0-indexed

	-- Debug: Print cursor position
	debug.debug_print("🔍 extract_backward_to_tombstone: cursor_line = " .. cursor_line, "debug")

	-- Get all lines from start of buffer to cursor line
	local all_lines = vim.api.nvim_buf_get_lines(current_buf, 0, cursor_line + 1, false)

	-- Debug: Print buffer content
	debug.debug_print("🔍 Buffer lines (0 to " .. cursor_line .. "):", "debug")
	for i, line in ipairs(all_lines) do
		debug.debug_print("  Line " .. (i - 1) .. ": " .. string.format("%q", line), "debug")
	end

	-- Find the last tombstone marker (∎) before the cursor
	local tombstone_line = -1
	for i = cursor_line, 0, -1 do
		local line = all_lines[i + 1] -- Convert back to 1-indexed for array access
		if line and line:match("^%s*∎%s*$") then
			tombstone_line = i
			debug.debug_print("🔍 Found tombstone at line " .. i, "debug")
			break
		end
	end

	debug.debug_print("🔍 tombstone_line = " .. tombstone_line, "debug")

	-- Extract lines from after the tombstone to the cursor
	local message_lines = {}
	local start_line = tombstone_line + 1

	debug.debug_print("🔍 Extracting from line " .. start_line .. " to " .. cursor_line, "debug")

	for i = start_line, cursor_line do
		local line = all_lines[i + 1] -- Convert to 1-indexed for array access
		if line then
			-- Skip empty lines at the beginning but include them in the middle/end
			if #message_lines > 0 or line:match("%S") then
				table.insert(message_lines, line)
				debug.debug_print("🔍 Added line: " .. string.format("%q", line), "debug")
			else
				debug.debug_print("🔍 Skipped empty line: " .. string.format("%q", line), "debug")
			end
		end
	end

	-- Join the lines and trim leading/trailing whitespace
	local message = table.concat(message_lines, "\n"):gsub("^%s+", ""):gsub("%s+$", "")

	debug.debug_print("🔍 Final extracted message: " .. string.format("%q", message), "debug")

	return message, start_line
end

-- Helper function to extract text forward from cursor to next tombstone or end of buffer
local function extract_forward_to_tombstone(current_buf)
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local cursor_line = cursor_pos[1] - 1 -- Convert to 0-indexed
	local total_lines = vim.api.nvim_buf_line_count(current_buf)

	-- Get all lines from cursor to end of buffer
	local all_lines = vim.api.nvim_buf_get_lines(current_buf, cursor_line, total_lines, false)

	-- Find the next tombstone marker
	local end_line = #all_lines
	for i = 1, #all_lines do
		if all_lines[i]:match("^%s*∎%s*$") then
			end_line = i - 1 -- Stop before the tombstone
			break
		end
	end

	-- Extract lines from cursor to next tombstone (or end of buffer)
	local message_lines = {}
	for i = 1, end_line do
		table.insert(message_lines, all_lines[i])
	end

	return table.concat(message_lines, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
end

-- Helper function to extract complete range from previous tombstone to next tombstone
local function extract_complete_range(current_buf)
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local cursor_line = cursor_pos[1] - 1 -- Convert to 0-indexed
	local total_lines = vim.api.nvim_buf_line_count(current_buf)

	-- Get all lines in buffer
	local all_lines = vim.api.nvim_buf_get_lines(current_buf, 0, total_lines, false)

	-- Find previous tombstone (search backward from cursor)
	local start_line = 1 -- Default to start of buffer (1-indexed for line extraction)
	for i = cursor_line, 1, -1 do
		if all_lines[i] and all_lines[i]:match("^%s*∎%s*$") then
			start_line = i + 1 -- Start after the tombstone
			break
		end
	end

	-- Find next tombstone (search forward from cursor)
	local end_line = total_lines -- Default to end of buffer
	for i = cursor_line + 1, total_lines do
		if all_lines[i] and all_lines[i]:match("^%s*∎%s*$") then
			end_line = i - 1 -- Stop before the tombstone
			break
		end
	end

	-- Extract lines from start to end
	local message_lines = {}
	for i = start_line, end_line do
		if all_lines[i] then
			table.insert(message_lines, all_lines[i])
		end
	end

	return table.concat(message_lines, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
end

-- Send a message to the AI and get response
function M.send_message(message, model)
	local backend = require("paragonic.backend")
	local rpc_client = backend._get_rpc_client()
	if not rpc_client then
		-- Try to initialize backend if not available
		if not backend.initialize_backend() then
			return nil, "Backend not available"
		end
		rpc_client = backend._get_rpc_client()
	end

	-- Use default model if not specified
	local config = require("paragonic.config")
	model = model or config.get("ollama_model") or "deepseek-r1:1.5b"

	-- Send chat completion request
	local response = rpc_client:chat_completion(model, message)
	if not response then
		return nil, "Failed to get response from AI"
	end

	-- Parse JSON response using enhanced parser
	local utils = require("paragonic.utils")
	local parsed_response = utils.parse_json_response_enhanced(response)
	if not parsed_response then
		return nil, "Failed to parse AI response"
	end

	-- Check for error in response
	if parsed_response.error then
		return nil, "AI error: " .. (parsed_response.error.message or "Unknown error")
	end

	-- Extract AI message content
	-- Handle different response formats:
	-- 1. JSON-RPC result wrapper with JSON string: {result: "{\"message\":{\"content\":\"...\"}}"}
	-- 2. JSON-RPC result wrapper: {result: {message: {content: "..."}}}
	-- 3. Direct Ollama response: {message: {content: "..."}}
	-- 4. Direct content: {content: "..."}

	if parsed_response.result then
		-- Check if result is a JSON string (from backend)
		if type(parsed_response.result) == "string" then
			-- Try using cjson if available
			local cjson_ok, cjson = pcall(require, "cjson")
			if cjson_ok then
				local success, inner_result = pcall(cjson.decode, parsed_response.result)
				if success and inner_result and inner_result.message then
					return inner_result.message.content
				end
			end
			-- Try using dkjson if available
			local dkjson_ok, dkjson = pcall(require, "dkjson")
			if dkjson_ok then
				local success, inner_result = pcall(dkjson.decode, parsed_response.result)
				if success and inner_result and inner_result.message then
					return inner_result.message.content
				end
			end
			-- Fallback to vim.json.decode
			local success, inner_result = pcall(vim.json.decode, parsed_response.result)
			if success and inner_result and inner_result.message then
				return inner_result.message.content
			end
		end

		-- Check if result is a table with message
		if type(parsed_response.result) == "table" and parsed_response.result.message then
			return parsed_response.result.message.content
		end

		-- Check if result is a table with content
		if type(parsed_response.result) == "table" and parsed_response.result.content then
			return parsed_response.result.content
		end
	end

	if parsed_response.message then
		return parsed_response.message.content
	end

	if parsed_response.content then
		return parsed_response.content
	end

	return nil, "Unexpected response format: " .. tostring(parsed_response)
end

-- Send message with server-side formatting
function M.send_message_formatted(message, model, format_config)
	local debug = require("paragonic.debug")
	debug.debug_print("🚀 send_message_formatted() called", "debug")
	debug.debug_print("🔧 Message: " .. string.format("%q", message), "debug")
	debug.debug_print("🔧 Model: " .. tostring(model), "debug")

	local backend = require("paragonic.backend")
	local rpc_client = backend._get_rpc_client()

	debug.debug_print("🔍 rpc_client: " .. tostring(rpc_client ~= nil), "debug")

	if not rpc_client then
		debug.debug_print("🔧 Backend not available, initializing...", "debug")
		-- Try to initialize backend if not available
		if not backend.initialize_backend() then
			debug.debug_print("❌ Backend initialization failed", "error")
			return nil, "Backend not available"
		end
		rpc_client = backend._get_rpc_client()
		debug.debug_print("🔍 rpc_client after init: " .. tostring(rpc_client ~= nil), "debug")
	end

	-- Use default model if not specified
	local config = require("paragonic.config")
	model = model or config.get("ollama_model") or "deepseek-r1:1.5b"

	-- Set default format configuration if not provided
	format_config = format_config
		or {
			max_width = 80,
			include_diamond = true,
			continuation_indent = 3,
			format_markdown = true,
			preserve_paragraphs = true,
		}

	-- Send formatted chat completion request
	debug.debug_print("🔧 About to call rpc_client:formatted_chat_completion", "debug")
	local response = rpc_client:formatted_chat_completion(model, message, format_config)

	debug.debug_print("🔍 Response: " .. tostring(response ~= nil), "debug")
	if response then
		debug.debug_print("🔍 Response type: " .. type(response), "debug")
		debug.debug_print("🔍 Response preview: " .. string.format("%q", tostring(response):sub(1, 100)), "debug")
	end

	if not response then
		debug.debug_print("❌ No response from AI", "error")
		return nil, "Failed to get response from AI"
	end

	-- Parse JSON response using enhanced parser
	local utils = require("paragonic.utils")
	local parsed_response = utils.parse_json_response_enhanced(response)
	if not parsed_response then
		return nil, "Failed to parse AI response"
	end

	-- Check for error in response
	if parsed_response.error then
		return nil, "AI error: " .. (parsed_response.error.message or "Unknown error")
	end

	-- Extract formatted content from response
	if parsed_response.result then
		-- Check if result is a JSON string (from backend)
		if type(parsed_response.result) == "string" then
			-- Try using cjson if available
			local cjson_ok, cjson = pcall(require, "cjson")
			if cjson_ok then
				local success, inner_result = pcall(cjson.decode, parsed_response.result)
				if success and inner_result and inner_result.formatted_content then
					return inner_result.formatted_content, inner_result.original_content, inner_result.duration_sec
				end
			end
			-- Try using dkjson if available
			local dkjson_ok, dkjson = pcall(require, "dkjson")
			if dkjson_ok then
				local success, inner_result = pcall(dkjson.decode, parsed_response.result)
				if success and inner_result and inner_result.formatted_content then
					return inner_result.formatted_content, inner_result.original_content, inner_result.duration_sec
				end
			end
			-- Fallback to vim.json.decode
			local success, inner_result = pcall(vim.json.decode, parsed_response.result)
			if success and inner_result and inner_result.formatted_content then
				return inner_result.formatted_content, inner_result.original_content, inner_result.duration_sec
			end
		end

		-- Check if result is a table with formatted_content
		if type(parsed_response.result) == "table" and parsed_response.result.formatted_content then
			return parsed_response.result.formatted_content,
				parsed_response.result.original_content,
				parsed_response.result.duration_sec
		end
	end

	return nil, "Unexpected response format: " .. tostring(parsed_response)
end

-- Enhanced send message with improved response parsing
function M.send_message_enhanced(message, model)
	local backend = require("paragonic.backend")
	local rpc_client = backend._get_rpc_client()
	if not rpc_client then
		return nil, "Backend not available"
	end

	-- Use default model if not specified
	local config = require("paragonic.config")
	model = model or config.get("ollama_model") or "deepseek-r1:1.5b"

	-- Send chat completion request
	local response, err = rpc_client:chat_completion(model, message)
	if err then
		return nil, "Failed to get response from AI: " .. tostring(err)
	end

	if not response then
		return nil, "Failed to get response from AI: no response"
	end

	-- Debug: Log the actual response structure
	local debug = require("paragonic.debug")
	debug.debug_print("Response type: " .. type(response), "debug")
	if type(response) == "table" then
		debug.debug_print("Response keys: " .. table.concat(vim.tbl_keys(response), ", "), "debug")
		if response.result then
			debug.debug_print("Result type: " .. type(response.result), "debug")
			if type(response.result) == "table" then
				debug.debug_print("Result keys: " .. table.concat(vim.tbl_keys(response.result), ", "), "debug")
			end
		end
	end
	-- Sanitize response preview to avoid newlines
	local response_str = tostring(response):gsub("\n", "\\n"):gsub("\r", "\\r")
	debug.debug_print("Response preview: " .. response_str:sub(1, 200), "debug")

	-- Check for error in response (response is already a parsed Lua table)
	if response.error then
		return nil, "AI error: " .. (response.error.message or "Unknown error")
	end

	-- Extract AI message content
	-- Handle different response formats:
	-- 1. JSON-RPC result wrapper with JSON string: {result: "{\"message\":{\"content\":\"...\"}}"}
	-- 2. JSON-RPC result wrapper: {result: {message: {content: "..."}}}
	-- 3. Direct Ollama response: {message: {content: "..."}}
	-- 4. Direct content: {content: "..."}

	if response.result then
		-- Check if result is a JSON string (from backend)
		if type(response.result) == "string" then
			-- Try using cjson if available
			local cjson_ok, cjson = pcall(require, "cjson")
			if cjson_ok then
				local success, inner_result = pcall(cjson.decode, response.result)
				if success and inner_result and inner_result.message then
					return inner_result.message.content
				end
			end
			-- Try using dkjson if available
			local dkjson_ok, dkjson = pcall(require, "dkjson")
			if dkjson_ok then
				local success, inner_result = pcall(dkjson.decode, response.result)
				if success and inner_result and inner_result.message then
					return inner_result.message.content
				end
			end
			-- Fallback to vim.json.decode
			local success, inner_result = pcall(vim.json.decode, response.result)
			if success and inner_result and inner_result.message then
				return inner_result.message.content
			end
		end

		-- Check if result is a table with message
		if type(response.result) == "table" and response.result.message then
			return response.result.message.content
		end

		-- Check if result is a table with content
		if type(response.result) == "table" and response.result.content then
			return response.result.content
		end

		-- Check if result is a table with completion (MCP format)
		if type(response.result) == "table" and response.result.completion then
			return response.result.completion
		end
	end

	if response.message then
		return response.message.content
	end

	if response.content then
		return response.content
	end

	return nil, "Unexpected response format: " .. tostring(response)
end

-- Open chat interface
function M.open_chat()
	-- Check if chat buffer already exists
	local chat_buf = nil
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local name = vim.api.nvim_buf_get_name(buf)
		if name == "paragonic://chat" then
			chat_buf = buf
			break
		end
	end

	-- Create new buffer if it doesn't exist
	if not chat_buf then
		chat_buf = vim.api.nvim_create_buf(true, true)

		-- Set buffer name
		vim.api.nvim_buf_set_name(chat_buf, "paragonic://chat")

		-- Set buffer options
		vim.api.nvim_buf_set_option(chat_buf, "buftype", "nofile")
		vim.api.nvim_buf_set_option(chat_buf, "swapfile", false)
		vim.api.nvim_buf_set_option(chat_buf, "modifiable", true)

		-- Add initial content with default model information
		vim.api.nvim_buf_set_lines(chat_buf, 0, -1, false, {
			"# Paragonic Chat",
			"Multi-line input extraction modes:",
			"• <CR>: Send message (smart - auto-detects model capabilities)",
			"• <leader>b: Send backward only (cursor to previous ∎)",
			"• <leader>f: Send forward only (cursor to next ∎ or end)",
			"• <leader><CR>: Send with debug output",
			"∎",
			"",
		})

		-- Models info will be updated when user first interacts with the chat
		-- This prevents freezing during buffer creation

		-- Set filetype for syntax highlighting
		vim.api.nvim_buf_set_option(chat_buf, "filetype", "markdown")

		-- Set up buffer-local commands for different extraction modes
		vim.api.nvim_buf_set_keymap(
			chat_buf,
			"n",
			"<CR>",
			":ParagonicSendSmart<CR>",
			{ noremap = true, silent = true, desc = "Send message (smart - auto-detects model capabilities)" }
		)
		
		-- TEST: Add notification to verify keymap is set
		vim.notify("TEST: Keymap <CR> set to ParagonicSendSmart", vim.log.levels.INFO)
		vim.api.nvim_buf_set_keymap(
			chat_buf,
			"n",
			"<leader>b",
			":ParagonicSendBackward<CR>",
			{ noremap = true, silent = true, desc = "Send backward to tombstone" }
		)
		vim.api.nvim_buf_set_keymap(
			chat_buf,
			"n",
			"<leader>f",
			":ParagonicSendForward<CR>",
			{ noremap = true, silent = true, desc = "Send forward to tombstone" }
		)
		vim.api.nvim_buf_set_keymap(
			chat_buf,
			"n",
			"<leader><CR>",
			":ParagonicSendDebug<CR>",
			{ noremap = true, silent = true, desc = "Send with debug output" }
		)
	end

	-- Get the width of the current window before splitting
	local original_width = vim.api.nvim_win_get_width(0)
	
	-- Open the buffer in a vertical split
	vim.api.nvim_command("vsplit")
	vim.api.nvim_set_current_buf(chat_buf)
	
	-- Set the width to 1/3 of the original window width
	local chat_width = math.floor(original_width / 3)
	vim.api.nvim_win_set_width(0, chat_width)

	-- Move cursor to the end of the buffer
	vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(0), 0 })
end

-- Enhanced send message command with debug messages
function M.send_message_command_debug()
	local current_buf = vim.api.nvim_get_current_buf()
	local buf_name = vim.api.nvim_buf_get_name(current_buf)

	-- Only work in chat buffer
	if buf_name ~= "paragonic://chat" then
		vim.notify("This command only works in the chat buffer", vim.log.levels.WARN)
		return
	end

	-- Extract multi-line message from cursor to previous tombstone
	local message, start_line = extract_backward_to_tombstone(current_buf)
	local line_num = vim.api.nvim_win_get_cursor(0)[1] - 1 -- Keep for insertion positioning

	-- Skip empty lines or lines that start with #
	if message == "" or message:match("^%s*#") then
		vim.notify("Please enter a message to send", vim.log.levels.INFO)
		return
	end

	-- Add immediate visual feedback that the chat is being sent
	local debug = require("paragonic.debug")
	debug.append_debug_message(current_buf, "Sending message to AI...", "info")

	-- Initialize backend if not available
	local backend = require("paragonic.backend")
	if not backend._rpc_client then
		debug.append_debug_message(current_buf, "🔧 Backend not available, starting initialization...", "info")
		debug.append_debug_message(current_buf, "🔧 Step 1: Creating RPC client...", "debug")

		local success = backend._initialize_backend()

		if not success then
			debug.append_debug_message(current_buf, "❌ Backend initialization failed", "error")
			vim.notify("Failed to send message: Backend initialization failed", vim.log.levels.ERROR)
			return
		else
			debug.append_debug_message(current_buf, "✅ Backend initialization completed", "success")
		end
	else
		debug.append_debug_message(current_buf, "✅ Backend already available", "info")
	end

	-- Check RPC client
	local rpc_client = backend._get_rpc_client()
	if not rpc_client then
		debug.append_debug_message(current_buf, "RPC client not available", "error")
		vim.notify("Failed to send message: Backend not available", vim.log.levels.ERROR)
		return
	end

	debug.append_debug_message(current_buf, "RPC client available", "info")

	-- Debug: Sending message
	debug.append_debug_message(current_buf, "Sending message: " .. message:sub(1, 50) .. "...", "debug")

	-- Start a progress indicator for long operations
	local progress_timer = nil
	local progress_count = 0
	local function update_progress()
		progress_count = progress_count + 1
		local dots = string.rep(".", progress_count % 4)
		debug.append_debug_message(current_buf, "⏳ Waiting for AI response" .. dots, "debug")
	end

	-- Start progress updates every 3 seconds for debug mode
	progress_timer = vim.loop.new_timer()
	progress_timer:start(3000, 3000, vim.schedule_wrap(update_progress))

	-- Record start time for timing information
	local start_time = vim.uv.now()
	
	-- Store the current window ID for later use in callbacks
	local chat_window_id = vim.api.nvim_get_current_win()

	-- Add zigzag arrow to indicate request is being sent
	vim.api.nvim_buf_set_lines(current_buf, line_num + 1, line_num + 1, false, { "↯" })

	-- Force buffer update to show zigzag immediately
	vim.api.nvim_buf_call(current_buf, function()
		vim.cmd("redraw!")
	end)

	-- Set up retry callback for RPC client
	if backend._rpc_client and backend._rpc_client.set_retry_callback then
		backend._rpc_client:set_retry_callback(function(attempt, max_attempts)
			-- Add retry notification to chat buffer
			vim.api.nvim_buf_set_lines(
				current_buf,
				line_num + 2,
				line_num + 2,
				false,
				{ "🔄 Retry attempt " .. attempt .. "/" .. max_attempts }
			)
		end)
	end

	-- Send the message using streaming thinking function for proper formatting
	local config = require("paragonic.config")
	local default_model = config.get("ollama_model") or "deepseek-r1:1.5b"
	
	-- Use shared on_chunk handler with debug enabled
	local on_chunk, on_complete = create_shared_on_chunk_handler(current_buf, line_num, chat_window_id, true)
	
	-- Use streaming thinking function
	local success, err = M.send_message_thinking_streaming(message, default_model, on_chunk, on_complete)
	
	-- Stop progress updates
	if progress_timer then
		progress_timer:stop()
		progress_timer:close()
	end
	
	if not success then
		debug.append_debug_message(current_buf, "Failed to send message: " .. tostring(err), "error")
		vim.notify("Failed to send message: " .. (err or "unknown error"), vim.log.levels.ERROR)
		
		-- Add error message to chat buffer with error symbol
		local error_lines = {
			"🛔  " .. (err or "unknown error"),
		}
		vim.api.nvim_buf_set_lines(current_buf, line_num + 2, line_num + 2, false, error_lines)
		return
	end
end

-- Send message command with server-side formatting
-- Send debug markdown test command
function M.send_debug_markdown_test()
	local current_buf = vim.api.nvim_get_current_buf()
	local buf_name = vim.api.nvim_buf_get_name(current_buf)

	-- Only work in chat buffer
	if buf_name ~= "paragonic://chat" then
		vim.notify("This command only works in the chat buffer", vim.log.levels.WARN)
		return
	end

	-- Get current cursor position
	local line_num = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 0-indexed

	-- Initialize backend if not available
	local backend = require("paragonic.backend")
	if not backend._rpc_client then
		if not backend.initialize_backend() then
			vim.notify("Failed to send debug test: Backend initialization failed", vim.log.levels.ERROR)
			return
		end
	end

	-- Get buffer width for formatting
	local buf_width = vim.api.nvim_win_get_width(0)

	-- Get RPC client
	local rpc_client = backend._get_rpc_client()
	if not rpc_client then
		vim.notify("Failed to send debug test: RPC client not available", vim.log.levels.ERROR)
		return
	end

	-- Add indicator that test is being sent
	vim.api.nvim_buf_set_lines(
		current_buf,
		line_num + 1,
		line_num + 1,
		false,
		{ "🧪 Sending debug markdown test..." }
	)

	-- Send the debug markdown test request
	local response, err = rpc_client:debug_markdown_test({
		max_width = buf_width - 5, -- Leave some margin
		include_diamond = true,
		continuation_indent = 3,
		format_markdown = true,
		preserve_paragraphs = true,
	})

	-- Remove the indicator line
	vim.api.nvim_buf_set_lines(current_buf, line_num + 1, line_num + 2, false, {})

	if not response then
		vim.notify("Failed to send debug test: " .. (err or "unknown error"), vim.log.levels.ERROR)
		vim.api.nvim_buf_set_lines(
			current_buf,
			line_num + 1,
			line_num + 1,
			false,
			{ "🛔 Debug test failed: " .. (err or "unknown error") }
		)
		return
	end

	-- Parse JSON response using enhanced parser (same as formatted_chat_completion)
	local utils = require("paragonic.utils")
	local parsed_response = utils.parse_json_response_enhanced(response)
	if not parsed_response then
		vim.notify("Failed to parse debug test response", vim.log.levels.ERROR)
		vim.api.nvim_buf_set_lines(
			current_buf,
			line_num + 1,
			line_num + 1,
			false,
			{ "🛔 Debug test failed: Failed to parse response" }
		)
		return
	end

	-- Check for error in response
	if parsed_response.error then
		local error_msg = parsed_response.error.message or "Unknown error"
		vim.notify("Debug test error: " .. error_msg, vim.log.levels.ERROR)
		vim.api.nvim_buf_set_lines(
			current_buf,
			line_num + 1,
			line_num + 1,
			false,
			{ "🛔 Debug test error: " .. error_msg }
		)
		return
	end

	-- Extract formatted content from response
	local formatted_content = nil
	if parsed_response.result then
		formatted_content = parsed_response.result
	end

	if not formatted_content then
		vim.notify("Debug test response missing result", vim.log.levels.ERROR)
		vim.api.nvim_buf_set_lines(
			current_buf,
			line_num + 1,
			line_num + 1,
			false,
			{ "🛔 Debug test failed: Missing result" }
		)
		return
	end

	-- Add debug test header
	vim.api.nvim_buf_set_lines(
		current_buf,
		line_num + 1,
		line_num + 1,
		false,
		{ "", "=== DEBUG MARKDOWN TEST RESPONSE ===" }
	)

	-- Split the formatted content into lines
	local response_lines = {}
	for line in formatted_content:gmatch("[^\r\n]+") do
		table.insert(response_lines, line)
	end

	-- If no lines were extracted, add the original response as a single line
	if #response_lines == 0 then
		table.insert(response_lines, formatted_content)
	end

	-- Add response to buffer
	vim.api.nvim_buf_set_lines(current_buf, line_num + 3, line_num + 3, false, response_lines)

	-- Add footer
	vim.api.nvim_buf_set_lines(
		current_buf,
		line_num + 3 + #response_lines,
		line_num + 3 + #response_lines,
		false,
		{ "=== END DEBUG TEST ===", "" }
	)

	-- Move cursor to end of added content
	local new_line_num = line_num + #response_lines + 6
	vim.api.nvim_win_set_cursor(0, { new_line_num, 0 })

	vim.notify("Debug markdown test completed - check formatting above", vim.log.levels.INFO)
end

-- Send a streaming message with real-time updates using brain symbol
function M.send_message_streaming(message, model, on_chunk, on_complete)
	local backend = require("paragonic.backend")
	local rpc_client = backend._get_rpc_client()
	if not rpc_client then
		-- Try to initialize backend if not available
		if not backend.initialize_backend() then
			return nil, "Backend not available - please ensure the Rust server is running"
		end
		rpc_client = backend._get_rpc_client()
	end

	-- Use default model if not specified
	local config = require("paragonic.config")
	model = model or config.get("ollama_model") or "deepseek-r1:1.5b"

	-- Start streaming chat completion
	local response, err = rpc_client:streaming_chat_completion({
		model = model,
		message = message,
		chunk_size = 30, -- Small chunks for smooth streaming
	})

	if err then
		return nil, "Failed to start streaming: " .. tostring(err)
	end

	if not response then
		return nil, "Failed to start streaming: no response"
	end

	-- Check for error in response (response is already a parsed Lua table)
	if response.error then
		return nil, "Streaming error: " .. (response.error.message or "Unknown error")
	end

	-- Set up non-blocking streaming with timers
	local max_wait_time = 30 -- seconds
	local check_interval = 100 -- milliseconds
	local total_wait_time = 0
	local chunks_received = 0
	local total_chunks = 0
	local streaming_complete = false
	
	-- Create a timer for non-blocking chunk checking
	local check_timer = vim.loop.new_timer()
	
	local function check_for_chunks()
		local chunks = rpc_client:get_streaming_chunks()
		if chunks and #chunks > 0 then
			-- Process all available chunks
			for _, chunk in ipairs(chunks) do
				chunks_received = chunks_received + 1
				
				-- Update total_chunks if provided
				if chunk.total_chunks then
					total_chunks = chunk.total_chunks
				end
				
				-- Process the chunk
				if on_chunk then
					local chunk_type = chunk.chunk_type or "regular_content"
					on_chunk(chunk.chunk, chunk.chunk_index, total_chunks, chunk_type)
				end
			end
			
			-- Check if we've received all chunks
			if total_chunks > 0 and chunks_received >= total_chunks then
				streaming_complete = true
				check_timer:stop()
				check_timer:close()
				if on_complete then
					on_complete()
				end
				return
			end
		end
		
		total_wait_time = total_wait_time + (check_interval / 1000)
		
		if total_wait_time >= max_wait_time then
			debug.debug_print("Timeout waiting for streaming chunks", "error")
			check_timer:stop()
			check_timer:close()
			if on_complete then
				on_complete()
			end
			return
		end
		
		-- Schedule next check
		check_timer:start(check_interval, 0, check_for_chunks)
	end
	
	-- Start the non-blocking chunk checking
	check_for_chunks()

	return true
end

-- Send a streaming message with thinking model support
-- Handles intermediate thinking output with <think></think> encapsulation
-- Uses brain symbol for first step, vertical ideographic iteration mark (〻) for successive steps
-- Implements Neovim folding for thinking steps
function M.send_message_thinking_streaming(message, model, on_chunk, on_complete)
	local backend = require("paragonic.backend")
	local rpc_client = backend._get_rpc_client()
	if not rpc_client then
		-- Try to initialize backend if not available
		if not backend.initialize_backend() then
			return nil, "Backend not available - please ensure the Rust server is running"
		end
		rpc_client = backend._get_rpc_client()
	end

	-- Use default model if not specified
	local config = require("paragonic.config")
	model = model or config.get("ollama_model") or "deepseek-r1:1.5b"

	-- Start streaming chat completion
	local response, err = rpc_client:streaming_chat_completion({
		model = model,
		message = message,
		chunk_size = 50, -- Larger chunks for thinking model
	})

	if err then
		return nil, "Failed to start streaming: " .. tostring(err)
	end

	if not response then
		return nil, "Failed to start streaming: no response"
	end

	-- Check for error in response (response is already a parsed Lua table)
	if response.error then
		return nil, "Streaming error: " .. (response.error.message or "Unknown error")
	end

	-- Debug: Log the response structure
	local debug = require("paragonic.debug")
	debug.debug_print("Response type: " .. type(response), "debug")
	if type(response) == "table" then
		debug.debug_print("Response keys: " .. table.concat(vim.tbl_keys(response), ", "), "debug")
		if response.result then
			debug.debug_print("Result type: " .. type(response.result), "debug")
			if type(response.result) == "table" then
				debug.debug_print("Result keys: " .. table.concat(vim.tbl_keys(response.result), ", "), "debug")
			end
		end
	end

	-- Process the first chunk from the immediate response
	-- Mark streaming as active to prevent reconnection conflicts
	rpc_client:set_streaming_active(true)
	
	-- Add first chunk to streaming buffer for consistent processing
	if response.chunk then
		debug.debug_print("Adding first chunk to streaming buffer: " .. (response.chunk_type or "unknown"), "debug")
		rpc_client:add_streaming_chunk(response)
	elseif response.result and response.result.chunk then
		debug.debug_print("Adding first chunk from result to streaming buffer: " .. (response.result.chunk_type or "unknown"), "debug")
		rpc_client:add_streaming_chunk(response.result)
	else
		debug.debug_print("No first chunk found in response", "debug")
	end

	-- Set up non-blocking streaming with timers
	local max_wait_time = 30 -- seconds
	local check_interval = 100 -- milliseconds
	local total_wait_time = 0
	local chunks_processed = 0
	local completion_detected = false
	
	-- Create a timer for non-blocking chunk checking
	local check_timer = vim.loop.new_timer()
	
		local function check_for_chunks()
			local chunks = rpc_client:get_streaming_chunks()
			debug.debug_print("Checking for chunks: " .. (chunks and #chunks or 0) .. " chunks found", "debug")
			
			-- Debug: Check if we're receiving any SSE data
			if rpc_client and rpc_client.is_connected then
				debug.debug_print("RPC client is connected, checking for new data", "debug")
			else
				debug.debug_print("RPC client is not connected", "debug")
			end
			
			-- Debug: Check SSE connection status and events
			local sse_client = require("paragonic.sse_client")
			if sse_client and sse_client.is_connected then
				debug.debug_print("SSE client is connected", "debug")
				-- Check if there are any SSE events in the buffer
				local events = sse_client.get_event_buffer()
				if events and #events > 0 then
					debug.debug_print("SSE event buffer has " .. #events .. " events", "debug")
					for i, event in ipairs(events) do
						debug.debug_print("SSE Event " .. i .. ": " .. (event.event_type or "unknown") .. " - " .. (event.data and event.data:sub(1, 50) or "no data"), "debug")
					end
				else
					debug.debug_print("SSE event buffer is empty", "debug")
				end
			else
				debug.debug_print("SSE client is not connected", "debug")
			end
		
		if chunks and #chunks > 0 then
			debug.debug_print("Found " .. #chunks .. " chunks, processing them", "debug")
			
			-- Process chunks asynchronously
			local function process_chunk_async(chunk_index)
				if chunk_index > #chunks then
					-- All chunks processed, call completion
					debug.debug_print("🔄 All chunks processed, calling completion", "debug")
					-- Mark streaming as inactive
					rpc_client:set_streaming_active(false)
					if on_complete then
						on_complete()
					end
					completion_detected = true
					check_timer:stop()
					check_timer:close()
					return
				end
				
				local chunk = chunks[chunk_index]
				if on_chunk then
					local chunk_type = chunk.chunk_type or "regular_content"
					debug.debug_print("🔄 About to call on_chunk for chunk " .. tostring(chunk_index) .. " with type: " .. chunk_type, "debug")
					debug.debug_print("🔄 Chunk content preview: " .. (chunk.chunk or "no content"):sub(1, 50), "debug")
					on_chunk(chunk.chunk, chunk.chunk_index or 0, chunk.total_chunks or 1, chunk_type)
					debug.debug_print("🔄 on_chunk call completed for chunk " .. tostring(chunk_index), "debug")
				end
				
				-- Schedule next chunk processing with a small delay for smooth animation
				vim.defer_fn(function()
					process_chunk_async(chunk_index + 1)
				end, 50) -- 50ms delay between chunks
			end
			
			-- Start processing chunks
			process_chunk_async(1)
			
			-- Clear chunks after retrieving them
			rpc_client:clear_streaming_chunks()
			debug.debug_print("🔄 Chunks processed and cleared, continuing to check for more", "debug")
			-- Don't return here - continue checking for more chunks
		end
		
		total_wait_time = total_wait_time + (check_interval / 1000)
		
		-- Check if we should complete (either timeout or no more chunks expected)
		if total_wait_time >= max_wait_time or completion_detected then
			debug.debug_print("Completing streaming (timeout or completion detected) after " .. total_wait_time .. "s", "debug")
			check_timer:stop()
			check_timer:close()
			-- Mark streaming as inactive
			rpc_client:set_streaming_active(false)
			if on_complete and not completion_detected then
				on_complete()
			end
			return
		end
		
		-- Check for completion based on chunk types
		if chunks and #chunks > 0 then
			local last_chunk = chunks[#chunks]
			if last_chunk and (last_chunk.chunk_type == "thinking_end" or last_chunk.chunk_type == "regular_content") then
				debug.debug_print("Final chunk type detected: " .. (last_chunk.chunk_type or "unknown"), "debug")
				-- Don't complete here, let the chunk processing handle it
			end
		end
		
		-- Schedule next check
		check_timer:start(check_interval, 0, check_for_chunks)
	end
	
	-- Start the non-blocking chunk checking
	check_for_chunks()

	return true
end

-- Send message command with thinking model support and folding
function M.send_message_command_thinking()
	local current_buf = vim.api.nvim_get_current_buf()
	local buf_name = vim.api.nvim_buf_get_name(current_buf)

	if buf_name ~= "paragonic://chat" then
		vim.notify("This command only works in the chat buffer", vim.log.levels.WARN)
		return
	end

	-- Extract message from cursor position
	local message, start_line = extract_backward_to_tombstone(current_buf)
	local line_num = vim.api.nvim_win_get_cursor(0)[1] - 1

	if message == "" or message:match("^%s*#") then
		vim.notify("Please enter a message to send", vim.log.levels.INFO)
		return
	end

	vim.notify(
		"🧠 Sending (thinking mode): " .. message:sub(1, 50) .. (message:len() > 50 and "..." or ""),
		vim.log.levels.INFO
	)

	-- Add user message to buffer (without zigzag since it's already added by smart function)
	local user_lines = { "", message, "" }
	vim.api.nvim_buf_set_lines(current_buf, line_num + 1, line_num + 1, false, user_lines)

	-- Store the current window ID for later use in callbacks
	local chat_window_id = vim.api.nvim_get_current_win()

	-- Use shared on_chunk handler with debug disabled for normal operation
	local on_chunk, on_complete = create_shared_on_chunk_handler(current_buf, line_num, chat_window_id, false)

	-- Send the thinking streaming message
	local config = require("paragonic.config")
	local default_model = config.get("ollama_model") or "deepseek-r1:1.5b"
	
	local success, err = M.send_message_thinking_streaming(message, default_model, on_chunk, on_complete)

	if not success then
		vim.notify("Failed to start thinking streaming: " .. (err or "unknown error"), vim.log.levels.ERROR)

		-- Add error message to chat buffer
		local error_lines = {
			"🛔  " .. (err or "unknown error"),
		}
		vim.api.nvim_buf_set_lines(current_buf, line_num + 2, line_num + 2, false, error_lines)
	end
end

-- Smart send message command that automatically chooses streaming type based on model
function M.send_message_command_smart()
	local current_buf = vim.api.nvim_get_current_buf()
	local buf_name = vim.api.nvim_buf_get_name(current_buf)

	if buf_name ~= "paragonic://chat" then
		vim.notify("This command only works in the chat buffer", vim.log.levels.WARN)
		return
	end

	-- Extract message from cursor position
	local message, start_line = extract_backward_to_tombstone(current_buf)
	local line_num = vim.api.nvim_win_get_cursor(0)[1] - 1

	if message == "" or message:match("^%s*#") then
		vim.notify("Please enter a message to send", vim.log.levels.INFO)
		return
	end

	-- Add immediate visual feedback (zigzag arrow) before any backend operations
	vim.api.nvim_buf_set_lines(current_buf, line_num + 1, line_num + 1, false, { "↯" })
	
	-- Force buffer update to show zigzag immediately
	vim.api.nvim_buf_call(current_buf, function()
		vim.cmd("redraw!")
	end)

	-- Get current model and its capabilities
	local config = require("paragonic.config")
	local current_model = config.get("ollama_model") or "deepseek-r1:1.5b"
	local streaming_type = config.get_current_model_streaming_type()
	local supports_thinking = config.current_model_supports_thinking()

	-- TEST: Add notification to see if this function is being called
	vim.notify("TEST: send_message_command_smart called with model: " .. current_model .. ", supports_thinking: " .. tostring(supports_thinking), vim.log.levels.INFO)

	-- Determine which command to use based on model capabilities
	if supports_thinking then
		vim.notify(
			"🧠 Sending (thinking mode): " .. message:sub(1, 50) .. (message:len() > 50 and "..." or ""),
			vim.log.levels.INFO
		)
		M.send_message_command_thinking()
	else
		vim.notify(
			"🮮 Sending (normal mode): " .. message:sub(1, 50) .. (message:len() > 50 and "..." or ""),
			vim.log.levels.INFO
		)
		-- For non-thinking models, use the thinking command as well since it handles streaming properly
		M.send_message_command_thinking()
	end
end

-- Smart send message function (for programmatic use)
function M.send_message_smart(message, model)
	local config = require("paragonic.config")
	local target_model = model or config.get("ollama_model") or "deepseek-r1:1.5b"
	local supports_thinking = config.model_supports_thinking(target_model)

	if supports_thinking then
		return M.send_message_thinking_streaming(message, target_model)
	else
		return M.send_message_streaming(message, target_model)
	end
end

-- Function to auto-fold thinking content between brain and hourglass markers
function M.fold_thinking_content(current_buf, start_line_num)
	-- Enable folding for the buffer
	vim.api.nvim_buf_set_option(current_buf, "foldmethod", "marker")
	vim.api.nvim_buf_set_option(current_buf, "foldmarker", "🧠,󱦟")
	
	-- Get all lines in the buffer
	local all_lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
	
	-- Find the thinking section that starts after the given line number
	local thinking_start_line = nil
	local thinking_end_line = nil
	
	for i = start_line_num + 2, #all_lines do -- +2 to skip the user message and start looking after it
		local line = all_lines[i]
		if line and line:match("^🧠%s*<think>") then
			thinking_start_line = i - 1 -- Convert to 0-indexed
		elseif line and line:match("^󱦟%s*</think>") and thinking_start_line then
			thinking_end_line = i - 1 -- Convert to 0-indexed
			break
		end
	end
	
	-- If we found a thinking section, create a fold
	if thinking_start_line and thinking_end_line and thinking_end_line > thinking_start_line then
		-- Create a fold from thinking_start_line to thinking_end_line
		local fold_start = thinking_start_line
		local fold_end = thinking_end_line
		
		-- Create the fold by modifying the existing lines to add fold markers
		local start_line_content = all_lines[thinking_start_line + 1] -- Convert back to 1-indexed
		local end_line_content = all_lines[thinking_end_line + 1] -- Convert back to 1-indexed
		
		-- Add fold markers to existing lines
		if start_line_content and not start_line_content:match("{{{$") then
			vim.api.nvim_buf_set_lines(current_buf, fold_start, fold_start + 1, false, {start_line_content .. " {{{"})
		end
		
		if end_line_content and not end_line_content:match("}}}$") then
			vim.api.nvim_buf_set_lines(current_buf, fold_end, fold_end + 1, false, {end_line_content .. " }}}"})
		end
		
		-- Close the fold using a safer approach
		vim.defer_fn(function()
			-- Check if the buffer and lines still exist
			if vim.api.nvim_buf_is_valid(current_buf) and 
			   fold_start < vim.api.nvim_buf_line_count(current_buf) then
				-- Use a more reliable way to close the fold
				vim.api.nvim_buf_call(current_buf, function()
					vim.cmd("normal! " .. (fold_start + 1) .. "G")
					vim.cmd("foldclose")
				end)
			end
		end, 100) -- Small delay to ensure buffer is ready
		
		-- Move cursor back to the end
		vim.defer_fn(function()
			if vim.api.nvim_buf_is_valid(current_buf) then
				local buffer_line_count = vim.api.nvim_buf_line_count(current_buf)
				vim.api.nvim_win_set_cursor(0, {buffer_line_count, 0})
			end
		end, 150)
		
		debug.debug_print("🧠 Created fold from line " .. fold_start .. " to " .. fold_end, "debug")
	end
end

-- Test function to verify zigzag arrow display
function M.test_zigzag_arrow()
	local current_buf = vim.api.nvim_get_current_buf()
	local line_num = vim.api.nvim_win_get_cursor(0)[1] - 1

	-- Add zigzag arrow to indicate request is being sent
	vim.api.nvim_buf_set_lines(current_buf, line_num + 1, line_num + 1, false, { "↯" })

	-- Force buffer update to show zigzag immediately
	vim.api.nvim_buf_call(current_buf, function()
		vim.cmd("redraw!")
	end)

	vim.notify("Zigzag arrow test: Added ↯ at line " .. (line_num + 1), vim.log.levels.INFO)
end

return M
