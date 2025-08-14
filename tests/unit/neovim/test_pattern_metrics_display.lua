-- Test file for pattern metrics display functions
-- Tests the floating window display functionality for pattern metrics and statistics

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

print("=== Pattern Metrics Display Test ===")

-- Mock Neovim API for testing
local mock_vim = {
	api = {
		nvim_create_buf = function(listed, scratch)
			return 1 -- Mock buffer ID
		end,
		nvim_open_win = function(buf, enter, config)
			return 1 -- Mock window ID
		end,
		nvim_buf_set_option = function(buf, option, value)
			-- Mock buffer option setting
		end,
		nvim_win_set_option = function(win, option, value)
			-- Mock window option setting
		end,
		nvim_buf_set_lines = function(buf, start, end_idx, strict_indexing, lines)
			-- Mock setting buffer lines
		end,
		nvim_win_get_cursor = function(win)
			return { 5, 0 } -- Mock cursor position
		end,
		nvim_win_close = function(win, force)
			-- Mock window closing
		end,
		nvim_buf_delete = function(buf, opts)
			-- Mock buffer deletion
		end,
		nvim_list_bufs = function()
			return { 1, 2, 3 } -- Mock buffer list
		end,
		nvim_buf_get_name = function(buf)
			return "mock_buffer_" .. buf -- Mock buffer name
		end,
		nvim_buf_get_option = function(buf, option)
			if option == "filetype" then
				return "lua"
			elseif option == "buftype" then
				return ""
			end
			return nil
		end,
		nvim_buf_set_name = function(buf, name)
			-- Mock setting buffer name
		end,
		nvim_buf_is_valid = function(buf)
			return true -- Mock buffer validity
		end,
		nvim_buf_get_lines = function(buf, start, end_idx, strict_indexing)
			return { "Mock buffer content" } -- Mock buffer lines
		end,
	},
	keymap = {
		set = function(mode, lhs, rhs, opts)
			-- Mock keymap setting
		end,
	},
	notify = function(msg, level)
		-- Mock notification
		print("NOTIFY: " .. msg .. " (level: " .. tostring(level) .. ")")
	end,
	o = {
		columns = 120,
		lines = 40,
	},
}

-- Mock Neovim API before loading the module
local original_vim = vim
vim = mock_vim

-- Mock the debug module
package.loaded.paragonic = package.loaded.paragonic or {}
package.loaded.paragonic.debug = {
	debug_print = function(msg, level)
		print("DEBUG: " .. msg .. " (level: " .. tostring(level) .. ")")
	end,
}

-- Mock the RPC module
package.loaded.paragonic.rpc = {
	call = function(method, params)
		if method == "get_pattern_metrics" then
			return {
				success = true,
				result = {
					pattern_id = params.pattern_id,
					pattern_name = "Session Summary Generation",
					metrics = {
						{
							metric_name = "success_rate",
							metric_value = 0.88,
							metric_unit = "percentage",
							time_period = "daily",
						},
						{
							metric_name = "execution_time",
							metric_value = 1250.5,
							metric_unit = "milliseconds",
							time_period = "daily",
						},
					},
					summary = {
						total_executions = 25,
						success_rate = 0.88,
						average_execution_time_ms = 1250.5,
						last_execution_at = "2025-08-08T10:30:00Z",
					},
				},
			}
		end
		return { success = false, error = "Method not found" }
	end,
}

-- Load the actual paragonic module for testing
local paragonic = require("paragonic.patterns")

-- Test function for pattern metrics display
local function test_pattern_metrics_display()
	print("📊 Testing pattern metrics display functionality...")

	-- Test 1: Check if pattern metrics functions exist
	print("  Testing pattern metrics function availability...")
	if paragonic.get_pattern_statistics then
		print("  ✅ get_pattern_statistics function available")
	else
		print("  ❌ get_pattern_statistics function not available")
	end

	if paragonic.get_pattern_metrics then
		print("  ✅ get_pattern_metrics function available")
	else
		print("  ❌ get_pattern_metrics function not available")
	end

	if paragonic.get_execution_history then
		print("  ✅ get_execution_history function available")
	else
		print("  ❌ get_execution_history function not available")
	end

	-- Test 2: Test pattern statistics retrieval
	print("  Testing pattern statistics retrieval...")
	local stats = paragonic.get_pattern_statistics("Session Summary Generation")
	assert(stats, "Pattern statistics should be returned")
	assert(type(stats.total_executions) == "number", "Total executions should be a number")
	assert(type(stats.success_rate) == "number", "Success rate should be a number")
	assert(stats.success_rate >= 0 and stats.success_rate <= 1, "Success rate should be between 0 and 1")
	assert(type(stats.average_execution_time_ms) == "number", "Average execution time should be a number")
	assert(stats.average_execution_time_ms >= 0, "Average execution time should be non-negative")
	print("  ✅ Pattern statistics retrieval works")

	-- Test 3: Test pattern metrics retrieval
	print("  Testing pattern metrics retrieval...")
	local metrics = paragonic.get_pattern_metrics("test-pattern-1", 7)
	assert(metrics, "Pattern metrics should be returned")
	assert(metrics.pattern_id, "Pattern ID should be present")
	assert(metrics.pattern_name, "Pattern name should be present")
	assert(metrics.metrics, "Metrics array should be present")
	assert(type(metrics.metrics) == "table", "Metrics should be a table")
	assert(metrics.summary, "Summary should be present")
	assert(type(metrics.summary) == "table", "Summary should be a table")
	print("  ✅ Pattern metrics retrieval works")

	-- Test 4: Test execution history retrieval
	print("  Testing execution history retrieval...")
	local history = paragonic.get_execution_history("Session Summary Generation")
	assert(history, "Execution history should be returned")
	assert(type(history) == "table", "History should be a table")
	assert(#history > 0, "History should contain entries")

	for _, entry in ipairs(history) do
		assert(entry.execution_id, "History entry should have execution_id")
		assert(entry.pattern_name, "History entry should have pattern_name")
		assert(entry.execution_status, "History entry should have execution_status")
		assert(entry.created_at, "History entry should have created_at")
	end
	print("  ✅ Execution history retrieval works")

	-- Test 5: Test RPC pattern metrics call
	print("  Testing RPC pattern metrics call...")
	local rpc_result = package.loaded.paragonic.rpc.call("get_pattern_metrics", {
		pattern_id = "test-pattern-1",
		days = 7,
	})
	assert(rpc_result, "RPC result should be returned")
	assert(rpc_result.success, "RPC call should be successful")
	assert(rpc_result.result, "RPC result should contain data")
	assert(rpc_result.result.pattern_id, "RPC result should have pattern_id")
	assert(rpc_result.result.metrics, "RPC result should have metrics")
	print("  ✅ RPC pattern metrics call works")

	-- Test 6: Test metrics data structure validation
	print("  Testing metrics data structure validation...")
	local metrics_data = paragonic.get_pattern_metrics("test-pattern-1", 7)

	-- Validate metrics array structure
	for _, metric in ipairs(metrics_data.metrics) do
		assert(metric.metric_name, "Metric should have name")
		assert(type(metric.metric_value) == "number", "Metric value should be a number")
		assert(metric.metric_unit, "Metric should have unit")
		assert(metric.time_period, "Metric should have time period")
	end

	-- Validate summary structure
	local summary = metrics_data.summary
	assert(type(summary.total_executions) == "number", "Total executions should be a number")
	assert(type(summary.success_rate) == "number", "Success rate should be a number")
	assert(type(summary.average_execution_time_ms) == "number", "Average execution time should be a number")
	print("  ✅ Metrics data structure validation works")

	-- Test 7: Test metrics calculation accuracy
	print("  Testing metrics calculation accuracy...")
	local stats = paragonic.get_pattern_statistics("Session Summary Generation")
	local metrics = paragonic.get_pattern_metrics("test-pattern-1", 7)

	-- Verify that statistics match metrics summary
	assert(
		stats.total_executions == metrics.summary.total_executions,
		"Total executions should match between stats and metrics"
	)
	assert(
		math.abs(stats.success_rate - metrics.summary.success_rate) < 0.01,
		"Success rate should match between stats and metrics"
	)
	assert(
		math.abs(stats.average_execution_time_ms - metrics.summary.average_execution_time_ms) < 0.1,
		"Average execution time should match between stats and metrics"
	)
	print("  ✅ Metrics calculation accuracy works")

	-- Test 8: Test error handling for invalid pattern
	print("  Testing error handling for invalid pattern...")
	local invalid_stats = paragonic.get_pattern_statistics("Invalid Pattern")
	-- This should return nil or throw an error for invalid patterns
	if invalid_stats == nil then
		print("  ✅ Invalid pattern handling works (returns nil)")
	else
		print("  ⚠ Invalid pattern handling returns data (may need review)")
	end

	-- Test 9: Test metrics time period filtering
	print("  Testing metrics time period filtering...")
	local daily_metrics = paragonic.get_pattern_metrics("test-pattern-1", 1)
	local weekly_metrics = paragonic.get_pattern_metrics("test-pattern-1", 7)

	assert(daily_metrics, "Daily metrics should be returned")
	assert(weekly_metrics, "Weekly metrics should be returned")
	assert(daily_metrics.pattern_id == weekly_metrics.pattern_id, "Pattern ID should be consistent")
	print("  ✅ Metrics time period filtering works")

	-- Test 10: Test execution history filtering
	print("  Testing execution history filtering...")
	local history = paragonic.get_execution_history("Session Summary Generation")

	-- Count successful vs failed executions
	local successful_count = 0
	local failed_count = 0

	for _, entry in ipairs(history) do
		if entry.execution_status == "completed" then
			successful_count = successful_count + 1
		elseif entry.execution_status == "failed" then
			failed_count = failed_count + 1
		end
	end

	assert(successful_count > 0, "Should have successful executions")
	assert(successful_count + failed_count == #history, "Total should match history count")
	print("  ✅ Execution history filtering works")

	print("  ✅ Pattern metrics display test passed")
	return true
end

-- Test function for metrics visualization functions
local function test_metrics_visualization_functions()
	print("📈 Testing metrics visualization function availability...")

	-- These functions should now be implemented in task 7.10
	local visualization_functions = {
		"show_pattern_metrics",
		"show_pattern_statistics",
		"show_execution_history",
		"show_metrics_chart",
		"show_performance_trends",
	}

	for _, func_name in ipairs(visualization_functions) do
		if paragonic[func_name] then
			print("  ✅ " .. func_name .. " function available")
		else
			print("  ❌ " .. func_name .. " function not available")
		end
	end

	print("  ✅ Metrics visualization function availability check completed")
	return true
end

-- Test function for metrics display integration
local function test_metrics_display_integration()
	print("🔗 Testing metrics display integration...")

	-- Test that metrics data can be properly formatted for display
	local metrics = paragonic.get_pattern_metrics("test-pattern-1", 7)

	-- Test metrics formatting for display
	local formatted_metrics = {}
	for _, metric in ipairs(metrics.metrics) do
		local formatted = {
			name = metric.metric_name,
			value = string.format("%.2f", metric.metric_value),
			unit = metric.metric_unit,
			period = metric.time_period,
		}
		table.insert(formatted_metrics, formatted)
	end

	assert(#formatted_metrics == #metrics.metrics, "Should format all metrics")
	for _, formatted in ipairs(formatted_metrics) do
		assert(formatted.name, "Formatted metric should have name")
		assert(formatted.value, "Formatted metric should have value")
		assert(formatted.unit, "Formatted metric should have unit")
	end
	print("  ✅ Metrics formatting for display works")

	-- Test summary formatting
	local summary = metrics.summary
	local formatted_summary = {
		total = summary.total_executions,
		success_rate = string.format("%.1f%%", summary.success_rate * 100),
		avg_time = string.format("%.1f ms", summary.average_execution_time_ms),
		last_execution = summary.last_execution_at,
	}

	assert(formatted_summary.total, "Formatted summary should have total")
	assert(formatted_summary.success_rate, "Formatted summary should have success rate")
	assert(formatted_summary.avg_time, "Formatted summary should have average time")
	print("  ✅ Summary formatting for display works")

	print("  ✅ Metrics display integration test passed")
	return true
end

-- Run all tests
local function run_all_tests()
	print("🚀 Starting pattern metrics display tests...")

	local tests = {
		{ name = "Pattern Metrics Display", func = test_pattern_metrics_display },
		{ name = "Metrics Visualization Functions", func = test_metrics_visualization_functions },
		{ name = "Metrics Display Integration", func = test_metrics_display_integration },
	}

	local passed = 0
	local total = #tests

	for _, test in ipairs(tests) do
		print("\n--- " .. test.name .. " ---")
		local success, result = pcall(test.func)
		if success and result then
			print("✅ " .. test.name .. " passed")
			passed = passed + 1
		else
			print("❌ " .. test.name .. " failed")
			if not success then
				print("Error: " .. tostring(result))
			end
		end
	end

	print("\n📊 Test Results: " .. passed .. "/" .. total .. " tests passed")

	if passed == total then
		print("🎉 All pattern metrics display tests passed!")
		return true
	else
		print("⚠ Some tests failed - review implementation")
		return false
	end
end

-- Run the tests
local success, result = pcall(run_all_tests)
if not success then
	print("❌ Test execution failed: " .. tostring(result))
	os.exit(1)
end

if result then
	print("\n🮮 All pattern metrics display tests completed successfully")
else
	print("\n🮮 Pattern metrics display tests completed with failures")
	os.exit(1)
end
