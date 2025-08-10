--[[
Debug test for RPC communication
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Mock vim functions
vim = {
    json = {
        encode = function(obj)
            if type(obj) == "table" then
                local parts = {}
                for k, v in pairs(obj) do
                    local key_str = string.format('"%s"', k)
                    local value_str
                    if type(v) == "string" then
                        value_str = string.format('"%s"', v)
                    elseif type(v) == "table" then
                        value_str = "[]"  -- Empty array for params
                    else
                        value_str = tostring(v)
                    end
                    table.insert(parts, key_str .. ":" .. value_str)
                end
                return "{" .. table.concat(parts, ",") .. "}"
            else
                return tostring(obj)
            end
        end,
        decode = function(str)
            print("DEBUG: Decoding JSON: " .. str)
            if str:find('"result"') then
                return {result = "test_response"}
            else
                return {error = "parse_error"}
            end
        end
    }
}

-- Test direct socket communication
local function test_direct_socket()
    print("Testing direct socket communication...")
    
    -- Try to load socket library
    local socket_available = pcall(require, "socket")
    local socket = socket_available and require("socket") or nil
    
    if not socket then
        print("✗ Socket library not available")
        return
    end
    
    -- Create TCP socket
    local sock = socket.tcp()
    sock:settimeout(5)
    
    -- Connect to backend
    local success, err = sock:connect("127.0.0.1", 3000)
    if not success then
        print("✗ Connection failed: " .. tostring(err))
        return
    end
    
    print("✓ Connected to backend")
    
    -- Create hello request
    local request = {
        jsonrpc = "2.0",
        method = "hello",
        params = {},
        id = 1
    }
    
    local request_json = vim.json.encode(request)
    print("DEBUG: Sending request: " .. request_json)
    
    -- Send request (line-delimited)
    local send_success, send_err = sock:send(request_json .. "\n")
    if not send_success then
        print("✗ Send failed: " .. tostring(send_err))
        sock:close()
        return
    end
    
    print("✓ Request sent")
    
    -- Receive response
    local response, recv_err = sock:receive("*l") -- Receive one line
    if not response then
        print("✗ Receive failed: " .. tostring(recv_err))
        sock:close()
        return
    end
    
    print("✓ Response received: " .. response)
    
    -- Parse response
    local success, parsed = pcall(vim.json.decode, response)
    if success and parsed then
        print("✓ Response parsed successfully")
        if parsed.result then
            print("✓ Result: " .. tostring(parsed.result))
        end
        if parsed.error then
            print("✗ Error: " .. tostring(parsed.error))
        end
    else
        print("✗ Failed to parse response")
    end
    
    sock:close()
end

-- Test the RPC module
local function test_rpc_module()
    print("\nTesting RPC module...")
    
    local rpc = require("paragonic.rpc")
    local client = rpc.new("127.0.0.1:3000")
    
    local success, err = client:connect()
    if success then
        print("✓ RPC connection successful")
        
        local response = client:hello()
        print("DEBUG: Hello response: " .. tostring(response))
        
        if response then
            local success, parsed = pcall(vim.json.decode, response)
            if success and parsed then
                print("✓ Response parsed: " .. vim.json.encode(parsed))
            else
                print("✗ Failed to parse response")
            end
        else
            print("✗ No response from hello")
        end
        
        client:disconnect()
    else
        print("✗ RPC connection failed: " .. tostring(err))
    end
end

-- Run tests
print("=== RPC Debug Test ===")
test_direct_socket()
test_rpc_module()
print("\n=== Debug Test Complete ===") 