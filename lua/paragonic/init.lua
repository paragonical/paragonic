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

-- Text processing functions - delegate to text module
local function wrap_text(text, max_width, indent)
    return text.wrap_text(text, max_width, indent)
end

local function wrap_text_with_diamond(text, max_width)
    return text.wrap_text_with_diamond(text, max_width)
end

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
        {name = "ParagonicChat", func = M.open_chat, opts = {}},
        {name = "ParagonicProjects", func = M.open_projects, opts = {}},
        {name = "ParagonicConfig", func = M.open_config, opts = {}},
        {name = "ParagonicDebug", func = M.open_debug_buffer, opts = {}},
        
        -- Chat commands
        {name = "ParagonicSend", func = function()
            M.debug_print("WRAPPER: About to call send_message_command", "debug")
            M.send_message_command()
            M.debug_print("WRAPPER: send_message_command completed", "debug")
        end, opts = {}},
        {name = "ParagonicSendDebug", func = M.send_message_command_debug, opts = {}},
        {name = "ParagonicTest", func = function()
            M.debug_print("TEST COMMAND WORKING", "debug")
            vim.notify("TEST COMMAND WORKING", vim.log.levels.INFO)
        end, opts = {}},
        
        -- Project and config commands
        {name = "ParagonicCreateProject", func = M.create_project_command, opts = {}},
        {name = "ParagonicSaveConfig", func = M.save_config_command, opts = {}},
        
        -- Search commands
        {name = "ParagonicSearch", func = M.search_command, opts = {nargs = "*"}},
        {name = "ParagonicSearchFiltered", func = M.search_filtered_command, opts = {nargs = "*"}},
        {name = "ParagonicSearchHybrid", func = M.search_hybrid_command, opts = {nargs = "*"}},
        
        -- Search history and saved searches commands
        {name = "ParagonicSearchHistory", func = M.show_search_history, opts = {}},
        {name = "ParagonicSavedSearches", func = M.show_saved_searches, opts = {}},
        {name = "ParagonicSaveSearch", func = M.save_current_search, opts = {}},
        
        -- Persistent storage commands
        {name = "ParagonicExportData", func = M.export_data, opts = {}},
        {name = "ParagonicImportData", func = M.import_data, opts = {}},
        {name = "ParagonicBackupData", func = M.backup_data, opts = {}},
        
        -- Agentic collaboration commands
        {name = "ParagonicAgentSession", func = M.get_agent_session_info, opts = {}},
        {name = "ParagonicAgentEdit", func = M.agent_edit_file, opts = {nargs = "*"}},
        {name = "ParagonicAgentCreate", func = M.agent_create_file, opts = {nargs = "*"}},
        {name = "ParagonicAgentSave", func = M.agent_save_file, opts = {}},
        
        -- MCP commands
        {name = "ParagonicMCPInit", func = M.initialize_mcp_server, opts = {}},
        {name = "ParagonicMCPResources", func = function() 
            local resources = M.list_mcp_resources()
            M.display_mcp_resources(resources)
        end, opts = {}},
        {name = "ParagonicMCPTools", func = function()
            local tools = M.list_mcp_tools()
            M.display_mcp_tools(tools)
        end, opts = {}},
        {name = "ParagonicMCPReadResource", func = function(args)
            local uri = args[1] or "neovim://session"
            local result = M.read_mcp_resource(uri)
            M.display_resource_content(uri, result)
        end, opts = {nargs = "?"}},
        
        -- MCP Client commands (sampling and roots)
        {name = "ParagonicMCPSample", func = function(args)
            local uri = args[1] or "neovim://buffers"
            local limit = tonumber(args[2]) or 5
            local criteria = {limit = limit}
            local result = M.sample_resource(uri, criteria)
            M.display_sampled_content(uri, result, criteria)
        end, opts = {nargs = "*"}},
        {name = "ParagonicMCPRoots", func = function(args)
            local uri = args[1] or "neovim://buffers"
            local roots = M.define_resource_roots(uri, {})
            M.display_resource_roots(uri, roots)
        end, opts = {nargs = "?"}},
        
        -- AI Agent collaboration commands
        {name = "ParagonicAIAgentStart", func = function(args)
            local agent_name = args[1] or "AI Agent"
            local session_id = M.start_ai_agent_session(agent_name)
            if session_id then
                vim.notify("AI agent session started: " .. session_id, vim.log.levels.INFO)
            end
        end, opts = {nargs = "?"}},
        {name = "ParagonicAIAgentStop", func = function()
            local success = M.stop_ai_agent_session()
            if success then
                vim.notify("AI agent session stopped successfully", vim.log.levels.INFO)
            end
        end, opts = {}},
        {name = "ParagonicAIAgentStatus", func = function()
            local status = M.get_ai_agent_session_status()
            M.display_ai_agent_status(status)
        end, opts = {}},
        {name = "ParagonicAIAgentMessage", func = function(args)
            if #args == 0 then
                vim.notify("Message content is required", vim.log.levels.WARN)
                return
            end
            local message = table.concat(args, " ")
            local success, message_id = M.send_ai_agent_message(message)
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
            local success, message_id = M.receive_ai_agent_message(message)
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
            local success, action_id, result = M.execute_ai_agent_command(command)
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
            
            local success, action_id, result = M.get_ai_agent_buffer_content(buffer_id, start_line, end_line)
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
            
            local success, action_id, result = M.set_ai_agent_buffer_content(buffer_id, lines)
            if success then
                vim.notify("AI agent buffer write (ID: " .. action_id .. ", " .. result.lines_written .. " lines)", vim.log.levels.INFO)
            else
                vim.notify("Failed to write buffer: " .. action_id, vim.log.levels.ERROR)
            end
        end, opts = {nargs = "*"}},
        
        -- Enhanced AI Agent Action Commands
        {name = "ParagonicAIAgentSwitchBuffer", func = function(args)
            local buffer_id = tonumber(args[1])
            local success, action_id, result = M.ai_agent_switch_buffer(buffer_id)
            if success then
                vim.notify("AI agent switched to buffer " .. result.buffer_id, vim.log.levels.INFO)
            else
                vim.notify("Failed to switch buffer: " .. action_id, vim.log.levels.ERROR)
            end
        end, opts = {nargs = "?"}},
        {name = "ParagonicAIAgentSetCursor", func = function(args)
            local line = tonumber(args[1]) or 1
            local column = tonumber(args[2]) or 0
            local success, action_id, result = M.ai_agent_set_cursor(line, column)
            if success then
                vim.notify("AI agent set cursor to line " .. line .. ", column " .. column, vim.log.levels.INFO)
            else
                vim.notify("Failed to set cursor: " .. action_id, vim.log.levels.ERROR)
            end
        end, opts = {nargs = "*"}},
        {name = "ParagonicAIAgentCreateWindow", func = function(args)
            local split_type = args[1] or "split"
            local buffer_id = tonumber(args[2])
            local success, action_id, result = M.ai_agent_create_window(split_type, buffer_id)
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
            
            local success, action_id, result = M.ai_agent_insert_text(text, mode)
            if success then
                vim.notify("AI agent inserted text (" .. mode .. " mode)", vim.log.levels.INFO)
            else
                vim.notify("Failed to insert text: " .. action_id, vim.log.levels.ERROR)
            end
        end, opts = {nargs = "*"}},
        {name = "ParagonicAIAgentGetState", func = function()
            local success, action_id, state = M.ai_agent_get_state()
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
            
            local success, action_id, result = M.ai_agent_execute_sequence(actions)
            if success then
                vim.notify("AI agent executed sequence (" .. result.successful_actions .. "/" .. result.total_actions .. " successful)", vim.log.levels.INFO)
            else
                vim.notify("AI agent executed sequence with errors (" .. result.successful_actions .. "/" .. result.total_actions .. " successful)", vim.log.levels.WARN)
            end
        end, opts = {nargs = "*"}},
        
        -- Connection management commands
        {name = "ParagonicReconnect", func = function()
            local success = M.force_reconnect()
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
    M._setup_keymaps()
    
    -- Load persistent data asynchronously to avoid startup delay
    vim.defer_fn(function()
        M._load_persistent_data()
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

-- AI agent session functions - delegate to ai_agent module
-- AI agent session functions - delegate to ai_agent module
function M.start_ai_agent_session(agent_name, capabilities)
    return ai_agent.start_ai_agent_session(agent_name, capabilities)
end

function M.stop_ai_agent_session()
    return ai_agent.stop_ai_agent_session()
end

-- AI agent message functions - delegate to ai_agent module
function M.send_ai_agent_message(message, message_type)
    return ai_agent.send_ai_agent_message(message, message_type)
end

function M.receive_ai_agent_message(message, message_type)
    return ai_agent.receive_ai_agent_message(message, message_type)
end

-- AI agent command function - delegate to ai_agent module
function M.execute_ai_agent_command(command, description)
    return ai_agent.execute_ai_agent_command(command, description)
end

-- AI agent buffer content function - delegate to ai_agent module
function M.get_ai_agent_buffer_content(buffer_id, start_line, end_line)
    return ai_agent.get_ai_agent_buffer_content(buffer_id, start_line, end_line)
end

-- AI agent buffer content setter - delegate to ai_agent module
function M.set_ai_agent_buffer_content(buffer_id, lines, start_line, end_line)
    return ai_agent.set_ai_agent_buffer_content(buffer_id, lines, start_line, end_line)
end

-- AI Agent Action Functions for Enhanced Collaboration

-- AI agent buffer switch function - delegate to ai_agent module
function M.ai_agent_switch_buffer(buffer_id)
    return ai_agent.ai_agent_switch_buffer(buffer_id)
end

-- AI agent cursor setter - delegate to ai_agent module
function M.ai_agent_set_cursor(line, column)
    return ai_agent.ai_agent_set_cursor(line, column)
end

-- AI agent window creator - delegate to ai_agent module
function M.ai_agent_create_window(split_type, buffer_id)
    return ai_agent.ai_agent_create_window(split_type, buffer_id)
end

-- AI agent text inserter - delegate to ai_agent module
function M.ai_agent_insert_text(text, mode)
    return ai_agent.ai_agent_insert_text(text, mode)
end

-- AI agent state getter - delegate to ai_agent module
function M.ai_agent_get_state()
    return ai_agent.ai_agent_get_state()
end

-- AI agent sequence executor - delegate to ai_agent module
function M.ai_agent_execute_sequence(actions)
    return ai_agent.ai_agent_execute_sequence(actions)
end

-- Event handling functions - delegate to events module
function M.register_buffer_change_handler(handler)
    return events.register_buffer_change_handler(handler)
end

function M.register_cursor_movement_handler(handler)
    return events.register_cursor_movement_handler(handler)
end

function M.register_window_change_handler(handler)
    return events.register_window_change_handler(handler)
end

-- Event trigger functions - delegate to events module
function M.trigger_buffer_change_event(buffer_id, change_type)
    return events.trigger_buffer_change_event(buffer_id, change_type)
end

function M.trigger_cursor_movement_event(line, column)
    return events.trigger_cursor_movement_event(line, column)
end

function M.trigger_window_change_event(window_id, change_type)
    return events.trigger_window_change_event(window_id, change_type)
end

-- Event setup functions - delegate to events module
function M.setup_buffer_change_autocommands()
    return events.setup_buffer_change_autocommands()
end

function M.setup_cursor_movement_autocommands()
    return events.setup_cursor_movement_autocommands()
end

function M.setup_window_change_autocommands()
    return events.setup_window_change_autocommands()
end

function M.setup_all_event_autocommands()
    return events.setup_all_event_autocommands()
end

-- AI Agent Session Integration Functions (TDD Implementation)

-- Session-aware event handler - delegate to events module
function M.register_session_aware_handler(event_type, handler)
    return events.register_session_aware_handler(event_type, handler)
end

-- Track event in session
function M.track_event_in_session(event_type, event_data)
    if not agent_collaboration_mode or not active_agent_id then
        return false, "No active AI agent session"
    end
    
    local session = ai_agent_sessions[active_agent_id]
    if not session then
        return false, "Session data not found"
    end
    
    -- Create event tracking object
    local event_obj = {
        id = #session.interactions + 1,
        timestamp = os.time(),
        type = "event",
        event_type = event_type,
        event_data = event_data,
        from_agent = false,
        status = "tracked"
    }
    
    -- Add to session interactions
    table.insert(session.interactions, event_obj)
    
    -- Update session context
    session.context = {
        current_file = vim.fn.expand("%"),
        current_directory = vim.fn.getcwd(),
        buffer_count = #vim.api.nvim_list_bufs(),
        mode = vim.fn.mode()
    }
    
    return true, "Event tracked in session successfully"
end

-- Get session event history
function M.get_session_event_history()
    if not agent_collaboration_mode or not active_agent_id then
        return false, "No active AI agent session"
    end
    
    local session = ai_agent_sessions[active_agent_id]
    if not session then
        return false, "Session data not found"
    end
    
    -- Filter interactions to only include events
    local event_history = {}
    for _, interaction in ipairs(session.interactions) do
        if interaction.type == "event" then
            table.insert(event_history, {
                id = interaction.id,
                timestamp = interaction.timestamp,
                event_type = interaction.event_type,
                event_data = interaction.event_data,
                status = interaction.status
            })
        end
    end
    
    return true, event_history
end

-- AI agent session status getter - delegate to ai_agent module
function M.get_ai_agent_session_status()
    return ai_agent.get_ai_agent_session_status()
end

-- Send message - delegate to chat module
function M.send_message(message, model)
    return chat.send_message(message, model)
end

-- Enhanced send message - delegate to chat module
function M.send_message_enhanced(message, model)
    return chat.send_message_enhanced(message, model)
end

-- Debug buffer management
local debug_buffer = nil

-- Debug print function - delegate to debug module
function M.debug_print(message, level)
    return debug.debug_print(message, level)
end

-- Debug buffer functions - delegate to debug module
function M.get_or_create_debug_buffer()
    return debug.get_or_create_debug_buffer()
end

function M.open_debug_buffer()
    return debug.open_debug_buffer()
end

function M.append_debug_message(buffer, message, level)
    return debug.append_debug_message(buffer, message, level)
end

-- Backend API functions - delegate to backend module
function M.get_available_models()
    return backend.get_available_models()
end

function M.get_projects()
    return backend.get_projects()
end

function M.create_project(name, description)
    return backend.create_project(name, description)
end

function M.get_config()
    return backend.get_config()
end

function M.save_config(config_data)
    return backend.save_config(config_data)
end

-- JSON parsing helpers - delegate to utils module
function M.parse_json_response(json_string)
    return utils.parse_json_response(json_string)
end

function M.parse_json_response_enhanced(input)
    return utils.parse_json_response_enhanced(input)
end

-- Backend initialization functions - delegate to backend module
function M._initialize_backend()
    return backend.initialize_backend()
end

function M.force_reconnect()
    return backend.force_reconnect()
end

-- Manually initialize backend when needed
function M.initialize_backend()
    if not M._rpc_client then
        M._initialize_backend()
    end
    return M._rpc_client ~= nil
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
    
    -- Stop progress updates
    if progress_timer then
        progress_timer:stop()
        progress_timer:close()
    end
    
    if not response then
        -- Update the status message to show failure
        M.append_debug_message(current_buf, "Failed to send message: " .. (err or "unknown error"), "error")
        vim.notify("Failed to send message: " .. (err or "unknown error"), vim.log.levels.ERROR)
        
        -- Add error message to chat buffer with error symbol
        local error_lines = {
            "🛔  " .. (err or "unknown error")
        }
        vim.api.nvim_buf_set_lines(current_buf, line_num + 2, line_num + 2, false, error_lines)
        return
    end
    
    -- Calculate timing information
    local end_time = vim.uv.now()
    local duration_ms = end_time - start_time
    local duration_sec = duration_ms / 1000
    
    -- Update the status message to show success
    M.append_debug_message(current_buf, "Message sent successfully, processing response...", "success")
    
    -- Add the response to the buffer
    -- Split response into lines to handle multi-line responses
    local response_content_lines = {}
    for line in response:gmatch("[^\r\n]+") do
        if line:match("%S") then  -- Only add non-empty lines
            table.insert(response_content_lines, line)
        end
    end
    
    -- If no lines were extracted, add the original response as a single line
    if #response_content_lines == 0 then
        table.insert(response_content_lines, response)
    end
    
    local response_lines = {}
    
    -- Get buffer width for word wrapping (70% of buffer width after indentation)
    local full_buffer_width = vim.api.nvim_win_get_width(0)
    local base_width = math.floor(full_buffer_width * 0.7)
    if base_width < 20 then base_width = 20 end -- Minimum width
    
    -- Add first line with diamond prefix and remaining lines with three-space indent
    if #response_content_lines > 0 then
        local wrapped_first = wrap_text_with_diamond(response_content_lines[1], base_width)
        for _, line in ipairs(wrapped_first) do
            table.insert(response_lines, line)
        end
        
        -- Add remaining lines with three spaces indentation
        for i = 2, #response_content_lines do
            local wrapped_lines = wrap_text(response_content_lines[i], base_width, "   ")
            for _, line in ipairs(wrapped_lines) do
                table.insert(response_lines, line)
            end
        end
    else
        -- If no content, just add the diamond
        table.insert(response_lines, "🮮")
    end
    
    -- Add timing information
    table.insert(response_lines, "")
    table.insert(response_lines, "   ⏱️  " .. string.format("%.2fs", duration_sec))
    
    -- Add closing lines
    table.insert(response_lines, "")
    table.insert(response_lines, "∎")
    
    -- Insert response after the zigzag arrow (line_num + 2 since zigzag is at line_num + 1)
    vim.api.nvim_buf_set_lines(current_buf, line_num + 2, line_num + 2, false, response_lines)
    
    -- Move cursor to the end of the buffer (safe positioning)
    local buffer_line_count = vim.api.nvim_buf_line_count(current_buf)
    vim.api.nvim_win_set_cursor(0, {buffer_line_count, 0})
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

function M._save_search_history()
    return utils.save_search_history(search_history, history_file)
end

function M._load_search_history()
    return utils.load_search_history(history_file)
end

function M._save_saved_searches()
    return utils.save_saved_searches(saved_searches, saved_searches_file)
end

function M._load_saved_searches()
    return utils.load_saved_searches(saved_searches_file)
end

-- Load all persistent data with error handling
function M._load_persistent_data()
    return utils.load_persistent_data(search_history, saved_searches)
end

-- Auto-save function
function M._auto_save()
    return utils.auto_save(search_history, saved_searches)
end

-- Export data to a file
function M.export_data()
    return utils.export_data(search_history, saved_searches)
end

-- Import data from a file
function M.import_data()
    return utils.import_data(search_history, saved_searches)
end

-- Backup data
function M.backup_data()
    return utils.backup_data(search_history, saved_searches)
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

-- Get file content from current session
function M.agent_get_file_content(file_path)
    if not file_path or file_path == "" then
        return nil, "File path is required"
    end
    
    -- Find buffer by file path
    local target_buffer = nil
    local buffers = vim.api.nvim_list_bufs()
    
    for _, buf in ipairs(buffers) do
        local buf_name = vim.api.nvim_buf_get_name(buf)
        if buf_name == file_path then
            target_buffer = buf
            break
        end
    end
    
    if not target_buffer then
        return nil, "File not found in current session: " .. file_path
    end
    
    -- Get file content
    local lines = vim.api.nvim_buf_get_lines(target_buffer, 0, -1, false)
    return {
        file_path = file_path,
        buffer_id = target_buffer,
        line_count = #lines,
        content = lines
    }
end

-- Agent file creator - delegate to ai_agent module
function M.agent_create_file(args)
    return ai_agent.agent_create_file(args)
end

-- Create a file with a template
function M.agent_create_file_with_template(template_name, file_name)
    local templates = {
        lua = {
            header = "--[[",
            footer = "--]]",
            content = "local M = {}\n\nreturn M"
        },
        rust = {
            header = "//",
            footer = "",
            content = "fn main() {\n    println!(\"Hello, world!\");\n}"
        },
        markdown = {
            header = "#",
            footer = "",
            content = "# Title\n\nContent goes here."
        }
    }
    
    local template = templates[template_name]
    if not template then
        return false, "Unknown template: " .. template_name
    end
    
    local content = template.content
    if template.header ~= "" then
        content = template.header .. " " .. file_name .. "\n" .. content
    end
    if template.footer ~= "" then
        content = content .. "\n" .. template.footer
    end
    
    return M.agent_create_file({file_name, content})
end

-- Agent file saver - delegate to ai_agent module
function M.agent_save_file(args)
    return ai_agent.agent_save_file(args)
end

-- Save all modified files
function M.agent_save_all_files()
    local buffers = vim.api.nvim_list_bufs()
    local saved_count = 0
    local failed_count = 0
    
    for _, buf in ipairs(buffers) do
        local buf_name = vim.api.nvim_buf_get_name(buf)
        local modified = vim.api.nvim_buf_get_option(buf, "modified")
        
        if buf_name ~= "" and modified then
            local success = M.agent_save_file({buf_name})
            if success then
                saved_count = saved_count + 1
            else
                failed_count = failed_count + 1
            end
        end
    end
    
    if saved_count > 0 then
        vim.notify("Saved " .. saved_count .. " files", vim.log.levels.INFO)
    end
    if failed_count > 0 then
        vim.notify("Failed to save " .. failed_count .. " files", vim.log.levels.WARN)
    end
    
    return saved_count, failed_count
end

-- Save file with backup
function M.agent_save_with_backup(args)
    local file_path = args[1]
    local create_backup = args[2] == "true"
    
    if create_backup and file_path then
        local backup_path = file_path .. ".backup"
        local success = M.agent_save_file({file_path})
        if success then
            -- Create backup by copying the file
            local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), 0, -1, false)
            vim.fn.writefile(lines, backup_path)
            vim.notify("Created backup: " .. backup_path, vim.log.levels.INFO)
        end
        return success
    else
        return M.agent_save_file(args)
    end
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
        
        -- Start progress
        progress_id, start_notification = M.start_progress_operation("file_edit", "Editing file: " .. file_path)
        table.insert(progress_notifications, start_notification)
        
        -- Find buffer by file path
        local target_buf = nil
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            local buf_name = vim.api.nvim_buf_get_name(buf)
            if buf_name == file_path then
                target_buf = buf
                break
            end
        end
        
        if not target_buf then
            M.complete_progress_operation(progress_id, "Error: File not found")
            return {
                id = id,
                error = {
                    code = -32602,
                    message = "File not found in session: " .. file_path
                }
            }
        end
        
        -- Update progress
        local update_notification = M.update_progress(progress_id, "Found file, performing edit...", 50)
        table.insert(progress_notifications, update_notification)
        
        -- Check if buffer is modifiable
        if not vim.api.nvim_buf_get_option(target_buf, "modifiable") then
            M.complete_progress_operation(progress_id, "Error: File not modifiable")
            return {
                id = id,
                error = {
                    code = -32602,
                    message = "File is not modifiable: " .. file_path
                }
            }
        end
        
        -- Perform the edit
        vim.api.nvim_set_current_buf(target_buf)
        vim.api.nvim_buf_set_lines(target_buf, line_number - 1, line_number, false, {content})
        
        -- Complete progress
        local complete_notification = M.complete_progress_operation(progress_id, "File edit completed successfully")
        table.insert(progress_notifications, complete_notification)
        
        return {
            id = id,
            result = {
                content = {
                    {
                        type = "text",
                        text = "Successfully edited file: " .. file_path .. " at line " .. line_number
                    }
                },
                metadata = {
                    file_path = file_path,
                    line_number = line_number,
                    content_length = #content,
                    timestamp = os.time(),
                    progress_notifications = progress_notifications
                }
            }
        }
        
    elseif tool_name == "agent_create_file" then
        local file_name = arguments.file_name
        local content = arguments.content or ""
        local open_in_window = arguments.open_in_window or false
        
        if not file_name then
            return {
                id = id,
                error = {
                    code = -32602,
                    message = "file_name is required for agent_create_file"
                }
            }
        end
        
        -- Start progress
        progress_id, start_notification = M.start_progress_operation("file_create", "Creating file: " .. file_name)
        table.insert(progress_notifications, start_notification)
        
        -- Check if file already exists
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            local buf_name = vim.api.nvim_buf_get_name(buf)
            if buf_name == file_name then
                M.complete_progress_operation(progress_id, "Error: File already exists")
                return {
                    id = id,
                    error = {
                        code = -32602,
                        message = "File already exists: " .. file_name
                    }
                }
            end
        end
        
        -- Update progress
        local update_notification = M.update_progress(progress_id, "Creating new buffer...", 50)
        table.insert(progress_notifications, update_notification)
        
        -- Create new buffer
        local new_buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_name(new_buf, file_name)
        vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, {content})
        
        if open_in_window then
            vim.api.nvim_open_win(new_buf, true, {relative = "editor", width = 80, height = 20, row = 1, col = 1})
        else
            vim.api.nvim_set_current_buf(new_buf)
        end
        
        -- Complete progress
        local complete_notification = M.complete_progress_operation(progress_id, "File created successfully")
        table.insert(progress_notifications, complete_notification)
        
        return {
            id = id,
            result = {
                content = {
                    {
                        type = "text",
                        text = "Successfully created file: " .. file_name
                    }
                },
                metadata = {
                    file_name = file_name,
                    buffer_id = new_buf,
                    content_length = #content,
                    opened_in_window = open_in_window,
                    timestamp = os.time(),
                    progress_notifications = progress_notifications
                }
            }
        }
        
    elseif tool_name == "agent_save_file" then
        local file_path = arguments.file_path
        local force = arguments.force or false
        
        -- Start progress
        progress_id, start_notification = M.start_progress_operation("file_save", "Saving file: " .. (file_path or "current file"))
        table.insert(progress_notifications, start_notification)
        
        local target_buf = nil
        if file_path then
            -- Save specific file
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                local buf_name = vim.api.nvim_buf_get_name(buf)
                if buf_name == file_path then
                    target_buf = buf
                    break
                end
            end
            
            if not target_buf then
                M.complete_progress_operation(progress_id, "Error: File not found")
                return {
                    id = id,
                    error = {
                        code = -32602,
                        message = "File not found in session: " .. file_path
                    }
                }
            end
        else
            -- Save current file
            target_buf = vim.api.nvim_get_current_buf()
            file_path = vim.api.nvim_buf_get_name(target_buf)
        end
        
        -- Update progress
        local update_notification = M.update_progress(progress_id, "Checking file status...", 30)
        table.insert(progress_notifications, update_notification)
        
        -- Check if file is modified
        if not force and not vim.api.nvim_buf_get_option(target_buf, "modified") then
            M.complete_progress_operation(progress_id, "File is not modified")
            return {
                id = id,
                result = {
                    content = {
                        {
                            type = "text",
                            text = "File is not modified: " .. file_path
                        }
                    },
                    metadata = {
                        file_path = file_path,
                        modified = false,
                        timestamp = os.time(),
                        progress_notifications = progress_notifications
                    }
                }
            }
        end
        
        -- Update progress
        local save_notification = M.update_progress(progress_id, "Writing file to disk...", 70)
        table.insert(progress_notifications, save_notification)
        
        -- Save the file
        local lines = vim.api.nvim_buf_get_lines(target_buf, 0, -1, false)
        local dir_path = vim.fn.fnamemodify(file_path, ":h")
        
        if not vim.fn.isdirectory(dir_path) then
            vim.fn.mkdir(dir_path, "p")
        end
        
        vim.fn.writefile(lines, file_path)
        vim.cmd("set nomodified")
        
        -- Complete progress
        local complete_notification = M.complete_progress_operation(progress_id, "File saved successfully")
        table.insert(progress_notifications, complete_notification)
        
        return {
            id = id,
            result = {
                content = {
                    {
                        type = "text",
                        text = "Successfully saved file: " .. file_path
                    }
                },
                metadata = {
                    file_path = file_path,
                    lines_saved = #lines,
                    directory_created = not vim.fn.isdirectory(dir_path),
                    timestamp = os.time(),
                    progress_notifications = progress_notifications
                }
            }
        }
        
    else
        return {
            id = id,
            error = {
                code = -32601,
                message = "Tool not found: " .. tool_name
            }
        }
    end
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

-- Integrate with MCP resource listing
local old_list_mcp_resources = M.list_mcp_resources
function M.list_mcp_resources()
    local resources = old_list_mcp_resources and old_list_mcp_resources() or {}
    table.insert(resources, {
        uri = "neovim://configuration",
        name = "Neovim Configuration",
        description = "Current configuration settings and schema",
        mime_type = "application/json"
    })
    table.insert(resources, {
        uri = "neovim://commands",
        name = "Neovim Commands",
        description = "List of all available commands",
        mime_type = "application/json"
    })
    table.insert(resources, {
        uri = "neovim://autocommands",
        name = "Neovim Autocommands",
        description = "List of all autocommands",
        mime_type = "application/json"
    })
    return resources
end

-- Integrate with MCP resource reading
local old_read_mcp_resource = M.read_mcp_resource
function M.read_mcp_resource(uri)
    if uri == "neovim://configuration" then
        return {
            contents = {
                {
                    uri = uri,
                    mime_type = "application/json",
                    text = vim.json.encode(M.get_configuration_as_resource())
                }
            }
        }
    elseif uri == "neovim://commands" then
        return {
            contents = {
                {
                    uri = uri,
                    mime_type = "application/json",
                    text = vim.json.encode(M.get_commands_info())
                }
            }
        }
    elseif uri == "neovim://autocommands" then
        return {
            contents = {
                {
                    uri = uri,
                    mime_type = "application/json",
                    text = vim.json.encode(M.get_autocommands_info())
                }
            }
        }
    end
    if old_read_mcp_resource then
        return old_read_mcp_resource(uri)
    end
    return { error = { code = -32601, message = "Unknown resource URI: " .. tostring(uri) } }
end

-- Integrate with MCP message handler
-- MCP message handler - delegate to mcp module
function M.handle_mcp_message(message)
    return mcp.handle_mcp_message(message)
end

-- System info functions - delegate to mcp module
function M.get_commands_info()
    return mcp.get_commands_info()
end

function M.get_autocommands_info()
    return mcp.get_autocommands_info()
end

-- Sample resource content - delegate to mcp module
function M.sample_resource(uri, criteria)
    return mcp.sample_resource(uri, criteria)
end

-- Define resource roots - delegate to mcp module
function M.define_resource_roots(uri, options)
    return mcp.define_resource_roots(uri, options)
end

-- Handle MCP sampling requests - delegate to mcp module
function M.handle_sampling_request(request)
    return mcp.handle_sampling_request(request)
end
                    criteria = criteria,
                    sample_size = type(sampled_data) == "table" and #sampled_data or 1,
                    timestamp = os.time()
                }
            }
        }
    else
        return {
            id = request.id,
            error = {
                code = -32602,
                message = "Failed to sample resource: " .. uri
            }
        }
    end
end

-- Handle MCP roots requests from external agents
function M.handle_roots_request(request)
    local uri = request.uri
    local options = request.options or {}
    
    local roots = M.define_resource_roots(uri, options)
    
    return {
        id = request.id,
        result = {
            roots = roots,
            metadata = {
                uri = uri,
                options = options,
                root_count = #roots,
                timestamp = os.time()
            }
        }
    }
end

-- Extend MCP message handler for sampling and roots
-- MCP message handler with sampling and roots - delegate to mcp module
function M.handle_mcp_message(message)
    return mcp.handle_mcp_message(message)
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

-- Enhanced tool call with cancellation support
-- Handle MCP tool calls with cancellation - delegate to mcp module
function M.handle_tool_call_with_cancellation(id, params)
    return mcp.handle_tool_call_with_cancellation(id, params)
end
        local content = arguments.content or ""
        
        if not file_path then
            M.complete_operation(operation_id)
            return {
                id = id,
                error = {
                    code = -32602,
                    message = "file_path is required for agent_edit_file"
                }
            }
        end
        
        -- Check for cancellation before starting
        if M.is_operation_cancelled(operation_id) then
            M.complete_operation(operation_id)
            return {
                id = id,
                error = {
                    code = -32800,
                    message = "Operation cancelled before start"
                }
            }
        end
        
        -- Find buffer by file path
        local target_buf = nil
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            -- Check for cancellation during search
            if M.is_operation_cancelled(operation_id) then
                M.complete_operation(operation_id)
                return {
                    id = id,
                    error = {
                        code = -32800,
                        message = "Operation cancelled during file search"
                    }
                }
            end
            
            local buf_name = vim.api.nvim_buf_get_name(buf)
            if buf_name == file_path then
                target_buf = buf
                break
            end
        end
        
        if not target_buf then
            M.complete_operation(operation_id)
            return {
                id = id,
                error = {
                    code = -32602,
                    message = "File not found in session: " .. file_path
                }
            }
        end
        
        -- Check for cancellation before edit
        if M.is_operation_cancelled(operation_id) then
            M.complete_operation(operation_id)
            return {
                id = id,
                error = {
                    code = -32800,
                    message = "Operation cancelled before edit"
                }
            }
        end
        
        -- Perform the edit
        vim.api.nvim_set_current_buf(target_buf)
        vim.api.nvim_buf_set_lines(target_buf, line_number - 1, line_number, false, {content})
        
        M.complete_operation(operation_id)
        return {
            id = id,
            result = {
                content = {
                    {
                        type = "text",
                        text = "Successfully edited file: " .. file_path .. " at line " .. line_number
                    }
                },
                metadata = {
                    file_path = file_path,
                    line_number = line_number,
                    content_length = #content,
                    timestamp = os.time(),
                    operation_id = operation_id
                }
            }
        }
    else
        M.complete_operation(operation_id)
        return {
            id = id,
            error = {
                code = -32601,
                message = "Tool not found: " .. tool_name
            }
        }
    end
end

-- Handle MCP cancellation messages
function M.handle_cancellation_message(message)
    if message.method == "cancel" then
        local operation_id = message.params.operation_id
        if operation_id then
            local cancelled = M.cancel_operation(operation_id)
            if cancelled then
                return {
                    id = message.id,
                    result = {
                        cancelled = true,
                        message = "Operation cancelled successfully"
                    }
                }
            else
                return {
                    id = message.id,
                    error = {
                        code = -32602,
                        message = "Operation not found: " .. operation_id
                    }
                }
            end
        else
            return {
                id = message.id,
                error = {
                    code = -32602,
                    message = "Operation ID is required for cancellation"
                }
            }
        end
    elseif message.method == "cancel/list" then
        local active_operations = {}
        for op_id, op in pairs(M.cancellation_state.active_operations) do
            table.insert(active_operations, {
                operation_id = op_id,
                type = op.type,
                description = op.description,
                start_time = op.start_time,
                cancelled = op.cancelled
            })
        end
        return {
            id = message.id,
            result = {
                operations = active_operations
            }
        }
    else
        return {
            id = message.id,
            error = {
                code = -32601,
                message = "Unknown cancellation method: " .. tostring(message.method)
            }
        }
    end
end

-- MCP message handler with cancellation - delegate to mcp module
function M.handle_mcp_message(message)
    return mcp.handle_mcp_message(message)
end

return M 