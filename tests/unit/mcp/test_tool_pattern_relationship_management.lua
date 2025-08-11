--[[
Test Tool-Pattern Relationship Management
Tests the management of relationships between MCP tools and patterns
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
local function test_tool_pattern_relationship_management()
    print("Testing Tool-Pattern Relationship Management...")
    
    -- Initialize MCP server
    local success = M.initialize_mcp_server()
    assert(success, "MCP server initialization failed")
    
    -- Test 1: Track tool-pattern usage
    print("  Testing tool-pattern usage tracking...")
    local track_result = M.track_tool_pattern_usage("agent_edit_file", "session_summary_generation", true)
    assert(track_result, "Tool-pattern usage tracking failed")
    
    -- Test tracking multiple usages
    M.track_tool_pattern_usage("agent_edit_file", "session_summary_generation", false)
    M.track_tool_pattern_usage("agent_edit_file", "activity_labeling", true)
    M.track_tool_pattern_usage("agent_create_file", "knowledge_extraction", true)
    print("  ✓ Tool-pattern usage tracking works")
    
    -- Test 2: Get tools for pattern
    print("  Testing get tools for pattern...")
    local tools_for_session = M.get_tools_for_pattern("session_summary_generation")
    assert(tools_for_session, "Failed to get tools for session_summary_generation")
    assert(type(tools_for_session) == "table", "Tools for pattern should be a table")
    assert(#tools_for_session > 0, "Should have at least one tool for session_summary_generation")
    
    -- Verify tool information
    local found_edit_tool = false
    for _, tool_info in ipairs(tools_for_session) do
        if tool_info.tool_name == "agent_edit_file" then
            found_edit_tool = true
            assert(tool_info.relationship_type, "Tool info missing relationship_type")
            assert(tool_info.description, "Tool info missing description")
            assert(tool_info.tool_description, "Tool info missing tool_description")
            break
        end
    end
    assert(found_edit_tool, "agent_edit_file not found in session_summary_generation tools")
    print("  ✓ Get tools for pattern works")
    
    -- Test 3: Get patterns for tool
    print("  Testing get patterns for tool...")
    local patterns_for_edit = M.get_patterns_for_tool("agent_edit_file")
    assert(patterns_for_edit, "Failed to get patterns for agent_edit_file")
    assert(type(patterns_for_edit) == "table", "Patterns for tool should be a table")
    assert(#patterns_for_edit > 0, "Should have at least one pattern for agent_edit_file")
    
    -- Verify pattern information
    local found_session_pattern = false
    for _, pattern in ipairs(patterns_for_edit) do
        if pattern.pattern_id == "session_summary_generation" then
            found_session_pattern = true
            assert(pattern.relationship_type, "Pattern missing relationship_type")
            assert(pattern.description, "Pattern missing description")
            break
        end
    end
    assert(found_session_pattern, "session_summary_generation pattern not found for agent_edit_file")
    print("  ✓ Get patterns for tool works")
    
    -- Test 4: Get usage statistics
    print("  Testing usage statistics...")
    local stats = M.get_tool_pattern_usage_stats("agent_edit_file", "session_summary_generation")
    assert(stats, "Failed to get usage statistics")
    assert(type(stats.total_usage) == "number", "Total usage should be a number")
    assert(type(stats.successful_usage) == "number", "Successful usage should be a number")
    assert(type(stats.success_rate) == "number", "Success rate should be a number")
    assert(stats.total_usage == 2, "Expected 2 total usages")
    assert(stats.successful_usage == 1, "Expected 1 successful usage")
    assert(stats.success_rate == 0.5, "Expected 50% success rate")
    assert(stats.last_used, "Last used should be set")
    print("  ✓ Usage statistics work correctly")
    
    -- Test 5: Test non-existent tool/pattern
    print("  Testing non-existent tool/pattern handling...")
    local non_existent_stats = M.get_tool_pattern_usage_stats("non_existent_tool", "non_existent_pattern")
    assert(non_existent_stats == nil, "Should return nil for non-existent tool/pattern")
    
    local non_existent_patterns = M.get_patterns_for_tool("non_existent_tool")
    assert(type(non_existent_patterns) == "table", "Should return empty table for non-existent tool")
    assert(#non_existent_patterns == 0, "Should return empty table for non-existent tool")
    
    local non_existent_tools = M.get_tools_for_pattern("non_existent_pattern")
    assert(type(non_existent_tools) == "table", "Should return empty table for non-existent pattern")
    assert(#non_existent_tools == 0, "Should return empty table for non-existent pattern")
    print("  ✓ Non-existent tool/pattern handling works")
    
    -- Test 6: Verify tool success metrics are updated
    print("  Testing tool success metrics updates...")
    local tools = M.list_mcp_tools()
    local edit_tool = nil
    for _, tool in ipairs(tools) do
        if tool.name == "agent_edit_file" then
            edit_tool = tool
            break
        end
    end
    assert(edit_tool, "agent_edit_file tool not found")
    assert(edit_tool.success_metrics.usage_count > 0, "Usage count should be updated")
    assert(edit_tool.success_metrics.last_used, "Last used should be updated")
    print("  ✓ Tool success metrics are updated correctly")
    
    print("  ✓ Tool-pattern relationship management test passed")
    return true
end

-- Run test
local success, result = pcall(test_tool_pattern_relationship_management)
if success then
    print("✅ Tool-Pattern Relationship Management Test: PASSED")
else
    print("❌ Tool-Pattern Relationship Management Test: FAILED")
    print("Error: " .. tostring(result))
    os.exit(1)
end
