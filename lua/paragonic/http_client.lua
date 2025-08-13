-- HTTP client for MCP Streamable HTTP transport
-- 
-- This module provides HTTP client functionality for the MCP
-- Streamable HTTP transport, including request building, sending,
-- and response handling.

local http_client = {}
local json = vim.json

-- HTTP client configuration
local DEFAULT_TIMEOUT = 30 -- seconds
local DEFAULT_RETRY_ATTEMPTS = 3
local DEFAULT_RETRY_DELAY = 1 -- seconds

-- HTTP client state
local client_state = {
    base_url = nil,
    session_id = nil,
    timeout = DEFAULT_TIMEOUT,
    retry_attempts = DEFAULT_RETRY_ATTEMPTS,
    retry_delay = DEFAULT_RETRY_DELAY,
    headers = {},
    -- Connection pooling state
    connection_pool = {
        connections = {},
        active = 0,
        max_size = 5, -- Default pool size
        connection_timeout = 30,
        idle_timeout = 300,
    },
    -- Optimization settings
    optimization = {
        enable_keep_alive = true,
        keep_alive_timeout = 30,
        max_idle_connections = 5,
        connection_timeout = 10,
    },
}

-- HTTP client errors
local HTTPClientError = {
    CONNECTION_FAILED = "connection_failed",
    TIMEOUT = "timeout",
    INVALID_RESPONSE = "invalid_response",
    SESSION_EXPIRED = "session_expired",
    MAX_RETRIES_EXCEEDED = "max_retries_exceeded",
    INVALID_URL = "invalid_url",
    INVALID_HEADERS = "invalid_headers",
}

-- Initialize HTTP client
function http_client.init(config)
    config = config or {}
    
    client_state.base_url = config.base_url or "http://localhost:3000"
    client_state.timeout = config.timeout or DEFAULT_TIMEOUT
    client_state.retry_attempts = config.retry_attempts or DEFAULT_RETRY_ATTEMPTS
    client_state.retry_delay = config.retry_delay or DEFAULT_RETRY_DELAY
    
    -- Set default headers
    client_state.headers = {
        ["Content-Type"] = "application/json",
        ["Accept"] = "application/json, text/event-stream",
        ["MCP-Protocol-Version"] = "2025-06-18",
        ["Origin"] = (config.origin or client_state.base_url or "http://localhost"),
    }
    
    -- Add custom headers if provided
    if config.headers then
        for key, value in pairs(config.headers) do
            client_state.headers[key] = value
        end
    end
    
    return true
end

-- Set session ID
function http_client.set_session_id(session_id)
    if not session_id or type(session_id) ~= "string" then
        return false, "Invalid session ID"
    end
    
    client_state.session_id = session_id
    client_state.headers["Mcp-Session-Id"] = session_id
    return true
end

-- Get current session ID
function http_client.get_session_id()
    return client_state.session_id
end

-- Connection pooling methods

-- Get connection pool configuration
function http_client.get_connection_pool_config()
    return {
        pool_size = client_state.connection_pool.max_size,
        active_connections = client_state.connection_pool.active,
        available_connections = #client_state.connection_pool.connections,
        connection_timeout = client_state.connection_pool.connection_timeout,
        idle_timeout = client_state.connection_pool.idle_timeout,
    }
end

-- Set connection pool size
function http_client.set_connection_pool_size(pool_size)
    if not pool_size or type(pool_size) ~= "number" then
        return false, "Pool size must be a number"
    end
    
    if pool_size <= 0 then
        return false, "Pool size must be greater than 0"
    end
    
    client_state.connection_pool.max_size = pool_size
    return true
end

-- Get connection from pool
function http_client.get_connection()
    local pool = client_state.connection_pool
    
    -- Check if we have available connections
    if #pool.connections > 0 then
        local connection = table.remove(pool.connections)
        pool.active = pool.active + 1
        connection.last_used = os.time()
        return connection
    end
    
    -- Check if we can create a new connection
    if pool.active < pool.max_size then
        local connection = http_client._create_connection()
        if connection then
            pool.active = pool.active + 1
            return connection
        end
    end
    
    return nil, "No available connections"
end

-- Return connection to pool
function http_client.return_connection(connection)
    if not connection then
        return false, "Invalid connection"
    end
    
    local pool = client_state.connection_pool
    
    -- Check if connection is still valid
    if http_client.is_connection_valid(connection) then
        table.insert(pool.connections, connection)
    end
    
    pool.active = pool.active - 1
    return true
end

-- Create a new connection (internal)
function http_client._create_connection()
    return {
        id = http_client._generate_connection_id(),
        created_at = os.time(),
        last_used = os.time(),
        host = client_state.base_url:match("^https?://([^:/]+)"),
        port = client_state.base_url:match(":(%d+)") or "80",
    }
end

-- Check if connection is still valid
function http_client.is_connection_valid(connection)
    if not connection then
        return false
    end
    
    local current_time = os.time()
    local idle_timeout = client_state.connection_pool.idle_timeout
    
    -- Check if connection has been idle too long
    if current_time - connection.last_used > idle_timeout then
        return false
    end
    
    return true
end

-- Generate unique connection ID
function http_client._generate_connection_id()
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local id = ""
    
    for i = 1, 8 do
        local random_index = math.random(1, #charset)
        id = id .. charset:sub(random_index, random_index)
    end
    
    return id
end

-- Cleanup expired connections
function http_client.cleanup_expired_connections()
    local pool = client_state.connection_pool
    local valid_connections = {}
    
    for _, connection in ipairs(pool.connections) do
        if http_client.is_connection_valid(connection) then
            table.insert(valid_connections, connection)
        end
    end
    
    pool.connections = valid_connections
    return true
end

-- Get connection pool metrics
function http_client.get_connection_pool_metrics()
    local pool = client_state.connection_pool
    local total = pool.active + #pool.connections
    local usage_percentage = total > 0 and (pool.active / total) * 100 or 0
    
    return {
        active_connections = pool.active,
        available_connections = #pool.connections,
        total_connections = total,
        usage_percentage = usage_percentage,
        max_size = pool.max_size,
    }
end

-- Configure request pooling
function http_client.configure_request_pooling(request_config)
    if not request_config or type(request_config) ~= "table" then
        return false, "Invalid request config"
    end
    
    -- Store pooling configuration for the request
    request_config.use_connection_pool = request_config.use_connection_pool or true
    return true
end

-- Set optimization configuration
function http_client.set_optimization_config(config)
    if not config or type(config) ~= "table" then
        return false, "Invalid optimization config"
    end
    
    if config.enable_keep_alive ~= nil then
        client_state.optimization.enable_keep_alive = config.enable_keep_alive
    end
    
    if config.keep_alive_timeout then
        client_state.optimization.keep_alive_timeout = config.keep_alive_timeout
    end
    
    if config.max_idle_connections then
        client_state.optimization.max_idle_connections = config.max_idle_connections
    end
    
    if config.connection_timeout then
        client_state.optimization.connection_timeout = config.connection_timeout
    end
    
    return true
end

-- Get optimization configuration
function http_client.get_optimization_config()
    return {
        enable_keep_alive = client_state.optimization.enable_keep_alive,
        keep_alive_timeout = client_state.optimization.keep_alive_timeout,
        max_idle_connections = client_state.optimization.max_idle_connections,
        connection_timeout = client_state.optimization.connection_timeout,
    }
end

-- Reset connection pool for testing
function http_client.reset_connection_pool()
    client_state.connection_pool = {
        connections = {},
        active = 0,
        max_size = 5, -- Default pool size
        connection_timeout = 30,
        idle_timeout = 300,
    }
    return true
end

-- Build HTTP request
function http_client.build_request(method, endpoint, data, custom_headers)
    if not method or type(method) ~= "string" then
        return nil, "Invalid HTTP method"
    end
    
    if not endpoint or type(endpoint) ~= "string" then
        return nil, "Invalid endpoint"
    end
    
    -- Build URL
    local url = client_state.base_url
    if url:match("/$") and endpoint:match("^/") then
        -- Remove trailing slash from base URL if endpoint starts with slash
        url = url:sub(1, -2)
    elseif not url:match("/$") and not endpoint:match("^/") then
        -- Add slash if neither has one
        url = url .. "/"
    end
    url = url .. endpoint
    
    -- Build headers
    local headers = {}
    for key, value in pairs(client_state.headers) do
        headers[key] = value
    end
    
    -- Add custom headers
    if custom_headers then
        for key, value in pairs(custom_headers) do
            headers[key] = value
        end
    end
    
    -- Build request
    local request = {
        method = method:upper(),
        url = url,
        headers = headers,
        timeout = client_state.timeout,
    }
    
    -- Add data for POST/PUT requests
    if data and (method:upper() == "POST" or method:upper() == "PUT") then
        if type(data) == "table" then
            request.data = json.encode(data)
        else
            request.data = tostring(data)
        end
    end
    
    return request
end

-- Send HTTP request with retry logic
function http_client.send_request(method, endpoint, data, custom_headers)
    local request, err = http_client.build_request(method, endpoint, data, custom_headers)
    if not request then
        return nil, err
    end
    
    local last_error
    for attempt = 1, client_state.retry_attempts do
        local response, error = http_client._send_single_request(request)
        
        if response then
            return response
        end
        
        last_error = error
        
        -- Don't retry on certain errors
        if error == HTTPClientError.INVALID_RESPONSE or 
           error == HTTPClientError.INVALID_URL or
           error == HTTPClientError.INVALID_HEADERS then
            break
        end
        
        -- Wait before retry (except on last attempt)
        if attempt < client_state.retry_attempts then
            vim.wait(client_state.retry_delay * 1000)
        end
    end
    
    return nil, last_error or HTTPClientError.MAX_RETRIES_EXCEEDED
end

-- Send a single HTTP request (internal function)
function http_client._send_single_request(request)
    -- Validate request
    if not request.method or not request.url then
        return nil, HTTPClientError.INVALID_RESPONSE
    end
    
    -- Get connection from pool if pooling is enabled
    local connection = nil
    local use_pooling = request.use_connection_pool ~= false -- Default to true
    
    if use_pooling then
        connection = http_client.get_connection()
        if connection then
            -- Add connection-specific headers for keep-alive
            if client_state.optimization.enable_keep_alive then
                request.headers["Connection"] = "keep-alive"
            end
        end
    end
    
    -- Use curl for HTTP requests (fallback to system curl if available)
    local curl_cmd = "curl"
    local args = {
        "-s", -- silent
        "-w", "%{http_code}", -- write out HTTP status code
        "-o", "/tmp/paragonic_response", -- output to temp file
        "-H", "Content-Type: application/json",
        "-H", "Accept: application/json, text/event-stream",
        "-H", "MCP-Protocol-Version: 2025-06-18",
    }
    
    -- Add keep-alive options if enabled
    if client_state.optimization.enable_keep_alive and connection then
        table.insert(args, "--keepalive-time")
        table.insert(args, tostring(client_state.optimization.keep_alive_timeout))
    end
    
    -- Add session ID header if available
    if client_state.session_id then
        table.insert(args, "-H")
        table.insert(args, "Mcp-Session-Id: " .. client_state.session_id)
    end
    
    -- Add custom headers
    for key, value in pairs(request.headers) do
        if key ~= "Content-Type" and key ~= "Accept" and key ~= "MCP-Protocol-Version" and key ~= "Mcp-Session-Id" then
            table.insert(args, "-H")
            table.insert(args, key .. ": " .. value)
        end
    end
    
    -- Add method
    table.insert(args, "-X")
    table.insert(args, request.method)
    
    -- Add data for POST/PUT requests
    if request.data then
        table.insert(args, "-d")
        table.insert(args, request.data)
    end
    
    -- Add timeout
    table.insert(args, "--max-time")
    table.insert(args, tostring(request.timeout))
    
    -- Add URL
    table.insert(args, request.url)
    
    -- Execute curl command
    local output
    local exit_code
    do
        local cmd = { curl_cmd }
        for _, a in ipairs(args) do
            table.insert(cmd, a)
        end
        output = vim.fn.system(cmd)
        exit_code = vim.v.shell_error
    end
    
    -- Return connection to pool if we used one
    if connection then
        http_client.return_connection(connection)
    end
    
    if exit_code ~= 0 then
        return nil, HTTPClientError.CONNECTION_FAILED
    end
    
    -- Parse response
    local status_code = tonumber(output:match("(%d+)$"))
    if not status_code then
        return nil, HTTPClientError.INVALID_RESPONSE
    end
    
    -- Read response body
    local response_body = vim.fn.readfile("/tmp/paragonic_response")
    local body_text = table.concat(response_body, "\n")
    
    -- Parse JSON response if possible
    local parsed_body = nil
    if body_text and body_text ~= "" then
        local success, result = pcall(json.decode, body_text)
        if success then
            parsed_body = result
        else
            parsed_body = body_text
        end
    end
    
    return {
        status_code = status_code,
        body = parsed_body,
        raw_body = body_text,
        headers = {}, -- TODO: Parse response headers if needed
    }
end

-- Send POST request
function http_client.post(endpoint, data, custom_headers)
    return http_client.send_request("POST", endpoint, data, custom_headers)
end

-- Send GET request
function http_client.get(endpoint, custom_headers)
    return http_client.send_request("GET", endpoint, nil, custom_headers)
end

-- Send DELETE request
function http_client.delete(endpoint, custom_headers)
    return http_client.send_request("DELETE", endpoint, nil, custom_headers)
end

-- Check if response indicates success
function http_client.is_success(response)
    return response and response.status_code and response.status_code >= 200 and response.status_code < 300
end

-- Check if response indicates client error
function http_client.is_client_error(response)
    return response and response.status_code and response.status_code >= 400 and response.status_code < 500
end

-- Check if response indicates server error
function http_client.is_server_error(response)
    return response and response.status_code and response.status_code >= 500
end

-- Get error message from response
function http_client.get_error_message(response)
    if not response then
        return "No response received"
    end
    
    if response.body and type(response.body) == "table" and response.body.error then
        return response.body.error
    end
    
    return "HTTP " .. (response.status_code or "unknown")
end

-- Clean up resources
function http_client.cleanup()
    -- Remove temporary files
    vim.fn.delete("/tmp/paragonic_response")
    
    -- Reset state
    client_state = {
        base_url = nil,
        session_id = nil,
        timeout = DEFAULT_TIMEOUT,
        retry_attempts = DEFAULT_RETRY_ATTEMPTS,
        retry_delay = DEFAULT_RETRY_DELAY,
        headers = {},
        -- Connection pooling state
        connection_pool = {
            connections = {},
            active = 0,
            max_size = 5, -- Default pool size
            connection_timeout = 30,
            idle_timeout = 300,
        },
        -- Optimization settings
        optimization = {
            enable_keep_alive = true,
            keep_alive_timeout = 30,
            max_idle_connections = 5,
            connection_timeout = 10,
        },
    }
end

-- Export module
return http_client
