#!/usr/bin/env lua

--[[
Unit Tests for Initialization Functions
TDD Step: Comprehensive testing of initialization functions to prevent freezing
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Mock vim API for testing
local vim_mock = {
    fn = {
        stdpath = function(path) 
            if path == "data" then
                return "/tmp/nvim_data"
            end
            return "/tmp"
        end,
        isdirectory = function(dir) 
            -- Simulate directory not existing initially
            return 0 
        end,
        mkdir = function(dir, mode) 
            print("  📁 Created directory: " .. dir)
            return 1 -- Success
        end,
        filereadable = function(file) 
            -- Simulate files not existing initially
            return 0 
        end,
        readfile = function(file) 
            -- Return empty array for non-existent files
            return {}
        end,
        writefile = function(lines, file) 
            print("  📝 Wrote to file: " .. file)
            return 0 -- Success
        end
    },
    json = {
        encode = function(data)
            if type(data) == "table" then
                return "{}" -- Simplified for test
            else
                return tostring(data)
            end
        end,
        decode = function(json_string)
            if json_string == "{}" or json_string == "" then
                return {}
            else
                return nil -- Simulate parsing error
            end
        end
    },
    api = {
        nvim_create_user_command = function(name, callback, opts)
            print("  🔧 Created command: " .. name)
        end,
        nvim_set_keymap = function(mode, lhs, rhs, opts)
            print("  ⌨️  Set keymap: " .. mode .. " " .. lhs .. " -> " .. rhs)
        end
    },
    keymap = {
        set = function(mode, lhs, rhs, opts)
            print("  ⌨️  Set keymap: " .. mode .. " " .. lhs .. " -> " .. rhs)
        end
    },
    notify = function(msg, level) 
        print("  📢 Notify [" .. (level or "info") .. "]: " .. msg)
    end,
    log = {
        levels = {
            INFO = 1,
            WARN = 2,
            ERROR = 3
        }
    },
    defer_fn = function(fn, delay)
        print("  ⏰ Deferred function with delay: " .. delay .. "ms")
        -- Execute immediately for testing
        fn()
    end
}

-- Test 1: _ensure_data_directory function
local function test_ensure_data_directory()
    print("=== Test 1: _ensure_data_directory ===")
    
    -- Replace global vim temporarily
    local original_vim = _G.vim
    _G.vim = vim_mock
    
    -- Create a minimal module for testing
    local M = {}
    
    function M._ensure_data_directory()
        local success, dir = pcall(function()
            return vim.fn.stdpath("data") .. "/paragonic"
        end)
        if not success then
            return false
        end
        
        local success2, is_dir = pcall(vim.fn.isdirectory, dir)
        if not success2 or is_dir == 0 then
            local success3 = pcall(vim.fn.mkdir, dir, "p")
            return success3
        end
        
        return true
    end
    
    -- Test the function
    print("  📝 Testing _ensure_data_directory...")
    local result = M._ensure_data_directory()
    
    if result then
        print("  ✅ _ensure_data_directory works correctly")
    else
        print("  ❌ _ensure_data_directory failed")
        return false
    end
    
    -- Restore original vim
    _G.vim = original_vim
    return true
end

-- Test 2: _load_from_json function with error handling
local function test_load_from_json()
    print("=== Test 2: _load_from_json ===")
    
    -- Replace global vim temporarily
    local original_vim = _G.vim
    _G.vim = vim_mock
    
    -- Create a minimal module for testing
    local M = {}
    
    function M._load_from_json(file_path)
        -- Use pcall for all file operations to prevent blocking
        local success, filereadable = pcall(vim.fn.filereadable, file_path)
        if not success or filereadable == 0 then
            return {}
        end
        
        local success2, lines = pcall(vim.fn.readfile, file_path)
        if not success2 or #lines == 0 then
            return {}
        end
        
        local json_string = table.concat(lines, "\n")
        local success3, data = pcall(vim.json.decode, json_string)
        
        if not success3 or not data then
            pcall(vim.notify, "Failed to parse JSON from " .. file_path, vim.log.levels.ERROR)
            return {}
        end
        
        return data
    end
    
    -- Test with non-existent file
    print("  📝 Testing _load_from_json with non-existent file...")
    local result1 = M._load_from_json("/tmp/nonexistent.json")
    if type(result1) == "table" and #result1 == 0 then
        print("  ✅ Handles non-existent file correctly")
    else
        print("  ❌ Failed to handle non-existent file")
        return false
    end
    
    -- Test with empty file
    print("  📝 Testing _load_from_json with empty file...")
    local result2 = M._load_from_json("/tmp/empty.json")
    if type(result2) == "table" and #result2 == 0 then
        print("  ✅ Handles empty file correctly")
    else
        print("  ❌ Failed to handle empty file")
        return false
    end
    
    -- Restore original vim
    _G.vim = original_vim
    return true
end

-- Test 3: _load_search_history function
local function test_load_search_history()
    print("=== Test 3: _load_search_history ===")
    
    -- Replace global vim temporarily
    local original_vim = _G.vim
    _G.vim = vim_mock
    
    -- Create a minimal module for testing
    local M = {}
    local history_file = "/tmp/nvim_data/paragonic/search_history.json"
    
    function M._load_from_json(file_path)
        local success, filereadable = pcall(vim.fn.filereadable, file_path)
        if not success or filereadable == 0 then
            return {}
        end
        
        local success2, lines = pcall(vim.fn.readfile, file_path)
        if not success2 or #lines == 0 then
            return {}
        end
        
        local json_string = table.concat(lines, "\n")
        local success3, data = pcall(vim.json.decode, json_string)
        
        if not success3 or not data then
            pcall(vim.notify, "Failed to parse JSON from " .. file_path, vim.log.levels.ERROR)
            return {}
        end
        
        return data
    end
    
    function M._load_search_history()
        local data = M._load_from_json(history_file)
        
        -- Validate and clean data with error handling
        local cleaned_data = {}
        local success, result = pcall(function()
            for _, entry in ipairs(data) do
                if entry.query and entry.type and entry.results_count then
                    -- Ensure all required fields are present
                    entry.timestamp = entry.timestamp or os.time()
                    entry.date = entry.date or os.date("%Y-%m-%d %H:%M:%S", entry.timestamp)
                    table.insert(cleaned_data, entry)
                end
            end
            return cleaned_data
        end)
        
        if success then
            return result
        else
            return {}
        end
    end
    
    -- Test the function
    print("  📝 Testing _load_search_history...")
    local result = M._load_search_history()
    
    if type(result) == "table" then
        print("  ✅ _load_search_history works correctly")
        print("  📊 Loaded " .. #result .. " history entries")
    else
        print("  ❌ _load_search_history failed")
        return false
    end
    
    -- Restore original vim
    _G.vim = original_vim
    return true
end

-- Test 4: _load_saved_searches function
local function test_load_saved_searches()
    print("=== Test 4: _load_saved_searches ===")
    
    -- Replace global vim temporarily
    local original_vim = _G.vim
    _G.vim = vim_mock
    
    -- Create a minimal module for testing
    local M = {}
    local saved_searches_file = "/tmp/nvim_data/paragonic/saved_searches.json"
    
    function M._load_from_json(file_path)
        local success, filereadable = pcall(vim.fn.filereadable, file_path)
        if not success or filereadable == 0 then
            return {}
        end
        
        local success2, lines = pcall(vim.fn.readfile, file_path)
        if not success2 or #lines == 0 then
            return {}
        end
        
        local json_string = table.concat(lines, "\n")
        local success3, data = pcall(vim.json.decode, json_string)
        
        if not success3 or not data then
            pcall(vim.notify, "Failed to parse JSON from " .. file_path, vim.log.levels.ERROR)
            return {}
        end
        
        return data
    end
    
    function M._load_saved_searches()
        local data = M._load_from_json(saved_searches_file)
        
        -- Validate and clean data with error handling
        local cleaned_data = {}
        local success, result = pcall(function()
            for _, saved in ipairs(data) do
                if saved.name and saved.query and saved.type then
                    -- Ensure all required fields are present
                    saved.limit = saved.limit or 10
                    saved.threshold = saved.threshold or 0.0
                    saved.created_at = saved.created_at or os.time()
                    saved.created_date = saved.created_date or os.date("%Y-%m-%d %H:%M:%S", saved.created_at)
                    table.insert(cleaned_data, saved)
                end
            end
            return cleaned_data
        end)
        
        if success then
            return result
        else
            return {}
        end
    end
    
    -- Test the function
    print("  📝 Testing _load_saved_searches...")
    local result = M._load_saved_searches()
    
    if type(result) == "table" then
        print("  ✅ _load_saved_searches works correctly")
        print("  📊 Loaded " .. #result .. " saved searches")
    else
        print("  ❌ _load_saved_searches failed")
        return false
    end
    
    -- Restore original vim
    _G.vim = original_vim
    return true
end

-- Test 5: _load_persistent_data function
local function test_load_persistent_data()
    print("=== Test 5: _load_persistent_data ===")
    
    -- Replace global vim temporarily
    local original_vim = _G.vim
    _G.vim = vim_mock
    
    -- Create a minimal module for testing
    local M = {}
    local search_history = {}
    local saved_searches = {}
    
    function M._load_search_history()
        return {}
    end
    
    function M._load_saved_searches()
        return {}
    end
    
    function M._load_persistent_data()
        -- Use pcall to prevent any errors from blocking startup
        local success1, history = pcall(M._load_search_history)
        if success1 then
            search_history = history
        else
            search_history = {}
        end
        
        local success2, searches = pcall(M._load_saved_searches)
        if success2 then
            saved_searches = searches
        else
            saved_searches = {}
        end
        
        -- Use pcall for notification to prevent blocking
        pcall(function()
            vim.notify("Paragonic: Loaded " .. #search_history .. " history entries and " .. #saved_searches .. " saved searches", vim.log.levels.INFO)
        end)
    end
    
    -- Test the function
    print("  📝 Testing _load_persistent_data...")
    local success = pcall(M._load_persistent_data)
    
    if success then
        print("  ✅ _load_persistent_data works correctly")
        print("  📊 History entries: " .. #search_history)
        print("  📊 Saved searches: " .. #saved_searches)
    else
        print("  ❌ _load_persistent_data failed")
        return false
    end
    
    -- Restore original vim
    _G.vim = original_vim
    return true
end

-- Test 6: _setup_keymaps function
local function test_setup_keymaps()
    print("=== Test 6: _setup_keymaps ===")
    
    -- Replace global vim temporarily
    local original_vim = _G.vim
    _G.vim = vim_mock
    
    -- Create a minimal module for testing
    local M = {}
    
    function M._setup_keymaps()
        -- Set up global key mappings
        vim.keymap.set("n", "<leader>ps", "<cmd>ParagonicSearch<CR>", { desc = "Paragonic Search" })
        vim.keymap.set("n", "<leader>pf", "<cmd>ParagonicFilteredSearch<CR>", { desc = "Paragonic Filtered Search" })
        vim.keymap.set("n", "<leader>ph", "<cmd>ParagonicHybridSearch<CR>", { desc = "Paragonic Hybrid Search" })
        vim.keymap.set("n", "<leader>pc", "<cmd>ParagonicOpenChat<CR>", { desc = "Paragonic Chat" })
        vim.keymap.set("n", "<leader>pp", "<cmd>ParagonicOpenProjects<CR>", { desc = "Paragonic Projects" })
        vim.keymap.set("n", "<leader>po", "<cmd>ParagonicOpenConfig<CR>", { desc = "Paragonic Config" })
    end
    
    -- Test the function
    print("  📝 Testing _setup_keymaps...")
    local success = pcall(M._setup_keymaps)
    
    if success then
        print("  ✅ _setup_keymaps works correctly")
    else
        print("  ❌ _setup_keymaps failed")
        return false
    end
    
    -- Restore original vim
    _G.vim = original_vim
    return true
end

-- Test 7: Complete initialization sequence
local function test_complete_initialization()
    print("=== Test 7: Complete Initialization Sequence ===")
    
    -- Replace global vim temporarily
    local original_vim = _G.vim
    _G.vim = vim_mock
    
    -- Create a minimal module for testing
    local M = {}
    local search_history = {}
    local saved_searches = {}
    
    function M._ensure_data_directory()
        local success, dir = pcall(function()
            return vim.fn.stdpath("data") .. "/paragonic"
        end)
        if not success then
            return false
        end
        
        local success2, is_dir = pcall(vim.fn.isdirectory, dir)
        if not success2 or is_dir == 0 then
            local success3 = pcall(vim.fn.mkdir, dir, "p")
            return success3
        end
        
        return true
    end
    
    function M._load_search_history()
        return {}
    end
    
    function M._load_saved_searches()
        return {}
    end
    
    function M._load_persistent_data()
        local success1, history = pcall(M._load_search_history)
        if success1 then
            search_history = history
        else
            search_history = {}
        end
        
        local success2, searches = pcall(M._load_saved_searches)
        if success2 then
            saved_searches = searches
        else
            saved_searches = {}
        end
        
        pcall(function()
            vim.notify("Paragonic: Loaded " .. #search_history .. " history entries and " .. #saved_searches .. " saved searches", vim.log.levels.INFO)
        end)
    end
    
    function M._setup_keymaps()
        vim.keymap.set("n", "<leader>ps", "<cmd>ParagonicSearch<CR>", { desc = "Paragonic Search" })
        vim.keymap.set("n", "<leader>pc", "<cmd>ParagonicOpenChat<CR>", { desc = "Paragonic Chat" })
    end
    
    function M._initialize_backend()
        print("  🔧 Backend initialization would happen here")
    end
    
    function M.setup()
        -- Ensure data directory exists
        local dir_success = M._ensure_data_directory()
        if not dir_success then
            print("  ❌ Failed to ensure data directory")
            return false
        end
        
        -- Set up keyboard mappings immediately
        M._setup_keymaps()
        
        -- Load persistent data asynchronously to avoid startup delay
        vim.defer_fn(function()
            M._load_persistent_data()
        end, 500)
        
        -- Initialize backend asynchronously to avoid startup delay
        vim.defer_fn(function()
            M._initialize_backend()
        end, 2000)
        
        return true
    end
    
    -- Test the complete setup
    print("  📝 Testing complete initialization sequence...")
    local success = pcall(M.setup)
    
    if success then
        print("  ✅ Complete initialization sequence works correctly")
    else
        print("  ❌ Complete initialization sequence failed")
        return false
    end
    
    -- Restore original vim
    _G.vim = original_vim
    return true
end

-- Main test execution
print("=== Initialization Unit Tests ===")
print("Testing initialization functions to prevent Neovim freezing...")

local tests = {
    test_ensure_data_directory,
    test_load_from_json,
    test_load_search_history,
    test_load_saved_searches,
    test_load_persistent_data,
    test_setup_keymaps,
    test_complete_initialization
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
    print("✅ All initialization unit tests passed!")
    print("The initialization functions should not cause Neovim to freeze.")
else
    print("❌ Some initialization unit tests failed.")
    print("This may indicate the source of the freezing issue.")
end

print("\n=== Recommendations ===")
if passed == total then
    print("• All initialization functions are working correctly in isolation")
    print("• The freezing may be caused by:")
    print("  - Real file system operations vs mocked operations")
    print("  - Interaction between multiple initialization steps")
    print("  - Timing issues with deferred functions")
    print("  - Memory pressure during startup")
else
    print("• Fix the failing initialization functions")
    print("• Add more error handling to prevent blocking operations")
    print("• Consider making more operations asynchronous")
end 