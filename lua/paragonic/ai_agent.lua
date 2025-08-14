--[[
Paragonic AI Agent Module
Handles AI agent collaboration functionality
--]]

local M = {}

-- AI agent collaboration state
local ai_agent_sessions = {}
local active_agent_id = nil
local agent_collaboration_mode = false

-- Start AI agent collaboration session
function M.start_ai_agent_session(agent_name, capabilities)
	if agent_collaboration_mode then
		vim.notify("AI agent collaboration already active. Stop current session first.", vim.log.levels.WARN)
		return false
	end

	local session_id = vim.fn.strftime("%Y%m%d_%H%M%S") .. "_" .. (agent_name or "ai_agent")

	local session = {
		id = session_id,
		name = agent_name or "AI Agent",
		capabilities = capabilities or {},
		start_time = os.time(),
		context = {
			current_file = vim.fn.expand("%"),
			current_directory = vim.fn.getcwd(),
			buffers = vim.api.nvim_list_bufs(),
			mode = vim.fn.mode(),
		},
		interactions = {},
	}

	ai_agent_sessions[session_id] = session
	active_agent_id = session_id
	agent_collaboration_mode = true

	vim.notify("Started AI agent collaboration session: " .. session_id, vim.log.levels.INFO)

	-- Execute session start patterns
	M.execute_session_pattern("Session Summary Generation", {
		event_type = "session_start",
		agent_name = agent_name,
		capabilities = capabilities,
	})

	return session_id
end

-- Stop AI agent collaboration session
function M.stop_ai_agent_session()
	if not agent_collaboration_mode or not active_agent_id then
		vim.notify("No active AI agent collaboration session to stop.", vim.log.levels.WARN)
		return false
	end

	local session = ai_agent_sessions[active_agent_id]
	if session then
		session.end_time = os.time()
		session.duration = session.end_time - session.start_time
		session.final_context = {
			current_file = vim.fn.expand("%"),
			current_directory = vim.fn.getcwd(),
			buffers = vim.api.nvim_list_bufs(),
			mode = vim.fn.mode(),
		}

		vim.notify(
			"Stopped AI agent collaboration session: " .. active_agent_id .. " (Duration: " .. session.duration .. "s)",
			vim.log.levels.INFO
		)
	end

	-- Execute session stop patterns before clearing session
	M.execute_session_pattern("Session Summary Generation", {
		event_type = "session_stop",
	})

	agent_collaboration_mode = false
	active_agent_id = nil

	return true
end

-- Send message from AI agent to Neovim
function M.send_ai_agent_message(message, message_type)
	if not agent_collaboration_mode or not active_agent_id then
		return false, "No active AI agent collaboration session"
	end

	local session = ai_agent_sessions[active_agent_id]
	if not session then
		return false, "Session data not found"
	end

	-- Create message object
	local message_obj = {
		id = #session.interactions + 1,
		timestamp = os.time(),
		type = message_type or "message",
		content = message,
		from_agent = true,
		status = "sent",
	}

	-- Add to session interactions
	table.insert(session.interactions, message_obj)

	-- Update session context
	session.context = {
		current_file = vim.fn.expand("%"),
		current_directory = vim.fn.getcwd(),
		buffer_count = #vim.api.nvim_list_bufs(),
		mode = vim.fn.mode(),
	}

	-- Notify user of AI message
	vim.notify("🤖 AI Agent: " .. message, vim.log.levels.INFO)

	-- Check for pattern triggers after message
	M.check_and_trigger_patterns()

	return true, message_obj.id
end

-- Receive message from Neovim to AI agent
function M.receive_ai_agent_message(message, message_type)
	if not agent_collaboration_mode or not active_agent_id then
		return false, "No active AI agent collaboration session"
	end

	local session = ai_agent_sessions[active_agent_id]
	if not session then
		return false, "Session data not found"
	end

	-- Create message object
	local message_obj = {
		id = #session.interactions + 1,
		timestamp = os.time(),
		type = message_type or "message",
		content = message,
		from_agent = false,
		status = "received",
	}

	-- Add to session interactions
	table.insert(session.interactions, message_obj)

	-- Update session context
	session.context = {
		current_file = vim.fn.expand("%"),
		current_directory = vim.fn.getcwd(),
		buffer_count = #vim.api.nvim_list_bufs(),
		mode = vim.fn.mode(),
	}

	-- Log the received message
	vim.notify("📥 Neovim: " .. message, vim.log.levels.INFO)

	-- Check for pattern triggers after message
	M.check_and_trigger_patterns()

	return true, message_obj.id
end

-- Execute Neovim command from AI agent
function M.execute_ai_agent_command(command, description)
	if not agent_collaboration_mode or not active_agent_id then
		return false, "No active AI agent collaboration session"
	end

	local session = ai_agent_sessions[active_agent_id]
	if not session then
		return false, "Session data not found"
	end

	if not command or command == "" then
		return false, "Command is required"
	end

	-- Create action object
	local action_obj = {
		id = #session.interactions + 1,
		timestamp = os.time(),
		type = "command",
		content = command,
		description = description or "AI agent command execution",
		from_agent = true,
		status = "executing",
	}

	-- Add to session interactions
	table.insert(session.interactions, action_obj)

	-- Execute the command
	local success, result = pcall(vim.cmd, command)

	-- Update action status
	if success then
		action_obj.status = "completed"
		action_obj.result = "Command executed successfully"
	else
		action_obj.status = "failed"
		action_obj.result = "Command failed: " .. tostring(result)
	end

	-- Update session context
	session.context = {
		current_file = vim.fn.expand("%"),
		current_directory = vim.fn.getcwd(),
		buffer_count = #vim.api.nvim_list_bufs(),
		mode = vim.fn.mode(),
	}

	-- Notify user of AI command execution
	local status_icon = success and "✅" or "❌"
	vim.notify(status_icon .. " AI Agent Command: " .. command, vim.log.levels.INFO)

	-- Check for pattern triggers after command
	if success then
		M.check_and_trigger_patterns()
	end

	return success, action_obj.id, action_obj.result
end

-- Get buffer content from AI agent
function M.get_ai_agent_buffer_content(buffer_id, start_line, end_line)
	if not agent_collaboration_mode or not active_agent_id then
		return false, "No active AI agent collaboration session"
	end

	local session = ai_agent_sessions[active_agent_id]
	if not session then
		return false, "Session data not found"
	end

	-- Use current buffer if not specified
	buffer_id = buffer_id or vim.api.nvim_get_current_buf()

	-- Validate buffer exists
	if not vim.api.nvim_buf_is_valid(buffer_id) then
		return false, "Invalid buffer ID: " .. tostring(buffer_id)
	end

	-- Get buffer name
	local buffer_name = vim.api.nvim_buf_get_name(buffer_id)

	-- Get buffer content
	local lines = vim.api.nvim_buf_get_lines(buffer_id, 0, -1, false)

	-- Apply line range if specified
	if start_line and end_line then
		start_line = math.max(0, start_line - 1) -- Convert to 0-based
		end_line = math.min(#lines, end_line) -- Convert to 0-based
		lines = vim.list_slice(lines, start_line + 1, end_line)
	end

	-- Create action object
	local action_obj = {
		id = #session.interactions + 1,
		timestamp = os.time(),
		type = "buffer_read",
		content = "Get buffer content",
		description = string.format("Read buffer %d (%s)", buffer_id, buffer_name),
		from_agent = true,
		status = "completed",
		result = {
			buffer_id = buffer_id,
			buffer_name = buffer_name,
			line_count = #lines,
			content = lines,
			start_line = start_line and (start_line + 1) or 1,
			end_line = end_line or #lines,
		},
	}

	-- Add to session interactions
	table.insert(session.interactions, action_obj)

	-- Update session context
	session.context = {
		current_file = vim.fn.expand("%"),
		current_directory = vim.fn.getcwd(),
		buffer_count = #vim.api.nvim_list_bufs(),
		mode = vim.fn.mode(),
	}

	-- Notify user of AI buffer read
	vim.notify("📖 AI Agent: Read buffer " .. buffer_id .. " (" .. #lines .. " lines)", vim.log.levels.INFO)

	return true, action_obj.id, action_obj.result
end

-- Set buffer content from AI agent
function M.set_ai_agent_buffer_content(buffer_id, lines, start_line, end_line)
	if not agent_collaboration_mode or not active_agent_id then
		return false, "No active AI agent collaboration session"
	end

	local session = ai_agent_sessions[active_agent_id]
	if not session then
		return false, "Session data not found"
	end

	-- Use current buffer if not specified
	buffer_id = buffer_id or vim.api.nvim_get_current_buf()

	-- Validate buffer exists
	if not vim.api.nvim_buf_is_valid(buffer_id) then
		return false, "Invalid buffer ID: " .. tostring(buffer_id)
	end

	-- Validate lines input
	if not lines or type(lines) ~= "table" then
		return false, "Lines must be a table of strings"
	end

	-- Get buffer name
	local buffer_name = vim.api.nvim_buf_get_name(buffer_id)

	-- Determine line range
	local start_idx = 0
	local end_idx = -1

	if start_line and end_line then
		start_idx = math.max(0, start_line - 1) -- Convert to 0-based
		end_idx = start_idx + #lines - 1 -- Set end to accommodate new content
	end

	-- Create action object
	local action_obj = {
		id = #session.interactions + 1,
		timestamp = os.time(),
		type = "buffer_write",
		content = "Set buffer content",
		description = string.format("Write to buffer %d (%s)", buffer_id, buffer_name),
		from_agent = true,
		status = "executing",
	}

	-- Add to session interactions
	table.insert(session.interactions, action_obj)

	-- Set buffer content
	local success, result = pcall(vim.api.nvim_buf_set_lines, buffer_id, start_idx, end_idx, false, lines)

	-- Update action status
	if success then
		action_obj.status = "completed"
		action_obj.result = {
			buffer_id = buffer_id,
			buffer_name = buffer_name,
			lines_written = #lines,
			start_line = start_idx + 1,
			end_line = end_idx + 1,
			message = "Buffer content updated successfully",
		}
	else
		action_obj.status = "failed"
		action_obj.result = {
			buffer_id = buffer_id,
			buffer_name = buffer_name,
			error = tostring(result),
			message = "Failed to update buffer content",
		}
	end

	-- Update session context
	session.context = {
		current_file = vim.fn.expand("%"),
		current_directory = vim.fn.getcwd(),
		buffer_count = #vim.api.nvim_list_bufs(),
		mode = vim.fn.mode(),
	}

	-- Notify user of AI buffer write
	local status_icon = success and "✏️" or "❌"
	vim.notify(
		status_icon .. " AI Agent: Write to buffer " .. buffer_id .. " (" .. #lines .. " lines)",
		vim.log.levels.INFO
	)

	return success, action_obj.id, action_obj.result
end

-- AI Agent Action Functions for Enhanced Collaboration

-- Switch to a specific buffer
function M.ai_agent_switch_buffer(buffer_id)
	if not agent_collaboration_mode or not active_agent_id then
		return false, "No active AI agent collaboration session"
	end

	local session = ai_agent_sessions[active_agent_id]
	if not session then
		return false, "Session data not found"
	end

	-- Use current buffer if not specified
	buffer_id = buffer_id or vim.api.nvim_get_current_buf()

	-- Validate buffer exists
	if not vim.api.nvim_buf_is_valid(buffer_id) then
		return false, "Invalid buffer ID: " .. tostring(buffer_id)
	end

	-- Get buffer name
	local buffer_name = vim.api.nvim_buf_get_name(buffer_id)

	-- Create action object
	local action_obj = {
		id = #session.interactions + 1,
		timestamp = os.time(),
		type = "switch_buffer",
		content = "Switch to buffer",
		description = string.format("Switch to buffer %d (%s)", buffer_id, buffer_name),
		from_agent = true,
		status = "executing",
	}

	-- Add to session interactions
	table.insert(session.interactions, action_obj)

	-- Switch to the buffer
	local success, result = pcall(vim.api.nvim_set_current_buf, buffer_id)

	-- Update action status
	if success then
		action_obj.status = "completed"
		action_obj.result = {
			buffer_id = buffer_id,
			buffer_name = buffer_name,
			message = "Successfully switched to buffer",
		}
	else
		action_obj.status = "failed"
		action_obj.result = {
			buffer_id = buffer_id,
			buffer_name = buffer_name,
			error = tostring(result),
			message = "Failed to switch to buffer",
		}
	end

	-- Update session context
	session.context = {
		current_file = vim.fn.expand("%"),
		current_directory = vim.fn.getcwd(),
		buffer_count = #vim.api.nvim_list_bufs(),
		mode = vim.fn.mode(),
	}

	-- Notify user of AI buffer switch
	local status_icon = success and "🔄" or "❌"
	vim.notify(status_icon .. " AI Agent: Switch to buffer " .. buffer_id, vim.log.levels.INFO)

	return success, action_obj.id, action_obj.result
end

-- Set cursor position in current buffer
function M.ai_agent_set_cursor(line, column)
	if not agent_collaboration_mode or not active_agent_id then
		return false, "No active AI agent collaboration session"
	end

	local session = ai_agent_sessions[active_agent_id]
	if not session then
		return false, "Session data not found"
	end

	-- Use current window
	local current_win = vim.api.nvim_get_current_win()

	-- Validate line and column
	line = line or 1
	column = column or 0

	-- Get buffer info
	local current_buf = vim.api.nvim_get_current_buf()
	local buffer_name = vim.api.nvim_buf_get_name(current_buf)
	local line_count = vim.api.nvim_buf_line_count(current_buf)

	-- Validate line number
	if line < 1 or line > line_count then
		return false, "Line number out of range: " .. line .. " (valid range: 1-" .. line_count .. ")"
	end

	-- Create action object
	local action_obj = {
		id = #session.interactions + 1,
		timestamp = os.time(),
		type = "set_cursor",
		content = "Set cursor position",
		description = string.format("Set cursor to line %d, column %d in buffer %d", line, column, current_buf),
		from_agent = true,
		status = "executing",
	}

	-- Add to session interactions
	table.insert(session.interactions, action_obj)

	-- Set cursor position (convert to 0-based)
	local success, result = pcall(vim.api.nvim_win_set_cursor, current_win, { line, column })

	-- Update action status
	if success then
		action_obj.status = "completed"
		action_obj.result = {
			window_id = current_win,
			buffer_id = current_buf,
			buffer_name = buffer_name,
			line = line,
			column = column,
			message = "Cursor position set successfully",
		}
	else
		action_obj.status = "failed"
		action_obj.result = {
			window_id = current_win,
			buffer_id = current_buf,
			buffer_name = buffer_name,
			error = tostring(result),
			message = "Failed to set cursor position",
		}
	end

	-- Update session context
	session.context = {
		current_file = vim.fn.expand("%"),
		current_directory = vim.fn.getcwd(),
		buffer_count = #vim.api.nvim_list_bufs(),
		mode = vim.fn.mode(),
	}

	-- Notify user of AI cursor movement
	local status_icon = success and "📍" or "❌"
	vim.notify(status_icon .. " AI Agent: Set cursor to line " .. line .. ", column " .. column, vim.log.levels.INFO)

	return success, action_obj.id, action_obj.result
end

-- Create a new window and switch to it
function M.ai_agent_create_window(split_type, buffer_id)
	if not agent_collaboration_mode or not active_agent_id then
		return false, "No active AI agent collaboration session"
	end

	local session = ai_agent_sessions[active_agent_id]
	if not session then
		return false, "Session data not found"
	end

	-- Use current buffer if not specified
	buffer_id = buffer_id or vim.api.nvim_get_current_buf()

	-- Validate buffer exists
	if not vim.api.nvim_buf_is_valid(buffer_id) then
		return false, "Invalid buffer ID: " .. tostring(buffer_id)
	end

	-- Default split type
	split_type = split_type or "split"

	-- Get buffer name
	local buffer_name = vim.api.nvim_buf_get_name(buffer_id)

	-- Create action object
	local action_obj = {
		id = #session.interactions + 1,
		timestamp = os.time(),
		type = "create_window",
		content = "Create new window",
		description = string.format("Create %s window with buffer %d (%s)", split_type, buffer_id, buffer_name),
		from_agent = true,
		status = "executing",
	}

	-- Add to session interactions
	table.insert(session.interactions, action_obj)

	-- Create window
	local success, result = pcall(function()
		if split_type == "split" then
			vim.cmd("split")
		elseif split_type == "vsplit" then
			vim.cmd("vsplit")
		elseif split_type == "tabnew" then
			vim.cmd("tabnew")
		else
			error("Invalid split type: " .. split_type)
		end

		-- Switch to the specified buffer in the new window
		vim.api.nvim_set_current_buf(buffer_id)

		return vim.api.nvim_get_current_win()
	end)

	-- Update action status
	if success then
		local new_win = result
		action_obj.status = "completed"
		action_obj.result = {
			window_id = new_win,
			buffer_id = buffer_id,
			buffer_name = buffer_name,
			split_type = split_type,
			message = "Window created successfully",
		}
	else
		action_obj.status = "failed"
		action_obj.result = {
			buffer_id = buffer_id,
			buffer_name = buffer_name,
			split_type = split_type,
			error = tostring(result),
			message = "Failed to create window",
		}
	end

	-- Update session context
	session.context = {
		current_file = vim.fn.expand("%"),
		current_directory = vim.fn.getcwd(),
		buffer_count = #vim.api.nvim_list_bufs(),
		mode = vim.fn.mode(),
	}

	-- Notify user of AI window creation
	local status_icon = success and "🪟" or "❌"
	vim.notify(status_icon .. " AI Agent: Create " .. split_type .. " window", vim.log.levels.INFO)

	return success, action_obj.id, action_obj.result
end

-- Insert text at cursor position
function M.ai_agent_insert_text(text, mode)
	if not agent_collaboration_mode or not active_agent_id then
		return false, "No active AI agent collaboration session"
	end

	local session = ai_agent_sessions[active_agent_id]
	if not session then
		return false, "Session data not found"
	end

	if not text or text == "" then
		return false, "Text content is required"
	end

	-- Default mode
	mode = mode or "insert"

	-- Get current buffer info
	local current_buf = vim.api.nvim_get_current_buf()
	local buffer_name = vim.api.nvim_buf_get_name(current_buf)
	local cursor_pos = vim.api.nvim_win_get_cursor(0)

	-- Create action object
	local action_obj = {
		id = #session.interactions + 1,
		timestamp = os.time(),
		type = "insert_text",
		content = "Insert text",
		description = string.format("Insert text in %s mode at line %d", mode, cursor_pos[1]),
		from_agent = true,
		status = "executing",
	}

	-- Add to session interactions
	table.insert(session.interactions, action_obj)

	-- Insert text based on mode
	local success, result = pcall(function()
		if mode == "insert" then
			-- Enter insert mode and insert text
			vim.cmd("startinsert")
			vim.api.nvim_put({ text }, "", false, true)
			vim.cmd("stopinsert")
		elseif mode == "append" then
			-- Enter insert mode after cursor and insert text
			vim.cmd("startinsert!")
			vim.api.nvim_put({ text }, "", false, true)
			vim.cmd("stopinsert")
		elseif mode == "replace" then
			-- Replace current line with text
			local lines = { text }
			vim.api.nvim_buf_set_lines(current_buf, cursor_pos[1] - 1, cursor_pos[1], false, lines)
		else
			error("Invalid mode: " .. mode)
		end

		return "Text inserted successfully"
	end)

	-- Update action status
	if success then
		action_obj.status = "completed"
		action_obj.result = {
			buffer_id = current_buf,
			buffer_name = buffer_name,
			text = text,
			mode = mode,
			line = cursor_pos[1],
			column = cursor_pos[2],
			message = result,
		}
	else
		action_obj.status = "failed"
		action_obj.result = {
			buffer_id = current_buf,
			buffer_name = buffer_name,
			text = text,
			mode = mode,
			error = tostring(result),
			message = "Failed to insert text",
		}
	end

	-- Update session context
	session.context = {
		current_file = vim.fn.expand("%"),
		current_directory = vim.fn.getcwd(),
		buffer_count = #vim.api.nvim_list_bufs(),
		mode = vim.fn.mode(),
	}

	-- Notify user of AI text insertion
	local status_icon = success and "✍️" or "❌"
	vim.notify(status_icon .. " AI Agent: Insert text (" .. mode .. " mode)", vim.log.levels.INFO)

	return success, action_obj.id, action_obj.result
end

-- Get current Neovim state for AI agent
function M.ai_agent_get_state()
	if not agent_collaboration_mode or not active_agent_id then
		return false, "No active AI agent collaboration session"
	end

	local session = ai_agent_sessions[active_agent_id]
	if not session then
		return false, "Session data not found"
	end

	-- Get comprehensive state information
	local state = {
		timestamp = os.time(),
		buffers = {},
		windows = {},
		current_buffer = vim.api.nvim_get_current_buf(),
		current_window = vim.api.nvim_get_current_win(),
		cursor_position = vim.api.nvim_win_get_cursor(0),
		mode = vim.fn.mode(),
		current_file = vim.fn.expand("%:p"),
		current_directory = vim.fn.getcwd(),
		terminal_size = {
			columns = vim.o.columns,
			lines = vim.o.lines,
		},
	}

	-- Get buffer information
	local buffers = vim.api.nvim_list_bufs()
	for _, buf in ipairs(buffers) do
		if vim.api.nvim_buf_is_valid(buf) then
			local buf_name = vim.api.nvim_buf_get_name(buf)
			local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
			local modifiable = vim.api.nvim_buf_get_option(buf, "modifiable")
			local line_count = vim.api.nvim_buf_line_count(buf)
			local modified = vim.api.nvim_buf_get_option(buf, "modified")

			table.insert(state.buffers, {
				id = buf,
				name = buf_name,
				type = buftype,
				modifiable = modifiable,
				line_count = line_count,
				modified = modified,
				is_current = (buf == state.current_buffer),
			})
		end
	end

	-- Get window information
	local windows = vim.api.nvim_list_wins()
	for _, win in ipairs(windows) do
		if vim.api.nvim_win_is_valid(win) then
			local buf = vim.api.nvim_win_get_buf(win)
			local cursor = vim.api.nvim_win_get_cursor(win)
			local pos = vim.api.nvim_win_get_position(win)
			local size = vim.api.nvim_win_get_width(win), vim.api.nvim_win_get_height(win)

			table.insert(state.windows, {
				id = win,
				buffer_id = buf,
				cursor_line = cursor[1],
				cursor_column = cursor[2],
				position = { row = pos[1], col = pos[2] },
				size = { width = size, height = size },
				is_current = (win == state.current_window),
			})
		end
	end

	-- Create action object
	local action_obj = {
		id = #session.interactions + 1,
		timestamp = os.time(),
		type = "get_state",
		content = "Get Neovim state",
		description = "Retrieve current Neovim state for AI agent",
		from_agent = true,
		status = "completed",
		result = state,
	}

	-- Add to session interactions
	table.insert(session.interactions, action_obj)

	-- Update session context
	session.context = {
		current_file = vim.fn.expand("%"),
		current_directory = vim.fn.getcwd(),
		buffer_count = #vim.api.nvim_list_bufs(),
		mode = vim.fn.mode(),
	}

	-- Notify user of AI state retrieval
	vim.notify("📊 AI Agent: Retrieved Neovim state", vim.log.levels.INFO)

	return true, action_obj.id, state
end

-- Execute a sequence of AI agent actions
function M.ai_agent_execute_sequence(actions)
	if not agent_collaboration_mode or not active_agent_id then
		return false, "No active AI agent collaboration session"
	end

	local session = ai_agent_sessions[active_agent_id]
	if not session then
		return false, "Session data not found"
	end

	if not actions or type(actions) ~= "table" or #actions == 0 then
		return false, "Actions sequence is required"
	end

	-- Create action object for the sequence
	local action_obj = {
		id = #session.interactions + 1,
		timestamp = os.time(),
		type = "execute_sequence",
		content = "Execute action sequence",
		description = string.format("Execute sequence of %d actions", #actions),
		from_agent = true,
		status = "executing",
		sequence_results = {},
	}

	-- Add to session interactions
	table.insert(session.interactions, action_obj)

	-- Execute each action in sequence
	local success_count = 0
	local failed_count = 0

	for i, action in ipairs(actions) do
		local action_type = action.type
		local action_params = action.params or {}

		local success, result_id, result

		if action_type == "command" then
			success, result_id, result = M.execute_ai_agent_command(action_params.command, action_params.description)
		elseif action_type == "switch_buffer" then
			success, result_id, result = M.ai_agent_switch_buffer(action_params.buffer_id)
		elseif action_type == "set_cursor" then
			success, result_id, result = M.ai_agent_set_cursor(action_params.line, action_params.column)
		elseif action_type == "create_window" then
			success, result_id, result = M.ai_agent_create_window(action_params.split_type, action_params.buffer_id)
		elseif action_type == "insert_text" then
			success, result_id, result = M.ai_agent_insert_text(action_params.text, action_params.mode)
		elseif action_type == "buffer_read" then
			success, result_id, result =
				M.get_ai_agent_buffer_content(action_params.buffer_id, action_params.start_line, action_params.end_line)
		elseif action_type == "buffer_write" then
			success, result_id, result = M.set_ai_agent_buffer_content(
				action_params.buffer_id,
				action_params.lines,
				action_params.start_line,
				action_params.end_line
			)
		else
			success = false
			result = "Unknown action type: " .. action_type
		end

		-- Record result
		table.insert(action_obj.sequence_results, {
			index = i,
			type = action_type,
			success = success,
			result_id = result_id,
			result = result,
		})

		if success then
			success_count = success_count + 1
		else
			failed_count = failed_count + 1
		end
	end

	-- Update action status
	if failed_count == 0 then
		action_obj.status = "completed"
		action_obj.result = {
			total_actions = #actions,
			successful_actions = success_count,
			failed_actions = failed_count,
			message = "All actions completed successfully",
		}
	else
		action_obj.status = "partial"
		action_obj.result = {
			total_actions = #actions,
			successful_actions = success_count,
			failed_actions = failed_count,
			message = string.format("%d actions completed, %d failed", success_count, failed_count),
		}
	end

	-- Update session context
	session.context = {
		current_file = vim.fn.expand("%"),
		current_directory = vim.fn.getcwd(),
		buffer_count = #vim.api.nvim_list_bufs(),
		mode = vim.fn.mode(),
	}

	-- Notify user of AI sequence execution
	local status_icon = (failed_count == 0) and "✅" or "⚠️"
	vim.notify(
		status_icon .. " AI Agent: Executed sequence (" .. success_count .. "/" .. #actions .. " successful)",
		vim.log.levels.INFO
	)

	return (failed_count == 0), action_obj.id, action_obj.result
end

-- Get AI agent session status
function M.get_ai_agent_session_status()
	if not agent_collaboration_mode or not active_agent_id then
		return {
			active = false,
			session_id = nil,
			message = "No active AI agent collaboration session",
		}
	end

	local session = ai_agent_sessions[active_agent_id]
	if not session then
		return {
			active = false,
			session_id = nil,
			message = "Session data not found",
		}
	end

	local current_time = os.time()
	local duration = current_time - session.start_time

	return {
		active = true,
		session_id = active_agent_id,
		agent_name = session.name,
		start_time = session.start_time,
		duration = duration,
		capabilities = session.capabilities,
		context = {
			current_file = vim.fn.expand("%"),
			current_directory = vim.fn.getcwd(),
			buffer_count = #vim.api.nvim_list_bufs(),
			mode = vim.fn.mode(),
		},
		interaction_count = #session.interactions,
		message = "AI agent collaboration session active",
	}
end

-- Get agent session info
function M.get_agent_session_info()
	local status = M.get_ai_agent_session_status()

	if not status.active then
		vim.notify(status.message, vim.log.levels.INFO)
		return
	end

	-- Create buffer for session info
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "modifiable", true)

	-- Format session info
	local lines = {
		"# AI Agent Session Info",
		"",
		"**Session ID:** " .. status.session_id,
		"**Agent Name:** " .. status.agent_name,
		"**Start Time:** " .. os.date("%Y-%m-%d %H:%M:%S", status.start_time),
		"**Duration:** " .. status.duration .. " seconds",
		"**Interaction Count:** " .. status.interaction_count,
		"",
		"## Capabilities",
		"",
	}

	for capability, enabled in pairs(status.capabilities) do
		table.insert(lines, "- " .. capability .. ": " .. (enabled and "✅" or "❌"))
	end

	table.insert(lines, "")
	table.insert(lines, "## Current Context")
	table.insert(lines, "")
	table.insert(lines, "**Current File:** " .. status.context.current_file)
	table.insert(lines, "**Current Directory:** " .. status.context.current_directory)
	table.insert(lines, "**Buffer Count:** " .. status.context.buffer_count)
	table.insert(lines, "**Mode:** " .. status.context.mode)

	-- Set buffer content
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- Open buffer in split
	vim.api.nvim_command("split")
	vim.api.nvim_set_current_buf(buf)

	-- Set buffer options
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

-- Agent file operations
function M.agent_edit_file(args)
	if #args < 2 then
		vim.notify("Usage: :ParagonicAgentEdit <file_path> <line_number> [content]", vim.log.levels.WARN)
		return
	end

	local file_path = args[1]
	local line_number = tonumber(args[2])
	local content = args[3] or ""

	-- Find buffer by file path
	local target_buf = nil
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local buf_name = vim.api.nvim_buf_get_name(buf)
		if buf_name == file_path then
			target_buf = buf
			break
		end
	end

	if not target_buf then
		vim.notify("File not found in session: " .. file_path, vim.log.levels.ERROR)
		return
	end

	-- Perform the edit
	vim.api.nvim_set_current_buf(target_buf)

	-- Split content into lines to handle newlines properly
	local lines = {}
	for line in content:gmatch("[^\r\n]+") do
		table.insert(lines, line)
	end
	vim.api.nvim_buf_set_lines(target_buf, line_number - 1, line_number, false, lines)

	vim.notify("Edited file: " .. file_path .. " at line " .. line_number, vim.log.levels.INFO)
end

function M.agent_create_file(args)
	if #args < 1 then
		vim.notify("Usage: :ParagonicAgentCreate <file_path> [content]", vim.log.levels.WARN)
		return
	end

	local file_path = args[1]
	local content = args[2] or ""

	-- Create new buffer
	local buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_buf_set_name(buf, file_path)

	-- Set content if provided
	if content ~= "" then
		local lines = {}
		for line in content:gmatch("[^\r\n]+") do
			table.insert(lines, line)
		end
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	end

	-- Switch to the new buffer
	vim.api.nvim_set_current_buf(buf)

	vim.notify("Created file: " .. file_path, vim.log.levels.INFO)
end

function M.agent_save_file()
	local current_buf = vim.api.nvim_get_current_buf()
	local file_path = vim.api.nvim_buf_get_name(current_buf)

	if file_path == "" then
		vim.notify("No file path set for current buffer", vim.log.levels.ERROR)
		return
	end

	-- Save the buffer
	vim.cmd("write")

	vim.notify("Saved file: " .. file_path, vim.log.levels.INFO)
end

-- Pattern integration functions
function M.execute_session_pattern(pattern_name, context)
	if not agent_collaboration_mode or not active_agent_id then
		return false, "No active AI agent collaboration session"
	end

	local session = ai_agent_sessions[active_agent_id]
	if not session then
		return false, "Session data not found"
	end

	-- Import patterns module
	local patterns = require("paragonic.patterns")

	-- Prepare session context
	local session_context = context or {}
	session_context.session_id = session.id
	session_context.session_name = session.name
	session_context.session_duration = os.time() - session.start_time
	session_context.interaction_count = #session.interactions

	-- Execute pattern with session context
	local result = patterns.execute_pattern(pattern_name, session_context)

	if result.success then
		-- Track pattern execution in session
		local pattern_interaction = {
			id = #session.interactions + 1,
			timestamp = os.time(),
			type = "pattern_execution",
			content = pattern_name,
			description = "Pattern execution: " .. pattern_name,
			from_agent = true,
			status = "completed",
			result = result.result,
		}

		table.insert(session.interactions, pattern_interaction)

		-- Update session context
		session.context = {
			current_file = vim.fn.expand("%"),
			current_directory = vim.fn.getcwd(),
			buffer_count = #vim.api.nvim_list_bufs(),
			mode = vim.fn.mode(),
		}

		vim.notify("✅ Pattern executed in session: " .. pattern_name, vim.log.levels.INFO)
	else
		vim.notify("❌ Pattern execution failed: " .. pattern_name, vim.log.levels.ERROR)
	end

	return result.success, result
end

function M.check_and_trigger_patterns()
	if not agent_collaboration_mode or not active_agent_id then
		return false, "No active AI agent collaboration session"
	end

	local session = ai_agent_sessions[active_agent_id]
	if not session then
		return false, "Session data not found"
	end

	-- Import patterns module
	local patterns = require("paragonic.patterns")

	-- Get all patterns
	local all_patterns = patterns.list_patterns()
	local triggered_patterns = {}

	-- Check for patterns that should be triggered based on session state
	for _, pattern in ipairs(all_patterns) do
		local should_trigger = false

		-- Check session duration triggers
		local session_duration = os.time() - session.start_time
		if pattern.name == "Session Summary Generation" and session_duration > 300 then
			should_trigger = true
		elseif pattern.name == "Activity Labeling" and #session.interactions > 2 then
			should_trigger = true
		elseif pattern.name == "Self-Reflection" and #session.interactions > 5 then
			should_trigger = true
		end

		if should_trigger then
			table.insert(triggered_patterns, pattern)
		end
	end

	-- Execute triggered patterns
	local executed_patterns = {}
	for _, pattern in ipairs(triggered_patterns) do
		local success, result = M.execute_session_pattern(pattern.name)
		if success then
			table.insert(executed_patterns, pattern.name)
		end
	end

	return true, {
		triggered_patterns = triggered_patterns,
		executed_patterns = executed_patterns,
	}
end

return M
