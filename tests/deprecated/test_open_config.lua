--[[
Test for open_config() function - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Test that open_config() creates a config buffer
local function test_open_config_creates_buffer()
	print("Testing open_config() creates config buffer...")

	-- Load the module
	local paragonic = require("paragonic")

	-- Count config buffers before
	local buffers_before = vim.api.nvim_list_bufs()
	local config_buffers_before = 0
	for _, buf in ipairs(buffers_before) do
		local name = vim.api.nvim_buf_get_name(buf)
		if name == "paragonic://config" then
			config_buffers_before = config_buffers_before + 1
		end
	end

	-- Call open_config
	paragonic.open_config()

	-- Count config buffers after
	local buffers_after = vim.api.nvim_list_bufs()
	local config_buffers_after = 0
	for _, buf in ipairs(buffers_after) do
		local name = vim.api.nvim_buf_get_name(buf)
		if name == "paragonic://config" then
			config_buffers_after = config_buffers_after + 1
		end
	end

	-- Should have created a config buffer
	assert(config_buffers_after > config_buffers_before, "Should create a config buffer")

	print("✓ open_config() creates config buffer test passed!")
end

-- Run the test
test_open_config_creates_buffer()
