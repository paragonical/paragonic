--[[
Test for implementing timeout_operations method in rpc_standalone.lua - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Test that timeout_operations method exists
local function test_timeout_operations_method_exists()
    print("Testing that timeout_operations method exists...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:3000")
    
    -- Test that timeout_operations method exists
    assert(type(client.timeout_operations) == "function", "timeout_operations method should exist and be a function")
    
    print("✓ timeout_operations method exists")
    return true
end

-- Test timeout_operations method implementation
local function test_timeout_operations_method_implementation()
    print("Testing timeout_operations method implementation...")
    
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
    assert(connect_result == true, "Should connect successfully")
    
    -- Test timeout_operations with normal timeout
    print("Testing timeout_operations with normal timeout...")
    local timeout_result = client:timeout_operations(5) -- 5 second timeout
    
    assert(timeout_result == true, "timeout_operations should return true when successful")
    
    -- Test that operations work with the timeout set
    local hello_result = client:hello()
    assert(hello_result == "world", "hello should work with timeout set")
    
    print("✓ timeout_operations method works with normal timeout")
    
    -- Test timeout_operations with different timeout values
    print("Testing timeout_operations with different timeout values...")
    local timeout_result2 = client:timeout_operations(10) -- 10 second timeout
    assert(timeout_result2 == true, "timeout_operations should return true with 10 second timeout")
    
    local timeout_result3 = client:timeout_operations(1) -- 1 second timeout
    assert(timeout_result3 == true, "timeout_operations should return true with 1 second timeout")
    
    print("✓ timeout_operations method works with different timeout values")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test timeout_operations error handling
local function test_timeout_operations_error_handling()
    print("Testing timeout_operations error handling...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:3000")
    
    -- Test timeout_operations with invalid timeout values
    local invalid_result1 = client:timeout_operations(nil)
    assert(invalid_result1 == false, "timeout_operations should fail with nil timeout")
    
    local invalid_result2 = client:timeout_operations("invalid")
    assert(invalid_result2 == false, "timeout_operations should fail with string timeout")
    
    local invalid_result3 = client:timeout_operations(-1)
    assert(invalid_result3 == false, "timeout_operations should fail with negative timeout")
    
    local invalid_result4 = client:timeout_operations(0)
    assert(invalid_result4 == false, "timeout_operations should fail with zero timeout")
    
    print("✓ timeout_operations error handling works correctly")
    
    return true
end

-- Test timeout_operations parameter validation
local function test_timeout_operations_parameter_validation()
    print("Testing timeout_operations parameter validation...")
    
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
    assert(connect_result == true, "Should connect successfully")
    
    -- Test timeout_operations with valid timeout values
    local valid_result1 = client:timeout_operations(1)
    assert(valid_result1 == true, "timeout_operations should succeed with 1 second timeout")
    
    local valid_result2 = client:timeout_operations(5)
    assert(valid_result2 == true, "timeout_operations should succeed with 5 second timeout")
    
    local valid_result3 = client:timeout_operations(30)
    assert(valid_result3 == true, "timeout_operations should succeed with 30 second timeout")
    
    print("✓ timeout_operations parameter validation works correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test timeout_operations consistency
local function test_timeout_operations_consistency()
    print("Testing timeout_operations consistency...")
    
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
    assert(connect_result == true, "Should connect successfully")
    
    -- Test that multiple timeout_operations calls work consistently
    local result1 = client:timeout_operations(5)
    local result2 = client:timeout_operations(10)
    local result3 = client:timeout_operations(5)
    
    assert(result1 == true, "First timeout_operations call should succeed")
    assert(result2 == true, "Second timeout_operations call should succeed")
    assert(result3 == true, "Third timeout_operations call should succeed")
    
    -- Test that operations still work after multiple timeout changes
    local hello_result = client:hello()
    assert(hello_result == "world", "hello should work after multiple timeout changes")
    
    print("✓ timeout_operations consistency test passed")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test timeout_operations with slow operations
local function test_timeout_operations_with_slow_operations()
    print("Testing timeout_operations with slow operations...")
    
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
    assert(connect_result == true, "Should connect successfully")
    
    -- Set a short timeout
    local timeout_result = client:timeout_operations(2) -- 2 second timeout
    assert(timeout_result == true, "timeout_operations should succeed with 2 second timeout")
    
    -- Test that normal operations work within the timeout
    local hello_result = client:hello()
    assert(hello_result == "world", "hello should work within 2 second timeout")
    
    -- Test that list_models works within the timeout (this might be slower)
    local models_result = client:list_models()
    assert(models_result ~= nil, "list_models should work within 2 second timeout")
    
    print("✓ timeout_operations with slow operations works correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test timeout_operations getter
local function test_timeout_operations_getter()
    print("Testing timeout_operations getter...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:3000")
    
    -- Test that we can get the current timeout value
    local current_timeout = client:get_timeout()
    assert(type(current_timeout) == "number", "get_timeout should return a number")
    assert(current_timeout > 0, "get_timeout should return a positive number")
    
    -- Set a new timeout and verify it's returned
    local set_result = client:timeout_operations(15)
    assert(set_result == true, "timeout_operations should succeed")
    
    local new_timeout = client:get_timeout()
    assert(new_timeout == 15, "get_timeout should return the newly set timeout value")
    
    print("✓ timeout_operations getter works correctly")
    print("  Initial timeout: " .. tostring(current_timeout))
    print("  New timeout: " .. tostring(new_timeout))
    
    return true
end

-- Run the tests
local success, err = pcall(function()
    test_timeout_operations_method_exists()
    test_timeout_operations_method_implementation()
    test_timeout_operations_error_handling()
    test_timeout_operations_parameter_validation()
    test_timeout_operations_consistency()
    test_timeout_operations_with_slow_operations()
    test_timeout_operations_getter()
end)

if not success then
    print("Test failed: " .. tostring(err))
    os.exit(1)
end

print("✓ All rpc_standalone timeout_operations tests passed!") 