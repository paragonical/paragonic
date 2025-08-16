--[[
Quick Test Runner for Thinking Callback Functionality
Run this script to quickly diagnose and test the thinking callback issue
--]]

-- Load the test suite
local test_suite = require("tests.unit.chat.test_thinking_callback_automation")

-- Check if we're in Neovim
if not vim then
    print("❌ This script must be run in Neovim")
    os.exit(1)
end

-- Parse command line arguments
local args = {...}
local mode = args[1] or "quick"

if mode == "quick" then
    print("🔍 Running Quick Diagnostic...")
    test_suite.quick_diagnostic()
elseif mode == "full" then
    print("🧪 Running Full Test Suite...")
    test_suite.run_all_tests()
elseif mode == "help" then
    print("Usage: lua run_thinking_callback_tests.lua [mode]")
    print("Modes:")
    print("  quick  - Run quick diagnostic (default)")
    print("  full   - Run full test suite")
    print("  help   - Show this help")
else
    print("❌ Unknown mode: " .. mode)
    print("Use 'help' mode to see available options")
end
