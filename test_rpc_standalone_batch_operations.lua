--[[
Test for implementing batch_operations method in rpc_standalone.lua - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Test that batch_operations method exists
local function test_batch_operations_method_exists()
    print("Testing that batch_operations method exists...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:3000")
    
    -- Test that batch_operations method exists
    assert(type(client.batch_operations) == "function", "batch_operations method should exist and be a function")
    
    print("✓ batch_operations method exists")
    return true
end

-- Test batch_operations method implementation
local function test_batch_operations_method_implementation()
    print("Testing batch_operations method implementation...")
    
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
    
    -- Test batch_operations with single operation first
    print("Testing batch_operations with single operation...")
    local single_operation = {
        {method = "hello", params = {}}
    }
    
    local single_result = client:batch_operations(single_operation)
    
    assert(single_result ~= nil, "batch_operations should return a result for single operation")
    assert(type(single_result) == "table", "batch_operations should return a table for single operation")
    assert(#single_result == 1, "batch_operations should return result for single operation")
    assert(single_result[1] == "world", "Single operation should return 'world'")
    
    print("✓ batch_operations method works with single operation")
    
    -- Test batch_operations with multiple operations
    print("Testing batch_operations with multiple operations...")
    local operations = {
        {method = "hello", params = {}},
        {method = "hello", params = {}} -- Use hello twice instead of list_models
    }
    
    local batch_result = client:batch_operations(operations)
    
    assert(batch_result ~= nil, "batch_operations should return a result")
    assert(type(batch_result) == "table", "batch_operations should return a table")
    assert(#batch_result == 2, "batch_operations should return results for all 2 operations")
    
    -- Check individual results
    assert(batch_result[1] == "world", "First operation (hello) should return 'world'")
    assert(batch_result[2] == "world", "Second operation (hello) should return 'world'")
    
    print("✓ batch_operations method works with multiple operations")
    print("  Hello result 1: " .. tostring(batch_result[1]))
    print("  Hello result 2: " .. tostring(batch_result[2]))
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test batch_operations error handling
local function test_batch_operations_error_handling()
    print("Testing batch_operations error handling...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:3000")
    
    -- Test batch_operations without connection
    local operations = {
        {method = "hello", params = {}}
    }
    
    local batch_result = client:batch_operations(operations)
    
    -- Should handle the error gracefully and return nil
    assert(batch_result == nil, "batch_operations should fail when not connected")
    
    print("✓ batch_operations error handling works correctly")
    
    return true
end

-- Test batch_operations parameter validation
local function test_batch_operations_parameter_validation()
    print("Testing batch_operations parameter validation...")
    
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
    
    -- Test batch_operations with nil operations
    local nil_result = client:batch_operations(nil)
    assert(nil_result == nil, "batch_operations should fail with nil operations")
    
    -- Test batch_operations with empty operations
    local empty_result = client:batch_operations({})
    assert(empty_result == nil, "batch_operations should fail with empty operations")
    
    -- Test batch_operations with invalid operation format
    local invalid_operations = {
        {method = "hello"}, -- Missing params
        {params = {}} -- Missing method
    }
    
    local invalid_result = client:batch_operations(invalid_operations)
    assert(invalid_result == nil, "batch_operations should fail with invalid operation format")
    
    print("✓ batch_operations parameter validation works correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test batch_operations with mixed success/failure
local function test_batch_operations_mixed_results()
    print("Testing batch_operations with mixed success/failure...")
    
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
    
    -- Test batch_operations with mixed valid/invalid operations
    local mixed_operations = {
        {method = "hello", params = {}}, -- Should succeed
        {method = "invalid_method", params = {}}, -- Should fail
        {method = "hello", params = {}} -- Should succeed
    }
    
    local mixed_result = client:batch_operations(mixed_operations)
    
    -- Should handle mixed results gracefully
    assert(mixed_result ~= nil, "batch_operations should return a result even with mixed operations")
    assert(type(mixed_result) == "table", "batch_operations should return a table with mixed operations")
    assert(#mixed_result == 3, "batch_operations should return results for all 3 operations")
    
    -- Check that valid operations succeeded
    assert(mixed_result[1] == "world", "First operation (hello) should succeed")
    assert(mixed_result[3] == "world", "Third operation (hello) should succeed")
    
    -- Check that invalid operation failed gracefully (could be nil or error response)
    -- The server might return an error response instead of nil
    assert(mixed_result[2] ~= "world", "Second operation (invalid_method) should not return 'world'")
    
    print("✓ batch_operations with mixed results works correctly")
    print("  Valid operation 1: " .. tostring(mixed_result[1]))
    print("  Invalid operation: " .. tostring(mixed_result[2]))
    print("  Valid operation 2: " .. tostring(mixed_result[3]))
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test batch_operations performance
local function test_batch_operations_performance()
    print("Testing batch_operations performance...")
    
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
    
    -- Create multiple operations
    local operations = {}
    for i = 1, 5 do
        table.insert(operations, {method = "hello", params = {}})
    end
    
    -- Test batch_operations performance
    local start_time = os.time()
    local batch_result = client:batch_operations(operations)
    local end_time = os.time()
    local batch_duration = end_time - start_time
    
    assert(batch_result ~= nil, "batch_operations should succeed")
    assert(#batch_result == 5, "batch_operations should return 5 results")
    assert(batch_duration <= 3, "batch_operations should complete within reasonable time")
    
    print("✓ batch_operations performance test passed: " .. #batch_result .. " operations in " .. batch_duration .. " seconds")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Run the tests
local success, err = pcall(function()
    test_batch_operations_method_exists()
    test_batch_operations_method_implementation()
    test_batch_operations_error_handling()
    test_batch_operations_parameter_validation()
    test_batch_operations_mixed_results()
    test_batch_operations_performance()
end)

if not success then
    print("Test failed: " .. tostring(err))
    os.exit(1)
end

print("✓ All rpc_standalone batch_operations tests passed!") 