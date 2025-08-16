-- Test thinking content wrapping
-- Verifies that thinking_content chunks are properly wrapped with zigzag prefix

-- Set up Lua path to find paragonic modules
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

local function test_thinking_content_wrapping()
	print("🧪 Testing thinking content wrapping...")
	
	-- Load the utils module to test wrapping directly
	local utils = require("paragonic.utils")
	if not utils then
		print("❌ Failed to load utils module")
		return false
	end
	
	print("✅ Utils module loaded successfully")
	
	-- Test the wrap_text_with_zigzag function directly
	local test_text = "This is a long thinking step that should be wrapped to multiple lines when it exceeds the maximum width limit. It contains multiple sentences and should demonstrate proper text wrapping functionality."
	local max_width = 50
	
	print("📝 Testing wrap_text_with_zigzag with width " .. max_width)
	local wrapped_lines = utils.wrap_text_with_zigzag(test_text, max_width)
	
	if not wrapped_lines or #wrapped_lines == 0 then
		print("❌ No wrapped lines returned")
		return false
	end
	
	print("✅ Wrapped into " .. #wrapped_lines .. " lines:")
	for i, line in ipairs(wrapped_lines) do
		print("  Line " .. i .. ": " .. line)
		-- Check that first line starts with zigzag symbol, continuation lines are indented
		if i == 1 then
			if not line:match("^〻") then
				print("❌ First line doesn't start with zigzag symbol")
				return false
			end
		else
			if not line:match("^     ") then
				print("❌ Continuation line " .. i .. " isn't properly indented")
				return false
			end
		end
	end
	
	-- Test with shorter text that doesn't need wrapping
	local short_text = "Short thinking step"
	print("📝 Testing with short text: " .. short_text)
	local short_wrapped = utils.wrap_text_with_zigzag(short_text, max_width)
	
	if not short_wrapped or #short_wrapped == 0 then
		print("❌ No wrapped lines returned for short text")
		return false
	end
	
	print("✅ Short text wrapped into " .. #short_wrapped .. " lines:")
	for i, line in ipairs(short_wrapped) do
		print("  Line " .. i .. ": " .. line)
		-- Short text should only have one line with zigzag symbol
		if not line:match("^〻") then
			print("❌ Short text line " .. i .. " doesn't start with zigzag symbol")
			return false
		end
	end
	
	-- Test with word that should fit on first line
	local short_word = "hippopotomonstrosesquippedaliophobia"
	print("📝 Testing with short word: " .. short_word)
	local short_wrapped = utils.wrap_text_with_zigzag(short_word, 50)
	
	if not short_wrapped or #short_wrapped == 0 then
		print("❌ No wrapped lines returned for short word")
		return false
	end
	
	print("✅ Short word wrapped into " .. #short_wrapped .. " lines:")
	for i, line in ipairs(short_wrapped) do
		print("  Line " .. i .. ": " .. line)
		-- Check that first line starts with zigzag symbol, continuation lines are indented
		if i == 1 then
			if not line:match("^〻") then
				print("❌ Short word first line doesn't start with zigzag symbol")
				return false
			end
		else
			if not line:match("^     ") then
				print("❌ Short word continuation line " .. i .. " isn't properly indented")
				return false
			end
		end
	end
	
	print("✅ Thinking content wrapping test passed")
	return true
end

-- Run the test
local success = test_thinking_content_wrapping()
if success then
	print("🎉 All thinking content wrapping tests passed!")
else
	print("💥 Some thinking content wrapping tests failed!")
end

return success
