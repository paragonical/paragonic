--[[
Test for implementing list_models method in rpc_standalone.lua - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Test that list_models method exists
local function test_list_models_method_exists()
    print("Testing that list_models method exists...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:2346")
    
    -- Test that list_models method exists
    assert(type(client.list_models) == "function", "list_models method should exist and be a function")
    
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
    
    -- Test that list_models method exists
    assert(type(client.list_models) == "function", "list_models should be a function")
    
    -- Test list_models functionality
    print("Testing list_models functionality...")
    local result = client:list_models()
    
    assert(result ~= nil, "list_models should return a result")
    assert(type(result) == "string", "list_models should return a string")
    
    -- Parse the result as JSON to verify it's a valid model list
    local cjson = require("cjson")
    local success, parsed = pcall(cjson.decode, result)
    assert(success, "list_models should return valid JSON")
    assert(type(parsed) == "table", "list_models should return a JSON array")
    assert(#parsed > 0, "list_models should return at least one model")
    
    -- Check if llama2 is in the list (we know it should be available)
    local has_llama2 = false
    for _, model in ipairs(parsed) do
        if model:find("llama2") then
            has_llama2 = true
            break
        end
    end
    assert(has_llama2, "list_models should include llama2 model")
    
    print("✓ list_models method works: found " .. #parsed .. " models")
    print("  Sample models: " .. table.concat({parsed[1], parsed[2], parsed[3]}, ", "))
    
    -- Test list_models without connection
    print("Testing list_models without connection...")
    client:disconnect()
    local result2 = client:list_models()
    
    assert(result2 == nil, "list_models should fail when not connected")
    
    print("✓ list_models correctly fails when not connected")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
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
    local result1 = client:list_models()
    local result2 = client:list_models()
    
    assert(result1 ~= nil, "First list_models call should succeed")
    assert(result2 ~= nil, "Second list_models call should succeed")
    assert(result1 == result2, "Multiple list_models calls should return consistent results")
    
    print("✓ list_models consistency test passed")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
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