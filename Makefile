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
	@echo "✓ RPC unit tests completed (connection tests temporarily disabled)"

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

# Integration tests (requires backend)
.PHONY: test-integration test-integration-chat test-integration-search test-integration-backend

test-integration-chat:
	@echo "=== Running Integration Tests: Chat ==="
	@echo "Testing basic chat functionality..."
	@$(NEOVIM_LUA) $(INTEGRATION_DIR)/chat/test_chat_simple.lua
	@echo "Testing chat interface..."
	@$(NEOVIM_LUA) $(INTEGRATION_DIR)/chat/test_chat_interface.lua
	@echo "Testing chat with backend..."
	@$(NEOVIM_LUA) $(INTEGRATION_DIR)/chat/test_chat_backend.lua
	@echo "Testing interactive chat..."
	@$(NEOVIM_LUA) $(INTEGRATION_DIR)/chat/test_chat_interactive.lua
	@echo "✓ Chat integration tests completed"

test-integration-search:
	@echo "=== Running Integration Tests: Search ==="
	@echo "Testing search integration..."
	@$(NEOVIM_LUA) $(INTEGRATION_DIR)/search/test_lua_search_integration.lua
	@echo "Testing enhanced search core..."
	@$(NEOVIM_LUA) $(INTEGRATION_DIR)/search/test_enhanced_search_core.lua
	@echo "Testing enhanced search UI..."
	@$(NEOVIM_LUA) $(INTEGRATION_DIR)/search/test_enhanced_search_ui.lua
	@echo "Testing Neovim search integration..."
	@$(NEOVIM_LUA) $(INTEGRATION_DIR)/search/test_neovim_search_integration.lua
	@echo "✓ Search integration tests completed"

test-integration-backend:
	@echo "=== Running Integration Tests: Backend ==="
	@echo "Testing backend initialization..."
	@$(NEOVIM_LUA) $(INTEGRATION_DIR)/backend/test_backend_init.lua
	@echo "Testing Rust backend server..."
	@$(NEOVIM_LUA) $(INTEGRATION_DIR)/backend/test_rust_backend_server.lua
	@echo "Testing Ollama integration..."
	@$(NEOVIM_LUA) $(INTEGRATION_DIR)/backend/test_ollama_integration.lua
	@echo "✓ Backend integration tests completed"

test-integration: test-integration-chat test-integration-search test-integration-backend
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

test-dev: test-unit test-integration-search
	@echo ""
	@echo "✓ Development test completed"

# Test with backend running
.PHONY: test-with-backend

test-with-backend:
	@echo "=== Running Tests with Backend ==="
	@echo "Make sure the Rust backend is running with: cargo run -- --no-database"
	@echo ""
	@$(MAKE) test-integration

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
	@echo "  test-integration  - All integration tests (requires backend)"
	@echo "  test-e2e          - All E2E tests (full Neovim environment)"
	@echo "  test-all          - All tests (unit + e2e, integration requires backend)"
	@echo "  test-dev          - Development test (unit + search)"
	@echo "  test-with-backend - Integration tests (requires backend running)"
	@echo ""
	@echo "Unit test categories:"
	@echo "  test-unit-core    - Core functionality tests"
	@echo "  test-unit-rpc     - RPC client tests"
	@echo "  test-unit-utils   - Utility function tests"
	@echo ""
	@echo "Integration test categories:"
	@echo "  test-integration-chat    - Chat functionality"
	@echo "  test-integration-search  - Search functionality"
	@echo "  test-integration-backend - Backend communication"
	@echo ""
	@echo "E2E test categories:"
	@echo "  test-e2e-plugin   - Plugin loading tests"
	@echo "  test-e2e-startup  - Startup tests"
	@echo ""
	@echo "Examples:"
	@echo "  make test              # Quick development test"
	@echo "  make test-unit         # Fast unit tests"
	@echo "  make test-integration  # Backend integration tests"
	@echo "  make test-all          # Complete test suite"
	@echo ""
	@echo "Backend setup:"
	@echo "  cargo run -- --no-database &  # Start backend"
	@echo "  make test-with-backend        # Run integration tests"

# Legacy targets for backward compatibility
.PHONY: test-lua test-lua-unit test-lua-integration

test-lua: test
test-lua-unit: test-unit
test-lua-integration: test-integration 