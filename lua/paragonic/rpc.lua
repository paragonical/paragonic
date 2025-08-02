--[[
Paragonic RPC Client for connecting to Rust JSON-RPC server
--]]

local M = {}

-- Try to load cjson, fallback to custom encoder if not available
local cjson_available = pcall(require, "cjson")
local cjson = cjson_available and require("cjson") or nil

-- Simple JSON encoding for basic objects (fallback)
local function encode_json_fallback(obj)
    if type(obj) == "table" then
        local parts = {}
        for k, v in pairs(obj) do
            if type(k) == "string" then
                table.insert(parts, string.format('"%s":%s', k, encode_json_fallback(v)))
            else
                table.insert(parts, encode_json_fallback(v))
            end
        end
        return "{" .. table.concat(parts, ",") .. "}"
    elseif type(obj) == "string" then
        return string.format('"%s"', obj)
    elseif type(obj) == "number" then
        return tostring(obj)
    elseif type(obj) == "boolean" then
        return obj and "true" or "false"
    else
        return "null"
    end
end

-- JSON encode function that uses cjson if available, fallback otherwise
local function encode_json(obj)
    if cjson then
        return cjson.encode(obj)
    else
        return encode_json_fallback(obj)
    end
end

-- JSON decode function that uses cjson if available, fallback otherwise
local function decode_json(str)
    if cjson then
        return cjson.decode(str)
    else
        -- Simple fallback decoder for basic cases
        -- This is very limited and should be replaced with a proper decoder
        error("JSON decoding not available without cjson")
    end
end

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

-- Connect to the RPC server
function M:connect()
    -- Parse server address
    local host, port = self.server_address:match("([^:]+):?(%d*)")
    port = port or "3000" -- Default port if not specified
    
    -- Use Neovim's built-in socket capabilities
    -- For now, create a mock socket object that simulates connection
    -- TODO: Replace with actual Neovim socket implementation when available
    self.socket = {
        connected = true,
        host = host,
        port = tonumber(port),
        close = function(self)
            self.connected = false
        end
    }
    
    -- Mark as connected
    self.connected = true
    return true
end

-- Disconnect from the RPC server
function M:disconnect()
    if self.socket then
        self.socket:close()
        self.socket = nil
    end
    self.connected = false
    return true
end

-- Check if connected
function M:is_connected()
    return self.connected
end

-- Make a JSON-RPC call
function M:call(method, params)
    -- Check if connected
    if not self:is_connected() then
        return nil, "Not connected to server"
    end
    
    -- Create JSON-RPC request
    local request = {
        jsonrpc = "2.0",
        method = method,
        params = params or {},
        id = 1
    }
    
    local request_json = encode_json(request)
    
    -- Add Content-Length header for JSON-RPC
    local message = "Content-Length: " .. #request_json .. "\r\n\r\n" .. request_json
    
    -- Send request through socket
    -- For now, simulate sending and receiving
    -- TODO: Replace with actual socket send/receive when available
    self.socket.last_request = message
    
    -- Simulate JSON-RPC response
    local response = {
        jsonrpc = "2.0",
        result = "mock_response",
        id = 1
    }
    
    return encode_json(response)
end

-- Send hello method to server
function M:hello()
    return self:call("hello", {})
end

-- Send chat completion request to server
function M:chat_completion(model, message)
    return self:call("chat_completion", {
        model = model,
        message = message
    })
end

-- List available models
function M:list_models()
    return self:call("list_models", {})
end

-- Get model information
function M:model_info(model)
    return self:call("model_info", {
        model = model
    })
end

-- Get list of projects
function M:get_projects()
    return self:call("get_projects", {})
end

-- Create a new project
function M:create_project(name, description)
    return self:call("create_project", {
        name = name,
        description = description
    })
end

-- Get configuration
function M:get_config()
    return self:call("get_config", {})
end

-- Save configuration
function M:save_config(config_data)
    return self:call("save_config", config_data)
end

return M
 