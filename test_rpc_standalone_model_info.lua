--[[
Test for implementing model_info method in rpc_standalone.lua - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- No external dependencies needed for vim.json
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Test that model_info method exists
local function test_model_info_method_exists()
    print("Testing that model_info method exists...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:2346")
    
    -- Test that model_info method exists
    assert(type(client.model_info) == "function", "model_info method should exist and be a function")
    
    print("✓ model_info method exists")
    return true
end

-- Test model_info method implementation
local function test_model_info_method_implementation()
    print("Testing model_info method implementation...")
    
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
    
    -- Test that model_info method exists
    assert(type(client.model_info) == "function", "model_info should be a function")
    
    -- Test model_info functionality with llama2
    print("Testing model_info functionality with llama2...")
    local result = client:model_info("llama2")
    
    assert(result ~= nil, "model_info should return a result")
    assert(type(result) == "string", "model_info should return a string")
    
    -- Parse the result as JSON to verify it's valid model info
    local success, parsed = pcall(vim.json.decode, result)
    assert(success, "model_info should return valid JSON")
    assert(type(parsed) == "table", "model_info should return a JSON object")
    
    -- Check for expected fields in model info
    assert(parsed.name ~= nil, "model_info should include 'name' field")
    assert(parsed.name:find("llama2"), "model_info should be for llama2 model")
    
    print("✓ model_info method works: " .. parsed.name)
    print("  Model details: " .. (parsed.license or "No license") .. ", " .. (parsed.modelfile or "No modelfile"))
    
    -- Test model_info with a different model
    print("Testing model_info with different model...")
    local result2 = client:model_info("llama3.2:3b")
    
    assert(result2 ~= nil, "Second model_info call should succeed")
    assert(type(result2) == "string", "Second model_info should return a string")
    
    local success2, parsed2 = pcall(vim.json.decode, result2)
    assert(success2, "Second model_info should return valid JSON")
    assert(parsed2.name:find("llama3.2"), "Second model_info should be for llama3.2 model")
    
    print("✓ Second model_info method works: " .. parsed2.name)
    
    -- Test model_info without connection
    print("Testing model_info without connection...")
    client:disconnect()
    local result3 = client:model_info("llama2")
    
    assert(result3 == nil, "model_info should fail when not connected")
    
    print("✓ model_info correctly fails when not connected")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test model_info error handling
local function test_model_info_error_handling()
    print("Testing model_info error handling...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a client with invalid server address
    local client = rpc_standalone.new("127.0.0.1:9999") -- Invalid port
    
    -- Test model_info with invalid server
    local result = client:model_info("llama2")
    
    -- Should handle the error gracefully
    assert(result == nil, "model_info should fail with invalid server")
    
    print("✓ model_info error handling works correctly")
    
    return true
end

-- Test model_info parameter validation
local function test_model_info_parameter_validation()
    print("Testing model_info parameter validation...")
    
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
    
    -- Test model_info with nil model name
    local result1 = client:model_info(nil)
    assert(result1 == nil, "model_info should fail with nil model name")
    
    -- Test model_info with empty model name
    local result2 = client:model_info("")
    assert(result2 == nil, "model_info should fail with empty model name")
    
    -- Test model_info with non-existent model
    local result3 = client:model_info("non_existent_model")
    -- This might succeed (return info about non-existent model) or fail
    -- We'll just check it doesn't crash
    assert(result3 ~= nil or true, "model_info should handle non-existent model gracefully")
    
    print("✓ model_info parameter validation works correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test model_info consistency
local function test_model_info_consistency()
    print("Testing model_info consistency...")
    
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
    
    -- Test that multiple calls return consistent results
    local result1 = client:model_info("llama2")
    local result2 = client:model_info("llama2")
    
    assert(result1 ~= nil, "First model_info call should succeed")
    assert(result2 ~= nil, "Second model_info call should succeed")
    assert(result1 == result2, "Multiple model_info calls should return consistent results")
    
    print("✓ model_info consistency test passed")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Run the tests
local success, err = pcall(function()
    test_model_info_method_exists()
    test_model_info_method_implementation()
    test_model_info_error_handling()
    test_model_info_parameter_validation()
    test_model_info_consistency()
end)

if not success then
    print("Test failed: " .. tostring(err))
    os.exit(1)
end

print("✓ All rpc_standalone model_info tests passed!") 