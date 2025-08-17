--[[
Contextual Approval Demo
Showcases cursor-based approval/rejection in chat buffers
--]]

-- Set up Lua path to find paragonic modules
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

-- Check if running in Neovim
local is_neovim = pcall(function() return vim.version() end)

if not is_neovim then
	print("🎬 Contextual Approval Demo")
	print("=" .. string.rep("=", 50))
	print("")
	print("⚠️  This demo requires Neovim to run properly.")
	print("")
	print("💡 To test contextual approval:")
	print("   1. Open Neovim: nvim")
	print("   2. Source this file: :source demo_contextual_approval.lua")
	print("   3. Run: :lua test_contextual_approval()")
	print("")
	return
end

-- Load the MCP module
local mcp = require("paragonic.mcp")

-- Initialize the contextual approval system
function initialize_contextual_demo()
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
	
	print("✅ Contextual approval system initialized")
end

-- Test contextual approval features
function test_contextual_approval()
	print("🎯 Testing Contextual Approval/Rejection")
	print("=" .. string.rep("=", 60))
	print("")
	print("This demo showcases cursor-based approval actions in chat buffers.")
	print("")
	
	-- Initialize the system
	initialize_contextual_demo()
	
	-- Create a test buffer
	local buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_buf_set_name(buf, "contextual_approval_test")
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
	
	-- Add test content
	local lines = {
		"# Contextual Approval Test",
		"",
		"AI: I'll help you set up a development environment.",
		"",
		"AI: Let me create the necessary configuration files.",
		"",
		"-- Approval markers will appear below --",
		"",
		"User: Can you also set up the testing framework?",
		"",
		"AI: Of course! I'll configure the testing setup as well.",
		""
	}
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	
	-- Open the buffer
	vim.api.nvim_command("edit contextual_approval_test")
	
	-- Set up contextual mappings
	if mcp.setup_chat_buffer_mappings then
		mcp.setup_chat_buffer_mappings()
	end
	
	-- Create test requests
	local requests = {
		{
			id = "context-config-" .. os.time(),
			type = "tool_execution",
			tool_name = "agent_edit_file",
			parameters = {
				file_path = "config.json",
				line_number = 1,
				content = '{"debug": true, "port": 3000}'
			},
			description = "Create development configuration file",
			timeout = 300
		},
		{
			id = "context-env-" .. os.time(),
			type = "tool_execution",
			tool_name = "agent_edit_file",
			parameters = {
				file_path = ".env",
				line_number = 1,
				content = "NODE_ENV=development\nDEBUG=true"
			},
			description = "Create environment variables file",
			timeout = 300
		},
		{
			id = "context-test-" .. os.time(),
			type = "tool_execution",
			tool_name = "agent_edit_file",
			parameters = {
				file_path = "test-setup.js",
				line_number = 1,
				content = "const jest = require('jest');\nmodule.exports = { testEnvironment: 'node' };"
			},
			description = "Create testing framework configuration",
			timeout = 300
		},
		{
			id = "context-decision-" .. os.time(),
			type = "decision_point",
			question = "Which package manager should we use?",
			options = {
				"npm (default)",
				"yarn (faster)",
				"pnpm (space efficient)"
			},
			description = "Choose package manager for the project",
			timeout = 300
		}
	}
	
	-- Register requests
	for i, request in ipairs(requests) do
		local success = mcp.register_approval_request(request)
		print("📋 Request " .. i .. " registered: " .. tostring(success))
	end
	
	print("")
	print("✅ Contextual approval test setup complete!")
	print("")
	print("🎯 Available Actions (when cursor is on a marker line):")
	print("")
	print("📝 Quick Actions:")
	print("   ya = Quick approve (yes-approve)")
	print("   nd = Quick deny (no-deny)")
	print("   gd = Show details (get-details)")
	print("   <CR> = Show options menu")
	print("")
	print("🎛️ Context Menu:")
	print("   <C-m> = Show context menu")
	print("")
	print("📦 Visual Mode (select multiple markers):")
	print("   ya = Approve all selected")
	print("   nd = Deny all selected")
	print("")
	print("💡 Try these workflows:")
	print("   1. Move cursor to a marker line")
	print("   2. Press 'ya' to quickly approve")
	print("   3. Press 'nd' to quickly deny")
	print("   4. Press '<C-m>' for context menu")
	print("   5. Use visual mode to select multiple markers")
	print("   6. Press 'ya' in visual mode to approve all")
end

-- Test quick actions
function test_quick_actions()
	print("⚡ Testing Quick Actions")
	print("=" .. string.rep("=", 40))
	print("")
	
	-- Initialize the system
	initialize_contextual_demo()
	
	-- Create a single request for testing
	local request = {
		id = "quick-test-" .. os.time(),
		type = "tool_execution",
		tool_name = "agent_edit_file",
		parameters = {
			file_path = "quick_test.txt",
			line_number = 1,
			content = "Testing quick actions"
		},
		description = "Test quick approval/denial actions",
		timeout = 300
	}
	
	-- Register the request
	local success = mcp.register_approval_request(request)
	print("📋 Quick test request registered: " .. tostring(success))
	
	if success then
		print("")
		print("🎯 Quick Action Test:")
		print("   1. Move cursor to the marker line")
		print("   2. Press 'ya' to quickly approve")
		print("   3. Press 'nd' to quickly deny")
		print("   4. Press 'gd' to show details")
		print("   5. Press '<C-m>' for context menu")
	end
end

-- Test visual mode batch operations
function test_visual_batch()
	print("📦 Testing Visual Mode Batch Operations")
	print("=" .. string.rep("=", 50))
	print("")
	
	-- Initialize the system
	initialize_contextual_demo()
	
	-- Create multiple requests for batch testing
	local requests = {
		{
			id = "batch-1-" .. os.time(),
			type = "tool_execution",
			tool_name = "agent_edit_file",
			parameters = {file_path = "batch1.txt", line_number = 1, content = "Batch 1"},
			description = "First batch test file",
			timeout = 300
		},
		{
			id = "batch-2-" .. os.time(),
			type = "tool_execution",
			tool_name = "agent_edit_file",
			parameters = {file_path = "batch2.txt", line_number = 1, content = "Batch 2"},
			description = "Second batch test file",
			timeout = 300
		},
		{
			id = "batch-3-" .. os.time(),
			type = "tool_execution",
			tool_name = "agent_edit_file",
			parameters = {file_path = "batch3.txt", line_number = 1, content = "Batch 3"},
			description = "Third batch test file",
			timeout = 300
		}
	}
	
	-- Register requests
	for i, request in ipairs(requests) do
		local success = mcp.register_approval_request(request)
		print("📋 Batch request " .. i .. " registered: " .. tostring(success))
	end
	
	print("")
	print("🎯 Visual Mode Batch Test:")
	print("   1. Use 'V' to enter visual line mode")
	print("   2. Select multiple marker lines")
	print("   3. Press 'ya' to approve all selected")
	print("   4. Or press 'nd' to deny all selected")
	print("")
	print("💡 This is useful for bulk approval/denial operations!")
end

-- Show contextual approval status
function show_contextual_status()
	print("📊 Contextual Approval System Status")
	print("=" .. string.rep("=", 50))
	
	-- Initialize if needed
	initialize_contextual_demo()
	
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
	
	-- Show contextual action info
	print("")
	print("🎯 Contextual Action Information:")
	print("  • ya = Quick approve marker under cursor")
	print("  • nd = Quick deny marker under cursor")
	print("  • gd = Show details for marker under cursor")
	print("  • <C-m> = Show context menu")
	print("  • Visual mode: ya/nd for batch operations")
	print("  • <CR> = Show options menu (existing behavior)")
end

-- Export for use in Neovim
return {
	test_contextual_approval = test_contextual_approval,
	test_quick_actions = test_quick_actions,
	test_visual_batch = test_visual_batch,
	show_contextual_status = show_contextual_status
}
