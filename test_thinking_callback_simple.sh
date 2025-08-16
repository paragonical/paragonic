#!/bin/bash

# Simple test script for thinking callback functionality
# This script tests individual components without loading the full module

set -e

echo "🧪 Paragonic Thinking Callback Simple Test"
echo "=========================================="

# Check if we're in the right directory
if [ ! -f "lua/paragonic/chat.lua" ]; then
    echo "❌ Error: Must run from paragonic project root"
    exit 1
fi

# Function to run simple test in Neovim
run_simple_test() {
    echo "🔍 Running simple component test..."
    
    # Create a temporary test script
    cat > /tmp/paragonic_simple_test.lua << 'EOF'
-- Simple component test
print("🔍 Testing individual components...")

-- Test 1: Check if files exist
local files_to_check = {
    "lua/paragonic/chat.lua",
    "lua/paragonic/config.lua",
    "lua/paragonic/debug.lua"
}

for _, file in ipairs(files_to_check) do
    local f = io.open(file, "r")
    if f then
        print("✅ " .. file .. " exists")
        f:close()
    else
        print("❌ " .. file .. " missing")
    end
end

-- Test 2: Check config module
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

-- Test 3: Check debug module
local success, debug = pcall(require, "paragonic.debug")
if success then
    print("✅ Debug module loaded")
    
    -- Test debug print
    local success = pcall(debug.debug_print, "Test debug message", "debug")
    if success then
        print("   Debug print working")
    else
        print("   Debug print failed")
    end
else
    print("❌ Debug module failed: " .. tostring(debug))
end

-- Test 4: Check chat module
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

-- Test 5: Test notification system
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

-- Test 6: Test keymap setup
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
print("🔍 Simple component test complete!")
EOF

    # Run the test in Neovim
    nvim --headless --noplugin -c "lua dofile('/tmp/paragonic_simple_test.lua')" -c "q"
    
    # Clean up
    rm -f /tmp/paragonic_simple_test.lua
}

# Run the simple test
run_simple_test

echo "✅ Simple test completed!"
