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
	local streaming_ok = streaming.init(config.get_all())
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

	-- Open the buffer in a new window
	vim.api.nvim_command("split")
	vim.api.nvim_win_set_buf(0, chat_buffer)

	-- Add welcome message
	ui.append_message(chat_buffer, "Welcome to Paragonic Chat! Type your message and press Enter to send.", "system")

	debug.debug_print("📝 Chat buffer opened", "debug")
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
local function create_shared_on_chunk_handler(buffer, start_line, window_id, enable_debug)
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
		local current_line = start_line + 2 -- Start after user message

		-- Handle different chunk types
		if chunk_type == "thinking_start" then
			-- Add thinking start marker
			table.insert(lines, current_line + 1, "🧠 <think>")
			vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
		elseif chunk_type == "thinking_content" then
			-- Add thinking content
			table.insert(lines, current_line + 1, "   " .. chunk_content)
			vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
		elseif chunk_type == "thinking_end" then
			-- Add thinking end marker
			table.insert(lines, current_line + 1, "󱦟 </think>")
			vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
		elseif chunk_type == "assistant_start" then
			-- Add assistant start marker
			table.insert(lines, current_line + 1, "🮮")
			vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
		elseif chunk_type == "assistant_content" then
			-- Add assistant content
			table.insert(lines, current_line + 1, "   " .. chunk_content)
			vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
		else
			-- Default: add as regular content
			table.insert(lines, current_line + 1, chunk_content)
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

	-- Add user message to buffer
	local user_lines = { "", message, "" }
	vim.api.nvim_buf_set_lines(current_buf, line_num + 1, line_num + 1, false, user_lines)

	-- Store the current window ID for later use in callbacks
	local chat_window_id = vim.api.nvim_get_current_win()

	-- Use shared on_chunk handler with debug disabled for normal operation
	local on_chunk, on_complete = create_shared_on_chunk_handler(current_buf, line_num, chat_window_id, false)

	-- Send message with thinking streaming
	M.send_message_thinking_streaming(message, nil, on_chunk, on_complete)
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

	-- Add user message to buffer
	local user_lines = { "", message, "" }
	vim.api.nvim_buf_set_lines(current_buf, line_num + 1, line_num + 1, false, user_lines)

	-- Store the current window ID for later use in callbacks
	local chat_window_id = vim.api.nvim_get_current_win()

	-- Use shared on_chunk handler with debug disabled for normal operation
	local on_chunk, on_complete = create_shared_on_chunk_handler(current_buf, line_num, chat_window_id, false)

	-- Send message with appropriate method
	if supports_thinking then
		M.send_message_thinking_streaming(message, model, on_chunk, on_complete)
	else
		-- For non-thinking models, use regular streaming
		M.send_message_thinking_streaming(message, model, on_chunk, on_complete)
	end
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

	-- Add user message to buffer
	local user_lines = { "", message, "" }
	vim.api.nvim_buf_set_lines(current_buf, line_num + 1, line_num + 1, false, user_lines)

	-- Store the current window ID for later use in callbacks
	local chat_window_id = vim.api.nvim_get_current_win()

	-- Use shared on_chunk handler with debug enabled
	local on_chunk, on_complete = create_shared_on_chunk_handler(current_buf, line_num, chat_window_id, true)

	-- Send message with thinking streaming
	M.send_message_thinking_streaming(message, nil, on_chunk, on_complete)
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
	local on_chunk, on_complete = create_shared_on_chunk_handler(current_buf, line_num, chat_window_id, true)

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
