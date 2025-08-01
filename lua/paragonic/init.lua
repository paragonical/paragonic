--[[
Paragonic - Agentic Neovim Extension
Main plugin entry point
--]]

local M = {}

-- Plugin configuration
local config = {
    ollama_host = "http://localhost:11434",
    ollama_model = "llama3.2:3b",
    database_path = vim.fn.stdpath("data") .. "/paragonic/db",
    log_level = "info",
}

-- Initialize the plugin
function M.setup(opts)
    -- Merge user options with defaults
    if opts then
        config = vim.tbl_deep_extend("force", config, opts)
    end
    
    -- Set up commands
    M._setup_commands()
    
    -- Set up autocommands
    M._setup_autocommands()
    
    -- Initialize Rust backend
    M._initialize_backend()
    
    vim.notify("Paragonic initialized", vim.log.levels.INFO)
end

-- Set up Neovim commands
function M._setup_commands()
    vim.api.nvim_create_user_command('ParagonicChat', function()
        M.open_chat()
    end, { desc = 'Open Paragonic chat interface' })
    
    vim.api.nvim_create_user_command('ParagonicProjects', function()
        M.open_projects()
    end, { desc = 'Open Paragonic projects interface' })
    
    vim.api.nvim_create_user_command('ParagonicConfig', function()
        M.open_config()
    end, { desc = 'Open Paragonic configuration' })
end

-- Set up autocommands
function M._setup_autocommands()
    -- Add any autocommands here as needed
end

-- Initialize Rust backend
function M._initialize_backend()
    -- TODO: Initialize Rust backend via RPC or similar
    -- This will be implemented as we build the integration
end

-- Open chat interface
function M.open_chat()
    -- TODO: Implement chat interface
    vim.notify("Chat interface not yet implemented", vim.log.levels.WARN)
end

-- Open projects interface
function M.open_projects()
    -- TODO: Implement projects interface
    vim.notify("Projects interface not yet implemented", vim.log.levels.WARN)
end

-- Open configuration
function M.open_config()
    -- TODO: Implement configuration interface
    vim.notify("Configuration interface not yet implemented", vim.log.levels.WARN)
end

-- Get current configuration
function M.get_config()
    return config
end

-- Update configuration
function M.update_config(new_config)
    config = vim.tbl_deep_extend("force", config, new_config)
end

return M 