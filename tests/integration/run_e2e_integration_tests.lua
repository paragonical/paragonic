--[[
Test runner for End-to-End Integration tests
--]]

-- Set up Lua path to find paragonic modules
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

local test_module = require("tests.integration.test_complete_approval_workflow")

-- Run the tests
local success = test_module.run_all_tests()

if success then
	os.exit(0)
else
	os.exit(1)
end
