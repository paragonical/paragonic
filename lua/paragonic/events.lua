--[[
Paragonic Events Module
Handles real-time event notification functionality
--]]

local M = {}

-- Real-time event notification state
local event_handlers = {
	buffer_change = {},
	cursor_movement = {},
	window_change = {},
}
local event_registration_enabled = false
local autocommand_group_id = nil

-- Register buffer change event handler
function M.register_buffer_change_handler(handler)
	if not handler or type(handler) ~= "function" then
		return false, "Handler must be a function"
	end

	table.insert(event_handlers.buffer_change, handler)
	event_registration_enabled = true

	return true, "Buffer change handler registered successfully"
end

-- Register cursor movement event handler
function M.register_cursor_movement_handler(handler)
	if not handler or type(handler) ~= "function" then
		return false, "Handler must be a function"
	end

	table.insert(event_handlers.cursor_movement, handler)
	event_registration_enabled = true

	return true, "Cursor movement handler registered successfully"
end

-- Register window change event handler
function M.register_window_change_handler(handler)
	if not handler or type(handler) ~= "function" then
		return false, "Handler must be a function"
	end

	table.insert(event_handlers.window_change, handler)
	event_registration_enabled = true

	return true, "Window change handler registered successfully"
end

-- Trigger buffer change event
function M.trigger_buffer_change_event(buffer_id, change_type)
	if not event_registration_enabled then
		return false, "Event registration not enabled"
	end

	-- Check if there's an active AI agent session
	local ai_agent = require("paragonic.ai_agent")
	if not ai_agent.agent_collaboration_mode or not ai_agent.active_agent_id then
		return false, "No active AI agent session"
	end

	local event_data = {
		type = "buffer_change",
		buffer_id = buffer_id,
		change_type = change_type,
		timestamp = os.time(),
		session_id = ai_agent.active_agent_id,
	}

	-- Execute all registered handlers
	for _, handler in ipairs(event_handlers.buffer_change) do
		local success, result = pcall(handler, event_data)
		if not success then
			local debug = require("paragonic.debug")
			debug.debug_print("Error in buffer change handler: " .. tostring(result), "error")
		end
	end

	return true, "Buffer change event triggered successfully"
end

-- Trigger cursor movement event
function M.trigger_cursor_movement_event(line, column)
	if not event_registration_enabled then
		return false, "Event registration not enabled"
	end

	-- Check if there's an active AI agent session
	local ai_agent = require("paragonic.ai_agent")
	if not ai_agent.agent_collaboration_mode or not ai_agent.active_agent_id then
		return false, "No active AI agent session"
	end

	local event_data = {
		type = "cursor_movement",
		line = line,
		column = column,
		timestamp = os.time(),
		session_id = ai_agent.active_agent_id,
	}

	-- Execute all registered handlers
	for _, handler in ipairs(event_handlers.cursor_movement) do
		local success, result = pcall(handler, event_data)
		if not success then
			local debug = require("paragonic.debug")
			debug.debug_print("Error in cursor movement handler: " .. tostring(result), "error")
		end
	end

	return true, "Cursor movement event triggered successfully"
end

-- Trigger window change event
function M.trigger_window_change_event(window_id, change_type)
	if not event_registration_enabled then
		return false, "Event registration not enabled"
	end

	-- Check if there's an active AI agent session
	local ai_agent = require("paragonic.ai_agent")
	if not ai_agent.agent_collaboration_mode or not ai_agent.active_agent_id then
		return false, "No active AI agent session"
	end

	local event_data = {
		type = "window_change",
		window_id = window_id,
		change_type = change_type,
		timestamp = os.time(),
		session_id = ai_agent.active_agent_id,
	}

	-- Execute all registered handlers
	for _, handler in ipairs(event_handlers.window_change) do
		local success, result = pcall(handler, event_data)
		if not success then
			local debug = require("paragonic.debug")
			debug.debug_print("Error in window change handler: " .. tostring(result), "error")
		end
	end

	return true, "Window change event triggered successfully"
end

-- Setup buffer change autocommands
function M.setup_buffer_change_autocommands()
	if not event_registration_enabled then
		return false, "Event registration not enabled"
	end

	-- Create autocommand group if it doesn't exist
	if not autocommand_group_id then
		autocommand_group_id = vim.api.nvim_create_augroup("ParagonicAIEvents", { clear = true })
	end

	-- Setup buffer change autocommands
	vim.api.nvim_create_autocmd({ "BufWritePost", "BufModifiedSet" }, {
		group = autocommand_group_id,
		callback = function(args)
			local buffer_id = args.buf
			local change_type = args.event == "BufWritePost" and "saved" or "modified"
			M.trigger_buffer_change_event(buffer_id, change_type)
		end,
	})

	return true, "Buffer change autocommands setup successfully"
end

-- Setup cursor movement autocommands
function M.setup_cursor_movement_autocommands()
	if not event_registration_enabled then
		return false, "Event registration not enabled"
	end

	-- Create autocommand group if it doesn't exist
	if not autocommand_group_id then
		autocommand_group_id = vim.api.nvim_create_augroup("ParagonicAIEvents", { clear = true })
	end

	-- Setup cursor movement autocommands
	vim.api.nvim_create_autocmd("CursorMoved", {
		group = autocommand_group_id,
		callback = function(args)
			local cursor_pos = vim.api.nvim_win_get_cursor(args.win)
			M.trigger_cursor_movement_event(cursor_pos[1], cursor_pos[2])
		end,
	})

	return true, "Cursor movement autocommands setup successfully"
end

-- Setup window change autocommands
function M.setup_window_change_autocommands()
	if not event_registration_enabled then
		return false, "Event registration not enabled"
	end

	-- Create autocommand group if it doesn't exist
	if not autocommand_group_id then
		autocommand_group_id = vim.api.nvim_create_augroup("ParagonicAIEvents", { clear = true })
	end

	-- Setup window change autocommands
	vim.api.nvim_create_autocmd({ "WinNew", "WinClosed", "WinScrolled" }, {
		group = autocommand_group_id,
		callback = function(args)
			local window_id = args.win or vim.api.nvim_get_current_win()
			local change_type = args.event:lower()
			M.trigger_window_change_event(window_id, change_type)
		end,
	})

	return true, "Window change autocommands setup successfully"
end

-- Setup all event autocommands
function M.setup_all_event_autocommands()
	if not event_registration_enabled then
		return false, "Event registration not enabled"
	end

	-- Setup all autocommand types
	local success1, _ = M.setup_buffer_change_autocommands()
	local success2, _ = M.setup_cursor_movement_autocommands()
	local success3, _ = M.setup_window_change_autocommands()

	if success1 and success2 and success3 then
		return true, "All event autocommands setup successfully"
	else
		return false, "Failed to setup some autocommands"
	end
end

-- Register session-aware event handler
function M.register_session_aware_handler(event_type, handler)
	if not handler or type(handler) ~= "function" then
		return false, "Handler must be a function"
	end

	if not event_type or type(event_type) ~= "string" then
		return false, "Event type must be a string"
	end

	-- Validate event type
	if event_type ~= "buffer_change" and event_type ~= "cursor_movement" and event_type ~= "window_change" then
		return false, "Invalid event type: " .. event_type
	end

	-- Add session context to handler
	local session_aware_handler = function(event_data)
		-- Only execute if there's an active session
		local ai_agent = require("paragonic.ai_agent")
		if ai_agent.agent_collaboration_mode and ai_agent.active_agent_id then
			event_data.session_id = ai_agent.active_agent_id
			event_data.session_name = ai_agent.ai_agent_sessions[ai_agent.active_agent_id]
					and ai_agent.ai_agent_sessions[ai_agent.active_agent_id].name
				or "Unknown"
			handler(event_data)
		end
	end

	-- Register the session-aware handler
	table.insert(event_handlers[event_type], session_aware_handler)
	event_registration_enabled = true

	return true, "Session-aware handler registered successfully"
end

-- Track event in session
function M.track_event_in_session(event_type, event_data)
	local ai_agent = require("paragonic.ai_agent")
	if not ai_agent.agent_collaboration_mode or not ai_agent.active_agent_id then
		return false, "No active AI agent session"
	end

	local session = ai_agent.ai_agent_sessions[ai_agent.active_agent_id]
	if not session then
		return false, "Session data not found"
	end

	-- Create event tracking object
	local event_obj = {
		id = #session.interactions + 1,
		timestamp = os.time(),
		type = "event",
		event_type = event_type,
		event_data = event_data,
		from_agent = false,
		status = "tracked",
	}

	-- Add to session interactions
	table.insert(session.interactions, event_obj)

	-- Update session context
	session.context = {
		current_file = vim.fn.expand("%"),
		current_directory = vim.fn.getcwd(),
		buffer_count = #vim.api.nvim_list_bufs(),
		mode = vim.fn.mode(),
	}

	return true, "Event tracked in session successfully"
end

-- Get session event history
function M.get_session_event_history()
	local ai_agent = require("paragonic.ai_agent")
	if not ai_agent.agent_collaboration_mode or not ai_agent.active_agent_id then
		return false, "No active AI agent session"
	end

	local session = ai_agent.ai_agent_sessions[ai_agent.active_agent_id]
	if not session then
		return false, "Session data not found"
	end

	-- Filter interactions to only include events
	local event_history = {}
	for _, interaction in ipairs(session.interactions) do
		if interaction.type == "event" then
			table.insert(event_history, {
				id = interaction.id,
				timestamp = interaction.timestamp,
				event_type = interaction.event_type,
				event_data = interaction.event_data,
				status = interaction.status,
			})
		end
	end

	return true, event_history
end

return M
