--[[
Unit tests for MCP Sampling Approval functionality
Tests the enhanced sampling request handler for approval workflows
--]]

local M = {}

-- Test configuration
local TEST_CONFIG = {
	valid_approval_request = {
		jsonrpc = "2.0",
		id = "test-1",
		method = "sampling/request",
		params = {
			uri = "approval://tool-execution",
			criteria = {
				approval_type = "tool_execution",
				tool_name = "agent_edit_file",
				parameters = {
					file_path = "test.lua",
					line_number = 10,
					content = "// test content"
				},
				impact = "Will modify line 10 in test.lua",
				timeout = 30
			}
		}
	},
	invalid_approval_request = {
		jsonrpc = "2.0",
		id = "test-2",
		method = "sampling/request",
		params = {
			uri = "approval://tool-execution",
			criteria = {
				-- Missing required fields
			}
		}
	},
	decision_point_request = {
		jsonrpc = "2.0",
		id = "test-3",
		method = "sampling/request",
		params = {
			uri = "approval://decision-point",
			criteria = {
				approval_type = "decision_point",
				question = "Which approach should I use for this refactoring?",
				options = {
					"Option A: Incremental refactoring",
					"Option B: Complete rewrite",
					"Option C: Hybrid approach"
				},
				timeout = 60
			}
		}
	}
}

-- Load actual MCP module for testing
local mcp = require("paragonic.mcp")

-- Test suite setup
function M.setup()
	-- Setup test environment
	-- No special setup needed for actual MCP module
end

function M.teardown()
	-- Cleanup test environment
	-- No special cleanup needed
end

-- Test cases
function M.test_approval_request_parsing()
	print("Testing approval request parsing...")
	
	local request = TEST_CONFIG.valid_approval_request
	local success, result = pcall(mcp.handle_sampling_request, request)
	
	assert(success, "Request parsing should not throw errors")
	assert(result, "Should return a result")
	assert(result.id == request.id, "Should preserve request ID")
	assert(result.result, "Should have result object")
	assert(result.result.approval_request, "Should have approval request")
	
	print("✅ Approval request parsing test passed")
end

function M.test_approval_request_validation()
	print("Testing approval request validation...")
	
	-- Test valid request
	local valid_request = TEST_CONFIG.valid_approval_request
	local is_valid, error_msg = mcp.validate_approval_request(valid_request)
	
	assert(is_valid, "Valid request should pass validation")
	assert(not error_msg, "Valid request should not have error message")
	
	-- Test invalid request
	local invalid_request = TEST_CONFIG.invalid_approval_request
	local is_invalid, error_msg = mcp.validate_approval_request(invalid_request)
	
	assert(not is_invalid, "Invalid request should fail validation")
	assert(error_msg, "Invalid request should have error message")
	assert(type(error_msg) == "string", "Error message should be a string")
	
	print("✅ Approval request validation test passed")
end

function M.test_approval_request_creation()
	print("Testing approval request creation...")
	
	local sampling_data = {
		approval_type = "tool_execution",
		tool_name = "agent_edit_file",
		timeout = 45
	}
	
	local approval_request = mcp.create_approval_request(sampling_data)
	
	assert(approval_request, "Should create approval request")
	assert(approval_request.id, "Should have ID")
	assert(approval_request.type == "tool_execution", "Should have correct type")
	assert(approval_request.status == "pending", "Should have pending status")
	assert(approval_request.timeout == 45, "Should have correct timeout")
	
	print("✅ Approval request creation test passed")
end

function M.test_decision_point_request()
	print("Testing decision point request...")
	
	local request = TEST_CONFIG.decision_point_request
	local success, result = pcall(mcp.handle_sampling_request, request)
	
	assert(success, "Decision point request should not throw errors")
	assert(result, "Should return a result")
	assert(result.result.approval_request, "Should have approval request")
	
	print("✅ Decision point request test passed")
end

function M.test_error_handling()
	print("Testing error handling...")
	
	-- Test with nil request
	local success, result = pcall(mcp.handle_sampling_request, nil)
	assert(success, "Nil request should be handled gracefully")
	assert(result.error, "Should return error for nil request")
	
	-- Test with invalid JSON-RPC format
	local invalid_request = {
		-- Missing required fields
	}
	local success2, result2 = pcall(mcp.handle_sampling_request, invalid_request)
	assert(success2, "Should handle invalid format gracefully")
	
	print("✅ Error handling test passed")
end

function M.test_timeout_handling()
	print("Testing timeout handling...")
	
	local request = TEST_CONFIG.valid_approval_request
	request.params.criteria.timeout = 0 -- Immediate timeout
	
	local success, result = pcall(mcp.handle_sampling_request, request)
	assert(success, "Timeout request should not throw errors")
	assert(result.result.approval_request.status == "timeout", "Should mark as timeout")
	
	print("✅ Timeout handling test passed")
end

-- Run all tests
function M.run_all_tests()
	print("🧪 Running MCP Sampling Approval Tests...")
	print("")
	
	M.setup()
	
	local tests = {
		M.test_approval_request_parsing,
		M.test_approval_request_validation,
		M.test_approval_request_creation,
		M.test_decision_point_request,
		M.test_error_handling,
		M.test_timeout_handling
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
