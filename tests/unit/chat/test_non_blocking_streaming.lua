-- Test non-blocking streaming implementation
-- Verifies that streaming doesn't block the Neovim UI

-- Set up Lua path to find paragonic modules
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

local function test_non_blocking_streaming()
	print("🧪 Testing non-blocking streaming implementation...")
	
	-- Mock the backend to avoid blocking initialization
	local original_backend = package.loaded["paragonic.backend"]
	package.loaded["paragonic.backend"] = {
		_get_rpc_client = function() return nil end,
		initialize_backend = function() return false end,
		_initialize_backend = function() return false end
	}
	
	-- Load the chat module
	local chat = require("paragonic.chat")
	if not chat then
		print("❌ Failed to load chat module")
		return false
	end
	
	print("✅ Chat module loaded successfully")
	
	-- Test that send_message_thinking_streaming exists
	if not chat.send_message_thinking_streaming then
		print("❌ send_message_thinking_streaming function not found")
		return false
	end
	
	print("✅ send_message_thinking_streaming function exists")
	
	-- Test that send_message_streaming exists
	if not chat.send_message_streaming then
		print("❌ send_message_streaming function not found")
		return false
	end
	
	print("✅ send_message_streaming function exists")
	
	-- Test that the functions return immediately (non-blocking)
	local start_time = vim.uv.now()
	
	local function on_chunk(chunk, chunk_index, total_chunks, chunk_type)
		-- This should be called asynchronously
		print("📥 Chunk received: " .. (chunk or "no content"):sub(1, 50))
	end
	
	local function on_complete()
		print("✅ Streaming completed")
	end
	
	-- Test thinking streaming (should return immediately, even if backend fails)
	local success, err = chat.send_message_thinking_streaming(
		"Test message for non-blocking streaming",
		"deepseek-r1:1.5b",
		on_chunk,
		on_complete
	)
	
	local end_time = vim.uv.now()
	local duration_ms = end_time - start_time
	
	print("⏱️  Function call duration: " .. duration_ms .. "ms")
	
	-- The function should return quickly (not block)
	if duration_ms > 1000 then
		print("❌ Function call took too long (" .. duration_ms .. "ms) - may be blocking")
		return false
	end
	
	print("✅ Function call returned quickly (non-blocking)")
	
	if not success then
		print("⚠️  Streaming failed (expected with mocked backend): " .. tostring(err))
		-- This is expected with the mocked backend
		return true
	end
	
	print("✅ Non-blocking streaming test passed")
	
	-- Restore original backend
	package.loaded["paragonic.backend"] = original_backend
	
	return true
end

-- Run the test
local success = test_non_blocking_streaming()
if success then
	print("🎉 All non-blocking streaming tests passed!")
else
	print("💥 Some non-blocking streaming tests failed!")
end

return success
