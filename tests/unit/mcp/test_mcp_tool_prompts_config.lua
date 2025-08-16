--[[
Unit tests for MCP Tool Prompts Configuration
Tests configuration loading and management
--]]

local M = {}

-- Test configuration loading
function M.test_configuration_loading()
	print("🧪 Testing configuration loading...")

	-- Add lua directory to package path for testing
	package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

	local config = require("paragonic.config")
	local mcp_tool_prompts = require("paragonic.mcp_tool_prompts")

	-- Test that configuration is loaded correctly
	local mcp_config = config.get_mcp_tool_prompts_config()
	assert(mcp_config, "Should have MCP tool prompts configuration")
	assert(type(mcp_config) == "table", "Configuration should be a table")
	assert(mcp_config.enabled == true, "Should be enabled by default")
	assert(mcp_config.prompt_style == "contextual", "Should have contextual style by default")
	assert(mcp_config.max_tools_per_prompt == 5, "Should have max 5 tools per prompt")
	assert(mcp_config.intent_detection_threshold == 0.7, "Should have 0.7 threshold")

	-- Test that module loads configuration correctly
	mcp_tool_prompts.init()
	assert(mcp_tool_prompts.config.enabled == true, "Module should load enabled setting")
	assert(mcp_tool_prompts.config.prompt_style == "contextual", "Module should load prompt style")

	print("✅ Configuration loading test passed")
end

-- Test configuration updates
function M.test_configuration_updates()
	print("🧪 Testing configuration updates...")

	local config = require("paragonic.config")

	-- Test updating configuration
	local new_config = {
		enabled = false,
		prompt_style = "base",
		max_tools_per_prompt = 3,
		intent_detection_threshold = 0.5,
	}

	local success = config.update_mcp_tool_prompts_config(new_config)
	assert(success, "Should successfully update configuration")

	-- Verify updates
	local updated_config = config.get_mcp_tool_prompts_config()
	assert(updated_config.enabled == false, "Should update enabled setting")
	assert(updated_config.prompt_style == "base", "Should update prompt style")
	assert(updated_config.max_tools_per_prompt == 3, "Should update max tools")
	assert(updated_config.intent_detection_threshold == 0.5, "Should update threshold")

	print("✅ Configuration updates test passed")
end

-- Test configuration helper functions
function M.test_configuration_helpers()
	print("🧪 Testing configuration helper functions...")

	local config = require("paragonic.config")

	-- Test helper functions
	assert(config.mcp_tool_prompts_enabled() == false, "Should return false when disabled")
	assert(config.get_mcp_tool_prompts_style() == "base", "Should return base style")
	assert(config.get_mcp_tool_prompts_threshold() == 0.5, "Should return 0.5 threshold")
	assert(config.get_mcp_tool_prompts_max_tools() == 3, "Should return 3 max tools")
	assert(config.get_mcp_tool_prompts_cache_size() == 100, "Should return 100 cache size")

	local tool_filtering = config.get_mcp_tool_prompts_tool_filtering()
	assert(type(tool_filtering) == "table", "Should return tool filtering table")

	print("✅ Configuration helper functions test passed")
end

-- Test default values
function M.test_default_values()
	print("🧪 Testing default values...")

	local config = require("paragonic.config")

	-- Reset to default configuration
	local default_config = {
		enabled = true,
		prompt_style = "contextual",
		include_pattern_context = true,
		include_usage_guidance = true,
		max_tools_per_prompt = 5,
		intent_detection_threshold = 0.7,
		cache_size = 100,
	}

	config.update_mcp_tool_prompts_config(default_config)

	-- Test default values
	assert(config.mcp_tool_prompts_enabled() == true, "Should return true when enabled")
	assert(config.get_mcp_tool_prompts_style() == "contextual", "Should return contextual style")
	assert(config.get_mcp_tool_prompts_threshold() == 0.7, "Should return 0.7 threshold")
	assert(config.get_mcp_tool_prompts_max_tools() == 5, "Should return 5 max tools")
	assert(config.get_mcp_tool_prompts_cache_size() == 100, "Should return 100 cache size")

	print("✅ Default values test passed")
end

-- Run all configuration tests
function M.run_all_tests()
	print("🚀 Running MCP Tool Prompts Configuration tests...")

	local tests = {
		{ name = "Configuration Loading", func = M.test_configuration_loading },
		{ name = "Configuration Updates", func = M.test_configuration_updates },
		{ name = "Configuration Helper Functions", func = M.test_configuration_helpers },
		{ name = "Default Values", func = M.test_default_values },
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

	print("📊 Configuration Test Results: " .. passed .. " passed, " .. failed .. " failed")

	if failed == 0 then
		print("🎉 All MCP Tool Prompts Configuration tests passed!")
	else
		print("⚠️ Some configuration tests failed. Please review the errors above.")
	end

	return failed == 0
end

-- Module interface
return M
