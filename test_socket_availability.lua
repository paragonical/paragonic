#!/usr/bin/env lua

-- Test script to check socket availability in Neovim
print("=== Socket Library Availability Test ===")

-- Test 1: socket library
print("Testing socket library...")
local socket_ok, socket = pcall(require, "socket")
if socket_ok then
    print("✅ socket library available")
    if socket.tcp then
        print("✅ socket.tcp available")
    else
        print("❌ socket.tcp not available")
    end
else
    print("❌ socket library not available: " .. tostring(socket))
end

-- Test 2: luasocket
print("\nTesting luasocket...")
local luasocket_ok, luasocket = pcall(require, "luasocket")
if luasocket_ok then
    print("✅ luasocket available")
else
    print("❌ luasocket not available: " .. tostring(luasocket))
end

-- Test 3: vim.loop (Neovim's built-in event loop)
print("\nTesting vim.loop...")
if vim and vim.loop then
    print("✅ vim.loop available")
    if vim.loop.new_tcp then
        print("✅ vim.loop.new_tcp available")
    else
        print("❌ vim.loop.new_tcp not available")
    end
else
    print("❌ vim.loop not available")
end

-- Test 4: Check if we can create a TCP connection with vim.loop
print("\nTesting vim.loop TCP connection...")
if vim and vim.loop and vim.loop.new_tcp then
    local tcp = vim.loop.new_tcp()
    if tcp then
        print("✅ vim.loop.new_tcp() works")
        tcp:close()
    else
        print("❌ vim.loop.new_tcp() failed")
    end
else
    print("❌ vim.loop.new_tcp not available")
end

print("\n=== Test Complete ===") 