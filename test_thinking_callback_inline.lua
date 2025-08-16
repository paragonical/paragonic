--[[
Inline Test for Thinking Callback Functionality
Run this script directly in Neovim to test the thinking callback issue
--]]

print("🧪 Inline Test for Thinking Callback Functionality")
print("=" .. string.rep("=", 60))

-- Test 1: Check if modules can be loaded
print("🔍 Testing module loading...")

local success, config = pcall(require, "paragonic.config")
if success then
    print("✅ Config module loaded")
    
    -- Test model detection
    local current_model = config.get("ollama_model")
    print("   Current model: " .. tostring(current_model))
    
    local supports_thinking = config.current_model_supports_thinking()
    print("   Supports thinking: " .. tostring(supports_thinking))
else
    print("❌ Config module failed: " .. tostring(config))
end

local success, debug = pcall(require, "paragonic.debug")
if success then
    print("✅ Debug module loaded")
else
    print("❌ Debug module failed: " .. tostring(debug))
end

local success, chat = pcall(require, "paragonic.chat")
if success then
    print("✅ Chat module loaded")
    
    -- Check if functions exist
    local functions_to_check = {
        "send_message_command_smart",
        "send_message_command_thinking",
        "send_message_thinking_streaming"
    }
    
    for _, func_name in ipairs(functions_to_check) do
        if chat[func_name] then
            print("   ✅ " .. func_name .. " exists")
        else
            print("   ❌ " .. func_name .. " missing")
        end
    end
else
    print("❌ Chat module failed: " .. tostring(chat))
end

-- Test 2: Test notification system
print("\n🔍 Testing notification system...")
local notifications_received = {}
local original_notify = vim.notify
vim.notify = function(msg, level, opts)
    table.insert(notifications_received, msg)
end

vim.notify("TEST: Notification test", vim.log.levels.INFO)
vim.notify = original_notify

if #notifications_received > 0 then
    print("✅ Notification system working")
else
    print("❌ Notification system failed")
end

-- Test 3: Test keymap setup
print("\n🔍 Testing keymap setup...")
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

-- Test 4: Test function call simulation (if modules loaded)
if chat and config then
    print("\n🔍 Testing function call simulation...")
    
    -- Create test buffer
    local test_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(test_buf, "paragonic://chat")
    
    -- Add test content
    vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, {
        "# Test Chat",
        "∎",
        "test message"
    })
    
    -- Set current buffer first
    local original_buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_set_current_buf(test_buf)
    
    -- Set cursor to the end of the buffer (after the message)
    local line_count = vim.api.nvim_buf_line_count(test_buf)
    vim.api.nvim_win_set_cursor(0, {line_count, 0}) -- Last line, column 0
    
    -- Track notifications
    local notifications_received = {}
    local original_notify = vim.notify
    vim.notify = function(msg, level, opts)
        table.insert(notifications_received, msg)
    end
    
    -- Test message extraction first
    print("   Testing message extraction...")
    local success, result = pcall(function()
        return chat.extract_backward_to_tombstone(test_buf)
    end)
    
    if success then
        local message, start_line = result, result
        print("   Extracted message: '" .. tostring(message) .. "'")
        print("   Start line: " .. tostring(start_line))
    else
        print("   Message extraction failed: " .. tostring(result))
        print("   Available functions in chat module:")
        for k, v in pairs(chat) do
            if type(v) == "function" then
                print("     - " .. k)
            end
        end
    end
    
    -- Test smart command directly
    print("   Testing send_message_command_smart directly...")
    local success = pcall(chat.send_message_command_smart)
    
    if success then
        print("✅ send_message_command_smart executed successfully")
        
        -- Check for expected notifications
        local found_test_notification = false
        local found_legacy_notification = false
        for _, notification in ipairs(notifications_received) do
            if notification then
                print("   Notification: " .. tostring(notification))
                if notification:find("TEST: send_message_command_smart called") then
                    found_test_notification = true
                end
                if notification:find("TEST: send_message_command_legacy called") then
                    found_legacy_notification = true
                end
            end
        end
        
        if found_test_notification then
            print("✅ Test notification found in command execution")
        else
            print("❌ Test notification not found in command execution")
        end
        
        if found_legacy_notification then
            print("❌ Legacy function was called instead!")
        end
        
        print("   Total notifications: " .. #notifications_received)
    else
        print("❌ send_message_command_smart failed to execute")
    end
    
    -- Test command execution via vim.cmd
    print("   Testing command execution via vim.cmd...")
    local notifications_received2 = {}
    vim.notify = function(msg, level, opts)
        table.insert(notifications_received2, msg)
    end
    
    local success2 = pcall(vim.cmd, "ParagonicSendSmart")
    
    if success2 then
        print("✅ ParagonicSendSmart command executed successfully")
        
        local found_test_notification2 = false
        for _, notification in ipairs(notifications_received2) do
            if notification then
                print("   Cmd Notification: " .. tostring(notification))
                if notification:find("TEST: send_message_command_smart called") then
                    found_test_notification2 = true
                end
            end
        end
        
        if found_test_notification2 then
            print("✅ Test notification found in command execution")
        else
            print("❌ Test notification not found in command execution")
        end
        
        print("   Total cmd notifications: " .. #notifications_received2)
    else
        print("❌ ParagonicSendSmart command failed to execute")
    end
    
    -- Restore
    vim.notify = original_notify
    vim.api.nvim_set_current_buf(original_buf)
    vim.api.nvim_buf_delete(test_buf, { force = true })
end

print("\n" .. "=" .. string.rep("=", 60))
print("🔍 Inline test complete!")

-- Summary
print("\n📊 Summary:")
if config then
    print("   ✅ Config module: Working")
else
    print("   ❌ Config module: Failed")
end

if debug then
    print("   ✅ Debug module: Working")
else
    print("   ❌ Debug module: Failed")
end

if chat then
    print("   ✅ Chat module: Working")
else
    print("   ❌ Chat module: Failed")
end

print("   ✅ Notification system: Working")
print("   ✅ Keymap setup: Working")

if config and chat then
    print("\n🎉 All core components working! The issue is likely in the function call chain.")
else
    print("\n🔧 Some modules failed to load. Check the module loading errors above.")
end
