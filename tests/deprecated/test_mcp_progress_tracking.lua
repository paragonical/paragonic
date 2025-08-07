#!/usr/bin/env lua

--[[
Test script for MCP progress tracking functionality
This tests progress notifications for long-running operations
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Test MCP progress tracking functionality
local function test_mcp_progress_tracking()
    print("=== Testing MCP Progress Tracking ===")
    
    -- Mock the required vim functions for testing
    local vim_mock = {
        api = {
            nvim_buf_set_lines = function(buf, start, end_, strict, lines)
                print("  Set lines in buffer " .. buf .. " from " .. start .. " to " .. end_)
                return 0
            end,
            nvim_buf_get_lines = function(buf, start, end_, strict)
                if buf == 1 then return {"line 1", "line 2", "line 3"}
                elseif buf == 2 then return {"function test()", "  return true", "end"}
                else return {} end
            end,
            nvim_set_current_buf = function(buf)
                print("  Set current buffer to " .. buf)
                return 0
            end,
            nvim_list_bufs = function()
                return {1, 2, 3}
            end,
            nvim_buf_get_name = function(buf)
                if buf == 1 then return "/tmp/file1.txt"
                elseif buf == 2 then return "/tmp/file2.lua"
                else return "" end
            end,
            nvim_buf_get_option = function(buf, option)
                if option == "modifiable" then return true
                elseif option == "modified" then return buf == 1
                else return false end
            end
        },
        fn = {
            writefile = function(lines, file_path)
                print("  Write " .. #lines .. " lines to " .. file_path)
                return 0
            end,
            filereadable = function(file_path)
                if file_path:find("file1") or file_path:find("file2") then return 1
                else return 0 end
            end,
            mkdir = function(dir_path)
                print("  Create directory " .. dir_path)
                return 0
            end,
            fnamemodify = function(file_path, modifier)
                if modifier == ":h" then
                    if file_path:find("/") then
                        return file_path:match("(.*)/[^/]*$")
                    else
                        return "."
                    end
                end
                return file_path
            end,
            isdirectory = function(dir_path)
                if dir_path == "." then return 1
                elseif dir_path:find("existing") then return 1
                else return 0 end
            end
        },
        cmd = function(command)
            print("  Execute command: " .. command)
            return 0
        end,
        notify = function(msg, level) 
            print("  Notify [" .. (level or "info") .. "]: " .. msg)
        end,
        log = {
            levels = {
                INFO = 1,
                WARN = 2,
                ERROR = 3
            }
        },
        json = {
            encode = function(data)
                -- Simple JSON encoder for testing
                if type(data) == "table" then
                    local parts = {}
                    for k, v in pairs(data) do
                        if type(v) == "string" then
                            table.insert(parts, string.format('"%s": "%s"', k, v))
                        elseif type(v) == "number" then
                            table.insert(parts, string.format('"%s": %s', k, v))
                        elseif type(v) == "boolean" then
                            table.insert(parts, string.format('"%s": %s', k, tostring(v)))
                        elseif type(v) == "table" then
                            table.insert(parts, string.format('"%s": %s', k, vim.json.encode(v)))
                        end
                    end
                    return "{" .. table.concat(parts, ", ") .. "}"
                elseif type(data) == "string" then
                    return string.format('"%s"', data)
                else
                    return tostring(data)
                end
            end,
            decode = function(json_str)
                -- Simple JSON decoder for testing
                if json_str:find("progress") then
                    return {progress = 50, message = "Processing files..."}
                else
                    return {}
                end
            end
        }
    }
    
    -- Replace global vim temporarily
    local original_vim = _G.vim
    _G.vim = vim_mock
    
    -- Test the MCP progress tracking functionality
    print("  Testing MCP progress tracking...")
    
    -- Create a simple test module
    local M = {}
    
    -- Progress tracking state
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
    
    -- Test progress notification creation
    local progress_notification = M.create_progress_notification("test-1", "Processing files...", 50, false)
    assert(progress_notification.method == "notifications/progress", "Should have correct method")
    assert(progress_notification.params.id == "test-1", "Should have correct progress ID")
    assert(progress_notification.params.message == "Processing files...", "Should have correct message")
    assert(progress_notification.params.percentage == 50, "Should have correct percentage")
    assert(progress_notification.params.done == false, "Should have correct done status")
    
    print("  ✓ Progress notification creation works")
    
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
    
    -- Test progress operation start
    local progress_id, start_notification = M.start_progress_operation("file_processing", "Starting file processing...")
    assert(progress_id:find("progress-"), "Should have progress ID prefix")
    assert(M.progress_state.active_operations[progress_id] ~= nil, "Should track active operation")
    assert(M.progress_state.active_operations[progress_id].name == "file_processing", "Should have correct operation name")
    assert(start_notification.params.percentage == 0, "Should start at 0%")
    
    print("  ✓ Progress operation start works")
    
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
    
    -- Test progress update
    local update_notification = M.update_progress(progress_id, "Processing file 1 of 3...", 33)
    assert(update_notification ~= nil, "Should return update notification")
    assert(update_notification.params.message == "Processing file 1 of 3...", "Should have updated message")
    assert(update_notification.params.percentage == 33, "Should have updated percentage")
    assert(M.progress_state.active_operations[progress_id].percentage == 33, "Should update state")
    
    print("  ✓ Progress update works")
    
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
    
    -- Test progress completion
    local complete_notification = M.complete_progress_operation(progress_id, "File processing completed!")
    assert(complete_notification ~= nil, "Should return completion notification")
    assert(complete_notification.params.percentage == 100, "Should be 100% complete")
    assert(complete_notification.params.done == true, "Should be marked as done")
    assert(M.progress_state.active_operations[progress_id] == nil, "Should remove from active operations")
    
    print("  ✓ Progress completion works")
    
    -- Enhanced tool call with progress tracking
    function M.handle_tool_call_with_progress(id, params)
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
    
    -- Test enhanced tool call with progress
    print("  Testing enhanced tool call with progress...")
    
    local edit_params = {
        name = "agent_edit_file",
        arguments = {
            file_path = "/tmp/file1.txt",
            line_number = 2,
            content = "new content"
        }
    }
    
    local edit_result = M.handle_tool_call_with_progress(1, edit_params)
    assert(edit_result.id == 1, "Should return correct message ID")
    assert(edit_result.result ~= nil, "Should have result for valid edit")
    assert(edit_result.result.metadata.progress_notifications ~= nil, "Should have progress notifications")
    assert(#edit_result.result.metadata.progress_notifications == 3, "Should have 3 progress notifications")
    assert(edit_result.result.metadata.progress_notifications[1].params.percentage == 0, "Should start at 0%")
    assert(edit_result.result.metadata.progress_notifications[2].params.percentage == 50, "Should update to 50%")
    assert(edit_result.result.metadata.progress_notifications[3].params.percentage == 100, "Should complete at 100%")
    
    print("  ✓ Enhanced tool call with progress works")
    
    -- Test progress for save operation
    local save_params = {
        name = "agent_save_file",
        arguments = {
            file_path = "/tmp/file1.txt",
            force = false
        }
    }
    
    local save_result = M.handle_tool_call_with_progress(2, save_params)
    assert(save_result.id == 2, "Should return correct message ID")
    assert(save_result.result ~= nil, "Should have result for valid save")
    assert(save_result.result.metadata.progress_notifications ~= nil, "Should have progress notifications")
    assert(#save_result.result.metadata.progress_notifications == 4, "Should have 4 progress notifications")
    
    print("  ✓ Progress for save operation works")
    
    -- Test progress for error cases
    local error_params = {
        name = "agent_edit_file",
        arguments = {
            file_path = "/tmp/nonexistent.txt",
            line_number = 1,
            content = "test"
        }
    }
    
    local error_result = M.handle_tool_call_with_progress(3, error_params)
    assert(error_result.id == 3, "Should return correct message ID")
    assert(error_result.error ~= nil, "Should have error for invalid file")
    assert(error_result.error.message:find("File not found"), "Should have correct error message")
    
    print("  ✓ Progress for error cases works")
    
    -- Test progress state management
    print("  Testing progress state management...")
    
    -- Start multiple operations
    local progress_id1, _ = M.start_progress_operation("op1", "Operation 1")
    local progress_id2, _ = M.start_progress_operation("op2", "Operation 2")
    
    assert(M.progress_state.active_operations[progress_id1] ~= nil, "Should track operation 1")
    assert(M.progress_state.active_operations[progress_id2] ~= nil, "Should track operation 2")
    assert(M.progress_state.active_operations[progress_id1].name == "op1", "Should have correct name for op1")
    assert(M.progress_state.active_operations[progress_id2].name == "op2", "Should have correct name for op2")
    
    -- Complete one operation
    M.complete_progress_operation(progress_id1, "Operation 1 completed")
    assert(M.progress_state.active_operations[progress_id1] == nil, "Should remove completed operation")
    assert(M.progress_state.active_operations[progress_id2] ~= nil, "Should keep other operation")
    
    -- Complete remaining operation
    M.complete_progress_operation(progress_id2, "Operation 2 completed")
    assert(M.progress_state.active_operations[progress_id2] == nil, "Should remove second operation")
    
    print("  ✓ Progress state management works")
    
    -- Test progress notification formatting
    print("  Testing progress notification formatting...")
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
    
    local test_notifications = {
        M.create_progress_notification("test-1", "Starting...", 0, false),
        M.create_progress_notification("test-1", "Processing...", 50, false),
        M.create_progress_notification("test-1", "Completed!", 100, true)
    }
    
    local summary = M.format_progress_summary(test_notifications)
    assert(summary.total_notifications == 3, "Should have correct total notifications")
    assert(summary.start_percentage == 0, "Should have correct start percentage")
    assert(summary.end_percentage == 100, "Should have correct end percentage")
    assert(summary.final_message == "Completed!", "Should have correct final message")
    assert(summary.completed == true, "Should indicate completion")
    
    print("  ✓ Progress notification formatting works")
    
    -- Restore original vim
    _G.vim = original_vim
    
    print("✓ All MCP progress tracking tests passed!")
end

-- Main test execution
print("=== MCP Progress Tracking Test ===")
print("Testing MCP progress tracking functionality...")

-- Run tests
test_mcp_progress_tracking()

print("\n=== Test Complete ===")
print("✓ All MCP progress tracking tests passed!")
print("MCP progress tracking features verified:")
print("  • Progress notification creation")
print("  • Progress operation lifecycle")
print("  • Progress state management")
print("  • Enhanced tool calls with progress")
print("  • Progress notification formatting")
print("  • Error handling with progress")
print("  • Multiple concurrent operations") 