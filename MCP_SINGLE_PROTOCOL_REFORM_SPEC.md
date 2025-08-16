# MCP Single Protocol Reform Specification

## Overview

This specification outlines the complete reform of the Paragonic system to use **only one protocol**: the MCP stdio transport. The current system has multiple transport layers (HTTP, TCP, custom RPC) which adds complexity and maintenance overhead. By standardizing on MCP stdio, we achieve simplicity, reliability, and full compliance with the MCP specification.

## Current State Analysis

### Current Architecture Problems
- **Multiple Transport Layers**: HTTP, TCP, custom RPC, and MCP HTTP transport
- **Complex Client Logic**: Transport detection, fallback mechanisms, adapter patterns
- **Server Complexity**: HTTP server, TCP server, multiple endpoints
- **Maintenance Overhead**: Multiple transport implementations to maintain
- **Protocol Inconsistency**: Different message formats across transports

### Current Transport Stack
1. **Custom TCP RPC** (`src/rpc.rs`) - Legacy, should be removed
2. **MCP HTTP Transport** (`lua/paragonic/mcp_http_transport.lua`) - Complex, HTTP-based
3. **HTTP Client** (`lua/paragonic/http_client.lua`) - HTTP-specific implementation
4. **SSE Client** (`lua/paragonic/sse_client.lua`) - Server-Sent Events complexity
5. **Transport Adapter** (`lua/paragonic/mcp_transport_adapter.lua`) - ✅ **REMOVED**

## Target Architecture

### Single Protocol: MCP stdio Transport

**Why stdio over HTTP?**
- **Simplicity**: No network configuration, ports, or connection management
- **Reliability**: Direct process communication, no network failures
- **Security**: No network exposure, local-only communication
- **Performance**: Minimal overhead, direct memory communication
- **MCP Compliance**: Full adherence to MCP specification
- **Cross-Platform**: Works consistently across all platforms

### Target Architecture
```
Neovim Client (Lua) ←→ MCP stdio Transport ←→ Rust Server (stdio)
```

## Phase 1: Rust Server stdio Implementation

### 1.1 Create MCP stdio Server Module

**File**: `src/mcp_stdio_server.rs`

```rust
use std::io::{self, BufRead, BufReader, Write};
use serde_json::{json, Value};
use tokio::sync::mpsc;
use uuid::Uuid;

pub struct McpStdioServer {
    server_info: ServerInfo,
    session_manager: Arc<SessionManager>,
    stream_manager: Arc<StreamManager>,
    ollama_client: Arc<OllamaClient>,
    pattern_registry: Arc<tokio::sync::RwLock<PatternRegistry>>,
}

impl McpStdioServer {
    pub fn new() -> Self {
        // Initialize components (same as HTTP server)
        Self {
            server_info: ServerInfo {
                name: "paragonic-mcp-server".to_string(),
                version: env!("CARGO_PKG_VERSION").to_string(),
                protocol_version: "2025-06-18".to_string(),
            },
            // ... other components
        }
    }

    pub async fn run(&self) -> Result<(), Box<dyn std::error::Error>> {
        let stdin = io::stdin();
        let mut stdout = io::stdout();
        let mut stderr = io::stderr();
        
        let reader = BufReader::new(stdin);
        
        // Write server info to stderr for debugging
        writeln!(stderr, "Paragonic MCP stdio server starting...")?;
        
        for line in reader.lines() {
            let line = line?;
            if line.trim().is_empty() {
                continue;
            }
            
            // Parse JSON-RPC message
            let message: Value = serde_json::from_str(&line)?;
            
            // Handle message
            let response = self.handle_message(message).await?;
            
            // Send response to stdout
            let response_line = serde_json::to_string(&response)?;
            writeln!(stdout, "{}", response_line)?;
            stdout.flush()?;
        }
        
        Ok(())
    }

    async fn handle_message(&self, message: Value) -> Result<Value, Box<dyn std::error::Error>> {
        // Implement MCP message handling
        // Convert existing HTTP server logic to stdio
        todo!("Implement MCP stdio message handling")
    }
}
```

### 1.2 Convert HTTP Server Logic to stdio

**Key Changes**:
- Remove HTTP-specific code (Axum, routing, headers)
- Convert HTTP handlers to stdio message handlers
- Implement JSON-RPC message parsing and response formatting
- Maintain all existing MCP tool implementations

**File**: `src/mcp_stdio_server.rs` (continued)

```rust
impl McpStdioServer {
    async fn handle_message(&self, message: Value) -> Result<Value, Box<dyn std::error::Error>> {
        // Extract JSON-RPC fields
        let jsonrpc = message.get("jsonrpc").and_then(|v| v.as_str());
        let id = message.get("id").cloned();
        let method = message.get("method").and_then(|v| v.as_str());
        let params = message.get("params").cloned();
        
        if jsonrpc != Some("2.0") {
            return Ok(json!({
                "jsonrpc": "2.0",
                "id": id,
                "error": {
                    "code": -32600,
                    "message": "Invalid Request"
                }
            }));
        }
        
        match method {
            Some("initialize") => self.handle_initialize(params).await,
            Some("initialized") => self.handle_initialized().await,
            Some("tools/list") => self.handle_tools_list().await,
            Some("tools/call") => self.handle_tools_call(params).await,
            Some("completion/complete") => self.handle_completion_complete(params).await,
            Some("streaming_chat_completion") => self.handle_streaming_chat_completion(params).await,
            _ => Ok(json!({
                "jsonrpc": "2.0",
                "id": id,
                "error": {
                    "code": -32601,
                    "message": "Method not found"
                }
            }))
        }
    }

    async fn handle_initialize(&self, params: Option<Value>) -> Result<Value, Box<dyn std::error::Error>> {
        // Create session
        let session_id = Uuid::new_v4().to_string();
        self.session_manager.create_session(&session_id).await;
        
        Ok(json!({
            "jsonrpc": "2.0",
            "id": 1,
            "result": {
                "protocolVersion": "2025-06-18",
                "capabilities": {
                    "tools": {},
                    "resources": {},
                    "notifications": {}
                },
                "serverInfo": {
                    "name": self.server_info.name,
                    "version": self.server_info.version
                }
            }
        }))
    }

    async fn handle_tools_call(&self, params: Option<Value>) -> Result<Value, Box<dyn std::error::Error>> {
        // Convert existing HTTP tool handlers to stdio
        // This will reuse all existing tool implementations
        todo!("Implement tools/call handling")
    }

    async fn handle_streaming_chat_completion(&self, params: Option<Value>) -> Result<Value, Box<dyn std::error::Error>> {
        // For stdio, we'll use progress notifications instead of SSE
        // This is simpler and more reliable
        todo!("Implement streaming chat completion with progress notifications")
    }
}
```

### 1.3 Update Main Server Entry Point

**File**: `src/main.rs`

```rust
use paragonic::mcp_stdio_server::McpStdioServer;

#[tokio::main]
async fn main() {
    // Initialize logging
    let log_level = env::var("RUST_LOG").unwrap_or_else(|_| "info".to_string());
    let env_filter = EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| EnvFilter::new(log_level.clone()));

    fmt()
        .with_env_filter(env_filter)
        .with_target(false)
        .with_thread_ids(true)
        .with_thread_names(true)
        .with_file(true)
        .with_line_number(true)
        .init();

    tracing::info!("Paragonic MCP stdio server starting...");

    // Parse command line arguments for special commands
    let args: Vec<String> = env::args().collect();
    
    // Handle special commands (demonstrate-iragl, index-file, search)
    if args.len() > 1 {
        match args[1].as_str() {
            "demonstrate-iragl" => {
                // ... existing special command handling
                return;
            }
            "index-file" => {
                // ... existing special command handling
                return;
            }
            "search" => {
                // ... existing special command handling
                return;
            }
            "--help" | "-h" => {
                println!("Paragonic - MCP stdio Server");
                println!();
                println!("Usage:");
                println!("  paragonic                    - Start the MCP stdio server");
                println!("  paragonic demonstrate-iragl  - Demonstrate IRAGL capabilities");
                println!("  paragonic index-file <path>  - Index a file for IRAGL");
                println!("  paragonic search <query>     - Search the IRAGL index");
                println!("  paragonic --help             - Show this help message");
                return;
            }
            _ => {
                // Continue with normal server startup
            }
        }
    }

    // Initialize the backend (same as before)
    if let Err(e) = initialize().await {
        eprintln!("Failed to initialize Paragonic backend: {e}");
        process::exit(1);
    }
    println!("Paragonic backend initialized successfully");

    // Start MCP stdio server
    let server = McpStdioServer::new();
    
    if let Err(e) = server.run().await {
        tracing::error!("MCP stdio server failed: {}", e);
        process::exit(1);
    }
}
```

### 1.4 Update Library Exports

**File**: `src/lib.rs`

```rust
// Remove HTTP server exports
// pub async fn start_http_server(addr: &str) -> ParagonicResult<()> { ... }

// Add stdio server module
pub mod mcp_stdio_server;

// Export stdio server for testing
pub use mcp_stdio_server::McpStdioServer;
```

## Phase 2: Neovim Client stdio Implementation

### 2.1 Create MCP stdio Client

**File**: `lua/paragonic/mcp_stdio_client.lua`

```lua
-- MCP stdio Transport for Model Context Protocol
--
-- This module provides a complete MCP stdio transport implementation,
-- following the MCP stdio transport specification.
-- 
-- Key principles:
-- 1. Launch server as subprocess
-- 2. Communicate via stdin/stdout
-- 3. Messages delimited by newlines
-- 4. No embedded newlines in messages

local mcp_stdio_client = {}

-- Check if we're in a Neovim environment
local is_neovim = _G.vim ~= nil

-- Use vim.json if available, otherwise use a simple JSON library
local json
if is_neovim then
    json = vim.json
else
    -- Simple JSON fallback for standalone Lua
    json = {
        decode = function(str)
            -- Very basic JSON decoder for testing
            if str:match("^%s*{%s*$") then
                return {}
            end
            return nil
        end,
        encode = function(obj)
            -- Very basic JSON encoder for testing
            if type(obj) == "table" then
                return "{}"
            end
            return tostring(obj)
        end
    }
end

-- MCP stdio transport state
local transport_state = {
    server_process = nil,
    server_path = nil,
    is_initialized = false,
    session_id = nil,
    callbacks = {},
    message_id_counter = 0,
    -- Track active streaming requests
    active_streams = {},
}

-- MCP stdio transport errors
local MCPStdioTransportError = {
    NOT_INITIALIZED = "not_initialized",
    INITIALIZATION_FAILED = "initialization_failed",
    PROCESS_FAILED = "process_failed",
    INVALID_MESSAGE = "invalid_message",
    TIMEOUT = "timeout",
    PROTOCOL_ERROR = "protocol_error",
}

-- Initialize MCP stdio transport
function mcp_stdio_client.init(config)
    config = config or {}
    
    -- Initialize transport state
    transport_state = {
        server_process = nil,
        server_path = config.server_path or "paragonic",
        is_initialized = false,
        session_id = nil,
        callbacks = {},
        message_id_counter = 0,
        active_streams = {},
    }
    
    transport_state.is_initialized = true
    return true
end

-- Launch server process
function mcp_stdio_client.launch_server()
    if not transport_state.is_initialized then
        return false, MCPStdioTransportError.NOT_INITIALIZED
    end
    
    if transport_state.server_process then
        return true -- Already running
    end
    
    -- Launch server process
    local process = vim.loop.spawn(transport_state.server_path, {
        args = {},
        stdio = { vim.loop.constants.STDIO_PIPE, vim.loop.constants.STDIO_PIPE, vim.loop.constants.STDIO_PIPE }
    }, function(code, signal)
        -- Handle process exit
        transport_state.server_process = nil
        if transport_state.callbacks.on_server_exit then
            transport_state.callbacks.on_server_exit(code, signal)
        end
    end)
    
    if not process then
        return false, "Failed to launch server process"
    end
    
    transport_state.server_process = process
    
    -- Set up stdout reader
    vim.loop.read_start(process.stdout, function(err, data)
        if err then
            if transport_state.callbacks.on_error then
                transport_state.callbacks.on_error("stdout read error: " .. err)
            end
            return
        end
        
        if data then
            -- Parse JSON-RPC messages from stdout
            local lines = vim.split(data, "\n")
            for _, line in ipairs(lines) do
                if line and line:match("%S") then -- Non-empty line
                    local success, message = pcall(json.decode, line)
                    if success then
                        mcp_stdio_client._handle_server_message(message)
                    else
                        if transport_state.callbacks.on_error then
                            transport_state.callbacks.on_error("Failed to parse server message: " .. line)
                        end
                    end
                end
            end
        end
    end)
    
    -- Set up stderr reader for logging
    vim.loop.read_start(process.stderr, function(err, data)
        if err then
            return
        end
        
        if data and transport_state.callbacks.on_log then
            transport_state.callbacks.on_log(data)
        end
    end)
    
    return true
end

-- Send message to server
function mcp_stdio_client.send_message(message)
    if not transport_state.server_process then
        return false, "Server process not running"
    end
    
    -- Ensure message has an ID
    if not message.id then
        message.id = mcp_stdio_client.generate_message_id()
    end
    
    -- Encode message to JSON
    local message_json = json.encode(message)
    
    -- Send to server stdin
    vim.loop.write(transport_state.server_process.stdin, message_json .. "\n", function(err)
        if err and transport_state.callbacks.on_error then
            transport_state.callbacks.on_error("Failed to send message: " .. err)
        end
    end)
    
    return true
end

-- Handle server messages
function mcp_stdio_client._handle_server_message(message)
    -- Handle different message types
    if message.method then
        -- Server request or notification
        if transport_state.callbacks.on_server_request then
            transport_state.callbacks.on_server_request(message)
        end
    elseif message.result then
        -- Server response
        if transport_state.callbacks.on_response then
            transport_state.callbacks.on_response(message)
        end
    elseif message.error then
        -- Server error
        if transport_state.callbacks.on_error then
            transport_state.callbacks.on_error("Server error: " .. (message.error.message or "unknown error"))
        end
    end
end

-- Generate unique message ID
function mcp_stdio_client.generate_message_id()
    transport_state.message_id_counter = transport_state.message_id_counter + 1
    return transport_state.message_id_counter
end

-- Set callbacks
function mcp_stdio_client.set_callbacks(callbacks)
    transport_state.callbacks = callbacks or {}
end

-- Initialize MCP session
function mcp_stdio_client.initialize_session(client_info)
    if not transport_state.is_initialized then
        return false, MCPStdioTransportError.NOT_INITIALIZED
    end
    
    -- Launch server if not running
    local launch_success, launch_err = mcp_stdio_client.launch_server()
    if not launch_success then
        return false, launch_err
    end
    
    -- Send initialize request
    local init_request = {
        jsonrpc = "2.0",
        id = mcp_stdio_client.generate_message_id(),
        method = "initialize",
        params = {
            protocolVersion = "2025-06-18",
            capabilities = client_info.capabilities or {},
            clientInfo = {
                name = client_info.name or "paragonic-client",
                version = client_info.version or "1.0.0",
            },
        },
    }
    
    -- Send and wait for response
    local response = mcp_stdio_client.send_request(init_request)
    if not response then
        return false, "Initialization request failed"
    end
    
    -- Send initialized notification
    local initialized_notification = {
        jsonrpc = "2.0",
        method = "initialized",
        params = {},
    }
    
    local success, err = mcp_stdio_client.send_notification(initialized_notification)
    if not success then
        return false, err or "Failed to send initialized notification"
    end
    
    return true
end

-- Send request and wait for response
function mcp_stdio_client.send_request(request)
    -- For stdio, we need to implement synchronous request/response
    -- This is more complex than HTTP but more reliable
    todo!("Implement synchronous request/response for stdio")
end

-- Send notification (fire and forget)
function mcp_stdio_client.send_notification(notification)
    return mcp_stdio_client.send_message(notification)
end

-- Cleanup
function mcp_stdio_client.cleanup()
    if transport_state.server_process then
        vim.loop.kill(transport_state.server_process.pid, vim.loop.constants.SIGTERM)
        transport_state.server_process = nil
    end
end

-- Check if ready
function mcp_stdio_client.is_ready()
    return transport_state.is_initialized and transport_state.server_process ~= nil
end

return mcp_stdio_client
```

### 2.2 Update Backend to Use stdio Client

**File**: `lua/paragonic/backend.lua`

```lua
--[[
Paragonic Backend Module
Handles MCP stdio client initialization and backend management
--]]

local M = {}

-- MCP-backed client instance (shim that exposes the old RPC-like API)
M._rpc_client = nil

-- Create MCP client shim that matches the existing RPC client's methods
local function create_mcp_client()
    local debug = require("paragonic.debug")
    local config = require("paragonic.config")
    local mcp = require("paragonic.mcp_stdio_client")

    local client = {}

    function client:connect()
        local server_path = config.get and config.get("server_path") or "paragonic"
        server_path = server_path or "paragonic"

        debug.debug_print("🔧 MCP stdio connect(): server_path=" .. tostring(server_path), "debug")

        local ok, err = mcp.init({
            server_path = server_path,
        })
        if not ok then
            debug.debug_print("❌ MCP stdio init failed: " .. tostring(err), "error")
            return false, err
        end

        -- Set up MCP callbacks for streaming
        mcp.set_callbacks({
            on_streaming_chunk = function(request_id, chunk)
                debug.debug_print("📥 Received streaming chunk for request " .. request_id .. ": " .. (chunk.chunk or "no content"), "debug")
                
                -- Store the chunk for the chat system to retrieve
                if not client.streaming_chunks then
                    client.streaming_chunks = {}
                end
                table.insert(client.streaming_chunks, chunk)
                debug.debug_print("📥 Total chunks stored: " .. #client.streaming_chunks, "debug")
            end,
            on_streaming_complete = function(request_id, chunks, final_response)
                debug.debug_print("✅ Streaming complete for request " .. request_id, "success")
                debug.debug_print("📊 Total chunks received: " .. #chunks, "debug")
                
                -- Store final response if provided
                if final_response then
                    client.final_response = final_response
                end
                
                -- Mark streaming as complete
                client.is_streaming = false
            end,
            on_streaming_error = function(request_id, error)
                debug.debug_print("❌ Streaming error for request " .. request_id .. ": " .. (error or "unknown error"), "error")
                client.is_streaming = false
                client.streaming_error = error
            end,
            on_log = function(message)
                debug.debug_print("📝 Server log: " .. message, "debug")
            end,
            on_error = function(error)
                debug.debug_print("❌ Server error: " .. error, "error")
            end,
        })

        local ok2, err2 = mcp.initialize_session({
            name = "paragonic.nvim",
            version = "1.0.0",
            capabilities = { tools = {}, resources = {}, notifications = {} },
        })
        if not ok2 then
            debug.debug_print("❌ MCP stdio initialize_session failed: " .. tostring(err2), "error")
            return false, err2
        end

        debug.debug_print("✅ MCP stdio connected and session initialized", "success")
        
        return true
    end

    -- ... rest of client methods remain the same, just use mcp.send_request instead of HTTP calls

    return client
end

-- ... rest of backend module remains the same
```

## Phase 3: Remove Legacy Transport Code

### 3.1 Remove HTTP Transport Files

**Files to Delete**:
- `lua/paragonic/mcp_http_transport.lua`
- `lua/paragonic/http_client.lua`
- `lua/paragonic/sse_client.lua`
- `lua/paragonic/mcp_transport_adapter.lua` - ✅ **REMOVED**
- `src/http_server.rs`

### 3.2 Remove TCP Transport Files

**Files to Delete**:
- `src/rpc.rs` (if still exists)
- Any TCP-specific client code

### 3.3 Update Configuration

**File**: `lua/paragonic/config.lua`

```lua
-- Remove HTTP/TCP transport configuration
-- Add stdio transport configuration
local DEFAULT_CONFIG = {
    server_path = "paragonic", -- Path to server binary
    -- ... other configuration
}
```

## Phase 4: Testing and Validation

### 4.1 Unit Tests

**File**: `tests/unit/mcp/test_stdio_transport.lua`

```lua
-- Test MCP stdio transport functionality
local mcp = require("paragonic.mcp_stdio_client")

describe("MCP stdio transport", function()
    it("should initialize correctly", function()
        local success, err = mcp.init({
            server_path = "paragonic"
        })
        assert.is_true(success)
        assert.is_nil(err)
    end)

    it("should launch server process", function()
        local success, err = mcp.launch_server()
        assert.is_true(success)
        assert.is_nil(err)
    end)

    it("should handle initialization", function()
        local success, err = mcp.initialize_session({
            name = "test-client",
            version = "1.0.0",
            capabilities = {}
        })
        assert.is_true(success)
        assert.is_nil(err)
    end)
end)
```

### 4.2 Integration Tests

**File**: `tests/integration/test_stdio_integration.lua`

```lua
-- Test full stdio integration
local backend = require("paragonic.backend")

describe("stdio integration", function()
    it("should connect to server", function()
        local success, err = backend.connect()
        assert.is_true(success)
        assert.is_nil(err)
    end)

    it("should perform chat completion", function()
        local response, err = backend._get_rpc_client():chat_completion("test-model", "hello")
        assert.is_not_nil(response)
        assert.is_nil(err)
    end)
end)
```

## Phase 5: Documentation Updates

### 5.1 Update README

**File**: `README.md`

```markdown
# Paragonic - MCP stdio Server

Paragonic is an advanced knowledge management system that uses the Model Context Protocol (MCP) with stdio transport for reliable, local communication.

## Architecture

Paragonic uses a single, standardized protocol:
- **Neovim Client**: Lua-based MCP stdio client
- **Rust Server**: MCP stdio server with full tool implementation
- **Transport**: MCP stdio (standard input/output)

## Installation

1. Install the Rust server: `cargo install paragonic`
2. Install the Neovim plugin
3. Configure the server path in your Neovim config

## Usage

The system automatically launches the server process and communicates via stdio, providing:
- Chat completion with AI models
- Knowledge management and search
- Pattern execution and learning
- File operations and project management

## Benefits of stdio Transport

- **Simplicity**: No network configuration required
- **Reliability**: Direct process communication
- **Security**: Local-only, no network exposure
- **Performance**: Minimal overhead
- **MCP Compliance**: Full adherence to MCP specification
```

### 5.2 Update Configuration Documentation

**File**: `docs/CONFIGURATION.md`

```markdown
# Configuration

## Server Configuration

### Server Path
Set the path to the Paragonic server binary:

```lua
require("paragonic").setup({
    server_path = "paragonic" -- or "/path/to/paragonic"
})
```

## Transport

Paragonic uses MCP stdio transport exclusively, which requires no network configuration.
```

## Implementation Timeline

### Week 1: Rust Server stdio Implementation
- [ ] Create `src/mcp_stdio_server.rs`
- [ ] Implement basic stdio message handling
- [ ] Convert HTTP server logic to stdio
- [ ] Update `src/main.rs` to use stdio server
- [ ] Test server startup and basic communication

### Week 2: Neovim Client stdio Implementation
- [ ] Create `lua/paragonic/mcp_stdio_client.lua`
- [ ] Implement process spawning and communication
- [ ] Update `lua/paragonic/backend.lua` to use stdio client
- [ ] Test client-server communication

### Week 3: Legacy Code Removal
- [ ] Remove HTTP transport files
- [ ] Remove TCP transport files
- [ ] Update configuration system
- [ ] Clean up unused dependencies

### Week 4: Testing and Documentation
- [ ] Write comprehensive unit tests
- [ ] Write integration tests
- [ ] Update documentation
- [ ] Performance testing and optimization

## Success Criteria

1. **Single Protocol**: Only MCP stdio transport is used
2. **Full Functionality**: All existing features work through stdio
3. **Reliability**: No network-related failures
4. **Performance**: Comparable or better performance than HTTP
5. **Simplicity**: Reduced codebase complexity
6. **MCP Compliance**: Full adherence to MCP specification

## Risk Mitigation

1. **Process Management**: Robust process spawning and cleanup
2. **Error Handling**: Comprehensive error handling for stdio communication
3. **Testing**: Extensive testing of stdio transport
4. **Fallback**: Graceful degradation if server process fails
5. **Documentation**: Clear documentation for troubleshooting

## Conclusion

This reform will significantly simplify the Paragonic architecture while improving reliability and maintainability. By standardizing on MCP stdio transport, we eliminate network complexity, reduce attack surface, and achieve full MCP compliance. The implementation will be more robust, easier to debug, and simpler to deploy across different environments.
