--[[
Simple test for chat response parsing
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
            -- Simple JSON parser for testing
            if str:find('"jsonrpc"') and str:find('"result"') then
                -- This is a JSON-RPC response
                local result_start = str:find('"result"%s*:%s*"') + 8
                local result_end = str:find('"%s*,%s*"id"', result_start) - 1
                local result_value = str:sub(result_start, result_end)
                
                return {
                    jsonrpc = "2.0",
                    result = result_value,
                    id = 1
                }
            end
            return {result = "test_response"}
        end
    }
}

-- Test the response parsing logic
local function test_response_parsing()
    print("Testing response parsing...")
    
    -- Simulate the actual response from the backend
    local response = '{"jsonrpc":"2.0","result":"{\\"model\\":\\"llama2\\",\\"created_at\\":\\"2025-08-06T14:22:54.320292Z\\",\\"message\\":{\\"role\\":\\"assistant\\",\\"content\\":\\"\\\\nHello! This is a test message.\\"},\\"done\\":true}","id":1}'
    
    print("Original response: " .. response)
    
    -- Parse the JSON-RPC response
    local parsed_response = vim.json.decode(response)
    print("Parsed response: " .. tostring(parsed_response))
    
    if parsed_response and parsed_response.result then
        print("Result type: " .. type(parsed_response.result))
        print("Result value: " .. tostring(parsed_response.result))
        
        -- Check if result is a JSON string
        if type(parsed_response.result) == "string" then
            print("Result is a string, trying to parse it...")
            local success, inner_result = pcall(vim.json.decode, parsed_response.result)
            if success and inner_result then
                print("Inner result: " .. tostring(inner_result))
                if inner_result.message and inner_result.message.content then
                    print("SUCCESS! Content: " .. inner_result.message.content)
                    return inner_result.message.content
                end
            else
                print("Failed to parse inner result: " .. tostring(inner_result))
            end
        end
    end
    
    print("Failed to extract content")
    return nil
end

-- Run test
print("=== Simple Chat Test ===")
test_response_parsing()
print("=== Test Complete ===") 