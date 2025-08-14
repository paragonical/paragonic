--[[
Paragonic Configuration Module
Handles plugin configuration, settings, and configuration management
--]]

local M = {}

-- Plugin configuration
local config = {
	ollama_host = "http://localhost:11434",
	ollama_model = "deepseek-r1:1.5b",
	database_path = nil, -- Will be set in setup() if vim is available
	log_level = "info",
	backend_base_url = "http://127.0.0.1:3000", -- Default MCP HTTP server
	allow_localhost = true, -- Allow localhost connections for development
}

-- Model capabilities configuration
-- Maps model names to their capabilities
local model_capabilities = {
	-- Thinking models (support intermediate thinking output)
	["deepseek-r1:1.5b"] = {
		streaming_type = "thinking",
		supports_thinking = true,
		thinking_format = "auto", -- auto-detect <think> tags
	},
	["deepseek-coder:1.3b"] = {
		streaming_type = "thinking",
		supports_thinking = true,
		thinking_format = "auto",
	},
	["deepseek-coder:6.7b"] = {
		streaming_type = "thinking",
		supports_thinking = true,
		thinking_format = "auto",
	},
	["deepseek-coder:33b"] = {
		streaming_type = "thinking",
		supports_thinking = true,
		thinking_format = "auto",
	},

	-- Standard models (regular streaming)
	["llama2"] = {
		streaming_type = "normal",
		supports_thinking = false,
	},
	["llama2:7b"] = {
		streaming_type = "normal",
		supports_thinking = false,
	},
	["llama2:13b"] = {
		streaming_type = "normal",
		supports_thinking = false,
	},
	["llama2:70b"] = {
		streaming_type = "normal",
		supports_thinking = false,
	},
	["llama3.2:3b"] = {
		streaming_type = "normal",
		supports_thinking = false,
	},
	["llama3.2:8b"] = {
		streaming_type = "normal",
		supports_thinking = false,
	},
	["llama3.2:70b"] = {
		streaming_type = "normal",
		supports_thinking = false,
	},
	["mistral"] = {
		streaming_type = "normal",
		supports_thinking = false,
	},
	["mistral:7b"] = {
		streaming_type = "normal",
		supports_thinking = false,
	},
	["mistral:8x7b"] = {
		streaming_type = "normal",
		supports_thinking = false,
	},
	["codellama"] = {
		streaming_type = "normal",
		supports_thinking = false,
	},
	["codellama:7b"] = {
		streaming_type = "normal",
		supports_thinking = false,
	},
	["codellama:13b"] = {
		streaming_type = "normal",
		supports_thinking = false,
	},
	["codellama:34b"] = {
		streaming_type = "normal",
		supports_thinking = false,
	},
}

-- Persistent storage paths (will be set in setup() if vim is available)
local data_dir = nil
local history_file = nil
local saved_searches_file = nil
local insights_file = nil

-- Initialize configuration paths
function M.initialize_paths()
	if not vim then
		return false, "Not in Neovim environment"
	end

	-- Initialize paths if not already set
	if not data_dir then
		data_dir = vim.fn.stdpath("data") .. "/paragonic"
		history_file = data_dir .. "/search_history.json"
		saved_searches_file = data_dir .. "/saved_searches.json"
		insights_file = data_dir .. "/search_insights.json"
	end

	-- Set database path if not already set
	if not config.database_path then
		config.database_path = vim.fn.stdpath("data") .. "/paragonic/db"
	end

	return true
end

-- Setup configuration with options
function M.setup(opts)
	-- Initialize paths
	local success, err = M.initialize_paths()
	if not success then
		return false, err
	end

	-- Merge options with defaults
	local new_config = vim.tbl_deep_extend("force", config, opts or {})
	config = vim.tbl_deep_extend("force", config, new_config)

	return true
end

-- Get current configuration
function M.get_config()
	return vim.tbl_deep_extend("force", {}, config)
end

-- Update configuration
function M.update_config(new_config)
	config = vim.tbl_deep_extend("force", config, new_config)
end

-- Get configuration value
function M.get(key)
	return config[key]
end

-- Set configuration value
function M.set(key, value)
	config[key] = value
end

-- Get data directory
function M.get_data_dir()
	return data_dir
end

-- Get history file path
function M.get_history_file()
	return history_file
end

-- Get saved searches file path
function M.get_saved_searches_file()
	return saved_searches_file
end

-- Get insights file path
function M.get_insights_file()
	return insights_file
end

-- Get configuration from backend
function M.get_backend_config()
	-- This would typically call the RPC client
	-- For now, return local config
	return config
end

-- Save configuration to backend
function M.save_backend_config(config_data)
	-- This would typically call the RPC client
	-- For now, update local config
	M.update_config(config_data)
	return true
end

-- Get model capabilities
function M.get_model_capabilities(model_name)
	return model_capabilities[model_name] or {
		streaming_type = "normal",
		supports_thinking = false,
	}
end

-- Check if a model supports thinking
function M.model_supports_thinking(model_name)
	local capabilities = M.get_model_capabilities(model_name)
	return capabilities.supports_thinking or false
end

-- Get streaming type for a model
function M.get_model_streaming_type(model_name)
	local capabilities = M.get_model_capabilities(model_name)
	return capabilities.streaming_type or "normal"
end

-- Get streaming type for current model
function M.get_current_model_streaming_type()
	local current_model = config.ollama_model
	return M.get_model_streaming_type(current_model)
end

-- Check if current model supports thinking
function M.current_model_supports_thinking()
	local current_model = config.ollama_model
	return M.model_supports_thinking(current_model)
end

-- Add a new model capability
function M.add_model_capability(model_name, capabilities)
	model_capabilities[model_name] = capabilities
end

-- Get all known models
function M.get_known_models()
	local models = {}
	for model_name, _ in pairs(model_capabilities) do
		table.insert(models, model_name)
	end
	table.sort(models)
	return models
end

-- Get thinking models
function M.get_thinking_models()
	local thinking_models = {}
	for model_name, capabilities in pairs(model_capabilities) do
		if capabilities.supports_thinking then
			table.insert(thinking_models, model_name)
		end
	end
	table.sort(thinking_models)
	return thinking_models
end

-- Get normal models
function M.get_normal_models()
	local normal_models = {}
	for model_name, capabilities in pairs(model_capabilities) do
		if not capabilities.supports_thinking then
			table.insert(normal_models, model_name)
		end
	end
	table.sort(normal_models)
	return normal_models
end

return M
