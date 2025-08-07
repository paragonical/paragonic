--[[
Test for Rust backend RPC server functionality - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Global variable to store the server process
local server_process = nil

-- Test that Rust backend server can be started in background
local function test_rust_backend_server_start()
    print("Testing Rust backend server start...")
    
    -- Check if Rust backend binary exists
    local backend_binary = "./target/debug/paragonic"
    local file = io.open(backend_binary, "r")
    if file then
        file:close()
        print("✓ Rust backend binary found at " .. backend_binary)
    else
        print("⚠ Rust backend binary not found, need to build first")
        return
    end
    
    -- Start the server in background
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
    os.execute("sleep 2")
    
    print("✓ Rust backend server start test passed!")
end

-- Test that Rust backend server can accept connections
local function test_rust_backend_server_connection()
    print("Testing Rust backend server connection...")
    
    -- Load the paragonic module
    local paragonic = require("paragonic")
    
    -- Initialize backend to get RPC client
    local success = paragonic._initialize_backend()
    assert(success, "Backend initialization should succeed")
    
    -- Get RPC client (should be available after initialization)
    local rpc_client = paragonic._get_rpc_client()
    assert(rpc_client ~= nil, "Should have RPC client")
    assert(rpc_client:is_connected(), "RPC client should be connected")
    
    -- Test that we can make a call to the backend
    local response = rpc_client:hello()
    assert(response ~= nil, "Should get response from backend")
    assert(type(response) == "string", "Response should be string")
    
    -- Should contain JSON-RPC structure
    assert(response:find('"jsonrpc"'), "Should contain jsonrpc field")
    
    print("✓ Rust backend server connection test passed!")
end

-- Test that Rust backend server responds to chat completion
local function test_rust_backend_server_chat()
    print("Testing Rust backend server chat completion...")
    
    -- Load the paragonic module
    local paragonic = require("paragonic")
    
    -- Test that we can send a chat message
    local response = paragonic.send_message("Hello, this is a test message", "llama2")
    assert(response ~= nil, "Should get response from chat completion")
    assert(type(response) == "string", "Response should be string")
    
    -- Should contain the mock AI response content
    assert(response:find("mock response"), "Should contain mock AI response content")
    
    print("✓ Rust backend server chat completion test passed!")
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

-- Run the tests
local success, err = pcall(function()
    test_rust_backend_server_start()
    test_rust_backend_server_connection()
    test_rust_backend_server_chat()
end)

-- Always cleanup
cleanup_server()

if not success then
    print("Test failed: " .. tostring(err))
    os.exit(1)
end

print("✓ All Rust backend server tests passed!") 