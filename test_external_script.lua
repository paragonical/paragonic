-- Test external Lua script directly
local file = io.open("/tmp/external_script.log", "w")
if file then
    file:write("Testing external Lua script directly...\n")
    
    -- Create a simple test script
    local test_script = [[
-- Simple test script
print("Testing socket library...")

local socket_ok, socket = pcall(require, "socket")
if socket_ok then
    print("✓ Socket library available")
    
    local tcp_ok, tcp = pcall(socket.tcp)
    if tcp_ok then
        print("✓ TCP socket created")
        
        -- Try to connect
        tcp:settimeout(5)
        local connect_ok, err = tcp:connect("127.0.0.1", 3000)
        if connect_ok then
            print("✓ Connected to server")
            
            -- Send hello request
            local request = {jsonrpc = "2.0", method = "hello", params = {}, id = 1}
            local json_ok, json = pcall(require, "cjson")
            if json_ok then
                local request_json = json.encode(request)
                tcp:send(request_json .. "\n")
                print("✓ Request sent")
                
                -- Receive response
                local response, err = tcp:receive("*l")
                if response then
                    print("✓ Response received: " .. response)
                else
                    print("✗ Failed to receive response: " .. tostring(err))
                end
            else
                print("✗ JSON library not available")
            end
            
            tcp:close()
        else
            print("✗ Failed to connect: " .. tostring(err))
        end
    else
        print("✗ Failed to create TCP socket: " .. tostring(tcp))
    end
else
    print("✗ Socket library not available: " .. tostring(socket))
end

print("=== External Script Test Complete ===")
]]
    
    -- Write test script to file
    local script_file = "/tmp/test_external.lua"
    vim.fn.writefile(vim.fn.split(test_script, "\n"), script_file)
    file:write("Test script written to: " .. script_file .. "\n")
    
    -- Execute the test script
    file:write("Executing test script...\n")
    local result = vim.fn.system("lua " .. script_file)
    file:write("Script result: " .. tostring(result) .. "\n")
    
    -- Clean up
    vim.fn.delete(script_file)
    
    file:write("=== External Script Test Complete ===\n")
    file:close()
end 