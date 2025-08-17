--[[
Chat Integration Demo
Demonstrates MCP sampling approval with sigil markers in chat buffers
--]]

-- Set up Lua path to find paragonic modules
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

-- Check if running in Neovim
local is_neovim = pcall(function() return vim.version() end)

if not is_neovim then
	print("🎬 Chat Integration Demo")
	print("=" .. string.rep("=", 40))
	print("")
	print("⚠️  This demo requires Neovim to run properly.")
	print("")
	print("💡 To test chat integration:")
	print("   1. Open Neovim: nvim")
	print("   2. Source this file: :source demo_chat_integration.lua")
	print("   3. Run: :lua test_chat_integration()")
	print("")
	return
end

-- Load the MCP module
local mcp = require("paragonic.mcp")

-- Initialize the system
function initialize_chat_demo()
	-- Initialize MCP server
	if mcp.initialize_mcp_server then
		mcp.initialize_mcp_server()
	end
	
	-- Initialize approval state
	if mcp.initialize_approval_state then
		mcp.initialize_approval_state()
	end
	
	-- Initialize chat integration
	local chat = require("paragonic.mcp_chat_integration")
	if chat.initialize then
		chat.initialize()
	end
	
	print("✅ Chat integration initialized")
end

-- Test chat integration with sigil markers
function test_chat_integration()
	print("💬 Testing Chat Integration with Sigil Markers")
	print("=" .. string.rep("=", 50))
	print("")
	print("🎯 This demo will create approval requests that appear as markers in the chat buffer.")
	print("   Look for the 󰭙 icon with pending approval markers.")
	print("   Press Enter on a marker to process the approval.")
	print("")
	
	-- Initialize if needed
	initialize_chat_demo()
	
	-- Create a chat-like buffer
	local buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_buf_set_name(buf, "chat_demo")
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
	
	-- Add some chat content
	local lines = {
		"# Chat Demo",
		"",
		"User: Can you help me create a Python project?",
		"",
		"AI: I'll help you create a Python project structure. Let me set up the basic files.",
		"",
		"-- Approval requests will appear below --",
		""
	}
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	
	-- Open the buffer
	vim.api.nvim_command("edit chat_demo")
	
	-- Set up chat buffer mappings
	local chat = require("paragonic.mcp_chat_integration")
	if chat.setup_chat_buffer_mappings then
		chat.setup_chat_buffer_mappings()
	end
	
	-- Create multiple approval requests
	local requests = {
		{
			id = "chat-edit-main-" .. os.time(),
			type = "tool_execution",
			tool_name = "agent_edit_file",
			parameters = {
				file_path = "main.py",
				line_number = 1,
				content = "# Main application"
			},
			description = "Create main.py with application header",
			timeout = 300
		},
		{
			id = "chat-edit-utils-" .. os.time(),
			type = "tool_execution",
			tool_name = "agent_edit_file",
			parameters = {
				file_path = "utils.py",
				line_number = 1,
				content = "# Utility functions"
			},
			description = "Create utils.py with utility functions",
			timeout = 300
		},
		{
			id = "chat-decision-" .. os.time(),
			type = "decision_point",
			question = "Which testing framework should we use?",
			options = {
				"pytest (recommended)",
				"unittest (built-in)",
				"nose (legacy)"
			},
			description = "Choose testing framework for the project",
			timeout = 300
		},
		{
			id = "chat-batch-" .. os.time(),
			type = "batch_action",
			actions = {
				{
					type = "create",
					file = "requirements.txt",
					description = "Create requirements file"
				},
				{
					type = "create",
					file = "README.md",
					description = "Create README file"
				},
				{
					type = "create",
					file = ".gitignore",
					description = "Create gitignore file"
				}
			},
			description = "Create project documentation and config files",
			timeout = 300
		}
	}
	
	-- Register all requests (this will create markers automatically)
	for i, request in ipairs(requests) do
		local success = mcp.register_approval_request(request)
		print("📋 Request " .. i .. " registered: " .. tostring(success))
	end
	
	print("")
	print("✅ Chat integration demo setup complete!")
	print("")
	print("🎯 What to do next:")
	print("   1. Look for the 󰭙 markers in the chat buffer")
	print("   2. Move your cursor to a marker line")
	print("   3. Press Enter to process the approval")
	print("   4. Choose Approve, Deny, or Details")
	print("")
	print("💡 The markers will update their status automatically:")
	print("   🔄 = Pending, ✅ = Approved, ❌ = Denied, ⏰ = Timeout")
end

-- Test individual marker creation
function test_single_marker()
	print("🎯 Testing Single Marker Creation")
	print("=" .. string.rep("=", 40))
	print("")
	
	-- Initialize if needed
	initialize_chat_demo()
	
	-- Create a single approval request
	local request = {
		id = "single-marker-" .. os.time(),
		type = "tool_execution",
		tool_name = "agent_edit_file",
		parameters = {
			file_path = "test.py",
			line_number = 1,
			content = "print('Hello, World!')"
		},
		description = "Create a simple test file",
		timeout = 300
	}
	
	-- Register the request (this will create a marker)
	local success = mcp.register_approval_request(request)
	print("📋 Single marker request registered: " .. tostring(success))
	
	if success then
		print("🖥️ Look for the 󰭙 marker in the current buffer")
		print("   Press Enter on the marker to process it")
	end
end

-- Show chat integration status
function show_chat_status()
	print("📊 Chat Integration Status")
	print("=" .. string.rep("=", 40))
	
	-- Initialize if needed
	initialize_chat_demo()
	
	local chat = require("paragonic.mcp_chat_integration")
	
	-- Show pending approvals
	local pending_count = chat.get_pending_approval_count()
	print("📋 Pending approvals: " .. pending_count)
	
	-- Show all approvals
	local total_count = 0
	for _ in pairs(chat.pending_approvals) do
		total_count = total_count + 1
	end
	print("📊 Total approval markers: " .. total_count)
	
	-- Show approval details
	if total_count > 0 then
		print("")
		print("📋 Approval Details:")
		for approval_id, approval in pairs(chat.pending_approvals) do
			print("  " .. approval_id .. ": " .. approval.status .. " - " .. approval.description)
		end
	end
end

-- Export for use in Neovim
return {
	test_chat_integration = test_chat_integration,
	test_single_marker = test_single_marker,
	show_chat_status = show_chat_status
}
