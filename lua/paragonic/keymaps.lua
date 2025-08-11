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
    vim.api.nvim_set_keymap("n", "<leader>ps", ":ParagonicSendSmart<CR>", {noremap = true, silent = true, desc = "Send Paragonic Message (Smart)"})
    vim.api.nvim_set_keymap("n", "<leader>pS", ":ParagonicSendDebug<CR>", {noremap = true, silent = true, desc = "Send Paragonic Message (Debug)"})
    vim.api.nvim_set_keymap("n", "<leader>PM", ":ParagonicDebugMarkdown<CR>", {noremap = true, silent = true, desc = "Send Debug Markdown Test"})
    
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
    
    -- Pattern-aware session keymaps
    vim.api.nvim_set_keymap("n", "<leader>pap", ":ParagonicAIAgentExecutePattern ", {noremap = true, silent = false, desc = "Execute Pattern in Session"})
    vim.api.nvim_set_keymap("n", "<leader>pat", ":ParagonicAIAgentCheckPatterns<CR>", {noremap = true, silent = true, desc = "Check Pattern Triggers"})
    
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

-- Which-key integration for Paragonic commands
function M.setup_which_key()
    -- Check if we're in Neovim environment
    if not vim then
        return
    end
    
    -- Check if which-key is available
    local ok, wk = pcall(require, "which-key")
    if not ok or not wk then
        local debug = require("paragonic.debug")
        debug.debug_print("which-key not available, skipping integration", "warning")
        return
    end
    
    -- Register Paragonic keymaps with which-key (new spec format)
    wk.add({
        { "<leader>P", group = "🚀 Paragonic", icon = "🚀" },
        { "<leader>Ps", "<cmd>ParagonicSearch<CR>", desc = "🔍 Basic Search" },
        { "<leader>Pf", "<cmd>ParagonicSearchFiltered<CR>", desc = "🔍 Filtered Search" },
        { "<leader>Ph", "<cmd>ParagonicSearchHybrid<CR>", desc = "🔍 Hybrid Search" },
        { "<leader>Pc", "<cmd>ParagonicChat<CR>", desc = "💬 Open Chat" },
        { "<leader>Pp", "<cmd>ParagonicProjects<CR>", desc = "📁 Open Projects" },
        { "<leader>Po", "<cmd>ParagonicConfig<CR>", desc = "⚙️  Open Config" },
        { "<leader>Pd", "<cmd>ParagonicDebug<CR>", desc = "🐛 Open Debug" },
        { "<leader>Py", "<cmd>ParagonicSearchHistory<CR>", desc = "📚 Search History" },
        { "<leader>Pv", "<cmd>ParagonicSavedSearches<CR>", desc = "💾 Saved Searches" },
        { "<leader>Pw", "<cmd>ParagonicSaveSearch<CR>", desc = "💾 Save Current Search" },
        { "<leader>Pa", "<cmd>ParagonicAgentSession<CR>", desc = "🤖 AI Agent Session" },
        { "<leader>Pe", "<cmd>ParagonicExportData<CR>", desc = "📤 Export Data" },
        { "<leader>Pi", "<cmd>ParagonicImportData<CR>", desc = "📥 Import Data" },
        { "<leader>Pb", "<cmd>ParagonicBackupData<CR>", desc = "💾 Backup Data" },
        { "<leader>Pr", "<cmd>ParagonicReconnect<CR>", desc = "🔌 Force Reconnect" },
    })
    
    -- Register visual mode keymaps for search with selection (new spec format)
    wk.add({
        {
            mode = { "v" },
            { "<leader>Ps", function()
                local saved_reg = vim.fn.getreg('"')
                vim.cmd('normal! y')
                local selected_text = vim.fn.getreg('"')
                vim.fn.setreg('"', saved_reg)
                
                if selected_text and selected_text ~= "" then
                    vim.cmd('ParagonicSearch ' .. vim.fn.shellescape(selected_text))
                else
                    vim.cmd('ParagonicSearch')
                end
            end, desc = "🔍 Search Selected Text" },
            { "<leader>Pf", function()
                local saved_reg = vim.fn.getreg('"')
                vim.cmd('normal! y')
                local selected_text = vim.fn.getreg('"')
                vim.fn.setreg('"', saved_reg)
                
                if selected_text and selected_text ~= "" then
                    vim.cmd('ParagonicSearchFiltered ' .. vim.fn.shellescape(selected_text))
                else
                    vim.cmd('ParagonicSearchFiltered')
                end
            end, desc = "🔍 Filtered Search Selected Text" },
            { "<leader>Ph", function()
                local saved_reg = vim.fn.getreg('"')
                vim.cmd('normal! y')
                local selected_text = vim.fn.getreg('"')
                vim.fn.setreg('"', saved_reg)
                
                if selected_text and selected_text ~= "" then
                    vim.cmd('ParagonicSearchHybrid ' .. vim.fn.shellescape(selected_text))
                else
                    vim.cmd('ParagonicSearchHybrid')
                end
            end, desc = "🔍 Hybrid Search Selected Text" },
        },
    })
    
    local debug = require("paragonic.debug")
    debug.debug_print("which-key integration setup completed", "info")
end

-- Set up keyboard mappings with which-key integration
function M.setup_keymaps()
    -- Set up which-key integration if available
    M.setup_which_key()
    
    -- Fallback keymaps for when which-key is not available
    vim.keymap.set("n", "<leader>Ps", "<cmd>ParagonicSearch<CR>", {desc = "Paragonic: Basic Search"})
    vim.keymap.set("n", "<leader>Pf", "<cmd>ParagonicSearchFiltered<CR>", {desc = "Paragonic: Filtered Search"})
    vim.keymap.set("n", "<leader>Ph", "<cmd>ParagonicSearchHybrid<CR>", {desc = "Paragonic: Hybrid Search"})
    vim.keymap.set("n", "<leader>Pc", "<cmd>ParagonicChat<CR>", {desc = "Paragonic: Open Chat"})
    vim.keymap.set("n", "<leader>Pp", "<cmd>ParagonicProjects<CR>", {desc = "Paragonic: Open Projects"})
    vim.keymap.set("n", "<leader>Po", "<cmd>ParagonicConfig<CR>", {desc = "Paragonic: Open Config"})
    vim.keymap.set("n", "<leader>Pd", "<cmd>ParagonicDebug<CR>", {desc = "Paragonic: Open Debug"})
    vim.keymap.set("n", "<leader>Py", "<cmd>ParagonicSearchHistory<CR>", {desc = "Paragonic: Search History"})
    vim.keymap.set("n", "<leader>Pv", "<cmd>ParagonicSavedSearches<CR>", {desc = "Paragonic: Saved Searches"})
    vim.keymap.set("n", "<leader>Pw", "<cmd>ParagonicSaveSearch<CR>", {desc = "Paragonic: Save Current Search"})
    vim.keymap.set("n", "<leader>Pa", "<cmd>ParagonicAgentSession<CR>", {desc = "Paragonic: AI Agent Session"})
    vim.keymap.set("n", "<leader>Pe", "<cmd>ParagonicExportData<CR>", {desc = "Paragonic: Export Data"})
    vim.keymap.set("n", "<leader>Pi", "<cmd>ParagonicImportData<CR>", {desc = "Paragonic: Import Data"})
    vim.keymap.set("n", "<leader>Pb", "<cmd>ParagonicBackupData<CR>", {desc = "Paragonic: Backup Data"})
    vim.keymap.set("n", "<leader>Pr", "<cmd>ParagonicReconnect<CR>", {desc = "Paragonic: Force Reconnect"})
    
    -- Visual mode keymaps for search with selection
    vim.keymap.set("v", "<leader>Ps", function()
        local saved_reg = vim.fn.getreg('"')
        vim.cmd('normal! y')
        local selected_text = vim.fn.getreg('"')
        vim.fn.setreg('"', saved_reg)
        
        if selected_text and selected_text ~= "" then
            vim.cmd('ParagonicSearch ' .. vim.fn.shellescape(selected_text))
        else
            vim.cmd('ParagonicSearch')
        end
    end, {desc = "Paragonic: Search Selected Text"})
    
    vim.keymap.set("v", "<leader>Pf", function()
        local saved_reg = vim.fn.getreg('"')
        vim.cmd('normal! y')
        local selected_text = vim.fn.getreg('"')
        vim.fn.setreg('"', saved_reg)
        
        if selected_text and selected_text ~= "" then
            vim.cmd('ParagonicSearchFiltered ' .. vim.fn.shellescape(selected_text))
        else
            vim.cmd('ParagonicSearchFiltered')
        end
    end, {desc = "Paragonic: Filtered Search Selected Text"})
    
    vim.keymap.set("v", "<leader>Ph", function()
        local saved_reg = vim.fn.getreg('"')
        vim.cmd('normal! y')
        local selected_text = vim.fn.getreg('"')
        vim.fn.setreg('"', saved_reg)
        
        if selected_text and selected_text ~= "" then
            vim.cmd('ParagonicSearchHybrid ' .. vim.fn.shellescape(selected_text))
        else
            vim.cmd('ParagonicSearchHybrid')
        end
    end, {desc = "Paragonic: Hybrid Search Selected Text"})
    
    local debug = require("paragonic.debug")
    debug.debug_print("Keymaps setup completed with which-key integration", "info")
end

return M
