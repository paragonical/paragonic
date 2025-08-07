--[[
Standalone test for chat functionality without Neovim dependencies
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Mock vim functions for standalone testing
vim = {
    json = {
        encode = function(obj)
            -- Simple JSON encoder for testing
            if type(obj) == "table" then
                local parts = {}
                for k, v in pairs(obj) do
                    if type(v) == "string" then
                        table.insert(parts, string.format('"%s":"%s"', k, v))
                    else
                        table.insert(parts, string.format('"%s":%s', k, tostring(v)))
                    end
                end
                return "{" .. table.concat(parts, ",") .. "}"
            else
                return tostring(obj)
            end
        end,
        decode = function(str)
            -- Simple JSON decoder for testing
            if str:find('"result"') then
                return {result = "test_response"}
            else
                return {error = "parse_error"}
            end
        end
    },
    fn = {
        stdpath = function(path)
            return "/tmp/paragonic_test"
        end,
        mkdir = function(dir, mode)
            return 1
        end,
        filereadable = function(file)
            return 0
        end,
        readfile = function(file)
            return {}
        end,
        writefile = function(lines, file)
            return 0
        end
    },
    api = {
        nvim_create_user_command = function() end,
        nvim_list_bufs = function() return {} end,
        nvim_get_current_buf = function() return 1 end,
        nvim_buf_get_name = function() return "test.lua" end,
        nvim_buf_get_lines = function() return {} end,
        nvim_buf_set_lines = function() end,
        nvim_buf_is_valid = function() return true end,
        nvim_buf_get_option = function() return true end,
        nvim_set_current_buf = function() end,
        nvim_win_get_cursor = function() return {1, 0} end,
        nvim_win_set_cursor = function() end,
        nvim_list_wins = function() return {1} end,
        nvim_win_get_buf = function() return 1 end,
        nvim_get_mode = function() return {mode = "n"} end,
        nvim_create_buf = function() return 1 end,
        nvim_buf_set_name = function() end,
        nvim_buf_set_option = function() end,
        nvim_open_win = function() return 1 end,
        nvim_command = function() end
    },
    o = {
        columns = 80,
        lines = 24
    },
    notify = function(msg, level)
        print("NOTIFY [" .. (level or "INFO") .. "]: " .. msg)
    end,
    log = {
        levels = {
            DEBUG = 0,
            INFO = 1,
            WARN = 2,
            ERROR = 3
        }
    },
    keymap = {
        set = function() end
    },
    tbl_deep_extend = function(mode, ...)
        local result = {}
        for i = 1, select('#', ...) do
            local tbl = select(i, ...)
            if tbl then
                for k, v in pairs(tbl) do
                    result[k] = v
                end
            end
        end
        return result
    end
}

-- Test the RPC connection directly
local function test_rpc_connection()
    print("Testing RPC connection...")
    
    -- Load the RPC module directly
    local rpc = require("paragonic.rpc")
    assert(rpc ~= nil, "RPC module should load")
    
    -- Create RPC client
    local client = rpc.new("127.0.0.1:3000")
    assert(client ~= nil, "RPC client should be created")
    
    -- Test connection
    local success, err = client:connect()
    if success then
        print("✓ RPC connection successful")
        
        -- Test hello method
        local response = client:hello()
        if response then
            print("✓ Hello method response: " .. tostring(response))
            
            -- Check if it's a mock response
            if response:find("mock_response") then
                print("⚠️  WARNING: Got mock response instead of real response")
                print("   This indicates the backend is not responding properly")
            else
                print("✓ Got real response from backend")
            end
        else
            print("✗ Hello method failed")
        end
        
        -- Test chat completion
        local chat_response = client:chat_completion("llama2", "Hello, this is a test")
        if chat_response then
            print("✓ Chat completion response received")
            if chat_response:find("mock_response") then
                print("⚠️  WARNING: Chat completion returned mock response")
            else
                print("✓ Chat completion returned real response")
            end
        else
            print("✗ Chat completion failed")
        end
        
        client:disconnect()
    else
        print("✗ RPC connection failed: " .. tostring(err))
    end
end

-- Test the standalone RPC module
local function test_standalone_rpc()
    print("\nTesting standalone RPC...")
    
    -- Create a simple standalone RPC client
    local function create_standalone_rpc(server_address)
        local client = {
            server_address = server_address,
            connected = false,
            socket = nil
        }
        
        function client:connect()
            -- Parse server address
            local host, port = self.server_address:match("([^:]+):?(%d*)")
            port = port or "3000"
            
            -- Try to load socket library
            local socket_available = pcall(require, "socket")
            local socket = socket_available and require("socket") or nil
            
            if socket and socket.tcp then
                -- Use real TCP socket
                self.socket = socket.tcp()
                self.socket:settimeout(5)
                
                local success, err = self.socket:connect(host, tonumber(port))
                if success then
                    self.connected = true
                    return true
                else
                    self.socket:close()
                    self.socket = nil
                    return false, err
                end
            else
                -- Fallback for testing
                self.connected = true
                return true
            end
        end
        
        function client:disconnect()
            if self.socket then
                self.socket:close()
                self.socket = nil
            end
            self.connected = false
            return true
        end
        
        function client:is_connected()
            return self.connected
        end
        
        function client:call(method, params)
            if not self:is_connected() then
                return nil, "Not connected"
            end
            
            -- Create JSON-RPC request
            local request = {
                jsonrpc = "2.0",
                method = method,
                params = params or {},
                id = 1
            }
            
            local request_json = vim.json.encode(request)
            local message = "Content-Length: " .. #request_json .. "\r\n\r\n" .. request_json
            
            if self.socket and self.socket.send and self.socket.receive then
                -- Real socket communication
                local send_success, send_err = self.socket:send(message)
                if not send_success then
                    return nil, "Failed to send: " .. tostring(send_err)
                end
                
                local response, recv_err = self.socket:receive("*a")
                if not response then
                    return nil, "Failed to receive: " .. tostring(recv_err)
                end
                
                return response
            else
                -- Mock response for testing
                return '{"jsonrpc":"2.0","result":"mock_response","id":1}'
            end
        end
        
        function client:hello()
            return self:call("hello", {})
        end
        
        function client:chat_completion(model, message)
            return self:call("chat_completion", {message, model})
        end
        
        return client
    end
    
    -- Test standalone client
    local client = create_standalone_rpc("127.0.0.1:3000")
    local success, err = client:connect()
    
    if success then
        print("✓ Standalone RPC connection successful")
        
        local response = client:hello()
        if response then
            print("✓ Standalone hello response: " .. tostring(response))
            if response:find("mock_response") then
                print("⚠️  WARNING: Standalone got mock response")
            end
        end
        
        client:disconnect()
    else
        print("✗ Standalone RPC connection failed: " .. tostring(err))
    end
end

-- Run tests
print("=== Paragonic Chat Interface Test ===")
test_rpc_connection()
test_standalone_rpc()
print("\n=== Test Complete ===") 