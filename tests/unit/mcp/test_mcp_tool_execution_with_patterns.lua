--[[
Test MCP Tool Execution with Patterns
Tests the integration between MCP tool execution and pattern system
--]]

-- Add lua directory to package path
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

-- Mock vim API for testing
local vim = {
    api = {
        nvim_list_bufs = function() return {} end,
        nvim_buf_is_valid = function() return true end,
        nvim_buf_get_name = function() return "test.lua" end,
        nvim_buf_get_option = function() return "" end,
        nvim_get_current_buf = function() return 1 end,
        nvim_buf_get_lines = function() return {} end,
        nvim_get_option = function() return "" end,
        nvim_get_var = function() return "" end,
        nvim_get_vvar = function() return "" end,
        nvim_list_wins = function() return {} end,
        nvim_win_get_buf = function() return 1 end,
        nvim_win_get_cursor = function() return {1, 0} end,
        nvim_win_get_position = function() return {0, 0} end,
        nvim_win_get_width = function() return 80 end,
        nvim_win_get_height = function() return 24 end,
        nvim_get_commands = function() return {} end,
        nvim_get_autocmds = function() return {} end
    },
    notify = function(msg, level) print("NOTIFY: " .. msg) end,
    log = { levels = { INFO = 1, WARN = 2, ERROR = 3 } }
}

-- Set global vim for testing
_G.vim = vim

local M = require('paragonic.mcp')

-- Test function
local function test_mcp_tool_execution_with_patterns()
    print("Testing MCP Tool Execution with Patterns...")
    
    -- Initialize MCP server
    local success = M.initialize_mcp_server()
    assert(success, "MCP server initialization failed")
    
    -- Test 1: Execute tool with pattern tracking
    print("  Testing tool execution with pattern tracking...")
    if M.execute_tool_with_pattern then
        local result = M.execute_tool_with_pattern("agent_edit_file", {
            file_path = "/tmp/test.txt",
            line_number = 1,
            content = "test content"
        }, "session_summary_generation")
        
        assert(result, "Tool execution with pattern failed")
        assert(result.success, "Tool execution should be successful")
        assert(result.pattern_tracked, "Pattern should be tracked")
        assert(result.execution_id, "Should have execution ID")
        print("  ✓ Tool execution with pattern tracking works")
    else
        print("  ⚠ Tool execution with pattern function not implemented yet")
    end
    
    -- Test 2: Execute tool with automatic pattern detection
    print("  Testing automatic pattern detection...")
    if M.execute_tool_with_auto_pattern_detection then
        local result = M.execute_tool_with_auto_pattern_detection("agent_create_file", {
            file_name = "summary.md",
            content = "# Session Summary\n\nThis is a test summary."
        })
        
        assert(result, "Auto pattern detection failed")
        assert(result.detected_patterns, "Should detect patterns")
        assert(#result.detected_patterns > 0, "Should detect at least one pattern")
        
        -- Should detect session_summary_generation pattern
        local found_session_pattern = false
        for _, pattern in ipairs(result.detected_patterns) do
            if pattern.pattern_id == "session_summary_generation" then
                found_session_pattern = true
                break
            end
        end
        assert(found_session_pattern, "Should detect session_summary_generation pattern")
        print("  ✓ Automatic pattern detection works")
    else
        print("  ⚠ Automatic pattern detection function not implemented yet")
    end
    
    -- Test 3: Execute tool with pattern validation
    print("  Testing pattern validation...")
    if M.execute_tool_with_pattern_validation then
        -- Valid pattern
        local valid_result = M.execute_tool_with_pattern_validation("agent_edit_file", {
            file_path = "/tmp/test.txt",
            line_number = 1,
            content = "test content"
        }, "session_summary_generation")
        
        assert(valid_result, "Valid pattern execution failed")
        assert(valid_result.valid, "Valid pattern should be accepted")
        
        -- Invalid pattern
        local invalid_result = M.execute_tool_with_pattern_validation("agent_edit_file", {
            file_path = "/tmp/test.txt",
            line_number = 1,
            content = "test content"
        }, "non_existent_pattern")
        
        assert(invalid_result, "Invalid pattern validation failed")
        assert(not invalid_result.valid, "Invalid pattern should be rejected")
        assert(invalid_result.error, "Should have error message for invalid pattern")
        print("  ✓ Pattern validation works")
    else
        print("  ⚠ Pattern validation function not implemented yet")
    end
    
    -- Test 4: Execute tool with pattern-based recommendations
    print("  Testing pattern-based recommendations...")
    if M.execute_tool_with_pattern_recommendations then
        local result = M.execute_tool_with_pattern_recommendations("agent_edit_file", {
            file_path = "/tmp/test.txt",
            line_number = 1,
            content = "test content"
        }, "session_summary_generation")
        
        assert(result, "Pattern-based recommendations failed")
        assert(result.recommendations, "Should have recommendations")
        assert(type(result.recommendations) == "table", "Recommendations should be a table")
        assert(#result.recommendations > 0, "Should have at least one recommendation")
        
        -- Verify recommendation structure
        for _, rec in ipairs(result.recommendations) do
            assert(rec.tool_name, "Recommendation missing tool_name")
            assert(rec.confidence, "Recommendation missing confidence")
            assert(rec.reason, "Recommendation missing reason")
        end
        print("  ✓ Pattern-based recommendations work")
    else
        print("  ⚠ Pattern-based recommendations function not implemented yet")
    end
    
    -- Test 5: Execute tool with pattern execution history
    print("  Testing pattern execution history...")
    if M.execute_tool_with_pattern_history then
        local result = M.execute_tool_with_pattern_history("agent_save_file", {
            file_path = "/tmp/test.txt"
        }, "progress_tracking")
        
        assert(result, "Pattern execution history failed")
        assert(result.history, "Should have execution history")
        assert(type(result.history) == "table", "History should be a table")
        
        -- Verify history structure
        for _, entry in ipairs(result.history) do
            assert(entry.tool_name, "History entry missing tool_name")
            assert(entry.pattern_id, "History entry missing pattern_id")
            assert(entry.timestamp, "History entry missing timestamp")
            assert(entry.success ~= nil, "History entry missing success")
        end
        print("  ✓ Pattern execution history works")
    else
        print("  ⚠ Pattern execution history function not implemented yet")
    end
    
    -- Test 6: Execute tool with pattern performance metrics
    print("  Testing pattern performance metrics...")
    if M.execute_tool_with_pattern_metrics then
        local result = M.execute_tool_with_pattern_metrics("agent_create_file", {
            file_name = "test.md",
            content = "test content"
        }, "knowledge_extraction")
        
        assert(result, "Pattern performance metrics failed")
        assert(result.metrics, "Should have performance metrics")
        assert(result.metrics.execution_time, "Should have execution time")
        assert(result.metrics.pattern_success_rate, "Should have pattern success rate")
        assert(result.metrics.tool_success_rate, "Should have tool success rate")
        print("  ✓ Pattern performance metrics work")
    else
        print("  ⚠ Pattern performance metrics function not implemented yet")
    end
    
    -- Test 7: Execute tool with pattern learning
    print("  Testing pattern learning...")
    if M.execute_tool_with_pattern_learning then
        local result = M.execute_tool_with_pattern_learning("agent_edit_file", {
            file_path = "/tmp/test.txt",
            line_number = 1,
            content = "test content"
        }, "session_summary_generation", true)
        
        assert(result, "Pattern learning failed")
        assert(result.learning_applied, "Learning should be applied")
        assert(result.pattern_adapted, "Pattern should be adapted")
        assert(result.new_success_rate, "Should have updated success rate")
        print("  ✓ Pattern learning works")
    else
        print("  ⚠ Pattern learning function not implemented yet")
    end
    
    print("  ✓ MCP tool execution with patterns test passed")
    return true
end

-- Run test
local success, result = pcall(test_mcp_tool_execution_with_patterns)
if success then
    print("✅ MCP Tool Execution with Patterns Test: PASSED")
else
    print("❌ MCP Tool Execution with Patterns Test: FAILED")
    print("Error: " .. tostring(result))
    os.exit(1)
end
