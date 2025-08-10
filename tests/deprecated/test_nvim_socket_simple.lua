-- Simple test for Neovim socket connection
local file = io.open("/tmp/nvim_socket_simple.log", "w")
if file then
    file:write("Testing simple Neovim socket connection...\n")
    
    -- Try to connect using Neovim's built-in socket
    local sock = vim.fn.sockconnect("tcp", "127.0.0.1:3000", {})
    file:write("Socket connection result: " .. tostring(sock) .. "\n")
    
    if sock > 0 then
        file:write("✓ Socket connected successfully\n")
        
        -- Try to send a simple message
        local send_result = vim.fn.sockwrite(sock, '{"jsonrpc":"2.0","method":"hello","params":[],"id":1}\n')
        file:write("Send result: " .. tostring(send_result) .. "\n")
        
        if send_result > 0 then
            file:write("✓ Message sent successfully\n")
            
            -- Try to read a response
            local response = vim.fn.sockread(sock, 1000)
            file:write("Response: " .. tostring(response) .. "\n")
            
            if response and response ~= "" then
                file:write("✓ Response received successfully\n")
            else
                file:write("✗ No response received\n")
            end
        else
            file:write("✗ Failed to send message\n")
        end
        
        -- Close the socket
        vim.fn.sockclose(sock)
        file:write("Socket closed\n")
    else
        file:write("✗ Failed to connect\n")
    end
    
    file:write("=== Simple Socket Test Complete ===\n")
    file:close()
end 