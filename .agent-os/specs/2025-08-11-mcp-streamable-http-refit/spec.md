# Spec Requirements Document

> Spec: MCP Streamable HTTP Refit
> Created: 2025-08-11
> Status: Planning

## Overview

Refit the current MCP implementation to use the correct Streamable HTTP transport protocol as specified in the MCP 2025-06-18 specification, replacing the current TCP-based JSON-RPC implementation with proper HTTP POST/GET endpoints and Server-Sent Events (SSE) for bidirectional communication.

## User Stories

### MCP Compliance Story

As a developer integrating with external AI agents, I want the Paragonic Neovim plugin to communicate using the standard MCP Streamable HTTP transport, so that it can seamlessly integrate with the broader MCP ecosystem and support multiple concurrent client connections.

**Detailed Workflow:**
1. External AI agents connect to the Paragonic MCP server via HTTP POST requests
2. The server responds with either immediate JSON responses or initiates SSE streams for streaming responses
3. The server can send notifications and requests to clients via SSE streams
4. Multiple clients can connect simultaneously without interference
5. Session management allows for stateful connections with proper cleanup

### Neovim Integration Story

As a Neovim user, I want the MCP functionality to work seamlessly within my editor environment, so that I can leverage external AI capabilities without disrupting my workflow.

**Detailed Workflow:**
1. Neovim plugin initializes MCP server with proper HTTP endpoints
2. Plugin maintains connection to external MCP servers using Streamable HTTP
3. All MCP resources and tools remain accessible through existing Neovim commands
4. Streaming responses are properly displayed in Neovim buffers
5. Connection failures are handled gracefully with automatic reconnection

## Spec Scope

1. **HTTP Server Implementation** - Replace TCP-based JSON-RPC server with HTTP server supporting POST/GET endpoints
2. **SSE Stream Management** - Implement Server-Sent Events for bidirectional communication and streaming responses
3. **Session Management** - Add proper session handling with unique session IDs and lifecycle management
4. **Protocol Compliance** - Ensure full compliance with MCP 2025-06-18 Streamable HTTP transport specification
5. **Backward Compatibility** - Maintain existing Lua client functionality while updating transport layer

## Out of Scope

- Changes to MCP message content or structure (only transport layer changes)
- Modifications to existing MCP resources or tools functionality
- Changes to Neovim plugin user interface or commands
- Database schema changes or data migration

## Expected Deliverable

1. HTTP-based MCP server that accepts POST requests and responds with JSON or SSE streams
2. Updated Lua client that communicates via HTTP instead of TCP sockets
3. Session management system with proper cleanup and reconnection handling
4. Full test suite validating MCP protocol compliance and transport functionality

## Spec Documentation

- Tasks: @.agent-os/specs/2025-08-11-mcp-streamable-http-refit/tasks.md
- Technical Specification: @.agent-os/specs/2025-08-11-mcp-streamable-http-refit/sub-specs/technical-spec.md
- API Specification: @.agent-os/specs/2025-08-11-mcp-streamable-http-refit/sub-specs/api-spec.md
- Tests Specification: @.agent-os/specs/2025-08-11-mcp-streamable-http-refit/sub-specs/tests.md
