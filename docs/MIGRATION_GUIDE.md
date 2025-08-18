# Migration Guide: TCP to HTTP Transport

## Overview

This guide helps existing users migrate from the TCP-based Model Context Protocol (MCP) transport to the new HTTP transport implementation. The HTTP transport provides improved performance, better security, and enhanced scalability.

## Table of Contents

1. [Why Migrate to HTTP Transport?](#why-migrate-to-http-transport)
2. [Migration Checklist](#migration-checklist)
3. [Step-by-Step Migration](#step-by-step-migration)
4. [Configuration Changes](#configuration-changes)
5. [Code Changes](#code-changes)
6. [Testing Migration](#testing-migration)
7. [Troubleshooting](#troubleshooting)
8. [Rollback Plan](#rollback-plan)

## Why Migrate to HTTP Transport?

### Benefits

- **Better Performance**: Connection pooling and keep-alive support
- **Enhanced Security**: OWASP Top 10 compliance and session management
- **Improved Scalability**: HTTP-based load balancing and caching
- **Better Monitoring**: Comprehensive performance metrics and debugging
- **Standard Protocol**: Uses widely-supported HTTP/HTTPS standards
- **Easier Deployment**: Works through firewalls and proxies

### Compatibility

The HTTP transport maintains full backward compatibility with existing MCP functionality while providing new features and improvements.

## Migration Checklist

### Pre-Migration

- [ ] Review current TCP transport configuration
- [ ] Identify all MCP client connections
- [ ] Document current performance metrics
- [ ] Create backup of current configuration
- [ ] Test HTTP transport in development environment
- [ ] Plan migration timeline

### During Migration

- [ ] Update configuration files
- [ ] Modify client initialization code
- [ ] Update error handling
- [ ] Test all MCP functionality
- [ ] Monitor performance metrics
- [ ] Validate security settings

### Post-Migration

- [ ] Verify all functionality works correctly
- [ ] Monitor performance improvements
- [ ] Update documentation
- [ ] Train users on new features
- [ ] Plan future optimizations

## Step-by-Step Migration

### Step 1: Install HTTP Transport

The HTTP transport is included in the latest version of the paragonic plugin. Update your plugin:

```lua
-- If using lazy.nvim
{
    "paragonic/paragonic",
    config = function()
        require("paragonic").setup({
            transport = "http", -- Enable HTTP transport
        })
    end,
}

-- If using packer
use {
    "paragonic/paragonic",
    config = function()
        require("paragonic").setup({
            transport = "http",
        })
    end,
}
```

### Step 2: Update Configuration

#### Old TCP Configuration

```lua
-- Old TCP configuration
local config = {
    transport = "tcp",
    host = "localhost",
    port = 3000,
    timeout = 30,
    retry_attempts = 3,
}
```

#### New HTTP Configuration

```lua
-- New HTTP configuration
local config = {
    transport = "http",
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

### Step 3: Update Client Initialization

#### Old TCP Initialization

```lua
-- Old TCP client initialization
local mcp_client = require("paragonic.mcp_client")
mcp_client.init({
    transport = "tcp",
    host = "localhost",
    port = 3000,
})
```

#### New HTTP Initialization

```lua
-- New HTTP client initialization
local mcp_transport = require("paragonic.mcp_http_transport")
mcp_transport.init({
    base_url = "http://localhost:3000",
    protocol_version = "2025-06-18",
    initialization_timeout = 30,
    request_timeout = 10,
})
```

### Step 4: Update Error Handling

#### Old TCP Error Handling

```lua
-- Old TCP error handling
local success, error = mcp_client.connect()
if not success then
    if error == "connection_refused" then
        print("Server not running")
    elseif error == "timeout" then
        print("Connection timeout")
    end
end
```

#### New HTTP Error Handling

```lua
-- New HTTP error handling
local success, session_id = mcp_transport.initialize_session()
if not success then
    if session_id == "connection_failed" then
        print("Server not reachable")
    elseif session_id == "timeout" then
        print("Initialization timeout")
    elseif session_id == "session_expired" then
        print("Session expired")
    end
end
```

## Configuration Changes

### Transport Selection

The new HTTP transport can be configured to work alongside or replace the TCP transport:

```lua
-- Use HTTP transport only
local config = {
    transport = "http",
    -- HTTP-specific configuration
}

-- Use HTTP with TCP fallback
local config = {
    transport = "http",
    fallback_transport = "tcp",
    -- Configuration for both transports
}

-- Use TCP transport only (backward compatibility)
local config = {
    transport = "tcp",
    -- TCP-specific configuration
}
```

### Environment-Specific Configuration

```lua
-- Development configuration
local dev_config = {
    transport = "http",
    base_url = "http://localhost:3000",
    debug = true,
    connection_pool = { size = 5 },
}

-- Production configuration
local prod_config = {
    transport = "http",
    base_url = "https://mcp.example.com",
    debug = false,
    connection_pool = { size = 20 },
    security = {
        validate_origin = true,
        session_timeout = 3600,
    },
}
```

## Code Changes

### Client Module Changes

#### Old TCP Client Usage

```lua
-- Old TCP client usage
local mcp_client = require("paragonic.mcp_client")

-- Initialize
mcp_client.init(config)

-- Connect
local success = mcp_client.connect()
if success then
    -- Send message
    local response = mcp_client.send_message(message)
end

-- Disconnect
mcp_client.disconnect()
```

#### New HTTP Client Usage

```lua
-- New HTTP client usage
local mcp_transport = require("paragonic.mcp_http_transport")

-- Initialize
mcp_transport.init(config)

-- Set up callbacks
mcp_transport.set_callbacks({
    on_message = function(message)
        -- Handle incoming messages
    end,
    on_error = function(error)
        -- Handle errors
    end,
})

-- Initialize session
local success, session_id = mcp_transport.initialize_session()
if success then
    -- Send message
    local success, error = mcp_transport.send_message(message)
end

-- Terminate session
mcp_transport.terminate_session()
```

### Message Handling Changes

#### Old TCP Message Handling

```lua
-- Old TCP message handling
local function handle_message(message)
    if message.method == "initialize" then
        -- Handle initialization
    elseif message.method == "notifications/list" then
        -- Handle notifications
    end
end

mcp_client.set_message_handler(handle_message)
```

#### New HTTP Message Handling

```lua
-- New HTTP message handling
mcp_transport.set_callbacks({
    on_message = function(message)
        if message.method == "initialize" then
            -- Handle initialization
        elseif message.method == "notifications/list" then
            -- Handle notifications
        end
    end,
    on_error = function(error)
        print("MCP error:", error)
    end,
})
```

### Session Management Changes

#### Old TCP Session Management

```lua
-- Old TCP session management (implicit)
local success = mcp_client.connect()
if success then
    -- Session is automatically managed
    mcp_client.send_message(message)
end
```

#### New HTTP Session Management

```lua
-- New HTTP session management (explicit)
local success, session_id = mcp_transport.initialize_session()
if success then
    print("Session ID:", session_id)
    
    -- Session is explicitly managed
    mcp_transport.send_message(message)
    
    -- Terminate session when done
    mcp_transport.terminate_session()
end
```

## Testing Migration

### Pre-Migration Testing

1. **Backup Current State**
   ```lua
   -- Save current configuration
   local current_config = vim.g.paragonic_config
   vim.fn.writefile(vim.json.encode(current_config), "backup_config.json")
   ```

2. **Document Current Performance**
   ```lua
   -- Record current metrics
   local metrics = {
       connection_time = 0,
       message_latency = 0,
       error_rate = 0,
   }
   ```

### Migration Testing

1. **Test Basic Functionality**
   ```lua
   -- Test HTTP transport initialization
   local success, error = mcp_transport.init(config)
   assert(success, "HTTP transport initialization failed: " .. error)
   
   -- Test session initialization
   local success, session_id = mcp_transport.initialize_session()
   assert(success, "Session initialization failed: " .. session_id)
   ```

2. **Test Message Sending**
   ```lua
   -- Test message sending
   local message = {
       jsonrpc = "2.0",
       method = "initialize",
       params = { protocolVersion = "2025-06-18" },
       id = "test-1",
   }
   
   local success, error = mcp_transport.send_message(message)
   assert(success, "Message sending failed: " .. error)
   ```

3. **Test Error Handling**
   ```lua
   -- Test error scenarios
   local success, error = mcp_transport.init({ base_url = "http://invalid" })
   assert(not success, "Should fail with invalid URL")
   ```

### Post-Migration Testing

1. **Performance Comparison**
   ```lua
   -- Compare performance metrics
   local http_metrics = {
       connection_time = 0,
       message_latency = 0,
       error_rate = 0,
   }
   
   -- Verify improvements
   assert(http_metrics.connection_time < tcp_metrics.connection_time)
   assert(http_metrics.message_latency < tcp_metrics.message_latency)
   ```

2. **Functionality Verification**
   ```lua
   -- Test all MCP features
   local features = {
       "initialize",
       "notifications/list",
       "notifications/show",
       "tools/list",
       "tools/call",
   }
   
   for _, feature in ipairs(features) do
       local success = test_feature(feature)
       assert(success, "Feature " .. feature .. " failed")
   end
   ```

## Troubleshooting

### Common Migration Issues

#### Issue: Connection Failures

**Symptoms**: HTTP transport fails to connect to server

**Solutions**:
1. Verify server is running and accessible
2. Check firewall settings
3. Validate base URL configuration
4. Test network connectivity

```lua
-- Test server connectivity
local http_client = require("paragonic.http_client")
local response = http_client.get("/health")
if not response then
    print("Server not reachable")
end
```

#### Issue: Session Expiration

**Symptoms**: Session timeout errors after migration

**Solutions**:
1. Increase session timeout
2. Implement session refresh logic
3. Handle reconnection automatically

```lua
-- Handle session expiration
if response and response.status_code == 401 then
    -- Reinitialize session
    local success = mcp_transport.initialize_session()
    if success then
        -- Retry request
        response = mcp_transport.send_message(message)
    end
end
```

#### Issue: Performance Degradation

**Symptoms**: Slower response times after migration

**Solutions**:
1. Enable connection pooling
2. Configure keep-alive
3. Optimize pool size
4. Monitor performance metrics

```lua
-- Enable optimization
http_client.set_optimization_config({
    enable_keep_alive = true,
    keep_alive_timeout = 30,
    max_idle_connections = 10,
})
```

#### Issue: Configuration Errors

**Symptoms**: Configuration validation failures

**Solutions**:
1. Validate configuration format
2. Check required fields
3. Use configuration validation

```lua
-- Validate configuration
local function validate_config(config)
    assert(config.base_url, "base_url is required")
    assert(config.timeout, "timeout is required")
    assert(config.timeout > 0, "timeout must be positive")
    return true
end

local success = validate_config(config)
if not success then
    print("Invalid configuration")
end
```

### Debugging Migration Issues

#### Enable Debug Logging

```lua
-- Enable debug mode
local debug = require("paragonic.debug")
debug.enable_debug_mode(true)
debug.set_log_level("debug")

-- Monitor HTTP transport
debug.log("HTTP transport initialized", "info")
debug.log_with_context("Request sent", {
    method = "POST",
    endpoint = "/mcp",
}, "debug")
```

#### Performance Monitoring

```lua
-- Monitor performance during migration
local performance = require("paragonic.mcp_performance")
performance.start_monitoring()

-- Get performance report
local report = performance.get_performance_report()
print("Performance report:", report)
```

#### Connection Pool Monitoring

```lua
-- Monitor connection pool
local http_client = require("paragonic.http_client")
local metrics = http_client.get_connection_pool_metrics()
print("Pool usage:", metrics.usage_percentage, "%")
print("Active connections:", metrics.active_connections)
```

## Rollback Plan

### Emergency Rollback

If issues arise during migration, you can quickly rollback to TCP transport:

```lua
-- Emergency rollback configuration
local rollback_config = {
    transport = "tcp",
    host = "localhost",
    port = 3000,
    timeout = 30,
}

-- Restore TCP transport
local mcp_client = require("paragonic.mcp_client")
mcp_client.init(rollback_config)
```

### Gradual Rollback

For more controlled rollback:

```lua
-- Gradual rollback with fallback
local config = {
    transport = "http",
    fallback_transport = "tcp",
    fallback_enabled = true,
    fallback_conditions = {
        connection_failures = 3,
        timeout_threshold = 5000,
    },
}
```

### Data Backup

Before migration, ensure all data is backed up:

```lua
-- Backup current state
local function backup_state()
    local state = {
        config = vim.g.paragonic_config,
        sessions = mcp_client.get_active_sessions(),
        metrics = performance.get_metrics(),
    }
    
    local json = vim.json.encode(state)
    vim.fn.writefile(json, "migration_backup.json")
end

backup_state()
```

## Migration Timeline

### Phase 1: Preparation (1-2 days)

- [ ] Review current implementation
- [ ] Set up development environment
- [ ] Install HTTP transport
- [ ] Create migration plan

### Phase 2: Development Testing (2-3 days)

- [ ] Test HTTP transport in development
- [ ] Update configuration
- [ ] Modify client code
- [ ] Test all functionality

### Phase 3: Staging Testing (1-2 days)

- [ ] Deploy to staging environment
- [ ] Perform integration testing
- [ ] Load testing
- [ ] Security testing

### Phase 4: Production Migration (1 day)

- [ ] Deploy to production
- [ ] Monitor performance
- [ ] Verify functionality
- [ ] Update documentation

### Phase 5: Post-Migration (1 week)

- [ ] Monitor performance
- [ ] Gather user feedback
- [ ] Optimize configuration
- [ ] Plan future improvements

## Support and Resources

### Documentation

- [HTTP Transport Documentation](HTTP_TRANSPORT_DOCUMENTATION.md)
- [API Reference](HTTP_TRANSPORT_API.md)
- [Performance Guide](PERFORMANCE_GUIDE.md)

### Community Support

- GitHub Issues: Report bugs and request features
- Discussions: Ask questions and share experiences
- Wiki: Community-maintained documentation

### Migration Support

If you encounter issues during migration:

1. Check the troubleshooting section above
2. Review the documentation
3. Search existing issues
4. Create a new issue with detailed information

### Contact Information

- **Repository**: https://github.com/paragonic/paragonic
- **Issues**: https://github.com/paragonic/paragonic/issues
- **Discussions**: https://github.com/paragonic/paragonic/discussions

## Conclusion

The migration from TCP to HTTP transport provides significant benefits in terms of performance, security, and scalability. By following this guide, you can ensure a smooth transition with minimal disruption to your existing workflow.

The HTTP transport maintains full backward compatibility while providing new features and improvements. Take your time during the migration process, test thoroughly, and don't hesitate to seek support if needed.

Remember to monitor performance after migration and optimize your configuration based on your specific use case and requirements.
