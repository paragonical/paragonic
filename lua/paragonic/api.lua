-- API Layer: High-level API operations, response normalization, business logic
-- Provides clean API interface for chat completion, model management, and other operations

local M = {}

-- Dependencies
local transport = require("paragonic.transport")
local debug = require("paragonic.debug")

-- API state
local api_state = {
    initialized = false,
}

-- Initialize API layer
function M.init(config)
    if api_state.initialized then
        debug.debug_print("⚠️ API layer already initialized", "warn")
        return true
    end

    debug.debug_print("🔧 Initializing API layer", "info")

    -- Initialize transport layer
    local transport_ok, transport_err = transport.init(config)
    if not transport_ok then
        debug.debug_print("❌ Transport initialization failed: " .. tostring(transport_err), "error")
        return false, "Transport initialization failed: " .. tostring(transport_err)
    end

    -- Connect to server
    local connect_ok, connect_err = transport.connect()
    if not connect_ok then
        debug.debug_print("❌ Connection failed: " .. tostring(connect_err), "error")
        return false, "Connection failed: " .. tostring(connect_err)
    end

    api_state.initialized = true
    debug.debug_print("✅ API layer initialized", "success")
    
    return true
end

-- Normalize response structure
local function normalize_response(response, method)
    if not response then
        return { success = false, error = "No response received" }
    end

    if response.error then
        return { 
            success = false, 
            error = response.error.message or "Unknown error",
            error_code = response.error.code
        }
    end

    -- Normalize based on method
    if method == "streaming_chat_completion" then
        if response.result and response.result.type == "streaming_chunks" then
            return {
                success = true,
                type = "streaming_chunks",
                chunks = response.result.chunks or {},
                progress_token = response.result.progressToken,
                total_chunks = response.result.chunks and #response.result.chunks or 0,
            }
        else
            return {
                success = true,
                type = "regular_response",
                content = response.result and response.result.content or "",
                model = response.result and response.result.model or "",
            }
        end
    else
        return {
            success = true,
            data = response.result,
        }
    end
end

-- Chat completion (non-streaming)
function M.chat_completion(message, model, options)
    if not api_state.initialized then
        return { success = false, error = "API layer not initialized" }
    end

    options = options or {}
    model = model or "deepseek-r1:1.5b"

    debug.debug_print("📤 Chat completion request", "debug")
    debug.debug_print("   Model: " .. model, "debug")
    debug.debug_print("   Message: " .. message:sub(1, 50) .. "...", "debug")

    local params = {
        message = message,
        model = model,
    }

    -- Add options to params
    for key, value in pairs(options) do
        params[key] = value
    end

    local response, err = transport.send_request("chat_completion", params)
    if not response then
        return { success = false, error = "Request failed: " .. tostring(err) }
    end

    return normalize_response(response, "chat_completion")
end

-- Streaming chat completion
function M.streaming_chat_completion(message, model, options)
    if not api_state.initialized then
        return { success = false, error = "API layer not initialized" }
    end

    options = options or {}
    model = model or "deepseek-r1:1.5b"

    debug.debug_print("📤 Streaming chat completion request", "debug")
    debug.debug_print("   Model: " .. model, "debug")
    debug.debug_print("   Message: " .. message:sub(1, 50) .. "...", "debug")

    local params = {
        message = message,
        model = model,
        chunk_size = options.chunk_size or 30,
    }

    -- Add options to params
    for key, value in pairs(options) do
        if key ~= "chunk_size" then
            params[key] = value
        end
    end

    local response, err = transport.send_request("streaming_chat_completion", params)
    if not response then
        return { success = false, error = "Request failed: " .. tostring(err) }
    end

    return normalize_response(response, "streaming_chat_completion")
end

-- List available models
function M.list_models()
    if not api_state.initialized then
        return { success = false, error = "API layer not initialized" }
    end

    debug.debug_print("📤 List models request", "debug")

    local response, err = transport.send_request("tools/call", {
        name = "list_models",
        arguments = {}
    })

    if not response then
        return { success = false, error = "Request failed: " .. tostring(err) }
    end

    return normalize_response(response, "list_models")
end

-- Get projects
function M.get_projects()
    if not api_state.initialized then
        return { success = false, error = "API layer not initialized" }
    end

    debug.debug_print("📤 Get projects request", "debug")

    local response, err = transport.send_request("tools/call", {
        name = "list_projects",
        arguments = {}
    })

    if not response then
        return { success = false, error = "Request failed: " .. tostring(err) }
    end

    return normalize_response(response, "get_projects")
end

-- Health check
function M.health_check()
    if not api_state.initialized then
        return { success = false, error = "API layer not initialized" }
    end

    debug.debug_print("📤 Health check request", "debug")

    local response, err = transport.send_request("tools/list", {})
    if not response then
        return { success = false, error = "Request failed: " .. tostring(err) }
    end

    return normalize_response(response, "health_check")
end

-- Check if API is ready
function M.is_ready()
    return api_state.initialized and transport.is_connected()
end

-- Get API status
function M.get_status()
    return {
        initialized = api_state.initialized,
        transport_status = transport.get_status(),
        ready = M.is_ready(),
    }
end

-- Cleanup API layer
function M.cleanup()
    debug.debug_print("🔧 Cleaning up API layer", "info")
    
    transport.cleanup()
    api_state.initialized = false
    
    debug.debug_print("✅ API layer cleaned up", "success")
end

return M
