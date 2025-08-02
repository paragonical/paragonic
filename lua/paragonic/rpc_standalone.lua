--[[
Standalone Paragonic RPC Client for connecting to Rust JSON-RPC server
This version doesn't depend on vim.api or init.lua
--]]

local M = {}

-- RPC Client constructor
function M.new(server_address)
    local client = {
        server_address = server_address,
        connected = false,
        socket = nil,
        timeout = 10, -- Default timeout of 10 seconds
        max_retries = 0, -- Default no retries
        retry_delay = 1 -- Default retry delay of 1 second
    }
    
    -- Set metatable for object-oriented behavior
    setmetatable(client, { __index = M })
    
    return client
end

-- Test server connectivity using external command
local function test_server_connectivity(server_address)
    -- Parse server address
    local host, port = server_address:match("([^:]+):?(%d*)")
    if not host then
        return false, "Invalid server address format"
    end
    
    -- Default port to 3000 if not specified
    port = port or "3000"
    
    -- Test connectivity using netcat
    local test_cmd = string.format('echo \'{"jsonrpc":"2.0","method":"hello","params":{},"id":1}\' | nc -w 3 %s %s 2>/dev/null', host, port)
    local test_process = io.popen(test_cmd)
    if not test_process then
        return false, "Failed to execute connectivity test"
    end
    
    local result = test_process:read("*a")
    test_process:close()
    
    -- Check if we got a valid JSON-RPC response
    if result and result ~= "" and result:find('"jsonrpc"') then
        return true, nil
    else
        return false, "No valid response from server"
    end
end

-- Connect to the RPC server
function M:connect()
    -- Test actual connectivity to the server
    local success, error_msg = test_server_connectivity(self.server_address)
    
    if success then
        self.connected = true
        return true
    else
        self.connected = false
        return false
    end
end

-- Disconnect from the RPC server
function M:disconnect()
    -- For now, just mark as disconnected
    -- In a real implementation, we might close any open sockets
    self.connected = false
    return true
end

-- Check if connected
function M:is_connected()
    return self.connected
end

-- Get current timeout value
function M:get_timeout()
    return self.timeout
end

-- Set timeout for operations
function M:timeout_operations(timeout_seconds)
    -- Parameter validation
    if not timeout_seconds or type(timeout_seconds) ~= "number" then
        return false, "Timeout must be a number"
    end
    
    if timeout_seconds <= 0 then
        return false, "Timeout must be greater than 0"
    end
    
    -- Set the timeout
    self.timeout = timeout_seconds
    return true
end

-- Get current retry configuration
function M:get_retry_config()
    return {
        max_retries = self.max_retries,
        delay = self.retry_delay
    }
end

-- Set retry configuration for operations
function M:retry_operations(max_retries, delay_seconds)
    -- Parameter validation
    if not max_retries or type(max_retries) ~= "number" then
        return false, "Max retries must be a number"
    end
    
    if not delay_seconds or type(delay_seconds) ~= "number" then
        return false, "Delay must be a number"
    end
    
    if max_retries < 0 then
        return false, "Max retries must be non-negative"
    end
    
    if delay_seconds < 0 then
        return false, "Delay must be non-negative"
    end
    
    -- Set the retry configuration
    self.max_retries = max_retries
    self.retry_delay = delay_seconds
    return true
end

-- Send JSON-RPC request using external command with retry logic
local function send_jsonrpc_request_with_retry(server_address, method, params, timeout, max_retries, retry_delay)
    -- Parse server address
    local host, port = server_address:match("([^:]+):?(%d*)")
    if not host then
        return nil, "Invalid server address format"
    end
    
    -- Default port to 3000 if not specified
    port = port or "3000"
    
    -- Use provided timeout or default to 10 seconds
    timeout = timeout or 10
    
    -- Use provided retry settings or default to no retries
    max_retries = max_retries or 0
    retry_delay = retry_delay or 1
    
    -- Create JSON-RPC request
    local request = {
        jsonrpc = "2.0",
        method = method,
        params = params or {},
        id = 1
    }
    
    -- Convert to JSON string
    local cjson = require("cjson")
    local json_request = cjson.encode(request)
    
    -- Try the request with retries
    for attempt = 0, max_retries do
        -- Send request using netcat with timeout
        local cmd = string.format('echo \'%s\' | nc -w %d %s %s', json_request, timeout, host, port)
        local process = io.popen(cmd)
        if not process then
            if attempt < max_retries then
                os.execute("sleep " .. retry_delay)
                goto continue
            else
                return nil, "Failed to execute RPC request"
            end
        end
        
        local response = process:read("*a")
        process:close()
        
        if response and response ~= "" then
            -- Try to parse the response
            local success, parsed = pcall(cjson.decode, response)
            if success and parsed and parsed.result then
                return parsed.result, nil
            else
                -- Check if this is a retryable error (like connection issues)
                if attempt < max_retries and (not response or response == "" or response:find("Connection refused") or response:find("No route to host")) then
                    os.execute("sleep " .. retry_delay)
                    goto continue
                else
                    return response, nil -- Return raw response if parsing fails
                end
            end
        else
            -- No response, retry if we have attempts left
            if attempt < max_retries then
                os.execute("sleep " .. retry_delay)
                goto continue
            else
                return nil, "No response from server"
            end
        end
        
        ::continue::
    end
    
    return nil, "All retry attempts failed"
end

-- Send JSON-RPC request using external command (legacy function for backward compatibility)
local function send_jsonrpc_request(server_address, method, params, timeout)
    return send_jsonrpc_request_with_retry(server_address, method, params, timeout, 0, 1)
end

-- Send hello method to server
function M:hello()
    if not self.connected then
        return nil, "Not connected to server"
    end
    
    local result, error_msg = send_jsonrpc_request_with_retry(self.server_address, "hello", {}, self.timeout, self.max_retries, self.retry_delay)
    if result then
        return result
    else
        return nil, error_msg
    end
end

-- Send chat completion request to server
function M:chat_completion(model, message)
    -- Parameter validation
    if not model or model == "" then
        return nil, "Model parameter is required"
    end
    
    if not message or message == "" then
        return nil, "Message parameter is required"
    end
    
    if not self.connected then
        return nil, "Not connected to server"
    end
    
    -- Send chat completion request with parameters as array [message, model]
    local result, error_msg = send_jsonrpc_request_with_retry(self.server_address, "chat_completion", {message, model}, self.timeout, self.max_retries, self.retry_delay)
    if result then
        return result
    else
        return nil, error_msg
    end
end

-- Get list of available models from server
function M:list_models()
    if not self.connected then
        return nil, "Not connected to server"
    end
    
    -- Send list_models request with empty parameters
    local result, error_msg = send_jsonrpc_request_with_retry(self.server_address, "list_models", {}, self.timeout, self.max_retries, self.retry_delay)
    if result then
        return result
    else
        return nil, error_msg
    end
end

-- Get detailed information about a specific model from server
function M:model_info(model_name)
    -- Parameter validation
    if not model_name or model_name == "" then
        return nil, "Model name parameter is required"
    end
    
    if not self.connected then
        return nil, "Not connected to server"
    end
    
    -- Send model_info request with model name as parameter
    local result, error_msg = send_jsonrpc_request_with_retry(self.server_address, "model_info", {model_name}, self.timeout, self.max_retries, self.retry_delay)
    if result then
        return result
    else
        return nil, error_msg
    end
end

-- Generate embeddings for text using server
function M:generate_embedding(model, text)
    -- Parameter validation
    if not model or model == "" then
        return nil, "Model parameter is required"
    end
    
    if not text or text == "" then
        return nil, "Text parameter is required"
    end
    
    if not self.connected then
        return nil, "Not connected to server"
    end
    
    -- Send generate_embedding request with parameters as array [text, model]
    local result, error_msg = send_jsonrpc_request_with_retry(self.server_address, "generate_embedding", {text, model}, self.timeout, self.max_retries, self.retry_delay)
    if result then
        return result
    else
        return nil, error_msg
    end
end

-- Ping the server to test connectivity and get server status
function M:ping()
    -- Send ping request to server (uses hello method as ping)
    local result, error_msg = send_jsonrpc_request_with_retry(self.server_address, "hello", {}, self.timeout, self.max_retries, self.retry_delay)
    if result then
        return "pong"
    else
        return nil
    end
end

-- Get detailed server information including status, version, and capabilities
function M:get_server_info()
    -- Try to get server information by testing connectivity
    local success, error_msg = test_server_connectivity(self.server_address)
    
    -- Parse server address for display
    local host, port = self.server_address:match("([^:]+):?(%d*)")
    if not host then
        host = "unknown"
        port = "unknown"
    end
    port = port or "3000"
    
    -- Create server info structure
    local server_info = {
        name = "Paragonic",
        version = "0.1.0",
        address = host .. ":" .. port,
        protocol = "JSON-RPC 2.0",
        status = success and "running" or "unavailable"
    }
    
    -- If server is available, try to get additional info
    if success then
        -- Try to get actual server version if possible
        local hello_result = send_jsonrpc_request_with_retry(self.server_address, "hello", {}, self.timeout, self.max_retries, self.retry_delay)
        if hello_result then
            -- Server is responding, we could extend this to get more detailed info
            -- For now, we just confirm it's running
            server_info.status = "running"
        end
    end
    
    return server_info
end

-- Execute multiple operations in a batch
function M:batch_operations(operations)
    -- Parameter validation
    if not operations or type(operations) ~= "table" or #operations == 0 then
        return nil, "Operations parameter must be a non-empty table"
    end
    
    if not self.connected then
        return nil, "Not connected to server"
    end
    
    -- Validate each operation
    for i, operation in ipairs(operations) do
        if type(operation) ~= "table" then
            return nil, "Operation " .. i .. " must be a table"
        end
        
        if not operation.method or type(operation.method) ~= "string" then
            return nil, "Operation " .. i .. " must have a method field"
        end
        
        if not operation.params then
            operation.params = {}
        end
    end
    
    -- Execute each operation and collect results
    local results = {}
    for i, operation in ipairs(operations) do
        local result, error_msg = send_jsonrpc_request_with_retry(self.server_address, operation.method, operation.params, self.timeout, self.max_retries, self.retry_delay)
        if result then
            results[i] = result
        else
            -- For batch operations, we continue even if some operations fail
            results[i] = nil
        end
    end
    
    return results
end

return M 