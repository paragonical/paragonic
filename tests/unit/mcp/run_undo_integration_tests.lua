--[[
Test runner for Neovim Undo Integration tests
--]]

-- Set up Lua path to find paragonic modules
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

local test_module = require("tests.unit.mcp.test_neovim_undo_integration")

-- Run the tests
local success = test_module.run_all_tests()

if success then
	os.exit(0)
else
	os.exit(1)
end
