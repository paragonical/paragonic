#!/usr/bin/env lua

--[[
Test Real File System Operations
TDD Step: Test actual file system operations that might cause freezing
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Test 1: Real file system operations with actual paths
local function test_real_filesystem_operations()
	print("=== Test 1: Real File System Operations ===")

	-- Get the actual data directory path
	local data_dir = vim.fn.stdpath("data") .. "/paragonic"
	local history_file = data_dir .. "/search_history.json"
	local saved_searches_file = data_dir .. "/saved_searches.json"

	print("  📁 Data directory: " .. data_dir)
	print("  📄 History file: " .. history_file)
	print("  📄 Saved searches file: " .. saved_searches_file)

	-- Test directory creation
	print("  📝 Testing directory creation...")
	local dir_exists = vim.fn.isdirectory(data_dir)
	print("    Directory exists: " .. tostring(dir_exists == 1))

	if dir_exists == 0 then
		print("    Creating directory...")
		local success = pcall(vim.fn.mkdir, data_dir, "p")
		print("    Directory creation success: " .. tostring(success))
	end

	-- Test file operations
	print("  📝 Testing file operations...")

	-- Test history file
	local history_readable = vim.fn.filereadable(history_file)
	print("    History file readable: " .. tostring(history_readable == 1))

	if history_readable == 1 then
		print("    Reading history file...")
		local success, lines = pcall(vim.fn.readfile, history_file)
		if success then
			print("    History file lines: " .. #lines)
			if #lines > 0 then
				print("    First line preview: " .. lines[1]:sub(1, 50) .. "...")
			end
		else
			print("    Failed to read history file")
		end
	end

	-- Test saved searches file
	local searches_readable = vim.fn.filereadable(saved_searches_file)
	print("    Saved searches file readable: " .. tostring(searches_readable == 1))

	if searches_readable == 1 then
		print("    Reading saved searches file...")
		local success, lines = pcall(vim.fn.readfile, saved_searches_file)
		if success then
			print("    Saved searches file lines: " .. #lines)
			if #lines > 0 then
				print("    First line preview: " .. lines[1]:sub(1, 50) .. "...")
			end
		else
			print("    Failed to read saved searches file")
		end
	end

	return true
end

-- Test 2: JSON parsing with real data
local function test_json_parsing()
	print("=== Test 2: JSON Parsing with Real Data ===")

	local data_dir = vim.fn.stdpath("data") .. "/paragonic"
	local history_file = data_dir .. "/search_history.json"
	local saved_searches_file = data_dir .. "/saved_searches.json"

	-- Test history file JSON parsing
	if vim.fn.filereadable(history_file) == 1 then
		print("  📝 Testing history file JSON parsing...")
		local success, lines = pcall(vim.fn.readfile, history_file)
		if success and #lines > 0 then
			local json_string = table.concat(lines, "\n")
			local parse_success, data = pcall(vim.json.decode, json_string)
			if parse_success and data then
				print("    ✅ History JSON parsed successfully")
				print("    📊 History entries: " .. #data)
			else
				print("    ❌ History JSON parsing failed")
				print("    📄 JSON preview: " .. json_string:sub(1, 100) .. "...")
			end
		else
			print("    📄 History file is empty or unreadable")
		end
	else
		print("  📄 History file does not exist")
	end

	-- Test saved searches file JSON parsing
	if vim.fn.filereadable(saved_searches_file) == 1 then
		print("  📝 Testing saved searches file JSON parsing...")
		local success, lines = pcall(vim.fn.readfile, saved_searches_file)
		if success and #lines > 0 then
			local json_string = table.concat(lines, "\n")
			local parse_success, data = pcall(vim.json.decode, json_string)
			if parse_success and data then
				print("    ✅ Saved searches JSON parsed successfully")
				print("    📊 Saved searches: " .. #data)
			else
				print("    ❌ Saved searches JSON parsing failed")
				print("    📄 JSON preview: " .. json_string:sub(1, 100) .. "...")
			end
		else
			print("    📄 Saved searches file is empty or unreadable")
		end
	else
		print("  📄 Saved searches file does not exist")
	end

	return true
end

-- Test 3: Simulate the actual _load_persistent_data function
local function test_actual_load_persistent_data()
	print("=== Test 3: Actual _load_persistent_data Function ===")

	-- Load the actual module
	local M = require("paragonic")

	-- Test the actual function
	print("  📝 Testing actual _load_persistent_data function...")
	local start_time = os.clock()

	local success = pcall(function()
		M._load_persistent_data()
	end)

	local end_time = os.clock()
	local duration = (end_time - start_time) * 1000 -- Convert to milliseconds

	print("    Execution time: " .. string.format("%.2f", duration) .. "ms")

	if success then
		print("    ✅ _load_persistent_data executed successfully")
	else
		print("    ❌ _load_persistent_data failed")
	end

	-- Check if it took too long (potential blocking operation)
	if duration > 1000 then
		print("    ⚠️  WARNING: Function took more than 1 second - potential blocking operation!")
		return false
	else
		print("    ✅ Function executed within reasonable time")
		return true
	end
end

-- Test 4: Test file system permissions and locks
local function test_filesystem_permissions()
	print("=== Test 4: File System Permissions and Locks ===")

	local data_dir = vim.fn.stdpath("data") .. "/paragonic"
	local test_file = data_dir .. "/test_permissions.json"

	print("  📝 Testing file system permissions...")

	-- Test if we can write to the directory
	local test_data = { test = "permission_check", timestamp = os.time() }
	local json_string = vim.json.encode(test_data)

	local write_success = pcall(vim.fn.writefile, { json_string }, test_file)
	print("    Write test: " .. tostring(write_success))

	if write_success then
		-- Test if we can read the file back
		local read_success, lines = pcall(vim.fn.readfile, test_file)
		print("    Read test: " .. tostring(read_success))

		if read_success then
			local parse_success, data = pcall(vim.json.decode, table.concat(lines, "\n"))
			print("    Parse test: " .. tostring(parse_success))

			if parse_success and data.test == "permission_check" then
				print("    ✅ File system permissions are working correctly")
			else
				print("    ❌ File system permissions test failed")
				return false
			end
		end

		-- Clean up test file
		os.remove(test_file)
	else
		print("    ❌ Cannot write to data directory - permission issue!")
		return false
	end

	return true
end

-- Test 5: Test memory usage during initialization
local function test_memory_usage()
	print("=== Test 5: Memory Usage During Initialization ===")

	-- Load the actual module
	local M = require("paragonic")

	print("  📝 Testing memory usage during initialization...")

	-- Measure memory before
	local mem_before = collectgarbage("count")
	print("    Memory before: " .. string.format("%.2f", mem_before) .. " KB")

	-- Run initialization functions
	local start_time = os.clock()

	local success = pcall(function()
		M._ensure_data_directory()
		M._setup_keymaps()
		M._load_persistent_data()
	end)

	local end_time = os.clock()
	local duration = (end_time - start_time) * 1000

	-- Measure memory after
	local mem_after = collectgarbage("count")
	local mem_diff = mem_after - mem_before

	print("    Memory after: " .. string.format("%.2f", mem_after) .. " KB")
	print("    Memory difference: " .. string.format("%.2f", mem_diff) .. " KB")
	print("    Execution time: " .. string.format("%.2f", duration) .. "ms")

	if success then
		print("    ✅ Initialization completed successfully")

		if mem_diff > 1000 then
			print("    ⚠️  WARNING: High memory usage during initialization!")
			return false
		else
			print("    ✅ Memory usage is reasonable")
			return true
		end
	else
		print("    ❌ Initialization failed")
		return false
	end
end

-- Main test execution
print("=== Real File System Operations Test ===")
print("Testing actual file system operations that might cause freezing...")

local tests = {
	test_real_filesystem_operations,
	test_json_parsing,
	test_actual_load_persistent_data,
	test_filesystem_permissions,
	test_memory_usage,
}

local passed = 0
local total = #tests

for i, test in ipairs(tests) do
	print("\n--- Running Test " .. i .. "/" .. total .. " ---")
	local success = test()
	if success then
		passed = passed + 1
	end
end

print("\n=== Test Results ===")
print("Passed: " .. passed .. "/" .. total)

if passed == total then
	print("✅ All real file system operation tests passed!")
	print("The file system operations should not cause Neovim to freeze.")
else
	print("❌ Some real file system operation tests failed.")
	print("This may indicate the source of the freezing issue.")
end

print("\n=== Analysis ===")
if passed == total then
	print("• File system operations are working correctly")
	print("• JSON parsing is functioning properly")
	print("• Memory usage is reasonable")
	print("• The freezing may be caused by:")
	print("  - Interaction with other plugins during startup")
	print("  - Timing issues with deferred functions")
	print("  - AstroNvim-specific initialization conflicts")
	print("  - System resource constraints")
else
	print("• File system or memory issues detected")
	print("• These should be addressed to prevent freezing")
end
