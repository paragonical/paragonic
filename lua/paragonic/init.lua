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
    -- Check if chat buffer already exists
    local chat_buf = nil
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(buf)
        if name == "paragonic://chat" then
            chat_buf = buf
            break
        end
    end
    
    -- Create new buffer if it doesn't exist
    if not chat_buf then
        chat_buf = vim.api.nvim_create_buf(true, true)
        
        -- Set buffer name
        vim.api.nvim_buf_set_name(chat_buf, "paragonic://chat")
        
        -- Set buffer options
        vim.api.nvim_buf_set_option(chat_buf, "buftype", "nofile")
        vim.api.nvim_buf_set_option(chat_buf, "swapfile", false)
        vim.api.nvim_buf_set_option(chat_buf, "modifiable", true)
        
        -- Add initial content
        vim.api.nvim_buf_set_lines(chat_buf, 0, -1, false, {
            "# Paragonic Chat",
            "",
            "Type your message below and press Enter to send:",
            "",
            "---"
        })
        
        -- Set filetype for syntax highlighting
        vim.api.nvim_buf_set_option(chat_buf, "filetype", "markdown")
    end
    
    -- Open the buffer in a new window
    vim.api.nvim_command("split")
    vim.api.nvim_set_current_buf(chat_buf)
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