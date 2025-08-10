-- Test Lua string.format escaping
local test = "test"
local result = string.format([[
local host, port = "%s":match("([^:]+):?(%%d*)")
]], test)

print("Result:")
print(result) 