--[[
MCP Approval UI - Chat Integration Only
Non-interruptive approval system using chat sigil markers
--]]

local M = {}

-- Configuration for chat-based approval
M.config = {
	sigil_marker = "󰭙", -- Account question icon
	pending_prefix = "🔄",
	approved_prefix = "✅",
	denied_prefix = "❌",
	timeout_prefix = "⏰",
	marker_color = "WarningMsg",
	pending_color = "Comment",
	approved_color = "String",
	denied_color = "ErrorMsg",
	timeout_color = "Special"
}

-- Track pending approvals in chat buffers
M.pending_approvals = {}
M.next_approval_id = 1

-- Initialize chat-based approval system
function M.initialize()
	M.pending_approvals = {}
	M.next_approval_id = 1
	
	-- Set up autocommands for chat buffers
	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = "*",
		callback = function()
			M.check_for_approval_markers()
		end
	})
	
	print("✅ Chat-based approval system initialized")
end

-- Create approval marker in chat buffer
function M.create_approval_marker(request_id, request_type, description)
	local approval_id = M.next_approval_id
	M.next_approval_id = M.next_approval_id + 1
	
	local marker_line = string.format("%s %s [%s] %s", 
		M.config.sigil_marker,
		M.config.pending_prefix,
		request_type,
		description
	)
	
	-- Store approval info
	M.pending_approvals[approval_id] = {
		id = approval_id,
		request_id = request_id,
		request_type = request_type,
		description = description,
		marker_line = marker_line,
		status = "pending",
		created_at = os.time(),
		buffer_id = vim.api.nvim_get_current_buf()
	}
	
	-- Add marker to current buffer
	local current_buf = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
	table.insert(lines, marker_line)
	vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, lines)
	
	-- Highlight the marker
	M.highlight_approval_marker(current_buf, #lines, approval_id)
	
	return approval_id
end

-- Highlight approval marker in buffer
function M.highlight_approval_marker(buffer_id, line_number, approval_id)
	local approval = M.pending_approvals[approval_id]
	if not approval then
		return
	end
	
	-- Create highlight namespace
	local ns_id = vim.api.nvim_create_namespace("mcp_approval_" .. approval_id)
	
	-- Highlight the marker
	local highlight_group = M.config.marker_color
	if approval.status == "pending" then
		highlight_group = M.config.pending_color
	elseif approval.status == "approved" then
		highlight_group = M.config.approved_color
	elseif approval.status == "denied" then
		highlight_group = M.config.denied_color
	elseif approval.status == "timeout" then
		highlight_group = M.config.timeout_color
	end
	
	vim.api.nvim_buf_add_highlight(buffer_id, ns_id, highlight_group, line_number - 1, 0, -1)
end

-- Update approval marker status
function M.update_approval_marker(approval_id, status, result)
	local approval = M.pending_approvals[approval_id]
	if not approval then
		return false
	end
	
	approval.status = status
	approval.result = result
	approval.updated_at = os.time()
	
	-- Update the marker line
	local new_prefix = M.config.pending_prefix
	if status == "approved" then
		new_prefix = M.config.approved_prefix
	elseif status == "denied" then
		new_prefix = M.config.denied_prefix
	elseif status == "timeout" then
		new_prefix = M.config.timeout_prefix
	end
	
	local new_marker_line = string.format("%s %s [%s] %s", 
		M.config.sigil_marker,
		new_prefix,
		approval.request_type,
		approval.description
	)
	
	-- Update the line in the buffer
	local buffer_id = approval.buffer_id
	if vim.api.nvim_buf_is_valid(buffer_id) then
		local lines = vim.api.nvim_buf_get_lines(buffer_id, 0, -1, false)
		
		-- Find the marker line
		for i, line in ipairs(lines) do
			if line:find(M.config.sigil_marker) and line:find(approval.description) then
				lines[i] = new_marker_line
				vim.api.nvim_buf_set_lines(buffer_id, 0, -1, false, lines)
				
				-- Update highlighting
				M.highlight_approval_marker(buffer_id, i, approval_id)
				break
			end
		end
	end
	
	return true
end

-- Check for approval markers in current buffer
function M.check_for_approval_markers()
	local current_buf = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
	
	for i, line in ipairs(lines) do
		if line:find(M.config.sigil_marker) then
			-- Found a marker, check if it's pending
			for approval_id, approval in pairs(M.pending_approvals) do
				if approval.buffer_id == current_buf and 
				   line:find(approval.description) and
				   approval.status == "pending" then
					M.highlight_approval_marker(current_buf, i, approval_id)
				end
			end
		end
	end
end

-- Handle Enter key in chat buffer for approval processing
function M.handle_enter_key()
	local current_buf = vim.api.nvim_get_current_buf()
	local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
	local lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
	
	if cursor_line <= #lines then
		local line = lines[cursor_line]
		if line:find(M.config.sigil_marker) then
			-- Found a marker, check if it's pending
			for approval_id, approval in pairs(M.pending_approvals) do
				if approval.buffer_id == current_buf and 
				   line:find(approval.description) and
				   approval.status == "pending" then
					-- Process the approval
					M.process_approval(approval_id)
					return true
				end
			end
		end
	end
	
	return false
end

-- Process approval when user presses Enter on marker
function M.process_approval(approval_id)
	local approval = M.pending_approvals[approval_id]
	if not approval or approval.status ~= "pending" then
		return false
	end
	
	-- Get the actual request
	local mcp = require("paragonic.mcp")
	local request_entry = mcp.get_approval_request(approval.request_id)
	if not request_entry then
		vim.notify("Approval request not found", vim.log.levels.ERROR)
		return false
	end
	
	local request = request_entry.request
	
	-- Show quick approval options
	local options = {"Approve", "Deny", "Details", "Cancel"}
	vim.ui.select(options, {
		prompt = "Process approval:",
		format_item = function(item)
			return item
		end
	}, function(choice)
		if choice == "Approve" then
			M.approve_request(approval_id, request)
		elseif choice == "Deny" then
			M.deny_request(approval_id, request)
		elseif choice == "Details" then
			M.show_request_details(approval_id, request)
		end
	end)
end

-- Approve request
function M.approve_request(approval_id, request)
	local mcp = require("paragonic.mcp")
	local success = mcp.approve_request(request.id, {approved = true})
	
	if success then
		M.update_approval_marker(approval_id, "approved", {approved = true})
		vim.notify("Request approved", vim.log.levels.INFO)
	else
		vim.notify("Failed to approve request", vim.log.levels.ERROR)
	end
end

-- Deny request
function M.deny_request(approval_id, request)
	local mcp = require("paragonic.mcp")
	local success = mcp.deny_request(request.id, {approved = false})
	
	if success then
		M.update_approval_marker(approval_id, "denied", {approved = false})
		vim.notify("Request denied", vim.log.levels.INFO)
	else
		vim.notify("Failed to deny request", vim.log.levels.ERROR)
	end
end

-- Show request details in a floating window
function M.show_request_details(approval_id, request)
	local details = {}
	table.insert(details, "Request Details:")
	table.insert(details, "Type: " .. (request.type or "Unknown"))
	table.insert(details, "ID: " .. (request.id or "Unknown"))
	
	if request.type == "tool_execution" then
		table.insert(details, "Tool: " .. (request.tool_name or "Unknown"))
		if request.parameters then
			table.insert(details, "Parameters:")
			for key, value in pairs(request.parameters) do
				table.insert(details, "  " .. key .. ": " .. tostring(value))
			end
		end
	elseif request.type == "decision_point" then
		table.insert(details, "Question: " .. (request.question or "Unknown"))
		if request.options then
			table.insert(details, "Options:")
			for i, option in ipairs(request.options) do
				table.insert(details, "  " .. i .. ". " .. option)
			end
		end
	elseif request.type == "batch_action" then
		table.insert(details, "Description: " .. (request.description or "Unknown"))
		if request.actions then
			table.insert(details, "Actions:")
			for i, action in ipairs(request.actions) do
				table.insert(details, "  " .. i .. ". " .. (action.type or "unknown") .. ": " .. (action.file or action.description or "unknown"))
			end
		end
	end
	
	-- Show details in a floating window
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, details)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	
	local width = 60
	local height = #details + 2
	local row = math.floor((vim.o.lines - height) / 2) - 1
	local col = math.floor((vim.o.columns - width) / 2)
	
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded"
	})
	
	-- Close on any key
	vim.keymap.set("n", "<CR>", function()
		vim.api.nvim_win_close(win, true)
		vim.api.nvim_buf_delete(buf, {force = true})
	end, {buffer = buf, noremap = true, silent = true})
	
	vim.keymap.set("n", "<Esc>", function()
		vim.api.nvim_win_close(win, true)
		vim.api.nvim_buf_delete(buf, {force = true})
	end, {buffer = buf, noremap = true, silent = true})
	
	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(win, true)
		vim.api.nvim_buf_delete(buf, {force = true})
	end, {buffer = buf, noremap = true, silent = true})
end

-- Set up Enter key mapping for chat buffers
function M.setup_chat_buffer_mappings()
	-- Override Enter key in chat buffers
	vim.keymap.set("n", "<CR>", function()
		if not M.handle_enter_key() then
			-- Default Enter behavior
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, true, true), "n", false)
		end
	end, {buffer = 0, noremap = true})
end

-- Clean up old approvals
function M.cleanup_old_approvals()
	local cutoff_time = os.time() - 3600 -- 1 hour
	local to_remove = {}
	
	for approval_id, approval in pairs(M.pending_approvals) do
		if approval.updated_at and approval.updated_at < cutoff_time then
			table.insert(to_remove, approval_id)
		end
	end
	
	for _, approval_id in ipairs(to_remove) do
		M.pending_approvals[approval_id] = nil
	end
	
	return #to_remove
end

-- Get pending approval count
function M.get_pending_approval_count()
	local count = 0
	for _, approval in pairs(M.pending_approvals) do
		if approval.status == "pending" then
			count = count + 1
		end
	end
	return count
end

-- Get all pending approvals
function M.get_pending_approvals()
	local pending = {}
	for approval_id, approval in pairs(M.pending_approvals) do
		if approval.status == "pending" then
			table.insert(pending, approval)
		end
	end
	return pending
end

-- Remove approval marker from buffer
function M.remove_approval_marker(approval_id)
	local approval = M.pending_approvals[approval_id]
	if not approval then
		return false
	end
	
	local buffer_id = approval.buffer_id
	if vim.api.nvim_buf_is_valid(buffer_id) then
		local lines = vim.api.nvim_buf_get_lines(buffer_id, 0, -1, false)
		
		-- Find and remove the marker line
		for i = #lines, 1, -1 do
			local line = lines[i]
			if line:find(M.config.sigil_marker) and line:find(approval.description) then
				table.remove(lines, i)
				vim.api.nvim_buf_set_lines(buffer_id, 0, -1, false, lines)
				break
			end
		end
	end
	
	-- Remove from tracking
	M.pending_approvals[approval_id] = nil
	
	return true
end

return M
