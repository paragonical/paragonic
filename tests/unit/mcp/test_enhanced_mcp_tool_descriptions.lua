--[[
Unit tests for Enhanced MCP Tool Descriptions
Tests the new tools and enhanced tool awareness functionality
--]]

local M = {}

-- Test configuration
local TEST_CONFIG = {
	test_message = "Please search for files and get session info",
	test_context = {
		current_buffer = "test.lua",
		current_directory = "/tmp/test",
		buffer_count = 3,
		mode = "n",
		timestamp = os.time(),
	},
}

-- Mock MCP module for testing
local mock_mcp = {
	list_mcp_tools = function()
		return {
			{
				name = "agent_edit_file",
				description = "Edit a file in the current Neovim session",
				inputSchema = {
					type = "object",
					properties = {
						file_path = { type = "string" },
						line_number = { type = "integer" },
						content = { type = "string" },
					},
				},
			},
			{
				name = "agent_create_file",
				description = "Create a new file in the current Neovim session",
				inputSchema = {
					type = "object",
					properties = {
						file_name = { type = "string" },
						content = { type = "string" },
						open_in_window = { type = "boolean" },
					},
				},
			},
			{
				name = "agent_save_file",
				description = "Save files to disk in the current Neovim session",
				inputSchema = {
					type = "object",
					properties = {
						file_path = { type = "string" },
						force = { type = "boolean" },
					},
				},
			},
			{
				name = "agent_session_info",
				description = "Get current session information and context",
				inputSchema = {
					type = "object",
					properties = {
						include_buffers = { type = "boolean" },
						include_patterns = { type = "boolean" },
						include_history = { type = "boolean" },
					},
				},
			},
			{
				name = "agent_search_files",
				description = "Search for files in the current directory and subdirectories",
				inputSchema = {
					type = "object",
					properties = {
						query = { type = "string" },
						file_type = { type = "string" },
						recursive = { type = "boolean" },
						max_results = { type = "integer" },
					},
				},
			},
			{
				name = "agent_execute_command",
				description = "Execute Neovim commands or external shell commands",
				inputSchema = {
					type = "object",
					properties = {
						command = { type = "string" },
						command_type = { type = "string" },
						args = { type = "array" },
					},
				},
			},
		}
	end,
}

-- Add lua directory to package path for testing
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Test enhanced tool discovery
function M.test_enhanced_tool_discovery()
	print("🧪 Testing enhanced tool discovery...")

	-- Mock the MCP module
	package.loaded["paragonic.mcp"] = mock_mcp

	local mcp_tool_prompts = require("paragonic.mcp_tool_prompts")
	mcp_tool_prompts.init()

	-- Test getting available tools
	local tools = mcp_tool_prompts.get_available_tools()
	assert(type(tools) == "table", "Tools should be a table")
	assert(#tools == 6, "Should have 6 tools (including new ones)")

	-- Verify new tools are present
	local tool_names = {}
	for _, tool in ipairs(tools) do
		table.insert(tool_names, tool.name)
	end

	assert(table.concat(tool_names, ","):find("agent_session_info"), "Should have agent_session_info tool")
	assert(table.concat(tool_names, ","):find("agent_search_files"), "Should have agent_search_files tool")
	assert(table.concat(tool_names, ","):find("agent_execute_command"), "Should have agent_execute_command tool")

	print("✅ Enhanced tool discovery test passed")
end

-- Test enhanced intent detection
function M.test_enhanced_intent_detection()
	print("🧪 Testing enhanced intent detection...")

	package.loaded["paragonic.mcp"] = mock_mcp
	local mcp_tool_prompts = require("paragonic.mcp_tool_prompts")
	mcp_tool_prompts.init()

	-- Test session management intent
	local session_intent = mcp_tool_prompts.detect_user_intent("Get session info and context")
	assert(session_intent.session_management, "Should detect session management intent")

	-- Test search operations intent
	local search_intent = mcp_tool_prompts.detect_user_intent("Search for files with .lua extension")
	assert(search_intent.search_operations, "Should detect search operations intent")

	-- Test command execution intent
	local command_intent = mcp_tool_prompts.detect_user_intent("Execute the git status command")
	assert(command_intent.command_execution, "Should detect command execution intent")

	print("✅ Enhanced intent detection test passed")
end

-- Test enhanced tool categorization
function M.test_enhanced_tool_categorization()
	print("🧪 Testing enhanced tool categorization...")

	package.loaded["paragonic.mcp"] = mock_mcp
	local mcp_tool_prompts = require("paragonic.mcp_tool_prompts")
	mcp_tool_prompts.init()

	local tools = mcp_tool_prompts.get_available_tools()
	local categorized = mcp_tool_prompts.categorize_tools(tools)

	-- Test new categories
	assert(categorized.session_management, "Should have session_management category")
	assert(categorized.search_navigation, "Should have search_navigation category")
	assert(categorized.command_execution, "Should have command_execution category")

	-- Test tool assignments
	local session_tools = categorized.session_management
	local session_tool_names = {}
	for _, tool in ipairs(session_tools) do
		table.insert(session_tool_names, tool.name)
	end
	assert(table.concat(session_tool_names, ","):find("agent_session_info"), "agent_session_info should be in session_management")

	local search_tools = categorized.search_navigation
	local search_tool_names = {}
	for _, tool in ipairs(search_tools) do
		table.insert(search_tool_names, tool.name)
	end
	assert(table.concat(search_tool_names, ","):find("agent_search_files"), "agent_search_files should be in search_navigation")

	local command_tools = categorized.command_execution
	local command_tool_names = {}
	for _, tool in ipairs(command_tools) do
		table.insert(command_tool_names, tool.name)
	end
	assert(table.concat(command_tool_names, ","):find("agent_execute_command"), "agent_execute_command should be in command_execution")

	print("✅ Enhanced tool categorization test passed")
end

-- Test enhanced prompt construction
function M.test_enhanced_prompt_construction()
	print("🧪 Testing enhanced prompt construction...")

	package.loaded["paragonic.mcp"] = mock_mcp
	local mcp_tool_prompts = require("paragonic.mcp_tool_prompts")
	mcp_tool_prompts.init()

	-- Test prompt with search and session intent
	local prompt = mcp_tool_prompts.build_tool_awareness_prompt(
		"Search for files and get session information",
		TEST_CONFIG.test_context
	)

	assert(type(prompt) == "string", "Prompt should be a string")
	assert(#prompt > 0, "Prompt should not be empty")
	assert(prompt:find("agent_search_files"), "Prompt should mention agent_search_files")
	assert(prompt:find("agent_session_info"), "Prompt should mention agent_session_info")

	print("✅ Enhanced prompt construction test passed")
end

-- Test enhanced pattern tool mappings
function M.test_enhanced_pattern_tool_mappings()
	print("🧪 Testing enhanced pattern tool mappings...")

	package.loaded["paragonic.mcp"] = mock_mcp
	local mcp_tool_prompts = require("paragonic.mcp_tool_prompts")
	mcp_tool_prompts.init()

	-- Test knowledge extraction pattern tools
	local knowledge_tools = mcp_tool_prompts.get_tools_for_pattern("knowledge_extraction")
	local knowledge_tool_names = {}
	for _, tool in ipairs(knowledge_tools) do
		table.insert(knowledge_tool_names, tool.name)
	end

	assert(table.concat(knowledge_tool_names, ","):find("agent_search_files"), "knowledge_extraction should include agent_search_files")

	-- Test context summarization pattern tools
	local context_tools = mcp_tool_prompts.get_tools_for_pattern("context_summarization")
	local context_tool_names = {}
	for _, tool in ipairs(context_tools) do
		table.insert(context_tool_names, tool.name)
	end

	assert(table.concat(context_tool_names, ","):find("agent_search_files"), "context_summarization should include agent_search_files")

	print("✅ Enhanced pattern tool mappings test passed")
end

-- Run all tests
function M.run_all_tests()
	print("🚀 Running Enhanced MCP Tool Descriptions Tests")
	print("=" .. string.rep("=", 50))

	M.test_enhanced_tool_discovery()
	M.test_enhanced_intent_detection()
	M.test_enhanced_tool_categorization()
	M.test_enhanced_prompt_construction()
	M.test_enhanced_pattern_tool_mappings()

	print("=" .. string.rep("=", 50))
	print("✅ All Enhanced MCP Tool Descriptions Tests Passed!")
end

-- Run tests if this file is executed directly
if arg[0]:match("test_enhanced_mcp_tool_descriptions.lua$") then
	M.run_all_tests()
end

return M
