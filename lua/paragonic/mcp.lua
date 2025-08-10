--[[
Paragonic MCP Module
Handles MCP (Model Context Protocol) functionality
--]]

local M = {}

-- MCP state
M.mcp_server_initialized = false
M.mcp_resources = {}
M.mcp_tools = {}

-- MCP Cancellation state management
M.cancellation_state = {
    active_operations = {},
    next_operation_id = 1
}

-- Initialize MCP server
function M.initialize_mcp_server()
    if M.mcp_server_initialized then
        vim.notify("MCP server already initialized", vim.log.levels.INFO)
        return true
    end
    
    -- Initialize MCP resources
    M.mcp_resources = {
        {
            uri = "neovim://buffers",
            name = "Neovim Buffers",
            description = "All open buffers in the current Neovim session",
            mimeType = "application/json"
        },
        {
            uri = "neovim://session",
            name = "Neovim Session",
            description = "Current Neovim session information",
            mimeType = "application/json"
        },
        {
            uri = "neovim://commands",
            name = "Neovim Commands",
            description = "Available Neovim commands",
            mimeType = "application/json"
        },
        {
            uri = "neovim://autocommands",
            name = "Neovim Autocommands",
            description = "Registered autocommands",
            mimeType = "application/json"
        }
    }
    
    -- Initialize MCP tools with enhanced pattern information
    M.mcp_tools = {
        {
            name = "agent_edit_file",
            description = "Edit a file in the current Neovim session",
            inputSchema = {
                type = "object",
                properties = {
                    file_path = {
                        type = "string",
                        description = "Path to the file to edit"
                    },
                    line_number = {
                        type = "integer",
                        description = "Line number to edit (1-based)"
                    },
                    content = {
                        type = "string",
                        description = "Content to insert at the specified line"
                    }
                },
                required = {"file_path", "line_number"}
            },
            patterns = {
                {
                    pattern_id = "session_summary_generation",
                    relationship_type = "input",
                    description = "Used to modify files during session summary generation"
                },
                {
                    pattern_id = "activity_labeling",
                    relationship_type = "enhance",
                    description = "Enhances activity labeling by tracking file modifications"
                }
            },
            usage_guidance = "Use this tool when you need to modify file content. Always specify the file_path and line_number. The content parameter is optional and will replace the entire line if provided.",
            success_metrics = {
                success_rate = 0.95,
                usage_count = 0,
                last_used = nil
            }
        }
    }
    
    M.mcp_server_initialized = true
    vim.notify("MCP server initialized successfully", vim.log.levels.INFO)
    return true
end

-- List MCP resources
function M.list_mcp_resources()
    if not M.mcp_server_initialized then
        M.initialize_mcp_server()
    end
    
    return M.mcp_resources
end

-- List MCP tools
function M.list_mcp_tools()
    if not M.mcp_server_initialized then
        M.initialize_mcp_server()
    end
    
    return M.mcp_tools
end

-- Read MCP resource
function M.read_mcp_resource(uri)
    if not M.mcp_server_initialized then
        M.initialize_mcp_server()
    end
    
    if uri == "neovim://buffers" then
        return M.get_buffers_info()
    elseif uri == "neovim://session" then
        return M.get_session_info()
    elseif uri == "neovim://commands" then
        return M.get_commands_info()
    elseif uri == "neovim://autocommands" then
        return M.get_autocommands_info()
    else
        return nil, "Unknown resource URI: " .. uri
    end
end

-- Get buffers information
function M.get_buffers_info()
    local buffers = vim.api.nvim_list_bufs()
    local result = {}
    
    for _, buf in ipairs(buffers) do
        if vim.api.nvim_buf_is_valid(buf) then
            local buf_name = vim.api.nvim_buf_get_name(buf)
            local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
            local modifiable = vim.api.nvim_buf_get_option(buf, "modifiable")
            local line_count = vim.api.nvim_buf_line_count(buf)
            local modified = vim.api.nvim_buf_get_option(buf, "modified")
            
            table.insert(result, {
                id = buf,
                name = buf_name,
                type = buftype,
                modifiable = modifiable,
                line_count = line_count,
                modified = modified,
                is_current = (buf == vim.api.nvim_get_current_buf())
            })
        end
    end
    
    return result
end

-- Get session information
function M.get_session_info()
    return {
        current_file = vim.fn.expand("%:p"),
        current_directory = vim.fn.getcwd(),
        buffer_count = #vim.api.nvim_list_bufs(),
        window_count = #vim.api.nvim_list_wins(),
        tab_count = #vim.api.nvim_list_tabpages(),
        mode = vim.fn.mode(),
        cursor_position = vim.api.nvim_win_get_cursor(0),
        terminal_size = {
            columns = vim.o.columns,
            lines = vim.o.lines
        },
        timestamp = os.time()
    }
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
                
                if criteria.filter.file_type and buffer.type ~= criteria.filter.file_type then
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

-- Handle MCP message
function M.handle_mcp_message(message)
    if message.method == "sampling/request" then
        return M.handle_sampling_request(message)
    elseif message.method == "roots/list" then
        return M.handle_roots_request(message)
    elseif message.method == "cancel" or message.method == "cancel/list" then
        return M.handle_cancellation_message(message)
    end
    
    return { error = { code = -32601, message = "Unknown MCP method: " .. tostring(message.method) } }
end

-- Display MCP resources
function M.display_mcp_resources(resources)
    -- Create buffer for resources
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "swapfile", false)
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    
    -- Format resources
    local lines = {
        "# MCP Resources",
        "",
        "Available resources:",
        ""
    }
    
    for _, resource in ipairs(resources) do
        table.insert(lines, "## " .. resource.name)
        table.insert(lines, "**URI:** " .. resource.uri)
        table.insert(lines, "**Description:** " .. resource.description)
        table.insert(lines, "**MIME Type:** " .. resource.mimeType)
        table.insert(lines, "")
    end
    
    -- Set buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Open buffer in split
    vim.api.nvim_command("split")
    vim.api.nvim_set_current_buf(buf)
    
    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

-- Display MCP tools
function M.display_mcp_tools(tools)
    -- Create buffer for tools
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "swapfile", false)
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    
    -- Format tools
    local lines = {
        "# MCP Tools",
        "",
        "Available tools:",
        ""
    }
    
    for _, tool in ipairs(tools) do
        table.insert(lines, "## " .. tool.name)
        table.insert(lines, "**Description:** " .. tool.description)
        if tool.inputSchema then
            table.insert(lines, "**Input Schema:** " .. vim.inspect(tool.inputSchema))
        end
        table.insert(lines, "")
    end
    
    -- Set buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Open buffer in split
    vim.api.nvim_command("split")
    vim.api.nvim_set_current_buf(buf)
    
    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

-- Display resource content
function M.display_resource_content(uri, result)
    -- Create buffer for resource content
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "swapfile", false)
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    
    -- Format content
    local lines = {
        "# Resource Content: " .. uri,
        "",
        "Content:",
        ""
    }
    
    if type(result) == "table" then
        table.insert(lines, vim.inspect(result))
    else
        table.insert(lines, tostring(result))
    end
    
    -- Set buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Open buffer in split
    vim.api.nvim_command("split")
    vim.api.nvim_set_current_buf(buf)
    
    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

-- Display sampled content
function M.display_sampled_content(uri, result, criteria)
    -- Create buffer for sampled content
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "swapfile", false)
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    
    -- Format content
    local lines = {
        "# Sampled Resource: " .. uri,
        "",
        "Criteria:",
        vim.inspect(criteria),
        "",
        "Sampled Content:",
        ""
    }
    
    if type(result) == "table" then
        table.insert(lines, vim.inspect(result))
    else
        table.insert(lines, tostring(result))
    end
    
    -- Set buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Open buffer in split
    vim.api.nvim_command("split")
    vim.api.nvim_set_current_buf(buf)
    
    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

-- Display resource roots
function M.display_resource_roots(uri, roots)
    -- Create buffer for resource roots
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "swapfile", false)
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    
    -- Format roots
    local lines = {
        "# Resource Roots: " .. uri,
        "",
        "Roots:",
        ""
    }
    
    for _, root in ipairs(roots) do
        table.insert(lines, "## " .. root.name)
        table.insert(lines, "**URI:** " .. root.uri)
        table.insert(lines, "**Description:** " .. root.description)
        table.insert(lines, "")
    end
    
    -- Set buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Open buffer in split
    vim.api.nvim_command("split")
    vim.api.nvim_set_current_buf(buf)
    
    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

-- Get pattern-aware tool recommendations
function M.get_pattern_aware_tool_recommendations(pattern_context)
    if not M.mcp_server_initialized then
        M.initialize_mcp_server()
    end
    
    local recommendations = {}
    local tools = M.list_mcp_tools()
    
    for _, tool in ipairs(tools) do
        if tool.patterns then
            for _, pattern in ipairs(tool.patterns) do
                -- Enhanced pattern matching based on context
                local pattern_lower = string.lower(pattern.pattern_id)
                local desc_lower = string.lower(pattern.description)
                local context_lower = string.lower(pattern_context)
                
                -- Check for direct matches or semantic matches
                if string.find(pattern_lower, context_lower) or
                   string.find(desc_lower, context_lower) or
                   string.find(context_lower, "file") and string.find(desc_lower, "file") or
                   string.find(context_lower, "edit") and string.find(desc_lower, "edit") then
                    table.insert(recommendations, {
                        tool_name = tool.name,
                        confidence = 0.8,
                        reason = "Pattern match: " .. pattern.pattern_id,
                        pattern_id = pattern.pattern_id,
                        relationship_type = pattern.relationship_type
                    })
                end
            end
        end
    end
    
    -- Sort by confidence (highest first)
    table.sort(recommendations, function(a, b)
        return a.confidence > b.confidence
    end)
    
    return recommendations
end

-- Track tool usage with pattern context
function M.track_tool_usage(tool_name, pattern_id, success)
    if not M.mcp_server_initialized then
        M.initialize_mcp_server()
    end
    
    -- Find the tool
    for _, tool in ipairs(M.mcp_tools) do
        if tool.name == tool_name then
            -- Update usage count
            tool.success_metrics.usage_count = tool.success_metrics.usage_count + 1
            
            -- Update last used timestamp
            tool.success_metrics.last_used = os.time()
            
            -- Update success rate (simple moving average)
            local current_rate = tool.success_metrics.success_rate
            local new_rate = success and 1.0 or 0.0
            tool.success_metrics.success_rate = (current_rate * 0.9) + (new_rate * 0.1)
            
            return true
        end
    end
    
    return false
end

return M
