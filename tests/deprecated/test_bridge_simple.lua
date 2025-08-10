-- Simple test for RPC bridge
local file = io.open("/tmp/bridge_simple.log", "w")
if file then
    file:write("Testing simple RPC bridge...\n")
    
    -- Add lua directory to package path
    package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
    file:write("Package path updated\n")
    
    -- Try to load the bridge directly
    local bridge_ok, bridge = pcall(require, "paragonic.rpc_bridge")
    if bridge_ok then
        file:write("✓ Bridge loaded successfully\n")
        
        -- Test sending a simple request
        file:write("Testing hello request...\n")
        local response = bridge.send_request("127.0.0.1:3000", "hello", {})
        file:write("Response: " .. tostring(response) .. "\n")
        
        if response then
            file:write("✓ Bridge is working!\n")
        else
            file:write("✗ Bridge failed\n")
        end
    else
        file:write("✗ Failed to load bridge: " .. tostring(bridge) .. "\n")
    end
    
    file:write("=== Simple Bridge Test Complete ===\n")
    file:close()
end 