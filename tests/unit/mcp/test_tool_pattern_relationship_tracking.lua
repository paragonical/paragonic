--[[
Test Tool-Pattern Relationship Tracking
Tests the tracking of relationships between MCP tools and patterns
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
local function test_tool_pattern_relationship_tracking()
    print("Testing Tool-Pattern Relationship Tracking...")
    
    -- Initialize MCP server
    local success = M.initialize_mcp_server()
    assert(success, "MCP server initialization failed")
    
    -- Get MCP tools
    local tools = M.list_mcp_tools()
    assert(tools, "Failed to get MCP tools")
    assert(#tools >= 3, "Expected at least 3 MCP tools")
    
    -- Test 1: Verify tool-pattern relationships exist
    print("  Testing tool-pattern relationship existence...")
    for _, tool in ipairs(tools) do
        assert(tool.patterns, "Tool " .. tool.name .. " missing patterns field")
        assert(type(tool.patterns) == "table", "Tool " .. tool.name .. " patterns should be a table")
        assert(#tool.patterns > 0, "Tool " .. tool.name .. " should have at least one pattern")
        
        for _, pattern in ipairs(tool.patterns) do
            assert(pattern.pattern_id, "Pattern missing pattern_id")
            assert(pattern.relationship_type, "Pattern missing relationship_type")
            assert(pattern.description, "Pattern missing description")
            
            -- Verify relationship types are valid
            local valid_types = {"input", "output", "enhance", "trigger", "prerequisite"}
            local valid_type = false
            for _, valid_type_name in ipairs(valid_types) do
                if pattern.relationship_type == valid_type_name then
                    valid_type = true
                    break
                end
            end
            assert(valid_type, "Invalid relationship_type: " .. pattern.relationship_type)
        end
    end
    print("  ✓ All tools have valid pattern relationships")
    
    -- Test 2: Verify pattern IDs are consistent
    print("  Testing pattern ID consistency...")
    local pattern_ids = {}
    for _, tool in ipairs(tools) do
        for _, pattern in ipairs(tool.patterns) do
            if not pattern_ids[pattern.pattern_id] then
                pattern_ids[pattern.pattern_id] = {}
            end
            table.insert(pattern_ids[pattern.pattern_id], {
                tool_name = tool.name,
                relationship_type = pattern.relationship_type
            })
        end
    end
    
    -- Verify we have the expected patterns
    local expected_patterns = {
        "session_summary_generation",
        "activity_labeling", 
        "knowledge_extraction",
        "progress_tracking"
    }
    
    for _, expected_pattern in ipairs(expected_patterns) do
        assert(pattern_ids[expected_pattern], "Missing expected pattern: " .. expected_pattern)
        assert(#pattern_ids[expected_pattern] > 0, "Pattern " .. expected_pattern .. " has no tool relationships")
    end
    print("  ✓ Pattern IDs are consistent and complete")
    
    -- Test 3: Test relationship tracking functions (if they exist)
    print("  Testing relationship tracking functions...")
    if M.track_tool_pattern_usage then
        -- Test tracking a tool usage with a pattern
        local test_result = M.track_tool_pattern_usage("agent_edit_file", "session_summary_generation", true)
        assert(test_result, "Tool-pattern usage tracking failed")
        print("  ✓ Tool-pattern usage tracking function works")
    else
        print("  ⚠ Tool-pattern usage tracking function not implemented yet")
    end
    
    -- Test 4: Test pattern-aware tool lookup
    print("  Testing pattern-aware tool lookup...")
    if M.get_tools_for_pattern then
        local tools_for_session = M.get_tools_for_pattern("session_summary_generation")
        assert(tools_for_session, "Failed to get tools for session_summary_generation pattern")
        assert(type(tools_for_session) == "table", "Tools for pattern should be a table")
        assert(#tools_for_session > 0, "Should have at least one tool for session_summary_generation")
        print("  ✓ Pattern-aware tool lookup works")
    else
        print("  ⚠ Pattern-aware tool lookup function not implemented yet")
    end
    
    -- Test 5: Test tool usage statistics
    print("  Testing tool usage statistics...")
    for _, tool in ipairs(tools) do
        assert(tool.success_metrics, "Tool " .. tool.name .. " missing success_metrics")
        assert(type(tool.success_metrics.success_rate) == "number", "Success rate should be a number")
        assert(tool.success_metrics.success_rate >= 0 and tool.success_metrics.success_rate <= 1, 
               "Success rate should be between 0 and 1")
        assert(type(tool.success_metrics.usage_count) == "number", "Usage count should be a number")
        assert(tool.success_metrics.usage_count >= 0, "Usage count should be non-negative")
    end
    print("  ✓ All tools have valid usage statistics")
    
    -- Test 6: Test relationship metadata
    print("  Testing relationship metadata...")
    for _, tool in ipairs(tools) do
        for _, pattern in ipairs(tool.patterns) do
            -- Verify pattern descriptions are meaningful
            assert(string.len(pattern.description) > 10, "Pattern description too short")
            assert(string.find(pattern.description, "pattern"), "Pattern description should mention pattern")
        end
    end
    print("  ✓ All relationship metadata is valid")
    
    print("  ✓ Tool-pattern relationship tracking test passed")
    return true
end

-- Run test
local success, result = pcall(test_tool_pattern_relationship_tracking)
if success then
    print("✅ Tool-Pattern Relationship Tracking Test: PASSED")
else
    print("❌ Tool-Pattern Relationship Tracking Test: FAILED")
    print("Error: " .. tostring(result))
    os.exit(1)
end
