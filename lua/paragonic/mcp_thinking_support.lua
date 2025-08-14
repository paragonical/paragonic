--[[
Paragonic MCP Thinking Model Support
Handles AI thinking model capabilities through MCP protocol
--]]

local M = {}

-- MCP thinking model state
M.thinking_state = {
    active_completions = {},
    active_sampling = {},
    active_elicitations = {},
    next_completion_id = 1,
    next_sampling_id = 1,
    next_elicitation_id = 1,
}

-- Initialize thinking model support
function M.initialize_thinking_support()
    M.thinking_state = {
        active_completions = {},
        active_sampling = {},
        active_elicitations = {},
        next_completion_id = 1,
        next_sampling_id = 1,
        next_elicitation_id = 1,
    }
    
    vim.notify("MCP thinking model support initialized", vim.log.levels.INFO)
    return true
end

-- Generate unique ID for operations
function M.generate_operation_id(operation_type)
    local timestamp = os.time()
    local random_suffix = math.random(1000, 9999)
    return string.format("%s-%d-%d", operation_type, timestamp, random_suffix)
end

-- Handle MCP completion/complete requests
function M.handle_completion_complete(prompt, model, options)
    local mcp_http_transport = require("paragonic.mcp_http_transport")
    
    if not mcp_http_transport.is_ready() then
        return nil, "MCP transport not ready"
    end
    
    local completion_id = M.generate_operation_id("completion")
    
    -- Register completion operation
    M.thinking_state.active_completions[completion_id] = {
        prompt = prompt,
        model = model or "deepseek-r1:1.5b",
        options = options or {},
        start_time = os.time(),
        status = "pending",
    }
    
    -- Prepare completion request
    local request = {
        jsonrpc = "2.0",
        id = completion_id,
        method = "completion/complete",
        params = {
            prompt = prompt,
            model = model or "deepseek-r1:1.5b",
            options = options or {},
        },
    }
    
    -- Send completion request
    local response, err = mcp_http_transport.send_request(request)
    if not response then
        M.thinking_state.active_completions[completion_id] = nil
        return nil, err or "Completion request failed"
    end
    
    -- Update completion status
    if response.result then
        M.thinking_state.active_completions[completion_id].status = "completed"
        M.thinking_state.active_completions[completion_id].result = response.result
        return response.result.completion, nil
    else
        M.thinking_state.active_completions[completion_id].status = "failed"
        M.thinking_state.active_completions[completion_id].error = response.error
        return nil, response.error and response.error.message or "Completion failed"
    end
end

-- Handle MCP sampling/createMessage requests
function M.handle_sampling_create_message(prompt, model, sampling_options)
    local mcp_http_transport = require("paragonic.mcp_http_transport")
    
    if not mcp_http_transport.is_ready() then
        return nil, "MCP transport not ready"
    end
    
    local sampling_id = M.generate_operation_id("sampling")
    
    -- Register sampling operation
    M.thinking_state.active_sampling[sampling_id] = {
        prompt = prompt,
        model = model or "deepseek-r1:1.5b",
        sampling_options = sampling_options or {},
        start_time = os.time(),
        status = "pending",
    }
    
    -- Prepare sampling request
    local request = {
        jsonrpc = "2.0",
        id = sampling_id,
        method = "sampling/createMessage",
        params = {
            prompt = prompt,
            model = model or "deepseek-r1:1.5b",
            sampling_options = sampling_options or {},
        },
    }
    
    -- Send sampling request
    local response, err = mcp_http_transport.send_request(request)
    if not response then
        M.thinking_state.active_sampling[sampling_id] = nil
        return nil, err or "Sampling request failed"
    end
    
    -- Update sampling status
    if response.result then
        M.thinking_state.active_sampling[sampling_id].status = "completed"
        M.thinking_state.active_sampling[sampling_id].result = response.result
        return response.result.message, nil
    else
        M.thinking_state.active_sampling[sampling_id].status = "failed"
        M.thinking_state.active_sampling[sampling_id].error = response.error
        return nil, response.error and response.error.message or "Sampling failed"
    end
end

-- Handle MCP elicitation/create requests
function M.handle_elicitation_create(prompt, elicitation_type)
    local mcp_http_transport = require("paragonic.mcp_http_transport")
    
    if not mcp_http_transport.is_ready() then
        return nil, "MCP transport not ready"
    end
    
    local elicitation_id = M.generate_operation_id("elicitation")
    
    -- Register elicitation operation
    M.thinking_state.active_elicitations[elicitation_id] = {
        prompt = prompt,
        type = elicitation_type or "user_input",
        start_time = os.time(),
        status = "pending",
    }
    
    -- Prepare elicitation request
    local request = {
        jsonrpc = "2.0",
        id = elicitation_id,
        method = "elicitation/create",
        params = {
            prompt = prompt,
            type = elicitation_type or "user_input",
        },
    }
    
    -- Send elicitation request
    local response, err = mcp_http_transport.send_request(request)
    if not response then
        M.thinking_state.active_elicitations[elicitation_id] = nil
        return nil, err or "Elicitation request failed"
    end
    
    -- Update elicitation status
    if response.result then
        M.thinking_state.active_elicitations[elicitation_id].status = "created"
        M.thinking_state.active_elicitations[elicitation_id].result = response.result
        return response.result.elicitation_id, nil
    else
        M.thinking_state.active_elicitations[elicitation_id].status = "failed"
        M.thinking_state.active_elicitations[elicitation_id].error = response.error
        return nil, response.error and response.error.message or "Elicitation failed"
    end
end

-- Handle MCP logging/setLevel requests
function M.handle_logging_set_level(level)
    local mcp_http_transport = require("paragonic.mcp_http_transport")
    
    if not mcp_http_transport.is_ready() then
        return nil, "MCP transport not ready"
    end
    
    -- Validate log level
    local valid_levels = { "debug", "info", "warn", "error" }
    local is_valid = false
    for _, valid_level in ipairs(valid_levels) do
        if level == valid_level then
            is_valid = true
            break
        end
    end
    
    if not is_valid then
        return nil, "Invalid log level. Must be one of: debug, info, warn, error"
    end
    
    -- Prepare logging request
    local request = {
        jsonrpc = "2.0",
        id = M.generate_operation_id("logging"),
        method = "logging/setLevel",
        params = {
            level = level,
        },
    }
    
    -- Send logging request
    local response, err = mcp_http_transport.send_request(request)
    if not response then
        return nil, err or "Logging request failed"
    end
    
    if response.result then
        return response.result, nil
    else
        return nil, response.error and response.error.message or "Logging failed"
    end
end

-- Handle MCP prompts/list requests
function M.handle_prompts_list()
    local mcp_http_transport = require("paragonic.mcp_http_transport")
    
    if not mcp_http_transport.is_ready() then
        return nil, "MCP transport not ready"
    end
    
    -- Prepare prompts list request
    local request = {
        jsonrpc = "2.0",
        id = M.generate_operation_id("prompts"),
        method = "prompts/list",
        params = {},
    }
    
    -- Send prompts list request
    local response, err = mcp_http_transport.send_request(request)
    if not response then
        return nil, err or "Prompts list request failed"
    end
    
    if response.result then
        return response.result.prompts, nil
    else
        return nil, response.error and response.error.message or "Prompts list failed"
    end
end

-- Handle MCP prompts/get requests
function M.handle_prompts_get(name)
    local mcp_http_transport = require("paragonic.mcp_http_transport")
    
    if not mcp_http_transport.is_ready() then
        return nil, "MCP transport not ready"
    end
    
    if not name or type(name) ~= "string" then
        return nil, "Prompt name is required"
    end
    
    -- Prepare prompt get request
    local request = {
        jsonrpc = "2.0",
        id = M.generate_operation_id("prompt"),
        method = "prompts/get",
        params = {
            name = name,
        },
    }
    
    -- Send prompt get request
    local response, err = mcp_http_transport.send_request(request)
    if not response then
        return nil, err or "Prompt get request failed"
    end
    
    if response.result then
        return response.result, nil
    else
        return nil, response.error and response.error.message or "Prompt get failed"
    end
end

-- Handle MCP roots/list requests
function M.handle_roots_list(uri, options)
    local mcp_http_transport = require("paragonic.mcp_http_transport")
    
    if not mcp_http_transport.is_ready() then
        return nil, "MCP transport not ready"
    end
    
    -- Prepare roots list request
    local request = {
        jsonrpc = "2.0",
        id = M.generate_operation_id("roots"),
        method = "roots/list",
        params = {
            uri = uri or "neovim://buffers",
            options = options or {},
        },
    }
    
    -- Send roots list request
    local response, err = mcp_http_transport.send_request(request)
    if not response then
        return nil, err or "Roots list request failed"
    end
    
    if response.result then
        return response.result.roots, nil
    else
        return nil, response.error and response.error.message or "Roots list failed"
    end
end

-- Get thinking model status
function M.get_thinking_status()
    return {
        active_completions = M.thinking_state.active_completions,
        active_sampling = M.thinking_state.active_sampling,
        active_elicitations = M.thinking_state.active_elicitations,
        total_operations = #M.thinking_state.active_completions + 
                          #M.thinking_state.active_sampling + 
                          #M.thinking_state.active_elicitations,
    }
end

-- Clean up completed operations
function M.cleanup_completed_operations()
    local cleanup_count = 0
    
    -- Clean up completed completions
    for id, completion in pairs(M.thinking_state.active_completions) do
        if completion.status == "completed" or completion.status == "failed" then
            M.thinking_state.active_completions[id] = nil
            cleanup_count = cleanup_count + 1
        end
    end
    
    -- Clean up completed sampling
    for id, sampling in pairs(M.thinking_state.active_sampling) do
        if sampling.status == "completed" or sampling.status == "failed" then
            M.thinking_state.active_sampling[id] = nil
            cleanup_count = cleanup_count + 1
        end
    end
    
    -- Clean up completed elicitations
    for id, elicitation in pairs(M.thinking_state.active_elicitations) do
        if elicitation.status == "created" or elicitation.status == "failed" then
            M.thinking_state.active_elicitations[id] = nil
            cleanup_count = cleanup_count + 1
        end
    end
    
    if cleanup_count > 0 then
        vim.notify("Cleaned up " .. cleanup_count .. " completed operations", vim.log.levels.INFO)
    end
    
    return cleanup_count
end

-- Enhanced thinking model completion with progress tracking
function M.thinking_completion_with_progress(prompt, model, options, progress_callback)
    local mcp_http_transport = require("paragonic.mcp_http_transport")
    
    if not mcp_http_transport.is_ready() then
        return nil, "MCP transport not ready"
    end
    
    local completion_id = M.generate_operation_id("thinking_completion")
    
    -- Register completion operation
    M.thinking_state.active_completions[completion_id] = {
        prompt = prompt,
        model = model or "deepseek-r1:1.5b",
        options = options or {},
        start_time = os.time(),
        status = "pending",
        progress = 0,
    }
    
    -- Call progress callback if provided
    if progress_callback and type(progress_callback) == "function" then
        progress_callback(completion_id, 0, "Starting thinking completion...")
    end
    
    -- Prepare completion request with progress token
    local request = {
        jsonrpc = "2.0",
        id = completion_id,
        method = "completion/complete",
        params = {
            prompt = prompt,
            model = model or "deepseek-r1:1.5b",
            options = options or {},
            _meta = {
                progressToken = completion_id,
            },
        },
    }
    
    -- Send completion request
    local response, err = mcp_http_transport.send_request(request)
    if not response then
        M.thinking_state.active_completions[completion_id] = nil
        return nil, err or "Thinking completion request failed"
    end
    
    -- Update completion status
    if response.result then
        M.thinking_state.active_completions[completion_id].status = "completed"
        M.thinking_state.active_completions[completion_id].result = response.result
        M.thinking_state.active_completions[completion_id].progress = 100
        
        -- Call progress callback for completion
        if progress_callback and type(progress_callback) == "function" then
            progress_callback(completion_id, 100, "Thinking completion finished")
        end
        
        return response.result.completion, nil
    else
        M.thinking_state.active_completions[completion_id].status = "failed"
        M.thinking_state.active_completions[completion_id].error = response.error
        
        -- Call progress callback for failure
        if progress_callback and type(progress_callback) == "function" then
            progress_callback(completion_id, -1, "Thinking completion failed: " .. (response.error and response.error.message or "Unknown error"))
        end
        
        return nil, response.error and response.error.message or "Thinking completion failed"
    end
end

-- Export module
return M
