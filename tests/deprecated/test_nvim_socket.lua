-- Debug test for socket library in Neovim
local file = io.open("/tmp/nvim_socket.log", "w")
if file then
    file:write("Starting socket library debug test in Neovim...\n")
    
    -- Check socket library availability
    local socket_ok, socket = pcall(require, "socket")
    file:write("Socket library available: " .. tostring(socket_ok) .. "\n")
    
    if socket_ok then
        file:write("Socket library loaded: " .. tostring(socket) .. "\n")
        
        -- Check if socket.tcp is available
        if socket.tcp then
            file:write("Socket.tcp is available\n")
            
            -- Try to create a TCP socket
            local tcp_ok, tcp = pcall(socket.tcp)
            if tcp_ok then
                file:write("TCP socket created: " .. tostring(tcp) .. "\n")
                
                -- Check if socket has send and receive methods
                if tcp.send then
                    file:write("✓ Socket has send method\n")
                else
                    file:write("✗ Socket does not have send method\n")
                end
                
                if tcp.receive then
                    file:write("✓ Socket has receive method\n")
                else
                    file:write("✗ Socket does not have receive method\n")
                end
                
                -- Try to connect
                local connect_ok, connect_err = pcall(tcp.connect, tcp, "127.0.0.1", 3000)
                if connect_ok then
                    file:write("✓ Socket connected successfully\n")
                    
                    -- Try to send a test message
                    local send_ok, send_err = pcall(tcp.send, tcp, '{"jsonrpc":"2.0","method":"hello","params":[],"id":1}\n')
                    if send_ok then
                        file:write("✓ Message sent successfully\n")
                        
                        -- Try to receive a response
                        local recv_ok, recv_err = pcall(tcp.receive, tcp, "*l")
                        if recv_ok then
                            file:write("✓ Response received: " .. tostring(recv_err) .. "\n")
                        else
                            file:write("✗ Failed to receive response: " .. tostring(recv_err) .. "\n")
                        end
                    else
                        file:write("✗ Failed to send message: " .. tostring(send_err) .. "\n")
                    end
                    
                    -- Close the socket
                    tcp:close()
                else
                    file:write("✗ Failed to connect: " .. tostring(connect_err) .. "\n")
                end
            else
                file:write("✗ Failed to create TCP socket: " .. tostring(tcp) .. "\n")
            end
        else
            file:write("✗ Socket.tcp is not available\n")
        end
    else
        file:write("✗ Socket library not available: " .. tostring(socket) .. "\n")
    end
    
    file:write("=== Socket Library Debug Test Complete ===\n")
    file:close()
end 