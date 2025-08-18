# Tool Types System Guide

This guide explains the type system for MCP tool arguments, including regex validation for string types and custom type creation.

## Overview

The tool types system provides:
- **Type definitions** with validation patterns
- **Regex validation** for string types
- **Automatic parameter validation** for MCP tools
- **Custom type creation** for specific use cases
- **Enhanced documentation** with examples

## Quick Start

### Basic Commands

```lua
-- Validate a value against a type
:lua require('paragonic.mcp').validate_type('value', 'type_name')

-- Validate tool parameters
:lua require('paragonic.mcp').validate_tool_parameters(params, 'tool_name')

-- Show type information
:lua require('paragonic.mcp').show_type_info('type_name')

-- List all available types
:lua require('paragonic.mcp').list_available_types()
```

## Built-in Types

### Basic Types

#### `string`
- **Description:** A string value
- **Validation:** No pattern restriction
- **Examples:** `"example"`, `"test"`, `"value"`

#### `integer`
- **Description:** An integer value
- **Validation:** Numeric constraints
- **Examples:** `1`, `42`, `1000`

#### `boolean`
- **Description:** A boolean value
- **Validation:** True/false only
- **Examples:** `true`, `false`

### File System Types

#### `file_path`
- **Description:** Path to a file
- **Pattern:** `^[^<>:"|?*]+$` (No invalid Windows characters)
- **Length:** 1-4096 characters
- **Examples:** `"src/main.lua"`, `"/home/user/file.txt"`, `"C:\\Users\\file.txt"`

#### `directory_path`
- **Description:** Path to a directory
- **Pattern:** `^[^<>:"|?*]+/?$` (Directory path, optional trailing slash)
- **Length:** 1-4096 characters
- **Examples:** `"src/"`, `"/home/user/"`, `"C:\\Users\\"`

#### `filename`
- **Description:** A filename (without path)
- **Pattern:** `^[^<>:"|?*/\\\\]+$` (No path separators or invalid chars)
- **Length:** 1-255 characters
- **Examples:** `"main.lua"`, `"config.json"`, `"README.md"`

#### `file_extension`
- **Description:** A file extension
- **Pattern:** `^\\.[a-zA-Z0-9]+$` (Starts with dot, alphanumeric)
- **Length:** 2-10 characters
- **Examples:** `".lua"`, `".json"`, `".md"`, `".txt"`

### Code and Content Types

#### `code_content`
- **Description:** Programming code content
- **Validation:** No pattern restriction for code
- **Length:** 0-100,000 characters (100KB limit)
- **Examples:** `"print('Hello World')"`, `"function test() { return true; }"`

#### `comment_content`
- **Description:** Comment content
- **Pattern:** `^[^\\n\\r]*$` (No newlines in comments)
- **Length:** 0-1,000 characters
- **Examples:** `"This is a comment"`, `"-- Lua comment"`, `"// C comment"`

#### `markdown_content`
- **Description:** Markdown formatted content
- **Validation:** No pattern restriction for markdown
- **Length:** 0-50,000 characters
- **Examples:** `"# Title\n\nContent here"`, `"**Bold** and *italic* text"`

### Search and Query Types

#### `search_query`
- **Description:** Search query string
- **Pattern:** `^[^\\n\\r]+$` (No newlines in search queries)
- **Length:** 1-1,000 characters
- **Examples:** `"function"`, `"*.lua"`, `"TODO"`

#### `regex_pattern`
- **Description:** Regular expression pattern
- **Validation:** No pattern restriction for regex
- **Length:** 1-500 characters
- **Examples:** `"\\b\\w+\\b"`, `".*\\.lua$"`, `"^[A-Z]"`

### Command Types

#### `neovim_command`
- **Description:** Neovim command
- **Pattern:** `^[a-zA-Z][a-zA-Z0-9_]*$` (Alphanumeric, starts with letter)
- **Length:** 1-100 characters
- **Examples:** `"buffers"`, `"ls"`, `"pwd"`, `"version"`

#### `shell_command`
- **Description:** Shell command
- **Pattern:** `^[a-zA-Z][a-zA-Z0-9_-]*$` (Alphanumeric, starts with letter)
- **Length:** 1-100 characters
- **Examples:** `"ls"`, `"pwd"`, `"date"`, `"whoami"`

### URL and Network Types

#### `url`
- **Description:** URL address
- **Pattern:** `^https?://[^\\s]+$` (HTTP/HTTPS URL)
- **Length:** 10-2,048 characters
- **Examples:** `"https://example.com"`, `"http://localhost:3000"`

### Configuration Types

#### `json_content`
- **Description:** JSON formatted content
- **Validation:** No pattern restriction for JSON
- **Length:** 2-100,000 characters (At least "{}")
- **Examples:** `"{\"key\": \"value\"}"`, `"{\"array\": [1, 2, 3]}"`

#### `config_key`
- **Description:** Configuration key name
- **Pattern:** `^[a-zA-Z_][a-zA-Z0-9_]*$` (Valid identifier)
- **Length:** 1-100 characters
- **Examples:** `"api_key"`, `"base_url"`, `"timeout"`

### Model and AI Types

#### `model_name`
- **Description:** AI model name/identifier
- **Pattern:** `^[a-zA-Z0-9][a-zA-Z0-9._-]*$` (Valid model name)
- **Length:** 1-100 characters
- **Examples:** `"llama3.1:8b"`, `"deepseek-coder:1.3b"`, `"gpt-4"`

### Time and Date Types

#### `timestamp`
- **Description:** ISO 8601 timestamp
- **Pattern:** `^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\.\\d{3})?Z?$`
- **Length:** 19-30 characters
- **Examples:** `"2024-01-15T10:30:00Z"`, `"2024-01-15T10:30:00.123Z"`

#### `date`
- **Description:** Date in YYYY-MM-DD format
- **Pattern:** `^\\d{4}-\\d{2}-\\d{2}$`
- **Length:** 10 characters (exact)
- **Examples:** `"2024-01-15"`, `"2024-12-31"`

### Custom Types

#### `email`
- **Description:** Email address
- **Pattern:** `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$`
- **Length:** 5-254 characters
- **Examples:** `"user@example.com"`, `"test.email+tag@domain.co.uk"`

#### `version_string`
- **Description:** Version string (semantic versioning)
- **Pattern:** `^\\d+\\.\\d+\\.\\d+(-[a-zA-Z0-9.-]+)?(\\+[a-zA-Z0-9.-]+)?$`
- **Length:** 5-50 characters
- **Examples:** `"1.0.0"`, `"2.1.3-beta"`, `"3.0.0+20240115"`

#### `hex_color`
- **Description:** Hexadecimal color code
- **Pattern:** `^#[0-9A-Fa-f]{6}$`
- **Length:** 7 characters (exact)
- **Examples:** `"#FF0000"`, `"#00FF00"`, `"#0000FF"`

## Type Validation

### Individual Type Validation

```lua
-- Validate a single value against a type
local valid, reason = require('paragonic.mcp').validate_type('user@example.com', 'email')
if valid then
    print("Valid email")
else
    print("Invalid email: " .. reason)
end
```

### Tool Parameter Validation

```lua
-- Validate complete tool parameters
local params = {
    file_name = "test.txt",
    content = "Hello World",
    open_in_window = false
}

local valid, reason = require('paragonic.mcp').validate_tool_parameters(params, 'agent_create_file')
if valid then
    print("Valid parameters")
else
    print("Invalid parameters: " .. reason)
end
```

### Validation Examples

```lua
-- File path validation
local valid, reason = require('paragonic.mcp').validate_type('src/main.lua', 'file_path')
-- Result: true, "Valid"

local valid, reason = require('paragonic.mcp').validate_type('file<with>invalid:chars', 'file_path')
-- Result: false, "String does not match pattern: ^[^<>:\"|?*]+$"

-- Email validation
local valid, reason = require('paragonic.mcp').validate_type('user@example.com', 'email')
-- Result: true, "Valid"

local valid, reason = require('paragonic.mcp').validate_type('invalid-email', 'email')
-- Result: false, "String does not match pattern: ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"

-- Version string validation
local valid, reason = require('paragonic.mcp').validate_type('1.2.3', 'version_string')
-- Result: true, "Valid"

local valid, reason = require('paragonic.mcp').validate_type('2.1.0-beta', 'version_string')
-- Result: true, "Valid"
```

## Custom Type Creation

### Creating Custom Types

```lua
-- Define a custom type
local custom_type_def = {
    type = "string",
    description = "Python function name (snake_case)",
    validation = {
        pattern = "^[a-z][a-z0-9_]*$",
        min_length = 1,
        max_length = 50,
        examples = {"calculate_sum", "process_data", "validate_input"}
    }
}

-- Create the custom type
local success, message = require('paragonic.mcp').create_custom_type("python_function_name", custom_type_def)
if success then
    print("Custom type created: " .. message)
else
    print("Failed to create type: " .. message)
end
```

### Custom Type Definition Structure

```lua
local type_definition = {
    type = "string",           -- Required: Base type (string, integer, boolean)
    description = "...",       -- Required: Human-readable description
    validation = {             -- Optional: Validation rules
        pattern = "...",       -- Optional: Regex pattern for strings
        min_length = 1,        -- Optional: Minimum length for strings
        max_length = 100,      -- Optional: Maximum length for strings
        min_value = 0,         -- Optional: Minimum value for integers
        max_value = 1000,      -- Optional: Maximum value for integers
        examples = {...}       -- Optional: Example values
    }
}
```

### Custom Type Examples

#### Python Function Name
```lua
{
    type = "string",
    description = "Python function name (snake_case)",
    validation = {
        pattern = "^[a-z][a-z0-9_]*$",
        min_length = 1,
        max_length = 50,
        examples = {"calculate_sum", "process_data", "validate_input"}
    }
}
```

#### Git Branch Name
```lua
{
    type = "string",
    description = "Git branch name",
    validation = {
        pattern = "^[a-zA-Z0-9/_-]+$",
        min_length = 1,
        max_length = 100,
        examples = {"main", "feature/new-feature", "bugfix/issue-123"}
    }
}
```

#### Port Number
```lua
{
    type = "integer",
    description = "Network port number",
    validation = {
        min_value = 1,
        max_value = 65535,
        examples = {80, 443, 3000, 8080}
    }
}
```

### Managing Custom Types

```lua
-- Create a custom type
local success, message = require('paragonic.mcp').create_custom_type("my_custom_type", definition)

-- Remove a custom type
local success, message = require('paragonic.mcp').remove_custom_type("my_custom_type")

-- List all types (including custom ones)
local types = require('paragonic.mcp').list_available_types()
for _, type_info in ipairs(types) do
    print(type_info.name .. " - " .. type_info.description)
end
```

## Tool Schema Enhancement

### Automatic Enhancement

Tool schemas are automatically enhanced with type information when the type system is available:

```lua
-- Original schema
{
    type = "object",
    properties = {
        file_name = {
            type = "string",
            custom_type = "filename",
            description = "Name of the file to create"
        }
    }
}

-- Enhanced schema (automatically generated)
{
    type = "object",
    properties = {
        file_name = {
            type = "string",
            custom_type = "filename",
            description = "Name of the file to create",
            type_description = "A filename (without path)",
            validation_pattern = "^[^<>:\"|?*/\\\\]+$",
            examples = {"main.lua", "config.json", "README.md"}
        }
    }
}
```

### Manual Enhancement

```lua
-- Enhance a specific tool's schema
local success, message = require('paragonic.mcp').enhance_tool_schema("agent_create_file")
if success then
    print("Schema enhanced: " .. message)
else
    print("Failed to enhance schema: " .. message)
end
```

## Type Information Display

### Show Type Information

```lua
-- Display detailed information about a type in a floating window
require('paragonic.mcp').show_type_info('file_path')
```

The floating window shows:
- **Description** and base type
- **Validation patterns** (regex)
- **Length/value constraints**
- **Example values**

### Available Commands

```lua
-- Show type information
:lua require('paragonic.mcp').show_type_info('file_path')
:lua require('paragonic.mcp').show_type_info('email')
:lua require('paragonic.mcp').show_type_info('version_string')

-- List all types
:lua print(vim.inspect(require('paragonic.mcp').list_available_types()))
```

## Integration with MCP Tools

### Automatic Validation

When tools are executed, parameters are automatically validated:

```lua
-- This will automatically validate parameters before execution
local success, result = require('paragonic.mcp').execute_tool_with_approval(
    "agent_create_file",
    {
        file_name = "test.txt",
        content = "Hello World"
    },
    "request-123"
)

if not success then
    print("Tool execution failed: " .. result)
end
```

### Updated Tool Schemas

MCP tools now include custom types:

```lua
-- agent_create_file tool schema
{
    name = "agent_create_file",
    inputSchema = {
        type = "object",
        properties = {
            file_name = {
                type = "string",
                custom_type = "filename",  -- Uses filename type
                description = "Name of the file to create"
            },
            content = {
                type = "string",
                custom_type = "code_content",  -- Uses code_content type
                description = "Initial content for the file"
            },
            open_in_window = {
                type = "boolean",
                description = "Whether to open the file in a new window"
            }
        },
        required = {"file_name"}
    }
}
```

## Best Practices

### 1. Type Selection

- **Use specific types** when possible (e.g., `file_path` instead of `string`)
- **Create custom types** for domain-specific validation
- **Consider validation patterns** when designing new types

### 2. Custom Type Design

- **Clear descriptions** help users understand the type
- **Comprehensive examples** show expected usage
- **Appropriate constraints** prevent invalid data
- **Regex patterns** should be well-tested

### 3. Validation Strategy

- **Validate early** in the tool execution pipeline
- **Provide clear error messages** when validation fails
- **Use type information** to guide users

### 4. Documentation

- **Document custom types** with clear descriptions
- **Include examples** for all types
- **Explain validation patterns** when complex

## Examples

### Complete Tool with Types

```lua
-- Define a tool with comprehensive type validation
local tool_definition = {
    name = "create_config_file",
    description = "Create a configuration file with validation",
    inputSchema = {
        type = "object",
        properties = {
            file_name = {
                type = "string",
                custom_type = "filename",
                description = "Configuration file name"
            },
            config_type = {
                type = "string",
                enum = {"json", "yaml", "toml"},
                description = "Configuration file format"
            },
            content = {
                type = "string",
                custom_type = "json_content",
                description = "Configuration content"
            },
            port = {
                type = "integer",
                minimum = 1,
                maximum = 65535,
                description = "Server port number"
            }
        },
        required = {"file_name", "config_type"}
    }
}
```

### Custom Type for API Keys

```lua
-- Create a custom type for API keys
local api_key_type = {
    type = "string",
    description = "API key (alphanumeric, 32-64 characters)",
    validation = {
        pattern = "^[a-zA-Z0-9]{32,64}$",
        min_length = 32,
        max_length = 64,
        examples = {"abc123def456ghi789jkl012mno345pqr678stu901"}
    }
}

require('paragonic.mcp').create_custom_type("api_key", api_key_type)
```

### Validation in Practice

```lua
-- Validate API key
local valid, reason = require('paragonic.mcp').validate_type("my-api-key-123", "api_key")
-- Result: false, "String does not match pattern: ^[a-zA-Z0-9]{32,64}$"

-- Validate with correct format
local valid, reason = require('paragonic.mcp').validate_type("abc123def456ghi789jkl012mno345pqr678stu901", "api_key")
-- Result: true, "Valid"
```

## Troubleshooting

### Common Issues

**Type not found:**
```lua
-- Check if type exists
local types = require('paragonic.mcp').list_available_types()
for _, type_info in ipairs(types) do
    if type_info.name == "my_type" then
        print("Type exists")
        break
    end
end
```

**Validation failing:**
```lua
-- Test pattern manually
local pattern = "^[a-zA-Z0-9]+$"
local test_value = "test123"
local match = string.match(test_value, pattern)
if match and match == test_value then
    print("Pattern matches")
else
    print("Pattern does not match")
end
```

**Custom type creation failing:**
```lua
-- Check type definition structure
local definition = {
    type = "string",           -- Required
    description = "...",       -- Required
    validation = {             -- Optional
        pattern = "...",       -- Optional
        examples = {...}       -- Optional
    }
}
```

### Debug Commands

```lua
-- Show detailed type information
:lua require('paragonic.mcp').show_type_info('type_name')

-- Test validation manually
:lua print(require('paragonic.mcp').validate_type('test', 'string'))

-- List all available types
:lua print(vim.inspect(require('paragonic.mcp').list_available_types()))
```

## Conclusion

The tool types system provides comprehensive validation for MCP tool arguments with regex patterns for string types. It enhances safety, documentation, and user experience while maintaining flexibility through custom type creation.

For more information, see the demo files:
- `demo_tool_types.lua` - Interactive type system demo
- `lua/paragonic/tool_types.lua` - Core type system implementation
