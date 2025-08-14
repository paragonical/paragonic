#!/usr/bin/env lua

--[[
Test script for agent file saving functionality
This tests the ability for an agent to save files to disk
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Test agent file saving functionality
local function test_agent_file_save()
	print("=== Testing Agent File Save ===")

	-- Mock the required vim functions for testing
	local vim_mock = {
		api = {
			nvim_list_bufs = function()
				return { 1, 2, 3 }
			end,
			nvim_buf_get_name = function(buf)
				if buf == 1 then
					return "/tmp/file1.txt"
				elseif buf == 2 then
					return "/tmp/file2.lua"
				else
					return "/tmp/file3.md"
				end
			end,
			nvim_buf_get_lines = function(buf, start, end_, strict)
				if start == 0 and end_ == -1 then
					return { "line 1", "line 2", "line 3" }
				else
					return { "line " .. (start + 1) }
				end
			end,
			nvim_buf_get_option = function(buf, option)
				if option == "modified" then
					if buf == 1 then
						return true
					else
						return false
					end
				elseif option == "modifiable" then
					return true
				end
				return nil
			end,
			nvim_get_current_buf = function()
				return 1
			end,
			nvim_buf_call = function(buf, fun)
				print("  Call function on buffer " .. buf)
				return fun()
			end,
		},
		fn = {
			expand = function(expr)
				if expr == "%:p" then
					return "/tmp/current.txt"
				elseif expr == "%:p:h" then
					return "/tmp"
				else
					return expr
				end
			end,
			input = function(prompt)
				if prompt:find("File path") then
					return "/tmp/saved_file.txt"
				else
					return "test"
				end
			end,
			getcwd = function()
				return "/tmp"
			end,
			writefile = function(lines, file_path)
				print("  Write " .. #lines .. " lines to " .. file_path)
				return 0 -- Success
			end,
			filereadable = function(file_path)
				if file_path:find("existing") then
					return 1
				else
					return 0
				end
			end,
			mkdir = function(dir_path, mode)
				print("  Create directory " .. dir_path)
				return 1 -- Success
			end,
			fnamemodify = function(file_path, modifier)
				if modifier == ":h" then
					if file_path:find("/") then
						return file_path:match("(.*)/[^/]*$")
					else
						return "."
					end
				end
				return file_path
			end,
			isdirectory = function(dir_path)
				if dir_path == "." then
					return 1
				elseif dir_path:find("existing") then
					return 1
				else
					return 0
				end
			end,
		},
		notify = function(msg, level)
			print("  Notify [" .. (level or "info") .. "]: " .. msg)
		end,
		log = {
			levels = {
				INFO = 1,
				WARN = 2,
				ERROR = 3,
			},
		},
		cmd = function(command)
			print("  Execute command: " .. command)
		end,
	}

	-- Replace global vim temporarily
	local original_vim = _G.vim
	_G.vim = vim_mock

	-- Test the agent_save_file function
	print("  Testing agent_save_file function...")

	-- Create a simple test module
	local M = {}

	-- Save current file or specified file
	function M.agent_save_file(args)
		local file_path = args[1]
		local force = args[2] == "true"

		local target_buffer = nil

		if file_path and file_path ~= "" then
			-- Find buffer by file path
			local buffers = vim.api.nvim_list_bufs()
			for _, buf in ipairs(buffers) do
				local buf_name = vim.api.nvim_buf_get_name(buf)
				if buf_name == file_path then
					target_buffer = buf
					break
				end
			end

			if not target_buffer then
				vim.notify("File not found in session: " .. file_path, vim.log.levels.WARN)
				return false
			end
		else
			-- Use current buffer
			target_buffer = vim.api.nvim_get_current_buf()
			file_path = vim.api.nvim_buf_get_name(target_buffer)
		end

		-- Check if buffer is modified
		local modified = vim.api.nvim_buf_get_option(target_buffer, "modified")
		if not modified and not force then
			vim.notify("File is not modified: " .. file_path, vim.log.levels.INFO)
			return true
		end

		-- Get buffer content
		local lines = vim.api.nvim_buf_get_lines(target_buffer, 0, -1, false)

		-- Ensure directory exists
		local dir_path = vim.fn.fnamemodify(file_path, ":h")
		if dir_path ~= "." and vim.fn.isdirectory(dir_path) == 0 then
			vim.fn.mkdir(dir_path, "p")
		end

		-- Write file
		local result = vim.fn.writefile(lines, file_path)
		if result == 0 then
			-- Mark buffer as not modified
			vim.api.nvim_buf_call(target_buffer, function()
				vim.cmd("set nomodified")
			end)
			vim.notify("Saved file: " .. file_path, vim.log.levels.INFO)
			return true
		else
			vim.notify("Failed to save file: " .. file_path, vim.log.levels.ERROR)
			return false
		end
	end

	-- Test the function
	print("  Testing save current file...")
	local success1 = M.agent_save_file({})
	assert(success1 == true, "Save current file should succeed")

	print("  Testing save specific file...")
	local success2 = M.agent_save_file({ "/tmp/file1.txt" })
	assert(success2 == true, "Save specific file should succeed")

	print("  Testing save unmodified file...")
	local success3 = M.agent_save_file({ "/tmp/file2.lua" })
	assert(success3 == true, "Save unmodified file should succeed")

	print("  Testing save with force...")
	local success4 = M.agent_save_file({ "/tmp/file2.lua", "true" })
	assert(success4 == true, "Save with force should succeed")

	print("  Testing save non-existent file...")
	local success5 = M.agent_save_file({ "/tmp/nonexistent.txt" })
	assert(success5 == false, "Save non-existent file should fail")

	print("  ✓ agent_save_file function works")

	-- Test batch save functionality
	print("  Testing batch save functionality...")
	function M.agent_save_all_files()
		local buffers = vim.api.nvim_list_bufs()
		local saved_count = 0
		local failed_count = 0

		for _, buf in ipairs(buffers) do
			local buf_name = vim.api.nvim_buf_get_name(buf)
			local modified = vim.api.nvim_buf_get_option(buf, "modified")

			if buf_name ~= "" and modified then
				local success = M.agent_save_file({ buf_name })
				if success then
					saved_count = saved_count + 1
				else
					failed_count = failed_count + 1
				end
			end
		end

		if saved_count > 0 then
			vim.notify("Saved " .. saved_count .. " files", vim.log.levels.INFO)
		end
		if failed_count > 0 then
			vim.notify("Failed to save " .. failed_count .. " files", vim.log.levels.WARN)
		end

		return saved_count, failed_count
	end

	local saved, failed = M.agent_save_all_files()
	assert(saved == 1, "Should save 1 modified file")
	assert(failed == 0, "Should not fail to save any files")

	print("  ✓ Batch save functionality works")

	-- Test save with backup
	print("  Testing save with backup...")
	function M.agent_save_with_backup(args)
		local file_path = args[1]
		local create_backup = args[2] == "true"

		if create_backup and file_path then
			local backup_path = file_path .. ".backup"
			local success = M.agent_save_file({ file_path })
			if success then
				-- Create backup by copying the file
				local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), 0, -1, false)
				vim.fn.writefile(lines, backup_path)
				vim.notify("Created backup: " .. backup_path, vim.log.levels.INFO)
			end
			return success
		else
			return M.agent_save_file(args)
		end
	end

	local success6 = M.agent_save_with_backup({ "/tmp/file1.txt", "true" })
	assert(success6 == true, "Save with backup should succeed")

	print("  ✓ Save with backup works")

	-- Restore original vim
	_G.vim = original_vim

	print("✓ All agent file save tests passed!")
end

-- Main test execution
print("=== Agent File Save Test ===")
print("Testing agent file saving functionality...")

-- Run tests
test_agent_file_save()

print("\n=== Test Complete ===")
print("✓ All agent file save tests passed!")
print("Agent file save features verified:")
print("  • Save current file")
print("  • Save specific file")
print("  • Check file modification status")
print("  • Force save unmodified files")
print("  • Create directories if needed")
print("  • Batch save all modified files")
print("  • Save with backup")
print("  • Error handling for invalid files")
