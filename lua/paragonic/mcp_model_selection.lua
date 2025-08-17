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

-- Available models
M.available_models = {
	{
		id = "gpt-4",
		name = "GPT-4",
		description = "Most capable model, best for complex reasoning",
		provider = "OpenAI",
		max_tokens = 8192
	},
	{
		id = "gpt-3.5-turbo",
		name = "GPT-3.5 Turbo",
		description = "Fast and efficient, good for most tasks",
		provider = "OpenAI",
		max_tokens = 4096
	},
	{
		id = "claude-3-opus",
		name = "Claude 3 Opus",
		description = "Anthropic's most powerful model",
		provider = "Anthropic",
		max_tokens = 200000
	},
	{
		id = "claude-3-sonnet",
		name = "Claude 3 Sonnet",
		description = "Balanced performance and speed",
		provider = "Anthropic",
		max_tokens = 200000
	},
	{
		id = "claude-3-haiku",
		name = "Claude 3 Haiku",
		description = "Fastest model, good for simple tasks",
		provider = "Anthropic",
		max_tokens = 200000
	},
	{
		id = "llama-3.1-8b",
		name = "Llama 3.1 8B",
		description = "Local model, good for privacy",
		provider = "Meta",
		max_tokens = 8192
	},
	{
		id = "llama-3.1-70b",
		name = "Llama 3.1 70B",
		description = "Local model, high quality",
		provider = "Meta",
		max_tokens = 8192
	}
}

-- Current model state
M.current_model = nil
M.model_markers = {}
M.next_marker_id = 1

-- Initialize model selection system
function M.initialize()
	M.current_model = M.available_models[2] -- Default to GPT-3.5 Turbo
	M.model_markers = {}
	M.next_marker_id = 1
	
	print("✅ Model selection system initialized")
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
