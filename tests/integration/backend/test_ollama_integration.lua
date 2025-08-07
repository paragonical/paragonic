--[[
Test for Ollama integration functionality - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Global variable to store the server process
local server_process = nil

-- Test that Ollama service is available
local function test_ollama_service_available()
    print("Testing Ollama service availability...")
    
    -- Check if Ollama is running
    local success = os.execute("curl -s http://localhost:11434/api/tags > /dev/null 2>&1")
    if success then
        print("✓ Ollama service is running on localhost:11434")
    else
        print("⚠ Ollama service not available, need to start Ollama first")
        print("  You can start Ollama with: ollama serve")
        return false
    end
    
    -- Check if llama2 model is available
    local model_check = io.popen("curl -s http://localhost:11434/api/tags | grep -q llama2")
    if model_check then
        model_check:close()
        print("✓ llama2 model is available")
    else
        print("⚠ llama2 model not found, you may need to pull it with: ollama pull llama2")
        return false
    end
    
    return true
end

-- Test that Rust backend can connect to Ollama
local function test_rust_backend_ollama_connection()
    print("Testing Rust backend Ollama connection...")
    
    -- Start the server in background
    local backend_binary = "./target/debug/paragonic"
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
    
    -- Load the paragonic module
    local paragonic = require("paragonic")
    
    -- Get RPC client (should initialize backend)
    local rpc_client = paragonic._get_rpc_client()
    assert(rpc_client ~= nil, "Should have RPC client")
    assert(rpc_client:is_connected(), "RPC client should be connected")
    
    print("✓ Rust backend Ollama connection test passed!")
end

-- Test that Ollama chat completion works
local function test_ollama_chat_completion()
    print("Testing Ollama chat completion...")
    
    -- Load the paragonic module
    local paragonic = require("paragonic")
    
    -- Test that we can send a chat message and get a real AI response
    local response = paragonic.send_message("Hello, what is 2+2?", "llama2")
    assert(response ~= nil, "Should get response from chat completion")
    assert(type(response) == "string", "Response should be string")
    assert(response ~= "mock_response", "Should not be mock response")
    assert(response ~= "", "Response should not be empty")
    
    -- The response should contain some indication of the answer
    local lower_response = response:lower()
    assert(lower_response:find("4") or lower_response:find("four") or lower_response:find("answer"), 
           "Response should contain answer to 2+2")
    
    print("✓ Ollama chat completion test passed!")
    print("  Response: " .. response:sub(1, 100) .. "...")
end

-- Test that Ollama model listing works
local function test_ollama_model_listing()
    print("Testing Ollama model listing...")
    
    -- Load the paragonic module
    local paragonic = require("paragonic")
    
    -- Test that we can get available models
    local models = paragonic.get_available_models()
    assert(models ~= nil, "Should get models list")
    assert(type(models) == "table", "Models should be table")
    assert(#models > 0, "Should have at least one model")
    
    -- Check if llama2 is in the list
    local has_llama2 = false
    for _, model in ipairs(models) do
        if model.name and model.name:find("llama2") then
            has_llama2 = true
            break
        end
    end
    assert(has_llama2, "Should have llama2 model available")
    
    print("✓ Ollama model listing test passed!")
    print("  Available models: " .. #models)
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
    -- First check if Ollama is available
    if not test_ollama_service_available() then
        print("⚠ Skipping Ollama integration tests - Ollama not available")
        return
    end
    
    test_rust_backend_ollama_connection()
    test_ollama_chat_completion()
    test_ollama_model_listing()
end)

-- Always cleanup
cleanup_server()

if not success then
    print("Test failed: " .. tostring(err))
    os.exit(1)
end

print("✓ All Ollama integration tests passed!") 