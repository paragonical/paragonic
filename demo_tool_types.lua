--[[
Demo: Tool Types System
Proof of concept showing type definitions and regex validation for MCP tool arguments
--]]

-- Check if running in Neovim
local is_neovim = pcall(function() return vim.api.nvim_get_current_buf() end)

if not is_neovim then
	print("❌ This demo must be run inside Neovim")
	print("   Please open Neovim and run: :lua dofile('demo_tool_types.lua')")
	os.exit(1)
end

-- Demo configuration
local DEMO_CONFIG = {
	demo_buffer_name = "*Tool Types Demo*",
	delay = 1000, -- milliseconds
}

-- Utility function to add delay
local function delay(ms)
	if ms then
		vim.wait(ms)
	end
end

-- Utility function to add text to buffer
local function add_text(text)
	local buf = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	table.insert(lines, text)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

-- Utility function to clear buffer
local function clear_buffer()
	local buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
end

-- Test tool types system
local function test_tool_types()
	print("🚀 Starting Tool Types Demo")
	print("")
	
	-- Initialize MCP system
	local mcp = require("paragonic.mcp")
	if mcp.initialize_mcp_server then
		mcp.initialize_mcp_server()
	end
	
	-- Initialize tool types
	local tool_types = require("paragonic.tool_types")
	
	-- Clear buffer
	clear_buffer()
	
	-- Add demo header
	add_text("# Tool Types System Demo")
	add_text("")
	add_text("This demo showcases type definitions and regex validation for MCP tool arguments.")
	add_text("")
	
	delay(DEMO_CONFIG.delay)
	
	-- Demo 1: Show available types
	add_text("## Demo 1: Available Types")
	add_text("")
	add_text("**Built-in Types with Regex Validation:**")
	add_text("")
	
	local types = mcp.list_available_types()
	for i, type_info in ipairs(types) do
		if i <= 10 then -- Show first 10 types
			add_text(i .. ". **" .. type_info.name .. "** - " .. type_info.description)
		end
	end
	
	if #types > 10 then
		add_text("... and " .. (#types - 10) .. " more types")
	end
	
	add_text("")
	delay(DEMO_CONFIG.delay)
	
	-- Demo 2: Type validation examples
	add_text("## Demo 2: Type Validation Examples")
	add_text("")
	add_text("**Testing different types with regex validation:**")
	add_text("")
	
	-- Test file_path type
	add_text("**Test 1: file_path validation**")
	local valid1, reason1 = mcp.validate_type("src/main.lua", "file_path")
	add_text("Input: 'src/main.lua'")
	add_text("Result: " .. (valid1 and "✅ VALID" or "❌ INVALID"))
	add_text("Reason: " .. reason1)
	add_text("")
	
	local valid1b, reason1b = mcp.validate_type("file<with>invalid:chars", "file_path")
	add_text("Input: 'file<with>invalid:chars'")
	add_text("Result: " .. (valid1b and "✅ VALID" or "❌ INVALID"))
	add_text("Reason: " .. reason1b)
	add_text("")
	
	-- Test filename type
	add_text("**Test 2: filename validation**")
	local valid2, reason2 = mcp.validate_type("config.json", "filename")
	add_text("Input: 'config.json'")
	add_text("Result: " .. (valid2 and "✅ VALID" or "❌ INVALID"))
	add_text("Reason: " .. reason2)
	add_text("")
	
	local valid2b, reason2b = mcp.validate_type("file/with/path", "filename")
	add_text("Input: 'file/with/path'")
	add_text("Result: " .. (valid2b and "✅ VALID" or "❌ INVALID"))
	add_text("Reason: " .. reason2b)
	add_text("")
	
	-- Test file_extension type
	add_text("**Test 3: file_extension validation**")
	local valid3, reason3 = mcp.validate_type(".lua", "file_extension")
	add_text("Input: '.lua'")
	add_text("Result: " .. (valid3 and "✅ VALID" or "❌ INVALID"))
	add_text("Reason: " .. reason3)
	add_text("")
	
	local valid3b, reason3b = mcp.validate_type("lua", "file_extension")
	add_text("Input: 'lua' (missing dot)")
	add_text("Result: " .. (valid3b and "✅ VALID" or "❌ INVALID"))
	add_text("Reason: " .. reason3b)
	add_text("")
	
	-- Test email type
	add_text("**Test 4: email validation**")
	local valid4, reason4 = mcp.validate_type("user@example.com", "email")
	add_text("Input: 'user@example.com'")
	add_text("Result: " .. (valid4 and "✅ VALID" or "❌ INVALID"))
	add_text("Reason: " .. reason4)
	add_text("")
	
	local valid4b, reason4b = mcp.validate_type("invalid-email", "email")
	add_text("Input: 'invalid-email'")
	add_text("Result: " .. (valid4b and "✅ VALID" or "❌ INVALID"))
	add_text("Reason: " .. reason4b)
	add_text("")
	
	-- Test version_string type
	add_text("**Test 5: version_string validation**")
	local valid5, reason5 = mcp.validate_type("1.2.3", "version_string")
	add_text("Input: '1.2.3'")
	add_text("Result: " .. (valid5 and "✅ VALID" or "❌ INVALID"))
	add_text("Reason: " .. reason5)
	add_text("")
	
	local valid5b, reason5b = mcp.validate_type("2.1.0-beta", "version_string")
	add_text("Input: '2.1.0-beta'")
	add_text("Result: " .. (valid5b and "✅ VALID" or "❌ INVALID"))
	add_text("Reason: " .. reason5b)
	add_text("")
	
	delay(DEMO_CONFIG.delay * 2)
	
	-- Demo 3: Tool parameter validation
	add_text("## Demo 3: Tool Parameter Validation")
	add_text("")
	add_text("**Testing complete tool parameter validation:**")
	add_text("")
	
	-- Test agent_create_file with valid parameters
	add_text("**Test 1: agent_create_file with valid parameters**")
	local valid_params1 = {
		file_name = "test.txt",
		content = "Hello World",
		open_in_window = false
	}
	local valid1, reason1 = mcp.validate_tool_parameters(valid_params1, "agent_create_file")
	add_text("Parameters: " .. vim.inspect(valid_params1))
	add_text("Result: " .. (valid1 and "✅ VALID" or "❌ INVALID"))
	add_text("Reason: " .. reason1)
	add_text("")
	
	-- Test agent_create_file with invalid parameters
	add_text("**Test 2: agent_create_file with invalid parameters**")
	local invalid_params1 = {
		file_name = "file/with/path", -- Invalid filename
		content = "Hello World",
		open_in_window = false
	}
	local valid2, reason2 = mcp.validate_tool_parameters(invalid_params1, "agent_create_file")
	add_text("Parameters: " .. vim.inspect(invalid_params1))
	add_text("Result: " .. (valid2 and "✅ VALID" or "❌ INVALID"))
	add_text("Reason: " .. reason2)
	add_text("")
	
	-- Test agent_edit_file with valid parameters
	add_text("**Test 3: agent_edit_file with valid parameters**")
	local valid_params2 = {
		file_path = "src/main.lua",
		line_number = 1,
		content = "print('Hello World')"
	}
	local valid3, reason3 = mcp.validate_tool_parameters(valid_params2, "agent_edit_file")
	add_text("Parameters: " .. vim.inspect(valid_params2))
	add_text("Result: " .. (valid3 and "✅ VALID" or "❌ INVALID"))
	add_text("Reason: " .. reason3)
	add_text("")
	
	-- Test agent_edit_file with invalid parameters
	add_text("**Test 4: agent_edit_file with invalid parameters**")
	local invalid_params2 = {
		file_path = "src/main.lua",
		line_number = 0, -- Invalid line number (must be >= 1)
		content = "print('Hello World')"
	}
	local valid4, reason4 = mcp.validate_tool_parameters(invalid_params2, "agent_edit_file")
	add_text("Parameters: " .. vim.inspect(invalid_params2))
	add_text("Result: " .. (valid4 and "✅ VALID" or "❌ INVALID"))
	add_text("Reason: " .. reason4)
	add_text("")
	
	delay(DEMO_CONFIG.delay * 2)
	
	-- Demo 4: Custom type creation
	add_text("## Demo 4: Custom Type Creation")
	add_text("")
	add_text("**Creating and using custom types:**")
	add_text("")
	
	-- Create a custom type
	add_text("**Step 1: Creating custom type 'python_function_name'**")
	local custom_type_def = {
		type = "string",
		description = "Python function name (snake_case)",
		validation = {
			pattern = "^[a-z][a-z0-9_]*$",
			min_length = 1,
			max_length = 50,
			examples = {"calculate_sum", "process_data", "validate_input"}
		}
	}
	
	local success1, message1 = mcp.create_custom_type("python_function_name", custom_type_def)
	add_text("Result: " .. (success1 and "✅ SUCCESS" or "❌ FAILED"))
	add_text("Message: " .. message1)
	add_text("")
	
	-- Test the custom type
	add_text("**Step 2: Testing custom type**")
	local valid_custom1, reason_custom1 = mcp.validate_type("calculate_sum", "python_function_name")
	add_text("Input: 'calculate_sum'")
	add_text("Result: " .. (valid_custom1 and "✅ VALID" or "❌ INVALID"))
	add_text("Reason: " .. reason_custom1)
	add_text("")
	
	local valid_custom2, reason_custom2 = mcp.validate_type("CalculateSum", "python_function_name")
	add_text("Input: 'CalculateSum' (PascalCase)")
	add_text("Result: " .. (valid_custom2 and "✅ VALID" or "❌ INVALID"))
	add_text("Reason: " .. reason_custom2)
	add_text("")
	
	-- Remove the custom type
	add_text("**Step 3: Removing custom type**")
	local success2, message2 = mcp.remove_custom_type("python_function_name")
	add_text("Result: " .. (success2 and "✅ SUCCESS" or "❌ FAILED"))
	add_text("Message: " .. message2)
	add_text("")
	
	delay(DEMO_CONFIG.delay)
	
	-- Demo 5: Type information display
	add_text("## Demo 5: Type Information Display")
	add_text("")
	add_text("**Showing detailed type information:**")
	add_text("")
	
	add_text("**Available Commands:**")
	add_text(":lua require('paragonic.mcp').show_type_info('file_path')")
	add_text(":lua require('paragonic.mcp').show_type_info('email')")
	add_text(":lua require('paragonic.mcp').show_type_info('version_string')")
	add_text("")
	
	add_text("**Type Information Includes:**")
	add_text("• Description and base type")
	add_text("• Validation patterns (regex)")
	add_text("• Length/value constraints")
	add_text("• Example values")
	add_text("")
	
	delay(DEMO_CONFIG.delay)
	
	-- Demo 6: Enhanced tool schemas
	add_text("## Demo 6: Enhanced Tool Schemas")
	add_text("")
	add_text("**Enhancing tool schemas with type information:**")
	add_text("")
	
	-- Enhance a tool schema
	add_text("**Step 1: Enhancing agent_create_file schema**")
	local success3, message3 = mcp.enhance_tool_schema("agent_create_file")
	add_text("Result: " .. (success3 and "✅ SUCCESS" or "❌ FAILED"))
	add_text("Message: " .. message3)
	add_text("")
	
	add_text("**Enhanced schema now includes:**")
	add_text("• Type descriptions")
	add_text("• Validation patterns")
	add_text("• Example values")
	add_text("• Better documentation")
	add_text("")
	
	delay(DEMO_CONFIG.delay)
	
	-- Show benefits
	add_text("## Type System Benefits")
	add_text("")
	add_text("✅ **Validation:** Automatic parameter validation with regex")
	add_text("✅ **Documentation:** Rich type descriptions and examples")
	add_text("✅ **Safety:** Prevents invalid tool calls")
	add_text("✅ **Extensibility:** Custom types for specific use cases")
	add_text("✅ **Consistency:** Standardized validation across tools")
	add_text("✅ **User Experience:** Better error messages and guidance")
	add_text("✅ **Integration:** Seamless integration with MCP approval system")
	add_text("")
	
	-- Show commands
	add_text("## Commands")
	add_text("")
	add_text("**Type Validation:**")
	add_text(":lua require('paragonic.mcp').validate_type('value', 'type_name')")
	add_text(":lua require('paragonic.mcp').validate_tool_parameters(params, 'tool_name')")
	add_text("")
	add_text("**Type Information:**")
	add_text(":lua require('paragonic.mcp').show_type_info('type_name')")
	add_text(":lua require('paragonic.mcp').list_available_types()")
	add_text("")
	add_text("**Custom Types:**")
	add_text(":lua require('paragonic.mcp').create_custom_type('name', definition)")
	add_text(":lua require('paragonic.mcp').remove_custom_type('name')")
	add_text("")
	add_text("**Schema Enhancement:**")
	add_text(":lua require('paragonic.mcp').enhance_tool_schema('tool_name')")
	add_text("")
	
	add_text("## Demo Notes")
	add_text("")
	add_text("• All string types support regex validation")
	add_text("• Custom types can be created for specific use cases")
	add_text("• Tool schemas are automatically enhanced with type info")
	add_text("• Validation happens before tool execution")
	add_text("• Type information is displayed in floating windows")
	add_text("")
	add_text("🎉 Tool Types system is working! 🎉")
	
	print("✅ Tool Types demo completed!")
	print("")
	print("💡 Try the commands shown above to explore types")
	print("💡 Use show_type_info() to see detailed type information")
	print("💡 Create custom types for your specific needs")
end

-- Run the demo
test_tool_types()
