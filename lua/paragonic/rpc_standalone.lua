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
        socket = nil
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

-- Send JSON-RPC request using external command
local function send_jsonrpc_request(server_address, method, params)
    -- Parse server address
    local host, port = server_address:match("([^:]+):?(%d*)")
    if not host then
        return nil, "Invalid server address format"
    end
    
    -- Default port to 3000 if not specified
    port = port or "3000"
    
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
    
    -- Send request using netcat
    local cmd = string.format('echo \'%s\' | nc -w 10 %s %s', json_request, host, port)
    local process = io.popen(cmd)
    if not process then
        return nil, "Failed to execute RPC request"
    end
    
    local response = process:read("*a")
    process:close()
    
    if response and response ~= "" then
        -- Try to parse the response
        local success, parsed = pcall(cjson.decode, response)
        if success and parsed and parsed.result then
            return parsed.result, nil
        else
            return response, nil -- Return raw response if parsing fails
        end
    else
        return nil, "No response from server"
    end
end

-- Send hello method to server
function M:hello()
    if not self.connected then
        return nil, "Not connected to server"
    end
    
    local result, error_msg = send_jsonrpc_request(self.server_address, "hello", {})
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
    local result, error_msg = send_jsonrpc_request(self.server_address, "chat_completion", {message, model})
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
    local result, error_msg = send_jsonrpc_request(self.server_address, "list_models", {})
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
    local result, error_msg = send_jsonrpc_request(self.server_address, "model_info", {model_name})
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
    local result, error_msg = send_jsonrpc_request(self.server_address, "generate_embedding", {text, model})
    if result then
        return result
    else
        return nil, error_msg
    end
end

-- Ping the server to test connectivity and get server status
function M:ping()
    -- Send ping request to server (uses hello method as ping)
    local result, error_msg = send_jsonrpc_request(self.server_address, "hello", {})
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
        local hello_result = send_jsonrpc_request(self.server_address, "hello", {})
        if hello_result then
            -- Server is responding, we could extend this to get more detailed info
            -- For now, we just confirm it's running
            server_info.status = "running"
        end
    end
    
    return server_info
end

return M 