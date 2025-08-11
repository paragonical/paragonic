# API Specification

This is the API specification for the spec detailed in @.agent-os/specs/2025-08-11-mcp-streamable-http-refit/spec.md

> Created: 2025-08-11
> Version: 1.0.0

## Endpoints

### POST /mcp

**Purpose:** Send JSON-RPC messages to the MCP server
**Parameters:** 
- `Content-Type: application/json`
- `Accept: application/json, text/event-stream`
- `MCP-Protocol-Version: 2025-06-18` (required)
- `Mcp-Session-Id: <session-id>` (optional, for existing sessions)
- `Origin: <origin>` (required, validated against allowed origins)

**Request Body:** Single JSON-RPC request, notification, or response
```json
{
  "jsonrpc": "2.0",
  "method": "initialize",
  "params": {
    "protocolVersion": "2025-06-18",
    "capabilities": {},
    "clientInfo": {
      "name": "paragonic-client",
      "version": "1.0.0"
    }
  },
  "id": 1
}
```

**Response:**
- **For notifications/responses:** HTTP 202 Accepted (no body)
- **For requests with immediate response:** HTTP 200 with JSON-RPC response
- **For requests requiring streaming:** HTTP 200 with `Content-Type: text/event-stream`

**Errors:**
- `400 Bad Request` - Invalid JSON-RPC message or missing required headers
- `405 Method Not Allowed` - Server doesn't support the requested method
- `404 Not Found` - Invalid session ID (for requests with session ID)

### GET /mcp

**Purpose:** Initiate SSE stream for server-to-client communication
**Parameters:**
- `Accept: text/event-stream` (required)
- `MCP-Protocol-Version: 2025-06-18` (required)
- `Mcp-Session-Id: <session-id>` (optional, for existing sessions)
- `Last-Event-ID: <event-id>` (optional, for stream resumption)

**Response:** HTTP 200 with `Content-Type: text/event-stream`
**SSE Events:**
```text
event: message
id: event-123
data: {"jsonrpc":"2.0","method":"notifications/notify","params":{"message":"Hello"}}

event: message
id: event-124
data: {"jsonrpc":"2.0","result":{"capabilities":{}},"id":1}
```

**Errors:**
- `405 Method Not Allowed` - Server doesn't support SSE streams
- `404 Not Found` - Invalid session ID (for requests with session ID)

### DELETE /mcp

**Purpose:** Terminate an active session
**Parameters:**
- `MCP-Protocol-Version: 2025-06-18` (required)
- `Mcp-Session-Id: <session-id>` (required)

**Response:** HTTP 200 OK (session terminated)
**Errors:**
- `400 Bad Request` - Missing session ID
- `404 Not Found` - Session not found
- `405 Method Not Allowed` - Server doesn't allow session termination

## Controllers

### MCP Controller

**Purpose:** Handle all MCP protocol communication
**Business Logic:**
- Validate incoming JSON-RPC messages
- Route messages to appropriate handlers
- Manage session state and lifecycle
- Handle SSE stream creation and management
- Implement proper error handling and status codes

**Key Actions:**
- `handle_post_request()` - Process JSON-RPC messages via POST
- `handle_get_request()` - Initiate SSE streams
- `handle_delete_request()` - Terminate sessions
- `validate_headers()` - Check required headers and security
- `create_sse_stream()` - Set up Server-Sent Events stream
- `manage_session()` - Handle session creation, validation, and cleanup

### Session Manager

**Purpose:** Manage MCP session lifecycle
**Business Logic:**
- Generate unique session IDs
- Store session state and metadata
- Handle session validation and cleanup
- Implement session timeout and expiration

**Key Actions:**
- `create_session()` - Generate new session with unique ID
- `validate_session()` - Check session validity and permissions
- `update_session()` - Update session state and metadata
- `terminate_session()` - Clean up session resources
- `cleanup_expired_sessions()` - Remove expired sessions

### Stream Manager

**Purpose:** Handle SSE stream lifecycle and event management
**Business Logic:**
- Create and manage SSE streams
- Generate unique event IDs
- Handle stream resumption via Last-Event-ID
- Manage multiple concurrent streams per client

**Key Actions:**
- `create_stream()` - Initialize new SSE stream
- `send_event()` - Send JSON-RPC message via SSE
- `resume_stream()` - Resume stream from specific event ID
- `close_stream()` - Properly close SSE stream
- `generate_event_id()` - Create unique event identifiers

## Error Handling

### HTTP Status Codes
- `200 OK` - Successful request processing
- `202 Accepted` - Request accepted (notifications/responses)
- `400 Bad Request` - Invalid request format or missing headers
- `404 Not Found` - Resource not found (invalid session ID)
- `405 Method Not Allowed` - HTTP method not supported
- `500 Internal Server Error` - Server error during processing

### JSON-RPC Error Codes
- `-32600` - Invalid Request (malformed JSON-RPC)
- `-32601` - Method not found
- `-32602` - Invalid params
- `-32603` - Internal error
- `-32700` - Parse error
- `-32000` - Server error (custom)

### Error Response Format
```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32602,
    "message": "Invalid params",
    "data": {
      "details": "Missing required parameter 'method'"
    }
  },
  "id": 1
}
```

## Security Headers

### Required Headers
- `MCP-Protocol-Version` - Must be "2025-06-18"
- `Origin` - Must be validated against allowed origins
- `Accept` - Must include supported content types

### Optional Headers
- `Mcp-Session-Id` - For session management
- `Last-Event-ID` - For SSE stream resumption

### Security Validation
- Origin header validation to prevent DNS rebinding attacks
- Session ID validation and sanitization
- Content-Type validation for all requests
- Protocol version compatibility checking
