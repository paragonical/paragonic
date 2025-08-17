--[[
Simple MCP Sampling Approval Demo
A simplified demo focusing on core approval functionality
--]]

-- Set up Lua path to find paragonic modules
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

-- Check if running in Neovim
local is_neovim = pcall(function() return vim.version() end)

if not is_neovim then
	print("🎬 Simple MCP Sampling Approval Demo")
	print("=" .. string.rep("=", 50))
	print("")
	print("⚠️  This demo requires Neovim to run properly.")
	print("")
	print("💡 To see this in action:")
	print("   1. Open Neovim: nvim")
	print("   2. Source this file: :source demo_simple_approval.lua")
	print("   3. Run the demo: :lua run_simple_demo()")
	print("")
	return
end

-- Load the MCP module
local mcp = require("paragonic.mcp")

-- Initialize the system
function initialize_simple_demo()
	print("🚀 Initializing Simple MCP Sampling Approval Demo...")
	
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

-- Demo 1: Basic Approval Dialog
function demo_basic_approval()
	print("📝 Demo 1: Basic Approval Dialog")
	print("=" .. string.rep("=", 40))
	
	-- Create a simple approval request
	local request = {
		id = "simple-basic-" .. os.time(),
		type = "tool_execution",
		tool_name = "agent_edit_file",
		parameters = {
			file_path = "example.lua",
			line_number = 1,
			content = "-- Example content"
		},
		timeout = 30
	}
	
	-- Register the approval request
	local register_success = mcp.register_approval_request(request)
	print("📋 Request registered: " .. tostring(register_success))
	
	-- Create and display approval dialog
	local dialog = mcp.create_approval_dialog(request.id)
	if dialog then
		print("🖥️ Approval dialog created")
		mcp.display_approval_dialog(dialog)
		
		-- Simulate user approval
		print("👤 Simulating user approval...")
		local approval_success = mcp.handle_user_approval(dialog, {
			approved = true,
			notes = "Simple demo approval"
		})
		print("✅ User approval handled: " .. tostring(approval_success))
		
		-- Close the dialog
		mcp.close_approval_dialog(dialog)
	end
	
	-- Check the approval status
	local approval = mcp.get_approval_request(request.id)
	print("📊 Approval status: " .. (approval.status or "unknown"))
	
	print("")
end

-- Demo 2: Decision Point Dialog
function demo_decision_point()
	print("🤔 Demo 2: Decision Point Dialog")
	print("=" .. string.rep("=", 40))
	
	-- Create a decision point request
	local decision_request = {
		id = "simple-decision-" .. os.time(),
		type = "decision_point",
		question = "Which approach should be used?",
		options = {
			"Option A: Simple approach",
			"Option B: Advanced approach", 
			"Option C: Hybrid approach"
		},
		timeout = 45
	}
	
	-- Register decision request
	local register_success = mcp.register_approval_request(decision_request)
	print("📋 Decision request registered: " .. tostring(register_success))
	
	-- Create decision point dialog
	local dialog = mcp.create_decision_point_dialog(decision_request.id)
	if dialog then
		print("🖥️ Decision point dialog created")
		mcp.display_approval_dialog(dialog)
		
		-- Simulate option selection
		print("👤 Simulating option selection (Option B)...")
		local selection_success = mcp.handle_option_selection(dialog, 2)
		print("✅ Option selection handled: " .. tostring(selection_success))
		
		-- Close the dialog
		mcp.close_approval_dialog(dialog)
	end
	
	print("")
end

-- Demo 3: Batch Action Dialog
function demo_batch_action()
	print("📦 Demo 3: Batch Action Dialog")
	print("=" .. string.rep("=", 40))
	
	-- Create a batch action request
	local batch_request = {
		id = "simple-batch-" .. os.time(),
		type = "batch_action",
		actions = {
			{
				type = "edit",
				file = "file1.lua",
				tool_name = "agent_edit_file",
				line = 1,
				content = "-- Action 1"
			},
			{
				type = "edit",
				file = "file2.lua",
				tool_name = "agent_edit_file",
				line = 1,
				content = "-- Action 2"
			}
		},
		description = "Simple batch modifications",
		timeout = 60
	}
	
	-- Register batch request
	local register_success = mcp.register_approval_request(batch_request)
	print("📋 Batch request registered: " .. tostring(register_success))
	
	-- Create batch action dialog
	local dialog = mcp.create_batch_action_dialog(batch_request.id)
	if dialog then
		print("🖥️ Batch action dialog created")
		mcp.display_approval_dialog(dialog)
		
		-- Simulate partial approval
		print("👤 Simulating partial approval (first action)...")
		local partial_success = mcp.handle_partial_approval(dialog, {1})
		print("✅ Partial approval handled: " .. tostring(partial_success))
		
		-- Close the dialog
		mcp.close_approval_dialog(dialog)
	end
	
	print("")
end

-- Demo 4: System Status
function demo_system_status()
	print("📊 Demo 4: System Status")
	print("=" .. string.rep("=", 40))
	
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
function run_simple_demo()
	print("🎬 Simple MCP Sampling Approval Demo")
	print("=" .. string.rep("=", 50))
	print("")
	
	-- Initialize the system
	initialize_simple_demo()
	
	-- Run demos
	demo_basic_approval()
	demo_decision_point()
	demo_batch_action()
	demo_system_status()
	
	print("🎉 Simple demo completed successfully!")
	print("")
	print("💡 What you just saw:")
	print("   - Approval dialogs for tool execution")
	print("   - Decision point dialogs with options")
	print("   - Batch action dialogs with partial approval")
	print("   - System status information")
	print("")
	print("🎯 In real usage:")
	print("   - AI agents automatically trigger these dialogs")
	print("   - Users interact with dialogs using keyboard shortcuts")
	print("   - All actions are tracked and can be undone")
	print("")
	print("🔧 Try these commands:")
	print("   :lua mcp.get_pending_approval_count()")
	print("   :lua mcp.cleanup_completed_approvals()")
end

-- Export for use in Neovim
return {
	run_simple_demo = run_simple_demo,
	demo_basic_approval = demo_basic_approval,
	demo_decision_point = demo_decision_point,
	demo_batch_action = demo_batch_action,
	demo_system_status = demo_system_status
}
