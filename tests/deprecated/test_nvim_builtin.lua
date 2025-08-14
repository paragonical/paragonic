-- Debug test for Neovim built-in socket functionality
local file = io.open("/tmp/nvim_builtin.log", "w")
if file then
	file:write("Starting Neovim built-in socket test...\n")

	-- Check if vim.fn.sockconnect is available
	if vim.fn.sockconnect then
		file:write("✓ vim.fn.sockconnect is available\n")
	else
		file:write("✗ vim.fn.sockconnect is not available\n")
	end

	-- Check if vim.fn.sockread is available
	if vim.fn.sockread then
		file:write("✓ vim.fn.sockread is available\n")
	else
		file:write("✗ vim.fn.sockread is not available\n")
	end

	-- Check if vim.fn.sockwrite is available
	if vim.fn.sockwrite then
		file:write("✓ vim.fn.sockwrite is available\n")
	else
		file:write("✗ vim.fn.sockwrite is not available\n")
	end

	-- Check if vim.fn.sockclose is available
	if vim.fn.sockclose then
		file:write("✓ vim.fn.sockclose is available\n")
	else
		file:write("✗ vim.fn.sockclose is not available\n")
	end

	-- Try to use built-in socket functionality
	if vim.fn.sockconnect then
		file:write("Testing built-in socket connection...\n")

		-- Try to connect
		local sock = vim.fn.sockconnect("tcp", "127.0.0.1:3000", {})
		if sock > 0 then
			file:write("✓ Socket connected, ID: " .. sock .. "\n")

			-- Try to send a message
			local send_result = vim.fn.sockwrite(sock, '{"jsonrpc":"2.0","method":"hello","params":[],"id":1}\n')
			if send_result > 0 then
				file:write("✓ Message sent successfully\n")

				-- Try to read a response
				local response = vim.fn.sockread(sock, 1000)
				if response and response ~= "" then
					file:write("✓ Response received: " .. response .. "\n")
				else
					file:write("✗ No response received\n")
				end
			else
				file:write("✗ Failed to send message\n")
			end

			-- Close the socket
			vim.fn.sockclose(sock)
			file:write("Socket closed\n")
		else
			file:write("✗ Failed to connect: " .. sock .. "\n")
		end
	end

	file:write("=== Neovim Built-in Socket Test Complete ===\n")
	file:close()
end
