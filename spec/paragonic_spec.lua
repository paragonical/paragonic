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
    
    -- Call the command functions directly
    paragonic.open_chat()
    paragonic.open_projects()
    paragonic.open_config()
    
    -- Restore original function
    vim.notify = original_notify
    
    -- Assert that appropriate messages were shown
    assert(#notify_calls >= 3, "Should show at least 3 notification messages")
    assert(notify_calls[1].msg:find("not yet implemented"), "Chat should show not implemented message")
    assert(notify_calls[2].msg:find("not yet implemented"), "Projects should show not implemented message")
    assert(notify_calls[3].msg:find("not yet implemented"), "Config should show not implemented message")
    
    print("✓ Command message test passed!")
end

-- Run all tests
test_paragonic_setup()
test_setup_creates_commands()
test_commands_show_messages() 