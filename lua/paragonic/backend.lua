--[[
Paragonic Backend Module
Handles RPC client initialization and backend management
--]]

local M = {}

-- RPC client instance
M._rpc_client = nil

-- Get RPC client, initializing backend if needed
function M._get_rpc_client()
    if not M._rpc_client then
        -- Return nil immediately - let calling functions handle initialization
        -- This prevents freezing during buffer operations
        return nil
    end
    
    -- Check if the client is still connected and try to reconnect if needed
    if not M._rpc_client:is_connected() then
        local debug = require("paragonic.debug")
        debug.debug_print("🔧 RPC client disconnected, attempting reconnection...", "info")
        local success = M._rpc_client:reconnect()
        if not success then
            debug.debug_print("❌ Reconnection failed, returning nil", "error")
            return nil
        end
        debug.debug_print("✅ RPC client reconnected successfully", "success")
    end
    
    return M._rpc_client
end

-- Initialize Rust backend
function M._initialize_backend()
    local debug = require("paragonic.debug")
    debug.debug_print("🔧 _initialize_backend() called", "debug")
    
    -- Only initialize once
    if M._rpc_client then
        debug.debug_print("✅ RPC client already exists, returning true", "info")
        return true
    end
    
    debug.debug_print("🔧 Starting backend initialization...", "info")
    
    -- Create RPC client with timeout
    debug.debug_print("🔧 Step 1: About to require paragonic.rpc...", "debug")
    local success, rpc = pcall(require, "paragonic.rpc")
    if not success then
        debug.debug_print("❌ Failed to require paragonic.rpc: " .. tostring(rpc), "error")
        return false
    end
    debug.debug_print("✅ paragonic.rpc module loaded successfully", "success")
    
    debug.debug_print("🔧 Step 2: About to create RPC client with rpc.new()...", "debug")
    local success2, client = pcall(function() return rpc.new("127.0.0.1:3000") end)
    if not success2 then
        debug.debug_print("❌ Failed to create RPC client: " .. tostring(client), "error")
        return false
    end
    M._rpc_client = client
    debug.debug_print("✅ RPC client created successfully", "success")
    
    -- Set a timeout for the connection attempt
    local connection_timeout = 5000 -- 5 seconds
    local max_retries = 2
    local retry_count = 0
    
    debug.debug_print("🔧 Step 3: About to start connection attempts...", "debug")
    
    while retry_count <= max_retries do
        local start_time = vim.loop.hrtime() / 1000000
        
        debug.debug_print("🔧 Attempt " .. (retry_count + 1) .. "/" .. (max_retries + 1) .. ": About to call connect()...", "debug")
        
        -- Connect to the Rust backend with timeout
        debug.debug_print("🔧 Calling M._rpc_client:connect()...", "debug")
        local success, err = M._rpc_client:connect()
        debug.debug_print("✅ connect() call completed, success=" .. tostring(success), "debug")
        
        if not success then
            local end_time = vim.loop.hrtime() / 1000000
            local duration = end_time - start_time
            
            retry_count = retry_count + 1
            
            if duration > connection_timeout then
                debug.debug_print("❌ Connection timed out after " .. string.format("%.1f", duration) .. "ms (attempt " .. retry_count .. "/" .. (max_retries + 1) .. ")", "error")
            else
                debug.debug_print("❌ Connection failed: " .. (err or "unknown error") .. " (attempt " .. retry_count .. "/" .. (max_retries + 1) .. ")", "error")
            end
            
            if retry_count > max_retries then
                debug.debug_print("❌ Failed to connect after " .. (max_retries + 1) .. " attempts", "error")
                M._rpc_client = nil
                return false
            end
            
            -- Wait a bit before retrying
            debug.debug_print("⏳ Waiting 1 second before retry...", "info")
            vim.wait(1000)
        else
            debug.debug_print("✅ Connection successful!", "success")
            break
        end
    end
    
    -- Test connection with hello call (also with timeout)
    debug.debug_print("🔧 Step 4: About to test connection with hello call...", "debug")
    local hello_start = vim.loop.hrtime() / 1000000
    debug.debug_print("🔧 Calling M._rpc_client:hello()...", "debug")
    local response = M._rpc_client:hello()
    debug.debug_print("✅ hello() call completed, response=" .. tostring(response ~= nil), "debug")
    local hello_end = vim.loop.hrtime() / 1000000
    local hello_duration = hello_end - hello_start
    
    if not response then
        if hello_duration > connection_timeout then
            debug.debug_print("❌ Hello call timed out after " .. string.format("%.1f", hello_duration) .. "ms", "error")
        else
            debug.debug_print("❌ Hello call failed - no response", "error")
        end
        
        M._rpc_client:disconnect()
        M._rpc_client = nil
        return false
    end
    
    debug.debug_print("✅ Backend initialization completed successfully in " .. string.format("%.1f", hello_duration) .. "ms", "success")
    return true
end

-- Force reconnection to the backend (useful when server restarts)
function M.force_reconnect()
    local debug = require("paragonic.debug")
    debug.debug_print("🔧 force_reconnect() called", "debug")
    
    if not M._rpc_client then
        debug.debug_print("🔧 No RPC client exists, initializing backend...", "info")
        return M._initialize_backend()
    end
    
    debug.debug_print("🔧 Forcing reconnection of existing RPC client...", "info")
    
    -- Disconnect current client
    M._rpc_client:disconnect()
    
    -- Try to reconnect
    local success = M._rpc_client:reconnect()
    
    if success then
        debug.debug_print("✅ Force reconnection successful", "success")
        return true
    else
        debug.debug_print("❌ Force reconnection failed, reinitializing backend...", "error")
        
        -- If reconnection fails, reinitialize the entire backend
        M._rpc_client = nil
        return M._initialize_backend()
    end
end

-- Manually initialize backend when needed
function M.initialize_backend()
    if not M._rpc_client then
        M._initialize_backend()
    end
    return M._rpc_client ~= nil
end

-- Get list of available models
function M.get_available_models()
    local rpc_client = M._get_rpc_client()
    if not rpc_client then
        -- Return default models to prevent freezing
        return {"llama2", "llama3.2:3b", "nomic-embed-text:latest"}
    end
    
    -- Get models list with timeout
    local success, response = pcall(function()
        return rpc_client:list_models()
    end)
    
    if not success or not response then
        -- Return default models on failure
        return {"llama2", "llama3.2:3b", "nomic-embed-text:latest"}
    end
    
    -- Parse JSON response
    local utils = require("paragonic.utils")
    local parsed_response = utils.parse_json_response(response)
    if not parsed_response then
        return {"llama2", "llama3.2:3b", "nomic-embed-text:latest"}
    end
    
    -- Check for error in response
    if parsed_response.error then
        return {"llama2", "llama3.2:3b", "nomic-embed-text:latest"}
    end
    
    -- Extract models list
    if parsed_response.result and parsed_response.result.models then
        return parsed_response.result.models
    else
        return {"llama2", "llama3.2:3b", "nomic-embed-text:latest"}
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
    local utils = require("paragonic.utils")
    local parsed_response = utils.parse_json_response(response)
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
    
    -- Return the full JSON-RPC response as a string
    return response
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

return M
