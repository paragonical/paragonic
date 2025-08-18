-- Very simple format test
local cwd = "/Users/sjanes/work2/paragonic"
local request_file = "/tmp/test_request.json"
local response_file = "/tmp/test_response.json"
local server_address = "127.0.0.1:3000"

print("Testing simple format...")

-- Test with minimal format string
local result = string.format(
	[[
package.path = package.path .. ";%s/lua/?.lua;%s/lua/?/init.lua"
local request_file = "%s"
local response_file = "%s"
local host, port = "%s":match("([^:]+):?(%%d*)")
]],
	cwd,
	cwd,
	request_file,
	response_file,
	server_address
)

print("Format successful, length:", #result)
