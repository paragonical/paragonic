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
                    {name = "deepseek-r1:1.5b", description = "DeepSeek R1 1.5B model"},
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
        },
        streaming_chat_completion = {
            jsonrpc = "2.0",
            result = {
                type = "streaming_chunk",
                chunk_index = 0,
                total_chunks = 3,
                chunk = "<think>\nAlright, so I need to figure out how to create a parts list for a Stirling engine. Hmm, okay, let me think about this step by step. First, I remember that a Stirling engine is an internal combustion engine, but it uses a different working fluid and operates differently than a Carnot engine. The main components must be different from those of an internal combustion engine.\n\n> I know a Stirling engine consists of two heat reservoirs-a hot one and a cold one-and the working substance, which in this case is usually a gas like air. It alternates between isothermal expansion at the high temperature and adiabatic expansion at the low temperature. There are also moving parts like pistons or steam chambers.\n\n> I think I should start by listing the components of each part first. Maybe break down the engine into main sections: the heat source, the working fluid, the compression system, the connecting rods, the cooling mechanism, and so on.\n\n> For the heat sources, there must be two reservoirs-hot and cold. Each would have a temperature and perhaps a pressure or volume. The hot one should be at a higher temperature than the cold one. So I'll need temperatures for both. Maybe 400°C for the hot and 120°C for the cold, just as an example.\n\n> The working fluid is usually air, so I can list that under 'working fluid' or maybe include it under 'comppressed gas.' The pressure and volume at these reservoirs might be important too. For instance, the high-pressure reservoir could have a pressure of 16 bar and a volume of 250 cm³, while the low-pressure reservoir would have 3 bar and 140 cm³. This helps in calculating work done during expansion.\n</think>\n\nCreating a comprehensive parts list for a Stirling engine:\n\n### 1. Heat Sources\n- **High Temperature Reservoir:**\n  - Temperature: 400°C (673 K)\n  - Pressure: 16 bar\n  - Volume: 250 cm³\n\n- **Low Temperature Reservoir:**\n  - Temperature: 120°C (393 K)\n  - Pressure: 3 bar\n  - Volume: 140 cm³\n\n### 2. Working Fluid\n- **Type:** Air\n- **Mass:** 5 kg\n- **Operating pressure range:** 3-16 bar\n\n### 3. Mechanical Components\n- **High-pressure piston:** 150 g\n- **Low-pressure piston:** 100 g\n- **Connecting rods:** High-pressure (40 cm), Low-pressure (28 cm)\n- **Cooling system:** Initial temperature 20°C\n- **Piston areas:** Large (16 cm²) for high-pressure, small (8 cm²) for low-pressure",
                remaining_chunks = 2
            },
            id = 1
        },
        get_next_chunk = {
            jsonrpc = "2.0",
            result = {
                type = "streaming_chunk",
                chunk_index = 1,
                total_chunks = 3,
                chunk = "",
                remaining_chunks = 1
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
            local config = require("paragonic.config")
        local default_model = config.get("ollama_model") or "deepseek-r1:1.5b"
        return self:call("chat_completion", {message = message, model = model or default_model})
end

function M:formatted_chat_completion(model, message, format_config)
    return self:call("formatted_chat_completion", {message, model, format_config})
end

function M:streaming_chat_completion(params)
    return self:call("streaming_chat_completion", params)
end

function M:get_next_chunk(params)
    return self:call("get_next_chunk", params)
end

function M:debug_markdown_test(format_config)
    return self:call("debug_markdown_test", format_config or {})
end

function M:disconnect()
    print("🔧 Simple RPC: disconnect() called")
    self.connected = false
end

return M 