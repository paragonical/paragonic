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
	@echo "✓ Unit tests completed"

# Integration tests (with backend, using standalone RPC client)
test-lua-integration:
	@echo "=== Running Lua Integration Tests ==="
	@echo "Testing search functionality integration..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_lua_search_integration.lua
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

# Agentic collaboration tests
test-lua-agent:
	@echo "=== Running Lua Agent Tests ==="
	@echo "Testing agent session info..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_agent_session_info.lua
	@echo ""
	@echo "✓ Agent tests completed"

# RPC-specific tests (standalone RPC client only)
test-lua-rpc:
	@echo "=== Running Lua RPC Tests ==="
	@echo "Testing RPC JSON handling..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_json.lua
	@echo ""
	@echo "Testing RPC standalone functionality..."
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/test_rpc_standalone.lua
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

# Comprehensive test runner
test-lua-comprehensive:
	@echo "=== Running Comprehensive Lua Test Suite ==="
	@$(NEOVIM_LUA) $(LUA_TEST_DIR)/run_lua_tests.lua

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
	@echo "  test-lua-comprehensive- Comprehensive test runner"
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
	@echo "  make test-lua-comprehensive    # Comprehensive test runner"
	@echo "  make test-lua-with-backend     # Full test with backend"
	@echo "  cargo run -- --no-database &   # Start backend"
	@echo "  make test-lua-with-backend     # Run tests"
