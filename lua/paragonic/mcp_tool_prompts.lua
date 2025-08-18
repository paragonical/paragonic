--[[
Paragonic MCP Tool Prompts Module
Handles dynamic construction of tool awareness prompts for AI models
--]]

local M = {}

-- Import required modules
local debug = require("paragonic.debug")
local config = require("paragonic.config")

-- Tool prompt templates
M.prompt_templates = {
	base_tool_awareness = [[
You are an AI assistant with direct access to Neovim through MCP tools.
Available tools: {tool_list}
Use these tools when appropriate instead of suggesting manual actions.
    ]],

	contextual_tools = [[
For this request, consider using: {relevant_tools}
{usage_guidance}
    ]],

	pattern_aware = [[
Current pattern context: {pattern_context}
Recommended tools for this pattern: {pattern_tools}
    ]],
}

-- Tool categorization
M.tool_categories = {
	file_operations = { "agent_edit_file", "agent_create_file", "agent_save_file" },
	session_management = { "agent_session_info" },
	pattern_execution = { "pattern_execute", "pattern_status" },
	search_navigation = { "agent_search_files", "file_search", "buffer_navigate" },
	command_execution = { "agent_execute_command" },
}

-- Intent detection patterns
M.intent_patterns = {
	file_editing = { "edit", "modify", "change", "update", "fix", "replace", "insert", "delete" },
	file_creation = { "create", "new", "add", "make", "generate", "write" },
	file_saving = { "save", "persist", "write", "store" },
	session_management = { "session", "buffer", "window", "tab", "info", "context" },
	pattern_execution = { "pattern", "execute", "run", "apply" },
	search_operations = { "search", "find", "locate", "grep", "look" },
	command_execution = { "command", "run", "execute", "call", "invoke" },
}

-- Configuration
M.config = {
	enabled = true,
	prompt_style = "contextual", -- "base", "contextual", "minimal"
	include_pattern_context = true,
	include_usage_guidance = true,
	max_tools_per_prompt = 5,
	intent_detection_threshold = 0.7,
	cache_size = 100,
}

-- Cache for constructed prompts
M.prompt_cache = {}
M.cache_hits = 0
M.cache_misses = 0

-- Initialize the module
function M.init()
	debug.debug_print("🔧 Initializing MCP Tool Prompts module", "info")

	-- Load configuration from config module
	local user_config = config.get_mcp_tool_prompts_config()
	if user_config and type(user_config) == "table" then
		for key, value in pairs(user_config) do
			M.config[key] = value
		end
	end

	debug.debug_print("✅ MCP Tool Prompts module initialized", "success")
	return true
end

-- Get available tools from MCP module
function M.get_available_tools()
	local mcp = require("paragonic.mcp")
	if not mcp then
		debug.debug_print("❌ MCP module not available", "error")
		return {}
	end

	local tools = mcp.list_mcp_tools()
	if not tools then
		debug.debug_print("❌ Failed to get MCP tools", "error")
		return {}
	end

	debug.debug_print("📋 Retrieved " .. #tools .. " MCP tools", "debug")
	return tools
end

-- Categorize tools by function
function M.categorize_tools(tools)
	local categorized = {}

	for _, tool in ipairs(tools) do
		local category = M.get_tool_category(tool.name)
		if not categorized[category] then
			categorized[category] = {}
		end
		table.insert(categorized[category], tool)
	end

	debug.debug_print(
		"📂 Categorized " .. #tools .. " tools into " .. M.count_table_keys(categorized) .. " categories",
		"debug"
	)
	return categorized
end

-- Get category for a specific tool
function M.get_tool_category(tool_name)
	for category, tools in pairs(M.tool_categories) do
		for _, tool in ipairs(tools) do
			if tool == tool_name then
				return category
			end
		end
	end
	return "other"
end

-- Detect user intent from message content
function M.detect_user_intent(message)
	if not message or type(message) ~= "string" then
		return {}
	end

	local message_lower = string.lower(message)
	local detected_intents = {}

	for intent, patterns in pairs(M.intent_patterns) do
		local score = 0
		for _, pattern in ipairs(patterns) do
			if string.find(message_lower, pattern) then
				score = score + 1
			end
		end

		if score > 0 then
			detected_intents[intent] = score / #patterns
		end
	end

	-- Filter by threshold
	local filtered_intents = {}
	for intent, score in pairs(detected_intents) do
		if score >= M.config.intent_detection_threshold then
			filtered_intents[intent] = score
		end
	end

	debug.debug_print("🎯 Detected intents: " .. M.table_to_string(filtered_intents), "debug")
	return filtered_intents
end

-- Extract conversation context
function M.extract_conversation_context()
	local context = {
		current_buffer = vim.fn.expand("%"),
		current_directory = vim.fn.getcwd(),
		buffer_count = #vim.api.nvim_list_bufs(),
		mode = vim.fn.mode(),
		timestamp = os.time(),
	}

	debug.debug_print("📊 Extracted conversation context", "debug")
	return context
end

-- Get active patterns
function M.get_active_patterns()
	local patterns = {}

	-- Try to get active patterns from AI agent session
	local success, ai_agent = pcall(require, "paragonic.ai_agent")
	if success and ai_agent then
		-- Check if there's an active AI agent session
		local session = ai_agent.get_active_session()
		if session and session.interactions then
			-- Look for pattern executions in session interactions
			for _, interaction in ipairs(session.interactions) do
				if interaction.type == "pattern_execution" and interaction.status == "completed" then
					table.insert(patterns, {
						id = interaction.content,
						name = interaction.content,
						status = "active",
						executed_at = interaction.timestamp,
						result = interaction.result,
					})
				end
			end

			-- Check for recently triggered patterns
			local triggered_patterns = ai_agent.check_and_trigger_patterns()
			if triggered_patterns and type(triggered_patterns) == "table" then
				for _, pattern in ipairs(triggered_patterns) do
					table.insert(patterns, {
						id = pattern.name,
						name = pattern.name,
						status = "triggered",
						triggered_at = os.time(),
					})
				end
			end
		end
	end

	-- Also check for patterns from patterns module
	local patterns_module = require("paragonic.patterns")
	if patterns_module then
		local all_patterns = patterns_module.list_patterns()
		-- For now, consider all available patterns as potentially active
		-- In the future, this could be enhanced with pattern state tracking
		for _, pattern in ipairs(all_patterns) do
			local is_active = M.is_pattern_active(pattern.id)
			if is_active then
				table.insert(patterns, {
					id = pattern.id,
					name = pattern.name,
					category = pattern.category,
					description = pattern.description,
					status = "available",
				})
			end
		end
	end

	if #patterns > 0 then
		debug.debug_print("🔄 Found " .. #patterns .. " active patterns", "debug")
	else
		debug.debug_print("🔄 No active patterns detected", "debug")
	end

	return patterns
end

-- Check if a pattern is currently active
function M.is_pattern_active(pattern_id)
	-- Check session context for pattern activity
	local success, ai_agent = pcall(require, "paragonic.ai_agent")
	if success and ai_agent then
		local session = ai_agent.get_active_session()
		if session then
			-- Check session duration and interaction count for pattern triggers
			local session_duration = os.time() - session.start_time
			local interaction_count = #session.interactions

			-- Pattern-specific activation logic
			if pattern_id == "session_summary_generation" and session_duration > 300 then
				return true
			elseif pattern_id == "activity_labeling" and interaction_count > 2 then
				return true
			elseif pattern_id == "self_reflection" and interaction_count > 5 then
				return true
			elseif pattern_id == "context_summarization" and interaction_count > 1 then
				return true
			elseif pattern_id == "progress_tracking" and interaction_count > 3 then
				return true
			elseif pattern_id == "knowledge_extraction" and interaction_count > 2 then
				return true
			end
		end
	end

	return false
end

-- Get buffer context
function M.get_buffer_context()
	local buffer = vim.api.nvim_get_current_buf()
	local context = {
		buffer_id = buffer,
		file_name = vim.fn.expand("%"),
		file_type = vim.api.nvim_buf_get_option(buffer, "filetype"),
		line_count = vim.api.nvim_buf_line_count(buffer),
		modified = vim.api.nvim_buf_get_option(buffer, "modified"),
	}

	debug.debug_print("📄 Extracted buffer context for " .. context.file_name, "debug")
	return context
end

-- Get relevant tools based on intent and context
function M.get_relevant_tools(intent, context)
	local all_tools = M.get_available_tools()
	local relevant_tools = {}

	for _, tool in ipairs(all_tools) do
		local relevance_score = M.calculate_tool_relevance(tool, intent, context)
		if relevance_score > 0 then
			table.insert(relevant_tools, {
				tool = tool,
				relevance = relevance_score,
			})
		end
	end

	-- Sort by relevance and limit
	table.sort(relevant_tools, function(a, b)
		return a.relevance > b.relevance
	end)

	local limited_tools = {}
	for i = 1, math.min(#relevant_tools, M.config.max_tools_per_prompt) do
		table.insert(limited_tools, relevant_tools[i].tool)
	end

	debug.debug_print("🎯 Selected " .. #limited_tools .. " relevant tools", "debug")
	return limited_tools
end

-- Calculate tool relevance score
function M.calculate_tool_relevance(tool, intent, context)
	local score = 0

	-- Intent-based scoring
	for intent_name, intent_score in pairs(intent) do
		local category = M.get_tool_category(tool.name)
		if M.intent_matches_category(intent_name, category) then
			score = score + intent_score
		end
	end

	-- Context-based scoring
	if context and context.current_buffer and tool.name:find("file") then
		score = score + 0.5
	end

	-- Pattern-based scoring
	local active_patterns = M.get_active_patterns()
	for _, pattern in ipairs(active_patterns) do
		local pattern_score = M.calculate_pattern_tool_relevance(tool, pattern)
		score = score + pattern_score
	end

	return score
end

-- Calculate tool relevance for a specific pattern
function M.calculate_pattern_tool_relevance(tool, pattern)
	local score = 0

	-- Pattern-specific tool relevance mapping
	local pattern_tool_relevance = {
		session_summary_generation = {
			agent_edit_file = 0.8,
			agent_create_file = 0.9,
			agent_save_file = 0.7,
			agent_session_info = 0.6,
		},
		activity_labeling = {
			agent_edit_file = 0.6,
			agent_create_file = 0.5,
			agent_save_file = 0.4,
			agent_session_info = 0.8,
			agent_execute_command = 0.7,
		},
		self_reflection = {
			agent_session_info = 0.9,
			agent_edit_file = 0.4,
			agent_create_file = 0.3,
		},
		context_summarization = {
			agent_session_info = 0.8,
			agent_edit_file = 0.5,
			agent_create_file = 0.4,
			agent_search_files = 0.8,
		},
		progress_tracking = {
			agent_session_info = 0.9,
			agent_edit_file = 0.6,
			agent_create_file = 0.5,
			agent_execute_command = 0.7,
		},
		knowledge_extraction = {
			agent_create_file = 0.9,
			agent_edit_file = 0.7,
			agent_save_file = 0.6,
			agent_search_files = 0.8,
		},
	}

	local pattern_id = pattern.id:gsub(" ", "_"):lower()
	local tool_relevance = pattern_tool_relevance[pattern_id]

	if tool_relevance and tool_relevance[tool.name] then
		score = tool_relevance[tool.name]

		-- Adjust score based on pattern status
		if pattern.status == "active" then
			score = score * 1.2 -- Boost for active patterns
		elseif pattern.status == "triggered" then
			score = score * 1.1 -- Slight boost for triggered patterns
		end
	end

	return score
end

-- Check if intent matches tool category
function M.intent_matches_category(intent, category)
	local intent_category_map = {
		file_editing = "file_operations",
		file_creation = "file_operations",
		file_saving = "file_operations",
		session_management = "session_management",
		pattern_execution = "pattern_execution",
		search_operations = "search_navigation",
		command_execution = "command_execution",
	}

	return intent_category_map[intent] == category
end

-- Get tool usage guidance
function M.get_tool_usage_guidance(tools, intent)
	local guidance = {}

	for _, tool in ipairs(tools) do
		local tool_guidance = M.get_specific_tool_guidance(tool, intent)
		if tool_guidance then
			table.insert(guidance, tool_guidance)
		end
	end

	return table.concat(guidance, "\n")
end

-- Get specific guidance for a tool
function M.get_specific_tool_guidance(tool, intent)
	local guidance_templates = {
		agent_edit_file = "Use agent_edit_file to directly modify files. Specify file_path and line_number, provide content to insert/replace.",
		agent_create_file = "Use agent_create_file to create new files. Specify file_name and optional initial content.",
		agent_save_file = "Use agent_save_file to persist changes. Specify file_path or save current buffer.",
		agent_session_info = "Use agent_session_info to get current session information and context.",
		agent_search_files = "Use agent_search_files to search for files by name or content. Specify query and optionally file_type filter.",
		agent_execute_command = "Use agent_execute_command to run Neovim or shell commands. Specify command and command_type (neovim/shell).",
	}

	return guidance_templates[tool.name]
end

-- Get pattern context
function M.get_pattern_context(context)
	local patterns = M.get_active_patterns()
	if #patterns == 0 then
		return "No active patterns"
	end

	local pattern_contexts = {}
	for _, pattern in ipairs(patterns) do
		local pattern_info = pattern.name or pattern
		if pattern.status then
			pattern_info = pattern_info .. " (" .. pattern.status .. ")"
		end
		if pattern.description then
			pattern_info = pattern_info .. ": " .. pattern.description
		end
		table.insert(pattern_contexts, pattern_info)
	end

	return "Active patterns: " .. table.concat(pattern_contexts, "; ")
end

-- Build tool awareness prompt
function M.build_tool_awareness_prompt(user_message, context)
	if not M.config.enabled then
		return ""
	end

	-- Check cache first
	local cache_key = M.generate_cache_key(user_message, context)
	if M.prompt_cache[cache_key] then
		M.cache_hits = M.cache_hits + 1
		debug.debug_print("💾 Using cached prompt", "debug")
		return M.prompt_cache[cache_key]
	end

	M.cache_misses = M.cache_misses + 1

	-- Build prompt
	local intent = M.detect_user_intent(user_message)
	local relevant_tools = M.get_relevant_tools(intent, context)
	local pattern_context = M.get_pattern_context(context)

	local prompt = M.construct_prompt(intent, relevant_tools, pattern_context)

	-- Cache the result
	M.cache_prompt(cache_key, prompt)

	debug.debug_print("🔨 Built tool awareness prompt (" .. #prompt .. " chars)", "debug")
	return prompt
end

-- Construct the final prompt
function M.construct_prompt(intent, relevant_tools, pattern_context)
	local prompt_parts = {}

	-- Base tool awareness
	if M.config.prompt_style == "base" or M.config.prompt_style == "contextual" then
		local all_tools = M.get_available_tools()
		local tool_list = M.format_tool_list(all_tools)
		local base_prompt = M.prompt_templates.base_tool_awareness:gsub("{tool_list}", tool_list)
		table.insert(prompt_parts, base_prompt)
	end

	-- Contextual tools
	if M.config.prompt_style == "contextual" and #relevant_tools > 0 then
		local tool_list = M.format_tool_list(relevant_tools)
		local usage_guidance = M.get_tool_usage_guidance(relevant_tools, intent)
		local contextual_prompt = M.prompt_templates.contextual_tools
			:gsub("{relevant_tools}", tool_list)
			:gsub("{usage_guidance}", usage_guidance)
		table.insert(prompt_parts, contextual_prompt)
	end

	-- Pattern context
	if M.config.include_pattern_context and pattern_context and pattern_context ~= "No active patterns" then
		local pattern_tools_info = M.format_pattern_tools_info()
		local pattern_prompt = M.prompt_templates.pattern_aware
			:gsub("{pattern_context}", pattern_context)
			:gsub("{pattern_tools}", pattern_tools_info)
		table.insert(prompt_parts, pattern_prompt)
	end

	return table.concat(prompt_parts, "\n\n")
end

-- Format tool list for prompt
function M.format_tool_list(tools)
	local tool_descriptions = {}

	for _, tool in ipairs(tools) do
		local description = tool.name
		if tool.description then
			description = description .. ": " .. tool.description
		end
		table.insert(tool_descriptions, "- " .. description)
	end

	return table.concat(tool_descriptions, "\n")
end

-- Get tools for current patterns
function M.get_pattern_tools()
	local patterns = M.get_active_patterns()
	local pattern_tools = {}

	for _, pattern in ipairs(patterns) do
		local tools_for_pattern = M.get_tools_for_pattern(pattern.id)
		if tools_for_pattern and #tools_for_pattern > 0 then
			table.insert(pattern_tools, {
				pattern = pattern.name,
				tools = tools_for_pattern,
				status = pattern.status,
			})
		end
	end

	return pattern_tools
end

-- Format pattern tools information for prompt
function M.format_pattern_tools_info()
	local pattern_tools = M.get_pattern_tools()
	if #pattern_tools == 0 then
		return "No pattern-specific tools available"
	end

	local formatted_info = {}
	for _, pattern_tool in ipairs(pattern_tools) do
		local tool_names = {}
		for _, tool in ipairs(pattern_tool.tools) do
			table.insert(tool_names, tool.name)
		end

		local pattern_info = pattern_tool.pattern .. ": " .. table.concat(tool_names, ", ")
		if pattern_tool.status then
			pattern_info = pattern_info .. " (" .. pattern_tool.status .. ")"
		end
		table.insert(formatted_info, pattern_info)
	end

	return table.concat(formatted_info, "; ")
end

-- Get tools specific to a pattern
function M.get_tools_for_pattern(pattern_id)
	local pattern_id_normalized = pattern_id:gsub(" ", "_"):lower()
	local all_tools = M.get_available_tools()
	local relevant_tools = {}

	-- Pattern-specific tool mappings
	local pattern_tool_mappings = {
		session_summary_generation = {
			"agent_edit_file",
			"agent_create_file",
			"agent_save_file",
			"agent_session_info",
		},
		activity_labeling = {
			"agent_edit_file",
			"agent_create_file",
			"agent_session_info",
			"agent_execute_command",
		},
		self_reflection = {
			"agent_session_info",
			"agent_edit_file",
		},
		context_summarization = {
			"agent_session_info",
			"agent_edit_file",
			"agent_create_file",
			"agent_search_files",
		},
		progress_tracking = {
			"agent_session_info",
			"agent_edit_file",
			"agent_create_file",
			"agent_execute_command",
		},
		knowledge_extraction = {
			"agent_create_file",
			"agent_edit_file",
			"agent_save_file",
			"agent_search_files",
		},
	}

	local tool_names = pattern_tool_mappings[pattern_id_normalized]
	if tool_names then
		for _, tool_name in ipairs(tool_names) do
			for _, tool in ipairs(all_tools) do
				if tool.name == tool_name then
					table.insert(relevant_tools, tool)
					break
				end
			end
		end
	end

	return relevant_tools
end

-- Generate cache key
function M.generate_cache_key(user_message, context)
	local key_parts = {
		user_message:sub(1, 100), -- First 100 chars
		context.current_buffer or "",
		context.current_directory or "",
		M.config.prompt_style,
	}

	return table.concat(key_parts, "|")
end

-- Cache prompt
function M.cache_prompt(key, prompt)
	-- Implement LRU cache
	if #M.prompt_cache >= M.config.cache_size then
		-- Remove oldest entry (simple implementation)
		local oldest_key = nil
		for k, _ in pairs(M.prompt_cache) do
			oldest_key = k
			break
		end
		if oldest_key then
			M.prompt_cache[oldest_key] = nil
		end
	end

	M.prompt_cache[key] = prompt
end

-- Get cache statistics
function M.get_cache_stats()
	return {
		hits = M.cache_hits,
		misses = M.cache_misses,
		size = M.count_table_keys(M.prompt_cache),
		max_size = M.config.cache_size,
	}
end

-- Clear cache
function M.clear_cache()
	M.prompt_cache = {}
	M.cache_hits = 0
	M.cache_misses = 0
	debug.debug_print("🗑️ Cleared prompt cache", "info")
end

-- Utility functions
function M.count_table_keys(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

function M.table_to_string(t)
	local parts = {}
	for k, v in pairs(t) do
		table.insert(parts, k .. ":" .. tostring(v))
	end
	return table.concat(parts, ", ")
end

-- Module interface
return M
