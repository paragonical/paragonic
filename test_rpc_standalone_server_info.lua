--[[
Test for implementing get_server_info method in rpc_standalone.lua - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Test that get_server_info method exists
local function test_get_server_info_method_exists()
    print("Testing that get_server_info method exists...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a new RPC client
    local client = rpc_standalone.new("127.0.0.1:3000")
    
    -- Test that get_server_info method exists
    assert(type(client.get_server_info) == "function", "get_server_info method should exist and be a function")
    
    print("✓ get_server_info method exists")
    return true
end

-- Test get_server_info method implementation
local function test_get_server_info_method_implementation()
    print("Testing get_server_info method implementation...")
    
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
    
    -- Test get_server_info without connection (should still work)
    print("Testing get_server_info without connection...")
    local server_info = client:get_server_info()
    
    assert(server_info ~= nil, "get_server_info should return a result")
    assert(type(server_info) == "table", "get_server_info should return a table")
    assert(server_info.name ~= nil, "server_info should have a name field")
    assert(server_info.version ~= nil, "server_info should have a version field")
    assert(server_info.status ~= nil, "server_info should have a status field")
    
    print("✓ get_server_info method works without connection")
    print("  Server name: " .. tostring(server_info.name))
    print("  Server version: " .. tostring(server_info.version))
    print("  Server status: " .. tostring(server_info.status))
    
    -- Connect to server
    local connect_result = client:connect()
    assert(connect_result == true, "Should connect successfully")
    
    -- Test get_server_info with connection
    print("Testing get_server_info with connection...")
    local server_info2 = client:get_server_info()
    
    assert(server_info2 ~= nil, "get_server_info should return a result when connected")
    assert(type(server_info2) == "table", "get_server_info should return a table when connected")
    assert(server_info2.name ~= nil, "server_info should have a name field when connected")
    assert(server_info2.version ~= nil, "server_info should have a version field when connected")
    assert(server_info2.status ~= nil, "server_info should have a status field when connected")
    
    print("✓ get_server_info method works with connection")
    print("  Server name: " .. tostring(server_info2.name))
    print("  Server version: " .. tostring(server_info2.version))
    print("  Server status: " .. tostring(server_info2.status))
    
    -- Test that the information is consistent
    assert(server_info.name == server_info2.name, "Server name should be consistent")
    assert(server_info.version == server_info2.version, "Server version should be consistent")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test get_server_info error handling
local function test_get_server_info_error_handling()
    print("Testing get_server_info error handling...")
    
    -- Load the rpc_standalone module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create a client with invalid server address
    local client = rpc_standalone.new("127.0.0.1:9999") -- Invalid port
    
    -- Test get_server_info with invalid server
    local server_info = client:get_server_info()
    
    -- Should handle the error gracefully and return basic info
    assert(server_info ~= nil, "get_server_info should return a result even with invalid server")
    assert(type(server_info) == "table", "get_server_info should return a table even with invalid server")
    assert(server_info.name ~= nil, "server_info should have a name field even with invalid server")
    assert(server_info.status == "unavailable", "server_info status should be 'unavailable' with invalid server")
    
    print("✓ get_server_info error handling works correctly")
    print("  Server name: " .. tostring(server_info.name))
    print("  Server status: " .. tostring(server_info.status))
    
    return true
end

-- Test get_server_info consistency
local function test_get_server_info_consistency()
    print("Testing get_server_info consistency...")
    
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
    
    -- Test that multiple calls return consistent results
    local info1 = client:get_server_info()
    local info2 = client:get_server_info()
    local info3 = client:get_server_info()
    
    assert(info1.name == info2.name and info2.name == info3.name, "Server name should be consistent across calls")
    assert(info1.version == info2.version and info2.version == info3.version, "Server version should be consistent across calls")
    assert(info1.status == info2.status and info2.status == info3.status, "Server status should be consistent across calls")
    
    print("✓ get_server_info consistency test passed")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test get_server_info with server restart
local function test_get_server_info_with_server_restart()
    print("Testing get_server_info with server restart...")
    
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
    
    -- Test get_server_info with server running
    local info1 = client:get_server_info()
    assert(info1.status == "running", "get_server_info should show 'running' status with server running")
    print("✓ Server info with server running: " .. info1.name .. " v" .. info1.version .. " (" .. info1.status .. ")")
    
    -- Stop the server
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    os.execute("sleep 2")
    
    -- Test get_server_info with server stopped
    local info2 = client:get_server_info()
    assert(info2.status == "unavailable", "get_server_info should show 'unavailable' status with server stopped")
    print("✓ Server info with server stopped: " .. info2.name .. " (" .. info2.status .. ")")
    
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
    
    -- Test get_server_info with server restarted
    local info3 = client:get_server_info()
    assert(info3.status == "running", "get_server_info should show 'running' status with server restarted")
    print("✓ Server info with server restarted: " .. info3.name .. " v" .. info3.version .. " (" .. info3.status .. ")")
    
    -- Verify that the server info is consistent after restart
    assert(info1.name == info3.name, "Server name should be consistent after restart")
    assert(info1.version == info3.version, "Server version should be consistent after restart")
    
    print("✓ get_server_info with server restart works correctly")
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Test get_server_info detailed information
local function test_get_server_info_detailed()
    print("Testing get_server_info detailed information...")
    
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
    
    -- Get server info
    local server_info = client:get_server_info()
    
    -- Test that we have all expected fields
    assert(server_info.name ~= nil, "Server info should have a name")
    assert(server_info.version ~= nil, "Server info should have a version")
    assert(server_info.status ~= nil, "Server info should have a status")
    assert(server_info.address ~= nil, "Server info should have an address")
    assert(server_info.protocol ~= nil, "Server info should have a protocol")
    
    -- Test that the values are reasonable
    assert(type(server_info.name) == "string", "Server name should be a string")
    assert(type(server_info.version) == "string", "Server version should be a string")
    assert(type(server_info.status) == "string", "Server status should be a string")
    assert(type(server_info.address) == "string", "Server address should be a string")
    assert(type(server_info.protocol) == "string", "Server protocol should be a string")
    
    -- Test specific values
    assert(server_info.name == "Paragonic", "Server name should be 'Paragonic'")
    assert(server_info.status == "running", "Server status should be 'running'")
    assert(server_info.address == "127.0.0.1:3000", "Server address should match")
    assert(server_info.protocol == "JSON-RPC 2.0", "Server protocol should be 'JSON-RPC 2.0'")
    
    print("✓ get_server_info detailed information test passed")
    print("  Name: " .. server_info.name)
    print("  Version: " .. server_info.version)
    print("  Status: " .. server_info.status)
    print("  Address: " .. server_info.address)
    print("  Protocol: " .. server_info.protocol)
    
    -- Cleanup
    os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
    print("✓ Server cleanup completed")
    
    return true
end

-- Run the tests
local success, err = pcall(function()
    test_get_server_info_method_exists()
    test_get_server_info_method_implementation()
    test_get_server_info_error_handling()
    test_get_server_info_consistency()
    test_get_server_info_with_server_restart()
    test_get_server_info_detailed()
end)

if not success then
    print("Test failed: " .. tostring(err))
    os.exit(1)
end

print("✓ All rpc_standalone get_server_info tests passed!") 