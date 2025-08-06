--[[
Direct test of RPC client
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
            -- Use real JSON decoder if available
            if _G.vim and _G.vim.json and _G.vim.json.decode then
                local success, result = pcall(_G.vim.json.decode, str)
                if success then
                    return result
                end
            end
            -- Try using cjson if available
            local cjson_ok, cjson = pcall(require, "cjson")
            if cjson_ok then
                local success, result = pcall(cjson.decode, str)
                if success then
                    return result
                end
            end
            -- Try using dkjson if available
            local dkjson_ok, dkjson = pcall(require, "dkjson")
            if dkjson_ok then
                local success, result = pcall(dkjson.decode, str)
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
    }
}

-- Test RPC client
local rpc = require("paragonic.rpc")
local client = rpc.new("127.0.0.1:3000")

print("Testing RPC client connection...")
local success, err = client:connect()
print("Connection success:", success, err or "none")

if success then
    print("Testing hello method...")
    local response = client:hello()
    print("Hello response:", response)
    
    print("Testing chat completion...")
    local chat_response = client:chat_completion("llama2", "Hello, this is a test message")
    print("Chat response:", chat_response)
    
    client:disconnect()
else
    print("Failed to connect to RPC server")
end

print("=== RPC Direct Test Complete ===") 