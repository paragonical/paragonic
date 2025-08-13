-- Test streaming response parsing functionality
local M = {}

-- Test parsing of streaming responses from the server
function M.test_streaming_response_parsing()
    print("=== Testing Streaming Response Parsing ===")
    
    local utils = require("paragonic.utils")
    
    -- Test successful streaming response parsing
    local mock_streaming_response = {
        id = 1,
        jsonrpc = "2.0",
        result = {
            type = "streaming_chunk",
            chunk = "Hello, world!",
            chunk_index = 0,
            total_chunks = 1,
            remaining_chunks = {}
        }
    }
    
    local response_json = vim.json.encode(mock_streaming_response)
    local parsed = utils.parse_json_response_enhanced(response_json)
    
    if not parsed then
        print("❌ Failed to parse streaming response")
        return false
    end
    
    if not parsed.result then
        print("❌ No result field in parsed response")
        return false
    end
    
    if parsed.result.type ~= "streaming_chunk" then
        print("❌ Expected type 'streaming_chunk', got: " .. (parsed.result.type or "nil"))
        return false
    end
    
    if parsed.result.chunk ~= "Hello, world!" then
        print("❌ Expected chunk 'Hello, world!', got: " .. (parsed.result.chunk or "nil"))
        return false
    end
    
    print("✅ Basic streaming response parsing successful")
    
    -- Test thinking content parsing
    local mock_thinking_response = {
        id = 1,
        jsonrpc = "2.0",
        result = {
            type = "streaming_chunk",
            chunk = "<think>\nLet me think about this step by step.\n</think>\n\nHere is the answer: The answer is 42.",
            chunk_index = 0,
            total_chunks = 1,
            remaining_chunks = {}
        }
    }
    
    local thinking_response_json = vim.json.encode(mock_thinking_response)
    local thinking_parsed = utils.parse_json_response_enhanced(thinking_response_json)
    
    if not thinking_parsed or not thinking_parsed.result then
        print("❌ Failed to parse thinking response")
        return false
    end
    
    local thinking_content = thinking_parsed.result.chunk
    
    -- Verify thinking tags are present
    if not thinking_content:match("<think>") then
        print("❌ <think> tag not found in thinking content")
        return false
    end
    
    if not thinking_content:match("</think>") then
        print("❌ </think> tag not found in thinking content")
        return false
    end
    
    -- Verify content structure
    local before_think = thinking_content:match("(.*)<think>")
    local after_think = thinking_content:match("</think>(.*)")
    
    if not after_think or after_think:match("^%s*$") then
        print("❌ No content after </think> tag")
        return false
    end
    
    if not after_think:match("Here is the answer:") then
        print("❌ Expected answer content not found")
        return false
    end
    
    print("✅ Thinking content parsing successful")
    
    return true
end

-- Test error handling in streaming response parsing
function M.test_streaming_response_error_handling()
    print("=== Testing Streaming Response Error Handling ===")
    
    local utils = require("paragonic.utils")
    
    -- Test malformed JSON
    local malformed_json = "{invalid json"
    local parsed = utils.parse_json_response_enhanced(malformed_json)
    
    if parsed then
        print("❌ Should have failed to parse malformed JSON")
        return false
    end
    
    print("✅ Malformed JSON correctly rejected")
    
    -- Test missing result field
    local incomplete_response = {
        id = 1,
        jsonrpc = "2.0"
        -- Missing result field
    }
    
    local incomplete_json = vim.json.encode(incomplete_response)
    local incomplete_parsed = utils.parse_json_response_enhanced(incomplete_json)
    
    if not incomplete_parsed then
        print("❌ Should handle missing result field gracefully")
        return false
    end
    
    if incomplete_parsed.result then
        print("❌ Should not have result field when missing")
        return false
    end
    
    print("✅ Missing result field handled correctly")
    
    -- Test wrong response type
    local wrong_type_response = {
        id = 1,
        jsonrpc = "2.0",
        result = {
            type = "wrong_type",
            chunk = "Hello, world!",
            chunk_index = 0,
            total_chunks = 1,
            remaining_chunks = {}
        }
    }
    
    local wrong_type_json = vim.json.encode(wrong_type_response)
    local wrong_type_parsed = utils.parse_json_response_enhanced(wrong_type_json)
    
    if not wrong_type_parsed or not wrong_type_parsed.result then
        print("❌ Should parse response even with wrong type")
        return false
    end
    
    if wrong_type_parsed.result.type ~= "wrong_type" then
        print("❌ Should preserve the actual type")
        return false
    end
    
    print("✅ Wrong response type handled correctly")
    
    return true
end

-- Test thinking content processing
function M.test_thinking_content_processing()
    print("=== Testing Thinking Content Processing ===")
    
    -- Mock thinking content that simulates what we get from the server
    local thinking_content = [[
<think>
Alright, so I need to figure out how to create a parts list for a Stirling engine. Hmm, okay, let me think about this step by step. First, I remember that a Stirling engine is an internal combustion engine, but it uses a different working fluid and operates differently than a Carnot engine. The main components must be different from those of an internal combustion engine.

> I know a Stirling engine consists of two heat reservoirs-a hot one and a cold one-and the working substance, which in this case is usually a gas like air. It alternates between isothermal expansion at the high temperature and adiabatic expansion at the low temperature. There are also moving parts like pistons or steam chambers.

> I think I should start by listing the components of each part first. Maybe break down the engine into main sections: the heat source, the working fluid, the compression system, the connecting rods, the cooling mechanism, and so on.
</think>

Creating a comprehensive parts list for a Stirling engine:

### 1. Heat Sources
- **High Temperature Reservoir:** Temperature: 400°C (673 K), Pressure: 16 bar, Volume: 250 cm³
- **Low Temperature Reservoir:** Temperature: 120°C (393 K), Pressure: 3 bar, Volume: 140 cm³

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
    
    -- Test content structure
    local before_think = thinking_content:match("(.*)<think>")
    local after_think = thinking_content:match("</think>(.*)")
    
    if not after_think or after_think:match("^%s*$") then
        print("❌ No content after </think> tag")
        return false
    end
    
    if not after_think:match("Creating a comprehensive parts list") then
        print("❌ Expected answer content not found")
        return false
    end
    
    print("✅ Content structure is correct (thinking + regular content)")
    
    return true
end

-- Test streaming chunk processing
function M.test_streaming_chunk_processing()
    print("=== Testing Streaming Chunk Processing ===")
    
    -- Simulate processing multiple chunks
    local chunks = {
        {chunk = "Hello", chunk_type = "regular_content"},
        {chunk = ", ", chunk_type = "regular_content"},
        {chunk = "world", chunk_type = "regular_content"},
        {chunk = "!", chunk_type = "regular_content"}
    }
    
    local accumulated_content = ""
    local chunk_count = 0
    
    for _, chunk_data in ipairs(chunks) do
        accumulated_content = accumulated_content .. chunk_data.chunk
        chunk_count = chunk_count + 1
    end
    
    if accumulated_content ~= "Hello, world!" then
        print("❌ Chunk accumulation failed")
        print("Expected: 'Hello, world!'")
        print("Got: '" .. accumulated_content .. "'")
        return false
    end
    
    if chunk_count ~= 4 then
        print("❌ Wrong number of chunks processed")
        print("Expected: 4")
        print("Got: " .. chunk_count)
        return false
    end
    
    print("✅ Streaming chunk processing successful")
    
    -- Test thinking chunks
    local thinking_chunks = {
        {chunk = "<think>", chunk_type = "thinking_start"},
        {chunk = "\nLet me think about this.", chunk_type = "thinking_step"},
        {chunk = "\n</think>", chunk_type = "thinking_end"},
        {chunk = "\n\nHere is the answer: 42", chunk_type = "regular_content"}
    }
    
    local thinking_content = ""
    local thinking_start_count = 0
    local thinking_end_count = 0
    local thinking_step_count = 0
    
    for _, chunk_data in ipairs(thinking_chunks) do
        thinking_content = thinking_content .. chunk_data.chunk
        
        if chunk_data.chunk_type == "thinking_start" then
            thinking_start_count = thinking_start_count + 1
        elseif chunk_data.chunk_type == "thinking_end" then
            thinking_end_count = thinking_end_count + 1
        elseif chunk_data.chunk_type == "thinking_step" then
            thinking_step_count = thinking_step_count + 1
        end
    end
    
    if not thinking_content:match("<think>") then
        print("❌ <think> tag not found in accumulated thinking content")
        return false
    end
    
    if not thinking_content:match("</think>") then
        print("❌ </think> tag not found in accumulated thinking content")
        return false
    end
    
    if thinking_start_count ~= 1 then
        print("❌ Expected 1 thinking start, got: " .. thinking_start_count)
        return false
    end
    
    if thinking_end_count ~= 1 then
        print("❌ Expected 1 thinking end, got: " .. thinking_end_count)
        return false
    end
    
    if thinking_step_count ~= 1 then
        print("❌ Expected 1 thinking step, got: " .. thinking_step_count)
        return false
    end
    
    print("✅ Thinking chunk processing successful")
    
    return true
end

-- Run all tests
function M.run_all_tests()
    print("Running streaming response parsing tests...")
    
    local test1_success = M.test_streaming_response_parsing()
    local test2_success = M.test_streaming_response_error_handling()
    local test3_success = M.test_thinking_content_processing()
    local test4_success = M.test_streaming_chunk_processing()
    
    local all_success = test1_success and test2_success and test3_success and test4_success
    
    print("=== Overall Test Results ===")
    print("All tests passed:", all_success)
    
    return all_success
end

return M
