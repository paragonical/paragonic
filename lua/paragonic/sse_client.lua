-- SSE client for MCP HTTP Server-Sent Events
-- 
-- This module provides SSE client functionality for the MCP
-- Streamable HTTP transport, including connection management,
-- event parsing, and stream resumption.

local sse_client = {}
-- Try to load http_client with different paths
local http_client
local success, result = pcall(require, "paragonic.http_client")
if success then
    http_client = result
else
    -- Fallback to relative path
    success, result = pcall(require, "http_client")
    if success then
        http_client = result
    else
        -- Final fallback to absolute path
        http_client = require("../../lua/paragonic/http_client")
    end
end

-- SSE client configuration
local DEFAULT_RECONNECT_DELAY = 1 -- seconds
local DEFAULT_MAX_RECONNECT_ATTEMPTS = 5
local DEFAULT_EVENT_BUFFER_SIZE = 100

-- SSE client state
local client_state = {
    base_url = nil,
    session_id = nil,
    stream_id = nil,
    last_event_id = nil,
    is_connected = false,
    reconnect_delay = DEFAULT_RECONNECT_DELAY,
    max_reconnect_attempts = DEFAULT_MAX_RECONNECT_ATTEMPTS,
    event_buffer_size = DEFAULT_EVENT_BUFFER_SIZE,
    event_buffer = {},
    callbacks = {},
    connection_thread = nil,
}

-- SSE event structure
local SSEEvent = {
    id = nil,
    event_type = nil,
    data = nil,
    retry = nil,
    timestamp = nil,
}

-- SSE client errors
local SSEClientError = {
    CONNECTION_FAILED = "connection_failed",
    STREAM_NOT_FOUND = "stream_not_found",
    INVALID_EVENT = "invalid_event",
    MAX_RECONNECT_ATTEMPTS_EXCEEDED = "max_reconnect_attempts_exceeded",
    ALREADY_CONNECTED = "already_connected",
    NOT_CONNECTED = "not_connected",
    INVALID_URL = "invalid_url",
}

-- Initialize SSE client
function sse_client.init(config)
    config = config or {}
    
    client_state.base_url = config.base_url or "http://localhost:3000"
    client_state.reconnect_delay = config.reconnect_delay or DEFAULT_RECONNECT_DELAY
    client_state.max_reconnect_attempts = config.max_reconnect_attempts or DEFAULT_MAX_RECONNECT_ATTEMPTS
    client_state.event_buffer_size = config.event_buffer_size or DEFAULT_EVENT_BUFFER_SIZE
    
    -- Initialize HTTP client
    http_client.init({
        base_url = client_state.base_url,
        timeout = config.timeout or 30,
        retry_attempts = 1, -- SSE handles its own retries
    })
    
    return true
end

-- Set session ID
function sse_client.set_session_id(session_id)
    if not session_id or type(session_id) ~= "string" then
        return false, "Invalid session ID"
    end
    
    client_state.session_id = session_id
    http_client.set_session_id(session_id)
    return true
end

-- Get current session ID
function sse_client.get_session_id()
    return client_state.session_id
end

-- Set stream ID
function sse_client.set_stream_id(stream_id)
    if not stream_id or type(stream_id) ~= "string" then
        return false, "Invalid stream ID"
    end
    
    client_state.stream_id = stream_id
    return true
end

-- Get current stream ID
function sse_client.get_stream_id()
    return client_state.stream_id
end

-- Set last event ID for resumption
function sse_client.set_last_event_id(event_id)
    client_state.last_event_id = event_id
end

-- Get last event ID
function sse_client.get_last_event_id()
    return client_state.last_event_id
end

-- Parse SSE event from text
function sse_client.parse_event(event_text)
    if not event_text or type(event_text) ~= "string" then
        return nil, "Invalid event text"
    end
    
    local event = {
        id = nil,
        event_type = nil,
        data = nil,
        retry = nil,
        timestamp = vim.loop.now(),
    }
    
    -- Parse event lines
    for line in event_text:gmatch("[^\r\n]+") do
        line = line:gsub("^%s+", ""):gsub("%s+$", "") -- trim whitespace
        
        if line == "" then
            -- Empty line indicates end of event
            break
        elseif line:match("^:") then
            -- Comment line, ignore
        elseif line:match("^id:") then
            event.id = line:sub(4):gsub("^%s+", ""):gsub("%s+$", "")
        elseif line:match("^event:") then
            event.event_type = line:sub(7):gsub("^%s+", ""):gsub("%s+$", "")
        elseif line:match("^data:") then
            local data = line:sub(6):gsub("^%s+", ""):gsub("%s+$", "")
            if event.data then
                event.data = event.data .. "\n" .. data
            else
                event.data = data
            end
        elseif line:match("^retry:") then
            local retry_str = line:sub(7):gsub("^%s+", ""):gsub("%s+$", "")
            event.retry = tonumber(retry_str)
        end
    end
    
    return event
end

-- Connection worker (runs in separate thread)
function sse_client._connection_worker()
    local reconnect_attempts = 0
    
    while client_state.is_connected do
        local success, response = pcall(function()
            return sse_client._establish_connection()
        end)
        
        if not success or not response then
            reconnect_attempts = reconnect_attempts + 1
            
            -- Trigger on_error callback
            if client_state.callbacks.on_error then
                client_state.callbacks.on_error("Connection failed", reconnect_attempts)
            end
            
            if reconnect_attempts >= client_state.max_reconnect_attempts then
                -- Trigger on_max_reconnect_attempts callback
                if client_state.callbacks.on_max_reconnect_attempts then
                    client_state.callbacks.on_max_reconnect_attempts()
                end
                break
            end
            
            -- Wait before reconnecting
            vim.wait(client_state.reconnect_delay * 1000)
        else
            -- Reset reconnect attempts on successful connection
            reconnect_attempts = 0
            
            -- Process SSE stream
            sse_client._process_stream(response)
        end
    end
end

-- Connect to SSE stream
function sse_client.connect(stream_id, callbacks)
    if client_state.is_connected then
        return false, SSEClientError.ALREADY_CONNECTED
    end
    
    if not stream_id or type(stream_id) ~= "string" then
        return false, "Invalid stream ID"
    end
    
    -- Set stream ID
    client_state.stream_id = stream_id
    
    -- Set callbacks
    client_state.callbacks = callbacks or {}
    
    -- Start connection thread
    client_state.connection_thread = vim.loop.new_thread()
    client_state.connection_thread:start(function()
        sse_client._connection_worker()
    end)
    
    client_state.is_connected = true
    
    -- Trigger on_connect callback
    if client_state.callbacks.on_connect then
        client_state.callbacks.on_connect(stream_id)
    end
    
    return true
end

-- Disconnect from SSE stream
function sse_client.disconnect()
    if not client_state.is_connected then
        return false, SSEClientError.NOT_CONNECTED
    end
    
    client_state.is_connected = false
    
    -- Stop connection thread
    if client_state.connection_thread then
        client_state.connection_thread:close()
        client_state.connection_thread = nil
    end
    
    -- Trigger on_disconnect callback
    if client_state.callbacks.on_disconnect then
        client_state.callbacks.on_disconnect()
    end
    
    return true
end



-- Establish SSE connection
function sse_client._establish_connection()
    local endpoint = "/mcp"
    if client_state.stream_id then
        endpoint = endpoint .. "?stream=" .. client_state.stream_id
    end
    
    local headers = {
        ["Accept"] = "text/event-stream",
        ["Cache-Control"] = "no-cache",
    }
    
    -- Add Last-Event-ID header for resumption
    if client_state.last_event_id then
        headers["Last-Event-ID"] = client_state.last_event_id
    end
    
    local response = http_client.get(endpoint, headers)
    
    if not response or not http_client.is_success(response) then
        return nil
    end
    
    return response.raw_body
end

-- Process SSE stream
function sse_client._process_stream(stream_data)
    if not stream_data or type(stream_data) ~= "string" then
        return
    end
    
    -- Split stream into events
    local events = {}
    local current_event = ""
    
    for line in stream_data:gmatch("[^\r\n]*") do
        if line == "" then
            -- Empty line indicates end of event
            if current_event ~= "" then
                table.insert(events, current_event)
                current_event = ""
            end
        else
            current_event = current_event .. line .. "\n"
        end
    end
    
    -- Process each event
    for _, event_text in ipairs(events) do
        local event, err = sse_client.parse_event(event_text)
        if event then
            sse_client._handle_event(event)
        elseif client_state.callbacks.on_parse_error then
            client_state.callbacks.on_parse_error(err, event_text)
        end
    end
end

-- Handle parsed SSE event
function sse_client._handle_event(event)
    -- Update last event ID
    if event.id then
        client_state.last_event_id = event.id
    end
    
    -- Add to event buffer
    table.insert(client_state.event_buffer, event)
    if #client_state.event_buffer > client_state.event_buffer_size then
        table.remove(client_state.event_buffer, 1)
    end
    
    -- Trigger appropriate callback
    if event.event_type == "message" or not event.event_type then
        if client_state.callbacks.on_message then
            client_state.callbacks.on_message(event)
        end
    elseif event.event_type == "notification" then
        if client_state.callbacks.on_notification then
            client_state.callbacks.on_notification(event)
        end
    elseif event.event_type == "error" then
        if client_state.callbacks.on_error then
            client_state.callbacks.on_error(event.data, 0)
        end
    end
    
    -- Trigger generic event callback
    if client_state.callbacks.on_event then
        client_state.callbacks.on_event(event)
    end
end

-- Get event buffer
function sse_client.get_event_buffer()
    return client_state.event_buffer
end

-- Clear event buffer
function sse_client.clear_event_buffer()
    client_state.event_buffer = {}
end

-- Check if connected
function sse_client.is_connected()
    return client_state.is_connected
end

-- Get connection status
function sse_client.get_connection_status()
    return {
        is_connected = client_state.is_connected,
        session_id = client_state.session_id,
        stream_id = client_state.stream_id,
        last_event_id = client_state.last_event_id,
        event_buffer_size = #client_state.event_buffer,
    }
end

-- Clean up resources
function sse_client.cleanup()
    -- Disconnect if connected
    if client_state.is_connected then
        sse_client.disconnect()
    end
    
    -- Clear state
    client_state = {
        base_url = nil,
        session_id = nil,
        stream_id = nil,
        last_event_id = nil,
        is_connected = false,
        reconnect_delay = DEFAULT_RECONNECT_DELAY,
        max_reconnect_attempts = DEFAULT_MAX_RECONNECT_ATTEMPTS,
        event_buffer_size = DEFAULT_EVENT_BUFFER_SIZE,
        event_buffer = {},
        callbacks = {},
        connection_thread = nil,
    }
    
    -- Clean up HTTP client
    http_client.cleanup()
end

-- Export module
return sse_client
