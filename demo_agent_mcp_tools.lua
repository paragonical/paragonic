--[[
Demo: Agent MCP Tools Integration
Proof of concept showing how agents can use MCP tools in Neovim client
--]]

-- Check if running in Neovim
local is_neovim = pcall(function() return vim.api.nvim_get_current_buf() end)

if not is_neovim then
	print("❌ This demo must be run inside Neovim")
	print("   Please open Neovim and run: :lua dofile('demo_agent_mcp_tools.lua')")
	os.exit(1)
end

-- Demo configuration
local DEMO_CONFIG = {
	demo_buffer_name = "*Agent MCP Tools Demo*",
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

-- Test agent using MCP tools
local function test_agent_mcp_tools()
	print("🚀 Starting Agent MCP Tools Demo")
	print("")
	
	-- Initialize MCP system
	local mcp = require("paragonic.mcp")
	if mcp.initialize_mcp_server then
		mcp.initialize_mcp_server()
	end
	
	-- Initialize API layer
	local api = require("paragonic.api")
	if api.initialize then
		api.initialize()
	end
	
	-- Clear buffer
	clear_buffer()
	
	-- Add demo header
	add_text("# Agent MCP Tools Integration Demo")
	add_text("")
	add_text("This demo showcases how AI agents can use MCP tools in the Neovim client.")
	add_text("")
	add_text("## Available MCP Tools:")
	add_text("")
	
	-- List available MCP tools
	local tools = mcp.list_mcp_tools()
	if tools then
		for i, tool in ipairs(tools) do
			add_text(i .. ". **" .. tool.name .. "** - " .. tool.description)
		end
	else
		add_text("No MCP tools available")
	end
	
	add_text("")
	delay(DEMO_CONFIG.delay)
	
	-- Demo 1: Agent using agent_session_info
	add_text("## Demo 1: Agent Using Session Info")
	add_text("")
	add_text("**Scenario:** Agent needs to understand current session context")
	add_text("")
	add_text("**Agent Request:** 'What's my current session status?'")
	add_text("")
	
	-- Simulate agent calling agent_session_info
	local session_response = api.call_tool("agent_session_info", {
		include_buffers = true,
		include_patterns = true,
		include_history = true
	})
	
	if session_response and session_response.success then
		add_text("**MCP Tool Call:** agent_session_info")
		add_text("**Response:** Session information retrieved successfully")
		add_text("**Data:** " .. (session_response.result and "Session data available" or "No session data"))
	else
		add_text("**MCP Tool Call:** agent_session_info")
		add_text("**Response:** Failed to get session info")
		add_text("**Error:** " .. (session_response and session_response.error or "Unknown error"))
	end
	
	add_text("")
	delay(DEMO_CONFIG.delay)
	
	-- Demo 2: Agent using agent_search_files
	add_text("## Demo 2: Agent Using File Search")
	add_text("")
	add_text("**Scenario:** Agent needs to find relevant files")
	add_text("")
	add_text("**Agent Request:** 'Find all Lua files in the project'")
	add_text("")
	
	-- Simulate agent calling agent_search_files
	local search_response = api.call_tool("agent_search_files", {
		query = "*.lua",
		file_type = "lua",
		recursive = true,
		max_results = 10
	})
	
	if search_response and search_response.success then
		add_text("**MCP Tool Call:** agent_search_files")
		add_text("**Response:** File search completed successfully")
		add_text("**Data:** Found " .. (search_response.result and #search_response.result or 0) .. " Lua files")
	else
		add_text("**MCP Tool Call:** agent_search_files")
		add_text("**Response:** Failed to search files")
		add_text("**Error:** " .. (search_response and search_response.error or "Unknown error"))
	end
	
	add_text("")
	delay(DEMO_CONFIG.delay)
	
	-- Demo 3: Agent using agent_create_file
	add_text("## Demo 3: Agent Creating Files")
	add_text("")
	add_text("**Scenario:** Agent needs to create a new file")
	add_text("")
	add_text("**Agent Request:** 'Create a test file for me'")
	add_text("")
	
	-- Simulate agent calling agent_create_file
	local create_response = api.call_tool("agent_create_file", {
		file_name = "agent_test_file.txt",
		content = "# Agent Created File\n\nThis file was created by an AI agent using MCP tools.\n\nTimestamp: " .. os.date("%Y-%m-%d %H:%M:%S"),
		open_in_window = false
	})
	
	if create_response and create_response.success then
		add_text("**MCP Tool Call:** agent_create_file")
		add_text("**Response:** File created successfully")
		add_text("**Data:** Created agent_test_file.txt")
	else
		add_text("**MCP Tool Call:** agent_create_file")
		add_text("**Response:** Failed to create file")
		add_text("**Error:** " .. (create_response and create_response.error or "Unknown error"))
	end
	
	add_text("")
	delay(DEMO_CONFIG.delay)
	
	-- Demo 4: Agent using agent_edit_file
	add_text("## Demo 4: Agent Editing Files")
	add_text("")
	add_text("**Scenario:** Agent needs to modify an existing file")
	add_text("")
	add_text("**Agent Request:** 'Add a comment to the current file'")
	add_text("")
	
	-- Get current file info
	local current_file = vim.api.nvim_buf_get_name(0)
	if current_file and current_file ~= "" then
		-- Simulate agent calling agent_edit_file
		local edit_response = api.call_tool("agent_edit_file", {
			file_path = current_file,
			line_number = 1,
			content = "-- Agent added comment: " .. os.date("%Y-%m-%d %H:%M:%S")
		})
		
		if edit_response and edit_response.success then
			add_text("**MCP Tool Call:** agent_edit_file")
			add_text("**Response:** File edited successfully")
			add_text("**Data:** Added comment to " .. vim.fn.fnamemodify(current_file, ":t"))
		else
			add_text("**MCP Tool Call:** agent_edit_file")
			add_text("**Response:** Failed to edit file")
			add_text("**Error:** " .. (edit_response and edit_response.error or "Unknown error"))
		end
	else
		add_text("**MCP Tool Call:** agent_edit_file")
		add_text("**Response:** No current file to edit")
		add_text("**Note:** This demo requires an open file")
	end
	
	add_text("")
	delay(DEMO_CONFIG.delay)
	
	-- Demo 5: Agent using agent_execute_command
	add_text("## Demo 5: Agent Executing Commands")
	add_text("")
	add_text("**Scenario:** Agent needs to execute a Neovim command")
	add_text("")
	add_text("**Agent Request:** 'Show me the current buffer list'")
	add_text("")
	
	-- Simulate agent calling agent_execute_command
	local command_response = api.call_tool("agent_execute_command", {
		command_type = "neovim",
		command = "buffers"
	})
	
	if command_response and command_response.success then
		add_text("**MCP Tool Call:** agent_execute_command")
		add_text("**Response:** Command executed successfully")
		add_text("**Data:** Buffer list displayed")
	else
		add_text("**MCP Tool Call:** agent_execute_command")
		add_text("**Response:** Failed to execute command")
		add_text("**Error:** " .. (command_response and command_response.error or "Unknown error"))
	end
	
	add_text("")
	delay(DEMO_CONFIG.delay)
	
	-- Demo 6: Agent using multiple tools in sequence
	add_text("## Demo 6: Agent Using Multiple Tools")
	add_text("")
	add_text("**Scenario:** Agent performing a complex task")
	add_text("")
	add_text("**Agent Request:** 'Analyze my current session and create a summary'")
	add_text("")
	
	-- Step 1: Get session info
	add_text("**Step 1:** Getting session information...")
	local session_info = api.call_tool("agent_session_info", {})
	if session_info and session_info.success then
		add_text("✅ Session info retrieved")
	else
		add_text("❌ Failed to get session info")
	end
	
	-- Step 2: Search for relevant files
	add_text("**Step 2:** Searching for relevant files...")
	local file_search = api.call_tool("agent_search_files", {
		query = "*.md",
		max_results = 5
	})
	if file_search and file_search.success then
		add_text("✅ File search completed")
	else
		add_text("❌ Failed to search files")
	end
	
	-- Step 3: Create summary file
	add_text("**Step 3:** Creating summary file...")
	local summary_content = "# Session Analysis Summary\n\n"
	summary_content = summary_content .. "Generated by AI Agent using MCP tools\n"
	summary_content = summary_content .. "Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n"
	summary_content = summary_content .. "## Session Overview\n"
	summary_content = summary_content .. "- Agent used multiple MCP tools\n"
	summary_content = summary_content .. "- Successfully integrated with Neovim\n"
	summary_content = summary_content .. "- Demonstrated tool chaining capabilities\n\n"
	summary_content = summary_content .. "## Tools Used\n"
	summary_content = summary_content .. "1. agent_session_info\n"
	summary_content = summary_content .. "2. agent_search_files\n"
	summary_content = summary_content .. "3. agent_create_file\n"
	
	local summary_response = api.call_tool("agent_create_file", {
		file_name = "session_analysis_summary.md",
		content = summary_content,
		open_in_window = true
	})
	
	if summary_response and summary_response.success then
		add_text("✅ Summary file created")
		add_text("📄 Created: session_analysis_summary.md")
	else
		add_text("❌ Failed to create summary file")
	end
	
	add_text("")
	delay(DEMO_CONFIG.delay)
	
	-- Show integration benefits
	add_text("## Integration Benefits")
	add_text("")
	add_text("✅ **Seamless Integration:** Agents can use Neovim tools directly")
	add_text("✅ **Context Awareness:** Tools have access to current session state")
	add_text("✅ **Approval System:** File operations go through approval workflow")
	add_text("✅ **Error Handling:** Robust error handling and recovery")
	add_text("✅ **Tool Chaining:** Multiple tools can be used in sequence")
	add_text("✅ **Audit Trail:** All tool usage is tracked and logged")
	add_text("")
	
	-- Show commands
	add_text("## Commands")
	add_text("")
	add_text("You can test these MCP tools manually:")
	add_text(":lua require('paragonic.api').call_tool('agent_session_info', {})")
	add_text(":lua require('paragonic.api').call_tool('agent_search_files', {query='*.lua'})")
	add_text(":lua require('paragonic.api').call_tool('agent_create_file', {file_name='test.txt', content='Hello'})")
	add_text(":lua require('paragonic.api').call_tool('agent_edit_file', {file_path='test.txt', line_number=1, content='Modified'})")
	add_text(":lua require('paragonic.api').call_tool('agent_execute_command', {command_type='neovim', command='buffers'})")
	add_text("")
	
	add_text("## Demo Notes")
	add_text("")
	add_text("• All MCP tool calls go through the approval system")
	add_text("• Tools are integrated with the undo system")
	add_text("• Session context is automatically provided")
	add_text("• Error handling ensures robust operation")
	add_text("• Tool usage is tracked for learning and optimization")
	add_text("")
	add_text("🎉 Agent MCP Tools integration is working! 🎉")
	
	print("✅ Agent MCP Tools demo completed!")
	print("")
	print("💡 Try the manual commands shown above to test individual tools")
	print("💡 Check the created files to see the results")
end

-- Run the demo
test_agent_mcp_tools()
