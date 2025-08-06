package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua'

local M = require('paragonic')

print("=== Simple RPC Test ===")

-- Test 1: Check if module loads
print("✅ Module loaded successfully")

-- Test 2: Try to get RPC client
print("📝 Getting RPC client...")
local client = M._get_rpc_client()
if client then
    print("✅ RPC client available")
else
    print("❌ RPC client not available")
end

-- Test 3: Try to initialize backend
print("📝 Initializing backend...")
local result = M.initialize_backend()
print("Backend initialization result:", result)

-- Test 4: Try to get RPC client after initialization
print("📝 Getting RPC client after initialization...")
local client = M._get_rpc_client()
if client then
    print("✅ RPC client available after initialization")
else
    print("❌ RPC client still not available after initialization")
end

-- Test 5: Try hello method directly
print("📝 Testing hello method...")
if client then
    local hello_result = client:hello()
    print("Hello result:", hello_result)
else
    print("❌ No client available for hello test")
end

print("=== Test completed ===") 