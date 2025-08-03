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
        retry_delay = 1, -- Default retry delay of 1 second
        pool_size = 1, -- Default pool size of 1 connection
        current_connection = 0, -- Current connection index for round-robin
        logging_enabled = false, -- Default logging disabled
        log_level = "info" -- Default log level
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

-- Get current connection pool configuration
function M:get_connection_pool_config()
    return {
        pool_size = self.pool_size
    }
end

-- Set connection pooling configuration
function M:connection_pooling(pool_size)
    -- Parameter validation
    if not pool_size or type(pool_size) ~= "number" then
        return false, "Pool size must be a number"
    end
    
    if pool_size <= 0 then
        return false, "Pool size must be greater than 0"
    end
    
    -- Set the pool size
    self.pool_size = pool_size
    return true
end

-- Get current logging configuration
function M:get_logging_config()
    return {
        enabled = self.logging_enabled,
        level = self.log_level
    }
end

-- Set logging configuration
function M:logging(enabled, level)
    -- Parameter validation
    if type(enabled) ~= "boolean" then
        return false, "Enabled must be a boolean"
    end
    
    -- Set the logging enabled flag
    self.logging_enabled = enabled
    
    -- If level is provided, validate and set it
    if level then
        if type(level) ~= "string" then
            return false, "Log level must be a string"
        end
        
        -- Validate log level
        local valid_levels = {"debug", "info", "warn", "error"}
        local is_valid = false
        for _, valid_level in ipairs(valid_levels) do
            if level == valid_level then
                is_valid = true
                break
            end
        end
        
        if not is_valid then
            return false, "Invalid log level. Must be one of: debug, info, warn, error"
        end
        
        self.log_level = level
    end
    
    return true
end

-- Log message with current configuration
local function log_message(client, level, message)
    if not client.logging_enabled then
        return
    end
    
    -- Check if the message level should be logged based on current log level
    local level_priority = {
        debug = 1,
        info = 2,
        warn = 3,
        error = 4
    }
    
    local current_priority = level_priority[client.log_level] or 2
    local message_priority = level_priority[level] or 2
    
    if message_priority >= current_priority then
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        local log_entry = string.format("[%s] [%s] %s", timestamp, level:upper(), message)
        print(log_entry)
    end
end

-- Get next connection index for round-robin load balancing
local function get_next_connection_index(client)
    client.current_connection = (client.current_connection % client.pool_size) + 1
    return client.current_connection
end

-- Send JSON-RPC request using external command with retry logic, connection pooling, and logging
local function send_jsonrpc_request_with_retry_and_pool_and_log(server_address, method, params, timeout, max_retries, retry_delay, pool_size, client)
    -- Parse server address
    local host, port = server_address:match("([^:]+):?(%d*)")
    if not host then
        if client then
            log_message(client, "error", "Invalid server address format: " .. tostring(server_address))
        end
        return nil, "Invalid server address format"
    end
    
    -- Default port to 3000 if not specified
    port = port or "3000"
    
    -- Use provided timeout or default to 10 seconds
    timeout = timeout or 10
    
    -- Use provided retry settings or default to no retries
    max_retries = max_retries or 0
    retry_delay = retry_delay or 1
    
    -- Use provided pool size or default to 1
    pool_size = pool_size or 1
    
    -- Create JSON-RPC request
    local request = {
        jsonrpc = "2.0",
        method = method,
        params = params or {},
        id = 1
    }
    
    -- Convert to JSON string
    local json_request = vim.json.encode(request)
    
    if client then
        log_message(client, "debug", string.format("Sending RPC request: %s to %s:%s", method, host, port))
    end
    
    -- Try the request with retries
    for attempt = 0, max_retries do
        -- For connection pooling, we could implement actual connection reuse
        -- For now, we'll simulate it by using round-robin selection
        -- In a real implementation, this would manage actual TCP connections
        
        if client and attempt > 0 then
            log_message(client, "info", string.format("Retry attempt %d/%d for method %s", attempt, max_retries, method))
        end
        
        -- Send request using netcat with timeout
        local cmd = string.format('echo \'%s\' | nc -w %d %s %s', json_request, timeout, host, port)
        local process = io.popen(cmd)
        if not process then
            if attempt < max_retries then
                if client then
                    log_message(client, "warn", string.format("Failed to execute RPC request, retrying in %s seconds", retry_delay))
                end
                os.execute("sleep " .. retry_delay)
                goto continue
            else
                if client then
                    log_message(client, "error", "Failed to execute RPC request after all retries")
                end
                return nil, "Failed to execute RPC request"
            end
        end
        
        local response = process:read("*a")
        process:close()
        
        if response and response ~= "" then
            -- Try to parse the response
            local success, parsed = pcall(vim.json.decode, response)
            if success and parsed then
                if client then
                    log_message(client, "debug", string.format("RPC request %s succeeded", method))
                end
                -- Extract the actual result from the JSON-RPC envelope
                if parsed.result then
                    -- If result is a string, parse it as JSON
                    if type(parsed.result) == "string" then
                        local success2, actual_result = pcall(vim.json.decode, parsed.result)
                        if success2 then
                            return actual_result, nil
                        else
                            return parsed.result, nil
                        end
                    else
                        return parsed.result, nil
                    end
                else
                    return parsed, nil
                end
            else
                -- Check if this is a retryable error (like connection issues)
                if attempt < max_retries and (not response or response == "" or response:find("Connection refused") or response:find("No route to host")) then
                    if client then
                        log_message(client, "warn", string.format("Retryable error for method %s, retrying in %s seconds", method, retry_delay))
                    end
                    os.execute("sleep " .. retry_delay)
                    goto continue
                else
                    if client then
                        log_message(client, "error", string.format("RPC request %s failed with response: %s", method, response))
                    end
                    return response, nil -- Return raw response if parsing fails
                end
            end
        else
            -- No response, retry if we have attempts left
            if attempt < max_retries then
                if client then
                    log_message(client, "warn", string.format("No response for method %s, retrying in %s seconds", method, retry_delay))
                end
                os.execute("sleep " .. retry_delay)
                goto continue
            else
                if client then
                    log_message(client, "error", string.format("No response from server for method %s after all retries", method))
                end
                return nil, "No response from server"
            end
        end
        
        ::continue::
    end
    
    if client then
        log_message(client, "error", string.format("All retry attempts failed for method %s", method))
    end
    return nil, "All retry attempts failed"
end

-- Send JSON-RPC request using external command with retry logic and connection pooling
local function send_jsonrpc_request_with_retry_and_pool(server_address, method, params, timeout, max_retries, retry_delay, pool_size)
    return send_jsonrpc_request_with_retry_and_pool_and_log(server_address, method, params, timeout, max_retries, retry_delay, pool_size, nil)
end

-- Send JSON-RPC request using external command with retry logic
local function send_jsonrpc_request_with_retry(server_address, method, params, timeout, max_retries, retry_delay)
    return send_jsonrpc_request_with_retry_and_pool(server_address, method, params, timeout, max_retries, retry_delay, 1)
end

-- Send JSON-RPC request using external command (legacy function for backward compatibility)
local function send_jsonrpc_request(server_address, method, params, timeout)
    return send_jsonrpc_request_with_retry(server_address, method, params, timeout, 0, 1)
end

-- Send hello method to server
function M:hello()
    if not self.connected then
        log_message(self, "error", "Not connected to server")
        return nil, "Not connected to server"
    end
    
    local result, error_msg = send_jsonrpc_request_with_retry_and_pool_and_log(self.server_address, "hello", {}, self.timeout, self.max_retries, self.retry_delay, self.pool_size, self)
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
        log_message(self, "error", "Model parameter is required")
        return nil, "Model parameter is required"
    end
    
    if not message or message == "" then
        log_message(self, "error", "Message parameter is required")
        return nil, "Message parameter is required"
    end
    
    if not self.connected then
        log_message(self, "error", "Not connected to server")
        return nil, "Not connected to server"
    end
    
    -- Send chat completion request with parameters as array [message, model]
    local result, error_msg = send_jsonrpc_request_with_retry_and_pool_and_log(self.server_address, "chat_completion", {message, model}, self.timeout, self.max_retries, self.retry_delay, self.pool_size, self)
    if result then
        return result
    else
        return nil, error_msg
    end
end

-- Get list of available models from server
function M:list_models()
    if not self.connected then
        log_message(self, "error", "Not connected to server")
        return nil, "Not connected to server"
    end
    
    -- Send list_models request with empty parameters
    local result, error_msg = send_jsonrpc_request_with_retry_and_pool_and_log(self.server_address, "list_models", {}, self.timeout, self.max_retries, self.retry_delay, self.pool_size, self)
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
        log_message(self, "error", "Model name parameter is required")
        return nil, "Model name parameter is required"
    end
    
    if not self.connected then
        log_message(self, "error", "Not connected to server")
        return nil, "Not connected to server"
    end
    
    -- Send model_info request with model name as parameter
    local result, error_msg = send_jsonrpc_request_with_retry_and_pool_and_log(self.server_address, "model_info", {model_name}, self.timeout, self.max_retries, self.retry_delay, self.pool_size, self)
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
        log_message(self, "error", "Model parameter is required")
        return nil, "Model parameter is required"
    end
    
    if not text or text == "" then
        log_message(self, "error", "Text parameter is required")
        return nil, "Text parameter is required"
    end
    
    if not self.connected then
        log_message(self, "error", "Not connected to server")
        return nil, "Not connected to server"
    end
    
    -- Send generate_embedding request with parameters as array [text, model]
    local result, error_msg = send_jsonrpc_request_with_retry_and_pool_and_log(self.server_address, "generate_embedding", {text, model}, self.timeout, self.max_retries, self.retry_delay, self.pool_size, self)
    if result then
        return result
    else
        return nil, error_msg
    end
end

-- Ping the server to test connectivity and get server status
function M:ping()
    -- Send ping request to server (uses hello method as ping)
    local result, error_msg = send_jsonrpc_request_with_retry_and_pool_and_log(self.server_address, "hello", {}, self.timeout, self.max_retries, self.retry_delay, self.pool_size, self)
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
        local hello_result = send_jsonrpc_request_with_retry_and_pool_and_log(self.server_address, "hello", {}, self.timeout, self.max_retries, self.retry_delay, self.pool_size, self)
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
        log_message(self, "error", "Operations parameter must be a non-empty table")
        return nil, "Operations parameter must be a non-empty table"
    end
    
    if not self.connected then
        log_message(self, "error", "Not connected to server")
        return nil, "Not connected to server"
    end
    
    -- Validate each operation
    for i, operation in ipairs(operations) do
        if type(operation) ~= "table" then
            log_message(self, "error", "Operation " .. i .. " must be a table")
            return nil, "Operation " .. i .. " must be a table"
        end
        
        if not operation.method or type(operation.method) ~= "string" then
            log_message(self, "error", "Operation " .. i .. " must have a method field")
            return nil, "Operation " .. i .. " must have a method field"
        end
        
        if not operation.params then
            operation.params = {}
        end
    end
    
    log_message(self, "info", string.format("Executing batch of %d operations", #operations))
    
    -- Execute each operation and collect results
    local results = {}
    for i, operation in ipairs(operations) do
        local result, error_msg = send_jsonrpc_request_with_retry_and_pool_and_log(self.server_address, operation.method, operation.params, self.timeout, self.max_retries, self.retry_delay, self.pool_size, self)
        if result then
            results[i] = result
        else
            -- For batch operations, we continue even if some operations fail
            log_message(self, "warn", string.format("Batch operation %d (%s) failed: %s", i, operation.method, error_msg or "unknown error"))
            results[i] = nil
        end
    end
    
    log_message(self, "info", string.format("Batch completed with %d/%d successful operations", #results, #operations))
    return results
end

-- Search embeddings using vector similarity
function M:search_embeddings(query, limit)
    -- Parameter validation
    if not query or query == "" then
        log_message(self, "error", "Query parameter is required")
        return nil, "Query parameter is required"
    end
    
    if not self.connected then
        log_message(self, "error", "Not connected to server")
        return nil, "Not connected to server"
    end
    
    -- Set default limit if not provided
    limit = limit or 10
    
    -- Validate limit
    if type(limit) ~= "number" or limit <= 0 then
        log_message(self, "error", "Limit must be a positive number")
        return nil, "Limit must be a positive number"
    end
    
    -- Prepare parameters
    local params = {
        query = query,
        limit = limit
    }
    
    -- Send search_embeddings request
    local result, error_msg = send_jsonrpc_request_with_retry_and_pool_and_log(self.server_address, "search_embeddings", params, self.timeout, self.max_retries, self.retry_delay, self.pool_size, self)
    if result then
        return result
    else
        return nil, error_msg
    end
end

-- Find similar content with optional filtering
function M:find_similar_content(query, content_type, limit, threshold)
    -- Parameter validation
    if not query or query == "" then
        log_message(self, "error", "Query parameter is required")
        return nil, "Query parameter is required"
    end
    
    if not self.connected then
        log_message(self, "error", "Not connected to server")
        return nil, "Not connected to server"
    end
    
    -- Set default values if not provided
    limit = limit or 10
    threshold = threshold or 0.0
    
    -- Validate parameters
    if type(limit) ~= "number" or limit <= 0 then
        log_message(self, "error", "Limit must be a positive number")
        return nil, "Limit must be a positive number"
    end
    
    if type(threshold) ~= "number" or threshold < 0 or threshold > 1 then
        log_message(self, "error", "Threshold must be a number between 0 and 1")
        return nil, "Threshold must be a number between 0 and 1"
    end
    
    -- Prepare parameters
    local params = {
        query = query,
        limit = limit,
        threshold = threshold
    }
    
    -- Add content_type if provided
    if content_type and content_type ~= "" then
        params.content_type = content_type
    end
    
    -- Send find_similar_content request
    local result, error_msg = send_jsonrpc_request_with_retry_and_pool_and_log(self.server_address, "find_similar_content", params, self.timeout, self.max_retries, self.retry_delay, self.pool_size, self)
    if result then
        return result
    else
        return nil, error_msg
    end
end

-- Perform hybrid search combining vector similarity with text filtering
function M:hybrid_search(query, content_type, limit, threshold, include_text_filtering)
    -- Parameter validation
    if not query or query == "" then
        log_message(self, "error", "Query parameter is required")
        return nil, "Query parameter is required"
    end
    
    if not self.connected then
        log_message(self, "error", "Not connected to server")
        return nil, "Not connected to server"
    end
    
    -- Set default values if not provided
    limit = limit or 10
    threshold = threshold or 0.0
    include_text_filtering = include_text_filtering ~= false -- Default to true
    
    -- Validate parameters
    if type(limit) ~= "number" or limit <= 0 then
        log_message(self, "error", "Limit must be a positive number")
        return nil, "Limit must be a positive number"
    end
    
    if type(threshold) ~= "number" or threshold < 0 or threshold > 1 then
        log_message(self, "error", "Threshold must be a number between 0 and 1")
        return nil, "Threshold must be a number between 0 and 1"
    end
    
    if type(include_text_filtering) ~= "boolean" then
        log_message(self, "error", "Include text filtering must be a boolean")
        return nil, "Include text filtering must be a boolean"
    end
    
    -- Prepare parameters
    local params = {
        query = query,
        limit = limit,
        threshold = threshold,
        include_text_filtering = include_text_filtering
    }
    
    -- Add content_type if provided
    if content_type and content_type ~= "" then
        params.content_type = content_type
    end
    
    -- Send hybrid_search request
    local result, error_msg = send_jsonrpc_request_with_retry_and_pool_and_log(self.server_address, "hybrid_search", params, self.timeout, self.max_retries, self.retry_delay, self.pool_size, self)
    if result then
        return result
    else
        return nil, error_msg
    end
end

-- Helper function to format search results for display
function M:format_search_results(search_results, max_length)
    if not search_results or not search_results.results then
        return "No search results found"
    end
    
    max_length = max_length or 100
    
    local formatted = {}
    for i, result in ipairs(search_results.results) do
        if result.embedding and result.embedding.content_text then
            local text = result.embedding.content_text
            if #text > max_length then
                text = text:sub(1, max_length) .. "..."
            end
            
            local score = result.similarity_score or 0
            local content_type = result.embedding.content_type or "unknown"
            
            table.insert(formatted, string.format("%d. [%s] (%.3f) %s", i, content_type, score, text))
        end
    end
    
    if #formatted == 0 then
        return "No search results found"
    end
    
    return table.concat(formatted, "\n")
end

-- Helper function to get search statistics
function M:get_search_stats(search_results)
    if not search_results or not search_results.results then
        return {
            total_results = 0,
            avg_score = 0,
            content_types = {},
            query = search_results and search_results.query or "unknown"
        }
    end
    
    local total_results = #search_results.results
    local total_score = 0
    local content_types = {}
    
    for _, result in ipairs(search_results.results) do
        if result.similarity_score then
            total_score = total_score + result.similarity_score
        end
        
        if result.embedding and result.embedding.content_type then
            local content_type = result.embedding.content_type
            content_types[content_type] = (content_types[content_type] or 0) + 1
        end
    end
    
    return {
        total_results = total_results,
        avg_score = total_results > 0 and (total_score / total_results) or 0,
        content_types = content_types,
        query = search_results.query or "unknown"
    }
end

return M 