--[[
Test for implementing logging method in rpc_standalone.lua - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Test that logging method exists
local function test_logging_method_exists()
    print("Testing that logging method exists...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:3000")
    
    -- Test that logging method exists
    assert(type(client.logging) == "function", "logging method should exist and be a function")
    
    print("✓ logging method exists")
    return true
end

-- Test logging method implementation
local function test_logging_method_implementation()
    print("Testing logging method implementation...")
    
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
    
    -- Test logging with default settings
    print("Testing logging with default settings...")
    local log_result = client:logging(true) -- Enable logging
    
    assert(log_result == true, "logging should return true when successful")
    
    -- Test that operations work with logging enabled
    local hello_result = client:hello()
    assert(hello_result == "world", "hello should work with logging enabled")
    
    print("✓ logging method works with default settings")
    
    -- Test logging with different settings
    print("Testing logging with different settings...")
    local log_result2 = client:logging(false) -- Disable logging
    assert(log_result2 == true, "logging should return true when disabling")
    
    local log_result3 = client:logging(true, "debug") -- Enable with debug level
    assert(log_result3 == true, "logging should return true with debug level")
    
    print("✓ logging method works with different settings")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test logging error handling
local function test_logging_error_handling()
    print("Testing logging error handling...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:3000")
    
    -- Test logging with invalid parameters
    local invalid_result1 = client:logging(nil)
    assert(invalid_result1 == false, "logging should fail with nil enabled")
    
    local invalid_result2 = client:logging("invalid")
    assert(invalid_result2 == false, "logging should fail with string enabled")
    
    local invalid_result3 = client:logging(true, "invalid_level")
    assert(invalid_result3 == false, "logging should fail with invalid log level")
    
    local invalid_result4 = client:logging(true, 123)
    assert(invalid_result4 == false, "logging should fail with number log level")
    
    print("✓ logging error handling works correctly")
    
    return true
end

-- Test logging parameter validation
local function test_logging_parameter_validation()
    print("Testing logging parameter validation...")
    
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
    
    -- Test logging with valid parameters
    local valid_result1 = client:logging(true)
    assert(valid_result1 == true, "logging should succeed with enabled=true")
    
    local valid_result2 = client:logging(false)
    assert(valid_result2 == true, "logging should succeed with enabled=false")
    
    local valid_result3 = client:logging(true, "info")
    assert(valid_result3 == true, "logging should succeed with info level")
    
    local valid_result4 = client:logging(true, "debug")
    assert(valid_result4 == true, "logging should succeed with debug level")
    
    local valid_result5 = client:logging(true, "warn")
    assert(valid_result5 == true, "logging should succeed with warn level")
    
    local valid_result6 = client:logging(true, "error")
    assert(valid_result6 == true, "logging should succeed with error level")
    
    print("✓ logging parameter validation works correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test logging consistency
local function test_logging_consistency()
    print("Testing logging consistency...")
    
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
    
    -- Test that multiple logging calls work consistently
    local result1 = client:logging(true, "info")
    local result2 = client:logging(false)
    local result3 = client:logging(true, "debug")
    
    assert(result1 == true, "First logging call should succeed")
    assert(result2 == true, "Second logging call should succeed")
    assert(result3 == true, "Third logging call should succeed")
    
    -- Test that operations still work after multiple logging changes
    local hello_result = client:hello()
    assert(hello_result == "world", "hello should work after multiple logging changes")
    
    print("✓ logging consistency test passed")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test logging with different log levels
local function test_logging_with_different_levels()
    print("Testing logging with different log levels...")
    
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
    
    -- Test different log levels
    local levels = {"debug", "info", "warn", "error"}
    for _, level in ipairs(levels) do
        local log_result = client:logging(true, level)
        assert(log_result == true, "logging should succeed with level: " .. level)
        
        -- Test that operations work with this log level
        local hello_result = client:hello()
        assert(hello_result == "world", "hello should work with log level: " .. level)
    end
    
    print("✓ logging with different log levels works correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test logging getter
local function test_logging_getter()
    print("Testing logging getter...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:3000")
    
    -- Test that we can get the current logging configuration
    local current_log = client:get_logging_config()
    assert(type(current_log) == "table", "get_logging_config should return a table")
    assert(type(current_log.enabled) == "boolean", "enabled should be a boolean")
    assert(type(current_log.level) == "string", "level should be a string")
    
    -- Set a new logging configuration and verify it's returned
    local set_result = client:logging(true, "debug")
    assert(set_result == true, "logging should succeed")
    
    local new_log = client:get_logging_config()
    assert(new_log.enabled == true, "get_logging_config should return the newly set enabled")
    assert(new_log.level == "debug", "get_logging_config should return the newly set level")
    
    print("✓ logging getter works correctly")
    print("  Initial enabled: " .. tostring(current_log.enabled))
    print("  Initial level: " .. tostring(current_log.level))
    print("  New enabled: " .. tostring(new_log.enabled))
    print("  New level: " .. tostring(new_log.level))
    
    return true
end

-- Test logging with batch operations
local function test_logging_with_batch_operations()
    print("Testing logging with batch operations...")
    
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
    
    -- Set logging
    local log_result = client:logging(true, "info") -- Enable logging with info level
    assert(log_result == true, "logging should succeed")
    
    -- Test batch operations with logging enabled
    local operations = {
        {method = "hello", params = {}},
        {method = "hello", params = {}}
    }
    
    local batch_result = client:batch_operations(operations)
    assert(batch_result ~= nil, "batch_operations should succeed with logging enabled")
    assert(#batch_result == 2, "batch_operations should return 2 results")
    assert(batch_result[1] == "world", "First batch operation should succeed")
    assert(batch_result[2] == "world", "Second batch operation should succeed")
    
    print("✓ logging with batch operations works correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test logging with retry operations
local function test_logging_with_retry_operations()
    print("Testing logging with retry operations...")
    
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
    
    -- Set both logging and retry configuration
    local log_result = client:logging(true, "debug") -- Enable logging with debug level
    assert(log_result == true, "logging should succeed")
    
    local retry_result = client:retry_operations(2, 0.1) -- 2 retries, 0.1s delay
    assert(retry_result == true, "retry_operations should succeed")
    
    -- Test that operations work with both logging and retry enabled
    local hello_result = client:hello()
    assert(hello_result == "world", "hello should work with both logging and retry enabled")
    
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
    
    print("✓ logging with retry operations works correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test logging with connection pooling
local function test_logging_with_connection_pooling()
    print("Testing logging with connection pooling...")
    
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
    
    -- Set both logging and connection pooling configuration
    local log_result = client:logging(true, "info") -- Enable logging with info level
    assert(log_result == true, "logging should succeed")
    
    local pool_result = client:connection_pooling(3) -- 3 connections in pool
    assert(pool_result == true, "connection_pooling should succeed")
    
    -- Test that operations work with both logging and connection pooling enabled
    local hello_result = client:hello()
    assert(hello_result == "world", "hello should work with both logging and connection pooling enabled")
    
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
    
    print("✓ logging with connection pooling works correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Run the tests
local success, err = pcall(function()
    test_logging_method_exists()
    test_logging_method_implementation()
    test_logging_error_handling()
    test_logging_parameter_validation()
    test_logging_consistency()
    test_logging_with_different_levels()
    test_logging_getter()
    test_logging_with_batch_operations()
    test_logging_with_retry_operations()
    test_logging_with_connection_pooling()
end)

if not success then
    print("Test failed: " .. tostring(err))
    os.exit(1)
end

print("✓ All rpc_standalone logging tests passed!") 