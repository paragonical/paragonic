--[[
Test script for RPC MCP logging integration (Neovim version)
This tests that the MCP logging functionality is properly integrated into the RPC module
Run this inside Neovim with: :source test_rpc_mcp_logging_nvim.lua
--]]

-- Set package path for Neovim
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

local function test_rpc_mcp_logging_nvim()
    print("=== Testing RPC MCP Logging Integration (Neovim) ===")
    print("Test function started")

    -- Test that we can load the RPC module
    local success, rpc = pcall(require, "paragonic.rpc_standalone")
    if not success then
        print("Failed to load RPC module: " .. tostring(rpc))
        return
    end
    
    print("  ✓ RPC module loaded successfully")
    
    -- Test that MCP logging functions are available
    if rpc.logging_config == nil then
        print("  ✗ Missing logging_config")
        return
    end
    if rpc.initialize_logging == nil then
        print("  ✗ Missing initialize_logging function")
        return
    end
    if rpc.log == nil then
        print("  ✗ Missing log function")
        return
    end
    if rpc.log_mcp_request == nil then
        print("  ✗ Missing log_mcp_request function")
        return
    end
    if rpc.log_mcp_response == nil then
        print("  ✗ Missing log_mcp_response function")
        return
    end
    if rpc.log_mcp_operation == nil then
        print("  ✗ Missing log_mcp_operation function")
        return
    end
    print("  ✓ MCP logging functions are available")

    -- Test logging configuration
    if rpc.logging_config.enabled ~= true then
        print("  ✗ Logging should be enabled by default")
        return
    end
    if rpc.logging_config.level ~= "info" then
        print("  ✗ Should have info level by default")
        return
    end
    print("  ✓ Logging configuration is correct")

    -- Test log level checking
    if rpc.should_log("info") ~= true then
        print("  ✗ Should log info level")
        return
    end
    if rpc.should_log("warn") ~= true then
        print("  ✗ Should log warn level")
        return
    end
    if rpc.should_log("error") ~= true then
        print("  ✗ Should log error level")
        return
    end
    print("  ✓ Log level checking works")

    -- Test log message formatting
    local formatted = rpc.format_log_message("info", "Test message", {key = "value"})
    if not formatted:find("Test message") then
        print("  ✗ Should include message in formatted log")
        return
    end
    if not formatted:find("INFO") then
        print("  ✗ Should include level in formatted log")
        return
    end
    print("  ✓ Log message formatting works")

    -- Test convenience logging functions
    rpc.log_debug("Debug message", {debug_key = "debug_value"})
    rpc.log_info("Info message", {info_key = "info_value"})
    rpc.log_warn("Warning message", {warn_key = "warn_value"})
    rpc.log_error("Error message", {error_key = "error_value"})
    print("  ✓ Convenience logging functions work")

    -- Test MCP-specific logging
    rpc.log_mcp_request("tools/call", {name = "agent_edit_file"}, {session_id = "123"})
    rpc.log_mcp_response("tools/call", {success = true}, nil, {session_id = "123"})
    rpc.log_mcp_operation("file_edit", "op-1", "started", {file_path = "/tmp/test.txt"})
    print("  ✓ MCP-specific logging works")

    -- Test RPC client creation
    local client = rpc.new("localhost:3000")
    if client == nil then
        print("  ✗ Should create RPC client")
        return
    end
    if client.server_address ~= "localhost:3000" then
        print("  ✗ Should set server address")
        return
    end
    print("  ✓ RPC client creation works")

    -- Test client logging integration
    client:logging(true, "debug")
    if client.logging_enabled ~= true then
        print("  ✗ Should enable client logging")
        return
    end
    if client.log_level ~= "debug" then
        print("  ✗ Should set client log level")
        return
    end
    print("  ✓ Client logging configuration works")

    print("✓ All RPC MCP logging integration tests passed!")
end

-- Run the test
test_rpc_mcp_logging_nvim() 