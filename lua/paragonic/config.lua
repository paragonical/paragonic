--[[
Paragonic Configuration Module
Handles plugin configuration, settings, and configuration management
--]]

local M = {}

-- Plugin configuration
local config = {
    ollama_host = "http://localhost:11434",
    ollama_model = "deepseek-r1:1.5b",
    database_path = nil, -- Will be set in setup() if vim is available
    log_level = "info",
}

-- Persistent storage paths (will be set in setup() if vim is available)
local data_dir = nil
local history_file = nil
local saved_searches_file = nil
local insights_file = nil

-- Initialize configuration paths
function M.initialize_paths()
    if not vim then
        return false, "Not in Neovim environment"
    end
    
    -- Initialize paths if not already set
    if not data_dir then
        data_dir = vim.fn.stdpath("data") .. "/paragonic"
        history_file = data_dir .. "/search_history.json"
        saved_searches_file = data_dir .. "/saved_searches.json"
        insights_file = data_dir .. "/search_insights.json"
    end
    
    -- Set database path if not already set
    if not config.database_path then
        config.database_path = vim.fn.stdpath("data") .. "/paragonic/db"
    end
    
    return true
end

-- Setup configuration with options
function M.setup(opts)
    -- Initialize paths
    local success, err = M.initialize_paths()
    if not success then
        return false, err
    end
    
    -- Merge options with defaults
    local new_config = vim.tbl_deep_extend("force", config, opts or {})
    config = vim.tbl_deep_extend("force", config, new_config)
    
    return true
end

-- Get current configuration
function M.get_config()
    return vim.tbl_deep_extend("force", {}, config)
end

-- Update configuration
function M.update_config(new_config)
    config = vim.tbl_deep_extend("force", config, new_config)
end

-- Get configuration value
function M.get(key)
    return config[key]
end

-- Set configuration value
function M.set(key, value)
    config[key] = value
end

-- Get data directory
function M.get_data_dir()
    return data_dir
end

-- Get history file path
function M.get_history_file()
    return history_file
end

-- Get saved searches file path
function M.get_saved_searches_file()
    return saved_searches_file
end

-- Get insights file path
function M.get_insights_file()
    return insights_file
end

-- Get configuration from backend
function M.get_backend_config()
    -- This would typically call the RPC client
    -- For now, return local config
    return config
end

-- Save configuration to backend
function M.save_backend_config(config_data)
    -- This would typically call the RPC client
    -- For now, update local config
    M.update_config(config_data)
    return true
end

return M
