--[[
Lua interface test file for Paragonic functionality
Following TDD principles: write test first, then implement
--]]

local M = {}

-- Test results tracking
local test_results = {
	passed = 0,
	failed = 0,
	total = 0,
}

-- Helper function to run a test
local function run_test(test_name, test_func)
	test_results.total = test_results.total + 1
	local success, result = pcall(test_func)

	if success then
		test_results.passed = test_results.passed + 1
		vim.notify("✓ " .. test_name .. " passed", vim.log.levels.INFO)
	else
		test_results.failed = test_results.failed + 1
		vim.notify("✗ " .. test_name .. " failed: " .. tostring(result), vim.log.levels.ERROR)
	end
end

-- Test helper function that can be called from Neovim
function M.run_tests()
	vim.notify("Running Paragonic interface tests...", vim.log.levels.INFO)

	-- Reset test results
	test_results = { passed = 0, failed = 0, total = 0 }

	-- Test 1: open_projects() creates projects buffer
	run_test("open_projects creates projects buffer", function()
		local paragonic = require("paragonic")

		-- Count buffers before
		local buffers_before = vim.api.nvim_list_bufs()
		local projects_buffers_before = 0
		for _, buf in ipairs(buffers_before) do
			local name = vim.api.nvim_buf_get_name(buf)
			if name == "paragonic://projects" then
				projects_buffers_before = projects_buffers_before + 1
			end
		end

		-- Call open_projects
		paragonic.open_projects()

		-- Count buffers after
		local buffers_after = vim.api.nvim_list_bufs()
		local projects_buffers_after = 0
		for _, buf in ipairs(buffers_after) do
			local name = vim.api.nvim_buf_get_name(buf)
			if name == "paragonic://projects" then
				projects_buffers_after = projects_buffers_after + 1
			end
		end

		-- Should have created a projects buffer
		assert(projects_buffers_after > projects_buffers_before, "Should create a projects buffer")
		return true
	end)

	-- Test 2: open_projects() sets correct buffer properties
	run_test("open_projects sets correct buffer properties", function()
		local paragonic = require("paragonic")

		-- Call open_projects
		paragonic.open_projects()

		-- Find the projects buffer
		local projects_buf = nil
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			local name = vim.api.nvim_buf_get_name(buf)
			if name == "paragonic://projects" then
				projects_buf = buf
				break
			end
		end

		assert(projects_buf ~= nil, "Projects buffer should exist")

		-- Check buffer properties
		local buftype = vim.api.nvim_buf_get_option(projects_buf, "buftype")
		assert(buftype == "nofile", "Buffer type should be nofile")

		local swapfile = vim.api.nvim_buf_get_option(projects_buf, "swapfile")
		assert(swapfile == false, "Swapfile should be disabled")

		local modifiable = vim.api.nvim_buf_get_option(projects_buf, "modifiable")
		assert(modifiable == true, "Buffer should be modifiable")

		local filetype = vim.api.nvim_buf_get_option(projects_buf, "filetype")
		assert(filetype == "markdown", "Filetype should be markdown")

		return true
	end)

	-- Test 3: open_projects() adds initial content
	run_test("open_projects adds initial content", function()
		local paragonic = require("paragonic")

		-- Call open_projects
		paragonic.open_projects()

		-- Find the projects buffer
		local projects_buf = nil
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			local name = vim.api.nvim_buf_get_name(buf)
			if name == "paragonic://projects" then
				projects_buf = buf
				break
			end
		end

		assert(projects_buf ~= nil, "Projects buffer should exist")

		-- Check initial content
		local lines = vim.api.nvim_buf_get_lines(projects_buf, 0, -1, false)
		assert(#lines > 0, "Buffer should have content")

		-- Should contain "Paragonic Projects" in the first line
		assert(lines[1]:find("Paragonic Projects"), "First line should contain 'Paragonic Projects'")

		return true
	end)

	-- Print summary
	local summary = string.format(
		"Interface tests completed: %d passed, %d failed, %d total",
		test_results.passed,
		test_results.failed,
		test_results.total
	)
	vim.notify(summary, vim.log.levels.INFO)

	return test_results
end

-- Command to run tests from Neovim
vim.api.nvim_create_user_command("ParagonicTestInterface", function()
	M.run_tests()
end, { desc = "Run Paragonic interface tests" })

return M
