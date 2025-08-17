# MCP Sampling Approval System - Usage Guide

## 🎯 Overview

The MCP Sampling Approval System provides user control over AI agent actions through native Neovim interfaces. It integrates seamlessly with the Model Context Protocol (MCP) to enable approval workflows for tool execution, decision points, and batch actions.

## 🚀 Quick Start

### 1. Initialize the System

```lua
-- In Neovim, source the demo file
:source demo_mcp_sampling_approval.lua

-- Run the complete demo
:lua run_demo()

-- Or run individual demos
:lua demo_basic_approval()
:lua demo_batch_actions()
:lua demo_decision_point()
:lua demo_undo_redo()
```

### 2. Basic Usage

The system automatically integrates with AI agents. When an AI agent attempts to execute a tool, an approval dialog will appear:

```
┌─────────────────────────────────────────┐
│ AI Agent Approval Request               │
├─────────────────────────────────────────┤
│ Tool: agent_edit_file                   │
│ File: example.lua                       │
│ Action: Modify line 10                  │
│ Impact: Will change function signature  │
│                                         │
│ [y] Approve  [n] Deny  [q] Quit        │
└─────────────────────────────────────────┘
```

## 🔧 Key Features

### 1. Tool Execution Approval

AI agents automatically trigger approval dialogs for tool execution:

```lua
-- AI agent calls this (automatically)
mcp.execute_tool_with_approval("agent_edit_file", {
    file_path = "example.lua",
    line_number = 10,
    content = "new content"
}, "request-id")
```

**User sees:** Approval dialog with tool details and impact assessment

### 2. Decision Points

For complex decisions, the system provides interactive decision dialogs:

```lua
-- AI agent requests user decision
local decision_request = {
    id = "decision-123",
    type = "decision_point",
    question = "Which approach should be used?",
    options = {
        "Option A: Simple approach",
        "Option B: Advanced approach",
        "Option C: Hybrid approach"
    }
}
```

**User sees:** Numbered options dialog with selection interface

### 3. Batch Actions

For multiple related actions, batch approval dialogs allow partial approval:

```lua
-- AI agent requests batch approval
local batch_request = {
    id = "batch-456",
    type = "batch_action",
    actions = {
        {type = "edit", file = "file1.lua", tool_name = "agent_edit_file"},
        {type = "edit", file = "file2.lua", tool_name = "agent_edit_file"},
        {type = "create", file = "file3.lua", tool_name = "agent_create_file"}
    }
}
```

**User sees:** Batch dialog with individual action selection

### 4. Undo Integration

All AI modifications are tracked in Neovim's undo tree:

```lua
-- Undo specific AI modification
:lua mcp.undo_ai_modification("request-id")

-- Redo specific AI modification
:lua mcp.redo_ai_modification("request-id")

-- Undo multiple AI modifications
:lua mcp.undo_ai_modifications({"id1", "id2", "id3"})
```

## 🎮 Interactive Controls

### Approval Dialog Controls

- **`y`** - Approve the action
- **`n`** - Deny the action
- **`q`** or **`<Esc>`** - Close dialog without action

### Decision Point Controls

- **`1`, `2`, `3`** - Select numbered option
- **`q`** or **`<Esc>`** - Cancel decision

### Batch Action Controls

- **`y`** - Approve all actions
- **`n`** - Deny all actions
- **`p`** - Partial approval (select specific actions)
- **`q`** or **`<Esc>`** - Cancel batch

## 📊 System Status Commands

### Check Approval Status

```lua
-- Show pending approvals
:lua print("Pending: " .. mcp.get_pending_approval_count())

-- Show approval details
:lua print(vim.inspect(mcp.get_approval_request("request-id")))
```

### Check Undo Integration

```lua
-- Show undo integration status
:lua print(vim.inspect(mcp.get_undo_integration_status()))

-- Show AI undo entries
:lua print(vim.inspect(mcp.get_ai_undo_entry("request-id")))
```

### Cleanup Commands

```lua
-- Clean up completed approvals
:lua mcp.cleanup_completed_approvals()

-- Clean up old undo entries
:lua mcp.cleanup_old_ai_undo_entries()
```

## 🔒 Security Features

### Auto-Approval

Certain "safe" tools are automatically approved:

```lua
-- These tools bypass approval
mcp.auto_approved_tools = {
    "agent_session_info",
    "agent_search_files", 
    "file_search",
    "buffer_navigate"
}
```

### Timeout Handling

All approval requests have configurable timeouts:

```lua
-- Request with 30-second timeout
local request = {
    id = "timeout-example",
    timeout = 30,  -- seconds
    -- ... other fields
}
```

### Validation

All requests are validated before processing:

```lua
-- Invalid requests are rejected
local invalid_request = {
    id = "invalid",
    tool_name = "nonexistent_tool",
    parameters = {}
}
-- Result: Request denied, error logged
```

## 🎯 Real-World Scenarios

### Scenario 1: Code Review

AI agent suggests code changes:

1. **AI Agent** proposes modification to `main.lua`
2. **User** sees approval dialog with diff preview
3. **User** approves with `y` or denies with `n`
4. **System** executes approved changes with undo tracking

### Scenario 2: Architecture Decision

AI agent needs user input for design decisions:

1. **AI Agent** presents multiple architectural options
2. **User** sees decision point dialog with numbered choices
3. **User** selects preferred option with number key
4. **System** proceeds with selected approach

### Scenario 3: Batch Refactoring

AI agent proposes multiple related changes:

1. **AI Agent** suggests refactoring across multiple files
2. **User** sees batch dialog listing all proposed changes
3. **User** can approve all, deny all, or select specific changes
4. **System** executes only approved changes

### Scenario 4: Undo Management

User wants to revert specific AI changes:

1. **User** identifies unwanted AI modification
2. **User** calls `:lua mcp.undo_ai_modification("request-id")`
3. **System** reverts only that specific change
4. **User** can redo with `:lua mcp.redo_ai_modification("request-id")`

## 🔧 Advanced Configuration

### Custom Approval Dialogs

```lua
-- Create custom approval dialog
local dialog = mcp.create_approval_dialog("custom-request-id")
mcp.display_approval_dialog(dialog)

-- Handle user interaction
mcp.handle_user_approval(dialog, {approved = true, notes = "Custom notes"})
```

### Custom Decision Points

```lua
-- Create custom decision point
local dialog = mcp.create_decision_point_dialog("decision-id")
mcp.display_approval_dialog(dialog)

-- Handle option selection
mcp.handle_option_selection(dialog, 2)  -- Select option 2
```

### Batch Action Management

```lua
-- Create batch action dialog
local dialog = mcp.create_batch_action_dialog("batch-id")
mcp.display_approval_dialog(dialog)

-- Handle partial approval
mcp.handle_partial_approval(dialog, {1, 3})  -- Approve actions 1 and 3
```

## 🐛 Troubleshooting

### Common Issues

1. **Dialog not appearing**
   - Check if Neovim has floating window support
   - Verify MCP module is loaded correctly

2. **Undo not working**
   - Ensure undo integration is initialized
   - Check if AI modification was tracked

3. **Approval not processing**
   - Verify request ID is valid
   - Check if request has timed out

### Debug Commands

```lua
-- Show system status
:lua show_system_status()

-- Check MCP tools
:lua print(vim.inspect(mcp.mcp_tools))

-- Check approval state
:lua print(vim.inspect(mcp.approval_state))
```

## 📚 API Reference

### Core Functions

- `mcp.register_approval_request(request)` - Register new approval request
- `mcp.approve_request(id, result)` - Approve specific request
- `mcp.deny_request(id, result)` - Deny specific request
- `mcp.get_approval_request(id)` - Get request details
- `mcp.get_pending_approval_count()` - Count pending requests

### UI Functions

- `mcp.create_approval_dialog(id)` - Create approval dialog
- `mcp.create_decision_point_dialog(id)` - Create decision dialog
- `mcp.create_batch_action_dialog(id)` - Create batch dialog
- `mcp.display_approval_dialog(dialog)` - Show dialog
- `mcp.close_approval_dialog(dialog)` - Close dialog

### Undo Functions

- `mcp.undo_ai_modification(id)` - Undo specific AI change
- `mcp.redo_ai_modification(id)` - Redo specific AI change
- `mcp.get_ai_undo_entry(id)` - Get undo entry details
- `mcp.get_undo_integration_status()` - Get undo system status

### Tool Execution

- `mcp.execute_tool_with_approval(tool, params, id)` - Execute with approval
- `mcp.execute_tool_with_undo_integration(tool, params, id)` - Execute with undo
- `mcp.execute_batch_with_undo_integration(actions, id)` - Execute batch with undo

## 🎉 Getting Started

1. **Load the system**: `:source demo_mcp_sampling_approval.lua`
2. **Run demo**: `:lua run_demo()`
3. **Watch dialogs**: Observe approval dialogs appearing
4. **Interact**: Use `y`/`n` keys to approve/deny
5. **Explore**: Try different demo scenarios
6. **Integrate**: Connect with your AI agent workflow

The MCP Sampling Approval System provides a powerful, user-friendly interface for controlling AI agent actions while maintaining full undo/redo capabilities and comprehensive safety mechanisms.
