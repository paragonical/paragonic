# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-11-mcp-streamable-http-refit/spec.md

> Created: 2025-08-11
> Version: 1.0.0

## Technical Requirements

### HTTP Server Requirements
- **Single MCP Endpoint**: Must provide a single HTTP endpoint (e.g., `/mcp`) that supports both POST and GET methods
- **Content Type Handling**: Must accept `application/json` and `text/event-stream` in Accept headers
- **Protocol Version Header**: Must include `MCP-Protocol-Version: 2025-06-18` on all requests
- **Security**: Must validate Origin headers and bind to localhost for local development
- **Session Management**: Must support session IDs via `Mcp-Session-Id` header

### SSE Stream Requirements
- **Bidirectional Communication**: Support Server-Sent Events for server-to-client communication
- **Stream Resumability**: Implement event IDs for stream resumption after disconnection
- **Multiple Streams**: Support multiple concurrent SSE streams per client
- **Stream Lifecycle**: Proper stream initiation, maintenance, and cleanup

### Message Handling Requirements
- **JSON-RPC Compliance**: All messages must follow JSON-RPC 2.0 format
- **Request Processing**: Handle JSON-RPC requests, notifications, and responses
- **Error Handling**: Proper HTTP status codes and JSON-RPC error responses
- **Streaming Responses**: Support for streaming JSON-RPC responses via SSE

### Client Requirements
- **HTTP Client**: Replace TCP socket communication with HTTP requests
- **SSE Client**: Implement SSE client for receiving server messages
- **Session Persistence**: Maintain session state across reconnections
- **Error Recovery**: Graceful handling of network failures and reconnection

## Approach Options

**Option A:** Complete HTTP Server Rewrite (Selected)
- **Pros:**
  - Full compliance with MCP specification
  - Better scalability and multiple client support
  - Standard HTTP tooling and debugging
  - Future-proof for MCP ecosystem integration
- **Cons:**
  - Significant refactoring required
  - More complex implementation
  - Need to maintain backward compatibility

**Option B:** HTTP Wrapper Around Existing TCP Server
- **Pros:**
  - Minimal changes to existing code
  - Faster implementation
  - Lower risk of breaking existing functionality
- **Cons:**
  - Not fully compliant with MCP specification
  - Limited scalability
  - Technical debt and maintenance burden

**Option C:** Hybrid Approach with Gradual Migration
- **Pros:**
  - Risk mitigation through incremental changes
  - Ability to test and validate each component
  - Fallback to existing implementation if needed
- **Cons:**
  - Longer implementation timeline
  - More complex testing requirements
  - Potential for inconsistent behavior during transition

**Rationale:** Option A provides the best long-term solution by ensuring full MCP compliance and enabling seamless integration with the broader MCP ecosystem. The investment in proper HTTP server implementation will pay dividends in maintainability and interoperability.

## External Dependencies

### Rust Dependencies
- **axum** - Modern HTTP web framework for Rust
  - **Justification:** Provides excellent async HTTP server capabilities with built-in SSE support
  - **Version:** ^0.7.0
- **tower** - HTTP middleware and utilities
  - **Justification:** Provides middleware for CORS, authentication, and request/response handling
  - **Version:** ^0.4.0
- **tokio-stream** - Async stream utilities
  - **Justification:** Required for proper SSE stream implementation and management
  - **Version:** ^0.1.0

### Lua Dependencies
- **lua-http** - HTTP client library for Lua
  - **Justification:** Provides HTTP client capabilities for making requests to MCP servers
  - **Version:** Latest compatible with Neovim
- **lua-socket** - Socket library for SSE client implementation
  - **Justification:** Required for SSE client functionality and connection management
  - **Version:** Latest compatible with Neovim

## Implementation Architecture

### Server Architecture
```
HTTP Server (axum)
├── MCP Endpoint (/mcp)
│   ├── POST Handler (JSON-RPC requests)
│   ├── GET Handler (SSE stream initiation)
│   └── DELETE Handler (session termination)
├── Session Manager
│   ├── Session ID Generation
│   ├── Session State Storage
│   └── Session Cleanup
└── Stream Manager
    ├── SSE Stream Creation
    ├── Event ID Management
    └── Stream Lifecycle Control
```

### Client Architecture
```
Lua MCP Client
├── HTTP Client
│   ├── Request Builder
│   ├── Response Parser
│   └── Error Handler
├── SSE Client
│   ├── Stream Connection
│   ├── Event Parser
│   └── Reconnection Logic
└── Session Manager
    ├── Session ID Storage
    ├── State Persistence
    └── Cleanup Handler
```

## Security Considerations

### Origin Validation
- Validate `Origin` header on all incoming connections
- Prevent DNS rebinding attacks
- Reject requests from unauthorized origins

### Local Development Security
- Bind server to localhost (127.0.0.1) only
- Implement proper authentication for production deployments
- Use secure session ID generation

### Data Protection
- Validate all incoming JSON-RPC messages
- Sanitize session IDs and prevent injection attacks
- Implement proper error handling without information leakage

## Performance Considerations

### Connection Management
- Implement connection pooling for HTTP clients
- Use async/await for non-blocking operations
- Optimize SSE stream handling for multiple concurrent connections

### Memory Management
- Proper cleanup of SSE streams and sessions
- Efficient JSON serialization/deserialization
- Memory-efficient event ID management

### Scalability
- Support for multiple concurrent client connections
- Efficient session state management
- Proper resource cleanup to prevent memory leaks
