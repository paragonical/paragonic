--[[
Test for implementing ping method in rpc_standalone.lua - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Test that ping method exists
local function test_ping_method_exists()
    print("Testing that ping method exists...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:2346")
    
    -- Test that ping method exists
    assert(type(client.ping) == "function", "ping method should exist and be a function")
    
    print("✓ ping method exists")
    return true
end

-- Test ping method implementation
local function test_ping_method_implementation()
    print("Testing ping method implementation...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:2346")
    
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
    
    -- Test ping without connection (should still work)
    print("Testing ping without connection...")
    local ping_result = client:ping()
    
    assert(ping_result ~= nil, "ping should return a result")
    assert(type(ping_result) == "string", "ping should return a string")
    assert(ping_result == "pong", "ping should return 'pong'")
    
    print("✓ ping method works without connection: " .. ping_result)
    
    -- Connect to server
    local connect_result = client:connect()
    assert(connect_result == true, "Should connect successfully")
    
    -- Test ping with connection
    print("Testing ping with connection...")
    local ping_result2 = client:ping()
    
    assert(ping_result2 ~= nil, "ping should return a result when connected")
    assert(type(ping_result2) == "string", "ping should return a string when connected")
    assert(ping_result2 == "pong", "ping should return 'pong' when connected")
    
    print("✓ ping method works with connection: " .. ping_result2)
    
    -- Test multiple ping calls
    print("Testing multiple ping calls...")
    local ping_result3 = client:ping()
    local ping_result4 = client:ping()
    local ping_result5 = client:ping()
    
    assert(ping_result3 == "pong", "First ping should return 'pong'")
    assert(ping_result4 == "pong", "Second ping should return 'pong'")
    assert(ping_result5 == "pong", "Third ping should return 'pong'")
    
    print("✓ Multiple ping calls work correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test ping error handling
local function test_ping_error_handling()
    print("Testing ping error handling...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a client with invalid server address
    local client = rpc_standalone.new("127.0.0.1:9999") -- Invalid port
    
    -- Test ping with invalid server
    local ping_result = client:ping()
    
    -- Should handle the error gracefully and return nil
    assert(ping_result == nil, "ping should fail with invalid server")
    
    print("✓ ping error handling works correctly")
    
    return true
end

-- Test ping consistency
local function test_ping_consistency()
    print("Testing ping consistency...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:2346")
    
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
    
    -- Test that multiple calls return consistent results
    local result1 = client:ping()
    local result2 = client:ping()
    local result3 = client:ping()
    
    assert(result1 == "pong", "First ping call should succeed")
    assert(result2 == "pong", "Second ping call should succeed")
    assert(result3 == "pong", "Third ping call should succeed")
    assert(result1 == result2 and result2 == result3, "Multiple ping calls should return consistent results")
    
    print("✓ ping consistency test passed")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test ping performance
local function test_ping_performance()
    print("Testing ping performance...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:2346")
    
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
    
    -- Test multiple rapid ping calls
    local start_time = os.time()
    local success_count = 0
    local total_calls = 10
    
    for i = 1, total_calls do
        local result = client:ping()
        if result == "pong" then
            success_count = success_count + 1
        end
    end
    
    local end_time = os.time()
    local duration = end_time - start_time
    
    assert(success_count == total_calls, "All ping calls should succeed")
    assert(duration <= 5, "Ping calls should complete within reasonable time")
    
    print("✓ ping performance test passed: " .. success_count .. "/" .. total_calls .. " successful in " .. duration .. " seconds")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test ping with server restart
local function test_ping_with_server_restart()
    print("Testing ping with server restart...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:2346")
    
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
    
    -- Test ping with server running
    local ping_result1 = client:ping()
    assert(ping_result1 == "pong", "ping should work with server running")
    
    -- Stop the server
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    os.execute("sleep 2")
    
    -- Test ping with server stopped
    local ping_result2 = client:ping()
    assert(ping_result2 == nil, "ping should fail with server stopped")
    
    -- Restart the server
    local server_cmd2 = "./target/debug/paragonic --no-database > /dev/null 2>&1 & echo $!"
    local server_process2 = io.popen(server_cmd2)
    if not server_process2 then
        error("Failed to restart server process")
    end
    
    local pid2 = server_process2:read("*a"):match("(%d+)")
    if not pid2 then
        error("Failed to get restarted server process ID")
    end
    
    print("✓ Server restarted with PID: " .. pid2)
    
    -- Wait for server to start
    os.execute("sleep 3")
    
    -- Test ping with server restarted
    local ping_result3 = client:ping()
    assert(ping_result3 == "pong", "ping should work with server restarted")
    
    print("✓ ping with server restart works correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Run the tests
local success, err = pcall(function()
    test_ping_method_exists()
    test_ping_method_implementation()
    test_ping_error_handling()
    test_ping_consistency()
    test_ping_performance()
    test_ping_with_server_restart()
end)

if not success then
    print("Test failed: " .. tostring(err))
    os.exit(1)
end

print("✓ All rpc_standalone ping tests passed!") 