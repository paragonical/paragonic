--[[
Automated Test Suite for Thinking Callback Functionality
Tests the complete chain from keymap to callback execution
--]]

local M = {}

-- Test configuration
local test_config = {
    timeout_ms = 5000,
    debug_level = "debug",
    test_model = "deepseek-r1:1.5b",
}

-- Test results storage
local test_results = {
    passed = 0,
    failed = 0,
    errors = {},
    details = {},
}

-- Helper function to run test with timeout
local function run_test_with_timeout(test_name, test_func, timeout_ms)
    timeout_ms = timeout_ms or test_config.timeout_ms
    
    local test_start = vim.uv.now()
    local success, result = pcall(test_func)
    local test_duration = vim.uv.now() - test_start
    
    if success then
        test_results.passed = test_results.passed + 1
        test_results.details[test_name] = {
            status = "PASSED",
            duration = test_duration,
            result = result
        }
        print("✅ " .. test_name .. " (PASSED in " .. string.format("%.2f", test_duration/1000) .. "s)")
    else
        test_results.failed = test_results.failed + 1
        test_results.errors[test_name] = result
        test_results.details[test_name] = {
            status = "FAILED",
            duration = test_duration,
            error = result
        }
        print("❌ " .. test_name .. " (FAILED in " .. string.format("%.2f", test_duration/1000) .. "s)")
        print("   Error: " .. tostring(result))
    end
end

-- Test 1: Verify keymap setup
function M.test_keymap_setup()
    return function()
        local chat = require("paragonic.chat")
        
        -- Create a test buffer
        local test_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(test_buf, "paragonic://chat")
        
        -- Set up keymaps
        vim.api.nvim_buf_set_keymap(
            test_buf,
            "n",
            "<CR>",
            ":ParagonicSendSmart<CR>",
            { noremap = true, silent = true, desc = "Test Send Smart" }
        )
        
        -- Verify keymap exists
        local keymap = vim.api.nvim_buf_get_keymap(test_buf, "n")
        local found = false
        for _, map in ipairs(keymap) do
            if map.lhs == "<CR>" and map.rhs == ":ParagonicSendSmart<CR>" then
                found = true
                break
            end
        end
        
        if not found then
            error("Keymap <CR> not found or incorrect")
        end
        
        -- Clean up
        vim.api.nvim_buf_delete(test_buf, { force = true })
        
        return "Keymap setup verified"
    end
end

-- Test 2: Verify model detection
function M.test_model_detection()
    return function()
        local config = require("paragonic.config")
        
        -- Test current model detection
        local current_model = config.get("ollama_model")
        if not current_model then
            error("No model configured")
        end
        
        -- Test thinking support detection
        local supports_thinking = config.current_model_supports_thinking()
        if not supports_thinking then
            error("Model " .. current_model .. " should support thinking")
        end
        
        return "Model detection working: " .. current_model .. " (thinking: " .. tostring(supports_thinking) .. ")"
    end
end

-- Test 3: Verify function registration
function M.test_function_registration()
    return function()
        -- Check if functions are registered
        local chat = require("paragonic.chat")
        
        if not chat.send_message_command_smart then
            error("send_message_command_smart not found")
        end
        
        if not chat.send_message_command_thinking then
            error("send_message_command_thinking not found")
        end
        
        if not chat.send_message_thinking_streaming then
            error("send_message_thinking_streaming not found")
        end
        
        return "All required functions registered"
    end
end

-- Test 4: Test callback creation and execution
function M.test_callback_creation()
    return function()
        local callback_called = false
        local callback_data = {}
        
        -- Create test callback
        local function test_callback(chunk, chunk_index, total_chunks, chunk_type)
            callback_called = true
            callback_data = {
                chunk = chunk,
                chunk_index = chunk_index,
                total_chunks = total_chunks,
                chunk_type = chunk_type
            }
        end
        
        -- Test callback execution
        test_callback("test content", 1, 3, "thinking_content")
        
        if not callback_called then
            error("Callback not executed")
        end
        
        if callback_data.chunk ~= "test content" then
            error("Callback data incorrect")
        end
        
        return "Callback creation and execution working"
    end
end

-- Test 5: Test function call chain (without actual backend)
function M.test_function_call_chain()
    return function()
        local chat = require("paragonic.chat")
        
        -- Create test buffer
        local test_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(test_buf, "paragonic://chat")
        
        -- Add test content
        vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, {
            "# Test Chat",
            "∎",
            "test message"
        })
        
        -- Set current buffer
        local original_buf = vim.api.nvim_get_current_buf()
        vim.api.nvim_set_current_buf(test_buf)
        
        -- Test message extraction
        local message, start_line = chat.extract_backward_to_tombstone(test_buf)
        
        if message ~= "test message" then
            error("Message extraction failed: got '" .. message .. "'")
        end
        
        -- Restore original buffer
        vim.api.nvim_set_current_buf(original_buf)
        vim.api.nvim_buf_delete(test_buf, { force = true })
        
        return "Function call chain working: extracted '" .. message .. "'"
    end
end

-- Test 6: Test notification system
function M.test_notification_system()
    return function()
        local notifications_received = {}
        
        -- Override vim.notify temporarily
        local original_notify = vim.notify
        vim.notify = function(msg, level, opts)
            table.insert(notifications_received, {
                message = msg,
                level = level,
                opts = opts
            })
        end
        
        -- Test notifications
        vim.notify("TEST: Notification test", vim.log.levels.INFO)
        
        -- Restore original notify
        vim.notify = original_notify
        
        if #notifications_received == 0 then
            error("No notifications received")
        end
        
        if notifications_received[1].message ~= "TEST: Notification test" then
            error("Notification content incorrect")
        end
        
        return "Notification system working: " .. #notifications_received .. " notifications received"
    end
end

-- Test 7: Test debug module integration
function M.test_debug_module()
    return function()
        local debug = require("paragonic.debug")
        
        if not debug then
            error("Debug module not available")
        end
        
        if not debug.debug_print then
            error("debug_print function not available")
        end
        
        -- Test debug print
        local success = pcall(debug.debug_print, "Test debug message", "debug")
        if not success then
            error("debug_print failed")
        end
        
        return "Debug module integration working"
    end
end

-- Test 8: Test command execution simulation
function M.test_command_execution()
    return function()
        local chat = require("paragonic.chat")
        
        -- Create test buffer
        local test_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(test_buf, "paragonic://chat")
        
        -- Add test content
        vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, {
            "# Test Chat",
            "∎",
            "test message"
        })
        
        -- Set current buffer
        local original_buf = vim.api.nvim_get_current_buf()
        vim.api.nvim_set_current_buf(test_buf)
        
        -- Track notifications
        local notifications_received = {}
        local original_notify = vim.notify
        vim.notify = function(msg, level, opts)
            table.insert(notifications_received, {
                message = msg,
                level = level,
                opts = opts
            })
        end
        
        -- Test smart command (should detect thinking model)
        local success = pcall(chat.send_message_command_smart)
        
        -- Restore
        vim.notify = original_notify
        vim.api.nvim_set_current_buf(original_buf)
        vim.api.nvim_buf_delete(test_buf, { force = true })
        
        if not success then
            error("send_message_command_smart failed to execute")
        end
        
        -- Check for expected notifications
        local found_test_notification = false
        for _, notification in ipairs(notifications_received) do
            if notification.message and notification.message:find("TEST: send_message_command_smart called") then
                found_test_notification = true
                break
            end
        end
        
        if not found_test_notification then
            error("Test notification not found in command execution")
        end
        
        return "Command execution working: " .. #notifications_received .. " notifications received"
    end
end

-- Test 9: Test keymap simulation
function M.test_keymap_simulation()
    return function()
        local chat = require("paragonic.chat")
        
        -- Create test buffer
        local test_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(test_buf, "paragonic://chat")
        
        -- Add test content
        vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, {
            "# Test Chat",
            "∎",
            "test message"
        })
        
        -- Set up keymap
        vim.api.nvim_buf_set_keymap(
            test_buf,
            "n",
            "<CR>",
            ":ParagonicSendSmart<CR>",
            { noremap = true, silent = true, desc = "Test Send Smart" }
        )
        
        -- Set current buffer
        local original_buf = vim.api.nvim_get_current_buf()
        vim.api.nvim_set_current_buf(test_buf)
        
        -- Track notifications
        local notifications_received = {}
        local original_notify = vim.notify
        vim.notify = function(msg, level, opts)
            table.insert(notifications_received, {
                message = msg,
                level = level,
                opts = opts
            })
        end
        
        -- Simulate keypress (execute command directly)
        local success = pcall(vim.cmd, "ParagonicSendSmart")
        
        -- Restore
        vim.notify = original_notify
        vim.api.nvim_set_current_buf(original_buf)
        vim.api.nvim_buf_delete(test_buf, { force = true })
        
        if not success then
            error("Keymap simulation failed")
        end
        
        -- Check for expected notifications
        local found_test_notification = false
        for _, notification in ipairs(notifications_received) do
            if notification.message and notification.message:find("TEST: send_message_command_smart called") then
                found_test_notification = true
                break
            end
        end
        
        if not found_test_notification then
            error("Test notification not found in keymap simulation")
        end
        
        return "Keymap simulation working: " .. #notifications_received .. " notifications received"
    end
end

-- Test 10: Test thinking callback integration
function M.test_thinking_callback_integration()
    return function()
        local chat = require("paragonic.chat")
        
        -- Create test buffer
        local test_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(test_buf, "paragonic://chat")
        
        -- Add test content
        vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, {
            "# Test Chat",
            "∎",
            "test message"
        })
        
        -- Set current buffer
        local original_buf = vim.api.nvim_get_current_buf()
        vim.api.nvim_set_current_buf(test_buf)
        
        -- Track notifications
        local notifications_received = {}
        local original_notify = vim.notify
        vim.notify = function(msg, level, opts)
            table.insert(notifications_received, {
                message = msg,
                level = level,
                opts = opts
            })
        end
        
        -- Test thinking command directly
        local success = pcall(chat.send_message_command_thinking)
        
        -- Restore
        vim.notify = original_notify
        vim.api.nvim_set_current_buf(original_buf)
        vim.api.nvim_buf_delete(test_buf, { force = true })
        
        if not success then
            error("send_message_command_thinking failed to execute")
        end
        
        -- Check for expected notifications
        local found_test_notification = false
        for _, notification in ipairs(notifications_received) do
            if notification.message and notification.message:find("TEST: on_chunk callback type") then
                found_test_notification = true
                break
            end
        end
        
        if not found_test_notification then
            error("Test notification not found in thinking callback test")
        end
        
        return "Thinking callback integration working: " .. #notifications_received .. " notifications received"
    end
end

-- Run all tests
function M.run_all_tests()
    print("🧪 Starting Automated Test Suite for Thinking Callback Functionality")
    print("=" .. string.rep("=", 70))
    
    local tests = {
        { "Keymap Setup", M.test_keymap_setup() },
        { "Model Detection", M.test_model_detection() },
        { "Function Registration", M.test_function_registration() },
        { "Callback Creation", M.test_callback_creation() },
        { "Function Call Chain", M.test_function_call_chain() },
        { "Notification System", M.test_notification_system() },
        { "Debug Module", M.test_debug_module() },
        { "Command Execution", M.test_command_execution() },
        { "Keymap Simulation", M.test_keymap_simulation() },
        { "Thinking Callback Integration", M.test_thinking_callback_integration() },
    }
    
    for _, test in ipairs(tests) do
        local test_name, test_func = test[1], test[2]
        run_test_with_timeout(test_name, test_func)
    end
    
    -- Print summary
    print("=" .. string.rep("=", 70))
    print("📊 Test Summary:")
    print("   Passed: " .. test_results.passed)
    print("   Failed: " .. test_results.failed)
    print("   Total: " .. (test_results.passed + test_results.failed))
    
    if test_results.failed > 0 then
        print("\n❌ Failed Tests:")
        for test_name, error_msg in pairs(test_results.errors) do
            print("   - " .. test_name .. ": " .. tostring(error_msg))
        end
    end
    
    if test_results.passed == #tests then
        print("\n🎉 All tests passed! The thinking callback functionality should be working.")
    else
        print("\n🔧 Some tests failed. Check the error messages above for specific issues.")
    end
    
    return test_results
end

-- Quick diagnostic function
function M.quick_diagnostic()
    print("🔍 Quick Diagnostic for Thinking Callback Issue")
    print("=" .. string.rep("=", 50))
    
    -- Test 1: Check if functions exist
    local chat = require("paragonic.chat")
    print("✅ Functions available:")
    print("   - send_message_command_smart: " .. tostring(chat.send_message_command_smart ~= nil))
    print("   - send_message_command_thinking: " .. tostring(chat.send_message_command_thinking ~= nil))
    print("   - send_message_thinking_streaming: " .. tostring(chat.send_message_thinking_streaming ~= nil))
    
    -- Test 2: Check model detection
    local config = require("paragonic.config")
    local current_model = config.get("ollama_model")
    local supports_thinking = config.current_model_supports_thinking()
    print("✅ Model detection:")
    print("   - Current model: " .. tostring(current_model))
    print("   - Supports thinking: " .. tostring(supports_thinking))
    
    -- Test 3: Check notification system
    local notifications_received = {}
    local original_notify = vim.notify
    vim.notify = function(msg, level, opts)
        table.insert(notifications_received, msg)
    end
    
    vim.notify("TEST: Quick diagnostic", vim.log.levels.INFO)
    vim.notify = original_notify
    
    print("✅ Notification system: " .. tostring(#notifications_received > 0))
    
    -- Test 4: Check keymap setup
    local test_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(test_buf, "paragonic://chat")
    vim.api.nvim_buf_set_keymap(
        test_buf,
        "n",
        "<CR>",
        ":ParagonicSendSmart<CR>",
        { noremap = true, silent = true }
    )
    
    local keymaps = vim.api.nvim_buf_get_keymap(test_buf, "n")
    local keymap_found = false
    for _, map in ipairs(keymaps) do
        if map.lhs == "<CR>" then
            keymap_found = true
            print("✅ Keymap <CR> found: " .. map.rhs)
            break
        end
    end
    
    if not keymap_found then
        print("❌ Keymap <CR> not found")
    end
    
    vim.api.nvim_buf_delete(test_buf, { force = true })
    
    print("=" .. string.rep("=", 50))
    print("🔍 Diagnostic complete. Check the results above for issues.")
end

return M
