-- Test RPC bridge in Neovim
-- Run this with: nvim -l test_nvim_bridge.lua

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Try to load the bridge
local bridge_ok, bridge = pcall(require, "paragonic.rpc_bridge")
if bridge_ok then
    print("✓ Bridge loaded successfully")
    
    -- Test sending a hello request
    print("Testing hello request...")
    local response = bridge.send_request("127.0.0.1:3000", "hello", {})
    print("Response:", vim.inspect(response))
    
    if response and response.result == "world" then
        print("✓ Bridge is working correctly!")
    else
        print("✗ Bridge failed or returned unexpected response")
    end
else
    print("✗ Failed to load bridge:", bridge)
end 