--[[
Test for implementing list_models method in rpc_standalone.lua - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Global variable to store the server process
local server_process = nil
local server_pid = nil

-- Test that list_models method exists
local function test_list_models_method_exists()
    print("Testing list_models method exists...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:2346")
    
    -- Test that list_models method exists
    assert(client.list_models ~= nil, "list_models method should exist")
    assert(type(client.list_models) == "function", "list_models should be a function")
    
    print("✓ list_models method exists")
    return true
end

-- Test list_models method implementation
local function test_list_models_method_implementation()
    print("Testing list_models method implementation...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:2346")
    
    -- Start the Rust backend server with database bypass
    local server_cmd = "./target/debug/paragonic --no-database > /dev/null 2>&1 & echo $!"
    server_process = io.popen(server_cmd)
    if not server_process then
        error("Failed to start server process")
    end
    
    -- Get the process ID
    server_pid = server_process:read("*a"):match("(%d+)")
    if not server_pid then
        error("Failed to get server process ID")
    end
    
    print("✓ Server started with PID: " .. server_pid)
    
    -- Wait for server to start
    os.execute("sleep 3")
    
    -- Connect to server
    local connect_result = client:connect()
    assert(connect_result == true, "Should connect successfully")
    
    -- Test list_models with connection
    print("Testing list_models with connection...")
    local result1 = client:list_models()
    
    assert(result1 ~= nil, "list_models should succeed when connected")
    assert(type(result1) == "table", "list_models should return a table")
    assert(#result1 > 0, "list_models should return at least one model")
    
    print("✓ list_models works correctly when connected")
    
    -- Test list_models without connection
    print("Testing list_models without connection...")
    client:disconnect()
    local result2 = client:list_models()
    
    assert(result2 == nil, "list_models should fail when not connected")
    
    print("✓ list_models correctly fails when not connected")
    
    -- Cleanup
    if server_pid then
        os.execute("kill " .. server_pid .. " > /dev/null 2>&1")
        print("✓ Test server (PID: " .. server_pid .. ") cleanup completed")
    end
    
    return true
end

-- Test list_models error handling
local function test_list_models_error_handling()
    print("Testing list_models error handling...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a client with invalid server address
    local client = rpc_standalone.new("127.0.0.1:9999") -- Invalid port
    
    -- Test list_models with invalid server
    local result = client:list_models()
    
    -- Should handle the error gracefully
    assert(result == nil, "list_models should fail with invalid server")
    
    print("✓ list_models error handling works correctly")
    
    return true
end

-- Test list_models consistency
local function test_list_models_consistency()
    print("Testing list_models consistency...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:2346")
    
    -- Start the Rust backend server with database bypass
    local server_cmd = "./target/debug/paragonic --no-database > /dev/null 2>&1 & echo $!"
    local server_process2 = io.popen(server_cmd)
    if not server_process2 then
        error("Failed to start server process")
    end
    
    local pid2 = server_process2:read("*a"):match("(%d+)")
    if not pid2 then
        error("Failed to get server process ID")
    end
    
    print("✓ Server started with PID: " .. pid2)
    
    -- Wait for server to start
    os.execute("sleep 3")
    
    -- Connect to server
    local connect_result = client:connect()
    assert(connect_result == true, "Should connect successfully")
    
    -- Test that multiple calls return consistent results
    local result1 = client:list_models()
    local result2 = client:list_models()
    
    assert(result1 ~= nil, "First list_models call should succeed")
    assert(result2 ~= nil, "Second list_models call should succeed")
    assert(result1 == result2, "Multiple list_models calls should return consistent results")
    
    print("✓ list_models consistency test passed")
    
    -- Cleanup
    if pid2 then
        os.execute("kill " .. pid2 .. " > /dev/null 2>&1")
        print("✓ Test server (PID: " .. pid2 .. ") cleanup completed")
    end
    
    return true
end

-- Run the tests
local success, err = pcall(function()
    test_list_models_method_exists()
    test_list_models_method_implementation()
    test_list_models_error_handling()
    test_list_models_consistency()
end)

if not success then
    print("Test failed: " .. tostring(err))
    os.exit(1)
end

print("✓ All rpc_standalone list_models tests passed!") 