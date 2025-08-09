-- Simple RPC Client for Neovim
-- Uses Neovim's built-in capabilities without external system() calls

local M = {}

-- JSON encode/decode using vim.json
local function encode_json(obj)
    return vim.json.encode(obj)
end

local function decode_json(str)
    return vim.json.decode(str)
end

-- Simple RPC Client constructor
function M.new(server_address)
    local client = {
        server_address = server_address,
        connected = false,
        host = nil,
        port = nil
    }
    
    -- Parse server address
    local host, port = server_address:match("([^:]+):?(%d*)")
    client.host = host
    client.port = tonumber(port) or 3000
    
    -- Set metatable for object-oriented behavior
    setmetatable(client, { __index = M })
    
    return client
end

-- Connect to the RPC server (simplified - just mark as connected)
function M:connect()
    print("🔧 Simple RPC: connect() called for " .. self.host .. ":" .. self.port)
    
    -- For now, just mark as connected
    -- In a real implementation, we'd use vim.loop.tcp() or similar
    self.connected = true
    print("✅ Simple RPC: Connection marked as successful")
    return true, nil  -- Return success, no error
end

-- Check if connected
function M:is_connected()
    return self.connected
end

-- Make a JSON-RPC call using a simple approach
function M:call(method, params)
    print("🔧 Simple RPC: call() called with method=" .. tostring(method))
    
    if not self:is_connected() then
        print("❌ Simple RPC: Not connected")
        return nil, "Not connected to server"
    end
    
    -- Create the request
    local request = {
        jsonrpc = "2.0",
        method = method,
        params = params or {},
        id = 1
    }
    
    local request_json = encode_json(request)
    print("🔧 Simple RPC: Request JSON: " .. request_json)
    
    -- For now, return a mock response
    -- In a real implementation, we'd use vim.loop.tcp() to send/receive
    local mock_responses = {
        hello = {
            jsonrpc = "2.0",
            result = "world",
            id = 1
        },
        list_models = {
            jsonrpc = "2.0",
            result = {
                models = {
                    {name = "llama2", description = "Llama 2 model"},
                    {name = "llama3.2:3b", description = "Llama 3.2 3B model"},
                    {name = "nomic-embed-text:latest", description = "Nomic embedding model"}
                }
            },
            id = 1
        },
        chat_completion = {
            jsonrpc = "2.0",
            result = {
                content = "This is a mock response from the AI. In a real implementation, this would be the actual AI response."
            },
            id = 1
        }
    }
    
    local response = mock_responses[method]
    if response then
        print("✅ Simple RPC: Returning mock response for " .. method)
        return encode_json(response)
    else
        print("❌ Simple RPC: No mock response for method " .. method)
        return encode_json({
            jsonrpc = "2.0",
            error = {
                code = -32601,
                message = "Method not found: " .. method
            },
            id = 1
        })
    end
end

-- Convenience methods
function M:hello()
    return self:call("hello", {})
end

function M:list_models()
    return self:call("list_models", {})
end

function M:chat_completion(message, model)
    return self:call("chat_completion", {message = message, model = model or "llama2"})
end

function M:formatted_chat_completion(model, message, format_config)
    return self:call("formatted_chat_completion", {message, model, format_config})
end

function M:disconnect()
    print("🔧 Simple RPC: disconnect() called")
    self.connected = false
end

return M 