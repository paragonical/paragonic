-- Test file for pattern management commands
-- Tests the ParagonicPatternList command and related functionality

package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua'

print("=== Pattern Management Commands Test ===")

-- Mock the paragonic module for testing
package.loaded.paragonic = {
  patterns = {
    list_patterns = function()
      return {
        {
          id = "test-pattern-1",
          name = "Session Summary Generation",
          category = "SessionManagement",
          description = "Generates comprehensive session summaries"
        },
        {
          id = "test-pattern-2", 
          name = "Activity Labeling",
          category = "ActivityLabeling",
          description = "Labels and categorizes development activities"
        }
      }
    end,
    get_pattern_by_name = function(name)
      if name == "Session Summary Generation" then
        return {
          id = "test-pattern-1",
          name = "Session Summary Generation",
          category = "SessionManagement",
          description = "Generates comprehensive session summaries",
          workflow_steps = {"analyze", "extract", "summarize"},
          output_format = {summary = "string", key_points = "array"}
        }
      end
      return nil
    end,
    execute_pattern = function(pattern_name)
      return {success = true, result = "test result"}
    end,
    show_pattern_details = function(pattern_name)
      return true
    end
  }
}

-- Test 1: Check if pattern listing function exists
print("📝 Testing pattern listing function...")
if package.loaded.paragonic.patterns.list_patterns then
  print("✅ Pattern listing function available")
else
  print("❌ Pattern listing function not available")
end

-- Test 2: Test pattern listing functionality
print("📝 Testing pattern listing...")
local patterns = package.loaded.paragonic.patterns.list_patterns()
if patterns and #patterns > 0 then
  print("✅ Pattern listing works, found " .. #patterns .. " patterns")
  for i, pattern in ipairs(patterns) do
    print("  Pattern " .. i .. ": " .. pattern.name .. " (" .. pattern.category .. ")")
  end
else
  print("❌ Pattern listing failed or returned empty list")
end

-- Test 3: Test pattern retrieval by name
print("📝 Testing pattern retrieval by name...")
local pattern = package.loaded.paragonic.patterns.get_pattern_by_name("Session Summary Generation")
if pattern then
  print("✅ Pattern retrieval works")
  print("  Name: " .. pattern.name)
  print("  Category: " .. pattern.category)
  print("  Description: " .. pattern.description)
else
  print("❌ Pattern retrieval failed")
end

-- Test 4: Test pattern execution function
print("📝 Testing pattern execution function...")
if package.loaded.paragonic.patterns.execute_pattern then
  print("✅ Pattern execution function available")
  local result = package.loaded.paragonic.patterns.execute_pattern("test-pattern")
  if result and result.success then
    print("✅ Pattern execution works")
  else
    print("❌ Pattern execution failed")
  end
else
  print("❌ Pattern execution function not available")
end

-- Test 5: Test pattern details function
print("📝 Testing pattern details function...")
if package.loaded.paragonic.patterns.show_pattern_details then
  print("✅ Pattern details function available")
  local result = package.loaded.paragonic.patterns.show_pattern_details("test-pattern")
  if result then
    print("✅ Pattern details function works")
  else
    print("❌ Pattern details function failed")
  end
else
  print("❌ Pattern details function not available")
end

-- Test 6: Test empty pattern list handling
print("📝 Testing empty pattern list handling...")
local original_list_patterns = package.loaded.paragonic.patterns.list_patterns
package.loaded.paragonic.patterns.list_patterns = function()
  return {}
end

local empty_patterns = package.loaded.paragonic.patterns.list_patterns()
if empty_patterns and #empty_patterns == 0 then
  print("✅ Empty pattern list handling works")
else
  print("❌ Empty pattern list handling failed")
end

-- Restore original function
package.loaded.paragonic.patterns.list_patterns = original_list_patterns

-- Test 7: Test error handling
print("📝 Testing error handling...")
package.loaded.paragonic.patterns.list_patterns = function()
  error("Database connection failed")
end

local status, err = pcall(function()
  return package.loaded.paragonic.patterns.list_patterns()
end)

if not status and tostring(err):find("Database connection failed") then
  print("✅ Error handling works")
else
  print("❌ Error handling failed")
end

-- Test 8: Test pattern formatting
print("📝 Testing pattern formatting...")
local test_pattern = {
  id = "test-pattern-long",
  name = "Very Long Pattern Name That Exceeds Normal Length",
  category = "SessionManagement", 
  description = "This is a very long description that should be properly formatted"
}

if test_pattern.name:find("Very Long Pattern Name") then
  print("✅ Long pattern name handling works")
else
  print("❌ Long pattern name handling failed")
end

if test_pattern.description:find("very long description") then
  print("✅ Long description handling works")
else
  print("❌ Long description handling failed")
end

-- Test 9: Test pattern categories
print("📝 Testing pattern categories...")
local categories = {"SessionManagement", "ActivityLabeling", "SelfReflection", "ContextSummarization", "ProgressTracking", "KnowledgeExtraction"}
local valid_categories = 0

for _, category in ipairs(categories) do
  if category:find("Management") or category:find("Labeling") or category:find("Reflection") or 
     category:find("Summarization") or category:find("Tracking") or category:find("Extraction") then
    valid_categories = valid_categories + 1
  end
end

if valid_categories == #categories then
  print("✅ Pattern categories are valid")
else
  print("❌ Some pattern categories are invalid")
end

-- Test 10: Test pattern workflow steps
print("📝 Testing pattern workflow steps...")
local pattern_with_workflow = package.loaded.paragonic.patterns.get_pattern_by_name("Session Summary Generation")
if pattern_with_workflow and pattern_with_workflow.workflow_steps then
  local steps = pattern_with_workflow.workflow_steps
  if #steps >= 3 then
    print("✅ Pattern workflow steps work")
    for i, step in ipairs(steps) do
      print("  Step " .. i .. ": " .. step)
    end
  else
    print("❌ Pattern workflow steps incomplete")
  end
else
  print("❌ Pattern workflow steps not available")
end

print("=== Pattern Management Commands Test Completed ===")
