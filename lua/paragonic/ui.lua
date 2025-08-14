--[[
Paragonic UI Module
Handles user interface functionality like opening projects and config buffers
--]]

local M = {}

-- Open projects interface
function M.open_projects()
	-- Check if projects buffer already exists
	local projects_buf = nil
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local name = vim.api.nvim_buf_get_name(buf)
		if name == "paragonic://projects" then
			projects_buf = buf
			break
		end
	end

	-- Create new buffer if it doesn't exist
	if not projects_buf then
		projects_buf = vim.api.nvim_create_buf(true, true)

		-- Set buffer name
		vim.api.nvim_buf_set_name(projects_buf, "paragonic://projects")

		-- Set buffer options
		vim.api.nvim_buf_set_option(projects_buf, "buftype", "nofile")
		vim.api.nvim_buf_set_option(projects_buf, "swapfile", false)
		vim.api.nvim_buf_set_option(projects_buf, "modifiable", true)

		-- Get projects from backend
		local projects_content = {
			"# Paragonic Projects",
			"",
			"Loading projects...",
		}

		local backend = require("paragonic.backend")
		local projects_response = backend.get_projects()
		if projects_response then
			-- Display actual projects from parsed response
			projects_content = {
				"# Paragonic Projects",
				"",
				"Projects loaded from backend:",
				"",
			}

			for _, project in ipairs(projects_response) do
				table.insert(projects_content, "## " .. project.name)
				if project.description and project.description ~= "" then
					table.insert(projects_content, project.description)
				end
				table.insert(projects_content, "")
			end

			table.insert(projects_content, "---")
		else
			projects_content = {
				"# Paragonic Projects",
				"",
				"No projects found or backend unavailable.",
				"",
				"Use :ParagonicCreateProject to create a new project.",
				"",
				"---",
			}
		end

		-- Add content to buffer
		vim.api.nvim_buf_set_lines(projects_buf, 0, -1, false, projects_content)

		-- Set filetype for syntax highlighting
		vim.api.nvim_buf_set_option(projects_buf, "filetype", "markdown")

		-- Set up buffer-local commands
		vim.api.nvim_buf_set_keymap(
			projects_buf,
			"n",
			"<CR>",
			":ParagonicCreateProject<CR>",
			{ noremap = true, silent = true }
		)
	end

	-- Open the buffer in a new window
	vim.api.nvim_command("split")
	vim.api.nvim_set_current_buf(projects_buf)
end

-- Open configuration
function M.open_config()
	-- Check if config buffer already exists
	local config_buf = nil
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local name = vim.api.nvim_buf_get_name(buf)
		if name == "paragonic://config" then
			config_buf = buf
			break
		end
	end

	-- Create new buffer if it doesn't exist
	if not config_buf then
		config_buf = vim.api.nvim_create_buf(true, true)

		-- Set buffer name
		vim.api.nvim_buf_set_name(config_buf, "paragonic://config")

		-- Set buffer options
		vim.api.nvim_buf_set_option(config_buf, "buftype", "nofile")
		vim.api.nvim_buf_set_option(config_buf, "swapfile", false)
		vim.api.nvim_buf_set_option(config_buf, "modifiable", true)

		-- Load configuration from backend
		local config_content = {
			"# Paragonic Configuration",
			"",
			"Loading configuration...",
		}

		local backend = require("paragonic.backend")
		local config_response = backend.get_config()
		if config_response then
			-- Display actual configuration from parsed response
			config_content = {
				"# Paragonic Configuration",
				"",
				"Current configuration loaded from backend:",
				"",
				"## Ollama Settings",
				"- Host: " .. (config_response.ollama_host or "127.0.0.1:11434"),
				"- Model: " .. (config_response.ollama_model or "deepseek-r1:1.5b"),
				"",
				"## Database Settings",
				"- Path: " .. (config_response.database_path or "/tmp/paragonic.db"),
				"",
				"## Logging Settings",
				"- Level: " .. (config_response.log_level or "info"),
				"",
				"---",
				"",
				"Edit the configuration above and use :ParagonicSaveConfig to save changes.",
			}
		else
			config_content = {
				"# Paragonic Configuration",
				"",
				"Configuration not available or backend unavailable.",
				"",
				"Use :ParagonicSaveConfig to save configuration changes.",
				"",
				"---",
			}
		end

		-- Add content to buffer
		vim.api.nvim_buf_set_lines(config_buf, 0, -1, false, config_content)

		-- Set filetype for syntax highlighting
		vim.api.nvim_buf_set_option(config_buf, "filetype", "markdown")

		-- Set up buffer-local commands
		vim.api.nvim_buf_set_keymap(
			config_buf,
			"n",
			"<CR>",
			":ParagonicSaveConfig<CR>",
			{ noremap = true, silent = true }
		)
	end

	-- Open the buffer in a new window
	vim.api.nvim_command("split")
	vim.api.nvim_set_current_buf(config_buf)
end

-- Create project command
function M.create_project_command()
	local current_buf = vim.api.nvim_get_current_buf()
	local buf_name = vim.api.nvim_buf_get_name(current_buf)

	-- Only work in projects buffer
	if buf_name ~= "paragonic://projects" then
		vim.notify("This command only works in the projects buffer", vim.log.levels.WARN)
		return
	end

	-- Get project name from user input
	local project_name = vim.fn.input("Project name: ")
	if project_name == "" then
		vim.notify("Project name cannot be empty", vim.log.levels.WARN)
		return
	end

	-- Get project description from user input
	local project_description = vim.fn.input("Project description: ")

	-- Create the project
	local backend = require("paragonic.backend")
	local response, err = backend.create_project(project_name, project_description)
	if not response then
		vim.notify("Failed to create project: " .. (err or "unknown error"), vim.log.levels.ERROR)
		return
	end

	-- Add the new project to the buffer
	local project_lines = {
		"",
		"## " .. project_name,
		project_description ~= "" and project_description or "No description provided",
		"",
		"---",
	}

	-- Insert project at the end of the buffer
	local last_line = vim.api.nvim_buf_line_count(current_buf)
	vim.api.nvim_buf_set_lines(current_buf, last_line, last_line, false, project_lines)

	vim.notify("Project '" .. project_name .. "' created successfully", vim.log.levels.INFO)
end

-- Save configuration command
function M.save_config_command()
	local current_buf = vim.api.nvim_get_current_buf()
	local buf_name = vim.api.nvim_buf_get_name(current_buf)

	-- Only work in config buffer
	if buf_name ~= "paragonic://config" then
		vim.notify("This command only works in the config buffer", vim.log.levels.WARN)
		return
	end

	-- Get all lines from the buffer
	local lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)

	-- Parse configuration from buffer content
	local config_data = {}

	for _, line in ipairs(lines) do
		-- Parse Ollama settings
		if line:match("^%- Host: (.+)$") then
			config_data.ollama_host = line:match("^%- Host: (.+)$")
		elseif line:match("^%- Model: (.+)$") then
			config_data.ollama_model = line:match("^%- Model: (.+)$")
		elseif line:match("^%- Path: (.+)$") then
			config_data.database_path = line:match("^%- Path: (.+)$")
		elseif line:match("^%- Level: (.+)$") then
			config_data.log_level = line:match("^%- Level: (.+)$")
		end
	end

	-- Save the configuration
	local backend = require("paragonic.backend")
	local response, err = backend.save_config(config_data)
	if not response then
		vim.notify("Failed to save configuration: " .. (err or "unknown error"), vim.log.levels.ERROR)
		return
	end

	-- Add confirmation message to buffer
	local confirmation_lines = {
		"",
		"**Configuration saved successfully!**",
		"",
		"---",
	}

	-- Insert confirmation at the end of the buffer
	local last_line = vim.api.nvim_buf_line_count(current_buf)
	vim.api.nvim_buf_set_lines(current_buf, last_line, last_line, false, confirmation_lines)

	vim.notify("Configuration saved successfully", vim.log.levels.INFO)
end

-- Display AI agent status
function M.display_ai_agent_status(status)
	-- Create buffer for status
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "modifiable", true)

	-- Format status
	local lines = {
		"# AI Agent Status",
		"",
		"**Active:** " .. (status.active and "Yes" or "No"),
		"",
	}

	if status.active then
		table.insert(lines, "**Session ID:** " .. status.session_id)
		table.insert(lines, "**Agent Name:** " .. status.agent_name)
		table.insert(lines, "**Start Time:** " .. os.date("%Y-%m-%d %H:%M:%S", status.start_time))
		table.insert(lines, "**Duration:** " .. status.duration .. " seconds")
		table.insert(lines, "**Interaction Count:** " .. status.interaction_count)
		table.insert(lines, "")
		table.insert(lines, "## Current Context")
		table.insert(lines, "")
		table.insert(lines, "**Current File:** " .. status.context.current_file)
		table.insert(lines, "**Current Directory:** " .. status.context.current_directory)
		table.insert(lines, "**Buffer Count:** " .. status.context.buffer_count)
		table.insert(lines, "**Mode:** " .. status.context.mode)
	else
		table.insert(lines, "**Message:** " .. status.message)
	end

	-- Set buffer content
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- Open buffer in split
	vim.api.nvim_command("split")
	vim.api.nvim_set_current_buf(buf)

	-- Set buffer options
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

return M
