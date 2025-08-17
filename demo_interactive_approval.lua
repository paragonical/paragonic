--[[
Interactive MCP Sampling Approval Demo
This demo creates approval dialogs and waits for actual user interaction
--]]

-- Set up Lua path to find paragonic modules
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

-- Check if running in Neovim
local is_neovim = pcall(function() return vim.version() end)

if not is_neovim then
	print("🎬 Interactive MCP Sampling Approval Demo")
	print("=" .. string.rep("=", 50))
	print("")
	print("⚠️  This demo requires Neovim to run properly.")
	print("")
	print("💡 To see this in action:")
	print("   1. Open Neovim: nvim")
	print("   2. Source this file: :source demo_interactive_approval.lua")
	print("   3. Run the demo: :lua run_interactive_demo()")
	print("")
	return
end

-- Load the MCP module
local mcp = require("paragonic.mcp")

-- Initialize the system
function initialize_interactive_demo()
	print("🚀 Initializing Interactive MCP Sampling Approval Demo...")
	
	-- Initialize MCP server
	if mcp.initialize_mcp_server then
		mcp.initialize_mcp_server()
	end
	
	-- Initialize approval state
	if mcp.initialize_approval_state then
		mcp.initialize_approval_state()
	end
	
	print("✅ System initialized successfully")
	print("")
end

-- Demo 1: Interactive Basic Approval Dialog
function demo_interactive_basic_approval()
	print("📝 Demo 1: Interactive Basic Approval Dialog")
	print("=" .. string.rep("=", 50))
	print("")
	print("🎯 A basic approval dialog will appear.")
	print("   Use 'y' to approve, 'n' to deny, or 'q' to quit.")
	print("   The dialog will stay open until you make a choice.")
	print("")
	
	-- Create a simple approval request
	local request = {
		id = "interactive-basic-" .. os.time(),
		type = "tool_execution",
		tool_name = "agent_edit_file",
		parameters = {
			file_path = "example.lua",
			line_number = 10,
			content = "print('Hello from AI agent!')"
		},
		timeout = 300, -- 5 minutes timeout for demo
		impact = "Will add a print statement to line 10"
	}
	
	-- Register the approval request
	local register_success = mcp.register_approval_request(request)
	print("📋 Request registered: " .. tostring(register_success))
	
	-- Create and display approval dialog
	local dialog = mcp.create_approval_dialog(request.id)
	if dialog then
		print("🖥️ Approval dialog created and displayed")
		print("   Look for the floating window above!")
		print("")
		print("⏳ Waiting for your interaction...")
		print("   (The dialog will stay open until you choose y/n/q)")
		
		-- Display the dialog and wait for user interaction
		mcp.display_approval_dialog(dialog)
		
		-- Don't automatically handle the approval - let the user interact
		-- The dialog will stay open until the user presses y, n, or q
		
		print("✅ Dialog interaction completed")
	else
		print("❌ Failed to create approval dialog")
	end
	
	print("")
end

-- Demo 2: Interactive Decision Point Dialog
function demo_interactive_decision_point()
	print("🤔 Demo 2: Interactive Decision Point Dialog")
	print("=" .. string.rep("=", 50))
	print("")
	print("🎯 A decision point dialog will appear with numbered options.")
	print("   Use '1', '2', '3' to select an option, or 'q' to quit.")
	print("   The dialog will stay open until you make a choice.")
	print("")
	
	-- Create a decision point request
	local decision_request = {
		id = "interactive-decision-" .. os.time(),
		type = "decision_point",
		question = "Which approach should be used for this project?",
		options = {
			"Option 1: Simple and straightforward approach",
			"Option 2: Advanced with additional features", 
			"Option 3: Hybrid approach with best of both"
		},
		timeout = 300 -- 5 minutes timeout for demo
	}
	
	-- Register decision request
	local register_success = mcp.register_approval_request(decision_request)
	print("📋 Decision request registered: " .. tostring(register_success))
	
	-- Create decision point dialog
	local dialog = mcp.create_decision_point_dialog(decision_request.id)
	if dialog then
		print("🖥️ Decision point dialog created and displayed")
		print("   Look for the floating window with numbered options!")
		print("")
		print("⏳ Waiting for your selection...")
		print("   (The dialog will stay open until you choose 1/2/3/q)")
		
		-- Display the dialog and wait for user interaction
		mcp.display_approval_dialog(dialog)
		
		-- Don't automatically handle the selection - let the user interact
		-- The dialog will stay open until the user presses 1, 2, 3, or q
		
		print("✅ Decision point interaction completed")
	else
		print("❌ Failed to create decision point dialog")
	end
	
	print("")
end

-- Demo 3: Interactive Batch Action Dialog
function demo_interactive_batch_action()
	print("📦 Demo 3: Interactive Batch Action Dialog")
	print("=" .. string.rep("=", 50))
	print("")
	print("🎯 A batch action dialog will appear with multiple actions.")
	print("   Use 'y' to approve all, 'n' to deny all, 'p' for partial approval, or 'q' to quit.")
	print("   The dialog will stay open until you make a choice.")
	print("")
	
	-- Create a batch action request
	local batch_request = {
		id = "interactive-batch-" .. os.time(),
		type = "batch_action",
		actions = {
			{
				type = "edit",
				file = "main.lua",
				tool_name = "agent_edit_file",
				line = 1,
				content = "-- Main entry point"
			},
			{
				type = "edit",
				file = "utils.lua",
				tool_name = "agent_edit_file",
				line = 1,
				content = "-- Utility functions"
			},
			{
				type = "create",
				file = "config.lua",
				tool_name = "agent_create_file",
				content = "-- Configuration file"
			}
		},
		description = "Create project structure with multiple files",
		timeout = 300 -- 5 minutes timeout for demo
	}
	
	-- Register batch request
	local register_success = mcp.register_approval_request(batch_request)
	print("📋 Batch request registered: " .. tostring(register_success))
	
	-- Create batch action dialog
	local dialog = mcp.create_batch_action_dialog(batch_request.id)
	if dialog then
		print("🖥️ Batch action dialog created and displayed")
		print("   Look for the floating window with multiple actions!")
		print("")
		print("⏳ Waiting for your batch decision...")
		print("   (The dialog will stay open until you choose y/n/p/q)")
		
		-- Display the dialog and wait for user interaction
		mcp.display_approval_dialog(dialog)
		
		-- Don't automatically handle the batch approval - let the user interact
		-- The dialog will stay open until the user presses y, n, p, or q
		
		print("✅ Batch action interaction completed")
	else
		print("❌ Failed to create batch action dialog")
	end
	
	print("")
end

-- Demo 4: Show System Status
function demo_system_status()
	print("📊 Demo 4: System Status")
	print("=" .. string.rep("=", 50))
	
	-- Show approval state
	local pending_count = mcp.get_pending_approval_count()
	print("📋 Pending approvals: " .. pending_count)
	
	-- Show active dialogs
	local ui = require("paragonic.mcp_approval_ui")
	local dialog_count = ui.get_active_dialog_count()
	print("🖥️ Active dialogs: " .. dialog_count)
	
	-- Show MCP tools
	if mcp.mcp_tools then
		local tool_count = 0
		for _ in pairs(mcp.mcp_tools) do
			tool_count = tool_count + 1
		end
		print("🔧 Available MCP tools: " .. tool_count)
	end
	
	print("")
end

-- Main demo function
function run_interactive_demo()
	print("🎬 Interactive MCP Sampling Approval Demo")
	print("=" .. string.rep("=", 60))
	print("")
	print("🎯 This demo will create approval dialogs and wait for YOUR interaction.")
	print("   Each dialog will stay open until you make a choice.")
	print("")
	print("📋 Available controls:")
	print("   - 'y' = Approve action")
	print("   - 'n' = Deny action")
	print("   - '1', '2', '3' = Select numbered options")
	print("   - 'p' = Partial approval (batch actions)")
	print("   - 'q' or '<Esc>' = Close dialog")
	print("")
	
	-- Initialize the system
	initialize_interactive_demo()
	
	-- Run interactive demos
	demo_interactive_basic_approval()
	demo_interactive_decision_point()
	demo_interactive_batch_action()
	demo_system_status()
	
	print("🎉 Interactive demo completed!")
	print("")
	print("💡 What you just experienced:")
	print("   - Real approval dialogs that wait for your input")
	print("   - Different types of dialogs (approval, decision, batch)")
	print("   - Interactive controls with keyboard shortcuts")
	print("")
	print("🎯 In real usage:")
	print("   - AI agents automatically trigger these dialogs")
	print("   - You have full control over AI actions")
	print("   - All approved actions are tracked and can be undone")
	print("")
	print("🔧 Try these commands to explore further:")
	print("   :lua mcp.get_pending_approval_count()")
	print("   :lua mcp.cleanup_completed_approvals()")
	print("   :lua demo_system_status()")
end

-- Export for use in Neovim
return {
	run_interactive_demo = run_interactive_demo,
	demo_interactive_basic_approval = demo_interactive_basic_approval,
	demo_interactive_decision_point = demo_interactive_decision_point,
	demo_interactive_batch_action = demo_interactive_batch_action,
	demo_system_status = demo_system_status
}
