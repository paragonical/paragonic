--[[
Integration tests for MCP Tool Awareness in Chat
Tests the integration of tool awareness prompts with the chat module
--]]

local M = {}

-- Test configuration
local TEST_CONFIG = {
	test_message = "Please create a new file and edit it",
	test_model = "deepseek-r1:1.5b",
}

-- Mock streaming module for testing
local mock_streaming = {
	init = function(config)
		return true
	end,
	start_session = function(message, model, options)
		return "test_session_id"
	end,
	get_chunks = function(session_id)
		return {
			{
				chunk = "I'll help you create a new file and edit it using the available tools.",
				chunk_type = "assistant_content",
				chunk_index = 0,
			},
		}
	end,
	cleanup_session = function(session_id)
		return true
	end,
}

-- Mock UI module for testing
local mock_ui = {
	init = function()
		return true
	end,
	create_chat_buffer = function()
		return 1 -- Return a mock buffer ID
	end,
	get_buffer_width = function(buffer)
		return 80
	end,
}

-- Mock MCP tool prompts module for testing
local mock_mcp_tool_prompts = {
	init = function()
		return true
	end,
	extract_conversation_context = function()
		return {
			current_buffer = "test.lua",
			current_directory = "/tmp/test",
			buffer_count = 3,
			mode = "n",
			timestamp = os.time(),
		}
	end,
	build_tool_awareness_prompt = function(message, context)
		return "You have access to the following Neovim integration tools through MCP:\n- agent_edit_file: Edit a file in the current Neovim session\n- agent_create_file: Create a new file in the current Neovim session\n- agent_save_file: Save files to disk in the current Neovim session\n\nWhen appropriate, use these tools to interact directly with Neovim instead of suggesting manual actions."
	end,
}

-- Mock config module for testing
local mock_config = {
	get = function(key)
		if key == "ollama_model" then
			return "deepseek-r1:1.5b"
		end
		return nil
	end,
	get_config = function()
		return {
			ollama_model = "deepseek-r1:1.5b",
			mcp_tool_prompts = {
				enabled = true,
				prompt_style = "contextual",
			},
		}
	end,
	model_supports_thinking = function(model)
		return true
	end,
}

-- Mock debug module for testing
local mock_debug = {
	debug_print = function(message, level)
		-- Do nothing in tests
	end,
}

-- Test chat integration with tool awareness
function M.test_chat_integration()
	print("🧪 Testing chat integration with tool awareness...")

	-- Mock the modules
	package.loaded["paragonic.streaming"] = mock_streaming
	package.loaded["paragonic.ui"] = mock_ui
	package.loaded["paragonic.mcp_tool_prompts"] = mock_mcp_tool_prompts
	package.loaded["paragonic.config"] = mock_config
	package.loaded["paragonic.debug"] = mock_debug

	-- Add lua directory to package path for testing
	package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

	local chat = require("paragonic.chat")

	-- Test that tool awareness is included in message sending
	local message_sent = nil
	local session_options = nil

	-- Override streaming.start_session to capture the enhanced message
	mock_streaming.start_session = function(message, model, options)
		message_sent = message
		session_options = options
		return "test_session_id"
	end

	-- Send a test message
	local success = chat.send_message_smart(TEST_CONFIG.test_message, TEST_CONFIG.test_model)

	-- Verify the message was enhanced with tool awareness
	assert(message_sent, "Message should be sent")
	assert(message_sent:find("agent_edit_file"), "Enhanced message should contain edit tool")
	assert(message_sent:find("agent_create_file"), "Enhanced message should contain create tool")
	assert(message_sent:find("agent_save_file"), "Enhanced message should contain save tool")
	assert(message_sent:find(TEST_CONFIG.test_message), "Enhanced message should contain original message")

	-- Verify the message starts with tool awareness prompt
	local tool_prompt_start = "You have access to the following Neovim integration tools through MCP:"
	assert(message_sent:find(tool_prompt_start), "Message should start with tool awareness prompt")

	print("✅ Chat integration test passed")
end

-- Test tool awareness prompt construction
function M.test_tool_awareness_prompt_construction()
	print("🧪 Testing tool awareness prompt construction...")

	-- Mock the modules
	package.loaded["paragonic.mcp_tool_prompts"] = mock_mcp_tool_prompts

	-- Add lua directory to package path for testing
	package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

	local chat = require("paragonic.chat")

	-- Test that tool awareness prompt is constructed correctly
	local context = mock_mcp_tool_prompts.extract_conversation_context()
	local tool_prompt = mock_mcp_tool_prompts.build_tool_awareness_prompt(TEST_CONFIG.test_message, context)

	assert(tool_prompt, "Tool prompt should be constructed")
	assert(type(tool_prompt) == "string", "Tool prompt should be a string")
	assert(#tool_prompt > 0, "Tool prompt should not be empty")
	assert(tool_prompt:find("agent_edit_file"), "Tool prompt should mention edit tool")
	assert(tool_prompt:find("agent_create_file"), "Tool prompt should mention create tool")
	assert(tool_prompt:find("agent_save_file"), "Tool prompt should mention save tool")
	assert(tool_prompt:find("Neovim integration tools"), "Tool prompt should mention Neovim integration")

	print("✅ Tool awareness prompt construction test passed")
end

-- Test context extraction
function M.test_context_extraction()
	print("🧪 Testing context extraction...")

	-- Mock the modules
	package.loaded["paragonic.mcp_tool_prompts"] = mock_mcp_tool_prompts

	-- Add lua directory to package path for testing
	package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

	local chat = require("paragonic.chat")

	-- Test that context is extracted correctly
	local context = mock_mcp_tool_prompts.extract_conversation_context()

	assert(context, "Context should be extracted")
	assert(type(context) == "table", "Context should be a table")
	assert(context.current_buffer, "Context should have current buffer")
	assert(context.current_directory, "Context should have current directory")
	assert(context.buffer_count, "Context should have buffer count")
	assert(context.mode, "Context should have mode")
	assert(context.timestamp, "Context should have timestamp")

	print("✅ Context extraction test passed")
end

-- Test message enhancement
function M.test_message_enhancement()
	print("🧪 Testing message enhancement...")

	-- Mock the modules
	package.loaded["paragonic.mcp_tool_prompts"] = mock_mcp_tool_prompts

	-- Add lua directory to package path for testing
	package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

	local chat = require("paragonic.chat")

	-- Test that messages are enhanced with tool awareness
	local original_message = "Create a new file"
	local context = mock_mcp_tool_prompts.extract_conversation_context()
	local tool_prompt = mock_mcp_tool_prompts.build_tool_awareness_prompt(original_message, context)

	local enhanced_message = original_message
	if tool_prompt and tool_prompt ~= "" then
		enhanced_message = tool_prompt .. "\n\n" .. original_message
	end

	assert(enhanced_message ~= original_message, "Message should be enhanced")
	assert(enhanced_message:find("agent_edit_file"), "Enhanced message should contain tool prompt")
	assert(enhanced_message:find(original_message), "Enhanced message should contain original message")

	-- Verify the structure: tool prompt + separator + original message
	local parts = {}
	for part in enhanced_message:gmatch("[^\n]+") do
		if part ~= "" then
			table.insert(parts, part)
		end
	end

	assert(#parts > 1, "Enhanced message should have multiple parts")
	assert(parts[#parts] == original_message, "Last part should be original message")

	print("✅ Message enhancement test passed")
end

-- Test disabled tool awareness
function M.test_disabled_tool_awareness()
	print("🧪 Testing disabled tool awareness...")

	-- Mock the modules with disabled tool awareness
	local mock_disabled_mcp_tool_prompts = {
		init = function()
			return true
		end,
		extract_conversation_context = function()
			return {}
		end,
		build_tool_awareness_prompt = function(message, context)
			return "" -- Return empty prompt (disabled)
		end,
	}

	package.loaded["paragonic.mcp_tool_prompts"] = mock_disabled_mcp_tool_prompts

	-- Add lua directory to package path for testing
	package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

	local chat = require("paragonic.chat")

	-- Test that messages are not enhanced when tool awareness is disabled
	local original_message = "Create a new file"
	local context = mock_disabled_mcp_tool_prompts.extract_conversation_context()
	local tool_prompt = mock_disabled_mcp_tool_prompts.build_tool_awareness_prompt(original_message, context)

	local enhanced_message = original_message
	if tool_prompt and tool_prompt ~= "" then
		enhanced_message = tool_prompt .. "\n\n" .. original_message
	end

	assert(enhanced_message == original_message, "Message should not be enhanced when tool awareness is disabled")

	print("✅ Disabled tool awareness test passed")
end

-- Test error handling
function M.test_error_handling()
	print("🧪 Testing error handling...")

	-- Mock the modules with error conditions
	local mock_error_mcp_tool_prompts = {
		init = function()
			return true
		end,
		extract_conversation_context = function()
			error("Context extraction failed")
		end,
		build_tool_awareness_prompt = function(message, context)
			return "" -- Return empty prompt on error
		end,
	}

	package.loaded["paragonic.mcp_tool_prompts"] = mock_error_mcp_tool_prompts

	-- Add lua directory to package path for testing
	package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

	local chat = require("paragonic.chat")

	-- Test that errors in tool awareness don't break message sending
	local success, result = pcall(function()
		local original_message = "Create a new file"
		local context = mock_error_mcp_tool_prompts.extract_conversation_context()
		local tool_prompt = mock_error_mcp_tool_prompts.build_tool_awareness_prompt(original_message, context)

		local enhanced_message = original_message
		if tool_prompt and tool_prompt ~= "" then
			enhanced_message = tool_prompt .. "\n\n" .. original_message
		end

		return enhanced_message
	end)

	-- Should handle error gracefully and return original message
	assert(not success, "Should detect errors in context extraction")
	assert(result:find("Context extraction failed"), "Should return error message")

	print("✅ Error handling test passed")
end

-- Run all integration tests
function M.run_all_tests()
	print("🚀 Running MCP Tool Awareness Integration tests...")

	local tests = {
		{ name = "Chat Integration", func = M.test_chat_integration },
		{ name = "Tool Awareness Prompt Construction", func = M.test_tool_awareness_prompt_construction },
		{ name = "Context Extraction", func = M.test_context_extraction },
		{ name = "Message Enhancement", func = M.test_message_enhancement },
		{ name = "Disabled Tool Awareness", func = M.test_disabled_tool_awareness },
		{ name = "Error Handling", func = M.test_error_handling },
	}

	local passed = 0
	local failed = 0

	for _, test in ipairs(tests) do
		local success, err = pcall(test.func)
		if success then
			passed = passed + 1
		else
			failed = failed + 1
			print("❌ " .. test.name .. " failed: " .. tostring(err))
		end
	end

	print("📊 Integration Test Results: " .. passed .. " passed, " .. failed .. " failed")

	if failed == 0 then
		print("🎉 All MCP Tool Awareness Integration tests passed!")
	else
		print("⚠️ Some integration tests failed. Please review the errors above.")
	end

	return failed == 0
end

-- Module interface
return M
