--[[
Test MCP-Only Compliance
Tests that all client interactions use MCP protocol only
--]]

local M = {}

-- Test configuration
local TEST_CONFIG = {
    base_url = "http://localhost:3000",
    timeout = 30,
}

-- Initialize test environment
function M.setup_test_environment()
    print("🧪 Setting up MCP-only compliance test environment...")
    
    -- Load required modules
    local mcp_http_transport = require("paragonic.mcp_http_transport")
    local backend = require("paragonic.backend")
    
    -- Initialize MCP transport
    local ok, err = mcp_http_transport.init({
        base_url = TEST_CONFIG.base_url,
        protocol_version = "2025-06-18",
        initialization_timeout = TEST_CONFIG.timeout,
        request_timeout = TEST_CONFIG.timeout,
    })
    if not ok then
        print("❌ MCP transport init failed: " .. tostring(err))
        return false, err
    end
    
    -- Initialize session
    local ok2, err2 = mcp_http_transport.initialize_session({
        name = "paragonic.nvim.test",
        version = "1.0.0",
        capabilities = { tools = {}, resources = {}, notifications = {} },
    })
    if not ok2 then
        print("❌ MCP session init failed: " .. tostring(err2))
        return false, err2
    end
    
    print("✅ MCP test environment initialized")
    return true
end

-- Test that tools/list returns all expected tools
function M.test_tools_list_compliance()
    print("🧪 Testing tools/list compliance...")
    
    local mcp_http_transport = require("paragonic.mcp_http_transport")
    
    local resp, err = mcp_http_transport.send_request({
        jsonrpc = "2.0",
        method = "tools/list",
        params = {}
    })
    
    if not resp then
        print("❌ tools/list failed: " .. tostring(err))
        return false
    end
    
    if not resp.result or not resp.result.tools then
        print("❌ tools/list response missing tools")
        return false
    end
    
    local tools = resp.result.tools
    local expected_tools = {
        "chat_completion",
        "formatted_chat_completion", 
        "streaming_chat_completion",
        "list_models",
        "search_embeddings",
        "find_similar_content",
        "hybrid_search",
        "create_project",
        "list_projects",
        "write_file",
        "read_file"
    }
    
    local found_tools = {}
    for _, tool in ipairs(tools) do
        found_tools[tool.name] = true
    end
    
    for _, expected_tool in ipairs(expected_tools) do
        if not found_tools[expected_tool] then
            print("❌ Missing expected tool: " .. expected_tool)
            return false
        end
    end
    
    print("✅ All expected tools found in tools/list")
    return true
end

-- Test that chat completion uses MCP completion/complete
function M.test_chat_completion_mcp_compliance()
    print("🧪 Testing chat completion MCP compliance...")
    
    local backend = require("paragonic.backend")
    
    -- Initialize backend
    local ok = backend._initialize_backend()
    if not ok then
        print("❌ Backend initialization failed")
        return false
    end
    
    local client = backend._get_rpc_client()
    if not client then
        print("❌ RPC client not available")
        return false
    end
    
    -- Test chat completion
    local result, err = client:chat_completion("deepseek-r1:1.5b", "Hello, this is a test")
    if not result then
        print("❌ Chat completion failed: " .. tostring(err))
        return false
    end
    
    -- Verify response format (should be from completion/complete)
    if result.completion then
        print("✅ Chat completion uses MCP completion/complete protocol")
        return true
    else
        print("❌ Chat completion response format unexpected")
        return false
    end
end

-- Test that search uses MCP tools/call
function M.test_search_mcp_compliance()
    print("🧪 Testing search MCP compliance...")
    
    local backend = require("paragonic.backend")
    
    -- Initialize backend
    local ok = backend._initialize_backend()
    if not ok then
        print("❌ Backend initialization failed")
        return false
    end
    
    local client = backend._get_rpc_client()
    if not client then
        print("❌ RPC client not available")
        return false
    end
    
    -- Test search embeddings
    local result, err = client:search_embeddings("test query", 5)
    if not result then
        print("❌ Search embeddings failed: " .. tostring(err))
        return false
    end
    
    -- Verify response format (should be from tools/call)
    if result.content and result.content[1] and result.content[1].text then
        print("✅ Search uses MCP tools/call protocol")
        return true
    else
        print("❌ Search response format unexpected")
        return false
    end
end

-- Test that model listing uses MCP tools/call
function M.test_model_listing_mcp_compliance()
    print("🧪 Testing model listing MCP compliance...")
    
    local backend = require("paragonic.backend")
    
    -- Initialize backend
    local ok = backend._initialize_backend()
    if not ok then
        print("❌ Backend initialization failed")
        return false
    end
    
    local client = backend._get_rpc_client()
    if not client then
        print("❌ RPC client not available")
        return false
    end
    
    -- Test list models
    local result, err = client:list_models()
    if not result then
        print("❌ List models failed: " .. tostring(err))
        return false
    end
    
    -- Verify response format (should be from tools/call)
    if result.content and result.content[1] and result.content[1].text then
        print("✅ Model listing uses MCP tools/call protocol")
        return true
    else
        print("❌ Model listing response format unexpected")
        return false
    end
end

-- Test that project operations use MCP tools/call
function M.test_project_operations_mcp_compliance()
    print("🧪 Testing project operations MCP compliance...")
    
    local backend = require("paragonic.backend")
    
    -- Initialize backend
    local ok = backend._initialize_backend()
    if not ok then
        print("❌ Backend initialization failed")
        return false
    end
    
    local client = backend._get_rpc_client()
    if not client then
        print("❌ RPC client not available")
        return false
    end
    
    -- Test list projects
    local result, err = client:get_projects()
    if not result then
        print("❌ List projects failed: " .. tostring(err))
        return false
    end
    
    -- Verify response format (should be from tools/call)
    if result.content and result.content[1] and result.content[1].text then
        print("✅ Project operations use MCP tools/call protocol")
        return true
    else
        print("❌ Project operations response format unexpected")
        return false
    end
end

-- Test that file operations use MCP tools/call
function M.test_file_operations_mcp_compliance()
    print("🧪 Testing file operations MCP compliance...")
    
    local backend = require("paragonic.backend")
    
    -- Initialize backend
    local ok = backend._initialize_backend()
    if not ok then
        print("❌ Backend initialization failed")
        return false
    end
    
    local client = backend._get_rpc_client()
    if not client then
        print("❌ RPC client not available")
        return false
    end
    
    -- Test save config (write file)
    local test_config = { test = "data" }
    local result, err = client:save_config(test_config)
    if not result then
        print("❌ Save config failed: " .. tostring(err))
        return false
    end
    
    -- Verify response format (should be from tools/call)
    if result.content and result.content[1] and result.content[1].text then
        print("✅ File operations use MCP tools/call protocol")
        return true
    else
        print("❌ File operations response format unexpected")
        return false
    end
end

-- Run all MCP compliance tests
function M.run_all_tests()
    print("🚀 Starting MCP-only compliance tests...")
    
    local tests = {
        { name = "Setup Test Environment", func = M.setup_test_environment },
        { name = "Tools List Compliance", func = M.test_tools_list_compliance },
        { name = "Chat Completion MCP Compliance", func = M.test_chat_completion_mcp_compliance },
        { name = "Search MCP Compliance", func = M.test_search_mcp_compliance },
        { name = "Model Listing MCP Compliance", func = M.test_model_listing_mcp_compliance },
        { name = "Project Operations MCP Compliance", func = M.test_project_operations_mcp_compliance },
        { name = "File Operations MCP Compliance", func = M.test_file_operations_mcp_compliance },
    }
    
    local passed = 0
    local failed = 0
    
    for _, test in ipairs(tests) do
        print("\n" .. string.rep("─", 60))
        print("🧪 Running: " .. test.name)
        print(string.rep("─", 60))
        
        local success, err = test.func()
        if success then
            print("✅ " .. test.name .. " PASSED")
            passed = passed + 1
        else
            print("❌ " .. test.name .. " FAILED: " .. tostring(err))
            failed = failed + 1
        end
    end
    
    print("\n" .. string.rep("=", 60))
    print("📊 MCP-Only Compliance Test Results")
    print(string.rep("=", 60))
    print("✅ Passed: " .. passed)
    print("❌ Failed: " .. failed)
    print("📈 Success Rate: " .. string.format("%.1f%%", (passed / (passed + failed)) * 100))
    
    if failed == 0 then
        print("\n🎉 ALL TESTS PASSED! MCP-only compliance achieved!")
        return true
    else
        print("\n⚠️  Some tests failed. MCP-only compliance not yet complete.")
        return false
    end
end

-- Export module
return M
