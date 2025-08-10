#!/bin/bash

# Create Proper Neovim Plugin Structure
# This creates a distributable plugin structure

echo "=== Creating Neovim Plugin Structure ==="

# Create plugin directory
PLUGIN_DIR="paragonic.nvim"
echo "📁 Creating plugin directory: $PLUGIN_DIR"

# Remove existing directory if it exists
if [ -d "$PLUGIN_DIR" ]; then
    echo "🗑️  Removing existing directory..."
    rm -rf "$PLUGIN_DIR"
fi

# Create directory structure
mkdir -p "$PLUGIN_DIR"
mkdir -p "$PLUGIN_DIR/lua"
mkdir -p "$PLUGIN_DIR/plugin"
mkdir -p "$PLUGIN_DIR/doc"
mkdir -p "$PLUGIN_DIR/README"

# Copy plugin files
echo "📋 Copying plugin files..."
cp -r lua/paragonic "$PLUGIN_DIR/lua/"

# Create plugin loader
cat > "$PLUGIN_DIR/plugin/paragonic.vim" << 'EOF'
" Paragonic Plugin - AI Agent Collaboration for Neovim
" Version: 0.1.0
" Author: Your Name
" Description: AI agent collaboration system for Neovim

" Check if already loaded
if exists('g:paragonic_loaded')
    finish
endif

" Plugin metadata
let g:paragonic_version = "0.1.0"
let g:paragonic_loaded = 1

" Load the main plugin
lua require('paragonic')
EOF

# Create README
cat > "$PLUGIN_DIR/README.md" << 'EOF'
# Paragonic - AI Agent Collaboration for Neovim

A Neovim plugin that enables AI agent collaboration through session management, message exchange, and buffer manipulation.

## Features

- **AI Agent Session Management**: Start, stop, and manage AI agent collaboration sessions
- **Message Exchange**: Two-way communication between AI agents and Neovim
- **Command Execution**: AI agents can execute Neovim commands
- **Buffer Operations**: Read and write buffer content from AI agents
- **Real-time Context**: Capture and update Neovim context during sessions

## Installation

### Using Packer
```lua
use {
    'your-username/paragonic.nvim',
    config = function()
        require('paragonic')
    end
}
```

### Using Lazy.nvim
```lua
{
    'your-username/paragonic.nvim',
    config = function()
        require('paragonic')
    end,
    lazy = false,
}
```

### Manual Installation
1. Clone this repository to your Neovim plugins directory
2. Add `require('paragonic')` to your Neovim config

## Usage

### Basic Commands

```vim
" Start AI agent collaboration
:ParagonicAIAgentStart CodeAssistant

" Check session status
:ParagonicAIAgentStatus

" Send message from AI agent
:ParagonicAIAgentMessage Hello Neovim

" Receive message from Neovim
:ParagonicAIAgentReceive User feedback

" Execute Neovim command
:ParagonicAIAgentCommand echo 'Hello World'

" Read buffer content
:ParagonicAIAgentBuffer

" Write buffer content
:ParagonicAIAgentBufferWrite 1 New line 1 New line 2

" Stop collaboration
:ParagonicAIAgentStop
```

### Programmatic Usage

```lua
-- Start session
local session_id = require('paragonic').start_ai_agent_session("MyAgent")

-- Send message
local success, msg_id = require('paragonic').send_ai_agent_message("Hello")

-- Execute command
local success, cmd_id = require('paragonic').execute_ai_agent_command("echo 'test'")

-- Read buffer
local success, read_id, result = require('paragonic').get_ai_agent_buffer_content()

-- Write buffer
local success, write_id = require('paragonic').set_ai_agent_buffer_content(nil, {"New content"})

-- Stop session
require('paragonic').stop_ai_agent_session()
```

## Configuration

The plugin works out of the box with default settings. No configuration required.

## Requirements

- Neovim 0.8.0 or higher
- Lua 5.1 or higher

## License

MIT License
EOF

# Create help documentation
cat > "$PLUGIN_DIR/doc/paragonic.txt" << 'EOF'
*paragonic.txt*    AI Agent Collaboration for Neovim

==============================================================================
CONTENTS                                                    *paragonic-contents*

Introduction        |paragonic-introduction|
Installation        |paragonic-installation|
Commands           |paragonic-commands|
Functions          |paragonic-functions|
Configuration      |paragonic-configuration|

==============================================================================
INTRODUCTION                                                *paragonic-introduction*

Paragonic is a Neovim plugin that enables AI agent collaboration through
session management, message exchange, and buffer manipulation.

Features:
- AI Agent Session Management
- Message Exchange System
- Command Execution
- Buffer Operations
- Real-time Context Updates

==============================================================================
INSTALLATION                                              *paragonic-installation*

Add to your Neovim config:

    lua require('paragonic')

==============================================================================
COMMANDS                                                   *paragonic-commands*

:ParagonicAIAgentStart {agent_name}    Start AI agent collaboration session
:ParagonicAIAgentStop                  Stop active AI agent session
:ParagonicAIAgentStatus                Display current session status
:ParagonicAIAgentMessage {message}     Send message from AI agent
:ParagonicAIAgentReceive {message}     Send message from Neovim
:ParagonicAIAgentCommand {command}     Execute Neovim command
:ParagonicAIAgentBuffer [id] [start] [end]  Read buffer content
:ParagonicAIAgentBufferWrite {id} {line1} {line2} ...  Write buffer content

==============================================================================
FUNCTIONS                                                  *paragonic-functions*

start_ai_agent_session(agent_name, capabilities)
    Start a new AI agent collaboration session

stop_ai_agent_session()
    Stop the current AI agent session

get_ai_agent_session_status()
    Get current session status

send_ai_agent_message(message, message_type)
    Send message from AI agent to Neovim

receive_ai_agent_message(message, message_type)
    Send message from Neovim to AI agent

execute_ai_agent_command(command, description)
    Execute Neovim command from AI agent

get_ai_agent_buffer_content(buffer_id, start_line, end_line)
    Read buffer content from AI agent

set_ai_agent_buffer_content(buffer_id, lines, start_line, end_line)
    Write buffer content from AI agent

==============================================================================
CONFIGURATION                                          *paragonic-configuration*

No configuration required. The plugin works with default settings.

==============================================================================

vim:tw=78:ts=8:ft=help:norl:
EOF

# Create tags for help
cat > "$PLUGIN_DIR/doc/tags" << 'EOF'
paragonic-contents	paragonic.txt	/*paragonic-contents*
paragonic-introduction	paragonic.txt	/*paragonic-introduction*
paragonic-installation	paragonic.txt	/*paragonic-installation*
paragonic-commands	paragonic.txt	/*paragonic-commands*
paragonic-functions	paragonic.txt	/*paragonic-functions*
paragonic-configuration	paragonic.txt	/*paragonic-configuration*
EOF

echo "✅ Plugin structure created!"
echo ""
echo "📁 Plugin directory: $PLUGIN_DIR"
echo ""
echo "📋 Files created:"
echo "   - lua/paragonic/ - Main plugin code"
echo "   - plugin/paragonic.vim - Plugin loader"
echo "   - README.md - Documentation"
echo "   - doc/paragonic.txt - Help documentation"
echo ""
echo "🚀 To install:"
echo "   1. Copy $PLUGIN_DIR to your Neovim plugins directory"
echo "   2. Add 'require(\"paragonic\")' to your Neovim config"
echo ""
echo "📚 To generate help tags:"
echo "   :helptags ~/.config/nvim/plugins/paragonic.nvim/doc" 