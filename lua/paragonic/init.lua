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
    
    -- Setup all autocommand types
    local success1, _ = M.setup_buffer_change_autocommands()
    local success2, _ = M.setup_cursor_movement_autocommands()
    local success3, _ = M.setup_window_change_autocommands()
    
    if success1 and success2 and success3 then
        return true, "All event autocommands setup successfully"
    else
        return false, "Failed to setup some autocommands"
    end
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

-- Send a message to the AI and get response
function M.send_message(message, model)
    local rpc_client = M._get_rpc_client()
    if not rpc_client then
        -- Try to initialize backend if not available
        if not M.initialize_backend() then
            return nil, "Backend not available"
        end
        rpc_client = M._get_rpc_client()
    end
    
    -- Use default model if not specified
    model = model or "llama2"
    
    -- Send chat completion request
    local response = rpc_client:chat_completion(model, message)
    if not response then
        return nil, "Failed to get response from AI"
    end
    
    -- Parse JSON response using enhanced parser
    local parsed_response = M.parse_json_response_enhanced(response)
    if not parsed_response then
        return nil, "Failed to parse AI response"
    end
    
    -- Check for error in response
    if parsed_response.error then
        return nil, "AI error: " .. (parsed_response.error.message or "Unknown error")
    end
    
    -- Extract AI message content
    -- Handle different response formats:
    -- 1. JSON-RPC result wrapper with JSON string: {result: "{\"message\":{\"content\":\"...\"}}"}
    -- 2. JSON-RPC result wrapper: {result: {message: {content: "..."}}}
    -- 3. Direct Ollama response: {message: {content: "..."}}
    -- 4. Direct content: {content: "..."}
    
    if parsed_response.result then
        -- Check if result is a JSON string (from backend)
        if type(parsed_response.result) == "string" then
            -- Try using cjson if available
            local cjson_ok, cjson = pcall(require, "cjson")
            if cjson_ok then
                local success, inner_result = pcall(cjson.decode, parsed_response.result)
                if success and inner_result and inner_result.message then
                    return inner_result.message.content
                end
            end
            -- Try using dkjson if available
            local dkjson_ok, dkjson = pcall(require, "dkjson")
            if dkjson_ok then
                local success, inner_result = pcall(dkjson.decode, parsed_response.result)
                if success and inner_result and inner_result.message then
                    return inner_result.message.content
                end
            end
            -- Fallback to vim.json.decode
            local success, inner_result = pcall(vim.json.decode, parsed_response.result)
            if success and inner_result and inner_result.message then
                return inner_result.message.content
            end
        end
        
        -- Check if result is a table with message
        if type(parsed_response.result) == "table" and parsed_response.result.message then
            return parsed_response.result.message.content
        end
        
        -- Check if result is a table with content
        if type(parsed_response.result) == "table" and parsed_response.result.content then
            return parsed_response.result.content
        end
    end
    
    if parsed_response.message then
        return parsed_response.message.content
    end
    
    if parsed_response.content then
        return parsed_response.content
    end
    
    return nil, "Unexpected response format: " .. tostring(parsed_response)
end

-- Enhanced send message with improved response parsing
function M.send_message_enhanced(message, model)
    local rpc_client = M._get_rpc_client()
    if not rpc_client then
        return nil, "Backend not available"
    end
    
    -- Use default model if not specified
    model = model or "llama2"
    
    -- Send chat completion request
    local response = rpc_client:chat_completion(model, message)
    if not response then
        return nil, "Failed to get response from AI"
    end
    
    -- Parse response using enhanced parser (handles both strings and tables)
    local parsed_response = M.parse_json_response_enhanced(response)
    if not parsed_response then
        return nil, "Failed to parse AI response"
    end
    
    -- Check for error in response
    if parsed_response.error then
        return nil, "AI error: " .. (parsed_response.error.message or "Unknown error")
    end
    
    -- Extract AI message content
    -- Handle different response formats:
    -- 1. JSON-RPC result wrapper with JSON string: {result: "{\"message\":{\"content\":\"...\"}}"}
    -- 2. JSON-RPC result wrapper: {result: {message: {content: "..."}}}
    -- 3. Direct Ollama response: {message: {content: "..."}}
    -- 4. Direct content: {content: "..."}
    
    if parsed_response.result then
        -- Check if result is a JSON string (from backend)
        if type(parsed_response.result) == "string" then
            -- Try using cjson if available
            local cjson_ok, cjson = pcall(require, "cjson")
            if cjson_ok then
                local success, inner_result = pcall(cjson.decode, parsed_response.result)
                if success and inner_result and inner_result.message then
                    return inner_result.message.content
                end
            end
            -- Try using dkjson if available
            local dkjson_ok, dkjson = pcall(require, "dkjson")
            if dkjson_ok then
                local success, inner_result = pcall(dkjson.decode, parsed_response.result)
                if success and inner_result and inner_result.message then
                    return inner_result.message.content
                end
            end
            -- Fallback to vim.json.decode
            local success, inner_result = pcall(vim.json.decode, parsed_response.result)
            if success and inner_result and inner_result.message then
                return inner_result.message.content
            end
        end
        
        -- Check if result is a table with message
        if type(parsed_response.result) == "table" and parsed_response.result.message then
            return parsed_response.result.message.content
        end
        
        -- Check if result is a table with content
        if type(parsed_response.result) == "table" and parsed_response.result.content then
            return parsed_response.result.content
        end
    end
    
    if parsed_response.message then
        return parsed_response.message.content
    end
    
    if parsed_response.content then
        return parsed_response.content
    end
    
    return nil, "Unexpected response format: " .. tostring(parsed_response)
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

-- Send message command
function M.send_message_command()
    -- Immediate debugging at function entry
    M.debug_print("🚀 send_message_command() called", "debug")
    M.debug_print("📝 Starting send_message_command function", "debug")
    
    local current_buf = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(current_buf)
    
    M.debug_print("📝 Current buffer: " .. buf_name, "debug")
    
    -- Only work in chat buffer
    if buf_name ~= "paragonic://chat" then
        M.debug_print("❌ This command only works in the chat buffer", "error")
        return
    end
    
    M.debug_print("✅ Buffer check passed", "debug")
    
    -- Get the current line as the message
    local line_num = vim.api.nvim_win_get_cursor(0)[1] - 1  -- 0-indexed
    local lines = vim.api.nvim_buf_get_lines(current_buf, line_num, line_num + 1, false)
    local message = lines[1] or ""
    
    M.debug_print("📝 Message: " .. message:sub(1, 50), "debug")
    
    -- Skip empty lines or lines that start with #
    if message == "" or message:match("^%s*#") then
        M.debug_print("❌ Please enter a message to send", "error")
        return
    end
    
    M.debug_print("✅ Message validation passed", "debug")
    M.debug_print("🔧 About to call append_debug_message...", "debug")
    
    -- Add immediate visual feedback that the chat is being sent
    M.debug_print("🔧 Calling append_debug_message...", "debug")
    local success, err = M.append_debug_message(current_buf, "Sending message to AI...", "info")
    
    if not success then
        M.debug_print("❌ append_debug_message failed: " .. tostring(err), "error")
        return
    else
        M.debug_print("✅ append_debug_message succeeded", "debug")
    end
    
    -- Initialize backend if not available
    if not M._rpc_client then
        M.append_debug_message(current_buf, "🔧 Backend not available, starting initialization...", "info")
        M.append_debug_message(current_buf, "🔧 Step 1: Creating RPC client...", "debug")
        
        local success = M._initialize_backend()
        
        if not success then
            M.append_debug_message(current_buf, "❌ Backend initialization failed", "error")
            vim.notify("Failed to send message: Backend initialization failed", vim.log.levels.ERROR)
            return
        else
            M.append_debug_message(current_buf, "✅ Backend initialization completed", "success")
        end
    else
        M.append_debug_message(current_buf, "✅ Backend already available", "info")
    end
    
    -- Start a progress indicator for long operations
    local progress_timer = nil
    local progress_count = 0
    local function update_progress()
        progress_count = progress_count + 1
        local dots = string.rep(".", progress_count % 4)
        M.append_debug_message(current_buf, "Waiting for AI response" .. dots, "info")
    end
    
    -- Start progress updates every 5 seconds
    progress_timer = vim.loop.new_timer()
    progress_timer:start(5000, 5000, vim.schedule_wrap(update_progress))
    
    -- Record start time for timing information
    local start_time = vim.uv.now()
    
    -- Add zigzag arrow to indicate request is being sent
    vim.api.nvim_buf_set_lines(current_buf, line_num + 1, line_num + 1, false, {"↯"})
    
    -- Force buffer update to show zigzag immediately
    vim.api.nvim_buf_call(current_buf, function()
        vim.cmd("redraw!")
    end)
    
    -- Set up retry callback for RPC client
    if M._rpc_client and M._rpc_client.set_retry_callback then
        M._rpc_client:set_retry_callback(function(attempt, max_attempts)
            -- Add retry notification to chat buffer
            vim.api.nvim_buf_set_lines(current_buf, line_num + 2, line_num + 2, false, {"🔄 Retry attempt " .. attempt .. "/" .. max_attempts})
        end)
    end
    
    -- Send the message using enhanced function
    local response, err = M.send_message_enhanced(message, "llama2")
    
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

-- Enhanced send message command with debug messages
function M.send_message_command_debug()
    local current_buf = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(current_buf)
    
    -- Only work in chat buffer
    if buf_name ~= "paragonic://chat" then
        vim.notify("This command only works in the chat buffer", vim.log.levels.WARN)
        return
    end
    
    -- Get the current line as the message
    local line_num = vim.api.nvim_win_get_cursor(0)[1] - 1  -- 0-indexed
    local lines = vim.api.nvim_buf_get_lines(current_buf, line_num, line_num + 1, false)
    local message = lines[1] or ""
    
    -- Skip empty lines or lines that start with #
    if message == "" or message:match("^%s*#") then
        vim.notify("Please enter a message to send", vim.log.levels.INFO)
        return
    end
    
    -- Add immediate visual feedback that the chat is being sent
    M.append_debug_message(current_buf, "🚀 Sending message to AI...", "info")
    
    -- Debug: Starting message send
    M.append_debug_message(current_buf, "Starting message send process", "debug")
    
    -- Initialize backend if not available
    if not M._rpc_client then
        M.append_debug_message(current_buf, "🔧 Backend not available, starting initialization...", "info")
        M.append_debug_message(current_buf, "🔧 Step 1: Creating RPC client...", "debug")
        
        local success = M._initialize_backend()
        
        if not success then
            M.append_debug_message(current_buf, "❌ Backend initialization failed", "error")
            vim.notify("Failed to send message: Backend initialization failed", vim.log.levels.ERROR)
            return
        else
            M.append_debug_message(current_buf, "✅ Backend initialization completed", "success")
        end
    else
        M.append_debug_message(current_buf, "✅ Backend already available", "info")
    end
    
    -- Check RPC client
    local rpc_client = M._get_rpc_client()
    if not rpc_client then
        M.append_debug_message(current_buf, "RPC client not available", "error")
        vim.notify("Failed to send message: Backend not available", vim.log.levels.ERROR)
        return
    end
    
    M.append_debug_message(current_buf, "RPC client available", "info")
    
    -- Debug: Sending message
    M.append_debug_message(current_buf, "Sending message: " .. message:sub(1, 50) .. "...", "debug")
    
    -- Start a progress indicator for long operations
    local progress_timer = nil
    local progress_count = 0
    local function update_progress()
        progress_count = progress_count + 1
        local dots = string.rep(".", progress_count % 4)
        M.append_debug_message(current_buf, "⏳ Waiting for AI response" .. dots, "debug")
    end
    
    -- Start progress updates every 3 seconds for debug mode
    progress_timer = vim.loop.new_timer()
    progress_timer:start(3000, 3000, vim.schedule_wrap(update_progress))
    
    -- Record start time for timing information
    local start_time = vim.uv.now()
    
    -- Add zigzag arrow to indicate request is being sent
    vim.api.nvim_buf_set_lines(current_buf, line_num + 1, line_num + 1, false, {"↯"})
    
    -- Force buffer update to show zigzag immediately
    vim.api.nvim_buf_call(current_buf, function()
        vim.cmd("redraw!")
    end)
    
    -- Set up retry callback for RPC client
    if M._rpc_client and M._rpc_client.set_retry_callback then
        M._rpc_client:set_retry_callback(function(attempt, max_attempts)
            -- Add retry notification to chat buffer
            vim.api.nvim_buf_set_lines(current_buf, line_num + 2, line_num + 2, false, {"🔄 Retry attempt " .. attempt .. "/" .. max_attempts})
        end)
    end
    
    -- Send the message using enhanced function
    local response, err = M.send_message_enhanced(message, "llama2")
    
    -- Stop progress updates
    if progress_timer then
        progress_timer:stop()
        progress_timer:close()
    end
    
    if not response then
        M.append_debug_message(current_buf, "Failed to send message: " .. tostring(err), "error")
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
    
    M.append_debug_message(current_buf, "✅ Successfully received response from AI", "success")
    
    -- Debug: Processing response
    M.append_debug_message(current_buf, "Processing response for buffer insertion", "debug")
    
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
    
    -- Debug: Inserting response
    M.append_debug_message(current_buf, "Inserting " .. #response_lines .. " lines into buffer", "debug")
    
    -- Insert response after the zigzag arrow (line_num + 2 since zigzag is at line_num + 1)
    vim.api.nvim_buf_set_lines(current_buf, line_num + 2, line_num + 2, false, response_lines)
    
    -- Move cursor to the end of the buffer (safe positioning)
    local buffer_line_count = vim.api.nvim_buf_line_count(current_buf)
    vim.api.nvim_win_set_cursor(0, {buffer_line_count, 0})
    
    -- Debug: Success
    M.append_debug_message(current_buf, "Message send process completed successfully", "success")
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

-- Add search to history
function M.add_to_search_history(query, search_type, results_count, timestamp)
    timestamp = timestamp or os.time()
    
    local history_entry = {
        query = query,
        type = search_type,
        results_count = results_count,
        timestamp = timestamp,
        date = os.date("%Y-%m-%d %H:%M:%S", timestamp)
    }
    
    -- Add to beginning of history
    table.insert(search_history, 1, history_entry)
    
    -- Keep history size manageable
    if #search_history > max_history_size then
        table.remove(search_history, #search_history)
    end
    
    -- Auto-save to disk
    M._save_search_history()
end

-- Get search history
function M.get_search_history()
    return search_history
end

-- Clear search history
function M.clear_search_history()
    search_history = {}
    
    -- Auto-save to disk
    M._save_search_history()
    
    vim.notify("Paragonic: Search history cleared", vim.log.levels.INFO)
end

-- Save a search
function M.save_search(name, query, search_type, content_type, limit, threshold)
    if not name or name == "" then
        vim.notify("Search name is required", vim.log.levels.WARN)
        return false
    end
    
    -- Check if name already exists
    for _, saved in ipairs(saved_searches) do
        if saved.name == name then
            vim.notify("A saved search with this name already exists", vim.log.levels.WARN)
            return false
        end
    end
    
    local saved_search = {
        name = name,
        query = query,
        type = search_type,
        content_type = content_type,
        limit = limit or 10,
        threshold = threshold or 0.0,
        created_at = os.time(),
        created_date = os.date("%Y-%m-%d %H:%M:%S")
    }
    
    table.insert(saved_searches, saved_search)
    
    -- Auto-save to disk
    M._save_saved_searches()
    
    vim.notify("Paragonic: Search '" .. name .. "' saved successfully", vim.log.levels.INFO)
    return true
end

-- Get saved searches
function M.get_saved_searches()
    return saved_searches
end

-- Delete a saved search
function M.delete_saved_search(name)
    for i, saved in ipairs(saved_searches) do
        if saved.name == name then
                    table.remove(saved_searches, i)
        
        -- Auto-save to disk
        M._save_saved_searches()
        
        vim.notify("Paragonic: Saved search '" .. name .. "' deleted", vim.log.levels.INFO)
        return true
        end
    end
    vim.notify("Saved search '" .. name .. "' not found", vim.log.levels.WARN)
    return false
end

-- Execute a saved search
function M.execute_saved_search(name)
    for _, saved in ipairs(saved_searches) do
        if saved.name == name then
            local results, err
            
            if saved.type == "basic" then
                results, err = M.search_embeddings(saved.query, saved.limit)
            elseif saved.type == "filtered" then
                results, err = M.find_similar_content(saved.query, saved.content_type, saved.limit, saved.threshold)
            elseif saved.type == "hybrid" then
                results, err = M.hybrid_search(saved.query, saved.content_type, saved.limit, saved.threshold, true)
            end
            
            if results then
                -- Add to history
                M.add_to_search_history(saved.query, saved.type, results.results and #results.results or 0)
                
                -- Display results
                M.display_search_results(results, "Saved Search: " .. saved.name)
                return true
            else
                vim.notify("Failed to execute saved search: " .. (err or "unknown error"), vim.log.levels.ERROR)
                return false
            end
        end
    end
    
    vim.notify("Saved search '" .. name .. "' not found", vim.log.levels.WARN)
    return false
end

-- Show search history
function M.show_search_history()
    if #search_history == 0 then
        vim.notify("Paragonic: No search history available", vim.log.levels.INFO)
        return
    end
    
    -- Create buffer for history
    local buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(buf, "paragonic://search-history")
    
    -- Format history
    local lines = {
        "📚 Search History",
        string.rep("─", 15),
        "",
        "Recent searches:",
        ""
    }
    
    for i, entry in ipairs(search_history) do
        local type_emoji = {
            basic = "🔍",
            filtered = "📁",
            hybrid = "🔗"
        }
        local emoji = type_emoji[entry.type] or "🔍"
        
        table.insert(lines, string.format("%d. %s %s (%d results) - %s", 
            i, emoji, entry.query, entry.results_count, entry.date))
    end
    
    -- Add footer
    table.insert(lines, "")
    table.insert(lines, string.rep("─", 50))
    table.insert(lines, "⌨️  Navigation: j/k to move, <CR> to repeat, d to delete, q to close")
    
    -- Set buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "swapfile", false)
    vim.api.nvim_buf_set_option(buf, "filetype", "paragonic-history")
    
    -- Create window
    local width = math.min(80, vim.o.columns - 4)
    local height = math.min(20, vim.o.lines - 4)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = " Search History ",
        title_pos = "center"
    })
    
    -- Set up keymaps
    vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "<cmd>close<CR>", {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", function()
        M.repeat_search_from_history(buf)
    end, {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "d", function()
        M.delete_from_search_history(buf)
    end, {noremap = true, silent = true})
    
    -- Set cursor to first entry
    vim.api.nvim_win_set_cursor(win, {5, 0})
end

-- Show saved searches
function M.show_saved_searches()
    if #saved_searches == 0 then
        vim.notify("Paragonic: No saved searches available", vim.log.levels.INFO)
        return
    end
    
    -- Create buffer for saved searches
    local buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(buf, "paragonic://saved-searches")
    
    -- Format saved searches
    local lines = {
        "💾 Saved Searches",
        string.rep("─", 17),
        "",
        "Your saved searches:",
        ""
    }
    
    for i, saved in ipairs(saved_searches) do
        local type_emoji = {
            basic = "🔍",
            filtered = "📁",
            hybrid = "🔗"
        }
        local emoji = type_emoji[saved.type] or "🔍"
        
        table.insert(lines, string.format("%d. %s %s (%s)", 
            i, emoji, saved.name, saved.query))
        table.insert(lines, string.format("   Type: %s, Limit: %d, Created: %s", 
            saved.type, saved.limit, saved.created_date))
        table.insert(lines, "")
    end
    
    -- Add footer
    table.insert(lines, string.rep("─", 50))
    table.insert(lines, "⌨️  Navigation: j/k to move, <CR> to execute, d to delete, q to close")
    
    -- Set buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "swapfile", false)
    vim.api.nvim_buf_set_option(buf, "filetype", "paragonic-saved")
    
    -- Create window
    local width = math.min(80, vim.o.columns - 4)
    local height = math.min(20, vim.o.lines - 4)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = " Saved Searches ",
        title_pos = "center"
    })
    
    -- Set up keymaps
    vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "<cmd>close<CR>", {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", function()
        M.execute_saved_search_from_list(buf)
    end, {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "d", function()
        M.delete_saved_search_from_list(buf)
    end, {noremap = true, silent = true})
    
    -- Set cursor to first entry
    vim.api.nvim_win_set_cursor(win, {5, 0})
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

-- Ensure data directory exists with error handling
function M._ensure_data_directory()
    local success, dir = pcall(function()
        return vim.fn.stdpath("data") .. "/paragonic"
    end)
    if not success then
        return false
    end
    
    local success2, is_dir = pcall(vim.fn.isdirectory, dir)
    if not success2 or is_dir == 0 then
        local success3 = pcall(vim.fn.mkdir, dir, "p")
        return success3
    end
    
    return true
end

-- Save data to JSON file
function M._save_to_json(data, file_path)
    M._ensure_data_directory()
    
    local json_string = vim.json.encode(data)
    if not json_string then
        vim.notify("Failed to encode data to JSON", vim.log.levels.ERROR)
        return false
    end
    
    local success = pcall(vim.fn.writefile, {json_string}, file_path)
    if not success then
        vim.notify("Failed to write data to " .. file_path, vim.log.levels.ERROR)
        return false
    end
    
    return true
end

-- Load data from JSON file with better error handling
function M._load_from_json(file_path)
    -- Use pcall for all file operations to prevent blocking
    local success, filereadable = pcall(vim.fn.filereadable, file_path)
    if not success or filereadable == 0 then
        return {}
    end
    
    local success2, lines = pcall(vim.fn.readfile, file_path)
    if not success2 or #lines == 0 then
        return {}
    end
    
    local json_string = table.concat(lines, "\n")
    local success3, data = pcall(vim.json.decode, json_string)
    
    if not success3 or not data then
        -- Don't show error notification during startup to avoid blocking
        return {}
    end
    
    return data
end

-- Save search history to disk
function M._save_search_history()
    return M._save_to_json(search_history, history_file)
end

-- Load search history from disk with error handling
function M._load_search_history()
    local data = M._load_from_json(history_file)
    
    -- Validate and clean data with error handling
    local cleaned_data = {}
    local success, result = pcall(function()
        for _, entry in ipairs(data) do
            if entry.query and entry.type and entry.results_count then
                -- Ensure all required fields are present
                entry.timestamp = entry.timestamp or os.time()
                entry.date = entry.date or os.date("%Y-%m-%d %H:%M:%S", entry.timestamp)
                table.insert(cleaned_data, entry)
            end
        end
        return cleaned_data
    end)
    
    if success then
        return result
    else
        return {}
    end
end

-- Save saved searches to disk
function M._save_saved_searches()
    return M._save_to_json(saved_searches, saved_searches_file)
end

-- Load saved searches from disk with error handling
function M._load_saved_searches()
    local data = M._load_from_json(saved_searches_file)
    
    -- Validate and clean data with error handling
    local cleaned_data = {}
    local success, result = pcall(function()
        for _, saved in ipairs(data) do
            if saved.name and saved.query and saved.type then
                -- Ensure all required fields are present
                saved.limit = saved.limit or 10
                saved.threshold = saved.threshold or 0.0
                saved.created_at = saved.created_at or os.time()
                saved.created_date = saved.created_date or os.date("%Y-%m-%d %H:%M:%S", saved.created_at)
                table.insert(cleaned_data, saved)
            end
        end
        return cleaned_data
    end)
    
    if success then
        return result
    else
        return {}
    end
end

-- Load all persistent data with error handling
function M._load_persistent_data()
    -- Use pcall to prevent any errors from blocking startup
    local success1, history = pcall(M._load_search_history)
    if success1 then
        search_history = history
    else
        search_history = {}
    end
    
    local success2, searches = pcall(M._load_saved_searches)
    if success2 then
        saved_searches = searches
    else
        saved_searches = {}
    end
    
    -- Use pcall for notification to prevent blocking
    pcall(function()
        vim.notify("Paragonic: Loaded " .. #search_history .. " history entries and " .. #saved_searches .. " saved searches", vim.log.levels.INFO)
    end)
end

-- Auto-save function
function M._auto_save()
    M._save_search_history()
    M._save_saved_searches()
end

-- Export data to a file
function M.export_data()
    local export_path = vim.fn.input("Export to file: ")
    if export_path == "" then
        vim.notify("Export path is required", vim.log.levels.WARN)
        return
    end
    
    local export_data = {
        search_history = search_history,
        saved_searches = saved_searches,
        export_date = os.date("%Y-%m-%d %H:%M:%S"),
        version = "1.0"
    }
    
    local success = M._save_to_json(export_data, export_path)
    if success then
        vim.notify("Paragonic: Data exported successfully to " .. export_path, vim.log.levels.INFO)
    else
        vim.notify("Failed to export data", vim.log.levels.ERROR)
    end
end

-- Import data from a file
function M.import_data()
    local import_path = vim.fn.input("Import from file: ")
    if import_path == "" then
        vim.notify("Import path is required", vim.log.levels.WARN)
        return
    end
    
    if vim.fn.filereadable(import_path) == 0 then
        vim.notify("Import file does not exist", vim.log.levels.ERROR)
        return
    end
    
    local import_data = M._load_from_json(import_path)
    if not import_data or not import_data.search_history or not import_data.saved_searches then
        vim.notify("Invalid import file format", vim.log.levels.ERROR)
        return
    end
    
    -- Validate and merge data
    local imported_history = 0
    local imported_saved = 0
    
    -- Import search history
    for _, entry in ipairs(import_data.search_history) do
        if entry.query and entry.type and entry.results_count then
            table.insert(search_history, entry)
            imported_history = imported_history + 1
        end
    end
    
    -- Import saved searches
    for _, saved in ipairs(import_data.saved_searches) do
        if saved.name and saved.query and saved.type then
            -- Check for duplicates
            local exists = false
            for _, existing in ipairs(saved_searches) do
                if existing.name == saved.name then
                    exists = true
                    break
                end
            end
            
            if not exists then
                table.insert(saved_searches, saved)
                imported_saved = imported_saved + 1
            end
        end
    end
    
    -- Save to disk
    M._auto_save()
    
    vim.notify(string.format("Paragonic: Imported %d history entries and %d saved searches", imported_history, imported_saved), vim.log.levels.INFO)
end

-- Backup data
function M.backup_data()
    local backup_dir = vim.fn.stdpath("data") .. "/paragonic/backups"
    if vim.fn.isdirectory(backup_dir) == 0 then
        vim.fn.mkdir(backup_dir, "p")
    end
    
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local backup_path = backup_dir .. "/backup_" .. timestamp .. ".json"
    
    local backup_data = {
        search_history = search_history,
        saved_searches = saved_searches,
        backup_date = os.date("%Y-%m-%d %H:%M:%S"),
        version = "1.0"
    }
    
    local success = M._save_to_json(backup_data, backup_path)
    if success then
        vim.notify("Paragonic: Backup created successfully: " .. backup_path, vim.log.levels.INFO)
    else
        vim.notify("Failed to create backup", vim.log.levels.ERROR)
    end
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
function M.initialize_mcp_server()
    local initialize_result = {
        protocol_version = M.mcp_server.protocol_version,
        capabilities = M.mcp_server.capabilities,
        server_info = M.mcp_server.server_info
    }
    
    vim.notify("MCP Server initialized with protocol version: " .. initialize_result.protocol_version, vim.log.levels.INFO)
    return initialize_result
end

-- List MCP Resources
function M.list_mcp_resources()
    return {
        {
            uri = "neovim://session",
            name = "Neovim Session",
            description = "Current Neovim session information",
            mime_type = "application/json"
        },
        {
            uri = "neovim://buffers",
            name = "Neovim Buffers", 
            description = "List of all buffers in the session",
            mime_type = "application/json"
        },
        {
            uri = "neovim://windows",
            name = "Neovim Windows",
            description = "List of all windows in the session", 
            mime_type = "application/json"
        },
        {
            uri = "neovim://marks",
            name = "Neovim Marks",
            description = "List of all marks in the session",
            mime_type = "application/json"
        },
        {
            uri = "neovim://registers",
            name = "Neovim Registers",
            description = "List of all registers and their content",
            mime_type = "application/json"
        },
        {
            uri = "neovim://macros",
            name = "Neovim Macros",
            description = "List of all recorded macros",
            mime_type = "application/json"
        },
        {
            uri = "neovim://plugins",
            name = "Neovim Plugins",
            description = "List of all loaded plugins",
            mime_type = "application/json"
        }
    }
end

-- List MCP Tools
function M.list_mcp_tools()
    return {
        {
            name = "agent_edit_file",
            description = "Edit a file in the current Neovim session",
            input_schema = {
                type = "object",
                properties = {
                    file_path = {type = "string"},
                    line_number = {type = "integer"},
                    content = {type = "string"}
                },
                required = {"file_path"}
            }
        },
        {
            name = "agent_create_file", 
            description = "Create a new file in the current Neovim session",
            input_schema = {
                type = "object",
                properties = {
                    file_name = {type = "string"},
                    content = {type = "string"},
                    open_in_window = {type = "boolean"}
                },
                required = {"file_name"}
            }
        },
        {
            name = "agent_save_file",
            description = "Save a file to disk",
            input_schema = {
                type = "object", 
                properties = {
                    file_path = {type = "string"},
                    force = {type = "boolean"}
                }
            }
        }
    }
end

-- Handle MCP messages
function M.handle_mcp_message(message)
    local id = message.id
    local method = message.method
    local params = message.params or {}
    
    if method == "initialize" then
        return {
            id = id,
            result = M.initialize_mcp_server()
        }
    elseif method == "resources/list" then
        return {
            id = id,
            result = {
                resources = M.list_mcp_resources()
            }
        }
    elseif method == "tools/list" then
        return {
            id = id,
            result = {
                tools = M.list_mcp_tools()
            }
        }
    elseif method == "tools/call" then
        return M.handle_tool_call(id, params)
    elseif method == "resources/read" then
        return M.handle_resource_read(id, params)
    else
        return {
            id = id,
            error = {
                code = -32601,
                message = "Method not found: " .. method
            }
        }
    end
end

-- Handle MCP resource reading
function M.handle_resource_read(id, params)
    local uri = params.uri
    if not uri then
        return {
            id = id,
            error = {
                code = -32602,
                message = "URI is required for resources/read"
            }
        }
    end
    
    local result = M.read_mcp_resource(uri)
    if result.error then
        return {
            id = id,
            error = result.error
        }
    else
        return {
            id = id,
            result = result
        }
    end
end

-- Read MCP resource content
function M.read_mcp_resource(uri)
    if uri == "neovim://session" then
        local session_info = M.get_agent_session_info()
        return {
            contents = {
                {
                    uri = uri,
                    mime_type = "application/json",
                    text = vim.json.encode(session_info)
                }
            }
        }
    elseif uri == "neovim://buffers" then
        local session_info = M.get_agent_session_info()
        return {
            contents = {
                {
                    uri = uri,
                    mime_type = "application/json",
                    text = vim.json.encode(session_info.buffers)
                }
            }
        }
    elseif uri == "neovim://windows" then
        local session_info = M.get_agent_session_info()
        return {
            contents = {
                {
                    uri = uri,
                    mime_type = "application/json",
                    text = vim.json.encode(session_info.windows)
                }
            }
        }
    elseif uri == "neovim://marks" then
        local marks_info = M.get_marks_info()
        return {
            contents = {
                {
                    uri = uri,
                    mime_type = "application/json",
                    text = vim.json.encode(marks_info)
                }
            }
        }
    elseif uri == "neovim://registers" then
        local registers_info = M.get_registers_info()
        return {
            contents = {
                {
                    uri = uri,
                    mime_type = "application/json",
                    text = vim.json.encode(registers_info)
                }
            }
        }
    elseif uri == "neovim://macros" then
        local macros_info = M.get_macros_info()
        return {
            contents = {
                {
                    uri = uri,
                    mime_type = "application/json",
                    text = vim.json.encode(macros_info)
                }
            }
        }
    elseif uri == "neovim://plugins" then
        local plugins_info = M.get_plugins_info()
        return {
            contents = {
                {
                    uri = uri,
                    mime_type = "application/json",
                    text = vim.json.encode(plugins_info)
                }
            }
        }
    else
        return {
            error = {
                code = -32602,
                message = "Resource not found: " .. uri
            }
        }
    end
end

-- Validate resource content
function M.validate_resource_content(content)
    if not content.uri then
        return false, "Missing URI"
    end
    if not content.mime_type then
        return false, "Missing MIME type"
    end
    if not content.text then
        return false, "Missing text content"
    end
    
    -- Validate JSON for JSON MIME types
    if content.mime_type == "application/json" then
        local success, _ = pcall(vim.json.decode, content.text)
        if not success then
            return false, "Invalid JSON content"
        end
    end
    
    return true, nil
end

-- MCP Progress tracking state
M.progress_state = {
    active_operations = {},
    next_progress_id = 1
}

-- Create a progress notification
function M.create_progress_notification(progress_id, message, percentage, done)
    return {
        method = "notifications/progress",
        params = {
            id = progress_id,
            message = message,
            percentage = percentage or 0,
            done = done or false
        }
    }
end

-- Start a progress operation
function M.start_progress_operation(operation_name, initial_message)
    local progress_id = "progress-" .. M.progress_state.next_progress_id
    M.progress_state.next_progress_id = M.progress_state.next_progress_id + 1
    
    M.progress_state.active_operations[progress_id] = {
        name = operation_name,
        message = initial_message,
        percentage = 0,
        start_time = os.time()
    }
    
    return progress_id, M.create_progress_notification(progress_id, initial_message, 0, false)
end

-- Update progress
function M.update_progress(progress_id, message, percentage)
    local operation = M.progress_state.active_operations[progress_id]
    if not operation then
        return nil, "Progress operation not found: " .. progress_id
    end
    
    operation.message = message or operation.message
    operation.percentage = percentage or operation.percentage
    
    return M.create_progress_notification(progress_id, operation.message, operation.percentage, false)
end

-- Complete progress operation
function M.complete_progress_operation(progress_id, final_message)
    local operation = M.progress_state.active_operations[progress_id]
    if not operation then
        return nil, "Progress operation not found: " .. progress_id
    end
    
    local final_notification = M.create_progress_notification(progress_id, final_message or operation.message, 100, true)
    M.progress_state.active_operations[progress_id] = nil
    
    return final_notification
end

-- Format progress summary
function M.format_progress_summary(progress_notifications)
    local summary = {
        total_notifications = #progress_notifications,
        start_percentage = progress_notifications[1] and progress_notifications[1].params.percentage or 0,
        end_percentage = progress_notifications[#progress_notifications] and progress_notifications[#progress_notifications].params.percentage or 0,
        final_message = progress_notifications[#progress_notifications] and progress_notifications[#progress_notifications].params.message or "",
        completed = progress_notifications[#progress_notifications] and progress_notifications[#progress_notifications].params.done or false
    }
    return summary
end

-- Handle MCP tool calls with enhanced error handling and metadata
function M.handle_tool_call(id, params)
    local tool_name = params.name
    local arguments = params.arguments or {}
    
    -- Validate required parameters
    if not tool_name then
        return {
            id = id,
            error = {
                code = -32602,
                message = "Tool name is required"
            }
        }
    end
    
    -- Start progress for long-running operations
    local progress_id = nil
    local progress_notifications = {}
    
    if tool_name == "agent_edit_file" then
        local file_path = arguments.file_path
        local line_number = arguments.line_number or 1
        local content = arguments.content or ""
        
        if not file_path then
            return {
                id = id,
                error = {
                    code = -32602,
                    message = "file_path is required for agent_edit_file"
                }
            }
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

-- Display MCP resources in a floating window
function M.display_mcp_resources(resources)
    local lines = {
        "📋 MCP Resources",
        string.rep("─", 30),
        ""
    }
    
    for i, resource in ipairs(resources) do
        table.insert(lines, string.format("%d. %s", i, resource.name))
        table.insert(lines, string.format("   URI: %s", resource.uri))
        table.insert(lines, string.format("   Description: %s", resource.description))
        table.insert(lines, string.format("   MIME Type: %s", resource.mime_type))
        table.insert(lines, "")
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
    
    vim.notify("Displayed " .. #resources .. " MCP resources", vim.log.levels.INFO)
end

-- Display MCP tools in a floating window
function M.display_mcp_tools(tools)
    local lines = {
        "🔧 MCP Tools",
        string.rep("─", 30),
        ""
    }
    
    for i, tool in ipairs(tools) do
        table.insert(lines, string.format("%d. %s", i, tool.name))
        table.insert(lines, string.format("   Description: %s", tool.description))
        
        -- Show input schema
        if tool.input_schema and tool.input_schema.properties then
            table.insert(lines, "   Parameters:")
            for param_name, param_schema in pairs(tool.input_schema.properties) do
                local required = tool.input_schema.required and 
                    vim.fn.index(tool.input_schema.required, param_name) >= 0
                local required_mark = required and " (required)" or " (optional)"
                table.insert(lines, string.format("     - %s: %s%s", 
                    param_name, param_schema.type, required_mark))
            end
        end
        table.insert(lines, "")
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
    
    vim.notify("Displayed " .. #tools .. " MCP tools", vim.log.levels.INFO)
end

-- Display MCP resource content in a floating window
function M.display_resource_content(uri, result)
    local lines = {
        "📄 MCP Resource Content: " .. uri,
        string.rep("─", 50),
        ""
    }
    
    if result.error then
        table.insert(lines, "❌ Error: " .. result.error.message)
        table.insert(lines, "Code: " .. result.error.code)
    elseif result.contents then
        for i, content in ipairs(result.contents) do
            table.insert(lines, string.format("Content %d:", i))
            table.insert(lines, "  URI: " .. content.uri)
            table.insert(lines, "  MIME Type: " .. content.mime_type)
            table.insert(lines, "  Content:")
            
            -- Format JSON content for display
            if content.mime_type == "application/json" then
                local success, decoded = pcall(vim.json.decode, content.text)
                if success then
                    local formatted = vim.json.encode(decoded, {indent = 2})
                    for line in formatted:gmatch("[^\r\n]+") do
                        table.insert(lines, "    " .. line)
                    end
                else
                    table.insert(lines, "    [Invalid JSON]")
                end
            else
                -- For non-JSON content, show first few lines
                local content_lines = {}
                for line in content.text:gmatch("[^\r\n]+") do
                    table.insert(content_lines, line)
                    if #content_lines >= 10 then
                        table.insert(content_lines, "...")
                        break
                    end
                end
                for _, line in ipairs(content_lines) do
                    table.insert(lines, "    " .. line)
                end
            end
            table.insert(lines, "")
        end
    else
        table.insert(lines, "No content available")
    end
    
    -- Create floating window
    local width = 100
    local height = math.min(#lines + 2, 25)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "filetype", "json")
    
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
    
    vim.notify("Displayed resource content for: " .. uri, vim.log.levels.INFO)
end

-- Display sampled content in a floating window
function M.display_sampled_content(uri, result, criteria)
    local lines = {
        "🔍 MCP Sampled Content: " .. uri,
        string.rep("─", 50),
        ""
    }
    
    if criteria then
        table.insert(lines, "📋 Sampling Criteria:")
        for key, value in pairs(criteria) do
            table.insert(lines, "  " .. key .. ": " .. tostring(value))
        end
        table.insert(lines, "")
    end
    
    if result then
        table.insert(lines, "📊 Sampled Data:")
        local formatted = vim.json.encode(result, {indent = 2})
        for line in formatted:gmatch("[^\r\n]+") do
            table.insert(lines, "  " .. line)
        end
    else
        table.insert(lines, "❌ No sampled content available")
    end
    
    -- Create floating window
    local width = 100
    local height = math.min(#lines + 2, 25)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "filetype", "json")
    
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
    
    vim.notify("Displayed sampled content for: " .. uri, vim.log.levels.INFO)
end

-- Display resource roots in a floating window
function M.display_resource_roots(uri, roots)
    local lines = {
        "🌳 MCP Resource Roots: " .. uri,
        string.rep("─", 50),
        ""
    }
    
    if roots and #roots > 0 then
        table.insert(lines, "📁 Available Roots (" .. #roots .. "):")
        for i, root in ipairs(roots) do
            table.insert(lines, "")
            table.insert(lines, "  " .. i .. ". " .. root.name)
            table.insert(lines, "     URI: " .. root.uri)
            if root.description then
                table.insert(lines, "     Description: " .. root.description)
            end
        end
    else
        table.insert(lines, "❌ No roots available")
    end
    
    -- Create floating window
    local width = 100
    local height = math.min(#lines + 2, 25)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "filetype", "json")
    
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
    
    vim.notify("Displayed resource roots for: " .. uri, vim.log.levels.INFO)
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

-- Helper to get all Neovim marks with context
function M.get_marks_info()
    local marks = {}
    local mark_list = vim.fn.getmarklist()
    for _, mark_data in ipairs(mark_list) do
        local mark = mark_data.mark
        local pos = mark_data.pos
        local file = mark_data.file
        if pos and pos[1] > 0 then -- Valid mark
            local buf = pos[1]
            local line = pos[2]
            local col = pos[3]
            local context_lines = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)
            local context = context_lines[1] or ""
            table.insert(marks, {
                mark = mark,
                buffer_id = buf,
                file_path = file,
                line = line,
                column = col,
                context = context,
                timestamp = os.time()
            })
        end
    end
    return marks
end

-- Helper to get all Neovim registers with content
function M.get_registers_info()
    local registers = {}
    local register_names = {"\"", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"}
    
    for _, reg in ipairs(register_names) do
        local content = vim.fn.getreg(reg)
        local reg_type = vim.fn.getregtype(reg)
        
        if content and content ~= "" then
            table.insert(registers, {
                register = reg,
                content = content,
                type = reg_type,
                length = #content,
                timestamp = os.time()
            })
        end
    end
    
    return registers
end

-- Helper to get all Neovim macros
function M.get_macros_info()
    local macros = {}
    local macro_registers = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"}
    
    for _, reg in ipairs(macro_registers) do
        local macro = vim.fn.getreg(reg)
        if macro and macro ~= "" and macro:match("^[a-zA-Z0-9@:]*$") then
            -- This looks like a macro (contains only letters, numbers, @, :)
            table.insert(macros, {
                register = reg,
                macro = macro,
                description = "Macro in register " .. reg,
                timestamp = os.time()
            })
        end
    end
    
    return macros
end

-- Helper to get all Neovim plugins
function M.get_plugins_info()
    local plugins = {}
    
    -- Get loaded plugins from g:loaded_plugins
    local loaded_plugins = vim.g.loaded_plugins or {}
    for plugin_name, loaded in pairs(loaded_plugins) do
        if loaded then
            table.insert(plugins, {
                name = plugin_name,
                loaded = true,
                path = "g:loaded_plugins",
                timestamp = os.time()
            })
        end
    end
    
    -- Get plugins from runtime path
    local runtime_path = vim.api.nvim_get_option("runtimepath")
    local paths = vim.fn.split(runtime_path, ",")
    
    for _, path in ipairs(paths) do
        local plugin_files = vim.fn.globpath(path, "**/plugin/*.vim", true, true)
        for _, plugin_file in ipairs(plugin_files) do
            local plugin_name = plugin_file:match("([^/]+)/plugin/[^/]+%.vim$")
            if plugin_name then
                -- Check if not already added
                local exists = false
                for _, existing_plugin in ipairs(plugins) do
                    if existing_plugin.name == plugin_name then
                        exists = true
                        break
                    end
                end
                
                if not exists then
                    table.insert(plugins, {
                        name = plugin_name,
                        loaded = true,
                        path = plugin_file,
                        timestamp = os.time()
                    })
                end
            end
        end
    end
    
    return plugins
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
function M.get_configuration()
    local ok, config = pcall(vim.api.nvim_get_var, "g:paragonic_config")
    if not ok or type(config) ~= "table" then config = {} end
    for key, schema in pairs(M.config_schema) do
        if config[key] == nil and schema.default ~= nil then
            config[key] = schema.default
        end
    end
    return config
end

-- Validate configuration value
function M.validate_config_value(key, value)
    local schema = M.config_schema[key]
    if not schema then
        return false, "Unknown configuration key: " .. key
    end
    if schema.type == "string" and type(value) ~= "string" then
        return false, "Value must be a string for key: " .. key
    elseif schema.type == "integer" and type(value) ~= "number" then
        return false, "Value must be a number for key: " .. key
    elseif schema.type == "boolean" and type(value) ~= "boolean" then
        return false, "Value must be a boolean for key: " .. key
    end
    if schema.enum and type(value) == "string" then
        local valid = false
        for _, enum_value in ipairs(schema.enum) do
            if value == enum_value then valid = true; break end
        end
        if not valid then
            return false, "Value must be one of: " .. table.concat(schema.enum, ", ")
        end
    end
    if schema.minimum and type(value) == "number" and value < schema.minimum then
        return false, "Value must be at least " .. schema.minimum .. " for key: " .. key
    end
    if schema.maximum and type(value) == "number" and value > schema.maximum then
        return false, "Value must be at most " .. schema.maximum .. " for key: " .. key
    end
    return true, nil
end

-- Set configuration value (with validation)
function M.set_configuration_value(key, value)
    local valid, err = M.validate_config_value(key, value)
    if not valid then return false, err end
    local config = M.get_configuration()
    config[key] = value
    vim.api.nvim_set_var("g:paragonic_config", config)
    return true, nil
end

-- Save configuration to file
function M.save_configuration_to_file(config, file_path)
    local config_dir = vim.fn.fnamemodify(file_path, ":h")
    if not vim.fn.isdirectory(config_dir) then
        vim.fn.mkdir(config_dir, "p")
    end
    local config_json = vim.json.encode(config)
    vim.fn.writefile({config_json}, file_path)
    return true
end

-- Load configuration from file
function M.load_configuration_from_file(file_path)
    if vim.fn.filereadable(file_path) == 0 then
        return nil, "Configuration file not found: " .. file_path
    end
    local lines = vim.fn.readfile(file_path)
    if #lines == 0 then
        return nil, "Configuration file is empty: " .. file_path
    end
    local ok, config = pcall(vim.json.decode, lines[1])
    if not ok then
        return nil, "Invalid JSON in configuration file: " .. file_path
    end
    return config
end

-- Get configuration schema as MCP resource
function M.get_configuration_schema()
    local schema_resources = {}
    for key, schema in pairs(M.config_schema) do
        table.insert(schema_resources, {
            key = key,
            type = schema.type,
            description = schema.description,
            default = schema.default,
            enum = schema.enum,
            minimum = schema.minimum,
            maximum = schema.maximum
        })
    end
    return schema_resources
end

-- Expose configuration as MCP resource
function M.get_configuration_as_resource()
    local config = M.get_configuration()
    local schema = M.get_configuration_schema()
    return {
        uri = "neovim://configuration",
        name = "Neovim Configuration",
        description = "Current configuration settings and schema",
        mime_type = "application/json",
        content = {
            config = config,
            schema = schema,
            timestamp = os.time()
        }
    }
end

-- Handle MCP configuration methods
function M.handle_configuration_method(method, params)
    if method == "config/get" then
        local config = M.get_configuration()
        return { config = config }
    elseif method == "config/set" then
        local key = params.key
        local value = params.value
        if not key then
            return { error = { code = -32602, message = "Configuration key is required" } }
        end
        local success, err = M.set_configuration_value(key, value)
        if success then
            return { success = true, message = "Configuration updated successfully" }
        else
            return { error = { code = -32602, message = err } }
        end
    elseif method == "config/schema" then
        local schema = M.get_configuration_schema()
        return { schema = schema }
    elseif method == "config/validate" then
        local key = params.key
        local value = params.value
        if not key then
            return { error = { code = -32602, message = "Configuration key is required" } }
        end
        local valid, err = M.validate_config_value(key, value)
        return { valid = valid, error = err }
    else
        return { error = { code = -32601, message = "Unknown configuration method: " .. tostring(method) } }
    end
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
local old_handle_mcp_message = M.handle_mcp_message
function M.handle_mcp_message(message)
    if message.method and message.method:match("^config/") then
        return M.handle_configuration_method(message.method, message.params or {})
    end
    if old_handle_mcp_message then
        return old_handle_mcp_message(message)
    end
    return { error = { code = -32601, message = "Unknown MCP method: " .. tostring(message.method) } }
end

-- Helper to get all Neovim commands
function M.get_commands_info()
    local commands = vim.api.nvim_get_commands({})
    local result = {}
    for name, cmd in pairs(commands) do
        table.insert(result, {
            name = name,
            definition = cmd.definition,
            nargs = cmd.nargs,
            bang = cmd.bang
        })
    end
    return result
end

-- Helper to get all Neovim autocommands
function M.get_autocommands_info()
    local autocmds = vim.api.nvim_get_autocmds({})
    local result = {}
    for _, ac in ipairs(autocmds) do
        table.insert(result, {
            event = ac.event,
            group = ac.group,
            group_name = ac.group_name,
            pattern = ac.pattern,
            command = ac.command,
            desc = ac.desc
        })
    end
    return result
end

-- Sample resource content based on criteria
function M.sample_resource(uri, criteria)
    if uri == "neovim://buffers" then
        local buffers = M.get_buffers_info()
        
        -- Apply sampling criteria
        if criteria and criteria.limit then
            local sampled = {}
            for i = 1, math.min(criteria.limit, #buffers) do
                table.insert(sampled, buffers[i])
            end
            return sampled
        end
        
        -- Apply filters
        if criteria and criteria.filter then
            local filtered = {}
            for _, buffer in ipairs(buffers) do
                local matches = true
                
                if criteria.filter.file_type and buffer.file_type ~= criteria.filter.file_type then
                    matches = false
                end
                
                if criteria.filter.name_pattern and not buffer.name:match(criteria.filter.name_pattern) then
                    matches = false
                end
                
                if matches then
                    table.insert(filtered, buffer)
                end
            end
            return filtered
        end
        
        return buffers
    elseif uri == "neovim://session" then
        local session = M.get_session_info()
        
        -- Apply field selection
        if criteria and criteria.fields then
            local sampled = {}
            for _, field in ipairs(criteria.fields) do
                if session[field] then
                    sampled[field] = session[field]
                end
            end
            return sampled
        end
        
        return session
    else
        return nil
    end
end

-- Define resource roots for context boundaries
function M.define_resource_roots(uri, options)
    if uri == "neovim://buffers" then
        local roots = {}
        
        if options and options.buffer_ids then
            for _, buf_id in ipairs(options.buffer_ids) do
                local buf_name = vim.api.nvim_buf_get_name(buf_id)
                if buf_name and buf_name ~= "" then
                    table.insert(roots, {
                        uri = "file://" .. buf_name,
                        name = vim.fn.fnamemodify(buf_name, ":t"),
                        description = "Buffer " .. buf_id .. ": " .. buf_name
                    })
                end
            end
        end
        
        if options and options.file_patterns then
            local buffers = vim.api.nvim_list_bufs()
            for _, buf_id in ipairs(buffers) do
                local buf_name = vim.api.nvim_buf_get_name(buf_id)
                if buf_name and buf_name ~= "" then
                    for _, pattern in ipairs(options.file_patterns) do
                        if buf_name:match(pattern) then
                            table.insert(roots, {
                                uri = "file://" .. buf_name,
                                name = vim.fn.fnamemodify(buf_name, ":t"),
                                description = "Pattern match: " .. buf_name
                            })
                            break
                        end
                    end
                end
            end
        end
        
        return roots
    elseif uri == "neovim://session" then
        local roots = {}
        
        if options and options.current_only then
            local cwd = vim.fn.getcwd()
            table.insert(roots, {
                uri = "file://" .. cwd,
                name = "Current Directory",
                description = "Current working directory: " .. cwd
            })
        end
        
        return roots
    else
        return {}
    end
end

-- Handle MCP sampling requests from external agents
function M.handle_sampling_request(request)
    local uri = request.uri
    local criteria = request.criteria or {}
    
    local sampled_data = M.sample_resource(uri, criteria)
    
    if sampled_data then
        return {
            id = request.id,
            result = {
                content = {
                    {
                        type = "text",
                        text = vim.json.encode(sampled_data)
                    }
                },
                metadata = {
                    uri = uri,
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
local old_handle_mcp_message = M.handle_mcp_message
function M.handle_mcp_message(message)
    if message.method == "sampling/request" then
        return M.handle_sampling_request(message)
    elseif message.method == "roots/list" then
        return M.handle_roots_request(message)
    elseif message.method == "cancel" or message.method == "cancel/list" then
        return M.handle_cancellation_message(message)
    end
    
    if old_handle_mcp_message then
        return old_handle_mcp_message(message)
    end
    return { error = { code = -32601, message = "Unknown MCP method: " .. tostring(message.method) } }
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
function M.handle_tool_call_with_cancellation(id, params)
    local tool_name = params.name
    local arguments = params.arguments or {}
    
    if not tool_name then
        return {
            id = id,
            error = {
                code = -32602,
                message = "Tool name is required"
            }
        }
    end
    
    -- Register operation for cancellation
    local operation_id = M.register_cancellable_operation("tool_call", "Tool: " .. tool_name)
    
    if tool_name == "agent_edit_file" then
        local file_path = arguments.file_path
        local line_number = arguments.line_number or 1
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

-- Extend MCP message handler for cancellation
local old_handle_mcp_message = M.handle_mcp_message
function M.handle_mcp_message(message)
    if message.method == "cancel" or message.method == "cancel/list" then
        return M.handle_cancellation_message(message)
    end
    
    if old_handle_mcp_message then
        return old_handle_mcp_message(message)
    end
    return { error = { code = -32601, message = "Unknown MCP method: " .. tostring(message.method) } }
end

return M 