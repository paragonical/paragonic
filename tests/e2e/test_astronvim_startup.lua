-- Test AstroNvim Startup Issues
-- This test should be run within Neovim using :source test_astronvim_startup.lua

-- Test 1: Check if we're in AstroNvim
local function test_astronvim_environment()
    print("=== Test 1: AstroNvim Environment ===")
    
    print("  📝 Checking AstroNvim environment...")
    
    -- Check if we're in AstroNvim
    local is_astronvim = pcall(require, "astronvim")
    print("    AstroNvim available: " .. tostring(is_astronvim))
    
    -- Check if lazy.nvim is available
    local is_lazy = pcall(require, "lazy")
    print("    Lazy.nvim available: " .. tostring(is_lazy))
    
    -- Check if we're in a full AstroNvim session
    if is_astronvim then
        print("    ✅ Running in AstroNvim environment")
        return true
    else
        print("    📝 Not in AstroNvim environment")
        return false
    end
end

-- Test 2: Check plugin loading order
local function test_plugin_loading_order()
    print("=== Test 2: Plugin Loading Order ===")
    
    print("  📝 Checking plugin loading order...")
    
    -- Check if lazy.nvim is managing plugins
    local success, lazy = pcall(require, "lazy")
    if success then
        print("    ✅ Lazy.nvim is managing plugins")
        
        -- Get plugin list
        local plugins = lazy.plugins()
        print("    📦 Total plugins loaded: " .. #plugins)
        
        -- Look for our plugin
        local our_plugin = nil
        for _, plugin in ipairs(plugins) do
            if plugin.name == "paragonic" then
                our_plugin = plugin
                break
            end
        end
        
        if our_plugin then
            print("    ✅ Paragonic plugin found in lazy.nvim")
            print("    📋 Plugin config:")
            print("      - Lazy: " .. tostring(our_plugin.lazy))
            print("      - Event: " .. tostring(our_plugin.event))
            print("      - Priority: " .. tostring(our_plugin.priority))
        else
            print("    ❌ Paragonic plugin not found in lazy.nvim")
        end
    else
        print("    ❌ Lazy.nvim not available")
    end
    
    return true
end

-- Test 3: Test plugin loading in AstroNvim context
local function test_astronvim_plugin_loading()
    print("=== Test 3: AstroNvim Plugin Loading ===")
    
    print("  📝 Testing plugin loading in AstroNvim context...")
    
    -- Try to load our plugin
    local start_time = vim.loop.hrtime() / 1000000
    local success, M = pcall(require, "paragonic")
    local end_time = vim.loop.hrtime() / 1000000
    local duration = end_time - start_time
    
    print("    Plugin load time: " .. string.format("%.2f", duration) .. "ms")
    
    if success then
        print("    ✅ Plugin loaded successfully in AstroNvim")
        
        -- Test setup
        local setup_start = vim.loop.hrtime() / 1000000
        local setup_success = pcall(M.setup)
        local setup_end = vim.loop.hrtime() / 1000000
        local setup_duration = setup_end - setup_start
        
        print("    Setup time: " .. string.format("%.2f", setup_duration) .. "ms")
        
        if setup_success then
            print("    ✅ Plugin setup completed successfully")
            
            if setup_duration > 5000 then
                print("    ⚠️  WARNING: Setup took more than 5 seconds!")
                return false
            else
                print("    ✅ Setup completed within reasonable time")
                return true
            end
        else
            print("    ❌ Plugin setup failed")
            return false
        end
    else
        print("    ❌ Failed to load plugin in AstroNvim: " .. tostring(M))
        return false
    end
end

-- Test 4: Check for conflicting plugins
local function test_conflicting_plugins()
    print("=== Test 4: Conflicting Plugins ===")
    
    print("  📝 Checking for conflicting plugins...")
    
    -- Check for common plugins that might conflict
    local potential_conflicts = {
        "copilot",
        "lsp_signature",
        "presence"
    }
    
    for _, plugin_name in ipairs(potential_conflicts) do
        local success = pcall(require, plugin_name)
        if success then
            print("    ⚠️  Potential conflict: " .. plugin_name .. " is loaded")
        else
            print("    ✅ No conflict: " .. plugin_name .. " not loaded")
        end
    end
    
    -- Check for RPC-related plugins
    local rpc_plugins = {
        "rpc",
        "jsonrpc",
        "neovim_rpc"
    }
    
    for _, plugin_name in ipairs(rpc_plugins) do
        local success = pcall(require, plugin_name)
        if success then
            print("    ⚠️  RPC conflict: " .. plugin_name .. " is loaded")
        end
    end
    
    return true
end

-- Test 5: Test startup timing
local function test_startup_timing()
    print("=== Test 5: Startup Timing ===")
    
    print("  📝 Testing startup timing...")
    
    -- Check when this test is being run
    local startup_time = vim.loop.hrtime() / 1000000
    print("    Current time since startup: " .. string.format("%.2f", startup_time) .. "ms")
    
    -- Test deferred function timing
    local deferred_called = false
    local defer_start = vim.loop.hrtime() / 1000000
    
    vim.defer_fn(function()
        deferred_called = true
        local defer_end = vim.loop.hrtime() / 1000000
        local defer_duration = defer_end - defer_start
        print("    ⏰ Deferred function executed after: " .. string.format("%.2f", defer_duration) .. "ms")
    end, 100)
    
    -- Wait for deferred function
    vim.wait(200, function()
        return deferred_called
    end)
    
    if deferred_called then
        print("    ✅ Deferred function timing is working")
        return true
    else
        print("    ❌ Deferred function timing issue")
        return false
    end
end

-- Test 6: Test memory and performance
local function test_memory_performance()
    print("=== Test 6: Memory and Performance ===")
    
    print("  📝 Testing memory and performance...")
    
    -- Measure memory
    local mem_before = collectgarbage("count")
    print("    Memory usage: " .. string.format("%.2f", mem_before) .. " KB")
    
    -- Test plugin operations
    local M = require("paragonic")
    
    -- Test key functions
    local functions_to_test = {
        "open_chat",
        "open_projects",
        "open_config"
    }
    
    for _, func_name in ipairs(functions_to_test) do
        if type(M[func_name]) == "function" then
            local start_time = vim.loop.hrtime() / 1000000
            local success = pcall(M[func_name])
            local end_time = vim.loop.hrtime() / 1000000
            local duration = end_time - start_time
            
            if success then
                print("    ✅ " .. func_name .. " executed in " .. string.format("%.2f", duration) .. "ms")
            else
                print("    ❌ " .. func_name .. " failed")
            end
        end
    end
    
    -- Measure memory after
    local mem_after = collectgarbage("count")
    local mem_diff = mem_after - mem_before
    print("    Memory difference: " .. string.format("%.2f", mem_diff) .. " KB")
    
    if mem_diff > 1000 then
        print("    ⚠️  WARNING: High memory usage!")
        return false
    else
        print("    ✅ Memory usage is reasonable")
        return true
    end
end

-- Main test execution
print("=== AstroNvim Startup Test ===")
print("Testing AstroNvim startup to identify freezing issues...")

local tests = {
    test_astronvim_environment,
    test_plugin_loading_order,
    test_astronvim_plugin_loading,
    test_conflicting_plugins,
    test_startup_timing,
    test_memory_performance
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
    print("✅ All AstroNvim startup tests passed!")
    print("The plugin should work correctly in AstroNvim.")
else
    print("❌ Some AstroNvim startup tests failed.")
    print("This may indicate the source of the freezing issue.")
end

print("\n=== Recommendations ===")
if passed == total then
    print("• Plugin works correctly in AstroNvim")
    print("• The freezing may be caused by:")
    print("  - Specific AstroNvim configuration")
    print("  - Plugin loading order issues")
    print("  - System resource constraints")
    print("  - Timing issues during startup")
else
    print("• AstroNvim-specific issues detected")
    print("• These should be addressed to prevent freezing")
end 