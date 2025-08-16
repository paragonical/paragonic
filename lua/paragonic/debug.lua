--[[
Paragonic Debug Module
Handles debug buffer management and debug printing functionality
--]]

local M = {}

-- Debug buffer management
local debug_buffer = nil

-- Debug configuration
local debug_config = {
	show_notifications = true, -- Set to false to disable debug notifications
}

-- Configure debug settings
function M.configure_debug(settings)
	if settings.show_notifications ~= nil then
		debug_config.show_notifications = settings.show_notifications
	end
end

-- Get current debug configuration
function M.get_debug_config()
	return vim.deepcopy(debug_config)
end

-- Convenience function to disable debug notifications
function M.disable_notifications()
	debug_config.show_notifications = false
end

-- Convenience function to enable debug notifications
function M.enable_notifications()
	debug_config.show_notifications = true
end

-- Debug print function that writes to debug buffer instead of terminal
function M.debug_print(message, level)
	level = level or "debug"
	-- Defer to safe context to avoid fast event context errors
	vim.defer_fn(function()
		M.append_debug_message(nil, message, level)
	end, 0)
end

-- Safe debug print function that can be called from fast contexts
-- This version uses vim.notify for immediate feedback and defers buffer logging
function M.debug_print_safe(message, level)
	level = level or "debug"
	
	-- Use vim.notify for immediate feedback in fast contexts (if enabled)
	if debug_config.show_notifications then
		local notify_level = vim.log.levels.DEBUG
		if level == "info" then
			notify_level = vim.log.levels.INFO
		elseif level == "warning" then
			notify_level = vim.log.levels.WARN
		elseif level == "error" then
			notify_level = vim.log.levels.ERROR
		elseif level == "success" then
			notify_level = vim.log.levels.INFO
		end
		
		-- Defer notification to safe context to avoid fast event context errors
		vim.defer_fn(function()
			vim.notify(message, notify_level, { title = "Paragonic Debug" })
		end, 0)
	end
	
	-- Defer buffer logging to safe context
	vim.defer_fn(function()
		M.append_debug_message(nil, message, level)
	end, 0)
end

function M.get_or_create_debug_buffer()
	-- Check if debug buffer already exists
	if debug_buffer and vim.api.nvim_buf_is_valid(debug_buffer) then
		return debug_buffer
	end

	-- Look for existing debug buffer
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local name = vim.api.nvim_buf_get_name(buf)
		if name == "paragonic://debug" then
			debug_buffer = buf
			return debug_buffer
		end
	end

	-- Create new debug buffer
	debug_buffer = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_buf_set_name(debug_buffer, "paragonic://debug")
	vim.api.nvim_buf_set_option(debug_buffer, "buftype", "nofile")
	vim.api.nvim_buf_set_option(debug_buffer, "swapfile", false)
	vim.api.nvim_buf_set_option(debug_buffer, "modifiable", true)
	vim.api.nvim_buf_set_option(debug_buffer, "filetype", "markdown")

	-- Add initial content
	vim.api.nvim_buf_set_lines(debug_buffer, 0, -1, false, {
		"# Paragonic Debug Log",
		"",
		"Debug messages and system information will appear here.",
		"",
		"---",
	})

	return debug_buffer
end

function M.open_debug_buffer()
	local debug_buf = M.get_or_create_debug_buffer()

	-- Open the buffer in a new window
	vim.api.nvim_command("split")
	vim.api.nvim_set_current_buf(debug_buf)
end

-- Append debug message to debug buffer instead of chat buffer
function M.append_debug_message(buffer, message, level)
	-- Don't debug the debug function itself to avoid infinite loops
	-- print("🔧 append_debug_message() called with buffer=" .. tostring(buffer) .. ", message=" .. tostring(message))

	if not message then
		-- Use vim.defer_fn for critical errors to avoid infinite loops (if notifications enabled)
		if debug_config.show_notifications then
			vim.defer_fn(function()
				vim.notify("❌ append_debug_message: Message is required", vim.log.levels.ERROR)
			end, 0)
		end
		return false, "Message is required"
	end

	-- Get or create debug buffer
	local debug_buf = M.get_or_create_debug_buffer()

	-- Validate debug buffer exists
	if not vim.api.nvim_buf_is_valid(debug_buf) then
		if debug_config.show_notifications then
			vim.defer_fn(function()
				vim.notify("❌ append_debug_message: Invalid debug buffer", vim.log.levels.ERROR)
			end, 0)
		end
		return false, "Invalid debug buffer"
	end

	-- Default level
	level = level or "info"

	-- Format debug message with timestamp
	local timestamp = os.date("%H:%M:%S")
	-- Get current debug buffer lines
	local current_lines = vim.api.nvim_buf_get_lines(debug_buf, 0, -1, false)

	-- Split message into lines to handle newlines properly
	local lines_to_add = {}
	local message_lines = {}
	for line in message:gmatch("[^\r\n]+") do
		table.insert(message_lines, line)
	end
	
	-- If no lines found, add the original message
	if #message_lines == 0 then
		table.insert(message_lines, message)
	end
	
	-- Format each line
	for i, line in ipairs(message_lines) do
		local prefix = "**[" .. timestamp .. "] DEBUG [" .. level:upper() .. "]:** "
		if i == 1 then
			table.insert(lines_to_add, prefix .. line)
		else
			-- Indent continuation lines
			table.insert(lines_to_add, string.rep(" ", #prefix) .. line)
		end
	end

	-- Append debug message to debug buffer
	vim.api.nvim_buf_set_lines(debug_buf, #current_lines, #current_lines, false, lines_to_add)

	return true, "Debug message appended successfully"
end

-- Clear debug buffer
function M.clear_debug_buffer()
	local debug_buf = M.get_or_create_debug_buffer()

	if vim.api.nvim_buf_is_valid(debug_buf) then
		vim.api.nvim_buf_set_lines(debug_buf, 0, -1, false, {
			"# Paragonic Debug Log",
			"",
			"Debug messages and system information will appear here.",
			"",
			"---",
		})
		return true
	end

	return false
end

-- Get debug buffer content
function M.get_debug_buffer_content()
	local debug_buf = M.get_or_create_debug_buffer()

	if vim.api.nvim_buf_is_valid(debug_buf) then
		return vim.api.nvim_buf_get_lines(debug_buf, 0, -1, false)
	end

	return {}
end

-- Log system information to debug buffer
function M.log_system_info()
	local info = {
		"## System Information",
		"",
		"**Neovim Version:** " .. vim.fn.nvim_get_version().version,
		"**Platform:** " .. vim.fn.has("win32") and "Windows" or vim.fn.has("mac") and "macOS" or "Linux",
		"**Terminal:** " .. (vim.fn.has("gui_running") and "GUI" or "Terminal"),
		"**Working Directory:** " .. vim.fn.getcwd(),
		"**Current File:** " .. vim.fn.expand("%:p"),
		"**Buffer Count:** " .. #vim.api.nvim_list_bufs(),
		"**Window Count:** " .. #vim.api.nvim_list_wins(),
		"**Tab Count:** " .. #vim.api.nvim_list_tabpages(),
		"",
	}

	for _, line in ipairs(info) do
		M.append_debug_message(nil, line, "info")
	end
end

-- Log configuration to debug buffer
function M.log_configuration()
	local config = require("paragonic.config")
	local config_data = config.get_config()

	local info = {
		"## Configuration",
		"",
	}

	for key, value in pairs(config_data) do
		table.insert(info, "**" .. key .. ":** " .. tostring(value))
	end

	table.insert(info, "")

	for _, line in ipairs(info) do
		M.append_debug_message(nil, line, "info")
	end
end

-- Log RPC client status to debug buffer
function M.log_rpc_status()
	local rpc_client = require("paragonic")._get_rpc_client()

	local info = {
		"## RPC Client Status",
		"",
	}

	if rpc_client then
		table.insert(info, "**Status:** Connected")
		table.insert(info, "**Connected:** " .. tostring(rpc_client:is_connected()))
	else
		table.insert(info, "**Status:** Not initialized")
	end

	table.insert(info, "")

	for _, line in ipairs(info) do
		M.append_debug_message(nil, line, "info")
	end
end

-- Export debug log to file
function M.export_debug_log(filepath)
	local content = M.get_debug_buffer_content()
	local content_str = table.concat(content, "\n")

	if not filepath then
		filepath = vim.fn.stdpath("data") .. "/paragonic/debug_log_" .. os.date("%Y%m%d_%H%M%S") .. ".md"
	end

	-- Ensure directory exists
	local dir = vim.fn.fnamemodify(filepath, ":h")
	vim.fn.mkdir(dir, "p")

	-- Write file
	local file = io.open(filepath, "w")
	if file then
		file:write(content_str)
		file:close()
		M.append_debug_message(nil, "Debug log exported to: " .. filepath, "info")
		return true, filepath
	else
		M.append_debug_message(nil, "Failed to export debug log to: " .. filepath, "error")
		return false, "Failed to write file"
	end
end

return M
