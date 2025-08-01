--[[
Paragonic Test Suite
Simple test for TDD workflow with nlua
--]]

-- Simple test function that can be run with nlua
local function test_paragonic_setup()
    print("Testing Paragonic setup...")
    
    -- Load the module
    local paragonic = require("paragonic")
    
    -- Test that setup function exists
    assert(type(paragonic.setup) == "function", "setup function should exist")
    
    -- Test that get_config function exists
    assert(type(paragonic.get_config) == "function", "get_config function should exist")
    
    -- Test default configuration
    local config = paragonic.get_config()
    assert(config.ollama_host == "http://localhost:11434", "default ollama_host should be set")
    assert(config.ollama_model == "llama3.2:3b", "default ollama_model should be set")
    
    print("✓ All tests passed!")
end

-- Test that setup creates Neovim commands
local function test_setup_creates_commands()
    print("Testing that setup creates Neovim commands...")
    
    -- Load the module
    local paragonic = require("paragonic")
    
    -- Track if nvim_create_user_command was called
    local command_calls = 0
    local original_create_command = vim.api.nvim_create_user_command
    vim.api.nvim_create_user_command = function(name, callback, opts)
        command_calls = command_calls + 1
        print("  Created command: " .. name)
    end
    
    -- Call setup
    paragonic.setup()
    
    -- Restore original function
    vim.api.nvim_create_user_command = original_create_command
    
    -- Assert that commands were created
    assert(command_calls >= 3, "Should create at least 3 commands (ParagonicChat, ParagonicProjects, ParagonicConfig)")
    
    print("✓ Command creation test passed!")
end

-- Test that commands show appropriate messages
local function test_commands_show_messages()
    print("Testing that commands show appropriate messages...")
    
    -- Load the module
    local paragonic = require("paragonic")
    
    -- Track notify calls
    local notify_calls = {}
    local original_notify = vim.notify
    vim.notify = function(msg, level)
        table.insert(notify_calls, {msg = msg, level = level})
        print("  Notify: " .. msg)
    end
    
    -- Call the command functions directly (skip open_chat since it now creates a buffer)
    paragonic.open_projects()
    paragonic.open_config()
    
    -- Restore original function
    vim.notify = original_notify
    
    -- Assert that appropriate messages were shown
    assert(#notify_calls >= 2, "Should show at least 2 notification messages")
    assert(notify_calls[1].msg:find("not yet implemented"), "Projects should show not implemented message")
    assert(notify_calls[2].msg:find("not yet implemented"), "Config should show not implemented message")
    
    print("✓ Command message test passed!")
end

-- Test that open_chat creates a chat buffer
local function test_open_chat_creates_buffer()
    print("Testing that open_chat creates a chat buffer...")
    
    -- Load the module
    local paragonic = require("paragonic")
    
    -- Track buffer creation
    local buffers_before = vim.api.nvim_list_bufs()
    local original_new_buf = vim.api.nvim_create_buf
    local created_buffers = {}
    
    vim.api.nvim_create_buf = function(listed, scratch)
        local buf = original_new_buf(listed, scratch)
        table.insert(created_buffers, buf)
        return buf
    end
    
    -- Call open_chat
    paragonic.open_chat()
    
    -- Restore original function
    vim.api.nvim_create_buf = original_new_buf
    
    -- Assert that a buffer was created
    assert(#created_buffers > 0, "open_chat should create at least one buffer")
    
    -- Check if the buffer has the right name
    local chat_buffer = created_buffers[1]
    local buf_name = vim.api.nvim_buf_get_name(chat_buffer)
    assert(buf_name:find("paragonic") or buf_name:find("chat"), "Chat buffer should have appropriate name")
    
    print("✓ Chat buffer creation test passed!")
end

-- Test that chat buffer has correct initial content
local function test_chat_buffer_content()
    print("Testing that chat buffer has correct initial content...")
    
    -- Load the module
    local paragonic = require("paragonic")
    
    -- Call open_chat to create buffer
    paragonic.open_chat()
    
    -- Get the current buffer (should be the chat buffer)
    local buf = vim.api.nvim_get_current_buf()
    
    -- Get buffer content
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    
    -- Assert that content is correct
    assert(lines[1] == "# Paragonic Chat", "First line should be header")
    assert(lines[3] == "Type your message below and press Enter to send:", "Should have instructions")
    assert(lines[5] == "---", "Should have separator")
    
    -- Check buffer options
    local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
    local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
    
    assert(buftype == "nofile", "Buffer should be nofile type")
    assert(filetype == "markdown", "Buffer should have markdown filetype")
    
    print("✓ Chat buffer content test passed!")
end

-- Test that chat buffer can handle user input
local function test_chat_buffer_input()
    print("Testing that chat buffer can handle user input...")
    
    -- Load the module
    local paragonic = require("paragonic")
    
    -- Call open_chat to create buffer
    paragonic.open_chat()
    
    -- Get the current buffer
    local buf = vim.api.nvim_get_current_buf()
    
    -- Add a user message to the buffer
    local user_message = "Hello, can you help me with this code?"
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"", "**User:** " .. user_message})
    
    -- Get updated content
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    
    -- Assert that user message was added
    local last_line = lines[#lines]
    assert(last_line:find(user_message), "User message should be in buffer")
    assert(last_line:find("**User:**"), "User message should be properly formatted")
    
    print("✓ Chat buffer input test passed!")
end

-- Test that chat can send messages to AI and get responses
local function test_chat_ai_response()
    print("Testing that chat can send messages to AI and get responses...")
    
    -- Load the module
    local paragonic = require("paragonic")
    
    -- Call open_chat to create buffer
    paragonic.open_chat()
    
    -- Get the current buffer
    local buf = vim.api.nvim_get_current_buf()
    
    -- Add a user message
    local user_message = "What is 2+2?"
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"", "**User:** " .. user_message})
    
    -- Call send_message function (we'll implement this)
    local success = paragonic.send_chat_message(user_message)
    
    -- Assert that send was successful
    assert(success, "send_chat_message should return true on success")
    
    -- Get updated content to check for AI response
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    
    -- Look for AI response in the buffer
    local has_ai_response = false
    for _, line in ipairs(lines) do
        if line:find("**AI:**") then
            has_ai_response = true
            break
        end
    end
    
    assert(has_ai_response, "Buffer should contain AI response")
    
    print("✓ Chat AI response test passed!")
end

-- Test that AI response is dynamic based on user message
local function test_chat_dynamic_response()
    print("Testing that AI response is dynamic based on user message...")
    
    -- Load the module
    local paragonic = require("paragonic")
    
    -- Create a fresh buffer for this test
    local buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(buf, "paragonic://test-chat")
    vim.api.nvim_set_current_buf(buf)
    
    -- Add initial content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "# Test Chat",
        "",
        "---"
    })
    
    -- Add a different user message
    local user_message = "What is the capital of France?"
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"", "**User:** " .. user_message})
    
    -- Call send_message function
    local success = paragonic.send_chat_message(user_message)
    
    -- Assert that send was successful
    assert(success, "send_chat_message should return true on success")
    
    -- Get updated content to check for AI response
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    
    -- Look for AI response in the buffer
    local ai_response = ""
    for _, line in ipairs(lines) do
        if line:find("**AI:**") then
            ai_response = line:gsub("**AI:** ", "")
            break
        end
    end
    

    
    -- Assert that response is different from the hardcoded one
    assert(ai_response ~= "**AI:** 2+2 equals 4. This is a basic arithmetic operation.", 
           "AI response should be dynamic, not hardcoded")
    assert(ai_response:find("France") or ai_response:find("Paris"), 
           "AI response should be relevant to the question about France")
    
    print("✓ Chat dynamic response test passed!")
end

-- Test that chat connects to Rust backend
local function test_chat_rust_backend_connection()
    print("Testing that chat connects to Rust backend...")
    
    -- Load the module
    local paragonic = require("paragonic")
    
    -- Create a fresh buffer for this test
    local buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(buf, "paragonic://test-rust")
    vim.api.nvim_set_current_buf(buf)
    
    -- Add initial content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "# Test Rust Backend",
        "",
        "---"
    })
    
    -- Add a user message
    local user_message = "Explain Rust ownership"
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"", "**User:** " .. user_message})
    
    -- Call send_message function with Rust backend flag
    local success = paragonic.send_chat_message_rust(user_message)
    
    -- Assert that send was successful
    assert(success, "send_chat_message_rust should return true on success")
    
    -- Get updated content to check for AI response
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    
    -- Look for AI response in the buffer
    local has_ai_response = false
    for _, line in ipairs(lines) do
        if line:find("**AI:**") then
            has_ai_response = true
            break
        end
    end
    
    assert(has_ai_response, "Buffer should contain AI response from Rust backend")
    
    print("✓ Chat Rust backend connection test passed!")
end

-- Test that Rust backend actually calls Ollama
local function test_chat_ollama_integration()
    print("Testing that Rust backend actually calls Ollama...")
    
    -- Load the module
    local paragonic = require("paragonic")
    
    -- Create a fresh buffer for this test
    local buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(buf, "paragonic://test-ollama")
    vim.api.nvim_set_current_buf(buf)
    
    -- Add initial content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "# Test Ollama Integration",
        "",
        "---"
    })
    
    -- Add a user message that should trigger Ollama
    local user_message = "Write a Python function to calculate fibonacci numbers"
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"", "**User:** " .. user_message})
    
    -- Call send_message function with real Ollama integration
    local success = paragonic.send_chat_message_ollama(user_message)
    
    -- Assert that send was successful
    assert(success, "send_chat_message_ollama should return true on success")
    
    -- Get updated content to check for AI response
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    
    -- Look for AI response in the buffer
    local has_ai_response = false
    local ai_response = ""
    for _, line in ipairs(lines) do
        if line:find("**AI:**") then
            has_ai_response = true
            ai_response = line:gsub("**AI:** ", "")
            break
        end
    end
    
    assert(has_ai_response, "Buffer should contain AI response from Ollama")
    assert(ai_response:find("def") or ai_response:find("function") or ai_response:find("fibonacci"), 
           "Ollama response should contain Python code or fibonacci reference")
    
    print("✓ Chat Ollama integration test passed!")
end

-- Test that chat calls actual Rust backend functions
local function test_chat_real_rust_backend()
    print("Testing that chat calls actual Rust backend functions...")
    
    -- Load the module
    local paragonic = require("paragonic")
    
    -- Create a fresh buffer for this test
    local buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(buf, "paragonic://test-real-rust")
    vim.api.nvim_set_current_buf(buf)
    
    -- Add initial content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "# Test Real Rust Backend",
        "",
        "---"
    })
    
    -- Add a user message
    local user_message = "What is the weather like today?"
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"", "**User:** " .. user_message})
    
    -- Call send_message function with real Rust backend
    local success = paragonic.send_chat_message_real_rust(user_message)
    
    -- Assert that send was successful
    assert(success, "send_chat_message_real_rust should return true on success")
    
    -- Get updated content to check for AI response
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    
    -- Look for AI response in the buffer
    local has_ai_response = false
    for _, line in ipairs(lines) do
        if line:find("**AI:**") then
            has_ai_response = true
            break
        end
    end
    
    assert(has_ai_response, "Buffer should contain AI response from real Rust backend")
    
    print("✓ Chat real Rust backend test passed!")
end

-- Test that chat actually calls Rust backend via RPC
local function test_chat_rpc_integration()
    print("Testing that chat actually calls Rust backend via RPC...")
    
    -- Load the module
    local paragonic = require("paragonic")
    
    -- Create a fresh buffer for this test
    local buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(buf, "paragonic://test-rpc")
    vim.api.nvim_set_current_buf(buf)
    
    -- Add initial content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "# Test RPC Integration",
        "",
        "---"
    })
    
    -- Add a user message
    local user_message = "Write a simple Rust function"
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"", "**User:** " .. user_message})
    
    -- Call send_message function with RPC integration
    local success = paragonic.send_chat_message_rpc(user_message)
    
    -- Assert that send was successful
    assert(success, "send_chat_message_rpc should return true on success")
    
    -- Get updated content to check for AI response
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    
    -- Look for AI response in the buffer
    local has_ai_response = false
    local ai_response = ""
    for _, line in ipairs(lines) do
        if line:find("**AI:**") then
            has_ai_response = true
            ai_response = line:gsub("**AI:** ", "")
            break
        end
    end
    
    assert(has_ai_response, "Buffer should contain AI response from RPC")
    assert(ai_response:find("fn ") or ai_response:find("function") or ai_response:find("Rust"), 
           "RPC response should contain Rust code or function reference")
    
    print("✓ Chat RPC integration test passed!")
end

-- Run all tests
test_paragonic_setup()
test_setup_creates_commands()
test_commands_show_messages()
test_open_chat_creates_buffer()
test_chat_buffer_content()
test_chat_buffer_input()
test_chat_ai_response()
test_chat_dynamic_response()
test_chat_rust_backend_connection()
test_chat_ollama_integration()
test_chat_real_rust_backend()
test_chat_rpc_integration() 