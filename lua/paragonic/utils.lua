--[[
Paragonic Utilities Module
Handles common utility functions like text wrapping, JSON parsing, and helper functions
--]]

local M = {}

-- Word wrapping helper function
function M.wrap_text(text, max_width, indent)
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
function M.wrap_text_with_diamond(text, max_width)
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

-- Format timestamp
function M.format_timestamp(timestamp)
    return os.date("%Y-%m-%d %H:%M:%S", timestamp or os.time())
end

-- Format duration in seconds
function M.format_duration(seconds)
    if seconds < 60 then
        return string.format("%.2fs", seconds)
    elseif seconds < 3600 then
        local minutes = math.floor(seconds / 60)
        local remaining_seconds = seconds % 60
        return string.format("%dm %.2fs", minutes, remaining_seconds)
    else
        local hours = math.floor(seconds / 3600)
        local remaining_minutes = math.floor((seconds % 3600) / 60)
        local remaining_seconds = seconds % 60
        return string.format("%dh %dm %.2fs", hours, remaining_minutes, remaining_seconds)
    end
end

-- Safe string truncation
function M.truncate_string(str, max_length, suffix)
    if not str then return "" end
    if #str <= max_length then return str end
    
    suffix = suffix or "..."
    return str:sub(1, max_length - #suffix) .. suffix
end

-- Escape special characters for display
function M.escape_for_display(str)
    if not str then return "" end
    return str:gsub("([%[%](){}*+?.|^$])", "\\%1")
end

-- Validate file path
function M.is_valid_file_path(path)
    if not path or type(path) ~= "string" then
        return false
    end
    
    -- Basic validation - check for invalid characters
    if path:match("[<>:\"|?*]") then
        return false
    end
    
    return true
end

-- Get file extension
function M.get_file_extension(filename)
    if not filename then return "" end
    return filename:match("%.([^%.]+)$") or ""
end

-- Check if file is text-based
function M.is_text_file(filename)
    local ext = M.get_file_extension(filename):lower()
    local text_extensions = {
        "txt", "md", "lua", "py", "js", "ts", "json", "xml", "html", "css", "scss",
        "rs", "go", "java", "c", "cpp", "h", "hpp", "sh", "bash", "zsh", "fish",
        "vim", "vimrc", "gitignore", "dockerfile", "makefile", "cmake", "yaml", "yml",
        "toml", "ini", "cfg", "conf", "log", "sql", "r", "pl", "php", "rb", "swift",
        "kt", "scala", "hs", "ml", "fs", "clj", "edn", "ex", "exs", "erl", "hrl"
    }
    
    for _, text_ext in ipairs(text_extensions) do
        if ext == text_ext then
            return true
        end
    end
    
    return false
end

return M
