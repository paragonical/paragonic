-- Transport Layer: MCP Protocol, HTTP Communication, Connection Management
-- Provides clean, protocol-agnostic interface for all transport operations

local M = {}

-- Transport state
local transport_state = {
	initialized = false,
	connected = false,
	base_url = nil,
	protocol_version = nil,
	session_id = nil,
	request_timeout = 60,
	initialization_timeout = 30,
}

-- Dependencies
local http_client = require("paragonic.http_client")
local debug = require("paragonic.debug")

-- Initialize transport layer
function M.init(config)
	if transport_state.initialized then
		debug.debug_print("⚠️ Transport already initialized", "warn")
		return true
	end

	config = config or {}

	-- Set configuration
	transport_state.base_url = config.base_url or "http://localhost:3000"
	transport_state.protocol_version = config.protocol_version or "2025-06-18"
	transport_state.request_timeout = config.request_timeout or 60
	transport_state.initialization_timeout = config.initialization_timeout or 30

	debug.debug_print("🔧 Initializing transport layer", "info")
	debug.debug_print("   Base URL: " .. transport_state.base_url, "debug")
	debug.debug_print("   Protocol Version: " .. transport_state.protocol_version, "debug")

	-- Initialize HTTP client
	local http_ok = http_client.init({
		base_url = transport_state.base_url,
		timeout = transport_state.request_timeout,
		retry_attempts = 3,
		retry_delay = 1,
	})

	if not http_ok then
		debug.debug_print("❌ HTTP client initialization failed", "error")
		return false, "HTTP client initialization failed"
	end

	transport_state.initialized = true
	debug.debug_print("✅ Transport layer initialized", "success")

	return true
end

-- Connect to server and initialize MCP session
function M.connect()
	if not transport_state.initialized then
		return false, "Transport not initialized"
	end

	if transport_state.connected then
		debug.debug_print("⚠️ Already connected", "warn")
		return true
	end

	debug.debug_print("🔧 Connecting to server", "info")

	-- Initialize MCP session
	local session_request = {
		jsonrpc = "2.0",
		method = "initialize",
		params = {
			protocolVersion = transport_state.protocol_version,
			capabilities = {
				tools = {},
				resources = {},
				notifications = {},
			},
			clientInfo = {
				name = "paragonic.nvim",
				version = "1.0.0",
			},
		},
		id = 1,
	}

	-- Use HTTP client directly to avoid recursive call
	local response, err = http_client.post("/mcp", session_request, M._get_headers())
	if not response then
		debug.debug_print("❌ Session initialization failed: " .. tostring(err), "error")
		return false, "Session initialization failed: " .. tostring(err)
	end

	if response.body and response.body.error then
		local error_msg = response.body.error.message or "Unknown error"
		debug.debug_print("❌ Session initialization failed: " .. error_msg, "error")
		return false, "Session initialization failed: " .. error_msg
	end

	-- Store session ID if provided
	if response.result and response.result.serverInfo then
		transport_state.session_id = response.result.serverInfo.sessionId
		debug.debug_print("✅ Session initialized with ID: " .. (transport_state.session_id or "none"), "success")
	end

	transport_state.connected = true
	debug.debug_print("✅ Connected to server", "success")

	return true
end

-- Disconnect from server
function M.disconnect()
	if not transport_state.connected then
		return true
	end

	debug.debug_print("🔧 Disconnecting from server", "info")

	-- Send shutdown request if connected
	if transport_state.connected then
		local shutdown_request = {
			jsonrpc = "2.0",
			method = "notifications/exit",
			params = {},
			id = math.random(1000, 9999),
		}

		-- Don't wait for response, just send it
		http_client.post("/mcp", shutdown_request, M._get_headers())
	end

	transport_state.connected = false
	transport_state.session_id = nil
	debug.debug_print("✅ Disconnected from server", "success")

	return true
end

-- Check if connected
function M.is_connected()
	return transport_state.connected
end

-- Send MCP request with consistent error handling
function M.send_request(method, params, request_id)
	if not transport_state.initialized then
		return nil, "Transport not initialized"
	end

	-- Don't auto-connect for initialize method to avoid infinite loop
	if not transport_state.connected and method ~= "initialize" then
		debug.debug_print("⚠️ Not connected, attempting to connect", "warn")
		local connect_ok, connect_err = M.connect()
		if not connect_ok then
			return nil, "Connection failed: " .. tostring(connect_err)
		end
	end

	-- Build request
	local request = {
		jsonrpc = "2.0",
		method = method,
		params = params or {},
		id = request_id or math.random(1000, 9999),
	}

	debug.debug_print("📤 Sending request: " .. method, "debug")
	debug.debug_print("   ID: " .. tostring(request.id), "debug")

	-- Send HTTP request
	local response, err = http_client.post("/mcp", request, M._get_headers())
	if not response then
		debug.debug_print("❌ HTTP request failed: " .. tostring(err), "error")
		return nil, "HTTP request failed: " .. tostring(err)
	end

	-- Parse response
	if not response.body then
		debug.debug_print("❌ Empty response body", "error")
		return nil, "Empty response body"
	end

	-- Check for JSON-RPC error
	if response.body.error then
		local error_msg = response.body.error.message or "Unknown JSON-RPC error"
		debug.debug_print("❌ JSON-RPC error: " .. error_msg, "error")
		return { error = response.body.error }, nil
	end

	debug.debug_print("✅ Request successful: " .. method, "debug")
	return response.body, nil
end

-- Get standard headers for MCP requests
function M._get_headers()
	return {
		["Accept"] = "application/json, text/event-stream",
		["Content-Type"] = "application/json",
		["MCP-Protocol-Version"] = transport_state.protocol_version,
		["Origin"] = "neovim://paragonic",
	}
end

-- Get transport status
function M.get_status()
	return {
		initialized = transport_state.initialized,
		connected = transport_state.connected,
		base_url = transport_state.base_url,
		protocol_version = transport_state.protocol_version,
		session_id = transport_state.session_id,
	}
end

-- Cleanup transport layer
function M.cleanup()
	debug.debug_print("🔧 Cleaning up transport layer", "info")

	M.disconnect()
	transport_state.initialized = false

	debug.debug_print("✅ Transport layer cleaned up", "success")
end

return M
