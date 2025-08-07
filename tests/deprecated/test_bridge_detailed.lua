-- Detailed test for RPC bridge with Neovim simulation
local file = io.open("/tmp/bridge_detailed.log", "w")
if file then
    file:write("Testing detailed RPC bridge...\n")
    
    -- Simulate Neovim functions
    local vim = {}
    vim.fn = {}
    vim.json = {}
    
    -- Mock vim.fn functions
    vim.fn.stdpath = function(path)
        if path == "cache" then
            return "/tmp"
        end
        return "/tmp"
    end
    
    vim.fn.mkdir = function(dir, mode)
        os.execute("mkdir -p " .. dir)
        return 1
    end
    
    vim.fn.strftime = function(format)
        return os.date(format)
    end
    
    vim.fn.writefile = function(lines, filename)
        local f = io.open(filename, "w")
        if f then
            for _, line in ipairs(lines) do
                f:write(line .. "\n")
            end
            f:close()
            return 1
        end
        return 0
    end
    
    vim.fn.split = function(str, sep)
        local result = {}
        for line in str:gmatch("[^" .. sep .. "]+") do
            table.insert(result, line)
        end
        return result
    end
    
    vim.fn.executable = function(cmd)
        local result = os.execute("which " .. cmd .. " > /dev/null 2>&1")
        return result and 1 or 0
    end
    
    vim.fn.system = function(cmd)
        local handle = io.popen(cmd .. " 2>&1", "r")
        if handle then
            local result = handle:read("*a")
            handle:close()
            return result
        end
        return ""
    end
    
    vim.fn.delete = function(filename)
        os.remove(filename)
        return 1
    end
    
    vim.fn.filereadable = function(filename)
        local f = io.open(filename, "r")
        if f then
            f:close()
            return 1
        end
        return 0
    end
    
    vim.fn.readfile = function(filename)
        local f = io.open(filename, "r")
        if f then
            local content = {}
            for line in f:lines() do
                table.insert(content, line)
            end
            f:close()
            return content
        end
        return {}
    end
    
    vim.fn.getcwd = function()
        return io.popen("pwd"):read("*l")
    end
    
    -- Mock vim.json functions
    vim.json.encode = function(data)
        local cjson = require("cjson")
        return cjson.encode(data)
    end
    
    vim.json.decode = function(json_str)
        local cjson = require("cjson")
        return cjson.decode(json_str)
    end
    
    file:write("Neovim functions mocked\n")
    
    -- Now test the bridge logic
    local server_address = "127.0.0.1:3000"
    local method = "hello"
    local params = {}
    
    -- Create temporary files for request and response
    local temp_dir = vim.fn.stdpath("cache") .. "/paragonic"
    vim.fn.mkdir(temp_dir, "p")
    local temp_file = temp_dir .. "/rpc_" .. vim.fn.strftime("%Y%m%d_%H%M%S") .. "_" .. math.random(1000, 9999)
    local request_file = temp_file .. "_request.json"
    local response_file = temp_file .. "_response.json"
    
    file:write("Temp file base: " .. temp_file .. "\n")
    file:write("Request file: " .. request_file .. "\n")
    file:write("Response file: " .. response_file .. "\n")
    
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
    file:write("Request written: " .. request_json .. "\n")
    
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
local host, port = "%s":match("([^:]+):?(%d*)")
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
    file:write("Script file created: " .. script_file .. "\n")
    
    -- Check if script file exists
    if vim.fn.filereadable(script_file) == 1 then
        file:write("✓ Script file exists\n")
        
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
        
        file:write("Using timeout command: " .. timeout_cmd .. "\n")
        local result = vim.fn.system(timeout_cmd)
        file:write("Script execution result: " .. tostring(result) .. "\n")
        
        -- Check if response file was created
        if vim.fn.filereadable(response_file) == 1 then
            file:write("✓ Response file created\n")
            local response_content = vim.fn.readfile(response_file)
            file:write("Response content: " .. table.concat(response_content, "\n") .. "\n")
            
            if #response_content > 0 then
                local response_json = table.concat(response_content, "\n")
                local success, response = pcall(vim.json.decode, response_json)
                if success then
                    file:write("✓ Response parsed successfully: " .. tostring(response) .. "\n")
                else
                    file:write("✗ Failed to parse response: " .. response .. "\n")
                end
            else
                file:write("✗ Empty response file\n")
            end
        else
            file:write("✗ Response file not created\n")
        end
    else
        file:write("✗ Script file not created\n")
    end
    
    -- Clean up
    vim.fn.delete(script_file)
    vim.fn.delete(request_file)
    vim.fn.delete(response_file)
    
    file:write("=== Detailed Bridge Test Complete ===\n")
    file:close()
end 