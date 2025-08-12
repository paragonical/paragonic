# MCP Transport Conversion Plan

## Overview
Convert the entire Paragonic system from custom TCP-based RPC to standard MCP HTTP transport, making MCP the primary and only transport protocol.

## Current State Analysis

### Current Architecture
- **Neovim Client**: Custom TCP RPC client (`lua/paragonic/rpc.lua`)
- **Rust Server**: Custom JSON-RPC server (`src/rpc.rs`)
- **Communication**: Direct TCP sockets with custom protocol
- **MCP**: Separate implementation not integrated with main functionality

### Target Architecture
- **Neovim Client**: MCP HTTP transport client (`lua/paragonic/mcp_http_transport.lua`)
- **Rust Server**: MCP HTTP server (`src/http_server.rs`)
- **Communication**: Standard MCP HTTP transport with Server-Sent Events
- **Integration**: All functionality through MCP protocol

## Phase 1: Rust Server Conversion

### 1.1 Replace RPC Server with HTTP Server

**File**: `src/main.rs`
**Changes**:
```rust
// Remove this line:
if let Err(e) = start_rpc_server(&server_addr) {

// Replace with:
if let Err(e) = start_http_server(&server_addr).await {
```

**File**: `src/lib.rs`
**Changes**:
```rust
// Remove this function:
pub fn start_rpc_server(addr: &str) -> ParagonicResult<()> {

// Add this function:
pub async fn start_http_server(addr: &str) -> ParagonicResult<()> {
    tracing::info!("Starting MCP HTTP server on {}", addr);
    
    let server = http_server::McpHttpServer::new();
    let app = server.create_router();
    
    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;
    
    Ok(())
}
```

### 1.2 Convert RPC Methods to MCP Tools

**File**: `src/http_server.rs` (expand existing)
**RPC Methods to Convert to MCP Tools**:

#### Core Chat & AI Functions
- `handle_chat_completion` → `mcp_tool_chat_completion`
- `handle_formatted_chat_completion` → `mcp_tool_formatted_chat_completion`
- `handle_agent_chat_completion` → `mcp_tool_agent_chat_completion`
- `execute_enhanced_tool_calling` → `mcp_tool_enhanced_tool_calling`
- `handle_streaming_chat_completion` → `mcp_tool_streaming_chat_completion`

#### File Operations
- `handle_read_file` → `mcp_tool_read_file`
- `handle_write_file` → `mcp_tool_write_file`
- `handle_list_files` → `mcp_tool_list_files`

#### Model Management
- `handle_list_models` → `mcp_tool_list_models`
- `handle_model_info` → `mcp_tool_model_info`
- `handle_generate_embedding` → `mcp_tool_generate_embedding`

#### Project Management
- `handle_create_project` → `mcp_tool_create_project`
- `handle_get_project` → `mcp_tool_get_project`
- `handle_list_projects` → `mcp_tool_list_projects`
- `handle_update_project` → `mcp_tool_update_project`
- `handle_delete_project` → `mcp_tool_delete_project`

#### Goal Management
- `handle_create_goal` → `mcp_tool_create_goal`
- `handle_get_goal` → `mcp_tool_get_goal`
- `handle_list_goals` → `mcp_tool_list_goals`
- `handle_update_goal` → `mcp_tool_update_goal`
- `handle_delete_goal` → `mcp_tool_delete_goal`

#### Task Management
- `handle_create_task` → `mcp_tool_create_task`
- `handle_get_task` → `mcp_tool_get_task`
- `handle_list_tasks` → `mcp_tool_list_tasks`
- `handle_update_task` → `mcp_tool_update_task`
- `handle_delete_task` → `mcp_tool_delete_task`

#### Search & Knowledge Management
- `handle_search_embeddings` → `mcp_tool_search_embeddings`
- `handle_find_similar_content` → `mcp_tool_find_similar_content`
- `handle_iragl_search` → `mcp_tool_iragl_search`
- `handle_hybrid_search` → `mcp_tool_hybrid_search`
- `handle_content_association` → `mcp_tool_content_association`
- `handle_ingest_knowledge_stream` → `mcp_tool_ingest_knowledge_stream`

#### Agent Management
- `handle_create_agent` → `mcp_tool_create_agent`
- `handle_delete_agent` → `mcp_tool_delete_agent`
- `handle_create_conversation` → `mcp_tool_create_conversation`
- `handle_get_conversation` → `mcp_tool_get_conversation`

#### Pattern Management
- `handle_list_patterns` → `mcp_tool_list_patterns`
- `handle_get_pattern` → `mcp_tool_get_pattern`
- `handle_execute_pattern` → `mcp_tool_execute_pattern`
- `handle_get_pattern_executions` → `mcp_tool_get_pattern_executions`
- `handle_get_pattern_metrics` → `mcp_tool_get_pattern_metrics`
- `handle_get_tool_patterns` → `mcp_tool_get_tool_patterns`
- `handle_trigger_session_patterns` → `mcp_tool_trigger_session_patterns`

#### Optimization & Debug
- `handle_optimize_knowledge_base` → `mcp_tool_optimize_knowledge_base`
- `handle_optimization_status` → `mcp_tool_optimization_status`
- `handle_optimization_history` → `mcp_tool_optimization_history`
- `handle_debug_markdown_test` → `mcp_tool_debug_markdown_test`
- `handle_test_streaming_format` → `mcp_tool_test_streaming_format`
- `handle_get_next_chunk` → `mcp_tool_get_next_chunk`

#### Tool Execution
- `execute_tool_call` → `mcp_tool_execute_tool_call`
- `parse_tool_calls` → `mcp_tool_parse_tool_calls`

**MCP Resources to Add**:
```rust
// Convert these to MCP resources:
- neovim://buffers -> mcp_resource_buffers
- neovim://session -> mcp_resource_session
- neovim://commands -> mcp_resource_commands
- patterns://list -> mcp_resource_patterns
- iragl://index -> mcp_resource_iragl_index
- projects://list -> mcp_resource_projects
- goals://list -> mcp_resource_goals
- tasks://list -> mcp_resource_tasks
- agents://list -> mcp_resource_agents
- conversations://list -> mcp_resource_conversations
```

### 1.3 Update Server Dependencies

**File**: `Cargo.toml`
**Add/Update**:
```toml
[dependencies]
axum = "0.7"
tower-http = { version = "0.5", features = ["cors"] }
tokio-stream = "0.1"
```

## Phase 2: Neovim Client Conversion

### 2.1 Replace RPC Client with MCP Transport

**File**: `lua/paragonic/backend.lua`
**Changes**:
```lua
-- Remove this:
local success, rpc = pcall(require, "paragonic.rpc")
local client = rpc.new("127.0.0.1:3000")

-- Replace with:
local mcp_transport = require("paragonic.mcp_http_transport")
local success, err = mcp_transport.init({
    base_url = "http://127.0.0.1:3000",
    timeout = 30,
    retry_attempts = 3,
})
```

### 2.2 Update Chat Module

**File**: `lua/paragonic/chat.lua`
**Changes**:
```lua
-- Remove this:
local response = rpc_client:chat_completion(model, message)

-- Replace with:
local response, err = mcp_transport.send_request({
    jsonrpc = "2.0",
    id = mcp_transport.generate_message_id(),
    method = "tools/call",
    params = {
        name = "chat_completion",
        arguments = {
            model = model,
            message = message
        }
    }
})
```

### 2.3 Update AI Agent Module

**File**: `lua/paragonic/ai_agent.lua`
**Changes**:
```lua
-- Convert all RPC calls to MCP tool calls:
-- rpc_client:agent_edit_file() -> mcp_transport.send_request({method: "tools/call", params: {name: "agent_edit_file"}})
-- rpc_client:agent_create_file() -> mcp_transport.send_request({method: "tools/call", params: {name: "agent_create_file"}})
-- etc.
```

### 2.4 Update Search Module

**File**: `lua/paragonic/search.lua`
**Changes**:
```lua
-- Convert search RPC calls to MCP tool calls:
-- rpc_client:search_content() -> mcp_transport.send_request({method: "tools/call", params: {name: "search_content"}})
-- rpc_client:search_iragl() -> mcp_transport.send_request({method: "tools/call", params: {name: "search_iragl"}})
```

## Phase 3: Configuration and Integration

### 3.1 Update Configuration

**File**: `lua/paragonic/config.lua`
**Changes**:
```lua
-- Remove TCP/RPC configuration
-- Add MCP HTTP transport configuration:
local DEFAULT_CONFIG = {
    mcp = {
        base_url = "http://127.0.0.1:3000",
        timeout = 30,
        retry_attempts = 3,
        retry_delay = 1,
        connection_pool = {
            size = 10,
            timeout = 30,
            idle_timeout = 300,
        },
        optimization = {
            enable_keep_alive = true,
            keep_alive_timeout = 30,
            max_idle_connections = 5,
            connection_timeout = 10,
        },
        security = {
            validate_origin = true,
            session_timeout = 3600,
            max_request_size = 1024 * 1024,
        },
    },
    -- Remove: ollama_host, ollama_port, rpc_timeout, etc.
}
```

### 3.2 Update Initialization

**File**: `lua/paragonic/init.lua`
**Changes**:
```lua
-- Remove RPC client initialization
-- Add MCP transport initialization:
local mcp_transport = require("paragonic.mcp_http_transport")
local config = require("paragonic.config")
local mcp_config = config.get("mcp")

local success, err = mcp_transport.init(mcp_config)
if not success then
    debug.debug_print("Failed to initialize MCP transport: " .. tostring(err), "error")
end
```

### 3.3 Remove Legacy Code

**Files to Remove**:
- `lua/paragonic/rpc.lua`
- `lua/paragonic/rpc_bridge.lua`
- `lua/paragonic/rpc_simple.lua`
- `lua/paragonic/rpc_standalone.lua`
- `src/rpc.rs`

**Files to Update**:
- Remove all `require("paragonic.rpc")` calls
- Remove all `rpc_client:` method calls
- Update all tests to use MCP transport

## Phase 4: Testing and Validation

### 4.1 Update Test Suite

**Changes**:
- Convert all `tests/unit/rpc/` tests to `tests/unit/mcp/`
- Update integration tests for HTTP transport
- Add MCP protocol compliance tests
- Update `justfile` test targets

### 4.2 Update Documentation

**Changes**:
- Update `README.md` to reflect MCP transport
- Update API documentation
- Remove TCP/RPC references
- Add MCP protocol documentation

## Implementation Order

1. **Start with Rust server** (Phase 1)
   - Convert RPC methods to MCP tools
   - Update server startup
   - Test HTTP server functionality

2. **Update Neovim client** (Phase 2)
   - Replace RPC client with MCP transport
   - Update all modules to use MCP
   - Test client-server communication

3. **Configuration and cleanup** (Phase 3)
   - Update configuration
   - Remove legacy code
   - Update initialization

4. **Testing and documentation** (Phase 4)
   - Update test suite
   - Update documentation
   - Final validation

## Migration Strategy

### Backward Compatibility
- **No backward compatibility** - this is a breaking change
- Remove all TCP/RPC code completely
- Force users to migrate to MCP transport

### Migration Steps for Users
1. Update to new version
2. Start HTTP server instead of TCP server
3. Update configuration to use MCP settings
4. Test functionality

### Rollback Plan
- Keep old version available for rollback
- Provide migration guide
- Support both versions temporarily if needed

## Success Criteria

1. **All functionality works through MCP transport**
2. **No TCP/RPC code remains**
3. **All tests pass with MCP transport**
4. **Documentation is updated**
5. **Performance is maintained or improved**
6. **MCP protocol compliance is verified**

## Timeline Estimate

- **Phase 1 (Rust Server)**: 2-3 days
- **Phase 2 (Neovim Client)**: 2-3 days  
- **Phase 3 (Configuration)**: 1 day
- **Phase 4 (Testing)**: 1-2 days
- **Total**: 6-9 days

## Risk Assessment

### High Risk
- Breaking change for all users
- Complex protocol conversion
- Potential performance impact

### Mitigation
- Comprehensive testing
- Clear migration documentation
- Performance benchmarking
- Gradual rollout if needed

## Detailed Implementation Steps

### Step 1: Expand HTTP Server (Day 1)
1. Add all MCP tools to `src/http_server.rs`
2. Convert each RPC method to MCP tool handler
3. Add proper MCP resource providers
4. Test HTTP server functionality

### Step 2: Update Server Startup (Day 2)
1. Modify `src/main.rs` to start HTTP server
2. Update `src/lib.rs` with HTTP server function
3. Test server startup and basic functionality

### Step 3: Update Neovim Client (Day 3-4)
1. Replace RPC client in `backend.lua`
2. Update `chat.lua` to use MCP transport
3. Update `ai_agent.lua` to use MCP transport
4. Update `search.lua` to use MCP transport

### Step 4: Configuration Updates (Day 5)
1. Update `config.lua` for MCP settings
2. Update `init.lua` for MCP initialization
3. Remove legacy RPC configuration

### Step 5: Testing and Cleanup (Day 6-7)
1. Convert all tests to use MCP transport
2. Remove legacy RPC files
3. Update documentation
4. Final validation and testing

### Step 6: Documentation and Release (Day 8-9)
1. Update all documentation
2. Create migration guide
3. Update release notes
4. Final testing and validation
