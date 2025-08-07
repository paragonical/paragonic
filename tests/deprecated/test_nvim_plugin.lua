--[[
Test script for Neovim plugin
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Load the plugin
local paragonic = require("paragonic")

-- Setup the plugin
paragonic.setup()

-- Test send_message
print("Testing send_message...")
local result, err = paragonic.send_message("Hello, this is a test message")
print("Result:", result)
print("Error:", err)

print("=== Neovim Plugin Test Complete ===") 