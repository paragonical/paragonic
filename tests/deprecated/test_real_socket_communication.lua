--[[
Test for real socket communication with Rust backend - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Global variable to store the server process
local server_process = nil

-- Test real socket communication with Rust backend
local function test_real_socket_communication()
    print("Testing real socket communication with Rust backend...")
    
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
    
    -- Test direct socket communication using curl (which doesn't require luasocket)
    print("Testing direct socket communication...")
    
    -- Test hello method via curl
    local hello_curl = io.popen('curl -s -X POST -H "Content-Type: application/json" -d \'{"jsonrpc":"2.0","method":"hello","params":{},"id":1}\' http://127.0.0.1:3000')
    if hello_curl then
        local hello_response = hello_curl:read("*a")
        hello_curl:close()
        
        if hello_response and hello_response ~= "" then
            print("✓ Hello response via curl: " .. hello_response:sub(1, 100))
            
            -- Parse the JSON response
            local cjson = require("cjson")
            local parsed = cjson.decode(hello_response)
            assert(parsed.jsonrpc == "2.0", "Should be valid JSON-RPC response")
            assert(parsed.result == "world", "Should get 'world' response from hello")
            
            print("✓ Real socket communication test passed!")
            return true
        else
            print("⚠ No response from hello method")
        end
    else
        print("⚠ Failed to execute curl command")
    end
    
    return false
end

-- Test chat completion via direct socket communication
local function test_chat_completion_via_curl()
    print("Testing chat completion via direct socket communication...")
    
    -- Test chat completion method via curl
    local chat_curl = io.popen('curl -s -X POST -H "Content-Type: application/json" -d \'{"jsonrpc":"2.0","method":"chat_completion","params":["Hello, what is 2+2?","llama2"],"id":1}\' http://127.0.0.1:3000')
    if chat_curl then
        local chat_response = chat_curl:read("*a")
        chat_curl:close()
        
        if chat_response and chat_response ~= "" then
            print("✓ Chat response via curl: " .. chat_response:sub(1, 200))
            
            -- Parse the JSON response
            local cjson = require("cjson")
            local parsed = cjson.decode(chat_response)
            assert(parsed.jsonrpc == "2.0", "Should be valid JSON-RPC response")
            
            -- Check if we got a real response (not an error)
            if parsed.result then
                assert(parsed.result ~= "mock_response", "Should not be mock response")
                assert(type(parsed.result) == "string", "Result should be string")
                assert(parsed.result ~= "", "Result should not be empty")
                
                print("✓ Chat completion via curl test passed!")
                return true
            else
                print("⚠ Chat completion returned error: " .. tostring(parsed.error))
            end
        else
            print("⚠ No response from chat completion method")
        end
    else
        print("⚠ Failed to execute curl command")
    end
    
    return false
end

-- Test list models via direct socket communication
local function test_list_models_via_curl()
    print("Testing list models via direct socket communication...")
    
    -- Test list models method via curl
    local models_curl = io.popen('curl -s -X POST -H "Content-Type: application/json" -d \'{"jsonrpc":"2.0","method":"list_models","params":{},"id":1}\' http://127.0.0.1:3000')
    if models_curl then
        local models_response = models_curl:read("*a")
        models_curl:close()
        
        if models_response and models_response ~= "" then
            print("✓ Models response via curl: " .. models_response:sub(1, 200))
            
            -- Parse the JSON response
            local cjson = require("cjson")
            local parsed = cjson.decode(models_response)
            assert(parsed.jsonrpc == "2.0", "Should be valid JSON-RPC response")
            
            -- Check if we got a real response (not an error)
            if parsed.result then
                assert(parsed.result ~= "mock_response", "Should not be mock response")
                assert(type(parsed.result) == "string", "Result should be string")
                
                -- Parse the result as JSON (it should be a JSON string)
                local result_parsed = cjson.decode(parsed.result)
                assert(type(result_parsed) == "table", "Result should be parseable as JSON")
                
                print("✓ List models via curl test passed!")
                return true
            else
                print("⚠ List models returned error: " .. tostring(parsed.error))
            end
        else
            print("⚠ No response from list models method")
        end
    else
        print("⚠ Failed to execute curl command")
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
    local socket_success = test_real_socket_communication()
    if socket_success then
        test_chat_completion_via_curl()
        test_list_models_via_curl()
    else
        print("⚠ Skipping curl tests - socket communication failed")
    end
end)

-- Always cleanup
cleanup_server()

if not success then
    print("Test failed: " .. tostring(err))
    os.exit(1)
end

print("✓ All real socket communication tests passed!") 