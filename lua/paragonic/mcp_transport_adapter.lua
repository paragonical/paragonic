-- MCP Transport Adapter for Backward Compatibility
-- 
-- This module provides backward compatibility between the existing
-- TCP-based MCP implementation and the new HTTP transport.

local mcp_transport_adapter = {}
-- Try to load mcp_http_transport with different paths
local mcp_http_transport
local success, result = pcall(require, "paragonic.mcp_http_transport")
if success then
    mcp_http_transport = result
else
    -- Fallback to relative path
    success, result = pcall(require, "mcp_http_transport")
    if success then
        mcp_http_transport = result
    else
        -- Final fallback to absolute path
        mcp_http_transport = require("../../lua/paragonic/mcp_http_transport")
    end
end

-- Transport types
local TransportType = {
    TCP = "tcp",
    HTTP = "http",
    AUTO = "auto",
}

-- Transport adapter configuration
local DEFAULT_TRANSPORT_TYPE = TransportType.AUTO
local DEFAULT_FALLBACK_TIMEOUT = 5 -- seconds
local DEFAULT_HEALTH_CHECK_INTERVAL = 30 -- seconds

-- Transport adapter state
local adapter_state = {
    transport_type = DEFAULT_TRANSPORT_TYPE,
    current_transport = nil,
    fallback_timeout = DEFAULT_FALLBACK_TIMEOUT,
    health_check_interval = DEFAULT_HEALTH_CHECK_INTERVAL,
    is_initialized = false,
    is_connected = false,
    callbacks = {},
    health_check_timer = nil,
    last_health_check = 0,
}

-- Transport adapter errors
local TransportAdapterError = {
    NO_TRANSPORT_AVAILABLE = "no_transport_available",
    TRANSPORT_INIT_FAILED = "transport_init_failed",
    HEALTH_CHECK_FAILED = "health_check_failed",
    FALLBACK_FAILED = "fallback_failed",
    NOT_INITIALIZED = "not_initialized",
    NOT_CONNECTED = "not_connected",
}

-- Initialize transport adapter
function mcp_transport_adapter.init(config)
    config = config or {}
    
    adapter_state.transport_type = config.transport_type or DEFAULT_TRANSPORT_TYPE
    adapter_state.fallback_timeout = config.fallback_timeout or DEFAULT_FALLBACK_TIMEOUT
    adapter_state.health_check_interval = config.health_check_interval or DEFAULT_HEALTH_CHECK_INTERVAL
    
    -- Initialize based on transport type
    if adapter_state.transport_type == TransportType.HTTP then
        local success, err = mcp_transport_adapter._init_http_transport(config)
        if not success then
            return false, err
        end
    elseif adapter_state.transport_type == TransportType.TCP then
        local success, err = mcp_transport_adapter._init_tcp_transport(config)
        if not success then
            return false, err
        end
    elseif adapter_state.transport_type == TransportType.AUTO then
        local success, err = mcp_transport_adapter._init_auto_transport(config)
        if not success then
            return false, err
        end
    else
        return false, "Invalid transport type: " .. tostring(adapter_state.transport_type)
    end
    
    adapter_state.is_initialized = true
    return true
end

-- Initialize HTTP transport
function mcp_transport_adapter._init_http_transport(config)
    local http_config = {
        base_url = config.base_url or "http://localhost:3000",
        protocol_version = config.protocol_version or "2025-06-18",
        initialization_timeout = config.initialization_timeout or 30,
        request_timeout = config.request_timeout or 60,
        reconnect_delay = config.reconnect_delay or 1,
        max_reconnect_attempts = config.max_reconnect_attempts or 5,
        event_buffer_size = config.event_buffer_size or 100,
    }
    
    local success = mcp_http_transport.init(http_config)
    if not success then
        return false, "Failed to initialize HTTP transport"
    end
    
    adapter_state.current_transport = "http"
    return true
end

-- Initialize TCP transport (placeholder for existing implementation)
function mcp_transport_adapter._init_tcp_transport(config)
    -- TODO: Integrate with existing TCP transport
    -- For now, return error to indicate TCP transport not yet implemented
    return false, "TCP transport not yet implemented in adapter"
end

-- Initialize auto transport (try HTTP first, fallback to TCP)
function mcp_transport_adapter._init_auto_transport(config)
    -- Try HTTP transport first
    local http_success, http_err = mcp_transport_adapter._init_http_transport(config)
    if http_success then
        return true
    end
    
    -- Log HTTP failure
    if adapter_state.callbacks.on_log then
        adapter_state.callbacks.on_log("HTTP transport failed: " .. (http_err or "unknown error"))
    end
    
    -- Try TCP transport as fallback
    local tcp_success, tcp_err = mcp_transport_adapter._init_tcp_transport(config)
    if tcp_success then
        return true
    end
    
    -- Log TCP failure
    if adapter_state.callbacks.on_log then
        adapter_state.callbacks.on_log("TCP transport failed: " .. (tcp_err or "unknown error"))
    end
    
    return false, "Both HTTP and TCP transports failed"
end

-- Set callbacks for transport events
function mcp_transport_adapter.set_callbacks(callbacks)
    adapter_state.callbacks = callbacks or {}
    
    -- Forward callbacks to current transport
    if adapter_state.current_transport == "http" then
        mcp_http_transport.set_callbacks(callbacks)
    elseif adapter_state.current_transport == "tcp" then
        -- TODO: Forward to TCP transport
    end
end

-- Initialize MCP session
function mcp_transport_adapter.initialize_session(client_info)
    if not adapter_state.is_initialized then
        return false, TransportAdapterError.NOT_INITIALIZED
    end
    
    if adapter_state.current_transport == "http" then
        return mcp_http_transport.initialize_session(client_info)
    elseif adapter_state.current_transport == "tcp" then
        -- TODO: Initialize TCP session
        return false, "TCP transport not yet implemented"
    else
        return false, TransportAdapterError.NO_TRANSPORT_AVAILABLE
    end
end

-- Send MCP request
function mcp_transport_adapter.send_request(request)
    if not adapter_state.is_initialized then
        return nil, TransportAdapterError.NOT_INITIALIZED
    end
    
    if adapter_state.current_transport == "http" then
        return mcp_http_transport.send_request(request)
    elseif adapter_state.current_transport == "tcp" then
        -- TODO: Send TCP request
        return nil, "TCP transport not yet implemented"
    else
        return nil, TransportAdapterError.NO_TRANSPORT_AVAILABLE
    end
end

-- Send MCP notification
function mcp_transport_adapter.send_notification(notification)
    if not adapter_state.is_initialized then
        return false, TransportAdapterError.NOT_INITIALIZED
    end
    
    if adapter_state.current_transport == "http" then
        return mcp_http_transport.send_notification(notification)
    elseif adapter_state.current_transport == "tcp" then
        -- TODO: Send TCP notification
        return false, "TCP transport not yet implemented"
    else
        return false, TransportAdapterError.NO_TRANSPORT_AVAILABLE
    end
end

-- Perform health check
function mcp_transport_adapter.health_check()
    if not adapter_state.is_initialized then
        return false, TransportAdapterError.NOT_INITIALIZED
    end
    
    local current_time = vim.loop.now()
    if current_time - adapter_state.last_health_check < (adapter_state.health_check_interval * 1000) then
        -- Skip health check if too recent
        return true
    end
    
    adapter_state.last_health_check = current_time
    
    if adapter_state.current_transport == "http" then
        -- Simple health check for HTTP transport
        local status = mcp_http_transport.get_status()
        if status.is_initialized then
            return true
        else
            return false, TransportAdapterError.HEALTH_CHECK_FAILED
        end
    elseif adapter_state.current_transport == "tcp" then
        -- TODO: Health check for TCP transport
        return false, "TCP transport not yet implemented"
    else
        return false, TransportAdapterError.NO_TRANSPORT_AVAILABLE
    end
end

-- Switch transport (for fallback scenarios)
function mcp_transport_adapter.switch_transport(transport_type, config)
    if not adapter_state.is_initialized then
        return false, TransportAdapterError.NOT_INITIALIZED
    end
    
    -- Shutdown current transport
    mcp_transport_adapter.shutdown()
    
    -- Update transport type
    adapter_state.transport_type = transport_type
    
    -- Initialize new transport
    if transport_type == TransportType.HTTP then
        local success, err = mcp_transport_adapter._init_http_transport(config)
        if not success then
            return false, err
        end
    elseif transport_type == TransportType.TCP then
        local success, err = mcp_transport_adapter._init_tcp_transport(config)
        if not success then
            return false, err
        end
    else
        return false, "Invalid transport type: " .. tostring(transport_type)
    end
    
    -- Restore callbacks
    if adapter_state.callbacks then
        mcp_transport_adapter.set_callbacks(adapter_state.callbacks)
    end
    
    return true
end

-- Shutdown transport
function mcp_transport_adapter.shutdown()
    if adapter_state.current_transport == "http" then
        mcp_http_transport.shutdown()
    elseif adapter_state.current_transport == "tcp" then
        -- TODO: Shutdown TCP transport
    end
    
    adapter_state.is_connected = false
    adapter_state.current_transport = nil
end

-- Get transport status
function mcp_transport_adapter.get_status()
    local status = {
        transport_type = adapter_state.transport_type,
        current_transport = adapter_state.current_transport,
        is_initialized = adapter_state.is_initialized,
        is_connected = adapter_state.is_connected,
        fallback_timeout = adapter_state.fallback_timeout,
        health_check_interval = adapter_state.health_check_interval,
        last_health_check = adapter_state.last_health_check,
    }
    
    -- Add transport-specific status
    if adapter_state.current_transport == "http" then
        local http_status = mcp_http_transport.get_status()
        status.transport_status = http_status
    elseif adapter_state.current_transport == "tcp" then
        -- TODO: Add TCP status
        status.transport_status = { error = "TCP transport not implemented" }
    end
    
    return status
end

-- Check if transport is ready
function mcp_transport_adapter.is_ready()
    if not adapter_state.is_initialized then
        return false
    end
    
    if adapter_state.current_transport == "http" then
        return mcp_http_transport.is_ready()
    elseif adapter_state.current_transport == "tcp" then
        -- TODO: Check TCP readiness
        return false
    else
        return false
    end
end

-- Get session ID
function mcp_transport_adapter.get_session_id()
    if adapter_state.current_transport == "http" then
        return mcp_http_transport.get_session_id()
    elseif adapter_state.current_transport == "tcp" then
        -- TODO: Get TCP session ID
        return nil
    else
        return nil
    end
end

-- Get stream ID
function mcp_transport_adapter.get_stream_id()
    if adapter_state.current_transport == "http" then
        return mcp_http_transport.get_stream_id()
    elseif adapter_state.current_transport == "tcp" then
        -- TODO: Get TCP stream ID
        return nil
    else
        return nil
    end
end

-- Start health check timer
function mcp_transport_adapter.start_health_check()
    if adapter_state.health_check_timer then
        return -- Already running
    end
    
    adapter_state.health_check_timer = vim.loop.new_timer()
    adapter_state.health_check_timer:start(0, adapter_state.health_check_interval * 1000, vim.schedule_wrap(function()
        local success, err = mcp_transport_adapter.health_check()
        if not success and adapter_state.callbacks.on_health_check_failed then
            adapter_state.callbacks.on_health_check_failed(err)
        end
    end))
end

-- Stop health check timer
function mcp_transport_adapter.stop_health_check()
    if adapter_state.health_check_timer then
        adapter_state.health_check_timer:stop()
        adapter_state.health_check_timer:close()
        adapter_state.health_check_timer = nil
    end
end

-- Clean up resources
function mcp_transport_adapter.cleanup()
    -- Stop health check timer
    mcp_transport_adapter.stop_health_check()
    
    -- Shutdown current transport
    mcp_transport_adapter.shutdown()
    
    -- Clean up HTTP transport
    mcp_http_transport.cleanup()
    
    -- Reset state
    adapter_state = {
        transport_type = DEFAULT_TRANSPORT_TYPE,
        current_transport = nil,
        fallback_timeout = DEFAULT_FALLBACK_TIMEOUT,
        health_check_interval = DEFAULT_HEALTH_CHECK_INTERVAL,
        is_initialized = false,
        is_connected = false,
        callbacks = {},
        health_check_timer = nil,
        last_health_check = 0,
    }
end

-- Export module
return mcp_transport_adapter
