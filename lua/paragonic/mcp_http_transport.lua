-- MCP HTTP Transport for Model Context Protocol
-- 
-- This module provides the complete MCP HTTP transport implementation,
-- integrating HTTP client for requests and SSE client for events.

local mcp_http_transport = {}
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

-- Try to load sse_client with different paths
local sse_client
local success2, result2 = pcall(require, "paragonic.sse_client")
if success2 then
    sse_client = result2
else
    -- Fallback to relative path
    success2, result2 = pcall(require, "sse_client")
    if success2 then
        sse_client = result2
    else
        -- Final fallback to absolute path
        sse_client = require("../../lua/paragonic/sse_client")
    end
end

local json = vim.json

-- MCP HTTP transport configuration
local DEFAULT_PROTOCOL_VERSION = "2025-06-18"
local DEFAULT_INITIALIZATION_TIMEOUT = 30 -- seconds
local DEFAULT_REQUEST_TIMEOUT = 60 -- seconds

-- MCP HTTP transport state
local transport_state = {
    base_url = nil,
    session_id = nil,
    stream_id = nil,
    protocol_version = DEFAULT_PROTOCOL_VERSION,
    is_initialized = false,
    is_connected = false,
    initialization_timeout = DEFAULT_INITIALIZATION_TIMEOUT,
    request_timeout = DEFAULT_REQUEST_TIMEOUT,
    callbacks = {},
    message_id_counter = 0,
}

-- MCP message types
local MCPMessageType = {
    REQUEST = "request",
    RESPONSE = "response",
    NOTIFICATION = "notification",
}

-- MCP HTTP transport errors
local MCPHTTPTransportError = {
    NOT_INITIALIZED = "not_initialized",
    NOT_CONNECTED = "not_connected",
    INITIALIZATION_FAILED = "initialization_failed",
    CONNECTION_FAILED = "connection_failed",
    INVALID_MESSAGE = "invalid_message",
    TIMEOUT = "timeout",
    PROTOCOL_ERROR = "protocol_error",
}

-- Initialize MCP HTTP transport
function mcp_http_transport.init(config)
    config = config or {}
    
    transport_state.base_url = config.base_url or "http://localhost:3000"
    transport_state.protocol_version = config.protocol_version or DEFAULT_PROTOCOL_VERSION
    transport_state.initialization_timeout = config.initialization_timeout or DEFAULT_INITIALIZATION_TIMEOUT
    transport_state.request_timeout = config.request_timeout or DEFAULT_REQUEST_TIMEOUT
    
    -- Initialize HTTP client
    local http_success = http_client.init({
        base_url = transport_state.base_url,
        timeout = transport_state.request_timeout,
        retry_attempts = 1, -- MCP handles its own retries
    })
    
    if not http_success then
        return false, "Failed to initialize HTTP client"
    end
    
    -- Initialize SSE client
    local sse_success = sse_client.init({
        base_url = transport_state.base_url,
        timeout = transport_state.initialization_timeout,
        reconnect_delay = config.reconnect_delay or 1,
        max_reconnect_attempts = config.max_reconnect_attempts or 5,
        event_buffer_size = config.event_buffer_size or 100,
    })
    
    if not sse_success then
        return false, "Failed to initialize SSE client"
    end
    
    transport_state.is_initialized = true
    return true
end

-- Set callbacks for MCP events
function mcp_http_transport.set_callbacks(callbacks)
    transport_state.callbacks = callbacks or {}
end

-- Generate unique message ID
function mcp_http_transport.generate_message_id()
    transport_state.message_id_counter = transport_state.message_id_counter + 1
    return tostring(transport_state.message_id_counter)
end

-- Initialize MCP session
function mcp_http_transport.initialize_session(client_info)
    if not transport_state.is_initialized then
        return false, MCPHTTPTransportError.NOT_INITIALIZED
    end
    
    -- Prepare initialization request
    local init_request = {
        jsonrpc = "2.0",
        id = mcp_http_transport.generate_message_id(),
        method = "initialize",
        params = {
            protocolVersion = transport_state.protocol_version,
            capabilities = client_info.capabilities or {},
            clientInfo = {
                name = client_info.name or "paragonic-client",
                version = client_info.version or "1.0.0",
            },
        },
    }
    
    -- Send initialization request
    local response, err = mcp_http_transport.send_request(init_request)
    if not response then
        return false, err or "Initialization request failed"
    end
    
    -- Check for initialization error
    if response.error then
        return false, response.error.message or "Initialization failed"
    end
    
    -- Extract session and stream information
    if response.result then
        transport_state.session_id = response.result.sessionId
        transport_state.stream_id = response.result.streamId
        
        -- Set session ID in clients
        http_client.set_session_id(transport_state.session_id)
        sse_client.set_session_id(transport_state.session_id)
        sse_client.set_stream_id(transport_state.stream_id)
    end
    
    -- Connect to SSE stream for events
    local sse_callbacks = {
        on_connect = function(stream_id)
            transport_state.is_connected = true
            if transport_state.callbacks.on_connect then
                transport_state.callbacks.on_connect(stream_id)
            end
        end,
        on_disconnect = function()
            transport_state.is_connected = false
            if transport_state.callbacks.on_disconnect then
                transport_state.callbacks.on_disconnect()
            end
        end,
        on_message = function(event)
            mcp_http_transport._handle_sse_message(event)
        end,
        on_notification = function(event)
            mcp_http_transport._handle_sse_notification(event)
        end,
        on_error = function(error_msg, attempt)
            if transport_state.callbacks.on_error then
                transport_state.callbacks.on_error(error_msg, attempt)
            end
        end,
        on_parse_error = function(error_msg, raw_event)
            if transport_state.callbacks.on_parse_error then
                transport_state.callbacks.on_parse_error(error_msg, raw_event)
            end
        end,
    }
    
    local connect_success, connect_err = sse_client.connect(transport_state.stream_id, sse_callbacks)
    if not connect_success then
        return false, connect_err or "Failed to connect to SSE stream"
    end
    
    return true
end

-- Send MCP request
function mcp_http_transport.send_request(request)
    if not transport_state.is_initialized then
        return nil, MCPHTTPTransportError.NOT_INITIALIZED
    end
    
    -- Validate request
    if not request or type(request) ~= "table" then
        return nil, MCPHTTPTransportError.INVALID_MESSAGE
    end
    
    if not request.jsonrpc or request.jsonrpc ~= "2.0" then
        return nil, MCPHTTPTransportError.PROTOCOL_ERROR
    end
    
    if not request.method or type(request.method) ~= "string" then
        return nil, MCPHTTPTransportError.INVALID_MESSAGE
    end
    
    -- Ensure request has an ID
    if not request.id then
        request.id = mcp_http_transport.generate_message_id()
    end
    
    -- Send HTTP POST request
    local response, err = http_client.post("/mcp", request)
    if not response then
        return nil, err or MCPHTTPTransportError.CONNECTION_FAILED
    end
    
    -- Check HTTP response
    if not http_client.is_success(response) then
        return nil, http_client.get_error_message(response)
    end
    
    -- Parse JSON response
    if not response.body or type(response.body) ~= "table" then
        return nil, MCPHTTPTransportError.INVALID_MESSAGE
    end
    
    return response.body
end

-- Send MCP notification
function mcp_http_transport.send_notification(notification)
    if not transport_state.is_initialized then
        return false, MCPHTTPTransportError.NOT_INITIALIZED
    end
    
    -- Validate notification
    if not notification or type(notification) ~= "table" then
        return false, MCPHTTPTransportError.INVALID_MESSAGE
    end
    
    if not notification.jsonrpc or notification.jsonrpc ~= "2.0" then
        return false, MCPHTTPTransportError.PROTOCOL_ERROR
    end
    
    if not notification.method or type(notification.method) ~= "string" then
        return false, MCPHTTPTransportError.INVALID_MESSAGE
    end
    
    -- Notifications should not have an ID
    if notification.id then
        return false, MCPHTTPTransportError.INVALID_MESSAGE
    end
    
    -- Send HTTP POST request
    local response, err = http_client.post("/mcp", notification)
    if not response then
        return false, err or MCPHTTPTransportError.CONNECTION_FAILED
    end
    
    -- Check HTTP response
    if not http_client.is_success(response) then
        return false, http_client.get_error_message(response)
    end
    
    return true
end

-- Handle SSE message event
function mcp_http_transport._handle_sse_message(event)
    if not event.data then
        return
    end
    
    -- Parse JSON-RPC message from SSE data
    local success, message = pcall(json.decode, event.data)
    if not success or not message then
        if transport_state.callbacks.on_parse_error then
            transport_state.callbacks.on_parse_error("Failed to parse SSE message", event.data)
        end
        return
    end
    
    -- Validate message
    if not message.jsonrpc or message.jsonrpc ~= "2.0" then
        if transport_state.callbacks.on_error then
            transport_state.callbacks.on_error("Invalid JSON-RPC version", 0)
        end
        return
    end
    
    -- Handle based on message type
    if message.id then
        -- This is a response
        if transport_state.callbacks.on_response then
            transport_state.callbacks.on_response(message)
        end
    else
        -- This is a notification
        if transport_state.callbacks.on_notification then
            transport_state.callbacks.on_notification(message)
        end
    end
end

-- Handle SSE notification event
function mcp_http_transport._handle_sse_notification(event)
    if not event.data then
        return
    end
    
    -- Parse JSON-RPC notification from SSE data
    local success, notification = pcall(json.decode, event.data)
    if not success or not notification then
        if transport_state.callbacks.on_parse_error then
            transport_state.callbacks.on_parse_error("Failed to parse SSE notification", event.data)
        end
        return
    end
    
    -- Validate notification
    if not notification.jsonrpc or notification.jsonrpc ~= "2.0" then
        if transport_state.callbacks.on_error then
            transport_state.callbacks.on_error("Invalid JSON-RPC version", 0)
        end
        return
    end
    
    -- Handle notification
    if transport_state.callbacks.on_notification then
        transport_state.callbacks.on_notification(notification)
    end
end

-- Shutdown MCP session
function mcp_http_transport.shutdown()
    if not transport_state.is_initialized then
        return false, MCPHTTPTransportError.NOT_INITIALIZED
    end
    
    -- Send shutdown notification
    local shutdown_notification = {
        jsonrpc = "2.0",
        method = "notifications/shutdown",
    }
    
    local success, err = mcp_http_transport.send_notification(shutdown_notification)
    if not success then
        -- Log error but continue with cleanup
        if transport_state.callbacks.on_error then
            transport_state.callbacks.on_error("Shutdown notification failed: " .. (err or "unknown error"), 0)
        end
    end
    
    -- Disconnect SSE client
    if transport_state.is_connected then
        sse_client.disconnect()
        transport_state.is_connected = false
    end
    
    -- Reset state
    transport_state.session_id = nil
    transport_state.stream_id = nil
    transport_state.is_initialized = false
    
    return true
end

-- Get transport status
function mcp_http_transport.get_status()
    return {
        is_initialized = transport_state.is_initialized,
        is_connected = transport_state.is_connected,
        session_id = transport_state.session_id,
        stream_id = transport_state.stream_id,
        protocol_version = transport_state.protocol_version,
        base_url = transport_state.base_url,
        message_id_counter = transport_state.message_id_counter,
    }
end

-- Check if transport is ready
function mcp_http_transport.is_ready()
    return transport_state.is_initialized and transport_state.is_connected
end

-- Get session ID
function mcp_http_transport.get_session_id()
    return transport_state.session_id
end

-- Get stream ID
function mcp_http_transport.get_stream_id()
    return transport_state.stream_id
end

-- Clean up resources
function mcp_http_transport.cleanup()
    -- Shutdown if initialized
    if transport_state.is_initialized then
        mcp_http_transport.shutdown()
    end
    
    -- Clean up clients
    http_client.cleanup()
    sse_client.cleanup()
    
    -- Reset state
    transport_state = {
        base_url = nil,
        session_id = nil,
        stream_id = nil,
        protocol_version = DEFAULT_PROTOCOL_VERSION,
        is_initialized = false,
        is_connected = false,
        initialization_timeout = DEFAULT_INITIALIZATION_TIMEOUT,
        request_timeout = DEFAULT_REQUEST_TIMEOUT,
        callbacks = {},
        message_id_counter = 0,
    }
end

-- Export module
return mcp_http_transport
