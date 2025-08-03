#!/usr/bin/env lua

-- Test script for RPC search functionality
-- This script demonstrates how to use the search RPC methods from Lua

local json = require("cjson")

-- Configuration
local RPC_HOST = "127.0.0.1"
local RPC_PORT = 8080
local RPC_ADDR = RPC_HOST .. ":" .. RPC_PORT

-- Helper function to make RPC calls
local function make_rpc_call(method, params)
    local socket = require("socket")
    local tcp = socket.tcp()
    
    -- Connect to RPC server
    local success, err = tcp:connect(RPC_HOST, RPC_PORT)
    if not success then
        print("Failed to connect to RPC server: " .. (err or "unknown error"))
        return nil
    end
    
    -- Prepare JSON-RPC request
    local request = {
        jsonrpc = "2.0",
        method = method,
        params = params,
        id = 1
    }
    
    local request_json = json.encode(request) .. "\n"
    
    -- Send request
    local success, err = tcp:send(request_json)
    if not success then
        print("Failed to send request: " .. (err or "unknown error"))
        tcp:close()
        return nil
    end
    
    -- Receive response
    local response, err = tcp:receive("*l")
    if not response then
        print("Failed to receive response: " .. (err or "unknown error"))
        tcp:close()
        return nil
    end
    
    tcp:close()
    
    -- Parse response
    local success, result = pcall(json.decode, response)
    if not success then
        print("Failed to parse response: " .. (result or "unknown error"))
        return nil
    end
    
    return result
end

-- Test functions
local function test_search_embeddings()
    print("\n=== Testing search_embeddings ===")
    
    local params = {
        query = "machine learning project",
        limit = 5
    }
    
    local result = make_rpc_call("search_embeddings", params)
    if result then
        if result.error then
            print("Error: " .. json.encode(result.error))
        else
            print("Success: Found " .. #result.result.results .. " results")
            for i, search_result in ipairs(result.result.results) do
                print(string.format("  %d. %s (%.3f)", i, search_result.embedding.content_text, search_result.similarity_score))
            end
        end
    end
end

local function test_find_similar_content()
    print("\n=== Testing find_similar_content ===")
    
    local params = {
        query = "AI neural network",
        content_type = "project",
        limit = 3,
        threshold = 0.3
    }
    
    local result = make_rpc_call("find_similar_content", params)
    if result then
        if result.error then
            print("Error: " .. json.encode(result.error))
        else
            print("Success: Found " .. #result.result.results .. " results")
            for i, search_result in ipairs(result.result.results) do
                print(string.format("  %d. %s (%.3f)", i, search_result.embedding.content_text, search_result.similarity_score))
            end
        end
    end
end

local function test_hybrid_search()
    print("\n=== Testing hybrid_search ===")
    
    local params = {
        query = "artificial intelligence development",
        content_type = "project",
        limit = 3,
        threshold = 0.3,
        include_text_filtering = true
    }
    
    local result = make_rpc_call("hybrid_search", params)
    if result then
        if result.error then
            print("Error: " .. json.encode(result.error))
        else
            print("Success: Found " .. #result.result.results .. " results")
            for i, search_result in ipairs(result.result.results) do
                print(string.format("  %d. %s (%.3f)", i, search_result.embedding.content_text, search_result.similarity_score))
            end
        end
    end
end

-- Main test execution
print("Paragonic RPC Search Test")
print("=========================")
print("Testing search functionality via RPC...")
print("Make sure the Rust backend is running on " .. RPC_ADDR)

-- Run tests
test_search_embeddings()
test_find_similar_content()
test_hybrid_search()

print("\n=== Test Complete ===")
print("Note: These tests will work with mock data if the database is not available.")
print("For real search results, ensure the database is initialized and contains embeddings.") 