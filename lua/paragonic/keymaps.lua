--[[
Paragonic Keymaps Module
Handles keyboard mappings and setup
--]]

local M = {}

-- Setup keyboard mappings
function M._setup_keymaps()
    -- Global keymaps
    vim.api.nvim_set_keymap("n", "<leader>pc", ":ParagonicChat<CR>", {noremap = true, silent = true, desc = "Open Paragonic Chat"})
    vim.api.nvim_set_keymap("n", "<leader>pp", ":ParagonicProjects<CR>", {noremap = true, silent = true, desc = "Open Paragonic Projects"})
    vim.api.nvim_set_keymap("n", "<leader>pC", ":ParagonicConfig<CR>", {noremap = true, silent = true, desc = "Open Paragonic Config"})
    vim.api.nvim_set_keymap("n", "<leader>pd", ":ParagonicDebug<CR>", {noremap = true, silent = true, desc = "Open Paragonic Debug"})
    vim.api.nvim_set_keymap("n", "<leader>ps", ":ParagonicSend<CR>", {noremap = true, silent = true, desc = "Send Paragonic Message"})
    vim.api.nvim_set_keymap("n", "<leader>pS", ":ParagonicSendDebug<CR>", {noremap = true, silent = true, desc = "Send Paragonic Message (Debug)"})
    
    -- Search keymaps
    vim.api.nvim_set_keymap("n", "<leader>psb", ":ParagonicSearch ", {noremap = true, silent = false, desc = "Paragonic Basic Search"})
    vim.api.nvim_set_keymap("n", "<leader>psf", ":ParagonicSearchFiltered ", {noremap = true, silent = false, desc = "Paragonic Filtered Search"})
    vim.api.nvim_set_keymap("n", "<leader>psh", ":ParagonicSearchHybrid ", {noremap = true, silent = false, desc = "Paragonic Hybrid Search"})
    vim.api.nvim_set_keymap("n", "<leader>psH", ":ParagonicSearchHistory<CR>", {noremap = true, silent = true, desc = "Show Search History"})
    vim.api.nvim_set_keymap("n", "<leader>psS", ":ParagonicSavedSearches<CR>", {noremap = true, silent = true, desc = "Show Saved Searches"})
    vim.api.nvim_set_keymap("n", "<leader>pss", ":ParagonicSaveSearch<CR>", {noremap = true, silent = true, desc = "Save Current Search"})
    
    -- AI Agent keymaps
    vim.api.nvim_set_keymap("n", "<leader>paa", ":ParagonicAIAgentStart ", {noremap = true, silent = false, desc = "Start AI Agent Session"})
    vim.api.nvim_set_keymap("n", "<leader>paA", ":ParagonicAIAgentStop<CR>", {noremap = true, silent = true, desc = "Stop AI Agent Session"})
    vim.api.nvim_set_keymap("n", "<leader>pas", ":ParagonicAIAgentStatus<CR>", {noremap = true, silent = true, desc = "Show AI Agent Status"})
    vim.api.nvim_set_keymap("n", "<leader>pam", ":ParagonicAIAgentMessage ", {noremap = true, silent = false, desc = "Send AI Agent Message"})
    vim.api.nvim_set_keymap("n", "<leader>par", ":ParagonicAIAgentReceive ", {noremap = true, silent = false, desc = "Receive AI Agent Message"})
    vim.api.nvim_set_keymap("n", "<leader>pac", ":ParagonicAIAgentCommand ", {noremap = true, silent = false, desc = "Execute AI Agent Command"})
    
    -- MCP keymaps
    vim.api.nvim_set_keymap("n", "<leader>pmi", ":ParagonicMCPInit<CR>", {noremap = true, silent = true, desc = "Initialize MCP Server"})
    vim.api.nvim_set_keymap("n", "<leader>pmr", ":ParagonicMCPResources<CR>", {noremap = true, silent = true, desc = "Show MCP Resources"})
    vim.api.nvim_set_keymap("n", "<leader>pmt", ":ParagonicMCPTools<CR>", {noremap = true, silent = true, desc = "Show MCP Tools"})
    vim.api.nvim_set_keymap("n", "<leader>pmR", ":ParagonicMCPReadResource ", {noremap = true, silent = false, desc = "Read MCP Resource"})
    vim.api.nvim_set_keymap("n", "<leader>pms", ":ParagonicMCPSample ", {noremap = true, silent = false, desc = "Sample MCP Resource"})
    vim.api.nvim_set_keymap("n", "<leader>pmR", ":ParagonicMCPRoots ", {noremap = true, silent = false, desc = "Show MCP Resource Roots"})
    
    -- Connection management
    vim.api.nvim_set_keymap("n", "<leader>pr", ":ParagonicReconnect<CR>", {noremap = true, silent = true, desc = "Reconnect to Backend"})
    
    -- Data management
    vim.api.nvim_set_keymap("n", "<leader>pe", ":ParagonicExportData<CR>", {noremap = true, silent = true, desc = "Export Data"})
    vim.api.nvim_set_keymap("n", "<leader>pi", ":ParagonicImportData<CR>", {noremap = true, silent = true, desc = "Import Data"})
    vim.api.nvim_set_keymap("n", "<leader>pb", ":ParagonicBackupData<CR>", {noremap = true, silent = true, desc = "Backup Data"})
    
    -- Test keymap
    vim.api.nvim_set_keymap("n", "<leader>pt", ":ParagonicTest<CR>", {noremap = true, silent = true, desc = "Test Paragonic"})
end

return M
