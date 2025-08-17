# MCP Sampling Approval Usage Guide

## Overview

The MCP Sampling Approval system provides a **non-interruptive, chat-based approval workflow** for AI agent actions. Instead of blocking dialogs, approval requests appear as sigil markers (󰭙) in chat buffers, allowing users to process them at their own pace.

## Key Features

- **Non-Interruptive**: No blocking dialogs that interrupt workflow
- **Chat Integration**: Approval markers appear naturally in chat flow
- **Visual Status**: Clear status indicators (🔄 ✅ ❌ ⏰)
- **Enter Key Integration**: Press Enter on markers to process approvals
- **Contextual**: Markers appear with relevant context and descriptions

## Quick Start

### 1. Initialize the System

```lua
local mcp = require("paragonic.mcp")

-- Initialize MCP server (includes approval system)
mcp.initialize_mcp_server()

-- Initialize approval state
mcp.initialize_approval_state()

-- Initialize chat-based approval UI
mcp.initialize_chat_approval()
```

### 2. Set Up Chat Buffer Mappings

```lua
-- Set up Enter key integration for chat buffers
mcp.setup_chat_buffer_mappings()
```

### 3. Create Approval Requests

```lua
-- Register an approval request (marker appears automatically)
local request = {
    id = "unique-request-id",
    type = "tool_execution",
    tool_name = "agent_edit_file",
    parameters = {
        file_path = "example.py",
        line_number = 1,
        content = "print('Hello, World!')"
    },
    description = "Create example.py with hello world",
    timeout = 300  -- 5 minutes
}

local success = mcp.register_approval_request(request)
```

## Visual Example

**Chat Buffer with Approval Markers:**
```
# AI Assistant Chat

User: Can you help me create a Python project?

AI: I'll help you set up a Python project structure.

AI: First, let me create the main application file.

󰭙 🔄 [tool_execution] Create main.py with application header
󰭙 🔄 [tool_execution] Create requirements.txt with dependencies
󰭙 🔄 [decision_point] Choose testing framework for the project
󰭙 🔄 [batch_action] Create project documentation and config files
```

**After Processing:**
```
󰭙 🆗 [tool_execution] Create main.py with application header - approved at 14:32:15 ✓
󰭙 ⛔ [tool_execution] Create requirements.txt with dependencies - denied at 14:32:45 ✗
󰭙 🆗 [decision_point] Choose testing framework for the project - approved at 14:33:10 ✓
󰭙 🔄 [batch_action] Create project documentation and config files
```

## User Interaction

### Processing Approvals

1. **Move cursor** to any 󰭙 marker line
2. **Press Enter** to open approval dialog
3. **Choose action**:
   - **Approve** - Approve the request
   - **Deny** - Deny the request
   - **Details** - View full request information
   - **Cancel** - Cancel the action

### Status Indicators

- **🔄 Pending** - Waiting for user approval
- **🆗 Approved** - Request has been approved (with timestamp)
- **⛔ Denied** - Request has been denied (with timestamp)
- **⏰ Timeout** - Request timed out automatically

**Note:** Completed requests (🆗/⛔) can be ignored. Press Enter on them to see completion details.

## Request Types

### 1. Tool Execution

```lua
local tool_request = {
    id = "tool-request-id",
    type = "tool_execution",
    tool_name = "agent_edit_file",
    parameters = {
        file_path = "file.txt",
        line_number = 1,
        content = "New content"
    },
    description = "Edit file.txt with new content",
    timeout = 300
}
```

### 2. Decision Point

```lua
local decision_request = {
    id = "decision-request-id",
    type = "decision_point",
    question = "Which database should we use?",
    options = {
        "SQLite (simple)",
        "PostgreSQL (production)",
        "MySQL (popular)"
    },
    description = "Choose database for the application",
    timeout = 300
}
```

### 3. Batch Action

```lua
local batch_request = {
    id = "batch-request-id",
    type = "batch_action",
    actions = {
        {
            type = "create",
            file = "file1.txt",
            description = "Create first file"
        },
        {
            type = "create", 
            file = "file2.txt",
            description = "Create second file"
        }
    },
    description = "Create multiple project files",
    timeout = 300
}
```

## API Reference

### Core Functions

```lua
-- Register approval request (creates marker automatically)
mcp.register_approval_request(request)

-- Get approval request by ID
mcp.get_approval_request(request_id)

-- Approve request
mcp.approve_request(request_id, result)

-- Deny request  
mcp.deny_request(request_id, result)

-- Get pending approval count
mcp.get_pending_approval_count()

-- Get all pending approvals
mcp.get_pending_approvals()
```

### Chat Integration Functions

```lua
-- Create approval marker in chat buffer
mcp.create_approval_marker(request_id, request_type, description)

-- Update marker status
mcp.update_approval_marker(approval_id, status, result)

-- Set up chat buffer mappings
mcp.setup_chat_buffer_mappings()

-- Remove approval marker
mcp.remove_approval_marker(approval_id)

-- Initialize chat approval system
mcp.initialize_chat_approval()
```

### Tool Execution Integration

```lua
-- Execute tool with approval workflow
mcp.execute_tool_with_approval(tool_name, parameters, request_id)

-- Execute tool with modified parameters
mcp.execute_tool_with_modification(tool_name, original_params, modified_params, request_id)

-- Execute batch tools with approval
mcp.execute_batch_tools_with_approval(actions, request_id)

-- Execute partial batch approval
mcp.execute_partial_batch_approval(actions, approved_indices, request_id)
```

## Configuration

### Auto-Approved Tools

Some tools are automatically approved to avoid unnecessary interruptions:

```lua
M.auto_approved_tools = {
    "agent_session_info",
    "agent_search_files", 
    "file_search",
    "buffer_navigate"
}
```

### Timeout Settings

Default timeout is 30 seconds, but can be customized per request:

```lua
local request = {
    id = "custom-timeout",
    type = "tool_execution",
    timeout = 600,  -- 10 minutes
    -- ... other fields
}
```

## Best Practices

### 1. Descriptive Requests

Always provide clear descriptions for approval requests:

```lua
-- Good
description = "Create main.py with Flask application setup"

-- Avoid
description = "Create file"
```

### 2. Appropriate Timeouts

Set timeouts based on request complexity:

```lua
-- Simple tool execution
timeout = 60  -- 1 minute

-- Complex decision point
timeout = 300  -- 5 minutes

-- Batch actions
timeout = 600  -- 10 minutes
```

### 3. Contextual Information

Include relevant context in request descriptions:

```lua
description = "Create requirements.txt with Flask dependencies for web app"
```

### 4. Error Handling

Always check return values:

```lua
local success, error = mcp.register_approval_request(request)
if not success then
    print("Failed to register request: " .. error)
end
```

## Demo Scripts

### Polished Chat Approval Demo

```lua
-- Source the demo
:source demo_polished_chat_approval.lua

-- Run the full demo
:lua test_polished_chat_approval()

-- Test individual marker interaction
:lua test_marker_interaction()

-- Show system status
:lua show_system_status()

-- Clean up demo
:lua cleanup_demo()
```

### Simple Chat Integration Demo

```lua
-- Source the demo
:source demo_chat_integration.lua

-- Run the demo
:lua test_chat_integration()

-- Test single marker
:lua test_single_marker()

-- Show status
:lua show_chat_status()
```

## Troubleshooting

### Common Issues

1. **Markers not appearing**
   - Ensure `mcp.initialize_chat_approval()` is called
   - Check that `mcp.setup_chat_buffer_mappings()` is set up
   - Verify the request has a valid `description` field

2. **Enter key not working**
   - Make sure chat buffer mappings are set up
   - Check that cursor is on a marker line
   - Verify the marker is still pending (🔄 status)

3. **Markers not updating**
   - Check that approval/denial functions are called correctly
   - Verify the request ID matches the marker
   - Ensure the UI module is properly loaded

### Debug Functions

```lua
-- Show pending approval count
print("Pending: " .. mcp.get_pending_approval_count())

-- Show all pending approvals
local pending = mcp.get_pending_approvals()
for i, approval in ipairs(pending) do
    print(i .. ". " .. approval.description)
end

-- Check specific request
local request = mcp.get_approval_request("request-id")
if request then
    print("Status: " .. request.status)
end
```

## Integration with Existing Systems

### MCP Protocol Integration

The approval system integrates seamlessly with MCP sampling requests:

```lua
-- Handle MCP sampling request
function M.handle_sampling_request(uri, criteria)
    if uri:find("approval://") then
        -- Extract approval information
        local approval_type = uri:match("approval://(.+)")
        local request = M.validate_approval_request(criteria)
        
        -- Register approval request (creates marker)
        M.register_approval_request(request)
        
        return {
            status = "pending",
            message = "Approval request created"
        }
    end
end
```

### Neovim Integration

The system works with Neovim's native features:

```lua
-- Set up autocommands for chat buffers
vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    callback = function()
        -- Check for approval markers
        mcp.check_for_approval_markers()
    end
})
```

## Performance Considerations

- **Marker Cleanup**: Old markers are automatically cleaned up after 1 hour
- **Memory Usage**: Each marker uses minimal memory (~1KB)
- **Highlighting**: Uses Neovim's efficient highlighting system
- **Updates**: Marker updates are batched for performance

## Security

- **Request Validation**: All requests are validated before processing
- **Audit Trail**: All approval actions are logged
- **Timeout Protection**: Automatic timeout prevents hanging requests
- **Access Control**: Only valid requests can be processed

This non-interruptive chat-sigil system provides a much better user experience compared to traditional blocking dialogs, allowing users to maintain their workflow while still having full control over AI agent actions.
