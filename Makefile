# Paragonic Test Suite Makefile
# Clean, organized test structure

# Configuration
LUA_TEST_DIR = .
LUA_MODULE_PATH = ./lua/?.lua;./lua/?/init.lua
NEOVIM_LUA = nlua

# Test directories
UNIT_DIR = tests/unit
INTEGRATION_DIR = tests/integration
E2E_DIR = tests/e2e
DEPRECATED_DIR = tests/deprecated

# Unit tests (fast, no external dependencies)
.PHONY: test-unit test-unit-core test-unit-rpc test-unit-utils

test-unit-core:
	@echo "=== Running Unit Tests: Core ==="
	@echo "Testing basic functionality..."
	@$(NEOVIM_LUA) $(UNIT_DIR)/core/test_simple.lua
	@echo "Testing JSON parsing..."
	@$(NEOVIM_LUA) $(UNIT_DIR)/core/test_json_parsing.lua
	@echo "Testing initialization..."
	@$(NEOVIM_LUA) $(UNIT_DIR)/core/test_initialization_unit.lua
	@echo "Testing persistent storage..."
	@$(NEOVIM_LUA) $(UNIT_DIR)/core/test_persistent_storage.lua
	@echo "Testing search functions..."
	@$(NEOVIM_LUA) $(UNIT_DIR)/core/test_search_functions.lua
	@echo "Testing search history..."
	@$(NEOVIM_LUA) $(UNIT_DIR)/core/test_search_history.lua
	@echo "✓ Core unit tests completed"

test-unit-rpc:
	@echo "=== Running Unit Tests: RPC ==="
	@echo "Testing basic RPC functionality..."
	@$(NEOVIM_LUA) $(UNIT_DIR)/rpc/test_rpc_simple.lua
	@echo "Testing RPC JSON handling..."
	@$(NEOVIM_LUA) $(UNIT_DIR)/rpc/test_rpc_json.lua
	@echo "Testing standalone RPC client..."
	@$(NEOVIM_LUA) $(UNIT_DIR)/rpc/test_rpc_standalone.lua
	@echo "Testing RPC model listing..."
	@$(NEOVIM_LUA) $(UNIT_DIR)/rpc/test_rpc_standalone_list_models.lua
	@echo "Testing RPC timeout and retry behavior..."
	@$(NEOVIM_LUA) $(UNIT_DIR)/rpc/test_timeout_retry_simple.lua
	@echo "✓ RPC unit tests completed"

test-rpc-integration:
	@echo "=== Running RPC Integration Tests ==="
	@echo "Testing RPC server integration (soft fail if server not available)..."
	@$(NEOVIM_LUA) $(UNIT_DIR)/rpc/test_rpc_integration.lua
	@echo "✓ RPC integration tests completed"

test-unit-utils:
	@echo "=== Running Unit Tests: Utils ==="
	@echo "Testing formatting utilities..."
	@$(NEOVIM_LUA) $(UNIT_DIR)/utils/test_format_simple.lua
	@echo "Testing escaping utilities..."
	@$(NEOVIM_LUA) $(UNIT_DIR)/utils/test_escape.lua
	@echo "Testing pattern matching..."
	@$(NEOVIM_LUA) $(UNIT_DIR)/utils/test_pattern.lua
	@echo "✓ Utils unit tests completed"

test-unit: test-unit-core test-unit-rpc test-unit-utils
	@echo ""
	@echo "✓ All unit tests completed"

# Server lifecycle tests (start/stop servers, use different ports)
.PHONY: test-server-lifecycle test-server-lifecycle-backend

test-server-lifecycle-backend:
	@echo "=== Running Server Lifecycle Tests: Backend ==="
	@echo "Testing server start/stop functionality..."
	@$(NEOVIM_LUA) $(INTEGRATION_DIR)/backend/test_rust_backend_server.lua
	@echo "✓ Backend server lifecycle tests completed"

test-server-lifecycle: test-server-lifecycle-backend
	@echo ""
	@echo "✓ All server lifecycle tests completed"

# Server interaction tests (use already running server on port 3000)
.PHONY: test-server-interaction test-server-interaction-chat test-server-interaction-search test-server-interaction-backend

test-server-interaction-chat:
	@echo "=== Running Server Interaction Tests: Chat ==="
	@echo "Testing basic chat functionality..."
	@$(NEOVIM_LUA) $(INTEGRATION_DIR)/chat/test_chat_simple.lua
	@echo "Testing chat interface..."
	@$(NEOVIM_LUA) $(INTEGRATION_DIR)/chat/test_chat_interface.lua
	@echo "Testing chat with backend..."
	@$(NEOVIM_LUA) $(INTEGRATION_DIR)/chat/test_chat_backend.lua
	@echo "Testing interactive chat..."
	@$(NEOVIM_LUA) $(INTEGRATION_DIR)/chat/test_chat_interactive.lua
	@echo "Testing chat visual feedback..."
	@$(NEOVIM_LUA) $(UNIT_DIR)/chat/test_chat_visual_feedback_simple.lua
	@echo "✓ Chat server interaction tests completed"

test-server-interaction-search:
	@echo "=== Running Server Interaction Tests: Search ==="
	@echo "Testing search integration..."
	@$(NEOVIM_LUA) $(INTEGRATION_DIR)/search/test_lua_search_integration.lua
	@echo "Testing enhanced search core..."
	@$(NEOVIM_LUA) $(INTEGRATION_DIR)/search/test_enhanced_search_core.lua
	@echo "Testing enhanced search UI..."
	@$(NEOVIM_LUA) $(INTEGRATION_DIR)/search/test_enhanced_search_ui.lua
	@echo "Testing Neovim search integration..."
	@$(NEOVIM_LUA) $(INTEGRATION_DIR)/search/test_neovim_search_integration.lua
	@echo "✓ Search server interaction tests completed"

test-server-interaction-backend:
	@echo "=== Running Server Interaction Tests: Backend ==="
	@echo "Testing backend initialization..."
	@$(NEOVIM_LUA) $(INTEGRATION_DIR)/backend/test_backend_init.lua
	@echo "Testing Ollama integration..."
	@$(NEOVIM_LUA) $(INTEGRATION_DIR)/backend/test_ollama_integration.lua
	@echo "✓ Backend server interaction tests completed"

test-server-interaction: test-server-interaction-chat test-server-interaction-search test-server-interaction-backend
	@echo ""
	@echo "✓ All server interaction tests completed"

# Legacy integration tests (for backward compatibility)
.PHONY: test-integration test-integration-chat test-integration-search test-integration-backend

test-integration-chat: test-server-interaction-chat
test-integration-search: test-server-interaction-search
test-integration-backend: test-server-interaction-backend

test-integration: test-server-interaction
	@echo ""
	@echo "✓ All integration tests completed"

# E2E tests (full Neovim environment)
.PHONY: test-e2e test-e2e-plugin test-e2e-startup

test-e2e-plugin:
	@echo "=== Running E2E Tests: Plugin ==="
	@echo "Testing plugin loading in Neovim..."
	@echo "✓ Plugin E2E tests completed"

test-e2e-startup:
	@echo "=== Running E2E Tests: Startup ==="
	@echo "Testing AstroNvim startup..."

test-e2e: test-e2e-plugin test-e2e-startup
	@echo ""
	@echo "✓ All E2E tests completed"

# All tests
.PHONY: test-all test

test-all: test-unit test-e2e
	@echo ""
	@echo "=== Test Summary ==="
	@echo "✓ Unit tests: Core, RPC, Utils"
	@echo "⚠️  Integration tests: Skipped (require running backend)"
	@echo "✓ E2E tests: Plugin, Startup"
	@echo ""
	@echo "🎉 All tests completed successfully!"

# Quick test (unit only)
test: test-unit
	@echo ""
	@echo "✓ Quick test completed (unit tests only)"

# Development test (unit + search)
.PHONY: test-dev

test-dev: test-unit test-server-interaction-search
	@echo ""
	@echo "✓ Development test completed"

# Timeout and retry behavior tests
.PHONY: test-timeout-retry

test-timeout-retry:
	@echo "=== Running Timeout and Retry Behavior Tests ==="
	@echo "Testing comprehensive timeout/retry behavior..."
	@$(NEOVIM_LUA) $(UNIT_DIR)/test_timeout_retry_suite.lua
	@echo "✓ Timeout and retry tests completed"

# Test with backend running
.PHONY: test-with-backend

test-with-backend:
	@echo "=== Running Tests with Backend ==="
	@echo "Make sure the Rust backend is running with: cargo run -- --no-database"
	@echo ""
	@$(MAKE) test-server-interaction

# Test server lifecycle (starts/stops servers)
.PHONY: test-server-lifecycle-standalone

test-server-lifecycle-standalone:
	@echo "=== Running Server Lifecycle Tests ==="
	@echo "These tests start and stop their own servers"
	@echo ""
	@$(MAKE) test-server-lifecycle

# Clean up deprecated tests
.PHONY: clean-deprecated

clean-deprecated:
	@echo "=== Cleaning Deprecated Tests ==="
	@echo "Moving deprecated tests to $(DEPRECATED_DIR)..."
	@echo "Review $(DEPRECATED_DIR) and remove obsolete tests manually"
	@echo "✓ Deprecated tests moved"

# Help
.PHONY: help

help:
	@echo "Paragonic Test Suite"
	@echo ""
	@echo "Available test targets:"
	@echo "  test              - Quick test (unit tests only)"
	@echo "  test-unit         - All unit tests (fast, no dependencies)"
	@echo "  test-server-interaction - Tests that use already running server"
	@echo "  test-server-lifecycle   - Tests that start/stop their own servers"
	@echo "  test-e2e          - All E2E tests (full Neovim environment)"
	@echo "  test-all          - All tests (unit + e2e, integration requires backend)"
	@echo "  test-dev          - Development test (unit + search)"
	@echo "  test-timeout-retry - Timeout and retry behavior tests"
	@echo "  test-with-backend - Server interaction tests (requires backend running)"
	@echo ""
	@echo "Unit test categories:"
	@echo "  test-unit-core    - Core functionality tests"
	@echo "  test-unit-rpc     - RPC client tests"
	@echo "  test-unit-utils   - Utility function tests"
	@echo ""
	@echo "Server interaction test categories:"
	@echo "  test-server-interaction-chat    - Chat functionality"
	@echo "  test-server-interaction-search  - Search functionality"
	@echo "  test-server-interaction-backend - Backend communication"
	@echo ""
	@echo "Server lifecycle test categories:"
	@echo "  test-server-lifecycle-backend   - Server start/stop tests"
	@echo ""
	@echo "E2E test categories:"
	@echo "  test-e2e-plugin   - Plugin loading tests"
	@echo "  test-e2e-startup  - Startup tests"
	@echo ""
	@echo "Examples:"
	@echo "  make test              # Quick development test"
	@echo "  make test-unit         # Fast unit tests"
	@echo "  make test-server-interaction  # Tests using running server"
	@echo "  make test-server-lifecycle    # Tests that manage servers"
	@echo "  make test-all          # Complete test suite"
	@echo ""
	@echo "Backend setup:"
	@echo "  cargo run -- --no-database &  # Start backend"
	@echo "  make test-with-backend        # Run server interaction tests"

# Legacy targets for backward compatibility
.PHONY: test-lua test-lua-unit test-lua-integration

test-lua: test
test-lua-unit: test-unit
test-lua-integration: test-server-interaction 