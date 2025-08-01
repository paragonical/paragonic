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

-- Connect to the RPC server
function M:connect()
    -- TODO: Implement actual connection logic
    -- For now, just mark as connected
    self.connected = true
    return true
end

-- Disconnect from the RPC server
function M:disconnect()
    -- TODO: Implement actual disconnection logic
    -- For now, just mark as disconnected
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