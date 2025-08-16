-- Test file for Pattern System Integration with MCP Tool Awareness
-- Tests the integration between the pattern system and MCP tool prompts

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

local mcp_tool_prompts = require("paragonic.mcp_tool_prompts")

-- Mock AI agent module
local mock_ai_agent = {
	get_active_session = function()
		return {
			id = "test_session_123",
			name = "Test AI Agent",
			start_time = os.time() - 600, -- 10 minutes ago
			interactions = {
				{
					id = 1,
					timestamp = os.time() - 300,
					type = "pattern_execution",
					content = "Session Summary Generation",
					status = "completed",
					result = { summary = "Test summary" },
				},
				{
					id = 2,
					timestamp = os.time() - 200,
					type = "pattern_execution",
					content = "Activity Labeling",
					status = "completed",
					result = { activities = "Test activities" },
				},
			},
		}
	end,
	check_and_trigger_patterns = function()
		return {
			{ name = "Self Reflection", id = "self_reflection" },
		}
	end,
}

-- Mock patterns module
local mock_patterns = {
	list_patterns = function()
		return {
			{
				id = "session_summary_generation",
				name = "Session Summary Generation",
				category = "SessionManagement",
				description = "Generates comprehensive session summaries",
			},
			{
				id = "activity_labeling",
				name = "Activity Labeling",
				category = "ActivityLabeling",
				description = "Labels and categorizes development activities",
			},
			{
				id = "self_reflection",
				name = "Self Reflection",
				category = "SelfReflection",
				description = "Analyzes session performance",
			},
		}
	end,
}

-- Test setup
local function setup_mocks()
	-- Mock vim API
	_G.vim = {
		api = {
			nvim_get_current_buf = function()
				return 1
			end,
			nvim_buf_get_option = function()
				return "lua"
			end,
			nvim_buf_line_count = function()
				return 10
			end,
			nvim_list_bufs = function()
				return { 1, 2 }
			end,
			nvim_create_buf = function()
				return 1
			end,
			nvim_open_win = function()
				return 1
			end,
			nvim_win_set_buf = function() end,
			nvim_win_set_option = function() end,
			nvim_buf_set_lines = function() end,
			nvim_buf_get_lines = function()
				return { "test line" }
			end,
			nvim_buf_set_option = function() end,
			nvim_buf_get_name = function()
				return "test.lua"
			end,
			nvim_buf_set_name = function() end,
			nvim_buf_is_valid = function()
				return true
			end,
			nvim_win_is_valid = function()
				return true
			end,
			nvim_win_get_buf = function()
				return 1
			end,
			nvim_win_get_option = function()
				return "normal"
			end,
		},
		fn = {
			expand = function()
				return "test.lua"
			end,
			getcwd = function()
				return "/test/dir"
			end,
			mode = function()
				return "n"
			end,
			strftime = function()
				return "20250101_120000"
			end,
		},
		log = {
			levels = {
				INFO = 1,
				WARN = 2,
				ERROR = 3,
			},
		},
		notify = function(msg, level) end,
		defer_fn = function(fn, delay)
			fn()
		end,
		schedule = function(fn)
			fn()
		end,
	}

	-- Mock require for AI agent
	local original_require = require
	require = function(module)
		if module == "paragonic.ai_agent" then
			return mock_ai_agent
		elseif module == "paragonic.patterns" then
			return mock_patterns
		else
			return original_require(module)
		end
	end

	-- Mock debug module
	package.loaded["paragonic.debug"] = {
		debug_print = function(msg, level) end,
	}

	-- Mock config module
	package.loaded["paragonic.config"] = {
		get_mcp_tool_prompts_config = function()
			return {
				enabled = true,
				prompt_style = "contextual",
				include_pattern_context = true,
				max_tools_per_prompt = 5,
				cache_size = 100,
				intent_detection_threshold = 0.3,
			}
		end,
	}
end

-- Test cleanup
local function cleanup_mocks()
	require = _G.require
end

-- Test active patterns detection
local function test_active_patterns_detection()
	print("🧪 Testing active patterns detection...")

	local patterns = mcp_tool_prompts.get_active_patterns()

	assert(type(patterns) == "table", "Should return a table of patterns")
	assert(#patterns > 0, "Should detect active patterns from session")

	-- Check for session-executed patterns
	local found_session_summary = false
	local found_activity_labeling = false
	for _, pattern in ipairs(patterns) do
		if pattern.id == "Session Summary Generation" and pattern.status == "active" then
			found_session_summary = true
		elseif pattern.id == "Activity Labeling" and pattern.status == "active" then
			found_activity_labeling = true
		end
	end

	assert(found_session_summary, "Should detect session summary generation pattern")
	assert(found_activity_labeling, "Should detect activity labeling pattern")

	print("✅ Active patterns detection test passed")
end

-- Test pattern-specific tool relevance
local function test_pattern_tool_relevance()
	print("🧪 Testing pattern-specific tool relevance...")

	local mock_tool = { name = "agent_create_file" }
	local mock_pattern = {
		id = "Session Summary Generation",
		name = "Session Summary Generation",
		status = "active",
	}

	local relevance = mcp_tool_prompts.calculate_pattern_tool_relevance(mock_tool, mock_pattern)

	assert(relevance > 0, "Should calculate positive relevance for pattern-specific tool")
	assert(relevance <= 1.5, "Relevance should be within reasonable bounds (allowing for pattern boosts)")

	print("✅ Pattern tool relevance test passed")
end

-- Test pattern tools retrieval
local function test_pattern_tools_retrieval()
	print("🧪 Testing pattern tools retrieval...")

	local tools_for_session = mcp_tool_prompts.get_tools_for_pattern("session_summary_generation")

	assert(type(tools_for_session) == "table", "Should return table of tools")
	assert(#tools_for_session > 0, "Should return tools for session summary pattern")

	-- Check for expected tools
	local found_create_file = false
	local found_edit_file = false
	for _, tool in ipairs(tools_for_session) do
		if tool.name == "agent_create_file" then
			found_create_file = true
		elseif tool.name == "agent_edit_file" then
			found_edit_file = true
		end
	end

	assert(found_create_file, "Should include agent_create_file for session summary")
	assert(found_edit_file, "Should include agent_edit_file for session summary")

	print("✅ Pattern tools retrieval test passed")
end

-- Test pattern context generation
local function test_pattern_context_generation()
	print("🧪 Testing pattern context generation...")

	local context = mcp_tool_prompts.get_pattern_context({})

	assert(type(context) == "string", "Should return string context")
	assert(context:find("Active patterns"), "Should include active patterns header")
	assert(context:find("Session Summary Generation"), "Should include session summary pattern")
	assert(context:find("Activity Labeling"), "Should include activity labeling pattern")

	print("✅ Pattern context generation test passed")
end

-- Test pattern tools formatting
local function test_pattern_tools_formatting()
	print("🧪 Testing pattern tools formatting...")

	local formatted_info = mcp_tool_prompts.format_pattern_tools_info()

	assert(type(formatted_info) == "string", "Should return formatted string")
	assert(formatted_info:find("Session Summary Generation"), "Should include session summary pattern")
	assert(formatted_info:find("agent_create_file"), "Should include pattern-specific tools")

	print("✅ Pattern tools formatting test passed")
end

-- Test enhanced tool relevance with patterns
local function test_enhanced_tool_relevance()
	print("🧪 Testing enhanced tool relevance with patterns...")

	local mock_tool = { name = "agent_create_file" }
	local mock_intent = { file_creation = 0.8 }
	local mock_context = { current_buffer = "test.txt" }

	local relevance = mcp_tool_prompts.calculate_tool_relevance(mock_tool, mock_intent, mock_context)

	assert(relevance > 0, "Should calculate positive relevance")
	-- Pattern-based scoring should add to the base relevance
	assert(relevance >= 0.8, "Should include pattern-based scoring")

	print("✅ Enhanced tool relevance test passed")
end

-- Test pattern-aware prompt construction
local function test_pattern_aware_prompt_construction()
	print("🧪 Testing pattern-aware prompt construction...")

	local user_message = "Create a summary of our session"
	local context = { current_buffer = "test.txt" }

	local prompt = mcp_tool_prompts.build_tool_awareness_prompt(user_message, context)

	assert(type(prompt) == "string", "Should return string prompt")
	assert(#prompt > 0, "Should generate non-empty prompt")
	assert(prompt:find("Active patterns"), "Should include pattern context")
	assert(prompt:find("agent_create_file"), "Should include pattern-relevant tools")

	print("✅ Pattern-aware prompt construction test passed")
end

-- Run all tests
local function run_tests()
	print("🚀 Running Pattern System Integration Tests")
	print("=" .. string.rep("=", 50))

	setup_mocks()

	local success, error_msg = pcall(function()
		test_active_patterns_detection()
		test_pattern_tool_relevance()
		test_pattern_tools_retrieval()
		test_pattern_context_generation()
		test_pattern_tools_formatting()
		test_enhanced_tool_relevance()
		test_pattern_aware_prompt_construction()
	end)

	cleanup_mocks()

	if success then
		print("=" .. string.rep("=", 50))
		print("✅ All Pattern System Integration tests passed!")
	else
		print("❌ Test failed: " .. tostring(error_msg))
		os.exit(1)
	end
end

-- Run tests if this file is executed directly
if arg[0]:match("test_pattern_system_integration.lua$") then
	run_tests()
end

return {
	run_tests = run_tests,
	test_active_patterns_detection = test_active_patterns_detection,
	test_pattern_tool_relevance = test_pattern_tool_relevance,
	test_pattern_tools_retrieval = test_pattern_tools_retrieval,
	test_pattern_context_generation = test_pattern_context_generation,
	test_pattern_tools_formatting = test_pattern_tools_formatting,
	test_enhanced_tool_relevance = test_enhanced_tool_relevance,
	test_pattern_aware_prompt_construction = test_pattern_aware_prompt_construction,
}
