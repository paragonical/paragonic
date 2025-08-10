-- Test thinking streaming integration
local M = {}

function M.test_thinking_streaming_integration()
    print("=== Testing Thinking Streaming Integration ===")
    
    local chat = require("paragonic.chat")
    local config = require("paragonic.config")
    
    -- Test that the thinking streaming function exists
    if not chat.send_message_thinking_streaming then
        print("❌ send_message_thinking_streaming function not found")
        return false
    end
    
    print("✅ send_message_thinking_streaming function exists")
    
    -- Test that the smart send function exists
    if not chat.send_message_smart then
        print("❌ send_message_smart function not found")
        return false
    end
    
    print("✅ send_message_smart function exists")
    
    -- Test model capability detection
    local test_model = "deepseek-r1:1.5b"
    local supports_thinking = config.model_supports_thinking(test_model)
    
    if not supports_thinking then
        print("❌ deepseek-r1:1.5b should support thinking")
        return false
    end
    
    print("✅ deepseek-r1:1.5b correctly identified as thinking model")
    
    -- Test that the command functions exist
    if not chat.send_message_command_thinking then
        print("❌ send_message_command_thinking function not found")
        return false
    end
    
    print("✅ send_message_command_thinking function exists")
    
    if not chat.send_message_command_smart then
        print("❌ send_message_command_smart function not found")
        return false
    end
    
    print("✅ send_message_command_smart function exists")
    
    -- Test that the commands are registered
    local commands = vim.api.nvim_get_commands({})
    local has_thinking_command = false
    local has_smart_command = false
    
    for name, _ in pairs(commands) do
        if name == "ParagonicSendThinking" then
            has_thinking_command = true
        elseif name == "ParagonicSendSmart" then
            has_smart_command = true
        end
    end
    
    if not has_thinking_command then
        print("❌ ParagonicSendThinking command not registered")
        return false
    end
    
    if not has_smart_command then
        print("❌ ParagonicSendSmart command not registered")
        return false
    end
    
    print("✅ Both commands are registered")
    
    print("✅ All integration tests passed!")
    return true
end

-- Test the thinking content processing logic
function M.test_thinking_content_processing()
    print("=== Testing Thinking Content Processing ===")
    
    -- Mock thinking content
    local thinking_content = [[
<think>
Alright, so I need to figure out how to create a parts list for a Stirling engine. Hmm, okay, let me think about this step by step. First, I remember that a Stirling engine is an internal combustion engine, but it uses a different working fluid and operates differently than a Carnot engine. The main components must be different from those of an internal combustion engine.

> I know a Stirling engine consists of two heat reservoirs-a hot one and a cold one-and the working substance, which in this case is usually a gas like air. It alternates between isothermal expansion at the high temperature and adiabatic expansion at the low temperature. There are also moving parts like pistons or steam chambers.

> I think I should start by listing the components of each part first. Maybe break down the engine into main sections: the heat source, the working fluid, the compression system, the connecting rods, the cooling mechanism, and so on.

> For the heat sources, there must be two reservoirs-hot and cold. Each would have a temperature and perhaps a pressure or volume. The hot one should be at a higher temperature than the cold one. So I'll need temperatures for both. Maybe 400°C for the hot and 120°C for the cold, just as an example.

> The working fluid is usually air, so I can list that under 'working fluid' or maybe include it under 'comppressed gas.' The pressure and volume at these reservoirs might be important too. For instance, the high-pressure reservoir could have a pressure of 16 bar and a volume of 250 cm³, while the low-pressure reservoir would have 3 bar and 140 cm³. This helps in calculating work done during expansion.
</think>

Creating a comprehensive parts list for a Stirling engine:

### 1. Heat Sources
- **High Temperature Reservoir:**
  - Temperature: 400°C (673 K)
  - Pressure: 16 bar
  - Volume: 250 cm³

- **Low Temperature Reservoir:**
  - Temperature: 120°C (393 K)
  - Pressure: 3 bar
  - Volume: 140 cm³

### 2. Working Fluid
- **Type:** Air
- **Mass:** 5 kg
- **Operating pressure range:** 3-16 bar

### 3. Mechanical Components
- **High-pressure piston:** 150 g
- **Low-pressure piston:** 100 g
- **Connecting rods:** High-pressure (40 cm), Low-pressure (28 cm)
- **Cooling system:** Initial temperature 20°C
- **Piston areas:** Large (16 cm²) for high-pressure, small (8 cm²) for low-pressure
]]
    
    -- Test thinking tag detection
    local has_think_start = thinking_content:match("<think>") ~= nil
    local has_think_end = thinking_content:match("</think>") ~= nil
    
    if not has_think_start then
        print("❌ <think> tag not found in content")
        return false
    end
    
    if not has_think_end then
        print("❌ </think> tag not found in content")
        return false
    end
    
    print("✅ <think> and </think> tags detected")
    
    -- Test thinking step detection
    local thinking_steps = {}
    for line in thinking_content:gmatch("[^\r\n]+") do
        if line:match("^%s*>%s*") then
            table.insert(thinking_steps, line)
        end
    end
    
    if #thinking_steps == 0 then
        print("❌ No thinking steps detected")
        return false
    end
    
    print(string.format("✅ %d thinking steps detected", #thinking_steps))
    
    -- Test that we have both thinking and regular content
    local before_think = thinking_content:match("(.*)<think>")
    local after_think = thinking_content:match("</think>(.*)")
    
    if not after_think or after_think:match("^%s*$") then
        print("❌ No content after </think> tag")
        return false
    end
    
    print("✅ Content structure is correct (thinking + regular content)")
    
    print("✅ All content processing tests passed!")
    return true
end

-- Run all tests
function M.run_all_tests()
    print("Running thinking streaming integration tests...")
    
    local test1_success = M.test_thinking_streaming_integration()
    local test2_success = M.test_thinking_content_processing()
    
    local all_success = test1_success and test2_success
    
    print("=== Overall Test Results ===")
    print("All tests passed:", all_success)
    
    return all_success
end

return M
