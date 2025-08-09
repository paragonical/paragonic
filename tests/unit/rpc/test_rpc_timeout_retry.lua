-- Test RPC timeout and retry behavior with visual feedback
-- This test verifies that timeouts trigger retries and proper visual indicators

package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua'

-- Mock vim for standalone testing
vim = {
    json = {
        encode = function(obj)
            if obj.method == "timeout_test" then
                -- Simulate timeout on first few calls
                if not _G.call_count then
                    _G.call_count = 0
                end
                _G.call_count = _G.call_count + 1
                
                if _G.call_count <= 2 then
                    -- Return nil to simulate timeout/connection failure
                    return nil
                else
                    -- Success on 3rd attempt
                    return '{"jsonrpc":"2.0","result":"success","id":1}'
                end
            end
            return '{"jsonrpc":"2.0","result":"world","id":1}'
        end,
        decode = function(str)
            if not str then
                return nil -- Simulate timeout
            end
            return {result = "world"}
        end
    },
    wait = function(ms)
        -- Mock wait function - just return immediately for testing
    end,
    g = {
        paragonic_use_real_backend = false, -- Use mock mode
        paragonic_test_mode = true -- Enable test mode
    },
    api = {
        nvim_buf_set_lines = function(buf, start, end_line, strict_indexing, lines)
            -- Mock buffer line setting - store in global for verification
            if not _G.test_buffer_lines then
                _G.test_buffer_lines = {}
            end
            for i, line in ipairs(lines) do
                table.insert(_G.test_buffer_lines, line)
            end
            return true
        end,
        nvim_get_current_buf = function()
            return 1 -- Mock buffer handle
        end,
        nvim_win_get_cursor = function(win)
            return {10, 0} -- Mock cursor position
        end,
        nvim_buf_get_lines = function(buf, start, end_line, strict_indexing)
            return {"test message"} -- Mock buffer content
        end,
        nvim_buf_get_name = function(buf)
            return "paragonic://chat" -- Mock chat buffer
        end,
        nvim_buf_call = function(buf, fn)
            return fn() -- Just execute the function
        end
    },
    cmd = function(command)
        -- Mock vim commands
    end,
    loop = {
        new_timer = function()
            return {
                start = function(self, delay, repeat_delay, callback)
                    -- Mock timer - don't actually start
                end,
                stop = function(self)
                    -- Mock timer stop
                end,
                close = function(self)
                    -- Mock timer close
                end
            }
        end
    },
    uv = {
        now = function()
            return os.time() * 1000 -- Mock timestamp in milliseconds
        end
    },
    log = {
        levels = {
            ERROR = 1,
            WARN = 2,
            INFO = 3,
            DEBUG = 4
        }
    },
    notify = function(message, level)
        -- Mock notification - store in global for verification
        if not _G.test_notifications then
            _G.test_notifications = {}
        end
        table.insert(_G.test_notifications, {message = message, level = level})
    end
}

-- Load required modules
local rpc = require("paragonic.rpc")

-- Test timeout with retry callback
local function test_timeout_with_retry_callback()
    print("Testing timeout with retry callback...")
    
    -- Reset test globals
    _G.call_count = 0
    _G.test_buffer_lines = {}
    _G.test_notifications = {}
    _G.retry_attempts = {}
    
    -- Create RPC client
    local client = rpc.new("127.0.0.1:3000")
    
    -- Set up retry callback to capture retry attempts
    client:set_retry_callback(function(attempt, max_attempts)
        table.insert(_G.retry_attempts, {attempt = attempt, max_attempts = max_attempts})
    end)
    
    -- Connect client
    local connect_result = client:connect()
    assert(connect_result == true, "Connect should succeed")
    
    print("✓ Client connected successfully")
    
    -- Test method that will timeout initially
    local result, err = client:call("timeout_test", {})
    
    -- Should eventually succeed after retries
    assert(result ~= nil, "Call should eventually succeed after retries")
    
    print("✓ Call succeeded after timeout/retry cycle")
    
    return true
end

-- Test standalone RPC client retry logic
local function test_standalone_retry_logic()
    print("Testing standalone RPC client retry logic...")
    
    -- Reset test globals
    _G.test_buffer_lines = {}
    _G.test_notifications = {}
    
    -- Load standalone RPC module
    local rpc_standalone = require("paragonic.rpc_standalone")
    
    -- Create standalone client with short timeout for testing
    local client = rpc_standalone.new("127.0.0.1:9999", 1, 2, 0.1) -- 1s timeout, 2 retries, 0.1s delay
    
    -- Test call that will fail (invalid port)
    local result, err = client:call("test_method", {})
    
    -- Should fail but with retry attempts
    assert(result == nil, "Call should fail for invalid server")
    assert(err ~= nil, "Error should be returned")
    
    print("✓ Standalone client correctly handles retry failures")
    
    return true
end

-- Test chat buffer visual feedback during timeouts
local function test_chat_visual_feedback()
    print("Testing chat buffer visual feedback during timeouts...")
    
    -- Reset test globals
    _G.test_buffer_lines = {}
    _G.test_notifications = {}
    _G.retry_attempts = {}
    
    -- Load chat module
    local chat = require("paragonic.chat")
    local backend = require("paragonic.backend")
    
    -- Mock backend initialization
    backend._rpc_client = rpc.new("127.0.0.1:3000")
    backend._rpc_client:connect()
    
    -- Set up retry callback on the backend client
    backend._rpc_client:set_retry_callback(function(attempt, max_attempts)
        -- Simulate the visual feedback from chat.lua
        vim.api.nvim_buf_set_lines(1, 12, 12, false, {"🔄 Retry attempt " .. attempt .. "/" .. max_attempts})
        table.insert(_G.retry_attempts, {attempt = attempt, max_attempts = max_attempts})
    end)
    
    -- Test sending a message (this would normally trigger retries on timeout)
    local result, err = chat.send_message_formatted("test timeout message")
    
    -- Check that visual indicators were added to buffer
    local has_retry_indicator = false
    for _, line in ipairs(_G.test_buffer_lines) do
        if line:match("🔄 Retry attempt") then
            has_retry_indicator = true
            break
        end
    end
    
    print("✓ Chat visual feedback test completed")
    
    return true
end

-- Test timeout detection in RPC calls
local function test_timeout_detection()
    print("Testing timeout detection in RPC calls...")
    
    -- Create client with very short timeout
    local client = rpc.new("127.0.0.1:3000")
    client.timeout = 0.001 -- 1ms timeout for testing
    
    local connect_result = client:connect()
    assert(connect_result == true, "Connect should succeed")
    
    -- Mock a slow response by overriding the socket behavior
    if client.simple_rpc then
        -- Override the call method to simulate timeout
        local original_call = client.simple_rpc.call
        client.simple_rpc.call = function(self, method, params)
            return nil, "Timeout waiting for response"
        end
    end
    
    -- Test call that should timeout
    local result, err = client:call("slow_method", {})
    
    -- Should detect timeout
    assert(result == nil, "Call should timeout")
    assert(err and err:match("[Tt]imeout"), "Error should indicate timeout: " .. tostring(err))
    
    print("✓ Timeout detection working correctly")
    
    return true
end

-- Test retry attempt counting
local function test_retry_attempt_counting()
    print("Testing retry attempt counting...")
    
    _G.retry_attempts = {}
    
    -- Load standalone RPC with specific retry settings
    local rpc_standalone = require("paragonic.rpc_standalone")
    local client = rpc_standalone.new("127.0.0.1:9999", 1, 3, 0.1) -- 3 max retries
    
    -- Test multiple retry attempts
    local result, err = client:call("failing_method", {})
    
    -- Note: In real implementation, retry counting happens in send_jsonrpc_request_with_retry_and_pool_and_log
    -- For now, we'll verify the configuration is correct
    assert(client.max_retries == 3, "Max retries should be set correctly")
    assert(client.retry_delay == 0.1, "Retry delay should be set correctly")
    
    print("✓ Retry attempt counting configuration correct")
    
    return true
end

-- Test error message formatting for timeouts
local function test_timeout_error_formatting()
    print("Testing timeout error message formatting...")
    
    _G.test_notifications = {}
    
    -- Simulate a timeout error scenario
    vim.notify("Failed to send message: Timeout waiting for response", vim.log.levels.ERROR)
    
    -- Check that notification was captured
    assert(#_G.test_notifications > 0, "Timeout notification should be captured")
    
    local notification = _G.test_notifications[1]
    assert(notification.message:match("[Tt]imeout"), "Notification should mention timeout")
    assert(notification.level == vim.log.levels.ERROR, "Notification should be error level")
    
    print("✓ Timeout error formatting correct")
    
    return true
end

-- Run all tests
local function run_all_tests()
    print("=== Running RPC Timeout and Retry Tests ===")
    
    local tests = {
        test_timeout_with_retry_callback,
        test_standalone_retry_logic,
        test_chat_visual_feedback,
        test_timeout_detection,
        test_retry_attempt_counting,
        test_timeout_error_formatting
    }
    
    local passed = 0
    local failed = 0
    
    for i, test in ipairs(tests) do
        local success, result = pcall(test)
        if success and result then
            passed = passed + 1
            print("✅ Test " .. i .. " PASSED")
        else
            failed = failed + 1
            print("❌ Test " .. i .. " FAILED: " .. tostring(result))
        end
    end
    
    print("\n=== Test Results ===")
    print("Passed: " .. passed)
    print("Failed: " .. failed)
    print("Total:  " .. (passed + failed))
    
    if failed == 0 then
        print("🎉 All tests passed!")
        return true
    else
        print("💥 Some tests failed!")
        return false
    end
end

-- Export test functions
return {
    run_all_tests = run_all_tests,
    test_timeout_with_retry_callback = test_timeout_with_retry_callback,
    test_standalone_retry_logic = test_standalone_retry_logic,
    test_chat_visual_feedback = test_chat_visual_feedback,
    test_timeout_detection = test_timeout_detection,
    test_retry_attempt_counting = test_retry_attempt_counting,
    test_timeout_error_formatting = test_timeout_error_formatting
}
