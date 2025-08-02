--[[
Test for implementing retry_operations method in rpc_standalone.lua - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Test that retry_operations method exists
local function test_retry_operations_method_exists()
    print("Testing that retry_operations method exists...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:3000")
    
    -- Test that retry_operations method exists
    assert(type(client.retry_operations) == "function", "retry_operations method should exist and be a function")
    
    print("✓ retry_operations method exists")
    return true
end

-- Test retry_operations method implementation
local function test_retry_operations_method_implementation()
    print("Testing retry_operations method implementation...")
    
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
    
    -- Test retry_operations with default settings
    print("Testing retry_operations with default settings...")
    local retry_result = client:retry_operations(3, 1) -- 3 retries, 1 second delay
    
    assert(retry_result == true, "retry_operations should return true when successful")
    
    -- Test that operations work with retry enabled
    local hello_result = client:hello()
    assert(hello_result == "world", "hello should work with retry enabled")
    
    print("✓ retry_operations method works with default settings")
    
    -- Test retry_operations with different settings
    print("Testing retry_operations with different settings...")
    local retry_result2 = client:retry_operations(5, 0.5) -- 5 retries, 0.5 second delay
    assert(retry_result2 == true, "retry_operations should return true with 5 retries")
    
    local retry_result3 = client:retry_operations(1, 2) -- 1 retry, 2 second delay
    assert(retry_result3 == true, "retry_operations should return true with 1 retry")
    
    print("✓ retry_operations method works with different settings")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test retry_operations error handling
local function test_retry_operations_error_handling()
    print("Testing retry_operations error handling...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:3000")
    
    -- Test retry_operations with invalid parameters
    local invalid_result1 = client:retry_operations(nil, 1)
    assert(invalid_result1 == false, "retry_operations should fail with nil max_retries")
    
    local invalid_result2 = client:retry_operations(3, nil)
    assert(invalid_result2 == false, "retry_operations should fail with nil delay")
    
    local invalid_result3 = client:retry_operations("invalid", 1)
    assert(invalid_result3 == false, "retry_operations should fail with string max_retries")
    
    local invalid_result4 = client:retry_operations(3, "invalid")
    assert(invalid_result4 == false, "retry_operations should fail with string delay")
    
    local invalid_result5 = client:retry_operations(-1, 1)
    assert(invalid_result5 == false, "retry_operations should fail with negative max_retries")
    
    local invalid_result6 = client:retry_operations(3, -1)
    assert(invalid_result6 == false, "retry_operations should fail with negative delay")
    
    print("✓ retry_operations error handling works correctly")
    
    return true
end

-- Test retry_operations parameter validation
local function test_retry_operations_parameter_validation()
    print("Testing retry_operations parameter validation...")
    
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
    
    -- Test retry_operations with valid parameters
    local valid_result1 = client:retry_operations(1, 0.1)
    assert(valid_result1 == true, "retry_operations should succeed with 1 retry, 0.1s delay")
    
    local valid_result2 = client:retry_operations(3, 0.5)
    assert(valid_result2 == true, "retry_operations should succeed with 3 retries, 0.5s delay")
    
    local valid_result3 = client:retry_operations(10, 1)
    assert(valid_result3 == true, "retry_operations should succeed with 10 retries, 1s delay")
    
    print("✓ retry_operations parameter validation works correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test retry_operations consistency
local function test_retry_operations_consistency()
    print("Testing retry_operations consistency...")
    
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
    
    -- Test that multiple retry_operations calls work consistently
    local result1 = client:retry_operations(2, 0.1)
    local result2 = client:retry_operations(3, 0.2)
    local result3 = client:retry_operations(1, 0.1)
    
    assert(result1 == true, "First retry_operations call should succeed")
    assert(result2 == true, "Second retry_operations call should succeed")
    assert(result3 == true, "Third retry_operations call should succeed")
    
    -- Test that operations still work after multiple retry changes
    local hello_result = client:hello()
    assert(hello_result == "world", "hello should work after multiple retry changes")
    
    print("✓ retry_operations consistency test passed")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test retry_operations with failed operations
local function test_retry_operations_with_failed_operations()
    print("Testing retry_operations with failed operations...")
    
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
    
    -- Set retry configuration
    local retry_result = client:retry_operations(2, 0.1) -- 2 retries, 0.1s delay
    assert(retry_result == true, "retry_operations should succeed")
    
    -- Test that normal operations work with retry enabled
    local hello_result = client:hello()
    assert(hello_result == "world", "hello should work with retry enabled")
    
    -- Test that invalid operations fail but don't crash
    local invalid_result = client:model_info("") -- Empty model name should fail
    assert(invalid_result == nil, "invalid operation should fail gracefully")
    
    print("✓ retry_operations with failed operations works correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test retry_operations getter
local function test_retry_operations_getter()
    print("Testing retry_operations getter...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:3000")
    
    -- Test that we can get the current retry configuration
    local current_retry = client:get_retry_config()
    assert(type(current_retry) == "table", "get_retry_config should return a table")
    assert(type(current_retry.max_retries) == "number", "max_retries should be a number")
    assert(type(current_retry.delay) == "number", "delay should be a number")
    assert(current_retry.max_retries >= 0, "max_retries should be non-negative")
    assert(current_retry.delay >= 0, "delay should be non-negative")
    
    -- Set a new retry configuration and verify it's returned
    local set_result = client:retry_operations(5, 1.5)
    assert(set_result == true, "retry_operations should succeed")
    
    local new_retry = client:get_retry_config()
    assert(new_retry.max_retries == 5, "get_retry_config should return the newly set max_retries")
    assert(new_retry.delay == 1.5, "get_retry_config should return the newly set delay")
    
    print("✓ retry_operations getter works correctly")
    print("  Initial max_retries: " .. tostring(current_retry.max_retries))
    print("  Initial delay: " .. tostring(current_retry.delay))
    print("  New max_retries: " .. tostring(new_retry.max_retries))
    print("  New delay: " .. tostring(new_retry.delay))
    
    return true
end

-- Test retry_operations with batch operations
local function test_retry_operations_with_batch_operations()
    print("Testing retry_operations with batch operations...")
    
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
    
    -- Set retry configuration
    local retry_result = client:retry_operations(2, 0.1) -- 2 retries, 0.1s delay
    assert(retry_result == true, "retry_operations should succeed")
    
    -- Test batch operations with retry enabled
    local operations = {
        {method = "hello", params = {}},
        {method = "hello", params = {}}
    }
    
    local batch_result = client:batch_operations(operations)
    assert(batch_result ~= nil, "batch_operations should succeed with retry enabled")
    assert(#batch_result == 2, "batch_operations should return 2 results")
    assert(batch_result[1] == "world", "First batch operation should succeed")
    assert(batch_result[2] == "world", "Second batch operation should succeed")
    
    print("✓ retry_operations with batch operations works correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Run the tests
local success, err = pcall(function()
    test_retry_operations_method_exists()
    test_retry_operations_method_implementation()
    test_retry_operations_error_handling()
    test_retry_operations_parameter_validation()
    test_retry_operations_consistency()
    test_retry_operations_with_failed_operations()
    test_retry_operations_getter()
    test_retry_operations_with_batch_operations()
end)

if not success then
    print("Test failed: " .. tostring(err))
    os.exit(1)
end

print("✓ All rpc_standalone retry_operations tests passed!") 