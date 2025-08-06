--[[
Final test for chat functionality
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
    },
    fn = {
        stdpath = function(path)
            if path == "data" then
                return "/tmp/paragonic_test"
            end
            return "/tmp"
        end,
        strftime = function(format)
            return os.date(format)
        end,
        expand = function(expr)
            if expr == "%" then
                return "test_file.lua"
            end
            return expr
        end,
        getcwd = function()
            return "/tmp"
        end,
        mode = function()
            return "n"
        end,
        filereadable = function(path)
            return false
        end,
        readfile = function(path)
            return {}
        end,
        writefile = function(lines, path)
            -- Mock file writing
        end,
        mkdir = function(path, flags)
            -- Mock directory creation
        end
    },
    api = {
        nvim_create_user_command = function(name, callback, opts)
            -- Mock command creation
        end,
        nvim_list_bufs = function()
            return {1}
        end,
        nvim_buf_get_name = function(buf)
            return "test_buffer"
        end,
        nvim_create_buf = function(listed, scratch)
            return 1
        end,
        nvim_buf_set_name = function(buf, name)
            -- Mock buffer name setting
        end,
        nvim_buf_set_option = function(buf, option, value)
            -- Mock buffer option setting
        end,
        nvim_buf_set_lines = function(buf, start, end_idx, strict, lines)
            -- Mock buffer lines setting
        end,
        nvim_buf_set_keymap = function(buf, mode, lhs, rhs, opts)
            -- Mock keymap setting
        end,
        nvim_command = function(cmd)
            -- Mock command execution
        end,
        nvim_set_current_buf = function(buf)
            -- Mock current buffer setting
        end
    },
    tbl_deep_extend = function(mode, ...)
        local result = {}
        local args = {...}
        for i, t in ipairs(args) do
            for k, v in pairs(t) do
                result[k] = v
            end
        end
        return result
    end,
    keymap = {
        set = function(mode, lhs, rhs, opts)
            -- Mock keymap setting
        end
    },
    notify = function(msg, level)
        print("NOTIFY:", msg, level)
    end,
    log = {
        levels = {
            ERROR = 1,
            WARN = 2,
            INFO = 3
        }
    }
}

-- Load the plugin
local paragonic = require("paragonic")

print("Testing chat functionality...")

-- Setup the plugin
paragonic.setup()

-- Test send_message function
print("Testing send_message function...")
local result, err = paragonic.send_message("Hello, this is a test message")
print("Send message result:", result)
print("Send message error:", err)

if result then
    print("✓ Chat functionality is working!")
else
    print("✗ Chat functionality failed:", err)
end

print("=== Chat Final Test Complete ===") 