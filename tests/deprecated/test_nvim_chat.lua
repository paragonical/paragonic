-- Test chat functionality in Neovim
print("Testing chat functionality in Neovim...")

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Load the plugin
local paragonic = require("paragonic")

-- Setup the plugin
paragonic.setup()

-- Test send_message function
print("Testing send_message function...")
local result, err = paragonic.send_message("Hello, this is a test message")
print("Send message result:", result)
print("Send message error:", err)

if result then
	print("✓ Chat functionality is working!")
else
	print("✗ Chat functionality failed:", err)
end

print("=== Neovim Chat Test Complete ===")
