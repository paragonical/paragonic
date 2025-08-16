-- Test script for brain wrapping function
print("🧪 Testing wrap_text_with_brain function")

-- Load the utils module
local utils = require("paragonic.utils")

-- Test data
local test_text = "Alright, the user greeted me with 'hello world' and mentioned 'in Pascal.' I need to respond appropriately to their greeting and address their mention of Pascal programming language."

print("Test text: " .. test_text)
print("Text length: " .. #test_text)

-- Test the function
local wrapped_lines = utils.wrap_text_with_brain(test_text, 60)

print("Wrapped lines count: " .. #wrapped_lines)
print("Wrapped lines:")
for i, line in ipairs(wrapped_lines) do
    print("  " .. i .. ": '" .. line .. "'")
end

-- Test with shorter text
local short_text = "This is a short test."
print("\nShort text: " .. short_text)
local short_wrapped = utils.wrap_text_with_brain(short_text, 60)
print("Short wrapped lines count: " .. #short_wrapped)
for i, line in ipairs(short_wrapped) do
    print("  " .. i .. ": '" .. line .. "'")
end

print("✅ Test completed!")
