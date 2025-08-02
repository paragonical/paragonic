--[[
Paragonic RPC Client for connecting to Rust JSON-RPC server
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

-- Send hello method to server
function M:hello()
    -- TODO: Implement actual RPC call
    -- For now, return mock response
    return "world"
end

return M
 