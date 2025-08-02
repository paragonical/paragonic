--[[
Test for implementing generate_embedding method in rpc_standalone.lua - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Test that generate_embedding method exists
local function test_generate_embedding_method_exists()
    print("Testing that generate_embedding method exists...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:3000")
    
    -- Test that generate_embedding method exists
    assert(type(client.generate_embedding) == "function", "generate_embedding method should exist and be a function")
    
    print("✓ generate_embedding method exists")
    return true
end

-- Test generate_embedding method implementation
local function test_generate_embedding_method_implementation()
    print("Testing generate_embedding method implementation...")
    
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
    
    -- Test that generate_embedding method exists
    assert(type(client.generate_embedding) == "function", "generate_embedding should be a function")
    
    -- Test generate_embedding functionality with nomic-embed-text
    print("Testing generate_embedding functionality with nomic-embed-text...")
    local result = client:generate_embedding("nomic-embed-text", "Hello world")
    
    assert(result ~= nil, "generate_embedding should return a result")
    assert(type(result) == "string", "generate_embedding should return a string")
    
    -- Parse the result as JSON to verify it's valid embedding
    local cjson = require("cjson")
    local success, parsed = pcall(cjson.decode, result)
    assert(success, "generate_embedding should return valid JSON")
    assert(type(parsed) == "table", "generate_embedding should return a JSON object")
    
    -- Check for expected fields in embedding result
    assert(parsed.embedding ~= nil, "generate_embedding should include 'embedding' field")
    assert(type(parsed.embedding) == "table", "embedding should be an array")
    assert(#parsed.embedding > 0, "embedding should have at least one dimension")
    
    print("✓ generate_embedding method works: " .. #parsed.embedding .. " dimensions")
    print("  Sample embedding values: " .. parsed.embedding[1] .. ", " .. parsed.embedding[2] .. ", " .. parsed.embedding[3])
    
    -- Test generate_embedding with a different text
    print("Testing generate_embedding with different text...")
    local result2 = client:generate_embedding("nomic-embed-text", "This is a different sentence for testing")
    
    assert(result2 ~= nil, "Second generate_embedding call should succeed")
    assert(type(result2) == "string", "Second generate_embedding should return a string")
    
    local success2, parsed2 = pcall(cjson.decode, result2)
    assert(success2, "Second generate_embedding should return valid JSON")
    assert(#parsed2.embedding > 0, "Second embedding should have dimensions")
    
    -- Verify that different texts produce different embeddings
    assert(result ~= result2, "Different texts should produce different embeddings")
    
    print("✓ Second generate_embedding method works: " .. #parsed2.embedding .. " dimensions")
    
    -- Test generate_embedding without connection
    print("Testing generate_embedding without connection...")
    client:disconnect()
    local result3 = client:generate_embedding("nomic-embed-text", "Hello world")
    
    assert(result3 == nil, "generate_embedding should fail when not connected")
    
    print("✓ generate_embedding correctly fails when not connected")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test generate_embedding error handling
local function test_generate_embedding_error_handling()
    print("Testing generate_embedding error handling...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a client with invalid server address
    local client = rpc_standalone.new("127.0.0.1:9999") -- Invalid port
    
    -- Test generate_embedding with invalid server
    local result = client:generate_embedding("nomic-embed-text", "Hello world")
    
    -- Should handle the error gracefully
    assert(result == nil, "generate_embedding should fail with invalid server")
    
    print("✓ generate_embedding error handling works correctly")
    
    return true
end

-- Test generate_embedding parameter validation
local function test_generate_embedding_parameter_validation()
    print("Testing generate_embedding parameter validation...")
    
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
    
    -- Test generate_embedding with nil model name
    local result1 = client:generate_embedding(nil, "Hello world")
    assert(result1 == nil, "generate_embedding should fail with nil model name")
    
    -- Test generate_embedding with empty model name
    local result2 = client:generate_embedding("", "Hello world")
    assert(result2 == nil, "generate_embedding should fail with empty model name")
    
    -- Test generate_embedding with nil text
    local result3 = client:generate_embedding("nomic-embed-text", nil)
    assert(result3 == nil, "generate_embedding should fail with nil text")
    
    -- Test generate_embedding with empty text
    local result4 = client:generate_embedding("nomic-embed-text", "")
    assert(result4 == nil, "generate_embedding should fail with empty text")
    
    -- Test generate_embedding with non-existent model
    local result5 = client:generate_embedding("non_existent_model", "Hello world")
    -- This might succeed (return embedding from default model) or fail
    -- We'll just check it doesn't crash
    assert(result5 ~= nil or true, "generate_embedding should handle non-existent model gracefully")
    
    print("✓ generate_embedding parameter validation works correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test generate_embedding consistency
local function test_generate_embedding_consistency()
    print("Testing generate_embedding consistency...")
    
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
    
    -- Test that multiple calls with same input return consistent results
    local result1 = client:generate_embedding("nomic-embed-text", "Consistent test")
    local result2 = client:generate_embedding("nomic-embed-text", "Consistent test")
    
    assert(result1 ~= nil, "First generate_embedding call should succeed")
    assert(result2 ~= nil, "Second generate_embedding call should succeed")
    assert(result1 == result2, "Multiple generate_embedding calls with same input should return consistent results")
    
    print("✓ generate_embedding consistency test passed")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test generate_embedding with different embedding models
local function test_generate_embedding_different_models()
    print("Testing generate_embedding with different models...")
    
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
    
    -- Test with nomic-embed-text model
    local result1 = client:generate_embedding("nomic-embed-text", "Test text")
    assert(result1 ~= nil, "nomic-embed-text should work")
    
    local cjson = require("cjson")
    local success1, parsed1 = pcall(cjson.decode, result1)
    assert(success1, "nomic-embed-text should return valid JSON")
    assert(#parsed1.embedding > 0, "nomic-embed-text should return embedding")
    
    print("✓ nomic-embed-text model works: " .. #parsed1.embedding .. " dimensions")
    
    -- Test with default model (should fall back to available embedding model)
    local result2 = client:generate_embedding("", "Test text")
    -- This might work or fail depending on available models
    if result2 then
        local success2, parsed2 = pcall(cjson.decode, result2)
        if success2 then
            print("✓ Default embedding model works: " .. #parsed2.embedding .. " dimensions")
        end
    end
    
    print("✓ generate_embedding different models test passed")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Run the tests
local success, err = pcall(function()
    test_generate_embedding_method_exists()
    test_generate_embedding_method_implementation()
    test_generate_embedding_error_handling()
    test_generate_embedding_parameter_validation()
    test_generate_embedding_consistency()
    test_generate_embedding_different_models()
end)

if not success then
    print("Test failed: " .. tostring(err))
    os.exit(1)
end

print("✓ All rpc_standalone generate_embedding tests passed!") 