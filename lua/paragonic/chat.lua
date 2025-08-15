--[[
Paragonic Chat Module
Handles chat interface and message sending functionality
--]]

local M = {}

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
	local response = rpc_client:chat_completion(model, message)
	if not response then
		return nil, "Failed to get response from AI"
	end

	-- Parse response using enhanced parser (handles both strings and tables)
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

	-- Open the buffer in a new window
	vim.api.nvim_command("split")
	vim.api.nvim_set_current_buf(chat_buf)

	-- Move cursor to the end of the buffer
	vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(0), 0 })
end

-- Send message command
function M.send_message_command_legacy()
	-- Immediate debugging at function entry
	local debug = require("paragonic.debug")
	debug.debug_print("🚀 send_message_command() called", "debug")
	debug.debug_print("📝 Starting send_message_command function", "debug")

	local current_buf = vim.api.nvim_get_current_buf()
	local buf_name = vim.api.nvim_buf_get_name(current_buf)

	debug.debug_print("📝 Current buffer: " .. buf_name, "debug")

	-- Only work in chat buffer
	if buf_name ~= "paragonic://chat" then
		debug.debug_print("❌ This command only works in the chat buffer", "error")
		return
	end

	debug.debug_print("✅ Buffer check passed", "debug")

	-- Extract multi-line message from cursor to previous tombstone
	local message, start_line = extract_backward_to_tombstone(current_buf)
	local line_num = vim.api.nvim_win_get_cursor(0)[1] - 1 -- Keep for insertion positioning

	debug.debug_print("📝 Message: " .. message:sub(1, 50), "debug")

	-- Skip empty lines or lines that start with #
	if message == "" or message:match("^%s*#") then
		debug.debug_print("❌ Please enter a message to send", "error")
		return
	end

	debug.debug_print("✅ Message validation passed", "debug")
	debug.debug_print("🔧 About to call append_debug_message...", "debug")

	-- Add immediate visual feedback that the chat is being sent
	debug.debug_print("🔧 Calling append_debug_message...", "debug")
	local success, err = debug.append_debug_message(current_buf, "Sending message to AI...", "info")

	if not success then
		debug.debug_print("❌ append_debug_message failed: " .. tostring(err), "error")
		return
	else
		debug.debug_print("✅ append_debug_message succeeded", "debug")
	end

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

	-- Start a progress indicator for long operations
	local progress_timer = nil
	local progress_count = 0
	local function update_progress()
		progress_count = progress_count + 1
		local dots = string.rep(".", progress_count % 4)
		debug.append_debug_message(current_buf, "Waiting for AI response" .. dots, "info")
	end

	-- Start progress updates every 5 seconds
	progress_timer = vim.loop.new_timer()
	progress_timer:start(5000, 5000, vim.schedule_wrap(update_progress))

	-- Record start time for timing information
	local start_time = vim.uv.now()

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

	-- Send the message using enhanced function
	local config = require("paragonic.config")
	local default_model = config.get("ollama_model") or "deepseek-r1:1.5b"
	local response, err = M.send_message_enhanced(message, default_model)

	-- Stop progress updates
	if progress_timer then
		progress_timer:stop()
		progress_timer:close()
	end

	if not response then
		-- Update the status message to show failure
		debug.append_debug_message(current_buf, "Failed to send message: " .. (err or "unknown error"), "error")
		vim.notify("Failed to send message: " .. (err or "unknown error"), vim.log.levels.ERROR)

		-- Add error message to chat buffer with error symbol
		local error_lines = {
			"🛔  " .. (err or "unknown error"),
		}
		vim.api.nvim_buf_set_lines(current_buf, line_num + 2, line_num + 2, false, error_lines)
		return
	end

	-- Calculate timing information
	local end_time = vim.uv.now()
	local duration_ms = end_time - start_time
	local duration_sec = duration_ms / 1000

	-- Update the status message to show success
	debug.append_debug_message(current_buf, "Message sent successfully, processing response...", "success")

	-- Add the response to the buffer
	-- Split response into lines to handle multi-line responses
	local response_content_lines = {}
	for line in response:gmatch("[^\r\n]+") do
		if line:match("%S") then -- Only add non-empty lines
			table.insert(response_content_lines, line)
		end
	end

	-- If no lines were extracted, add the original response as a single line
	if #response_content_lines == 0 then
		table.insert(response_content_lines, response)
	end

	local response_lines = {}

	-- Get buffer width for word wrapping (70% of buffer width after indentation)
	local full_buffer_width = vim.api.nvim_win_get_width(0)
	local base_width = math.floor(full_buffer_width * 0.7)
	if base_width < 20 then
		base_width = 20
	end -- Minimum width

	-- Add first line with diamond prefix and remaining lines with three-space indent
	local utils = require("paragonic.utils")
	if #response_content_lines > 0 then
		local wrapped_first = utils.wrap_text_with_diamond(response_content_lines[1], base_width)
		for _, line in ipairs(wrapped_first) do
			table.insert(response_lines, line)
		end

		-- Add remaining lines with six spaces indentation (3-space gutter + 3-space continuation)
		for i = 2, #response_content_lines do
			local wrapped_lines = utils.wrap_text(response_content_lines[i], base_width, "      ")
			for _, line in ipairs(wrapped_lines) do
				table.insert(response_lines, line)
			end
		end
	else
		-- If no content, just add the diamond with proper gutter spacing
		table.insert(response_lines, "🮮   ")
	end

	-- Add timing information
	table.insert(response_lines, "")
	table.insert(response_lines, " ⏱️   " .. string.format("%.2fs", duration_sec))

	-- Add closing lines
	table.insert(response_lines, "")
	table.insert(response_lines, "∎")

	-- Insert response after the zigzag arrow (line_num + 2 since zigzag is at line_num + 1)
	vim.api.nvim_buf_set_lines(current_buf, line_num + 2, line_num + 2, false, response_lines)

	-- Move cursor to the end of the buffer (safe positioning)
	local buffer_line_count = vim.api.nvim_buf_line_count(current_buf)
	vim.api.nvim_win_set_cursor(0, { buffer_line_count, 0 })
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

	-- Send the message using enhanced function
	local config = require("paragonic.config")
	local default_model = config.get("ollama_model") or "deepseek-r1:1.5b"
	local response, err = M.send_message_enhanced(message, default_model)

	-- Stop progress updates
	if progress_timer then
		progress_timer:stop()
		progress_timer:close()
	end

	if not response then
		debug.append_debug_message(current_buf, "Failed to send message: " .. tostring(err), "error")
		vim.notify("Failed to send message: " .. (err or "unknown error"), vim.log.levels.ERROR)

		-- Add error message to chat buffer with error symbol
		local error_lines = {
			"🛔  " .. (err or "unknown error"),
		}
		vim.api.nvim_buf_set_lines(current_buf, line_num + 2, line_num + 2, false, error_lines)
		return
	end

	-- Calculate timing information
	local end_time = vim.uv.now()
	local duration_ms = end_time - start_time
	local duration_sec = duration_ms / 1000

	debug.append_debug_message(current_buf, "✅ Successfully received response from AI", "success")

	-- Debug: Processing response
	debug.append_debug_message(current_buf, "Processing response for buffer insertion", "debug")

	-- Add the response to the buffer
	-- Split response into lines to handle multi-line responses
	local response_content_lines = {}
	for line in response:gmatch("[^\r\n]+") do
		if line:match("%S") then -- Only add non-empty lines
			table.insert(response_content_lines, line)
		end
	end

	-- If no lines were extracted, add the original response as a single line
	if #response_content_lines == 0 then
		table.insert(response_content_lines, response)
	end

	local response_lines = {}

	-- Get buffer width for word wrapping (70% of buffer width after indentation)
	local full_buffer_width = vim.api.nvim_win_get_width(0)
	local base_width = math.floor(full_buffer_width * 0.7)
	if base_width < 20 then
		base_width = 20
	end -- Minimum width

	-- Add first line with diamond prefix and remaining lines with three-space indent
	local utils = require("paragonic.utils")
	if #response_content_lines > 0 then
		local wrapped_first = utils.wrap_text_with_diamond(response_content_lines[1], base_width)
		for _, line in ipairs(wrapped_first) do
			table.insert(response_lines, line)
		end

		-- Add remaining lines with six spaces indentation (3-space gutter + 3-space continuation)
		for i = 2, #response_content_lines do
			local wrapped_lines = utils.wrap_text(response_content_lines[i], base_width, "      ")
			for _, line in ipairs(wrapped_lines) do
				table.insert(response_lines, line)
			end
		end
	else
		-- If no content, just add the diamond with proper gutter spacing
		table.insert(response_lines, "🮮   ")
	end

	-- Add timing information
	table.insert(response_lines, "")
	table.insert(response_lines, " ⏱️   " .. string.format("%.2fs", duration_sec))

	-- Add closing lines
	table.insert(response_lines, "")
	table.insert(response_lines, "∎")

	-- Debug: Inserting response
	debug.append_debug_message(current_buf, "Inserting " .. #response_lines .. " lines into buffer", "debug")

	-- Insert response after the zigzag arrow (line_num + 2 since zigzag is at line_num + 1)
	vim.api.nvim_buf_set_lines(current_buf, line_num + 2, line_num + 2, false, response_lines)

	-- Move cursor to the end of the buffer (safe positioning)
	local buffer_line_count = vim.api.nvim_buf_line_count(current_buf)
	vim.api.nvim_win_set_cursor(0, { buffer_line_count, 0 })

	-- Debug: Success
	debug.append_debug_message(current_buf, "Message send process completed successfully", "success")
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
	local response = rpc_client:streaming_chat_completion({
		model = model,
		message = message,
		chunk_size = 30, -- Small chunks for smooth streaming
	})

	if not response then
		return nil, "Failed to start streaming"
	end

	-- Parse the initial response
	local utils = require("paragonic.utils")
	local parsed_response = utils.parse_json_response_enhanced(response)
	if not parsed_response then
		return nil, "Failed to parse streaming response"
	end

	-- Check for error in response
	if parsed_response.error then
		return nil, "Streaming error: " .. (parsed_response.error.message or "Unknown error")
	end

	-- Extract streaming data
	local result = parsed_response.result
	if type(result) == "string" then
		-- Try to parse JSON string
		local success, parsed = pcall(vim.json.decode, result)
		if success then
			result = parsed
		else
			return nil, "Failed to parse streaming result"
		end
	end

	if not result or result.type ~= "streaming_chunk" then
		return nil, "Unexpected streaming response format"
	end

	-- Call on_chunk for the first chunk
	if on_chunk then
		local chunk_type = result.chunk_type or "regular_content"
		on_chunk(result.chunk, result.chunk_index, result.total_chunks, chunk_type)
	end

	-- Set up SSE notification handler for streaming chunks
	local streaming_complete = false
	local total_chunks = result.total_chunks or 1
	local chunks_received = 1 -- We already have the first chunk

	-- Create a notification handler for streaming chunks
	local original_on_notification = mcp_http_transport.get_callbacks().on_notification
	local streaming_handler = function(notification)
		if notification.method == "notifications/message" and notification.params then
			local params = notification.params
			
			if params.type == "streaming_chunk" then
				chunks_received = chunks_received + 1
				
				-- Process the chunk
				if on_chunk then
					local chunk_type = params.chunk_type or "regular_content"
					on_chunk(params.chunk, params.chunk_index, total_chunks, chunk_type)
				end
				
			elseif params.type == "streaming_complete" then
				streaming_complete = true
				if on_complete then
					on_complete()
				end
				
				-- Restore original notification handler
				mcp_http_transport.set_callbacks({
					on_notification = original_on_notification
				})
			end
		end
		
		-- Call original handler for other notifications
		if original_on_notification then
			original_on_notification(notification)
		end
	end

	-- Set up streaming notification handler
	mcp_http_transport.set_callbacks({
		on_notification = streaming_handler
	})

	-- Set a timeout for streaming completion
	vim.defer_fn(function()
		if not streaming_complete then
			-- Timeout reached, restore original handler and call completion
			mcp_http_transport.set_callbacks({
				on_notification = original_on_notification
			})
			if on_complete then
				on_complete()
			end
		end
	end, 30000) -- 30 second timeout

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
	local response = rpc_client:streaming_chat_completion({
		model = model,
		message = message,
		chunk_size = 50, -- Larger chunks for thinking model
	})

	if not response then
		return nil, "Failed to start streaming"
	end

	-- Parse the initial response
	local utils = require("paragonic.utils")
	local parsed_response = utils.parse_json_response_enhanced(response)
	if not parsed_response then
		return nil, "Failed to parse streaming response"
	end

	-- Check for error in response
	if parsed_response.error then
		return nil, "Streaming error: " .. (parsed_response.error.message or "Unknown error")
	end

	-- Wait for streaming chunks to arrive via SSE
	local max_wait_time = 30 -- seconds
	local wait_interval = 0.1 -- seconds
	local total_wait_time = 0
	
	while total_wait_time < max_wait_time do
		local chunks = rpc_client:get_streaming_chunks()
		if #chunks > 0 then
			-- Process the first chunk to get started
			local first_chunk = chunks[1]
			if first_chunk.type == "streaming_chunk" then
				break -- We have chunks, proceed with processing
			end
		end
		
		vim.wait(wait_interval * 1000) -- Convert to milliseconds
		total_wait_time = total_wait_time + wait_interval
	end
	
	-- Get all available chunks
	local chunks = rpc_client:get_streaming_chunks()
	if #chunks == 0 then
		return nil, "No streaming chunks received"
	end

	-- Initialize thinking state
	local thinking_state = {
		in_thinking = false,
		thinking_start_line = nil,
		thinking_step_count = 0,
		current_content = "",
		final_content = "",
	}

	-- Function to process thinking content
	local function process_thinking_content(content, is_final)
		if is_final then
			thinking_state.final_content = thinking_state.final_content .. content
		else
			thinking_state.current_content = thinking_state.current_content .. content
		end

		-- Check if we're entering thinking mode
		if not thinking_state.in_thinking and thinking_state.current_content:match("<think>") then
			thinking_state.in_thinking = true
			thinking_state.thinking_step_count = 0
			thinking_state.current_content = thinking_state.current_content:gsub("<think>", "")

			-- Start thinking section with brain symbol
			if on_chunk then
				on_chunk("󰧑   <think>\n", 0, 1, "thinking_start")
			end
		end

		-- Check if we're exiting thinking mode
		if thinking_state.in_thinking and thinking_state.current_content:match("</think>") then
			thinking_state.in_thinking = false
			local before_end, after_end = thinking_state.current_content:match("(.*)</think>(.*)")
			thinking_state.current_content = before_end or ""
			thinking_state.final_content = (after_end or "") .. thinking_state.final_content

			-- End thinking section
			if on_chunk then
				on_chunk("</think>\n", 0, 1, "thinking_end")
			end
		end

		-- Process thinking content with step detection
		if thinking_state.in_thinking then
			-- Split content into lines to detect thinking steps
			local lines = {}
			for line in thinking_state.current_content:gmatch("[^\r\n]+") do
				table.insert(lines, line)
			end

			-- Process each line for thinking steps
			for i, line in ipairs(lines) do
				-- Check if this is a new thinking step (starts with > or specific patterns)
				if line:match("^%s*>%s*") or line:match("^%s*%d+%.") or line:match("^%s*%-%s*") then
					thinking_state.thinking_step_count = thinking_state.thinking_step_count + 1

					-- Use brain for first step, vertical ideographic iteration mark for others
					local step_symbol = thinking_state.thinking_step_count == 1 and "󰧑" or "〻"

					if on_chunk then
						on_chunk(step_symbol .. "   " .. line .. "\n", 0, 1, "thinking_step")
					end
				else
					-- Regular thinking content
					if on_chunk then
						on_chunk("   " .. line .. "\n", 0, 1, "thinking_content")
					end
				end
			end

			-- Clear processed content
			thinking_state.current_content = ""
		else
			-- Regular content (not in thinking mode)
			if thinking_state.current_content ~= "" then
				if on_chunk then
					on_chunk(thinking_state.current_content, 0, 1, "regular_content")
				end
				thinking_state.current_content = ""
			end
		end
	end

	-- Process all chunks from SSE
	local processed_chunks = 0
	local total_chunks = #chunks
	
	-- Function to process chunks
	local function process_chunks()
		while processed_chunks < total_chunks do
			processed_chunks = processed_chunks + 1
			local chunk = chunks[processed_chunks]
			
			if chunk.type == "streaming_complete" then
				-- Process any remaining content
				if thinking_state.current_content ~= "" then
					process_thinking_content(thinking_state.current_content, true)
				end
				
				-- Streaming finished
				if on_complete then
					on_complete()
				end
				return
			elseif chunk.type == "streaming_chunk" then
				-- Process this chunk with thinking logic
				process_thinking_content(chunk.chunk, false)
				
				-- Small delay for smooth animation
				if processed_chunks < total_chunks then
					vim.wait(50) -- 50ms delay between chunks
				end
			end
		end
		
		-- Process any remaining content
		if thinking_state.current_content ~= "" then
			process_thinking_content(thinking_state.current_content, true)
		end
		
		-- All chunks processed
		if on_complete then
			on_complete()
		end
	end
	
	-- Start processing chunks
	vim.defer_fn(process_chunks, 100) -- Start after 100ms

	return true
end

-- Helper function to extract text backward from cursor to previous tombstone
-- This enables multi-line input by capturing all lines from the cursor
-- position back to the previous ∎ tombstone marker
local function extract_backward_to_tombstone(current_buf)
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local cursor_line = cursor_pos[1] - 1 -- Convert to 0-indexed

	-- Debug: Print cursor position
	local debug = require("paragonic.debug")
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
	local end_line = #all_lines -- Default to end of buffer
	for i = cursor_line + 1, #all_lines do
		if all_lines[i] and all_lines[i]:match("^%s*∎%s*$") then
			end_line = i - 1 -- Stop before the tombstone
			break
		end
	end

	-- Extract lines in the range
	local message_lines = {}
	for i = start_line, end_line do
		if all_lines[i] then
			table.insert(message_lines, all_lines[i])
		end
	end

	local result = table.concat(message_lines, "\n")
	-- Only trim trailing whitespace, preserve leading structure and empty lines
	return result:gsub("%s+$", "")
end

function M.send_message_command()
	local debug = require("paragonic.debug")
	debug.debug_print("🚀 send_message_command() called", "debug")

	local current_buf = vim.api.nvim_get_current_buf()
	local buf_name = vim.api.nvim_buf_get_name(current_buf)

	debug.debug_print("🔍 Current buffer: " .. buf_name, "debug")

	-- Only work in chat buffer
	if buf_name ~= "paragonic://chat" then
		debug.debug_print("❌ Not in chat buffer", "error")
		vim.notify("This command only works in the chat buffer", vim.log.levels.WARN)
		return
	end

	debug.debug_print("✅ In chat buffer, extracting message...", "debug")

	-- Extract multi-line message from cursor to previous tombstone
	local message, start_line = extract_backward_to_tombstone(current_buf)
	local line_num = vim.api.nvim_win_get_cursor(0)[1] - 1 -- Keep for insertion positioning

	debug.debug_print("🔍 Extracted message: " .. string.format("%q", message), "debug")
	debug.debug_print("🔍 Message length: " .. #message, "debug")

	-- Debug: Show what was extracted
	vim.notify("Extracted message: " .. string.format("%q", message), vim.log.levels.INFO)

	-- Skip empty lines or lines that start with #
	if message == "" or message:match("^%s*#") then
		vim.notify("Please enter a message to send", vim.log.levels.INFO)
		return
	end

	-- Initialize backend if not available
	local backend = require("paragonic.backend")
	debug.debug_print("🔍 Checking backend._rpc_client: " .. tostring(backend._rpc_client ~= nil), "debug")

	if not backend._rpc_client then
		debug.debug_print("🔧 Backend not available, initializing...", "debug")
		local success = backend._initialize_backend()
		debug.debug_print("🔧 Backend initialization result: " .. tostring(success), "debug")

		if not success then
			debug.debug_print("❌ Backend initialization failed", "error")
			vim.notify("Failed to initialize backend", vim.log.levels.ERROR)
			return
		end
	else
		debug.debug_print("✅ Backend already available", "debug")
	end

	-- Get buffer width for formatting
	local buffer_width = vim.api.nvim_win_get_width(0)
	local format_width = math.floor(buffer_width * 0.7)
	if format_width < 20 then
		format_width = 20
	end -- Minimum width

	-- Configure formatting for server-side processing
	local format_config = {
		max_width = format_width,
		include_diamond = true,
		continuation_indent = 3,
		format_markdown = true,
		preserve_paragraphs = true,
	}

	-- Record start time for timing information
	local start_time = vim.uv.now()

	-- Add zigzag arrow to indicate request is being sent
	vim.api.nvim_buf_set_lines(current_buf, line_num + 1, line_num + 1, false, { "↯" })

	-- Force immediate buffer update to show zigzag arrow
	vim.api.nvim_buf_call(current_buf, function()
		vim.cmd("redraw!")
	end)

	-- Small delay to ensure zigzag arrow is visible
	vim.defer_fn(function()
		-- Send the message using server-side formatted function
		local config = require("paragonic.config")
		local default_model = config.get("ollama_model") or "deepseek-r1:1.5b"

		debug.debug_print("🔧 About to send message to model: " .. default_model, "debug")
		debug.debug_print("🔧 Message to send: " .. string.format("%q", message), "debug")

		local formatted_response, original_response, server_duration_sec, err =
			M.send_message_formatted(message, default_model, format_config)

		if not formatted_response then
			vim.notify("Failed to send message: " .. (err or "unknown error"), vim.log.levels.ERROR)

			-- Add error message to chat buffer with error symbol
			local error_lines = {
				"🛔  " .. (err or "unknown error"),
			}
			vim.api.nvim_buf_set_lines(current_buf, line_num + 2, line_num + 2, false, error_lines)
			return
		end

		-- Since the response is already formatted by the server, we can add it directly
		local response_lines = {}
		for line in formatted_response:gmatch("[^\r\n]+") do
			table.insert(response_lines, line)
		end

		-- Add closing line
		table.insert(response_lines, "")
		table.insert(response_lines, "∎")

		-- Insert response after the zigzag arrow (line_num + 2 since zigzag is at line_num + 1)
		vim.api.nvim_buf_set_lines(current_buf, line_num + 2, line_num + 2, false, response_lines)

		-- Move cursor to the end of the buffer
		local buffer_line_count = vim.api.nvim_buf_line_count(current_buf)
		vim.api.nvim_win_set_cursor(0, { buffer_line_count, 0 })

		-- Notify success
		vim.notify("Message sent successfully (server-formatted)", vim.log.levels.INFO)
	end, 100) -- 100ms delay
end

-- Send message with streaming updates using brain symbol
function M.send_message_command_streaming()
	local debug = require("paragonic.debug")
	debug.debug_print("🚀 send_message_command_streaming() called", "debug")

	-- Get current buffer and cursor position
	local current_buf = vim.api.nvim_get_current_buf()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local line_num = cursor_pos[1] - 1 -- Convert to 0-based index

	-- Extract message from current line
	local line_content = vim.api.nvim_buf_get_lines(current_buf, line_num, line_num + 1, false)[1] or ""
	local message = line_content:match("^%s*(.+)%s*$") -- Trim whitespace

	if not message or message == "" then
		vim.notify("No message to send", vim.log.levels.WARN)
		return
	end

	-- Add immediate visual feedback that the chat is being sent
	debug.debug_print("🔧 Calling append_debug_message...", "debug")
	local success, err = debug.append_debug_message(current_buf, "Starting streaming message to AI...", "info")

	if not success then
		debug.debug_print("❌ append_debug_message failed: " .. tostring(err), "error")
		return
	else
		debug.debug_print("✅ append_debug_message succeeded", "debug")
	end

	-- Initialize backend if not available
	local backend = require("paragonic.backend")
	if not backend._rpc_client then
		debug.append_debug_message(current_buf, "🔧 Backend not available, starting initialization...", "info")

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

	-- Record start time for timing information
	local start_time = vim.uv.now()

	-- Add brain symbol to indicate streaming is starting
	vim.api.nvim_buf_set_lines(current_buf, line_num + 1, line_num + 1, false, { "󰧑" })

	-- Force buffer update to show brain symbol immediately
	vim.api.nvim_buf_call(current_buf, function()
		vim.cmd("redraw!")
	end)

	-- Initialize response buffer
	local response_buffer = ""
	local response_line_start = line_num + 2

	-- Callback for each chunk
	local function on_chunk(chunk, chunk_index, total_chunks)
		-- Append chunk to response buffer
		response_buffer = response_buffer .. chunk

		-- Update the response line with current content and brain symbol
		local response_lines = {}
		for line in response_buffer:gmatch("[^\r\n]+") do
			if line:match("%S") then -- Only add non-empty lines
				table.insert(response_lines, line)
			end
		end

		-- If no lines were extracted, add the current buffer as a single line
		if #response_lines == 0 then
			table.insert(response_lines, response_buffer)
		end

		-- Format with brain symbol for progress and diamond for final
		local formatted_lines = {}
		local utils = require("paragonic.utils")

		-- Get buffer width for word wrapping
		local full_buffer_width = vim.api.nvim_win_get_width(0)
		local base_width = math.floor(full_buffer_width * 0.7)
		if base_width < 20 then
			base_width = 20
		end

		if #response_lines > 0 then
			-- First line with brain symbol (progress indicator)
			local wrapped_first = utils.wrap_text_with_diamond(response_lines[1], base_width)
			for _, line in ipairs(wrapped_first) do
				-- Replace diamond with brain symbol for progress
				line = line:gsub("🮮", "󰧑")
				table.insert(formatted_lines, line)
			end

			-- Remaining lines with six spaces indentation
			for i = 2, #response_lines do
				local wrapped_lines = utils.wrap_text(response_lines[i], base_width, "      ")
				for _, line in ipairs(wrapped_lines) do
					table.insert(formatted_lines, line)
				end
			end
		else
			-- If no content, just add the brain symbol with proper gutter spacing
			table.insert(formatted_lines, "󰧑   ")
		end

		-- Update the buffer with current progress
		vim.api.nvim_buf_set_lines(
			current_buf,
			response_line_start,
			response_line_start + #formatted_lines,
			false,
			formatted_lines
		)

		-- Force buffer update
		vim.api.nvim_buf_call(current_buf, function()
			vim.cmd("redraw!")
		end)
	end

	-- Callback for completion
	local function on_complete()
		-- Calculate timing information
		local end_time = vim.uv.now()
		local duration_ms = end_time - start_time
		local duration_sec = duration_ms / 1000

		-- Replace brain symbol with diamond for final result
		local final_lines = {}
		for line in response_buffer:gmatch("[^\r\n]+") do
			if line:match("%S") then
				table.insert(final_lines, line)
			end
		end

		if #final_lines == 0 then
			table.insert(final_lines, response_buffer)
		end

		-- Format with diamond symbol for final result
		local utils = require("paragonic.utils")
		local full_buffer_width = vim.api.nvim_win_get_width(0)
		local base_width = math.floor(full_buffer_width * 0.7)
		if base_width < 20 then
			base_width = 20
		end

		local formatted_lines = {}
		if #final_lines > 0 then
			-- First line with diamond symbol (final result)
			local wrapped_first = utils.wrap_text_with_diamond(final_lines[1], base_width)
			for _, line in ipairs(wrapped_first) do
				table.insert(formatted_lines, line)
			end

			-- Remaining lines with six spaces indentation
			for i = 2, #final_lines do
				local wrapped_lines = utils.wrap_text(final_lines[i], base_width, "      ")
				for _, line in ipairs(wrapped_lines) do
					table.insert(formatted_lines, line)
				end
			end
		else
			table.insert(formatted_lines, "🮮   ")
		end

		-- Add timing information
		table.insert(formatted_lines, "")
		table.insert(formatted_lines, " ⏱️   " .. string.format("%.2fs", duration_sec))

		-- Add closing lines
		table.insert(formatted_lines, "")
		table.insert(formatted_lines, "∎")

		-- Update the buffer with final result
		vim.api.nvim_buf_set_lines(
			current_buf,
			response_line_start,
			response_line_start + #formatted_lines,
			false,
			formatted_lines
		)

		-- Move cursor to the end of the buffer
		local buffer_line_count = vim.api.nvim_buf_line_count(current_buf)
		vim.api.nvim_win_set_cursor(0, { buffer_line_count, 0 })

		-- Notify success
		vim.notify("Streaming message completed successfully", vim.log.levels.INFO)
		debug.append_debug_message(current_buf, "✅ Streaming message completed", "success")
	end

	-- Send the streaming message
	local config = require("paragonic.config")
	local default_model = config.get("ollama_model") or "deepseek-r1:1.5b"
	local success, err = M.send_message_streaming(message, default_model, on_chunk, on_complete)

	if not success then
		debug.append_debug_message(current_buf, "Failed to start streaming: " .. (err or "unknown error"), "error")
		vim.notify("Failed to start streaming: " .. (err or "unknown error"), vim.log.levels.ERROR)

		-- Add error message to chat buffer
		local error_lines = {
			"🛔  " .. (err or "unknown error"),
		}
		vim.api.nvim_buf_set_lines(current_buf, line_num + 2, line_num + 2, false, error_lines)
	end
end

-- Alternative send functions for different extraction modes
function M.send_message_backward_only()
	local current_buf = vim.api.nvim_get_current_buf()
	local buf_name = vim.api.nvim_buf_get_name(current_buf)

	if buf_name ~= "paragonic://chat" then
		vim.notify("This command only works in the chat buffer", vim.log.levels.WARN)
		return
	end

	-- Extract only backward from cursor to previous tombstone
	local message, start_line = extract_backward_to_tombstone(current_buf)
	local line_num = vim.api.nvim_win_get_cursor(0)[1] - 1

	if message == "" or message:match("^%s*#") then
		vim.notify("Please enter a message to send", vim.log.levels.INFO)
		return
	end

	vim.notify(
		"📤 Sending (backward only): " .. message:sub(1, 50) .. (message:len() > 50 and "..." or ""),
		vim.log.levels.INFO
	)

	-- Get and send to backend
	local backend = require("paragonic.backend")
	local config = require("paragonic.config")
	local default_model = config.get("ollama_model") or "deepseek-r1:1.5b"
	local success, response = backend.send_message(message, default_model)

	if success then
		vim.api.nvim_buf_set_lines(current_buf, line_num + 1, line_num + 1, false, { "", "∎" })
		local new_line_num = line_num + 3
		vim.api.nvim_win_set_cursor(0, { new_line_num, 0 })
		vim.notify("Message sent successfully (backward extraction)", vim.log.levels.INFO)
	else
		vim.notify("Failed to send message: " .. (response or "unknown error"), vim.log.levels.ERROR)
	end
end

function M.send_message_forward_only()
	local current_buf = vim.api.nvim_get_current_buf()
	local buf_name = vim.api.nvim_buf_get_name(current_buf)

	if buf_name ~= "paragonic://chat" then
		vim.notify("This command only works in the chat buffer", vim.log.levels.WARN)
		return
	end

	-- Extract only forward from cursor to next tombstone or end
	local message = extract_forward_to_tombstone(current_buf)
	local line_num = vim.api.nvim_win_get_cursor(0)[1] - 1

	if message == "" or message:match("^%s*#") then
		vim.notify("Please enter a message to send", vim.log.levels.INFO)
		return
	end

	vim.notify(
		"📤 Sending (forward only): " .. message:sub(1, 50) .. (message:len() > 50 and "..." or ""),
		vim.log.levels.INFO
	)

	-- Get and send to backend
	local backend = require("paragonic.backend")
	local config = require("paragonic.config")
	local default_model = config.get("ollama_model") or "deepseek-r1:1.5b"
	local success, response = backend.send_message(message, default_model)

	if success then
		vim.api.nvim_buf_set_lines(current_buf, line_num + 1, line_num + 1, false, { "", "∎" })
		local new_line_num = line_num + 3
		vim.api.nvim_win_set_cursor(0, { new_line_num, 0 })
		vim.notify("Message sent successfully (forward extraction)", vim.log.levels.INFO)
	else
		vim.notify("Failed to send message: " .. (response or "unknown error"), vim.log.levels.ERROR)
	end
end

-- Test functions for unit testing (only expose when testing)
M._test_extract_backward_to_tombstone = extract_backward_to_tombstone
M._test_extract_forward_to_tombstone = extract_forward_to_tombstone
M._test_extract_complete_range = extract_complete_range

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

	-- Add user message to buffer
	local user_lines = { "", "↯   " .. message, "" }
	vim.api.nvim_buf_set_lines(current_buf, line_num + 1, line_num + 1, false, user_lines)

	-- Calculate response line start
	local response_line_start = line_num + 4

	-- Initialize response buffer and thinking state
	local response_buffer = ""
	local thinking_start_line = nil
	local thinking_end_line = nil
	local fold_start_line = nil
	local thinking_step_count = 0

	-- Set up chunk callback for thinking streaming
	local function on_chunk(chunk, chunk_index, total_chunks, chunk_type)
		if chunk_type == "thinking_start" then
			-- Start thinking section - don't add anything visible yet
			-- The brain symbol will be added with the first thinking step
			thinking_start_line = response_line_start
				+ #vim.api.nvim_buf_get_lines(current_buf, response_line_start, -1, false)
			fold_start_line = thinking_start_line
		elseif chunk_type == "thinking_step" then
			-- Add thinking step with brain symbol for first step, iteration mark for others
			local lines = {}
			for line in chunk:gmatch("[^\r\n]+") do
				-- Use brain symbol for first thinking step, iteration mark for others
				local symbol = "󰧑   " -- Brain symbol for first step
				if thinking_step_count and thinking_step_count > 0 then
					symbol = "〻   " -- Iteration mark for subsequent steps
				end
				table.insert(lines, symbol .. line)
			end
			vim.api.nvim_buf_set_lines(current_buf, -1, -1, false, lines)

			-- Track thinking step count
			if not thinking_step_count then
				thinking_step_count = 0
			end
			thinking_step_count = thinking_step_count + 1
		elseif chunk_type == "thinking_content" then
			-- Add thinking content with indentation
			local lines = {}
			for line in chunk:gmatch("[^\r\n]+") do
				table.insert(lines, "   " .. line)
			end
			vim.api.nvim_buf_set_lines(current_buf, -1, -1, false, lines)
		elseif chunk_type == "thinking_end" then
			-- End thinking section - don't add anything visible
			-- The thinking process is complete, no need for fold markers
		elseif chunk_type == "regular_content" then
			-- Add regular content with lozenge symbol
			response_buffer = response_buffer .. chunk

			-- Format and add to buffer with lozenge symbol
			local lines = {}
			for line in response_buffer:gmatch("[^\r\n]+") do
				table.insert(lines, "◊   " .. line)
			end

			-- Replace or append to buffer
			local current_lines = vim.api.nvim_buf_get_lines(current_buf, response_line_start, -1, false)
			if #current_lines > 0 and current_lines[#current_lines]:match("^◊") then
				-- Replace existing lozenge content
				vim.api.nvim_buf_set_lines(current_buf, response_line_start, -1, false, lines)
			else
				-- Add new lozenge content
				vim.api.nvim_buf_set_lines(current_buf, -1, -1, false, lines)
			end
		else
			-- Default chunk handling
			response_buffer = response_buffer .. chunk
		end

		-- Move cursor to the end of the buffer
		local buffer_line_count = vim.api.nvim_buf_line_count(current_buf)
		vim.api.nvim_win_set_cursor(0, { buffer_line_count, 0 })
	end

	-- Set up completion callback
	local function on_complete()
		local duration_sec = 0 -- TODO: Calculate actual duration

		-- Add timing information
		local timing_lines = {
			"",
			" ⏱️   " .. string.format("%.2fs", duration_sec),
			"",
			"∎",
		}
		vim.api.nvim_buf_set_lines(current_buf, -1, -1, false, timing_lines)

		-- Move cursor to the end of the buffer
		local buffer_line_count = vim.api.nvim_buf_line_count(current_buf)
		vim.api.nvim_win_set_cursor(0, { buffer_line_count, 0 })

		-- Notify success
		vim.notify("Thinking streaming completed successfully", vim.log.levels.INFO)
	end

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
		vim.api.nvim_buf_set_lines(current_buf, response_line_start, response_line_start, false, error_lines)
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

	-- Get current model and its capabilities
	local config = require("paragonic.config")
	local current_model = config.get("ollama_model") or "deepseek-r1:1.5b"
	local streaming_type = config.get_current_model_streaming_type()
	local supports_thinking = config.current_model_supports_thinking()

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
		M.send_message_command_streaming()
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
