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

-- Run the test
test_paragonic_setup() 