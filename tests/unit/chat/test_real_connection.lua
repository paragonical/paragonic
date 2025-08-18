-- Test real connection to Rust server
local M = {}

function M.test_real_connection()
	print("=== Testing Real Connection to Rust Server ===")

	-- Try to require the real RPC module
	local success, rpc = pcall(require, "paragonic.rpc")
	if not success then
		print("❌ Failed to require paragonic.rpc:", rpc)
		return false
	end

	print("✅ paragonic.rpc module loaded")

	-- Create RPC client
	local client = rpc.new("127.0.0.1:3000")
	if not client then
		print("❌ Failed to create RPC client")
		return false
	end

	print("✅ RPC client created")

	-- Try to connect
	local connect_success, err = client:connect()
	if not connect_success then
		print("❌ Failed to connect:", err)
		return false
	end

	print("✅ Connected to server")

	-- Test hello call
	local response = client:hello()
	if not response then
		print("❌ Hello call failed")
		return false
	end

	print("✅ Hello call successful")
	print("Response:", response)

	-- Test if streaming methods exist
	if client.streaming_chat_completion then
		print("✅ streaming_chat_completion method exists")
	else
		print("❌ streaming_chat_completion method missing")
		return false
	end

	if client.get_next_chunk then
		print("✅ get_next_chunk method exists")
	else
		print("❌ get_next_chunk method missing")
		return false
	end

	-- Test streaming call
	local streaming_response = client:streaming_chat_completion({
		model = "deepseek-r1:1.5b",
		message = "Test message",
		chunk_size = 50,
	})

	if streaming_response then
		print("✅ streaming_chat_completion call successful")
		print("Response length:", #streaming_response)

		-- Try to parse the response
		local success2, parsed = pcall(vim.json.decode, streaming_response)
		if success2 then
			print("✅ Response parsed successfully")
			if parsed.result then
				print("✅ Response has result field")
			else
				print("❌ Response missing result field")
				return false
			end
		else
			print("❌ Failed to parse response:", parsed)
			return false
		end
	else
		print("❌ streaming_chat_completion call failed")
		return false
	end

	print("✅ All real connection tests passed!")
	return true
end

return M
