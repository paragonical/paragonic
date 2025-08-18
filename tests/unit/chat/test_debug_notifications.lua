-- Test debug notification configuration
-- Verifies that debug notifications can be disabled while keeping debug buffer functionality

-- Set up Lua path to find paragonic modules
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

local function test_debug_notifications()
	print("🧪 Testing debug notification configuration...")

	-- Load the debug module
	local debug = require("paragonic.debug")
	if not debug then
		print("❌ Failed to load debug module")
		return false
	end

	print("✅ Debug module loaded successfully")

	-- Test initial configuration
	local config = debug.get_debug_config()
	print("📋 Initial config: show_notifications = " .. tostring(config.show_notifications))

	-- Test disabling notifications
	debug.disable_notifications()
	config = debug.get_debug_config()
	print("📋 After disable: show_notifications = " .. tostring(config.show_notifications))

	if config.show_notifications then
		print("❌ Failed to disable notifications")
		return false
	end

	-- Test enabling notifications
	debug.enable_notifications()
	config = debug.get_debug_config()
	print("📋 After enable: show_notifications = " .. tostring(config.show_notifications))

	if not config.show_notifications then
		print("❌ Failed to enable notifications")
		return false
	end

	-- Test configure_debug function
	debug.configure_debug({ show_notifications = false })
	config = debug.get_debug_config()
	print("📋 After configure: show_notifications = " .. tostring(config.show_notifications))

	if config.show_notifications then
		print("❌ Failed to configure notifications")
		return false
	end

	-- Test that debug_print still works (should not show notifications when disabled)
	print("📝 Testing debug_print with notifications disabled...")
	debug.debug_print("Test debug message", "info")

	-- Test that debug buffer is still accessible
	local debug_buf = debug.get_or_create_debug_buffer()
	if not debug_buf then
		print("❌ Failed to get debug buffer")
		return false
	end

	print("✅ Debug buffer accessible: " .. tostring(debug_buf))

	print("✅ Debug notification configuration test passed")
	return true
end

-- Run the test
local success = test_debug_notifications()
if success then
	print("🎉 All debug notification tests passed!")
else
	print("💥 Some debug notification tests failed!")
end

return success
