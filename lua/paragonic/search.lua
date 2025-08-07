--[[
Paragonic Search Module
Handles search functionality, search history, and saved searches
--]]

local M = {}

-- Search history and saved searches
local search_history = {}
local saved_searches = {}
local max_history_size = 50

-- AI-powered search enhancement
local search_insights = {}
local context_cache = {}
local suggestion_cache = {}

-- Add search to history
function M.add_to_search_history(query, search_type, result_count)
    local search_entry = {
        query = query,
        type = search_type or "basic",
        result_count = result_count or 0,
        timestamp = os.time(),
        date = os.date("%Y-%m-%d %H:%M:%S")
    }
    
    -- Add to beginning of history
    table.insert(search_history, 1, search_entry)
    
    -- Limit history size
    if #search_history > max_history_size then
        table.remove(search_history, #search_history)
    end
    
    return true
end

-- Get search history
function M.get_search_history()
    return vim.tbl_deep_extend("force", {}, search_history)
end

-- Clear search history
function M.clear_search_history()
    search_history = {}
    return true
end

-- Save current search
function M.save_current_search(name, query, search_type)
    if not name or name == "" then
        return false, "Search name is required"
    end
    
    if not query or query == "" then
        return false, "Search query is required"
    end
    
    local saved_search = {
        name = name,
        query = query,
        type = search_type or "basic",
        timestamp = os.time(),
        date = os.date("%Y-%m-%d %H:%M:%S")
    }
    
    saved_searches[name] = saved_search
    return true
end

-- Get saved searches
function M.get_saved_searches()
    return vim.tbl_deep_extend("force", {}, saved_searches)
end

-- Delete saved search
function M.delete_saved_search(name)
    if saved_searches[name] then
        saved_searches[name] = nil
        return true
    end
    return false, "Saved search not found"
end

-- Clear saved searches
function M.clear_saved_searches()
    saved_searches = {}
    return true
end

-- Search command handlers
function M.search_command(args)
    local query = table.concat(args, " ")
    if query == "" then
        query = vim.fn.input("Search query: ")
        if query == "" then
            vim.notify("Search query cannot be empty", vim.log.levels.WARN)
            return
        end
    end
    
    local limit = tonumber(vim.fn.input("Limit (default 10): ")) or 10
    
    -- Perform search
    local backend = require("paragonic.backend")
    local results, err = backend.search_embeddings(query, limit)
    if not results then
        vim.notify("Search failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
        return
    end
    
    -- Add to search history
    M.add_to_search_history(query, "basic", results.results and #results.results or 0)
    
    -- Display results in a floating window
    M.display_search_results(results, "Basic Search: " .. query)
end

function M.search_filtered_command(args)
    local query = table.concat(args, " ")
    if query == "" then
        query = vim.fn.input("Search query: ")
        if query == "" then
            vim.notify("Search query cannot be empty", vim.log.levels.WARN)
            return
        end
    end
    
    local content_type = vim.fn.input("Content type (optional): ")
    local limit = tonumber(vim.fn.input("Limit (default 10): ")) or 10
    local threshold = tonumber(vim.fn.input("Threshold (default 0.0): ")) or 0.0
    
    -- Perform filtered search
    local backend = require("paragonic.backend")
    local results, err = backend.find_similar_content(query, content_type ~= "" and content_type or nil, limit, threshold)
    if not results then
        vim.notify("Filtered search failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
        return
    end
    
    -- Add to search history
    M.add_to_search_history(query, "filtered", results.results and #results.results or 0)
    
    -- Display results in a floating window
    M.display_search_results(results, "Filtered Search: " .. query)
end

function M.search_hybrid_command(args)
    local query = table.concat(args, " ")
    if query == "" then
        query = vim.fn.input("Search query: ")
        if query == "" then
            vim.notify("Search query cannot be empty", vim.log.levels.WARN)
            return
        end
    end
    
    local content_type = vim.fn.input("Content type (optional): ")
    local limit = tonumber(vim.fn.input("Limit (default 10): ")) or 10
    local threshold = tonumber(vim.fn.input("Threshold (default 0.0): ")) or 0.0
    local include_text_filtering = vim.fn.input("Include text filtering? (y/n, default y): "):lower() ~= "n"
    
    -- Perform hybrid search
    local backend = require("paragonic.backend")
    local results, err = backend.hybrid_search(query, content_type ~= "" and content_type or nil, limit, threshold, include_text_filtering)
    if not results then
        vim.notify("Hybrid search failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
        return
    end
    
    -- Add to search history
    M.add_to_search_history(query, "hybrid", results.results and #results.results or 0)
    
    -- Display results in a floating window
    M.display_search_results(results, "Hybrid Search: " .. query)
end

-- Display search results in a floating window
function M.display_search_results(results, title)
    -- Create floating window
    local width = math.min(80, vim.o.columns - 4)
    local height = math.min(20, vim.o.lines - 4)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    
    -- Create buffer for results
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "swapfile", false)
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    
    -- Format results
    local lines = {
        "# " .. (title or "Search Results"),
        "",
        "Found " .. (results.total or #results.results) .. " results",
        ""
    }
    
    if results.results then
        for i, result in ipairs(results.results) do
            table.insert(lines, "## Result " .. i)
            if result.title then
                table.insert(lines, "**Title:** " .. result.title)
            end
            if result.content then
                table.insert(lines, "**Content:** " .. result.content:sub(1, 100) .. (result.content:len() > 100 and "..." or ""))
            end
            if result.score then
                table.insert(lines, "**Score:** " .. string.format("%.3f", result.score))
            end
            if result.metadata then
                table.insert(lines, "**Metadata:** " .. vim.inspect(result.metadata))
            end
            table.insert(lines, "")
        end
    end
    
    -- Set buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Create window
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded"
    })
    
    -- Set window options
    vim.api.nvim_win_set_option(win, "wrap", true)
    vim.api.nvim_win_set_option(win, "linebreak", true)
    
    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    
    -- Add keymaps
    vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "<cmd>close<CR>", {noremap = true, silent = true})
end

-- Show search history
function M.show_search_history()
    local history = M.get_search_history()
    
    if #history == 0 then
        vim.notify("No search history found", vim.log.levels.INFO)
        return
    end
    
    -- Create buffer for history
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "swapfile", false)
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    
    -- Format history
    local lines = {
        "# Search History",
        "",
        "Recent searches:",
        ""
    }
    
    for i, entry in ipairs(history) do
        table.insert(lines, "## " .. i .. ". " .. entry.query)
        table.insert(lines, "**Type:** " .. entry.type)
        table.insert(lines, "**Results:** " .. entry.result_count)
        table.insert(lines, "**Date:** " .. entry.date)
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

-- Show saved searches
function M.show_saved_searches()
    local saved = M.get_saved_searches()
    
    if vim.tbl_isempty(saved) then
        vim.notify("No saved searches found", vim.log.levels.INFO)
        return
    end
    
    -- Create buffer for saved searches
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "swapfile", false)
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    
    -- Format saved searches
    local lines = {
        "# Saved Searches",
        "",
        "Saved searches:",
        ""
    }
    
    for name, entry in pairs(saved) do
        table.insert(lines, "## " .. name)
        table.insert(lines, "**Query:** " .. entry.query)
        table.insert(lines, "**Type:** " .. entry.type)
        table.insert(lines, "**Date:** " .. entry.date)
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

-- Save current search command
function M.save_current_search_command()
    local name = vim.fn.input("Search name: ")
    if name == "" then
        vim.notify("Search name cannot be empty", vim.log.levels.WARN)
        return
    end
    
    local query = vim.fn.input("Search query: ")
    if query == "" then
        vim.notify("Search query cannot be empty", vim.log.levels.WARN)
        return
    end
    
    local search_type = vim.fn.input("Search type (basic/filtered/hybrid, default basic): ")
    if search_type == "" then
        search_type = "basic"
    end
    
    local success, err = M.save_current_search(name, query, search_type)
    if success then
        vim.notify("Search '" .. name .. "' saved successfully", vim.log.levels.INFO)
    else
        vim.notify("Failed to save search: " .. (err or "unknown error"), vim.log.levels.ERROR)
    end
end

-- Load persistent data
function M.load_persistent_data()
    local config = require("paragonic.config")
    local history_file = config.get_history_file()
    local saved_searches_file = config.get_saved_searches_file()
    local insights_file = config.get_insights_file()
    
    -- Load search history
    if history_file then
        local file = io.open(history_file, "r")
        if file then
            local content = file:read("*all")
            file:close()
            
            local success, data = pcall(vim.json.decode, content)
            if success and data then
                search_history = data
            end
        end
    end
    
    -- Load saved searches
    if saved_searches_file then
        local file = io.open(saved_searches_file, "r")
        if file then
            local content = file:read("*all")
            file:close()
            
            local success, data = pcall(vim.json.decode, content)
            if success and data then
                saved_searches = data
            end
        end
    end
    
    -- Load search insights
    if insights_file then
        local file = io.open(insights_file, "r")
        if file then
            local content = file:read("*all")
            file:close()
            
            local success, data = pcall(vim.json.decode, content)
            if success and data then
                search_insights = data
            end
        end
    end
end

-- Save persistent data
function M.save_persistent_data()
    local config = require("paragonic.config")
    local history_file = config.get_history_file()
    local saved_searches_file = config.get_saved_searches_file()
    local insights_file = config.get_insights_file()
    
    -- Ensure directory exists
    local data_dir = config.get_data_dir()
    if data_dir then
        vim.fn.mkdir(data_dir, "p")
    end
    
    -- Save search history
    if history_file then
        local file = io.open(history_file, "w")
        if file then
            file:write(vim.json.encode(search_history))
            file:close()
        end
    end
    
    -- Save saved searches
    if saved_searches_file then
        local file = io.open(saved_searches_file, "w")
        if file then
            file:write(vim.json.encode(saved_searches))
            file:close()
        end
    end
    
    -- Save search insights
    if insights_file then
        local file = io.open(insights_file, "w")
        if file then
            file:write(vim.json.encode(search_insights))
            file:close()
        end
    end
end

return M
