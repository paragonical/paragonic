#!/bin/bash

# Fix AstroNvim Installation Script
# This adds the Paragonic plugin to the correct user.lua file

echo "=== Fixing AstroNvim Installation ==="

# Get the user.lua file path
USER_LUA="$HOME/.config/nvim/lua/plugins/user.lua"
BACKUP_LUA="$HOME/.config/nvim/lua/plugins/user.lua.backup"

echo "📁 User.lua file: $USER_LUA"

# Check if user.lua exists
if [ ! -f "$USER_LUA" ]; then
    echo "❌ Error: user.lua file not found"
    echo "   Expected: $USER_LUA"
    exit 1
fi

# Create backup
echo "📋 Creating backup: $BACKUP_LUA"
cp "$USER_LUA" "$BACKUP_LUA"

# Get current directory (project path)
PROJECT_PATH=$(pwd)
echo "📁 Project path: $PROJECT_PATH"

# Create temporary file with Paragonic plugin added
echo "📝 Adding Paragonic plugin to user.lua..."

# Create a temporary file
TEMP_FILE=$(mktemp)

# Read the original file and add the plugin
awk -v project_path="$PROJECT_PATH" '
{
    print $0
    if ($0 ~ /^}$/) {
        print "  -- == Paragonic AI Agent Plugin =="
        print "  {"
        print "    dir = \"" project_path "\",  -- Your project path"
        print "    name = \"paragonic\","
        print "    config = function()"
        print "      require(\"paragonic\")"
        print "    end,"
        print "    lazy = false,  -- Load immediately"
        print "    priority = 1000,  -- High priority to load early"
        print "    enabled = true,"
        print "  },"
    }
}' "$USER_LUA" > "$TEMP_FILE"

# Replace the original file
mv "$TEMP_FILE" "$USER_LUA"

echo "✅ Paragonic plugin added to user.lua!"
echo ""
echo "📝 Next steps:"
echo "   1. Restart Neovim or run :Lazy sync"
echo "   2. Test the plugin with: :ParagonicAIAgentStart TestAgent"
echo ""
echo "🚀 Available commands:"
echo "   :ParagonicAIAgentStart <agent_name>  - Start AI agent session"
echo "   :ParagonicAIAgentStop                - Stop AI agent session"
echo "   :ParagonicAIAgentStatus              - Show session status"
echo "   :ParagonicAIAgentMessage <message>   - Send AI agent message"
echo "   :ParagonicAIAgentReceive <message>   - Receive Neovim message"
echo "   :ParagonicAIAgentCommand <command>   - Execute Neovim command"
echo "   :ParagonicAIAgentBuffer [id] [start] [end] - Read buffer content"
echo "   :ParagonicAIAgentBufferWrite <id> <line1> <line2> ... - Write buffer content"
echo ""
echo "🧪 To test the installation:"
echo "   nvim -c \"ParagonicAIAgentStart TestAgent\""
echo ""
echo "📁 Backup created: $BACKUP_LUA"
echo "📁 Project path: $PROJECT_PATH" 