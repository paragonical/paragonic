--[[
Paragonic Backend Module
Handles MCP HTTP client initialization and backend management
--]]

local M = {}

-- MCP-backed client instance (shim that exposes the old RPC-like API)
M._rpc_client = nil

-- Create MCP client shim that matches the existing RPC client's methods
local function create_mcp_client()
	local debug = require("paragonic.debug")
	local config = require("paragonic.config")
	local mcp = require("paragonic.mcp_http_transport")

	local client = {}

	function client:connect()
		local base_url = config.get and (config.get("backend_base_url") or config.get("base_url")) or nil
		base_url = base_url or "http://localhost:3000"

		debug.debug_print("🔧 MCP connect(): base_url=" .. tostring(base_url), "debug")

		local ok, err = mcp.init({
			base_url = base_url,
			protocol_version = "2025-06-18",
			initialization_timeout = 30,
			request_timeout = 60,
		})
		if not ok then
			debug.debug_print("❌ MCP init failed: " .. tostring(err), "error")
			return false, err
		end

		local ok2, err2 = mcp.initialize_session({
			name = "paragonic.nvim",
			version = "1.0.0",
			capabilities = { tools = {}, resources = {}, notifications = {} },
		})
		if not ok2 then
			debug.debug_print("❌ MCP initialize_session failed: " .. tostring(err2), "error")
			return false, err2
		end

		debug.debug_print("✅ MCP connected and session initialized", "success")
		return true
	end

	function client:is_connected()
		local ok = mcp.is_ready()
		return ok and true or false
	end

	function client:reconnect()
		debug.debug_print("🔧 MCP reconnect()", "debug")
		mcp.cleanup()
		return self:connect()
	end

	function client:disconnect()
		debug.debug_print("🔧 MCP disconnect()", "debug")
		mcp.shutdown()
		return true
	end

	function client:hello()
		-- Use tools/list as a lightweight liveness check
		local resp, err = mcp.send_request({ jsonrpc = "2.0", method = "tools/list", params = {} })
		return resp, err
	end

	-- Model Management (using MCP tools)
	function client:list_models()
		local resp, err = mcp.send_request({
			jsonrpc = "2.0",
			method = "tools/call",
			params = {
				name = "list_models",
				arguments = {}
			}
		})
		return resp, err
	end

	-- Chat/AI (using MCP completion and tools)
	function client:chat_completion(model, message)
		local resp, err = mcp.send_request({
			jsonrpc = "2.0",
			method = "completion/complete",
			params = {
				prompt = message,
				model = model or "deepseek-r1:1.5b",
				options = {},
				_meta = {
					progressToken = "chat_" .. os.time() .. "_" .. math.random(1000, 9999)
				}
			}
		})
		return resp, err
	end

	function client:formatted_chat_completion(model, message, format_config)
		local resp, err = mcp.send_request({
			jsonrpc = "2.0",
			method = "tools/call",
			params = {
				name = "formatted_chat_completion",
				arguments = {
					model = model or "deepseek-r1:1.5b",
					message = message,
					format_config = format_config or {}
				}
			}
		})
		return resp, err
	end

	function client:streaming_chat_completion(params)
		local resp, err = mcp.send_request({
			jsonrpc = "2.0",
			method = "tools/call",
			params = {
				name = "streaming_chat_completion",
				arguments = params or {},
				_meta = {
					progressToken = "streaming_" .. os.time() .. "_" .. math.random(1000, 9999)
				}
			}
		})
		return resp, err
	end

	function client:get_next_chunk(params)
		local resp, err = mcp.send_request({
			jsonrpc = "2.0",
			method = "get_next_chunk",
			params = params or {},
		})
		return resp, err
	end

	function client:debug_markdown_test(params)
		local resp, err = mcp.send_request({
			jsonrpc = "2.0",
			method = "debug_markdown_test",
			params = params or {},
		})
		return resp, err
	end

	-- Config/Projects (using MCP tools)
	function client:get_projects()
		local resp, err = mcp.send_request({
			jsonrpc = "2.0",
			method = "tools/call",
			params = {
				name = "list_projects",
				arguments = {}
			}
		})
		return resp, err
	end

	function client:create_project(name, description)
		local resp, err = mcp.send_request({
			jsonrpc = "2.0",
			method = "tools/call",
			params = {
				name = "create_project",
				arguments = {
					name = name,
					description = description or ""
				}
			}
		})
		return resp, err
	end

	function client:get_config()
		-- For now use resources/read on a mock config resource
		local resp, err = mcp.send_request({
			jsonrpc = "2.0",
			method = "resources/read",
			params = { uri = "neovim://session" },
		})
		return resp, err
	end

	-- File Operations (using MCP tools)
	function client:save_config(config_data)
		local resp, err = mcp.send_request({
			jsonrpc = "2.0",
			method = "tools/call",
			params = {
				name = "write_file",
				arguments = {
					file_path = "config.json",
					content = vim.json.encode(config_data)
				}
			}
		})
		return resp, err
	end

	-- Search/Knowledge (using MCP tools)
	function client:search_embeddings(query, limit)
		local resp, err = mcp.send_request({
			jsonrpc = "2.0",
			method = "tools/call",
			params = {
				name = "search_embeddings",
				arguments = {
					query = query,
					limit = limit or 10
				}
			}
		})
		return resp, err
	end

	function client:find_similar_content(query, content_type, limit, threshold)
		local resp, err = mcp.send_request({
			jsonrpc = "2.0",
			method = "tools/call",
			params = {
				name = "find_similar_content",
				arguments = {
					query = query,
					content_type = content_type,
					limit = limit or 10,
					threshold = threshold or 0.0
				}
			}
		})
		return resp, err
	end

	function client:hybrid_search(query, content_type, limit, threshold, include_text_filtering)
		local resp, err = mcp.send_request({
			jsonrpc = "2.0",
			method = "tools/call",
			params = {
				name = "hybrid_search",
				arguments = {
					query = query,
					content_type = content_type,
					limit = limit or 10,
					threshold = threshold or 0.0,
					include_text_filtering = include_text_filtering ~= false
				}
			}
		})
		return resp, err
	end

	return client
end

-- Get RPC client, initializing backend if needed
function M._get_rpc_client()
	if not M._rpc_client then
		-- Return nil immediately - let calling functions handle initialization
		-- This prevents freezing during buffer operations
		return nil
	end

	-- Check if the client is still connected and try to reconnect if needed
	if not M._rpc_client:is_connected() then
		local debug = require("paragonic.debug")
		debug.debug_print("🔧 Client disconnected, attempting reconnection...", "info")
		local success = M._rpc_client:reconnect()
		if not success then
			debug.debug_print("❌ Reconnection failed, returning nil", "error")
			return nil
		end
		debug.debug_print("✅ Client reconnected successfully", "success")
	end

	return M._rpc_client
end

-- Initialize Rust backend (now MCP HTTP)
function M._initialize_backend()
	local debug = require("paragonic.debug")
	debug.debug_print("🔧 _initialize_backend() called (MCP)", "debug")

	-- Only initialize once
	if M._rpc_client then
		debug.debug_print("✅ Client already exists, returning true", "info")
		return true
	end

	debug.debug_print("🔧 Starting MCP backend initialization...", "info")

	-- Create MCP client shim
	local client = create_mcp_client()
	M._rpc_client = client

	-- Connection attempts (preserve original timing/flow)
	local connection_timeout = 5000 -- 5 seconds
	local max_retries = 2
	local retry_count = 0

	while retry_count <= max_retries do
		local start_time = vim.loop.hrtime() / 1000000
		debug.debug_print(
			"🔧 Attempt " .. (retry_count + 1) .. "/" .. (max_retries + 1) .. ": About to call connect()...",
			"debug"
		)

		local ok, err = M._rpc_client:connect()
		if not ok then
			local end_time = vim.loop.hrtime() / 1000000
			local duration = end_time - start_time
			retry_count = retry_count + 1
			if duration > connection_timeout then
				debug.debug_print(
					"❌ Connection timed out after "
						.. string.format("%.1f", duration)
						.. "ms (attempt "
						.. retry_count
						.. "/"
						.. (max_retries + 1)
						.. ")",
					"error"
				)
			else
				debug.debug_print(
					"❌ Connection failed: "
						.. (err or "unknown error")
						.. " (attempt "
						.. retry_count
						.. "/"
						.. (max_retries + 1)
						.. ")",
					"error"
				)
			end
			if retry_count > max_retries then
				debug.debug_print("❌ Failed to connect after " .. (max_retries + 1) .. " attempts", "error")
				M._rpc_client = nil
				return false
			end
			debug.debug_print("⏳ Waiting 1 second before retry...", "info")
			vim.wait(1000)
		else
			debug.debug_print("✅ Connection successful!", "success")
			break
		end
	end

	-- Test connection with hello call
	debug.debug_print("🔧 Step 4: About to test connection with hello call (MCP)...", "debug")
	local hello_start = vim.loop.hrtime() / 1000000
	local response = M._rpc_client:hello()
	local hello_end = vim.loop.hrtime() / 1000000
	local hello_duration = hello_end - hello_start

	if not response then
		if hello_duration > connection_timeout then
			debug.debug_print(
				"❌ Hello call timed out after " .. string.format("%.1f", hello_duration) .. "ms",
				"error"
			)
		else
			debug.debug_print("❌ Hello call failed - no response", "error")
		end
		M._rpc_client:disconnect()
		M._rpc_client = nil
		return false
	end

	debug.debug_print(
		"✅ Backend initialization completed successfully in " .. string.format("%.1f", hello_duration) .. "ms",
		"success"
	)
	return true
end

-- Force reconnection to the backend (useful when server restarts)
function M.force_reconnect()
	local debug = require("paragonic.debug")
	debug.debug_print("🔧 force_reconnect() called", "debug")

	if not M._rpc_client then
		debug.debug_print("🔧 No client exists, initializing backend...", "info")
		return M._initialize_backend()
	end

	debug.debug_print("🔧 Forcing reconnection of existing client...", "info")
	M._rpc_client:disconnect()
	local success = M._rpc_client:reconnect()
	if success then
		debug.debug_print("✅ Force reconnection successful", "success")
		return true
	else
		debug.debug_print("❌ Force reconnection failed, reinitializing backend...", "error")
		M._rpc_client = nil
		return M._initialize_backend()
	end
end

-- Manually initialize backend when needed
function M.initialize_backend()
	if not M._rpc_client then
		-- If MCP is already initialized and connected, adopt it without reconnecting
		local ok_mcp, mcp = pcall(require, "paragonic.mcp_http_transport")
		if ok_mcp and mcp.is_ready() then
			M._rpc_client = (M._rpc_client or create_mcp_client())
			return true
		end
		M._initialize_backend()
	end
	return M._rpc_client ~= nil
end

-- Get list of available models
function M.get_available_models()
	local rpc_client = M._get_rpc_client()
	if not rpc_client then
		-- Return default models to prevent freezing
		return { "deepseek-r1:1.5b", "llama2", "llama3.2:3b", "nomic-embed-text:latest" }
	end

	local success, response = pcall(function()
		return rpc_client:list_models()
	end)

	if not success or not response then
		return { "deepseek-r1:1.5b", "llama2", "llama3.2:3b", "nomic-embed-text:latest" }
	end

	local utils = require("paragonic.utils")
	local parsed_response = utils.parse_json_response(response)
	if not parsed_response then
		return { "deepseek-r1:1.5b", "llama2", "llama3.2:3b", "nomic-embed-text:latest" }
	end

	if parsed_response.result and parsed_response.result.models then
		return parsed_response.result.models
	else
		return { "deepseek-r1:1.5b", "llama2", "llama3.2:3b", "nomic-embed-text:latest" }
	end
end

-- The remainder of the module uses the rpc_client interface unchanged
-- (get_projects, create_project, get_config, save_config, search functions)
-- which are now backed by MCP HTTP through the shim above

return M
