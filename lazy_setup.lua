-- Lazy.nvim Configuration for Paragonic Plugin
-- Add this to your Neovim config to install via Lazy.nvim

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Plugin specifications
require("lazy").setup({
	-- Paragonic Plugin (local development)
	{
		dir = "~/work2/paragonic", -- Change this path to your actual project location
		name = "paragonic",
		config = function()
			require("paragonic")
		end,
		lazy = false,
		priority = 1000,
	},

	-- Add other plugins here as needed
})
