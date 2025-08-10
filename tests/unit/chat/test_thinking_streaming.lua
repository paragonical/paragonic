-- Test file for thinking streaming functionality
local M = {}

-- Test thinking streaming with mock data
function M.test_thinking_streaming()
    local chat = require("paragonic.chat")
    
    -- Mock thinking content that simulates what a thinking model would output
    local mock_thinking_content = [[
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

    -- Test the thinking content processing
    local thinking_state = {
        in_thinking = false,
        thinking_step_count = 0,
        current_content = "",
        final_content = ""
    }
    
    local processed_chunks = {}
    
    -- Simulate the chunk processing function
    local function on_chunk(chunk, chunk_index, total_chunks, chunk_type)
        table.insert(processed_chunks, {
            chunk = chunk,
            chunk_type = chunk_type,
            chunk_index = chunk_index
        })
    end
    
    -- Process the mock content in chunks
    local chunk_size = 50
    for i = 1, #mock_thinking_content, chunk_size do
        local chunk = mock_thinking_content:sub(i, i + chunk_size - 1)
        -- This would normally be called by the streaming function
        -- For now, we'll just simulate the processing
        if chunk:match("<think>") then
            on_chunk("󰧑   <think>\n", 0, 1, "thinking_start")
        elseif chunk:match("</think>") then
            on_chunk("</think>\n", 0, 1, "thinking_end")
        elseif chunk:match("^%s*>%s*") then
            on_chunk("〻   " .. chunk .. "\n", 0, 1, "thinking_step")
        else
            on_chunk(chunk, 0, 1, "regular_content")
        end
    end
    
    -- Verify the processing worked correctly
    local success = true
    local errors = {}
    
    -- Check that we have thinking start and end
    local has_thinking_start = false
    local has_thinking_end = false
    local thinking_steps = 0
    
    for _, chunk_data in ipairs(processed_chunks) do
        if chunk_data.chunk_type == "thinking_start" then
            has_thinking_start = true
        elseif chunk_data.chunk_type == "thinking_end" then
            has_thinking_end = true
        elseif chunk_data.chunk_type == "thinking_step" then
            thinking_steps = thinking_steps + 1
        end
    end
    
    if not has_thinking_start then
        table.insert(errors, "Missing thinking start")
        success = false
    end
    
    if not has_thinking_end then
        table.insert(errors, "Missing thinking end")
        success = false
    end
    
    if thinking_steps == 0 then
        table.insert(errors, "No thinking steps detected")
        success = false
    end
    
    -- Print results
    print("=== Thinking Streaming Test Results ===")
    print("Success:", success)
    if #errors > 0 then
        print("Errors:")
        for _, error in ipairs(errors) do
            print("  - " .. error)
        end
    end
    print("Thinking steps detected:", thinking_steps)
    print("Total chunks processed:", #processed_chunks)
    
    return success
end

-- Test the thinking streaming command (mock version)
function M.test_thinking_command()
    print("=== Testing Thinking Command ===")
    
    -- This would normally test the actual command
    -- For now, we'll just verify the function exists
    local chat = require("paragonic.chat")
    
    if chat.send_message_command_thinking then
        print("✅ send_message_command_thinking function exists")
        return true
    else
        print("❌ send_message_command_thinking function not found")
        return false
    end
end

-- Run all tests
function M.run_all_tests()
    print("Running thinking streaming tests...")
    
    local test1_success = M.test_thinking_streaming()
    local test2_success = M.test_thinking_command()
    
    local all_success = test1_success and test2_success
    
    print("=== Overall Test Results ===")
    print("All tests passed:", all_success)
    
    return all_success
end

return M
