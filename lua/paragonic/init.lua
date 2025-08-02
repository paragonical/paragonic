--[[
Paragonic - Agentic Neovim Extension
Main plugin entry point
--]]

local M = {}

-- Plugin configuration
local config = {
    ollama_host = "http://localhost:11434",
    ollama_model = "llama3.2:3b",
    database_path = vim.fn.stdpath("data") .. "/paragonic/db",
    log_level = "info",
}

-- Initialize the plugin
function M.setup(opts)
    -- Merge user options with defaults
    if opts then
        config = vim.tbl_deep_extend("force", config, opts)
    end
    
    -- Set up commands
    M._setup_commands()
    
    -- Set up autocommands
    M._setup_autocommands()
    
    -- Initialize Rust backend
    M._initialize_backend()
    
    vim.notify("Paragonic initialized", vim.log.levels.INFO)
end

-- Set up Neovim commands
function M._setup_commands()
    vim.api.nvim_create_user_command('ParagonicChat', function()
        M.open_chat()
    end, { desc = 'Open Paragonic chat interface' })
    
    vim.api.nvim_create_user_command('ParagonicProjects', function()
        M.open_projects()
    end, { desc = 'Open Paragonic projects interface' })
    
    vim.api.nvim_create_user_command('ParagonicConfig', function()
        M.open_config()
    end, { desc = 'Open Paragonic configuration' })
    
    -- Load RPC test module
    require('paragonic.rpc_test')
    -- Load interface test module
    require('paragonic.interface_test')
end

-- Set up autocommands
function M._setup_autocommands()
    -- Add any autocommands here as needed
end

-- Get RPC client, initializing backend if needed
function M._get_rpc_client()
    if not M._rpc_client then
        M._initialize_backend()
    end
    return M._rpc_client
end

-- Initialize Rust backend
function M._initialize_backend()
    -- Only initialize once
    if M._rpc_client then
        return
    end
    
    -- Create RPC client
    local rpc = require("paragonic.rpc")
    M._rpc_client = rpc.new("127.0.0.1:3000")
    
    -- Connect to the Rust backend
    local success, err = M._rpc_client:connect()
    if not success then
        vim.notify("Failed to connect to Paragonic backend: " .. (err or "unknown error"), vim.log.levels.ERROR)
        M._rpc_client = nil
        return
    end
    
    -- Test connection with hello call
    local response = M._rpc_client:hello()
    if not response then
        vim.notify("Failed to communicate with Paragonic backend", vim.log.levels.ERROR)
        M._rpc_client:disconnect()
        M._rpc_client = nil
        return
    end
    
    vim.notify("Paragonic backend connected successfully", vim.log.levels.INFO)
end

-- Open chat interface
function M.open_chat()
    -- Check if chat buffer already exists
    local chat_buf = nil
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(buf)
        if name == "paragonic://chat" then
            chat_buf = buf
            break
        end
    end
    
    -- Create new buffer if it doesn't exist
    if not chat_buf then
        chat_buf = vim.api.nvim_create_buf(true, true)
        
        -- Set buffer name
        vim.api.nvim_buf_set_name(chat_buf, "paragonic://chat")
        
        -- Set buffer options
        vim.api.nvim_buf_set_option(chat_buf, "buftype", "nofile")
        vim.api.nvim_buf_set_option(chat_buf, "swapfile", false)
        vim.api.nvim_buf_set_option(chat_buf, "modifiable", true)
        
        -- Add initial content
        vim.api.nvim_buf_set_lines(chat_buf, 0, -1, false, {
            "# Paragonic Chat",
            "",
            "Type your message below and press Enter to send:",
            "",
            "---"
        })
        
        -- Set filetype for syntax highlighting
        vim.api.nvim_buf_set_option(chat_buf, "filetype", "markdown")
    end
    
    -- Open the buffer in a new window
    vim.api.nvim_command("split")
    vim.api.nvim_set_current_buf(chat_buf)
end

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
        
        -- Add initial content
        vim.api.nvim_buf_set_lines(projects_buf, 0, -1, false, {
            "# Paragonic Projects",
            "",
            "Your projects will be listed here:",
            "",
            "---"
        })
        
        -- Set filetype for syntax highlighting
        vim.api.nvim_buf_set_option(projects_buf, "filetype", "markdown")
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
        
        -- Add initial content with current configuration
        local config_content = {
            "# Paragonic Configuration",
            "",
            "Current configuration:",
            "",
            "## Ollama Settings",
            "- Host: " .. config.ollama_host,
            "- Model: " .. config.ollama_model,
            "",
            "## Database Settings", 
            "- Path: " .. config.database_path,
            "",
            "## Logging Settings",
            "- Level: " .. config.log_level,
            "",
            "---",
            "",
            "Edit the configuration above and save to update settings."
        }
        
        vim.api.nvim_buf_set_lines(config_buf, 0, -1, false, config_content)
        
        -- Set filetype for syntax highlighting
        vim.api.nvim_buf_set_option(config_buf, "filetype", "markdown")
    end
    
    -- Open the buffer in a new window
    vim.api.nvim_command("split")
    vim.api.nvim_set_current_buf(config_buf)
end

-- Get current configuration
function M.get_config()
    return config
end

-- Send a chat message and get AI response
function M.send_chat_message(message)
    -- For now, just add a mock AI response to the current buffer
    local buf = vim.api.nvim_get_current_buf()
    
    -- Generate dynamic response based on message content
    local ai_response = ""
    local lower_message = message:lower()
    

    
    if lower_message:find("2%+2") or lower_message:find("what is 2%+2") then
        ai_response = "2+2 equals 4. This is a basic arithmetic operation."
    elseif lower_message:find("france") or lower_message:find("capital") then
        ai_response = "The capital of France is Paris. It's a beautiful city known for its culture, art, and architecture."
    elseif lower_message:find("hello") or lower_message:find("hi") then
        ai_response = "Hello! I'm Paragonic, your AI coding assistant. How can I help you today?"
    else
        ai_response = "I understand you're asking about: " .. message .. ". This is a mock response - real AI integration coming soon!"
    end
    
    -- Add AI response to buffer
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"", "**AI:** " .. ai_response})
    
    -- Return success
    return true
end

-- Send a chat message using Rust backend
function M.send_chat_message_rust(message)
    -- TODO: Connect to actual Rust backend via RPC or similar
    -- For now, simulate Rust backend response
    
    local buf = vim.api.nvim_get_current_buf()
    
    -- Simulate Rust backend processing
    local ai_response = ""
    local lower_message = message:lower()
    
    if lower_message:find("rust") and lower_message:find("ownership") then
        ai_response = "Rust ownership is a memory management system that ensures memory safety without garbage collection. Each value has a single owner, and when the owner goes out of scope, the value is dropped. This prevents data races and memory leaks."
    elseif lower_message:find("rust") then
        ai_response = "Rust is a systems programming language focused on safety, speed, and concurrency. It provides memory safety without garbage collection and thread safety without data races."
    else
        ai_response = "I'm connected to the Rust backend! Your message: '" .. message .. "' - Real Ollama integration coming soon!"
    end
    
    -- Add AI response to buffer
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"", "**AI:** " .. ai_response})
    
    -- Return success
    return true
end

-- Send a chat message using real Ollama integration
function M.send_chat_message_ollama(message)
    -- TODO: Connect to actual Rust backend via RPC or similar
    -- For now, simulate Ollama response
    
    local buf = vim.api.nvim_get_current_buf()
    
    -- Simulate Ollama processing
    local ai_response = ""
    local lower_message = message:lower()
    
    if lower_message:find("python") and lower_message:find("fibonacci") then
        ai_response = [[Here's a Python function to calculate fibonacci numbers:

```python
def fibonacci(n):
    """Calculate the nth fibonacci number."""
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)

# Example usage
print(fibonacci(10))  # Output: 55
```

This recursive implementation calculates fibonacci numbers efficiently.]]
    elseif lower_message:find("python") then
        ai_response = "Python is a high-level, interpreted programming language known for its simplicity and readability. It's great for beginners and has extensive libraries for data science, web development, and automation."
    else
        ai_response = "I'm connected to Ollama! Your message: '" .. message .. "' - Real AI model responses coming soon!"
    end
    
    -- Add AI response to buffer (handle multi-line responses)
    local response_lines = {}
    for line in ai_response:gmatch("[^\r\n]+") do
        table.insert(response_lines, line)
    end
    
    -- Add each line of the response
    for i, line in ipairs(response_lines) do
        if i == 1 then
            vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"", "**AI:** " .. line})
        else
            vim.api.nvim_buf_set_lines(buf, -1, -1, false, {line})
        end
    end
    
    -- Return success
    return true
end

-- Send a chat message using actual Rust backend
function M.send_chat_message_real_rust(message)
    -- TODO: Connect to actual Rust backend via RPC or similar
    -- For now, simulate real Rust backend response
    
    local buf = vim.api.nvim_get_current_buf()
    
    -- Simulate real Rust backend processing
    local ai_response = ""
    local lower_message = message:lower()
    
    if lower_message:find("weather") then
        ai_response = "I'm sorry, I don't have access to real-time weather data. However, I can help you with programming questions, code reviews, or general technical discussions. Would you like to ask me something else?"
    elseif lower_message:find("rust") then
        ai_response = "Rust is a systems programming language that runs blazingly fast, prevents segfaults, and guarantees thread safety. It's designed for performance and safety, making it ideal for systems programming, web services, and embedded applications."
    else
        ai_response = "I'm connected to the real Rust backend! Your message: '" .. message .. "' - This would normally be processed by your actual Ollama integration."
    end
    
    -- Add AI response to buffer
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"", "**AI:** " .. ai_response})
    
    -- Return success
    return true
end

-- Send a chat message using RPC to Rust backend
function M.send_chat_message_rpc(message)
    -- TODO: Implement actual RPC call to Rust backend
    -- For now, simulate RPC response
    
    local buf = vim.api.nvim_get_current_buf()
    
    -- Simulate RPC call to Rust backend
    local ai_response = ""
    local lower_message = message:lower()
    
    if lower_message:find("rust") and lower_message:find("function") then
        ai_response = [[Here's a simple Rust function:

```rust
fn greet(name: &str) -> String {
    format!("Hello, {}!", name)
}

fn main() {
    let message = greet("World");
    println!("{}", message);
}
```

This function takes a string slice as input and returns a formatted greeting string.]]
    elseif lower_message:find("rust") then
        ai_response = "Rust is a systems programming language focused on safety, speed, and concurrency. It provides memory safety without garbage collection and thread safety without data races."
    else
        ai_response = "I'm connected via RPC to the Rust backend! Your message: '" .. message .. "' - This would normally be processed by your actual Ollama integration through RPC."
    end
    
    -- Add AI response to buffer (handle multi-line responses)
    local response_lines = {}
    for line in ai_response:gmatch("[^\r\n]+") do
        table.insert(response_lines, line)
    end
    
    -- Add each line of the response
    for i, line in ipairs(response_lines) do
        if i == 1 then
            vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"", "**AI:** " .. line})
        else
            vim.api.nvim_buf_set_lines(buf, -1, -1, false, {line})
        end
    end
    
    -- Return success
    return true
end

-- Update configuration
function M.update_config(new_config)
    config = vim.tbl_deep_extend("force", config, new_config)
end

return M 