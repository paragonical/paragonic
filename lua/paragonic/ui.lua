-- UI Layer: Neovim-specific UI operations, buffer management, visual feedback
-- Provides clean UI interface for buffer management, visual feedback, and user interaction

local M = {}

-- Dependencies
local debug = require("paragonic.debug")

-- UI state
local ui_state = {
    chat_buffer_name = "paragonic://chat",
    active_buffers = {},
}

-- Create or get chat buffer
function M.create_chat_buffer()
    local buf_name = ui_state.chat_buffer_name
    
    -- Check if buffer already exists
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_get_name(buf) == buf_name then
            debug.debug_print("📄 Using existing chat buffer: " .. buf, "debug")
            return buf
        end
    end

    -- Create new buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, buf_name)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "swapfile", false)
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    vim.api.nvim_buf_set_option(buf, "readonly", false)

    -- Set buffer options for better chat experience
    vim.api.nvim_buf_set_option(buf, "wrap", true)
    vim.api.nvim_buf_set_option(buf, "linebreak", true)
    vim.api.nvim_buf_set_option(buf, "breakindent", true)

    debug.debug_print("📄 Created new chat buffer: " .. buf, "success")
    return buf
end

-- Get current buffer if it's a chat buffer
function M.get_chat_buffer()
    local current_buf = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(current_buf)
    
    if buf_name == ui_state.chat_buffer_name then
        return current_buf
    end
    
    return nil
end

-- Append message to buffer
function M.append_message(buffer, message, message_type)
    if not buffer then
        debug.debug_print("❌ No buffer provided for message", "error")
        return false
    end

    message_type = message_type or "user"
    
    -- Format message based on type
    local formatted_message = ""
    if message_type == "user" then
        formatted_message = "👤 " .. message
    elseif message_type == "assistant" then
        formatted_message = "🮮 " .. message
    elseif message_type == "thinking" then
        formatted_message = "🧠 " .. message
    elseif message_type == "error" then
        formatted_message = "❌ " .. message
    elseif message_type == "system" then
        formatted_message = "⚙️ " .. message
    else
        formatted_message = message
    end

    -- Get current buffer lines
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    
    -- Add message
    table.insert(lines, formatted_message)
    table.insert(lines, "") -- Empty line for spacing
    
    -- Update buffer
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
    
    -- Scroll to bottom
    local last_line = #lines
    vim.api.nvim_buf_call(buffer, function()
        vim.api.nvim_win_set_cursor(0, {last_line, 0})
    end)

    debug.debug_print("📝 Appended " .. message_type .. " message to buffer", "debug")
    return true
end

-- Show progress indicator
function M.show_progress(buffer, message)
    if not buffer then
        return false
    end

    local progress_message = "⏳ " .. (message or "Processing...")
    
    -- Get current buffer lines
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    
    -- Add progress indicator
    table.insert(lines, progress_message)
    
    -- Update buffer
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
    
    -- Scroll to bottom
    local last_line = #lines
    vim.api.nvim_buf_call(buffer, function()
        vim.api.nvim_win_set_cursor(0, {last_line, 0})
    end)

    debug.debug_print("⏳ Showing progress: " .. message, "debug")
    return true
end

-- Clear progress indicator
function M.clear_progress(buffer)
    if not buffer then
        return false
    end

    -- Get current buffer lines
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    
    -- Remove last line if it's a progress indicator
    if #lines > 0 and lines[#lines]:match("^⏳ ") then
        table.remove(lines)
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
        debug.debug_print("🧹 Cleared progress indicator", "debug")
    end

    return true
end

-- Show error message
function M.show_error(buffer, error_message)
    if not buffer then
        debug.debug_print("❌ No buffer provided for error", "error")
        return false
    end

    local error_line = "🛔 " .. (error_message or "Unknown error")
    
    -- Get current buffer lines
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    
    -- Add error message
    table.insert(lines, error_line)
    table.insert(lines, "") -- Empty line for spacing
    
    -- Update buffer
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
    
    -- Scroll to bottom
    local last_line = #lines
    vim.api.nvim_buf_call(buffer, function()
        vim.api.nvim_win_set_cursor(0, {last_line, 0})
    end)

    debug.debug_print("❌ Showed error: " .. error_message, "debug")
    return true
end

-- Show success message
function M.show_success(buffer, message)
    if not buffer then
        return false
    end

    local success_line = "✅ " .. (message or "Success")
    
    -- Get current buffer lines
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    
    -- Add success message
    table.insert(lines, success_line)
    table.insert(lines, "") -- Empty line for spacing
    
    -- Update buffer
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
    
    -- Scroll to bottom
    local last_line = #lines
    vim.api.nvim_buf_call(buffer, function()
        vim.api.nvim_win_set_cursor(0, {last_line, 0})
    end)

    debug.debug_print("✅ Showed success: " .. message, "debug")
    return true
end

-- Update line in buffer
function M.update_line(buffer, line_number, new_content)
    if not buffer then
        return false
    end

    -- Ensure line number is within bounds
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    if line_number < 0 or line_number >= #lines then
        debug.debug_print("❌ Line number out of bounds: " .. line_number, "error")
        return false
    end

    -- Update the line
    vim.api.nvim_buf_set_lines(buffer, line_number, line_number + 1, false, {new_content})
    
    debug.debug_print("📝 Updated line " .. line_number .. " in buffer", "debug")
    return true
end

-- Get buffer width
function M.get_buffer_width(buffer)
    if not buffer then
        return 80 -- Default width
    end

    -- Get window that displays this buffer
    local windows = vim.api.nvim_list_wins()
    for _, win in ipairs(windows) do
        if vim.api.nvim_win_get_buf(win) == buffer then
            return vim.api.nvim_win_get_width(win)
        end
    end

    return 80 -- Default width if no window found
end

-- Format text for buffer width
function M.format_text_for_width(text, width)
    width = width or 80
    
    if #text <= width then
        return {text}
    end

    local lines = {}
    local current_line = ""
    local words = vim.split(text, " ")
    
    for _, word in ipairs(words) do
        if #current_line + #word + 1 <= width then
            if current_line ~= "" then
                current_line = current_line .. " " .. word
            else
                current_line = word
            end
        else
            if current_line ~= "" then
                table.insert(lines, current_line)
            end
            current_line = word
        end
    end
    
    if current_line ~= "" then
        table.insert(lines, current_line)
    end
    
    return lines
end

-- Show notification
function M.show_notification(message, level)
    level = level or vim.log.levels.INFO
    
    vim.notify(message, level)
    debug.debug_print("📢 Notification: " .. message, "debug")
end

-- Get UI status
function M.get_status()
    local chat_buffer = M.get_chat_buffer()
    return {
        chat_buffer_exists = chat_buffer ~= nil,
        chat_buffer_id = chat_buffer,
        active_buffers_count = #ui_state.active_buffers,
    }
end

-- Initialize UI layer
function M.init()
    debug.debug_print("🔧 Initializing UI layer", "info")
    
    -- Create chat buffer if it doesn't exist
    local chat_buffer = M.create_chat_buffer()
    if chat_buffer then
        ui_state.active_buffers[chat_buffer] = true
    end
    
    debug.debug_print("✅ UI layer initialized", "success")
    return true
end

-- Cleanup UI layer
function M.cleanup()
    debug.debug_print("🔧 Cleaning up UI layer", "info")
    
    -- Clear active buffers
    ui_state.active_buffers = {}
    
    debug.debug_print("✅ UI layer cleaned up", "success")
end

return M
