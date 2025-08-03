--[[
Test for implementing connection_pooling method in rpc_standalone.lua - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Test that connection_pooling method exists
local function test_connection_pooling_method_exists()
    print("Testing that connection_pooling method exists...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:2346")
    
    -- Test that connection_pooling method exists
    assert(type(client.connection_pooling) == "function", "connection_pooling method should exist and be a function")
    
    print("✓ connection_pooling method exists")
    return true
end

-- Test connection_pooling method implementation
local function test_connection_pooling_method_implementation()
    print("Testing connection_pooling method implementation...")
    
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
    
    -- Connect to server
    local connect_result = client:connect()
    assert(connect_result == true, "Should connect successfully")
    
    -- Test connection_pooling with default settings
    print("Testing connection_pooling with default settings...")
    local pool_result = client:connection_pooling(3) -- 3 connections in pool
    
    assert(pool_result == true, "connection_pooling should return true when successful")
    
    -- Test that operations work with connection pooling enabled
    local hello_result = client:hello()
    assert(hello_result == "world", "hello should work with connection pooling enabled")
    
    print("✓ connection_pooling method works with default settings")
    
    -- Test connection_pooling with different settings
    print("Testing connection_pooling with different settings...")
    local pool_result2 = client:connection_pooling(5) -- 5 connections in pool
    assert(pool_result2 == true, "connection_pooling should return true with 5 connections")
    
    local pool_result3 = client:connection_pooling(1) -- 1 connection in pool
    assert(pool_result3 == true, "connection_pooling should return true with 1 connection")
    
    print("✓ connection_pooling method works with different settings")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test connection_pooling error handling
local function test_connection_pooling_error_handling()
    print("Testing connection_pooling error handling...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:2346")
    
    -- Test connection_pooling with invalid parameters
    local invalid_result1 = client:connection_pooling(nil)
    assert(invalid_result1 == false, "connection_pooling should fail with nil pool_size")
    
    local invalid_result2 = client:connection_pooling("invalid")
    assert(invalid_result2 == false, "connection_pooling should fail with string pool_size")
    
    local invalid_result3 = client:connection_pooling(-1)
    assert(invalid_result3 == false, "connection_pooling should fail with negative pool_size")
    
    local invalid_result4 = client:connection_pooling(0)
    assert(invalid_result4 == false, "connection_pooling should fail with zero pool_size")
    
    print("✓ connection_pooling error handling works correctly")
    
    return true
end

-- Test connection_pooling parameter validation
local function test_connection_pooling_parameter_validation()
    print("Testing connection_pooling parameter validation...")
    
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
    
    -- Connect to server
    local connect_result = client:connect()
    assert(connect_result == true, "Should connect successfully")
    
    -- Test connection_pooling with valid parameters
    local valid_result1 = client:connection_pooling(1)
    assert(valid_result1 == true, "connection_pooling should succeed with 1 connection")
    
    local valid_result2 = client:connection_pooling(3)
    assert(valid_result2 == true, "connection_pooling should succeed with 3 connections")
    
    local valid_result3 = client:connection_pooling(10)
    assert(valid_result3 == true, "connection_pooling should succeed with 10 connections")
    
    print("✓ connection_pooling parameter validation works correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test connection_pooling consistency
local function test_connection_pooling_consistency()
    print("Testing connection_pooling consistency...")
    
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
    
    -- Connect to server
    local connect_result = client:connect()
    assert(connect_result == true, "Should connect successfully")
    
    -- Test that multiple connection_pooling calls work consistently
    local result1 = client:connection_pooling(2)
    local result2 = client:connection_pooling(4)
    local result3 = client:connection_pooling(1)
    
    assert(result1 == true, "First connection_pooling call should succeed")
    assert(result2 == true, "Second connection_pooling call should succeed")
    assert(result3 == true, "Third connection_pooling call should succeed")
    
    -- Test that operations still work after multiple pool changes
    local hello_result = client:hello()
    assert(hello_result == "world", "hello should work after multiple pool changes")
    
    print("✓ connection_pooling consistency test passed")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test connection_pooling with load balancing
local function test_connection_pooling_load_balancing()
    print("Testing connection_pooling load balancing...")
    
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
    
    -- Connect to server
    local connect_result = client:connect()
    assert(connect_result == true, "Should connect successfully")
    
    -- Set connection pooling
    local pool_result = client:connection_pooling(3) -- 3 connections in pool
    assert(pool_result == true, "connection_pooling should succeed")
    
    -- Test that multiple operations work with load balancing
    local results = {}
    for i = 1, 5 do
        results[i] = client:hello()
    end
    
    -- All operations should succeed
    for i = 1, 5 do
        assert(results[i] == "world", "Operation " .. i .. " should succeed with load balancing")
    end
    
    print("✓ connection_pooling load balancing works correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test connection_pooling getter
local function test_connection_pooling_getter()
    print("Testing connection_pooling getter...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:2346")
    
    -- Test that we can get the current connection pool configuration
    local current_pool = client:get_connection_pool_config()
    assert(type(current_pool) == "table", "get_connection_pool_config should return a table")
    assert(type(current_pool.pool_size) == "number", "pool_size should be a number")
    assert(current_pool.pool_size >= 1, "pool_size should be at least 1")
    
    -- Set a new connection pool configuration and verify it's returned
    local set_result = client:connection_pooling(5)
    assert(set_result == true, "connection_pooling should succeed")
    
    local new_pool = client:get_connection_pool_config()
    assert(new_pool.pool_size == 5, "get_connection_pool_config should return the newly set pool_size")
    
    print("✓ connection_pooling getter works correctly")
    print("  Initial pool_size: " .. tostring(current_pool.pool_size))
    print("  New pool_size: " .. tostring(new_pool.pool_size))
    
    return true
end

-- Test connection_pooling with batch operations
local function test_connection_pooling_with_batch_operations()
    print("Testing connection_pooling with batch operations...")
    
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
    
    -- Connect to server
    local connect_result = client:connect()
    assert(connect_result == true, "Should connect successfully")
    
    -- Set connection pooling
    local pool_result = client:connection_pooling(3) -- 3 connections in pool
    assert(pool_result == true, "connection_pooling should succeed")
    
    -- Test batch operations with connection pooling enabled
    local operations = {
        {method = "hello", params = {}},
        {method = "hello", params = {}},
        {method = "hello", params = {}}
    }
    
    local batch_result = client:batch_operations(operations)
    assert(batch_result ~= nil, "batch_operations should succeed with connection pooling enabled")
    assert(#batch_result == 3, "batch_operations should return 3 results")
    assert(batch_result[1] == "world", "First batch operation should succeed")
    assert(batch_result[2] == "world", "Second batch operation should succeed")
    assert(batch_result[3] == "world", "Third batch operation should succeed")
    
    print("✓ connection_pooling with batch operations works correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test connection_pooling with retry operations
local function test_connection_pooling_with_retry_operations()
    print("Testing connection_pooling with retry operations...")
    
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
    
    -- Connect to server
    local connect_result = client:connect()
    assert(connect_result == true, "Should connect successfully")
    
    -- Set both connection pooling and retry configuration
    local pool_result = client:connection_pooling(3) -- 3 connections in pool
    assert(pool_result == true, "connection_pooling should succeed")
    
    local retry_result = client:retry_operations(2, 0.1) -- 2 retries, 0.1s delay
    assert(retry_result == true, "retry_operations should succeed")
    
    -- Test that operations work with both connection pooling and retry enabled
    local hello_result = client:hello()
    assert(hello_result == "world", "hello should work with both connection pooling and retry enabled")
    
    -- Test batch operations with both features enabled
    local operations = {
        {method = "hello", params = {}},
        {method = "hello", params = {}}
    }
    
    local batch_result = client:batch_operations(operations)
    assert(batch_result ~= nil, "batch_operations should succeed with both features enabled")
    assert(#batch_result == 2, "batch_operations should return 2 results")
    assert(batch_result[1] == "world", "First batch operation should succeed")
    assert(batch_result[2] == "world", "Second batch operation should succeed")
    
    print("✓ connection_pooling with retry operations works correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Run the tests
local success, err = pcall(function()
    test_connection_pooling_method_exists()
    test_connection_pooling_method_implementation()
    test_connection_pooling_error_handling()
    test_connection_pooling_parameter_validation()
    test_connection_pooling_consistency()
    test_connection_pooling_load_balancing()
    test_connection_pooling_getter()
    test_connection_pooling_with_batch_operations()
    test_connection_pooling_with_retry_operations()
end)

if not success then
    print("Test failed: " .. tostring(err))
    os.exit(1)
end

print("✓ All rpc_standalone connection_pooling tests passed!") 