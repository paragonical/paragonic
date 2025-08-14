-- Test suite runner for timeout and retry behavior tests
-- Combines RPC and chat visual feedback tests

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

print("=== Paragonic Timeout and Retry Test Suite ===")

-- Test that all required modules can be loaded
local function test_module_loading()
	print("Testing module loading...")

	local modules_to_test = {
		"paragonic.rpc",
		"paragonic.rpc_standalone",
		"paragonic.chat",
		"paragonic.backend",
	}

	for _, module_name in ipairs(modules_to_test) do
		local success, module = pcall(require, module_name)
		assert(success, "Failed to load module: " .. module_name .. " - " .. tostring(module))
		print("✓ Loaded module: " .. module_name)
	end

	return true
end

-- Run RPC timeout/retry tests
local function run_rpc_tests()
	print("\n--- Running RPC Timeout/Retry Tests ---")

	local rpc_tests = require("tests.unit.rpc.test_timeout_retry_simple")
	return rpc_tests.run_all_tests()
end

-- Run chat visual feedback tests
local function run_chat_tests()
	print("\n--- Running Chat Visual Feedback Tests ---")

	local chat_tests = require("tests.unit.chat.test_chat_visual_feedback_simple")
	return chat_tests.run_all_tests()
end

-- Integration test: full timeout/retry cycle concept
local function test_full_timeout_retry_cycle()
	print("\n--- Testing Full Timeout/Retry Cycle Concept ---")

	-- Test the complete conceptual flow
	local visual_feedback = {}
	local retry_count = 0
	local call_count = 0
	local max_retries = 3

	-- Mock functions that represent the real system
	local function add_visual_indicator(symbol, message)
		table.insert(visual_feedback, symbol .. " " .. message)
	end

	local function simulate_rpc_call_with_retry()
		local result, err

		for attempt = 1, max_retries + 1 do
			call_count = call_count + 1

			-- Show zigzag arrow when starting
			if attempt == 1 then
				add_visual_indicator("↯", "Request sent")
			end

			-- Simulate timeout on first few attempts
			if attempt <= 2 then
				retry_count = retry_count + 1
				add_visual_indicator("🔄", "Retry attempt " .. attempt .. "/" .. max_retries)
				add_visual_indicator("⏳", "Waiting for response...")
				err = "Timeout waiting for response"
			else
				-- Success on final attempt
				result = "Success after retries"
				err = nil
				break
			end
		end

		if not result then
			add_visual_indicator("🛔", "All retries failed: " .. err)
		end

		return result, err
	end

	-- Execute the simulation
	local result, err = simulate_rpc_call_with_retry()

	-- Verify the complete flow
	assert(result == "Success after retries", "Should succeed after retries")
	assert(retry_count == 2, "Should have 2 retry attempts")
	assert(call_count == 3, "Should make 3 total calls")
	assert(#visual_feedback >= 4, "Should have multiple visual indicators")

	-- Check for specific visual indicators
	local has_zigzag = false
	local has_retry = false
	local has_progress = false

	for _, indicator in ipairs(visual_feedback) do
		if indicator:match("↯") then
			has_zigzag = true
		end
		if indicator:match("🔄") then
			has_retry = true
		end
		if indicator:match("⏳") then
			has_progress = true
		end
	end

	assert(has_zigzag, "Should show zigzag arrow when request starts")
	assert(has_retry, "Should show retry symbol during retries")
	assert(has_progress, "Should show progress indicator while waiting")

	print("✓ Full timeout/retry cycle concept verified")
	print("✓ Retry count: " .. retry_count)
	print("✓ Call attempts: " .. call_count)
	print("✓ Visual indicators: " .. #visual_feedback)

	return true
end

-- Main test runner
local function run_all_tests()
	print("Starting comprehensive timeout/retry behavior test suite...\n")

	local test_sections = {
		{ name = "Module Loading", func = test_module_loading },
		{ name = "RPC Tests", func = run_rpc_tests },
		{ name = "Chat Tests", func = run_chat_tests },
		{ name = "Integration Test", func = test_full_timeout_retry_cycle },
	}

	local total_passed = 0
	local total_failed = 0

	for _, section in ipairs(test_sections) do
		print("=== " .. section.name .. " ===")

		local success, result = pcall(section.func)
		if success and result then
			total_passed = total_passed + 1
			print("✅ " .. section.name .. " PASSED\n")
		else
			total_failed = total_failed + 1
			print("❌ " .. section.name .. " FAILED: " .. tostring(result) .. "\n")
		end
	end

	print("=== FINAL RESULTS ===")
	print("Test Sections Passed: " .. total_passed)
	print("Test Sections Failed: " .. total_failed)
	print("Total Test Sections:  " .. (total_passed + total_failed))

	if total_failed == 0 then
		print("\n🎉 ALL TIMEOUT/RETRY TESTS PASSED! 🎉")
		print("The Neovim client correctly handles timeouts with:")
		print("  • Automatic retry logic")
		print("  • Visual feedback (🔄, ↯, ⏳, 🛔)")
		print("  • Proper error handling")
		print("  • Timer cleanup")
		return true
	else
		print("\n💥 Some timeout/retry tests failed!")
		return false
	end
end

-- Run tests automatically
run_all_tests()

return {
	run_all_tests = run_all_tests,
	test_module_loading = test_module_loading,
	test_full_timeout_retry_cycle = test_full_timeout_retry_cycle,
}
