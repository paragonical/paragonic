# HTTP Transport Documentation

## Overview

The HTTP Transport implementation provides a modern, scalable alternative to TCP-based communication for the Model Context Protocol (MCP). This document provides comprehensive documentation for the HTTP transport system, including architecture, implementation details, configuration, and usage examples.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Server Implementation](#server-implementation)
3. [Client Implementation](#client-implementation)
4. [Connection Pooling](#connection-pooling)
5. [Security Features](#security-features)
6. [Performance Optimization](#performance-optimization)
7. [Configuration](#configuration)
8. [API Reference](#api-reference)
9. [Usage Examples](#usage-examples)
10. [Troubleshooting](#troubleshooting)

## Architecture Overview

### System Components

The HTTP transport system consists of several key components:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Neovim Client │    │  HTTP Transport │    │  Rust Backend   │
│   (Lua)         │◄──►│   (Lua/Rust)    │◄──►│   (Rust)        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        │                       │                       │
        ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  HTTP Client    │    │  SSE Client     │    │  HTTP Server    │
│  (Connection    │    │  (Event Stream) │    │  (Axum)         │
│   Pooling)      │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Transport Flow

1. **Initialization**: Client establishes connection with server
2. **Session Management**: Secure session ID generation and validation
3. **Request/Response**: HTTP-based JSON-RPC communication
4. **Streaming**: Server-Sent Events (SSE) for real-time updates
5. **Connection Pooling**: Optimized connection reuse and management

## Server Implementation

### Rust HTTP Server (Axum)

The server is implemented using the Axum web framework in Rust, providing high performance and type safety.

#### Key Features

- **MCP Endpoint**: `/mcp` endpoint handling POST/GET/DELETE requests
- **Session Management**: Secure UUID-based session handling
- **SSE Streaming**: Real-time event streaming support
- **Security**: OWASP Top 10 security enhancements
- **Performance**: Async/await for non-blocking operations

#### Server Configuration

```rust
// Example server configuration
let app = Router::new()
    .route("/mcp", post(handle_mcp_request))
    .route("/mcp", get(handle_sse_stream))
    .route("/mcp", delete(handle_session_cleanup))
    .layer(CorsLayer::permissive())
    .layer(DefaultBodyLimit::max(1024 * 1024)); // 1MB limit
```

#### Session Management

```rust
// Session creation and validation
pub async fn create_session() -> Result<SessionId, Error> {
    let session_id = SessionId::new_v4();
    // Store session state
    Ok(session_id)
}

pub async fn validate_session(session_id: &SessionId) -> Result<bool, Error> {
    // Validate session and check expiration
    Ok(true)
}
```

## Client Implementation

### Lua HTTP Client

The client is implemented in Lua for Neovim integration, providing seamless MCP communication.

#### Core Features

- **Request Building**: Dynamic HTTP request construction
- **Response Parsing**: JSON-RPC response handling
- **Error Recovery**: Automatic retry and reconnection
- **Session Persistence**: Session ID management
- **Connection Pooling**: Optimized connection reuse

#### Client Configuration

```lua
-- Initialize HTTP client
local http_client = require("paragonic.http_client")

local config = {
    base_url = "http://localhost:3000",
    timeout = 30,
    retry_attempts = 3,
    retry_delay = 1,
    headers = {
        ["Content-Type"] = "application/json",
        ["Accept"] = "application/json, text/event-stream",
        ["MCP-Protocol-Version"] = "2025-06-18",
    }
}

http_client.init(config)
```

## Connection Pooling

### Overview

Connection pooling provides significant performance improvements by reusing HTTP connections, reducing connection overhead and improving response times.

### Features

- **Configurable Pool Size**: Adjustable connection pool limits
- **Connection Reuse**: Efficient connection lifecycle management
- **Keep-Alive Support**: HTTP keep-alive optimization
- **Metrics Monitoring**: Real-time connection pool statistics
- **Automatic Cleanup**: Expired connection cleanup

### Configuration

```lua
-- Configure connection pooling
http_client.set_connection_pool_size(10)
http_client.set_optimization_config({
    enable_keep_alive = true,
    keep_alive_timeout = 30,
    max_idle_connections = 5,
    connection_timeout = 10,
})
```

### Usage

```lua
-- Get connection from pool
local connection = http_client.get_connection()
if connection then
    -- Use connection for HTTP request
    local response = http_client.get("/mcp")
    -- Return connection to pool
    http_client.return_connection(connection)
end
```

### Performance Metrics

```lua
-- Get connection pool metrics
local metrics = http_client.get_connection_pool_metrics()
print("Active connections:", metrics.active_connections)
print("Available connections:", metrics.available_connections)
print("Usage percentage:", metrics.usage_percentage)
```

## Security Features

### OWASP Top 10 Compliance

The HTTP transport implementation includes comprehensive security measures:

1. **Input Validation**: All inputs are validated and sanitized
2. **Authentication**: Session-based authentication
3. **Authorization**: Access control for MCP operations
4. **Data Protection**: Secure data transmission
5. **Error Handling**: Secure error messages without information leakage

### Security Configuration

```lua
-- Security settings
local security_config = {
    validate_origin = true,
    allowed_origins = {"http://localhost:3000"},
    session_timeout = 3600, -- 1 hour
    max_request_size = 1024 * 1024, -- 1MB
    enable_cors = true,
}
```

## Performance Optimization

### Optimization Features

- **Connection Pooling**: Reduces connection overhead
- **Keep-Alive**: Maintains persistent connections
- **Request Caching**: Caches frequently requested data
- **Compression**: HTTP compression for large responses
- **Async Operations**: Non-blocking request handling

### Performance Monitoring

```lua
-- Performance monitoring
local performance = require("paragonic.mcp_performance")

performance.init({
    METRICS = {
        ENABLE_REAL_TIME_MONITORING = true,
        COLLECTION_INTERVAL = 5,
        MAX_METRICS_ENTRIES = 720,
    },
    THRESHOLDS = {
        REQUEST_TIMEOUT_WARNING = 2000,
        REQUEST_TIMEOUT_CRITICAL = 10000,
        MEMORY_USAGE_WARNING = 100,
        MEMORY_USAGE_CRITICAL = 200,
    },
})
```

## Configuration

### Server Configuration

```toml
# Server configuration (Rust)
[server]
host = "127.0.0.1"
port = 3000
max_connections = 100
session_timeout = 3600
enable_cors = true

[security]
validate_origin = true
allowed_origins = ["http://localhost:3000"]
max_request_size = 1048576
```

### Client Configuration

```lua
-- Client configuration (Lua)
local config = {
    -- Basic settings
    base_url = "http://localhost:3000",
    timeout = 30,
    retry_attempts = 3,
    retry_delay = 1,
    
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

## API Reference

### HTTP Client API

#### Initialization

```lua
-- Initialize HTTP client
function http_client.init(config)
    -- config: Configuration table
    -- Returns: boolean success
end
```

#### Request Methods

```lua
-- Send GET request
function http_client.get(endpoint, custom_headers)
    -- endpoint: Request endpoint
    -- custom_headers: Optional custom headers
    -- Returns: response table or nil, error
end

-- Send POST request
function http_client.post(endpoint, data, custom_headers)
    -- endpoint: Request endpoint
    -- data: Request data
    -- custom_headers: Optional custom headers
    -- Returns: response table or nil, error
end

-- Send DELETE request
function http_client.delete(endpoint, custom_headers)
    -- endpoint: Request endpoint
    -- custom_headers: Optional custom headers
    -- Returns: response table or nil, error
end
```

#### Connection Pooling API

```lua
-- Get connection from pool
function http_client.get_connection()
    -- Returns: connection object or nil, error
end

-- Return connection to pool
function http_client.return_connection(connection)
    -- connection: Connection object
    -- Returns: boolean success
end

-- Get connection pool metrics
function http_client.get_connection_pool_metrics()
    -- Returns: metrics table
end

-- Set connection pool size
function http_client.set_connection_pool_size(size)
    -- size: Pool size (number)
    -- Returns: boolean success
end
```

#### Configuration API

```lua
-- Set optimization configuration
function http_client.set_optimization_config(config)
    -- config: Optimization configuration table
    -- Returns: boolean success
end

-- Get optimization configuration
function http_client.get_optimization_config()
    -- Returns: configuration table
end

-- Reset connection pool
function http_client.reset_connection_pool()
    -- Returns: boolean success
end
```

### SSE Client API

```lua
-- Initialize SSE client
function sse_client.init(config)
    -- config: Configuration table
    -- Returns: boolean success
end

-- Connect to SSE stream
function sse_client.connect(stream_id)
    -- stream_id: Stream identifier
    -- Returns: boolean success
end

-- Disconnect from SSE stream
function sse_client.disconnect()
    -- Returns: boolean success
end

-- Set event callback
function sse_client.set_callback(event_type, callback)
    -- event_type: Event type string
    -- callback: Callback function
    -- Returns: boolean success
end
```

## Usage Examples

### Basic HTTP Client Usage

```lua
-- Initialize client
local http_client = require("paragonic.http_client")
http_client.init({
    base_url = "http://localhost:3000",
    timeout = 30,
})

-- Send MCP request
local response = http_client.post("/mcp", {
    jsonrpc = "2.0",
    method = "initialize",
    params = {
        protocolVersion = "2025-06-18",
        capabilities = {},
    },
    id = 1,
})

if response and http_client.is_success(response) then
    print("Request successful:", response.body)
else
    print("Request failed:", http_client.get_error_message(response))
end
```

### Connection Pooling Usage

```lua
-- Configure connection pooling
http_client.set_connection_pool_size(5)
http_client.set_optimization_config({
    enable_keep_alive = true,
    keep_alive_timeout = 30,
})

-- Make multiple requests (connections are automatically pooled)
for i = 1, 10 do
    local response = http_client.get("/mcp")
    if response then
        print("Request", i, "completed")
    end
end

-- Check pool metrics
local metrics = http_client.get_connection_pool_metrics()
print("Pool usage:", metrics.usage_percentage, "%")
```

### SSE Client Usage

```lua
-- Initialize SSE client
local sse_client = require("paragonic.sse_client")
sse_client.init({
    base_url = "http://localhost:3000",
    timeout = 30,
})

-- Set up event handlers
sse_client.set_callback("message", function(event)
    print("Received message:", event.data)
end)

sse_client.set_callback("error", function(event)
    print("SSE error:", event.data)
end)

-- Connect to stream
sse_client.connect("mcp-stream")
```

### MCP Transport Integration

```lua
-- Initialize MCP HTTP transport
local mcp_transport = require("paragonic.mcp_http_transport")
mcp_transport.init({
    base_url = "http://localhost:3000",
    protocol_version = "2025-06-18",
    initialization_timeout = 30,
    request_timeout = 10,
})

-- Set up callbacks
mcp_transport.set_callbacks({
    on_message = function(message)
        print("MCP message received:", message)
    end,
    on_error = function(error)
        print("MCP error:", error)
    end,
})

-- Initialize MCP session
local success, session_id = mcp_transport.initialize_session()
if success then
    print("MCP session initialized:", session_id)
end
```

## Troubleshooting

### Common Issues

#### Connection Failures

**Problem**: HTTP requests fail with connection errors

**Solutions**:
1. Verify server is running on correct port
2. Check firewall settings
3. Validate base URL configuration
4. Test network connectivity

```lua
-- Test server connectivity
local response = http_client.get("/health")
if not response then
    print("Server not reachable")
end
```

#### Connection Pool Exhaustion

**Problem**: "No available connections" errors

**Solutions**:
1. Increase pool size
2. Check for connection leaks
3. Reduce concurrent requests
4. Enable connection cleanup

```lua
-- Increase pool size
http_client.set_connection_pool_size(20)

-- Check pool metrics
local metrics = http_client.get_connection_pool_metrics()
print("Pool status:", metrics.active_connections, "/", metrics.max_size)
```

#### Performance Issues

**Problem**: Slow response times

**Solutions**:
1. Enable connection pooling
2. Configure keep-alive
3. Optimize request frequency
4. Monitor performance metrics

```lua
-- Enable optimization
http_client.set_optimization_config({
    enable_keep_alive = true,
    keep_alive_timeout = 30,
    max_idle_connections = 10,
})
```

#### Session Expiration

**Problem**: Session timeout errors

**Solutions**:
1. Increase session timeout
2. Implement session refresh
3. Handle reconnection logic
4. Check server session configuration

```lua
-- Handle session expiration
if response and response.status_code == 401 then
    -- Reinitialize session
    local success = mcp_transport.initialize_session()
    if success then
        -- Retry request
        response = http_client.post("/mcp", request_data)
    end
end
```

### Debugging

#### Enable Debug Logging

```lua
-- Enable debug mode
local debug = require("paragonic.debug")
debug.enable_debug_mode(true)

-- Set log level
debug.set_log_level("debug")
```

#### Performance Monitoring

```lua
-- Monitor performance
local performance = require("paragonic.mcp_performance")
performance.start_monitoring()

-- Get performance report
local report = performance.get_performance_report()
print("Performance report:", report)
```

### Error Codes

| Error Code | Description | Solution |
|------------|-------------|----------|
| `connection_failed` | Unable to connect to server | Check server status and network |
| `timeout` | Request timed out | Increase timeout or check server load |
| `session_expired` | Session has expired | Reinitialize session |
| `pool_exhausted` | No available connections | Increase pool size or reduce load |
| `invalid_response` | Malformed server response | Check server implementation |

## Best Practices

### Performance Optimization

1. **Use Connection Pooling**: Always enable connection pooling for production
2. **Configure Keep-Alive**: Enable HTTP keep-alive for persistent connections
3. **Monitor Metrics**: Regularly check connection pool and performance metrics
4. **Optimize Pool Size**: Set appropriate pool size based on expected load
5. **Handle Errors Gracefully**: Implement proper error handling and recovery

### Security Considerations

1. **Validate Inputs**: Always validate and sanitize all inputs
2. **Use HTTPS**: Use HTTPS in production environments
3. **Session Management**: Implement proper session timeout and cleanup
4. **Access Control**: Validate session permissions for all operations
5. **Error Handling**: Avoid information leakage in error messages

### Configuration Guidelines

1. **Environment-Specific Config**: Use different configurations for dev/staging/prod
2. **Resource Limits**: Set appropriate timeouts and size limits
3. **Monitoring**: Enable performance monitoring in production
4. **Logging**: Configure appropriate log levels for different environments
5. **Backup Strategy**: Implement fallback mechanisms for reliability

## Conclusion

The HTTP transport implementation provides a robust, scalable, and secure alternative to TCP-based MCP communication. With comprehensive connection pooling, performance optimization, and security features, it's ready for production use in modern development environments.

For additional support or questions, please refer to the project documentation or create an issue in the project repository.
