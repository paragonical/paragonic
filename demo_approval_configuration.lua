--[[
Demo: Approval Configuration System
Proof of concept showing auto-approval patterns and YOLO mode
--]]

-- Check if running in Neovim
local is_neovim = pcall(function() return vim.api.nvim_get_current_buf() end)

if not is_neovim then
	print("❌ This demo must be run inside Neovim")
	print("   Please open Neovim and run: :lua dofile('demo_approval_configuration.lua')")
	os.exit(1)
end

-- Demo configuration
local DEMO_CONFIG = {
	demo_buffer_name = "*Approval Configuration Demo*",
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

-- Test approval configuration system
local function test_approval_configuration()
	print("🚀 Starting Approval Configuration Demo")
	print("")
	
	-- Initialize MCP system
	local mcp = require("paragonic.mcp")
	if mcp.initialize_mcp_server then
		mcp.initialize_mcp_server()
	end
	
	-- Initialize approval configuration
	local approval_config = require("paragonic.approval_config")
	
	-- Clear buffer
	clear_buffer()
	
	-- Add demo header
	add_text("# Approval Configuration System Demo")
	add_text("")
	add_text("This demo showcases the auto-approval patterns and YOLO mode configuration.")
	add_text("")
	
	delay(DEMO_CONFIG.delay)
	
	-- Demo 1: Show current configuration
	add_text("## Demo 1: Current Configuration Status")
	add_text("")
	add_text("**Current Auto-Approval Settings:**")
	add_text("")
	
	local config = approval_config.get_config()
	add_text("• YOLO Mode: " .. (config.yolo_mode and "🟢 ENABLED" or "🔴 DISABLED"))
	add_text("• Auto-Approval: " .. (config.auto_approval.enabled and "🟢 ENABLED" or "🔴 DISABLED"))
	add_text("• Auto-Approved Tools: " .. #config.auto_approval.patterns.tools)
	add_text("• Auto-Approved Directories: " .. #config.auto_approval.patterns.file_operations.create_in_dirs)
	add_text("• Auto-Approved Extensions: " .. #config.auto_approval.patterns.file_operations.create_extensions)
	add_text("")
	
	delay(DEMO_CONFIG.delay)
	
	-- Demo 2: Test auto-approval patterns
	add_text("## Demo 2: Auto-Approval Pattern Testing")
	add_text("")
	add_text("**Testing different tool scenarios:**")
	add_text("")
	
	-- Test 1: Auto-approved tool
	add_text("**Test 1: agent_session_info (should be auto-approved)**")
	local should_approve, reason = approval_config.should_auto_approve_tool("agent_session_info", {})
	add_text("Result: " .. (should_approve and "✅ AUTO-APPROVED" or "❌ REQUIRES APPROVAL"))
	add_text("Reason: " .. reason)
	add_text("")
	
	-- Test 2: File creation in temp directory
	add_text("**Test 2: Create file in temp/ (should be auto-approved)**")
	local should_approve2, reason2 = approval_config.should_auto_approve_tool("agent_create_file", {
		file_name = "temp/test.log"
	})
	add_text("Result: " .. (should_approve2 and "✅ AUTO-APPROVED" or "❌ REQUIRES APPROVAL"))
	add_text("Reason: " .. reason2)
	add_text("")
	
	-- Test 3: File creation with .tmp extension
	add_text("**Test 3: Create file with .tmp extension (should be auto-approved)**")
	local should_approve3, reason3 = approval_config.should_auto_approve_tool("agent_create_file", {
		file_name = "data.tmp"
	})
	add_text("Result: " .. (should_approve3 and "✅ AUTO-APPROVED" or "❌ REQUIRES APPROVAL"))
	add_text("Reason: " .. reason3)
	add_text("")
	
	-- Test 4: File creation in project root (should require approval)
	add_text("**Test 4: Create file in project root (should require approval)**")
	local should_approve4, reason4 = approval_config.should_auto_approve_tool("agent_create_file", {
		file_name = "main.py"
	})
	add_text("Result: " .. (should_approve4 and "✅ AUTO-APPROVED" or "❌ REQUIRES APPROVAL"))
	add_text("Reason: " .. reason4)
	add_text("")
	
	-- Test 5: Small content (should be auto-approved)
	add_text("**Test 5: Small content (should be auto-approved)**")
	local should_approve5, reason5 = approval_config.should_auto_approve_tool("agent_create_file", {
		file_name = "comment.txt",
		content = "-- This is a comment"
	})
	add_text("Result: " .. (should_approve5 and "✅ AUTO-APPROVED" or "❌ REQUIRES APPROVAL"))
	add_text("Reason: " .. reason5)
	add_text("")
	
	delay(DEMO_CONFIG.delay * 2)
	
	-- Demo 3: YOLO Mode
	add_text("## Demo 3: YOLO Mode")
	add_text("")
	add_text("**YOLO Mode bypasses ALL approval checks!**")
	add_text("")
	add_text("**Current Status:** " .. (config.yolo_mode and "🟢 YOLO MODE ACTIVE" or "🔴 NORMAL MODE"))
	add_text("")
	
	-- Test YOLO mode
	add_text("**Testing YOLO Mode:**")
	add_text("")
	
	-- Enable YOLO mode
	add_text("**Step 1: Enabling YOLO Mode...**")
	approval_config.enable_yolo_mode()
	add_text("✅ YOLO Mode enabled")
	add_text("")
	
	-- Test tool with YOLO mode
	add_text("**Step 2: Testing tool with YOLO mode...**")
	local should_approve_yolo, reason_yolo = approval_config.should_auto_approve_tool("agent_create_file", {
		file_name = "dangerous_file.py",
		content = "import os; os.system('rm -rf /')" -- Dangerous content
	})
	add_text("Result: " .. (should_approve_yolo and "✅ AUTO-APPROVED" or "❌ REQUIRES APPROVAL"))
	add_text("Reason: " .. reason_yolo)
	add_text("⚠️ WARNING: This would be auto-approved in YOLO mode!")
	add_text("")
	
	-- Disable YOLO mode
	add_text("**Step 3: Disabling YOLO Mode...**")
	approval_config.disable_yolo_mode()
	add_text("✅ YOLO Mode disabled")
	add_text("")
	
	-- Test same tool without YOLO mode
	add_text("**Step 4: Testing same tool without YOLO mode...**")
	local should_approve_normal, reason_normal = approval_config.should_auto_approve_tool("agent_create_file", {
		file_name = "dangerous_file.py",
		content = "import os; os.system('rm -rf /')"
	})
	add_text("Result: " .. (should_approve_normal and "✅ AUTO-APPROVED" or "❌ REQUIRES APPROVAL"))
	add_text("Reason: " .. reason_normal)
	add_text("✅ Safety restored - requires approval")
	add_text("")
	
	delay(DEMO_CONFIG.delay * 2)
	
	-- Demo 4: Dynamic Configuration
	add_text("## Demo 4: Dynamic Configuration")
	add_text("")
	add_text("**Adding and removing auto-approval patterns:**")
	add_text("")
	
	-- Add a new tool to auto-approval
	add_text("**Step 1: Adding agent_edit_file to auto-approval...**")
	local success1, message1 = approval_config.add_auto_approval_tool("agent_edit_file")
	add_text("Result: " .. (success1 and "✅ SUCCESS" or "❌ FAILED"))
	add_text("Message: " .. message1)
	add_text("")
	
	-- Test the newly added tool
	add_text("**Step 2: Testing newly added tool...**")
	local should_approve_new, reason_new = approval_config.should_auto_approve_tool("agent_edit_file", {
		file_path = "main.py",
		line_number = 1,
		content = "print('Hello World')"
	})
	add_text("Result: " .. (should_approve_new and "✅ AUTO-APPROVED" or "❌ REQUIRES APPROVAL"))
	add_text("Reason: " .. reason_new)
	add_text("")
	
	-- Add a new directory to auto-approval
	add_text("**Step 3: Adding 'demo/' directory to auto-approval...**")
	local success2, message2 = approval_config.add_auto_approval_directory("demo/")
	add_text("Result: " .. (success2 and "✅ SUCCESS" or "❌ FAILED"))
	add_text("Message: " .. message2)
	add_text("")
	
	-- Test file creation in new directory
	add_text("**Step 4: Testing file creation in new directory...**")
	local should_approve_dir, reason_dir = approval_config.should_auto_approve_tool("agent_create_file", {
		file_name = "demo/test_file.txt"
	})
	add_text("Result: " .. (should_approve_dir and "✅ AUTO-APPROVED" or "❌ REQUIRES APPROVAL"))
	add_text("Reason: " .. reason_dir)
	add_text("")
	
	-- Remove the tool from auto-approval
	add_text("**Step 5: Removing agent_edit_file from auto-approval...**")
	local success3, message3 = approval_config.remove_auto_approval_tool("agent_edit_file")
	add_text("Result: " .. (success3 and "✅ SUCCESS" or "❌ FAILED"))
	add_text("Message: " .. message3)
	add_text("")
	
	-- Test the removed tool
	add_text("**Step 6: Testing removed tool...**")
	local should_approve_removed, reason_removed = approval_config.should_auto_approve_tool("agent_edit_file", {
		file_path = "main.py",
		line_number = 1,
		content = "print('Hello World')"
	})
	add_text("Result: " .. (should_approve_removed and "✅ AUTO-APPROVED" or "❌ REQUIRES APPROVAL"))
	add_text("Reason: " .. reason_removed)
	add_text("")
	
	delay(DEMO_CONFIG.delay * 2)
	
	-- Demo 5: Time-based and Session-based patterns
	add_text("## Demo 5: Advanced Auto-Approval Patterns")
	add_text("")
	add_text("**Time-based and Session-based auto-approval:**")
	add_text("")
	
	-- Test time-based auto-approval
	add_text("**Time-based Auto-Approval:**")
	local time_should_approve, time_reason = approval_config.should_auto_approve_by_time()
	add_text("Result: " .. (time_should_approve and "✅ ALLOWED" or "❌ NOT ALLOWED"))
	add_text("Reason: " .. time_reason)
	add_text("")
	
	-- Test session-based auto-approval
	add_text("**Session-based Auto-Approval:**")
	local session_should_approve, session_reason = approval_config.should_auto_approve_by_session(3, 0.5)
	add_text("Result: " .. (session_should_approve and "✅ ALLOWED" or "❌ NOT ALLOWED"))
	add_text("Reason: " .. session_reason)
	add_text("(Testing with 3 approvals, 0.5 similarity)")
	add_text("")
	
	delay(DEMO_CONFIG.delay)
	
	-- Show configuration benefits
	add_text("## Configuration Benefits")
	add_text("")
	add_text("✅ **Flexible Patterns:** Multiple ways to configure auto-approval")
	add_text("✅ **YOLO Mode:** Complete bypass for power users")
	add_text("✅ **Dynamic Configuration:** Add/remove patterns at runtime")
	add_text("✅ **Safety Controls:** Time-based and session-based limits")
	add_text("✅ **Granular Control:** Tool, directory, extension, and content patterns")
	add_text("✅ **Persistence:** Save and load configurations")
	add_text("✅ **Visual Status:** Easy-to-read configuration display")
	add_text("")
	
	-- Show commands
	add_text("## Commands")
	add_text("")
	add_text("**YOLO Mode:**")
	add_text(":lua require('paragonic.mcp').toggle_yolo_mode()")
	add_text(":lua require('paragonic.mcp').enable_yolo_mode()")
	add_text(":lua require('paragonic.mcp').disable_yolo_mode()")
	add_text("")
	add_text("**Configuration Management:**")
	add_text(":lua require('paragonic.mcp').show_approval_config()")
	add_text(":lua require('paragonic.mcp').add_auto_approval_tool('tool_name')")
	add_text(":lua require('paragonic.mcp').add_auto_approval_directory('dir/')")
	add_text(":lua require('paragonic.mcp').add_auto_approval_extension('.ext')")
	add_text("")
	add_text("**Persistence:**")
	add_text(":lua require('paragonic.mcp').save_approval_config()")
	add_text(":lua require('paragonic.mcp').load_approval_config()")
	add_text("")
	
	add_text("## Demo Notes")
	add_text("")
	add_text("• YOLO mode bypasses ALL safety checks")
	add_text("• Auto-approval patterns are checked in order")
	add_text("• Configuration changes take effect immediately")
	add_text("• Settings can be saved and restored")
	add_text("• Use YOLO mode with extreme caution!")
	add_text("")
	add_text("🎉 Approval Configuration system is working! 🎉")
	
	print("✅ Approval Configuration demo completed!")
	print("")
	print("💡 Try the commands shown above to configure auto-approval")
	print("💡 Use YOLO mode carefully - it bypasses all safety checks")
	print("💡 Check the configuration status with show_approval_config()")
end

-- Run the demo
test_approval_configuration()
