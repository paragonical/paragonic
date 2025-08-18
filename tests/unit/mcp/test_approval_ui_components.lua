--[[
Unit tests for Approval UI Components
Tests the approval dialog creation, display, and user interaction handling
--]]

local M = {}

-- Test configuration
local TEST_CONFIG = {
	valid_approval_request = {
		id = "approval-ui-test-1234",
		type = "tool_execution",
		status = "pending",
		created_at = os.time(),
		timeout = 60,
		tool_name = "agent_edit_file",
		parameters = {
			file_path = "test.lua",
			line_number = 10,
			content = "// test content"
		},
		impact = "Will modify line 10 in test.lua"
	},
	decision_point_request = {
		id = "approval-ui-test-5678",
		type = "decision_point",
		status = "pending",
		created_at = os.time(),
		timeout = 60,
		question = "Which approach should I use?",
		options = {
			"Option A: Incremental refactoring",
			"Option B: Complete rewrite",
			"Option C: Hybrid approach"
		}
	},
	batch_action_request = {
		id = "approval-ui-test-9012",
		type = "batch_action",
		status = "pending",
		created_at = os.time(),
		timeout = 120,
		actions = {
			{type = "edit", file = "file1.lua", description = "Update function signature"},
			{type = "edit", file = "file2.lua", description = "Add error handling"},
			{type = "create", file = "file3.lua", description = "Create new utility module"}
		},
		description = "Refactor authentication system"
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
		nvim_open_win = function(buf, enter, config)
			return 2001 -- Mock window ID
		end,
		nvim_win_set_option = function(win, option, value)
			-- Mock window option setting
		end,
		nvim_command = function(cmd)
			-- Mock command execution
		end,
		nvim_set_current_buf = function(buf)
			-- Mock buffer switching
		end,
		nvim_get_current_buf = function()
			return 1001 -- Mock current buffer
		end,
		nvim_list_wins = function()
			return {2001, 2002} -- Mock window list
		end,
		nvim_win_close = function(win, force)
			-- Mock window closing
		end,
		nvim_buf_delete = function(buf, opts)
			-- Mock buffer deletion
		end,
		nvim_win_is_valid = function(win)
			return win == 2001 -- Mock window validation
		end,
		nvim_buf_is_valid = function(buf)
			return buf == 1001 -- Mock buffer validation
		end,
		nvim_set_current_win = function(win)
			-- Mock window switching
		end
	},
	o = {
		lines = 50,
		columns = 100
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
	-- Initialize approval state management
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
function M.test_approval_dialog_creation()
	print("Testing approval dialog creation...")
	
	local request = TEST_CONFIG.valid_approval_request
	mcp.register_approval_request(request)
	
	-- Create approval dialog
	local dialog = mcp.create_approval_dialog(request.id)
	assert(dialog, "Should create approval dialog")
	assert(dialog.buffer_id, "Should have buffer ID")
	assert(dialog.window_id, "Should have window ID")
	assert(dialog.request_id == request.id, "Should have correct request ID")
	
	print("✅ Approval dialog creation test passed")
end

function M.test_approval_dialog_display()
	print("Testing approval dialog display...")
	
	local request = TEST_CONFIG.valid_approval_request
	mcp.register_approval_request(request)
	
	-- Create and display dialog
	local dialog = mcp.create_approval_dialog(request.id)
	local success = mcp.display_approval_dialog(dialog)
	
	assert(success, "Should display approval dialog successfully")
	
	print("✅ Approval dialog display test passed")
end

function M.test_user_interaction_handling()
	print("Testing user interaction handling...")
	
	local request = TEST_CONFIG.valid_approval_request
	mcp.register_approval_request(request)
	
	-- Create dialog
	local dialog = mcp.create_approval_dialog(request.id)
	
	-- Test approve interaction
	local success = mcp.handle_user_approval(dialog, {approved = true, notes = "Looks good"})
	assert(success, "Should handle approval interaction")
	
	-- Verify approval
	local updated = mcp.get_approval_request(request.id)
	assert(updated.status == "approved", "Should have approved status")
	
	print("✅ User interaction handling test passed")
end

function M.test_approval_denial_handling()
	print("Testing approval denial handling...")
	
	local request = TEST_CONFIG.decision_point_request
	mcp.register_approval_request(request)
	
	-- Create dialog
	local dialog = mcp.create_approval_dialog(request.id)
	
	-- Test deny interaction
	local success = mcp.handle_user_denial(dialog, {approved = false, reason = "Not needed"})
	assert(success, "Should handle denial interaction")
	
	-- Verify denial
	local updated = mcp.get_approval_request(request.id)
	assert(updated.status == "denied", "Should have denied status")
	
	print("✅ Approval denial handling test passed")
end

function M.test_dialog_timeout_handling()
	print("Testing dialog timeout handling...")
	
	local request = {
		id = "approval-timeout-ui-test-1234",
		type = "tool_execution",
		status = "pending",
		created_at = os.time(),
		timeout = 1, -- 1 second timeout
		tool_name = "agent_edit_file",
		parameters = {file_path = "timeout_test.lua"}
	}
	mcp.register_approval_request(request)
	
	-- Create dialog
	local dialog = mcp.create_approval_dialog(request.id)
	
	-- Wait for timeout
	os.execute("sleep 2")
	
	-- Check for timeout
	local updated = mcp.get_approval_request(request.id)
	assert(updated.status == "timeout", "Should have timeout status")
	
	-- Dialog should be closed automatically
	local is_open = mcp.is_dialog_open(dialog)
	assert(not is_open, "Dialog should be closed on timeout")
	
	print("✅ Dialog timeout handling test passed")
end

function M.test_ui_state_management()
	print("Testing UI state management...")
	
	local request = TEST_CONFIG.valid_approval_request
	mcp.register_approval_request(request)
	
	-- Create dialog
	local dialog = mcp.create_approval_dialog(request.id)
	
	-- Test UI state updates
	local state = mcp.get_dialog_state(dialog)
	assert(state.status == "open", "Should have open status")
	assert(state.request_id == request.id, "Should have correct request ID")
	
	-- Close dialog
	mcp.close_approval_dialog(dialog)
	
	-- Check closed state
	local closed_state = mcp.get_dialog_state(dialog)
	assert(closed_state.status == "closed", "Should have closed status")
	
	print("✅ UI state management test passed")
end

function M.test_error_handling()
	print("Testing error handling...")
	
	-- Test with invalid request ID
	local dialog = mcp.create_approval_dialog("invalid-id")
	assert(not dialog, "Should not create dialog for invalid request")
	
	-- Test with nil request
	local dialog2 = mcp.create_approval_dialog(nil)
	assert(not dialog2, "Should not create dialog for nil request")
	
	-- Test display with invalid dialog
	local success = mcp.display_approval_dialog(nil)
	assert(not success, "Should not display invalid dialog")
	
	print("✅ Error handling test passed")
end

function M.test_decision_point_ui()
	print("Testing decision point UI...")
	
	local request = {
		id = "approval-decision-ui-test-5678",
		type = "decision_point",
		status = "pending",
		created_at = os.time(),
		timeout = 60,
		question = "Which approach should I use?",
		options = {
			"Option A: Incremental refactoring",
			"Option B: Complete rewrite",
			"Option C: Hybrid approach"
		}
	}
	mcp.register_approval_request(request)
	
	-- Create decision point dialog
	local dialog = mcp.create_decision_point_dialog(request.id)
	assert(dialog, "Should create decision point dialog")
	
	-- Test option selection
	local success = mcp.handle_option_selection(dialog, 1) -- Select first option
	assert(success, "Should handle option selection")
	
	-- Verify selection
	local updated = mcp.get_approval_request(request.id)
	assert(updated.result.selected_option == 1, "Should have selected option")
	
	print("✅ Decision point UI test passed")
end

function M.test_batch_action_ui()
	print("Testing batch action UI...")
	
	local request = TEST_CONFIG.batch_action_request
	mcp.register_approval_request(request)
	
	-- Create batch action dialog
	local dialog = mcp.create_batch_action_dialog(request.id)
	assert(dialog, "Should create batch action dialog")
	
	-- Test partial approval
	local success = mcp.handle_partial_approval(dialog, {1, 3}) -- Approve actions 1 and 3
	assert(success, "Should handle partial approval")
	
	-- Verify partial approval
	local updated = mcp.get_approval_request(request.id)
	assert(updated.result.approved_actions, "Should have approved actions")
	assert(#updated.result.approved_actions == 2, "Should have 2 approved actions")
	
	print("✅ Batch action UI test passed")
end

-- Run all tests
function M.run_all_tests()
	print("🧪 Running Approval UI Components Tests...")
	print("")
	
	M.setup()
	
	local tests = {
		M.test_approval_dialog_creation,
		M.test_approval_dialog_display,
		M.test_user_interaction_handling,
		M.test_approval_denial_handling,
		M.test_dialog_timeout_handling,
		M.test_ui_state_management,
		M.test_error_handling,
		M.test_decision_point_ui,
		M.test_batch_action_ui
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
