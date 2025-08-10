-- Test enhanced MCP tool descriptions with pattern information
-- This test verifies that MCP tools include pattern relationships and usage guidance

print("=== Testing Enhanced MCP Tool Descriptions ===")

-- Add lua directory to package path
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

-- Try to load the module
local success, M = pcall(function()
    return require('paragonic.mcp')
end)

if not success then
    print("✗ Module loading failed: " .. tostring(M))
    os.exit(1)
end

print("✓ Module loaded successfully")

-- Initialize MCP server
local init_success = M.initialize_mcp_server()
if not init_success then
    print("✗ MCP server initialization failed")
    os.exit(1)
end

print("✓ MCP server initialized")

-- Test 1: Check that tools have pattern information
print("\n--- Test 1: Pattern Information ---")
local tools = M.list_mcp_tools()
print("Found " .. #tools .. " tools")

for i, tool in ipairs(tools) do
    print("Tool " .. i .. ": " .. tool.name)
    
    -- Check for patterns field
    if tool.patterns then
        print("  ✓ Has patterns field")
        if #tool.patterns > 0 then
            for j, pattern in ipairs(tool.patterns) do
                print("    Pattern " .. j .. ": " .. (pattern.pattern_id or "no_id"))
            end
        else
            print("    No patterns defined yet")
        end
    else
        print("  ✗ Missing patterns field")
    end
    
    -- Check for usage guidance
    if tool.usage_guidance then
        print("  ✓ Has usage guidance")
    else
        print("  ✗ Missing usage guidance")
    end
    
    -- Check for success metrics
    if tool.success_metrics then
        print("  ✓ Has success metrics")
    else
        print("  ✗ Missing success metrics")
    end
end

-- Test 2: Check backward compatibility
print("\n--- Test 2: Backward Compatibility ---")
for i, tool in ipairs(tools) do
    if tool.name and tool.description and tool.inputSchema then
        print("✓ Tool " .. i .. " maintains backward compatibility")
    else
        print("✗ Tool " .. i .. " missing required fields")
    end
end

-- Test 3: Test pattern-aware recommendations (if function exists)
print("\n--- Test 3: Pattern-Aware Recommendations ---")
if M.get_pattern_aware_tool_recommendations then
    local recommendations = M.get_pattern_aware_tool_recommendations("file_editing")
    if recommendations and #recommendations > 0 then
        print("✓ Pattern-aware recommendations working")
        for i, rec in ipairs(recommendations) do
            print("  Recommendation " .. i .. ": " .. rec.tool_name)
        end
    else
        print("✗ No recommendations returned")
    end
else
    print("⚠ Function get_pattern_aware_tool_recommendations not implemented yet")
end

-- Test 4: Test tool usage tracking (if function exists)
print("\n--- Test 4: Tool Usage Tracking ---")
if M.track_tool_usage then
    local test_tool = tools[1]
    if test_tool then
        local success = M.track_tool_usage(test_tool.name, "test_pattern_id", true)
        if success then
            print("✓ Tool usage tracking working")
        else
            print("✗ Tool usage tracking failed")
        end
    else
        print("⚠ No tools available for testing")
    end
else
    print("⚠ Function track_tool_usage not implemented yet")
end

print("\n=== Enhanced MCP Tool Descriptions Test Complete ===")
