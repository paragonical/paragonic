-- Chat module for Paragonic
-- Uses the new layered architecture: transport -> api -> streaming -> ui

local M = {}

-- Import required modules
local debug = require("paragonic.debug")
local config = require("paragonic.config")
local streaming = require("paragonic.streaming")
local ui = require("paragonic.ui")

-- Chat state
local chat_state = {
	initialized = false,
	active_sessions = {},
}

-- Initialize chat module
function M.init()
	if chat_state.initialized then
		debug.debug_print("📝 Chat module already initialized", "debug")
		return true
	end

	debug.debug_print("🔧 Initializing chat module", "info")

	-- Initialize streaming layer
	local streaming_ok = streaming.init(config.get_config())
	if not streaming_ok then
		debug.debug_print("❌ Failed to initialize streaming layer", "error")
		return false
	end

	-- Initialize UI layer
	local ui_ok = ui.init()
	if not ui_ok then
		debug.debug_print("❌ Failed to initialize UI layer", "error")
		return false
	end

	chat_state.initialized = true
	debug.debug_print("✅ Chat module initialized", "success")
	return true
end

-- Open chat buffer
function M.open_chat()
	if not chat_state.initialized then
		local ok = M.init()
		if not ok then
			vim.notify("Failed to initialize chat module", vim.log.levels.ERROR)
			return
		end
	end

	local chat_buffer = ui.create_chat_buffer()
	if not chat_buffer then
		vim.notify("Failed to create chat buffer", vim.log.levels.ERROR)
		return
	end

	-- Get the width of the current window before splitting
	local original_width = vim.api.nvim_win_get_width(0)

	-- Open the buffer in a vertical split
	vim.api.nvim_command("vsplit")
	vim.api.nvim_win_set_buf(0, chat_buffer)

	-- Set the width to 1/3 of the original window width
	local chat_width = math.floor(original_width / 3)
	vim.api.nvim_win_set_width(0, chat_width)

	-- Add initial chat content with instructions and tombstone
	local initial_content = {
		"# Paragonic Chat",
		"Multi-line input extraction modes:",
		"• <CR>: Send message (smart - auto-detects model capabilities)",
		"• <leader>b: Send backward only (cursor to previous ∎)",
		"• <leader>f: Send forward only (cursor to next ∎ or end)",
		"• <leader><CR>: Send with debug output",
		"∎",
		"",
	}

	-- Set initial content
	vim.api.nvim_buf_set_lines(chat_buffer, 0, -1, false, initial_content)

	-- Set filetype for syntax highlighting
	vim.api.nvim_buf_set_option(chat_buffer, "filetype", "markdown")

	-- Set up buffer-local keymaps for different extraction modes
	vim.api.nvim_buf_set_keymap(
		chat_buffer,
		"n",
		"<CR>",
		":ParagonicSendSmart<CR>",
		{ noremap = true, silent = true, desc = "Send message (smart - auto-detects model capabilities)" }
	)

	vim.api.nvim_buf_set_keymap(
		chat_buffer,
		"n",
		"<leader>b",
		":ParagonicSendBackward<CR>",
		{ noremap = true, silent = true, desc = "Send backward to tombstone" }
	)

	vim.api.nvim_buf_set_keymap(
		chat_buffer,
		"n",
		"<leader>f",
		":ParagonicSendForward<CR>",
		{ noremap = true, silent = true, desc = "Send forward to tombstone" }
	)

	vim.api.nvim_buf_set_keymap(
		chat_buffer,
		"n",
		"<leader><CR>",
		":ParagonicSendDebug<CR>",
		{ noremap = true, silent = true, desc = "Send with debug output" }
	)

	-- Move cursor to the end of the buffer
	vim.api.nvim_win_set_cursor(0, { #initial_content, 0 })

	debug.debug_print("📝 Chat buffer opened with instructions and tombstone", "debug")
end

-- Extract message from cursor position backwards to tombstone
local function extract_backward_to_tombstone(buffer)
	local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
	local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1 -- Convert to 0-indexed

	-- Find the last tombstone (∎) before cursor
	local start_line = cursor_line
	for i = cursor_line, 0, -1 do
		if lines[i + 1] and lines[i + 1]:match("^%s*∎") then
			start_line = i
			break
		end
	end

	-- Extract message from start_line + 1 to cursor_line
	local message_lines = {}
	for i = start_line + 1, cursor_line do
		if lines[i + 1] then
			table.insert(message_lines, lines[i + 1])
		end
	end

	local message = table.concat(message_lines, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
	return message, start_line
end

-- Create shared chunk handler for UI updates
local function create_shared_on_chunk_handler(buffer, start_line, window_id, enable_debug, original_message)
	local utils = require("paragonic.utils")
	local thinking_content_started = false
	local thinking_end_line = nil -- Track where thinking content ends
	local has_thinking_content = false -- Track if any thinking content was processed
	local assistant_content_started = false -- Track if assistant content has started

	return function(chunk_content, chunk_index, total_chunks, chunk_type)
		if not buffer or not vim.api.nvim_buf_is_valid(buffer) then
			return
		end

		if enable_debug then
			debug.debug_print(
				"📝 Processing chunk " .. chunk_index .. "/" .. total_chunks .. " with type: " .. chunk_type,
				"debug"
			)
		end

		-- Get current buffer lines
		local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)

		-- Handle different chunk types
		if chunk_type == "thinking_start" then
			-- Add thinking start marker with brain icon after user message
			local insert_line = start_line + 2 -- After user message
			table.insert(lines, insert_line + 1, "🧠 <think>")
			thinking_content_started = true
			thinking_end_line = insert_line + 1 -- Track the line after brain icon
			vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
		elseif chunk_type == "thinking_content" then
			-- Add thinking content with proper wrapping and continuation icons
			local buffer_width = ui.get_buffer_width(buffer)
			local wrapped_lines

			if enable_debug then
				debug.debug_print("🧠 Raw thinking content: " .. chunk_content, "debug")
			end

			has_thinking_content = true -- Mark that we have thinking content

			if not thinking_content_started then
				-- First thinking content - add brain icon and wrap to buffer width
				wrapped_lines = utils.wrap_text_with_brain(chunk_content, buffer_width - 4) -- Leave margin
				thinking_content_started = true
				-- Insert after the brain icon line
				local insert_line = start_line + 2

				if enable_debug then
					debug.debug_print("🧠 Wrapped lines count: " .. #wrapped_lines, "debug")
					for i, line in ipairs(wrapped_lines) do
						debug.debug_print("🧠 Line " .. i .. ": " .. line, "debug")
					end
				end

				-- Reverse the lines to fix the order issue
				for i = #wrapped_lines, 1, -1 do
					table.insert(lines, insert_line + 1, wrapped_lines[i])
				end
				thinking_end_line = insert_line + #wrapped_lines
			else
				-- Subsequent thinking content - add vertical continuation icon with consistent indentation
				wrapped_lines = M.wrap_thinking_content(chunk_content, buffer_width - 4, "⋮")
				-- Insert at the end of current thinking content
				-- Reverse the lines to fix the order issue
				for i = #wrapped_lines, 1, -1 do
					table.insert(lines, thinking_end_line + 1, wrapped_lines[i])
				end
				thinking_end_line = thinking_end_line + #wrapped_lines
			end
			vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
		elseif chunk_type == "thinking_end" then
			-- Add thinking end marker with completed hourglass after thinking content
			table.insert(lines, thinking_end_line + 1, "⌛ </think>")
			thinking_content_started = false
			vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
		elseif chunk_type == "assistant_start" then
			-- Add assistant start marker with lozenge icon after thinking section
			local insert_line = thinking_end_line and thinking_end_line + 1 or start_line + 2
			table.insert(lines, insert_line + 1, "◊")
			vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
		elseif chunk_type == "assistant_content" then
			-- Add assistant content with proper wrapping (no indentation for responses)
			local buffer_width = ui.get_buffer_width(buffer)
			local wrapped_lines = M.wrap_response_content(chunk_content, buffer_width - 4)

			-- Add lozenge icon for first assistant content chunk
			if not assistant_content_started then
				-- Insert lozenge icon before the first assistant content
				local insert_line = #lines
				table.insert(lines, insert_line + 1, "◊")
				assistant_content_started = true
			end

			-- Insert at the end of current content
			local insert_line = #lines
			-- Reverse the lines to fix the order issue (same as thinking content)
			for i = #wrapped_lines, 1, -1 do
				table.insert(lines, insert_line + 1, wrapped_lines[i])
			end
			vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
		else
			-- Default: add as regular content with proper wrapping (no indentation for responses)
			if enable_debug then
				debug.debug_print("📝 Default chunk content: " .. chunk_content, "debug")
			end

			-- Skip if this looks like the user's message being repeated
			-- Check if the chunk content matches the original message (case-insensitive, more flexible)
			local normalized_chunk = chunk_content:gsub("%s+", " "):lower():match("^%s*(.-)%s*$")
			local normalized_message = original_message:gsub("%s+", " "):lower():match("^%s*(.-)%s*$")

			if
				chunk_content
				and original_message
				and (
										-- Exact match (case-insensitive)
normalized_chunk == normalized_message
					-- Or contains the message as a substring (more flexible)
					or normalized_chunk:find(normalized_message, 1, true)
					-- Or the chunk is very similar to the original message (word-based comparison)
					or (#normalized_chunk == #normalized_message and normalized_chunk == normalized_message)
				)
			then
				if enable_debug then
					debug.debug_print("🚫 Skipping repeated user message: " .. chunk_content, "debug")
				end
				return
			end

			local buffer_width = ui.get_buffer_width(buffer)
			local wrapped_lines = M.wrap_response_content(chunk_content, buffer_width - 4)

			-- Add lozenge icon for first response content chunk (if not already added)
			if not assistant_content_started then
				-- Insert lozenge icon before the first response content
				local insert_line = #lines
				table.insert(lines, insert_line + 1, "◊")
				assistant_content_started = true
			end

			-- Insert at the end of current content
			local insert_line = #lines
			-- Reverse the lines to fix the order issue (same as thinking content)
			for i = #wrapped_lines, 1, -1 do
				table.insert(lines, insert_line + 1, wrapped_lines[i])
			end
			vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
		end

		-- Scroll to bottom
		local last_line = #lines
		if window_id and vim.api.nvim_win_is_valid(window_id) then
			vim.api.nvim_win_set_cursor(window_id, { last_line, 0 })
		end
	end, function()
		-- Completion callback
		if enable_debug then
			debug.debug_print("✅ Streaming completed", "success")
		end

		-- Add tombstone marker after completion
		if buffer and vim.api.nvim_buf_is_valid(buffer) then
			local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
			table.insert(lines, "")
			table.insert(lines, "∎")
			vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)

			-- Auto-fold thinking content if it exists
			if has_thinking_content then
				M.fold_thinking_content(buffer, start_line)
			end

			-- Scroll to bottom
			local last_line = #lines
			if window_id and vim.api.nvim_win_is_valid(window_id) then
				vim.api.nvim_win_set_cursor(window_id, { last_line, 0 })
			end
		end
	end
end

-- Send message with thinking streaming (new architecture)
function M.send_message_thinking_streaming(message, model, on_chunk, on_complete)
	if not chat_state.initialized then
		local ok = M.init()
		if not ok then
			debug.debug_print("❌ Failed to initialize chat module", "error")
			if on_complete then
				on_complete()
			end
			return false
		end
	end

	debug.debug_print("🧠 Starting thinking streaming session", "info")

	-- Start streaming session
	local session_id = streaming.start_session(message, model, {
		thinking_enabled = true,
		streaming_enabled = true,
	})

	if not session_id then
		debug.debug_print("❌ Failed to start streaming session", "error")
		if on_complete then
			on_complete()
		end
		return false
	end

	-- Get chunks from session
	local chunks = streaming.get_chunks(session_id)
	if not chunks then
		debug.debug_print("❌ No chunks received from session", "error")
		if on_complete then
			on_complete()
		end
		return false
	end

	-- Process chunks
	if chunks and #chunks > 0 then
		debug.debug_print("📝 Processing " .. #chunks .. " chunks", "debug")

		for i, chunk in ipairs(chunks) do
			if on_chunk then
				local chunk_type = chunk.chunk_type or "regular_content"
				debug.debug_print("📝 Processing chunk " .. i .. " with type: " .. chunk_type, "debug")
				on_chunk(chunk.chunk, chunk.chunk_index or i - 1, #chunks, chunk_type)
			end
		end
	end

	-- Cleanup session
	streaming.cleanup_session(session_id)

	-- Call completion callback
	if on_complete then
		on_complete()
	end

	debug.debug_print("✅ Thinking streaming session completed successfully", "success")
	return true
end

-- Send message command with thinking model support
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

	-- Get current model for display
	local current_model = config.get("ollama_model") or "deepseek-r1:1.5b"

	-- Add zigzag arrow and model name to indicate request is being sent
	vim.api.nvim_buf_set_lines(current_buf, line_num + 1, line_num + 1, false, { "↯ " .. current_model })

	-- Force buffer update to show zigzag and model name immediately
	vim.api.nvim_buf_call(current_buf, function()
		vim.cmd("redraw!")
	end)

	-- Add user message to buffer
	local user_lines = { "", message, "" }
	vim.api.nvim_buf_set_lines(current_buf, line_num + 2, line_num + 2, false, user_lines)

	-- Store the current window ID for later use in callbacks
	local chat_window_id = vim.api.nvim_get_current_win()

	-- Use shared on_chunk handler with debug disabled for normal operation
	local on_chunk, on_complete =
		create_shared_on_chunk_handler(current_buf, line_num + 1, chat_window_id, false, message)

	-- Send message with thinking streaming
	M.send_message_thinking_streaming(message, current_model, on_chunk, on_complete)
end

-- Send message command (smart - auto-detects thinking support)
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

	-- Get model and check thinking support
	local model = config.get("ollama_model") or "deepseek-r1:1.5b"
	local supports_thinking = config.model_supports_thinking(model)

	vim.notify(
		"📤 Sending ("
			.. (supports_thinking and "thinking" or "standard")
			.. " mode): "
			.. message:sub(1, 50)
			.. (message:len() > 50 and "..." or ""),
		vim.log.levels.INFO
	)

	-- Add zigzag arrow and model name to indicate request is being sent
	vim.api.nvim_buf_set_lines(current_buf, line_num + 1, line_num + 1, false, { "↯ " .. model })

	-- Force buffer update to show zigzag and model name immediately
	vim.api.nvim_buf_call(current_buf, function()
		vim.cmd("redraw!")
	end)

	-- Add user message to buffer
	local user_lines = { "", message, "" }
	vim.api.nvim_buf_set_lines(current_buf, line_num + 2, line_num + 2, false, user_lines)

	-- Store the current window ID for later use in callbacks
	local chat_window_id = vim.api.nvim_get_current_win()

	-- Use shared on_chunk handler with debug disabled for normal operation
	local on_chunk, on_complete =
		create_shared_on_chunk_handler(current_buf, line_num + 1, chat_window_id, false, message)

	-- Send message with appropriate method
	if supports_thinking then
		M.send_message_thinking_streaming(message, model, on_chunk, on_complete)
	else
		-- For non-thinking models, use regular streaming
		M.send_message_thinking_streaming(message, model, on_chunk, on_complete)
	end
end

-- Send message command (backward extraction)
function M.send_message_command_backward()
	local current_buf = vim.api.nvim_get_current_buf()
	local buf_name = vim.api.nvim_buf_get_name(current_buf)

	if buf_name ~= "paragonic://chat" then
		vim.notify("This command only works in the chat buffer", vim.log.levels.WARN)
		return
	end

	-- Extract message from cursor position backwards to tombstone
	local message, start_line = extract_backward_to_tombstone(current_buf)
	local line_num = vim.api.nvim_win_get_cursor(0)[1] - 1

	if message == "" or message:match("^%s*#") then
		vim.notify("Please enter a message to send", vim.log.levels.INFO)
		return
	end

	vim.notify(
		"📤 Sending (backward): " .. message:sub(1, 50) .. (message:len() > 50 and "..." or ""),
		vim.log.levels.INFO
	)

	-- Get current model for display
	local current_model = config.get("ollama_model") or "deepseek-r1:1.5b"

	-- Add zigzag arrow and model name to indicate request is being sent
	vim.api.nvim_buf_set_lines(current_buf, line_num + 1, line_num + 1, false, { "↯ " .. current_model })

	-- Force buffer update to show zigzag and model name immediately
	vim.api.nvim_buf_call(current_buf, function()
		vim.cmd("redraw!")
	end)

	-- Add user message to buffer
	local user_lines = { "", message, "" }
	vim.api.nvim_buf_set_lines(current_buf, line_num + 2, line_num + 2, false, user_lines)

	-- Store the current window ID for later use in callbacks
	local chat_window_id = vim.api.nvim_get_current_win()

	-- Use shared on_chunk handler with debug disabled for normal operation
	local on_chunk, on_complete =
		create_shared_on_chunk_handler(current_buf, line_num + 1, chat_window_id, false, message)

	-- Send message with thinking streaming
	M.send_message_thinking_streaming(message, current_model, on_chunk, on_complete)
end

-- Send message command (forward extraction)
function M.send_message_command_forward()
	local current_buf = vim.api.nvim_get_current_buf()
	local buf_name = vim.api.nvim_buf_get_name(current_buf)

	if buf_name ~= "paragonic://chat" then
		vim.notify("This command only works in the chat buffer", vim.log.levels.WARN)
		return
	end

	-- Extract message from cursor position forwards to tombstone or end
	local lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
	local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1
	local total_lines = #lines

	-- Find the next tombstone (∎) after cursor
	local end_line = total_lines
	for i = cursor_line + 1, total_lines do
		if lines[i + 1] and lines[i + 1]:match("^%s*∎") then
			end_line = i - 1
			break
		end
	end

	-- Extract message from cursor_line to end_line
	local message_lines = {}
	for i = cursor_line, end_line do
		if lines[i + 1] then
			table.insert(message_lines, lines[i + 1])
		end
	end

	local message = table.concat(message_lines, "\n"):gsub("^%s+", ""):gsub("%s+$", "")

	if message == "" or message:match("^%s*#") then
		vim.notify("Please enter a message to send", vim.log.levels.INFO)
		return
	end

	vim.notify(
		"📤 Sending (forward): " .. message:sub(1, 50) .. (message:len() > 50 and "..." or ""),
		vim.log.levels.INFO
	)

	-- Get current model for display
	local current_model = config.get("ollama_model") or "deepseek-r1:1.5b"

	-- Add zigzag arrow and model name to indicate request is being sent
	vim.api.nvim_buf_set_lines(current_buf, cursor_line + 1, cursor_line + 1, false, { "↯ " .. current_model })

	-- Force buffer update to show zigzag and model name immediately
	vim.api.nvim_buf_call(current_buf, function()
		vim.cmd("redraw!")
	end)

	-- Add user message to buffer
	local user_lines = { "", message, "" }
	vim.api.nvim_buf_set_lines(current_buf, cursor_line + 2, cursor_line + 2, false, user_lines)

	-- Store the current window ID for later use in callbacks
	local chat_window_id = vim.api.nvim_get_current_win()

	-- Use shared on_chunk handler with debug disabled for normal operation
	local on_chunk, on_complete =
		create_shared_on_chunk_handler(current_buf, cursor_line + 1, chat_window_id, false, message)

	-- Send message with thinking streaming
	M.send_message_thinking_streaming(message, current_model, on_chunk, on_complete)
end

-- Send message command (debug mode)
function M.send_message_command_debug()
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
		"🐛 Sending (debug mode): " .. message:sub(1, 50) .. (message:len() > 50 and "..." or ""),
		vim.log.levels.INFO
	)

	-- Get current model for display
	local current_model = config.get("ollama_model") or "deepseek-r1:1.5b"

	-- Add zigzag arrow and model name to indicate request is being sent
	vim.api.nvim_buf_set_lines(current_buf, line_num + 1, line_num + 1, false, { "↯ " .. current_model })

	-- Force buffer update to show zigzag and model name immediately
	vim.api.nvim_buf_call(current_buf, function()
		vim.cmd("redraw!")
	end)

	-- Add user message to buffer
	local user_lines = { "", message, "" }
	vim.api.nvim_buf_set_lines(current_buf, line_num + 2, line_num + 2, false, user_lines)

	-- Store the current window ID for later use in callbacks
	local chat_window_id = vim.api.nvim_get_current_win()

	-- Use shared on_chunk handler with debug enabled
	local on_chunk, on_complete =
		create_shared_on_chunk_handler(current_buf, line_num + 1, chat_window_id, true, message)

	-- Send message with thinking streaming
	M.send_message_thinking_streaming(message, current_model, on_chunk, on_complete)
end

-- Smart send message function (for programmatic use)
function M.send_message_smart(message, model)
	local target_model = model or config.get("ollama_model") or "deepseek-r1:1.5b"
	local supports_thinking = config.model_supports_thinking(target_model)

	if supports_thinking then
		return M.send_message_thinking_streaming(message, target_model)
	else
		return M.send_message_thinking_streaming(message, target_model)
	end
end

-- Custom wrapping function for response content (no indentation)
function M.wrap_response_content(text, max_width)
	-- Set default max_width if not provided
	max_width = max_width or 80

	if not text or text == "" then
		return { "" }
	end

	local lines = {}

	-- Split text into lines
	local text_lines = {}
	for line in text:gmatch("[^\r\n]+") do
		table.insert(text_lines, line)
	end

	-- Process each line with simple word wrapping (no indentation)
	for i, line in ipairs(text_lines) do
		if line:match("%S") then -- Only process non-empty lines
			-- Strip leading spaces from the line
			local clean_line = line:match("^%s*(.+)$")

			-- Word wrapping without any indentation
			local words = {}
			for word in clean_line:gmatch("[^%s]+") do
				table.insert(words, word)
			end

			local current_line = ""
			local current_length = 0

			for j, word in ipairs(words) do
				local word_length = #word

				-- If adding this word would exceed the line limit
				if current_length + word_length > max_width then
					-- Add current line to lines (if not empty)
					if current_line ~= "" then
						table.insert(lines, current_line)
					end
					-- Start new line with no indentation
					current_line = word
					current_length = word_length
				else
					-- Add word to current line (with space if not first word)
					if current_line ~= "" then
						current_line = current_line .. " " .. word
						current_length = current_length + 1 + word_length
					else
						current_line = word
						current_length = word_length
					end
				end
			end

			-- Add the last line if it has content
			if current_line ~= "" then
				table.insert(lines, current_line)
			end
		end
	end

	return lines
end

-- Custom wrapping function for thinking content with continuation marker only on first line
function M.wrap_thinking_content(text, max_width, glyph)
	-- Set default max_width if not provided
	max_width = max_width or 80

	-- Set default glyph if not provided
	glyph = glyph or "⋮"

	if not text or text == "" then
		return { glyph .. "  " }
	end

	local lines = {}

	-- Split text into lines
	local text_lines = {}
	for line in text:gmatch("[^\r\n]+") do
		table.insert(text_lines, line)
	end

	-- Process each line with continuation marker only on first line
	for i, line in ipairs(text_lines) do
		if line:match("%S") then -- Only process non-empty lines
			-- Strip leading spaces from the line
			local clean_line = line:match("^%s*(.+)$")

			-- Word wrapping with continuation marker only on first line
			local words = {}
			for word in clean_line:gmatch("[^%s]+") do
				table.insert(words, word)
			end

			local is_first_line = true
			local current_line = ""
			local current_length = 0
			local text_start_pos = 3 -- Position where text content starts (3 spaces after glyph)

			for j, word in ipairs(words) do
				local word_length = #word

				-- If adding this word would exceed the line limit
				if current_length + word_length > max_width then
					-- Add current line to lines (if not empty)
					if current_line ~= "" then
						table.insert(lines, current_line)
					end
					-- Start new line with indentation that aligns with text content start
					current_line = string.rep(" ", text_start_pos) .. word
					current_length = text_start_pos + word_length
				else
					-- Add word to current line (with space if not first word)
					if current_line ~= "" then
						current_line = current_line .. " " .. word
						current_length = current_length + 1 + word_length
					else
						-- First word on the line - only add glyph to the very first line
						if is_first_line then
							current_line = glyph .. "  " .. word
							current_length = #glyph + 2 + word_length
							is_first_line = false
						else
							current_line = string.rep(" ", text_start_pos) .. word
							current_length = text_start_pos + word_length
						end
					end
				end
			end

			-- Add the last line if it has content
			if current_line ~= "" then
				table.insert(lines, current_line)
			end
		end
	end

	return lines
end

-- Function to auto-fold thinking content between brain and hourglass markers
function M.fold_thinking_content(current_buf, start_line_num)
	-- Enable folding for the buffer
	vim.api.nvim_buf_set_option(current_buf, "foldmethod", "marker")
	vim.api.nvim_buf_set_option(current_buf, "foldmarker", "🧠,⌛")

	-- Get all lines in the buffer
	local all_lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)

	-- Find the thinking section that starts after the given line number
	local thinking_start_line = nil
	local thinking_end_line = nil

	for i = start_line_num + 2, #all_lines do -- +2 to skip the user message and start looking after it
		local line = all_lines[i]
		if line and line:match("^🧠%s*<think>") then
			thinking_start_line = i - 1 -- Convert to 0-indexed
		elseif line and line:match("^⌛%s*</think>") and thinking_start_line then
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
			vim.api.nvim_buf_set_lines(current_buf, fold_start, fold_start + 1, false, { start_line_content .. " {{{" })
		end

		if end_line_content and not end_line_content:match("}}}$") then
			vim.api.nvim_buf_set_lines(current_buf, fold_end, fold_end + 1, false, { end_line_content .. " }}}" })
		end

		-- Close the fold using a more reliable approach
		vim.defer_fn(function()
			-- Check if the buffer and lines still exist
			if vim.api.nvim_buf_is_valid(current_buf) and fold_start < vim.api.nvim_buf_line_count(current_buf) then
				-- Use a more reliable way to close the fold
				vim.api.nvim_buf_call(current_buf, function()
					-- Move to the fold start line
					vim.cmd("normal! " .. (fold_start + 1) .. "G")
					-- Close the fold
					vim.cmd("foldclose")
					-- Force redraw to show the fold
					vim.cmd("redraw!")
				end)
			end
		end, 200) -- Increased delay to ensure buffer is ready

		-- Move cursor back to the end
		vim.defer_fn(function()
			if vim.api.nvim_buf_is_valid(current_buf) then
				local buffer_line_count = vim.api.nvim_buf_line_count(current_buf)
				vim.api.nvim_win_set_cursor(0, { buffer_line_count, 0 })
			end
		end, 250)

		debug.debug_print("🧠 Created fold from line " .. fold_start .. " to " .. fold_end, "debug")
	else
		debug.debug_print("🧠 No thinking section found to fold", "debug")
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

-- Debug markdown test
function M.send_debug_markdown_test()
	local current_buf = vim.api.nvim_get_current_buf()
	local buf_name = vim.api.nvim_buf_get_name(current_buf)

	if buf_name ~= "paragonic://chat" then
		vim.notify("This command only works in the chat buffer", vim.log.levels.WARN)
		return
	end

	local test_message =
		"Please format this as markdown: # Hello World\n\nThis is a **test** message with *italic* text and `code`."

	vim.notify("🐛 Sending debug markdown test", vim.log.levels.INFO)

	-- Add user message to buffer
	local line_num = vim.api.nvim_win_get_cursor(0)[1] - 1
	local user_lines = { "", test_message, "" }
	vim.api.nvim_buf_set_lines(current_buf, line_num + 1, line_num + 1, false, user_lines)

	-- Store the current window ID for later use in callbacks
	local chat_window_id = vim.api.nvim_get_current_win()

	-- Use shared on_chunk handler with debug enabled
	local on_chunk, on_complete =
		create_shared_on_chunk_handler(current_buf, line_num, chat_window_id, true, test_message)

	-- Send message with thinking streaming
	M.send_message_thinking_streaming(test_message, nil, on_chunk, on_complete)
end

-- Get chat status
function M.get_status()
	return {
		initialized = chat_state.initialized,
		active_sessions_count = #chat_state.active_sessions,
		streaming_status = streaming.get_status(),
		ui_status = ui.get_status(),
	}
end

-- Cleanup chat module
function M.cleanup()
	debug.debug_print("🔧 Cleaning up chat module", "info")

	-- Cleanup streaming layer
	streaming.cleanup()

	-- Cleanup UI layer
	ui.cleanup()

	-- Reset chat state
	chat_state.initialized = false
	chat_state.active_sessions = {}

	debug.debug_print("✅ Chat module cleaned up", "success")
end

return M
