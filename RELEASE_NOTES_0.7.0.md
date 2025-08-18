# Paragonic v0.7.0 Release Notes

## ⚠️ IMPORTANT: Major Breaking Change - Not Expected to be Functional

**This release represents a major architectural change that converts the entire communication system from TCP-based JSON-RPC to HTTP-based Model Context Protocol (MCP). This is a foundational change that may break existing functionality and is intended for development/testing purposes only.**

## 🚨 Breaking Changes

### Complete Transport Layer Replacement
- **Removed**: All TCP-based JSON-RPC transport code
- **Removed**: `src/rpc.rs` - Legacy RPC server implementation
- **Removed**: `lua/paragonic/rpc.lua` - Legacy RPC client
- **Removed**: All RPC-related test files and integration tests
- **Added**: `src/http_server.rs` - New MCP HTTP server implementation
- **Added**: `lua/paragonic/mcp_http_transport.lua` - New MCP HTTP transport

### Client-Server Communication
- **Old**: Direct TCP socket connections on port 3000
- **New**: HTTP REST API on port 3000 with MCP protocol
- **Impact**: All existing client connections will fail until updated

### API Changes
- **Removed**: Direct RPC method calls (`rpc_client:method_name()`)
- **Added**: MCP HTTP transport with JSON-RPC over HTTP
- **Changed**: All method calls now go through `mcp.send_request()`

## 🔧 New Architecture

### MCP HTTP Transport
- **Protocol**: Model Context Protocol (MCP) over HTTP
- **Transport**: HTTP/1.1 with JSON-RPC 2.0 payloads
- **Features**: 
  - Connection pooling and keep-alive
  - Server-Sent Events (SSE) for streaming
  - Session management
  - Stream management

### Backend Shim Layer
- **File**: `lua/paragonic/backend.lua`
- **Purpose**: Provides RPC-like API compatibility
- **Function**: Routes calls through MCP HTTP transport
- **Methods**: `connect()`, `chat_completion()`, `list_models()`, etc.

### Security Enhancements
- **File**: `lua/paragonic/mcp_owasp_security.lua`
- **Features**:
  - SSRF protection with configurable localhost override
  - CORS validation
  - Rate limiting
  - Input sanitization
  - Security headers

## 📦 New Components

### HTTP Client (`lua/paragonic/http_client.lua`)
- Connection pooling with keep-alive
- Automatic retry logic
- Error handling and timeout management
- Request/response logging

### SSE Client (`lua/paragonic/sse_client.lua`)
- Server-Sent Events for real-time streaming
- Automatic reconnection
- Event parsing and handling
- Headless Neovim compatibility

### Performance Monitoring (`lua/paragonic/mcp_performance.lua`)
- Request timing and metrics
- Memory usage tracking
- Cache hit/miss statistics
- Performance alerts

## 🧪 Testing Infrastructure

### New Test Suites
- **HTTP Transport Tests**: `tests/unit/http/`
- **Load Testing**: Real and mock scenarios
- **Security Tests**: OWASP Top 10 compliance
- **Performance Tests**: Memory and resource monitoring
- **Integration Tests**: Headless Neovim validation

### Test Coverage
- **356 Rust tests** passing (10 ignored)
- **Lua unit tests** across all modules
- **E2E tests** for plugin and startup
- **Deployment tests** for configuration validation

## 🔄 Migration Guide

### For Users
1. **Backup**: Save any existing configuration
2. **Update**: Install v0.7.0
3. **Configure**: Set `MCP_ALLOW_LOCALHOST=1` for development
4. **Test**: Verify basic functionality
5. **Report**: Issues to maintainers

### For Developers
1. **Update**: All client code to use MCP transport
2. **Remove**: Direct RPC dependencies
3. **Test**: With new HTTP transport
4. **Document**: Any API changes

## 🚧 Known Issues

### Functionality
- **Not Production Ready**: This is a development release
- **Breaking Changes**: Existing integrations will fail
- **Limited Testing**: Real-world usage scenarios untested
- **Performance**: HTTP overhead vs direct TCP

### Compatibility
- **Neovim Version**: Requires recent Neovim with Lua support
- **Operating System**: Tested on macOS, Linux compatibility unknown
- **Dependencies**: Requires `curl` for HTTP requests
- **Network**: Requires localhost access on port 3000

## 🔮 Future Plans

### Short Term (v0.7.x)
- Stabilize MCP HTTP transport
- Fix compatibility issues
- Improve error handling
- Add comprehensive logging

### Medium Term (v0.8.x)
- Production hardening
- Performance optimization
- Security audit completion
- Documentation updates

### Long Term (v0.9.x)
- Feature parity with RPC transport
- Advanced MCP features
- Plugin ecosystem support
- Community adoption

## 📋 Technical Details

### MCP Protocol Version
- **Version**: 2025-06-18
- **Transport**: HTTP/1.1
- **Encoding**: JSON-RPC 2.0
- **Streaming**: Server-Sent Events

### Server Configuration
- **Host**: 127.0.0.1
- **Port**: 3000
- **Protocol**: HTTP
- **CORS**: Enabled for localhost

### Client Configuration
- **Base URL**: http://127.0.0.1:3000
- **Timeout**: 60 seconds
- **Retries**: 3 attempts
- **Pool Size**: 5 connections

## 🛠️ Development Notes

### Environment Variables
```bash
# Allow localhost connections (development only)
export MCP_ALLOW_LOCALHOST=1

# Enable debug logging
export RUST_LOG=info

# Use mock database for testing
export USE_MOCK_DATABASE=1
```

### Testing Commands
```bash
# Run all tests
just test-all

# Run Rust tests only
cargo test --lib

# Run Lua tests only
just test-unit

# Run MCP client validation
just test-mcp-client-validation
```

## 📚 Documentation

### New Documentation Files
- `docs/HTTP_TRANSPORT_DOCUMENTATION.md` - Transport architecture
- `docs/HTTP_TRANSPORT_API.md` - API reference
- `docs/MIGRATION_GUIDE.md` - Migration instructions
- `RELEASE_NOTES_HTTP_TRANSPORT.md` - Previous transport notes

### Updated Files
- `justfile` - Updated test targets
- `README.md` - Architecture overview
- `Cargo.toml` - Version bump to 0.7.0

## 🎯 Summary

This release represents a fundamental architectural change that modernizes the communication layer from TCP RPC to HTTP MCP. While this provides a more standard and extensible foundation, it comes with significant breaking changes and is not expected to be fully functional for production use.

**Recommendation**: Use this release for development and testing only. Wait for v0.7.x stabilization releases before considering production deployment.

---

**Version**: 0.7.0  
**Release Date**: August 13, 2025  
**Status**: Development Release  
**Compatibility**: Breaking Changes
