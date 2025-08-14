#!/usr/bin/env lua

-- Quick RPC Test Runner
-- Usage: lua tests/run_rpc_tests.lua

local success, test_module = pcall(require, "tests.unit.rpc.test_rpc_integration")
if not success then
	print("❌ Failed to load test module:", test_module)
	os.exit(1)
end

local test_success = test_module.run_all_tests()
os.exit(test_success and 0 or 1)
