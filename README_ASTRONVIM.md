# Paragonic Plugin for AstroNvim

AI Agent Collaboration plugin for AstroNvim users.

## 🚀 Quick Installation

### Option 1: Automatic Installation (Recommended)
```bash
# Run the AstroNvim installation script
./astronvim_install.sh
```

### Option 2: Manual Installation

1. **Create the AstroNvim user directory structure** (if it doesn't exist):
   ```bash
   mkdir -p ~/.config/nvim/lua/user/plugins
   ```

2. **Create a basic user configuration** (optional):
   ```lua
   -- ~/.config/nvim/lua/user/init.lua
   return {
     plugins = {
       -- Your plugins will go here
     },
   }
   ```

2. **Create `~/.config/nvim/lua/user/plugins/paragonic.lua`**:
   ```lua
   return {
     -- Paragonic Plugin for AI Agent Collaboration
     {
       dir = "~/work2/paragonic",  -- Change to your project path
       name = "paragonic",
       config = function()
         require('paragonic')
       end,
       lazy = false,  -- Load immediately
       priority = 1000,  -- High priority to load early
       enabled = true,
     },
   }
   ```

3. **Sync AstroNvim**:
   ```vim
   :AstroSync
   ```

## 🧪 Testing Installation

### Quick Test
```vim
:ParagonicAIAgentStart TestAgent
```

### Comprehensive Test
```bash
nvim -c "lua dofile('test_installation.lua')"
```

### Integration Test
```bash
./run_integration_test.sh
```

## 🎯 Available Commands

Once installed, you'll have these commands available:

### Session Management
- `:ParagonicAIAgentStart <agent_name>` - Start AI agent collaboration session
- `:ParagonicAIAgentStop` - Stop active AI agent session
- `:ParagonicAIAgentStatus` - Display current session status

### Message Exchange
- `:ParagonicAIAgentMessage <message>` - Send message from AI agent to Neovim
- `:ParagonicAIAgentReceive <message>` - Send message from Neovim to AI agent

### Command Execution
- `:ParagonicAIAgentCommand <command>` - Execute Neovim command from AI agent

### Buffer Operations
- `:ParagonicAIAgentBuffer [id] [start] [end]` - Read buffer content
- `:ParagonicAIAgentBufferWrite <id> <line1> <line2> ...` - Write buffer content

## 📝 Usage Examples

### Basic Workflow
```vim
" Start AI agent collaboration
:ParagonicAIAgentStart CodeAssistant

" Check session status
:ParagonicAIAgentStatus

" Send message from AI agent
:ParagonicAIAgentMessage Hello Neovim

" Execute a command
:ParagonicAIAgentCommand echo 'Hello World'

" Read current buffer
:ParagonicAIAgentBuffer

" Write to buffer
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

## 🔧 Configuration

The plugin works out of the box with AstroNvim. No additional configuration required.

### Optional: Custom Configuration

If you want to customize the plugin, you can add configuration to your AstroNvim user config:

```lua
-- In ~/.config/nvim/lua/user/init.lua
return {
  plugins = {
    -- Your other plugins...
  },
  -- Optional: Add custom configuration
  paragonic = {
    -- Add any custom settings here
  },
}
```

## 🐛 Troubleshooting

### Plugin Not Loading
1. Check that the plugin file exists: `~/.config/nvim/lua/user/plugins/paragonic.lua`
2. Verify the project path is correct in the configuration
3. Run `:AstroSync` to sync plugins
4. Check `:messages` for any error messages
5. Ensure AstroNvim is properly installed (the script will create user directories but not AstroNvim itself)

### Commands Not Available
1. Restart Neovim after installation
2. Check that the plugin loaded: `:lua print(require('paragonic') ~= nil)`
3. Verify the plugin is enabled in your configuration

### Testing Issues
1. Run the integration test: `./run_integration_test.sh`
2. Check that Neovim version is 0.8.0 or higher: `:version`
3. Verify Lua is available: `:lua print(_VERSION)`

## 📚 Additional Resources

- [AstroNvim Documentation](https://astronvim.com/)
- [AstroNvim User Configuration](https://astronvim.com/Configuration/user_config)
- [Lazy.nvim Plugin Management](https://github.com/folke/lazy.nvim)

## 🎉 Features

- **AI Agent Session Management**: Start, stop, and manage AI agent collaboration sessions
- **Message Exchange**: Two-way communication between AI agents and Neovim
- **Command Execution**: AI agents can execute Neovim commands
- **Buffer Operations**: Read and write buffer content from AI agents
- **Real-time Context**: Capture and update Neovim context during sessions
- **AstroNvim Integration**: Seamless integration with AstroNvim's plugin system

## 📋 Requirements

- AstroNvim (latest version)
- Neovim 0.8.0 or higher
- Lua 5.1 or higher

## 📄 License

MIT License 