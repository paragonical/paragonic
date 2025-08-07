-- Test with exact bridge format string
local file = io.open("/tmp/bridge_exact.log", "w")
if file then
    file:write("Testing exact bridge format string...\n")
    
    -- Use the exact same format string as the bridge
    local cwd = "/Users/sjanes/work2/paragonic"
    local request_file = "/tmp/test_request.json"
    local response_file = "/tmp/test_response.json"
    local server_address = "127.0.0.1:3000"
    
    file:write("Parameters:\n")
    file:write("cwd: " .. cwd .. "\n")
    file:write("request_file: " .. request_file .. "\n")
    file:write("response_file: " .. response_file .. "\n")
    file:write("server_address: " .. server_address .. "\n")
    
    -- Create the external Lua script (exact copy from bridge)
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
]], cwd, cwd, request_file, response_file, server_address)
    
    file:write("✓ String format successful\n")
    file:write("Script content length: " .. #script_content .. "\n")
    
    -- Write the script to a file and test it
    local script_file = "/tmp/test_exact_script.lua"
    local f = io.open(script_file, "w")
    if f then
        f:write(script_content)
        f:close()
        file:write("✓ Script file written\n")
        
        -- Create a test request
        local request = {
            jsonrpc = "2.0",
            method = "hello",
            params = {},
            id = 1
        }
        
        local cjson = require("cjson")
        local request_json = cjson.encode(request)
        local req_f = io.open(request_file, "w")
        if req_f then
            req_f:write(request_json)
            req_f:close()
            file:write("✓ Request file written\n")
            
            -- Test the script execution
            local result = os.execute("lua " .. script_file)
            file:write("Script execution result: " .. tostring(result) .. "\n")
            
            -- Check if response file was created
            local resp_f = io.open(response_file, "r")
            if resp_f then
                local response_content = resp_f:read("*a")
                resp_f:close()
                file:write("✓ Response file created\n")
                file:write("Response content: " .. response_content .. "\n")
            else
                file:write("✗ Response file not created\n")
            end
            
            -- Clean up
            os.remove(request_file)
            os.remove(response_file)
        else
            file:write("✗ Failed to write request file\n")
        end
        
        -- Keep script file for debugging
        -- os.remove(script_file)
    else
        file:write("✗ Failed to write script file\n")
    end
    
    file:write("=== Exact Bridge Test Complete ===\n")
    file:close()
end 