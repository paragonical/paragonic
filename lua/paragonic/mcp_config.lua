-- MCP Configuration Module
-- 
-- This module provides configuration management for MCP transport
-- selection and settings, supporting both HTTP and TCP transports.

local mcp_config = {}

-- Configuration file path
local CONFIG_FILE = vim.fn.stdpath("config") .. "/paragonic_mcp.json"

-- Default configuration
local DEFAULT_CONFIG = {
    transport = {
        type = "auto", -- "auto", "http", "tcp"
        http = {
            base_url = "http://localhost:3000",
            protocol_version = "2025-06-18",
            initialization_timeout = 30,
            request_timeout = 60,
            reconnect_delay = 1,
            max_reconnect_attempts = 5,
            event_buffer_size = 100,
        },
        tcp = {
            host = "localhost",
            port = 3000,
            timeout = 30,
            retry_attempts = 3,
        },
        adapter = {
            fallback_timeout = 5,
            health_check_interval = 30,
        },
    },
    client = {
        name = "paragonic-client",
        version = "1.0.0",
        capabilities = {},
    },
    logging = {
        level = "info", -- "debug", "info", "warn", "error"
        enabled = true,
        file = nil, -- Set to file path for file logging
    },
}

-- Current configuration
local current_config = {}

-- Load configuration from file
function mcp_config.load()
    local success, content = pcall(vim.fn.readfile, CONFIG_FILE)
    if not success then
        -- Use default configuration if file doesn't exist
        current_config = vim.deepcopy(DEFAULT_CONFIG)
        return current_config
    end
    
    -- Parse JSON content
    local success2, parsed = pcall(vim.json.decode, table.concat(content, "\n"))
    if not success2 then
        -- Use default configuration if parsing fails
        current_config = vim.deepcopy(DEFAULT_CONFIG)
        return current_config
    end
    
    -- Merge with defaults
    current_config = vim.tbl_deep_extend("force", vim.deepcopy(DEFAULT_CONFIG), parsed)
    return current_config
end

-- Save configuration to file
function mcp_config.save()
    local json_content = vim.json.encode(current_config, { indent = 2 })
    vim.fn.writefile(vim.fn.split(json_content, "\n"), CONFIG_FILE)
end

-- Get current configuration
function mcp_config.get()
    if not current_config.transport then
        mcp_config.load()
    end
    return current_config
end

-- Set configuration
function mcp_config.set(config)
    current_config = vim.tbl_deep_extend("force", current_config, config)
end

-- Get transport configuration
function mcp_config.get_transport_config()
    local config = mcp_config.get()
    return config.transport
end

-- Set transport type
function mcp_config.set_transport_type(transport_type)
    if not current_config.transport then
        mcp_config.load()
    end
    
    if transport_type == "auto" or transport_type == "http" or transport_type == "tcp" then
        current_config.transport.type = transport_type
        return true
    else
        return false, "Invalid transport type: " .. tostring(transport_type)
    end
end

-- Get transport type
function mcp_config.get_transport_type()
    local config = mcp_config.get()
    return config.transport.type
end

-- Get HTTP transport configuration
function mcp_config.get_http_config()
    local config = mcp_config.get()
    return config.transport.http
end

-- Set HTTP transport configuration
function mcp_config.set_http_config(http_config)
    if not current_config.transport then
        mcp_config.load()
    end
    
    current_config.transport.http = vim.tbl_deep_extend("force", current_config.transport.http, http_config)
end

-- Get TCP transport configuration
function mcp_config.get_tcp_config()
    local config = mcp_config.get()
    return config.transport.tcp
end

-- Set TCP transport configuration
function mcp_config.set_tcp_config(tcp_config)
    if not current_config.transport then
        mcp_config.load()
    end
    
    current_config.transport.tcp = vim.tbl_deep_extend("force", current_config.transport.tcp, tcp_config)
end

-- Get adapter configuration
function mcp_config.get_adapter_config()
    local config = mcp_config.get()
    return config.transport.adapter
end

-- Set adapter configuration
function mcp_config.set_adapter_config(adapter_config)
    if not current_config.transport then
        mcp_config.load()
    end
    
    current_config.transport.adapter = vim.tbl_deep_extend("force", current_config.transport.adapter, adapter_config)
end

-- Get client configuration
function mcp_config.get_client_config()
    local config = mcp_config.get()
    return config.client
end

-- Set client configuration
function mcp_config.set_client_config(client_config)
    if not current_config.client then
        mcp_config.load()
    end
    
    current_config.client = vim.tbl_deep_extend("force", current_config.client, client_config)
end

-- Get logging configuration
function mcp_config.get_logging_config()
    local config = mcp_config.get()
    return config.logging
end

-- Set logging configuration
function mcp_config.set_logging_config(logging_config)
    if not current_config.logging then
        mcp_config.load()
    end
    
    current_config.logging = vim.tbl_deep_extend("force", current_config.logging, logging_config)
end

-- Validate configuration
function mcp_config.validate()
    local config = mcp_config.get()
    
    -- Validate transport type
    if config.transport.type ~= "auto" and config.transport.type ~= "http" and config.transport.type ~= "tcp" then
        return false, "Invalid transport type: " .. tostring(config.transport.type)
    end
    
    -- Validate HTTP configuration
    if config.transport.http.base_url and type(config.transport.http.base_url) ~= "string" then
        return false, "HTTP base_url must be a string"
    end
    
    if config.transport.http.protocol_version and type(config.transport.http.protocol_version) ~= "string" then
        return false, "HTTP protocol_version must be a string"
    end
    
    if config.transport.http.initialization_timeout and type(config.transport.http.initialization_timeout) ~= "number" then
        return false, "HTTP initialization_timeout must be a number"
    end
    
    if config.transport.http.request_timeout and type(config.transport.http.request_timeout) ~= "number" then
        return false, "HTTP request_timeout must be a number"
    end
    
    -- Validate TCP configuration
    if config.transport.tcp.host and type(config.transport.tcp.host) ~= "string" then
        return false, "TCP host must be a string"
    end
    
    if config.transport.tcp.port and type(config.transport.tcp.port) ~= "number" then
        return false, "TCP port must be a number"
    end
    
    -- Validate client configuration
    if config.client.name and type(config.client.name) ~= "string" then
        return false, "Client name must be a string"
    end
    
    if config.client.version and type(config.client.version) ~= "string" then
        return false, "Client version must be a string"
    end
    
    -- Validate logging configuration
    if config.logging.level and not vim.tbl_contains({"debug", "info", "warn", "error"}, config.logging.level) then
        return false, "Logging level must be one of: debug, info, warn, error"
    end
    
    if config.logging.enabled and type(config.logging.enabled) ~= "boolean" then
        return false, "Logging enabled must be a boolean"
    end
    
    return true
end

-- Reset configuration to defaults
function mcp_config.reset()
    current_config = vim.deepcopy(DEFAULT_CONFIG)
end

-- Export configuration for transport initialization
function mcp_config.export_for_transport()
    local config = mcp_config.get()
    local transport_config = {
        transport_type = config.transport.type,
        base_url = config.transport.http.base_url,
        protocol_version = config.transport.http.protocol_version,
        initialization_timeout = config.transport.http.initialization_timeout,
        request_timeout = config.transport.http.request_timeout,
        reconnect_delay = config.transport.http.reconnect_delay,
        max_reconnect_attempts = config.transport.http.max_reconnect_attempts,
        event_buffer_size = config.transport.http.event_buffer_size,
        fallback_timeout = config.transport.adapter.fallback_timeout,
        health_check_interval = config.transport.adapter.health_check_interval,
        -- TCP configuration
        host = config.transport.tcp.host,
        port = config.transport.tcp.port,
        timeout = config.transport.tcp.timeout,
        retry_attempts = config.transport.tcp.retry_attempts,
    }
    
    return transport_config
end

-- Export client configuration
function mcp_config.export_client_config()
    local config = mcp_config.get()
    return {
        name = config.client.name,
        version = config.client.version,
        capabilities = config.client.capabilities,
    }
end

-- Get configuration file path
function mcp_config.get_config_file_path()
    return CONFIG_FILE
end

-- Check if configuration file exists
function mcp_config.config_file_exists()
    return vim.fn.filereadable(CONFIG_FILE) == 1
end

-- Create default configuration file
function mcp_config.create_default_config()
    if mcp_config.config_file_exists() then
        return false, "Configuration file already exists"
    end
    
    mcp_config.reset()
    mcp_config.save()
    return true
end

-- Export module
return mcp_config
