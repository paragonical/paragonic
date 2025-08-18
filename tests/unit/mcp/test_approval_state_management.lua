--[[
Unit tests for Approval State Management
Tests the approval request registration, tracking, and lifecycle management
--]]

local M = {}

-- Test configuration
local TEST_CONFIG = {
	valid_approval_request = {
		id = "approval-1234567890-1234",
		type = "tool_execution",
		status = "pending",
		created_at = os.time(),
		timeout = 30,
		tool_name = "agent_edit_file",
		parameters = {
			file_path = "test.lua",
			line_number = 10,
			content = "// test content"
		},
		impact = "Will modify line 10 in test.lua"
	},
	decision_point_request = {
		id = "approval-1234567890-5678",
		type = "decision_point",
		status = "pending",
		created_at = os.time(),
		timeout = 60,
		question = "Which approach?",
		options = {"A", "B", "C"}
	},
	batch_action_request = {
		id = "approval-1234567890-9012",
		type = "batch_action",
		status = "pending",
		created_at = os.time(),
		timeout = 120,
		actions = {
			{type = "edit", file = "file1.lua"},
			{type = "edit", file = "file2.lua"}
		},
		description = "Refactor multiple files"
	}
}

-- Mock Neovim API for testing
local mock_vim = {
	api = {
		nvim_buf_get_name = function() return "test.lua" end,
		nvim_list_bufs = function() return {1, 2, 3} end,
	},
	notify = function(msg, level) print("NOTIFY: " .. msg) end,
	log = {
		levels = {
			INFO = 1,
			WARN = 2,
			ERROR = 3
		}
	},
	json = {
		encode = function(data) return "encoded:" .. tostring(data) end
	}
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
function M.test_approval_request_registration()
	print("Testing approval request registration...")
	
	local request = TEST_CONFIG.valid_approval_request
	
	-- Register approval request
	local success = mcp.register_approval_request(request)
	assert(success, "Should successfully register approval request")
	
	-- Verify registration
	local registered = mcp.get_approval_request(request.id)
	assert(registered, "Should retrieve registered request")
	assert(registered.id == request.id, "Should have correct ID")
	assert(registered.status == "pending", "Should have pending status")
	
	print("✅ Approval request registration test passed")
end

function M.test_approval_lifecycle_management()
	print("Testing approval lifecycle management...")
	
	local request = TEST_CONFIG.valid_approval_request
	mcp.register_approval_request(request)
	
	-- Test approval
	local success = mcp.approve_request(request.id, {approved = true, user_notes = "Looks good"})
	assert(success, "Should successfully approve request")
	
	local updated = mcp.get_approval_request(request.id)
	assert(updated.status == "approved", "Should have approved status")
	assert(updated.result.approved == true, "Should have approval result")
	assert(updated.result.user_notes == "Looks good", "Should have user notes")
	
	-- Test denial
	local request2 = TEST_CONFIG.decision_point_request
	mcp.register_approval_request(request2)
	
	local success2 = mcp.deny_request(request2.id, {approved = false, reason = "Not needed"})
	assert(success2, "Should successfully deny request")
	
	local updated2 = mcp.get_approval_request(request2.id)
	assert(updated2.status == "denied", "Should have denied status")
	assert(updated2.result.approved == false, "Should have denial result")
	assert(updated2.result.reason == "Not needed", "Should have denial reason")
	
	print("✅ Approval lifecycle management test passed")
end

function M.test_approval_timeout_management()
	print("Testing approval timeout management...")
	
	local request = {
		id = "approval-timeout-test-1234",
		type = "tool_execution",
		status = "pending",
		created_at = os.time(),
		timeout = 1, -- 1 second timeout
		tool_name = "agent_edit_file",
		parameters = {file_path = "timeout_test.lua"}
	}
	mcp.register_approval_request(request)
	
	-- Wait for timeout
	os.execute("sleep 2")
	
	-- Check for timeout
	local updated = mcp.get_approval_request(request.id)
	assert(updated.status == "timeout", "Should have timeout status")
	
	print("✅ Approval timeout management test passed")
end

function M.test_audit_trail_recording()
	print("Testing audit trail recording...")
	
	local request = TEST_CONFIG.valid_approval_request
	request.timeout = 60 -- Set longer timeout for test
	mcp.register_approval_request(request)
	
	-- Approve request
	mcp.approve_request(request.id, {approved = true})
	
	-- Check audit trail
	local audit_entry = mcp.get_audit_entry(request.id)
	assert(audit_entry, "Should have audit entry")
	assert(audit_entry.request_id == request.id, "Should have correct request ID")
	assert(audit_entry.action == "approved", "Should have correct action")
	assert(audit_entry.timestamp, "Should have timestamp")
	
	print("✅ Audit trail recording test passed")
end

function M.test_concurrent_approval_handling()
	print("Testing concurrent approval handling...")
	
	-- Create unique requests for testing
	local requests = {
		{
			id = "approval-1234567890-1111",
			type = "tool_execution",
			status = "pending",
			created_at = os.time(),
			timeout = 60,
			tool_name = "agent_edit_file",
			parameters = {file_path = "test1.lua"}
		},
		{
			id = "approval-1234567890-2222",
			type = "decision_point",
			status = "pending",
			created_at = os.time(),
			timeout = 60,
			question = "Test question",
			options = {"A", "B"}
		},
		{
			id = "approval-1234567890-3333",
			type = "batch_action",
			status = "pending",
			created_at = os.time(),
			timeout = 60,
			actions = {{type = "edit", file = "test3.lua"}}
		}
	}
	
	for _, request in ipairs(requests) do
		local success = mcp.register_approval_request(request)
		assert(success, "Should register request: " .. request.id)
	end
	
	-- Verify all are registered
	local pending_count = mcp.get_pending_approval_count()
	assert(pending_count >= 3, "Should have at least 3 pending requests")
	
	-- Approve one, deny one, leave one pending
	mcp.approve_request(requests[1].id, {approved = true})
	mcp.deny_request(requests[2].id, {approved = false})
	
	-- Check final counts
	local final_pending = mcp.get_pending_approval_count()
	assert(final_pending >= 1, "Should have at least 1 pending request")
	
	print("✅ Concurrent approval handling test passed")
end

function M.test_approval_request_cleanup()
	print("Testing approval request cleanup...")
	
	local request = TEST_CONFIG.valid_approval_request
	mcp.register_approval_request(request)
	
	-- Approve request
	mcp.approve_request(request.id, {approved = true})
	
	-- Clean up completed requests
	local cleaned = mcp.cleanup_completed_approvals()
	assert(cleaned > 0, "Should clean up completed requests")
	
	-- Verify cleanup
	local retrieved = mcp.get_approval_request(request.id)
	assert(not retrieved, "Should not retrieve cleaned up request")
	
	print("✅ Approval request cleanup test passed")
end

function M.test_approval_state_persistence()
	print("Testing approval state persistence...")
	
	local request = TEST_CONFIG.valid_approval_request
	mcp.register_approval_request(request)
	
	-- Save state
	local success = mcp.save_approval_state()
	assert(success, "Should save approval state")
	
	-- Clear state
	mcp.clear_approval_state()
	
	-- Load state
	local success2 = mcp.load_approval_state()
	assert(success2, "Should load approval state")
	
	-- Verify persistence
	local retrieved = mcp.get_approval_request(request.id)
	assert(retrieved, "Should retrieve persisted request")
	
	print("✅ Approval state persistence test passed")
end

-- Run all tests
function M.run_all_tests()
	print("🧪 Running Approval State Management Tests...")
	print("")
	
	M.setup()
	
	local tests = {
		M.test_approval_request_registration,
		M.test_approval_lifecycle_management,
		M.test_approval_timeout_management,
		M.test_audit_trail_recording,
		M.test_concurrent_approval_handling,
		M.test_approval_request_cleanup,
		M.test_approval_state_persistence
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
