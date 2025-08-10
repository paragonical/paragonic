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
local server_pid = nil
local TEST_PORT = 3001

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
    
    -- Start the server in background on test port
    local server_cmd = backend_binary .. " --port " .. TEST_PORT .. " > /dev/null 2>&1 & echo $!"
    server_process = io.popen(server_cmd)
    if not server_process then
        error("Failed to start server process")
    end
    
    -- Get the process ID
    server_pid = server_process:read("*a"):match("(%d+)")
    if not server_pid then
        error("Failed to get server process ID")
    end
    
    print("✓ Server started with PID: " .. server_pid .. " on port " .. TEST_PORT)
    
    -- Wait a moment for the server to start up
    os.execute("sleep 2")
    
    print("✓ Rust backend server start test passed!")
end

-- Test that Rust backend server can accept connections
local function test_rust_backend_server_connection()
    print("Testing Rust backend server connection...")
    
    -- Load the paragonic module
    local paragonic = require("paragonic")
    
    -- Create a temporary RPC client for the test server
    local rpc = require("paragonic.rpc")
    local test_client = rpc.new("127.0.0.1:" .. TEST_PORT)
    
    -- Test that we can make a call to the backend
    local response = test_client:hello()
    assert(response ~= nil, "Should get response from backend")
    assert(type(response) == "string", "Response should be string")
    
    -- Parse the JSON-RPC response
    local success, parsed = pcall(vim.json.decode, response)
    assert(success, "Should be able to parse JSON response")
    assert(parsed.jsonrpc == "2.0", "Should be JSON-RPC 2.0")
    assert(parsed.result == "world", "Should get 'world' as result")
    
    print("✓ Rust backend server connection test passed!")
end

-- Test that Rust backend server responds to chat completion
local function test_rust_backend_server_chat()
    print("Testing Rust backend server chat completion...")
    
    -- Create a temporary RPC client for the test server
    local rpc = require("paragonic.rpc")
    local test_client = rpc.new("127.0.0.1:" .. TEST_PORT)
    
    -- Test that we can send a chat message
    local response = test_client:chat_completion("llama2", "Hello, this is a test message")
    assert(response ~= nil, "Should get response from chat completion")
    assert(type(response) == "string", "Response should be string")
    
    -- Parse the JSON-RPC response
    local success, parsed = pcall(vim.json.decode, response)
    assert(success, "Should be able to parse JSON response")
    assert(parsed.jsonrpc == "2.0", "Should be JSON-RPC 2.0")
    assert(parsed.result ~= nil, "Should have a result")
    
    print("✓ Rust backend server chat completion test passed!")
end

-- Cleanup function to stop the server
local function cleanup_server()
    if server_process then
        server_process:close()
        -- Kill only the specific test server process
        if server_pid then
            os.execute("kill " .. server_pid .. " > /dev/null 2>&1")
            print("✓ Test server (PID: " .. server_pid .. ") cleanup completed")
        end
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