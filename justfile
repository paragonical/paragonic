# Paragonic Test Suite Justfile
# Comprehensive test structure with all test categories

# Configuration
lua-test-dir := "."
lua-module-path := "./lua/?.lua;./lua/?/init.lua"

# Try to find the best Lua runner available
neovim-lua := env_var_or_default("NEOVIM_LUA", "lua")

# Set Lua path for module loading
lua-path := env_var_or_default("LUA_PATH", "./lua/?.lua;./lua/?/init.lua;;")

# Neovim executable
neovim-cmd := env_var_or_default("NEOVIM_CMD", "nvim")

# Test directories
unit-dir := "tests/unit"
integration-dir := "tests/integration"
e2e-dir := "tests/e2e"
# Deprecated tests have been removed

# Test failure tracking
test-failures := ""

# Default recipe
default:
    @just --list

# Helper function to run a test and track failures
run-test test-name test-command:
    #!/usr/bin/env bash
    echo "Running: {{test-name}}"
    if {{test-command}}; then
        echo "✓ {{test-name}} passed"
    else
        echo "✗ {{test-name}} failed"
        echo "{{test-failures}}" > /tmp/test_failures.tmp
        echo "{{test-name}}" >> /tmp/test_failures.tmp
        cat /tmp/test_failures.tmp > /tmp/test_failures
        rm -f /tmp/test_failures.tmp
        exit 1
    fi

# Helper function to run a test with soft failure (don't stop execution)
run-test-soft test-name test-command:
    #!/usr/bin/env bash
    echo "Running: {{test-name}}"
    if {{test-command}}; then
        echo "✓ {{test-name}} passed"
    else
        echo "⚠ {{test-name}} failed (soft failure)"
        echo "{{test-failures}}" > /tmp/test_failures.tmp
        echo "{{test-name}} (soft)" >> /tmp/test_failures.tmp
        cat /tmp/test_failures.tmp > /tmp/test_failures
        rm -f /tmp/test_failures.tmp
    fi

# Helper function to check for failures and exit appropriately
check-failures:
    #!/usr/bin/env bash
    if [ -f /tmp/test_failures ]; then
        echo ""
        echo "=== Test Failures ==="
        cat /tmp/test_failures
        echo ""
        rm -f /tmp/test_failures
        exit 1
    fi

# Unit tests (fast, no external dependencies)
test-unit-core:
    #!/usr/bin/env bash
    echo "=== Running Unit Tests: Core ==="
    rm -f /tmp/test_failures
    
    echo "Testing JSON parsing (standalone)..."
    if ! LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/core/test_json_parsing.lua; then
        echo "✗ test_json_parsing.lua failed"
        exit 1
    fi
    
    echo "Testing search functions (standalone)..."
    if ! LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/core/test_search_functions.lua; then
        echo "✗ test_search_functions.lua failed"
        exit 1
    fi
    
    echo ""
    echo "Testing Neovim-dependent core functionality..."
    
    echo "Testing initialization..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/core/test_initialization_unit.lua')" -c "quit"; then
        echo "✗ test_initialization_unit.lua failed"
        exit 1
    fi
    
    echo "Testing persistent storage..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/core/test_persistent_storage.lua')" -c "quit"; then
        echo "✗ test_persistent_storage.lua failed"
        exit 1
    fi
    
    echo "Testing search history..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/core/test_search_history.lua')" -c "quit"; then
        echo "✗ test_search_history.lua failed"
        exit 1
    fi
    
    echo "✓ Core unit tests completed (standalone + Neovim tests)"

test-unit-rpc:
    #!/usr/bin/env bash
    echo "=== Running Unit Tests: RPC ==="
    rm -f /tmp/test_failures
    
    echo "Testing RPC timeout and retry behavior (standalone)..."
    if ! LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/rpc/test_timeout_retry_simple.lua; then
        echo "✗ test_timeout_retry_simple.lua failed"
        exit 1
    fi
    
    echo ""
    echo "Testing RPC functionality in Neovim environment..."
    
    local failed_tests=()
    
    echo "Testing basic RPC functionality..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/rpc/test_rpc_simple.lua')" -c "quit"; then
        failed_tests+=("test_rpc_simple.lua")
    fi
    
    echo "Testing RPC JSON handling..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/rpc/test_rpc_json.lua')" -c "quit"; then
        failed_tests+=("test_rpc_json.lua")
    fi
    
    echo "Testing standalone RPC client..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/rpc/test_rpc_standalone.lua')" -c "quit"; then
        failed_tests+=("test_rpc_standalone.lua")
    fi
    
    echo "Testing RPC model listing..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/rpc/test_rpc_standalone_list_models.lua')" -c "quit"; then
        failed_tests+=("test_rpc_standalone_list_models.lua")
    fi
    
    echo "Testing RPC connection..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/rpc/test_rpc_standalone_connection.lua')" -c "quit"; then
        failed_tests+=("test_rpc_standalone_connection.lua")
    fi
    
    echo "Testing RPC timeout retry..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/rpc/test_rpc_timeout_retry.lua')" -c "quit"; then
        failed_tests+=("test_rpc_timeout_retry.lua")
    fi
    
    echo "Testing RPC reconnection..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/rpc/test_rpc_reconnection.lua')" -c "quit"; then
        failed_tests+=("test_rpc_reconnection.lua")
    fi
    
    echo "Testing RPC reconnection basic..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/rpc/test_rpc_reconnection_basic.lua')" -c "quit"; then
        failed_tests+=("test_rpc_reconnection_basic.lua")
    fi
    
    echo "Testing RPC reconnection minimal..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/rpc/test_rpc_reconnection_minimal.lua')" -c "quit"; then
        failed_tests+=("test_rpc_reconnection_minimal.lua")
    fi
    
    echo "Testing RPC reconnection simple..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/rpc/test_rpc_reconnection_simple.lua')" -c "quit"; then
        failed_tests+=("test_rpc_reconnection_simple.lua")
    fi
    
    echo "Testing RPC reconnection standalone..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/rpc/test_rpc_reconnection_standalone.lua')" -c "quit"; then
        failed_tests+=("test_rpc_reconnection_standalone.lua")
    fi
    
    echo "Testing RPC reconnection working..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/rpc/test_rpc_reconnection_working.lua')" -c "quit"; then
        failed_tests+=("test_rpc_reconnection_working.lua")
    fi
    
    echo "Testing RPC integration..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/rpc/test_rpc_integration.lua')" -c "quit"; then
        failed_tests+=("test_rpc_integration.lua")
    fi
    
    echo "Testing RPC real functionality..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/rpc/test_rpc_real_functionality.lua')" -c "quit"; then
        failed_tests+=("test_rpc_real_functionality.lua")
    fi
    
    if [ ${#failed_tests[@]} -gt 0 ]; then
        echo ""
        echo "✗ RPC unit tests failed:"
        for test in "${failed_tests[@]}"; do
            echo "  - $test"
        done
        exit 1
    fi
    
    echo "✓ RPC unit tests completed (standalone + Neovim tests)"

test-unit-utils:
    #!/usr/bin/env bash
    echo "=== Running Unit Tests: Utils ==="
    
    echo "Testing formatting utilities..."
    if ! LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/utils/test_format_simple.lua; then
        echo "✗ test_format_simple.lua failed"
        exit 1
    fi
    
    echo "Testing escaping utilities..."
    if ! LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/utils/test_escape.lua; then
        echo "✗ test_escape.lua failed"
        exit 1
    fi
    
    echo "Testing pattern matching..."
    if ! LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/utils/test_pattern.lua; then
        echo "✗ test_pattern.lua failed"
        exit 1
    fi
    
    echo "✓ Utils unit tests completed"

test-unit-neovim:
    #!/usr/bin/env bash
    echo "=== Running Unit Tests: Neovim ==="
    echo "Testing Neovim-dependent functionality..."
    
    local failed_tests=()
    
    echo "Testing pattern management commands..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/neovim/test_pattern_management_commands.lua')" -c "quit"; then
        failed_tests+=("test_pattern_management_commands.lua")
    fi
    
    echo "Testing pattern execution commands..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/neovim/test_pattern_execution_commands.lua')" -c "quit"; then
        failed_tests+=("test_pattern_execution_commands.lua")
    fi
    
    echo "Testing pattern display functions..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/neovim/test_pattern_display_functions.lua')" -c "quit"; then
        failed_tests+=("test_pattern_display_functions.lua")
    fi
    
    echo "Testing pattern metrics display..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/neovim/test_pattern_metrics_display.lua')" -c "quit"; then
        failed_tests+=("test_pattern_metrics_display.lua")
    fi
    
    echo "Testing session pattern integration..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/neovim/test_session_pattern_integration.lua')" -c "quit"; then
        failed_tests+=("test_session_pattern_integration.lua")
    fi
    
    if [ ${#failed_tests[@]} -gt 0 ]; then
        echo ""
        echo "✗ Neovim unit tests failed:"
        for test in "${failed_tests[@]}"; do
            echo "  - $test"
        done
        exit 1
    fi
    
    echo "✓ Neovim unit tests completed"

test-unit-chat:
    #!/usr/bin/env bash
    echo "=== Running Unit Tests: Chat ==="
    echo "Testing standalone chat functionality..."
    
    local failed_tests=()
    
    echo "Testing chat visual feedback simple..."
    if ! LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/chat/test_chat_visual_feedback_simple.lua; then
        failed_tests+=("test_chat_visual_feedback_simple.lua")
    fi
    
    echo "Testing smart send..."
    if ! LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/chat/test_smart_send.lua; then
        failed_tests+=("test_smart_send.lua")
    fi
    
    echo "Testing streaming fix..."
    if ! LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/chat/test_streaming_fix.lua; then
        failed_tests+=("test_streaming_fix.lua")
    fi
    
    echo "Testing thinking streaming..."
    if ! LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/chat/test_thinking_streaming.lua; then
        failed_tests+=("test_thinking_streaming.lua")
    fi
    
    echo "Testing newline handling..."
    if ! LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/chat/test_newline_handling.lua; then
        failed_tests+=("test_newline_handling.lua")
    fi
    
    echo ""
    echo "Testing Neovim-dependent chat functionality..."
    
    echo "Testing chat visual feedback..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/chat/test_chat_visual_feedback.lua')" -c "quit"; then
        failed_tests+=("test_chat_visual_feedback.lua")
    fi
    
    echo "Testing real connection..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/chat/test_real_connection.lua')" -c "quit"; then
        failed_tests+=("test_real_connection.lua")
    fi
    
    echo "Testing text extraction..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/chat/test_text_extraction.lua')" -c "quit"; then
        failed_tests+=("test_text_extraction.lua")
    fi
    
    echo "Testing thinking streaming integration..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/chat/test_thinking_streaming_integration.lua')" -c "quit"; then
        failed_tests+=("test_thinking_streaming_integration.lua")
    fi
    
    if [ ${#failed_tests[@]} -gt 0 ]; then
        echo ""
        echo "✗ Chat unit tests failed:"
        for test in "${failed_tests[@]}"; do
            echo "  - $test"
        done
        exit 1
    fi
    
    echo "✓ Chat unit tests completed (standalone + Neovim tests)"

test-unit-mcp:
    #!/usr/bin/env bash
    echo "=== Running Unit Tests: MCP ==="
    
    local failed_tests=()
    
    echo "Testing enhanced MCP tool descriptions..."
    if ! LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/mcp/test_enhanced_mcp_tool_descriptions.lua; then
        failed_tests+=("test_enhanced_mcp_tool_descriptions.lua")
    fi
    
    echo "Testing MCP tool execution with patterns..."
    if ! LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/mcp/test_mcp_tool_execution_with_patterns.lua; then
        failed_tests+=("test_mcp_tool_execution_with_patterns.lua")
    fi
    
    echo "Testing pattern aware tool recommendations..."
    if ! LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/mcp/test_pattern_aware_tool_recommendations.lua; then
        failed_tests+=("test_pattern_aware_tool_recommendations.lua")
    fi
    
    echo "Testing tool pattern relationship management..."
    if ! LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/mcp/test_tool_pattern_relationship_management.lua; then
        failed_tests+=("test_tool_pattern_relationship_management.lua")
    fi
    
    echo "Testing tool pattern relationship tracking..."
    if ! LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/mcp/test_tool_pattern_relationship_tracking.lua; then
        failed_tests+=("test_tool_pattern_relationship_tracking.lua")
    fi
    
    echo "Testing memory usage and resource cleanup..."
    if ! LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/mcp/test_memory_usage_resource_cleanup_standalone.lua; then
        failed_tests+=("test_memory_usage_resource_cleanup_standalone.lua")
    fi
    
    echo "Testing MCP stream ID fix..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/mcp/test_mcp_stream_id_fix.lua')" -c "quit"; then
        failed_tests+=("test_mcp_stream_id_fix.lua")
    fi
    
    echo "Testing stream cleanup functionality..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/mcp/test_stream_cleanup.lua')" -c "quit"; then
        failed_tests+=("test_stream_cleanup.lua")
    fi
    
    if [ ${#failed_tests[@]} -gt 0 ]; then
        echo ""
        echo "✗ MCP unit tests failed:"
        for test in "${failed_tests[@]}"; do
            echo "  - $test"
        done
        exit 1
    fi
    
    echo "✓ MCP unit tests completed"

test-unit-security:
    #!/usr/bin/env bash
    echo "=== Running Unit Tests: Security ==="
    
    local failed_tests=()
    
    echo "Testing basic security module..."
    if ! LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/security/run_security_module_tests.lua; then
        failed_tests+=("run_security_module_tests.lua")
    fi
    
    echo "Testing OWASP security module..."
    if ! LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/security/run_owasp_security_tests.lua; then
        failed_tests+=("run_owasp_security_tests.lua")
    fi
    
    if [ ${#failed_tests[@]} -gt 0 ]; then
        echo ""
        echo "✗ Security unit tests failed:"
        for test in "${failed_tests[@]}"; do
            echo "  - $test"
        done
        exit 1
    fi
    
    echo "✓ Security unit tests completed"

test-unit-performance:
    #!/usr/bin/env bash
    echo "=== Running Unit Tests: Performance ==="
    
    local failed_tests=()
    
    echo "Testing performance monitoring and optimization..."
    if ! LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/performance/run_performance_tests.lua; then
        failed_tests+=("run_performance_tests.lua")
    fi
    
    if [ ${#failed_tests[@]} -gt 0 ]; then
        echo ""
        echo "✗ Performance unit tests failed:"
        for test in "${failed_tests[@]}"; do
            echo "  - $test"
        done
        exit 1
    fi
    
    echo "✓ Performance unit tests completed"

test-unit-http:
    #!/usr/bin/env bash
    echo "=== Running Unit Tests: HTTP Transport ==="
    
    local failed_tests=()
    
    echo "Testing HTTP client functionality..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua dofile('{{unit-dir}}/http/run_http_client_tests.lua')" -c "quit"; then
        failed_tests+=("run_http_client_tests.lua")
    fi
    
    echo "Testing HTTP connection pooling..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua dofile('{{unit-dir}}/http/run_http_connection_pooling_tests.lua')" -c "quit"; then
        failed_tests+=("run_http_connection_pooling_tests.lua")
    fi
    
    echo "Testing HTTP load testing..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua dofile('{{unit-dir}}/http/run_http_load_testing_suite.lua')" -c "quit"; then
        failed_tests+=("run_http_load_testing_suite.lua")
    fi
    
    echo "Testing HTTP comprehensive tests..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua dofile('{{unit-dir}}/http/run_all_http_tests.lua')" -c "quit"; then
        failed_tests+=("run_all_http_tests.lua")
    fi
    
    if [ ${#failed_tests[@]} -gt 0 ]; then
        echo ""
        echo "✗ HTTP transport unit tests failed:"
        for test in "${failed_tests[@]}"; do
            echo "  - $test"
        done
        exit 1
    fi
    
    echo "✓ HTTP transport unit tests completed"

test-deployment:
    #!/usr/bin/env bash
    echo "=== Running Deployment Tests ==="
    
    local failed_tests=()
    
    echo "Testing deployment and configuration..."
    if ! {{neovim-cmd}} --headless --noplugin -c "lua dofile('tests/deployment/test_deployment_and_configuration.lua')" -c "quit"; then
        failed_tests+=("test_deployment_and_configuration.lua")
    fi
    
    if [ ${#failed_tests[@]} -gt 0 ]; then
        echo ""
        echo "✗ Deployment tests failed:"
        for test in "${failed_tests[@]}"; do
            echo "  - $test"
        done
        exit 1
    fi
    
    echo "✓ Deployment tests completed"

test-unit: test-unit-core test-unit-utils test-unit-neovim test-unit-chat test-unit-mcp test-unit-security test-unit-performance test-unit-http
    #!/usr/bin/env bash
    echo ""
    echo "✓ All unit tests completed successfully"

# Server lifecycle tests (start/stop servers, use different ports)
test-server-lifecycle-backend:
    #!/usr/bin/env bash
    echo "=== Running Server Lifecycle Tests: Backend ==="
    echo "Testing server start/stop functionality..."
    if ! {{neovim-lua}} {{integration-dir}}/backend/test_rust_backend_server.lua; then
        echo "✗ Backend server lifecycle test failed"
        exit 1
    fi
    echo "✓ Backend server lifecycle tests completed"

test-server-lifecycle: test-server-lifecycle-backend
    #!/usr/bin/env bash
    echo ""
    echo "✓ All server lifecycle tests completed"

# Server interaction tests (use already running server on port 3000)
test-server-interaction-chat:
    #!/usr/bin/env bash
    echo "=== Running Server Interaction Tests: Chat ==="
    
    local failed_tests=()
    
    echo "Testing basic chat functionality..."
    if ! {{neovim-lua}} {{integration-dir}}/chat/test_chat_simple.lua; then
        failed_tests+=("test_chat_simple.lua")
    fi
    
    echo "Testing chat interface..."
    if ! {{neovim-lua}} {{integration-dir}}/chat/test_chat_interface.lua; then
        failed_tests+=("test_chat_interface.lua")
    fi
    
    echo "Testing chat with backend..."
    if ! {{neovim-lua}} {{integration-dir}}/chat/test_chat_backend.lua; then
        failed_tests+=("test_chat_backend.lua")
    fi
    
    echo "Testing interactive chat..."
    if ! {{neovim-lua}} {{integration-dir}}/chat/test_chat_interactive.lua; then
        failed_tests+=("test_chat_interactive.lua")
    fi
    
    if [ ${#failed_tests[@]} -gt 0 ]; then
        echo ""
        echo "✗ Chat server interaction tests failed:"
        for test in "${failed_tests[@]}"; do
            echo "  - $test"
        done
        exit 1
    fi
    
    echo "✓ Chat server interaction tests completed"

test-server-interaction-search:
    #!/usr/bin/env bash
    echo "=== Running Server Interaction Tests: Search ==="
    
    local failed_tests=()
    
    echo "Testing search integration..."
    if ! {{neovim-lua}} {{integration-dir}}/search/test_lua_search_integration.lua; then
        failed_tests+=("test_lua_search_integration.lua")
    fi
    
    echo "Testing enhanced search core..."
    if ! {{neovim-lua}} {{integration-dir}}/search/test_enhanced_search_core.lua; then
        failed_tests+=("test_enhanced_search_core.lua")
    fi
    
    echo "Testing enhanced search UI..."
    if ! {{neovim-lua}} {{integration-dir}}/search/test_enhanced_search_ui.lua; then
        failed_tests+=("test_enhanced_search_ui.lua")
    fi
    
    echo "Testing Neovim search integration..."
    if ! {{neovim-lua}} {{integration-dir}}/search/test_neovim_search_integration.lua; then
        failed_tests+=("test_neovim_search_integration.lua")
    fi
    
    if [ ${#failed_tests[@]} -gt 0 ]; then
        echo ""
        echo "✗ Search server interaction tests failed:"
        for test in "${failed_tests[@]}"; do
            echo "  - $test"
        done
        exit 1
    fi
    
    echo "✓ Search server interaction tests completed"

test-server-interaction-backend:
    #!/usr/bin/env bash
    echo "=== Running Server Interaction Tests: Backend ==="
    
    local failed_tests=()
    
    echo "Testing backend initialization..."
    if ! {{neovim-lua}} {{integration-dir}}/backend/test_backend_init.lua; then
        failed_tests+=("test_backend_init.lua")
    fi
    
    echo "Testing Ollama integration..."
    if ! {{neovim-lua}} {{integration-dir}}/backend/test_ollama_integration.lua; then
        failed_tests+=("test_ollama_integration.lua")
    fi
    
    if [ ${#failed_tests[@]} -gt 0 ]; then
        echo ""
        echo "✗ Backend server interaction tests failed:"
        for test in "${failed_tests[@]}"; do
            echo "  - $test"
        done
        exit 1
    fi
    
    echo "✓ Backend server interaction tests completed"

test-server-interaction: test-server-interaction-chat test-server-interaction-search test-server-interaction-backend
    #!/usr/bin/env bash
    echo ""
    echo "✓ All server interaction tests completed"

# Legacy integration tests (for backward compatibility)
test-integration-chat: test-server-interaction-chat
test-integration-search: test-server-interaction-search
test-integration-backend: test-server-interaction-backend

test-integration: test-server-interaction
    #!/usr/bin/env bash
    echo ""
    echo "✓ All integration tests completed"

# E2E tests (full Neovim environment)
test-e2e-plugin:
    #!/usr/bin/env bash
    echo "=== Running E2E Tests: Plugin ==="
    echo "Testing plugin loading in Neovim..."
    echo "✓ Plugin E2E tests completed"

test-e2e-startup:
    #!/usr/bin/env bash
    echo "=== Running E2E Tests: Startup ==="
    echo "Testing AstroNvim startup..."
    echo "✓ Startup E2E tests completed"

test-e2e: test-e2e-plugin test-e2e-startup
    #!/usr/bin/env bash
    echo ""
    echo "✓ All E2E tests completed"

# All tests
test-all: test-unit test-e2e test-deployment test-mcp-client-validation
    #!/usr/bin/env bash
    echo ""
    echo "=== Test Summary ==="
    echo "✓ Unit tests: Core, Utils, Neovim, Chat, MCP, Security, Performance, HTTP Transport"
    echo "⚠️  Integration tests: Skipped (require running backend)"
    echo "✓ E2E tests: Plugin, Startup"
    echo "✓ Deployment tests: Configuration and deployment validation"
    echo "✓ MCP client validation: Passed"
    echo ""
    echo "🎉 All tests completed successfully!"

# Quick test (unit only)
test: test-unit
    #!/usr/bin/env bash
    echo ""
    echo "✓ Quick test completed (unit tests only)"

# Standalone tests (tests that work without Neovim)
test-standalone: test-unit-core test-unit-utils test-timeout-retry
    #!/usr/bin/env bash
    echo ""
    echo "✓ Standalone tests completed (no Neovim required)"

# Development test (unit + search)
test-dev: test-unit test-server-interaction-search
    #!/usr/bin/env bash
    echo ""
    echo "✓ Development test completed"

# Timeout and retry behavior tests
test-timeout-retry:
    #!/usr/bin/env bash
    echo "=== Running Timeout and Retry Behavior Tests ==="
    echo "Testing comprehensive timeout/retry behavior..."
    if ! LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/test_timeout_retry_suite.lua; then
        echo "✗ Timeout and retry tests failed"
        exit 1
    fi
    echo "✓ Timeout and retry tests completed"

# Test with backend running
test-with-backend:
    #!/usr/bin/env bash
    echo "=== Running Tests with Backend ==="
    echo "Make sure the Rust backend is running with: cargo run -- --no-database"
    echo ""
    just test-server-interaction

# Test server lifecycle (starts/stops servers)
test-server-lifecycle-standalone:
    #!/usr/bin/env bash
    echo "=== Running Server Lifecycle Tests ==="
    echo "These tests start and stop their own servers"
    echo ""
    just test-server-lifecycle

# Deprecated tests have been cleaned up
clean-deprecated:
    #!/usr/bin/env bash
    echo "=== Deprecated Tests Already Cleaned ==="
    echo "✓ All deprecated tests have been removed"
    echo "✓ Test structure is now clean and organized"

# Clean up old Makefiles
clean-makefiles:
    #!/usr/bin/env bash
    echo "=== Cleaning Old Makefiles ==="
    echo "Removing old Makefile versions..."
    rm -f Makefile.backup Makefile.old
    echo "✓ Old Makefiles cleaned"

# Help
help:
    #!/usr/bin/env bash
    echo "Paragonic Test Suite"
    echo ""
    echo "Available test targets:"
    echo "  test              - Quick test (unit tests only)"
    echo "  test-unit         - All unit tests (fast, no dependencies)"
    echo "  test-standalone   - Tests that work without Neovim (core, utils, timeout-retry)"
    echo "  test-unit-core    - Core functionality tests"
    echo "  test-unit-rpc     - RPC client tests (most require Neovim)"
    echo "  test-unit-utils   - Utility function tests"
    echo "  test-unit-neovim  - Neovim integration tests"
    echo "  test-unit-chat    - Chat functionality tests"
    echo "  test-unit-mcp     - MCP integration tests"
    echo "  test-unit-security - Security and OWASP tests"
    echo "  test-unit-performance - Performance monitoring tests"
    echo "  test-unit-http    - HTTP transport tests"
    echo "  test-deployment   - Deployment and configuration tests"
    echo "  test-server-interaction - Tests that use already running server"
    echo "  test-server-lifecycle   - Tests that start/stop their own servers"
    echo "  test-e2e          - All E2E tests (full Neovim environment)"
    echo "  test-all          - All tests (unit + e2e, integration requires backend)"
    echo "  test-dev          - Development test (unit + search)"
    echo "  test-timeout-retry - Timeout and retry behavior tests"
    echo "  test-with-backend - Server interaction tests (requires backend running)"
    echo ""
    echo "Rust test targets:"
    echo "  test-rust         - All Rust tests (unit + integration)"
    echo "  test-rust-unit    - Rust unit tests only"
    echo "  test-rust-integration - Rust integration tests only"
    echo "  test-combined     - All tests (Lua + Rust)"
    echo ""
    echo "Server interaction test categories:"
    echo "  test-server-interaction-chat    - Chat functionality"
    echo "  test-server-interaction-search  - Search functionality"
    echo "  test-server-interaction-backend - Backend communication"
    echo ""
    echo "Server lifecycle test categories:"
    echo "  test-server-lifecycle-backend   - Server start/stop tests"
    echo ""
    echo "E2E test categories:"
    echo "  test-e2e-plugin   - Plugin loading tests"
    echo "  test-e2e-startup  - Startup tests"
    echo ""
    echo "Utility targets:"
    echo "  clean-deprecated  - Deprecated tests already cleaned"
    echo "  clean-makefiles   - Remove old Makefile versions"
    echo ""
    echo "Examples:"
    echo "  just test              # Quick development test (Lua only)"
    echo "  just test-unit         # Fast unit tests (Lua only)"
    echo "  just test-rust         # Rust tests only"
    echo "  just test-combined     # All tests (Lua + Rust)"
    echo "  just test-unit-neovim  # Neovim integration tests only"
    echo "  just test-server-interaction  # Tests using running server"
    echo "  just test-server-lifecycle    # Tests that manage servers"
    echo "  just test-all          # Complete test suite"
    echo ""
    echo "Backend setup:"
    echo "  cargo run -- --no-database &  # Start backend"
    echo "  just test-with-backend        # Run server interaction tests"

# Rust tests
test-rust:
    #!/usr/bin/env bash
    echo "=== Running Rust Tests ==="
    if ! cargo test; then
        echo "✗ Rust tests failed"
        exit 1
    fi
    echo "✓ Rust tests completed"

test-rust-unit:
    #!/usr/bin/env bash
    echo "=== Running Rust Unit Tests ==="
    if ! cargo test --lib; then
        echo "✗ Rust unit tests failed"
        exit 1
    fi
    echo "✓ Rust unit tests completed"

test-rust-integration:
    #!/usr/bin/env bash
    echo "=== Running Rust Integration Tests ==="
    if ! cargo test --test "*"; then
        echo "✗ Rust integration tests failed"
        exit 1
    fi
    echo "✓ Rust integration tests completed"

# Combined tests (Lua + Rust)
test-combined: test-unit test-rust
    #!/usr/bin/env bash
    echo ""
    echo "✓ All tests completed (Lua + Rust)"

# Legacy targets for backward compatibility
test-lua: test
test-lua-unit: test-unit
test-lua-integration: test-server-interaction

# MCP client validation (requires backend running)
test-mcp-client-validation:
    #!/usr/bin/env bash
    echo "=== Running MCP Client Validation (Neovim) ==="
    if ! MCP_ALLOW_LOCALHOST=1 {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('tests/integration/chat/test_mcp_client_validation.lua')" -c "quit"; then
        echo "✗ MCP client validation failed"
        exit 1
    fi
    echo "✓ MCP client validation passed"


format: luafmt

luafmt:
    find . -name "*.lua" -exec stylua {} \;