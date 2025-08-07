-- Test regex pattern
local addr = "127.0.0.1:3000"
print("Testing pattern on:", addr)

-- Test different patterns
local host1 = addr:match("([^:]+)")
print("Host1:", host1)

local host2, port2 = addr:match("([^:]+):?([0-9]*)")
print("Host2:", host2, "Port2:", port2)

local host3, port3 = addr:match("([^:]+):?(%d*)")
print("Host3:", host3, "Port3:", port3) 