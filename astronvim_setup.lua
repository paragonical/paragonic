-- AstroNvim Configuration for Paragonic Plugin
-- Add this to your AstroNvim user configuration

-- AstroNvim uses Lazy.nvim, so we need to add the plugin to the plugins table
-- This should go in your user/plugins/ directory or in your user/init.lua

return {
  -- Paragonic Plugin for AI Agent Collaboration
  {
    dir = "~/work2/paragonic",  -- Change this to your actual project path
    name = "paragonic",
    config = function()
      require('paragonic')
    end,
    lazy = false,  -- Load immediately
    priority = 1000,  -- High priority to load early
    enabled = true,
    -- Optional: Add to AstroNvim's plugin management
    dependencies = {},
    -- Optional: Add to specific file types if needed
    ft = {},
    -- Optional: Add to specific events if needed
    event = {},
  },
} 