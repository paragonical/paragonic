--[[
Test for socket communication logic - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Test socket library availability detection
local function test_socket_library_detection()
    print("Testing socket library detection...")
    
    -- Test if luasocket is available
    local success, socket = pcall(require, "socket")
    if success then
        print("✓ luasocket library is available")
        assert(socket.tcp ~= nil, "TCP function should be available")
        print("✓ TCP function is available")
    else
        print("⚠ luasocket library not available, using mock socket")
        print("  Error: " .. tostring(socket))
    end
    
    print("✓ Socket library detection test passed!")
end

-- Test RPC client socket creation
local function test_rpc_client_socket_creation()
    print("Testing RPC client socket creation...")
    
    -- Load the RPC module
    local rpc = require("paragonic.rpc")
    
    -- Create a new RPC client
    local client = rpc:new()
    assert(client ~= nil, "Should create RPC client")
    
    -- Test connection to a real address (should use real socket if available)
    local success, err = client:connect("127.0.0.1", "3000")
    
    if success then
        print("✓ RPC client connected successfully")
        assert(client:is_connected(), "Client should be connected")
        
        -- Test that we can send a hello request
        local response = client:hello()
        assert(response ~= nil, "Should get response from hello")
        
        -- Parse the JSON response
        local cjson = require("cjson")
        local parsed = cjson.decode(response)
        assert(parsed.jsonrpc == "2.0", "Should be valid JSON-RPC response")
        
        print("✓ RPC client socket creation test passed!")
    else
        print("⚠ RPC client connection failed: " .. tostring(err))
        print("  This is expected if no server is running on port 3000")
    end
end

-- Test mock socket fallback behavior
local function test_mock_socket_fallback()
    print("Testing mock socket fallback behavior...")
    
    -- Load the RPC module
    local rpc = require("paragonic.rpc")
    
    -- Create a new RPC client
    local client = rpc:new()
    
    -- Test connection to an invalid address (should trigger mock fallback)
    local success, err = client:connect("127.0.0.1", "9999")
    
    -- The mock socket should always succeed for this test address
    assert(success == false, "Should fail to connect to invalid address")
    assert(err == "Connection refused", "Should get connection refused error")
    
    print("✓ Mock socket fallback test passed!")
end

-- Test JSON-RPC message formatting
local function test_json_rpc_message_formatting()
    print("Testing JSON-RPC message formatting...")
    
    -- Load the RPC module
    local rpc = require("paragonic.rpc")
    
    -- Create a new RPC client
    local client = rpc:new()
    
    -- Test that we can create a JSON-RPC call
    local response = client:call("hello", {})
    assert(response ~= nil, "Should get response from call")
    
    -- Parse the JSON response
    local cjson = require("cjson")
    local parsed = cjson.decode(response)
    assert(parsed.jsonrpc == "2.0", "Should be valid JSON-RPC response")
    assert(parsed.id == 1, "Should have correct ID")
    
    print("✓ JSON-RPC message formatting test passed!")
end

-- Test parameter format for chat completion
local function test_chat_completion_parameter_format()
    print("Testing chat completion parameter format...")
    
    -- Load the RPC module
    local rpc = require("paragonic.rpc")
    
    -- Create a new RPC client
    local client = rpc:new()
    
    -- Test chat completion with correct parameter format
    local response = client:chat_completion("llama2", "Hello, what is 2+2?")
    assert(response ~= nil, "Should get response from chat completion")
    
    -- Parse the JSON response
    local cjson = require("cjson")
    local parsed = cjson.decode(response)
    assert(parsed.jsonrpc == "2.0", "Should be valid JSON-RPC response")
    
    print("✓ Chat completion parameter format test passed!")
end

-- Run the tests
local success, err = pcall(function()
    test_socket_library_detection()
    test_rpc_client_socket_creation()
    test_mock_socket_fallback()
    test_json_rpc_message_formatting()
    test_chat_completion_parameter_format()
end)

if not success then
    print("Test failed: " .. tostring(err))
    os.exit(1)
end

print("✓ All socket logic tests passed!") 