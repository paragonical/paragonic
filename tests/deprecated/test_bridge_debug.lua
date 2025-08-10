-- Debug test for RPC bridge timeout issue
local file = io.open("/tmp/bridge_debug.log", "w")
if file then
    file:write("Testing RPC bridge debug...\n")
    
    -- Test if timeout command exists
    local timeout_result = os.execute("which timeout > /dev/null 2>&1")
    if timeout_result then
        file:write("✓ timeout command available\n")
    else
        file:write("✗ timeout command not available\n")
    end
    
    -- Test direct lua execution
    local lua_result = os.execute("lua -e 'print(\"test\")'")
    if lua_result then
        file:write("✓ lua command available\n")
    else
        file:write("✗ lua command not available\n")
    end
    
    -- Test with gtimeout (macOS equivalent)
    local gtimeout_result = os.execute("which gtimeout > /dev/null 2>&1")
    if gtimeout_result then
        file:write("✓ gtimeout command available\n")
    else
        file:write("✗ gtimeout command not available\n")
    end
    
    -- Test with built-in timeout alternative
    local test_script = [[
-- Test script
local socket = require("socket")
local json = require("cjson")
print("Libraries loaded successfully")
print("Test completed")
]]
    
    local temp_script = "/tmp/test_script.lua"
    local f = io.open(temp_script, "w")
    if f then
        f:write(test_script)
        f:close()
        
        -- Test direct execution
        local direct_result = os.execute("lua " .. temp_script)
        if direct_result then
            file:write("✓ Direct lua execution works\n")
        else
            file:write("✗ Direct lua execution failed\n")
        end
        
        -- Test with timeout equivalent
        local timeout_alt_result = os.execute("lua " .. temp_script .. " & sleep 5 && kill $! 2>/dev/null || true")
        if timeout_alt_result then
            file:write("✓ Timeout alternative works\n")
        else
            file:write("✗ Timeout alternative failed\n")
        end
        
        os.remove(temp_script)
    end
    
    file:write("=== Bridge Debug Test Complete ===\n")
    file:close()
end 