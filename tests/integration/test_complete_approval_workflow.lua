--[[
End-to-End Integration Tests for Complete MCP Sampling Approval Workflow
Tests the complete integration of all components: sampling, approval state, UI, tool execution, and undo integration
--]]

local M = {}

-- Test configuration
local TEST_CONFIG = {
	complete_workflow_request = {
		id = "e2e-workflow-test-1234",
		type = "tool_execution",
		status = "pending",
		created_at = os.time(),
		timeout = 60,
		tool_name = "agent_edit_file",
		parameters = {
			file_path = "test_e2e.lua",
			line_number = 10,
			content = "// E2E test content"
		},
		impact = "Will modify line 10 in test_e2e.lua"
	},
	batch_workflow_request = {
		id = "e2e-batch-test-5678",
		type = "batch_action",
		status = "pending",
		created_at = os.time(),
		timeout = 120,
		actions = {
			{type = "edit", file = "file1.lua", tool_name = "agent_edit_file", line = 5, content = "// E2E edit 1"},
			{type = "edit", file = "file2.lua", tool_name = "agent_edit_file", line = 15, content = "// E2E edit 2"},
			{type = "create", file = "file3.lua", tool_name = "agent_create_file", content = "// E2E created file"}
		},
		description = "E2E batch modifications"
	},
	decision_workflow_request = {
		id = "e2e-decision-test-9012",
		type = "decision_point",
		status = "pending",
		created_at = os.time(),
		timeout = 60,
		question = "Which approach should be used for E2E testing?",
		options = {
			"Option A: Comprehensive testing",
			"Option B: Minimal testing",
			"Option C: Balanced testing"
		}
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
			return "test_e2e.lua" -- Mock buffer name
		end,
		nvim_buf_is_valid = function(buf)
			return buf == 1001 -- Mock buffer validation
		end,
		nvim_open_win = function(buf, enter, config)
			return 2001 -- Mock window ID
		end,
		nvim_win_set_option = function(win, option, value)
			-- Mock window option setting
		end,
		nvim_win_is_valid = function(win)
			return win == 2001 -- Mock window validation
		end,
		nvim_win_close = function(win, force)
			-- Mock window closing
		end,
		nvim_buf_delete = function(buf, opts)
			-- Mock buffer deletion
		end,
		nvim_command = function(cmd)
			-- Mock command execution
		end,
		nvim_set_current_win = function(win)
			-- Mock window switching
		end,
		nvim_eval = function(expr)
			if expr == "&undolevels" then
				return 1000 -- Mock undo levels
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
	keymap = {
		set = function(mode, lhs, rhs, opts)
			-- Mock keymap setting
		end
	},
	ui = {
		select = function(items, opts, on_choice)
			-- Mock UI selection
			if on_choice then
				on_choice(1, items[1]) -- Mock first choice
			end
		end,
		input = function(opts, on_confirm)
			-- Mock input dialog
			if on_confirm then
				on_confirm("test input") -- Mock input
			end
		end
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
	},
	inspect = function(value)
		return tostring(value)
	end
}

-- Set up global vim mock
_G.vim = mock_vim

-- Load MCP module
local mcp = require("paragonic.mcp")

-- Test suite setup
function M.setup()
	-- Initialize all MCP components
	if mcp.initialize_mcp_server then
		mcp.initialize_mcp_server()
	end
	if mcp.initialize_approval_state then
		mcp.initialize_approval_state()
	end
	
	-- Initialize undo integration
	local undo = require("paragonic.mcp_undo_integration")
	if undo.initialize then
		undo.initialize()
	end
end

function M.teardown()
	-- Cleanup all components
	if mcp.clear_approval_state then
		mcp.clear_approval_state()
	end
	
	-- Clear undo entries
	local undo = require("paragonic.mcp_undo_integration")
	if undo.clear_all_ai_undo_entries then
		undo.clear_all_ai_undo_entries()
	end
end

-- Test cases
function M.test_complete_approval_workflow()
	print("Testing complete approval workflow...")
	
	local request = TEST_CONFIG.complete_workflow_request
	
	-- Step 1: Register approval request
	local register_success = mcp.register_approval_request(request)
	assert(register_success, "Should register approval request")
	
	-- Step 2: Create approval dialog
	local dialog = mcp.create_approval_dialog(request.id)
	assert(dialog, "Should create approval dialog")
	assert(dialog.request_id == request.id, "Should have correct request ID")
	
	-- Step 3: Display dialog
	local display_success = mcp.display_approval_dialog(dialog)
	assert(display_success, "Should display approval dialog")
	
	-- Step 4: Execute tool with undo integration
	local execution_success = mcp.execute_tool_with_undo_integration(request.tool_name, request.parameters, request.id)
	assert(execution_success, "Should execute tool with undo integration")
	
	-- Step 5: Handle user approval
	local approval_success = mcp.handle_user_approval(dialog, {approved = true, notes = "E2E test approval"})
	assert(approval_success, "Should handle user approval")
	
	-- Step 6: Verify approval state
	local approval = mcp.get_approval_request(request.id)
	assert(approval.status == "approved", "Should have approved status")
	assert(approval.result.approved == true, "Should have approval result")
	
	-- Step 7: Verify tool execution status
	local execution_status = mcp.get_tool_execution_status(request.id)
	assert(execution_status == "waiting_approval" or execution_status == "completed", "Should have appropriate execution status")
	
	-- Step 8: Verify undo integration
	local undo_entry = mcp.get_ai_undo_entry(request.id)
	assert(undo_entry, "Should have AI undo entry")
	assert(undo_entry.tool_name == request.tool_name, "Should have correct tool name")
	
	print("✅ Complete approval workflow test passed")
end

function M.test_mcp_protocol_compliance()
	print("Testing MCP protocol compliance...")
	
	-- Test MCP sampling request handling
	local sampling_request = {
		id = "protocol-test-1234",
		uri = "approval://tool_execution",
		criteria = {
			approval_type = "tool_execution",
			tool_name = "agent_edit_file",
			parameters = {
				file_path = "test_protocol.lua",
				line_number = 10,
				content = "// Protocol test"
			},
			timeout = 30
		}
	}
	
	-- Test direct sampling request handling
	local response = mcp.handle_sampling_request(sampling_request)
	assert(response, "Should handle MCP sampling request")
	assert(response.result, "Should have result")
	assert(response.result.approval_request, "Should have approval request")
	
	-- Test MCP error handling
	local invalid_request = {
		id = "error-test-5678",
		uri = "invalid://uri"
	}
	
	local error_response = mcp.handle_sampling_request(invalid_request)
	assert(error_response, "Should handle invalid request")
	assert(error_response.error, "Should have error")
	
	print("✅ MCP protocol compliance test passed")
end

function M.test_ui_integration_across_contexts()
	print("Testing UI integration across different Neovim contexts...")
	
	local request = TEST_CONFIG.decision_workflow_request
	mcp.register_approval_request(request)
	
	-- Test dialog creation in different contexts
	local dialog = mcp.create_decision_point_dialog(request.id)
	assert(dialog, "Should create decision point dialog")
	
	-- Test dialog state management
	local dialog_state = mcp.get_dialog_state(dialog)
	assert(dialog_state.status == "open", "Should have open status")
	assert(dialog_state.request_id == request.id, "Should have correct request ID")
	
	-- Test dialog closure
	local close_success = mcp.close_approval_dialog(dialog)
	assert(close_success, "Should close dialog")
	
	-- Verify dialog is closed
	local closed_state = mcp.get_dialog_state(dialog)
	assert(closed_state.status == "closed", "Should have closed status")
	
	print("✅ UI integration test passed")
end

function M.test_security_and_safety_mechanisms()
	print("Testing security and safety mechanisms...")
	
	-- Test invalid request handling
	local invalid_request = {
		id = "security-test-1234",
		type = "tool_execution",
		tool_name = "invalid_tool",
		parameters = {}
	}
	
	local register_success = mcp.register_approval_request(invalid_request)
	assert(register_success, "Should register invalid request")
	
	-- Test execution with invalid tool
	local execution_success = mcp.execute_tool_with_approval(invalid_request.tool_name, invalid_request.parameters, invalid_request.id)
	assert(not execution_success, "Should not execute invalid tool")
	
	-- Test timeout handling
	local timeout_request = {
		id = "timeout-test-5678",
		type = "tool_execution",
		tool_name = "agent_edit_file",
		parameters = {file_path = "test.lua"},
		timeout = 1 -- 1 second timeout
	}
	
	mcp.register_approval_request(timeout_request)
	os.execute("sleep 2") -- Wait for timeout
	
	local timeout_approval = mcp.get_approval_request(timeout_request.id)
	assert(timeout_approval.status == "timeout", "Should have timeout status")
	
	print("✅ Security and safety mechanisms test passed")
end

function M.test_performance_and_concurrent_operations()
	print("Testing performance and concurrent operations...")
	
	-- Create multiple concurrent requests
	local concurrent_requests = {}
	for i = 1, 10 do
		local request = {
			id = "concurrent-test-" .. i,
			type = "tool_execution",
			tool_name = "agent_edit_file",
			parameters = {
				file_path = "test_concurrent_" .. i .. ".lua",
				line_number = i * 10,
				content = "// Concurrent test " .. i
			}
		}
		table.insert(concurrent_requests, request)
	end
	
	-- Register all requests concurrently
	for _, request in ipairs(concurrent_requests) do
		local success = mcp.register_approval_request(request)
		assert(success, "Should register request: " .. request.id)
	end
	
	-- Execute all tools concurrently
	for _, request in ipairs(concurrent_requests) do
		local success = mcp.execute_tool_with_approval(request.tool_name, request.parameters, request.id)
		assert(success, "Should execute tool: " .. request.id)
	end
	
	-- Verify all are pending
	local pending_count = mcp.get_pending_approval_count()
	assert(pending_count >= 10, "Should have at least 10 pending requests")
	
	-- Test performance under load
	local start_time = os.time()
	for _, request in ipairs(concurrent_requests) do
		mcp.approve_request(request.id, {approved = true})
	end
	local end_time = os.time()
	
	local processing_time = end_time - start_time
	assert(processing_time < 5, "Should process requests quickly: " .. processing_time .. "s")
	
	print("✅ Performance and concurrent operations test passed")
end

function M.test_undo_system_integration_and_performance()
	print("Testing undo system integration and performance...")
	
	-- Create multiple AI modifications
	local modifications = {}
	for i = 1, 20 do
		local mod_id = "undo-perf-test-" .. i
		mcp.register_approval_request({id = mod_id, type = "tool_execution"})
		local success = mcp.execute_tool_with_undo_integration("agent_edit_file", {
			file_path = "test_undo_perf.lua",
			line_number = i * 5,
			content = "// Undo performance test " .. i
		}, mod_id)
		assert(success, "Should execute modification: " .. mod_id)
		table.insert(modifications, mod_id)
	end
	
	-- Test undo tree integrity
	local integrity_check = mcp.verify_undo_tree_integrity()
	assert(integrity_check.valid, "Undo tree should be valid")
	assert(integrity_check.ai_entries_count >= 20, "Should have at least 20 AI entries")
	
	-- Test undo performance
	local start_time = os.time()
	for i = 1, 5 do
		local undo_success = mcp.undo_ai_modification(modifications[i])
		assert(undo_success, "Should undo modification: " .. modifications[i])
	end
	local end_time = os.time()
	
	local undo_time = end_time - start_time
	assert(undo_time < 3, "Should undo quickly: " .. undo_time .. "s")
	
	-- Test redo performance
	local start_time2 = os.time()
	for i = 1, 5 do
		local redo_success = mcp.redo_ai_modification(modifications[i])
		assert(redo_success, "Should redo modification: " .. modifications[i])
	end
	local end_time2 = os.time()
	
	local redo_time = end_time2 - start_time2
	assert(redo_time < 3, "Should redo quickly: " .. redo_time .. "s")
	
	print("✅ Undo system integration and performance test passed")
end

function M.test_comprehensive_error_recovery()
	print("Testing comprehensive error recovery...")
	
	-- Test recovery from invalid state
	local invalid_state_request = {
		id = "error-recovery-test-1234",
		type = "tool_execution",
		tool_name = "agent_edit_file",
		parameters = nil -- Invalid parameters
	}
	
	-- Should handle gracefully
	local register_success = mcp.register_approval_request(invalid_state_request)
	assert(register_success, "Should register request with invalid parameters")
	
	local execution_success = mcp.execute_tool_with_approval(invalid_state_request.tool_name, invalid_state_request.parameters, invalid_state_request.id)
	assert(not execution_success, "Should not execute with invalid parameters")
	
	-- Test recovery from dialog errors
	local dialog_error_request = {
		id = "dialog-error-test-5678",
		type = "tool_execution",
		tool_name = "agent_edit_file",
		parameters = {file_path = "test.lua"}
	}
	
	mcp.register_approval_request(dialog_error_request)
	local dialog = mcp.create_approval_dialog(dialog_error_request.id)
	assert(dialog, "Should create dialog even after errors")
	
	-- Test recovery from undo errors
	local undo_error_request = {
		id = "undo-error-test-9012",
		type = "tool_execution",
		tool_name = "agent_edit_file",
		parameters = {file_path = "test.lua"}
	}
	
	mcp.register_approval_request(undo_error_request)
	local undo_success = mcp.execute_tool_with_undo_integration(undo_error_request.tool_name, undo_error_request.parameters, undo_error_request.id)
	assert(undo_success, "Should execute with undo integration after errors")
	
	print("✅ Comprehensive error recovery test passed")
end

-- Run all tests
function M.run_all_tests()
	print("🧪 Running End-to-End Integration Tests...")
	print("")
	
	M.setup()
	
	local tests = {
		M.test_complete_approval_workflow,
		M.test_mcp_protocol_compliance,
		M.test_ui_integration_across_contexts,
		M.test_security_and_safety_mechanisms,
		M.test_performance_and_concurrent_operations,
		M.test_undo_system_integration_and_performance,
		M.test_comprehensive_error_recovery
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
