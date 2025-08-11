--[[
Paragonic Patterns Module
Handles system pattern management and execution
--]]

local M = {}

local debug = require("paragonic.debug")
local utils = require("paragonic.utils")

-- Pattern management functions
function M.list_patterns()
    debug.debug_print("📋 Listing patterns...", "info")
    
    -- Try to get patterns from backend
    local success, patterns = pcall(function()
        -- For now, return mock patterns
        -- In the future, this will call the Rust backend
        return {
            {
                id = "session-summary-generation",
                name = "Session Summary Generation",
                category = "SessionManagement",
                description = "Generates comprehensive session summaries with key decisions and insights"
            },
            {
                id = "activity-labeling",
                name = "Activity Labeling", 
                category = "ActivityLabeling",
                description = "Labels and categorizes development activities for better tracking"
            },
            {
                id = "self-reflection",
                name = "Self-Reflection",
                category = "SelfReflection", 
                description = "Analyzes session performance and identifies areas for improvement"
            },
            {
                id = "context-summarization",
                name = "Context Summarization",
                category = "ContextSummarization",
                description = "Condenses session context into key points and categories"
            },
            {
                id = "progress-tracking",
                name = "Progress Tracking",
                category = "ProgressTracking",
                description = "Tracks development progress and identifies achieved milestones"
            },
            {
                id = "knowledge-extraction",
                name = "Knowledge Extraction",
                category = "KnowledgeExtraction",
                description = "Extracts reusable knowledge and patterns from session data"
            }
        }
    end)
    
    if not success then
        debug.debug_print("❌ Failed to list patterns: " .. tostring(patterns), "error")
        return {}
    end
    
    return patterns
end

function M.get_pattern_by_name(name)
    debug.debug_print("🔍 Getting pattern by name: " .. name, "info")
    
    local patterns = M.list_patterns()
    for _, pattern in ipairs(patterns) do
        if pattern.name == name then
            return pattern
        end
    end
    
    return nil
end

function M.execute_pattern(pattern_name, context)
    debug.debug_print("⚡ Executing pattern: " .. pattern_name, "info")
    
    -- Try to execute pattern
    local success, result = pcall(function()
        -- For now, return mock execution result
        -- In the future, this will call the Rust backend
        return {
            success = true,
            pattern_name = pattern_name,
            result = {
                summary = "Pattern executed successfully",
                timestamp = os.date(),
                context = context or {}
            }
        }
    end)
    
    if not success then
        debug.debug_print("❌ Failed to execute pattern: " .. tostring(result), "error")
        return {
            success = false,
            error = tostring(result)
        }
    end
    
    return result
end

function M.show_pattern_details(pattern_name)
    debug.debug_print("📖 Showing details for pattern: " .. pattern_name, "info")
    
    local pattern = M.get_pattern_by_name(pattern_name)
    if not pattern then
        vim.notify("Pattern not found: " .. pattern_name, vim.log.levels.ERROR)
        return false
    end
    
    -- Create a floating window to show pattern details
    local width = math.min(80, vim.o.columns - 4)
    local height = math.min(20, vim.o.lines - 4)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    
    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'rounded'
    })
    
    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_buf_set_option(buf, 'readonly', true)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
    
    -- Set window options
    vim.api.nvim_win_set_option(win, 'wrap', true)
    vim.api.nvim_win_set_option(win, 'number', false)
    vim.api.nvim_win_set_option(win, 'relativenumber', false)
    
    -- Format pattern details
    local lines = {
        "# " .. pattern.name,
        "",
        "**Category:** " .. pattern.category,
        "**Description:** " .. pattern.description,
        "",
        "## Workflow Steps",
        "",
        "1. Analyze session data",
        "2. Extract key information", 
        "3. Generate structured output",
        "",
        "## Output Format",
        "",
        "- Summary: Comprehensive overview",
        "- Key Points: Important insights",
        "- Action Items: Next steps",
        "",
        "---",
        "*Press 'q' to close*"
    }
    
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Add key mappings
    local opts = {buffer = buf, silent = true}
    vim.keymap.set('n', 'q', function()
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_buf_delete(buf, {force = true})
    end, opts)
    
    return true
end

-- Command functions
function M.pattern_list_command()
    debug.debug_print("📋 Executing pattern list command", "info")
    
    local patterns = M.list_patterns()
    if #patterns == 0 then
        vim.notify("No patterns found", vim.log.levels.WARN)
        return
    end
    
    -- Create a floating window to show patterns
    local width = math.min(100, vim.o.columns - 4)
    local height = math.min(25, vim.o.lines - 4)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    
    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'rounded'
    })
    
    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_buf_set_option(buf, 'readonly', true)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
    
    -- Set window options
    vim.api.nvim_win_set_option(win, 'wrap', false)
    vim.api.nvim_win_set_option(win, 'number', true)
    vim.api.nvim_win_set_option(win, 'relativenumber', false)
    
    -- Format patterns as a table
    local lines = {
        "# System Patterns",
        "",
        "| Name | Category | Description |",
        "|------|----------|-------------|"
    }
    
    for _, pattern in ipairs(patterns) do
        local description = pattern.description
        if #description > 50 then
            description = description:sub(1, 47) .. "..."
        end
        table.insert(lines, string.format("| %s | %s | %s |", pattern.name, pattern.category, description))
    end
    
    table.insert(lines, "")
    table.insert(lines, "---")
    table.insert(lines, "*Press 'Enter' to view details, 'e' to execute, 'q' to close*")
    
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Add key mappings
    local opts = {buffer = buf, silent = true}
    
    -- Close window
    vim.keymap.set('n', 'q', function()
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_buf_delete(buf, {force = true})
    end, opts)
    
    -- View pattern details
    vim.keymap.set('n', '<CR>', function()
        local line = vim.api.nvim_win_get_cursor(win)[1]
        if line > 4 and line <= 4 + #patterns then
            local pattern_index = line - 4
            local pattern = patterns[pattern_index]
            if pattern then
                vim.api.nvim_win_close(win, true)
                vim.api.nvim_buf_delete(buf, {force = true})
                M.show_pattern_details(pattern.name)
            end
        end
    end, opts)
    
    -- Execute pattern
    vim.keymap.set('n', 'e', function()
        local line = vim.api.nvim_win_get_cursor(win)[1]
        if line > 4 and line <= 4 + #patterns then
            local pattern_index = line - 4
            local pattern = patterns[pattern_index]
            if pattern then
                vim.api.nvim_win_close(win, true)
                vim.api.nvim_buf_delete(buf, {force = true})
                M.execute_pattern_command(pattern.name)
            end
        end
    end, opts)
    
    debug.debug_print("✅ Pattern list displayed", "success")
end

function M.execute_pattern_command(pattern_name)
    debug.debug_print("⚡ Executing pattern command: " .. pattern_name, "info")
    
    local result = M.execute_pattern(pattern_name)
    if result.success then
        vim.notify("Pattern executed successfully: " .. pattern_name, vim.log.levels.INFO)
        
        -- Show result in a floating window
        local width = math.min(80, vim.o.columns - 4)
        local height = math.min(15, vim.o.lines - 4)
        local row = math.floor((vim.o.lines - height) / 2)
        local col = math.floor((vim.o.columns - width) / 2)
        
        local buf = vim.api.nvim_create_buf(false, true)
        local win = vim.api.nvim_open_win(buf, true, {
            relative = 'editor',
            width = width,
            height = height,
            row = row,
            col = col,
            style = 'minimal',
            border = 'rounded'
        })
        
        -- Set buffer options
        vim.api.nvim_buf_set_option(buf, 'modifiable', false)
        vim.api.nvim_buf_set_option(buf, 'readonly', true)
        vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
        vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
        
        -- Set window options
        vim.api.nvim_win_set_option(win, 'wrap', true)
        vim.api.nvim_win_set_option(win, 'number', false)
        vim.api.nvim_win_set_option(win, 'relativenumber', false)
        
        -- Format result
        local lines = {
            "# Pattern Execution Result",
            "",
            "**Pattern:** " .. pattern_name,
            "**Status:** Success",
            "**Timestamp:** " .. result.result.timestamp,
            "",
            "## Summary",
            "",
            result.result.result.summary,
            "",
            "---",
            "*Press 'q' to close*"
        }
        
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        
        -- Add key mapping to close
        local opts = {buffer = buf, silent = true}
        vim.keymap.set('n', 'q', function()
            vim.api.nvim_win_close(win, true)
            vim.api.nvim_buf_delete(buf, {force = true})
        end, opts)
        
    else
        vim.notify("Failed to execute pattern: " .. (result.error or "Unknown error"), vim.log.levels.ERROR)
    end
end

return M
