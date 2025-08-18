--[[
Paragonic - Agentic Neovim Extension
Main plugin entry point
--]]

local M = {}

-- Load all modules
local ai_agent = require("paragonic.ai_agent")
local backend = require("paragonic.backend")
local chat = require("paragonic.chat")
local config = require("paragonic.config")
local debug = require("paragonic.debug")
local events = require("paragonic.events")
local keymaps = require("paragonic.keymaps")
local mcp = require("paragonic.mcp")
local patterns = require("paragonic.patterns")
local search = require("paragonic.search")
local text = require("paragonic.text")
local ui = require("paragonic.ui")
local utils = require("paragonic.utils")

-- Expose modules directly for clean API
M.ai_agent = ai_agent
M.backend = backend
M.chat = chat
M.config = config
M.debug = debug
M.events = events
M.keymaps = keymaps
M.mcp = mcp
M.patterns = patterns
M.search = search
M.text = text
M.ui = ui
M.utils = utils

-- Initialize the plugin
function M.setup(opts)
	-- Check if we're in Neovim environment
	if not vim then
		debug.debug_print("Not in Neovim environment, skipping setup", "warning")
		return
	end

	-- Set debug buffer flag for RPC module
	vim.g.paragonic_debug_buffer = true

	-- Setup configuration
	config.setup(opts)

	-- Define all user commands in a table for clean iteration
	local commands = {
		-- Core interface commands
		{ name = "ParagonicChat", func = M.chat.open_chat, opts = {} },
		{ name = "ParagonicDebug", func = M.debug.open_debug_buffer, opts = {} },

		-- Chat commands
		{ name = "ParagonicSendDebug", func = M.chat.send_message_command_debug, opts = {} },
		{ name = "ParagonicSendThinking", func = M.chat.send_message_command_thinking, opts = {} },
		{ name = "ParagonicSendSmart", func = M.chat.send_message_command_smart, opts = {} },
		{ name = "ParagonicSendBackward", func = M.chat.send_message_command_backward, opts = {} },
		{ name = "ParagonicSendForward", func = M.chat.send_message_command_forward, opts = {} },
		{ name = "ParagonicDebugMarkdown", func = M.chat.send_debug_markdown_test, opts = {} },
		{
			name = "ParagonicTest",
			func = function()
				M.debug.debug_print("TEST COMMAND WORKING", "debug")
				vim.notify("TEST COMMAND WORKING", vim.log.levels.INFO)
			end,
			opts = {},
		},
		{
			name = "ParagonicTestThinkingCallback",
			func = function()
				local test_suite = require("tests.unit.chat.test_thinking_callback_automation")
				test_suite.quick_diagnostic()
			end,
			opts = {},
		},
		{
			name = "ParagonicTestThinkingCallbackFull",
			func = function()
				local test_suite = require("tests.unit.chat.test_thinking_callback_automation")
				test_suite.run_all_tests()
			end,
			opts = {},
		},
		{
			name = "ParagonicTestInline",
			func = function()
				vim.cmd("source test_thinking_callback_inline.lua")
			end,
			opts = {},
		},

		-- Project and config commands (temporarily disabled during architecture migration)
		-- { name = "ParagonicCreateProject", func = M.ui.create_project_command, opts = {} },
		-- { name = "ParagonicSaveConfig", func = M.ui.save_config_command, opts = {} },

		-- Search commands
		{ name = "ParagonicSearch", func = M.search.search_command, opts = { nargs = "*" } },
		{ name = "ParagonicSearchFiltered", func = M.search.search_filtered_command, opts = { nargs = "*" } },
		{ name = "ParagonicSearchHybrid", func = M.search.search_hybrid_command, opts = { nargs = "*" } },

		-- Search history and saved searches commands
		{ name = "ParagonicSearchHistory", func = M.search.show_search_history, opts = {} },
		{ name = "ParagonicSavedSearches", func = M.search.show_saved_searches, opts = {} },
		{ name = "ParagonicSaveSearch", func = M.search.save_current_search, opts = {} },

		-- Persistent storage commands
		{ name = "ParagonicExportData", func = M.utils.export_data, opts = {} },
		{ name = "ParagonicImportData", func = M.utils.import_data, opts = {} },
		{ name = "ParagonicBackupData", func = M.utils.backup_data, opts = {} },

		-- Agentic collaboration commands
		{ name = "ParagonicAgentSession", func = M.ai_agent.get_agent_session_info, opts = {} },
		{ name = "ParagonicAgentEdit", func = M.ai_agent.agent_edit_file, opts = { nargs = "*" } },
		{ name = "ParagonicAgentCreate", func = M.ai_agent.agent_create_file, opts = { nargs = "*" } },
		{ name = "ParagonicAgentSave", func = M.ai_agent.agent_save_file, opts = {} },

		-- MCP commands
		{ name = "ParagonicMCPInit", func = M.mcp.initialize_mcp_server, opts = {} },
		{
			name = "ParagonicMCPResources",
			func = function()
				local resources = M.mcp.list_mcp_resources()
				M.mcp.display_mcp_resources(resources)
			end,
			opts = {},
		},
		{
			name = "ParagonicMCPTools",
			func = function()
				local tools = M.mcp.list_mcp_tools()
				M.mcp.display_mcp_tools(tools)
			end,
			opts = {},
		},
		{
			name = "ParagonicMCPReadResource",
			func = function(args)
				local uri = args[1] or "neovim://session"
				local result = M.mcp.read_mcp_resource(uri)
				M.mcp.display_resource_content(uri, result)
			end,
			opts = { nargs = "?" },
		},

		-- MCP Client commands (sampling and roots)
		{
			name = "ParagonicMCPSample",
			func = function(args)
				local uri = args[1] or "neovim://buffers"
				local limit = tonumber(args[2]) or 5
				local criteria = { limit = limit }
				local result = M.mcp.sample_resource(uri, criteria)
				M.mcp.display_sampled_content(uri, result, criteria)
			end,
			opts = { nargs = "*" },
		},
		{
			name = "ParagonicMCPRoots",
			func = function(args)
				local uri = args[1] or "neovim://buffers"
				local roots = M.mcp.define_resource_roots(uri, {})
				M.mcp.display_resource_roots(uri, roots)
			end,
			opts = { nargs = "?" },
		},

		-- AI Agent collaboration commands
		{
			name = "ParagonicAIAgentStart",
			func = function(args)
				local agent_name = args[1] or "AI Agent"
				local session_id = M.ai_agent.start_ai_agent_session(agent_name)
				if session_id then
					vim.notify("AI agent session started: " .. session_id, vim.log.levels.INFO)
				end
			end,
			opts = { nargs = "?" },
		},
		{
			name = "ParagonicAIAgentStop",
			func = function()
				local success = M.ai_agent.stop_ai_agent_session()
				if success then
					vim.notify("AI agent session stopped successfully", vim.log.levels.INFO)
				end
			end,
			opts = {},
		},
		{
			name = "ParagonicAIAgentStatus",
			func = function()
				local status = M.ai_agent.get_ai_agent_session_status()
				M.mcp.display_ai_agent_status(status)
			end,
			opts = {},
		},
		{
			name = "ParagonicAIAgentMessage",
			func = function(args)
				if #args == 0 then
					vim.notify("Message content is required", vim.log.levels.WARN)
					return
				end
				local message = table.concat(args, " ")
				local success, message_id = M.ai_agent.send_ai_agent_message(message)
				if success then
					vim.notify("AI agent message sent (ID: " .. message_id .. ")", vim.log.levels.INFO)
				else
					vim.notify("Failed to send AI agent message: " .. message_id, vim.log.levels.ERROR)
				end
			end,
			opts = { nargs = "*" },
		},
		{
			name = "ParagonicAIAgentReceive",
			func = function(args)
				if #args == 0 then
					vim.notify("Message content is required", vim.log.levels.WARN)
					return
				end
				local message = table.concat(args, " ")
				local success, message_id = M.ai_agent.receive_ai_agent_message(message)
				if success then
					vim.notify("Neovim message received (ID: " .. message_id .. ")", vim.log.levels.INFO)
				else
					vim.notify("Failed to receive Neovim message: " .. message_id, vim.log.levels.ERROR)
				end
			end,
			opts = { nargs = "*" },
		},
		{
			name = "ParagonicAIAgentCommand",
			func = function(args)
				if #args == 0 then
					vim.notify("Command is required", vim.log.levels.WARN)
					return
				end
				local command = table.concat(args, " ")
				local success, action_id, result = M.ai_agent.execute_ai_agent_command(command)
				if success then
					vim.notify("AI agent command executed (ID: " .. action_id .. ")", vim.log.levels.INFO)
				else
					vim.notify("Failed to execute AI agent command: " .. action_id, vim.log.levels.ERROR)
				end
			end,
			opts = { nargs = "*" },
		},
		{
			name = "ParagonicAIAgentBuffer",
			func = function(args)
				local buffer_id = tonumber(args[1])
				local start_line = tonumber(args[2])
				local end_line = tonumber(args[3])

				local success, action_id, result =
					M.ai_agent.get_ai_agent_buffer_content(buffer_id, start_line, end_line)
				if success then
					vim.notify(
						"AI agent buffer read (ID: " .. action_id .. ", " .. result.line_count .. " lines)",
						vim.log.levels.INFO
					)
				else
					vim.notify("Failed to read buffer: " .. action_id, vim.log.levels.ERROR)
				end
			end,
			opts = { nargs = "*" },
		},
		{
			name = "ParagonicAIAgentBufferWrite",
			func = function(args)
				if #args < 2 then
					vim.notify(
						"Usage: :ParagonicAIAgentBufferWrite <buffer_id> <line1> <line2> ...",
						vim.log.levels.WARN
					)
					return
				end

				local buffer_id = tonumber(args[1])
				local lines = {}
				for i = 2, #args do
					table.insert(lines, args[i])
				end

				local success, action_id, result = M.ai_agent.set_ai_agent_buffer_content(buffer_id, lines)
				if success then
					vim.notify(
						"AI agent buffer write (ID: " .. action_id .. ", " .. result.lines_written .. " lines)",
						vim.log.levels.INFO
					)
				else
					vim.notify("Failed to write buffer: " .. action_id, vim.log.levels.ERROR)
				end
			end,
			opts = { nargs = "*" },
		},

		-- Enhanced AI Agent Action Commands
		{
			name = "ParagonicAIAgentSwitchBuffer",
			func = function(args)
				local buffer_id = tonumber(args[1])
				local success, action_id, result = M.ai_agent.ai_agent_switch_buffer(buffer_id)
				if success then
					vim.notify("AI agent switched to buffer " .. result.buffer_id, vim.log.levels.INFO)
				else
					vim.notify("Failed to switch buffer: " .. action_id, vim.log.levels.ERROR)
				end
			end,
			opts = { nargs = "?" },
		},
		{
			name = "ParagonicAIAgentSetCursor",
			func = function(args)
				local line = tonumber(args[1]) or 1
				local column = tonumber(args[2]) or 0
				local success, action_id, result = M.ai_agent.ai_agent_set_cursor(line, column)
				if success then
					vim.notify("AI agent set cursor to line " .. line .. ", column " .. column, vim.log.levels.INFO)
				else
					vim.notify("Failed to set cursor: " .. action_id, vim.log.levels.ERROR)
				end
			end,
			opts = { nargs = "*" },
		},
		{
			name = "ParagonicAIAgentCreateWindow",
			func = function(args)
				local split_type = args[1] or "split"
				local buffer_id = tonumber(args[2])
				local success, action_id, result = M.ai_agent.ai_agent_create_window(split_type, buffer_id)
				if success then
					vim.notify("AI agent created " .. split_type .. " window", vim.log.levels.INFO)
				else
					vim.notify("Failed to create window: " .. action_id, vim.log.levels.ERROR)
				end
			end,
			opts = { nargs = "*" },
		},
		{
			name = "ParagonicAIAgentInsertText",
			func = function(args)
				if #args < 1 then
					vim.notify("Usage: :ParagonicAIAgentInsertText <text> [mode]", vim.log.levels.WARN)
					return
				end

				local text = table.concat(args, " ")
				local mode = args[#args] == "insert"
					or args[#args] == "append"
					or args[#args] == "replace" and args[#args]
					or "insert"
				if mode ~= "insert" and mode ~= "append" and mode ~= "replace" then
					mode = "insert"
				end

				local success, action_id, result = M.ai_agent.ai_agent_insert_text(text, mode)
				if success then
					vim.notify("AI agent inserted text (" .. mode .. " mode)", vim.log.levels.INFO)
				else
					vim.notify("Failed to insert text: " .. action_id, vim.log.levels.ERROR)
				end
			end,
			opts = { nargs = "*" },
		},
		{
			name = "ParagonicAIAgentGetState",
			func = function()
				local success, action_id, state = M.ai_agent.ai_agent_get_state()
				if success then
					vim.notify(
						"AI agent retrieved Neovim state ("
							.. #state.buffers
							.. " buffers, "
							.. #state.windows
							.. " windows)",
						vim.log.levels.INFO
					)
				else
					vim.notify("Failed to get state: " .. action_id, vim.log.levels.ERROR)
				end
			end,
			opts = {},
		},
		{
			name = "ParagonicAIAgentExecuteSequence",
			func = function(args)
				if #args < 1 then
					vim.notify("Usage: :ParagonicAIAgentExecuteSequence <action1> <action2> ...", vim.log.levels.WARN)
					return
				end

				-- For now, this is a simple implementation that executes commands
				-- In a full implementation, this would parse action objects
				local actions = {}
				for i, arg in ipairs(args) do
					table.insert(actions, {
						type = "command",
						params = { command = arg },
					})
				end

				local success, action_id, result = M.ai_agent.ai_agent_execute_sequence(actions)
				if success then
					vim.notify(
						"AI agent executed sequence ("
							.. result.successful_actions
							.. "/"
							.. result.total_actions
							.. " successful)",
						vim.log.levels.INFO
					)
				else
					vim.notify(
						"AI agent executed sequence with errors ("
							.. result.successful_actions
							.. "/"
							.. result.total_actions
							.. " successful)",
						vim.log.levels.WARN
					)
				end
			end,
			opts = { nargs = "*" },
		},

		-- Pattern management commands
		{ name = "ParagonicPatternList", func = M.patterns.pattern_list_command, opts = {} },
		{
			name = "ParagonicPatternExecute",
			func = function(args)
				if #args == 0 then
					vim.notify("Pattern name is required", vim.log.levels.WARN)
					return
				end
				local pattern_name = table.concat(args, " ")
				M.patterns.execute_pattern_command(pattern_name)
			end,
			opts = { nargs = "*" },
		},

		-- Pattern metrics visualization commands
		{
			name = "ParagonicPatternStats",
			func = function(args)
				if #args == 0 then
					vim.notify("Pattern name is required", vim.log.levels.WARN)
					return
				end
				local pattern_name = table.concat(args, " ")
				M.patterns.show_pattern_statistics(pattern_name)
			end,
			opts = { nargs = "*" },
		},
		{
			name = "ParagonicPatternMetrics",
			func = function(args)
				if #args == 0 then
					vim.notify("Pattern name is required", vim.log.levels.WARN)
					return
				end
				local pattern_name = table.concat(args, " ")
				M.patterns.show_pattern_metrics(pattern_name)
			end,
			opts = { nargs = "*" },
		},
		{
			name = "ParagonicPatternHistory",
			func = function(args)
				if #args == 0 then
					vim.notify("Pattern name is required", vim.log.levels.WARN)
					return
				end
				local pattern_name = table.concat(args, " ")
				M.patterns.show_execution_history(pattern_name)
			end,
			opts = { nargs = "*" },
		},
		{
			name = "ParagonicPatternChart",
			func = function(args)
				if #args == 0 then
					vim.notify("Pattern name is required", vim.log.levels.WARN)
					return
				end
				local pattern_name = table.concat(args, " ")
				M.patterns.show_metrics_chart(pattern_name)
			end,
			opts = { nargs = "*" },
		},
		{
			name = "ParagonicPatternTrends",
			func = function(args)
				if #args == 0 then
					vim.notify("Pattern name is required", vim.log.levels.WARN)
					return
				end
				local pattern_name = table.concat(args, " ")
				M.patterns.show_performance_trends(pattern_name)
			end,
			opts = { nargs = "*" },
		},

		-- Pattern-aware session commands
		{
			name = "ParagonicAIAgentExecutePattern",
			func = function(args)
				if #args == 0 then
					vim.notify("Pattern name is required", vim.log.levels.WARN)
					return
				end
				local pattern_name = table.concat(args, " ")
				local success, result = M.ai_agent.execute_session_pattern(pattern_name)
				if success then
					vim.notify("Pattern executed in session: " .. pattern_name, vim.log.levels.INFO)
				else
					vim.notify("Failed to execute pattern: " .. tostring(result), vim.log.levels.ERROR)
				end
			end,
			opts = { nargs = "*" },
		},
		{
			name = "ParagonicAIAgentCheckPatterns",
			func = function()
				local success, result = M.ai_agent.check_and_trigger_patterns()
				if success then
					local triggered_count = #result.triggered_patterns
					local executed_count = #result.executed_patterns
					vim.notify(
						"Pattern check completed: "
							.. triggered_count
							.. " triggered, "
							.. executed_count
							.. " executed",
						vim.log.levels.INFO
					)
				else
					vim.notify("Pattern check failed: " .. tostring(result), vim.log.levels.ERROR)
				end
			end,
			opts = {},
		},

		-- Connection management commands
		{
			name = "ParagonicReconnect",
			func = function()
				local success = M.backend.force_reconnect()
				if success then
					vim.notify("Successfully reconnected to Paragonic backend", vim.log.levels.INFO)
				else
					vim.notify("Failed to reconnect to Paragonic backend", vim.log.levels.ERROR)
				end
			end,
			opts = {},
		},
	}

	-- Create all commands in a clean iteration
	for _, cmd in ipairs(commands) do
		vim.api.nvim_create_user_command(cmd.name, cmd.func, cmd.opts)
	end

	-- Set up keyboard mappings immediately
	M.keymaps.setup_keymaps()

	-- Load persistent data asynchronously to avoid startup delay
	vim.defer_fn(function()
		M.utils.load_persistent_data()
	end, 500) -- Wait 500ms after startup

	-- Don't initialize backend during startup - let it initialize on first use
	-- This prevents freezing during Neovim startup
	-- Backend will be initialized when first needed (e.g., when opening chat)

	-- Add any autocommands here as needed
end

-- Get RPC client, initializing backend if needed
function M._get_rpc_client()
	if not M._rpc_client then
		-- Return nil immediately - let calling functions handle initialization
		-- This prevents freezing during buffer operations
		return nil
	end

	-- Check if the client is still connected and try to reconnect if needed
	if not M._rpc_client:is_connected() then
		M.debug.debug_print("🔧 RPC client disconnected, attempting reconnection...", "info")
		local success = M._rpc_client:reconnect()
		if not success then
			M.debug.debug_print("❌ Reconnection failed, returning nil", "error")
			return nil
		end
		M.debug.debug_print("✅ RPC client reconnected successfully", "success")
	end

	return M._rpc_client
end

return M
