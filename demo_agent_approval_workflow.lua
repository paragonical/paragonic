--[[
Demo: Agent Approval Workflow with MCP Tools
Proof of concept showing how agents use MCP tools with approval system
--]]

-- Check if running in Neovim
local is_neovim = pcall(function() return vim.api.nvim_get_current_buf() end)

if not is_neovim then
	print("❌ This demo must be run inside Neovim")
	print("   Please open Neovim and run: :lua dofile('demo_agent_approval_workflow.lua')")
	os.exit(1)
end

-- Demo configuration
local DEMO_CONFIG = {
	demo_buffer_name = "*Agent Approval Workflow Demo*",
	delay = 1500, -- milliseconds
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

-- Test agent approval workflow
local function test_agent_approval_workflow()
	print("🚀 Starting Agent Approval Workflow Demo")
	print("")
	
	-- Initialize MCP system
	local mcp = require("paragonic.mcp")
	if mcp.initialize_mcp_server then
		mcp.initialize_mcp_server()
	end
	
	-- Initialize approval system
	if mcp.initialize_approval_state then
		mcp.initialize_approval_state()
	end
	
	-- Initialize chat approval UI
	if mcp.initialize_chat_approval then
		mcp.initialize_chat_approval()
	end
	
	-- Clear buffer
	clear_buffer()
	
	-- Add demo header
	add_text("# Agent Approval Workflow Demo")
	add_text("")
	add_text("This demo showcases how AI agents use MCP tools with the approval system.")
	add_text("")
	add_text("## Workflow Overview:")
	add_text("1. Agent requests to use MCP tools")
	add_text("2. System creates approval markers in chat")
	add_text("3. User approves/denies the requests")
	add_text("4. Tools execute based on user decisions")
	add_text("")
	
	delay(DEMO_CONFIG.delay)
	
	-- Demo 1: Agent requesting file creation (requires approval)
	add_text("## Demo 1: Agent Requesting File Creation")
	add_text("")
	add_text("**Scenario:** Agent wants to create a new configuration file")
	add_text("")
	add_text("**Agent Request:** 'I need to create a config.json file for this project'")
	add_text("")
	
	-- Create approval request for file creation
	local request_id = "demo-file-create-" .. os.time()
	local approval_request = {
		id = request_id,
		type = "tool_execution",
		tool_name = "agent_create_file",
		description = "Create config.json file for project configuration",
		impact = "Will create a new configuration file in the project root",
		parameters = {
			file_name = "config.json",
			content = '{\n  "project": "demo",\n  "version": "1.0.0",\n  "created_by": "ai_agent"\n}',
			open_in_window = false
		},
		timeout = 60
	}
	
	-- Register the approval request
	local success = mcp.register_approval_request(approval_request)
	if success then
		add_text("**System:** Approval request created")
		add_text("**Marker:** 󰭙 🔄 [tool_execution] Create config.json file for project configuration")
		add_text("**Status:** Waiting for user approval")
		add_text("")
		add_text("**User Action Required:**")
		add_text("• Move cursor to the marker line above")
		add_text("• Press Enter to see approval options")
		add_text("• Choose 'Approve' to allow file creation")
		add_text("• Choose 'Deny' to reject the request")
		add_text("")
	else
		add_text("**System:** Failed to create approval request")
	end
	
	delay(DEMO_CONFIG.delay * 2)
	
	-- Demo 2: Agent requesting file editing (requires approval)
	add_text("## Demo 2: Agent Requesting File Editing")
	add_text("")
	add_text("**Scenario:** Agent wants to modify an existing file")
	add_text("")
	add_text("**Agent Request:** 'I need to add a header comment to the main file'")
	add_text("")
	
	-- Create approval request for file editing
	local edit_request_id = "demo-file-edit-" .. os.time()
	local edit_approval_request = {
		id = edit_request_id,
		type = "tool_execution",
		tool_name = "agent_edit_file",
		description = "Add header comment to main file",
		impact = "Will add a comment at the top of the current file",
		parameters = {
			file_path = vim.api.nvim_buf_get_name(0) or "unknown.txt",
			line_number = 1,
			content = "-- Modified by AI Agent: " .. os.date("%Y-%m-%d %H:%M:%S")
		},
		timeout = 60
	}
	
	-- Register the approval request
	local edit_success = mcp.register_approval_request(edit_approval_request)
	if edit_success then
		add_text("**System:** Approval request created")
		add_text("**Marker:** 󰭙 🔄 [tool_execution] Add header comment to main file")
		add_text("**Status:** Waiting for user approval")
		add_text("")
		add_text("**User Action Required:**")
		add_text("• Move cursor to the marker line above")
		add_text("• Press Enter to see approval options")
		add_text("• Choose 'Approve' to allow file editing")
		add_text("• Choose 'Deny' to reject the request")
		add_text("")
	else
		add_text("**System:** Failed to create approval request")
	end
	
	delay(DEMO_CONFIG.delay * 2)
	
	-- Demo 3: Agent requesting batch operations (requires approval)
	add_text("## Demo 3: Agent Requesting Batch Operations")
	add_text("")
	add_text("**Scenario:** Agent wants to perform multiple related actions")
	add_text("")
	add_text("**Agent Request:** 'I need to set up the project structure with multiple files'")
	add_text("")
	
	-- Create approval request for batch operations
	local batch_request_id = "demo-batch-" .. os.time()
	local batch_approval_request = {
		id = batch_request_id,
		type = "batch_action",
		description = "Set up project structure with multiple files",
		impact = "Will create README.md, .gitignore, and package.json files",
		actions = {
			{
				tool_name = "agent_create_file",
				parameters = {
					file_name = "README.md",
					content = "# Project Demo\n\nThis project was set up by an AI agent using MCP tools.\n",
					open_in_window = false
				}
			},
			{
				tool_name = "agent_create_file",
				parameters = {
					file_name = ".gitignore",
					content = "*.tmp\n*.log\nnode_modules/\n",
					open_in_window = false
				}
			},
			{
				tool_name = "agent_create_file",
				parameters = {
					file_name = "package.json",
					content = '{\n  "name": "demo-project",\n  "version": "1.0.0",\n  "description": "Demo project"\n}',
					open_in_window = false
				}
			}
		},
		timeout = 120
	}
	
	-- Register the approval request
	local batch_success = mcp.register_approval_request(batch_approval_request)
	if batch_success then
		add_text("**System:** Batch approval request created")
		add_text("**Marker:** 󰭙 🔄 [batch_action] Set up project structure with multiple files")
		add_text("**Status:** Waiting for user approval")
		add_text("")
		add_text("**User Action Required:**")
		add_text("• Move cursor to the marker line above")
		add_text("• Press Enter to see approval options")
		add_text("• Choose 'Approve' to allow all actions")
		add_text("• Choose 'Deny' to reject all actions")
		add_text("• Choose 'Partial Approval' to select specific actions")
		add_text("")
	else
		add_text("**System:** Failed to create batch approval request")
	end
	
	delay(DEMO_CONFIG.delay * 2)
	
	-- Demo 4: Auto-approved tools (no approval needed)
	add_text("## Demo 4: Auto-Approved Tools")
	add_text("")
	add_text("**Scenario:** Agent uses tools that don't require approval")
	add_text("")
	add_text("**Agent Request:** 'What's my current session status?'")
	add_text("")
	
	-- This would be auto-approved
	add_text("**System:** Using agent_session_info (auto-approved)")
	add_text("**Action:** Getting session information")
	add_text("**Status:** Executed immediately (no approval needed)")
	add_text("")
	add_text("**Agent Request:** 'Search for Lua files in the project'")
	add_text("")
	add_text("**System:** Using agent_search_files (auto-approved)")
	add_text("**Action:** Searching for *.lua files")
	add_text("**Status:** Executed immediately (no approval needed)")
	add_text("")
	
	delay(DEMO_CONFIG.delay)
	
	-- Demo 5: Decision point (requires user choice)
	add_text("## Demo 5: Decision Point")
	add_text("")
	add_text("**Scenario:** Agent needs user input for a decision")
	add_text("")
	add_text("**Agent Request:** 'Which testing framework should I use for this project?'")
	add_text("")
	
	-- Create decision point request
	local decision_request_id = "demo-decision-" .. os.time()
	local decision_approval_request = {
		id = decision_request_id,
		type = "decision_point",
		description = "Choose testing framework for the project",
		impact = "Will determine which testing framework to set up",
		options = {
			"Jest - JavaScript testing framework",
			"Pytest - Python testing framework", 
			"RSpec - Ruby testing framework",
			"Custom - Let me specify a different framework"
		},
		default_option = 1,
		timeout = 120
	}
	
	-- Register the decision point request
	local decision_success = mcp.register_approval_request(decision_approval_request)
	if decision_success then
		add_text("**System:** Decision point created")
		add_text("**Marker:** 󰭙 🔄 [decision_point] Choose testing framework for the project")
		add_text("**Status:** Waiting for user decision")
		add_text("")
		add_text("**User Action Required:**")
		add_text("• Move cursor to the marker line above")
		add_text("• Press Enter to see decision options")
		add_text("• Choose from the available testing frameworks")
		add_text("• Or select 'Custom' to specify your own")
		add_text("")
	else
		add_text("**System:** Failed to create decision point")
	end
	
	delay(DEMO_CONFIG.delay * 2)
	
	-- Show approval workflow benefits
	add_text("## Approval Workflow Benefits")
	add_text("")
	add_text("✅ **Safety:** All file operations require user approval")
	add_text("✅ **Transparency:** Clear markers show what agents want to do")
	add_text("✅ **Control:** Users can approve, deny, or modify requests")
	add_text("✅ **Batch Operations:** Handle multiple related actions together")
	add_text("✅ **Decision Points:** Get user input for important choices")
	add_text("✅ **Auto-Approval:** Safe tools execute immediately")
	add_text("✅ **Audit Trail:** All decisions are tracked and logged")
	add_text("")
	
	-- Show interaction methods
	add_text("## Interaction Methods")
	add_text("")
	add_text("**Method 1: Enter Key**")
	add_text("• Move cursor to marker line")
	add_text("• Press Enter to see options")
	add_text("• Choose from the menu")
	add_text("")
	add_text("**Method 2: Quick Actions**")
	add_text("• Move cursor to marker line")
	add_text("• Press 'ya' to quick approve")
	add_text("• Press 'nd' to quick deny")
	add_text("• Press 'gd' to see details")
	add_text("")
	add_text("**Method 3: Visual Mode**")
	add_text("• Select multiple marker lines")
	add_text("• Press 'ya' to approve all selected")
	add_text("• Press 'nd' to deny all selected")
	add_text("")
	
	-- Show commands
	add_text("## Commands")
	add_text("")
	add_text("You can test the approval system manually:")
	add_text(":lua require('paragonic.mcp').get_pending_approval_count()")
	add_text(":lua require('paragonic.mcp').get_pending_approvals()")
	add_text(":lua require('paragonic.mcp').approve_request('request-id', {})")
	add_text(":lua require('paragonic.mcp').deny_request('request-id', {})")
	add_text("")
	
	add_text("## Demo Notes")
	add_text("")
	add_text("• All file operations require approval")
	add_text("• Session info and search are auto-approved")
	add_text("• Decision points require user choice")
	add_text("• Batch operations can be partially approved")
	add_text("• All actions are tracked in the audit trail")
	add_text("• Timeout occurs if no action is taken")
	add_text("")
	add_text("🎉 Agent Approval Workflow is working! 🎉")
	
	print("✅ Agent Approval Workflow demo completed!")
	print("")
	print("💡 Look for the 󰭙 markers in your chat buffer")
	print("💡 Try the different interaction methods shown above")
	print("💡 Check the approval system status with the commands")
end

-- Run the demo
test_agent_approval_workflow()
