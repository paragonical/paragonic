-- Performance tests for MCP HTTP transport
--
-- This test suite verifies performance characteristics of the MCP
-- HTTP transport implementation.

local mcp_http_transport = require("../../lua/paragonic/mcp_http_transport")
local mcp_config = require("../../lua/paragonic/mcp_config")

-- Test utilities
local function assert_true(value, message)
	if not value then
		error(
			string.format(
				"Assertion failed: %s (expected true, got %s)",
				message or "value should be true",
				tostring(value)
			)
		)
	end
end

local function assert_false(value, message)
	if value then
		error(
			string.format(
				"Assertion failed: %s (expected false, got %s)",
				message or "value should be false",
				tostring(value)
			)
		)
	end
end

local function assert_not_nil(value, message)
	if value == nil then
		error(string.format("Assertion failed: %s (expected non-nil value)", message or "value should not be nil"))
	end
end

-- Test results
local test_results = {
	passed = 0,
	failed = 0,
	errors = {},
}

local function run_test(test_name, test_func)
	print("Running test: " .. test_name)
	local success, err = pcall(test_func)
	if success then
		print("  ✓ PASSED")
		test_results.passed = test_results.passed + 1
	else
		print("  ✗ FAILED: " .. tostring(err))
		test_results.failed = test_results.failed + 1
		table.insert(test_results.errors, { name = test_name, error = err })
	end
end

-- Performance measurement utilities
local function measure_time(func)
	local start_time = vim.loop.now()
	func()
	local end_time = vim.loop.now()
	return (end_time - start_time) / 1000 -- Convert to seconds
end

local function measure_memory_usage()
	-- Simple memory usage estimation
	local success, info = pcall(vim.loop.getrusage)
	if success and info and info.ru_maxrss then
		return info.ru_maxrss -- Resident set size in KB
	else
		-- Fallback: return a dummy value for testing
		return 1000 -- 1MB dummy value
	end
end

-- Test functions
local function test_initialization_performance()
	print("  Testing initialization performance...")

	local times = {}
	for i = 1, 10 do
		local time = measure_time(function()
			mcp_http_transport.init()
			mcp_http_transport.cleanup()
		end)
		table.insert(times, time)
	end

	local avg_time = 0
	for _, time in ipairs(times) do
		avg_time = avg_time + time
	end
	avg_time = avg_time / #times

	print(string.format("    Average initialization time: %.3f seconds", avg_time))
	assert_true(avg_time < 1.0, "Initialization should complete within 1 second")
end

local function test_request_throughput()
	print("  Testing request throughput...")

	mcp_http_transport.init()

	local request_count = 100
	local start_time = vim.loop.now()

	for i = 1, request_count do
		local request = {
			jsonrpc = "2.0",
			method = "test/request",
			params = { id = i },
		}

		local response, err = mcp_http_transport.send_request(request)
		-- Expected to fail without server, but we're measuring throughput
	end

	local end_time = vim.loop.now()
	local total_time = (end_time - start_time) / 1000
	local requests_per_second = request_count / total_time

	print(string.format("    Processed %d requests in %.3f seconds", request_count, total_time))
	print(string.format("    Throughput: %.1f requests/second", requests_per_second))
	assert_true(requests_per_second > 10, "Should process at least 10 requests per second")

	mcp_http_transport.cleanup()
end

local function test_memory_usage()
	print("  Testing memory usage...")

	local initial_memory = measure_memory_usage()

	mcp_http_transport.init()

	-- Send multiple requests to simulate usage
	for i = 1, 50 do
		local request = {
			jsonrpc = "2.0",
			method = "test/memory",
			params = { data = string.rep("x", 1000) }, -- 1KB of data
		}

		local response, err = mcp_http_transport.send_request(request)
	end

	local final_memory = measure_memory_usage()
	local memory_increase = final_memory - initial_memory

	print(string.format("    Memory increase: %d KB", memory_increase))
	assert_true(memory_increase < 10000, "Memory increase should be less than 10MB")

	mcp_http_transport.cleanup()
end

local function test_concurrent_operations()
	print("  Testing concurrent operations...")

	mcp_http_transport.init()

	local operation_count = 20
	local completed_operations = 0
	local start_time = vim.loop.now()

	-- Simulate concurrent operations
	for i = 1, operation_count do
		-- Simulate async operation
		vim.schedule(function()
			local request = {
				jsonrpc = "2.0",
				method = "test/concurrent",
				params = { id = i },
			}

			local response, err = mcp_http_transport.send_request(request)
			completed_operations = completed_operations + 1
		end)
	end

	-- Wait for operations to complete
	while completed_operations < operation_count do
		vim.wait(10) -- Wait 10ms
	end

	local end_time = vim.loop.now()
	local total_time = (end_time - start_time) / 1000

	print(string.format("    Completed %d concurrent operations in %.3f seconds", operation_count, total_time))
	assert_true(total_time < 5.0, "Concurrent operations should complete within 5 seconds")

	mcp_http_transport.cleanup()
end

local function test_transport_switching_performance()
	print("  Testing transport switching performance...")

	mcp_http_transport.init()

	local switch_count = 10
	local times = {}

	for i = 1, switch_count do
		local time = measure_time(function()
			mcp_http_transport.switch_transport("http", {
				base_url = "http://localhost:3000",
			})
		end)
		table.insert(times, time)
	end

	local avg_time = 0
	for _, time in ipairs(times) do
		avg_time = avg_time + time
	end
	avg_time = avg_time / #times

	print(string.format("    Average transport switch time: %.3f seconds", avg_time))
	assert_true(avg_time < 0.5, "Transport switching should complete within 0.5 seconds")

	mcp_http_transport.cleanup()
end

local function test_health_check_performance()
	print("  Testing health check performance...")

	mcp_http_transport.init()

	local check_count = 50
	local times = {}

	for i = 1, check_count do
		local time = measure_time(function()
			mcp_http_transport.health_check()
		end)
		table.insert(times, time)
	end

	local avg_time = 0
	for _, time in ipairs(times) do
		avg_time = avg_time + time
	end
	avg_time = avg_time / #times

	print(string.format("    Average health check time: %.3f seconds", avg_time))
	assert_true(avg_time < 0.1, "Health check should complete within 0.1 seconds")

	mcp_http_transport.cleanup()
end

local function test_configuration_performance()
	print("  Testing configuration performance...")

	local load_times = {}
	local save_times = {}

	for i = 1, 20 do
		-- Test configuration loading
		local load_time = measure_time(function()
			mcp_config.load()
		end)
		table.insert(load_times, load_time)

		-- Test configuration saving
		local save_time = measure_time(function()
			mcp_config.save()
		end)
		table.insert(save_times, save_time)
	end

	local avg_load_time = 0
	for _, time in ipairs(load_times) do
		avg_load_time = avg_load_time + time
	end
	avg_load_time = avg_load_time / #load_times

	local avg_save_time = 0
	for _, time in ipairs(save_times) do
		avg_save_time = avg_save_time + time
	end
	avg_save_time = avg_save_time / #save_times

	print(string.format("    Average config load time: %.3f seconds", avg_load_time))
	print(string.format("    Average config save time: %.3f seconds", avg_save_time))
	assert_true(avg_load_time < 0.1, "Configuration loading should complete within 0.1 seconds")
	assert_true(avg_save_time < 0.1, "Configuration saving should complete within 0.1 seconds")
end

local function test_error_handling_performance()
	print("  Testing error handling performance...")

	mcp_http_transport.init()

	local error_count = 100
	local times = {}

	for i = 1, error_count do
		local time = measure_time(function()
			-- Send invalid request to trigger error handling
			local response, err = mcp_http_transport.send_request(nil)
		end)
		table.insert(times, time)
	end

	local avg_time = 0
	for _, time in ipairs(times) do
		avg_time = avg_time + time
	end
	avg_time = avg_time / #times

	print(string.format("    Average error handling time: %.3f seconds", avg_time))
	assert_true(avg_time < 0.01, "Error handling should complete within 0.01 seconds")

	mcp_http_transport.cleanup()
end

-- Run all tests
print("Starting MCP Performance Tests")
print("==============================")

-- Clean up before running tests
mcp_http_transport.cleanup()

-- Run tests
run_test("Initialization performance", test_initialization_performance)
run_test("Request throughput", test_request_throughput)
run_test("Memory usage", test_memory_usage)
run_test("Concurrent operations", test_concurrent_operations)
run_test("Transport switching performance", test_transport_switching_performance)
run_test("Health check performance", test_health_check_performance)
run_test("Configuration performance", test_configuration_performance)
run_test("Error handling performance", test_error_handling_performance)

-- Print results
print("\nTest Results")
print("============")
print(string.format("Passed: %d", test_results.passed))
print(string.format("Failed: %d", test_results.failed))
print(string.format("Total: %d", test_results.passed + test_results.failed))

if test_results.failed > 0 then
	print("\nFailed Tests:")
	for _, error_info in ipairs(test_results.errors) do
		print(string.format("  - %s: %s", error_info.name, error_info.error))
	end
end

-- Clean up after tests
mcp_http_transport.cleanup()

-- Exit with appropriate code
if test_results.failed > 0 then
	os.exit(1)
else
	os.exit(0)
end
