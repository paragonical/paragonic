# Approval Configuration Guide

This guide explains how to configure auto-approval patterns and YOLO mode for the Paragonic MCP approval system.

## Overview

The approval configuration system allows you to customize when and how AI agent tool requests are automatically approved, reducing the need for manual intervention while maintaining safety.

## Quick Start

### Basic Commands

```lua
-- Toggle YOLO mode (bypasses all approvals)
:lua require('paragonic.mcp').toggle_yolo_mode()

-- Show current configuration
:lua require('paragonic.mcp').show_approval_config()

-- Add a tool to auto-approval
:lua require('paragonic.mcp').add_auto_approval_tool('agent_edit_file')

-- Add a directory to auto-approval
:lua require('paragonic.mcp').add_auto_approval_directory('temp/')
```

## Configuration Options

### 1. YOLO Mode

**⚠️ DANGER: YOLO mode bypasses ALL safety checks!**

YOLO mode is a "You Only Live Once" setting that automatically approves ALL tool requests without any safety checks.

```lua
-- Enable YOLO mode
:lua require('paragonic.mcp').enable_yolo_mode()

-- Disable YOLO mode
:lua require('paragonic.mcp').disable_yolo_mode()

-- Toggle YOLO mode
:lua require('paragonic.mcp').toggle_yolo_mode()
```

**Use Cases:**
- Development environments where you trust the AI completely
- Automated workflows where speed is critical
- Testing scenarios where you want to bypass all approvals

**⚠️ Warnings:**
- YOLO mode will approve dangerous operations
- No file content validation
- No directory restrictions
- Use with extreme caution!

### 2. Auto-Approval Patterns

Auto-approval patterns allow you to automatically approve specific types of requests based on various criteria.

#### Tool-Based Patterns

Automatically approve specific tools:

```lua
-- Add a tool to auto-approval
:lua require('paragonic.mcp').add_auto_approval_tool('agent_session_info')

-- Remove a tool from auto-approval
:lua require('paragonic.mcp').remove_auto_approval_tool('agent_edit_file')
```

**Default Auto-Approved Tools:**
- `agent_session_info` - Session information queries
- `agent_search_files` - File search operations
- `file_search` - File search operations
- `buffer_navigate` - Buffer navigation

#### File Operation Patterns

Automatically approve file operations based on location, extension, or content.

**Directory-Based Auto-Approval:**
```lua
-- Add a directory to auto-approval
:lua require('paragonic.mcp').add_auto_approval_directory('temp/')
:lua require('paragonic.mcp').add_auto_approval_directory('logs/')
:lua require('paragonic.mcp').add_auto_approval_directory('cache/')
```

**Default Auto-Approved Directories:**
- `temp/` - Temporary files
- `tmp/` - Temporary files
- `logs/` - Log files
- `cache/` - Cache files

**Extension-Based Auto-Approval:**
```lua
-- Add an extension to auto-approval
:lua require('paragonic.mcp').add_auto_approval_extension('.tmp')
:lua require('paragonic.mcp').add_auto_approval_extension('.log')
```

**Default Auto-Approved Extensions:**
- `.tmp` - Temporary files
- `.log` - Log files
- `.cache` - Cache files
- `.bak` - Backup files

**Content-Based Auto-Approval:**
- **Size Limit:** Files with content ≤ 100 characters
- **Pattern Matching:** Content matching specific patterns:
  - `^-- .*$` - Comments (Lua, SQL)
  - `^# .*$` - Markdown headers
  - `^// .*$` - C-style comments
  - `^%. .*$` - Vim comments

#### Command Patterns

Automatically approve specific commands:

**Neovim Commands:**
- `buffers` - List buffers
- `ls` - List buffers
- `pwd` - Show current directory
- `version` - Show version

**Shell Commands:**
- `ls` - List files
- `pwd` - Show current directory
- `date` - Show current date
- `whoami` - Show current user

### 3. Time-Based Patterns

Automatically approve requests during specific time windows:

```lua
-- Enable time-based auto-approval
local config = require('paragonic.approval_config')
config.config.auto_approval.time_based.enabled = true

-- Configure allowed hours (24-hour format)
config.config.auto_approval.time_based.allowed_hours = {9, 10, 11, 12, 13, 14, 15, 16, 17, 18}

-- Configure allowed days (1=Monday, 7=Sunday)
config.config.auto_approval.time_based.allowed_days = {1, 2, 3, 4, 5} -- Weekdays only
```

### 4. Session-Based Patterns

Automatically approve requests based on session history:

```lua
-- Enable session-based auto-approval
local config = require('paragonic.approval_config')
config.config.auto_approval.session_based.enabled = true

-- Auto-approve after N successful approvals in session
config.config.auto_approval.session_based.trust_threshold = 5

-- Auto-approve if user has approved similar requests before
config.config.auto_approval.session_based.similarity_threshold = 0.8
```

## Configuration Management

### Save and Load Configuration

```lua
-- Save current configuration to file
:lua require('paragonic.mcp').save_approval_config()

-- Load configuration from file
:lua require('paragonic.mcp').load_approval_config()

-- Save to specific file
:lua require('paragonic.mcp').save_approval_config('/path/to/config.json')

-- Load from specific file
:lua require('paragonic.mcp').load_approval_config('/path/to/config.json')
```

### Configuration File Format

The configuration is saved as JSON:

```json
{
  "yolo_mode": false,
  "auto_approval": {
    "enabled": true,
    "patterns": {
      "tools": ["agent_session_info", "agent_search_files"],
      "file_operations": {
        "create_in_dirs": ["temp/", "logs/"],
        "create_extensions": [".tmp", ".log"],
        "edit_file_types": ["*.tmp", "*.log"]
      },
      "commands": {
        "neovim_commands": ["buffers", "ls"],
        "shell_commands": ["ls", "pwd"]
      },
      "content": {
        "patterns": ["^-- .*$", "^# .*$"],
        "max_auto_approve_size": 100
      }
    },
    "time_based": {
      "enabled": false,
      "allowed_hours": [9, 10, 11, 12, 13, 14, 15, 16, 17, 18],
      "allowed_days": [1, 2, 3, 4, 5, 6, 7]
    },
    "session_based": {
      "enabled": true,
      "trust_threshold": 5,
      "similarity_threshold": 0.8
    }
  },
  "timeout": {
    "default_timeout": 30,
    "file_operations_timeout": 60,
    "batch_operations_timeout": 120,
    "decision_points_timeout": 180
  },
  "notifications": {
    "show_auto_approval_notifications": true,
    "show_yolo_mode_warnings": true,
    "notification_duration": 3
  }
}
```

## Advanced Configuration

### Custom Configuration in init.lua

You can configure auto-approval patterns in your Neovim configuration:

```lua
-- In your init.lua or init.vim
require('paragonic').setup({
  approval_config = {
    yolo_mode = false,
    auto_approval = {
      enabled = true,
      patterns = {
        tools = {
          "agent_session_info",
          "agent_search_files",
          "my_custom_tool"
        },
        file_operations = {
          create_in_dirs = {
            "temp/",
            "logs/",
            "my_project/temp/"
          },
          create_extensions = {
            ".tmp",
            ".log",
            ".test"
          }
        }
      }
    }
  }
})
```

### Programmatic Configuration

```lua
-- Get approval configuration module
local approval_config = require('paragonic.approval_config')

-- Load custom configuration
approval_config.load_config({
  yolo_mode = false,
  auto_approval = {
    enabled = true,
    patterns = {
      tools = {"agent_session_info", "agent_search_files"}
    }
  }
})

-- Check if a tool should be auto-approved
local should_approve, reason = approval_config.should_auto_approve_tool("agent_create_file", {
  file_name = "temp/test.log"
})
print("Should approve:", should_approve)
print("Reason:", reason)
```

## Safety Considerations

### 1. YOLO Mode Safety

- **Never use YOLO mode in production environments**
- **Always test in isolated development environments**
- **Monitor all AI agent activities when YOLO mode is enabled**
- **Have backup and recovery procedures in place**

### 2. Auto-Approval Pattern Safety

- **Start with conservative patterns**
- **Gradually expand auto-approval as you build trust**
- **Regularly review and audit auto-approval patterns**
- **Monitor for unexpected auto-approvals**

### 3. File Operation Safety

- **Be careful with directory-based auto-approval**
- **Avoid auto-approving operations in critical directories**
- **Use content size limits to prevent large file creation**
- **Consider file type restrictions**

### 4. Command Safety

- **Only auto-approve read-only commands initially**
- **Avoid auto-approving commands that modify system state**
- **Be cautious with shell command auto-approval**
- **Consider command parameter validation**

## Best Practices

### 1. Gradual Configuration

1. **Start with default settings**
2. **Enable auto-approval for safe tools first**
3. **Add directory-based patterns for temporary files**
4. **Expand to more complex patterns as needed**
5. **Use YOLO mode only for specific development tasks**

### 2. Monitoring and Auditing

1. **Regularly check approval system status**
2. **Review auto-approval patterns periodically**
3. **Monitor for unexpected auto-approvals**
4. **Keep logs of all approval decisions**

### 3. Environment-Specific Configuration

1. **Development:** More permissive auto-approval
2. **Testing:** Moderate auto-approval with safety checks
3. **Production:** Conservative auto-approval or manual approval only

### 4. Team Configuration

1. **Share configuration files with team members**
2. **Document auto-approval patterns and reasoning**
3. **Establish approval policies and procedures**
4. **Train team members on safety considerations**

## Troubleshooting

### Common Issues

**Auto-approval not working:**
```lua
-- Check if auto-approval is enabled
:lua require('paragonic.mcp').show_approval_config()

-- Verify tool is in auto-approval list
:lua require('paragonic.mcp').add_auto_approval_tool('tool_name')
```

**YOLO mode not working:**
```lua
-- Check YOLO mode status
:lua require('paragonic.mcp').show_approval_config()

-- Enable YOLO mode
:lua require('paragonic.mcp').enable_yolo_mode()
```

**Configuration not persisting:**
```lua
-- Save configuration
:lua require('paragonic.mcp').save_approval_config()

-- Load configuration
:lua require('paragonic.mcp').load_approval_config()
```

### Debug Commands

```lua
-- Show detailed configuration
:lua print(vim.inspect(require('paragonic.approval_config').get_config()))

-- Test auto-approval for specific tool
:lua local config = require('paragonic.approval_config'); print(config.should_auto_approve_tool('agent_create_file', {file_name='test.txt'}))
```

## Examples

### Development Environment Configuration

```lua
-- Development setup with permissive auto-approval
require('paragonic.approval_config').load_config({
  yolo_mode = false,
  auto_approval = {
    enabled = true,
    patterns = {
      tools = {
        "agent_session_info",
        "agent_search_files",
        "agent_create_file",
        "agent_edit_file"
      },
      file_operations = {
        create_in_dirs = {"temp/", "logs/", "test/"},
        create_extensions = {".tmp", ".log", ".test"},
        edit_file_types = {"*.tmp", "*.log", "*.test"}
      }
    }
  }
})
```

### Production Environment Configuration

```lua
-- Production setup with conservative auto-approval
require('paragonic.approval_config').load_config({
  yolo_mode = false,
  auto_approval = {
    enabled = true,
    patterns = {
      tools = {
        "agent_session_info",
        "agent_search_files"
      },
      file_operations = {
        create_in_dirs = {"logs/"},
        create_extensions = {".log"},
        edit_file_types = {"*.log"}
      }
    }
  }
})
```

### Testing Environment Configuration

```lua
-- Testing setup with YOLO mode for automation
require('paragonic.approval_config').load_config({
  yolo_mode = true,  -- Enable for automated testing
  auto_approval = {
    enabled = true,
    patterns = {
      tools = {
        "agent_session_info",
        "agent_search_files",
        "agent_create_file",
        "agent_edit_file",
        "agent_execute_command"
      }
    }
  }
})
```

## Conclusion

The approval configuration system provides flexible control over when AI agent requests are automatically approved. Start with conservative settings and gradually expand as you build trust in the system. Always prioritize safety and use YOLO mode with extreme caution.

For more information, see the demo files:
- `demo_approval_configuration.lua` - Interactive configuration demo
- `demo_agent_mcp_tools.lua` - Agent MCP tools integration demo
- `demo_agent_approval_workflow.lua` - Approval workflow demo
