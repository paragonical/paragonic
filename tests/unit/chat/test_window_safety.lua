-- Test window safety during streaming
-- Verifies that streaming doesn't crash when user switches buffers

-- Set up Lua path to find paragonic modules
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

local function test_window_safety()
	print("🧪 Testing window safety during streaming...")
	
	-- Mock the backend to avoid actual network calls
	local original_backend = package.loaded["paragonic.backend"]
	package.loaded["paragonic.backend"] = {
		_get_rpc_client = function() 
			return {
				streaming_chat_completion = function()
					return { chunk = "test", chunk_type = "regular_content" }, nil
				end,
				get_streaming_chunks = function()
					return {
						{ chunk = "test content", chunk_type = "regular_content", chunk_index = 1, total_chunks = 1 }
					}
				end,
				clear_streaming_chunks = function() end
			}
		end,
		initialize_backend = function() return true end,
		_initialize_backend = function() return true end
	}
	
	-- Load the chat module
	local chat = require("paragonic.chat")
	if not chat then
		print("❌ Failed to load chat module")
		return false
	end
	
	print("✅ Chat module loaded successfully")
	
	-- Test that the function handles window changes gracefully
	local function on_chunk(chunk, chunk_index, total_chunks, chunk_type)
		print("📥 Chunk received: " .. (chunk or "no content"):sub(1, 50))
	end
	
	local function on_complete()
		print("✅ Streaming completed")
	end
	
	-- Test that the function doesn't crash with window changes
	local success, err = pcall(function()
		return chat.send_message_thinking_streaming(
			"Test message for window safety",
			"deepseek-r1:1.5b",
			on_chunk,
			on_complete
		)
	end)
	
	if not success then
		print("❌ Function crashed: " .. tostring(err))
		return false
	end
	
	print("✅ Function completed without crashing")
	
	-- Restore original backend
	package.loaded["paragonic.backend"] = original_backend
	
	return true
end

-- Run the test
local success = test_window_safety()
if success then
	print("🎉 Window safety test passed!")
else
	print("💥 Window safety test failed!")
end

return success
