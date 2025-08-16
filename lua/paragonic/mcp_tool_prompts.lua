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
    ]]
}

-- Tool categorization
M.tool_categories = {
    file_operations = {"agent_edit_file", "agent_create_file", "agent_save_file"},
    session_management = {"agent_session_info"},
    pattern_execution = {"pattern_execute", "pattern_status"},
    search_navigation = {"file_search", "buffer_navigate"}
}

-- Intent detection patterns
M.intent_patterns = {
    file_editing = {"edit", "modify", "change", "update", "fix", "replace", "insert", "delete"},
    file_creation = {"create", "new", "add", "make", "generate", "write"},
    file_saving = {"save", "persist", "write", "store"},
    session_management = {"session", "buffer", "window", "tab"},
    pattern_execution = {"pattern", "execute", "run", "apply"},
    search_operations = {"search", "find", "locate", "grep"}
}

-- Configuration
M.config = {
    enabled = true,
    prompt_style = "contextual", -- "base", "contextual", "minimal"
    include_pattern_context = true,
    include_usage_guidance = true,
    max_tools_per_prompt = 5,
    intent_detection_threshold = 0.7,
    cache_size = 100
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
    
    debug.debug_print("📂 Categorized " .. #tools .. " tools into " .. M.count_table_keys(categorized) .. " categories", "debug")
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
        timestamp = os.time()
    }
    
    debug.debug_print("📊 Extracted conversation context", "debug")
    return context
end

-- Get active patterns
function M.get_active_patterns()
    -- TODO: Integrate with pattern system when available
    local patterns = {}
    
    -- For now, return empty patterns
    debug.debug_print("🔄 No active patterns detected", "debug")
    return patterns
end

-- Get buffer context
function M.get_buffer_context()
    local buffer = vim.api.nvim_get_current_buf()
    local context = {
        buffer_id = buffer,
        file_name = vim.fn.expand("%"),
        file_type = vim.api.nvim_buf_get_option(buffer, "filetype"),
        line_count = vim.api.nvim_buf_line_count(buffer),
        modified = vim.api.nvim_buf_get_option(buffer, "modified")
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
                relevance = relevance_score
            })
        end
    end
    
    -- Sort by relevance and limit
    table.sort(relevant_tools, function(a, b) return a.relevance > b.relevance end)
    
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
        search_operations = "search_navigation"
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
        agent_session_info = "Use agent_session_info to get current session information and context."
    }
    
    return guidance_templates[tool.name]
end

-- Get pattern context
function M.get_pattern_context(context)
    local patterns = M.get_active_patterns()
    if #patterns == 0 then
        return "No active patterns"
    end
    
    local pattern_names = {}
    for _, pattern in ipairs(patterns) do
        table.insert(pattern_names, pattern.name or pattern)
    end
    
    return "Active patterns: " .. table.concat(pattern_names, ", ")
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
        local contextual_prompt = M.prompt_templates.contextual_tools:gsub("{relevant_tools}", tool_list):gsub("{usage_guidance}", usage_guidance)
        table.insert(prompt_parts, contextual_prompt)
    end
    
    -- Pattern context
    if M.config.include_pattern_context and pattern_context and pattern_context ~= "No active patterns" then
        local pattern_prompt = M.prompt_templates.pattern_aware:gsub("{pattern_context}", pattern_context):gsub("{pattern_tools}", M.get_pattern_tools())
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
        -- TODO: Get tools specific to each pattern
        table.insert(pattern_tools, "agent_edit_file, agent_create_file")
    end
    
    return table.concat(pattern_tools, ", ")
end

-- Generate cache key
function M.generate_cache_key(user_message, context)
    local key_parts = {
        user_message:sub(1, 100), -- First 100 chars
        context.current_buffer or "",
        context.current_directory or "",
        M.config.prompt_style
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
        max_size = M.config.cache_size
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
    for _ in pairs(t) do count = count + 1 end
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
