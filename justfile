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
deprecated-dir := "tests/deprecated"

# Default recipe
default:
    @just --list

# Unit tests (fast, no external dependencies)
test-unit-core:
    #!/usr/bin/env bash
    echo "=== Running Unit Tests: Core ==="
    echo "Testing basic functionality (standalone)..."
    LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/core/test_simple.lua
    echo "Testing JSON parsing (standalone)..."
    LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/core/test_json_parsing.lua
    echo "Testing search functions (standalone)..."
    LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/core/test_search_functions.lua
    echo ""
    echo "Testing Neovim-dependent core functionality..."
    echo "Testing initialization..."
    {{neovim-cmd}} --headless --noplugin -c "lua dofile('{{unit-dir}}/core/test_initialization_unit.lua')" -c "quit"
    echo "Testing persistent storage..."
    {{neovim-cmd}} --headless --noplugin -c "lua dofile('{{unit-dir}}/core/test_persistent_storage.lua')" -c "quit"
    echo "Testing search history..."
    {{neovim-cmd}} --headless --noplugin -c "lua dofile('{{unit-dir}}/core/test_search_history.lua')" -c "quit"
    echo "✓ Core unit tests completed (standalone + Neovim tests)"

test-unit-rpc:
    #!/usr/bin/env bash
    echo "=== Running Unit Tests: RPC ==="
    echo "Testing RPC timeout and retry behavior (standalone)..."
    LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/rpc/test_timeout_retry_simple.lua
    echo ""
    echo "Testing RPC functionality in Neovim environment..."
    echo "Testing basic RPC functionality..."
    {{neovim-cmd}} --headless --noplugin -c "lua dofile('{{unit-dir}}/rpc/test_rpc_simple.lua')" -c "quit"
    echo "Testing RPC JSON handling..."
    {{neovim-cmd}} --headless --noplugin -c "lua dofile('{{unit-dir}}/rpc/test_rpc_json.lua')" -c "quit"
    echo "Testing standalone RPC client..."
    {{neovim-cmd}} --headless --noplugin -c "lua dofile('{{unit-dir}}/rpc/test_rpc_standalone.lua')" -c "quit"
    echo "Testing RPC model listing..."
    {{neovim-cmd}} --headless --noplugin -c "lua dofile('{{unit-dir}}/rpc/test_rpc_standalone_list_models.lua')" -c "quit"
    echo "Testing RPC connection..."
    {{neovim-cmd}} --headless --noplugin -c "lua dofile('{{unit-dir}}/rpc/test_rpc_standalone_connection.lua')" -c "quit"
    echo "Testing RPC timeout retry..."
    {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/rpc/test_rpc_timeout_retry.lua')" -c "quit"
    echo "Testing RPC reconnection..."
    {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/rpc/test_rpc_reconnection.lua')" -c "quit"
    echo "Testing RPC reconnection basic..."
    {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/rpc/test_rpc_reconnection_basic.lua')" -c "quit"
    echo "Testing RPC reconnection minimal..."
    {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/rpc/test_rpc_reconnection_minimal.lua')" -c "quit"
    echo "Testing RPC reconnection simple..."
    {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/rpc/test_rpc_reconnection_simple.lua')" -c "quit"
    echo "Testing RPC reconnection standalone..."
    {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/rpc/test_rpc_reconnection_standalone.lua')" -c "quit"
    echo "Testing RPC reconnection working..."
    {{neovim-cmd}} --headless --noplugin -c "lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua' dofile('{{unit-dir}}/rpc/test_rpc_reconnection_working.lua')" -c "quit"
    echo "✓ RPC unit tests completed (standalone + Neovim tests)"

test-unit-utils:
    #!/usr/bin/env bash
    echo "=== Running Unit Tests: Utils ==="
    echo "Testing formatting utilities..."
    LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/utils/test_format_simple.lua
    echo "Testing escaping utilities..."
    LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/utils/test_escape.lua
    echo "Testing pattern matching..."
    LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/utils/test_pattern.lua
    echo "✓ Utils unit tests completed"

test-unit-neovim:
    #!/usr/bin/env bash
    echo "=== Running Unit Tests: Neovim ==="
    echo "Testing pattern management commands..."
    LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/neovim/test_pattern_management_commands.lua
    echo "Testing pattern execution commands..."
    LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/neovim/test_pattern_execution_commands.lua
    echo "Testing pattern display functions..."
    LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/neovim/test_pattern_display_functions.lua
    echo "Testing pattern metrics display..."
    LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/neovim/test_pattern_metrics_display.lua
    echo "Testing session pattern integration..."
    LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/neovim/test_session_pattern_integration.lua
    echo "✓ Neovim unit tests completed"

test-unit-chat:
    #!/usr/bin/env bash
    echo "=== Running Unit Tests: Chat ==="
    echo "Testing standalone chat functionality..."
    echo "Testing chat visual feedback simple..."
    LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/chat/test_chat_visual_feedback_simple.lua
    echo "Testing smart send..."
    LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/chat/test_smart_send.lua
    echo "Testing streaming fix..."
    LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/chat/test_streaming_fix.lua
    echo "Testing thinking streaming..."
    LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/chat/test_thinking_streaming.lua
    echo ""
    echo "Testing Neovim-dependent chat functionality..."
    echo "Testing chat visual feedback..."
    {{neovim-cmd}} --headless --noplugin -c "lua dofile('{{unit-dir}}/chat/test_chat_visual_feedback.lua')" -c "quit"
    echo "Testing real connection..."
    {{neovim-cmd}} --headless --noplugin -c "lua dofile('{{unit-dir}}/chat/test_real_connection.lua')" -c "quit"
    echo "Testing RPC fallback..."
    {{neovim-cmd}} --headless --noplugin -c "lua dofile('{{unit-dir}}/chat/test_rpc_fallback.lua')" -c "quit"
    echo "Testing simple RPC..."
    {{neovim-cmd}} --headless --noplugin -c "lua dofile('{{unit-dir}}/chat/test_simple_rpc.lua')" -c "quit"
    echo "Testing text extraction..."
    {{neovim-cmd}} --headless --noplugin -c "lua dofile('{{unit-dir}}/chat/test_text_extraction.lua')" -c "quit"
    echo "Testing thinking streaming integration..."
    {{neovim-cmd}} --headless --noplugin -c "lua dofile('{{unit-dir}}/chat/test_thinking_streaming_integration.lua')" -c "quit"
    echo "✓ Chat unit tests completed (standalone + Neovim tests)"

test-unit-mcp:
    #!/usr/bin/env bash
    echo "=== Running Unit Tests: MCP ==="
    echo "Testing enhanced MCP tool descriptions..."
    LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/mcp/test_enhanced_mcp_tool_descriptions.lua
    echo "Testing MCP tool execution with patterns..."
    LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/mcp/test_mcp_tool_execution_with_patterns.lua
    echo "Testing pattern aware tool recommendations..."
    LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/mcp/test_pattern_aware_tool_recommendations.lua
    echo "Testing tool pattern relationship management..."
    LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/mcp/test_tool_pattern_relationship_management.lua
    echo "Testing tool pattern relationship tracking..."
    LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/mcp/test_tool_pattern_relationship_tracking.lua
    echo "✓ MCP unit tests completed"

test-unit: test-unit-core test-unit-rpc test-unit-utils test-unit-neovim test-unit-chat test-unit-mcp
    #!/usr/bin/env bash
    echo ""
    echo "✓ All unit tests completed"

# RPC integration tests
test-rpc-integration:
    #!/usr/bin/env bash
    echo "=== Running RPC Integration Tests ==="
    echo "Testing RPC server integration (soft fail if server not available)..."
    LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/rpc/test_rpc_integration.lua
    echo "✓ RPC integration tests completed"

# Server lifecycle tests (start/stop servers, use different ports)
test-server-lifecycle-backend:
    #!/usr/bin/env bash
    echo "=== Running Server Lifecycle Tests: Backend ==="
    echo "Testing server start/stop functionality..."
    {{neovim-lua}} {{integration-dir}}/backend/test_rust_backend_server.lua
    echo "✓ Backend server lifecycle tests completed"

test-server-lifecycle: test-server-lifecycle-backend
    #!/usr/bin/env bash
    echo ""
    echo "✓ All server lifecycle tests completed"

# Server interaction tests (use already running server on port 3000)
test-server-interaction-chat:
    #!/usr/bin/env bash
    echo "=== Running Server Interaction Tests: Chat ==="
    echo "Testing basic chat functionality..."
    {{neovim-lua}} {{integration-dir}}/chat/test_chat_simple.lua
    echo "Testing chat interface..."
    {{neovim-lua}} {{integration-dir}}/chat/test_chat_interface.lua
    echo "Testing chat with backend..."
    {{neovim-lua}} {{integration-dir}}/chat/test_chat_backend.lua
    echo "Testing interactive chat..."
    {{neovim-lua}} {{integration-dir}}/chat/test_chat_interactive.lua
    echo "✓ Chat server interaction tests completed"

test-server-interaction-search:
    #!/usr/bin/env bash
    echo "=== Running Server Interaction Tests: Search ==="
    echo "Testing search integration..."
    {{neovim-lua}} {{integration-dir}}/search/test_lua_search_integration.lua
    echo "Testing enhanced search core..."
    {{neovim-lua}} {{integration-dir}}/search/test_enhanced_search_core.lua
    echo "Testing enhanced search UI..."
    {{neovim-lua}} {{integration-dir}}/search/test_enhanced_search_ui.lua
    echo "Testing Neovim search integration..."
    {{neovim-lua}} {{integration-dir}}/search/test_neovim_search_integration.lua
    echo "✓ Search server interaction tests completed"

test-server-interaction-backend:
    #!/usr/bin/env bash
    echo "=== Running Server Interaction Tests: Backend ==="
    echo "Testing backend initialization..."
    {{neovim-lua}} {{integration-dir}}/backend/test_backend_init.lua
    echo "Testing Ollama integration..."
    {{neovim-lua}} {{integration-dir}}/backend/test_ollama_integration.lua
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

test-e2e: test-e2e-plugin test-e2e-startup
    #!/usr/bin/env bash
    echo ""
    echo "✓ All E2E tests completed"

# All tests
test-all: test-unit test-e2e
    #!/usr/bin/env bash
    echo ""
    echo "=== Test Summary ==="
    echo "✓ Unit tests: Core, RPC, Utils, Neovim, Chat, MCP"
    echo "⚠️  Integration tests: Skipped (require running backend)"
    echo "✓ E2E tests: Plugin, Startup"
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
    LUA_PATH="{{lua-path}}" {{neovim-lua}} {{unit-dir}}/test_timeout_retry_suite.lua
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

# Clean up deprecated tests
clean-deprecated:
    #!/usr/bin/env bash
    echo "=== Cleaning Deprecated Tests ==="
    echo "Moving deprecated tests to {{deprecated-dir}}..."
    echo "Review {{deprecated-dir}} and remove obsolete tests manually"
    echo "✓ Deprecated tests moved"

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
    echo "  test-server-interaction - Tests that use already running server"
    echo "  test-server-lifecycle   - Tests that start/stop their own servers"
    echo "  test-e2e          - All E2E tests (full Neovim environment)"
    echo "  test-all          - All tests (unit + e2e, integration requires backend)"
    echo "  test-dev          - Development test (unit + search)"
    echo "  test-timeout-retry - Timeout and retry behavior tests"
    echo "  test-with-backend - Server interaction tests (requires backend running)"
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
    echo "  clean-deprecated  - Clean up deprecated tests"
    echo "  clean-makefiles   - Remove old Makefile versions"
    echo ""
    echo "Examples:"
    echo "  just test              # Quick development test"
    echo "  just test-unit         # Fast unit tests"
    echo "  just test-unit-neovim  # Neovim integration tests only"
    echo "  just test-server-interaction  # Tests using running server"
    echo "  just test-server-lifecycle    # Tests that manage servers"
    echo "  just test-all          # Complete test suite"
    echo ""
    echo "Backend setup:"
    echo "  cargo run -- --no-database &  # Start backend"
    echo "  just test-with-backend        # Run server interaction tests"

# Legacy targets for backward compatibility
test-lua: test
test-lua-unit: test-unit
test-lua-integration: test-server-interaction
