-- Streaming Layer: Streaming state management, chunk processing, progress tracking
-- Provides clean streaming interface for managing streaming sessions and chunk processing

local M = {}

-- Dependencies
local api = require("paragonic.api")
local debug = require("paragonic.debug")

-- Streaming state
local streaming_state = {
    active_sessions = {},
    session_counter = 0,
}

-- Create new streaming session
function M.start_session(message, model, options)
    if not api.is_ready() then
        return nil, "API not ready"
    end

    options = options or {}
    model = model or "deepseek-r1:1.5b"

    -- Generate session ID
    local session_id = "session_" .. os.time() .. "_" .. streaming_state.session_counter
    streaming_state.session_counter = streaming_state.session_counter + 1

    debug.debug_print("🔄 Starting streaming session: " .. session_id, "info")
    debug.debug_print("   Model: " .. model, "debug")
    debug.debug_print("   Message: " .. message:sub(1, 50) .. "...", "debug")

    -- Call API layer for streaming chat completion
    local response = api.streaming_chat_completion(message, model, options)
    
    if not response.success then
        debug.debug_print("❌ Streaming session failed: " .. tostring(response.error), "error")
        return nil, response.error
    end

    -- Create session object
    local session = {
        id = session_id,
        model = model,
        message = message,
        start_time = os.time(),
        chunks = {},
        processed_chunks = 0,
        total_chunks = 0,
        completed = false,
        error = nil,
        progress_token = response.progress_token,
    }

    -- Process response based on type
    if response.type == "streaming_chunks" then
        -- Store chunks from response
        session.chunks = response.chunks or {}
        session.total_chunks = response.total_chunks or #session.chunks
        session.completed = true -- All chunks received immediately
        
        debug.debug_print("✅ Session completed immediately with " .. #session.chunks .. " chunks", "success")
    else
        -- Regular response (non-streaming)
        session.chunks = {{
            chunk = response.content or "",
            chunk_type = "regular_content",
            chunk_index = 0,
            total_chunks = 1,
        }}
        session.total_chunks = 1
        session.completed = true
        
        debug.debug_print("✅ Session completed with regular response", "success")
    end

    -- Store session
    streaming_state.active_sessions[session_id] = session

    debug.debug_print("🔄 Session " .. session_id .. " created successfully", "success")
    return session_id
end

-- Get chunks for a session
function M.get_chunks(session_id)
    local session = streaming_state.active_sessions[session_id]
    if not session then
        return nil, "Session not found: " .. tostring(session_id)
    end

    -- Return unprocessed chunks
    local unprocessed_chunks = {}
    for i = session.processed_chunks + 1, #session.chunks do
        table.insert(unprocessed_chunks, session.chunks[i])
    end

    -- Mark chunks as processed
    session.processed_chunks = #session.chunks

    debug.debug_print("📥 Returning " .. #unprocessed_chunks .. " chunks for session " .. session_id, "debug")
    return unprocessed_chunks
end

-- Check if session is complete
function M.is_complete(session_id)
    local session = streaming_state.active_sessions[session_id]
    if not session then
        return true -- Session not found, consider it complete
    end

    return session.completed
end

-- Get session status
function M.get_session_status(session_id)
    local session = streaming_state.active_sessions[session_id]
    if not session then
        return nil, "Session not found: " .. tostring(session_id)
    end

    return {
        id = session.id,
        model = session.model,
        start_time = session.start_time,
        completed = session.completed,
        total_chunks = session.total_chunks,
        processed_chunks = session.processed_chunks,
        remaining_chunks = session.total_chunks - session.processed_chunks,
        error = session.error,
        progress_token = session.progress_token,
    }
end

-- Cancel streaming session
function M.cancel(session_id)
    local session = streaming_state.active_sessions[session_id]
    if not session then
        return false, "Session not found: " .. tostring(session_id)
    end

    debug.debug_print("🛑 Cancelling session: " .. session_id, "info")

    session.completed = true
    session.error = "Cancelled by user"

    debug.debug_print("✅ Session " .. session_id .. " cancelled", "success")
    return true
end

-- Cleanup session
function M.cleanup_session(session_id)
    local session = streaming_state.active_sessions[session_id]
    if not session then
        return false, "Session not found: " .. tostring(session_id)
    end

    debug.debug_print("🧹 Cleaning up session: " .. session_id, "debug")

    -- Remove session from active sessions
    streaming_state.active_sessions[session_id] = nil

    debug.debug_print("✅ Session " .. session_id .. " cleaned up", "success")
    return true
end

-- Get all active sessions
function M.get_active_sessions()
    local sessions = {}
    for session_id, session in pairs(streaming_state.active_sessions) do
        table.insert(sessions, {
            id = session_id,
            model = session.model,
            completed = session.completed,
            total_chunks = session.total_chunks,
            processed_chunks = session.processed_chunks,
        })
    end
    return sessions
end

-- Cleanup all sessions
function M.cleanup_all_sessions()
    debug.debug_print("🧹 Cleaning up all streaming sessions", "info")

    local session_count = 0
    for session_id, _ in pairs(streaming_state.active_sessions) do
        M.cleanup_session(session_id)
        session_count = session_count + 1
    end

    debug.debug_print("✅ Cleaned up " .. session_count .. " sessions", "success")
    return session_count
end

-- Get streaming layer status
function M.get_status()
    local active_sessions = M.get_active_sessions()
    return {
        active_sessions_count = #active_sessions,
        active_sessions = active_sessions,
        session_counter = streaming_state.session_counter,
    }
end

-- Initialize streaming layer
function M.init(config)
    debug.debug_print("🔧 Initializing streaming layer", "info")

    -- Initialize API layer
    local api_ok, api_err = api.init(config)
    if not api_ok then
        debug.debug_print("❌ API initialization failed: " .. tostring(api_err), "error")
        return false, "API initialization failed: " .. tostring(api_err)
    end

    debug.debug_print("✅ Streaming layer initialized", "success")
    return true
end

-- Check if streaming layer is ready
function M.is_ready()
    return api.is_ready()
end

-- Cleanup streaming layer
function M.cleanup()
    debug.debug_print("🔧 Cleaning up streaming layer", "info")
    
    M.cleanup_all_sessions()
    api.cleanup()
    
    debug.debug_print("✅ Streaming layer cleaned up", "success")
end

return M
