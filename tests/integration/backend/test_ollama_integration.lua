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
local server_pid = nil

-- Test that Ollama service is available
local function test_ollama_service_available()
    print("Testing Ollama service availability...")
    
    -- Check if Ollama is running on localhost:11434
    local check_cmd = "curl -s http://localhost:11434/api/tags > /dev/null 2>&1"
    local result = os.execute(check_cmd)
    
    if result then
        print("✓ Ollama service is running on localhost:11434")
        
        -- Check if llama2 model is available
        local model_cmd = "curl -s http://localhost:11434/api/tags | grep -q llama2"
        local model_result = os.execute(model_cmd)
        
        if model_result then
            print("✓ llama2 model is available")
            return true
        else
            print("⚠ llama2 model not found, but Ollama is running")
            return true -- Still proceed with tests
        end
    else
        print("❌ Ollama service is not running on localhost:11434")
        return false
    end
end

-- Test that Rust backend can connect to Ollama
local function test_rust_backend_ollama_connection()
    print("Testing Rust backend Ollama connection...")
    
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
    server_pid = server_process:read("*a"):match("(%d+)")
    if not server_pid then
        error("Failed to get server process ID")
    end
    
    print("✓ Server started with PID: " .. server_pid)
    
    -- Wait a moment for the server to start up
    os.execute("sleep 3")
    
    -- Load the paragonic module
    local paragonic = require("paragonic")
    
    -- Initialize backend to get RPC client
    local success = paragonic.backend.initialize_backend()
    assert(success, "Backend initialization should succeed")
    
    -- Get RPC client (should be available after initialization)
    local rpc_client = paragonic.backend._get_rpc_client()
    assert(rpc_client ~= nil, "Should have RPC client")
    assert(rpc_client:is_connected(), "RPC client should be connected")
    
    print("✓ Rust backend Ollama connection test passed!")
end

-- Test that Ollama chat completion works
local function test_ollama_chat_completion()
    print("Testing Ollama chat completion...")
    
    -- Load the paragonic module
    local paragonic = require("paragonic")
    
    -- Test that we can send a chat message and get a response
    local response = paragonic.chat.send_message("Hello, what is 2+2?", "llama2")
    assert(response ~= nil, "Should get response from chat completion")
    assert(type(response) == "string", "Response should be string")
    assert(response ~= "", "Response should not be empty")
    
    -- The response should contain real AI content (not mock)
    assert(response:find("4") or response:find("four") or response:find("answer"), "Response should contain answer to 2+2")
    
    print("✓ Ollama chat completion test passed!")
    print("  Response: " .. response:sub(1, 100) .. "...")
end

-- Test that Ollama model listing works
local function test_ollama_model_listing()
    print("Testing Ollama model listing...")
    
    -- Load the paragonic module
    local paragonic = require("paragonic")
    
    -- Test that we can get available models
    local models = paragonic.backend.get_available_models()
    assert(models ~= nil, "Should get models list")
    assert(type(models) == "table", "Models should be table")
    assert(#models > 0, "Should have at least one model")
    
    -- Check if llama2 is in the list (models may have suffixes like "llama2:7b")
    local has_llama2 = false
    for _, model in ipairs(models) do
        local model_name = nil
        if type(model) == "table" and model.name then
            model_name = model.name
        elseif type(model) == "string" then
            model_name = model
        end
        
        if model_name and model_name:find("llama2") then
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
        -- Kill only the specific test server process
        if server_pid then
            os.execute("kill " .. server_pid .. " > /dev/null 2>&1")
            print("✓ Test server (PID: " .. server_pid .. ") cleanup completed")
        end
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