--[[
Debug test for rpc_standalone hello method - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Debug the hello method
local function debug_hello_method()
    print("Debugging hello method...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:3000")
    
    -- Start the Rust backend server with database bypass
    local server_cmd = "./target/debug/paragonic --no-database > /dev/null 2>&1 & echo $!"
    local server_process = io.popen(server_cmd)
    if not server_process then
        error("Failed to start server process")
    end
    
    local pid = server_process:read("*a"):match("(%d+)")
    if not pid then
        error("Failed to get server process ID")
    end
    
    print("✓ Server started with PID: " .. pid)
    
    -- Wait for server to start
    os.execute("sleep 3")
    
    -- Connect to server
    local connect_result = client:connect()
    print("Connect result: " .. tostring(connect_result))
    print("Connected: " .. tostring(client.connected))
    
    -- Test hello method
    local hello_result = client:hello()
    print("Hello result type: " .. type(hello_result))
    print("Hello result: " .. tostring(hello_result))
    
    if type(hello_result) == "string" then
        print("Hello result length: " .. #hello_result)
        print("Hello result first 100 chars: " .. hello_result:sub(1, 100))
    end
    
    -- Test raw netcat call for comparison
    print("Testing raw netcat call...")
    local raw_cmd = 'echo \'{"jsonrpc":"2.0","method":"hello","params":{},"id":1}\' | nc -w 5 127.0.0.1 3000'
    local raw_process = io.popen(raw_cmd)
    if raw_process then
        local raw_result = raw_process:read("*a")
        raw_process:close()
        print("Raw netcat result: " .. raw_result:sub(1, 100))
    end
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
end

-- Run the debug
local success, err = pcall(debug_hello_method)

if not success then
    print("Debug failed: " .. tostring(err))
    os.exit(1)
end

print("✓ Debug completed!") 