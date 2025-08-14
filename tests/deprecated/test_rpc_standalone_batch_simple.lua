--[[
Simple test for batch_operations method to debug issues
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Load the rpc_standalone module
local rpc_standalone = require("paragonic.rpc_standalone")

-- Create a new RPC client
local client = rpc_standalone.new("127.0.0.1:2346")

print("Testing batch_operations method exists...")
assert(type(client.batch_operations) == "function", "batch_operations method should exist")
print("✓ batch_operations method exists")

-- Test with server running
print("Starting server...")
local server_cmd = "./target/debug/paragonic --no-database > /dev/null 2>&1 & echo $!"
local server_process = io.popen(server_cmd)
local pid = server_process:read("*a"):match("(%d+)")
print("✓ Server started with PID: " .. pid)

-- Wait for server to start
os.execute("sleep 3")

-- Connect to server
print("Connecting to server...")
local connect_result = client:connect()
assert(connect_result == true, "Should connect successfully")
print("✓ Connected to server")

-- Test simple batch operation
print("Testing simple batch operation...")
local operations = {
	{ method = "hello", params = {} },
}

local batch_result = client:batch_operations(operations)
print("Batch result type: " .. type(batch_result))
if batch_result then
	print("Batch result length: " .. #batch_result)
	print("First result: " .. tostring(batch_result[1]))
end

-- Cleanup
os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
print("✓ Server cleanup completed")

print("✓ Simple batch_operations test completed")
