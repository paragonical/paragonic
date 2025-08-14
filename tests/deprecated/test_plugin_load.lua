-- Test script to check if Paragonic plugin loads
print("=== Testing Paragonic Plugin Load ===")

-- Check if we can find the plugin file
local plugin_path = "lua/paragonic/init.lua"
print("Plugin path:", plugin_path)
print("File exists:", vim.fn.filereadable(plugin_path))

-- Add current directory to Lua path
local current_dir = vim.fn.getcwd()
package.path = package.path .. ";" .. current_dir .. "/lua/?.lua;" .. current_dir .. "/lua/?/init.lua"
print("Added to Lua path:", current_dir .. "/lua/?.lua;" .. current_dir .. "/lua/?/init.lua")

-- Try to load the plugin
print("Attempting to load plugin...")
local ok, result = pcall(require, "paragonic")
print("Load result:", ok)
if not ok then
	print("Error:", result)
end

-- Check if plugin functions are available
if ok and result then
	print("Plugin loaded successfully!")
	print("Available functions:")
	for name, func in pairs(result) do
		if type(func) == "function" then
			print("  - " .. name)
		end
	end
else
	print("Plugin failed to load")
end

print("=== Test Complete ===")
