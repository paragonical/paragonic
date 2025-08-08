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

-- Word wrapping helper function
local function wrap_text(text, max_width, indent)
    if not text or text == "" then
        return {}
    end
    
    indent = indent or ""
    local lines = {}
    
    -- Split text into lines and detect paragraph breaks
    local text_lines = {}
    for line in text:gmatch("[^\r\n]+") do
        table.insert(text_lines, line)
    end
    
    -- Process each line as a potential paragraph
    for i, line in ipairs(text_lines) do
        if line:match("%S") then  -- Only process non-empty lines
            -- Strip leading spaces from the line
            local clean_line = line:match("^%s*(.+)$")
            local words = {}
            
            -- Split clean line into words
            for word in clean_line:gmatch("[^%s]+") do
                table.insert(words, word)
            end
            
            local current_line = indent
            local current_length = #indent
            
            for i, word in ipairs(words) do
                local word_length = #word
                
                -- If adding this word would exceed the line limit
                if current_length + word_length > max_width then
                    -- Add current line to lines (if not empty)
                    if current_line ~= indent then
                        table.insert(lines, current_line)
                    end
                    -- Start new line with indent
                    current_line = indent .. word
                    current_length = #indent + word_length
                else
                    -- Add word to current line (with space if not first word)
                    if current_line ~= indent then
                        current_line = current_line .. " " .. word
                        current_length = current_length + 1 + word_length
                    else
                        current_line = current_line .. word
                        current_length = current_length + word_length
                    end
                end
            end
            
            -- Add the last line if it has content
            if current_line ~= indent then
                table.insert(lines, current_line)
            end
            
            -- Check if we should add a blank line after this paragraph
            local should_add_blank = false
            
            -- Add blank line if this is not the last line
            if i < #text_lines then
                local next_line = text_lines[i + 1]
                if next_line and next_line:match("%S") then
                    -- Check if next line starts a new paragraph type
                    local next_clean = next_line:match("^%s*(.+)$")
                    
                    -- Add blank line if next line is a numbered list item
                    if next_clean and next_clean:match("^%d+%.") then
                        should_add_blank = true
                    -- Add blank line if next line starts with common paragraph starters
                    elseif next_clean and (next_clean:match("^The ") or 
                                         next_clean:match("^This ") or 
                                         next_clean:match("^These ") or
                                         next_clean:match("^In ") or
                                         next_clean:match("^When ") or
                                         next_clean:match("^While ") or
                                         next_clean:match("^However ") or
                                         next_clean:match("^Additionally ") or
                                         next_clean:match("^Furthermore ") or
                                         next_clean:match("^Moreover ")) then
                        should_add_blank = true
                    end
                end
            end
            
            if should_add_blank then
                table.insert(lines, "")
            end
        end
    end
    
    return lines
end

-- Word wrapping helper function for first line with diamond
local function wrap_text_with_diamond(text, max_width)
    if not text or text == "" then
        return {"🮮"}
    end
    
    local lines = {}
    
    -- Split text into lines and detect paragraph breaks
    local text_lines = {}
    for line in text:gmatch("[^\r\n]+") do
        table.insert(text_lines, line)
    end
    
    -- Process each line as a potential paragraph
    for i, line in ipairs(text_lines) do
        if line:match("%S") then  -- Only process non-empty lines
            -- Strip leading spaces from the line
            local clean_line = line:match("^%s*(.+)$")
            local words = {}
            
            -- Split clean line into words
            for word in clean_line:gmatch("[^%s]+") do
                table.insert(words, word)
            end
            
            local current_line = "🮮  "
            local current_length = 3  -- Length of diamond + two spaces
            
            for i, word in ipairs(words) do
                local word_length = #word
                
                -- If adding this word would exceed the line limit
                if current_length + word_length > max_width then
                    -- Add current line to lines (if not empty)
                    if current_line ~= "🮮  " then
                        table.insert(lines, current_line)
                    end
                    -- Start new line with three spaces (no diamond)
                    current_line = "   " .. word
                    current_length = 3 + word_length
                else
                    -- Add word to current line (with space if not first word)
                    if current_line ~= "🮮  " then
                        current_line = current_line .. " " .. word
                        current_length = current_length + 1 + word_length
                    else
                        current_line = current_line .. word
                        current_length = current_length + word_length
                    end
                end
            end
            
            -- Add the last line if it has content
            if current_line ~= "🮮  " then
                table.insert(lines, current_line)
            end
            
            -- Check if we should add a blank line after this paragraph
            local should_add_blank = false
            
            -- Add blank line if this is not the last line
            if i < #text_lines then
                local next_line = text_lines[i + 1]
                if next_line and next_line:match("%S") then
                    -- Check if next line starts a new paragraph type
                    local next_clean = next_line:match("^%s*(.+)$")
                    
                    -- Add blank line if next line is a numbered list item
                    if next_clean and next_clean:match("^%d+%.") then
                        should_add_blank = true
                    -- Add blank line if next line starts with common paragraph starters
                    elseif next_clean and (next_clean:match("^The ") or 
                                         next_clean:match("^This ") or 
                                         next_clean:match("^These ") or
                                         next_clean:match("^In ") or
                                         next_clean:match("^When ") or
                                         next_clean:match("^While ") or
                                         next_clean:match("^However ") or
                                         next_clean:match("^Additionally ") or
                                         next_clean:match("^Furthermore ") or
                                         next_clean:match("^Moreover ")) then
                        should_add_blank = true
                    end
                end
            end
            
            if should_add_blank then
                table.insert(lines, "")
            end
        end
    end
    
    return lines
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
    
    -- Create commands
    vim.api.nvim_create_user_command("ParagonicChat", M.open_chat, {})
vim.api.nvim_create_user_command("ParagonicProjects", M.open_projects, {})
vim.api.nvim_create_user_command("ParagonicConfig", M.open_config, {})
vim.api.nvim_create_user_command("ParagonicDebug", M.open_debug_buffer, {})
    vim.api.nvim_create_user_command("ParagonicSend", function()
        M.debug_print("WRAPPER: About to call send_message_command", "debug")
        M.send_message_command()
        M.debug_print("WRAPPER: send_message_command completed", "debug")
    end, {})
    vim.api.nvim_create_user_command("ParagonicSendDebug", M.send_message_command_debug, {})
    vim.api.nvim_create_user_command("ParagonicTest", function()
        M.debug_print("TEST COMMAND WORKING", "debug")
        vim.notify("TEST COMMAND WORKING", vim.log.levels.INFO)
    end, {})
    
    vim.api.nvim_create_user_command("ParagonicCreateProject", M.create_project_command, {})
    vim.api.nvim_create_user_command("ParagonicSaveConfig", M.save_config_command, {})
    
    -- Search commands
    vim.api.nvim_create_user_command("ParagonicSearch", M.search_command, {nargs = "*"})
    vim.api.nvim_create_user_command("ParagonicSearchFiltered", M.search_filtered_command, {nargs = "*"})
    vim.api.nvim_create_user_command("ParagonicSearchHybrid", M.search_hybrid_command, {nargs = "*"})
    
    -- Search history and saved searches commands
    vim.api.nvim_create_user_command("ParagonicSearchHistory", M.show_search_history, {})
    vim.api.nvim_create_user_command("ParagonicSavedSearches", M.show_saved_searches, {})
    vim.api.nvim_create_user_command("ParagonicSaveSearch", M.save_current_search, {})
    
    -- Persistent storage commands
    vim.api.nvim_create_user_command("ParagonicExportData", M.export_data, {})
    vim.api.nvim_create_user_command("ParagonicImportData", M.import_data, {})
    vim.api.nvim_create_user_command("ParagonicBackupData", M.backup_data, {})
    
    -- Agentic collaboration commands
    vim.api.nvim_create_user_command("ParagonicAgentSession", M.get_agent_session_info, {})
    vim.api.nvim_create_user_command("ParagonicAgentEdit", M.agent_edit_file, {nargs = "*"})
    vim.api.nvim_create_user_command("ParagonicAgentCreate", M.agent_create_file, {nargs = "*"})
    vim.api.nvim_create_user_command("ParagonicAgentSave", M.agent_save_file, {})
    
    -- MCP commands
    vim.api.nvim_create_user_command("ParagonicMCPInit", M.initialize_mcp_server, {})
    vim.api.nvim_create_user_command("ParagonicMCPResources", function() 
        local resources = M.list_mcp_resources()
        M.display_mcp_resources(resources)
    end, {})
    vim.api.nvim_create_user_command("ParagonicMCPTools", function()
        local tools = M.list_mcp_tools()
        M.display_mcp_tools(tools)
    end, {})
    vim.api.nvim_create_user_command("ParagonicMCPReadResource", function(args)
        local uri = args[1] or "neovim://session"
        local result = M.read_mcp_resource(uri)
        M.display_resource_content(uri, result)
    end, {nargs = "?"})
    
    -- MCP Client commands (sampling and roots)
    vim.api.nvim_create_user_command("ParagonicMCPSample", function(args)
        local uri = args[1] or "neovim://buffers"
        local limit = tonumber(args[2]) or 5
        local criteria = {limit = limit}
        local result = M.sample_resource(uri, criteria)
        M.display_sampled_content(uri, result, criteria)
    end, {nargs = "*"})
    vim.api.nvim_create_user_command("ParagonicMCPRoots", function(args)
        local uri = args[1] or "neovim://buffers"
        local roots = M.define_resource_roots(uri, {})
        M.display_resource_roots(uri, roots)
    end, {nargs = "?"})
    
    -- AI Agent collaboration commands
    vim.api.nvim_create_user_command("ParagonicAIAgentStart", function(args)
        local agent_name = args[1] or "AI Agent"
        local session_id = M.start_ai_agent_session(agent_name)
        if session_id then
            vim.notify("AI agent session started: " .. session_id, vim.log.levels.INFO)
        end
    end, {nargs = "?"})
    vim.api.nvim_create_user_command("ParagonicAIAgentStop", function()
        local success = M.stop_ai_agent_session()
        if success then
            vim.notify("AI agent session stopped successfully", vim.log.levels.INFO)
        end
    end, {})
    vim.api.nvim_create_user_command("ParagonicAIAgentStatus", function()
        local status = M.get_ai_agent_session_status()
        M.display_ai_agent_status(status)
    end, {})
    vim.api.nvim_create_user_command("ParagonicAIAgentMessage", function(args)
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
    end, {nargs = "*"})
    vim.api.nvim_create_user_command("ParagonicAIAgentReceive", function(args)
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
    end, {nargs = "*"})
    vim.api.nvim_create_user_command("ParagonicAIAgentCommand", function(args)
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
    end, {nargs = "*"})
    vim.api.nvim_create_user_command("ParagonicAIAgentBuffer", function(args)
        local buffer_id = tonumber(args[1])
        local start_line = tonumber(args[2])
        local end_line = tonumber(args[3])
        
        local success, action_id, result = M.get_ai_agent_buffer_content(buffer_id, start_line, end_line)
        if success then
            vim.notify("AI agent buffer read (ID: " .. action_id .. ", " .. result.line_count .. " lines)", vim.log.levels.INFO)
        else
            vim.notify("Failed to read buffer: " .. action_id, vim.log.levels.ERROR)
        end
    end, {nargs = "*"})
    vim.api.nvim_create_user_command("ParagonicAIAgentBufferWrite", function(args)
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
    end, {nargs = "*"})
    
    -- Enhanced AI Agent Action Commands
    vim.api.nvim_create_user_command("ParagonicAIAgentSwitchBuffer", function(args)
        local buffer_id = tonumber(args[1])
        local success, action_id, result = M.ai_agent_switch_buffer(buffer_id)
        if success then
            vim.notify("AI agent switched to buffer " .. result.buffer_id, vim.log.levels.INFO)
        else
            vim.notify("Failed to switch buffer: " .. action_id, vim.log.levels.ERROR)
        end
    end, {nargs = "?"})
    
    vim.api.nvim_create_user_command("ParagonicAIAgentSetCursor", function(args)
        local line = tonumber(args[1]) or 1
        local column = tonumber(args[2]) or 0
        local success, action_id, result = M.ai_agent_set_cursor(line, column)
        if success then
            vim.notify("AI agent set cursor to line " .. line .. ", column " .. column, vim.log.levels.INFO)
        else
            vim.notify("Failed to set cursor: " .. action_id, vim.log.levels.ERROR)
        end
    end, {nargs = "*"})
    
    vim.api.nvim_create_user_command("ParagonicAIAgentCreateWindow", function(args)
        local split_type = args[1] or "split"
        local buffer_id = tonumber(args[2])
        local success, action_id, result = M.ai_agent_create_window(split_type, buffer_id)
        if success then
            vim.notify("AI agent created " .. split_type .. " window", vim.log.levels.INFO)
        else
            vim.notify("Failed to create window: " .. action_id, vim.log.levels.ERROR)
        end
    end, {nargs = "*"})
    
    vim.api.nvim_create_user_command("ParagonicAIAgentInsertText", function(args)
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
    end, {nargs = "*"})
    
    vim.api.nvim_create_user_command("ParagonicAIAgentGetState", function()
        local success, action_id, state = M.ai_agent_get_state()
        if success then
            vim.notify("AI agent retrieved Neovim state (" .. #state.buffers .. " buffers, " .. #state.windows .. " windows)", vim.log.levels.INFO)
        else
            vim.notify("Failed to get state: " .. action_id, vim.log.levels.ERROR)
        end
    end, {})
    
    vim.api.nvim_create_user_command("ParagonicAIAgentExecuteSequence", function(args)
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
    end, {nargs = "*"})
    
    -- Connection management commands
    vim.api.nvim_create_user_command("ParagonicReconnect", function()
        local success = M.force_reconnect()
        if success then
            vim.notify("Successfully reconnected to Paragonic backend", vim.log.levels.INFO)
        else
            vim.notify("Failed to reconnect to Paragonic backend", vim.log.levels.ERROR)
        end
    end, {})
    
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

function M.get_or_create_debug_buffer()
    -- Check if debug buffer already exists
    if debug_buffer and vim.api.nvim_buf_is_valid(debug_buffer) then
        return debug_buffer
    end
    
    -- Look for existing debug buffer
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(buf)
        if name == "paragonic://debug" then
            debug_buffer = buf
            return debug_buffer
        end
    end
    
    -- Create new debug buffer
    debug_buffer = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(debug_buffer, "paragonic://debug")
    vim.api.nvim_buf_set_option(debug_buffer, "buftype", "nofile")
    vim.api.nvim_buf_set_option(debug_buffer, "swapfile", false)
    vim.api.nvim_buf_set_option(debug_buffer, "modifiable", true)
    vim.api.nvim_buf_set_option(debug_buffer, "filetype", "markdown")
    
    -- Add initial content
    vim.api.nvim_buf_set_lines(debug_buffer, 0, -1, false, {
        "# Paragonic Debug Log",
        "",
        "Debug messages and system information will appear here.",
        "",
        "---"
    })
    
    return debug_buffer
end

function M.open_debug_buffer()
    local debug_buf = M.get_or_create_debug_buffer()
    
    -- Open the buffer in a new window
    vim.api.nvim_command("split")
    vim.api.nvim_set_current_buf(debug_buf)
end

-- Append debug message to debug buffer instead of chat buffer
function M.append_debug_message(buffer, message, level)
    -- Don't debug the debug function itself to avoid infinite loops
    -- print("🔧 append_debug_message() called with buffer=" .. tostring(buffer) .. ", message=" .. tostring(message))
    
    if not message then
        -- Use vim.notify for critical errors to avoid infinite loops
        vim.notify("❌ append_debug_message: Message is required", vim.log.levels.ERROR)
        return false, "Message is required"
    end
    
    -- Get or create debug buffer
    local debug_buf = M.get_or_create_debug_buffer()
    
    -- Validate debug buffer exists
    if not vim.api.nvim_buf_is_valid(debug_buf) then
        vim.notify("❌ append_debug_message: Invalid debug buffer", vim.log.levels.ERROR)
        return false, "Invalid debug buffer"
    end
    
    -- Default level
    level = level or "info"
    
    -- Format debug message with timestamp
    local timestamp = os.date("%H:%M:%S")
    local formatted_message = "**[" .. timestamp .. "] DEBUG [" .. level:upper() .. "]:** " .. message
    
    -- Get current debug buffer lines
    local current_lines = vim.api.nvim_buf_get_lines(debug_buf, 0, -1, false)
    
    -- Append debug message to debug buffer
    vim.api.nvim_buf_set_lines(debug_buf, #current_lines, #current_lines, false, {
        formatted_message
    })
    
    return true, "Debug message appended successfully"
end

-- Get list of available models
function M.get_available_models()
    local rpc_client = M._get_rpc_client()
    if not rpc_client then
        -- Return default models to prevent freezing
        return {"llama2", "llama3.2:3b", "nomic-embed-text:latest"}
    end
    
    -- Get models list with timeout
    local success, response = pcall(function()
        return rpc_client:list_models()
    end)
    
    if not success or not response then
        -- Return default models on failure
        return {"llama2", "llama3.2:3b", "nomic-embed-text:latest"}
    end
    
    -- Parse JSON response
    local parsed_response = M.parse_json_response(response)
    if not parsed_response then
        return {"llama2", "llama3.2:3b", "nomic-embed-text:latest"}
    end
    
    -- Check for error in response
    if parsed_response.error then
        return {"llama2", "llama3.2:3b", "nomic-embed-text:latest"}
    end
    
    -- Extract models list
    if parsed_response.result and parsed_response.result.models then
        return parsed_response.result.models
    else
        return {"llama2", "llama3.2:3b", "nomic-embed-text:latest"}
    end
end

-- Get list of projects
function M.get_projects()
    local rpc_client = M._get_rpc_client()
    if not rpc_client then
        return nil, "Backend not available"
    end
    
    -- Get projects list
    local response = rpc_client:get_projects()
    if not response then
        return nil, "Failed to get projects list"
    end
    
    -- Parse JSON response
    local parsed_response = M.parse_json_response(response)
    if not parsed_response then
        return nil, "Failed to parse projects response"
    end
    
    -- Check for error in response
    if parsed_response.error then
        return nil, "Projects error: " .. (parsed_response.error.message or "Unknown error")
    end
    
    -- Extract projects list
    if parsed_response.result and parsed_response.result.projects then
        return parsed_response.result.projects
    else
        return nil, "Unexpected projects response format"
    end
end

-- Create a new project
function M.create_project(name, description)
    local rpc_client = M._get_rpc_client()
    if not rpc_client then
        return nil, "Backend not available"
    end
    
    -- Create project
    local response = rpc_client:create_project(name, description)
    if not response then
        return nil, "Failed to create project"
    end
    
    return response
end

-- Get configuration from backend
function M.get_config()
    local rpc_client = M._get_rpc_client()
    if not rpc_client then
        return nil, "Backend not available"
    end
    
    -- Get configuration
    local response = rpc_client:get_config()
    if not response then
        return nil, "Failed to get configuration"
    end
    
    -- Return the full JSON-RPC response as a string
    return response
end

-- Save configuration to backend
function M.save_config(config_data)
    local rpc_client = M._get_rpc_client()
    if not rpc_client then
        return nil, "Backend not available"
    end
    
    -- Save configuration
    local response = rpc_client:save_config(config_data)
    if not response then
        return nil, "Failed to save configuration"
    end
    
    return response
end

-- Parse JSON-RPC response
function M.parse_json_response(json_string)
    if not json_string or json_string == "" then
        return nil, "Empty JSON string"
    end
    
    -- Parse JSON with error handling using vim.json
    local success, result = pcall(vim.json.decode, json_string)
    if not success then
        return nil, "Failed to parse JSON: " .. tostring(result)
    end
    
    return result
end

-- Enhanced parse JSON-RPC response (handles both strings and tables)
function M.parse_json_response_enhanced(input)
    if not input then
        return nil, "Empty input"
    end
    
    -- If input is already a table, return it directly
    if type(input) == "table" then
        return input
    end
    
    -- If input is a string, parse it as JSON
    if type(input) == "string" then
        if input == "" then
            return nil, "Empty JSON string"
        end
        
        -- Parse JSON with error handling using vim.json
        local success, result = pcall(vim.json.decode, input)
        if not success then
            return nil, "Failed to parse JSON: " .. tostring(result)
        end
        
        return result
    end
    
    -- Unsupported input type
    return nil, "Unsupported input type: " .. type(input)
end

-- Initialize Rust backend
function M._initialize_backend()
    M.debug_print("🔧 _initialize_backend() called", "debug")
    
    -- Only initialize once
    if M._rpc_client then
        M.debug_print("✅ RPC client already exists, returning true", "info")
        return true
    end
    
    M.debug_print("🔧 Starting backend initialization...", "info")
    
    -- Create RPC client with timeout
    M.debug_print("🔧 Step 1: About to require paragonic.rpc...", "debug")
    local success, rpc = pcall(require, "paragonic.rpc")
    if not success then
        M.debug_print("❌ Failed to require paragonic.rpc: " .. tostring(rpc), "error")
        return false
    end
    M.debug_print("✅ paragonic.rpc module loaded successfully", "success")
    
    M.debug_print("🔧 Step 2: About to create RPC client with rpc.new()...", "debug")
    local success2, client = pcall(function() return rpc.new("127.0.0.1:3000") end)
    if not success2 then
        M.debug_print("❌ Failed to create RPC client: " .. tostring(client), "error")
        return false
    end
    M._rpc_client = client
    M.debug_print("✅ RPC client created successfully", "success")
    
    -- Set a timeout for the connection attempt
    local connection_timeout = 5000 -- 5 seconds
    local max_retries = 2
    local retry_count = 0
    
    M.debug_print("🔧 Step 3: About to start connection attempts...", "debug")
    
    while retry_count <= max_retries do
        local start_time = vim.loop.hrtime() / 1000000
        
        M.debug_print("🔧 Attempt " .. (retry_count + 1) .. "/" .. (max_retries + 1) .. ": About to call connect()...", "debug")
        
        -- Connect to the Rust backend with timeout
        M.debug_print("🔧 Calling M._rpc_client:connect()...", "debug")
        local success, err = M._rpc_client:connect()
        M.debug_print("✅ connect() call completed, success=" .. tostring(success), "debug")
        
        if not success then
            local end_time = vim.loop.hrtime() / 1000000
            local duration = end_time - start_time
            
            retry_count = retry_count + 1
            
            if duration > connection_timeout then
                M.debug_print("❌ Connection timed out after " .. string.format("%.1f", duration) .. "ms (attempt " .. retry_count .. "/" .. (max_retries + 1) .. ")", "error")
            else
                M.debug_print("❌ Connection failed: " .. (err or "unknown error") .. " (attempt " .. retry_count .. "/" .. (max_retries + 1) .. ")", "error")
            end
            
            if retry_count > max_retries then
                M.debug_print("❌ Failed to connect after " .. (max_retries + 1) .. " attempts", "error")
                M._rpc_client = nil
                return false
            end
            
            -- Wait a bit before retrying
            M.debug_print("⏳ Waiting 1 second before retry...", "info")
            vim.wait(1000)
        else
            M.debug_print("✅ Connection successful!", "success")
            break
        end
    end
    
    -- Test connection with hello call (also with timeout)
    M.debug_print("🔧 Step 4: About to test connection with hello call...", "debug")
    local hello_start = vim.loop.hrtime() / 1000000
    M.debug_print("🔧 Calling M._rpc_client:hello()...", "debug")
    local response = M._rpc_client:hello()
    M.debug_print("✅ hello() call completed, response=" .. tostring(response ~= nil), "debug")
    local hello_end = vim.loop.hrtime() / 1000000
    local hello_duration = hello_end - hello_start
    
    if not response then
        if hello_duration > connection_timeout then
            M.debug_print("❌ Hello call timed out after " .. string.format("%.1f", hello_duration) .. "ms", "error")
        else
            M.debug_print("❌ Hello call failed - no response", "error")
        end
        
        M._rpc_client:disconnect()
        M._rpc_client = nil
        return false
    end
    
    M.debug_print("✅ Backend initialization completed successfully in " .. string.format("%.1f", hello_duration) .. "ms", "success")
    return true
end

-- Force reconnection to the backend (useful when server restarts)
function M.force_reconnect()
    M.debug_print("🔧 force_reconnect() called", "debug")
    
    if not M._rpc_client then
        M.debug_print("🔧 No RPC client exists, initializing backend...", "info")
        return M._initialize_backend()
    end
    
    M.debug_print("🔧 Forcing reconnection of existing RPC client...", "info")
    
    -- Disconnect current client
    M._rpc_client:disconnect()
    
    -- Try to reconnect
    local success = M._rpc_client:reconnect()
    
    if success then
        M.debug_print("✅ Force reconnection successful", "success")
        return true
    else
        M.debug_print("❌ Force reconnection failed, reinitializing backend...", "error")
        
        -- If reconnection fails, reinitialize the entire backend
        M._rpc_client = nil
        return M._initialize_backend()
    end
end

-- Manually initialize backend when needed
function M.initialize_backend()
    if not M._rpc_client then
        M._initialize_backend()
    end
    return M._rpc_client ~= nil
end

-- Open chat interface
function M.open_chat()
    -- Check if chat buffer already exists
    local chat_buf = nil
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(buf)
        if name == "paragonic://chat" then
            chat_buf = buf
            break
        end
    end
    
    -- Create new buffer if it doesn't exist
    if not chat_buf then
        chat_buf = vim.api.nvim_create_buf(true, true)
        
        -- Set buffer name
        vim.api.nvim_buf_set_name(chat_buf, "paragonic://chat")
        
        -- Set buffer options
        vim.api.nvim_buf_set_option(chat_buf, "buftype", "nofile")
        vim.api.nvim_buf_set_option(chat_buf, "swapfile", false)
        vim.api.nvim_buf_set_option(chat_buf, "modifiable", true)
        
        -- Add initial content with default model information
        vim.api.nvim_buf_set_lines(chat_buf, 0, -1, false, {
            "# Paragonic Chat",
            "",
            "Available models: llama2 (default)",
            "",
            "Type your message below and use :ParagonicSend to send:",
            "",
            "∎"
        })
        
        -- Models info will be updated when user first interacts with the chat
        -- This prevents freezing during buffer creation
        
        -- Set filetype for syntax highlighting
        vim.api.nvim_buf_set_option(chat_buf, "filetype", "markdown")
        
        -- Set up buffer-local commands
        vim.api.nvim_buf_set_keymap(chat_buf, "n", "<CR>", ":ParagonicSend<CR>", {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(chat_buf, "n", "<leader><CR>", ":ParagonicSendDebug<CR>", {noremap = true, silent = true})
    end
    
    -- Open the buffer in a new window
    vim.api.nvim_command("split")
    vim.api.nvim_set_current_buf(chat_buf)
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

-- Create project command
function M.create_project_command()
    local current_buf = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(current_buf)
    
    -- Only work in projects buffer
    if buf_name ~= "paragonic://projects" then
        vim.notify("This command only works in the projects buffer", vim.log.levels.WARN)
        return
    end
    
    -- Get project name from user input
    local project_name = vim.fn.input("Project name: ")
    if project_name == "" then
        vim.notify("Project name cannot be empty", vim.log.levels.WARN)
        return
    end
    
    -- Get project description from user input
    local project_description = vim.fn.input("Project description: ")
    
    -- Create the project
    local response, err = M.create_project(project_name, project_description)
    if not response then
        vim.notify("Failed to create project: " .. (err or "unknown error"), vim.log.levels.ERROR)
        return
    end
    
    -- Add the new project to the buffer
    local project_lines = {
        "",
        "## " .. project_name,
        project_description ~= "" and project_description or "No description provided",
        "",
        "---"
    }
    
    -- Insert project at the end of the buffer
    local last_line = vim.api.nvim_buf_line_count(current_buf)
    vim.api.nvim_buf_set_lines(current_buf, last_line, last_line, false, project_lines)
    
    vim.notify("Project '" .. project_name .. "' created successfully", vim.log.levels.INFO)
end

-- Save configuration command
function M.save_config_command()
    local current_buf = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(current_buf)
    
    -- Only work in config buffer
    if buf_name ~= "paragonic://config" then
        vim.notify("This command only works in the config buffer", vim.log.levels.WARN)
        return
    end
    
    -- Get all lines from the buffer
    local lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
    
    -- Parse configuration from buffer content
    local config_data = {}
    
    for _, line in ipairs(lines) do
        -- Parse Ollama settings
        if line:match("^%- Host: (.+)$") then
            config_data.ollama_host = line:match("^%- Host: (.+)$")
        elseif line:match("^%- Model: (.+)$") then
            config_data.ollama_model = line:match("^%- Model: (.+)$")
        elseif line:match("^%- Path: (.+)$") then
            config_data.database_path = line:match("^%- Path: (.+)$")
        elseif line:match("^%- Level: (.+)$") then
            config_data.log_level = line:match("^%- Level: (.+)$")
        end
    end
    
    -- Save the configuration
    local response, err = M.save_config(config_data)
    if not response then
        vim.notify("Failed to save configuration: " .. (err or "unknown error"), vim.log.levels.ERROR)
        return
    end
    
    -- Add confirmation message to buffer
    local confirmation_lines = {
        "",
        "**Configuration saved successfully!**",
        "",
        "---"
    }
    
    -- Insert confirmation at the end of the buffer
    local last_line = vim.api.nvim_buf_line_count(current_buf)
    vim.api.nvim_buf_set_lines(current_buf, last_line, last_line, false, confirmation_lines)
    
    vim.notify("Configuration saved successfully", vim.log.levels.INFO)
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

-- Handle search result selection
function M.select_search_result(buf)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor_pos[1]
    
    -- Get the results data
    local success, results = pcall(vim.api.nvim_buf_get_var, buf, "paragonic_search_results")
    if not success or not results or not results.results then
        vim.notify("No search results available", vim.log.levels.WARN)
        return
    end
    
    -- Calculate which result was selected (accounting for header lines)
    local result_index = line_num - 4 -- Subtract header lines
    if result_index >= 1 and result_index <= #results.results then
        local selected_result = results.results[result_index]
        
        -- Display detailed information about the selected result
        M.show_result_details(selected_result)
    else
        vim.notify("Invalid selection", vim.log.levels.WARN)
    end
end

-- Show detailed information about a search result
function M.show_result_details(result)
    if not result or not result.embedding then
        vim.notify("Invalid result data", vim.log.levels.ERROR)
        return
    end
    
    -- Create a new buffer for detailed view
    local detail_buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(detail_buf, "paragonic://result-details")
    
    -- Format detailed information
    local lines = {
        "📋 Search Result Details",
        string.rep("─", 25),
        "",
        "📄 Content Type: " .. (result.embedding.content_type or "unknown"),
        "🎯 Similarity Score: " .. string.format("%.3f", result.similarity_score or 0),
        "🆔 Content ID: " .. (result.embedding.content_id or "unknown"),
        "",
        "📝 Content:",
        string.rep("─", 10),
        result.embedding.content_text or "No content available",
        "",
        "📅 Created: " .. (result.embedding.created_at or "unknown"),
        "🔄 Updated: " .. (result.embedding.updated_at or "unknown"),
        "",
        string.rep("─", 50),
        "Press q to close"
    }
    
    -- Set buffer content
    vim.api.nvim_buf_set_lines(detail_buf, 0, -1, false, lines)
    
    -- Set buffer options
    vim.api.nvim_buf_set_option(detail_buf, "modifiable", false)
    vim.api.nvim_buf_set_option(detail_buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(detail_buf, "swapfile", false)
    vim.api.nvim_buf_set_option(detail_buf, "filetype", "markdown")
    
    -- Create window
    local width = math.min(70, vim.o.columns - 4)
    local height = math.min(20, vim.o.lines - 4)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    
    local detail_win = vim.api.nvim_open_win(detail_buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = " Result Details ",
        title_pos = "center"
    })
    
    -- Set up keymaps
    vim.api.nvim_buf_set_keymap(detail_buf, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(detail_buf, "n", "<Esc>", "<cmd>close<CR>", {noremap = true, silent = true})
    
    -- Set cursor to first line
    vim.api.nvim_win_set_cursor(detail_win, {1, 0})
end

-- Which-key integration for Paragonic commands
function M.setup_which_key()
    -- Check if we're in Neovim environment
    if not vim then
        return
    end
    
    -- Check if which-key is available
    local ok, wk = pcall(require, "which-key")
    if not ok or not wk then
        M.debug_print("which-key not available, skipping integration", "warning")
        return
    end
    
    -- Register Paragonic keymaps with which-key (new spec format)
    wk.add({
        { "<leader>P", group = "🚀 Paragonic", icon = "🚀" },
        { "<leader>Ps", "<cmd>ParagonicSearch<CR>", desc = "🔍 Basic Search" },
        { "<leader>Pf", "<cmd>ParagonicSearchFiltered<CR>", desc = "🔍 Filtered Search" },
        { "<leader>Ph", "<cmd>ParagonicSearchHybrid<CR>", desc = "🔍 Hybrid Search" },
        { "<leader>Pc", "<cmd>ParagonicChat<CR>", desc = "💬 Open Chat" },
        { "<leader>Pp", "<cmd>ParagonicProjects<CR>", desc = "📁 Open Projects" },
        { "<leader>Po", "<cmd>ParagonicConfig<CR>", desc = "⚙️  Open Config" },
        { "<leader>Pd", "<cmd>ParagonicDebug<CR>", desc = "🐛 Open Debug" },
        { "<leader>Py", "<cmd>ParagonicSearchHistory<CR>", desc = "📚 Search History" },
        { "<leader>Pv", "<cmd>ParagonicSavedSearches<CR>", desc = "💾 Saved Searches" },
        { "<leader>Pw", "<cmd>ParagonicSaveSearch<CR>", desc = "💾 Save Current Search" },
        { "<leader>Pa", "<cmd>ParagonicAgentSession<CR>", desc = "🤖 AI Agent Session" },
        { "<leader>Pe", "<cmd>ParagonicExportData<CR>", desc = "📤 Export Data" },
        { "<leader>Pi", "<cmd>ParagonicImportData<CR>", desc = "📥 Import Data" },
        { "<leader>Pb", "<cmd>ParagonicBackupData<CR>", desc = "💾 Backup Data" },
        { "<leader>Pr", "<cmd>ParagonicReconnect<CR>", desc = "🔌 Force Reconnect" },
    })
    
    -- Register visual mode keymaps for search with selection (new spec format)
    wk.add({
        {
            mode = { "v" },
            { "<leader>Ps", function()
                local saved_reg = vim.fn.getreg('"')
                vim.cmd('normal! y')
                local selected_text = vim.fn.getreg('"')
                vim.fn.setreg('"', saved_reg)
                
                if selected_text and selected_text ~= "" then
                    vim.cmd('ParagonicSearch ' .. vim.fn.shellescape(selected_text))
                else
                    vim.cmd('ParagonicSearch')
                end
            end, desc = "🔍 Search Selected Text" },
            { "<leader>Pf", function()
                local saved_reg = vim.fn.getreg('"')
                vim.cmd('normal! y')
                local selected_text = vim.fn.getreg('"')
                vim.fn.setreg('"', saved_reg)
                
                if selected_text and selected_text ~= "" then
                    vim.cmd('ParagonicSearchFiltered ' .. vim.fn.shellescape(selected_text))
                else
                    vim.cmd('ParagonicSearchFiltered')
                end
            end, desc = "🔍 Filtered Search Selected Text" },
            { "<leader>Ph", function()
                local saved_reg = vim.fn.getreg('"')
                vim.cmd('normal! y')
                local selected_text = vim.fn.getreg('"')
                vim.fn.setreg('"', saved_reg)
                
                if selected_text and selected_text ~= "" then
                    vim.cmd('ParagonicSearchHybrid ' .. vim.fn.shellescape(selected_text))
                else
                    vim.cmd('ParagonicSearchHybrid')
                end
            end, desc = "🔍 Hybrid Search Selected Text" },
        },
    })
    
    M.debug_print("which-key integration setup completed", "info")
end

-- Set up keyboard mappings
function M._setup_keymaps()
    -- Set up which-key integration if available
    M.setup_which_key()
    
    -- Fallback keymaps for when which-key is not available
    vim.keymap.set("n", "<leader>Ps", "<cmd>ParagonicSearch<CR>", {desc = "Paragonic: Basic Search"})
    vim.keymap.set("n", "<leader>Pf", "<cmd>ParagonicSearchFiltered<CR>", {desc = "Paragonic: Filtered Search"})
    vim.keymap.set("n", "<leader>Ph", "<cmd>ParagonicSearchHybrid<CR>", {desc = "Paragonic: Hybrid Search"})
    vim.keymap.set("n", "<leader>Pc", "<cmd>ParagonicChat<CR>", {desc = "Paragonic: Open Chat"})
    vim.keymap.set("n", "<leader>Pp", "<cmd>ParagonicProjects<CR>", {desc = "Paragonic: Open Projects"})
    vim.keymap.set("n", "<leader>Po", "<cmd>ParagonicConfig<CR>", {desc = "Paragonic: Open Config"})
    vim.keymap.set("n", "<leader>Pd", "<cmd>ParagonicDebug<CR>", {desc = "Paragonic: Open Debug"})
    vim.keymap.set("n", "<leader>Py", "<cmd>ParagonicSearchHistory<CR>", {desc = "Paragonic: Search History"})
    vim.keymap.set("n", "<leader>Pv", "<cmd>ParagonicSavedSearches<CR>", {desc = "Paragonic: Saved Searches"})
    vim.keymap.set("n", "<leader>Pw", "<cmd>ParagonicSaveSearch<CR>", {desc = "Paragonic: Save Current Search"})
    vim.keymap.set("n", "<leader>Pa", "<cmd>ParagonicAgentSession<CR>", {desc = "Paragonic: AI Agent Session"})
    vim.keymap.set("n", "<leader>Pe", "<cmd>ParagonicExportData<CR>", {desc = "Paragonic: Export Data"})
    vim.keymap.set("n", "<leader>Pi", "<cmd>ParagonicImportData<CR>", {desc = "Paragonic: Import Data"})
    vim.keymap.set("n", "<leader>Pb", "<cmd>ParagonicBackupData<CR>", {desc = "Paragonic: Backup Data"})
    vim.keymap.set("n", "<leader>Pr", "<cmd>ParagonicReconnect<CR>", {desc = "Paragonic: Force Reconnect"})
    
    -- Visual mode keymaps for search with selection
    vim.keymap.set("v", "<leader>Ps", function()
        local saved_reg = vim.fn.getreg('"')
        vim.cmd('normal! y')
        local selected_text = vim.fn.getreg('"')
        vim.fn.setreg('"', saved_reg)
        
        if selected_text and selected_text ~= "" then
            vim.cmd('ParagonicSearch ' .. vim.fn.shellescape(selected_text))
        else
            vim.cmd('ParagonicSearch')
        end
    end, {desc = "Paragonic: Search Selected Text"})
    
    vim.keymap.set("v", "<leader>Pf", function()
        local saved_reg = vim.fn.getreg('"')
        vim.cmd('normal! y')
        local selected_text = vim.fn.getreg('"')
        vim.fn.setreg('"', saved_reg)
        
        if selected_text and selected_text ~= "" then
            vim.cmd('ParagonicSearchFiltered ' .. vim.fn.shellescape(selected_text))
        else
            vim.cmd('ParagonicSearchFiltered')
        end
    end, {desc = "Paragonic: Filtered Search Selected Text"})
    
    vim.keymap.set("v", "<leader>Ph", function()
        local saved_reg = vim.fn.getreg('"')
        vim.cmd('normal! y')
        local selected_text = vim.fn.getreg('"')
        vim.fn.setreg('"', saved_reg)
        
        if selected_text and selected_text ~= "" then
            vim.cmd('ParagonicSearchHybrid ' .. vim.fn.shellescape(selected_text))
        else
            vim.cmd('ParagonicSearchHybrid')
        end
    end, {desc = "Paragonic: Hybrid Search Selected Text"})
    
    M.debug_print("Keymaps setup completed with which-key integration", "info")
end

-- Enhanced search command with better UX
function M.quick_search()
    local query = vim.fn.input("🔍 Search: ")
    if query == "" then
        return
    end
    
    -- Perform search
    local results, err = M.search_embeddings(query, 10)
    if not results then
        vim.notify("Search failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
        return
    end
    
    -- Add to search history
    M.add_to_search_history(query, "basic", results.results and #results.results or 0)
    
    -- Display results in a floating window
    M.display_search_results(results, "Quick Search: " .. query)
end

-- Enhanced filtered search with content type selection
function M.quick_filtered_search()
    local query = vim.fn.input("🔍 Search: ")
    if query == "" then
        return
    end
    
    -- Content type selection
    local content_types = {"project", "task", "note", "code", "document"}
    local content_type = vim.fn.input("📁 Content Type (project/task/note/code/document): ")
    
    -- Perform filtered search
    local results, err = M.find_similar_content(query, content_type ~= "" and content_type or nil, 10, 0.0)
    if not results then
        vim.notify("Filtered search failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
        return
    end
    
    -- Add to search history
    M.add_to_search_history(query, "filtered", results.results and #results.results or 0)
    
    -- Display results in a floating window
    M.display_search_results(results, "Filtered Search: " .. query)
end

-- Enhanced hybrid search with options
function M.quick_hybrid_search()
    local query = vim.fn.input("🔍 Search: ")
    if query == "" then
        return
    end
    
    local content_type = vim.fn.input("📁 Content Type (optional): ")
    local include_text_filtering = vim.fn.input("🔤 Include text filtering? (y/n, default y): "):lower() ~= "n"
    
    -- Perform hybrid search
    local results, err = M.hybrid_search(query, content_type ~= "" and content_type or nil, 10, 0.0, include_text_filtering)
    if not results then
        vim.notify("Hybrid search failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
        return
    end
    
    -- Add to search history
    M.add_to_search_history(query, "hybrid", results.results and #results.results or 0)
    
    -- Display results in a floating window
    M.display_search_results(results, "Hybrid Search: " .. query)
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

-- Repeat search from history
function M.repeat_search_from_history(buf)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor_pos[1]
    
    -- Calculate which entry was selected (accounting for header lines)
    local entry_index = line_num - 4 -- Subtract header lines
    if entry_index >= 1 and entry_index <= #search_history then
        local entry = search_history[entry_index]
        
        -- Execute the search
        local results, err
        if entry.type == "basic" then
            results, err = M.search_embeddings(entry.query, 10)
        elseif entry.type == "filtered" then
            results, err = M.find_similar_content(entry.query, nil, 10, 0.0)
        elseif entry.type == "hybrid" then
            results, err = M.hybrid_search(entry.query, nil, 10, 0.0, true)
        end
        
        if results then
            -- Add to history again
            M.add_to_search_history(entry.query, entry.type, results.results and #results.results or 0)
            
            -- Display results
            M.display_search_results(results, "History Search: " .. entry.query)
        else
            vim.notify("Failed to repeat search: " .. (err or "unknown error"), vim.log.levels.ERROR)
        end
    else
        vim.notify("Invalid selection", vim.log.levels.WARN)
    end
end

-- Delete from search history
function M.delete_from_search_history(buf)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor_pos[1]
    
    -- Calculate which entry was selected (accounting for header lines)
    local entry_index = line_num - 4 -- Subtract header lines
    if entry_index >= 1 and entry_index <= #search_history then
        local entry = search_history[entry_index]
        table.remove(search_history, entry_index)
        
        -- Refresh the display
        vim.api.nvim_command("close")
        M.show_search_history()
    else
        vim.notify("Invalid selection", vim.log.levels.WARN)
    end
end

-- Execute saved search from list
function M.execute_saved_search_from_list(buf)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor_pos[1]
    
    -- Calculate which entry was selected (accounting for header lines)
    local entry_index = math.floor((line_num - 4) / 3) + 1 -- Each entry takes 3 lines
    if entry_index >= 1 and entry_index <= #saved_searches then
        local saved = saved_searches[entry_index]
        M.execute_saved_search(saved.name)
    else
        vim.notify("Invalid selection", vim.log.levels.WARN)
    end
end

-- Delete saved search from list
function M.delete_saved_search_from_list(buf)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor_pos[1]
    
    -- Calculate which entry was selected (accounting for header lines)
    local entry_index = math.floor((line_num - 4) / 3) + 1 -- Each entry takes 3 lines
    if entry_index >= 1 and entry_index <= #saved_searches then
        local saved = saved_searches[entry_index]
        M.delete_saved_search(saved.name)
        
        -- Refresh the display
        vim.api.nvim_command("close")
        M.show_saved_searches()
    else
        vim.notify("Invalid selection", vim.log.levels.WARN)
    end
end

-- Save current search
function M.save_current_search()
    local name = vim.fn.input("💾 Save search as: ")
    if name == "" then
        vim.notify("Search name is required", vim.log.levels.WARN)
        return
    end
    
    -- For now, save the last search from history
    if #search_history > 0 then
        local last_search = search_history[1]
        M.save_search(name, last_search.query, last_search.type, nil, 10, 0.0)
    else
        vim.notify("No recent searches to save", vim.log.levels.WARN)
    end
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

-- Register a cancellable operation
function M.register_cancellable_operation(operation_type, description)
    local operation_id = "op-" .. M.cancellation_state.next_operation_id
    M.cancellation_state.next_operation_id = M.cancellation_state.next_operation_id + 1
    
    M.cancellation_state.active_operations[operation_id] = {
        type = operation_type,
        description = description,
        start_time = os.time(),
        cancelled = false
    }
    
    return operation_id
end

-- Check if operation is cancelled
function M.is_operation_cancelled(operation_id)
    local operation = M.cancellation_state.active_operations[operation_id]
    return operation and operation.cancelled
end

-- Cancel an operation
function M.cancel_operation(operation_id)
    local operation = M.cancellation_state.active_operations[operation_id]
    if operation then
        operation.cancelled = true
        operation.cancel_time = os.time()
        return true
    end
    return false
end

-- Complete an operation (remove from active list)
function M.complete_operation(operation_id)
    M.cancellation_state.active_operations[operation_id] = nil
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