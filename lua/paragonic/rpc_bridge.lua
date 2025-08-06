-- RPC Bridge for Neovim
-- This module provides a bridge to external Lua processes for socket communication
-- when the socket library is not available in Neovim

local M = {}

-- Check if we're running in Neovim
local function is_neovim()
    return vim ~= nil
end

-- Check if socket library is available
local function has_socket_library()
    local ok = pcall(require, "socket")
    return ok
end

-- Create a temporary file for communication
local function create_temp_file()
    local temp_dir = vim.fn.stdpath("cache") .. "/paragonic"
    vim.fn.mkdir(temp_dir, "p")
    return temp_dir .. "/rpc_" .. vim.fn.strftime("%Y%m%d_%H%M%S") .. "_" .. math.random(1000, 9999)
end

-- Send request via external Lua process
function M.send_request(server_address, method, params)
    if not is_neovim() then
        return nil, "Not running in Neovim"
    end
    
    -- Create temporary files for request and response
    local temp_file = create_temp_file()
    local request_file = temp_file .. "_request.json"
    local response_file = temp_file .. "_response.json"
    
    -- Create the request
    local request = {
        jsonrpc = "2.0",
        method = method,
        params = params or {},
        id = 1
    }
    
    -- Write request to file
    local request_json = vim.json.encode(request)
    vim.fn.writefile({request_json}, request_file)
    
    -- Create the external Lua script
    local script_content = string.format([[
-- External RPC script
package.path = package.path .. ";%s/lua/?.lua;%s/lua/?/init.lua"

local socket = require("socket")
local json = require("cjson")

-- Read request
local request_file = "%s"
local response_file = "%s"

local request_content = io.open(request_file, "r"):read("*a")
local request = json.decode(request_content)

-- Parse server address
local server_addr = "%s"
local host, port = server_addr:match("([^:]+):?([0-9]*)")
port = port or "3000"

-- Connect to server
local tcp = socket.tcp()
tcp:settimeout(5)
local success, err = tcp:connect(host, tonumber(port))

if not success then
    local error_response = json.encode({
        jsonrpc = "2.0",
        error = {code = -1, message = "Connection failed: " .. err},
        id = request.id
    })
    io.open(response_file, "w"):write(error_response):close()
    os.exit(1)
end

-- Send request
local request_json = json.encode(request)
tcp:send(request_json .. "\n")

-- Receive response
local response, err = tcp:receive("*l")
tcp:close()

if not response then
    local error_response = json.encode({
        jsonrpc = "2.0",
        error = {code = -1, message = "Failed to receive response: " .. err},
        id = request.id
    })
    io.open(response_file, "w"):write(error_response):close()
    os.exit(1)
end

-- Write response to file
io.open(response_file, "w"):write(response):close()
]], vim.fn.getcwd(), vim.fn.getcwd(), request_file, response_file, server_address)
    
    local script_file = temp_file .. "_script.lua"
    vim.fn.writefile(vim.fn.split(script_content, "\n"), script_file)
    
    -- Execute the external script with timeout (macOS compatible)
    local timeout_cmd
    if vim.fn.executable("timeout") == 1 then
        timeout_cmd = "timeout 10 lua " .. script_file
    elseif vim.fn.executable("gtimeout") == 1 then
        timeout_cmd = "gtimeout 10 lua " .. script_file
    else
        -- macOS fallback: use background process with sleep and kill
        timeout_cmd = "lua " .. script_file .. " & sleep 10 && kill $! 2>/dev/null || true"
    end
    local result = vim.fn.system(timeout_cmd)
    
    -- Clean up script file
    vim.fn.delete(script_file)
    vim.fn.delete(request_file)
    
    -- Read response
    if vim.fn.filereadable(response_file) == 1 then
        local response_content = vim.fn.readfile(response_file)
        vim.fn.delete(response_file)
        
        if #response_content > 0 then
            local response_json = table.concat(response_content, "\n")
            local success, response = pcall(vim.json.decode, response_json)
            if success then
                return response
            else
                return nil, "Failed to parse response: " .. response
            end
        else
            return nil, "Empty response file"
        end
    else
        return nil, "Response file not found: " .. result
    end
end

return M 