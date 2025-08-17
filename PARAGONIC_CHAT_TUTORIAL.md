# Paragonic Chat Tutorial

## Welcome to Paragonic Chat! 🚀

Paragonic Chat is an AI assistant that integrates seamlessly with Neovim, providing intelligent code assistance, file management, and project setup capabilities. This tutorial will guide you through all the features and help you become proficient with the system.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Basic Chat Interaction](#basic-chat-interaction)
3. [Approval System Overview](#approval-system-overview)
4. [Understanding Approval Markers](#understanding-approval-markers)
5. [Processing Approvals](#processing-approvals)
6. [Advanced Features](#advanced-features)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

---

## Getting Started

### Prerequisites

- **Neovim** (version 0.8.0 or higher)
- **Paragonic plugin** installed and configured
- Basic familiarity with Neovim commands

### Initial Setup

1. **Open Neovim** in your project directory:
   ```bash
   nvim
   ```

2. **Initialize the chat system** (if not already done):
   ```lua
   :lua require("paragonic.mcp").initialize_mcp_server()
   ```

3. **Create a chat buffer** or open an existing one:
   ```lua
   :lua require("paragonic.chat").open_chat()
   ```

---

## Basic Chat Interaction

### Starting a Conversation

1. **Open the chat interface**:
   ```lua
   :lua require("paragonic.chat").open_chat()
   ```

2. **Type your message** and press Enter:
   ```
   User: Can you help me create a Python web application?
   ```

3. **AI responds** with suggestions and actions:
   ```
   AI: I'll help you create a Python web application! Let me set up the project structure.
   ```

### Example Conversation

```
User: I need a simple Flask app with user authentication.

AI: I'll help you create a Flask application with user authentication. Let me set up the basic structure.

AI: First, I'll create the main application file with Flask setup.

  🔄 [tool_execution] Create main.py with Flask application setup

AI: Now I'll create the authentication module.

  🔄 [tool_execution] Create auth.py with user authentication logic

AI: Let me set up the database configuration.

  🔄 [decision_point] Choose database for user authentication
```

---

## Approval System Overview

Paragonic Chat uses an **approval system** to ensure you have control over all AI actions. Instead of interrupting your workflow with popup dialogs, approval requests appear as **markers** in the chat buffer.

### Why Approval System?

- **Safety**: You control what the AI can do
- **Transparency**: See exactly what actions are proposed
- **Non-interruptive**: No blocking dialogs
- **Contextual**: Approvals appear in chat flow

### Types of Actions Requiring Approval

1. **Tool Execution** - File creation, editing, deletion
2. **Decision Points** - AI needs your input for choices
3. **Batch Actions** - Multiple related operations

---

## Understanding Approval Markers

### Marker Format

Approval markers follow this format:
```
󰭙 [status] [type] description - additional info
```

### Status Indicators

- **🔄 Pending** - Waiting for your approval
- **🆗 Approved** - Action has been approved (with timestamp)
- **⛔ Denied** - Action has been denied (with timestamp)
- **⏰ Timeout** - Request timed out automatically

### Example Markers

```
󰭙 🔄 [tool_execution] Create main.py with Flask application setup
󰭙 🆗 [tool_execution] Create requirements.txt - approved at 14:32:15 ✓
󰭙 ⛔ [decision_point] Choose database - denied at 14:32:45 ✗
󰭙 🔄 [batch_action] Create project documentation and config files
```

### Marker Types

1. **`[tool_execution]`** - AI wants to create, edit, or delete files
2. **`[decision_point]`** - AI needs you to choose between options
3. **`[batch_action]`** - AI wants to perform multiple related actions

---

## Processing Approvals

### Method 1: Enter Key (Traditional)

1. **Move cursor** to any marker line
2. **Press Enter** to open options menu
3. **Choose action**:
   - **Approve** - Allow the action
   - **Deny** - Reject the action
   - **Details** - View full request information
   - **Cancel** - Close without action

### Method 2: Quick Actions (Recommended)

When your cursor is on a marker line:

- **`ya`** - Quick approve (yes-approve)
- **`nd`** - Quick deny (no-deny)
- **`gd`** - Show details (get-details)
- **`<C-m>`** - Show context menu

### Method 3: Visual Mode (Batch Operations)

1. **Enter visual mode** - Press `V` to select lines
2. **Select multiple markers** - Choose the lines you want to process
3. **Batch approve** - Press `ya` to approve all selected
4. **Batch deny** - Press `nd` to deny all selected

### Method 4: Context Menu

1. **Position cursor** on marker line
2. **Press `<C-m>`** to open context menu
3. **Select action** from the menu

---

## Advanced Features

### Auto-Approved Tools

Some tools are automatically approved to avoid unnecessary interruptions:

- **`agent_session_info`** - Get session information
- **`agent_search_files`** - Search for files
- **`file_search`** - Find files
- **`buffer_navigate`** - Navigate buffers

### Timeout System

All approval requests have configurable timeouts:

- **Default**: 30 seconds
- **Customizable**: Per request
- **Automatic**: Requests timeout if not processed

### Completed Request Handling

- **🆗/⛔ markers** can be safely ignored
- **Press Enter** on completed markers to see details
- **No action required** for completed requests

---

## Best Practices

### Writing Effective Prompts

**Good Examples:**
```
"Create a React component for user profile display"
"Set up a Python project with Flask and SQLAlchemy"
"Help me refactor this function to be more efficient"
```

**Avoid:**
```
"Fix everything" (too vague)
"Make it better" (not specific)
"Do something" (no clear goal)
```

### Managing Approvals

1. **Review before approving** - Check the details of proposed actions
2. **Use batch operations** - Select multiple similar requests
3. **Set appropriate timeouts** - Longer for complex decisions
4. **Monitor completed actions** - Check results of approved requests

### Workflow Tips

1. **Start with small requests** - Build up to complex tasks
2. **Be specific** - Clear instructions get better results
3. **Use the approval system** - Don't skip reviewing proposed actions
4. **Leverage batch operations** - Process multiple approvals efficiently

---

## Practical Examples

### Example 1: Project Setup

```
User: Create a Node.js project with Express and MongoDB

AI: I'll help you set up a Node.js project with Express and MongoDB.

  🔄 [tool_execution] Create package.json with Express dependencies
  🔄 [tool_execution] Create server.js with Express setup
  🔄 [tool_execution] Create .env file for MongoDB connection
  🔄 [decision_point] Choose MongoDB connection method
  🔄 [batch_action] Create project structure and documentation
```

**Your Actions:**
1. Press `ya` on first marker → Approve package.json
2. Press `ya` on second marker → Approve server.js
3. Press `<C-m>` on third marker → View context menu, choose Approve
4. Press `<CR>` on decision point → Choose "MongoDB Atlas"
5. Visual select batch action → Press `ya` to approve all

### Example 2: Code Review

```
User: Review this function and suggest improvements

AI: I'll analyze the function and suggest improvements.

  🔄 [tool_execution] Analyze function complexity and performance
  🔄 [decision_point] Choose refactoring approach
  🔄 [tool_execution] Create improved version of function
```

**Your Actions:**
1. Press `gd` on first marker → Review analysis details
2. Press `ya` on first marker → Approve analysis
3. Press `<CR>` on decision point → Choose "Extract helper functions"
4. Press `gd` on last marker → Review proposed changes
5. Press `ya` on last marker → Approve improvements

### Example 3: File Management

```
User: Organize my project files into a better structure

AI: I'll help you reorganize your project files for better structure.

  🔄 [batch_action] Create new directory structure
  🔄 [tool_execution] Move source files to src/ directory
  🔄 [tool_execution] Move test files to tests/ directory
  🔄 [tool_execution] Update import paths in moved files
```

**Your Actions:**
1. Visual select all markers → Press `ya` to approve all
2. Review the results → Check that files were moved correctly
3. Test the project → Ensure everything still works

---

## Troubleshooting

### Common Issues

#### Markers Not Appearing
**Problem**: Approval markers don't show up in chat
**Solution**:
```lua
-- Check if system is initialized
:lua print(require("paragonic.mcp").get_pending_approval_count())

-- Reinitialize if needed
:lua require("paragonic.mcp").initialize_mcp_server()
```

#### Quick Actions Not Working
**Problem**: `ya`/`nd` keys don't work
**Solution**:
```lua
-- Check if mappings are set up
:lua require("paragonic.mcp").setup_chat_buffer_mappings()

-- Verify cursor is on marker line
-- Look for 󰭙 symbol in the line
```

#### Context Menu Not Opening
**Problem**: `<C-m>` doesn't show context menu
**Solution**:
- Ensure cursor is on a marker line
- Check for 󰭙 symbol in the line
- Try `<CR>` as alternative

#### Batch Operations Not Working
**Problem**: Visual mode `ya`/`nd` doesn't work
**Solution**:
- Make sure you're in visual line mode (`V`)
- Select complete marker lines
- Check that markers are still pending (🔄 status)

### Debug Commands

```lua
-- Show pending approval count
:lua print("Pending: " .. require("paragonic.mcp").get_pending_approval_count())

-- Show all pending approvals
:lua print(vim.inspect(require("paragonic.mcp").get_pending_approvals()))

-- Check specific request
:lua print(vim.inspect(require("paragonic.mcp").get_approval_request("request-id")))

-- Show system status
:lua require("paragonic.mcp").show_system_status()
```

### Getting Help

1. **Check documentation** - Review this tutorial
2. **Use debug commands** - See system status
3. **Restart Neovim** - Reinitialize the system
4. **Check logs** - Look for error messages

---

## Quick Reference

### Key Mappings

| Action | Key | Description |
|--------|-----|-------------|
| Quick Approve | `ya` | Approve marker under cursor |
| Quick Deny | `nd` | Deny marker under cursor |
| Show Details | `gd` | Show marker details |
| Context Menu | `<C-m>` | Show context menu |
| Options Menu | `<CR>` | Show options menu |
| Visual Approve | `ya` | Approve selected markers |
| Visual Deny | `nd` | Deny selected markers |

### Status Indicators

| Status | Symbol | Meaning |
|--------|--------|---------|
| Pending | 🔄 | Waiting for approval |
| Approved | 🆗 | Action approved |
| Denied | ⛔ | Action denied |
| Timeout | ⏰ | Request timed out |

### Marker Types

| Type | Description |
|------|-------------|
| `[tool_execution]` | File operations |
| `[decision_point]` | User choices needed |
| `[batch_action]` | Multiple operations |

### Common Commands

```lua
-- Open chat
:lua require("paragonic.chat").open_chat()

-- Initialize system
:lua require("paragonic.mcp").initialize_mcp_server()

-- Setup mappings
:lua require("paragonic.mcp").setup_chat_buffer_mappings()

-- Show status
:lua require("paragonic.mcp").show_system_status()
```

---

## Next Steps

Now that you understand the basics, try these exercises:

1. **Start a simple project** - Ask AI to create a basic application
2. **Practice approvals** - Use different methods to process markers
3. **Try batch operations** - Select multiple markers and approve/deny
4. **Explore advanced features** - Use decision points and complex requests

### Advanced Topics to Explore

- **Custom approval workflows** - Configure auto-approval rules
- **Integration with other tools** - Connect with external systems
- **Performance optimization** - Handle large numbers of approvals
- **Custom markers** - Create specialized approval types

---

## Support and Resources

- **Documentation**: Check the main Paragonic documentation
- **Examples**: Review the demo scripts in the project
- **Community**: Join the Paragonic community discussions
- **Issues**: Report bugs and request features

Happy chatting with Paragonic! 🎉
