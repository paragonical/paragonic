-- Test file for smart send functionality
local M = {}

-- Test smart send with different models
function M.test_smart_send_model_detection()
	local chat = require("paragonic.chat")
	local config = require("paragonic.config")

	print("=== Testing Smart Send Model Detection ===")

	-- Test thinking models
	local thinking_models = {
		"deepseek-r1:1.5b",
		"deepseek-coder:1.3b",
		"deepseek-coder:6.7b",
		"deepseek-coder:33b",
	}

	for _, model in ipairs(thinking_models) do
		local supports_thinking = config.model_supports_thinking(model)
		local streaming_type = config.get_model_streaming_type(model)

		print(string.format("Model: %s", model))
		print(string.format("  Supports thinking: %s", tostring(supports_thinking)))
		print(string.format("  Streaming type: %s", streaming_type))

		if not supports_thinking then
			print("  ❌ ERROR: Thinking model should support thinking")
			return false
		end

		if streaming_type ~= "thinking" then
			print("  ❌ ERROR: Thinking model should have 'thinking' streaming type")
			return false
		end

		print("  ✅ PASS")
	end

	-- Test normal models
	local normal_models = {
		"llama2",
		"llama2:7b",
		"llama2:13b",
		"llama2:70b",
		"llama3.2:3b",
		"llama3.2:8b",
		"llama3.2:70b",
		"mistral",
		"mistral:7b",
		"mistral:8x7b",
		"codellama",
		"codellama:7b",
		"codellama:13b",
		"codellama:34b",
	}

	for _, model in ipairs(normal_models) do
		local supports_thinking = config.model_supports_thinking(model)
		local streaming_type = config.get_model_streaming_type(model)

		print(string.format("Model: %s", model))
		print(string.format("  Supports thinking: %s", tostring(supports_thinking)))
		print(string.format("  Streaming type: %s", streaming_type))

		if supports_thinking then
			print("  ❌ ERROR: Normal model should not support thinking")
			return false
		end

		if streaming_type ~= "normal" then
			print("  ❌ ERROR: Normal model should have 'normal' streaming type")
			return false
		end

		print("  ✅ PASS")
	end

	return true
end

-- Test smart send function
function M.test_smart_send_function()
	local chat = require("paragonic.chat")
	local config = require("paragonic.config")

	print("=== Testing Smart Send Function ===")

	-- Test with thinking model
	local thinking_model = "deepseek-r1:1.5b"
	local test_message = "Create a parts list for a Stirling engine."

	print(string.format("Testing with thinking model: %s", thinking_model))

	-- This would normally call the actual streaming function
	-- For now, we'll just verify the function exists and can be called
	if chat.send_message_smart then
		print("✅ send_message_smart function exists")

		-- Test that it returns the right type for thinking models
		local supports_thinking = config.model_supports_thinking(thinking_model)
		if supports_thinking then
			print("✅ Model correctly identified as thinking model")
		else
			print("❌ ERROR: Model should be identified as thinking model")
			return false
		end
	else
		print("❌ ERROR: send_message_smart function not found")
		return false
	end

	return true
end

-- Test current model detection
function M.test_current_model_detection()
	local config = require("paragonic.config")

	print("=== Testing Current Model Detection ===")

	-- Test current model capabilities
	local current_model = config.get("ollama_model")
	local supports_thinking = config.current_model_supports_thinking()
	local streaming_type = config.get_current_model_streaming_type()

	print(string.format("Current model: %s", current_model))
	print(string.format("Supports thinking: %s", tostring(supports_thinking)))
	print(string.format("Streaming type: %s", streaming_type))

	-- Verify the current model is deepseek-r1:1.5b (thinking model)
	if current_model == "deepseek-r1:1.5b" then
		if not supports_thinking then
			print("❌ ERROR: Current model should support thinking")
			return false
		end

		if streaming_type ~= "thinking" then
			print("❌ ERROR: Current model should have 'thinking' streaming type")
			return false
		end

		print("✅ Current model correctly configured as thinking model")
	else
		print("⚠️  WARNING: Current model is not deepseek-r1:1.5b")
	end

	return true
end

-- Test model list functions
function M.test_model_list_functions()
	local config = require("paragonic.config")

	print("=== Testing Model List Functions ===")

	-- Test getting all models
	local all_models = config.get_known_models()
	print(string.format("Total known models: %d", #all_models))

	-- Test getting thinking models
	local thinking_models = config.get_thinking_models()
	print(string.format("Thinking models: %d", #thinking_models))
	for _, model in ipairs(thinking_models) do
		print(string.format("  - %s", model))
	end

	-- Test getting normal models
	local normal_models = config.get_normal_models()
	print(string.format("Normal models: %d", #normal_models))

	-- Verify counts add up
	if #all_models ~= #thinking_models + #normal_models then
		print("❌ ERROR: Model counts don't add up")
		return false
	end

	print("✅ Model list functions working correctly")
	return true
end

-- Run all tests
function M.run_all_tests()
	print("Running smart send tests...")

	local test1_success = M.test_smart_send_model_detection()
	local test2_success = M.test_smart_send_function()
	local test3_success = M.test_current_model_detection()
	local test4_success = M.test_model_list_functions()

	local all_success = test1_success and test2_success and test3_success and test4_success

	print("=== Overall Test Results ===")
	print("All tests passed:", all_success)

	return all_success
end

return M
