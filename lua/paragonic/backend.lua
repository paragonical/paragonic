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

		-- Set up MCP callbacks for streaming
		mcp.set_callbacks({
			on_streaming_chunk = function(request_id, chunk)
				debug.debug_print("📥 Received streaming chunk for request " .. request_id .. ": " .. (chunk.chunk or "no content"), "debug")
				debug.debug_print("📥 Chunk type: " .. (chunk.chunk_type or "unknown"), "debug")
				debug.debug_print("📥 Chunk index: " .. (chunk.chunk_index or "unknown"), "debug")
				
				-- Store the chunk for the chat system to retrieve
				if not client.streaming_chunks then
					client.streaming_chunks = {}
				end
				table.insert(client.streaming_chunks, chunk)
				debug.debug_print("📥 Total chunks stored: " .. #client.streaming_chunks, "debug")
			end,
			on_streaming_complete = function(request_id, chunks, final_response)
				debug.debug_print("✅ Streaming complete for request " .. request_id, "success")
				debug.debug_print("📊 Total chunks received: " .. #chunks, "debug")
				
				-- Store final response if provided
				if final_response then
					client.final_response = final_response
				end
				
				-- Mark streaming as complete
				client.is_streaming = false
			end,
			on_streaming_error = function(request_id, error)
				debug.debug_print("❌ Streaming error for request " .. request_id .. ": " .. (error or "unknown error"), "error")
				client.is_streaming = false
				client.streaming_error = error
			end,
		})

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
		-- Clear any previous streaming chunks
		client.streaming_chunks = {}
		client.streaming_error = nil
		client.final_response = nil
		
		-- Mark as streaming
		client.is_streaming = true
		
		local resp, err = mcp.send_request({
			jsonrpc = "2.0",
			method = "streaming_chat_completion",
			id = math.random(1000, 9999),
			params = params or {},
			_meta = {
				progressToken = "streaming_" .. os.time() .. "_" .. math.random(1000, 9999)
			}
		})
		
		if not resp then
			client.is_streaming = false
			return resp, err
		end
		
		-- Check if this is a streaming response
		if resp.result and resp.result.streaming then
			client.current_streaming_request_id = resp.result.request_id
			debug.debug_print("🔄 Started streaming request: " .. resp.result.request_id, "info")
			return resp
		else
			-- Regular response, not streaming
			client.is_streaming = false
			return resp, err
		end
	end

	function client:get_streaming_chunks()
		local chunks = client.streaming_chunks or {}
		return chunks
	end

	function client:add_streaming_chunk(chunk)
		if not client.streaming_chunks then
			client.streaming_chunks = {}
		end
		table.insert(client.streaming_chunks, chunk)
		debug.debug_print("📥 Added chunk to streaming buffer: " .. (chunk.chunk_type or "unknown"), "debug")
	end

	function client:clear_streaming_chunks()
		client.streaming_chunks = {}
	end

	function client:set_streaming_active(active)
		client.is_streaming = active
		local debug = require("paragonic.debug")
		if active then
			debug.debug_print("🔄 Streaming marked as active", "debug")
		else
			debug.debug_print("🔄 Streaming marked as inactive", "debug")
		end
	end

	function client:is_streaming_complete()
		if not client.current_streaming_request_id then
			return true -- No active streaming
		end
		
		return mcp.is_streaming_complete(client.current_streaming_request_id)
	end

	function client:cancel_streaming()
		if not client.current_streaming_request_id then
			return false, "No active streaming to cancel"
		end
		
		local success, err = mcp.cancel_streaming(client.current_streaming_request_id)
		if success then
			client.is_streaming = false
			client.current_streaming_request_id = nil
			debug.debug_print("🛑 Streaming cancelled", "info")
		end
		
		return success, err
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
					content_type = content_type or "all",
					limit = limit or 10,
					threshold = threshold or 0.7
				}
			}
		})
		return resp, err
	end

	-- Knowledge Management (using MCP tools)
	function client:add_knowledge(content, content_type, metadata)
		local resp, err = mcp.send_request({
			jsonrpc = "2.0",
			method = "tools/call",
			params = {
				name = "add_knowledge",
				arguments = {
					content = content,
					content_type = content_type or "text",
					metadata = metadata or {}
				}
			}
		})
		return resp, err
	end

	function client:get_knowledge_summary()
		local resp, err = mcp.send_request({
			jsonrpc = "2.0",
			method = "tools/call",
			params = {
				name = "get_knowledge_summary",
				arguments = {}
			}
		})
		return resp, err
	end

	-- Pattern Management (using MCP tools)
	function client:list_patterns()
		local resp, err = mcp.send_request({
			jsonrpc = "2.0",
			method = "tools/call",
			params = {
				name = "list_patterns",
				arguments = {}
			}
		})
		return resp, err
	end

	function client:execute_pattern(pattern_name, context)
		local resp, err = mcp.send_request({
			jsonrpc = "2.0",
			method = "tools/call",
			params = {
				name = "execute_pattern",
				arguments = {
					pattern_name = pattern_name,
					context = context or {}
				}
			}
		})
		return resp, err
	end

	function client:create_pattern(pattern_data)
		local resp, err = mcp.send_request({
			jsonrpc = "2.0",
			method = "tools/call",
			params = {
				name = "create_pattern",
				arguments = pattern_data
			}
		})
		return resp, err
	end

	-- Session Management (using MCP tools)
	function client:get_session_info()
		local resp, err = mcp.send_request({
			jsonrpc = "2.0",
			method = "tools/call",
			params = {
				name = "get_session_info",
				arguments = {}
			}
		})
		return resp, err
	end

	function client:update_session_context(context)
		local resp, err = mcp.send_request({
			jsonrpc = "2.0",
			method = "tools/call",
			params = {
				name = "update_session_context",
				arguments = {
					context = context or {}
				}
			}
		})
		return resp, err
	end

	-- Debug and Testing
	function client:test_connection()
		local resp, err = mcp.send_request({
			jsonrpc = "2.0",
			method = "tools/call",
			params = {
				name = "test_connection",
				arguments = {}
			}
		})
		return resp, err
	end

	function client:get_debug_info()
		local resp, err = mcp.send_request({
			jsonrpc = "2.0",
			method = "tools/call",
			params = {
				name = "get_debug_info",
				arguments = {}
			}
		})
		return resp, err
	end

	-- Initialize streaming state
	client.streaming_chunks = {}
	client.is_streaming = false
	client.current_streaming_request_id = nil
	client.streaming_error = nil
	client.final_response = nil

	return client
end

-- Initialize backend
function M.init()
	local debug = require("paragonic.debug")
	debug.debug_print("🔧 Initializing Paragonic backend", "info")

	-- Create MCP client
	M._rpc_client = create_mcp_client()

	debug.debug_print("✅ Paragonic backend initialized", "success")
	return true
end

-- Get RPC client instance
function M._get_rpc_client()
	return M._rpc_client
end

-- Connect to backend
function M.connect()
	if not M._rpc_client then
		M.init()
	end

	local debug = require("paragonic.debug")
	debug.debug_print("🔧 Connecting to Paragonic backend", "info")

	local success, err = M._rpc_client:connect()
	if success then
		debug.debug_print("✅ Connected to Paragonic backend", "success")
	else
		debug.debug_print("❌ Failed to connect to Paragonic backend: " .. tostring(err), "error")
	end

	return success, err
end

-- Initialize backend (for backward compatibility with chat module)
function M.initialize_backend()
	if not M._rpc_client then
		M.init()
	end
	
	local success, err = M.connect()
	return success
end

-- Disconnect from backend
function M.disconnect()
	if M._rpc_client then
		local debug = require("paragonic.debug")
		debug.debug_print("🔧 Disconnecting from Paragonic backend", "info")

		local success = M._rpc_client:disconnect()
		if success then
			debug.debug_print("✅ Disconnected from Paragonic backend", "success")
		else
			debug.debug_print("❌ Failed to disconnect from Paragonic backend", "error")
		end

		return success
	end
	return false
end

-- Check if connected
function M.is_connected()
	if M._rpc_client then
		return M._rpc_client:is_connected()
	end
	return false
end

-- Reconnect to backend
function M.reconnect()
	if M._rpc_client then
		local debug = require("paragonic.debug")
		debug.debug_print("🔧 Reconnecting to Paragonic backend", "info")

		local success, err = M._rpc_client:reconnect()
		if success then
			debug.debug_print("✅ Reconnected to Paragonic backend", "success")
		else
			debug.debug_print("❌ Failed to reconnect to Paragonic backend: " .. tostring(err), "error")
		end

		return success, err
	end
	return false, "No RPC client available"
end

-- Get backend status
function M.get_status()
	if not M._rpc_client then
		return {
			initialized = false,
			connected = false,
			streaming = false,
		}
	end

	return {
		initialized = true,
		connected = M._rpc_client:is_connected(),
		streaming = M._rpc_client.is_streaming or false,
		streaming_chunks_count = #(M._rpc_client.streaming_chunks or {}),
		current_streaming_request_id = M._rpc_client.current_streaming_request_id,
		streaming_error = M._rpc_client.streaming_error,
	}
end

-- Clean up backend
function M.cleanup()
	if M._rpc_client then
		local debug = require("paragonic.debug")
		debug.debug_print("🔧 Cleaning up Paragonic backend", "info")

		M._rpc_client:disconnect()
		M._rpc_client = nil

		debug.debug_print("✅ Paragonic backend cleaned up", "success")
	end
end

return M
