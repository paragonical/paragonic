--[[
MCP Sampling Approval System Demo
This script demonstrates the key features of the MCP Sampling Approval system
--]]

-- Set up Lua path to find paragonic modules
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

-- Check if running in Neovim
local is_neovim = pcall(function() return vim.version() end)

if not is_neovim then
	print("🎬 MCP Sampling Approval System Demo")
	print("=" .. string.rep("=", 60))
	print("")
	print("⚠️  This demo requires Neovim to run properly.")
	print("")
	print("💡 To see this in action:")
	print("")
	print("   1. Open Neovim:")
	print("      nvim")
	print("")
	print("   2. Source this file:")
	print("      :source demo_mcp_sampling_approval.lua")
	print("")
	print("   3. Run the demo:")
	print("      :lua run_demo()")
	print("")
	print("   4. Or run individual demos:")
	print("      :lua demo_basic_approval()")
	print("      :lua demo_batch_actions()")
	print("      :lua demo_decision_point()")
	print("      :lua demo_undo_redo()")
	print("")
	print("🔧 Available commands in Neovim:")
	print("   - :lua mcp.show_approval_status() -- Show current approvals")
	print("   - :lua mcp.cleanup_completed_approvals() -- Clean up completed requests")
	print("   - :lua mcp.get_undo_integration_status() -- Show undo status")
	print("")
	print("📋 Key Features to Watch For:")
	print("   - Approval dialogs appearing as floating windows")
	print("   - Interactive approval/denial with 'y'/'n' keys")
	print("   - Decision point dialogs with numbered options")
	print("   - Batch action dialogs with partial approval")
	print("   - Undo/redo integration with Neovim's undo tree")
	print("")
	print("🎯 Real-World Usage:")
	print("   - AI agents will automatically trigger approval dialogs")
	print("   - Users can approve, deny, or modify AI actions")
	print("   - All AI modifications are tracked in the undo tree")
	print("   - Granular undo/redo control for AI changes")
	print("")
	return
end

-- Load the MCP module (only if in Neovim)
local mcp = require("paragonic.mcp")

-- Demo configuration
local DEMO_CONFIG = {
	demo_file = "demo_output.lua",
	demo_content = {
		"-- MCP Sampling Approval Demo",
		"",
		"-- This file was created by the AI agent",
		"-- with user approval through the MCP system",
		"",
		"local function demo_function()",
		"    print('Hello from the demo!')",
		"end",
		"",
		"return demo_function"
	}
}

-- Initialize the system
function initialize_demo()
	print("🚀 Initializing MCP Sampling Approval Demo...")
	
	-- Initialize MCP server
	if mcp.initialize_mcp_server then
		mcp.initialize_mcp_server()
	end
	
	-- Initialize approval state
	if mcp.initialize_approval_state then
		mcp.initialize_approval_state()
	end
	
	-- Initialize undo integration
	local undo = require("paragonic.mcp_undo_integration")
	if undo.initialize then
		undo.initialize()
	end
	
	print("✅ System initialized successfully")
	print("")
end

-- Demo 1: Basic Tool Execution with Approval
function demo_basic_approval()
	print("📝 Demo 1: Basic Tool Execution with Approval")
	print("=" .. string.rep("=", 50))
	
	-- Create a simple approval request
	local request = {
		id = "demo-basic-" .. os.time(),
		type = "tool_execution",
		tool_name = "agent_edit_file",
		parameters = {
			file_path = DEMO_CONFIG.demo_file,
			line_number = 1,
			content = DEMO_CONFIG.demo_content[1]
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
			notes = "Demo approval"
		})
		print("✅ User approval handled: " .. tostring(approval_success))
		
		-- Close the dialog
		mcp.close_approval_dialog(dialog)
	end
	
	-- Execute the tool with undo integration
	local execution_success = mcp.execute_tool_with_undo_integration(
		request.tool_name, 
		request.parameters, 
		request.id
	)
	print("🔧 Tool executed: " .. tostring(execution_success))
	
	-- Check the approval status
	local approval = mcp.get_approval_request(request.id)
	print("📊 Approval status: " .. (approval.status or "unknown"))
	
	-- Check undo integration
	local undo_entry = mcp.get_ai_undo_entry(request.id)
	if undo_entry then
		print("↩️ Undo entry created for: " .. undo_entry.tool_name)
	end
	
	print("")
end

-- Demo 2: Batch Actions with Partial Approval
function demo_batch_actions()
	print("📦 Demo 2: Batch Actions with Partial Approval")
	print("=" .. string.rep("=", 50))
	
	-- Create a batch action request
	local batch_request = {
		id = "demo-batch-" .. os.time(),
		type = "batch_action",
		actions = {
			{
				type = "edit",
				file = DEMO_CONFIG.demo_file,
				tool_name = "agent_edit_file",
				line = 2,
				content = DEMO_CONFIG.demo_content[2]
			},
			{
				type = "edit",
				file = DEMO_CONFIG.demo_file,
				tool_name = "agent_edit_file",
				line = 3,
				content = DEMO_CONFIG.demo_content[3]
			},
			{
				type = "edit",
				file = DEMO_CONFIG.demo_file,
				tool_name = "agent_edit_file",
				line = 4,
				content = DEMO_CONFIG.demo_content[4]
			}
		},
		description = "Add multiple lines to demo file",
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
		
		-- Simulate partial approval (approve first 2 actions)
		print("👤 Simulating partial approval (first 2 actions)...")
		local partial_success = mcp.handle_partial_approval(dialog, {1, 2})
		print("✅ Partial approval handled: " .. tostring(partial_success))
		
		-- Close the dialog
		mcp.close_approval_dialog(dialog)
	end
	
	-- Execute batch with undo integration
	local execution_success = mcp.execute_batch_with_undo_integration(
		batch_request.actions,
		batch_request.id
	)
	print("🔧 Batch executed: " .. tostring(execution_success))
	
	print("")
end

-- Demo 3: Decision Point
function demo_decision_point()
	print("🤔 Demo 3: Decision Point")
	print("=" .. string.rep("=", 50))
	
	-- Create a decision point request
	local decision_request = {
		id = "demo-decision-" .. os.time(),
		type = "decision_point",
		question = "Which approach should be used for the demo?",
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

-- Demo 4: Undo/Redo Operations
function demo_undo_redo()
	print("↩️ Demo 4: Undo/Redo Operations")
	print("=" .. string.rep("=", 50))
	
	-- Create multiple modifications to demonstrate undo
	local modifications = {}
	for i = 1, 3 do
		local mod_id = "demo-undo-" .. i .. "-" .. os.time()
		mcp.register_approval_request({id = mod_id, type = "tool_execution"})
		
		local success = mcp.execute_tool_with_undo_integration("agent_edit_file", {
			file_path = DEMO_CONFIG.demo_file,
			line_number = 10 + i,
			content = "-- Modification " .. i
		}, mod_id)
		
		if success then
			table.insert(modifications, mod_id)
			print("📝 Created modification " .. i .. ": " .. mod_id)
		end
	end
	
	-- Demonstrate undo operations
	print("")
	print("🔄 Demonstrating undo operations...")
	
	-- Undo the last modification
	if #modifications > 0 then
		local undo_success = mcp.undo_ai_modification(modifications[#modifications])
		print("↩️ Undo last modification: " .. tostring(undo_success))
	end
	
	-- Redo the modification
	if #modifications > 0 then
		local redo_success = mcp.redo_ai_modification(modifications[#modifications])
		print("↪️ Redo last modification: " .. tostring(redo_success))
	end
	
	-- Show undo tree status
	local status = mcp.get_undo_integration_status()
	print("📊 Undo integration status: " .. tostring(status.active_entries) .. " active entries")
	
	print("")
end

-- Demo 5: Performance and Concurrent Operations
function demo_performance()
	print("⚡ Demo 5: Performance and Concurrent Operations")
	print("=" .. string.rep("=", 50))
	
	-- Create multiple concurrent requests
	local concurrent_requests = {}
	for i = 1, 5 do
		local request = {
			id = "demo-perf-" .. i .. "-" .. os.time(),
			type = "tool_execution",
			tool_name = "agent_edit_file",
			parameters = {
				file_path = "perf_test_" .. i .. ".lua",
				line_number = 1,
				content = "-- Performance test " .. i
			}
		}
		table.insert(concurrent_requests, request)
	end
	
	-- Register all requests
	local start_time = os.time()
	for _, request in ipairs(concurrent_requests) do
		mcp.register_approval_request(request)
	end
	local register_time = os.time() - start_time
	print("📋 Registered " .. #concurrent_requests .. " requests in " .. register_time .. "s")
	
	-- Execute all tools
	start_time = os.time()
	for _, request in ipairs(concurrent_requests) do
		mcp.execute_tool_with_approval(request.tool_name, request.parameters, request.id)
	end
	local execute_time = os.time() - start_time
	print("🔧 Executed " .. #concurrent_requests .. " tools in " .. execute_time .. "s")
	
	-- Approve all requests
	start_time = os.time()
	for _, request in ipairs(concurrent_requests) do
		mcp.approve_request(request.id, {approved = true})
	end
	local approve_time = os.time() - start_time
	print("✅ Approved " .. #concurrent_requests .. " requests in " .. approve_time .. "s")
	
	-- Show pending count
	local pending_count = mcp.get_pending_approval_count()
	print("📊 Pending approvals: " .. pending_count)
	
	print("")
end

-- Demo 6: Error Handling and Recovery
function demo_error_handling()
	print("🛡️ Demo 6: Error Handling and Recovery")
	print("=" .. string.rep("=", 50))
	
	-- Test invalid tool execution
	print("🧪 Testing invalid tool execution...")
	local invalid_success = mcp.execute_tool_with_approval("invalid_tool", {}, "invalid-test")
	print("❌ Invalid tool execution: " .. tostring(invalid_success))
	
	-- Test timeout handling
	print("⏱️ Testing timeout handling...")
	local timeout_request = {
		id = "timeout-test-" .. os.time(),
		type = "tool_execution",
		tool_name = "agent_edit_file",
		parameters = {file_path = "test.lua"},
		timeout = 1 -- 1 second timeout
	}
	
	mcp.register_approval_request(timeout_request)
	print("⏳ Waiting for timeout...")
	os.execute("sleep 2")
	
	local timeout_approval = mcp.get_approval_request(timeout_request.id)
	print("📊 Timeout status: " .. (timeout_approval.status or "unknown"))
	
	-- Test recovery from errors
	print("🔄 Testing error recovery...")
	local recovery_request = {
		id = "recovery-test-" .. os.time(),
		type = "tool_execution",
		tool_name = "agent_edit_file",
		parameters = {file_path = "recovery_test.lua"}
	}
	
	mcp.register_approval_request(recovery_request)
	local recovery_success = mcp.execute_tool_with_undo_integration(
		recovery_request.tool_name,
		recovery_request.parameters,
		recovery_request.id
	)
	print("✅ Recovery successful: " .. tostring(recovery_success))
	
	print("")
end

-- Show system status
function show_system_status()
	print("📊 System Status")
	print("=" .. string.rep("=", 50))
	
	-- Show approval state
	local pending_count = mcp.get_pending_approval_count()
	print("📋 Pending approvals: " .. pending_count)
	
	-- Show undo integration status
	local undo_status = mcp.get_undo_integration_status()
	print("↩️ AI undo entries: " .. tostring(undo_status.active_entries))
	
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
function run_demo()
	print("🎬 MCP Sampling Approval System Demo")
	print("=" .. string.rep("=", 60))
	print("")
	
	-- Initialize the system
	initialize_demo()
	
	-- Run all demos
	demo_basic_approval()
	demo_batch_actions()
	demo_decision_point()
	demo_undo_redo()
	demo_performance()
	demo_error_handling()
	
	-- Show final status
	show_system_status()
	
	print("🎉 Demo completed successfully!")
	print("")
	print("💡 To see this in Neovim:")
	print("   1. Open Neovim")
	print("   2. Source this file: :source demo_mcp_sampling_approval.lua")
	print("   3. Watch the approval dialogs appear and interact with them")
	print("")
	print("🔧 Available commands in Neovim:")
	print("   - :lua mcp.show_approval_status() -- Show current approvals")
	print("   - :lua mcp.cleanup_completed_approvals() -- Clean up completed requests")
	print("   - :lua mcp.get_undo_integration_status() -- Show undo status")
end

-- Export for use in Neovim
return {
	run_demo = run_demo,
	demo_basic_approval = demo_basic_approval,
	demo_batch_actions = demo_batch_actions,
	demo_decision_point = demo_decision_point,
	demo_undo_redo = demo_undo_redo,
	demo_performance = demo_performance,
	demo_error_handling = demo_error_handling,
	show_system_status = show_system_status
}
