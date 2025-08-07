--[[
Paragonic Chat Module
Handles chat interface and message sending functionality
--]]

local M = {}

-- Send a message to the AI and get response
function M.send_message(message, model)
    local backend = require("paragonic.backend")
    local rpc_client = backend._get_rpc_client()
    if not rpc_client then
        -- Try to initialize backend if not available
        if not backend.initialize_backend() then
            return nil, "Backend not available"
        end
        rpc_client = backend._get_rpc_client()
    end
    
    -- Use default model if not specified
    model = model or "llama2"
    
    -- Send chat completion request
    local response = rpc_client:chat_completion(model, message)
    if not response then
        return nil, "Failed to get response from AI"
    end
    
    -- Parse JSON response using enhanced parser
    local utils = require("paragonic.utils")
    local parsed_response = utils.parse_json_response_enhanced(response)
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
    local backend = require("paragonic.backend")
    local rpc_client = backend._get_rpc_client()
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
    local utils = require("paragonic.utils")
    local parsed_response = utils.parse_json_response_enhanced(response)
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

-- Send message command
function M.send_message_command()
    -- Immediate debugging at function entry
    local debug = require("paragonic.debug")
    debug.debug_print("🚀 send_message_command() called", "debug")
    debug.debug_print("📝 Starting send_message_command function", "debug")
    
    local current_buf = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(current_buf)
    
    debug.debug_print("📝 Current buffer: " .. buf_name, "debug")
    
    -- Only work in chat buffer
    if buf_name ~= "paragonic://chat" then
        debug.debug_print("❌ This command only works in the chat buffer", "error")
        return
    end
    
    debug.debug_print("✅ Buffer check passed", "debug")
    
    -- Get the current line as the message
    local line_num = vim.api.nvim_win_get_cursor(0)[1] - 1  -- 0-indexed
    local lines = vim.api.nvim_buf_get_lines(current_buf, line_num, line_num + 1, false)
    local message = lines[1] or ""
    
    debug.debug_print("📝 Message: " .. message:sub(1, 50), "debug")
    
    -- Skip empty lines or lines that start with #
    if message == "" or message:match("^%s*#") then
        debug.debug_print("❌ Please enter a message to send", "error")
        return
    end
    
    debug.debug_print("✅ Message validation passed", "debug")
    debug.debug_print("🔧 About to call append_debug_message...", "debug")
    
    -- Add immediate visual feedback that the chat is being sent
    debug.debug_print("🔧 Calling append_debug_message...", "debug")
    local success, err = debug.append_debug_message(current_buf, "Sending message to AI...", "info")
    
    if not success then
        debug.debug_print("❌ append_debug_message failed: " .. tostring(err), "error")
        return
    else
        debug.debug_print("✅ append_debug_message succeeded", "debug")
    end
    
    -- Initialize backend if not available
    local backend = require("paragonic.backend")
    if not backend._rpc_client then
        debug.append_debug_message(current_buf, "🔧 Backend not available, starting initialization...", "info")
        debug.append_debug_message(current_buf, "🔧 Step 1: Creating RPC client...", "debug")
        
        local success = backend._initialize_backend()
        
        if not success then
            debug.append_debug_message(current_buf, "❌ Backend initialization failed", "error")
            vim.notify("Failed to send message: Backend initialization failed", vim.log.levels.ERROR)
            return
        else
            debug.append_debug_message(current_buf, "✅ Backend initialization completed", "success")
        end
    else
        debug.append_debug_message(current_buf, "✅ Backend already available", "info")
    end
    
    -- Start a progress indicator for long operations
    local progress_timer = nil
    local progress_count = 0
    local function update_progress()
        progress_count = progress_count + 1
        local dots = string.rep(".", progress_count % 4)
        debug.append_debug_message(current_buf, "Waiting for AI response" .. dots, "info")
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
    if backend._rpc_client and backend._rpc_client.set_retry_callback then
        backend._rpc_client:set_retry_callback(function(attempt, max_attempts)
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
        debug.append_debug_message(current_buf, "Failed to send message: " .. (err or "unknown error"), "error")
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
    debug.append_debug_message(current_buf, "Message sent successfully, processing response...", "success")
    
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
    local utils = require("paragonic.utils")
    if #response_content_lines > 0 then
        local wrapped_first = utils.wrap_text_with_diamond(response_content_lines[1], base_width)
        for _, line in ipairs(wrapped_first) do
            table.insert(response_lines, line)
        end
        
        -- Add remaining lines with three spaces indentation
        for i = 2, #response_content_lines do
            local wrapped_lines = utils.wrap_text(response_content_lines[i], base_width, "   ")
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
    local debug = require("paragonic.debug")
    debug.append_debug_message(current_buf, "Sending message to AI...", "info")
    
    -- Initialize backend if not available
    local backend = require("paragonic.backend")
    if not backend._rpc_client then
        debug.append_debug_message(current_buf, "🔧 Backend not available, starting initialization...", "info")
        debug.append_debug_message(current_buf, "🔧 Step 1: Creating RPC client...", "debug")
        
        local success = backend._initialize_backend()
        
        if not success then
            debug.append_debug_message(current_buf, "❌ Backend initialization failed", "error")
            vim.notify("Failed to send message: Backend initialization failed", vim.log.levels.ERROR)
            return
        else
            debug.append_debug_message(current_buf, "✅ Backend initialization completed", "success")
        end
    else
        debug.append_debug_message(current_buf, "✅ Backend already available", "info")
    end
    
    -- Check RPC client
    local rpc_client = backend._get_rpc_client()
    if not rpc_client then
        debug.append_debug_message(current_buf, "RPC client not available", "error")
        vim.notify("Failed to send message: Backend not available", vim.log.levels.ERROR)
        return
    end
    
    debug.append_debug_message(current_buf, "RPC client available", "info")
    
    -- Debug: Sending message
    debug.append_debug_message(current_buf, "Sending message: " .. message:sub(1, 50) .. "...", "debug")
    
    -- Start a progress indicator for long operations
    local progress_timer = nil
    local progress_count = 0
    local function update_progress()
        progress_count = progress_count + 1
        local dots = string.rep(".", progress_count % 4)
        debug.append_debug_message(current_buf, "⏳ Waiting for AI response" .. dots, "debug")
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
    if backend._rpc_client and backend._rpc_client.set_retry_callback then
        backend._rpc_client:set_retry_callback(function(attempt, max_attempts)
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
        debug.append_debug_message(current_buf, "Failed to send message: " .. tostring(err), "error")
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
    
    debug.append_debug_message(current_buf, "✅ Successfully received response from AI", "success")
    
    -- Debug: Processing response
    debug.append_debug_message(current_buf, "Processing response for buffer insertion", "debug")
    
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
    local utils = require("paragonic.utils")
    if #response_content_lines > 0 then
        local wrapped_first = utils.wrap_text_with_diamond(response_content_lines[1], base_width)
        for _, line in ipairs(wrapped_first) do
            table.insert(response_lines, line)
        end
        
        -- Add remaining lines with three spaces indentation
        for i = 2, #response_content_lines do
            local wrapped_lines = utils.wrap_text(response_content_lines[i], base_width, "   ")
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
    debug.append_debug_message(current_buf, "Inserting " .. #response_lines .. " lines into buffer", "debug")
    
    -- Insert response after the zigzag arrow (line_num + 2 since zigzag is at line_num + 1)
    vim.api.nvim_buf_set_lines(current_buf, line_num + 2, line_num + 2, false, response_lines)
    
    -- Move cursor to the end of the buffer (safe positioning)
    local buffer_line_count = vim.api.nvim_buf_line_count(current_buf)
    vim.api.nvim_win_set_cursor(0, {buffer_line_count, 0})
    
    -- Debug: Success
    debug.append_debug_message(current_buf, "Message send process completed successfully", "success")
end

return M
