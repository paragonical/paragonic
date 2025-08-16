--[[
Test MCP Thinking Model Support
Tests the new MCP methods for AI thinking model capabilities
--]]

local M = {}

-- Test configuration
local TEST_CONFIG = {
	base_url = "http://localhost:3000",
	test_prompt = "Explain quantum computing in simple terms",
	test_model = "deepseek-r1:1.5b",
	timeout = 30,
}

-- Initialize test environment
function M.setup_test_environment()
	print("🧪 Setting up MCP thinking model test environment...")

	-- Load required modules
	local mcp_thinking = require("paragonic.mcp_thinking_support")
	local mcp_http_transport = require("paragonic.mcp_http_transport")

	-- Initialize MCP transport
	local ok, err = mcp_http_transport.init({
		base_url = TEST_CONFIG.base_url,
		protocol_version = "2025-06-18",
		initialization_timeout = TEST_CONFIG.timeout,
		request_timeout = TEST_CONFIG.timeout,
	})

	if not ok then
		print("❌ Failed to initialize MCP transport: " .. tostring(err))
		return false, err
	end

	-- Initialize session
	local ok2, err2 = mcp_http_transport.initialize_session({
		name = "paragonic-test-client",
		version = "1.0.0",
		capabilities = { tools = {}, resources = {}, notifications = {} },
	})

	if not ok2 then
		print("❌ Failed to initialize MCP session: " .. tostring(err2))
		return false, err2
	end

	-- Initialize thinking model support
	mcp_thinking.initialize_thinking_support()

	print("✅ Test environment setup complete")
	return true
end

-- Test MCP completion/complete method
function M.test_completion_complete()
	print("🧪 Testing MCP completion/complete method...")

	local mcp_thinking = require("paragonic.mcp_thinking_support")

	-- Test basic completion
	local completion, err =
		mcp_thinking.handle_completion_complete(TEST_CONFIG.test_prompt, TEST_CONFIG.test_model, { temperature = 0.7 })

	if not completion then
		print("❌ Completion failed: " .. tostring(err))
		return false
	end

	-- Verify completion response
	assert(type(completion) == "string", "Completion should be a string")
	assert(#completion > 0, "Completion should not be empty")
	assert(completion:find("quantum"), "Completion should contain quantum-related content")

	print("✅ Completion test passed")
	return true
end

-- Test MCP sampling/createMessage method
function M.test_sampling_create_message()
	print("🧪 Testing MCP sampling/createMessage method...")

	local mcp_thinking = require("paragonic.mcp_thinking_support")

	-- Test sampling with thinking model
	local message, err = mcp_thinking.handle_sampling_create_message(
		"Think step by step about how to solve a Rubik's cube",
		TEST_CONFIG.test_model,
		{
			temperature = 0.8,
			max_tokens = 500,
			thinking_enabled = true,
		}
	)

	if not message then
		print("❌ Sampling failed: " .. tostring(err))
		return false
	end

	-- Verify sampling response
	assert(type(message) == "table", "Message should be a table")
	assert(message.role == "assistant", "Message should have assistant role")
	assert(type(message.content) == "string", "Message content should be a string")
	assert(#message.content > 0, "Message content should not be empty")

	-- Check for thinking tags if thinking is enabled
	if message.content:find("<think>") then
		print("✅ Sampling with thinking tags detected")
	end

	print("✅ Sampling test passed")
	return true
end

-- Test MCP elicitation/create method
function M.test_elicitation_create()
	print("🧪 Testing MCP elicitation/create method...")

	local mcp_thinking = require("paragonic.mcp_thinking_support")

	-- Test elicitation creation
	local elicitation_id, err = mcp_thinking.handle_elicitation_create(
		"What additional information do you need to help me with this task?",
		"user_input"
	)

	if not elicitation_id then
		print("❌ Elicitation failed: " .. tostring(err))
		return false
	end

	-- Verify elicitation response
	assert(type(elicitation_id) == "string", "Elicitation ID should be a string")
	assert(#elicitation_id > 0, "Elicitation ID should not be empty")
	assert(elicitation_id:find("elicitation"), "Elicitation ID should contain 'elicitation'")

	print("✅ Elicitation test passed")
	return true
end

-- Test MCP logging/setLevel method
function M.test_logging_set_level()
	print("🧪 Testing MCP logging/setLevel method...")

	local mcp_thinking = require("paragonic.mcp_thinking_support")

	-- Test setting different log levels
	local valid_levels = { "debug", "info", "warn", "error" }

	for _, level in ipairs(valid_levels) do
		local result, err = mcp_thinking.handle_logging_set_level(level)

		if not result then
			print("❌ Logging set level failed for " .. level .. ": " .. tostring(err))
			return false
		end

		-- Verify logging response
		assert(type(result) == "table", "Logging result should be a table")
		assert(result.level == level, "Logging level should match requested level")
		assert(result.status == "updated", "Logging status should be 'updated'")
	end

	-- Test invalid log level
	local invalid_result, invalid_err = mcp_thinking.handle_logging_set_level("invalid_level")
	assert(not invalid_result, "Invalid log level should fail")
	assert(invalid_err:find("Invalid log level"), "Should return invalid log level error")

	print("✅ Logging test passed")
	return true
end

-- Test MCP prompts/list method
function M.test_prompts_list()
	print("🧪 Testing MCP prompts/list method...")

	local mcp_thinking = require("paragonic.mcp_thinking_support")

	-- Test prompts list
	local prompts, err = mcp_thinking.handle_prompts_list()

	if not prompts then
		print("❌ Prompts list failed: " .. tostring(err))
		return false
	end

	-- Verify prompts response
	assert(type(prompts) == "table", "Prompts should be a table")
	assert(#prompts > 0, "Should have at least one prompt")

	-- Check for expected prompts
	local found_thinking = false
	local found_code = false

	for _, prompt in ipairs(prompts) do
		assert(type(prompt) == "table", "Each prompt should be a table")
		assert(prompt.name, "Prompt should have a name")
		assert(prompt.description, "Prompt should have a description")
		assert(prompt.content, "Prompt should have content")

		if prompt.name == "thinking_assistant" then
			found_thinking = true
			assert(prompt.content:find("<think>"), "Thinking assistant should mention thinking tags")
		elseif prompt.name == "code_assistant" then
			found_code = true
			assert(prompt.content:find("code"), "Code assistant should mention code")
		end
	end

	assert(found_thinking, "Should find thinking_assistant prompt")
	assert(found_code, "Should find code_assistant prompt")

	print("✅ Prompts list test passed")
	return true
end

-- Test MCP prompts/get method
function M.test_prompts_get()
	print("🧪 Testing MCP prompts/get method...")

	local mcp_thinking = require("paragonic.mcp_thinking_support")

	-- Test getting specific prompt
	local prompt, err = mcp_thinking.handle_prompts_get("thinking_assistant")

	if not prompt then
		print("❌ Prompt get failed: " .. tostring(err))
		return false
	end

	-- Verify prompt response
	assert(type(prompt) == "table", "Prompt should be a table")
	assert(prompt.name == "thinking_assistant", "Prompt name should match")
	assert(prompt.description, "Prompt should have description")
	assert(prompt.content, "Prompt should have content")
	assert(prompt.content:find("<think>"), "Thinking prompt should mention thinking tags")

	-- Test getting non-existent prompt
	local not_found_prompt, not_found_err = mcp_thinking.handle_prompts_get("non_existent_prompt")
	assert(not not_found_prompt, "Non-existent prompt should fail")
	assert(not_found_err:find("failed"), "Should return failure error")

	print("✅ Prompts get test passed")
	return true
end

-- Test MCP roots/list method
function M.test_roots_list()
	print("🧪 Testing MCP roots/list method...")

	local mcp_thinking = require("paragonic.mcp_thinking_support")

	-- Test roots list for buffers
	local roots, err = mcp_thinking.handle_roots_list("neovim://buffers", {})

	if not roots then
		print("❌ Roots list failed: " .. tostring(err))
		return false
	end

	-- Verify roots response
	assert(type(roots) == "table", "Roots should be a table")
	assert(#roots > 0, "Should have at least one root")

	-- Check for expected root
	local found_buffers = false
	for _, root in ipairs(roots) do
		assert(type(root) == "table", "Each root should be a table")
		assert(root.uri, "Root should have URI")
		assert(root.name, "Root should have name")
		assert(root.description, "Root should have description")

		if root.uri == "neovim://buffers" then
			found_buffers = true
			assert(root.name == "Neovim Buffers", "Should have correct buffer root name")
		end
	end

	assert(found_buffers, "Should find neovim://buffers root")

	print("✅ Roots list test passed")
	return true
end

-- Test thinking model status and cleanup
function M.test_thinking_status_and_cleanup()
	print("🧪 Testing thinking model status and cleanup...")

	local mcp_thinking = require("paragonic.mcp_thinking_support")

	-- Get initial status
	local initial_status = mcp_thinking.get_thinking_status()
	assert(type(initial_status) == "table", "Status should be a table")
	assert(type(initial_status.active_completions) == "table", "Should have active completions")
	assert(type(initial_status.active_sampling) == "table", "Should have active sampling")
	assert(type(initial_status.active_elicitations) == "table", "Should have active elicitations")

	-- Perform some operations to create active items
	mcp_thinking.handle_completion_complete("Test completion", "test-model")
	mcp_thinking.handle_sampling_create_message("Test sampling", "test-model")
	mcp_thinking.handle_elicitation_create("Test elicitation", "test-type")

	-- Get status after operations
	local after_status = mcp_thinking.get_thinking_status()
	assert(after_status.total_operations >= 3, "Should have at least 3 operations")

	-- Test cleanup
	local cleanup_count = mcp_thinking.cleanup_completed_operations()
	assert(type(cleanup_count) == "number", "Cleanup count should be a number")

	print("✅ Status and cleanup test passed")
	return true
end

-- Test thinking completion with progress tracking
function M.test_thinking_completion_with_progress()
	print("🧪 Testing thinking completion with progress tracking...")

	local mcp_thinking = require("paragonic.mcp_thinking_support")

	local progress_updates = {}
	local progress_callback = function(operation_id, progress, message)
		table.insert(progress_updates, {
			operation_id = operation_id,
			progress = progress,
			message = message,
		})
	end

	-- Test completion with progress
	local completion, err = mcp_thinking.thinking_completion_with_progress(
		"Explain the concept of recursion with examples",
		TEST_CONFIG.test_model,
		{ temperature = 0.7 },
		progress_callback
	)

	if not completion then
		print("❌ Thinking completion with progress failed: " .. tostring(err))
		return false
	end

	-- Verify completion response
	assert(type(completion) == "string", "Completion should be a string")
	assert(#completion > 0, "Completion should not be empty")

	-- Verify progress updates
	assert(#progress_updates > 0, "Should have progress updates")
	assert(progress_updates[1].progress == 0, "First update should be 0%")
	assert(progress_updates[#progress_updates].progress == 100, "Last update should be 100%")

	print("✅ Thinking completion with progress test passed")
	return true
end

-- Run all tests
function M.run_all_tests()
	print("🚀 Starting MCP Thinking Model Support Tests")
	print("=" .. string.rep("=", 50))

	local tests = {
		{ name = "Setup Test Environment", func = M.setup_test_environment },
		{ name = "Completion Complete", func = M.test_completion_complete },
		{ name = "Sampling Create Message", func = M.test_sampling_create_message },
		{ name = "Elicitation Create", func = M.test_elicitation_create },
		{ name = "Logging Set Level", func = M.test_logging_set_level },
		{ name = "Prompts List", func = M.test_prompts_list },
		{ name = "Prompts Get", func = M.test_prompts_get },
		{ name = "Roots List", func = M.test_roots_list },
		{ name = "Thinking Status and Cleanup", func = M.test_thinking_status_and_cleanup },
		{ name = "Thinking Completion with Progress", func = M.test_thinking_completion_with_progress },
	}

	local passed = 0
	local failed = 0

	for _, test in ipairs(tests) do
		print("\n🧪 Running: " .. test.name)
		local success, err = pcall(test.func)

		if success then
			print("✅ " .. test.name .. " PASSED")
			passed = passed + 1
		else
			print("❌ " .. test.name .. " FAILED: " .. tostring(err))
			failed = failed + 1
		end
	end

	print("\n" .. string.rep("=", 50))
	print("📊 Test Results:")
	print("   Passed: " .. passed)
	print("   Failed: " .. failed)
	print("   Total: " .. (passed + failed))

	if failed == 0 then
		print("🎉 All tests passed!")
		return true
	else
		print("⚠️  Some tests failed")
		return false
	end
end

-- Export module
local M = M

-- Run tests if this file is executed directly
if arg[0]:match("test_thinking_model_support.lua$") then
	M.run_all_tests()
end

return M
