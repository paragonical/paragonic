-- Simple test to fix the string.format issue
local file = io.open("/tmp/bridge_simple_fix.log", "w")
if file then
	file:write("Testing simple bridge fix...\n")

	-- Test the string.format with the exact same parameters
	local cwd = io.popen("pwd"):read("*l")
	local request_file = "/tmp/test_request.json"
	local response_file = "/tmp/test_response.json"
	local server_address = "127.0.0.1:3000"

	file:write("cwd: " .. cwd .. "\n")
	file:write("request_file: " .. request_file .. "\n")
	file:write("response_file: " .. response_file .. "\n")
	file:write("server_address: " .. server_address .. "\n")

	-- Test the format string
	local script_content = string.format(
		[[
-- External RPC script
package.path = package.path .. ";%s/lua/?.lua;%s/lua/?/init.lua"

local socket = require("socket")
local json = require("cjson")

-- Read request
local request_file = "%s"
local response_file = "%s"

local request_content = io.open(request_file, "r"):read("*a")
local request = json.decode(request_content)

-- Parse server address
local host, port = "%s":match("([^:]+):?(%d*)")
port = port or "3000"

-- Connect to server
local tcp = socket.tcp()
tcp:settimeout(5)
local success, err = tcp:connect(host, tonumber(port))

if not success then
    local error_response = json.encode({
        jsonrpc = "2.0",
        error = {code = -1, message = "Connection failed: " .. err},
        id = request.id
    })
    io.open(response_file, "w"):write(error_response):close()
    os.exit(1)
end

-- Send request
local request_json = json.encode(request)
tcp:send(request_json .. "\n")

-- Receive response
local response, err = tcp:receive("*l")
tcp:close()

if not response then
    local error_response = json.encode({
        jsonrpc = "2.0",
        error = {code = -1, message = "Failed to receive response: " .. err},
        id = request.id
    })
    io.open(response_file, "w"):write(error_response):close()
    os.exit(1)
end

-- Write response to file
io.open(response_file, "w"):write(response):close()
]],
		cwd,
		cwd,
		request_file,
		response_file,
		server_address
	)

	file:write("✓ String format successful\n")
	file:write("Script content length: " .. #script_content .. "\n")

	-- Write the script to a file
	local script_file = "/tmp/test_script.lua"
	local f = io.open(script_file, "w")
	if f then
		f:write(script_content)
		f:close()
		file:write("✓ Script file written\n")

		-- Test the script execution
		local result = os.execute("lua " .. script_file)
		file:write("Script execution result: " .. tostring(result) .. "\n")

		-- Clean up
		os.remove(script_file)
	else
		file:write("✗ Failed to write script file\n")
	end

	file:write("=== Simple Bridge Fix Test Complete ===\n")
	file:close()
end
