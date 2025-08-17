--[[
Simplified unit tests for MCP Sampling Approval functionality
Tests the approval-specific functions without Neovim dependencies
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

-- Test cases
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

function M.test_decision_point_creation()
	print("Testing decision point creation...")
	
	local sampling_data = {
		approval_type = "decision_point",
		question = "Which approach?",
		options = {"A", "B", "C"},
		timeout = 60
	}
	
	local approval_request = mcp.create_approval_request(sampling_data)
	
	assert(approval_request, "Should create decision point request")
	assert(approval_request.type == "decision_point", "Should have correct type")
	assert(approval_request.question == "Which approach?", "Should have question")
	assert(#approval_request.options == 3, "Should have options")
	
	print("✅ Decision point creation test passed")
end

function M.test_batch_action_creation()
	print("Testing batch action creation...")
	
	local sampling_data = {
		approval_type = "batch_action",
		actions = {
			{type = "edit", file = "file1.lua"},
			{type = "edit", file = "file2.lua"}
		},
		description = "Refactor multiple files",
		timeout = 120
	}
	
	local approval_request = mcp.create_approval_request(sampling_data)
	
	assert(approval_request, "Should create batch action request")
	assert(approval_request.type == "batch_action", "Should have correct type")
	assert(#approval_request.actions == 2, "Should have actions")
	assert(approval_request.description == "Refactor multiple files", "Should have description")
	
	print("✅ Batch action creation test passed")
end

function M.test_timeout_handling()
	print("Testing timeout handling...")
	
	local sampling_data = {
		approval_type = "tool_execution",
		tool_name = "agent_edit_file",
		timeout = 0 -- Immediate timeout
	}
	
	local approval_request = mcp.create_approval_request(sampling_data)
	
	assert(approval_request.timeout == 0, "Should have zero timeout")
	
	print("✅ Timeout handling test passed")
end

function M.test_invalid_approval_type()
	print("Testing invalid approval type...")
	
	local request = {
		params = {
			criteria = {
				approval_type = "invalid_type"
			}
		}
	}
	
	local is_valid, error_msg = mcp.validate_approval_request(request)
	
	assert(not is_valid, "Invalid approval type should fail validation")
	assert(error_msg:match("Invalid approval_type"), "Should have appropriate error message")
	
	print("✅ Invalid approval type test passed")
end

-- Run all tests
function M.run_all_tests()
	print("🧪 Running Simplified MCP Sampling Approval Tests...")
	print("")
	
	local tests = {
		M.test_approval_request_validation,
		M.test_approval_request_creation,
		M.test_decision_point_creation,
		M.test_batch_action_creation,
		M.test_timeout_handling,
		M.test_invalid_approval_type
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
