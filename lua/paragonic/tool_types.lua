--[[
Tool Types Module
Provides type definitions and validation for MCP tool arguments
--]]

local M = {}

-- Type definitions with validation patterns
M.types = {
	-- Basic types
	string = {
		type = "string",
		description = "A string value",
		validation = {
			pattern = nil, -- No pattern restriction
			min_length = 0,
			max_length = nil,
			examples = {"example", "test", "value"}
		}
	},
	
	integer = {
		type = "integer",
		description = "An integer value",
		validation = {
			min_value = nil,
			max_value = nil,
			examples = {1, 42, 1000}
		}
	},
	
	boolean = {
		type = "boolean",
		description = "A boolean value",
		validation = {
			examples = {true, false}
		}
	},
	
	-- File system types
	file_path = {
		type = "string",
		description = "Path to a file",
		validation = {
			pattern = "^[^<>:\"|?*]+$", -- No invalid Windows characters
			min_length = 1,
			max_length = 4096,
			examples = {"src/main.lua", "/home/user/file.txt", "C:\\Users\\file.txt"}
		}
	},
	
	directory_path = {
		type = "string",
		description = "Path to a directory",
		validation = {
			pattern = "^[^<>:\"|?*]+/?$", -- Directory path, optional trailing slash
			min_length = 1,
			max_length = 4096,
			examples = {"src/", "/home/user/", "C:\\Users\\"}
		}
	},
	
	filename = {
		type = "string",
		description = "A filename (without path)",
		validation = {
			pattern = "^[^<>:\"|?*/\\\\]+$", -- No path separators or invalid chars
			min_length = 1,
			max_length = 255,
			examples = {"main.lua", "config.json", "README.md"}
		}
	},
	
	file_extension = {
		type = "string",
		description = "A file extension",
		validation = {
			pattern = "^\\.[a-zA-Z0-9]+$", -- Starts with dot, alphanumeric
			min_length = 2, -- At least ".x"
			max_length = 10,
			examples = {".lua", ".json", ".md", ".txt"}
		}
	},
	
	-- Code and content types
	code_content = {
		type = "string",
		description = "Programming code content",
		validation = {
			pattern = nil, -- No pattern restriction for code
			min_length = 0,
			max_length = 100000, -- 100KB limit
			examples = {"print('Hello World')", "function test() { return true; }"}
		}
	},
	
	comment_content = {
		type = "string",
		description = "Comment content",
		validation = {
			pattern = "^[^\\n\\r]*$", -- No newlines in comments
			min_length = 0,
			max_length = 1000,
			examples = {"This is a comment", "-- Lua comment", "// C comment"}
		}
	},
	
	markdown_content = {
		type = "string",
		description = "Markdown formatted content",
		validation = {
			pattern = nil, -- No pattern restriction for markdown
			min_length = 0,
			max_length = 50000,
			examples = {"# Title\n\nContent here", "**Bold** and *italic* text"}
		}
	},
	
	-- Search and query types
	search_query = {
		type = "string",
		description = "Search query string",
		validation = {
			pattern = "^[^\\n\\r]+$", -- No newlines in search queries
			min_length = 1,
			max_length = 1000,
			examples = {"function", "*.lua", "TODO"}
		}
	},
	
	regex_pattern = {
		type = "string",
		description = "Regular expression pattern",
		validation = {
			pattern = nil, -- No pattern restriction for regex
			min_length = 1,
			max_length = 500,
			examples = {"\\b\\w+\\b", ".*\\.lua$", "^[A-Z]"}
		}
	},
	
	-- Command types
	neovim_command = {
		type = "string",
		description = "Neovim command",
		validation = {
			pattern = "^[a-zA-Z][a-zA-Z0-9_]*$", -- Alphanumeric, starts with letter
			min_length = 1,
			max_length = 100,
			examples = {"buffers", "ls", "pwd", "version"}
		}
	},
	
	shell_command = {
		type = "string",
		description = "Shell command",
		validation = {
			pattern = "^[a-zA-Z][a-zA-Z0-9_-]*$", -- Alphanumeric, starts with letter
			min_length = 1,
			max_length = 100,
			examples = {"ls", "pwd", "date", "whoami"}
		}
	},
	
	-- URL and network types
	url = {
		type = "string",
		description = "URL address",
		validation = {
			pattern = "^https?://[^\\s]+$", -- HTTP/HTTPS URL
			min_length = 10,
			max_length = 2048,
			examples = {"https://example.com", "http://localhost:3000"}
		}
	},
	
	-- Configuration types
	json_content = {
		type = "string",
		description = "JSON formatted content",
		validation = {
			pattern = nil, -- No pattern restriction for JSON
			min_length = 2, -- At least "{}"
			max_length = 100000,
			examples = {"{\"key\": \"value\"}", "{\"array\": [1, 2, 3]}"}
		}
	},
	
	config_key = {
		type = "string",
		description = "Configuration key name",
		validation = {
			pattern = "^[a-zA-Z_][a-zA-Z0-9_]*$", -- Valid identifier
			min_length = 1,
			max_length = 100,
			examples = {"api_key", "base_url", "timeout"}
		}
	},
	
	-- Model and AI types
	model_name = {
		type = "string",
		description = "AI model name/identifier",
		validation = {
			pattern = "^[a-zA-Z0-9][a-zA-Z0-9._-]*$", -- Valid model name
			min_length = 1,
			max_length = 100,
			examples = {"llama3.1:8b", "deepseek-coder:1.3b", "gpt-4"}
		}
	},
	
	-- Time and date types
	timestamp = {
		type = "string",
		description = "ISO 8601 timestamp",
		validation = {
			pattern = "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\.\\d{3})?Z?$",
			min_length = 19,
			max_length = 30,
			examples = {"2024-01-15T10:30:00Z", "2024-01-15T10:30:00.123Z"}
		}
	},
	
	date = {
		type = "string",
		description = "Date in YYYY-MM-DD format",
		validation = {
			pattern = "^\\d{4}-\\d{2}-\\d{2}$",
			min_length = 10,
			max_length = 10,
			examples = {"2024-01-15", "2024-12-31"}
		}
	},
	
	-- Custom types for specific use cases
	email = {
		type = "string",
		description = "Email address",
		validation = {
			pattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$",
			min_length = 5,
			max_length = 254,
			examples = {"user@example.com", "test.email+tag@domain.co.uk"}
		}
	},
	
	version_string = {
		type = "string",
		description = "Version string (semantic versioning)",
		validation = {
			pattern = "^\\d+\\.\\d+\\.\\d+(-[a-zA-Z0-9.-]+)?(\\+[a-zA-Z0-9.-]+)?$",
			min_length = 5,
			max_length = 50,
			examples = {"1.0.0", "2.1.3-beta", "3.0.0+20240115"}
		}
	},
	
	hex_color = {
		type = "string",
		description = "Hexadecimal color code",
		validation = {
			pattern = "^#[0-9A-Fa-f]{6}$",
			min_length = 7,
			max_length = 7,
			examples = {"#FF0000", "#00FF00", "#0000FF"}
		}
	}
}

-- Type validation functions
function M.validate_type(value, type_name)
	local type_def = M.types[type_name]
	if not type_def then
		return false, "Unknown type: " .. type_name
	end
	
	-- Check basic type
	if type(value) ~= type_def.type then
		return false, "Expected " .. type_def.type .. ", got " .. type(value)
	end
	
	-- String-specific validation
	if type_def.type == "string" and type_def.validation then
		local validation = type_def.validation
		
		-- Check length constraints
		if validation.min_length and #value < validation.min_length then
			return false, "String too short (min: " .. validation.min_length .. ")"
		end
		
		if validation.max_length and #value > validation.max_length then
			return false, "String too long (max: " .. validation.max_length .. ")"
		end
		
		-- Check regex pattern
		if validation.pattern then
			local match = string.match(value, validation.pattern)
			if not match or match ~= value then
				return false, "String does not match pattern: " .. validation.pattern
			end
		end
	end
	
	-- Integer-specific validation
	if type_def.type == "integer" and type_def.validation then
		local validation = type_def.validation
		
		if validation.min_value and value < validation.min_value then
			return false, "Value too small (min: " .. validation.min_value .. ")"
		end
		
		if validation.max_value and value > validation.max_value then
			return false, "Value too large (max: " .. validation.max_value .. ")"
		end
	end
	
	return true, "Valid"
end

-- Validate tool parameters against schema
function M.validate_tool_parameters(parameters, tool_schema)
	if not parameters or type(parameters) ~= "table" then
		return false, "Parameters must be a table"
	end
	
	if not tool_schema or not tool_schema.properties then
		return false, "Invalid tool schema"
	end
	
	local errors = {}
	
	-- Check required parameters
	if tool_schema.required then
		for _, required_param in ipairs(tool_schema.required) do
			if parameters[required_param] == nil then
				table.insert(errors, "Missing required parameter: " .. required_param)
			end
		end
	end
	
	-- Validate each parameter
	for param_name, param_value in pairs(parameters) do
		local param_schema = tool_schema.properties[param_name]
		if param_schema then
			-- Check if parameter has a custom type
			if param_schema.custom_type and M.types[param_schema.custom_type] then
				local valid, error_msg = M.validate_type(param_value, param_schema.custom_type)
				if not valid then
					table.insert(errors, param_name .. ": " .. error_msg)
				end
			else
				-- Use standard JSON Schema validation
				local valid, error_msg = M.validate_json_schema_value(param_value, param_schema)
				if not valid then
					table.insert(errors, param_name .. ": " .. error_msg)
				end
			end
		else
			-- Unknown parameter
			table.insert(errors, "Unknown parameter: " .. param_name)
		end
	end
	
	if #errors > 0 then
		return false, table.concat(errors, "; ")
	end
	
	return true, "Valid"
end

-- Validate value against JSON Schema
function M.validate_json_schema_value(value, schema)
	if not schema or not schema.type then
		return true, "No validation schema"
	end
	
	-- Type validation
	if schema.type == "string" then
		if type(value) ~= "string" then
			return false, "Expected string"
		end
		
		-- Check min/max length
		if schema.minLength and #value < schema.minLength then
			return false, "String too short (min: " .. schema.minLength .. ")"
		end
		
		if schema.maxLength and #value > schema.maxLength then
			return false, "String too long (max: " .. schema.maxLength .. ")"
		end
		
		-- Check pattern
		if schema.pattern then
			local match = string.match(value, schema.pattern)
			if not match or match ~= value then
				return false, "String does not match pattern: " .. schema.pattern
			end
		end
		
	elseif schema.type == "integer" then
		if type(value) ~= "number" or math.floor(value) ~= value then
			return false, "Expected integer"
		end
		
		-- Check min/max value
		if schema.minimum and value < schema.minimum then
			return false, "Value too small (min: " .. schema.minimum .. ")"
		end
		
		if schema.maximum and value > schema.maximum then
			return false, "Value too large (max: " .. schema.maximum .. ")"
		end
		
	elseif schema.type == "boolean" then
		if type(value) ~= "boolean" then
			return false, "Expected boolean"
		end
		
	elseif schema.type == "array" then
		if type(value) ~= "table" then
			return false, "Expected array"
		end
		
		-- Check array items
		if schema.items then
			for i, item in ipairs(value) do
				local valid, error_msg = M.validate_json_schema_value(item, schema.items)
				if not valid then
					return false, "Array item " .. i .. ": " .. error_msg
				end
			end
		end
		
	elseif schema.type == "object" then
		if type(value) ~= "table" then
			return false, "Expected object"
		end
		
		-- Check object properties
		if schema.properties then
			for prop_name, prop_value in pairs(value) do
				local prop_schema = schema.properties[prop_name]
				if prop_schema then
					local valid, error_msg = M.validate_json_schema_value(prop_value, prop_schema)
					if not valid then
						return false, "Property " .. prop_name .. ": " .. error_msg
					end
				end
			end
		end
	end
	
	return true, "Valid"
end

-- Generate enhanced schema with custom types
function M.enhance_schema_with_types(schema)
	if not schema or not schema.properties then
		return schema
	end
	
	local enhanced = vim.deepcopy(schema)
	
	for param_name, param_schema in pairs(enhanced.properties) do
		-- Add custom type information if available
		if param_schema.custom_type and M.types[param_schema.custom_type] then
			local type_def = M.types[param_schema.custom_type]
			param_schema.type_description = type_def.description
			param_schema.validation_pattern = type_def.validation.pattern
			param_schema.examples = type_def.validation.examples
		end
	end
	
	return enhanced
end

-- Get type information for a parameter
function M.get_type_info(type_name)
	local type_def = M.types[type_name]
	if not type_def then
		return nil
	end
	
	return {
		description = type_def.description,
		validation = type_def.validation,
		examples = type_def.validation.examples
	}
end

-- List all available types
function M.list_types()
	local type_list = {}
	for type_name, type_def in pairs(M.types) do
		table.insert(type_list, {
			name = type_name,
			description = type_def.description,
			validation = type_def.validation
		})
	end
	return type_list
end

-- Create a custom type
function M.create_custom_type(name, definition)
	if M.types[name] then
		return false, "Type already exists: " .. name
	end
	
	-- Validate definition structure
	if not definition.type then
		return false, "Type definition must include 'type' field"
	end
	
	if not definition.description then
		return false, "Type definition must include 'description' field"
	end
	
	-- Set default validation if not provided
	if not definition.validation then
		definition.validation = {}
	end
	
	M.types[name] = definition
	return true, "Custom type created: " .. name
end

-- Remove a custom type
function M.remove_custom_type(name)
	if not M.types[name] then
		return false, "Type does not exist: " .. name
	end
	
	-- Don't allow removal of built-in types
	local built_in_types = {
		"string", "integer", "boolean", "file_path", "directory_path",
		"filename", "file_extension", "code_content", "comment_content",
		"markdown_content", "search_query", "regex_pattern", "neovim_command",
		"shell_command", "url", "json_content", "config_key", "model_name",
		"timestamp", "date", "email", "version_string", "hex_color"
	}
	
	for _, built_in in ipairs(built_in_types) do
		if name == built_in then
			return false, "Cannot remove built-in type: " .. name
		end
	end
	
	M.types[name] = nil
	return true, "Custom type removed: " .. name
end

-- Show type information in a floating window
function M.show_type_info(type_name)
	local type_def = M.types[type_name]
	if not type_def then
		vim.notify("Type not found: " .. type_name, vim.log.levels.ERROR)
		return
	end
	
	local lines = {
		"# Type: " .. type_name,
		"",
		"**Description:** " .. type_def.description,
		"**Base Type:** " .. type_def.type,
		""
	}
	
	if type_def.validation then
		table.insert(lines, "## Validation Rules")
		table.insert(lines, "")
		
		if type_def.validation.pattern then
			table.insert(lines, "**Pattern:** `" .. type_def.validation.pattern .. "`")
		end
		
		if type_def.validation.min_length then
			table.insert(lines, "**Min Length:** " .. type_def.validation.min_length)
		end
		
		if type_def.validation.max_length then
			table.insert(lines, "**Max Length:** " .. type_def.validation.max_length)
		end
		
		if type_def.validation.min_value then
			table.insert(lines, "**Min Value:** " .. type_def.validation.min_value)
		end
		
		if type_def.validation.max_value then
			table.insert(lines, "**Max Value:** " .. type_def.validation.max_value)
		end
		
		if type_def.validation.examples then
			table.insert(lines, "")
			table.insert(lines, "## Examples")
			for _, example in ipairs(type_def.validation.examples) do
				table.insert(lines, "- `" .. tostring(example) .. "`")
			end
		end
	end
	
	-- Display in floating window
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	
	local width = 60
	local height = #lines + 2
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
	
	-- Close on q
	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(win, true)
		vim.api.nvim_buf_delete(buf, {force = true})
	end, {buffer = buf, noremap = true, silent = true})
end

return M
