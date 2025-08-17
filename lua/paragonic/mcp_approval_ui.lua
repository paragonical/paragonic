--[[
Paragonic MCP Approval UI Module
Handles approval dialog creation, display, and user interaction
--]]

local M = {}

-- UI state management
M.active_dialogs = {}
M.next_dialog_id = 1

-- Dialog configuration
M.dialog_config = {
	default_width = 80,
	default_height = 20,
	position = "center",
	style = "minimal",
	timeout_check_interval = 1, -- seconds
}

-- Initialize approval UI module
function M.initialize()
	if not M.active_dialogs then
		M.active_dialogs = {}
	end
	if not M.next_dialog_id then
		M.next_dialog_id = 1
	end
	return true
end

-- Create approval dialog
function M.create_approval_dialog(request_id)
	if not request_id then
		return nil, "Invalid request ID"
	end
	
	-- Get the approval request
	local mcp = require("paragonic.mcp")
	local request_entry = mcp.get_approval_request(request_id)
	if not request_entry then
		return nil, "Request not found: " .. request_id
	end
	
	local request = request_entry.request
	
	-- Create buffer
	local buf = vim.api.nvim_create_buf(false, true)
	if not buf then
		return nil, "Failed to create buffer"
	end
	
	-- Set buffer options
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	
	-- Create window
	local width = M.dialog_config.default_width
	local height = M.dialog_config.default_height
	
	local win_config = {
		relative = "editor",
		width = width,
		height = height,
		row = (vim.o.lines - height) / 2,
		col = (vim.o.columns - width) / 2,
		style = M.dialog_config.style,
		border = "rounded",
	}
	
	local win = vim.api.nvim_open_win(buf, true, win_config)
	if not win then
		vim.api.nvim_buf_delete(buf, {force = true})
		return nil, "Failed to create window"
	end
	
	-- Set window options
	vim.api.nvim_win_set_option(win, "wrap", false)
	vim.api.nvim_win_set_option(win, "cursorline", true)
	
	-- Generate dialog content
	local content = M.generate_dialog_content(request)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
	
	-- Set buffer options after content
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "filetype", "approval")
	
	-- Create dialog object
	local dialog_id = "dialog-" .. M.next_dialog_id
	M.next_dialog_id = M.next_dialog_id + 1
	
	local dialog = {
		id = dialog_id,
		buffer_id = buf,
		window_id = win,
		request_id = request_id,
		request_type = request.type,
		status = "open",
		created_at = os.time(),
	}
	
	-- Store dialog
	M.active_dialogs[dialog_id] = dialog
	
	-- Set up keymaps
	M.setup_dialog_keymaps(dialog)
	
	return dialog
end

-- Generate dialog content based on request type
function M.generate_dialog_content(request)
	local lines = {}
	
	-- Header
	table.insert(lines, "╭─────────────────────────────────────────────────────────────────────────────────╮")
	table.insert(lines, "│                           APPROVAL REQUEST                                    │")
	table.insert(lines, "├─────────────────────────────────────────────────────────────────────────────────┤")
	
	-- Request type specific content
	if request.type == "tool_execution" then
		lines = M.generate_tool_execution_content(request, lines)
	elseif request.type == "decision_point" then
		lines = M.generate_decision_point_content(request, lines)
	elseif request.type == "batch_action" then
		lines = M.generate_batch_action_content(request, lines)
	else
		lines = M.generate_generic_content(request, lines)
	end
	
	-- Footer
	table.insert(lines, "├─────────────────────────────────────────────────────────────────────────────────┤")
	table.insert(lines, "│  [y] Approve  [n] Deny  [m] Modify  [q] Close  [t] Timeout: " .. (request.timeout or "∞") .. "s │")
	table.insert(lines, "╰─────────────────────────────────────────────────────────────────────────────────╯")
	
	return lines
end

-- Generate content for tool execution requests
function M.generate_tool_execution_content(request, lines)
	table.insert(lines, "│  Tool: " .. (request.tool_name or "Unknown"))
	table.insert(lines, "│")
	
	if request.parameters then
		table.insert(lines, "│  Parameters:")
		for key, value in pairs(request.parameters) do
			if type(value) == "table" then
				table.insert(lines, "│    " .. key .. ": " .. vim.inspect(value))
			else
				table.insert(lines, "│    " .. key .. ": " .. tostring(value))
			end
		end
		table.insert(lines, "│")
	end
	
	if request.impact then
		table.insert(lines, "│  Impact: " .. request.impact)
		table.insert(lines, "│")
	end
	
	return lines
end

-- Generate content for decision point requests
function M.generate_decision_point_content(request, lines)
	table.insert(lines, "│  Question: " .. (request.question or "No question provided"))
	table.insert(lines, "│")
	
	if request.options and #request.options > 0 then
		table.insert(lines, "│  Options:")
		for i, option in ipairs(request.options) do
			table.insert(lines, "│    " .. i .. ". " .. option)
		end
		table.insert(lines, "│")
	end
	
	return lines
end

-- Generate content for batch action requests
function M.generate_batch_action_content(request, lines)
	table.insert(lines, "│  Description: " .. (request.description or "Batch action"))
	table.insert(lines, "│")
	
	if request.actions and #request.actions > 0 then
		table.insert(lines, "│  Actions:")
		for i, action in ipairs(request.actions) do
			local action_text = "│    " .. i .. ". " .. (action.type or "unknown") .. ": " .. (action.file or action.description or "unknown")
			table.insert(lines, action_text)
		end
		table.insert(lines, "│")
	end
	
	return lines
end

-- Generate generic content for unknown request types
function M.generate_generic_content(request, lines)
	table.insert(lines, "│  Type: " .. (request.type or "Unknown"))
	table.insert(lines, "│  ID: " .. (request.id or "Unknown"))
	table.insert(lines, "│")
	
	-- Show all request data
	for key, value in pairs(request) do
		if key ~= "type" and key ~= "id" and key ~= "timeout" then
			if type(value) == "table" then
				table.insert(lines, "│  " .. key .. ": " .. vim.inspect(value))
			else
				table.insert(lines, "│  " .. key .. ": " .. tostring(value))
			end
		end
	end
	
	return lines
end

-- Set up keymaps for dialog
function M.setup_dialog_keymaps(dialog)
	local buf = dialog.buffer_id
	
	-- Approve
	vim.keymap.set("n", "y", function()
		M.handle_user_approval(dialog, {approved = true})
	end, {buffer = buf, noremap = true, silent = true})
	
	-- Deny
	vim.keymap.set("n", "n", function()
		M.handle_user_denial(dialog, {approved = false})
	end, {buffer = buf, noremap = true, silent = true})
	
	-- Close
	vim.keymap.set("n", "q", function()
		M.close_approval_dialog(dialog)
	end, {buffer = buf, noremap = true, silent = true})
	
	-- Escape
	vim.keymap.set("n", "<Esc>", function()
		M.close_approval_dialog(dialog)
	end, {buffer = buf, noremap = true, silent = true})
end

-- Display approval dialog
function M.display_approval_dialog(dialog)
	if not dialog or not dialog.window_id then
		return false, "Invalid dialog"
	end
	
	-- Focus the window
	vim.api.nvim_set_current_win(dialog.window_id)
	
	-- Update dialog status
	dialog.status = "displayed"
	dialog.displayed_at = os.time()
	
	return true
end

-- Handle user approval
function M.handle_user_approval(dialog, result)
	if not dialog or not dialog.request_id then
		return false, "Invalid dialog"
	end
	
	local mcp = require("paragonic.mcp")
	local success = mcp.approve_request(dialog.request_id, result)
	
	if success then
		M.close_approval_dialog(dialog)
		vim.notify("Request approved", vim.log.levels.INFO)
		return true
	else
		vim.notify("Failed to approve request", vim.log.levels.ERROR)
		return false
	end
end

-- Handle user denial
function M.handle_user_denial(dialog, result)
	if not dialog or not dialog.request_id then
		return false, "Invalid dialog"
	end
	
	local mcp = require("paragonic.mcp")
	local success = mcp.deny_request(dialog.request_id, result)
	
	if success then
		M.close_approval_dialog(dialog)
		vim.notify("Request denied", vim.log.levels.INFO)
		return true
	else
		vim.notify("Failed to deny request", vim.log.levels.ERROR)
		return false
	end
end

-- Close approval dialog
function M.close_approval_dialog(dialog)
	if not dialog then
		return false
	end
	
	-- Close window if it exists
	if dialog.window_id and vim.api.nvim_win_is_valid(dialog.window_id) then
		vim.api.nvim_win_close(dialog.window_id, true)
	end
	
	-- Delete buffer if it exists
	if dialog.buffer_id and vim.api.nvim_buf_is_valid(dialog.buffer_id) then
		vim.api.nvim_buf_delete(dialog.buffer_id, {force = true})
	end
	
	-- Update dialog status
	dialog.status = "closed"
	dialog.closed_at = os.time()
	
	-- Remove from active dialogs
	M.active_dialogs[dialog.id] = nil
	
	return true
end

-- Check if dialog is open
function M.is_dialog_open(dialog)
	if not dialog or not dialog.window_id then
		return false
	end
	
	-- Check for timeout and close if needed
	local mcp = require("paragonic.mcp")
	local request_entry = mcp.get_approval_request(dialog.request_id)
	if request_entry and request_entry.status == "timeout" then
		M.close_approval_dialog(dialog)
		return false
	end
	
	return vim.api.nvim_win_is_valid(dialog.window_id)
end

-- Get dialog state
function M.get_dialog_state(dialog)
	if not dialog then
		return {status = "invalid"}
	end
	
	return {
		id = dialog.id,
		status = dialog.status,
		request_id = dialog.request_id,
		request_type = dialog.request_type,
		created_at = dialog.created_at,
		displayed_at = dialog.displayed_at,
		closed_at = dialog.closed_at,
		is_open = M.is_dialog_open(dialog)
	}
end

-- Create decision point dialog
function M.create_decision_point_dialog(request_id)
	local dialog = M.create_approval_dialog(request_id)
	if not dialog then
		return nil
	end
	
	-- Add decision point specific keymaps
	local buf = dialog.buffer_id
	
	-- Number keys for option selection
	for i = 1, 9 do
		vim.keymap.set("n", tostring(i), function()
			M.handle_option_selection(dialog, i)
		end, {buffer = buf, noremap = true, silent = true})
	end
	
	return dialog
end

-- Handle option selection for decision points
function M.handle_option_selection(dialog, option_index)
	if not dialog or not dialog.request_id then
		return false, "Invalid dialog"
	end
	
	local mcp = require("paragonic.mcp")
	local request_entry = mcp.get_approval_request(dialog.request_id)
	if not request_entry then
		return false, "Request not found"
	end
	
	local request = request_entry.request
	if request.type ~= "decision_point" then
		return false, "Not a decision point request"
	end
	
	if not request.options or option_index > #request.options then
		return false, "Invalid option index"
	end
	
	-- Approve with selected option
	local result = {
		approved = true,
		selected_option = option_index,
		selected_value = request.options[option_index]
	}
	
	return M.handle_user_approval(dialog, result)
end

-- Create batch action dialog
function M.create_batch_action_dialog(request_id)
	local dialog = M.create_approval_dialog(request_id)
	if not dialog then
		return nil
	end
	
	-- Add batch action specific keymaps
	local buf = dialog.buffer_id
	
	-- Partial approval keymaps
	vim.keymap.set("n", "p", function()
		M.show_partial_approval_menu(dialog)
	end, {buffer = buf, noremap = true, silent = true})
	
	return dialog
end

-- Show partial approval menu
function M.show_partial_approval_menu(dialog)
	if not dialog or not dialog.request_id then
		return false
	end
	
	local mcp = require("paragonic.mcp")
	local request_entry = mcp.get_approval_request(dialog.request_id)
	if not request_entry then
		return false
	end
	
	local request = request_entry.request
	if request.type ~= "batch_action" or not request.actions then
		return false
	end
	
	-- Create selection items
	local items = {}
	for i, action in ipairs(request.actions) do
		table.insert(items, i .. ". " .. (action.description or action.type .. ": " .. (action.file or "unknown")))
	end
	
	-- Show selection dialog
	vim.ui.select(items, {
		prompt = "Select actions to approve (space to toggle, enter to confirm):",
		format_item = function(item)
			return item
		end
	}, function(choices)
		if choices then
			local approved_indices = {}
			for i, selected in ipairs(choices) do
				if selected then
					table.insert(approved_indices, i)
				end
			end
			M.handle_partial_approval(dialog, approved_indices)
		end
	end)
end

-- Handle partial approval for batch actions
function M.handle_partial_approval(dialog, approved_indices)
	if not dialog or not dialog.request_id then
		return false, "Invalid dialog"
	end
	
	local mcp = require("paragonic.mcp")
	local request_entry = mcp.get_approval_request(dialog.request_id)
	if not request_entry then
		return false, "Request not found"
	end
	
	local request = request_entry.request
	if request.type ~= "batch_action" then
		return false, "Not a batch action request"
	end
	
	-- Create result with approved actions
	local result = {
		approved = true,
		approved_actions = approved_indices,
		partial_approval = true
	}
	
	return M.handle_user_approval(dialog, result)
end

-- Clean up all dialogs
function M.cleanup_all_dialogs()
	for dialog_id, dialog in pairs(M.active_dialogs) do
		M.close_approval_dialog(dialog)
	end
end

-- Get active dialog count
function M.get_active_dialog_count()
	local count = 0
	for _, dialog in pairs(M.active_dialogs) do
		if M.is_dialog_open(dialog) then
			count = count + 1
		end
	end
	return count
end

return M
