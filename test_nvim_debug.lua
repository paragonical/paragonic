-- Debug test for Neovim
local file = io.open("/tmp/nvim_debug.log", "w")
if file then
    file:write("Starting Neovim debug test...\n")
    
    -- Add lua directory to package path
    package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
    file:write("Package path updated\n")
    
    -- Load the plugin
    local success, paragonic = pcall(require, "paragonic")
    if success then
        file:write("Plugin loaded successfully\n")
        
        -- Setup the plugin
        paragonic.setup()
        file:write("Plugin setup completed\n")
        
        -- Test send_message function
        file:write("Testing send_message function...\n")
        local result, err = paragonic.send_message("Hello, this is a test message")
        file:write("Send message result: " .. tostring(result) .. "\n")
        file:write("Send message error: " .. tostring(err) .. "\n")
        
        if result then
            file:write("✓ Chat functionality is working!\n")
        else
            file:write("✗ Chat functionality failed: " .. tostring(err) .. "\n")
        end
    else
        file:write("Failed to load plugin: " .. tostring(paragonic) .. "\n")
    end
    
    file:write("=== Neovim Debug Test Complete ===\n")
    file:close()
end 