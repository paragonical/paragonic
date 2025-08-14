# MCP-Only Neovim Client Conversion Plan

## 🎯 **Objective: 100% MCP Protocol Compliance**

Convert the entire Neovim client to use **only MCP protocol methods** for all interactions with the Rust server, eliminating all legacy non-MCP method calls.

## **Current State Analysis**

### ✅ **Already Using MCP Protocol**
- `tools/list` - MCP protocol
- `resources/read` - MCP protocol  
- `resources/subscribe` - MCP protocol
- `completion/complete` - MCP thinking model support
- `sampling/createMessage` - MCP thinking model support
- `elicitation/create` - MCP thinking model support

### ❌ **Still Using Legacy Non-MCP Methods**
- `chat_completion` → Should use `completion/complete`
- `formatted_chat_completion` → Should use `completion/complete` with options
- `streaming_chat_completion` → Should use `completion/complete` with streaming
- `list_models` → Should use `tools/call` with model tools
- `search_embeddings` → Should use `tools/call` with search tool
- `find_similar_content` → Should use `tools/call` with similarity tool
- `hybrid_search` → Should use `tools/call` with hybrid search tool
- `list_projects` → Should use `tools/call` with project tools
- `create_project` → Should use `tools/call` with project creation tool
- `write_file` → Should use `tools/call` with file operations tool

## **Implementation Plan**

### **Phase 1: High Priority - Core AI/Chat Functionality (Week 1)**

#### **1.1 Update Rust Server MCP Tools**

**File**: `src/http_server.rs`
**Changes**: Enhance `handle_tools_list` and `handle_tools_call` to expose all functionality as MCP tools

**Priority**: 🔴 **CRITICAL**

#### **1.2 Convert Neovim Client Core Methods**

**File**: `lua/paragonic/backend.lua`
**Changes**: Replace legacy chat methods with MCP protocol calls

**Priority**: 🔴 **CRITICAL**

### **Phase 2: Medium Priority - Search & Knowledge (Week 2)**

#### **2.1 Convert Search Functionality**

**File**: `lua/paragonic/search.lua`
**Changes**: Replace mock implementations with MCP tool calls

**Priority**: 🟡 **HIGH**

#### **2.2 Convert Model Management**

**File**: `lua/paragonic/backend.lua`
**Changes**: Convert model listing to MCP tools

**Priority**: 🟡 **HIGH**

### **Phase 3: Low Priority - Project & File Operations (Week 3)**

#### **3.1 Convert Project Management**

**File**: `lua/paragonic/backend.lua`
**Changes**: Convert project operations to MCP tools

**Priority**: 🟢 **MEDIUM**

#### **3.2 Convert File Operations**

**File**: `lua/paragonic/backend.lua`
**Changes**: Convert file operations to MCP tools

**Priority**: 🟢 **MEDIUM**

### **Phase 4: Cleanup & Testing (Week 4)**

#### **4.1 Remove Legacy Code**

**Files to Remove**:
- `lua/paragonic/rpc_bridge.lua`
- `lua/paragonic/rpc_simple.lua`
- `lua/paragonic/rpc_standalone.lua`

**Priority**: 🟢 **MEDIUM**

#### **4.2 Comprehensive Testing**

**File**: `tests/unit/mcp/test_mcp_only_compliance.lua`
**Changes**: Create test suite for MCP-only compliance

**Priority**: 🟡 **HIGH**

## **Detailed Implementation Steps**

### **Step 1: Update Rust Server MCP Tools (HIGH PRIORITY)**

#### **1.1 Enhance `handle_tools_list`**

Add all available functionality as MCP tools:

```rust
async fn handle_tools_list(
    server: &Self,
    params: Option<&Value>,
) -> Result<Value, StatusCode> {
    Ok(serde_json::json!({
        "tools": [
            // AI & Chat Tools
            {
                "name": "chat_completion",
                "description": "Generate AI chat completions with thinking model support",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "model": {"type": "string", "description": "Model to use for completion"},
                        "message": {"type": "string", "description": "User message"},
                        "options": {"type": "object", "description": "Completion options"}
                    },
                    "required": ["message"]
                }
            },
            {
                "name": "formatted_chat_completion", 
                "description": "Generate formatted AI chat completions",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "model": {"type": "string"},
                        "message": {"type": "string"},
                        "format_config": {"type": "object"}
                    },
                    "required": ["message"]
                }
            },
            {
                "name": "streaming_chat_completion",
                "description": "Generate streaming AI chat completions",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "model": {"type": "string"},
                        "message": {"type": "string"},
                        "chunk_size": {"type": "number"}
                    },
                    "required": ["message"]
                }
            },
            // Model Management Tools
            {
                "name": "list_models",
                "description": "List available AI models",
                "inputSchema": {
                    "type": "object",
                    "properties": {}
                }
            },
            // Search & Knowledge Tools
            {
                "name": "search_embeddings",
                "description": "Search content using vector embeddings",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "query": {"type": "string"},
                        "limit": {"type": "number"}
                    },
                    "required": ["query"]
                }
            },
            {
                "name": "find_similar_content",
                "description": "Find similar content with filtering",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "query": {"type": "string"},
                        "content_type": {"type": "string"},
                        "limit": {"type": "number"},
                        "threshold": {"type": "number"}
                    },
                    "required": ["query"]
                }
            },
            {
                "name": "hybrid_search",
                "description": "Perform hybrid search combining vector and text matching",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "query": {"type": "string"},
                        "content_type": {"type": "string"},
                        "limit": {"type": "number"},
                        "threshold": {"type": "number"},
                        "include_text_filtering": {"type": "boolean"}
                    },
                    "required": ["query"]
                }
            },
            // Project Management Tools
            {
                "name": "create_project",
                "description": "Create a new project",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "name": {"type": "string"},
                        "description": {"type": "string"}
                    },
                    "required": ["name"]
                }
            },
            {
                "name": "list_projects",
                "description": "List all projects",
                "inputSchema": {
                    "type": "object",
                    "properties": {}
                }
            },
            // File Operations Tools
            {
                "name": "write_file",
                "description": "Write content to a file",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "file_path": {"type": "string"},
                        "content": {"type": "string"}
                    },
                    "required": ["file_path", "content"]
                }
            },
            {
                "name": "read_file",
                "description": "Read content from a file",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "file_path": {"type": "string"}
                    },
                    "required": ["file_path"]
                }
            }
        ]
    }))
}
```

#### **1.2 Enhance `handle_tools_call`**

Route all tool calls to existing handlers:

```rust
async fn handle_tools_call(
    server: &Self,
    params: Option<&Value>,
) -> Result<Value, StatusCode> {
    let params = params.ok_or(StatusCode::BAD_REQUEST)?;
    
    let name = params.get("name")
        .and_then(|n| n.as_str())
        .ok_or(StatusCode::BAD_REQUEST)?;
    
    let arguments = params.get("arguments")
        .and_then(|a| a.as_object())
        .ok_or(StatusCode::BAD_REQUEST)?;

    // Route to appropriate handler based on tool name
    let result = match name {
        // AI & Chat Tools
        "chat_completion" => {
            let model = arguments.get("model").and_then(|m| m.as_str()).unwrap_or("deepseek-r1:1.5b");
            let message = arguments.get("message").and_then(|m| m.as_str()).ok_or(StatusCode::BAD_REQUEST)?;
            let options = arguments.get("options");
            
            // Use the existing MCP completion handler
            Self::handle_completion_complete(server, Some(&serde_json::json!({
                "prompt": message,
                "model": model,
                "options": options
            }))).await
        },
        "formatted_chat_completion" => {
            let model = arguments.get("model").and_then(|m| m.as_str()).unwrap_or("deepseek-r1:1.5b");
            let message = arguments.get("message").and_then(|m| m.as_str()).ok_or(StatusCode::BAD_REQUEST)?;
            let format_config = arguments.get("format_config");
            
            // Use the existing formatted chat completion handler
            Self::handle_formatted_chat_completion(server, Some(&serde_json::json!({
                "model": model,
                "message": message,
                "format_config": format_config
            }))).await
        },
        "streaming_chat_completion" => {
            let model = arguments.get("model").and_then(|m| m.as_str()).unwrap_or("deepseek-r1:1.5b");
            let message = arguments.get("message").and_then(|m| m.as_str()).ok_or(StatusCode::BAD_REQUEST)?;
            let chunk_size = arguments.get("chunk_size").and_then(|c| c.as_u64()).unwrap_or(30);
            
            // Use the existing streaming chat completion handler
            Self::handle_streaming_chat_completion(server, Some(&serde_json::json!({
                "model": model,
                "message": message,
                "chunk_size": chunk_size
            }))).await
        },
        // Model Management Tools
        "list_models" => Self::handle_list_models(server, Some(&Value::Object(serde_json::Map::new()))).await,
        "model_info" => Self::handle_model_info(server, Some(&serde_json::json!(arguments))).await,
        // Search & Knowledge Tools
        "search_embeddings" => Self::handle_search_embeddings(server, Some(&serde_json::json!(arguments))).await,
        "find_similar_content" => Self::handle_find_similar_content(server, Some(&serde_json::json!(arguments))).await,
        "hybrid_search" => Self::handle_hybrid_search(server, Some(&serde_json::json!(arguments))).await,
        // Project Management Tools
        "create_project" => Self::handle_create_project(server, Some(&serde_json::json!(arguments))).await,
        "list_projects" => Self::handle_list_projects(server, Some(&Value::Object(serde_json::Map::new()))).await,
        // File Operations Tools
        "write_file" => Self::handle_write_file(server, Some(&serde_json::json!(arguments))).await,
        "read_file" => Self::handle_read_file(server, Some(&serde_json::json!(arguments))).await,
        // Unknown tool
        _ => {
            error!("Unknown tool: {}", name);
            return Err(StatusCode::BAD_REQUEST);
        }
    };

    match result {
        Ok(data) => Ok(serde_json::json!({
            "content": [
                {
                    "type": "text",
                    "text": serde_json::to_string(&data).unwrap_or_default()
                }
            ]
        })),
        Err(e) => {
            error!("Tool call failed for {}: {:?}", name, e);
            Err(e)
        }
    }
}
```

### **Step 2: Convert Neovim Client Core Methods (HIGH PRIORITY)**

#### **2.1 Update Backend Client**

**File**: `lua/paragonic/backend.lua`

Replace legacy method calls with MCP tool calls:

```lua
-- Create MCP client shim that matches the existing RPC client's methods
local function create_mcp_client()
    local debug = require("paragonic.debug")
    local config = require("paragonic.config")
    local mcp = require("paragonic.mcp_http_transport")

    local client = {}

    -- ... existing connection methods ...

    -- Model Management (using MCP tools)
    function client:list_models()
        local resp, err = mcp.send_request({
            jsonrpc = "2.0",
            method = "tools/call",
            params = {
                name = "list_models",
                arguments = {}
            }
        })
        return resp, err
    end

    -- Chat/AI (using MCP completion)
    function client:chat_completion(model, message)
        local resp, err = mcp.send_request({
            jsonrpc = "2.0",
            method = "completion/complete",
            params = {
                prompt = message,
                model = model or "deepseek-r1:1.5b",
                options = {}
            }
        })
        return resp, err
    end

    function client:formatted_chat_completion(model, message, format_config)
        local resp, err = mcp.send_request({
            jsonrpc = "2.0",
            method = "tools/call",
            params = {
                name = "formatted_chat_completion",
                arguments = {
                    model = model or "deepseek-r1:1.5b",
                    message = message,
                    format_config = format_config or {}
                }
            }
        })
        return resp, err
    end

    function client:streaming_chat_completion(params)
        local resp, err = mcp.send_request({
            jsonrpc = "2.0",
            method = "tools/call",
            params = {
                name = "streaming_chat_completion",
                arguments = params or {}
            }
        })
        return resp, err
    end

    -- Search/Knowledge (using MCP tools)
    function client:search_embeddings(query, limit)
        local resp, err = mcp.send_request({
            jsonrpc = "2.0",
            method = "tools/call",
            params = {
                name = "search_embeddings",
                arguments = {
                    query = query,
                    limit = limit or 10
                }
            }
        })
        return resp, err
    end

    function client:find_similar_content(query, content_type, limit, threshold)
        local resp, err = mcp.send_request({
            jsonrpc = "2.0",
            method = "tools/call",
            params = {
                name = "find_similar_content",
                arguments = {
                    query = query,
                    content_type = content_type,
                    limit = limit or 10,
                    threshold = threshold or 0.0
                }
            }
        })
        return resp, err
    end

    function client:hybrid_search(query, content_type, limit, threshold, include_text_filtering)
        local resp, err = mcp.send_request({
            jsonrpc = "2.0",
            method = "tools/call",
            params = {
                name = "hybrid_search",
                arguments = {
                    query = query,
                    content_type = content_type,
                    limit = limit or 10,
                    threshold = threshold or 0.0,
                    include_text_filtering = include_text_filtering ~= false
                }
            }
        })
        return resp, err
    end

    -- Project Management (using MCP tools)
    function client:get_projects()
        local resp, err = mcp.send_request({
            jsonrpc = "2.0",
            method = "tools/call",
            params = {
                name = "list_projects",
                arguments = {}
            }
        })
        return resp, err
    end

    function client:create_project(name, description)
        local resp, err = mcp.send_request({
            jsonrpc = "2.0",
            method = "tools/call",
            params = {
                name = "create_project",
                arguments = {
                    name = name,
                    description = description or ""
                }
            }
        })
        return resp, err
    end

    -- File Operations (using MCP tools)
    function client:save_config(config_data)
        local resp, err = mcp.send_request({
            jsonrpc = "2.0",
            method = "tools/call",
            params = {
                name = "write_file",
                arguments = {
                    file_path = "config.json",
                    content = vim.json.encode(config_data)
                }
            }
        })
        return resp, err
    end

    return client
end
```

## **Testing Strategy**

### **Phase 1 Testing (High Priority)**

1. **Unit Tests**: Test each MCP tool individually
2. **Integration Tests**: Test complete chat workflows
3. **Performance Tests**: Ensure MCP-only approach maintains performance

### **Phase 2 Testing (Medium Priority)**

1. **Search Tests**: Test all search functionality through MCP tools
2. **Model Tests**: Test model management through MCP tools

### **Phase 3 Testing (Low Priority)**

1. **Project Tests**: Test project management through MCP tools
2. **File Tests**: Test file operations through MCP tools

## **Success Criteria**

✅ **100% MCP Protocol Compliance**
- All client-server communication uses MCP methods
- No legacy non-MCP method calls
- Full MCP specification compliance

✅ **Complete Functionality**
- All existing features work through MCP tools
- Thinking model support fully implemented
- Performance maintained or improved

✅ **Clean Architecture**
- Removed all legacy RPC code
- Clear separation of concerns
- Comprehensive documentation

✅ **Comprehensive Testing**
- All MCP tools tested
- Integration tests updated
- Performance benchmarks

## **Implementation Timeline**

### **Week 1: High Priority Changes**
- [ ] Update Rust server MCP tools
- [ ] Convert Neovim client core methods
- [ ] Test AI/chat functionality

### **Week 2: Medium Priority Changes**
- [ ] Convert search functionality
- [ ] Convert model management
- [ ] Test search and model functionality

### **Week 3: Low Priority Changes**
- [ ] Convert project management
- [ ] Convert file operations
- [ ] Test project and file functionality

### **Week 4: Cleanup and Validation**
- [ ] Remove legacy code
- [ ] Comprehensive testing
- [ ] Performance validation
- [ ] Documentation updates

This plan ensures a complete migration to MCP-only architecture while maintaining all existing functionality and improving the overall system design through standard protocol compliance.
