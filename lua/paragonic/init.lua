--[[
Paragonic - Agentic Neovim Extension
Main plugin entry point
--]]

local M = {}

-- Load all modules
local config = require("paragonic.config")
local utils = require("paragonic.utils")
local debug = require("paragonic.debug")
local backend = require("paragonic.backend")
local chat = require("paragonic.chat")
local search = require("paragonic.search")
local ai_agent = require("paragonic.ai_agent")
local mcp = require("paragonic.mcp")
local events = require("paragonic.events")
local ui = require("paragonic.ui")
local keymaps = require("paragonic.keymaps")
local text = require("paragonic.text")

-- Expose modules directly for clean API
M.backend = backend
M.chat = chat
M.search = search
M.ai_agent = ai_agent
M.mcp = mcp
M.events = events
M.ui = ui
M.keymaps = keymaps
M.text = text
M.debug = debug
M.utils = utils
M.config = config

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
        {name = "ParagonicChat", func = M.chat.open_chat, opts = {}},
        {name = "ParagonicProjects", func = M.ui.open_projects, opts = {}},
        {name = "ParagonicConfig", func = M.ui.open_config, opts = {}},
        {name = "ParagonicDebug", func = M.debug.open_debug_buffer, opts = {}},
        
                -- Chat commands
        {name = "ParagonicSend", func = function()
        M.debug.debug_print("WRAPPER: About to call send_message_command", "debug")
        M.chat.send_message_command()
        M.debug.debug_print("WRAPPER: send_message_command completed", "debug")
        end, opts = {}},
        {name = "ParagonicSendDebug", func = M.chat.send_message_command_debug, opts = {}},
                {name = "ParagonicTest", func = function()
        M.debug.debug_print("TEST COMMAND WORKING", "debug")
        vim.notify("TEST COMMAND WORKING", vim.log.levels.INFO)
        end, opts = {}},
    
        -- Project and config commands
        {name = "ParagonicCreateProject", func = M.ui.create_project_command, opts = {}},
        {name = "ParagonicSaveConfig", func = M.ui.save_config_command, opts = {}},
    
    -- Search commands
        {name = "ParagonicSearch", func = M.search.search_command, opts = {nargs = "*"}},
        {name = "ParagonicSearchFiltered", func = M.search.search_filtered_command, opts = {nargs = "*"}},
        {name = "ParagonicSearchHybrid", func = M.search.search_hybrid_command, opts = {nargs = "*"}},
    
    -- Search history and saved searches commands
        {name = "ParagonicSearchHistory", func = M.search.show_search_history, opts = {}},
        {name = "ParagonicSavedSearches", func = M.search.show_saved_searches, opts = {}},
        {name = "ParagonicSaveSearch", func = M.search.save_current_search, opts = {}},
    
    -- Persistent storage commands
        {name = "ParagonicExportData", func = M.utils.export_data, opts = {}},
        {name = "ParagonicImportData", func = M.utils.import_data, opts = {}},
        {name = "ParagonicBackupData", func = M.utils.backup_data, opts = {}},
        
        -- Agentic collaboration commands
        {name = "ParagonicAgentSession", func = M.ai_agent.get_agent_session_info, opts = {}},
        {name = "ParagonicAgentEdit", func = M.ai_agent.agent_edit_file, opts = {nargs = "*"}},
        {name = "ParagonicAgentCreate", func = M.ai_agent.agent_create_file, opts = {nargs = "*"}},
        {name = "ParagonicAgentSave", func = M.ai_agent.agent_save_file, opts = {}},
        
        -- MCP commands
        {name = "ParagonicMCPInit", func = M.mcp.initialize_mcp_server, opts = {}},
        {name = "ParagonicMCPResources", func = function() 
            local resources = M.mcp.list_mcp_resources()
            M.mcp.display_mcp_resources(resources)
        end, opts = {}},
        {name = "ParagonicMCPTools", func = function()
            local tools = M.mcp.list_mcp_tools()
            M.mcp.display_mcp_tools(tools)
        end, opts = {}},
        {name = "ParagonicMCPReadResource", func = function(args)
            local uri = args[1] or "neovim://session"
            local result = M.mcp.read_mcp_resource(uri)
            M.mcp.display_resource_content(uri, result)
        end, opts = {nargs = "?"}},
        
        -- MCP Client commands (sampling and roots)
        {name = "ParagonicMCPSample", func = function(args)
            local uri = args[1] or "neovim://buffers"
            local limit = tonumber(args[2]) or 5
            local criteria = {limit = limit}
            local result = M.mcp.sample_resource(uri, criteria)
            M.mcp.display_sampled_content(uri, result, criteria)
        end, opts = {nargs = "*"}},
        {name = "ParagonicMCPRoots", func = function(args)
            local uri = args[1] or "neovim://buffers"
            local roots = M.mcp.define_resource_roots(uri, {})
            M.mcp.display_resource_roots(uri, roots)
        end, opts = {nargs = "?"}},
        
        -- AI Agent collaboration commands
        {name = "ParagonicAIAgentStart", func = function(args)
            local agent_name = args[1] or "AI Agent"
            local session_id = M.ai_agent.start_ai_agent_session(agent_name)
            if session_id then
                vim.notify("AI agent session started: " .. session_id, vim.log.levels.INFO)
            end
        end, opts = {nargs = "?"}},
        {name = "ParagonicAIAgentStop", func = function()
            local success = M.ai_agent.stop_ai_agent_session()
            if success then
                vim.notify("AI agent session stopped successfully", vim.log.levels.INFO)
            end
        end, opts = {}},
        {name = "ParagonicAIAgentStatus", func = function()
            local status = M.ai_agent.get_ai_agent_session_status()
            M.mcp.display_ai_agent_status(status)
        end, opts = {}},
        {name = "ParagonicAIAgentMessage", func = function(args)
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
        end, opts = {nargs = "*"}},
        {name = "ParagonicAIAgentReceive", func = function(args)
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
        end, opts = {nargs = "*"}},
        {name = "ParagonicAIAgentCommand", func = function(args)
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
        end, opts = {nargs = "*"}},
        {name = "ParagonicAIAgentBuffer", func = function(args)
            local buffer_id = tonumber(args[1])
            local start_line = tonumber(args[2])
            local end_line = tonumber(args[3])
            
            local success, action_id, result = M.ai_agent.get_ai_agent_buffer_content(buffer_id, start_line, end_line)
            if success then
                vim.notify("AI agent buffer read (ID: " .. action_id .. ", " .. result.line_count .. " lines)", vim.log.levels.INFO)
            else
                vim.notify("Failed to read buffer: " .. action_id, vim.log.levels.ERROR)
            end
        end, opts = {nargs = "*"}},
        {name = "ParagonicAIAgentBufferWrite", func = function(args)
            if #args < 2 then
                vim.notify("Usage: :ParagonicAIAgentBufferWrite <buffer_id> <line1> <line2> ...", vim.log.levels.WARN)
                return
            end
            
            local buffer_id = tonumber(args[1])
            local lines = {}
            for i = 2, #args do
                table.insert(lines, args[i])
            end
            
            local success, action_id, result = M.ai_agent.set_ai_agent_buffer_content(buffer_id, lines)
            if success then
                vim.notify("AI agent buffer write (ID: " .. action_id .. ", " .. result.lines_written .. " lines)", vim.log.levels.INFO)
            else
                vim.notify("Failed to write buffer: " .. action_id, vim.log.levels.ERROR)
            end
        end, opts = {nargs = "*"}},
        
        -- Enhanced AI Agent Action Commands
        {name = "ParagonicAIAgentSwitchBuffer", func = function(args)
            local buffer_id = tonumber(args[1])
            local success, action_id, result = M.ai_agent.ai_agent_switch_buffer(buffer_id)
            if success then
                vim.notify("AI agent switched to buffer " .. result.buffer_id, vim.log.levels.INFO)
            else
                vim.notify("Failed to switch buffer: " .. action_id, vim.log.levels.ERROR)
            end
        end, opts = {nargs = "?"}},
        {name = "ParagonicAIAgentSetCursor", func = function(args)
            local line = tonumber(args[1]) or 1
            local column = tonumber(args[2]) or 0
            local success, action_id, result = M.ai_agent.ai_agent_set_cursor(line, column)
            if success then
                vim.notify("AI agent set cursor to line " .. line .. ", column " .. column, vim.log.levels.INFO)
            else
                vim.notify("Failed to set cursor: " .. action_id, vim.log.levels.ERROR)
            end
        end, opts = {nargs = "*"}},
        {name = "ParagonicAIAgentCreateWindow", func = function(args)
            local split_type = args[1] or "split"
            local buffer_id = tonumber(args[2])
            local success, action_id, result = M.ai_agent.ai_agent_create_window(split_type, buffer_id)
            if success then
                vim.notify("AI agent created " .. split_type .. " window", vim.log.levels.INFO)
            else
                vim.notify("Failed to create window: " .. action_id, vim.log.levels.ERROR)
            end
        end, opts = {nargs = "*"}},
        {name = "ParagonicAIAgentInsertText", func = function(args)
            if #args < 1 then
                vim.notify("Usage: :ParagonicAIAgentInsertText <text> [mode]", vim.log.levels.WARN)
                return
            end
            
            local text = table.concat(args, " ")
            local mode = args[#args] == "insert" or args[#args] == "append" or args[#args] == "replace" and args[#args] or "insert"
            if mode ~= "insert" and mode ~= "append" and mode ~= "replace" then
                mode = "insert"
            end
            
            local success, action_id, result = M.ai_agent.ai_agent_insert_text(text, mode)
            if success then
                vim.notify("AI agent inserted text (" .. mode .. " mode)", vim.log.levels.INFO)
            else
                vim.notify("Failed to insert text: " .. action_id, vim.log.levels.ERROR)
            end
        end, opts = {nargs = "*"}},
        {name = "ParagonicAIAgentGetState", func = function()
            local success, action_id, state = M.ai_agent.ai_agent_get_state()
            if success then
                vim.notify("AI agent retrieved Neovim state (" .. #state.buffers .. " buffers, " .. #state.windows .. " windows)", vim.log.levels.INFO)
            else
                vim.notify("Failed to get state: " .. action_id, vim.log.levels.ERROR)
            end
        end, opts = {}},
        {name = "ParagonicAIAgentExecuteSequence", func = function(args)
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
                    params = {command = arg}
                })
            end
            
            local success, action_id, result = M.ai_agent.ai_agent_execute_sequence(actions)
            if success then
                vim.notify("AI agent executed sequence (" .. result.successful_actions .. "/" .. result.total_actions .. " successful)", vim.log.levels.INFO)
            else
                vim.notify("AI agent executed sequence with errors (" .. result.successful_actions .. "/" .. result.total_actions .. " successful)", vim.log.levels.WARN)
            end
        end, opts = {nargs = "*"}},
        
        -- Connection management commands
        {name = "ParagonicReconnect", func = function()
            local success = M.backend.force_reconnect()
            if success then
                vim.notify("Successfully reconnected to Paragonic backend", vim.log.levels.INFO)
            else
                vim.notify("Failed to reconnect to Paragonic backend", vim.log.levels.ERROR)
            end
        end, opts = {}},
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
    end, 500)  -- Wait 500ms after startup
    
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
        M.debug_print("🔧 RPC client disconnected, attempting reconnection...", "info")
        local success = M._rpc_client:reconnect()
        if not success then
            M.debug_print("❌ Reconnection failed, returning nil", "error")
            return nil
        end
        M.debug_print("✅ RPC client reconnected successfully", "success")
    end
    
    return M._rpc_client
end









-- Open chat interface - delegate to chat module
function M.open_chat()
    return chat.open_chat()
end

-- Open projects interface - delegate to ui module
function M.open_projects()
    return ui.open_projects()
end

-- Open configuration - delegate to ui module
function M.open_config()
    return ui.open_config()
end

-- Update configuration
function M.update_config(new_config)
    config = vim.tbl_deep_extend("force", config, new_config)
end

-- Send message command - delegate to chat module
function M.send_message_command()
    return chat.send_message_command()
end

-- Enhanced send message command with debug messages - delegate to chat module
function M.send_message_command_debug()
    return chat.send_message_command_debug()
end

-- Command functions - delegate to ui module
function M.create_project_command()
    return ui.create_project_command()
end

function M.save_config_command()
    return ui.save_config_command()
end

-- Search functionality - delegate to search module
function M.search_embeddings(query, limit)
    return search.search_embeddings(query, limit)
end

function M.find_similar_content(query, content_type, limit, threshold)
    return search.find_similar_content(query, content_type, limit, threshold)
end

function M.hybrid_search(query, content_type, limit, threshold, include_text_filtering)
    return search.hybrid_search(query, content_type, limit, threshold, include_text_filtering)
end

-- Search command handlers - delegate to search module
function M.search_command(args)
    return search.search_command(args)
end

function M.search_filtered_command(args)
    return search.search_filtered_command(args)
end

function M.search_hybrid_command(args)
    return search.search_hybrid_command(args)
end

-- Display search results - delegate to search module
function M.display_search_results(results, title)
    return search.display_search_results(results, title)
end

-- Handle search result selection - delegate to search module
function M.select_search_result(buf)
    return search.select_search_result(buf)
end

-- Show detailed information about a search result - delegate to search module
function M.show_result_details(result)
    return search.show_result_details(result)
end

-- Keymap setup functions - delegate to keymaps module
function M.setup_which_key()
    return keymaps.setup_which_key()
end

function M._setup_keymaps()
    return keymaps.setup_keymaps()
end

-- Quick search functions - delegate to search module
function M.quick_search()
    return search.quick_search()
end

function M.quick_filtered_search()
    return search.quick_filtered_search()
end

function M.quick_hybrid_search()
    return search.quick_hybrid_search()
end

-- Search history and saved searches functionality

-- Search history functions - delegate to search module
function M.add_to_search_history(query, search_type, results_count, timestamp)
    return search.add_to_search_history(query, search_type, results_count, timestamp)
end

function M.get_search_history()
    return search.get_search_history()
end

function M.clear_search_history()
    return search.clear_search_history()
end

function M.save_search(name, query, search_type, content_type, limit, threshold)
    return search.save_search(name, query, search_type, content_type, limit, threshold)
end

function M.get_saved_searches()
    return search.get_saved_searches()
end

function M.delete_saved_search(name)
    return search.delete_saved_search(name)
end

function M.execute_saved_search(name)
    return search.execute_saved_search(name)
end

-- Show search history - delegate to search module
function M.show_search_history()
    return search.show_search_history()
end

-- Show saved searches - delegate to search module
function M.show_saved_searches()
    return search.show_saved_searches()
end

-- Search history interaction functions - delegate to search module
function M.repeat_search_from_history(buf)
    return search.repeat_search_from_history(buf)
end

function M.delete_from_search_history(buf)
    return search.delete_from_search_history(buf)
end

function M.execute_saved_search_from_list(buf)
    return search.execute_saved_search_from_list(buf)
end

function M.delete_saved_search_from_list(buf)
    return search.delete_saved_search_from_list(buf)
end

function M.save_current_search()
    return search.save_current_search()
end

-- Persistent storage functionality

-- Persistent storage functions - delegate to utils module
function M._ensure_data_directory()
    return utils.ensure_data_directory()
end

function M._save_to_json(data, file_path)
    return utils.save_to_json(data, file_path)
end

function M._load_from_json(file_path)
    return utils.load_from_json(file_path)
end

-- Persistent storage functions - delegate to utils module
function M._save_search_history()
    return utils.save_search_history()
end

function M._load_search_history()
    return utils.load_search_history()
end

function M._save_saved_searches()
    return utils.save_saved_searches()
end

function M._load_saved_searches()
    return utils.load_saved_searches()
end

-- Load all persistent data with error handling
function M._load_persistent_data()
    return utils.load_persistent_data()
end

-- Auto-save function
function M._auto_save()
    return utils.auto_save()
end

-- Export data to a file
function M.export_data()
    return utils.export_data()
end

-- Import data from a file
function M.import_data()
    return utils.import_data()
end

-- Backup data
function M.backup_data()
    return utils.backup_data()
end

-- Agentic collaboration functionality

-- Agent session info getter - delegate to ai_agent module
function M.get_agent_session_info()
    return ai_agent.get_agent_session_info()
end

-- Agent file editor - delegate to ai_agent module
function M.agent_edit_file(args)
    return ai_agent.agent_edit_file(args)
end

-- Get file content from current session - delegate to ai_agent module
function M.agent_get_file_content(file_path)
    return ai_agent.agent_get_file_content(file_path)
end

-- Agent file creator - delegate to ai_agent module
function M.agent_create_file(args)
    return ai_agent.agent_create_file(args)
end

-- Create a file with a template - delegate to ai_agent module
function M.agent_create_file_with_template(template_name, file_name)
    return ai_agent.agent_create_file_with_template(template_name, file_name)
end

-- Agent file saver - delegate to ai_agent module
function M.agent_save_file(args)
    return ai_agent.agent_save_file(args)
end

-- Save all modified files - delegate to ai_agent module
function M.agent_save_all_files()
    return ai_agent.agent_save_all_files()
end

-- Save file with backup - delegate to ai_agent module
function M.agent_save_with_backup(args)
    return ai_agent.agent_save_with_backup(args)
end

-- MCP Server functionality

-- MCP Server configuration
M.mcp_server = {
    protocol_version = "2025-06-18",
    server_info = {
        name = "paragonic-neovim",
        version = "1.0.0"
    },
    capabilities = {
        resources = {
            list_resources = true,
            read_resources = true
        },
        tools = {
            list_tools = true,
            call_tools = true
        },
        prompts = {
            list_prompts = true,
            show_prompts = true
        }
    }
}

-- Initialize MCP server
-- Initialize MCP server - delegate to mcp module
function M.initialize_mcp_server()
    return mcp.initialize_mcp_server()
end

-- List MCP resources - delegate to mcp module
function M.list_mcp_resources()
    return mcp.list_mcp_resources()
end

-- List MCP tools - delegate to mcp module
function M.list_mcp_tools()
    return mcp.list_mcp_tools()
end

-- Handle MCP messages - delegate to mcp module
function M.handle_mcp_message(message)
    return mcp.handle_mcp_message(message)
end

-- Handle MCP resource reading - delegate to mcp module
function M.handle_resource_read(id, params)
    return mcp.handle_resource_read(id, params)
end

-- Read MCP resource content - delegate to mcp module
function M.read_mcp_resource(uri)
    return mcp.read_mcp_resource(uri)
end

-- Validate resource content - delegate to mcp module
function M.validate_resource_content(content)
    return mcp.validate_resource_content(content)
end

-- MCP Progress tracking state
M.progress_state = {
    active_operations = {},
    next_progress_id = 1
}

-- Progress notification functions - delegate to mcp module
function M.create_progress_notification(progress_id, message, percentage, done)
    return mcp.create_progress_notification(progress_id, message, percentage, done)
end

function M.start_progress_operation(operation_name, initial_message)
    return mcp.start_progress_operation(operation_name, initial_message)
end

function M.update_progress(progress_id, message, percentage)
    return mcp.update_progress(progress_id, message, percentage)
end

function M.complete_progress_operation(progress_id, final_message)
    return mcp.complete_progress_operation(progress_id, final_message)
end

function M.format_progress_summary(progress_notifications)
    return mcp.format_progress_summary(progress_notifications)
end

-- Handle MCP tool calls - delegate to mcp module
function M.handle_tool_call(id, params)
    return mcp.handle_tool_call(id, params)
end


-- Display MCP resources - delegate to mcp module
function M.display_mcp_resources(resources)
    return mcp.display_mcp_resources(resources)
end

-- Display MCP tools - delegate to mcp module
function M.display_mcp_tools(tools)
    return mcp.display_mcp_tools(tools)
end

-- Display MCP resource content - delegate to mcp module
function M.display_resource_content(uri, result)
    return mcp.display_resource_content(uri, result)
end

-- Display sampled content - delegate to mcp module
function M.display_sampled_content(uri, result, criteria)
    return mcp.display_sampled_content(uri, result, criteria)
end

-- Display resource roots - delegate to mcp module
function M.display_resource_roots(uri, roots)
    return mcp.display_resource_roots(uri, roots)
end

-- Display AI agent session status in a floating window
function M.display_ai_agent_status(status)
    local lines = {
        "🤖 AI Agent Session Status",
        string.rep("─", 50),
        ""
    }
    
    if status.active then
        table.insert(lines, "✅ " .. status.message)
        table.insert(lines, "")
        table.insert(lines, "📋 Session Details:")
        table.insert(lines, "  ID: " .. status.session_id)
        table.insert(lines, "  Agent: " .. status.agent_name)
        table.insert(lines, "  Duration: " .. status.duration .. " seconds")
        table.insert(lines, "  Interactions: " .. status.interaction_count)
        table.insert(lines, "")
        table.insert(lines, "📍 Current Context:")
        table.insert(lines, "  File: " .. (status.context.current_file or "none"))
        table.insert(lines, "  Directory: " .. status.context.current_directory)
        table.insert(lines, "  Buffers: " .. status.context.buffer_count)
        table.insert(lines, "  Mode: " .. status.context.mode)
    else
        table.insert(lines, "❌ " .. status.message)
    end
    
    -- Create floating window
    local width = 80
    local height = math.min(#lines + 2, 20)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
    
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "single"
    })
    
    -- Set up keymaps
    vim.keymap.set("n", "q", "<cmd>close<CR>", {buffer = buf, noremap = true})
    vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", {buffer = buf, noremap = true})
    
    vim.notify("Displayed AI agent session status", vim.log.levels.INFO)
end

-- System info functions - delegate to mcp module
function M.get_marks_info()
    return mcp.get_marks_info()
end

function M.get_registers_info()
    return mcp.get_registers_info()
end

function M.get_macros_info()
    return mcp.get_macros_info()
end

function M.get_plugins_info()
    return mcp.get_plugins_info()
end

-- MCP Configuration Schema
M.config_schema = {
    ollama_host = {
        type = "string",
        description = "Ollama server host and port",
        default = "http://localhost:11434"
    },
    ollama_model = {
        type = "string",
        description = "Default Ollama model to use",
        default = "llama3.2:3b"
    },
    database_path = {
        type = "string",
        description = "Path to the database directory",
        default = "/tmp/paragonic/db"
    },
    log_level = {
        type = "string",
        description = "Logging level",
        default = "info",
        enum = {"debug", "info", "warn", "error"}
    },
    search_history_size = {
        type = "integer",
        description = "Maximum number of search history entries",
        default = 50,
        minimum = 10,
        maximum = 1000
    },
    auto_save = {
        type = "boolean",
        description = "Automatically save files after edits",
        default = true
    }
}

-- Get current configuration (with defaults)
-- Configuration functions - delegate to config module
function M.get_configuration()
    return config.get_configuration()
end

function M.validate_config_value(key, value)
    return config.validate_config_value(key, value)
end

function M.set_configuration_value(key, value)
    return config.set_configuration_value(key, value)
end

function M.save_configuration_to_file(config, file_path)
    return config.save_configuration_to_file(config, file_path)
end

function M.load_configuration_from_file(file_path)
    return config.load_configuration_from_file(file_path)
end

function M.get_configuration_schema()
    return config.get_configuration_schema()
end

function M.get_configuration_as_resource()
    return config.get_configuration_as_resource()
end

function M.handle_configuration_method(method, params)
    return config.handle_configuration_method(method, params)
end

-- List MCP resources - delegate to mcp module
function M.list_mcp_resources()
    return mcp.list_mcp_resources()
end

-- MCP Cancellation state management
M.cancellation_state = {
    active_operations = {},
    next_operation_id = 1
}

-- Cancellation operation helpers - delegate to mcp module
function M.register_cancellable_operation(operation_type, description)
    return mcp.register_cancellable_operation(operation_type, description)
end

function M.is_operation_cancelled(operation_id)
    return mcp.is_operation_cancelled(operation_id)
end

function M.cancel_operation(operation_id)
    return mcp.cancel_operation(operation_id)
end

function M.complete_operation(operation_id)
    return mcp.complete_operation(operation_id)
end

-- Handle MCP tool calls with cancellation - delegate to mcp module
function M.handle_tool_call_with_cancellation(id, params)
    return mcp.handle_tool_call_with_cancellation(id, params)
end

-- Handle MCP cancellation messages - delegate to mcp module
function M.handle_cancellation_message(message)
    return mcp.handle_cancellation_message(message)
end

-- Handle MCP messages - delegate to mcp module
function M.handle_mcp_message(message)
    return mcp.handle_mcp_message(message)
end

return M 