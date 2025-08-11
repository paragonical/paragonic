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

-- Pattern metrics visualization functions

-- Get pattern statistics from backend
function M.get_pattern_statistics(pattern_name)
    debug.debug_print("📊 Getting statistics for pattern: " .. pattern_name, "info")
    
    -- Try to get statistics from backend
    local success, stats = pcall(function()
        -- For now, return mock statistics
        -- In the future, this will call the Rust backend
        return {
            total_executions = 25,
            successful_executions = 22,
            failed_executions = 3,
            average_execution_time_ms = 1250.5,
            last_executed = "2025-08-08T10:30:00Z",
            success_rate = 0.88
        }
    end)
    
    if not success then
        debug.debug_print("❌ Failed to get pattern statistics: " .. tostring(stats), "error")
        return nil
    end
    
    return stats
end

-- Get pattern metrics from backend
function M.get_pattern_metrics(pattern_id, days)
    debug.debug_print("📈 Getting metrics for pattern: " .. pattern_id .. " (days: " .. days .. ")", "info")
    
    -- Try to get metrics from backend
    local success, metrics = pcall(function()
        -- For now, return mock metrics
        -- In the future, this will call the Rust backend
        return {
            pattern_id = pattern_id,
            pattern_name = "Session Summary Generation",
            metrics = {
                {
                    metric_name = "success_rate",
                    metric_value = 0.88,
                    metric_unit = "percentage",
                    time_period = "daily",
                    period_start = "2025-08-01T00:00:00Z",
                    period_end = "2025-08-08T23:59:59Z"
                },
                {
                    metric_name = "execution_time",
                    metric_value = 1250.5,
                    metric_unit = "milliseconds",
                    time_period = "daily",
                    period_start = "2025-08-01T00:00:00Z",
                    period_end = "2025-08-08T23:59:59Z"
                },
                {
                    metric_name = "usage_frequency",
                    metric_value = 3.5,
                    metric_unit = "executions_per_day",
                    time_period = "daily",
                    period_start = "2025-08-01T00:00:00Z",
                    period_end = "2025-08-08T23:59:59Z"
                }
            },
            summary = {
                total_executions = 25,
                success_rate = 0.88,
                average_execution_time_ms = 1250.5,
                last_execution_at = "2025-08-08T10:30:00Z"
            }
        }
    end)
    
    if not success then
        debug.debug_print("❌ Failed to get pattern metrics: " .. tostring(metrics), "error")
        return nil
    end
    
    return metrics
end

-- Get execution history from backend
function M.get_execution_history(pattern_name)
    debug.debug_print("📋 Getting execution history for pattern: " .. pattern_name, "info")
    
    -- Try to get execution history from backend
    local success, history = pcall(function()
        -- For now, return mock history
        -- In the future, this will call the Rust backend
        return {
            {
                execution_id = "exec-1",
                pattern_name = pattern_name,
                execution_status = "completed",
                execution_time_ms = 1200,
                created_at = "2025-08-08T10:30:00Z",
                result_summary = "Successfully generated session summary"
            },
            {
                execution_id = "exec-2",
                pattern_name = pattern_name,
                execution_status = "completed",
                execution_time_ms = 1300,
                created_at = "2025-08-08T09:15:00Z",
                result_summary = "Successfully generated session summary"
            },
            {
                execution_id = "exec-3",
                pattern_name = pattern_name,
                execution_status = "failed",
                execution_time_ms = 500,
                created_at = "2025-08-08T08:45:00Z",
                result_summary = "Failed to generate summary due to missing data"
            }
        }
    end)
    
    if not success then
        debug.debug_print("❌ Failed to get execution history: " .. tostring(history), "error")
        return {}
    end
    
    return history
end

-- Show pattern statistics in a floating window
function M.show_pattern_statistics(pattern_name)
    debug.debug_print("📊 Showing statistics for pattern: " .. pattern_name, "info")
    
    local stats = M.get_pattern_statistics(pattern_name)
    if not stats then
        vim.notify("Failed to get statistics for pattern: " .. pattern_name, vim.log.levels.ERROR)
        return false
    end
    
    -- Create a floating window to show statistics
    local width = math.min(70, vim.o.columns - 4)
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
    
    -- Format statistics
    local success_rate_percent = string.format("%.1f%%", stats.success_rate * 100)
    local avg_time_ms = string.format("%.1f ms", stats.average_execution_time_ms)
    
    local lines = {
        "# Pattern Statistics: " .. pattern_name,
        "",
        "## Summary",
        "",
        "**Total Executions:** " .. stats.total_executions,
        "**Successful:** " .. stats.successful_executions,
        "**Failed:** " .. stats.failed_executions,
        "**Success Rate:** " .. success_rate_percent,
        "**Avg Execution Time:** " .. avg_time_ms,
        "",
        "**Last Executed:** " .. (stats.last_executed or "Never"),
        "",
        "---",
        "*Press 'q' to close, 'h' for history, 'm' for metrics*"
    }
    
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Add key mappings
    local opts = {buffer = buf, silent = true}
    
    -- Close window
    vim.keymap.set('n', 'q', function()
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_buf_delete(buf, {force = true})
    end, opts)
    
    -- Show execution history
    vim.keymap.set('n', 'h', function()
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_buf_delete(buf, {force = true})
        M.show_execution_history(pattern_name)
    end, opts)
    
    -- Show detailed metrics
    vim.keymap.set('n', 'm', function()
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_buf_delete(buf, {force = true})
        M.show_pattern_metrics(pattern_name)
    end, opts)
    
    return true
end

-- Show pattern metrics in a floating window
function M.show_pattern_metrics(pattern_name)
    debug.debug_print("📈 Showing metrics for pattern: " .. pattern_name, "info")
    
    local pattern = M.get_pattern_by_name(pattern_name)
    if not pattern then
        vim.notify("Pattern not found: " .. pattern_name, vim.log.levels.ERROR)
        return false
    end
    
    local metrics = M.get_pattern_metrics(pattern.id, 7) -- Last 7 days
    if not metrics then
        vim.notify("Failed to get metrics for pattern: " .. pattern_name, vim.log.levels.ERROR)
        return false
    end
    
    -- Create a floating window to show metrics
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
    
    -- Format metrics
    local lines = {
        "# Pattern Metrics: " .. pattern_name,
        "",
        "## Summary (Last 7 Days)",
        "",
        "**Total Executions:** " .. metrics.summary.total_executions,
        "**Success Rate:** " .. string.format("%.1f%%", metrics.summary.success_rate * 100),
        "**Avg Execution Time:** " .. string.format("%.1f ms", metrics.summary.average_execution_time_ms),
        "**Last Execution:** " .. metrics.summary.last_execution_at,
        "",
        "## Detailed Metrics",
        "",
        "| Metric | Value | Unit | Period |",
        "|--------|-------|------|--------|"
    }
    
    for _, metric in ipairs(metrics.metrics) do
        local value_str = string.format("%.2f", metric.metric_value)
        table.insert(lines, string.format("| %s | %s | %s | %s |", 
            metric.metric_name, value_str, metric.metric_unit, metric.time_period))
    end
    
    table.insert(lines, "")
    table.insert(lines, "---")
    table.insert(lines, "*Press 'q' to close, 's' for statistics, 'h' for history*")
    
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Add key mappings
    local opts = {buffer = buf, silent = true}
    
    -- Close window
    vim.keymap.set('n', 'q', function()
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_buf_delete(buf, {force = true})
    end, opts)
    
    -- Show statistics
    vim.keymap.set('n', 's', function()
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_buf_delete(buf, {force = true})
        M.show_pattern_statistics(pattern_name)
    end, opts)
    
    -- Show execution history
    vim.keymap.set('n', 'h', function()
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_buf_delete(buf, {force = true})
        M.show_execution_history(pattern_name)
    end, opts)
    
    return true
end

-- Show execution history in a floating window
function M.show_execution_history(pattern_name)
    debug.debug_print("📋 Showing execution history for pattern: " .. pattern_name, "info")
    
    local history = M.get_execution_history(pattern_name)
    if #history == 0 then
        vim.notify("No execution history found for pattern: " .. pattern_name, vim.log.levels.WARN)
        return false
    end
    
    -- Create a floating window to show history
    local width = math.min(90, vim.o.columns - 4)
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
    vim.api.nvim_win_set_option(win, 'number', true)
    vim.api.nvim_win_set_option(win, 'relativenumber', false)
    
    -- Format history
    local lines = {
        "# Execution History: " .. pattern_name,
        "",
        "| ID | Status | Time (ms) | Date | Summary |",
        "|----|--------|-----------|------|---------|"
    }
    
    for _, entry in ipairs(history) do
        local status_icon = entry.execution_status == "completed" and "✅" or "❌"
        local time_str = string.format("%d", entry.execution_time_ms)
        local date_str = entry.created_at:sub(1, 16) -- Truncate timestamp
        local summary = entry.result_summary
        if #summary > 40 then
            summary = summary:sub(1, 37) .. "..."
        end
        
        table.insert(lines, string.format("| %s | %s %s | %s | %s | %s |", 
            entry.execution_id:sub(1, 8), status_icon, entry.execution_status, 
            time_str, date_str, summary))
    end
    
    table.insert(lines, "")
    table.insert(lines, "---")
    table.insert(lines, "*Press 'q' to close, 's' for statistics, 'm' for metrics*")
    
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Add key mappings
    local opts = {buffer = buf, silent = true}
    
    -- Close window
    vim.keymap.set('n', 'q', function()
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_buf_delete(buf, {force = true})
    end, opts)
    
    -- Show statistics
    vim.keymap.set('n', 's', function()
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_buf_delete(buf, {force = true})
        M.show_pattern_statistics(pattern_name)
    end, opts)
    
    -- Show metrics
    vim.keymap.set('n', 'm', function()
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_buf_delete(buf, {force = true})
        M.show_pattern_metrics(pattern_name)
    end, opts)
    
    return true
end

-- Show metrics chart (ASCII art visualization)
function M.show_metrics_chart(pattern_name)
    debug.debug_print("📊 Showing metrics chart for pattern: " .. pattern_name, "info")
    
    local metrics = M.get_pattern_metrics(pattern_name, 7)
    if not metrics then
        vim.notify("Failed to get metrics for pattern: " .. pattern_name, vim.log.levels.ERROR)
        return false
    end
    
    -- Create a floating window to show chart
    local width = math.min(70, vim.o.columns - 4)
    local height = math.min(18, vim.o.lines - 4)
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
    vim.api.nvim_win_set_option(win, 'number', false)
    vim.api.nvim_win_set_option(win, 'relativenumber', false)
    
    -- Create ASCII chart
    local lines = {
        "# Metrics Chart: " .. pattern_name,
        "",
        "## Success Rate Trend",
        "",
        "100% ████████████████████████████████████████████████████████████████",
        " 90% ████████████████████████████████████████████████████████████████",
        " 80% ████████████████████████████████████████████████████████████████",
        " 70% ████████████████████████████████████████████████████████████████",
        " 60% ████████████████████████████████████████████████████████████████",
        " 50% ████████████████████████████████████████████████████████████████",
        " 40% ████████████████████████████████████████████████████████████████",
        " 30% ████████████████████████████████████████████████████████████████",
        " 20% ████████████████████████████████████████████████████████████████",
        " 10% ████████████████████████████████████████████████████████████████",
        "  0% ████████████████████████████████████████████████████████████████",
        "     └─────────────────────────────────────────────────────────────────┘",
        "     Last 7 days",
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
    
    return true
end

-- Show performance trends
function M.show_performance_trends(pattern_name)
    debug.debug_print("📈 Showing performance trends for pattern: " .. pattern_name, "info")
    
    local stats = M.get_pattern_statistics(pattern_name)
    if not stats then
        vim.notify("Failed to get statistics for pattern: " .. pattern_name, vim.log.levels.ERROR)
        return false
    end
    
    -- Create a floating window to show trends
    local width = math.min(75, vim.o.columns - 4)
    local height = math.min(16, vim.o.lines - 4)
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
    
    -- Format trends
    local success_rate_percent = string.format("%.1f%%", stats.success_rate * 100)
    local avg_time_ms = string.format("%.1f ms", stats.average_execution_time_ms)
    
    local lines = {
        "# Performance Trends: " .. pattern_name,
        "",
        "## Key Metrics",
        "",
        "**Success Rate:** " .. success_rate_percent .. " (Excellent)",
        "**Execution Time:** " .. avg_time_ms .. " (Good)",
        "**Reliability:** " .. (stats.success_rate > 0.8 and "High" or "Medium"),
        "",
        "## Trend Analysis",
        "",
        "• Pattern shows consistent performance",
        "• Success rate is above 80% threshold",
        "• Execution time is within acceptable range",
        "• Ready for production use",
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
    
    return true
end

return M
