--[[
Unit tests for Tool Execution Integration
Tests the approval workflow integration with existing tool calls
--]]

local M = {}

-- Test configuration
local TEST_CONFIG = {
	tool_execution_request = {
		id = "tool-exec-test-1234",
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
	auto_approved_tool = {
		id = "auto-approve-test-5678",
		type = "tool_execution",
		status = "pending",
		created_at = os.time(),
		timeout = 60,
		tool_name = "agent_session_info",
		parameters = {},
		impact = "Will retrieve session information"
	},
	batch_tool_request = {
		id = "batch-tool-test-9012",
		type = "batch_action",
		status = "pending",
		created_at = os.time(),
		timeout = 120,
		actions = {
			{type = "edit", file = "file1.lua", tool_name = "agent_edit_file"},
			{type = "edit", file = "file2.lua", tool_name = "agent_edit_file"},
			{type = "create", file = "file3.lua", tool_name = "agent_create_file"}
		},
		description = "Refactor multiple files"
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
function M.test_approval_workflow_integration()
	print("Testing approval workflow integration with existing tool calls...")
	
	local request = TEST_CONFIG.tool_execution_request
	mcp.register_approval_request(request)
	
	-- Simulate tool execution with approval workflow
	local success = mcp.execute_tool_with_approval(request.tool_name, request.parameters, request.id)
	assert(success, "Should execute tool with approval workflow")
	
	-- Verify approval request was created
	local approval = mcp.get_approval_request(request.id)
	assert(approval, "Should have approval request")
	assert(approval.status == "pending", "Should be pending approval")
	
	print("✅ Approval workflow integration test passed")
end

function M.test_approval_bypass_for_auto_approved_tools()
	print("Testing approval bypass for auto-approved tools...")
	
	local request = TEST_CONFIG.auto_approved_tool
	mcp.register_approval_request(request)
	
	-- Simulate auto-approved tool execution
	local success = mcp.execute_tool_with_approval(request.tool_name, request.parameters, request.id)
	assert(success, "Should execute auto-approved tool")
	
	-- Verify approval was bypassed
	local approval = mcp.get_approval_request(request.id)
	assert(approval, "Should have approval request")
	assert(approval.status == "approved", "Should be auto-approved")
	
	print("✅ Approval bypass test passed")
end

function M.test_tool_execution_cancellation_on_denial()
	print("Testing tool execution cancellation on approval denial...")
	
	local request = TEST_CONFIG.tool_execution_request
	request.id = "denial-test-1234" -- Unique ID
	mcp.register_approval_request(request)
	
	-- Simulate tool execution
	local success = mcp.execute_tool_with_approval(request.tool_name, request.parameters, request.id)
	assert(success, "Should start tool execution")
	
	-- Deny the approval
	local deny_success = mcp.deny_request(request.id, {approved = false, reason = "Not needed"})
	assert(deny_success, "Should deny approval")
	
	-- Verify tool execution was cancelled
	local approval = mcp.get_approval_request(request.id)
	assert(approval.status == "denied", "Should be denied")
	
	-- Check that tool execution was cancelled
	local execution_status = mcp.get_tool_execution_status(request.id)
	assert(execution_status == "cancelled", "Tool execution should be cancelled")
	
	print("✅ Tool execution cancellation test passed")
end

function M.test_modified_tool_execution_handling()
	print("Testing modified tool execution based on user input...")
	
	local request = TEST_CONFIG.tool_execution_request
	request.id = "modify-test-5678" -- Unique ID
	mcp.register_approval_request(request)
	
	-- Simulate tool execution with modification
	local modified_params = {
		file_path = "modified_test.lua",
		line_number = 15,
		content = "// modified content"
	}
	
	local success = mcp.execute_tool_with_modification(request.tool_name, request.parameters, modified_params, request.id)
	assert(success, "Should execute tool with modification")
	
	-- Verify modification was applied
	local approval = mcp.get_approval_request(request.id)
	assert(approval.result.modified_parameters, "Should have modified parameters")
	assert(approval.result.modified_parameters.file_path == "modified_test.lua", "Should have modified file path")
	
	print("✅ Modified tool execution test passed")
end

function M.test_batch_tool_execution_integration()
	print("Testing batch tool execution integration...")
	
	local request = TEST_CONFIG.batch_tool_request
	mcp.register_approval_request(request)
	
	-- Simulate batch tool execution
	local success = mcp.execute_batch_tools_with_approval(request.actions, request.id)
	assert(success, "Should execute batch tools with approval")
	
	-- Verify batch approval request
	local approval = mcp.get_approval_request(request.id)
	assert(approval, "Should have batch approval request")
	assert(approval.status == "pending", "Should be pending batch approval")
	
	print("✅ Batch tool execution integration test passed")
end

function M.test_partial_batch_approval_execution()
	print("Testing partial batch approval execution...")
	
	local request = TEST_CONFIG.batch_tool_request
	request.id = "partial-batch-test-9012" -- Unique ID
	mcp.register_approval_request(request)
	
	-- Simulate partial approval
	local approved_actions = {1, 3} -- Approve actions 1 and 3
	local success = mcp.execute_partial_batch_approval(request.actions, approved_actions, request.id)
	assert(success, "Should execute partial batch approval")
	
	-- Verify partial execution
	local approval = mcp.get_approval_request(request.id)
	assert(approval.result.approved_actions, "Should have approved actions")
	assert(#approval.result.approved_actions == 2, "Should have 2 approved actions")
	
	print("✅ Partial batch approval execution test passed")
end

function M.test_tool_execution_timeout_handling()
	print("Testing tool execution timeout handling...")
	
	local request = TEST_CONFIG.tool_execution_request
	request.id = "timeout-exec-test-3456" -- Unique ID
	request.timeout = 1 -- 1 second timeout
	mcp.register_approval_request(request)
	
	-- Simulate tool execution
	local success = mcp.execute_tool_with_approval(request.tool_name, request.parameters, request.id)
	assert(success, "Should start tool execution")
	
	-- Wait for timeout
	os.execute("sleep 2")
	
	-- Verify timeout handling
	local approval = mcp.get_approval_request(request.id)
	assert(approval.status == "timeout", "Should have timeout status")
	
	-- Check that tool execution was cancelled on timeout
	local execution_status = mcp.get_tool_execution_status(request.id)
	assert(execution_status == "timeout", "Tool execution should be timeout")
	
	print("✅ Tool execution timeout handling test passed")
end

function M.test_concurrent_tool_execution_approval()
	print("Testing concurrent tool execution approval...")
	
	-- Create multiple tool execution requests
	local requests = {
		{
			id = "concurrent-1",
			type = "tool_execution",
			tool_name = "agent_edit_file",
			parameters = {file_path = "file1.lua"}
		},
		{
			id = "concurrent-2",
			type = "tool_execution",
			tool_name = "agent_create_file",
			parameters = {file_path = "file2.lua"}
		},
		{
			id = "concurrent-3",
			type = "tool_execution",
			tool_name = "agent_search_files",
			parameters = {query = "test"}
		}
	}
	
	-- Register all requests
	for _, req in ipairs(requests) do
		mcp.register_approval_request(req)
	end
	
	-- Execute all tools concurrently
	for _, req in ipairs(requests) do
		local success = mcp.execute_tool_with_approval(req.tool_name, req.parameters, req.id)
		assert(success, "Should execute tool: " .. req.id)
	end
	
	-- Verify all are pending
	local pending_count = mcp.get_pending_approval_count()
	assert(pending_count >= 3, "Should have at least 3 pending approvals")
	
	-- Approve one, deny one, leave one pending
	mcp.approve_request(requests[1].id, {approved = true})
	mcp.deny_request(requests[2].id, {approved = false})
	
	-- Check final state
	local final_pending = mcp.get_pending_approval_count()
	assert(final_pending >= 1, "Should have at least 1 pending approval")
	
	print("✅ Concurrent tool execution approval test passed")
end

function M.test_tool_execution_error_handling()
	print("Testing tool execution error handling...")
	
	-- Test with invalid tool name
	local success = mcp.execute_tool_with_approval("invalid_tool", {}, "error-test-1234")
	assert(not success, "Should not execute invalid tool")
	
	-- Test with nil parameters
	local success2 = mcp.execute_tool_with_approval("agent_edit_file", nil, "error-test-5678")
	assert(not success2, "Should not execute tool with nil parameters")
	
	-- Test with invalid request ID
	local success3 = mcp.execute_tool_with_approval("agent_edit_file", {}, nil)
	assert(not success3, "Should not execute tool with nil request ID")
	
	print("✅ Tool execution error handling test passed")
end

-- Run all tests
function M.run_all_tests()
	print("🧪 Running Tool Execution Integration Tests...")
	print("")
	
	M.setup()
	
	local tests = {
		M.test_approval_workflow_integration,
		M.test_approval_bypass_for_auto_approved_tools,
		M.test_tool_execution_cancellation_on_denial,
		M.test_modified_tool_execution_handling,
		M.test_batch_tool_execution_integration,
		M.test_partial_batch_approval_execution,
		M.test_tool_execution_timeout_handling,
		M.test_concurrent_tool_execution_approval,
		M.test_tool_execution_error_handling
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
