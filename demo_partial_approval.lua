--[[
Partial Approval Demo
Test the space toggling functionality for batch actions
--]]

-- Set up Lua path to find paragonic modules
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

-- Check if running in Neovim
local is_neovim = pcall(function() return vim.version() end)

if not is_neovim then
	print("🎬 Partial Approval Demo")
	print("=" .. string.rep("=", 40))
	print("")
	print("⚠️  This demo requires Neovim to run properly.")
	print("")
	print("💡 To test partial approval:")
	print("   1. Open Neovim: nvim")
	print("   2. Source this file: :source demo_partial_approval.lua")
	print("   3. Run: :lua test_partial_approval()")
	print("")
	return
end

-- Load the MCP module
local mcp = require("paragonic.mcp")

-- Initialize the system
function initialize_partial_demo()
	-- Initialize MCP server
	if mcp.initialize_mcp_server then
		mcp.initialize_mcp_server()
	end
	
	-- Initialize approval state
	if mcp.initialize_approval_state then
		mcp.initialize_approval_state()
	end
	
	print("✅ System initialized for partial approval testing")
end

-- Test partial approval with space toggling
function test_partial_approval()
	print("📦 Testing Partial Approval with Space Toggling")
	print("=" .. string.rep("=", 50))
	print("")
	print("🎯 A batch action dialog will appear with multiple actions.")
	print("   Press 'p' to enter partial approval mode.")
	print("   In partial approval mode:")
	print("   - Use <Space> to toggle selections")
	print("   - Use <Enter> to confirm")
	print("   - Use <Esc> to cancel")
	print("")
	
	-- Initialize if needed
	initialize_partial_demo()
	
	-- Create a batch action request with multiple actions
	local batch_request = {
		id = "partial-test-" .. os.time(),
		type = "batch_action",
		actions = {
			{
				type = "edit",
				file = "main.py",
				tool_name = "agent_edit_file",
				line = 1,
				content = "# Main application",
				description = "Add main application header"
			},
			{
				type = "edit",
				file = "utils.py",
				tool_name = "agent_edit_file",
				line = 1,
				content = "# Utility functions",
				description = "Add utility functions header"
			},
			{
				type = "create",
				file = "config.py",
				tool_name = "agent_create_file",
				content = "# Configuration",
				description = "Create configuration file"
			},
			{
				type = "edit",
				file = "README.md",
				tool_name = "agent_edit_file",
				line = 1,
				content = "# Project Title",
				description = "Update README title"
			},
			{
				type = "edit",
				file = "requirements.txt",
				tool_name = "agent_edit_file",
				line = 1,
				content = "requests>=2.25.0",
				description = "Add requests dependency"
			}
		},
		description = "Initialize Python project structure",
		timeout = 300 -- 5 minutes
	}
	
	-- Register batch request
	local register_success = mcp.register_approval_request(batch_request)
	print("📋 Batch request registered: " .. tostring(register_success))
	
	-- Create batch action dialog
	local dialog = mcp.create_batch_action_dialog(batch_request.id)
	if dialog then
		print("🖥️ Batch action dialog displayed")
		print("   Press 'p' to test partial approval with space toggling")
		mcp.display_approval_dialog(dialog)
	else
		print("❌ Failed to create batch action dialog")
	end
end

-- Test individual partial approval
function test_single_partial()
	print("🎯 Testing Single Partial Approval")
	print("=" .. string.rep("=", 40))
	print("")
	print("This will show just the partial approval dialog.")
	print("")
	
	-- Initialize if needed
	initialize_partial_demo()
	
	-- Create a simple batch request
	local batch_request = {
		id = "single-partial-" .. os.time(),
		type = "batch_action",
		actions = {
			{
				type = "edit",
				file = "test1.txt",
				description = "Create first test file"
			},
			{
				type = "edit", 
				file = "test2.txt",
				description = "Create second test file"
			},
			{
				type = "edit",
				file = "test3.txt", 
				description = "Create third test file"
			}
		},
		description = "Create test files",
		timeout = 300
	}
	
	-- Register and create dialog
	mcp.register_approval_request(batch_request)
	local dialog = mcp.create_batch_action_dialog(batch_request.id)
	
	if dialog then
		print("🖥️ Batch dialog created")
		print("   Press 'p' to enter partial approval mode")
		mcp.display_approval_dialog(dialog)
	else
		print("❌ Failed to create dialog")
	end
end

-- Export for use in Neovim
return {
	test_partial_approval = test_partial_approval,
	test_single_partial = test_single_partial
}
