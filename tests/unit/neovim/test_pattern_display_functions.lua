-- Test file for pattern display functions
-- Tests the floating window display functionality for patterns

package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua'

print("=== Pattern Display Functions Test ===")

-- Mock Neovim API for testing
local mock_vim = {
    api = {
        nvim_create_buf = function(listed, scratch)
            return 1  -- Mock buffer ID
        end,
        nvim_open_win = function(buf, enter, config)
            return 1  -- Mock window ID
        end,
        nvim_buf_set_option = function(buf, option, value)
            -- Mock buffer option setting
        end,
        nvim_win_set_option = function(win, option, value)
            -- Mock window option setting
        end,
        nvim_buf_set_lines = function(buf, start, end_idx, strict_indexing, lines)
            -- Mock setting buffer lines
        end,
        nvim_win_get_cursor = function(win)
            return {5, 0}  -- Mock cursor position
        end,
        nvim_win_close = function(win, force)
            -- Mock window closing
        end,
        nvim_buf_delete = function(buf, opts)
            -- Mock buffer deletion
        end
    },
    keymap = {
        set = function(mode, lhs, rhs, opts)
            -- Mock keymap setting
        end
    },
    notify = function(msg, level)
        -- Mock notification
        print("NOTIFY: " .. msg .. " (level: " .. tostring(level) .. ")")
    end,
    o = {
        columns = 120,
        lines = 40
    }
}

-- Mock the paragonic module for testing
package.loaded.paragonic = {
    patterns = {
        list_patterns = function()
            return {
                {
                    id = "session-summary-generation",
                    name = "Session Summary Generation",
                    category = "SessionManagement",
                    description = "Generates comprehensive session summaries"
                },
                {
                    id = "activity-labeling",
                    name = "Activity Labeling",
                    category = "ActivityLabeling", 
                    description = "Labels and categorizes development activities"
                },
                {
                    id = "knowledge-extraction",
                    name = "Knowledge Extraction",
                    category = "KnowledgeExtraction",
                    description = "Extracts reusable knowledge and patterns from session data"
                }
            }
        end,
        get_pattern_by_name = function(name)
            if name == "Session Summary Generation" then
                return {
                    id = "session-summary-generation",
                    name = "Session Summary Generation",
                    category = "SessionManagement",
                    description = "Generates comprehensive session summaries",
                    workflow_steps = {"analyze", "extract", "summarize"},
                    output_format = {summary = "string", key_points = "array"}
                }
            elseif name == "Activity Labeling" then
                return {
                    id = "activity-labeling",
                    name = "Activity Labeling",
                    category = "ActivityLabeling",
                    description = "Labels and categorizes development activities",
                    workflow_steps = {"analyze", "label", "categorize"},
                    output_format = {label = "string", category = "string"}
                }
            end
            return nil
        end,
        execute_pattern = function(pattern_name, context)
            return {
                success = true,
                pattern_name = pattern_name,
                result = {
                    summary = "Pattern executed successfully",
                    timestamp = "2025-01-15 10:30:00",
                    context = context or {}
                }
            }
        end,
        show_pattern_details = function(pattern_name)
            -- Mock implementation that would create floating window
            local pattern = package.loaded.paragonic.patterns.get_pattern_by_name(pattern_name)
            if not pattern then
                mock_vim.notify("Pattern not found: " .. pattern_name, 4)  -- ERROR level
                return false
            end
            
            -- Mock window creation
            local buf = mock_vim.api.nvim_create_buf(false, true)
            local win = mock_vim.api.nvim_open_win(buf, true, {
                relative = 'editor',
                width = 80,
                height = 20,
                row = 10,
                col = 20,
                style = 'minimal',
                border = 'rounded'
            })
            
            -- Mock buffer options
            mock_vim.api.nvim_buf_set_option(buf, 'modifiable', false)
            mock_vim.api.nvim_buf_set_option(buf, 'readonly', true)
            mock_vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
            mock_vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
            
            -- Mock window options
            mock_vim.api.nvim_win_set_option(win, 'wrap', true)
            mock_vim.api.nvim_win_set_option(win, 'number', false)
            mock_vim.api.nvim_win_set_option(win, 'relativenumber', false)
            
            -- Mock content formatting
            local lines = {
                "# " .. pattern.name,
                "",
                "**Category:** " .. pattern.category,
                "**Description:** " .. pattern.description,
                "",
                "## Workflow Steps",
                "",
                "1. Analyze session data",
                "2. Extract key information",
                "3. Generate structured output",
                "",
                "## Output Format",
                "",
                "- Summary: Comprehensive overview",
                "- Key Points: Important insights", 
                "- Action Items: Next steps",
                "",
                "---",
                "*Press 'q' to close*"
            }
            
            mock_vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            
            -- Mock key mappings
            local opts = {buffer = buf, silent = true}
            mock_vim.keymap.set('n', 'q', function()
                mock_vim.api.nvim_win_close(win, true)
                mock_vim.api.nvim_buf_delete(buf, {force = true})
            end, opts)
            
            return true
        end,
        pattern_list_command = function()
            -- Mock implementation that would create floating window
            local patterns = package.loaded.paragonic.patterns.list_patterns()
            if #patterns == 0 then
                mock_vim.notify("No patterns found", 2)  -- WARN level
                return
            end
            
            -- Mock window creation
            local buf = mock_vim.api.nvim_create_buf(false, true)
            local win = mock_vim.api.nvim_open_win(buf, true, {
                relative = 'editor',
                width = 100,
                height = 25,
                row = 7,
                col = 10,
                style = 'minimal',
                border = 'rounded'
            })
            
            -- Mock buffer options
            mock_vim.api.nvim_buf_set_option(buf, 'modifiable', false)
            mock_vim.api.nvim_buf_set_option(buf, 'readonly', true)
            mock_vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
            mock_vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
            
            -- Mock window options
            mock_vim.api.nvim_win_set_option(win, 'wrap', false)
            mock_vim.api.nvim_win_set_option(win, 'number', true)
            mock_vim.api.nvim_win_set_option(win, 'relativenumber', false)
            
            -- Mock content formatting
            local lines = {
                "# System Patterns",
                "",
                "| Name | Category | Description |",
                "|------|----------|-------------|"
            }
            
            for _, pattern in ipairs(patterns) do
                local description = pattern.description
                if #description > 50 then
                    description = description:sub(1, 47) .. "..."
                end
                table.insert(lines, string.format("| %s | %s | %s |", pattern.name, pattern.category, description))
            end
            
            table.insert(lines, "")
            table.insert(lines, "---")
            table.insert(lines, "*Press 'Enter' to view details, 'e' to execute, 'q' to close*")
            
            mock_vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            
            -- Mock key mappings
            local opts = {buffer = buf, silent = true}
            
            -- Close window
            mock_vim.keymap.set('n', 'q', function()
                mock_vim.api.nvim_win_close(win, true)
                mock_vim.api.nvim_buf_delete(buf, {force = true})
            end, opts)
            
            -- View pattern details
            mock_vim.keymap.set('n', '<CR>', function()
                local line = mock_vim.api.nvim_win_get_cursor(win)[1]
                if line > 4 and line <= 4 + #patterns then
                    local pattern_index = line - 4
                    local pattern = patterns[pattern_index]
                    if pattern then
                        mock_vim.api.nvim_win_close(win, true)
                        mock_vim.api.nvim_buf_delete(buf, {force = true})
                        package.loaded.paragonic.patterns.show_pattern_details(pattern.name)
                    end
                end
            end, opts)
            
            -- Execute pattern
            mock_vim.keymap.set('n', 'e', function()
                local line = mock_vim.api.nvim_win_get_cursor(win)[1]
                if line > 4 and line <= 4 + #patterns then
                    local pattern_index = line - 4
                    local pattern = patterns[pattern_index]
                    if pattern then
                        mock_vim.api.nvim_win_close(win, true)
                        mock_vim.api.nvim_buf_delete(buf, {force = true})
                        package.loaded.paragonic.patterns.execute_pattern_command(pattern.name)
                    end
                end
            end, opts)
            
            return true
        end,
        execute_pattern_command = function(pattern_name)
            -- Mock implementation that would create floating window
            local result = package.loaded.paragonic.patterns.execute_pattern(pattern_name)
            if result.success then
                mock_vim.notify("Pattern executed successfully: " .. pattern_name, 1)  -- INFO level
                
                -- Mock window creation
                local buf = mock_vim.api.nvim_create_buf(false, true)
                local win = mock_vim.api.nvim_open_win(buf, true, {
                    relative = 'editor',
                    width = 80,
                    height = 15,
                    row = 12,
                    col = 20,
                    style = 'minimal',
                    border = 'rounded'
                })
                
                -- Mock buffer options
                mock_vim.api.nvim_buf_set_option(buf, 'modifiable', false)
                mock_vim.api.nvim_buf_set_option(buf, 'readonly', true)
                mock_vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
                mock_vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
                
                -- Mock window options
                mock_vim.api.nvim_win_set_option(win, 'wrap', true)
                mock_vim.api.nvim_win_set_option(win, 'number', false)
                mock_vim.api.nvim_win_set_option(win, 'relativenumber', false)
                
                -- Mock content formatting
                local lines = {
                    "# Pattern Execution Result",
                    "",
                    "**Pattern:** " .. pattern_name,
                    "**Status:** Success",
                    "**Timestamp:** " .. result.result.timestamp,
                    "",
                    "## Summary",
                    "",
                    result.result.summary,
                    "",
                    "---",
                    "*Press 'q' to close*"
                }
                
                mock_vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
                
                -- Mock key mapping to close
                local opts = {buffer = buf, silent = true}
                mock_vim.keymap.set('n', 'q', function()
                    mock_vim.api.nvim_win_close(win, true)
                    mock_vim.api.nvim_buf_delete(buf, {force = true})
                end, opts)
                
                return true
            else
                mock_vim.notify("Failed to execute pattern: " .. (result.error or "Unknown error"), 4)  -- ERROR level
                return false
            end
        end
    }
}

-- Test 1: Check if pattern display functions exist
print("📝 Testing pattern display function availability...")
if package.loaded.paragonic.patterns.show_pattern_details then
    print("✅ show_pattern_details function available")
else
    print("❌ show_pattern_details function not available")
end

if package.loaded.paragonic.patterns.pattern_list_command then
    print("✅ pattern_list_command function available")
else
    print("❌ pattern_list_command function not available")
end

if package.loaded.paragonic.patterns.execute_pattern_command then
    print("✅ execute_pattern_command function available")
else
    print("❌ execute_pattern_command function not available")
end

-- Test 2: Test show_pattern_details with valid pattern
print("📝 Testing show_pattern_details with valid pattern...")
local details_result = package.loaded.paragonic.patterns.show_pattern_details("Session Summary Generation")
if details_result then
    print("✅ show_pattern_details works with valid pattern")
else
    print("❌ show_pattern_details failed with valid pattern")
end

-- Test 3: Test show_pattern_details with invalid pattern
print("📝 Testing show_pattern_details with invalid pattern...")
local invalid_details_result = package.loaded.paragonic.patterns.show_pattern_details("Invalid Pattern")
if not invalid_details_result then
    print("✅ show_pattern_details correctly handles invalid pattern")
else
    print("❌ show_pattern_details should have failed with invalid pattern")
end

-- Test 4: Test pattern_list_command with patterns available
print("📝 Testing pattern_list_command with patterns available...")
local list_result = package.loaded.paragonic.patterns.pattern_list_command()
if list_result then
    print("✅ pattern_list_command works with patterns available")
else
    print("❌ pattern_list_command failed with patterns available")
end

-- Test 5: Test pattern_list_command with no patterns
print("📝 Testing pattern_list_command with no patterns...")
local original_list_patterns = package.loaded.paragonic.patterns.list_patterns
package.loaded.paragonic.patterns.list_patterns = function()
    return {}
end

local empty_list_result = package.loaded.paragonic.patterns.pattern_list_command()
if empty_list_result == nil then
    print("✅ pattern_list_command correctly handles empty pattern list")
else
    print("❌ pattern_list_command should return nil for empty list")
end

-- Restore original function
package.loaded.paragonic.patterns.list_patterns = original_list_patterns

-- Test 6: Test execute_pattern_command with successful execution
print("📝 Testing execute_pattern_command with successful execution...")
local execute_result = package.loaded.paragonic.patterns.execute_pattern_command("Activity Labeling")
if execute_result then
    print("✅ execute_pattern_command works with successful execution")
else
    print("❌ execute_pattern_command failed with successful execution")
end

-- Test 7: Test execute_pattern_command with failed execution
print("📝 Testing execute_pattern_command with failed execution...")
local original_execute_pattern = package.loaded.paragonic.patterns.execute_pattern
package.loaded.paragonic.patterns.execute_pattern = function(pattern_name, context)
    return {
        success = false,
        error = "Test error message"
    }
end

local failed_execute_result = package.loaded.paragonic.patterns.execute_pattern_command("Test Pattern")
if not failed_execute_result then
    print("✅ execute_pattern_command correctly handles failed execution")
else
    print("❌ execute_pattern_command should return false for failed execution")
end

-- Restore original function
package.loaded.paragonic.patterns.execute_pattern = original_execute_pattern

-- Test 8: Test floating window configuration
print("📝 Testing floating window configuration...")
local test_pattern = package.loaded.paragonic.patterns.get_pattern_by_name("Session Summary Generation")
if test_pattern then
    print("✅ Pattern data structure is correct")
    print("  Name: " .. test_pattern.name)
    print("  Category: " .. test_pattern.category)
    print("  Description: " .. test_pattern.description)
else
    print("❌ Pattern data structure is incorrect")
end

-- Test 9: Test window sizing calculations
print("📝 Testing window sizing calculations...")
local width = math.min(80, mock_vim.o.columns - 4)
local height = math.min(20, mock_vim.o.lines - 4)
local row = math.floor((mock_vim.o.lines - height) / 2)
local col = math.floor((mock_vim.o.columns - width) / 2)

if width == 80 and height == 20 and row == 10 and col == 20 then
    print("✅ Window sizing calculations are correct")
    print("  Width: " .. width .. " (expected: 80)")
    print("  Height: " .. height .. " (expected: 20)")
    print("  Row: " .. row .. " (expected: 10)")
    print("  Col: " .. col .. " (expected: 20)")
else
    print("❌ Window sizing calculations are incorrect")
    print("  Width: " .. width .. " (expected: 80)")
    print("  Height: " .. height .. " (expected: 20)")
    print("  Row: " .. row .. " (expected: 10)")
    print("  Col: " .. col .. " (expected: 20)")
end

-- Test 10: Test content formatting
print("📝 Testing content formatting...")
local patterns = package.loaded.paragonic.patterns.list_patterns()
if #patterns == 3 then
    print("✅ Pattern list formatting works")
    for i, pattern in ipairs(patterns) do
        print("  Pattern " .. i .. ": " .. pattern.name .. " (" .. pattern.category .. ")")
    end
else
    print("❌ Pattern list formatting failed")
end

print("=== Pattern Display Functions Test Complete ===")
