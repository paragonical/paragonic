--[[
Emoji Indicators Demo
Test the new emoji indicators (🆗/⛔) with timestamps
--]]

-- Set up Lua path to find paragonic modules
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

-- Check if running in Neovim
local is_neovim = pcall(function() return vim.version() end)

if not is_neovim then
	print("🎬 Emoji Indicators Demo")
	print("=" .. string.rep("=", 40))
	print("")
	print("⚠️  This demo requires Neovim to run properly.")
	print("")
	print("💡 To test the new emoji indicators:")
	print("   1. Open Neovim: nvim")
	print("   2. Source this file: :source demo_emoji_indicators.lua")
	print("   3. Run: :lua test_emoji_indicators()")
	print("")
	return
end

-- Load the MCP module
local mcp = require("paragonic.mcp")

-- Initialize the system
function initialize_emoji_demo()
	-- Initialize MCP server
	if mcp.initialize_mcp_server then
		mcp.initialize_mcp_server()
	end
	
	-- Initialize approval state
	if mcp.initialize_approval_state then
		mcp.initialize_approval_state()
	end
	
	-- Initialize chat-based approval UI
	if mcp.initialize_chat_approval then
		mcp.initialize_chat_approval()
	end
	
	print("✅ Emoji indicators demo initialized")
end

-- Test the new emoji indicators
function test_emoji_indicators()
	print("🎯 Testing New Emoji Indicators")
	print("=" .. string.rep("=", 50))
	print("")
	print("🆗 = Approved (Squared OK)")
	print("⛔ = Denied (No Entry)")
	print("")
	print("Both include timestamps and can be ignored when completed.")
	print("")
	
	-- Initialize the system
	initialize_emoji_demo()
	
	-- Create a test buffer
	local buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_buf_set_name(buf, "emoji_test")
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
	
	-- Add test content
	local lines = {
		"# Emoji Indicators Test",
		"",
		"Testing the new approval status indicators:",
		"",
		"-- Test requests will appear below --",
		""
	}
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	
	-- Open the buffer
	vim.api.nvim_command("edit emoji_test")
	
	-- Set up chat buffer mappings
	if mcp.setup_chat_buffer_mappings then
		mcp.setup_chat_buffer_mappings()
	end
	
	-- Create test requests
	local requests = {
		{
			id = "emoji-approve-" .. os.time(),
			type = "tool_execution",
			tool_name = "agent_edit_file",
			parameters = {
				file_path = "test_approve.txt",
				line_number = 1,
				content = "This will be approved"
			},
			description = "Test approval with 🆗 indicator",
			timeout = 300
		},
		{
			id = "emoji-deny-" .. os.time(),
			type = "tool_execution",
			tool_name = "agent_edit_file",
			parameters = {
				file_path = "test_deny.txt",
				line_number = 1,
				content = "This will be denied"
			},
			description = "Test denial with ⛔ indicator",
			timeout = 300
		},
		{
			id = "emoji-decision-" .. os.time(),
			type = "decision_point",
			question = "Test decision point?",
			options = {
				"Yes",
				"No"
			},
			description = "Test decision point with emoji indicators",
			timeout = 300
		}
	}
	
	-- Register requests
	for i, request in ipairs(requests) do
		local success = mcp.register_approval_request(request)
		print("📋 Request " .. i .. " registered: " .. tostring(success))
	end
	
	print("")
	print("✅ Emoji indicators test setup complete!")
	print("")
	print("🎯 What to test:")
	print("   1. Look for the 󰭙 🔄 markers")
	print("   2. Press Enter on a marker to process it")
	print("   3. Choose Approve to see 🆗 with timestamp")
	print("   4. Choose Deny to see ⛔ with timestamp")
	print("   5. Press Enter on completed markers to see details")
	print("")
	print("💡 The completed markers (🆗/⛔) can be ignored - they show completion status.")
end

-- Test completed marker interaction
function test_completed_markers()
	print("🎯 Testing Completed Marker Interaction")
	print("=" .. string.rep("=", 50))
	print("")
	
	-- Initialize the system
	initialize_emoji_demo()
	
	-- Create a request and immediately approve it
	local request = {
		id = "completed-test-" .. os.time(),
		type = "tool_execution",
		tool_name = "agent_edit_file",
		parameters = {
			file_path = "completed_test.txt",
			line_number = 1,
			content = "This is a completed test"
		},
		description = "Test completed marker interaction",
		timeout = 300
	}
	
	-- Register and immediately approve
	local success = mcp.register_approval_request(request)
	if success then
		-- Wait a moment for the marker to appear
		vim.defer_fn(function()
			-- Approve the request
			mcp.approve_request(request.id, {approved = true})
			print("✅ Request approved - look for 🆗 marker")
			print("   Press Enter on the 🆗 marker to see completion details")
		end, 1000)
	end
end

-- Show emoji indicator status
function show_emoji_status()
	print("📊 Emoji Indicators Status")
	print("=" .. string.rep("=", 40))
	
	-- Initialize if needed
	initialize_emoji_demo()
	
	-- Show pending approvals
	local pending_count = mcp.get_pending_approval_count()
	print("📋 Pending approvals: " .. pending_count)
	
	-- Show all pending approvals
	local pending_approvals = mcp.get_pending_approvals()
	if #pending_approvals > 0 then
		print("")
		print("📋 Pending Approval Details:")
		for i, approval in ipairs(pending_approvals) do
			print("  " .. i .. ". " .. approval.description .. " (" .. approval.request_type .. ")")
		end
	end
	
	-- Show emoji indicator info
	print("")
	print("🎯 Emoji Indicator Information:")
	print("  • 🆗 (Squared OK) = Approved with timestamp")
	print("  • ⛔ (No Entry) = Denied with timestamp")
	print("  • Both can be ignored when completed")
	print("  • Press Enter on completed markers for details")
end

-- Export for use in Neovim
return {
	test_emoji_indicators = test_emoji_indicators,
	test_completed_markers = test_completed_markers,
	show_emoji_status = show_emoji_status
}
