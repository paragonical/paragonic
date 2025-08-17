--[[
Polished Chat Approval Demo
Showcases the non-interruptive chat-sigil approval system
--]]

-- Set up Lua path to find paragonic modules
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

-- Check if running in Neovim
local is_neovim = pcall(function() return vim.version() end)

if not is_neovim then
	print("🎬 Polished Chat Approval Demo")
	print("=" .. string.rep("=", 50))
	print("")
	print("⚠️  This demo requires Neovim to run properly.")
	print("")
	print("💡 To test the polished chat approval system:")
	print("   1. Open Neovim: nvim")
	print("   2. Source this file: :source demo_polished_chat_approval.lua")
	print("   3. Run: :lua test_polished_chat_approval()")
	print("")
	return
end

-- Load the MCP module
local mcp = require("paragonic.mcp")

-- Initialize the polished chat approval system
function initialize_polished_system()
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
	
	print("✅ Polished chat approval system initialized")
end

-- Create a realistic chat conversation with approval markers
function test_polished_chat_approval()
	print("💬 Polished Chat Approval System Demo")
	print("=" .. string.rep("=", 60))
	print("")
	print("🎯 This demo showcases the non-interruptive chat-sigil approval system.")
	print("   Approval requests appear as 󰭙 markers in the chat flow.")
	print("   Press Enter on any marker to process the approval.")
	print("")
	
	-- Initialize the system
	initialize_polished_system()
	
	-- Create a realistic chat buffer
	local buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_buf_set_name(buf, "polished_chat_demo")
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
	
	-- Add realistic chat content
	local lines = {
		"# AI Assistant Chat",
		"",
		"**User:** I need help setting up a Python web application with Flask.",
		"",
		"**AI Assistant:** I'll help you create a Flask web application! Let me set up the project structure and basic files for you.",
		"",
		"**AI Assistant:** First, I'll create the main application file with a basic Flask setup.",
		"",
		"-- Approval requests will appear below as the AI works --",
		""
	}
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	
	-- Open the buffer
	vim.api.nvim_command("edit polished_chat_demo")
	
	-- Set up chat buffer mappings
	if mcp.setup_chat_buffer_mappings then
		mcp.setup_chat_buffer_mappings()
	end
	
	-- Simulate AI working and creating approval requests
	local requests = {
		{
			id = "flask-main-" .. os.time(),
			type = "tool_execution",
			tool_name = "agent_edit_file",
			parameters = {
				file_path = "app.py",
				line_number = 1,
				content = "from flask import Flask, render_template\n\napp = Flask(__name__)\n\n@app.route('/')\ndef home():\n    return render_template('index.html')\n\nif __name__ == '__main__':\n    app.run(debug=True)"
			},
			description = "Create main Flask application file (app.py)",
			timeout = 300
		},
		{
			id = "flask-requirements-" .. os.time(),
			type = "tool_execution",
			tool_name = "agent_edit_file",
			parameters = {
				file_path = "requirements.txt",
				line_number = 1,
				content = "Flask==2.3.3\nWerkzeug==2.3.7\nJinja2==3.1.2"
			},
			description = "Create requirements.txt with Flask dependencies",
			timeout = 300
		},
		{
			id = "flask-decision-" .. os.time(),
			type = "decision_point",
			question = "Which database would you prefer for this Flask app?",
			options = {
				"SQLite (simple, built-in)",
				"PostgreSQL (production-ready)",
				"MySQL (popular choice)"
			},
			description = "Choose database for Flask application",
			timeout = 300
		},
		{
			id = "flask-batch-" .. os.time(),
			type = "batch_action",
			actions = {
				{
					type = "create",
					file = "templates/index.html",
					description = "Create main template file"
				},
				{
					type = "create",
					file = "static/css/style.css",
					description = "Create basic CSS styles"
				},
				{
					type = "create",
					file = "README.md",
					description = "Create project documentation"
				}
			},
			description = "Create templates, static files, and documentation",
			timeout = 300
		}
	}
	
	-- Register requests with delays to simulate real AI work
	for i, request in ipairs(requests) do
		-- Add a small delay to simulate AI thinking
		vim.defer_fn(function()
			local success = mcp.register_approval_request(request)
			if success then
				print("📋 Request " .. i .. " registered: " .. request.description)
			end
		end, i * 1000) -- 1 second delay between each request
	end
	
	print("")
	print("✅ Polished chat approval demo setup complete!")
	print("")
	print("🎯 What you'll see:")
	print("   1. 󰭙 markers appearing in the chat as AI works")
	print("   2. Each marker shows the action type and description")
	print("   3. Press Enter on any marker to process it")
	print("   4. Markers update status: 🔄 → ✅/❌/⏰")
	print("")
	print("💡 Try these interactions:")
	print("   • Press Enter on a marker to see approval options")
	print("   • Choose 'Details' to see full request information")
	print("   • Approve some requests and deny others")
	print("   • Watch how markers update their status")
	print("")
	print("🔄 Status indicators:")
	print("   🔄 = Pending approval")
	print("   ✅ = Approved")
	print("   ❌ = Denied")
	print("   ⏰ = Timed out")
end

-- Test individual marker interaction
function test_marker_interaction()
	print("🎯 Testing Individual Marker Interaction")
	print("=" .. string.rep("=", 50))
	print("")
	
	-- Initialize the system
	initialize_polished_system()
	
	-- Create a single approval request
	local request = {
		id = "interaction-test-" .. os.time(),
		type = "tool_execution",
		tool_name = "agent_edit_file",
		parameters = {
			file_path = "test_interaction.py",
			line_number = 1,
			content = "print('Testing marker interaction!')"
		},
		description = "Create test file for marker interaction",
		timeout = 300
	}
	
	-- Register the request
	local success = mcp.register_approval_request(request)
	print("📋 Interaction test request registered: " .. tostring(success))
	
	if success then
		print("🖥️ Look for the 󰭙 marker in the current buffer")
		print("   Move your cursor to the marker line")
		print("   Press Enter to interact with the approval")
		print("   Try all the options: Approve, Deny, Details, Cancel")
	end
end

-- Show system status
function show_system_status()
	print("📊 Polished Chat Approval System Status")
	print("=" .. string.rep("=", 50))
	
	-- Initialize if needed
	initialize_polished_system()
	
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
	
	-- Show system info
	print("")
	print("🔧 System Information:")
	print("  • Chat-sigil system: Active")
	print("  • Non-interruptive UI: Enabled")
	print("  • Enter key integration: Active")
	print("  • Visual status updates: Enabled")
end

-- Clean up demo
function cleanup_demo()
	print("🧹 Cleaning up demo...")
	
	-- Get all pending approvals
	local pending_approvals = mcp.get_pending_approvals()
	
	-- Remove all approval markers
	for _, approval in ipairs(pending_approvals) do
		mcp.remove_approval_marker(approval.id)
	end
	
	print("✅ Demo cleanup complete")
end

-- Export for use in Neovim
return {
	test_polished_chat_approval = test_polished_chat_approval,
	test_marker_interaction = test_marker_interaction,
	show_system_status = show_system_status,
	cleanup_demo = cleanup_demo
}
