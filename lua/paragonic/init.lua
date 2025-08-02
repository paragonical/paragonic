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
    -- Merge options with defaults
    local new_config = vim.tbl_deep_extend("force", config, opts or {})
    config = vim.tbl_deep_extend("force", config, new_config)
    
    -- Create commands
    vim.api.nvim_create_user_command("ParagonicChat", M.open_chat, {})
    vim.api.nvim_create_user_command("ParagonicProjects", M.open_projects, {})
    vim.api.nvim_create_user_command("ParagonicConfig", M.open_config, {})
    vim.api.nvim_create_user_command("ParagonicSend", M.send_message_command, {})
    vim.api.nvim_create_user_command("ParagonicCreateProject", M.create_project_command, {})
    vim.api.nvim_create_user_command("ParagonicSaveConfig", M.save_config_command, {})
    
    -- Initialize backend
    M._initialize_backend()
    
    -- Add any autocommands here as needed
end

-- Get RPC client, initializing backend if needed
function M._get_rpc_client()
    if not M._rpc_client then
        M._initialize_backend()
    end
    return M._rpc_client
end

-- Send a message to the AI and get response
function M.send_message(message, model)
    local rpc_client = M._get_rpc_client()
    if not rpc_client then
        return nil, "Backend not available"
    end
    
    -- Use default model if not specified
    model = model or "llama2"
    
    -- Send chat completion request
    local response = rpc_client:chat_completion(model, message)
    if not response then
        return nil, "Failed to get response from AI"
    end
    
    -- Parse JSON response
    local parsed_response = M.parse_json_response(response)
    if not parsed_response then
        return nil, "Failed to parse AI response"
    end
    
    -- Check for error in response
    if parsed_response.error then
        return nil, "AI error: " .. (parsed_response.error.message or "Unknown error")
    end
    
    -- Extract AI message content
    if parsed_response.result and parsed_response.result.message then
        return parsed_response.result.message.content
    elseif parsed_response.result and parsed_response.result.content then
        return parsed_response.result.content
    else
        return nil, "Unexpected response format"
    end
end

-- Get list of available models
function M.get_available_models()
    local rpc_client = M._get_rpc_client()
    if not rpc_client then
        return nil, "Backend not available"
    end
    
    -- Get models list
    local response = rpc_client:list_models()
    if not response then
        return nil, "Failed to get models list"
    end
    
    -- Parse JSON response
    local parsed_response = M.parse_json_response(response)
    if not parsed_response then
        return nil, "Failed to parse models response"
    end
    
    -- Check for error in response
    if parsed_response.error then
        return nil, "Models error: " .. (parsed_response.error.message or "Unknown error")
    end
    
    -- Extract models list
    if parsed_response.result and parsed_response.result.models then
        return parsed_response.result.models
    else
        return nil, "Unexpected models response format"
    end
end

-- Get list of projects
function M.get_projects()
    local rpc_client = M._get_rpc_client()
    if not rpc_client then
        return nil, "Backend not available"
    end
    
    -- Get projects list
    local response = rpc_client:get_projects()
    if not response then
        return nil, "Failed to get projects list"
    end
    
    -- Parse JSON response
    local parsed_response = M.parse_json_response(response)
    if not parsed_response then
        return nil, "Failed to parse projects response"
    end
    
    -- Check for error in response
    if parsed_response.error then
        return nil, "Projects error: " .. (parsed_response.error.message or "Unknown error")
    end
    
    -- Extract projects list
    if parsed_response.result and parsed_response.result.projects then
        return parsed_response.result.projects
    else
        return nil, "Unexpected projects response format"
    end
end

-- Create a new project
function M.create_project(name, description)
    local rpc_client = M._get_rpc_client()
    if not rpc_client then
        return nil, "Backend not available"
    end
    
    -- Create project
    local response = rpc_client:create_project(name, description)
    if not response then
        return nil, "Failed to create project"
    end
    
    return response
end

-- Get configuration from backend
function M.get_config()
    local rpc_client = M._get_rpc_client()
    if not rpc_client then
        return nil, "Backend not available"
    end
    
    -- Get configuration
    local response = rpc_client:get_config()
    if not response then
        return nil, "Failed to get configuration"
    end
    
    -- Parse JSON response
    local parsed_response = M.parse_json_response(response)
    if not parsed_response then
        return nil, "Failed to parse configuration response"
    end
    
    -- Check for error in response
    if parsed_response.error then
        return nil, "Configuration error: " .. (parsed_response.error.message or "Unknown error")
    end
    
    -- Extract configuration data
    if parsed_response.result then
        return parsed_response.result
    else
        return nil, "Unexpected configuration response format"
    end
end

-- Save configuration to backend
function M.save_config(config_data)
    local rpc_client = M._get_rpc_client()
    if not rpc_client then
        return nil, "Backend not available"
    end
    
    -- Save configuration
    local response = rpc_client:save_config(config_data)
    if not response then
        return nil, "Failed to save configuration"
    end
    
    return response
end

-- Parse JSON-RPC response
function M.parse_json_response(json_string)
    if not json_string or json_string == "" then
        return nil, "Empty JSON string"
    end
    
    -- Try to load cjson
    local cjson_available = pcall(require, "cjson")
    local cjson = cjson_available and require("cjson") or nil
    
    if not cjson then
        return nil, "cjson library not available"
    end
    
    -- Parse JSON with error handling
    local success, result = pcall(cjson.decode, json_string)
    if not success then
        return nil, "Failed to parse JSON: " .. tostring(result)
    end
    
    return result
end

-- Initialize Rust backend
function M._initialize_backend()
    -- Only initialize once
    if M._rpc_client then
        return
    end
    
    -- Create RPC client
    local rpc = require("paragonic.rpc")
    M._rpc_client = rpc.new("127.0.0.1:3000")
    
    -- Connect to the Rust backend
    local success, err = M._rpc_client:connect()
    if not success then
        vim.notify("Failed to connect to Paragonic backend: " .. (err or "unknown error"), vim.log.levels.ERROR)
        M._rpc_client = nil
        return
    end
    
    -- Test connection with hello call
    local response = M._rpc_client:hello()
    if not response then
        vim.notify("Failed to communicate with Paragonic backend", vim.log.levels.ERROR)
        M._rpc_client:disconnect()
        M._rpc_client = nil
        return
    end
    
    vim.notify("Paragonic backend connected successfully", vim.log.levels.INFO)
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
        
        -- Get available models for display
        local models_info = "Available models: llama2 (default)"
        local models_response = M.get_available_models()
        if models_response then
            -- Display actual models from parsed response
            local model_names = {}
            for _, model in ipairs(models_response) do
                table.insert(model_names, model.name)
            end
            if #model_names > 0 then
                models_info = "Available models: " .. table.concat(model_names, ", ")
            else
                models_info = "Available models: llama2 (default) - check backend for full list"
            end
        end
        
        -- Add initial content with model information
        vim.api.nvim_buf_set_lines(chat_buf, 0, -1, false, {
            "# Paragonic Chat",
            "",
            models_info,
            "",
            "Type your message below and use :ParagonicSend to send:",
            "",
            "---"
        })
        
        -- Set filetype for syntax highlighting
        vim.api.nvim_buf_set_option(chat_buf, "filetype", "markdown")
        
        -- Set up buffer-local commands
        vim.api.nvim_buf_set_keymap(chat_buf, "n", "<CR>", ":ParagonicSend<CR>", {noremap = true, silent = true})
    end
    
    -- Open the buffer in a new window
    vim.api.nvim_command("split")
    vim.api.nvim_set_current_buf(chat_buf)
end

-- Open projects interface
function M.open_projects()
    -- Check if projects buffer already exists
    local projects_buf = nil
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(buf)
        if name == "paragonic://projects" then
            projects_buf = buf
            break
        end
    end
    
    -- Create new buffer if it doesn't exist
    if not projects_buf then
        projects_buf = vim.api.nvim_create_buf(true, true)
        
        -- Set buffer name
        vim.api.nvim_buf_set_name(projects_buf, "paragonic://projects")
        
        -- Set buffer options
        vim.api.nvim_buf_set_option(projects_buf, "buftype", "nofile")
        vim.api.nvim_buf_set_option(projects_buf, "swapfile", false)
        vim.api.nvim_buf_set_option(projects_buf, "modifiable", true)
        
        -- Get projects from backend
        local projects_content = {
            "# Paragonic Projects",
            "",
            "Loading projects..."
        }
        
        local projects_response = M.get_projects()
        if projects_response then
            -- Display actual projects from parsed response
            projects_content = {
                "# Paragonic Projects",
                "",
                "Projects loaded from backend:",
                ""
            }
            
            for _, project in ipairs(projects_response) do
                table.insert(projects_content, "## " .. project.name)
                if project.description and project.description ~= "" then
                    table.insert(projects_content, project.description)
                end
                table.insert(projects_content, "")
            end
            
            table.insert(projects_content, "---")
        else
            projects_content = {
                "# Paragonic Projects",
                "",
                "No projects found or backend unavailable.",
                "",
                "Use :ParagonicCreateProject to create a new project.",
                "",
                "---"
            }
        end
        
        -- Add content to buffer
        vim.api.nvim_buf_set_lines(projects_buf, 0, -1, false, projects_content)
        
        -- Set filetype for syntax highlighting
        vim.api.nvim_buf_set_option(projects_buf, "filetype", "markdown")
        
        -- Set up buffer-local commands
        vim.api.nvim_buf_set_keymap(projects_buf, "n", "<CR>", ":ParagonicCreateProject<CR>", {noremap = true, silent = true})
    end
    
    -- Open the buffer in a new window
    vim.api.nvim_command("split")
    vim.api.nvim_set_current_buf(projects_buf)
end

-- Open configuration
function M.open_config()
    -- Check if config buffer already exists
    local config_buf = nil
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(buf)
        if name == "paragonic://config" then
            config_buf = buf
            break
        end
    end
    
    -- Create new buffer if it doesn't exist
    if not config_buf then
        config_buf = vim.api.nvim_create_buf(true, true)
        
        -- Set buffer name
        vim.api.nvim_buf_set_name(config_buf, "paragonic://config")
        
        -- Set buffer options
        vim.api.nvim_buf_set_option(config_buf, "buftype", "nofile")
        vim.api.nvim_buf_set_option(config_buf, "swapfile", false)
        vim.api.nvim_buf_set_option(config_buf, "modifiable", true)
        
        -- Load configuration from backend
        local config_content = {
            "# Paragonic Configuration",
            "",
            "Loading configuration..."
        }
        
        local config_response = M.get_config()
        if config_response then
            -- Display actual configuration from parsed response
            config_content = {
                "# Paragonic Configuration",
                "",
                "Current configuration loaded from backend:",
                "",
                "## Ollama Settings",
                "- Host: " .. (config_response.ollama_host or "127.0.0.1:11434"),
                "- Model: " .. (config_response.ollama_model or "llama2"),
                "",
                "## Database Settings", 
                "- Path: " .. (config_response.database_path or "/tmp/paragonic.db"),
                "",
                "## Logging Settings",
                "- Level: " .. (config_response.log_level or "info"),
                "",
                "---",
                "",
                "Edit the configuration above and use :ParagonicSaveConfig to save changes."
            }
        else
            config_content = {
                "# Paragonic Configuration",
                "",
                "Configuration not available or backend unavailable.",
                "",
                "Use :ParagonicSaveConfig to save configuration changes.",
                "",
                "---"
            }
        end
        
        -- Add content to buffer
        vim.api.nvim_buf_set_lines(config_buf, 0, -1, false, config_content)
        
        -- Set filetype for syntax highlighting
        vim.api.nvim_buf_set_option(config_buf, "filetype", "markdown")
        
        -- Set up buffer-local commands
        vim.api.nvim_buf_set_keymap(config_buf, "n", "<CR>", ":ParagonicSaveConfig<CR>", {noremap = true, silent = true})
    end
    
    -- Open the buffer in a new window
    vim.api.nvim_command("split")
    vim.api.nvim_set_current_buf(config_buf)
end

-- Update configuration
function M.update_config(new_config)
    config = vim.tbl_deep_extend("force", config, new_config)
end

-- Send message command
function M.send_message_command()
    local current_buf = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(current_buf)
    
    -- Only work in chat buffer
    if buf_name ~= "paragonic://chat" then
        vim.notify("This command only works in the chat buffer", vim.log.levels.WARN)
        return
    end
    
    -- Get the current line as the message
    local line_num = vim.api.nvim_win_get_cursor(0)[1] - 1  -- 0-indexed
    local lines = vim.api.nvim_buf_get_lines(current_buf, line_num, line_num + 1, false)
    local message = lines[1] or ""
    
    -- Skip empty lines or lines that start with #
    if message == "" or message:match("^%s*#") then
        vim.notify("Please enter a message to send", vim.log.levels.INFO)
        return
    end
    
    -- Send the message
    local response, err = M.send_message(message, "llama2")
    if not response then
        vim.notify("Failed to send message: " .. (err or "unknown error"), vim.log.levels.ERROR)
        return
    end
    
    -- Add the response to the buffer
    local response_lines = {
        "",
        "**AI Response:**",
        response,
        "",
        "---"
    }
    
    -- Insert response after the current line
    vim.api.nvim_buf_set_lines(current_buf, line_num + 1, line_num + 1, false, response_lines)
    
    -- Move cursor to end of response
    vim.api.nvim_win_set_cursor(0, {line_num + #response_lines + 1, 0})
end

-- Create project command
function M.create_project_command()
    local current_buf = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(current_buf)
    
    -- Only work in projects buffer
    if buf_name ~= "paragonic://projects" then
        vim.notify("This command only works in the projects buffer", vim.log.levels.WARN)
        return
    end
    
    -- Get project name from user input
    local project_name = vim.fn.input("Project name: ")
    if project_name == "" then
        vim.notify("Project name cannot be empty", vim.log.levels.WARN)
        return
    end
    
    -- Get project description from user input
    local project_description = vim.fn.input("Project description: ")
    
    -- Create the project
    local response, err = M.create_project(project_name, project_description)
    if not response then
        vim.notify("Failed to create project: " .. (err or "unknown error"), vim.log.levels.ERROR)
        return
    end
    
    -- Add the new project to the buffer
    local project_lines = {
        "",
        "## " .. project_name,
        project_description ~= "" and project_description or "No description provided",
        "",
        "---"
    }
    
    -- Insert project at the end of the buffer
    local last_line = vim.api.nvim_buf_line_count(current_buf)
    vim.api.nvim_buf_set_lines(current_buf, last_line, last_line, false, project_lines)
    
    vim.notify("Project '" .. project_name .. "' created successfully", vim.log.levels.INFO)
end

-- Save configuration command
function M.save_config_command()
    local current_buf = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(current_buf)
    
    -- Only work in config buffer
    if buf_name ~= "paragonic://config" then
        vim.notify("This command only works in the config buffer", vim.log.levels.WARN)
        return
    end
    
    -- Get all lines from the buffer
    local lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
    
    -- Parse configuration from buffer content
    local config_data = {}
    
    for _, line in ipairs(lines) do
        -- Parse Ollama settings
        if line:match("^%- Host: (.+)$") then
            config_data.ollama_host = line:match("^%- Host: (.+)$")
        elseif line:match("^%- Model: (.+)$") then
            config_data.ollama_model = line:match("^%- Model: (.+)$")
        elseif line:match("^%- Path: (.+)$") then
            config_data.database_path = line:match("^%- Path: (.+)$")
        elseif line:match("^%- Level: (.+)$") then
            config_data.log_level = line:match("^%- Level: (.+)$")
        end
    end
    
    -- Save the configuration
    local response, err = M.save_config(config_data)
    if not response then
        vim.notify("Failed to save configuration: " .. (err or "unknown error"), vim.log.levels.ERROR)
        return
    end
    
    -- Add confirmation message to buffer
    local confirmation_lines = {
        "",
        "**Configuration saved successfully!**",
        "",
        "---"
    }
    
    -- Insert confirmation at the end of the buffer
    local last_line = vim.api.nvim_buf_line_count(current_buf)
    vim.api.nvim_buf_set_lines(current_buf, last_line, last_line, false, confirmation_lines)
    
    vim.notify("Configuration saved successfully", vim.log.levels.INFO)
end

return M 