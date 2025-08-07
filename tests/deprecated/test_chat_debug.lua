--[[
Debug test for chat completion in Neovim plugin context
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Mock vim functions
vim = {
    json = {
        encode = function(obj)
            if type(obj) == "table" then
                local parts = {}
                for k, v in pairs(obj) do
                    local key_str = string.format('"%s"', k)
                    local value_str
                    if type(v) == "string" then
                        value_str = string.format('"%s"', v)
                    elseif type(v) == "table" then
                        if #v > 0 then
                            local array_parts = {}
                            for i, val in ipairs(v) do
                                if type(val) == "string" then
                                    table.insert(array_parts, string.format('"%s"', val))
                                else
                                    table.insert(array_parts, tostring(val))
                                end
                            end
                            value_str = "[" .. table.concat(array_parts, ",") .. "]"
                        else
                            value_str = "[]"
                        end
                    else
                        value_str = tostring(v)
                    end
                    table.insert(parts, key_str .. ":" .. value_str)
                end
                return "{" .. table.concat(parts, ",") .. "}"
            else
                return tostring(obj)
            end
        end,
        decode = function(str)
            print("DEBUG: Decoding JSON: " .. str)
            -- Use real JSON decoder if available
            if _G.vim and _G.vim.json and _G.vim.json.decode then
                local success, result = pcall(_G.vim.json.decode, str)
                if success then
                    return result
                end
            end
            -- Fallback to simple parsing
            if str:find('"result"') then
                return {result = "test_response"}
            else
                return {error = "parse_error"}
            end
        end
    },
    api = {
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
        nvim_command = function() end,
        nvim_create_user_command = function() end
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
    end,
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
    }
}

-- Test the send_message function
local function test_send_message()
    print("Testing send_message function...")
    
    local paragonic = require("paragonic")
    
    -- Initialize the plugin
    paragonic.setup()
    
    -- Test sending a message
    local response, err = paragonic.send_message("Hello, this is a test message", "llama2")
    
    if response then
        print("✓ Message sent successfully")
        print("Response: " .. tostring(response))
    else
        print("✗ Failed to send message: " .. tostring(err))
    end
end

-- Test RPC client directly
local function test_rpc_client()
    print("\nTesting RPC client directly...")
    
    local rpc = require("paragonic.rpc")
    local client = rpc.new("127.0.0.1:3000")
    
    local success, err = client:connect()
    if success then
        print("✓ RPC connection successful")
        
        -- Test hello
        local hello_response = client:hello()
        print("DEBUG: Hello response: " .. tostring(hello_response))
        
        -- Test chat completion
        local chat_response = client:chat_completion("llama2", "Hello, this is a test message")
        print("DEBUG: Chat completion response: " .. tostring(chat_response))
        
        if chat_response then
            local success, parsed = pcall(vim.json.decode, chat_response)
            if success and parsed then
                print("✓ Chat response parsed: " .. vim.json.encode(parsed))
            else
                print("✗ Failed to parse chat response")
            end
        else
            print("✗ No chat completion response")
        end
        
        client:disconnect()
    else
        print("✗ RPC connection failed: " .. tostring(err))
    end
end

-- Run tests
print("=== Chat Debug Test ===")
test_rpc_client()
test_send_message()
print("\n=== Chat Debug Test Complete ===") 