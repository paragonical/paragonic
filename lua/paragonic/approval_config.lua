--[[
Approval Configuration Module
Handles auto-approval patterns, YOLO mode, and approval workflow configuration
--]]

local M = {}

-- Default configuration
M.config = {
	-- YOLO mode: bypass all approvals (use with caution!)
	yolo_mode = false,
	
	-- Auto-approval patterns
	auto_approval = {
		enabled = true,
		patterns = {
			-- Tool-based patterns
			tools = {
				"agent_session_info",
				"agent_search_files", 
				"file_search",
				"buffer_navigate"
			},
			
			-- File operation patterns
			file_operations = {
				-- Auto-approve file creation in specific directories
				create_in_dirs = {
					"temp/",
					"tmp/",
					"logs/",
					"cache/"
				},
				
				-- Auto-approve file creation with specific extensions
				create_extensions = {
					".tmp",
					".log",
					".cache",
					".bak"
				},
				
				-- Auto-approve editing of specific file types
				edit_file_types = {
					"*.tmp",
					"*.log",
					"*.cache"
				}
			},
			
			-- Command patterns
			commands = {
				-- Auto-approve specific Neovim commands
				neovim_commands = {
					"buffers",
					"ls",
					"pwd",
					"version"
				},
				
				-- Auto-approve specific shell commands
				shell_commands = {
					"ls",
					"pwd",
					"date",
					"whoami"
				}
			},
			
			-- Content patterns
			content = {
				-- Auto-approve if content matches patterns
				patterns = {
					"^-- .*$", -- Comments
					"^# .*$", -- Markdown headers
					"^// .*$", -- C-style comments
					"^%. .*$", -- Vim comments
				},
				
				-- Auto-approve if content is small
				max_auto_approve_size = 100 -- characters
			}
		},
		
		-- Time-based patterns
		time_based = {
			enabled = false,
			-- Auto-approve during specific hours (24-hour format)
			allowed_hours = {9, 10, 11, 12, 13, 14, 15, 16, 17, 18},
			-- Auto-approve on specific days (1=Monday, 7=Sunday)
			allowed_days = {1, 2, 3, 4, 5, 6, 7}
		},
		
		-- Session-based patterns
		session_based = {
			enabled = true,
			-- Auto-approve after N successful approvals in session
			trust_threshold = 5,
			-- Auto-approve if user has approved similar requests before
			similarity_threshold = 0.8
		}
	},
	
	-- Approval timeout configuration
	timeout = {
		default_timeout = 30, -- seconds
		file_operations_timeout = 60,
		batch_operations_timeout = 120,
		decision_points_timeout = 180
	},
	
	-- Notification settings
	notifications = {
		show_auto_approval_notifications = true,
		show_yolo_mode_warnings = true,
		notification_duration = 3 -- seconds
	}
}

-- Load configuration from user settings
function M.load_config(user_config)
	if user_config then
		-- Merge user config with defaults
		for key, value in pairs(user_config) do
			if type(value) == "table" and M.config[key] then
				-- Deep merge for nested tables
				for subkey, subvalue in pairs(value) do
					M.config[key][subkey] = subvalue
				end
			else
				M.config[key] = value
			end
		end
	end
end

-- Check if a tool should be auto-approved
function M.should_auto_approve_tool(tool_name, parameters)
	-- YOLO mode bypasses all checks
	if M.config.yolo_mode then
		return true, "YOLO mode enabled"
	end
	
	-- Check if auto-approval is enabled
	if not M.config.auto_approval.enabled then
		return false, "Auto-approval disabled"
	end
	
	-- Check tool-based patterns
	for _, auto_tool in ipairs(M.config.auto_approval.patterns.tools) do
		if auto_tool == tool_name then
			return true, "Tool in auto-approval list"
		end
	end
	
	-- Check file operation patterns
	if tool_name == "agent_create_file" or tool_name == "agent_edit_file" then
		return M.should_auto_approve_file_operation(tool_name, parameters)
	end
	
	-- Check command patterns
	if tool_name == "agent_execute_command" then
		return M.should_auto_approve_command(parameters)
	end
	
	return false, "No auto-approval pattern matched"
end

-- Check if a file operation should be auto-approved
function M.should_auto_approve_file_operation(tool_name, parameters)
	local file_path = parameters.file_path or parameters.file_name or ""
	
	-- Check directory patterns
	for _, dir in ipairs(M.config.auto_approval.patterns.file_operations.create_in_dirs) do
		if file_path:find(dir, 1, true) then
			return true, "File in auto-approval directory"
		end
	end
	
	-- Check extension patterns
	for _, ext in ipairs(M.config.auto_approval.patterns.file_operations.create_extensions) do
		if file_path:sub(-#ext) == ext then
			return true, "File has auto-approval extension"
		end
	end
	
	-- Check file type patterns
	for _, pattern in ipairs(M.config.auto_approval.patterns.file_operations.edit_file_types) do
		if M.match_pattern(file_path, pattern) then
			return true, "File matches auto-approval pattern"
		end
	end
	
	-- Check content size
	if parameters.content and #parameters.content <= M.config.auto_approval.patterns.content.max_auto_approve_size then
		return true, "Content size within auto-approval limit"
	end
	
	-- Check content patterns
	if parameters.content then
		for _, pattern in ipairs(M.config.auto_approval.patterns.content.patterns) do
			if parameters.content:match(pattern) then
				return true, "Content matches auto-approval pattern"
			end
		end
	end
	
	return false, "File operation not auto-approved"
end

-- Check if a command should be auto-approved
function M.should_auto_approve_command(parameters)
	local command = parameters.command or ""
	local command_type = parameters.command_type or "neovim"
	
	if command_type == "neovim" then
		for _, auto_cmd in ipairs(M.config.auto_approval.patterns.commands.neovim_commands) do
			if command == auto_cmd then
				return true, "Neovim command in auto-approval list"
			end
		end
	elseif command_type == "shell" then
		for _, auto_cmd in ipairs(M.config.auto_approval.patterns.commands.shell_commands) do
			if command == auto_cmd then
				return true, "Shell command in auto-approval list"
			end
		end
	end
	
	return false, "Command not auto-approved"
end

-- Check time-based auto-approval
function M.should_auto_approve_by_time()
	if not M.config.auto_approval.time_based.enabled then
		return false, "Time-based auto-approval disabled"
	end
	
	local current_time = os.date("*t")
	local current_hour = current_time.hour
	local current_day = current_time.wday
	
	-- Check if current hour is allowed
	local hour_allowed = false
	for _, hour in ipairs(M.config.auto_approval.time_based.allowed_hours) do
		if current_hour == hour then
			hour_allowed = true
			break
		end
	end
	
	-- Check if current day is allowed
	local day_allowed = false
	for _, day in ipairs(M.config.auto_approval.time_based.allowed_days) do
		if current_day == day then
			day_allowed = true
			break
		end
	end
	
	if hour_allowed and day_allowed then
		return true, "Current time allows auto-approval"
	end
	
	return false, "Current time not in auto-approval window"
end

-- Check session-based auto-approval
function M.should_auto_approve_by_session(session_approvals, similar_requests)
	if not M.config.auto_approval.session_based.enabled then
		return false, "Session-based auto-approval disabled"
	end
	
	-- Check trust threshold
	if session_approvals and session_approvals >= M.config.auto_approval.session_based.trust_threshold then
		return true, "Session trust threshold reached"
	end
	
	-- Check similarity threshold
	if similar_requests and similar_requests >= M.config.auto_approval.session_based.similarity_threshold then
		return true, "Similar request previously approved"
	end
	
	return false, "Session-based auto-approval conditions not met"
end

-- Enable YOLO mode
function M.enable_yolo_mode()
	M.config.yolo_mode = true
	if M.config.notifications.show_yolo_mode_warnings then
		vim.notify("⚠️ YOLO mode enabled! All approvals will be bypassed.", vim.log.levels.WARN)
	end
end

-- Disable YOLO mode
function M.disable_yolo_mode()
	M.config.yolo_mode = false
	vim.notify("✅ YOLO mode disabled. Normal approval workflow restored.", vim.log.levels.INFO)
end

-- Toggle YOLO mode
function M.toggle_yolo_mode()
	if M.config.yolo_mode then
		M.disable_yolo_mode()
	else
		M.enable_yolo_mode()
	end
end

-- Add tool to auto-approval list
function M.add_auto_approval_tool(tool_name)
	for _, existing in ipairs(M.config.auto_approval.patterns.tools) do
		if existing == tool_name then
			return false, "Tool already in auto-approval list"
		end
	end
	
	table.insert(M.config.auto_approval.patterns.tools, tool_name)
	return true, "Tool added to auto-approval list"
end

-- Remove tool from auto-approval list
function M.remove_auto_approval_tool(tool_name)
	for i, existing in ipairs(M.config.auto_approval.patterns.tools) do
		if existing == tool_name then
			table.remove(M.config.auto_approval.patterns.tools, i)
			return true, "Tool removed from auto-approval list"
		end
	end
	
	return false, "Tool not found in auto-approval list"
end

-- Add directory to auto-approval list
function M.add_auto_approval_directory(directory)
	for _, existing in ipairs(M.config.auto_approval.patterns.file_operations.create_in_dirs) do
		if existing == directory then
			return false, "Directory already in auto-approval list"
		end
	end
	
	table.insert(M.config.auto_approval.patterns.file_operations.create_in_dirs, directory)
	return true, "Directory added to auto-approval list"
end

-- Add extension to auto-approval list
function M.add_auto_approval_extension(extension)
	for _, existing in ipairs(M.config.auto_approval.patterns.file_operations.create_extensions) do
		if existing == extension then
			return false, "Extension already in auto-approval list"
		end
	end
	
	table.insert(M.config.auto_approval.patterns.file_operations.create_extensions, extension)
	return true, "Extension added to auto-approval list"
end

-- Get current configuration
function M.get_config()
	return M.config
end

-- Save configuration to file
function M.save_config(file_path)
	file_path = file_path or vim.fn.stdpath("config") .. "/paragonic_approval_config.json"
	
	local success, encoded = pcall(vim.json.encode, M.config)
	if not success then
		return false, "Failed to encode configuration"
	end
	
	local success, err = pcall(vim.fn.writefile, {encoded}, file_path)
	if not success then
		return false, "Failed to write configuration file: " .. tostring(err)
	end
	
	return true, "Configuration saved to " .. file_path
end

-- Load configuration from file
function M.load_config_from_file(file_path)
	file_path = file_path or vim.fn.stdpath("config") .. "/paragonic_approval_config.json"
	
	local success, content = pcall(vim.fn.readfile, file_path)
	if not success then
		return false, "Failed to read configuration file"
	end
	
	local success, decoded = pcall(vim.json.decode, table.concat(content, "\n"))
	if not success then
		return false, "Failed to decode configuration file"
	end
	
	M.load_config(decoded)
	return true, "Configuration loaded from " .. file_path
end

-- Show configuration status
function M.show_status()
	local status = {
		"# Approval Configuration Status",
		"",
		"## YOLO Mode: " .. (M.config.yolo_mode and "🟢 ENABLED" or "🔴 DISABLED"),
		"",
		"## Auto-Approval: " .. (M.config.auto_approval.enabled and "🟢 ENABLED" or "🔴 DISABLED"),
		"",
		"### Auto-Approved Tools (" .. #M.config.auto_approval.patterns.tools .. "):",
	}
	
	for _, tool in ipairs(M.config.auto_approval.patterns.tools) do
		table.insert(status, "- " .. tool)
	end
	
	table.insert(status, "")
	table.insert(status, "### Auto-Approved Directories (" .. #M.config.auto_approval.patterns.file_operations.create_in_dirs .. "):")
	for _, dir in ipairs(M.config.auto_approval.patterns.file_operations.create_in_dirs) do
		table.insert(status, "- " .. dir)
	end
	
	table.insert(status, "")
	table.insert(status, "### Auto-Approved Extensions (" .. #M.config.auto_approval.patterns.file_operations.create_extensions .. "):")
	for _, ext in ipairs(M.config.auto_approval.patterns.file_operations.create_extensions) do
		table.insert(status, "- " .. ext)
	end
	
	table.insert(status, "")
	table.insert(status, "## Commands:")
	table.insert(status, ":lua require('paragonic.approval_config').toggle_yolo_mode()")
	table.insert(status, ":lua require('paragonic.approval_config').add_auto_approval_tool('tool_name')")
	table.insert(status, ":lua require('paragonic.approval_config').add_auto_approval_directory('dir/')")
	table.insert(status, ":lua require('paragonic.approval_config').show_status()")
	
	-- Display in a floating window
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, status)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	
	local width = 60
	local height = #status + 2
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
	
	-- Close on q
	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(win, true)
		vim.api.nvim_buf_delete(buf, {force = true})
	end, {buffer = buf, noremap = true, silent = true})
end

-- Helper function to match file patterns
function M.match_pattern(filename, pattern)
	-- Simple pattern matching (can be enhanced)
	if pattern:sub(1, 1) == "*" then
		local ext = pattern:sub(2)
		return filename:sub(-#ext) == ext
	elseif pattern:sub(1, 1) == "." then
		return filename:sub(-#pattern) == pattern
	end
	return filename == pattern
end

return M
