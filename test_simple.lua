-- Simple test to debug module loading
print("Testing module loading...")

-- Add lua directory to package path
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"
print("Package path: " .. package.path)

-- Try to load the module
local success, result = pcall(function()
    return require('paragonic.rpc')
end)

if success then
    print("✓ Module loaded successfully")
    print("Module type: " .. type(result))
else
    print("✗ Module loading failed: " .. tostring(result))
end 