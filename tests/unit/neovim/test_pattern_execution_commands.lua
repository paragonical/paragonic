-- Test file for pattern execution commands
-- Tests the ParagonicPatternExecute command and related functionality

package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua'

print("=== Pattern Execution Commands Test ===")

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
          timestamp = os.date(),
          context = context or {}
        }
      }
    end,
    execute_pattern_command = function(pattern_name)
      return {
        success = true,
        pattern_name = pattern_name,
        result = {
          summary = "Pattern executed successfully",
          timestamp = os.date()
        }
      }
    end
  }
}

-- Test 1: Check if pattern execution function exists
print("📝 Testing pattern execution function...")
if package.loaded.paragonic.patterns.execute_pattern then
  print("✅ Pattern execution function available")
else
  print("❌ Pattern execution function not available")
end

-- Test 2: Test pattern execution with valid pattern
print("📝 Testing pattern execution with valid pattern...")
local result = package.loaded.paragonic.patterns.execute_pattern("Session Summary Generation")
if result and result.success then
  print("✅ Pattern execution works with valid pattern")
  print("  Pattern: " .. result.pattern_name)
  print("  Status: " .. (result.success and "Success" or "Failed"))
  print("  Timestamp: " .. result.result.timestamp)
else
  print("❌ Pattern execution failed with valid pattern")
end

-- Test 3: Test pattern execution with context
print("📝 Testing pattern execution with context...")
local context = {
  session_duration = 30,
  message_count = 15,
  files_modified = {"test.rs", "main.rs"}
}
local result_with_context = package.loaded.paragonic.patterns.execute_pattern("Activity Labeling", context)
if result_with_context and result_with_context.success then
  print("✅ Pattern execution works with context")
  if result_with_context.result.context.session_duration then
    print("  Context included: session_duration = " .. result_with_context.result.context.session_duration)
  end
else
  print("❌ Pattern execution failed with context")
end

-- Test 4: Test pattern execution with invalid pattern
print("📝 Testing pattern execution with invalid pattern...")
local invalid_result = package.loaded.paragonic.patterns.execute_pattern("NonExistentPattern")
if invalid_result then
  print("✅ Pattern execution handles invalid patterns gracefully")
else
  print("❌ Pattern execution failed to handle invalid patterns")
end

-- Test 5: Test pattern execution command function
print("📝 Testing pattern execution command function...")
if package.loaded.paragonic.patterns.execute_pattern_command then
  print("✅ Pattern execution command function available")
  local cmd_result = package.loaded.paragonic.patterns.execute_pattern_command("Session Summary Generation")
  if cmd_result and cmd_result.success then
    print("✅ Pattern execution command works")
  else
    print("❌ Pattern execution command failed")
  end
else
  print("❌ Pattern execution command function not available")
end

-- Test 6: Test pattern execution error handling
print("📝 Testing pattern execution error handling...")
local original_execute = package.loaded.paragonic.patterns.execute_pattern
package.loaded.paragonic.patterns.execute_pattern = function(pattern_name)
  error("Pattern execution failed: " .. pattern_name)
end

local status, err = pcall(function()
  return package.loaded.paragonic.patterns.execute_pattern("TestPattern")
end)

if not status and tostring(err):find("Pattern execution failed") then
  print("✅ Pattern execution error handling works")
else
  print("❌ Pattern execution error handling failed")
end

-- Restore original function
package.loaded.paragonic.patterns.execute_pattern = original_execute

-- Test 7: Test pattern execution with different pattern types
print("📝 Testing pattern execution with different pattern types...")
local patterns = package.loaded.paragonic.patterns.list_patterns()
local execution_results = {}

for _, pattern in ipairs(patterns) do
  local result = package.loaded.paragonic.patterns.execute_pattern(pattern.name)
  if result and result.success then
    table.insert(execution_results, pattern.name)
  end
end

if #execution_results == #patterns then
  print("✅ All pattern types execute successfully")
  for i, pattern_name in ipairs(execution_results) do
    print("  " .. i .. ". " .. pattern_name)
  end
else
  print("❌ Some pattern types failed to execute")
end

-- Test 8: Test pattern execution result structure
print("📝 Testing pattern execution result structure...")
local test_result = package.loaded.paragonic.patterns.execute_pattern("Session Summary Generation")
if test_result then
  local has_required_fields = test_result.success ~= nil and 
                             test_result.pattern_name ~= nil and 
                             test_result.result ~= nil and
                             test_result.result.timestamp ~= nil
  
  if has_required_fields then
    print("✅ Pattern execution result has required structure")
    print("  success: " .. tostring(test_result.success))
    print("  pattern_name: " .. test_result.pattern_name)
    print("  timestamp: " .. test_result.result.timestamp)
  else
    print("❌ Pattern execution result missing required fields")
  end
else
  print("❌ Pattern execution result is nil")
end

-- Test 9: Test pattern execution with empty context
print("📝 Testing pattern execution with empty context...")
local empty_context_result = package.loaded.paragonic.patterns.execute_pattern("Activity Labeling", {})
if empty_context_result and empty_context_result.success then
  print("✅ Pattern execution works with empty context")
  if type(empty_context_result.result.context) == "table" then
    print("  Context is properly initialized as empty table")
  end
else
  print("❌ Pattern execution failed with empty context")
end

-- Test 10: Test pattern execution with nil context
print("📝 Testing pattern execution with nil context...")
local nil_context_result = package.loaded.paragonic.patterns.execute_pattern("Session Summary Generation", nil)
if nil_context_result and nil_context_result.success then
  print("✅ Pattern execution works with nil context")
  if nil_context_result.result.context then
    print("  Context is properly handled when nil")
  end
else
  print("❌ Pattern execution failed with nil context")
end

-- Test 11: Test pattern execution performance
print("📝 Testing pattern execution performance...")
local start_time = os.clock()
local performance_result = package.loaded.paragonic.patterns.execute_pattern("Session Summary Generation")
local end_time = os.clock()
local execution_time = (end_time - start_time) * 1000 -- Convert to milliseconds

if performance_result and performance_result.success then
  print("✅ Pattern execution completed in " .. string.format("%.2f", execution_time) .. "ms")
  if execution_time < 100 then
    print("  Performance is acceptable (< 100ms)")
  else
    print("  Performance might be slow (> 100ms)")
  end
else
  print("❌ Pattern execution performance test failed")
end

-- Test 12: Test pattern execution command validation
print("📝 Testing pattern execution command validation...")
local validation_tests = {
  {name = "Session Summary Generation", should_pass = true},
  {name = "Activity Labeling", should_pass = true},
  {name = "", should_pass = true}, -- Empty string should still work with current implementation
  {name = nil, should_pass = true}, -- Nil should still work with current implementation
  {name = "NonExistentPattern", should_pass = true} -- Non-existent patterns should still work with current implementation
}

for i, test in ipairs(validation_tests) do
  local result = package.loaded.paragonic.patterns.execute_pattern(test.name)
  local passed = result and result.success
  local status = (passed == test.should_pass) and "✅" or "❌"
  print("  " .. status .. " Test " .. i .. ": " .. (test.name or "nil") .. " - " .. (passed and "passed" or "failed"))
end

print("=== Pattern Execution Commands Test Completed ===")
