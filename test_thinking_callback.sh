#!/bin/bash

# Test script for thinking callback functionality
# This script runs automated tests to diagnose the thinking callback issue

set -e

echo "🧪 Paragonic Thinking Callback Test Suite"
echo "=========================================="

# Check if we're in the right directory
if [ ! -f "lua/paragonic/chat.lua" ]; then
    echo "❌ Error: Must run from paragonic project root"
    exit 1
fi

# Function to run test in Neovim
run_test() {
    local test_mode=$1
    echo "🔍 Running $test_mode test..."
    
    # Create a temporary test script
    cat > /tmp/paragonic_test.lua << EOF
-- Temporary test script
vim.cmd("source lua/paragonic/init.lua")
local test_suite = require("tests.unit.chat.test_thinking_callback_automation")
test_suite.$test_mode()
EOF

    # Run the test in Neovim
    nvim --headless --noplugin -c "lua dofile('/tmp/paragonic_test.lua')" -c "q"
    
    # Clean up
    rm -f /tmp/paragonic_test.lua
}

# Parse command line arguments
case "${1:-quick}" in
    "quick")
        run_test "quick_diagnostic"
        ;;
    "full")
        run_test "run_all_tests"
        ;;
    "help")
        echo "Usage: $0 [mode]"
        echo "Modes:"
        echo "  quick  - Run quick diagnostic (default)"
        echo "  full   - Run full test suite"
        echo "  help   - Show this help"
        ;;
    *)
        echo "❌ Unknown mode: $1"
        echo "Use 'help' mode to see available options"
        exit 1
        ;;
esac

echo "✅ Test completed!"
