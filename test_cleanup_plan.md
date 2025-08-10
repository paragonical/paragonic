# Test File Cleanup Plan

## Current State
- **154 test files** in root directory
- Many duplicates and obsolete tests
- Poor organization
- Inconsistent naming

## New Structure
```
tests/
├── unit/           # Unit tests (no external dependencies)
│   ├── core/       # Core functionality tests
│   ├── rpc/        # RPC client tests
│   └── utils/      # Utility function tests
├── integration/    # Integration tests (with backend)
│   ├── chat/       # Chat functionality
│   ├── search/     # Search functionality
│   └── backend/    # Backend communication
├── e2e/           # End-to-end tests (full Neovim)
└── deprecated/    # Old tests to be removed
```

## Essential Tests to Keep

### Unit Tests (tests/unit/)
#### Core (tests/unit/core/)
- `test_simple.lua` - Basic functionality
- `test_json_parsing.lua` - JSON handling
- `test_initialization_unit.lua` - Initialization tests
- `test_persistent_storage.lua` - Storage functionality
- `test_search_functions.lua` - Search core functions
- `test_search_history.lua` - Search history

#### RPC (tests/unit/rpc/)
- `test_rpc_simple.lua` - Basic RPC functionality
- `test_rpc_json.lua` - RPC JSON handling
- `test_rpc_standalone.lua` - Standalone RPC client
- `test_rpc_standalone_connection.lua` - Connection tests
- `test_rpc_standalone_list_models.lua` - Model listing

#### Utils (tests/unit/utils/)
- `test_format_simple.lua` - Formatting utilities
- `test_escape.lua` - Escaping utilities
- `test_pattern.lua` - Pattern matching

### Integration Tests (tests/integration/)
#### Chat (tests/integration/chat/)
- `test_chat_simple.lua` - Basic chat functionality
- `test_chat_interface.lua` - Chat interface
- `test_chat_backend.lua` - Chat with backend
- `test_chat_interactive.lua` - Interactive chat

#### Search (tests/integration/search/)
- `test_lua_search_integration.lua` - Search integration
- `test_enhanced_search_core.lua` - Enhanced search
- `test_enhanced_search_ui.lua` - Search UI
- `test_neovim_search_integration.lua` - Neovim search

#### Backend (tests/integration/backend/)
- `test_backend_init.lua` - Backend initialization
- `test_rust_backend_server.lua` - Rust backend
- `test_ollama_integration.lua` - Ollama integration

### E2E Tests (tests/e2e/)
- `test_plugin_loading.lua` - Plugin loading in Neovim
- `test_astronvim_startup.lua` - AstroNvim startup
- `test_real_filesystem_operations_nvim.lua` - Real filesystem ops

## Tests to Deprecate (tests/deprecated/)

### Bridge Tests (Obsolete - we removed the bridge)
- `test_bridge_*.lua` (all bridge-related tests)

### Duplicate/Redundant Tests
- `test_chat_debug_*.lua` (multiple debug variants)
- `test_chat_response_*.lua` (multiple response variants)
- `test_nvim_debug*.lua` (multiple debug variants)
- `test_rpc_debug*.lua` (multiple debug variants)

### Obsolete/Experimental Tests
- `test_external_script.lua` (uses system() calls)
- `test_timeout_*.lua` (timeout workarounds)
- `test_installation.lua` (installation tests)
- `test_startup_performance.lua` (performance tests)

### Debug/Development Tests
- `test_*_debug*.lua` (all debug variants)
- `test_*_simple*.lua` (simple variants of complex tests)

## Migration Steps

1. **Create new directory structure** ✅
2. **Move essential tests** to appropriate directories
3. **Move deprecated tests** to deprecated directory
4. **Update Makefile** to use new structure
5. **Remove obsolete tests** after verification
6. **Update documentation** to reflect new structure

## New Makefile Targets

```makefile
# Unit tests (fast, no dependencies)
test-unit: test-unit-core test-unit-rpc test-unit-utils

# Integration tests (requires backend)
test-integration: test-integration-chat test-integration-search test-integration-backend

# E2E tests (full Neovim environment)
test-e2e: test-e2e-plugin test-e2e-startup

# All tests
test-all: test-unit test-integration test-e2e

# Quick test (unit only)
test: test-unit
```

## Benefits

1. **Reduced complexity** - From 154 to ~30 essential tests
2. **Better organization** - Clear separation of concerns
3. **Faster testing** - Unit tests run quickly
4. **Easier maintenance** - Clear structure
5. **Better CI/CD** - Can run different test types separately 