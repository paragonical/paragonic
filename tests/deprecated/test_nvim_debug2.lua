-- Detailed debug test for Neovim
local file = io.open("/tmp/nvim_debug2.log", "w")
if file then
    file:write("Starting detailed Neovim debug test...\n")
    
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
        
        -- Test JSON parsing directly
        file:write("Testing JSON parsing directly...\n")
        local test_json = '{"jsonrpc":"2.0","result":"{\\"model\\":\\"llama2\\",\\"message\\":{\\"role\\":\\"assistant\\",\\"content\\":\\"Hello!\\"}}","id":1}'
        file:write("Test JSON: " .. test_json .. "\n")
        
        local parse_success, parse_result = pcall(vim.json.decode, test_json)
        if parse_success then
            file:write("✓ Outer JSON parsed successfully\n")
            file:write("Result type: " .. type(parse_result.result) .. "\n")
            file:write("Result value: " .. tostring(parse_result.result) .. "\n")
            
            -- Parse the inner JSON string
            if type(parse_result.result) == "string" then
                local inner_success, inner_result = pcall(vim.json.decode, parse_result.result)
                if inner_success then
                    file:write("✓ Inner JSON parsed successfully\n")
                    file:write("Inner result: " .. tostring(inner_result) .. "\n")
                    if inner_result.message and inner_result.message.content then
                        file:write("✓ Message content: " .. inner_result.message.content .. "\n")
                    else
                        file:write("✗ No message content in inner result\n")
                    end
                else
                    file:write("✗ Failed to parse inner JSON: " .. tostring(inner_result) .. "\n")
                end
            end
        else
            file:write("✗ Failed to parse outer JSON: " .. tostring(parse_result) .. "\n")
        end
        
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
    
    file:write("=== Detailed Neovim Debug Test Complete ===\n")
    file:close()
end 