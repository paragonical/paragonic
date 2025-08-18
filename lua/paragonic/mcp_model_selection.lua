--[[
MCP Model Selection
Handles LLM model selection with sigil markers in chat buffers
--]]

local M = {}

-- Configuration for model selection
M.config = {
	sigil_marker = "󰣩", -- Globe model icon
	current_prefix = "🔵",
	available_prefix = "⚪",
	selected_prefix = "✅",
	marker_color = "Special",
	current_color = "String",
	available_color = "Comment",
	selected_color = "String"
}

-- Available models (will be populated from Ollama server)
M.available_models = {}

-- Model descriptions for common models
M.model_descriptions = {
	["llama3.1:8b"] = "Fast and efficient, good for most tasks",
	["llama3.1:70b"] = "High quality model, best for complex reasoning",
	["llama3.2:3b"] = "Ultra-fast model, good for simple tasks",
	["llama3.2:8b"] = "Balanced performance and speed",
	["llama3.2:70b"] = "Most capable model, best for complex reasoning",
	["codellama:7b"] = "Specialized for code generation and analysis",
	["codellama:13b"] = "Enhanced code generation capabilities",
	["codellama:34b"] = "Most capable code generation model",
	["mistral:7b"] = "Fast and efficient general-purpose model",
	["mixtral:8x7b"] = "High-quality mixture of experts model",
	["llama2:7b"] = "Reliable general-purpose model",
	["llama2:13b"] = "Enhanced general-purpose model",
	["llama2:70b"] = "High-quality general-purpose model",
	["neural-chat:7b"] = "Optimized for chat and conversation",
	["orca-mini:3b"] = "Lightweight model for simple tasks",
	["orca-mini:7b"] = "Balanced chat model",
	["phi:2.7b"] = "Fast and efficient Microsoft model",
	["phi:3.5"] = "Enhanced Microsoft model",
	["qwen:7b"] = "Alibaba's efficient model",
	["qwen:14b"] = "Alibaba's enhanced model",
	["qwen:72b"] = "Alibaba's most capable model",
}

-- Current model state
M.current_model = nil
M.model_markers = {}
M.next_marker_id = 1

-- Initialize model selection system
function M.initialize()
	M.model_markers = {}
	M.next_marker_id = 1
	
	-- Load models from Ollama server
	local success = M.load_models_from_server()
	if success then
		-- Set default model to first available, or a common one
		if #M.available_models > 0 then
			M.current_model = M.available_models[1]
		else
			-- Fallback to a common model if none available
			M.current_model = {
				id = "llama3.1:8b",
				name = "Llama 3.1 8B",
				description = "Fast and efficient, good for most tasks",
				provider = "Ollama",
				max_tokens = 8192,
				ollama_model = "llama3.1:8b"
			}
		end
		print("✅ Model selection system initialized with " .. #M.available_models .. " Ollama models")
	else
		print("⚠️ Model selection system initialized with fallback models")
	end
end

-- Load models from Ollama server via Rust backend
function M.load_models_from_server()
	local success, api = pcall(require, "paragonic.api")
	if not success or not api then
		print("❌ Could not load API module")
		return false
	end
	
	-- Check if API is ready
	if not api.is_ready() then
		print("❌ API not ready, cannot load models")
		return false
	end
	
	-- Get models from server
	local response = api.list_models()
	if not response or not response.success then
		print("❌ Failed to get models from server: " .. (response and response.error or "unknown error"))
		return false
	end
	
	-- Parse models from response
	local models = response.result or response.data or {}
	if type(models) == "table" and models.models then
		models = models.models
	end
	
	if not models or #models == 0 then
		print("⚠️ No models found on Ollama server")
		return false
	end
	
	-- Convert to our format
	M.available_models = {}
	for _, model in ipairs(models) do
		local model_name = model.name or model.id
		if model_name then
			local description = M.model_descriptions[model_name] or "Ollama model"
			local display_name = M.format_model_name(model_name)
			
			table.insert(M.available_models, {
				id = model_name,
				name = display_name,
				description = description,
				provider = "Ollama",
				max_tokens = 8192,
				ollama_model = model_name,
				size = model.size,
				modified_at = model.modified_at
			})
		end
	end
	
	print("📦 Loaded " .. #M.available_models .. " models from Ollama server")
	return true
end

-- Format model name for display
function M.format_model_name(model_name)
	-- Convert model names to display names
	local name_mappings = {
		["llama3.1:8b"] = "Llama 3.1 8B",
		["llama3.1:70b"] = "Llama 3.1 70B",
		["llama3.2:3b"] = "Llama 3.2 3B",
		["llama3.2:8b"] = "Llama 3.2 8B",
		["llama3.2:70b"] = "Llama 3.2 70B",
		["codellama:7b"] = "Code Llama 7B",
		["codellama:13b"] = "Code Llama 13B",
		["codellama:34b"] = "Code Llama 34B",
		["mistral:7b"] = "Mistral 7B",
		["mixtral:8x7b"] = "Mixtral 8x7B",
		["llama2:7b"] = "Llama 2 7B",
		["llama2:13b"] = "Llama 2 13B",
		["llama2:70b"] = "Llama 2 70B",
		["neural-chat:7b"] = "Neural Chat 7B",
		["orca-mini:3b"] = "Orca Mini 3B",
		["orca-mini:7b"] = "Orca Mini 7B",
		["phi:2.7b"] = "Phi 2.7B",
		["phi:3.5"] = "Phi 3.5",
		["qwen:7b"] = "Qwen 7B",
		["qwen:14b"] = "Qwen 14B",
		["qwen:72b"] = "Qwen 72B",
	}
	
	return name_mappings[model_name] or model_name
end

-- Refresh models from server
function M.refresh_models()
	return M.load_models_from_server()
end

-- Get current model
function M.get_current_model()
	return M.current_model
end

-- Set current model
function M.set_current_model(model_id)
	for _, model in ipairs(M.available_models) do
		if model.id == model_id then
			M.current_model = model
			M.update_model_markers()
			return true
		end
	end
	return false, "Model not found: " .. model_id
end

-- Create model selection marker in chat buffer
function M.create_model_marker(model_id, action_type)
	local marker_id = M.next_marker_id
	M.next_marker_id = M.next_marker_id + 1
	
	-- Find the model
	local model = nil
	for _, m in ipairs(M.available_models) do
		if m.id == model_id then
			model = m
			break
		end
	end
	
	if not model then
		return nil, "Model not found: " .. model_id
	end
	
	local prefix = M.config.available_prefix
	if model_id == M.current_model.id then
		prefix = M.config.current_prefix
	end
	
	local marker_line = string.format("%s %s [%s] %s (%s)", 
		M.config.sigil_marker,
		prefix,
		action_type,
		model.name,
		model.provider
	)
	
	-- Store marker info
	M.model_markers[marker_id] = {
		id = marker_id,
		model_id = model_id,
		action_type = action_type,
		marker_line = marker_line,
		status = "pending",
		created_at = os.time(),
		buffer_id = vim.api.nvim_get_current_buf()
	}
	
	-- Add marker to current buffer
	local current_buf = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
	table.insert(lines, marker_line)
	vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, lines)
	
	-- Highlight the marker
	M.highlight_model_marker(current_buf, #lines, marker_id)
	
	return marker_id
end

-- Highlight model marker in buffer
function M.highlight_model_marker(buffer_id, line_number, marker_id)
	local marker = M.model_markers[marker_id]
	if not marker then
		return
	end
	
	-- Create highlight namespace
	local ns_id = vim.api.nvim_create_namespace("model_selection_" .. marker_id)
	
	-- Highlight the marker
	local highlight_group = M.config.marker_color
	if marker.model_id == M.current_model.id then
		highlight_group = M.config.current_color
	elseif marker.status == "selected" then
		highlight_group = M.config.selected_color
	else
		highlight_group = M.config.available_color
	end
	
	vim.api.nvim_buf_add_highlight(buffer_id, ns_id, highlight_group, line_number - 1, 0, -1)
end

-- Update model marker status
function M.update_model_marker(marker_id, status, result)
	local marker = M.model_markers[marker_id]
	if not marker then
		return false
	end
	
	marker.status = status
	marker.result = result
	marker.updated_at = os.time()
	
	-- Update the marker line
	local new_prefix = M.config.available_prefix
	if status == "selected" then
		new_prefix = M.config.selected_prefix
	elseif marker.model_id == M.current_model.id then
		new_prefix = M.config.current_prefix
	end
	
	-- Find the model
	local model = nil
	for _, m in ipairs(M.available_models) do
		if m.id == marker.model_id then
			model = m
			break
		end
	end
	
	if model then
		local new_marker_line = string.format("%s %s [%s] %s (%s)", 
			M.config.sigil_marker,
			new_prefix,
			marker.action_type,
			model.name,
			model.provider
		)
		
		-- Update the line in the buffer
		local buffer_id = marker.buffer_id
		if vim.api.nvim_buf_is_valid(buffer_id) then
			local lines = vim.api.nvim_buf_get_lines(buffer_id, 0, -1, false)
			
			-- Find the marker line
			for i, line in ipairs(lines) do
				if line:find(M.config.sigil_marker) and line:find(model.name) then
					lines[i] = new_marker_line
					vim.api.nvim_buf_set_lines(buffer_id, 0, -1, false, lines)
					
					-- Update highlighting
					M.highlight_model_marker(buffer_id, i, marker_id)
					break
				end
			end
		end
	end
	
	return true
end

-- Update all model markers (when current model changes)
function M.update_model_markers()
	for marker_id, marker in pairs(M.model_markers) do
		M.highlight_model_marker(marker.buffer_id, 0, marker_id) -- Will find correct line
	end
end

-- Handle Enter key for model selection
function M.handle_model_enter_key()
	local current_buf = vim.api.nvim_get_current_buf()
	local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
	local lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
	
	if cursor_line <= #lines then
		local line = lines[cursor_line]
		if line:find(M.config.sigil_marker) then
			-- Found a model marker, check if it's pending
			for marker_id, marker in pairs(M.model_markers) do
				if marker.buffer_id == current_buf and 
				   line:find(marker.model_id) and
				   marker.status == "pending" then
					-- Process the model selection
					M.process_model_selection(marker_id)
					return true
				end
			end
			
			-- Check if it's a model info request
			if line:find(M.config.sigil_marker) then
				M.show_model_info(line)
				return true
			end
		end
	end
	
	return false
end

-- Process model selection when user presses Enter on marker
function M.process_model_selection(marker_id)
	local marker = M.model_markers[marker_id]
	if not marker or marker.status ~= "pending" then
		return false
	end
	
	-- Find the model
	local model = nil
	for _, m in ipairs(M.available_models) do
		if m.id == marker.model_id then
			model = m
			break
		end
	end
	
	if not model then
		vim.notify("Model not found", vim.log.levels.ERROR)
		return false
	end
	
	-- Show model selection options
	local options = {"Select Model", "Show Details", "Cancel"}
	vim.ui.select(options, {
		prompt = "Model Selection:",
		format_item = function(item)
			return item
		end
	}, function(choice)
		if choice == "Select Model" then
			M.select_model(marker_id, model)
		elseif choice == "Show Details" then
			M.show_model_details(marker_id, model)
		end
	end)
end

-- Select a model
function M.select_model(marker_id, model)
	-- Set as current model
	local success = M.set_current_model(model.id)
	if success then
		M.update_model_marker(marker_id, "selected", {selected = true})
		vim.notify("Model changed to: " .. model.name, vim.log.levels.INFO)
	else
		vim.notify("Failed to change model", vim.log.levels.ERROR)
	end
end

-- Show model details
function M.show_model_details(marker_id, model)
	local details = {
		"Model Details:",
		"Name: " .. model.name,
		"Provider: " .. model.provider,
		"Description: " .. model.description,
		"Max Tokens: " .. model.max_tokens,
		"",
		"Current Model: " .. (model.id == M.current_model.id and "Yes" or "No"),
		"",
		"Press any key to close."
	}
	
	-- Show details in a floating window
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, details)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	
	local width = 60
	local height = #details + 2
	local row = math.floor((vim.o.lines - height) / 2) - 1
	local col = math.floor((vim.o.columns - width) / 2)
	
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded"
	})
	
	-- Close on any key
	vim.keymap.set("n", "<CR>", function()
		vim.api.nvim_win_close(win, true)
		vim.api.nvim_buf_delete(buf, {force = true})
	end, {buffer = buf, noremap = true, silent = true})
	
	vim.keymap.set("n", "<Esc>", function()
		vim.api.nvim_win_close(win, true)
		vim.api.nvim_buf_delete(buf, {force = true})
	end, {buffer = buf, noremap = true, silent = true})
	
	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(win, true)
		vim.api.nvim_buf_delete(buf, {force = true})
	end, {buffer = buf, noremap = true, silent = true})
end

-- Show model info for completed markers
function M.show_model_info(marker_line)
	-- Extract model information from the line
	local model_name = marker_line:match("%] .+%] (.+) %(")
	local provider = marker_line:match("%((.+)%)")
	
	if model_name and provider then
		local info = {
			"Model Information:",
			"Name: " .. model_name,
			"Provider: " .. provider,
			"",
			"This model selection has been processed.",
			"",
			"Press any key to close."
		}
		
		-- Show info in a floating window
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, info)
		vim.api.nvim_buf_set_option(buf, "modifiable", false)
		vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
		
		local width = 50
		local height = #info + 2
		local row = math.floor((vim.o.lines - height) / 2) - 1
		local col = math.floor((vim.o.columns - width) / 2)
		
		local win = vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			width = width,
			height = height,
			row = row,
			col = col,
			style = "minimal",
			border = "rounded"
		})
		
		-- Close on any key
		vim.keymap.set("n", "<CR>", function()
			vim.api.nvim_win_close(win, true)
			vim.api.nvim_buf_delete(buf, {force = true})
		end, {buffer = buf, noremap = true, silent = true})
		
		vim.keymap.set("n", "<Esc>", function()
			vim.api.nvim_win_close(win, true)
			vim.api.nvim_buf_delete(buf, {force = true})
		end, {buffer = buf, noremap = true, silent = true})
		
		vim.keymap.set("n", "q", function()
			vim.api.nvim_win_close(win, true)
			vim.api.nvim_buf_delete(buf, {force = true})
		end, {buffer = buf, noremap = true, silent = true})
	end
end

-- Show current model
function M.show_current_model()
	local model = M.get_current_model()
	if model then
		vim.notify("Current model: " .. model.name .. " (" .. model.provider .. ")", vim.log.levels.INFO)
		return model
	else
		vim.notify("No model selected", vim.log.levels.WARN)
		return nil
	end
end

-- List all available models
function M.list_available_models()
	local models = {}
	for i, model in ipairs(M.available_models) do
		local current = model.id == M.current_model.id and " (current)" or ""
		table.insert(models, i .. ". " .. model.name .. " - " .. model.provider .. current)
	end
	
	vim.ui.select(models, {
		prompt = "Available Models:",
		format_item = function(item)
			return item
		end
	}, function(choice)
		if choice then
			local index = tonumber(choice:match("^(%d+)"))
			if index and M.available_models[index] then
				M.set_current_model(M.available_models[index].id)
				vim.notify("Model changed to: " .. M.available_models[index].name, vim.log.levels.INFO)
			end
		end
	end)
end

-- Get available models
function M.get_available_models()
	return M.available_models
end

-- Add custom model
function M.add_custom_model(model)
	if not model.id or not model.name or not model.provider then
		return false, "Invalid model: missing required fields"
	end
	
	-- Check for duplicate ID
	for _, existing in ipairs(M.available_models) do
		if existing.id == model.id then
			return false, "Model ID already exists: " .. model.id
		end
	end
	
	-- Set defaults
	model.description = model.description or "Custom model"
	model.max_tokens = model.max_tokens or 4096
	
	table.insert(M.available_models, model)
	return true
end

return M
