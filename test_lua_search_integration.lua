#!/usr/bin/env lua

-- Test script for Lua RPC client search functionality
-- This script demonstrates how to use the search methods from the Lua RPC client

-- Load the RPC client module
local rpc_client = require("lua.paragonic.rpc_standalone")

-- Configuration
local SERVER_ADDRESS = "127.0.0.1:3000"

-- Helper function to print formatted output
local function print_section(title)
    print("\n" .. string.rep("=", 60))
    print(" " .. title)
    print(string.rep("=", 60))
end

local function print_subsection(title)
    print("\n" .. string.rep("-", 40))
    print(" " .. title)
    print(string.rep("-", 40))
end

-- Test function for basic search
local function test_basic_search(client)
    print_subsection("Testing Basic Search")
    
    print("Searching for 'machine learning project'...")
    local result, error = client:search_embeddings("machine learning project", 5)
    
    if result then
        print("✓ Search successful!")
        print("Found " .. #result.results .. " results")
        
        -- Format and display results
        local formatted = client:format_search_results(result, 80)
        print("\nFormatted results:")
        print(formatted)
        
        -- Show statistics
        local stats = client:get_search_stats(result)
        print("\nSearch statistics:")
        print("  Query: " .. stats.query)
        print("  Total results: " .. stats.total_results)
        print("  Average score: " .. string.format("%.3f", stats.avg_score))
        print("  Content types: " .. (next(stats.content_types) and "various" or "none"))
    else
        print("✗ Search failed: " .. (error or "unknown error"))
    end
end

-- Test function for filtered search
local function test_filtered_search(client)
    print_subsection("Testing Filtered Search")
    
    print("Searching for 'AI neural network' in projects only...")
    local result, error = client:find_similar_content("AI neural network", "project", 3, 0.3)
    
    if result then
        print("✓ Filtered search successful!")
        print("Found " .. #result.results .. " results")
        
        -- Format and display results
        local formatted = client:format_search_results(result, 80)
        print("\nFormatted results:")
        print(formatted)
        
        -- Verify filtering
        local all_projects = true
        for _, search_result in ipairs(result.results) do
            if search_result.embedding.content_type ~= "project" then
                all_projects = false
                break
            end
        end
        
        if all_projects then
            print("✓ All results are projects (filtering working)")
        else
            print("✗ Some results are not projects (filtering issue)")
        end
    else
        print("✗ Filtered search failed: " .. (error or "unknown error"))
    end
end

-- Test function for hybrid search
local function test_hybrid_search(client)
    print_subsection("Testing Hybrid Search")
    
    print("Performing hybrid search for 'artificial intelligence development'...")
    local result, error = client:hybrid_search("artificial intelligence development", "project", 3, 0.3, true)
    
    if result then
        print("✓ Hybrid search successful!")
        print("Found " .. #result.results .. " results")
        
        -- Format and display results
        local formatted = client:format_search_results(result, 80)
        print("\nFormatted results:")
        print(formatted)
        
        -- Show detailed statistics
        local stats = client:get_search_stats(result)
        print("\nDetailed statistics:")
        print("  Query: " .. stats.query)
        print("  Total results: " .. stats.total_results)
        print("  Average score: " .. string.format("%.3f", stats.avg_score))
        
        if next(stats.content_types) then
            print("  Content type distribution:")
            for content_type, count in pairs(stats.content_types) do
                print("    " .. content_type .. ": " .. count)
            end
        end
    else
        print("✗ Hybrid search failed: " .. (error or "unknown error"))
    end
end

-- Test function for search with different parameters
local function test_search_parameters(client)
    print_subsection("Testing Search Parameters")
    
    -- Test with different limits
    print("Testing with limit=2...")
    local result1, error1 = client:search_embeddings("test", 2)
    if result1 then
        print("✓ Limited search successful: " .. #result1.results .. " results")
    else
        print("✗ Limited search failed: " .. (error1 or "unknown error"))
    end
    
    -- Test with high threshold
    print("\nTesting with high threshold (0.8)...")
    local result2, error2 = client:find_similar_content("test", nil, 5, 0.8)
    if result2 then
        print("✓ High threshold search successful: " .. #result2.results .. " results")
        if #result2.results > 0 then
            print("  All results should have high similarity scores")
            for i, search_result in ipairs(result2.results) do
                print("    Result " .. i .. ": " .. string.format("%.3f", search_result.similarity_score))
            end
        end
    else
        print("✗ High threshold search failed: " .. (error2 or "unknown error"))
    end
    
    -- Test without text filtering
    print("\nTesting hybrid search without text filtering...")
    local result3, error3 = client:hybrid_search("test", nil, 3, 0.0, false)
    if result3 then
        print("✓ Hybrid search without text filtering successful: " .. #result3.results .. " results")
    else
        print("✗ Hybrid search without text filtering failed: " .. (error3 or "unknown error"))
    end
end

-- Test function for error handling
local function test_error_handling(client)
    print_subsection("Testing Error Handling")
    
    -- Test with empty query
    print("Testing with empty query...")
    local result1, error1 = client:search_embeddings("", 5)
    if not result1 and error1 then
        print("✓ Empty query properly rejected: " .. error1)
    else
        print("✗ Empty query should have been rejected")
    end
    
    -- Test with invalid limit
    print("\nTesting with invalid limit...")
    local result2, error2 = client:search_embeddings("test", -1)
    if not result2 and error2 then
        print("✓ Invalid limit properly rejected: " .. error2)
    else
        print("✗ Invalid limit should have been rejected")
    end
    
    -- Test with invalid threshold
    print("\nTesting with invalid threshold...")
    local result3, error3 = client:find_similar_content("test", nil, 5, 1.5)
    if not result3 and error3 then
        print("✓ Invalid threshold properly rejected: " .. error3)
    else
        print("✗ Invalid threshold should have been rejected")
    end
end

-- Main test execution
print_section("Paragonic Lua RPC Client Search Test")
print("Testing search functionality integration...")
print("Make sure the Rust backend is running on " .. SERVER_ADDRESS)

-- Create RPC client
local client = rpc_client.new(SERVER_ADDRESS)

-- Configure client
client:logging(true, "info")
client:timeout_operations(15)
client:retry_operations(2, 1)

print("\nClient configuration:")
print("  Server: " .. client.server_address)
print("  Timeout: " .. client.timeout .. " seconds")
print("  Max retries: " .. client.max_retries)
print("  Logging: " .. (client.logging_enabled and "enabled" or "disabled"))

-- Test connectivity
print_subsection("Testing Connectivity")
local success, error_msg = client:connect()
if success then
    print("✓ Connected to server successfully")
else
    print("✗ Failed to connect: " .. (error_msg or "unknown error"))
    print("Note: Tests will still run but may fail if server is not available")
end

-- Run tests
test_basic_search(client)
test_filtered_search(client)
test_hybrid_search(client)
test_search_parameters(client)
test_error_handling(client)

-- Test server info
print_subsection("Server Information")
local server_info = client:get_server_info()
if server_info then
    print("Server: " .. server_info.name .. " v" .. server_info.version)
    print("Address: " .. server_info.address)
    print("Protocol: " .. server_info.protocol)
    print("Status: " .. server_info.status)
else
    print("Failed to get server information")
end

print_section("Test Complete")
print("Note: These tests will work with mock data if the database is not available.")
print("For real search results, ensure the database is initialized and contains embeddings.")
print("Check the logs above for detailed information about each test.") 