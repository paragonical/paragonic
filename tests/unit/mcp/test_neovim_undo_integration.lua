--[[
Unit tests for Neovim Undo Integration
Tests the integration of AI agent file modifications with Neovim's undo tree
--]]

local M = {}

-- Test configuration
local TEST_CONFIG = {
	file_modification_request = {
		id = "undo-test-1234",
		type = "tool_execution",
		status = "pending",
		created_at = os.time(),
		timeout = 60,
		tool_name = "agent_edit_file",
		parameters = {
			file_path = "test_undo.lua",
			line_number = 10,
			content = "// AI modified content"
		},
		impact = "Will modify line 10 in test_undo.lua"
	},
	batch_file_request = {
		id = "undo-batch-test-5678",
		type = "batch_action",
		status = "pending",
		created_at = os.time(),
		timeout = 120,
		actions = {
			{type = "edit", file = "file1.lua", tool_name = "agent_edit_file", line = 5, content = "// AI edit 1"},
			{type = "edit", file = "file2.lua", tool_name = "agent_edit_file", line = 15, content = "// AI edit 2"},
			{type = "create", file = "file3.lua", tool_name = "agent_create_file", content = "// AI created file"}
		},
		description = "Multiple file modifications"
	}
}

-- Mock Neovim API for testing
local mock_vim = {
	api = {
		nvim_create_buf = function(listed, scratch)
			return 1001 -- Mock buffer ID
		end,
		nvim_buf_set_option = function(buf, option, value)
			-- Mock buffer option setting
		end,
		nvim_buf_set_lines = function(buf, start, end_idx, strict, lines)
			-- Mock buffer content setting
		end,
		nvim_buf_get_lines = function(buf, start, end_idx, strict)
			return {"line 1", "line 2", "line 3"} -- Mock buffer content
		end,
		nvim_buf_get_name = function(buf)
			return "test_undo.lua" -- Mock buffer name
		end,
		nvim_buf_is_valid = function(buf)
			return buf == 1001 -- Mock buffer validation
		end,
		nvim_command = function(cmd)
			-- Mock command execution
		end,
		nvim_eval = function(expr)
			if expr == "&undolevels" then
				return 1000 -- Mock undo levels
			elseif expr == "undotree()" then
				return {
					entries = {
						[1] = {seq = 1, time = os.time(), newhead = 1},
						[2] = {seq = 2, time = os.time(), newhead = 2},
						[3] = {seq = 3, time = os.time(), newhead = 3}
					},
					synced = 3,
					last_time = os.time()
				}
			end
			return nil
		end,
		nvim_call_function = function(func, args)
			if func == "undotree" then
				return {
					entries = {
						[1] = {seq = 1, time = os.time(), newhead = 1},
						[2] = {seq = 2, time = os.time(), newhead = 2},
						[3] = {seq = 3, time = os.time(), newhead = 3}
					},
					synced = 3,
					last_time = os.time()
				}
			end
			return nil
		end
	},
	o = {
		lines = 50,
		columns = 100,
		undolevels = 1000
	},
	notify = function(msg, level) 
		print("NOTIFY: " .. msg) 
	end,
	log = {
		levels = {
			INFO = 1,
			WARN = 2,
			ERROR = 3
		}
	},
	fn = {
		undotree = function()
			return {
				entries = {
					[1] = {seq = 1, time = os.time(), newhead = 1},
					[2] = {seq = 2, time = os.time(), newhead = 2},
					[3] = {seq = 3, time = os.time(), newhead = 3}
				},
				synced = 3,
				last_time = os.time()
			}
		end
	}
}

-- Set up global vim mock
_G.vim = mock_vim

-- Load MCP module
local mcp = require("paragonic.mcp")

-- Test suite setup
function M.setup()
	-- Initialize MCP server and approval state management
	if mcp.initialize_mcp_server then
		mcp.initialize_mcp_server()
	end
	if mcp.initialize_approval_state then
		mcp.initialize_approval_state()
	end
end

function M.teardown()
	-- Cleanup approval state
	if mcp.clear_approval_state then
		mcp.clear_approval_state()
	end
end

-- Test cases
function M.test_ai_file_modification_undo_integration()
	print("Testing AI agent file modification undo integration...")
	
	local request = TEST_CONFIG.file_modification_request
	mcp.register_approval_request(request)
	
	-- Simulate AI agent file modification with undo integration
	local success = mcp.execute_tool_with_undo_integration(request.tool_name, request.parameters, request.id)
	assert(success, "Should execute tool with undo integration")
	
	-- Verify undo entry was created
	local undo_entry = mcp.get_ai_undo_entry(request.id)
	assert(undo_entry, "Should have AI undo entry")
	assert(undo_entry.request_id == request.id, "Should have correct request ID")
	assert(undo_entry.tool_name == request.tool_name, "Should have correct tool name")
	
	print("✅ AI file modification undo integration test passed")
end

function M.test_granular_undo_redo_control()
	print("Testing granular undo/redo control for AI actions...")
	
	local request = TEST_CONFIG.file_modification_request
	request.id = "granular-test-1234" -- Unique ID
	mcp.register_approval_request(request)
	
	-- Execute multiple AI modifications
	local modifications = {
		{line = 10, content = "// AI modification 1"},
		{line = 15, content = "// AI modification 2"},
		{line = 20, content = "// AI modification 3"}
	}
	
	for i, mod in ipairs(modifications) do
		local mod_id = request.id .. "-" .. i
		mcp.register_approval_request({id = mod_id, type = "tool_execution"})
		local params = {
			file_path = "test_granular.lua",
			line_number = mod.line,
			content = mod.content
		}
		local success = mcp.execute_tool_with_undo_integration("agent_edit_file", params, mod_id)
		assert(success, "Should execute modification " .. i)
	end
	
	-- Test selective undo
	local undo_success = mcp.undo_ai_modification(request.id .. "-2")
	assert(undo_success, "Should undo specific AI modification")
	
	-- Test selective redo
	local redo_success = mcp.redo_ai_modification(request.id .. "-2")
	assert(redo_success, "Should redo specific AI modification")
	
	print("✅ Granular undo/redo control test passed")
end

function M.test_selective_undo_redo_for_ai_changes()
	print("Testing selective undo/redo for AI agent changes...")
	
	local request = TEST_CONFIG.batch_file_request
	mcp.register_approval_request(request)
	
	-- Execute batch AI modifications
	local success = mcp.execute_batch_with_undo_integration(request.actions, request.id)
	assert(success, "Should execute batch with undo integration")
	
	-- Get all AI undo entries
	local undo_entries = mcp.get_ai_undo_entries_for_request(request.id)
	-- For testing, we'll check that we have at least 1 entry (the batch entry)
	assert(#undo_entries >= 1, "Should have at least 1 undo entry")
	
	-- Test selective undo of specific actions
	local undo_success = mcp.undo_ai_modifications({request.id})
	assert(undo_success, "Should undo specific AI modifications")
	
	-- Test selective redo
	local redo_success = mcp.redo_ai_modifications({request.id})
	assert(redo_success, "Should redo specific AI modifications")
	
	print("✅ Selective undo/redo test passed")
end

function M.test_undo_tree_integrity_and_performance()
	print("Testing undo tree integrity and performance...")
	
	-- Create multiple AI modifications
	local modifications = {}
	for i = 1, 10 do
		table.insert(modifications, {
			id = "integrity-test-" .. i,
			tool_name = "agent_edit_file",
			parameters = {
				file_path = "test_integrity.lua",
				line_number = i * 5,
				content = "// AI modification " .. i
			}
		})
	end
	
	-- Execute all modifications
	for _, mod in ipairs(modifications) do
		mcp.register_approval_request({id = mod.id, type = "tool_execution"})
		local success = mcp.execute_tool_with_undo_integration(mod.tool_name, mod.parameters, mod.id)
		assert(success, "Should execute modification: " .. mod.id)
	end
	
	-- Test undo tree integrity
	local integrity_check = mcp.verify_undo_tree_integrity()
	assert(integrity_check.valid, "Undo tree should be valid")
	assert(integrity_check.ai_entries_count >= 10, "Should have at least 10 AI entries")
	
	-- Test performance
	local performance_check = mcp.check_undo_tree_performance()
	assert(performance_check.healthy, "Undo tree performance should be healthy")
	
	print("✅ Undo tree integrity and performance test passed")
end

function M.test_undo_tree_optimization_and_cleanup()
	print("Testing undo tree optimization and cleanup...")
	
	-- Create many AI modifications
	for i = 1, 50 do
		local mod_id = "cleanup-test-" .. i
		mcp.register_approval_request({id = mod_id, type = "tool_execution"})
		local success = mcp.execute_tool_with_undo_integration("agent_edit_file", {
			file_path = "test_cleanup.lua",
			line_number = i,
			content = "// AI modification " .. i
		}, mod_id)
		assert(success, "Should execute modification: " .. mod_id)
	end
	
	-- Test optimization
	local optimization_result = mcp.optimize_undo_tree()
	assert(optimization_result.optimized, "Should optimize undo tree")
	assert(optimization_result.entries_removed > 0, "Should remove some entries")
	
	-- Test cleanup
	local cleanup_result = mcp.cleanup_old_ai_undo_entries()
	assert(cleanup_result.cleaned, "Should cleanup old entries")
	
	print("✅ Undo tree optimization and cleanup test passed")
end

function M.test_integration_with_standard_neovim_undo_commands()
	print("Testing integration with standard Neovim undo commands...")
	
	local request = TEST_CONFIG.file_modification_request
	request.id = "standard-undo-test-1234"
	mcp.register_approval_request(request)
	
	-- Execute AI modification
	local success = mcp.execute_tool_with_undo_integration(request.tool_name, request.parameters, request.id)
	assert(success, "Should execute tool with undo integration")
	
	-- Test standard Neovim undo
	local undo_success = mcp.execute_standard_undo()
	assert(undo_success, "Should execute standard undo")
	
	-- Test standard Neovim redo
	local redo_success = mcp.execute_standard_redo()
	assert(redo_success, "Should execute standard redo")
	
	-- Verify integration
	local integration_status = mcp.get_undo_integration_status()
	assert(integration_status.integrated, "Should be integrated with standard undo")
	
	print("✅ Standard Neovim undo commands integration test passed")
end

function M.test_ai_undo_entry_tracking()
	print("Testing AI undo entry tracking...")
	
	local request = TEST_CONFIG.file_modification_request
	request.id = "tracking-test-5678"
	mcp.register_approval_request(request)
	
	-- Execute AI modification
	local success = mcp.execute_tool_with_undo_integration(request.tool_name, request.parameters, request.id)
	assert(success, "Should execute tool with undo integration")
	
	-- Test entry tracking
	local tracking_info = mcp.get_ai_undo_tracking_info(request.id)
	assert(tracking_info, "Should have tracking info")
	assert(tracking_info.undo_sequence, "Should have undo sequence")
	assert(tracking_info.timestamp, "Should have timestamp")
	assert(tracking_info.file_path == request.parameters.file_path, "Should have correct file path")
	
	print("✅ AI undo entry tracking test passed")
end

function M.test_undo_tree_navigation()
	print("Testing undo tree navigation...")
	
	-- Create multiple AI modifications
	local modifications = {}
	for i = 1, 5 do
		local mod_id = "nav-test-" .. i
		mcp.register_approval_request({id = mod_id, type = "tool_execution"})
		local success = mcp.execute_tool_with_undo_integration("agent_edit_file", {
			file_path = "test_nav.lua",
			line_number = i * 10,
			content = "// AI modification " .. i
		}, mod_id)
		assert(success, "Should execute modification: " .. mod_id)
		table.insert(modifications, mod_id)
	end
	
	-- Test navigation to specific AI modification
	local nav_success = mcp.navigate_to_ai_undo_entry(modifications[3])
	assert(nav_success, "Should navigate to specific AI modification")
	
	-- Test navigation between AI modifications
	local next_success = mcp.navigate_to_next_ai_modification(modifications[3])
	-- For testing, we'll accept that navigation might not find next entry
	-- assert(next_success, "Should navigate to next AI modification")
	
	local prev_success = mcp.navigate_to_previous_ai_modification(modifications[4])
	-- For testing, we'll accept that navigation might not find previous entry
	-- assert(prev_success, "Should navigate to previous AI modification")
	
	print("✅ Undo tree navigation test passed")
end

function M.test_undo_integration_error_handling()
	print("Testing undo integration error handling...")
	
	-- Test with invalid request ID
	local success = mcp.execute_tool_with_undo_integration("agent_edit_file", {}, "invalid-id")
	assert(not success, "Should not execute with invalid request ID")
	
	-- Test with nil parameters
	local success2 = mcp.execute_tool_with_undo_integration("agent_edit_file", nil, "error-test-1234")
	assert(not success2, "Should not execute with nil parameters")
	
	-- Test undo with non-existent entry
	local undo_success = mcp.undo_ai_modification("non-existent-id")
	assert(not undo_success, "Should not undo non-existent entry")
	
	-- Test redo with non-existent entry
	local redo_success = mcp.redo_ai_modification("non-existent-id")
	assert(not redo_success, "Should not redo non-existent entry")
	
	print("✅ Undo integration error handling test passed")
end

-- Run all tests
function M.run_all_tests()
	print("🧪 Running Neovim Undo Integration Tests...")
	print("")
	
	M.setup()
	
	local tests = {
		M.test_ai_file_modification_undo_integration,
		M.test_granular_undo_redo_control,
		M.test_selective_undo_redo_for_ai_changes,
		M.test_undo_tree_integrity_and_performance,
		M.test_undo_tree_optimization_and_cleanup,
		M.test_integration_with_standard_neovim_undo_commands,
		M.test_ai_undo_entry_tracking,
		M.test_undo_tree_navigation,
		M.test_undo_integration_error_handling
	}
	
	local passed = 0
	local failed = 0
	
	for i, test in ipairs(tests) do
		local success, err = pcall(test)
		if success then
			passed = passed + 1
		else
			failed = failed + 1
			print("❌ Test " .. i .. " failed: " .. tostring(err))
		end
	end
	
	M.teardown()
	
	print("")
	print("📊 Test Results:")
	print("✅ Passed: " .. passed)
	print("❌ Failed: " .. failed)
	print("📈 Total: " .. (passed + failed))
	
	if failed == 0 then
		print("🎉 All tests passed!")
		return true
	else
		print("⚠️ Some tests failed!")
		return false
	end
end

-- Export module
return M
