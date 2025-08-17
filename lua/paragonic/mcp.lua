--[[
Paragonic MCP Module
Handles MCP (Model Context Protocol) functionality
--]]

local M = {}

-- MCP state
M.mcp_server_initialized = false
M.mcp_resources = {}
M.mcp_tools = {}

-- MCP Cancellation state management
M.cancellation_state = {
	active_operations = {},
	next_operation_id = 1,
}

-- Tool-pattern relationship tracking
M.tool_pattern_usage = {}
M.pattern_tool_mappings = {}

-- Pattern execution tracking
M.pattern_execution_history = {}
M.execution_counter = 0

-- Approval state management
M.approval_state = {
	active_requests = {},
	audit_trail = {},
	next_audit_id = 1,
	cleanup_timer = nil,
}

-- Initialize MCP server
function M.initialize_mcp_server()
	if M.mcp_server_initialized then
		vim.notify("MCP server already initialized", vim.log.levels.INFO)
		return true
	end

	-- Initialize MCP resources
	M.mcp_resources = {
		{
			uri = "neovim://buffers",
			name = "Neovim Buffers",
			description = "All open buffers in the current Neovim session",
			mimeType = "application/json",
		},
		{
			uri = "neovim://session",
			name = "Neovim Session",
			description = "Current Neovim session information",
			mimeType = "application/json",
		},
		{
			uri = "neovim://commands",
			name = "Neovim Commands",
			description = "Available Neovim commands",
			mimeType = "application/json",
		},
		{
			uri = "neovim://autocommands",
			name = "Neovim Autocommands",
			description = "Registered autocommands",
			mimeType = "application/json",
		},
	}

	-- Initialize MCP tools with enhanced pattern information
	M.mcp_tools = {
		{
			name = "agent_edit_file",
			description = "Edit a file in the current Neovim session",
			inputSchema = {
				type = "object",
				properties = {
					file_path = {
						type = "string",
						description = "Path to the file to edit",
					},
					line_number = {
						type = "integer",
						description = "Line number to edit (1-based)",
					},
					content = {
						type = "string",
						description = "Content to insert at the specified line",
					},
				},
				required = { "file_path", "line_number" },
			},
			patterns = {
				{
					pattern_id = "session_summary_generation",
					relationship_type = "input",
					description = "Used to modify files during session summary generation pattern",
				},
				{
					pattern_id = "activity_labeling",
					relationship_type = "enhance",
					description = "Enhances activity labeling pattern by tracking file modifications",
				},
			},
			usage_guidance = "Use this tool when you need to modify file content. Always specify the file_path and line_number. The content parameter is optional and will replace the entire line if provided.",
			success_metrics = {
				success_rate = 0.95,
				usage_count = 0,
				last_used = nil,
			},
		},
		{
			name = "agent_create_file",
			description = "Create a new file in the current Neovim session",
			inputSchema = {
				type = "object",
				properties = {
					file_name = {
						type = "string",
						description = "Name of the file to create",
					},
					content = {
						type = "string",
						description = "Initial content for the file",
					},
					open_in_window = {
						type = "boolean",
						description = "Whether to open the file in a new window",
					},
				},
				required = { "file_name" },
			},
			patterns = {
				{
					pattern_id = "session_summary_generation",
					relationship_type = "input",
					description = "Used to create summary files during session summary generation pattern",
				},
				{
					pattern_id = "activity_labeling",
					relationship_type = "enhance",
					description = "Enhances activity labeling pattern by tracking file creation activities",
				},
				{
					pattern_id = "knowledge_extraction",
					relationship_type = "output",
					description = "Creates files to store extracted knowledge and insights pattern",
				},
			},
			usage_guidance = "Use this tool when you need to create new files. The file_name parameter is required. Content is optional and will create an empty file if not provided. Set open_in_window to true if you want the file to open in a new window.",
			success_metrics = {
				success_rate = 0.92,
				usage_count = 0,
				last_used = nil,
			},
		},
		{
			name = "agent_save_file",
			description = "Save files to disk in the current Neovim session",
			inputSchema = {
				type = "object",
				properties = {
					file_path = {
						type = "string",
						description = "Path to the file to save (optional, uses current buffer if not specified)",
					},
					force = {
						type = "boolean",
						description = "Force save even if file is read-only",
					},
				},
				required = {},
			},
			patterns = {
				{
					pattern_id = "progress_tracking",
					relationship_type = "enhance",
					description = "Enhances progress tracking pattern by recording file save events",
				},
				{
					pattern_id = "activity_labeling",
					relationship_type = "enhance",
					description = "Enhances activity labeling pattern by tracking file save activities",
				},
				{
					pattern_id = "session_summary_generation",
					relationship_type = "input",
					description = "Used to save files before generating session summaries pattern",
				},
			},
			usage_guidance = "Use this tool when you need to save files to disk. If file_path is not specified, it will save the current buffer. Use force=true to save read-only files. This tool is essential for persisting changes.",
			success_metrics = {
				success_rate = 0.98,
				usage_count = 0,
				last_used = nil,
			},
		},
		{
			name = "agent_session_info",
			description = "Get current session information and context",
			inputSchema = {
				type = "object",
				properties = {
					include_buffers = {
						type = "boolean",
						description = "Include information about open buffers",
					},
					include_patterns = {
						type = "boolean",
						description = "Include information about active patterns",
					},
					include_history = {
						type = "boolean",
						description = "Include recent interaction history",
					},
				},
				required = {},
			},
			patterns = {
				{
					pattern_id = "self_reflection",
					relationship_type = "input",
					description = "Provides session context for self-reflection pattern",
				},
				{
					pattern_id = "activity_labeling",
					relationship_type = "enhance",
					description = "Enhances activity labeling pattern with session context",
				},
				{
					pattern_id = "progress_tracking",
					relationship_type = "input",
					description = "Provides session data for progress tracking pattern",
				},
			},
			usage_guidance = "Use this tool to get current session information including buffer details, active patterns, and recent interactions. This is useful for understanding the current context before making decisions.",
			success_metrics = {
				success_rate = 0.99,
				usage_count = 0,
				last_used = nil,
			},
		},
		{
			name = "agent_search_files",
			description = "Search for files in the current directory and subdirectories",
			inputSchema = {
				type = "object",
				properties = {
					query = {
						type = "string",
						description = "Search query (filename pattern or content)",
					},
					file_type = {
						type = "string",
						description = "Filter by file type (e.g., 'lua', 'md', 'txt')",
					},
					recursive = {
						type = "boolean",
						description = "Search recursively in subdirectories",
					},
					max_results = {
						type = "integer",
						description = "Maximum number of results to return",
					},
				},
				required = { "query" },
			},
			patterns = {
				{
					pattern_id = "knowledge_extraction",
					relationship_type = "input",
					description = "Used to find relevant files for knowledge extraction pattern",
				},
				{
					pattern_id = "context_summarization",
					relationship_type = "input",
					description = "Used to find files for context summarization pattern",
				},
			},
			usage_guidance = "Use this tool to search for files by name or content. Specify a query string and optionally filter by file type. Set recursive=true to search subdirectories.",
			success_metrics = {
				success_rate = 0.90,
				usage_count = 0,
				last_used = nil,
			},
		},
		{
			name = "agent_execute_command",
			description = "Execute Neovim commands or external shell commands",
			inputSchema = {
				type = "object",
				properties = {
					command = {
						type = "string",
						description = "Command to execute (Neovim command or shell command)",
					},
					command_type = {
						type = "string",
						enum = { "neovim", "shell" },
						description = "Type of command to execute",
					},
					args = {
						type = "array",
						items = { type = "string" },
						description = "Additional arguments for the command",
					},
				},
				required = { "command" },
			},
			patterns = {
				{
					pattern_id = "activity_labeling",
					relationship_type = "enhance",
					description = "Enhances activity labeling pattern by tracking command executions",
				},
				{
					pattern_id = "progress_tracking",
					relationship_type = "enhance",
					description = "Enhances progress tracking pattern by recording command activities",
				},
			},
			usage_guidance = "Use this tool to execute Neovim commands or shell commands. Specify command_type as 'neovim' for Neovim commands or 'shell' for external commands. Be careful with shell commands and ensure they are safe.",
			success_metrics = {
				success_rate = 0.85,
				usage_count = 0,
				last_used = nil,
			},
		},
	}

	M.mcp_server_initialized = true
	vim.notify("MCP server initialized successfully", vim.log.levels.INFO)
	return true
end

-- List MCP resources
function M.list_mcp_resources()
	if not M.mcp_server_initialized then
		M.initialize_mcp_server()
	end

	return M.mcp_resources
end

-- List MCP tools
function M.list_mcp_tools()
	if not M.mcp_server_initialized then
		M.initialize_mcp_server()
	end

	return M.mcp_tools
end

-- Read MCP resource
function M.read_mcp_resource(uri)
	if not M.mcp_server_initialized then
		M.initialize_mcp_server()
	end

	if uri == "neovim://buffers" then
		return M.get_buffers_info()
	elseif uri == "neovim://session" then
		return M.get_session_info()
	elseif uri == "neovim://commands" then
		return M.get_commands_info()
	elseif uri == "neovim://autocommands" then
		return M.get_autocommands_info()
	else
		return nil, "Unknown resource URI: " .. uri
	end
end

-- Track tool-pattern usage
function M.track_tool_pattern_usage(tool_name, pattern_id, success)
	if not M.tool_pattern_usage[tool_name] then
		M.tool_pattern_usage[tool_name] = {}
	end

	if not M.tool_pattern_usage[tool_name][pattern_id] then
		M.tool_pattern_usage[tool_name][pattern_id] = {
			total_usage = 0,
			successful_usage = 0,
			last_used = nil,
		}
	end

	local usage = M.tool_pattern_usage[tool_name][pattern_id]
	usage.total_usage = usage.total_usage + 1
	if success then
		usage.successful_usage = usage.successful_usage + 1
	end
	usage.last_used = os.time()

	-- Update tool success metrics
	for _, tool in ipairs(M.mcp_tools) do
		if tool.name == tool_name then
			tool.success_metrics.usage_count = tool.success_metrics.usage_count + 1
			tool.success_metrics.last_used = os.time()

			-- Update success rate based on pattern usage
			local total_pattern_usage = 0
			local total_successful_pattern_usage = 0
			for _, pattern_usage in pairs(M.tool_pattern_usage[tool_name]) do
				total_pattern_usage = total_pattern_usage + pattern_usage.total_usage
				total_successful_pattern_usage = total_successful_pattern_usage + pattern_usage.successful_usage
			end

			if total_pattern_usage > 0 then
				tool.success_metrics.success_rate = total_successful_pattern_usage / total_pattern_usage
			end
			break
		end
	end

	return true
end

-- Get tools for a specific pattern
function M.get_tools_for_pattern(pattern_id)
	local tools_for_pattern = {}

	for _, tool in ipairs(M.mcp_tools) do
		for _, pattern in ipairs(tool.patterns) do
			if pattern.pattern_id == pattern_id then
				table.insert(tools_for_pattern, {
					tool_name = tool.name,
					relationship_type = pattern.relationship_type,
					description = pattern.description,
					tool_description = tool.description,
				})
				break
			end
		end
	end

	return tools_for_pattern
end

-- Get patterns for a specific tool
function M.get_patterns_for_tool(tool_name)
	for _, tool in ipairs(M.mcp_tools) do
		if tool.name == tool_name then
			return tool.patterns
		end
	end

	return {}
end

-- Get tool-pattern usage statistics
function M.get_tool_pattern_usage_stats(tool_name, pattern_id)
	if not M.tool_pattern_usage[tool_name] or not M.tool_pattern_usage[tool_name][pattern_id] then
		return nil
	end

	local usage = M.tool_pattern_usage[tool_name][pattern_id]
	return {
		total_usage = usage.total_usage,
		successful_usage = usage.successful_usage,
		success_rate = usage.total_usage > 0 and usage.successful_usage / usage.total_usage or 0,
		last_used = usage.last_used,
	}
end

-- Get pattern-specific recommendations
function M.get_pattern_recommendations(pattern_id)
	local recommendations = {}

	for _, tool in ipairs(M.mcp_tools) do
		for _, pattern in ipairs(tool.patterns) do
			if pattern.pattern_id == pattern_id then
				local stats = M.get_tool_pattern_usage_stats(tool.name, pattern_id)
				local success_rate = stats and stats.success_rate or tool.success_metrics.success_rate
				local usage_count = stats and stats.total_usage or tool.success_metrics.usage_count

				table.insert(recommendations, {
					tool_name = tool.name,
					pattern_id = pattern_id,
					confidence = success_rate * (1 + math.min(usage_count / 10, 1)),
					reason = pattern.description,
					success_rate = success_rate,
					usage_count = usage_count,
					relationship_type = pattern.relationship_type,
				})
				break
			end
		end
	end

	-- Sort by confidence (highest first)
	table.sort(recommendations, function(a, b)
		return a.confidence > b.confidence
	end)

	return recommendations
end

-- Get context-based recommendations
function M.get_context_recommendations(context)
	local recommendations = {}
	local context_score = {}

	-- Calculate context relevance scores for each tool
	for _, tool in ipairs(M.mcp_tools) do
		local score = 0

		-- Score based on recent tool usage
		if context.recent_tools then
			for _, recent_tool in ipairs(context.recent_tools) do
				if recent_tool == tool.name then
					score = score + 0.3
					break
				end
			end
		end

		-- Score based on active patterns
		if context.patterns_active then
			for _, pattern in ipairs(tool.patterns) do
				for _, active_pattern in ipairs(context.patterns_active) do
					if pattern.pattern_id == active_pattern then
						score = score + 0.4
						break
					end
				end
			end
		end

		-- Score based on current activity
		if context.current_activity then
			if context.current_activity == "file_editing" and tool.name == "agent_edit_file" then
				score = score + 0.3
			elseif context.current_activity == "file_creation" and tool.name == "agent_create_file" then
				score = score + 0.3
			elseif context.current_activity == "file_saving" and tool.name == "agent_save_file" then
				score = score + 0.3
			end
		end

		-- Add success rate to score
		score = score + tool.success_metrics.success_rate * 0.2

		if score > 0 then
			table.insert(recommendations, {
				tool_name = tool.name,
				confidence = score,
				reason = "Contextually relevant based on current activity and patterns",
				success_rate = tool.success_metrics.success_rate,
				usage_count = tool.success_metrics.usage_count,
			})
		end
	end

	-- Sort by confidence (highest first)
	table.sort(recommendations, function(a, b)
		return a.confidence > b.confidence
	end)

	return recommendations
end

-- Get top performing tools
function M.get_top_performing_tools(limit)
	local tool_performance = {}

	for _, tool in ipairs(M.mcp_tools) do
		table.insert(tool_performance, {
			tool_name = tool.name,
			success_rate = tool.success_metrics.success_rate,
			usage_count = tool.success_metrics.usage_count,
			last_used = tool.success_metrics.last_used,
		})
	end

	-- Sort by success rate (highest first)
	table.sort(tool_performance, function(a, b)
		return a.success_rate > b.success_rate
	end)

	-- Return top N tools
	if limit then
		return { table.unpack(tool_performance, 1, math.min(limit, #tool_performance)) }
	else
		return tool_performance
	end
end

-- Get task-specific recommendations
function M.get_task_recommendations(task_type)
	local task_patterns = {
		file_creation = { "knowledge_extraction", "session_summary_generation" },
		file_editing = { "session_summary_generation", "activity_labeling" },
		file_saving = { "progress_tracking", "session_summary_generation" },
		session_management = { "session_summary_generation", "activity_labeling" },
		knowledge_management = { "knowledge_extraction", "activity_labeling" },
	}

	local recommendations = {}
	local patterns = task_patterns[task_type] or {}

	for _, pattern_id in ipairs(patterns) do
		local pattern_recs = M.get_pattern_recommendations(pattern_id)
		for _, rec in ipairs(pattern_recs) do
			table.insert(recommendations, rec)
		end
	end

	-- Remove duplicates and sort by confidence
	local seen = {}
	local unique_recommendations = {}
	for _, rec in ipairs(recommendations) do
		if not seen[rec.tool_name] then
			seen[rec.tool_name] = true
			table.insert(unique_recommendations, rec)
		end
	end

	table.sort(unique_recommendations, function(a, b)
		return a.confidence > b.confidence
	end)

	return unique_recommendations
end

-- Get collaborative recommendations
function M.get_collaborative_recommendations(tool_name)
	local collaborative_tools = {
		agent_edit_file = { "agent_save_file" },
		agent_create_file = { "agent_edit_file", "agent_save_file" },
		agent_save_file = { "agent_edit_file" },
	}

	local recommendations = {}
	local collaborators = collaborative_tools[tool_name] or {}

	for _, collab_tool_name in ipairs(collaborators) do
		for _, tool in ipairs(M.mcp_tools) do
			if tool.name == collab_tool_name then
				table.insert(recommendations, {
					tool_name = tool.name,
					confidence = tool.success_metrics.success_rate,
					reason = "Frequently used together with " .. tool_name,
					success_rate = tool.success_metrics.success_rate,
					usage_count = tool.success_metrics.usage_count,
				})
				break
			end
		end
	end

	-- Sort by confidence (highest first)
	table.sort(recommendations, function(a, b)
		return a.confidence > b.confidence
	end)

	return recommendations
end

-- Get filtered recommendations
function M.get_filtered_recommendations(filters)
	local all_recommendations = {}

	-- Get all tools as recommendations
	for _, tool in ipairs(M.mcp_tools) do
		local rec = {
			tool_name = tool.name,
			success_rate = tool.success_metrics.success_rate,
			usage_count = tool.success_metrics.usage_count,
			last_used = tool.success_metrics.last_used,
		}

		-- Add pattern information
		for _, pattern in ipairs(tool.patterns) do
			if filters.pattern_ids then
				for _, filter_pattern in ipairs(filters.pattern_ids) do
					if pattern.pattern_id == filter_pattern then
						rec.pattern_id = pattern.pattern_id
						rec.relationship_type = pattern.relationship_type
						break
					end
				end
			end
		end

		table.insert(all_recommendations, rec)
	end

	-- Apply filters
	local filtered_recommendations = {}
	for _, rec in ipairs(all_recommendations) do
		local include = true

		if filters.min_success_rate and rec.success_rate < filters.min_success_rate then
			include = false
		end

		if filters.max_usage_count and rec.usage_count > filters.max_usage_count then
			include = false
		end

		if filters.pattern_ids and not rec.pattern_id then
			include = false
		end

		if include then
			table.insert(filtered_recommendations, rec)
		end
	end

	-- Sort by success rate (highest first)
	table.sort(filtered_recommendations, function(a, b)
		return a.success_rate > b.success_rate
	end)

	return filtered_recommendations
end

-- Execute tool with pattern tracking
function M.execute_tool_with_pattern(tool_name, args, pattern_id)
	M.execution_counter = M.execution_counter + 1
	local execution_id = "exec_" .. M.execution_counter

	-- Validate pattern exists for this tool
	local valid_pattern = false
	for _, tool in ipairs(M.mcp_tools) do
		if tool.name == tool_name then
			for _, pattern in ipairs(tool.patterns) do
				if pattern.pattern_id == pattern_id then
					valid_pattern = true
					break
				end
			end
			break
		end
	end

	if not valid_pattern then
		return {
			success = false,
			error = "Invalid pattern " .. pattern_id .. " for tool " .. tool_name,
			execution_id = execution_id,
		}
	end

	-- Simulate tool execution (in real implementation, this would call the actual tool)
	local success = true
	local result = "Tool " .. tool_name .. " executed successfully with pattern " .. pattern_id

	-- Track the execution
	M.track_tool_pattern_usage(tool_name, pattern_id, success)

	-- Record in execution history
	table.insert(M.pattern_execution_history, {
		execution_id = execution_id,
		tool_name = tool_name,
		pattern_id = pattern_id,
		args = args,
		success = success,
		timestamp = os.time(),
		result = result,
	})

	return {
		success = success,
		pattern_tracked = true,
		execution_id = execution_id,
		result = result,
	}
end

-- Execute tool with automatic pattern detection
function M.execute_tool_with_auto_pattern_detection(tool_name, args)
	M.execution_counter = M.execution_counter + 1
	local execution_id = "exec_" .. M.execution_counter

	local detected_patterns = {}

	-- Find the tool and its patterns
	for _, tool in ipairs(M.mcp_tools) do
		if tool.name == tool_name then
			-- Simple pattern detection based on tool name and args
			if tool_name == "agent_create_file" and args.file_name then
				if string.find(args.file_name, "summary") or string.find(args.file_name, "summary") then
					table.insert(detected_patterns, { pattern_id = "session_summary_generation", confidence = 0.9 })
				end
				if args.content and string.find(args.content, "knowledge") then
					table.insert(detected_patterns, { pattern_id = "knowledge_extraction", confidence = 0.8 })
				end
			elseif tool_name == "agent_edit_file" then
				table.insert(detected_patterns, { pattern_id = "activity_labeling", confidence = 0.7 })
			elseif tool_name == "agent_save_file" then
				table.insert(detected_patterns, { pattern_id = "progress_tracking", confidence = 0.8 })
			end

			-- Add all tool patterns with lower confidence
			for _, pattern in ipairs(tool.patterns) do
				local found = false
				for _, detected in ipairs(detected_patterns) do
					if detected.pattern_id == pattern.pattern_id then
						found = true
						break
					end
				end
				if not found then
					table.insert(detected_patterns, { pattern_id = pattern.pattern_id, confidence = 0.5 })
				end
			end
			break
		end
	end

	-- Track usage for detected patterns
	for _, pattern in ipairs(detected_patterns) do
		M.track_tool_pattern_usage(tool_name, pattern.pattern_id, true)
	end

	return {
		success = true,
		detected_patterns = detected_patterns,
		execution_id = execution_id,
	}
end

-- Execute tool with pattern validation
function M.execute_tool_with_pattern_validation(tool_name, args, pattern_id)
	-- Check if pattern is valid for this tool
	local valid = false
	local error_msg = nil

	for _, tool in ipairs(M.mcp_tools) do
		if tool.name == tool_name then
			for _, pattern in ipairs(tool.patterns) do
				if pattern.pattern_id == pattern_id then
					valid = true
					break
				end
			end
			if not valid then
				error_msg = "Pattern " .. pattern_id .. " is not valid for tool " .. tool_name
			end
			break
		end
	end

	if not valid then
		return {
			valid = false,
			error = error_msg,
		}
	end

	-- Execute the tool if validation passes
	local result = M.execute_tool_with_pattern(tool_name, args, pattern_id)
	result.valid = true

	return result
end

-- Execute tool with pattern-based recommendations
function M.execute_tool_with_pattern_recommendations(tool_name, args, pattern_id)
	-- Get recommendations for the pattern
	local recommendations = M.get_pattern_recommendations(pattern_id)

	-- Execute the tool
	local result = M.execute_tool_with_pattern(tool_name, args, pattern_id)

	-- Add recommendations to result
	result.recommendations = recommendations

	return result
end

-- Execute tool with pattern execution history
function M.execute_tool_with_pattern_history(tool_name, args, pattern_id)
	-- Execute the tool
	local result = M.execute_tool_with_pattern(tool_name, args, pattern_id)

	-- Get execution history for this tool-pattern combination
	local history = {}
	for _, entry in ipairs(M.pattern_execution_history) do
		if entry.tool_name == tool_name and entry.pattern_id == pattern_id then
			table.insert(history, {
				tool_name = entry.tool_name,
				pattern_id = entry.pattern_id,
				timestamp = entry.timestamp,
				success = entry.success,
				execution_id = entry.execution_id,
			})
		end
	end

	result.history = history

	return result
end

-- Execute tool with pattern performance metrics
function M.execute_tool_with_pattern_metrics(tool_name, args, pattern_id)
	local start_time = os.clock()

	-- Execute the tool
	local result = M.execute_tool_with_pattern(tool_name, args, pattern_id)

	local execution_time = os.clock() - start_time

	-- Get performance metrics
	local stats = M.get_tool_pattern_usage_stats(tool_name, pattern_id)
	local tool_stats = nil
	for _, tool in ipairs(M.mcp_tools) do
		if tool.name == tool_name then
			tool_stats = tool.success_metrics
			break
		end
	end

	result.metrics = {
		execution_time = execution_time,
		pattern_success_rate = stats and stats.success_rate or 0,
		tool_success_rate = tool_stats and tool_stats.success_rate or 0,
	}

	return result
end

-- Execute tool with pattern learning
function M.execute_tool_with_pattern_learning(tool_name, args, pattern_id, success)
	-- Execute the tool
	local result = M.execute_tool_with_pattern(tool_name, args, pattern_id)

	-- Apply learning (update success rates based on actual outcome)
	if success ~= nil then
		M.track_tool_pattern_usage(tool_name, pattern_id, success)

		-- Update tool success metrics
		for _, tool in ipairs(M.mcp_tools) do
			if tool.name == tool_name then
				-- Recalculate success rate based on all pattern usage
				local total_usage = 0
				local total_successful = 0
				for _, pattern_usage in pairs(M.tool_pattern_usage[tool_name] or {}) do
					total_usage = total_usage + pattern_usage.total_usage
					total_successful = total_successful + pattern_usage.successful_usage
				end

				if total_usage > 0 then
					tool.success_metrics.success_rate = total_successful / total_usage
				end
				break
			end
		end

		result.learning_applied = true
		result.pattern_adapted = true
		result.new_success_rate = M.get_tool_pattern_usage_stats(tool_name, pattern_id)
				and M.get_tool_pattern_usage_stats(tool_name, pattern_id).success_rate
			or 0
	end

	return result
end

-- Get buffers information
function M.get_buffers_info()
	local buffers = vim.api.nvim_list_bufs()
	local result = {}

	for _, buf in ipairs(buffers) do
		if vim.api.nvim_buf_is_valid(buf) then
			local buf_name = vim.api.nvim_buf_get_name(buf)
			local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
			local modifiable = vim.api.nvim_buf_get_option(buf, "modifiable")
			local line_count = vim.api.nvim_buf_line_count(buf)
			local modified = vim.api.nvim_buf_get_option(buf, "modified")

			table.insert(result, {
				id = buf,
				name = buf_name,
				type = buftype,
				modifiable = modifiable,
				line_count = line_count,
				modified = modified,
				is_current = (buf == vim.api.nvim_get_current_buf()),
			})
		end
	end

	return result
end

-- Get session information
function M.get_session_info()
	return {
		current_file = vim.fn.expand("%:p"),
		current_directory = vim.fn.getcwd(),
		buffer_count = #vim.api.nvim_list_bufs(),
		window_count = #vim.api.nvim_list_wins(),
		tab_count = #vim.api.nvim_list_tabpages(),
		mode = vim.fn.mode(),
		cursor_position = vim.api.nvim_win_get_cursor(0),
		terminal_size = {
			columns = vim.o.columns,
			lines = vim.o.lines,
		},
		timestamp = os.time(),
	}
end

-- Helper to get all Neovim commands
function M.get_commands_info()
	local commands = vim.api.nvim_get_commands({})
	local result = {}
	for name, cmd in pairs(commands) do
		table.insert(result, {
			name = name,
			definition = cmd.definition,
			nargs = cmd.nargs,
			bang = cmd.bang,
		})
	end
	return result
end

-- Helper to get all Neovim autocommands
function M.get_autocommands_info()
	local autocmds = vim.api.nvim_get_autocmds({})
	local result = {}
	for _, ac in ipairs(autocmds) do
		table.insert(result, {
			event = ac.event,
			group = ac.group,
			group_name = ac.group_name,
			pattern = ac.pattern,
			command = ac.command,
			desc = ac.desc,
		})
	end
	return result
end

-- Sample resource content based on criteria
function M.sample_resource(uri, criteria)
	if uri == "neovim://buffers" then
		local buffers = M.get_buffers_info()

		-- Apply sampling criteria
		if criteria and criteria.limit then
			local sampled = {}
			for i = 1, math.min(criteria.limit, #buffers) do
				table.insert(sampled, buffers[i])
			end
			return sampled
		end

		-- Apply filters
		if criteria and criteria.filter then
			local filtered = {}
			for _, buffer in ipairs(buffers) do
				local matches = true

				if criteria.filter.file_type and buffer.type ~= criteria.filter.file_type then
					matches = false
				end

				if criteria.filter.name_pattern and not buffer.name:match(criteria.filter.name_pattern) then
					matches = false
				end

				if matches then
					table.insert(filtered, buffer)
				end
			end
			return filtered
		end

		return buffers
	elseif uri == "neovim://session" then
		local session = M.get_session_info()

		-- Apply field selection
		if criteria and criteria.fields then
			local sampled = {}
			for _, field in ipairs(criteria.fields) do
				if session[field] then
					sampled[field] = session[field]
				end
			end
			return sampled
		end

		return session
	else
		return nil
	end
end

-- Define resource roots for context boundaries
function M.define_resource_roots(uri, options)
	if uri == "neovim://buffers" then
		local roots = {}

		if options and options.buffer_ids then
			for _, buf_id in ipairs(options.buffer_ids) do
				local buf_name = vim.api.nvim_buf_get_name(buf_id)
				if buf_name and buf_name ~= "" then
					table.insert(roots, {
						uri = "file://" .. buf_name,
						name = vim.fn.fnamemodify(buf_name, ":t"),
						description = "Buffer " .. buf_id .. ": " .. buf_name,
					})
				end
			end
		end

		if options and options.file_patterns then
			local buffers = vim.api.nvim_list_bufs()
			for _, buf_id in ipairs(buffers) do
				local buf_name = vim.api.nvim_buf_get_name(buf_id)
				if buf_name and buf_name ~= "" then
					for _, pattern in ipairs(options.file_patterns) do
						if buf_name:match(pattern) then
							table.insert(roots, {
								uri = "file://" .. buf_name,
								name = vim.fn.fnamemodify(buf_name, ":t"),
								description = "Pattern match: " .. buf_name,
							})
							break
						end
					end
				end
			end
		end

		return roots
	elseif uri == "neovim://session" then
		local roots = {}

		if options and options.current_only then
			local cwd = vim.fn.getcwd()
			table.insert(roots, {
				uri = "file://" .. cwd,
				name = "Current Directory",
				description = "Current working directory: " .. cwd,
			})
		end

		return roots
	else
		return {}
	end
end

-- Handle MCP sampling requests from external agents
function M.handle_sampling_request(request)
	-- Validate request structure
	if not request or type(request) ~= "table" then
		return {
			id = request and request.id or "unknown",
			error = {
				code = -32600,
				message = "Invalid request: request must be a table",
			},
		}
	end

	local uri = request.uri
	local criteria = request.criteria or {}

	-- Check if this is an approval request
	if uri and uri:match("^approval://") then
		return M.handle_approval_sampling_request(request)
	end

	-- Handle regular sampling requests
	local sampled_data = M.sample_resource(uri, criteria)

	if sampled_data then
		return {
			id = request.id,
			result = {
				content = {
					{
						type = "text",
						text = vim.json.encode(sampled_data),
					},
				},
				metadata = {
					uri = uri,
					criteria = criteria,
					sample_size = type(sampled_data) == "table" and #sampled_data or 1,
					timestamp = os.time(),
				},
			},
		}
	else
		return {
			id = request.id,
			error = {
				code = -32602,
				message = "Failed to sample resource: " .. uri,
			},
		}
	end
end

-- Handle approval-specific sampling requests
function M.handle_approval_sampling_request(request)
	local uri = request.uri
	local criteria = request.criteria or {}
	
	-- Validate approval request
	local is_valid, error_msg = M.validate_approval_request(request)
	if not is_valid then
		return {
			id = request.id,
			error = {
				code = -32602,
				message = "Invalid approval request: " .. error_msg,
			},
		}
	end

	-- Create approval request
	local approval_request = M.create_approval_request(criteria)
	
	-- Check for immediate timeout
	if criteria.timeout and criteria.timeout <= 0 then
		approval_request.status = "timeout"
		approval_request.result = "timeout"
	end

	return {
		id = request.id,
		result = {
			approval_request = approval_request,
			metadata = {
				uri = uri,
				criteria = criteria,
				timestamp = os.time(),
			},
		},
	}
end

-- Validate approval request structure and content
function M.validate_approval_request(request)
	if not request.params or not request.params.criteria then
		return false, "Missing criteria"
	end
	
	local criteria = request.params.criteria
	
	-- Check required fields based on approval type
	if not criteria.approval_type then
		return false, "Missing approval_type"
	end
	
	-- Validate approval type
	local valid_types = {"tool_execution", "decision_point", "batch_action"}
	local is_valid_type = false
	for _, valid_type in ipairs(valid_types) do
		if criteria.approval_type == valid_type then
			is_valid_type = true
			break
		end
	end
	
	if not is_valid_type then
		return false, "Invalid approval_type: " .. tostring(criteria.approval_type)
	end
	
	-- Validate type-specific requirements
	if criteria.approval_type == "tool_execution" then
		if not criteria.tool_name then
			return false, "Missing tool_name for tool_execution"
		end
		if not criteria.parameters then
			return false, "Missing parameters for tool_execution"
		end
	elseif criteria.approval_type == "decision_point" then
		if not criteria.question then
			return false, "Missing question for decision_point"
		end
		if not criteria.options or type(criteria.options) ~= "table" then
			return false, "Missing or invalid options for decision_point"
		end
	end
	
	-- Validate timeout if provided
	if criteria.timeout and (type(criteria.timeout) ~= "number" or criteria.timeout < 0) then
		return false, "Invalid timeout value"
	end
	
	return true, nil
end

-- Create approval request from sampling data
function M.create_approval_request(criteria)
	local approval_id = "approval-" .. os.time() .. "-" .. math.random(1000, 9999)
	
	local approval_request = {
		id = approval_id,
		type = criteria.approval_type,
		status = "pending",
		created_at = os.time(),
		timeout = criteria.timeout or 30,
		criteria = criteria,
	}
	
	-- Add type-specific data
	if criteria.approval_type == "tool_execution" then
		approval_request.tool_name = criteria.tool_name
		approval_request.parameters = criteria.parameters
		approval_request.impact = criteria.impact or "Tool execution"
	elseif criteria.approval_type == "decision_point" then
		approval_request.question = criteria.question
		approval_request.options = criteria.options
	elseif criteria.approval_type == "batch_action" then
		approval_request.actions = criteria.actions or {}
		approval_request.description = criteria.description or "Batch action"
	end
	
	return approval_request
end

-- Handle MCP roots requests from external agents
function M.handle_roots_request(request)
	local uri = request.uri
	local options = request.options or {}

	local roots = M.define_resource_roots(uri, options)

	return {
		id = request.id,
		result = {
			roots = roots,
			metadata = {
				uri = uri,
				options = options,
				root_count = #roots,
				timestamp = os.time(),
			},
		},
	}
end

-- Register a cancellable operation
function M.register_cancellable_operation(operation_type, description)
	local operation_id = "op-" .. M.cancellation_state.next_operation_id
	M.cancellation_state.next_operation_id = M.cancellation_state.next_operation_id + 1

	M.cancellation_state.active_operations[operation_id] = {
		type = operation_type,
		description = description,
		start_time = os.time(),
		cancelled = false,
	}

	return operation_id
end

-- Check if operation is cancelled
function M.is_operation_cancelled(operation_id)
	local operation = M.cancellation_state.active_operations[operation_id]
	return operation and operation.cancelled
end

-- Cancel an operation
function M.cancel_operation(operation_id)
	local operation = M.cancellation_state.active_operations[operation_id]
	if operation then
		operation.cancelled = true
		operation.cancel_time = os.time()
		return true
	end
	return false
end

-- Complete an operation (remove from active list)
function M.complete_operation(operation_id)
	M.cancellation_state.active_operations[operation_id] = nil
end

-- Enhanced tool call with cancellation support
function M.handle_tool_call_with_cancellation(id, params)
	local tool_name = params.name
	local arguments = params.arguments or {}

	if not tool_name then
		return {
			id = id,
			error = {
				code = -32602,
				message = "Tool name is required",
			},
		}
	end

	-- Register operation for cancellation
	local operation_id = M.register_cancellable_operation("tool_call", "Tool: " .. tool_name)

	if tool_name == "agent_edit_file" then
		local file_path = arguments.file_path
		local line_number = arguments.line_number or 1
		local content = arguments.content or ""

		if not file_path then
			M.complete_operation(operation_id)
			return {
				id = id,
				error = {
					code = -32602,
					message = "file_path is required for agent_edit_file",
				},
			}
		end

		-- Check for cancellation before starting
		if M.is_operation_cancelled(operation_id) then
			M.complete_operation(operation_id)
			return {
				id = id,
				error = {
					code = -32800,
					message = "Operation cancelled before start",
				},
			}
		end

		-- Find buffer by file path
		local target_buf = nil
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			-- Check for cancellation during search
			if M.is_operation_cancelled(operation_id) then
				M.complete_operation(operation_id)
				return {
					id = id,
					error = {
						code = -32800,
						message = "Operation cancelled during file search",
					},
				}
			end

			local buf_name = vim.api.nvim_buf_get_name(buf)
			if buf_name == file_path then
				target_buf = buf
				break
			end
		end

		if not target_buf then
			M.complete_operation(operation_id)
			return {
				id = id,
				error = {
					code = -32602,
					message = "File not found in session: " .. file_path,
				},
			}
		end

		-- Check for cancellation before edit
		if M.is_operation_cancelled(operation_id) then
			M.complete_operation(operation_id)
			return {
				id = id,
				error = {
					code = -32800,
					message = "Operation cancelled before edit",
				},
			}
		end

		-- Perform the edit
		vim.api.nvim_set_current_buf(target_buf)

		-- Split content into lines to handle newlines properly
		local lines = {}
		for line in content:gmatch("[^\r\n]+") do
			table.insert(lines, line)
		end
		vim.api.nvim_buf_set_lines(target_buf, line_number - 1, line_number, false, lines)

		M.complete_operation(operation_id)
		return {
			id = id,
			result = {
				content = {
					{
						type = "text",
						text = "Successfully edited file: " .. file_path .. " at line " .. line_number,
					},
				},
				metadata = {
					file_path = file_path,
					line_number = line_number,
					content_length = #content,
					timestamp = os.time(),
					operation_id = operation_id,
				},
			},
		}
	else
		M.complete_operation(operation_id)
		return {
			id = id,
			error = {
				code = -32601,
				message = "Tool not found: " .. tool_name,
			},
		}
	end
end

-- Handle MCP cancellation messages
function M.handle_cancellation_message(message)
	if message.method == "cancel" then
		local operation_id = message.params.operation_id
		if operation_id then
			local cancelled = M.cancel_operation(operation_id)
			if cancelled then
				return {
					id = message.id,
					result = {
						cancelled = true,
						message = "Operation cancelled successfully",
					},
				}
			else
				return {
					id = message.id,
					error = {
						code = -32602,
						message = "Operation not found: " .. operation_id,
					},
				}
			end
		else
			return {
				id = message.id,
				error = {
					code = -32602,
					message = "Operation ID is required for cancellation",
				},
			}
		end
	elseif message.method == "cancel/list" then
		local active_operations = {}
		for op_id, op in pairs(M.cancellation_state.active_operations) do
			table.insert(active_operations, {
				operation_id = op_id,
				type = op.type,
				description = op.description,
				start_time = op.start_time,
				cancelled = op.cancelled,
			})
		end
		return {
			id = message.id,
			result = {
				operations = active_operations,
			},
		}
	else
		return {
			id = message.id,
			error = {
				code = -32601,
				message = "Unknown cancellation method: " .. tostring(message.method),
			},
		}
	end
end

-- Handle MCP message
function M.handle_mcp_message(message)
	if message.method == "sampling/request" then
		return M.handle_sampling_request(message)
	elseif message.method == "roots/list" then
		return M.handle_roots_request(message)
	elseif message.method == "cancel" or message.method == "cancel/list" then
		return M.handle_cancellation_message(message)
	end

	return { error = { code = -32601, message = "Unknown MCP method: " .. tostring(message.method) } }
end

-- Display MCP resources
function M.display_mcp_resources(resources)
	-- Create buffer for resources
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "modifiable", true)

	-- Format resources
	local lines = {
		"# MCP Resources",
		"",
		"Available resources:",
		"",
	}

	for _, resource in ipairs(resources) do
		table.insert(lines, "## " .. resource.name)
		table.insert(lines, "**URI:** " .. resource.uri)
		table.insert(lines, "**Description:** " .. resource.description)
		table.insert(lines, "**MIME Type:** " .. resource.mimeType)
		table.insert(lines, "")
	end

	-- Set buffer content
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- Open buffer in split
	vim.api.nvim_command("split")
	vim.api.nvim_set_current_buf(buf)

	-- Set buffer options
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

-- Display MCP tools
function M.display_mcp_tools(tools)
	-- Create buffer for tools
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "modifiable", true)

	-- Format tools
	local lines = {
		"# MCP Tools",
		"",
		"Available tools:",
		"",
	}

	for _, tool in ipairs(tools) do
		table.insert(lines, "## " .. tool.name)
		table.insert(lines, "**Description:** " .. tool.description)
		if tool.inputSchema then
			table.insert(lines, "**Input Schema:** " .. vim.inspect(tool.inputSchema))
		end
		table.insert(lines, "")
	end

	-- Set buffer content
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- Open buffer in split
	vim.api.nvim_command("split")
	vim.api.nvim_set_current_buf(buf)

	-- Set buffer options
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

-- Display resource content
function M.display_resource_content(uri, result)
	-- Create buffer for resource content
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "modifiable", true)

	-- Format content
	local lines = {
		"# Resource Content: " .. uri,
		"",
		"Content:",
		"",
	}

	if type(result) == "table" then
		table.insert(lines, vim.inspect(result))
	else
		table.insert(lines, tostring(result))
	end

	-- Set buffer content
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- Open buffer in split
	vim.api.nvim_command("split")
	vim.api.nvim_set_current_buf(buf)

	-- Set buffer options
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

-- Display sampled content
function M.display_sampled_content(uri, result, criteria)
	-- Create buffer for sampled content
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "modifiable", true)

	-- Format content
	local lines = {
		"# Sampled Resource: " .. uri,
		"",
		"Criteria:",
		vim.inspect(criteria),
		"",
		"Sampled Content:",
		"",
	}

	if type(result) == "table" then
		table.insert(lines, vim.inspect(result))
	else
		table.insert(lines, tostring(result))
	end

	-- Set buffer content
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- Open buffer in split
	vim.api.nvim_command("split")
	vim.api.nvim_set_current_buf(buf)

	-- Set buffer options
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

-- Display resource roots
function M.display_resource_roots(uri, roots)
	-- Create buffer for resource roots
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "modifiable", true)

	-- Format roots
	local lines = {
		"# Resource Roots: " .. uri,
		"",
		"Roots:",
		"",
	}

	for _, root in ipairs(roots) do
		table.insert(lines, "## " .. root.name)
		table.insert(lines, "**URI:** " .. root.uri)
		table.insert(lines, "**Description:** " .. root.description)
		table.insert(lines, "")
	end

	-- Set buffer content
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- Open buffer in split
	vim.api.nvim_command("split")
	vim.api.nvim_set_current_buf(buf)

	-- Set buffer options
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

-- Get pattern-aware tool recommendations
function M.get_pattern_aware_tool_recommendations(pattern_context)
	if not M.mcp_server_initialized then
		M.initialize_mcp_server()
	end

	local recommendations = {}
	local tools = M.list_mcp_tools()

	for _, tool in ipairs(tools) do
		if tool.patterns then
			for _, pattern in ipairs(tool.patterns) do
				-- Enhanced pattern matching based on context
				local pattern_lower = string.lower(pattern.pattern_id)
				local desc_lower = string.lower(pattern.description)
				local context_lower = string.lower(pattern_context)

				-- Check for direct matches or semantic matches
				if
					string.find(pattern_lower, context_lower)
					or string.find(desc_lower, context_lower)
					or string.find(context_lower, "file") and string.find(desc_lower, "file")
					or string.find(context_lower, "edit") and string.find(desc_lower, "edit")
				then
					table.insert(recommendations, {
						tool_name = tool.name,
						confidence = 0.8,
						reason = "Pattern match: " .. pattern.pattern_id,
						pattern_id = pattern.pattern_id,
						relationship_type = pattern.relationship_type,
					})
				end
			end
		end
	end

	-- Sort by confidence (highest first)
	table.sort(recommendations, function(a, b)
		return a.confidence > b.confidence
	end)

	return recommendations
end

-- Track tool usage with pattern context
function M.track_tool_usage(tool_name, pattern_id, success)
	if not M.mcp_server_initialized then
		M.initialize_mcp_server()
	end

	-- Find the tool
	for _, tool in ipairs(M.mcp_tools) do
		if tool.name == tool_name then
			-- Update usage count
			tool.success_metrics.usage_count = tool.success_metrics.usage_count + 1

			-- Update last used timestamp
			tool.success_metrics.last_used = os.time()

			-- Update success rate (simple moving average)
			local current_rate = tool.success_metrics.success_rate
			local new_rate = success and 1.0 or 0.0
			tool.success_metrics.success_rate = (current_rate * 0.9) + (new_rate * 0.1)

			return true
		end
	end

	return false
end

-- ============================================================================
-- Approval State Management Functions
-- ============================================================================

-- Initialize approval state management
function M.initialize_approval_state()
	if not M.approval_state then
		M.approval_state = {
			active_requests = {},
			audit_trail = {},
			next_audit_id = 1,
			cleanup_timer = nil,
		}
	end
	
	-- Start cleanup timer if not already running
	if not M.approval_state.cleanup_timer then
		M.start_approval_cleanup_timer()
	end
	
	return true
end

-- Register an approval request
function M.register_approval_request(request)
	if not M.approval_state then
		M.initialize_approval_state()
	end
	
	-- Validate request
	if not request or not request.id then
		return false, "Invalid request: missing ID"
	end
	
	-- Check for duplicate
	if M.approval_state.active_requests[request.id] then
		return false, "Request already registered: " .. request.id
	end
	
	-- Add to active requests
	M.approval_state.active_requests[request.id] = {
		request = request,
		status = "pending",
		created_at = os.time(),
		updated_at = os.time(),
	}
	
	return true
end

-- Get an approval request by ID
function M.get_approval_request(request_id)
	if not M.approval_state or not M.approval_state.active_requests then
		return nil
	end
	
	local entry = M.approval_state.active_requests[request_id]
	if not entry then
		return nil
	end
	
	-- Check for timeout (only if status is still pending)
	if entry.status == "pending" and entry.request.timeout and (os.time() - entry.created_at) > entry.request.timeout then
		entry.status = "timeout"
		entry.updated_at = os.time()
		M.record_audit_entry(request_id, "timeout", {reason = "automatic timeout"})
	end
	
	-- Return the request data with status information
	return {
		id = entry.request.id,
		status = entry.status,
		created_at = entry.created_at,
		updated_at = entry.updated_at,
		result = entry.result,
		request = entry.request
	}
end

-- Approve a request
function M.approve_request(request_id, result)
	if not M.approval_state or not M.approval_state.active_requests then
		return false, "Approval state not initialized"
	end
	
	local entry = M.approval_state.active_requests[request_id]
	if not entry then
		return false, "Request not found: " .. request_id
	end
	
	if entry.status ~= "pending" then
		return false, "Request not in pending status: " .. entry.status
	end
	
	-- Update status
	entry.status = "approved"
	entry.updated_at = os.time()
	entry.result = result or {approved = true}
	
	-- Record audit entry
	M.record_audit_entry(request_id, "approved", result)
	
	return true
end

-- Deny a request
function M.deny_request(request_id, result)
	if not M.approval_state or not M.approval_state.active_requests then
		return false, "Approval state not initialized"
	end
	
	local entry = M.approval_state.active_requests[request_id]
	if not entry then
		return false, "Request not found: " .. request_id
	end
	
	if entry.status ~= "pending" then
		return false, "Request not in pending status: " .. entry.status
	end
	
	-- Update status
	entry.status = "denied"
	entry.updated_at = os.time()
	entry.result = result or {approved = false}
	
	-- Record audit entry
	M.record_audit_entry(request_id, "denied", result)
	
	return true
end

-- Record audit entry
function M.record_audit_entry(request_id, action, details)
	if not M.approval_state then
		return false
	end
	
	local audit_entry = {
		id = M.approval_state.next_audit_id,
		request_id = request_id,
		action = action,
		timestamp = os.time(),
		details = details or {},
	}
	
	M.approval_state.audit_trail[audit_entry.id] = audit_entry
	M.approval_state.next_audit_id = M.approval_state.next_audit_id + 1
	
	return true
end

-- Get audit entry
function M.get_audit_entry(request_id)
	if not M.approval_state or not M.approval_state.audit_trail then
		return nil
	end
	
	-- Find the most recent audit entry for this request
	local latest_entry = nil
	for _, entry in pairs(M.approval_state.audit_trail) do
		if entry.request_id == request_id then
			if not latest_entry or entry.timestamp > latest_entry.timestamp then
				latest_entry = entry
			end
		end
	end
	
	return latest_entry
end

-- Get pending approval count
function M.get_pending_approval_count()
	if not M.approval_state or not M.approval_state.active_requests then
		return 0
	end
	
	local count = 0
	for _, entry in pairs(M.approval_state.active_requests) do
		if entry.status == "pending" then
			count = count + 1
		end
	end
	
	return count
end

-- Clean up completed approvals
function M.cleanup_completed_approvals()
	if not M.approval_state or not M.approval_state.active_requests then
		return 0
	end
	
	local cleaned = 0
	local to_remove = {}
	
	for request_id, entry in pairs(M.approval_state.active_requests) do
		if entry.status ~= "pending" then
			table.insert(to_remove, request_id)
		end
	end
	
	for _, request_id in ipairs(to_remove) do
		M.approval_state.active_requests[request_id] = nil
		cleaned = cleaned + 1
	end
	
	return cleaned
end

-- Start approval cleanup timer
function M.start_approval_cleanup_timer()
	if M.approval_state.cleanup_timer then
		return -- Already running
	end
	
	-- Simple timer implementation (in a real environment, use vim.loop.timer)
	M.approval_state.cleanup_timer = true
	
	-- For testing purposes, we'll handle cleanup manually
	-- In production, this would be a proper timer
end

-- Save approval state
function M.save_approval_state()
	if not M.approval_state then
		return false
	end
	
	-- Store state in a temporary variable for testing
	M._saved_state = {
		active_requests = {},
		audit_trail = {},
		next_audit_id = M.approval_state.next_audit_id
	}
	
	-- Copy active requests
	for id, entry in pairs(M.approval_state.active_requests) do
		M._saved_state.active_requests[id] = entry
	end
	
	-- Copy audit trail
	for id, entry in pairs(M.approval_state.audit_trail) do
		M._saved_state.audit_trail[id] = entry
	end
	
	return true
end

-- Load approval state
function M.load_approval_state()
	if not M.approval_state then
		M.initialize_approval_state()
	end
	
	if not M._saved_state then
		return false
	end
	
	-- Restore state from saved data
	M.approval_state.active_requests = {}
	M.approval_state.audit_trail = {}
	M.approval_state.next_audit_id = M._saved_state.next_audit_id
	
	-- Restore active requests
	for id, entry in pairs(M._saved_state.active_requests) do
		M.approval_state.active_requests[id] = entry
	end
	
	-- Restore audit trail
	for id, entry in pairs(M._saved_state.audit_trail) do
		M.approval_state.audit_trail[id] = entry
	end
	
	return true
end

-- Clear approval state
function M.clear_approval_state()
	if M.approval_state then
		M.approval_state.active_requests = {}
		M.approval_state.audit_trail = {}
		M.approval_state.next_audit_id = 1
	end
end

-- ============================================================================
-- Approval UI Integration Functions
-- ============================================================================

-- Create approval dialog
function M.create_approval_dialog(request_id)
	local ui = require("paragonic.mcp_approval_ui")
	return ui.create_approval_dialog(request_id)
end

-- Display approval dialog
function M.display_approval_dialog(dialog)
	local ui = require("paragonic.mcp_approval_ui")
	return ui.display_approval_dialog(dialog)
end

-- Handle user approval
function M.handle_user_approval(dialog, result)
	local ui = require("paragonic.mcp_approval_ui")
	return ui.handle_user_approval(dialog, result)
end

-- Handle user denial
function M.handle_user_denial(dialog, result)
	local ui = require("paragonic.mcp_approval_ui")
	return ui.handle_user_denial(dialog, result)
end

-- Close approval dialog
function M.close_approval_dialog(dialog)
	local ui = require("paragonic.mcp_approval_ui")
	return ui.close_approval_dialog(dialog)
end

-- Check if dialog is open
function M.is_dialog_open(dialog)
	local ui = require("paragonic.mcp_approval_ui")
	return ui.is_dialog_open(dialog)
end

-- Get dialog state
function M.get_dialog_state(dialog)
	local ui = require("paragonic.mcp_approval_ui")
	return ui.get_dialog_state(dialog)
end

-- Create decision point dialog
function M.create_decision_point_dialog(request_id)
	local ui = require("paragonic.mcp_approval_ui")
	return ui.create_decision_point_dialog(request_id)
end

-- Handle option selection
function M.handle_option_selection(dialog, option_index)
	local ui = require("paragonic.mcp_approval_ui")
	return ui.handle_option_selection(dialog, option_index)
end

-- Create batch action dialog
function M.create_batch_action_dialog(request_id)
	local ui = require("paragonic.mcp_approval_ui")
	return ui.create_batch_action_dialog(request_id)
end

-- Handle partial approval
function M.handle_partial_approval(dialog, approved_indices)
	local ui = require("paragonic.mcp_approval_ui")
	return ui.handle_partial_approval(dialog, approved_indices)
end

return M
