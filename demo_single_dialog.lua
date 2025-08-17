--[[
Single Dialog MCP Sampling Approval Demo
This demo creates just one approval dialog for easy testing
--]]

-- Set up Lua path to find paragonic modules
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

-- Check if running in Neovim
local is_neovim = pcall(function() return vim.version() end)

if not is_neovim then
	print("🎬 Single Dialog MCP Sampling Approval Demo")
	print("=" .. string.rep("=", 50))
	print("")
	print("⚠️  This demo requires Neovim to run properly.")
	print("")
	print("💡 To see this in action:")
	print("   1. Open Neovim: nvim")
	print("   2. Source this file: :source demo_single_dialog.lua")
	print("   3. Run a single demo:")
	print("      :lua show_approval_dialog()")
	print("      :lua show_decision_dialog()")
	print("      :lua show_batch_dialog()")
	print("")
	return
end

-- Load the MCP module
local mcp = require("paragonic.mcp")

-- Initialize the system
function initialize_single_demo()
	-- Initialize MCP server
	if mcp.initialize_mcp_server then
		mcp.initialize_mcp_server()
	end
	
	-- Initialize approval state
	if mcp.initialize_approval_state then
		mcp.initialize_approval_state()
	end
	
	print("✅ System initialized")
end

-- Show a single approval dialog
function show_approval_dialog()
	print("📝 Showing Approval Dialog")
	print("=" .. string.rep("=", 30))
	
	-- Initialize if needed
	initialize_single_demo()
	
	-- Create a simple approval request
	local request = {
		id = "single-approval-" .. os.time(),
		type = "tool_execution",
		tool_name = "agent_edit_file",
		parameters = {
			file_path = "test.lua",
			line_number = 5,
			content = "local result = process_data()"
		},
		timeout = 300, -- 5 minutes
		impact = "Will add a function call to line 5"
	}
	
	-- Register the approval request
	local register_success = mcp.register_approval_request(request)
	print("📋 Request registered: " .. tostring(register_success))
	
	-- Create and display approval dialog
	local dialog = mcp.create_approval_dialog(request.id)
	if dialog then
		print("🖥️ Approval dialog displayed")
		print("   Use 'y' to approve, 'n' to deny, or 'q' to quit")
		mcp.display_approval_dialog(dialog)
	else
		print("❌ Failed to create approval dialog")
	end
end

-- Show a single decision point dialog
function show_decision_dialog()
	print("🤔 Showing Decision Point Dialog")
	print("=" .. string.rep("=", 30))
	
	-- Initialize if needed
	initialize_single_demo()
	
	-- Create a decision point request
	local decision_request = {
		id = "single-decision-" .. os.time(),
		type = "decision_point",
		question = "How should we handle this error?",
		options = {
			"Option 1: Log and continue",
			"Option 2: Retry with backoff", 
			"Option 3: Fail fast and report"
		},
		timeout = 300 -- 5 minutes
	}
	
	-- Register decision request
	local register_success = mcp.register_approval_request(decision_request)
	print("📋 Decision request registered: " .. tostring(register_success))
	
	-- Create decision point dialog
	local dialog = mcp.create_decision_point_dialog(decision_request.id)
	if dialog then
		print("🖥️ Decision point dialog displayed")
		print("   Use '1', '2', '3' to select, or 'q' to quit")
		mcp.display_approval_dialog(dialog)
	else
		print("❌ Failed to create decision point dialog")
	end
end

-- Show a single batch action dialog
function show_batch_dialog()
	print("📦 Showing Batch Action Dialog")
	print("=" .. string.rep("=", 30))
	
	-- Initialize if needed
	initialize_single_demo()
	
	-- Create a batch action request
	local batch_request = {
		id = "single-batch-" .. os.time(),
		type = "batch_action",
		actions = {
			{
				type = "edit",
				file = "app.js",
				tool_name = "agent_edit_file",
				line = 1,
				content = "// Application entry point"
			},
			{
				type = "edit",
				file = "styles.css",
				tool_name = "agent_edit_file",
				line = 1,
				content = "/* Main stylesheet */"
			}
		},
		description = "Initialize web application files",
		timeout = 300 -- 5 minutes
	}
	
	-- Register batch request
	local register_success = mcp.register_approval_request(batch_request)
	print("📋 Batch request registered: " .. tostring(register_success))
	
	-- Create batch action dialog
	local dialog = mcp.create_batch_action_dialog(batch_request.id)
	if dialog then
		print("🖥️ Batch action dialog displayed")
		print("   Use 'y' for all, 'n' for none, 'p' for partial, or 'q' to quit")
		mcp.display_approval_dialog(dialog)
	else
		print("❌ Failed to create batch action dialog")
	end
end

-- Show system status
function show_status()
	print("📊 System Status")
	print("=" .. string.rep("=", 30))
	
	-- Initialize if needed
	initialize_single_demo()
	
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
end

-- Export for use in Neovim
return {
	show_approval_dialog = show_approval_dialog,
	show_decision_dialog = show_decision_dialog,
	show_batch_dialog = show_batch_dialog,
	show_status = show_status
}
