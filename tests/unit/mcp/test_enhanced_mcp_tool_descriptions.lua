--[[
Test Enhanced MCP Tool Descriptions
Tests the enhanced MCP tools with pattern information
--]]

-- Add lua directory to package path
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

local M = require('paragonic.mcp')

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

-- Test function
local function test_enhanced_mcp_tool_descriptions()
    print("Testing Enhanced MCP Tool Descriptions...")
    
    -- Initialize MCP server
    local success = M.initialize_mcp_server()
    assert(success, "MCP server initialization failed")
    
    -- Get MCP tools
    local tools = M.list_mcp_tools()
    assert(tools, "Failed to get MCP tools")
    assert(#tools >= 3, "Expected at least 3 MCP tools")
    
    -- Test agent_edit_file tool
    local edit_tool = nil
    for _, tool in ipairs(tools) do
        if tool.name == "agent_edit_file" then
            edit_tool = tool
            break
        end
    end
    assert(edit_tool, "agent_edit_file tool not found")
    assert(edit_tool.patterns, "agent_edit_file missing patterns")
    assert(#edit_tool.patterns >= 2, "agent_edit_file should have at least 2 patterns")
    assert(edit_tool.usage_guidance, "agent_edit_file missing usage guidance")
    assert(edit_tool.success_metrics, "agent_edit_file missing success metrics")
    print("  ✓ agent_edit_file tool enhanced with pattern information")
    
    -- Test agent_create_file tool
    local create_tool = nil
    for _, tool in ipairs(tools) do
        if tool.name == "agent_create_file" then
            create_tool = tool
            break
        end
    end
    assert(create_tool, "agent_create_file tool not found")
    assert(create_tool.patterns, "agent_create_file missing patterns")
    assert(#create_tool.patterns >= 3, "agent_create_file should have at least 3 patterns")
    assert(create_tool.usage_guidance, "agent_create_file missing usage guidance")
    assert(create_tool.success_metrics, "agent_create_file missing success metrics")
    
    -- Verify agent_create_file pattern relationships
    local has_session_summary = false
    local has_activity_labeling = false
    local has_knowledge_extraction = false
    for _, pattern in ipairs(create_tool.patterns) do
        if pattern.pattern_id == "session_summary_generation" then
            has_session_summary = true
        elseif pattern.pattern_id == "activity_labeling" then
            has_activity_labeling = true
        elseif pattern.pattern_id == "knowledge_extraction" then
            has_knowledge_extraction = true
        end
    end
    assert(has_session_summary, "agent_create_file missing session_summary_generation pattern")
    assert(has_activity_labeling, "agent_create_file missing activity_labeling pattern")
    assert(has_knowledge_extraction, "agent_create_file missing knowledge_extraction pattern")
    print("  ✓ agent_create_file tool enhanced with pattern information")
    
    -- Test agent_save_file tool
    local save_tool = nil
    for _, tool in ipairs(tools) do
        if tool.name == "agent_save_file" then
            save_tool = tool
            break
        end
    end
    assert(save_tool, "agent_save_file tool not found")
    assert(save_tool.patterns, "agent_save_file missing patterns")
    assert(#save_tool.patterns >= 3, "agent_save_file should have at least 3 patterns")
    assert(save_tool.usage_guidance, "agent_save_file missing usage guidance")
    assert(save_tool.success_metrics, "agent_save_file missing success metrics")
    
    -- Verify agent_save_file pattern relationships
    local has_progress_tracking = false
    local has_activity_labeling_save = false
    local has_session_summary_save = false
    for _, pattern in ipairs(save_tool.patterns) do
        if pattern.pattern_id == "progress_tracking" then
            has_progress_tracking = true
        elseif pattern.pattern_id == "activity_labeling" then
            has_activity_labeling_save = true
        elseif pattern.pattern_id == "session_summary_generation" then
            has_session_summary_save = true
        end
    end
    assert(has_progress_tracking, "agent_save_file missing progress_tracking pattern")
    assert(has_activity_labeling_save, "agent_save_file missing activity_labeling pattern")
    assert(has_session_summary_save, "agent_save_file missing session_summary_generation pattern")
    print("  ✓ agent_save_file tool enhanced with pattern information")
    
    -- Test schema validation
    assert(edit_tool.inputSchema, "agent_edit_file missing inputSchema")
    assert(edit_tool.inputSchema.type == "object", "agent_edit_file inputSchema should be object type")
    assert(edit_tool.inputSchema.required, "agent_edit_file missing required fields")
    
    assert(create_tool.inputSchema, "agent_create_file missing inputSchema")
    assert(create_tool.inputSchema.type == "object", "agent_create_file inputSchema should be object type")
    assert(create_tool.inputSchema.required, "agent_create_file missing required fields")
    
    assert(save_tool.inputSchema, "agent_save_file missing inputSchema")
    assert(save_tool.inputSchema.type == "object", "agent_save_file inputSchema should be object type")
    print("  ✓ All tools have proper input schemas")
    
    -- Test success metrics
    assert(edit_tool.success_metrics.success_rate > 0, "agent_edit_file success rate should be positive")
    assert(create_tool.success_metrics.success_rate > 0, "agent_create_file success rate should be positive")
    assert(save_tool.success_metrics.success_rate > 0, "agent_save_file success rate should be positive")
    print("  ✓ All tools have success metrics")
    
    print("  ✓ Enhanced MCP tool descriptions test passed")
    return true
end

-- Run test
local success, result = pcall(test_enhanced_mcp_tool_descriptions)
if success then
    print("✅ Enhanced MCP Tool Descriptions Test: PASSED")
else
    print("❌ Enhanced MCP Tool Descriptions Test: FAILED")
    print("Error: " .. tostring(result))
    os.exit(1)
end
