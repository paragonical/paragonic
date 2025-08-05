README.html: README.md
	pandoc -o $@ $<

# Lua test suite targets
.PHONY: test-lua test-lua-unit test-lua-integration test-lua-search test-lua-rpc test-lua-all test-lua-standalone test-lua-comprehensive

# Test configuration
LUA_TEST_DIR = .
LUA_MODULE_PATH = ./lua/?.lua;./lua/?/init.lua
NEOVIM_LUA = nlua

# Core unit tests (basic functionality, no external dependencies)
test-lua-unit:
	@echo "=== Running Lua Unit Tests ==="
	@echo "Testing basic JSON handling..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_json.lua
	@echo ""
	@echo "Testing simple functionality..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_simple.lua
	@echo ""
	@echo "Testing JSON parsing..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_json_parsing.lua
	@echo ""
	@echo "Testing database bypass simple..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_database_bypass_simple.lua
	@echo ""
	@echo "Testing database bypass complete..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_database_bypass_complete.lua
	@echo ""
	@echo "Testing PostgreSQL workaround..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_postgresql_workaround.lua
	@echo ""
	@echo "Testing socket communication..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_socket_communication.lua
	@echo ""
	@echo "Testing socket logic..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_socket_logic.lua
	@echo ""
	@echo "Testing raw TCP communication..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_raw_tcp_communication.lua
	@echo ""
	@echo "Testing real socket communication..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_real_socket_communication.lua
	@echo ""
	@echo "Testing working TCP communication..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_working_tcp_communication.lua
	@echo ""
	@echo "Testing RPC chat completion..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_chat_completion.lua
	@echo ""
	@echo "Testing RPC connect..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_connect.lua
	@echo ""
	@echo "Testing RPC debug..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_debug.lua
	@echo ""
	@echo "Testing RPC hello..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_hello.lua
	@echo ""
	@echo "Testing RPC models..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_models.lua
	@echo ""
	@echo "Testing RPC search..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_search.lua
	@echo ""
	@echo "Testing RPC..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc.lua
	@echo ""
	@echo "✓ Unit tests completed"

# Integration tests (with backend, using standalone RPC client)
test-lua-integration:
	@echo "=== Running Lua Integration Tests ==="
	@echo "Testing search functionality integration..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_lua_search_integration.lua
	@echo ""
	@echo "Testing enhanced search UI..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_enhanced_search_ui.lua
	@echo ""
	@echo "Testing Neovim search integration..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_neovim_search_integration.lua
	@echo ""
	@echo "Testing open chat integration..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_open_chat_integration.lua
	@echo ""
	@echo "Testing open config..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_open_config.lua
	@echo ""
	@echo "Testing open projects..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_open_projects.lua
	@echo ""
	@echo "Testing projects integration..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_projects_integration.lua
	@echo ""
	@echo "Testing backend init..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_backend_init.lua
	@echo ""
	@echo "Testing Rust backend server..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rust_backend_server.lua
	@echo ""
	@echo "✓ Integration tests completed"

# Search-specific tests (standalone RPC client only)
test-lua-search:
	@echo "=== Running Lua Search Tests ==="
	@echo "Testing search integration..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_lua_search_integration.lua
	@echo ""
	@echo "Testing search functions..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_search_functions.lua
	@echo ""
	@echo "Testing enhanced search UI..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_enhanced_search_core.lua
	@echo ""
	@echo "Testing search history..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_search_history.lua
	@echo ""
	@echo "Testing persistent storage..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_persistent_storage.lua
	@echo ""
	@echo "✓ Search tests completed"

# Agentic collaboration tests (mocked unit tests)
test-lua-agent:
	@echo "=== Running Lua Agent Tests ==="
	@echo "Testing agent session info..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_agent_session_info.lua
	@echo ""
	@echo "Testing agent file edit..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_agent_file_edit.lua
	@echo ""
	@echo "Testing agent file create..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_agent_file_create.lua
	@echo ""
	@echo "Testing agent file save..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_agent_file_save.lua
	@echo ""
	@echo "Testing MCP server init..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_mcp_server_init.lua
	@echo ""
	@echo "Testing MCP resource content..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_mcp_resource_content.lua
	@echo ""
	@echo "Testing MCP marks resource..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_mcp_marks_resource.lua
	@echo ""
	@echo "Testing MCP additional resources..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_mcp_additional_resources.lua
	@echo ""
	@echo "Testing MCP tool enhancement..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_mcp_tool_enhancement.lua
	@echo ""
	@echo "Testing MCP progress tracking..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_mcp_progress_tracking.lua
	@echo ""
	@echo "Testing MCP sampling and roots..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_mcp_sampling_roots.lua
	@echo ""
	@echo "Testing MCP cancellation..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_mcp_cancellation.lua
	@echo ""
	@echo "Testing MCP logging..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_mcp_logging.lua
	@echo ""
	@echo "Testing MCP configuration..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_mcp_configuration.lua
	@echo ""
	@echo "Testing MCP commands and autocommands..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_mcp_commands_autocommands.lua
	@echo ""
	@echo "Testing MCP client features..."
	@lua $(LUA_TEST_DIR)/test_mcp_client_features.lua
	@echo ""
	@echo "Testing AI agent session management..."
	@lua $(LUA_TEST_DIR)/test_ai_agent_session.lua
	@echo ""
	@echo "Testing AI agent message sending..."
	@lua $(LUA_TEST_DIR)/test_ai_agent_message.lua
	@echo ""
	@echo "Testing AI agent message receiving..."
	@lua $(LUA_TEST_DIR)/test_ai_agent_receive.lua
	@echo ""
	@echo "Testing AI agent command execution..."
	@lua $(LUA_TEST_DIR)/test_ai_agent_command.lua
	@echo ""
	@echo "Testing AI agent buffer content..."
	@lua $(LUA_TEST_DIR)/test_ai_agent_buffer.lua
	@echo ""
	@echo "Testing AI agent buffer write..."
	@lua $(LUA_TEST_DIR)/test_ai_agent_buffer_write.lua
	@echo ""
	@echo "Testing configuration integration..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_config_integration.lua
	@echo ""
	@echo "Testing chat backend..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_chat_backend.lua
	@echo ""
	@echo "Testing chat interactive..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_chat_interactive.lua
	@echo ""
	@echo "Testing chat interface..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_chat_interface.lua
	@echo ""
	@echo "Testing database bypass..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_database_bypass.lua
	@echo ""
	@echo "Testing Ollama integration..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_ollama_integration.lua
	@echo ""
	@echo "Testing Ollama integration fixed..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_ollama_integration_fixed.lua
	@echo ""
	@echo "Testing Ollama runtime debug..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_ollama_runtime_debug.lua
	@echo ""
	@echo "✓ Agent tests completed"

# Real Neovim integration tests (actual Neovim environment)
test-lua-integration-real:
	@echo "=== Running Real Neovim Integration Tests ==="
	@echo "Testing AI agent functions in actual Neovim environment..."
	@./run_integration_test.sh
	@echo ""
	@echo "✓ Real Neovim integration tests completed"

# RPC-specific tests (standalone RPC client only)
test-lua-rpc:
	@echo "=== Running Lua RPC Tests ==="
	@echo "Testing RPC JSON handling..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_json.lua
	@echo ""
	@echo "Testing RPC standalone functionality..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_standalone.lua
	@echo ""
	@echo "Testing RPC standalone batch operations..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_standalone_batch_operations.lua
	@echo ""
	@echo "Testing RPC standalone batch simple..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_standalone_batch_simple.lua
	@echo ""
	@echo "Testing RPC standalone connection pooling..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_standalone_connection_pooling.lua
	@echo ""
	@echo "Testing RPC standalone connection..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_standalone_connection.lua
	@echo ""
	@echo "Testing RPC standalone debug..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_standalone_debug.lua
	@echo ""
	@echo "Testing RPC standalone disconnect..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_standalone_disconnect.lua
	@echo ""
	@echo "Testing RPC standalone list models..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_standalone_list_models.lua
	@echo ""
	@echo "Testing RPC standalone logging..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_standalone_logging.lua
	@echo ""
	@echo "Testing RPC standalone ping..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_standalone_ping.lua
	@echo ""
	@echo "Testing RPC standalone retry operations..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_standalone_retry_operations.lua
	@echo ""
	@echo "Testing RPC standalone server info..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_standalone_server_info.lua
	@echo ""
	@echo "Testing RPC standalone timeout operations..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_standalone_timeout_operations.lua
	@echo ""
	@echo "✓ RPC tests completed"

# Standalone tests (no external dependencies)
test-lua-standalone:
	@echo "=== Running Lua Standalone Tests ==="
	@echo "Testing RPC JSON handling..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_json.lua
	@echo ""
	@echo "Testing simple functionality..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_simple.lua
	@echo ""
	@echo "Testing RPC standalone functionality..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_standalone.lua
	@echo ""
	@echo "✓ Standalone tests completed"

# Legacy comprehensive test runner (deprecated)
# test-lua-comprehensive:
# 	@echo "=== Running Comprehensive Lua Test Suite ==="
# 	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/run_lua_tests.lua

# All Lua tests (comprehensive, with backend)
test-lua-all:
	@echo "=== Running Complete Lua Test Suite ==="
	@echo ""
	@$(MAKE) test-lua-unit
	@echo ""
	@$(MAKE) test-lua-integration
	@echo ""
	@echo "=== Additional Standalone Tests ==="
	@echo "Testing model info..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_standalone_model_info.lua || echo "⚠ Model info test failed (may need backend)"
	@echo ""
	@echo "Testing chat completion..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_standalone_chat_completion.lua || echo "⚠ Chat completion test failed (may need backend)"
	@echo ""
	@echo "Testing generate embedding..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_standalone_generate_embedding.lua || echo "⚠ Generate embedding test failed (may need backend)"
	@echo ""
	@echo "✓ Complete Lua test suite finished"

# Comprehensive test suite (unit + integration)
test-lua-comprehensive:
	@echo "=== Running Comprehensive Test Suite ==="
	@echo "Phase 1: Unit Tests (Mocked API)..."
	@$(MAKE) test-lua-agent
	@echo ""
	@echo "Phase 2: Integration Tests (Real Neovim)..."
	@$(MAKE) test-lua-integration-real
	@echo ""
	@echo "✓ Comprehensive test suite completed"

# Quick test (most important tests)
test-lua: test-lua-unit test-lua-search
	@echo ""
	@echo "✓ Quick Lua test suite completed"

# Test with backend running (requires backend to be started)
test-lua-with-backend:
	@echo "=== Running Lua Tests with Backend ==="
	@echo "Make sure the Rust backend is running with: cargo run -- --no-database"
	@echo ""
	@$(MAKE) test-lua-all

# Development test (frequently used during development)
test-lua-dev: test-lua-standalone test-lua-search
	@echo ""
	@echo "✓ Development test suite completed"

# Help target
help:
	@echo "Available Lua test targets:"
	@echo "  test-lua              - Quick test (unit + search)"
	@echo "  test-lua-unit         - Unit tests only (no dependencies)"
	@echo "  test-lua-integration  - Integration tests (requires backend)"
	@echo "  test-lua-search       - Search functionality tests"
	@echo "  test-lua-rpc          - RPC functionality tests"
	@echo "  test-lua-standalone   - Standalone tests (no external deps)"
	@echo "  test-lua-agent        - AI agent unit tests (mocked API)"
	@echo "  test-lua-integration-real - AI agent integration tests (real Neovim)"
	@echo "  test-lua-comprehensive- Comprehensive test suite (unit + integration)"
	@echo "  test-lua-all          - All Lua tests"
	@echo "  test-lua-with-backend - All tests (requires backend running)"
	@echo "  test-lua-dev          - Development tests (frequently used)"
	@echo ""
	@echo "Test Categories:"
	@echo "  Unit tests: Basic functionality, no external dependencies"
	@echo "  Integration tests: Require Rust backend to be running"
	@echo "  Standalone tests: Use standalone RPC client, no socket deps"
	@echo ""
	@echo "Examples:"
	@echo "  make test-lua-dev              # Development workflow"
	@echo "  make test-lua-agent            # AI agent unit tests (fast)"
	@echo "  make test-lua-integration-real # AI agent integration tests (real Neovim)"
	@echo "  make test-lua-comprehensive    # Complete test suite (unit + integration)"
	@echo "  make test-lua-with-backend     # Full test with backend"
	@echo "  cargo run -- --no-database &   # Start backend"
	@echo "  make test-lua-with-backend     # Run tests"
