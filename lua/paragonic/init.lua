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

-- Search history and saved searches
local search_history = {}
local saved_searches = {}
local max_history_size = 50

-- Persistent storage paths
local data_dir = vim.fn.stdpath("data") .. "/paragonic"
local history_file = data_dir .. "/search_history.json"
local saved_searches_file = data_dir .. "/saved_searches.json"

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
    
    -- Search commands
    vim.api.nvim_create_user_command("ParagonicSearch", M.search_command, {nargs = "*"})
    vim.api.nvim_create_user_command("ParagonicSearchFiltered", M.search_filtered_command, {nargs = "*"})
    vim.api.nvim_create_user_command("ParagonicSearchHybrid", M.search_hybrid_command, {nargs = "*"})
    
    -- Search history and saved searches commands
    vim.api.nvim_create_user_command("ParagonicSearchHistory", M.show_search_history, {})
    vim.api.nvim_create_user_command("ParagonicSavedSearches", M.show_saved_searches, {})
    vim.api.nvim_create_user_command("ParagonicSaveSearch", M.save_current_search, {})
    
    -- Persistent storage commands
    vim.api.nvim_create_user_command("ParagonicExportData", M.export_data, {})
    vim.api.nvim_create_user_command("ParagonicImportData", M.import_data, {})
    vim.api.nvim_create_user_command("ParagonicBackupData", M.backup_data, {})
    
    -- Initialize backend
    M._initialize_backend()
    
    -- Set up keyboard mappings
    M._setup_keymaps()
    
    -- Load persistent data
    M._load_persistent_data()
    
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
    
    -- Parse JSON with error handling using vim.json
    local success, result = pcall(vim.json.decode, json_string)
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

-- Search functionality
function M.search_embeddings(query, limit)
    local rpc_client = M._get_rpc_client()
    if not rpc_client then
        return nil, "Backend not available"
    end
    
    -- Use default limit if not specified
    limit = limit or 10
    
    -- Perform search
    local response = rpc_client:search_embeddings(query, limit)
    if not response then
        return nil, "Failed to perform search"
    end
    
    return response
end

function M.find_similar_content(query, content_type, limit, threshold)
    local rpc_client = M._get_rpc_client()
    if not rpc_client then
        return nil, "Backend not available"
    end
    
    -- Use default values if not specified
    limit = limit or 10
    threshold = threshold or 0.0
    
    -- Perform filtered search
    local response = rpc_client:find_similar_content(query, content_type, limit, threshold)
    if not response then
        return nil, "Failed to perform filtered search"
    end
    
    return response
end

function M.hybrid_search(query, content_type, limit, threshold, include_text_filtering)
    local rpc_client = M._get_rpc_client()
    if not rpc_client then
        return nil, "Backend not available"
    end
    
    -- Use default values if not specified
    limit = limit or 10
    threshold = threshold or 0.0
    include_text_filtering = include_text_filtering ~= false -- Default to true
    
    -- Perform hybrid search
    local response = rpc_client:hybrid_search(query, content_type, limit, threshold, include_text_filtering)
    if not response then
        return nil, "Failed to perform hybrid search"
    end
    
    return response
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
    local results, err = M.search_embeddings(query, limit)
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
    local results, err = M.find_similar_content(query, content_type ~= "" and content_type or nil, limit, threshold)
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
    local results, err = M.hybrid_search(query, content_type ~= "" and content_type or nil, limit, threshold, include_text_filtering)
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
    
    -- Store results data in buffer for interaction
    vim.api.nvim_buf_set_var(buf, "paragonic_search_results", results)
    vim.api.nvim_buf_set_var(buf, "paragonic_search_title", title)
    
    -- Format results with better styling
    local lines = {
        "🔍 " .. title,
        string.rep("─", #title + 2),
        "",
        "📊 Found " .. (results.results and #results.results or 0) .. " results",
        ""
    }
    
    if results.results then
        for i, result in ipairs(results.results) do
            if result.embedding and result.embedding.content_text then
                local text = result.embedding.content_text
                if #text > 60 then
                    text = text:sub(1, 60) .. "..."
                end
                
                local score = result.similarity_score or 0
                local content_type = result.embedding.content_type or "unknown"
                
                -- Add emoji for content type
                local type_emoji = {
                    project = "📁",
                    task = "✅",
                    note = "📝",
                    code = "💻",
                    document = "📄"
                }
                local emoji = type_emoji[content_type] or "📄"
                
                -- Color-coded score
                local score_color = ""
                if score >= 0.8 then
                    score_color = "🟢"
                elseif score >= 0.6 then
                    score_color = "🟡"
                else
                    score_color = "🔴"
                end
                
                table.insert(lines, string.format("%d. %s [%s] %s(%.3f) %s", 
                    i, emoji, content_type, score_color, score, text))
            end
        end
    end
    
    if #lines == 4 then -- Only title and "Found 0 results"
        table.insert(lines, "❌ No results found")
        table.insert(lines, "")
        table.insert(lines, "💡 Try:")
        table.insert(lines, "   • Different keywords")
        table.insert(lines, "   • Lower similarity threshold")
        table.insert(lines, "   • Different content type")
    end
    
    -- Add footer with enhanced help
    table.insert(lines, "")
    table.insert(lines, string.rep("─", width - 2))
    table.insert(lines, "⌨️  Navigation: j/k to move, <CR> to select, q to close")
    
    -- Set buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "swapfile", false)
    vim.api.nvim_buf_set_option(buf, "filetype", "paragonic-search")
    
    -- Create window with enhanced styling
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = " Paragonic Search ",
        title_pos = "center"
    })
    
    -- Set up enhanced keymaps
    vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "<cmd>close<CR>", {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", function()
        M.select_search_result(buf)
    end, {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "j", "j", {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "k", "k", {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "gg", "gg", {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "G", "G", {noremap = true, silent = true})
    
    -- Set cursor to first result line
    local first_result_line = 5 -- After header
    if results.results and #results.results > 0 then
        vim.api.nvim_win_set_cursor(win, {first_result_line, 0})
    else
        vim.api.nvim_win_set_cursor(win, {1, 0})
    end
end

-- Handle search result selection
function M.select_search_result(buf)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor_pos[1]
    
    -- Get the results data
    local success, results = pcall(vim.api.nvim_buf_get_var, buf, "paragonic_search_results")
    if not success or not results or not results.results then
        vim.notify("No search results available", vim.log.levels.WARN)
        return
    end
    
    -- Calculate which result was selected (accounting for header lines)
    local result_index = line_num - 4 -- Subtract header lines
    if result_index >= 1 and result_index <= #results.results then
        local selected_result = results.results[result_index]
        
        -- Display detailed information about the selected result
        M.show_result_details(selected_result)
    else
        vim.notify("Invalid selection", vim.log.levels.WARN)
    end
end

-- Show detailed information about a search result
function M.show_result_details(result)
    if not result or not result.embedding then
        vim.notify("Invalid result data", vim.log.levels.ERROR)
        return
    end
    
    -- Create a new buffer for detailed view
    local detail_buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(detail_buf, "paragonic://result-details")
    
    -- Format detailed information
    local lines = {
        "📋 Search Result Details",
        string.rep("─", 25),
        "",
        "📄 Content Type: " .. (result.embedding.content_type or "unknown"),
        "🎯 Similarity Score: " .. string.format("%.3f", result.similarity_score or 0),
        "🆔 Content ID: " .. (result.embedding.content_id or "unknown"),
        "",
        "📝 Content:",
        string.rep("─", 10),
        result.embedding.content_text or "No content available",
        "",
        "📅 Created: " .. (result.embedding.created_at or "unknown"),
        "🔄 Updated: " .. (result.embedding.updated_at or "unknown"),
        "",
        string.rep("─", 50),
        "Press q to close"
    }
    
    -- Set buffer content
    vim.api.nvim_buf_set_lines(detail_buf, 0, -1, false, lines)
    
    -- Set buffer options
    vim.api.nvim_buf_set_option(detail_buf, "modifiable", false)
    vim.api.nvim_buf_set_option(detail_buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(detail_buf, "swapfile", false)
    vim.api.nvim_buf_set_option(detail_buf, "filetype", "markdown")
    
    -- Create window
    local width = math.min(70, vim.o.columns - 4)
    local height = math.min(20, vim.o.lines - 4)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    
    local detail_win = vim.api.nvim_open_win(detail_buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = " Result Details ",
        title_pos = "center"
    })
    
    -- Set up keymaps
    vim.api.nvim_buf_set_keymap(detail_buf, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(detail_buf, "n", "<Esc>", "<cmd>close<CR>", {noremap = true, silent = true})
    
    -- Set cursor to first line
    vim.api.nvim_win_set_cursor(detail_win, {1, 0})
end

-- Set up keyboard mappings
function M._setup_keymaps()
    -- Search keymaps (leader + ps for "paragonic search")
    vim.keymap.set("n", "<leader>ps", "<cmd>ParagonicSearch<CR>", {desc = "Paragonic: Basic Search"})
    vim.keymap.set("n", "<leader>pf", "<cmd>ParagonicSearchFiltered<CR>", {desc = "Paragonic: Filtered Search"})
    vim.keymap.set("n", "<leader>ph", "<cmd>ParagonicSearchHybrid<CR>", {desc = "Paragonic: Hybrid Search"})
    
    -- Quick search with visual selection
    vim.keymap.set("v", "<leader>ps", function()
        local saved_reg = vim.fn.getreg('"')
        vim.cmd('normal! y')
        local selected_text = vim.fn.getreg('"')
        vim.fn.setreg('"', saved_reg)
        
        if selected_text and selected_text ~= "" then
            vim.cmd('ParagonicSearch ' .. vim.fn.shellescape(selected_text))
        else
            vim.cmd('ParagonicSearch')
        end
    end, {desc = "Paragonic: Search Selected Text"})
    
    -- Quick filtered search with visual selection
    vim.keymap.set("v", "<leader>pf", function()
        local saved_reg = vim.fn.getreg('"')
        vim.cmd('normal! y')
        local selected_text = vim.fn.getreg('"')
        vim.fn.setreg('"', saved_reg)
        
        if selected_text and selected_text ~= "" then
            vim.cmd('ParagonicSearchFiltered ' .. vim.fn.shellescape(selected_text))
        else
            vim.cmd('ParagonicSearchFiltered')
        end
    end, {desc = "Paragonic: Filtered Search Selected Text"})
    
    -- Quick hybrid search with visual selection
    vim.keymap.set("v", "<leader>ph", function()
        local saved_reg = vim.fn.getreg('"')
        vim.cmd('normal! y')
        local selected_text = vim.fn.getreg('"')
        vim.fn.setreg('"', saved_reg)
        
        if selected_text and selected_text ~= "" then
            vim.cmd('ParagonicSearchHybrid ' .. vim.fn.shellescape(selected_text))
        else
            vim.cmd('ParagonicSearchHybrid')
        end
        end, {desc = "Paragonic: Hybrid Search Selected Text"})
    
    -- Search history and saved searches keymaps
    vim.keymap.set("n", "<leader>ph", "<cmd>ParagonicSearchHistory<CR>", {desc = "Paragonic: Show Search History"})
    vim.keymap.set("n", "<leader>ps", "<cmd>ParagonicSavedSearches<CR>", {desc = "Paragonic: Show Saved Searches"})
    vim.keymap.set("n", "<leader>ps", "<cmd>ParagonicSaveSearch<CR>", {desc = "Paragonic: Save Current Search"})
end

-- Enhanced search command with better UX
function M.quick_search()
    local query = vim.fn.input("🔍 Search: ")
    if query == "" then
        return
    end
    
    -- Perform search
    local results, err = M.search_embeddings(query, 10)
    if not results then
        vim.notify("Search failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
        return
    end
    
    -- Add to search history
    M.add_to_search_history(query, "basic", results.results and #results.results or 0)
    
    -- Display results in a floating window
    M.display_search_results(results, "Quick Search: " .. query)
end

-- Enhanced filtered search with content type selection
function M.quick_filtered_search()
    local query = vim.fn.input("🔍 Search: ")
    if query == "" then
        return
    end
    
    -- Content type selection
    local content_types = {"project", "task", "note", "code", "document"}
    local content_type = vim.fn.input("📁 Content Type (project/task/note/code/document): ")
    
    -- Perform filtered search
    local results, err = M.find_similar_content(query, content_type ~= "" and content_type or nil, 10, 0.0)
    if not results then
        vim.notify("Filtered search failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
        return
    end
    
    -- Add to search history
    M.add_to_search_history(query, "filtered", results.results and #results.results or 0)
    
    -- Display results in a floating window
    M.display_search_results(results, "Filtered Search: " .. query)
end

-- Enhanced hybrid search with options
function M.quick_hybrid_search()
    local query = vim.fn.input("🔍 Search: ")
    if query == "" then
        return
    end
    
    local content_type = vim.fn.input("📁 Content Type (optional): ")
    local include_text_filtering = vim.fn.input("🔤 Include text filtering? (y/n, default y): "):lower() ~= "n"
    
    -- Perform hybrid search
    local results, err = M.hybrid_search(query, content_type ~= "" and content_type or nil, 10, 0.0, include_text_filtering)
    if not results then
        vim.notify("Hybrid search failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
        return
    end
    
    -- Add to search history
    M.add_to_search_history(query, "hybrid", results.results and #results.results or 0)
    
    -- Display results in a floating window
    M.display_search_results(results, "Hybrid Search: " .. query)
end

-- Search history and saved searches functionality

-- Add search to history
function M.add_to_search_history(query, search_type, results_count, timestamp)
    timestamp = timestamp or os.time()
    
    local history_entry = {
        query = query,
        type = search_type,
        results_count = results_count,
        timestamp = timestamp,
        date = os.date("%Y-%m-%d %H:%M:%S", timestamp)
    }
    
    -- Add to beginning of history
    table.insert(search_history, 1, history_entry)
    
    -- Keep history size manageable
    if #search_history > max_history_size then
        table.remove(search_history, #search_history)
    end
    
    -- Auto-save to disk
    M._save_search_history()
end

-- Get search history
function M.get_search_history()
    return search_history
end

-- Clear search history
function M.clear_search_history()
    search_history = {}
    
    -- Auto-save to disk
    M._save_search_history()
    
    vim.notify("Search history cleared", vim.log.levels.INFO)
end

-- Save a search
function M.save_search(name, query, search_type, content_type, limit, threshold)
    if not name or name == "" then
        vim.notify("Search name is required", vim.log.levels.WARN)
        return false
    end
    
    -- Check if name already exists
    for _, saved in ipairs(saved_searches) do
        if saved.name == name then
            vim.notify("A saved search with this name already exists", vim.log.levels.WARN)
            return false
        end
    end
    
    local saved_search = {
        name = name,
        query = query,
        type = search_type,
        content_type = content_type,
        limit = limit or 10,
        threshold = threshold or 0.0,
        created_at = os.time(),
        created_date = os.date("%Y-%m-%d %H:%M:%S")
    }
    
    table.insert(saved_searches, saved_search)
    
    -- Auto-save to disk
    M._save_saved_searches()
    
    vim.notify("Search '" .. name .. "' saved successfully", vim.log.levels.INFO)
    return true
end

-- Get saved searches
function M.get_saved_searches()
    return saved_searches
end

-- Delete a saved search
function M.delete_saved_search(name)
    for i, saved in ipairs(saved_searches) do
        if saved.name == name then
                    table.remove(saved_searches, i)
        
        -- Auto-save to disk
        M._save_saved_searches()
        
        vim.notify("Saved search '" .. name .. "' deleted", vim.log.levels.INFO)
        return true
        end
    end
    vim.notify("Saved search '" .. name .. "' not found", vim.log.levels.WARN)
    return false
end

-- Execute a saved search
function M.execute_saved_search(name)
    for _, saved in ipairs(saved_searches) do
        if saved.name == name then
            local results, err
            
            if saved.type == "basic" then
                results, err = M.search_embeddings(saved.query, saved.limit)
            elseif saved.type == "filtered" then
                results, err = M.find_similar_content(saved.query, saved.content_type, saved.limit, saved.threshold)
            elseif saved.type == "hybrid" then
                results, err = M.hybrid_search(saved.query, saved.content_type, saved.limit, saved.threshold, true)
            end
            
            if results then
                -- Add to history
                M.add_to_search_history(saved.query, saved.type, results.results and #results.results or 0)
                
                -- Display results
                M.display_search_results(results, "Saved Search: " .. saved.name)
                return true
            else
                vim.notify("Failed to execute saved search: " .. (err or "unknown error"), vim.log.levels.ERROR)
                return false
            end
        end
    end
    
    vim.notify("Saved search '" .. name .. "' not found", vim.log.levels.WARN)
    return false
end

-- Show search history
function M.show_search_history()
    if #search_history == 0 then
        vim.notify("No search history available", vim.log.levels.INFO)
        return
    end
    
    -- Create buffer for history
    local buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(buf, "paragonic://search-history")
    
    -- Format history
    local lines = {
        "📚 Search History",
        string.rep("─", 15),
        "",
        "Recent searches:",
        ""
    }
    
    for i, entry in ipairs(search_history) do
        local type_emoji = {
            basic = "🔍",
            filtered = "📁",
            hybrid = "🔗"
        }
        local emoji = type_emoji[entry.type] or "🔍"
        
        table.insert(lines, string.format("%d. %s %s (%d results) - %s", 
            i, emoji, entry.query, entry.results_count, entry.date))
    end
    
    -- Add footer
    table.insert(lines, "")
    table.insert(lines, string.rep("─", 50))
    table.insert(lines, "⌨️  Navigation: j/k to move, <CR> to repeat, d to delete, q to close")
    
    -- Set buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "swapfile", false)
    vim.api.nvim_buf_set_option(buf, "filetype", "paragonic-history")
    
    -- Create window
    local width = math.min(80, vim.o.columns - 4)
    local height = math.min(20, vim.o.lines - 4)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = " Search History ",
        title_pos = "center"
    })
    
    -- Set up keymaps
    vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "<cmd>close<CR>", {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", function()
        M.repeat_search_from_history(buf)
    end, {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "d", function()
        M.delete_from_search_history(buf)
    end, {noremap = true, silent = true})
    
    -- Set cursor to first entry
    vim.api.nvim_win_set_cursor(win, {5, 0})
end

-- Show saved searches
function M.show_saved_searches()
    if #saved_searches == 0 then
        vim.notify("No saved searches available", vim.log.levels.INFO)
        return
    end
    
    -- Create buffer for saved searches
    local buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(buf, "paragonic://saved-searches")
    
    -- Format saved searches
    local lines = {
        "💾 Saved Searches",
        string.rep("─", 17),
        "",
        "Your saved searches:",
        ""
    }
    
    for i, saved in ipairs(saved_searches) do
        local type_emoji = {
            basic = "🔍",
            filtered = "📁",
            hybrid = "🔗"
        }
        local emoji = type_emoji[saved.type] or "🔍"
        
        table.insert(lines, string.format("%d. %s %s (%s)", 
            i, emoji, saved.name, saved.query))
        table.insert(lines, string.format("   Type: %s, Limit: %d, Created: %s", 
            saved.type, saved.limit, saved.created_date))
        table.insert(lines, "")
    end
    
    -- Add footer
    table.insert(lines, string.rep("─", 50))
    table.insert(lines, "⌨️  Navigation: j/k to move, <CR> to execute, d to delete, q to close")
    
    -- Set buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "swapfile", false)
    vim.api.nvim_buf_set_option(buf, "filetype", "paragonic-saved")
    
    -- Create window
    local width = math.min(80, vim.o.columns - 4)
    local height = math.min(20, vim.o.lines - 4)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = " Saved Searches ",
        title_pos = "center"
    })
    
    -- Set up keymaps
    vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "<cmd>close<CR>", {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", function()
        M.execute_saved_search_from_list(buf)
    end, {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "d", function()
        M.delete_saved_search_from_list(buf)
    end, {noremap = true, silent = true})
    
    -- Set cursor to first entry
    vim.api.nvim_win_set_cursor(win, {5, 0})
end

-- Repeat search from history
function M.repeat_search_from_history(buf)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor_pos[1]
    
    -- Calculate which entry was selected (accounting for header lines)
    local entry_index = line_num - 4 -- Subtract header lines
    if entry_index >= 1 and entry_index <= #search_history then
        local entry = search_history[entry_index]
        
        -- Execute the search
        local results, err
        if entry.type == "basic" then
            results, err = M.search_embeddings(entry.query, 10)
        elseif entry.type == "filtered" then
            results, err = M.find_similar_content(entry.query, nil, 10, 0.0)
        elseif entry.type == "hybrid" then
            results, err = M.hybrid_search(entry.query, nil, 10, 0.0, true)
        end
        
        if results then
            -- Add to history again
            M.add_to_search_history(entry.query, entry.type, results.results and #results.results or 0)
            
            -- Display results
            M.display_search_results(results, "History Search: " .. entry.query)
        else
            vim.notify("Failed to repeat search: " .. (err or "unknown error"), vim.log.levels.ERROR)
        end
    else
        vim.notify("Invalid selection", vim.log.levels.WARN)
    end
end

-- Delete from search history
function M.delete_from_search_history(buf)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor_pos[1]
    
    -- Calculate which entry was selected (accounting for header lines)
    local entry_index = line_num - 4 -- Subtract header lines
    if entry_index >= 1 and entry_index <= #search_history then
        local entry = search_history[entry_index]
        table.remove(search_history, entry_index)
        
        -- Refresh the display
        vim.api.nvim_command("close")
        M.show_search_history()
    else
        vim.notify("Invalid selection", vim.log.levels.WARN)
    end
end

-- Execute saved search from list
function M.execute_saved_search_from_list(buf)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor_pos[1]
    
    -- Calculate which entry was selected (accounting for header lines)
    local entry_index = math.floor((line_num - 4) / 3) + 1 -- Each entry takes 3 lines
    if entry_index >= 1 and entry_index <= #saved_searches then
        local saved = saved_searches[entry_index]
        M.execute_saved_search(saved.name)
    else
        vim.notify("Invalid selection", vim.log.levels.WARN)
    end
end

-- Delete saved search from list
function M.delete_saved_search_from_list(buf)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor_pos[1]
    
    -- Calculate which entry was selected (accounting for header lines)
    local entry_index = math.floor((line_num - 4) / 3) + 1 -- Each entry takes 3 lines
    if entry_index >= 1 and entry_index <= #saved_searches then
        local saved = saved_searches[entry_index]
        M.delete_saved_search(saved.name)
        
        -- Refresh the display
        vim.api.nvim_command("close")
        M.show_saved_searches()
    else
        vim.notify("Invalid selection", vim.log.levels.WARN)
    end
end

-- Save current search
function M.save_current_search()
    local name = vim.fn.input("💾 Save search as: ")
    if name == "" then
        vim.notify("Search name is required", vim.log.levels.WARN)
        return
    end
    
    -- For now, save the last search from history
    if #search_history > 0 then
        local last_search = search_history[1]
        M.save_search(name, last_search.query, last_search.type, nil, 10, 0.0)
    else
        vim.notify("No recent searches to save", vim.log.levels.WARN)
    end
end

-- Persistent storage functionality

-- Ensure data directory exists
function M._ensure_data_directory()
    local dir = vim.fn.stdpath("data") .. "/paragonic"
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
    end
end

-- Save data to JSON file
function M._save_to_json(data, file_path)
    M._ensure_data_directory()
    
    local json_string = vim.json.encode(data)
    if not json_string then
        vim.notify("Failed to encode data to JSON", vim.log.levels.ERROR)
        return false
    end
    
    local success = pcall(vim.fn.writefile, {json_string}, file_path)
    if not success then
        vim.notify("Failed to write data to " .. file_path, vim.log.levels.ERROR)
        return false
    end
    
    return true
end

-- Load data from JSON file
function M._load_from_json(file_path)
    if vim.fn.filereadable(file_path) == 0 then
        return {}
    end
    
    local lines = vim.fn.readfile(file_path)
    if #lines == 0 then
        return {}
    end
    
    local json_string = table.concat(lines, "\n")
    local success, data = pcall(vim.json.decode, json_string)
    
    if not success or not data then
        vim.notify("Failed to parse JSON from " .. file_path, vim.log.levels.ERROR)
        return {}
    end
    
    return data
end

-- Save search history to disk
function M._save_search_history()
    return M._save_to_json(search_history, history_file)
end

-- Load search history from disk
function M._load_search_history()
    local data = M._load_from_json(history_file)
    
    -- Validate and clean data
    local cleaned_data = {}
    for _, entry in ipairs(data) do
        if entry.query and entry.type and entry.results_count then
            -- Ensure all required fields are present
            entry.timestamp = entry.timestamp or os.time()
            entry.date = entry.date or os.date("%Y-%m-%d %H:%M:%S", entry.timestamp)
            table.insert(cleaned_data, entry)
        end
    end
    
    return cleaned_data
end

-- Save saved searches to disk
function M._save_saved_searches()
    return M._save_to_json(saved_searches, saved_searches_file)
end

-- Load saved searches from disk
function M._load_saved_searches()
    local data = M._load_from_json(saved_searches_file)
    
    -- Validate and clean data
    local cleaned_data = {}
    for _, saved in ipairs(data) do
        if saved.name and saved.query and saved.type then
            -- Ensure all required fields are present
            saved.limit = saved.limit or 10
            saved.threshold = saved.threshold or 0.0
            saved.created_at = saved.created_at or os.time()
            saved.created_date = saved.created_date or os.date("%Y-%m-%d %H:%M:%S", saved.created_at)
            table.insert(cleaned_data, saved)
        end
    end
    
    return cleaned_data
end

-- Load all persistent data
function M._load_persistent_data()
    search_history = M._load_search_history()
    saved_searches = M._load_saved_searches()
    
    vim.notify("Loaded " .. #search_history .. " history entries and " .. #saved_searches .. " saved searches", vim.log.levels.INFO)
end

-- Auto-save function
function M._auto_save()
    M._save_search_history()
    M._save_saved_searches()
end

-- Export data to a file
function M.export_data()
    local export_path = vim.fn.input("Export to file: ")
    if export_path == "" then
        vim.notify("Export path is required", vim.log.levels.WARN)
        return
    end
    
    local export_data = {
        search_history = search_history,
        saved_searches = saved_searches,
        export_date = os.date("%Y-%m-%d %H:%M:%S"),
        version = "1.0"
    }
    
    local success = M._save_to_json(export_data, export_path)
    if success then
        vim.notify("Data exported successfully to " .. export_path, vim.log.levels.INFO)
    else
        vim.notify("Failed to export data", vim.log.levels.ERROR)
    end
end

-- Import data from a file
function M.import_data()
    local import_path = vim.fn.input("Import from file: ")
    if import_path == "" then
        vim.notify("Import path is required", vim.log.levels.WARN)
        return
    end
    
    if vim.fn.filereadable(import_path) == 0 then
        vim.notify("Import file does not exist", vim.log.levels.ERROR)
        return
    end
    
    local import_data = M._load_from_json(import_path)
    if not import_data or not import_data.search_history or not import_data.saved_searches then
        vim.notify("Invalid import file format", vim.log.levels.ERROR)
        return
    end
    
    -- Validate and merge data
    local imported_history = 0
    local imported_saved = 0
    
    -- Import search history
    for _, entry in ipairs(import_data.search_history) do
        if entry.query and entry.type and entry.results_count then
            table.insert(search_history, entry)
            imported_history = imported_history + 1
        end
    end
    
    -- Import saved searches
    for _, saved in ipairs(import_data.saved_searches) do
        if saved.name and saved.query and saved.type then
            -- Check for duplicates
            local exists = false
            for _, existing in ipairs(saved_searches) do
                if existing.name == saved.name then
                    exists = true
                    break
                end
            end
            
            if not exists then
                table.insert(saved_searches, saved)
                imported_saved = imported_saved + 1
            end
        end
    end
    
    -- Save to disk
    M._auto_save()
    
    vim.notify(string.format("Imported %d history entries and %d saved searches", imported_history, imported_saved), vim.log.levels.INFO)
end

-- Backup data
function M.backup_data()
    local backup_dir = vim.fn.stdpath("data") .. "/paragonic/backups"
    if vim.fn.isdirectory(backup_dir) == 0 then
        vim.fn.mkdir(backup_dir, "p")
    end
    
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local backup_path = backup_dir .. "/backup_" .. timestamp .. ".json"
    
    local backup_data = {
        search_history = search_history,
        saved_searches = saved_searches,
        backup_date = os.date("%Y-%m-%d %H:%M:%S"),
        version = "1.0"
    }
    
    local success = M._save_to_json(backup_data, backup_path)
    if success then
        vim.notify("Backup created successfully: " .. backup_path, vim.log.levels.INFO)
    else
        vim.notify("Failed to create backup", vim.log.levels.ERROR)
    end
end

return M 