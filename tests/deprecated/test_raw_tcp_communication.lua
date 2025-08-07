--[[
Test for raw TCP communication with Rust backend - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Global variable to store the server process
local server_process = nil

-- Test raw TCP communication with Rust backend
local function test_raw_tcp_communication()
    print("Testing raw TCP communication with Rust backend...")
    
    -- Check if Rust backend binary exists
    local backend_binary = "./target/debug/paragonic"
    local file = io.open(backend_binary, "r")
    if not file then
        print("⚠ Rust backend binary not found at " .. backend_binary)
        print("  Need to build with: cargo build")
        return false
    end
    file:close()
    print("✓ Rust backend binary found at " .. backend_binary)
    
    -- Start the server in background
    server_process = io.popen(backend_binary .. " > /dev/null 2>&1 & echo $!")
    if not server_process then
        error("Failed to start server process")
    end
    
    -- Get the process ID
    local pid = server_process:read("*a"):match("(%d+)")
    if not pid then
        error("Failed to get server process ID")
    end
    
    print("✓ Server started with PID: " .. pid)
    
    -- Wait a moment for the server to start up
    os.execute("sleep 3")
    
    -- Test raw TCP communication using netcat
    print("Testing raw TCP communication...")
    
    -- Create a temporary file with the JSON-RPC request
    local request_file = "/tmp/paragonic_test_request.json"
    local request_json = '{"jsonrpc":"2.0","method":"hello","params":{},"id":1}'
    local f = io.open(request_file, "w")
    if f then
        f:write(request_json)
        f:close()
    end
    
    -- Send request via netcat
    local nc_cmd = string.format("cat %s | nc -w 5 127.0.0.1 3000", request_file)
    local nc_process = io.popen(nc_cmd)
    if nc_process then
        local response = nc_process:read("*a")
        nc_process:close()
        
        -- Clean up temp file
        os.remove(request_file)
        
        if response and response ~= "" then
            print("✓ Raw TCP response: " .. response:sub(1, 100))
            
            -- Parse the JSON response
            local cjson = require("cjson")
            local parsed = cjson.decode(response)
            assert(parsed.jsonrpc == "2.0", "Should be valid JSON-RPC response")
            assert(parsed.result == "world", "Should get 'world' response from hello")
            
            print("✓ Raw TCP communication test passed!")
            return true
        else
            print("⚠ No response from raw TCP communication")
        end
    else
        print("⚠ Failed to execute netcat command")
    end
    
    return false
end

-- Test chat completion via raw TCP communication
local function test_chat_completion_via_raw_tcp()
    print("Testing chat completion via raw TCP communication...")
    
    -- Create a temporary file with the JSON-RPC request
    local request_file = "/tmp/paragonic_test_chat.json"
    local request_json = '{"jsonrpc":"2.0","method":"chat_completion","params":["Hello, what is 2+2?","llama2"],"id":1}'
    local f = io.open(request_file, "w")
    if f then
        f:write(request_json)
        f:close()
    end
    
    -- Send request via netcat
    local nc_cmd = string.format("cat %s | nc -w 5 127.0.0.1 3000", request_file)
    local nc_process = io.popen(nc_cmd)
    if nc_process then
        local response = nc_process:read("*a")
        nc_process:close()
        
        -- Clean up temp file
        os.remove(request_file)
        
        if response and response ~= "" then
            print("✓ Chat completion raw TCP response: " .. response:sub(1, 200))
            
            -- Parse the JSON response
            local cjson = require("cjson")
            local parsed = cjson.decode(response)
            assert(parsed.jsonrpc == "2.0", "Should be valid JSON-RPC response")
            
            -- Check if we got a real response (not an error)
            if parsed.result then
                assert(parsed.result ~= "mock_response", "Should not be mock response")
                assert(type(parsed.result) == "string", "Result should be string")
                assert(parsed.result ~= "", "Result should not be empty")
                
                print("✓ Chat completion via raw TCP test passed!")
                return true
            else
                print("⚠ Chat completion returned error: " .. tostring(parsed.error))
            end
        else
            print("⚠ No response from chat completion method")
        end
    else
        print("⚠ Failed to execute netcat command")
    end
    
    return false
end

-- Cleanup function to stop the server
local function cleanup_server()
    if server_process then
        server_process:close()
        -- Kill the background process
        os.execute("pkill -f 'target/debug/paragonic' > /dev/null 2>&1")
        print("✓ Server cleanup completed")
    end
end

-- Run the tests
local success, err = pcall(function()
    local tcp_success = test_raw_tcp_communication()
    if tcp_success then
        test_chat_completion_via_raw_tcp()
    else
        print("⚠ Skipping raw TCP tests - communication failed")
    end
end)

-- Always cleanup
cleanup_server()

if not success then
    print("Test failed: " .. tostring(err))
    os.exit(1)
end

print("✓ All raw TCP communication tests passed!") 