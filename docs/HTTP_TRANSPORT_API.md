# HTTP Transport API Documentation

## Overview

This document provides detailed API reference for the HTTP transport implementation, including all modules, functions, and usage examples.

## Table of Contents

1. [HTTP Client API](#http-client-api)
2. [SSE Client API](#sse-client-api)
3. [MCP Transport API](#mcp-transport-api)
4. [Performance API](#performance-api)
5. [Debug API](#debug-api)
6. [Configuration Reference](#configuration-reference)
7. [Error Handling](#error-handling)
8. [Examples](#examples)

## HTTP Client API

### Module: `paragonic.http_client`

The HTTP client module provides HTTP request functionality with connection pooling and optimization.

#### Initialization

```lua
local http_client = require("paragonic.http_client")

-- Initialize with configuration
function http_client.init(config)
    -- config: Configuration table
    -- Returns: boolean success
end
```

**Configuration Options:**
- `base_url` (string): Base URL for HTTP requests
- `timeout` (number): Request timeout in seconds
- `retry_attempts` (number): Number of retry attempts
- `retry_delay` (number): Delay between retries in seconds
- `headers` (table): Default headers to include in requests

**Example:**
```lua
local success = http_client.init({
    base_url = "http://localhost:3000",
    timeout = 30,
    retry_attempts = 3,
    retry_delay = 1,
    headers = {
        ["Content-Type"] = "application/json",
        ["Accept"] = "application/json, text/event-stream",
    }
})
```

#### Session Management

```lua
-- Set session ID
function http_client.set_session_id(session_id)
    -- session_id: Session identifier string
    -- Returns: boolean success, string error
end

-- Get current session ID
function http_client.get_session_id()
    -- Returns: string session_id or nil
end
```

**Example:**
```lua
local success, error = http_client.set_session_id("session-123")
if success then
    print("Session ID set successfully")
else
    print("Failed to set session ID:", error)
end
```

#### Request Methods

```lua
-- Send GET request
function http_client.get(endpoint, custom_headers)
    -- endpoint: Request endpoint (string)
    -- custom_headers: Optional custom headers (table)
    -- Returns: response table or nil, string error
end

-- Send POST request
function http_client.post(endpoint, data, custom_headers)
    -- endpoint: Request endpoint (string)
    -- data: Request data (table or string)
    -- custom_headers: Optional custom headers (table)
    -- Returns: response table or nil, string error
end

-- Send DELETE request
function http_client.delete(endpoint, custom_headers)
    -- endpoint: Request endpoint (string)
    -- custom_headers: Optional custom headers (table)
    -- Returns: response table or nil, string error
end

-- Send custom request
function http_client.send_request(method, endpoint, data, custom_headers)
    -- method: HTTP method (string)
    -- endpoint: Request endpoint (string)
    -- data: Request data (table or string)
    -- custom_headers: Optional custom headers (table)
    -- Returns: response table or nil, string error
end
```

**Response Format:**
```lua
{
    status_code = 200,
    body = { ... }, -- Parsed JSON response
    raw_body = "...", -- Raw response body
    headers = { ... }, -- Response headers
}
```

**Example:**
```lua
-- GET request
local response, error = http_client.get("/api/data")
if response then
    print("Status:", response.status_code)
    print("Data:", response.body)
else
    print("Error:", error)
end

-- POST request
local data = { name = "test", value = 123 }
local response, error = http_client.post("/api/create", data)
if response and http_client.is_success(response) then
    print("Created successfully")
end
```

#### Response Validation

```lua
-- Check if response indicates success
function http_client.is_success(response)
    -- response: Response table
    -- Returns: boolean success
end

-- Check if response indicates client error
function http_client.is_client_error(response)
    -- response: Response table
    -- Returns: boolean is_client_error
end

-- Check if response indicates server error
function http_client.is_server_error(response)
    -- response: Response table
    -- Returns: boolean is_server_error
end

-- Get error message from response
function http_client.get_error_message(response)
    -- response: Response table
    -- Returns: string error_message
end
```

**Example:**
```lua
local response = http_client.get("/api/data")
if http_client.is_success(response) then
    print("Request successful")
elseif http_client.is_client_error(response) then
    print("Client error:", http_client.get_error_message(response))
elseif http_client.is_server_error(response) then
    print("Server error:", http_client.get_error_message(response))
end
```

#### Connection Pooling API

```lua
-- Get connection pool configuration
function http_client.get_connection_pool_config()
    -- Returns: configuration table
end

-- Set connection pool size
function http_client.set_connection_pool_size(pool_size)
    -- pool_size: Number of connections in pool
    -- Returns: boolean success, string error
end

-- Get connection from pool
function http_client.get_connection()
    -- Returns: connection object or nil, string error
end

-- Return connection to pool
function http_client.return_connection(connection)
    -- connection: Connection object
    -- Returns: boolean success, string error
end

-- Check if connection is valid
function http_client.is_connection_valid(connection)
    -- connection: Connection object
    -- Returns: boolean valid
end

-- Cleanup expired connections
function http_client.cleanup_expired_connections()
    -- Returns: boolean success
end

-- Get connection pool metrics
function http_client.get_connection_pool_metrics()
    -- Returns: metrics table
end

-- Reset connection pool
function http_client.reset_connection_pool()
    -- Returns: boolean success
end
```

**Metrics Format:**
```lua
{
    active_connections = 2,
    available_connections = 3,
    total_connections = 5,
    usage_percentage = 40.0,
    max_size = 10,
}
```

**Example:**
```lua
-- Configure connection pooling
local success, error = http_client.set_connection_pool_size(10)
if success then
    print("Connection pool configured")
end

-- Get pool metrics
local metrics = http_client.get_connection_pool_metrics()
print("Pool usage:", metrics.usage_percentage, "%")
print("Active connections:", metrics.active_connections)
print("Available connections:", metrics.available_connections)
```

#### Optimization API

```lua
-- Set optimization configuration
function http_client.set_optimization_config(config)
    -- config: Optimization configuration table
    -- Returns: boolean success, string error
end

-- Get optimization configuration
function http_client.get_optimization_config()
    -- Returns: configuration table
end

-- Configure request pooling
function http_client.configure_request_pooling(request_config)
    -- request_config: Request configuration table
    -- Returns: boolean success, string error
end
```

**Optimization Configuration:**
```lua
{
    enable_keep_alive = true,
    keep_alive_timeout = 30,
    max_idle_connections = 5,
    connection_timeout = 10,
}
```

**Example:**
```lua
local success, error = http_client.set_optimization_config({
    enable_keep_alive = true,
    keep_alive_timeout = 30,
    max_idle_connections = 5,
    connection_timeout = 10,
})
if success then
    print("Optimization configured")
end
```

#### Cleanup

```lua
-- Clean up resources
function http_client.cleanup()
    -- Returns: void
end
```

**Example:**
```lua
-- Clean up when done
http_client.cleanup()
```

## SSE Client API

### Module: `paragonic.sse_client`

The SSE client module provides Server-Sent Events functionality for real-time communication.

#### Initialization

```lua
local sse_client = require("paragonic.sse_client")

-- Initialize SSE client
function sse_client.init(config)
    -- config: Configuration table
    -- Returns: boolean success
end
```

**Configuration Options:**
- `base_url` (string): Base URL for SSE connection
- `timeout` (number): Connection timeout in seconds
- `reconnect_delay` (number): Delay between reconnection attempts
- `max_reconnect_attempts` (number): Maximum reconnection attempts
- `event_buffer_size` (number): Size of event buffer

**Example:**
```lua
local success = sse_client.init({
    base_url = "http://localhost:3000",
    timeout = 30,
    reconnect_delay = 1,
    max_reconnect_attempts = 5,
    event_buffer_size = 100,
})
```

#### Session Management

```lua
-- Set session ID
function sse_client.set_session_id(session_id)
    -- session_id: Session identifier string
    -- Returns: boolean success, string error
end

-- Get current session ID
function sse_client.get_session_id()
    -- Returns: string session_id or nil
end
```

#### Stream Management

```lua
-- Set stream ID
function sse_client.set_stream_id(stream_id)
    -- stream_id: Stream identifier string
    -- Returns: boolean success, string error
end

-- Get current stream ID
function sse_client.get_stream_id()
    -- Returns: string stream_id or nil
end

-- Set last event ID for resumption
function sse_client.set_last_event_id(event_id)
    -- event_id: Event identifier string
    -- Returns: void
end

-- Get last event ID
function sse_client.get_last_event_id()
    -- Returns: string event_id or nil
end
```

#### Connection Management

```lua
-- Connect to SSE stream
function sse_client.connect(stream_id)
    -- stream_id: Stream identifier string
    -- Returns: boolean success, string error
end

-- Disconnect from SSE stream
function sse_client.disconnect()
    -- Returns: boolean success, string error
end

-- Check if connected
function sse_client.is_connected()
    -- Returns: boolean connected
end
```

#### Event Handling

```lua
-- Set event callback
function sse_client.set_callback(event_type, callback)
    -- event_type: Event type string
    -- callback: Callback function
    -- Returns: boolean success
end

-- Parse SSE event from text
function sse_client.parse_event(text)
    -- text: Raw SSE event text
    -- Returns: event table or nil, string error
end
```

**Event Format:**
```lua
{
    id = "event-123",
    event_type = "message",
    data = { ... },
    retry = 3000,
    timestamp = 1234567890,
}
```

**Example:**
```lua
-- Set up event handlers
sse_client.set_callback("message", function(event)
    print("Received message:", event.data)
end)

sse_client.set_callback("error", function(event)
    print("SSE error:", event.data)
end)

-- Connect to stream
local success, error = sse_client.connect("mcp-stream")
if success then
    print("Connected to SSE stream")
else
    print("Failed to connect:", error)
end
```

#### Event Buffer

```lua
-- Get event buffer
function sse_client.get_event_buffer()
    -- Returns: array of events
end

-- Clear event buffer
function sse_client.clear_event_buffer()
    -- Returns: boolean success
end

-- Get buffer size
function sse_client.get_buffer_size()
    -- Returns: number size
end
```

## MCP Transport API

### Module: `paragonic.mcp_http_transport`

The MCP transport module provides Model Context Protocol communication over HTTP.

#### Initialization

```lua
local mcp_transport = require("paragonic.mcp_http_transport")

-- Initialize MCP transport
function mcp_transport.init(config)
    -- config: Configuration table
    -- Returns: boolean success, string error
end
```

**Configuration Options:**
- `base_url` (string): Base URL for MCP server
- `protocol_version` (string): MCP protocol version
- `initialization_timeout` (number): Initialization timeout
- `request_timeout` (number): Request timeout
- `reconnect_delay` (number): Reconnection delay
- `max_reconnect_attempts` (number): Maximum reconnection attempts
- `event_buffer_size` (number): Event buffer size

**Example:**
```lua
local success, error = mcp_transport.init({
    base_url = "http://localhost:3000",
    protocol_version = "2025-06-18",
    initialization_timeout = 30,
    request_timeout = 10,
    reconnect_delay = 1,
    max_reconnect_attempts = 5,
    event_buffer_size = 100,
})
```

#### Callback Management

```lua
-- Set callbacks for MCP events
function mcp_transport.set_callbacks(callbacks)
    -- callbacks: Callbacks table
    -- Returns: void
end
```

**Callbacks Format:**
```lua
{
    on_message = function(message) ... end,
    on_error = function(error) ... end,
    on_connect = function() ... end,
    on_disconnect = function() ... end,
}
```

#### Session Management

```lua
-- Initialize MCP session
function mcp_transport.initialize_session()
    -- Returns: boolean success, string session_id or error
end

-- Terminate MCP session
function mcp_transport.terminate_session()
    -- Returns: boolean success, string error
end

-- Get current session ID
function mcp_transport.get_session_id()
    -- Returns: string session_id or nil
end
```

#### Message Handling

```lua
-- Send MCP message
function mcp_transport.send_message(message)
    -- message: MCP message table
    -- Returns: boolean success, string error
end

-- Generate unique message ID
function mcp_transport.generate_message_id()
    -- Returns: string message_id
end
```

**Message Format:**
```lua
{
    jsonrpc = "2.0",
    method = "initialize",
    params = { ... },
    id = "msg-123",
}
```

**Example:**
```lua
-- Set up callbacks
mcp_transport.set_callbacks({
    on_message = function(message)
        print("MCP message received:", message)
    end,
    on_error = function(error)
        print("MCP error:", error)
    end,
})

-- Initialize session
local success, session_id = mcp_transport.initialize_session()
if success then
    print("MCP session initialized:", session_id)
    
    -- Send initialization message
    local message = {
        jsonrpc = "2.0",
        method = "initialize",
        params = {
            protocolVersion = "2025-06-18",
            capabilities = {},
        },
        id = mcp_transport.generate_message_id(),
    }
    
    local success, error = mcp_transport.send_message(message)
    if success then
        print("Initialization message sent")
    else
        print("Failed to send message:", error)
    end
end
```

## Performance API

### Module: `paragonic.mcp_performance`

The performance module provides monitoring and optimization features.

#### Initialization

```lua
local performance = require("paragonic.mcp_performance")

-- Initialize performance monitoring
function performance.init(config)
    -- config: Configuration table
    -- Returns: boolean success
end
```

**Configuration Options:**
```lua
{
    METRICS = {
        ENABLE_REAL_TIME_MONITORING = true,
        COLLECTION_INTERVAL = 5,
        RETENTION_PERIOD = 3600,
        MAX_METRICS_ENTRIES = 720,
    },
    THRESHOLDS = {
        REQUEST_TIMEOUT_WARNING = 2000,
        REQUEST_TIMEOUT_CRITICAL = 10000,
        MEMORY_USAGE_WARNING = 100,
        MEMORY_USAGE_CRITICAL = 200,
        CPU_USAGE_WARNING = 80,
        CPU_USAGE_CRITICAL = 95,
        CONCURRENT_REQUESTS_WARNING = 50,
        CONCURRENT_REQUESTS_CRITICAL = 100,
    },
    OPTIMIZATION = {
        ENAABLE_CONNECTION_POOLING = true,
        POOL_SIZE = 10,
        CONNECTION_TIMEOUT = 30,
        IDLE_TIMEOUT = 300,
        ENABLE_REQUEST_CACHING = true,
        CACHE_SIZE = 1000,
        CACHE_TTL = 300,
        ENABLE_COMPRESSION = true,
        COMPRESSION_LEVEL = 6,
    },
    PROFILING = {
        ENABLE_FUNCTION_PROFILING = true,
        ENABLE_MEMORY_PROFILING = true,
        ENABLE_NETWORK_PROFILING = true,
        PROFILE_SAMPLE_RATE = 0.1,
    },
}
```

#### Monitoring

```lua
-- Start performance monitoring
function performance.start_monitoring()
    -- Returns: boolean success
end

-- Stop performance monitoring
function performance.stop_monitoring()
    -- Returns: boolean success
end

-- Get performance metrics
function performance.get_metrics()
    -- Returns: metrics table
end

-- Get performance report
function performance.get_performance_report()
    -- Returns: report table
end
```

#### Alerts

```lua
-- Get performance alerts
function performance.get_alerts()
    -- Returns: array of alerts
end

-- Clear performance alerts
function performance.clear_alerts()
    -- Returns: boolean success
end
```

**Example:**
```lua
-- Initialize performance monitoring
performance.init({
    METRICS = {
        ENABLE_REAL_TIME_MONITORING = true,
        COLLECTION_INTERVAL = 5,
    },
    THRESHOLDS = {
        REQUEST_TIMEOUT_WARNING = 2000,
        MEMORY_USAGE_WARNING = 100,
    },
})

-- Start monitoring
performance.start_monitoring()

-- Get metrics periodically
local metrics = performance.get_metrics()
print("Active connections:", metrics.connection_pool_usage)
print("Memory usage:", metrics.memory_usage_mb, "MB")

-- Get alerts
local alerts = performance.get_alerts()
for _, alert in ipairs(alerts) do
    print("Alert:", alert.message)
end
```

## Debug API

### Module: `paragonic.debug`

The debug module provides debugging and logging functionality.

#### Debug Mode

```lua
local debug = require("paragonic.debug")

-- Enable debug mode
function debug.enable_debug_mode(enabled)
    -- enabled: boolean
    -- Returns: void
end

-- Check if debug mode is enabled
function debug.is_debug_mode_enabled()
    -- Returns: boolean enabled
end

-- Set log level
function debug.set_log_level(level)
    -- level: "debug", "info", "warn", "error"
    -- Returns: void
end

-- Get current log level
function debug.get_log_level()
    -- Returns: string level
end
```

#### Logging

```lua
-- Log debug message
function debug.log(message, level)
    -- message: Log message string
    -- level: Log level (optional)
    -- Returns: void
end

-- Log debug message with context
function debug.log_with_context(message, context, level)
    -- message: Log message string
    -- context: Context table
    -- level: Log level (optional)
    -- Returns: void
end
```

**Example:**
```lua
-- Enable debug mode
debug.enable_debug_mode(true)
debug.set_log_level("debug")

-- Log messages
debug.log("HTTP client initialized", "info")
debug.log_with_context("Request sent", {
    method = "POST",
    endpoint = "/mcp",
    data = { ... }
}, "debug")
```

## Configuration Reference

### HTTP Client Configuration

```lua
{
    -- Basic settings
    base_url = "http://localhost:3000",
    timeout = 30,
    retry_attempts = 3,
    retry_delay = 1,
    
    -- Headers
    headers = {
        ["Content-Type"] = "application/json",
        ["Accept"] = "application/json, text/event-stream",
        ["MCP-Protocol-Version"] = "2025-06-18",
    },
    
    -- Connection pooling
    connection_pool = {
        size = 10,
        timeout = 30,
        idle_timeout = 300,
    },
    
    -- Optimization
    optimization = {
        enable_keep_alive = true,
        keep_alive_timeout = 30,
        max_idle_connections = 5,
        connection_timeout = 10,
    },
    
    -- Security
    security = {
        validate_origin = true,
        session_timeout = 3600,
        max_request_size = 1024 * 1024,
    },
}
```

### SSE Client Configuration

```lua
{
    -- Basic settings
    base_url = "http://localhost:3000",
    timeout = 30,
    
    -- Reconnection
    reconnect_delay = 1,
    max_reconnect_attempts = 5,
    
    -- Event buffer
    event_buffer_size = 100,
}
```

### MCP Transport Configuration

```lua
{
    -- Basic settings
    base_url = "http://localhost:3000",
    protocol_version = "2025-06-18",
    
    -- Timeouts
    initialization_timeout = 30,
    request_timeout = 10,
    
    -- Reconnection
    reconnect_delay = 1,
    max_reconnect_attempts = 5,
    
    -- Event buffer
    event_buffer_size = 100,
}
```

## Error Handling

### Error Types

| Error Type | Description | Common Causes |
|------------|-------------|---------------|
| `connection_failed` | Unable to connect to server | Server not running, network issues |
| `timeout` | Request timed out | Server overload, network latency |
| `session_expired` | Session has expired | Session timeout, server restart |
| `pool_exhausted` | No available connections | High load, small pool size |
| `invalid_response` | Malformed server response | Server error, protocol mismatch |
| `invalid_request` | Invalid request format | Malformed data, missing parameters |

### Error Handling Patterns

```lua
-- Basic error handling
local response, error = http_client.get("/api/data")
if not response then
    if error == "connection_failed" then
        print("Server not reachable")
    elseif error == "timeout" then
        print("Request timed out")
    else
        print("Unknown error:", error)
    end
end

-- Retry pattern
local function make_request_with_retry(endpoint, max_retries)
    for attempt = 1, max_retries do
        local response, error = http_client.get(endpoint)
        if response then
            return response
        end
        
        if error == "session_expired" then
            -- Reinitialize session
            mcp_transport.initialize_session()
        elseif error == "pool_exhausted" then
            -- Wait and retry
            vim.wait(1000)
        else
            -- Don't retry on other errors
            break
        end
    end
    return nil, "Max retries exceeded"
end
```

## Examples

### Complete HTTP Client Example

```lua
local http_client = require("paragonic.http_client")

-- Initialize client
local success = http_client.init({
    base_url = "http://localhost:3000",
    timeout = 30,
    retry_attempts = 3,
    retry_delay = 1,
})

if not success then
    print("Failed to initialize HTTP client")
    return
end

-- Configure connection pooling
http_client.set_connection_pool_size(10)
http_client.set_optimization_config({
    enable_keep_alive = true,
    keep_alive_timeout = 30,
})

-- Set session ID
http_client.set_session_id("session-123")

-- Make requests
local response = http_client.post("/mcp", {
    jsonrpc = "2.0",
    method = "initialize",
    params = { protocolVersion = "2025-06-18" },
    id = 1,
})

if response and http_client.is_success(response) then
    print("Request successful:", response.body)
else
    print("Request failed:", http_client.get_error_message(response))
end

-- Check pool metrics
local metrics = http_client.get_connection_pool_metrics()
print("Pool usage:", metrics.usage_percentage, "%")

-- Cleanup
http_client.cleanup()
```

### Complete SSE Client Example

```lua
local sse_client = require("paragonic.sse_client")

-- Initialize SSE client
local success = sse_client.init({
    base_url = "http://localhost:3000",
    timeout = 30,
    reconnect_delay = 1,
    max_reconnect_attempts = 5,
})

if not success then
    print("Failed to initialize SSE client")
    return
end

-- Set session ID
sse_client.set_session_id("session-123")

-- Set up event handlers
sse_client.set_callback("message", function(event)
    print("Received message:", event.data)
end)

sse_client.set_callback("error", function(event)
    print("SSE error:", event.data)
end)

-- Connect to stream
local success, error = sse_client.connect("mcp-stream")
if success then
    print("Connected to SSE stream")
else
    print("Failed to connect:", error)
end

-- Disconnect when done
sse_client.disconnect()
```

### Complete MCP Transport Example

```lua
local mcp_transport = require("paragonic.mcp_http_transport")

-- Initialize MCP transport
local success, error = mcp_transport.init({
    base_url = "http://localhost:3000",
    protocol_version = "2025-06-18",
    initialization_timeout = 30,
    request_timeout = 10,
})

if not success then
    print("Failed to initialize MCP transport:", error)
    return
end

-- Set up callbacks
mcp_transport.set_callbacks({
    on_message = function(message)
        print("MCP message received:", message)
    end,
    on_error = function(error)
        print("MCP error:", error)
    end,
    on_connect = function()
        print("MCP connected")
    end,
    on_disconnect = function()
        print("MCP disconnected")
    end,
})

-- Initialize session
local success, session_id = mcp_transport.initialize_session()
if success then
    print("MCP session initialized:", session_id)
    
    -- Send initialization message
    local message = {
        jsonrpc = "2.0",
        method = "initialize",
        params = {
            protocolVersion = "2025-06-18",
            capabilities = {},
        },
        id = mcp_transport.generate_message_id(),
    }
    
    local success, error = mcp_transport.send_message(message)
    if success then
        print("Initialization message sent")
    else
        print("Failed to send message:", error)
    end
else
    print("Failed to initialize session:", session_id)
end

-- Terminate session when done
mcp_transport.terminate_session()
```

This API documentation provides comprehensive coverage of all HTTP transport functionality, including detailed function signatures, configuration options, error handling patterns, and complete usage examples.
