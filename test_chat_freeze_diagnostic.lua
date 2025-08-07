-- Chat Freeze Diagnostic Test
-- Run this in Neovim to identify where the freezing occurs

print("=== Chat Freeze Diagnostic ===")

-- Test 1: Check if we can load the module
print("1. Testing module load...")
local success, M = pcall(require, "paragonic")
if success then
    print("  ✅ Module loaded successfully")
else
    print("  ❌ Module load failed: " .. tostring(M))
    return
end

-- Test 2: Check if we can create a basic buffer
print("2. Testing basic buffer creation...")
local success, buf = pcall(vim.api.nvim_create_buf, true, true)
if success then
    print("  ✅ Basic buffer creation works")
    vim.api.nvim_buf_delete(buf, {force = true})
else
    print("  ❌ Basic buffer creation failed: " .. tostring(buf))
    return
end

-- Test 3: Check if we can get RPC client (without initializing)
print("3. Testing RPC client check...")
local rpc_client = M._get_rpc_client()
if rpc_client then
    print("  ✅ RPC client already available")
else
    print("  📝 RPC client not available (will initialize on first use)")
end

-- Test 4: Test open_chat step by step
print("4. Testing open_chat step by step...")

-- 4a: Check if chat buffer already exists
print("  4a. Checking for existing chat buffer...")
local chat_buf = nil
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if name == "paragonic://chat" then
        chat_buf = buf
        break
    end
end

if chat_buf then
    print("    ✅ Existing chat buffer found")
else
    print("    📝 No existing chat buffer, will create new one")
end

-- 4b: Create new buffer if needed
if not chat_buf then
    print("  4b. Creating new chat buffer...")
    local success, new_buf = pcall(vim.api.nvim_create_buf, true, true)
    if success then
        chat_buf = new_buf
        print("    ✅ Chat buffer created successfully")
    else
        print("    ❌ Chat buffer creation failed: " .. tostring(new_buf))
        return
    end
end

-- 4c: Set buffer name
print("  4c. Setting buffer name...")
local success = pcall(vim.api.nvim_buf_set_name, chat_buf, "paragonic://chat")
if success then
    print("    ✅ Buffer name set successfully")
else
    print("    ❌ Buffer name setting failed")
    return
end

-- 4d: Set buffer options
print("  4d. Setting buffer options...")
local success1 = pcall(vim.api.nvim_buf_set_option, chat_buf, "buftype", "nofile")
local success2 = pcall(vim.api.nvim_buf_set_option, chat_buf, "swapfile", false)
local success3 = pcall(vim.api.nvim_buf_set_option, chat_buf, "modifiable", true)

if success1 and success2 and success3 then
    print("    ✅ Buffer options set successfully")
else
    print("    ❌ Buffer options setting failed")
    return
end

-- 4e: Set initial content
print("  4e. Setting initial content...")
local success = pcall(vim.api.nvim_buf_set_lines, chat_buf, 0, -1, false, {
    "# Paragonic Chat",
    "",
    "Available models: llama2 (default)",
    "",
    "Type your message below and use :ParagonicSend to send:",
    "",
    "---"
})
if success then
    print("    ✅ Initial content set successfully")
else
    print("    ❌ Initial content setting failed")
    return
end

-- 4f: Test deferred models update (this is likely where it freezes)
print("  4f. Testing deferred models update...")
local deferred_called = false
local deferred_success = false

vim.defer_fn(function()
    print("    ⏰ Deferred function called")
    deferred_called = true
    
    -- Test get_available_models without actually calling it
    local success = pcall(function()
        -- Just check if the function exists, don't call it
        if type(M.get_available_models) == "function" then
            print("      ✅ get_available_models function exists")
        else
            print("      ❌ get_available_models function not found")
        end
    end)
    
    if success then
        print("      ✅ Deferred function executed successfully")
        deferred_success = true
    else
        print("      ❌ Deferred function failed")
    end
end, 100)

-- Wait for deferred function
vim.wait(200, function()
    return deferred_called
end)

if deferred_called then
    if deferred_success then
        print("    ✅ Deferred models update test passed")
    else
        print("    ❌ Deferred models update test failed")
    end
else
    print("    ❌ Deferred function never called (timeout)")
end

-- 4g: Set filetype
print("  4g. Setting filetype...")
local success = pcall(vim.api.nvim_buf_set_option, chat_buf, "filetype", "markdown")
if success then
    print("    ✅ Filetype set successfully")
else
    print("    ❌ Filetype setting failed")
end

-- 4h: Set keymaps
print("  4h. Setting keymaps...")
local success1 = pcall(vim.api.nvim_buf_set_keymap, chat_buf, "n", "<CR>", ":ParagonicSend<CR>", {noremap = true, silent = true})
local success2 = pcall(vim.api.nvim_buf_set_keymap, chat_buf, "n", "<leader><CR>", ":ParagonicSendDebug<CR>", {noremap = true, silent = true})

if success1 and success2 then
    print("    ✅ Keymaps set successfully")
else
    print("    ❌ Keymaps setting failed")
end

-- 4i: Open buffer in window
print("  4i. Opening buffer in window...")
local success = pcall(vim.api.nvim_command, "split")
if success then
    print("    ✅ Window split successful")
else
    print("    ❌ Window split failed")
    return
end

local success = pcall(vim.api.nvim_set_current_buf, chat_buf)
if success then
    print("    ✅ Buffer switch successful")
else
    print("    ❌ Buffer switch failed")
    return
end

print("=== Chat Freeze Diagnostic Complete ===")
print("If the test completed successfully, the issue is likely in:")
print("1. The get_available_models() call in the deferred function")
print("2. The backend connection during RPC client initialization")
print("3. The Ollama service response time")

print("\nTo fix the freezing, try:")
print("1. Comment out the deferred get_available_models call")
print("2. Add more timeout handling to backend calls")
print("3. Make backend initialization completely non-blocking") 