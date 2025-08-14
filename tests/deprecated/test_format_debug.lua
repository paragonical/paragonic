-- Debug string.format issue
local cwd = "/Users/sjanes/work2/paragonic"
local request_file = "/tmp/test_request.json"
local response_file = "/tmp/test_response.json"
local server_address = "127.0.0.1:3000"

print("Testing string.format with parameters:")
print("cwd:", cwd)
print("request_file:", request_file)
print("response_file:", response_file)
print("server_address:", server_address)

-- Test the format string step by step
local format_str = [[
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
]]

print("Format string has", select(2, format_str:gsub("%%s", "%%s")) .. " %s placeholders")

local result = string.format(format_str, cwd, cwd, request_file, response_file, server_address)
print("String format successful, result length:", #result)
