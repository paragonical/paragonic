--[[
Demo: Model Selection with Sigil Markers
Showcases the new model selection feature using 󰣩 Globe model sigil
--]]

-- Check if running in Neovim
local is_neovim = pcall(function() return vim.api.nvim_get_current_buf() end)

if not is_neovim then
	print("❌ This demo must be run inside Neovim")
	print("   Please open Neovim and run: :lua dofile('demo_model_selection.lua')")
	os.exit(1)
end

-- Demo configuration
local DEMO_CONFIG = {
	demo_buffer_name = "*Model Selection Demo*",
	delay = 1000, -- milliseconds
}

-- Utility function to add delay
local function delay(ms)
	if ms then
		vim.wait(ms)
	end
end

-- Utility function to add text to buffer
local function add_text(text)
	local buf = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	table.insert(lines, text)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

-- Utility function to clear buffer
local function clear_buffer()
	local buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
end

-- Test model selection system
local function test_model_selection()
	print("🚀 Starting Model Selection Demo")
	print("")
	
	-- Initialize MCP system
	local mcp = require("paragonic.mcp")
	if mcp.initialize_mcp_server then
		mcp.initialize_mcp_server()
	end
	
	-- Initialize model selection
	if mcp.initialize_model_selection then
		mcp.initialize_model_selection()
	end
	
	-- Try to load models from server
	if mcp.load_models_from_server then
		local success = mcp.load_models_from_server()
		if success then
			print("✅ Models loaded from Ollama server")
		else
			print("⚠️ Using fallback models (server not available)")
		end
	end
	
	-- Clear buffer
	clear_buffer()
	
	-- Add demo header
	add_text("# Model Selection Demo")
	add_text("")
	add_text("This demo showcases the new model selection feature using 󰣩 Globe model sigil markers.")
	add_text("")
	add_text("## How it works:")
	add_text("1. Model markers appear in chat buffers with 󰣩 symbol")
	add_text("2. Press Enter on a marker to interact with it")
	add_text("3. Choose to select the model or view details")
	add_text("4. Current model is marked with 🔵, available with ⚪, selected with ✅")
	add_text("")
	
	delay(DEMO_CONFIG.delay)
	
	-- Show current model
	add_text("## Current Model")
	local current_model = mcp.get_current_model()
	if current_model then
		add_text("Current model: " .. current_model.name .. " (" .. current_model.provider .. ")")
	else
		add_text("No model selected")
	end
	add_text("")
	
	delay(DEMO_CONFIG.delay)
	
	-- Create model selection markers
	add_text("## Model Selection Markers")
	add_text("")
	add_text("The following markers will appear in your chat buffer:")
	add_text("")
	
	-- Create markers for different models
	local models = mcp.get_available_models()
	local marker_ids = {}
	
	for i, model in ipairs(models) do
		if i <= 4 then -- Limit to first 4 models for demo
			local action_type = "model_switch"
			if model.id == current_model.id then
				action_type = "current_model"
			end
			
			local marker_id = mcp.create_model_marker(model.id, action_type)
			if marker_id then
				table.insert(marker_ids, marker_id)
				add_text("Created marker for: " .. model.name)
			end
		end
	end
	
	add_text("")
	add_text("## Interactive Features")
	add_text("")
	add_text("Try these interactions:")
	add_text("1. Move cursor to any 󰣩 marker line")
	add_text("2. Press Enter to open model selection menu")
	add_text("3. Choose 'Select Model' to switch models")
	add_text("4. Choose 'Show Details' to view model information")
	add_text("5. Press Enter on completed markers to see info")
	add_text("")
	
	delay(DEMO_CONFIG.delay)
	
	-- Show available models list
	add_text("## Available Models")
	add_text("")
	for i, model in ipairs(models) do
		local current = model.id == current_model.id and " (current)" or ""
		add_text(i .. ". " .. model.name .. " - " .. model.provider .. current)
	end
	add_text("")
	
	-- Show commands
	add_text("## Commands")
	add_text("")
	add_text("You can also use these commands:")
	add_text(":lua require('paragonic.mcp').show_current_model()")
	add_text(":lua require('paragonic.mcp').list_available_models()")
	add_text(":lua require('paragonic.mcp').set_current_model('llama3.1:8b')")
	add_text(":lua require('paragonic.mcp').refresh_models()")
	add_text("")
	
	add_text("## Demo Notes")
	add_text("")
	add_text("• Model markers use 󰣩 (Globe model) sigil")
	add_text("• 🔵 = Current model")
	add_text("• ⚪ = Available model")
	add_text("• ✅ = Selected model")
	add_text("• Press Enter on markers to interact")
	add_text("• Completed selections can be ignored")
	add_text("")
	add_text("Happy model switching! 🎉")
	
	print("✅ Model selection demo completed!")
	print("")
	print("💡 Try moving your cursor to the 󰣩 markers and pressing Enter")
	print("💡 Use the commands shown above to interact with models")
end

-- Run the demo
test_model_selection()
