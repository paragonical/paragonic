--[[
Debug test for RPC communication - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Global variable to store the server process
local server_process = nil

-- Test RPC communication with debugging
local function test_rpc_debug()
    print("Testing RPC communication with debugging...")
    
    -- Start the server in background
    local backend_binary = "./target/debug/paragonic"
    server_process = io.popen(backend_binary .. " > /dev/null 2>&1 & echo $!")
    if not server_process then
        error("Failed to start server process")
    end
    
    -- Get the process ID
    local pid = server_process:read("*a"):match("(%d+)")
    if not pid then
        error("Failed to get server process ID")
    end
    
    print("✓ Server started with PID: " .. pid)
    
    -- Wait a moment for the server to start up
    os.execute("sleep 3")
    
    -- Load the paragonic module
    local paragonic = require("paragonic")
    
    -- Get RPC client
    local rpc_client = paragonic._get_rpc_client()
    assert(rpc_client ~= nil, "Should have RPC client")
    assert(rpc_client:is_connected(), "RPC client should be connected")
    
    -- Test hello method
    print("Testing hello method...")
    local hello_response = rpc_client:hello()
    print("Hello response: " .. tostring(hello_response))
    
    -- Test chat completion with debugging
    print("Testing chat completion...")
    local chat_response = rpc_client:chat_completion("llama2", "Hello, what is 2+2?")
    print("Chat response: " .. tostring(chat_response))
    
    -- Test list models
    print("Testing list models...")
    local models_response = rpc_client:list_models()
    print("Models response: " .. tostring(models_response))
    
    print("✓ RPC debug test completed!")
end

-- Cleanup function to stop the server
local function cleanup_server()
    if server_process then
        server_process:close()
        -- Kill the background process
        os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
        print("✓ Server cleanup completed")
    end
end

-- Run the test
local success, err = pcall(function()
    test_rpc_debug()
end)

-- Always cleanup
cleanup_server()

if not success then
    print("Test failed: " .. tostring(err))
    os.exit(1)
end

print("✓ RPC debug test passed!") 