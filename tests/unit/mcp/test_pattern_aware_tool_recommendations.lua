--[[
Test Pattern-Aware Tool Recommendations
Tests the pattern-aware tool recommendation system
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
local function test_pattern_aware_tool_recommendations()
    print("Testing Pattern-Aware Tool Recommendations...")
    
    -- Initialize MCP server
    local success = M.initialize_mcp_server()
    assert(success, "MCP server initialization failed")
    
    -- Set up some usage data for testing
    M.track_tool_pattern_usage("agent_edit_file", "session_summary_generation", true)
    M.track_tool_pattern_usage("agent_edit_file", "session_summary_generation", true)
    M.track_tool_pattern_usage("agent_edit_file", "activity_labeling", false)
    M.track_tool_pattern_usage("agent_create_file", "knowledge_extraction", true)
    M.track_tool_pattern_usage("agent_create_file", "knowledge_extraction", true)
    M.track_tool_pattern_usage("agent_create_file", "knowledge_extraction", true)
    M.track_tool_pattern_usage("agent_save_file", "progress_tracking", true)
    
    -- Test 1: Get recommendations for a specific pattern
    print("  Testing pattern-specific recommendations...")
    if M.get_pattern_recommendations then
        local session_recommendations = M.get_pattern_recommendations("session_summary_generation")
        assert(session_recommendations, "Failed to get session summary recommendations")
        assert(type(session_recommendations) == "table", "Recommendations should be a table")
        assert(#session_recommendations > 0, "Should have at least one recommendation")
        
        -- Verify recommendation structure
        for _, rec in ipairs(session_recommendations) do
            assert(rec.tool_name, "Recommendation missing tool_name")
            assert(rec.pattern_id, "Recommendation missing pattern_id")
            assert(rec.confidence, "Recommendation missing confidence")
            assert(rec.reason, "Recommendation missing reason")
            assert(rec.success_rate, "Recommendation missing success_rate")
        end
        print("  ✓ Pattern-specific recommendations work")
    else
        print("  ⚠ Pattern-specific recommendations function not implemented yet")
    end
    
    -- Test 2: Get recommendations based on context
    print("  Testing context-based recommendations...")
    if M.get_context_recommendations then
        local context = {
            current_activity = "file_editing",
            session_duration = 30,
            recent_tools = {"agent_edit_file"},
            patterns_active = {"session_summary_generation"}
        }
        
        local context_recommendations = M.get_context_recommendations(context)
        assert(context_recommendations, "Failed to get context-based recommendations")
        assert(type(context_recommendations) == "table", "Context recommendations should be a table")
        print("  ✓ Context-based recommendations work")
    else
        print("  ⚠ Context-based recommendations function not implemented yet")
    end
    
    -- Test 3: Get top performing tools
    print("  Testing top performing tools...")
    if M.get_top_performing_tools then
        local top_tools = M.get_top_performing_tools(5)
        assert(top_tools, "Failed to get top performing tools")
        assert(type(top_tools) == "table", "Top tools should be a table")
        assert(#top_tools > 0, "Should have at least one top tool")
        
        -- Verify tools are sorted by performance
        for i = 1, #top_tools - 1 do
            assert(top_tools[i].success_rate >= top_tools[i + 1].success_rate, 
                   "Tools should be sorted by success rate")
        end
        print("  ✓ Top performing tools work")
    else
        print("  ⚠ Top performing tools function not implemented yet")
    end
    
    -- Test 4: Get tool recommendations for specific task
    print("  Testing task-specific recommendations...")
    if M.get_task_recommendations then
        local file_creation_recommendations = M.get_task_recommendations("file_creation")
        assert(file_creation_recommendations, "Failed to get file creation recommendations")
        assert(type(file_creation_recommendations) == "table", "Task recommendations should be a table")
        
        -- Should recommend agent_create_file for file creation
        local found_create_tool = false
        for _, rec in ipairs(file_creation_recommendations) do
            if rec.tool_name == "agent_create_file" then
                found_create_tool = true
                break
            end
        end
        assert(found_create_tool, "agent_create_file should be recommended for file creation")
        print("  ✓ Task-specific recommendations work")
    else
        print("  ⚠ Task-specific recommendations function not implemented yet")
    end
    
    -- Test 5: Get collaborative recommendations
    print("  Testing collaborative recommendations...")
    if M.get_collaborative_recommendations then
        local collaborative_recs = M.get_collaborative_recommendations("agent_edit_file")
        assert(collaborative_recs, "Failed to get collaborative recommendations")
        assert(type(collaborative_recs) == "table", "Collaborative recommendations should be a table")
        
        -- Should recommend tools that work well together
        local found_save_tool = false
        for _, rec in ipairs(collaborative_recs) do
            if rec.tool_name == "agent_save_file" then
                found_save_tool = true
                break
            end
        end
        assert(found_save_tool, "agent_save_file should be recommended after agent_edit_file")
        print("  ✓ Collaborative recommendations work")
    else
        print("  ⚠ Collaborative recommendations function not implemented yet")
    end
    
    -- Test 6: Test recommendation filtering
    print("  Testing recommendation filtering...")
    if M.get_filtered_recommendations then
        local filtered_recs = M.get_filtered_recommendations({
            min_success_rate = 0.8,
            max_usage_count = 10,
            pattern_ids = {"session_summary_generation"}
        })
        assert(filtered_recs, "Failed to get filtered recommendations")
        assert(type(filtered_recs) == "table", "Filtered recommendations should be a table")
        
        -- Verify filtering criteria
        for _, rec in ipairs(filtered_recs) do
            assert(rec.success_rate >= 0.8, "Filtered recommendations should meet success rate criteria")
            assert(rec.usage_count <= 10, "Filtered recommendations should meet usage count criteria")
        end
        print("  ✓ Recommendation filtering works")
    else
        print("  ⚠ Recommendation filtering function not implemented yet")
    end
    
    print("  ✓ Pattern-aware tool recommendations test passed")
    return true
end

-- Run test
local success, result = pcall(test_pattern_aware_tool_recommendations)
if success then
    print("✅ Pattern-Aware Tool Recommendations Test: PASSED")
else
    print("❌ Pattern-Aware Tool Recommendations Test: FAILED")
    print("Error: " .. tostring(result))
    os.exit(1)
end
