-- Test the exact line from the generated script
local addr = '127.0.0.1:3000'
local host, port = addr:match('([^:]+):?([0-9]*)')
print("Host:", host)
print("Port:", port) 