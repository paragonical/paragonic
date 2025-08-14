-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- You can also add or configure plugins by creating files in this `plugins/` folder
-- PLEASE REMOVE THE EXAMPLES YOU HAVE NO INTEREST IN BEFORE ENABLING THIS FILE
-- Here are some examples:

-- vim.opt.clipboard = "unamedplus"
-- vim.keymap.set({ "n", "v" }, "<D-c>", '"+y')
-- vim.keymap.set({ "n", "v" }, "<D-v>", '"+p')
--
-- local guifont = "Victor Mono"
-- local guifontsize = 14
--
-- local function adjust_font_size(amount)
--   guifontsize = guifontsize + amount
--   vim.o.guifont = string.format("%s:h%d", guifont, guifontsize)
-- end
--
-- vim.keymap.set("n", "<C-+>", function() adjust_font_size(1) end)
-- vim.keymap.set("n", "<C-->", function() adjust_font_size(-1) end)
-- adjust_font_size(0)
--

---@type LazySpec
return {
	{
		"github/copilot.vim",
		event = "VeryLazy",
		version = "*",
	},

	-- == Examples of Adding Plugins ==

	"andweeb/presence.nvim",
	{
		"ray-x/lsp_signature.nvim",
		event = "BufRead",
		config = function()
			require("lsp_signature").setup()
		end,
	},

	-- == Paragonic AI Agent Plugin ==
	{
		dir = "/Users/sjanes/work2/paragonic", -- Your project path
		name = "paragonic",
		config = function()
			-- Add the project's lua directory to the Lua path
			local project_path = "/Users/sjanes/work2/paragonic"
			package.path = package.path .. ";" .. project_path .. "/lua/?.lua;" .. project_path .. "/lua/?/init.lua"

			-- Defer plugin setup to avoid blocking startup
			vim.defer_fn(function()
				local paragonic = require("paragonic")
				paragonic.setup()
			end, 1000) -- Wait 1 second after startup
		end,
		lazy = true, -- Load lazily to avoid startup blocking
		event = "VeryLazy", -- Load when Neovim is ready
		enabled = true,
	},
}
