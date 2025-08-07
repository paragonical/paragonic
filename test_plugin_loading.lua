-- Test Plugin Loading in Neovim
-- This test should be run within Neovim using :source test_plugin_loading.lua

-- Test 1: Check if plugin is loaded
local function test_plugin_loading()
    print("=== Test 1: Plugin Loading ===")
    
    print("  📝 Testing plugin loading...")
    
    -- Check if the plugin module is available
    local success, M = pcall(require, "paragonic")
    if success then
        print("    ✅ Plugin module loaded successfully")
        print("    📦 Module type: " .. type(M))
        
        -- Check if setup function exists
        if type(M.setup) == "function" then
            print("    ✅ Setup function exists")
        else
            print("    ❌ Setup function not found")
            return false
        end
    else
        print("    ❌ Failed to load plugin module: " .. tostring(M))
        return false
    end
    
    return true
end

-- Test 2: Test plugin setup
local function test_plugin_setup()
    print("=== Test 2: Plugin Setup ===")
    
    print("  📝 Testing plugin setup...")
    
    local M = require("paragonic")
    
    -- Test setup function
    local start_time = vim.loop.hrtime() / 1000000
    local success = pcall(M.setup)
    local end_time = vim.loop.hrtime() / 1000000
    local duration = end_time - start_time
    
    print("    Setup execution time: " .. string.format("%.2f", duration) .. "ms")
    
    if success then
        print("    ✅ Plugin setup completed successfully")
        
        if duration > 5000 then
            print("    ⚠️  WARNING: Setup took more than 5 seconds - potential blocking!")
            return false
        else
            print("    ✅ Setup completed within reasonable time")
            return true
        end
    else
        print("    ❌ Plugin setup failed")
        return false
    end
end

-- Test 3: Test plugin functionality
local function test_plugin_functionality()
    print("=== Test 3: Plugin Functionality ===")
    
    print("  📝 Testing plugin functionality...")
    
    local M = require("paragonic")
    
    -- Test key functions
    local functions_to_test = {
        "open_chat",
        "search",
        "filtered_search", 
        "hybrid_search",
        "open_projects",
        "open_config"
    }
    
    for _, func_name in ipairs(functions_to_test) do
        if type(M[func_name]) == "function" then
            print("    ✅ " .. func_name .. " function exists")
        else
            print("    ❌ " .. func_name .. " function not found")
        end
    end
    
    -- Test RPC client
    local rpc_client = M._get_rpc_client()
    if rpc_client then
        print("    ✅ RPC client is available")
    else
        print("    📝 RPC client not available (may be initialized later)")
    end
    
    return true
end

-- Test 4: Test deferred loading
local function test_deferred_loading()
    print("=== Test 4: Deferred Loading ===")
    
    print("  📝 Testing deferred loading...")
    
    local deferred_called = false
    local start_time = vim.loop.hrtime() / 1000000
    
    -- Simulate the deferred setup from AstroNvim config
    vim.defer_fn(function()
        deferred_called = true
        local current_time = vim.loop.hrtime() / 1000000
        local delay = current_time - start_time
        print("    ⏰ Deferred setup called after: " .. string.format("%.2f", delay) .. "ms")
        
        -- Test setup in deferred context
        local M = require("paragonic")
        local setup_success = pcall(M.setup)
        if setup_success then
            print("    ✅ Deferred setup completed successfully")
        else
            print("    ❌ Deferred setup failed")
        end
    end, 100)
    
    -- Wait for deferred function
    vim.wait(200, function()
        return deferred_called
    end)
    
    if deferred_called then
        print("    ✅ Deferred loading is working correctly")
        return true
    else
        print("    ❌ Deferred loading issue detected")
        return false
    end
end

-- Test 5: Test memory usage after loading
local function test_memory_after_loading()
    print("=== Test 5: Memory Usage After Loading ===")
    
    print("  📝 Testing memory usage after plugin loading...")
    
    -- Measure memory before
    local mem_before = collectgarbage("count")
    print("    Memory before: " .. string.format("%.2f", mem_before) .. " KB")
    
    -- Load and setup plugin
    local M = require("paragonic")
    local success = pcall(M.setup)
    
    -- Measure memory after
    local mem_after = collectgarbage("count")
    local mem_diff = mem_after - mem_before
    
    print("    Memory after: " .. string.format("%.2f", mem_after) .. " KB")
    print("    Memory difference: " .. string.format("%.2f", mem_diff) .. " KB")
    
    if success then
        print("    ✅ Plugin loaded successfully")
        
        if mem_diff > 5000 then
            print("    ⚠️  WARNING: High memory usage after loading!")
            return false
        else
            print("    ✅ Memory usage is reasonable")
            return true
        end
    else
        print("    ❌ Plugin loading failed")
        return false
    end
end

-- Main test execution
print("=== Plugin Loading Test ===")
print("Testing plugin loading and setup to identify freezing issues...")

local tests = {
    test_plugin_loading,
    test_plugin_setup,
    test_plugin_functionality,
    test_deferred_loading,
    test_memory_after_loading
}

local passed = 0
local total = #tests

for i, test in ipairs(tests) do
    print("\n--- Running Test " .. i .. "/" .. total .. " ---")
    local success = test()
    if success then
        passed = passed + 1
    end
end

print("\n=== Test Results ===")
print("Passed: " .. passed .. "/" .. total)

if passed == total then
    print("✅ All plugin loading tests passed!")
    print("The plugin should load correctly without freezing.")
else
    print("❌ Some plugin loading tests failed.")
    print("This may indicate the source of the freezing issue.")
end

print("\n=== Recommendations ===")
if passed == total then
    print("• Plugin loading is working correctly")
    print("• The freezing may be caused by:")
    print("  - AstroNvim startup sequence conflicts")
    print("  - Other plugins interfering during startup")
    print("  - System resource constraints")
    print("  - Plugin loading order issues")
    print("• Try starting Neovim with minimal configuration:")
    print("  nvim --clean -c 'source ~/.config/nvim/lua/plugins/user.lua'")
else
    print("• Plugin loading issues detected")
    print("• These should be addressed to prevent freezing")
end 