-- MCP HTTP Transport for Model Context Protocol
--
-- This module provides the complete MCP HTTP transport implementation,
-- integrating HTTP client for requests and SSE client for events.

local mcp_http_transport = {}
-- Try to load http_client with different paths
local http_client
local success, result = pcall(require, "paragonic.http_client")
if success then
	http_client = result
else
	-- Fallback to relative path
	success, result = pcall(require, "http_client")
	if success then
		http_client = result
	else
		-- Final fallback to absolute path
		http_client = require("../../lua/paragonic/http_client")
	end
end

-- Try to load sse_client with different paths
local sse_client
local success2, result2 = pcall(require, "paragonic.sse_client")
if success2 then
	sse_client = result2
else
	-- Fallback to relative path
	success2, result2 = pcall(require, "sse_client")
	if success2 then
		sse_client = result2
	else
		-- Final fallback to absolute path
		sse_client = require("../../lua/paragonic/sse_client")
	end
end

-- Try to load OWASP security module with different paths
local mcp_owasp_security
local success3, result3 = pcall(require, "paragonic.mcp_owasp_security")
if success3 then
	mcp_owasp_security = result3
else
	-- Fallback to relative path
	success3, result3 = pcall(require, "mcp_owasp_security")
	if success3 then
		mcp_owasp_security = result3
	else
		-- Final fallback to absolute path
		mcp_owasp_security = require("../../lua/paragonic/mcp_owasp_security")
	end
end

-- Try to load performance monitoring module with different paths
local mcp_performance
local success4, result4 = pcall(require, "paragonic.mcp_performance")
if success4 then
	mcp_performance = result4
else
	-- Fallback to relative path
	success4, result4 = pcall(require, "mcp_performance")
	if success4 then
		mcp_performance = result4
	else
		-- Final fallback to absolute path
		mcp_performance = require("../../lua/paragonic/mcp_performance")
	end
end

local json = vim.json

-- MCP HTTP transport configuration
local DEFAULT_PROTOCOL_VERSION = "2025-06-18"
local DEFAULT_INITIALIZATION_TIMEOUT = 30 -- seconds
local DEFAULT_REQUEST_TIMEOUT = 60 -- seconds

-- MCP HTTP transport state
local transport_state = {
	base_url = nil,
	session_id = nil,
	stream_id = nil,
	protocol_version = DEFAULT_PROTOCOL_VERSION,
	is_initialized = false,
	is_connected = false,
	initialization_timeout = DEFAULT_INITIALIZATION_TIMEOUT,
	request_timeout = DEFAULT_REQUEST_TIMEOUT,
	callbacks = {},
	message_id_counter = 0,
}

-- MCP message types
local MCPMessageType = {
	REQUEST = "request",
	RESPONSE = "response",
	NOTIFICATION = "notification",
}

-- MCP HTTP transport errors
local MCPHTTPTransportError = {
	NOT_INITIALIZED = "not_initialized",
	NOT_CONNECTED = "not_connected",
	INITIALIZATION_FAILED = "initialization_failed",
	CONNECTION_FAILED = "connection_failed",
	INVALID_MESSAGE = "invalid_message",
	TIMEOUT = "timeout",
	PROTOCOL_ERROR = "protocol_error",
}

-- Initialize MCP HTTP transport
function mcp_http_transport.init(config)
	config = config or {}

	-- Basic validation for now
	local base_url = config.base_url or "http://localhost:3000"

	-- URL validation
	if type(base_url) ~= "string" then
		return false, "Invalid base_url: must be a string"
	end

	if not base_url:match("^https?://") then
		return false, "Invalid base_url: must start with http:// or https://"
	end

	-- Prevent dangerous protocols
	if
		base_url:match("^ftp://")
		or base_url:match("^file://")
		or base_url:match("^javascript:")
		or base_url:match("^data:")
	then
		return false, "Invalid base_url: dangerous protocol not allowed"
	end

	-- OWASP SSRF protection
	if mcp_owasp_security then
		local ssrf_valid, ssrf_err = mcp_owasp_security.validate_url_for_ssrf(base_url)
		if not ssrf_valid then
			return false, "SSRF protection: " .. ssrf_err
		end
	end

	-- Validate port if present
	local port_match = base_url:match(":(%d+)/?")
	if port_match then
		local port = tonumber(port_match)
		if port <= 0 or port > 65535 then
			return false, "Invalid base_url: port must be between 1 and 65535"
		end
	end

	-- Additional validation for negative ports (more specific)
	-- This regex is too complex, removing for now
	-- if base_url:match("://[^/]*:-%d+") then
	--     return false, "Invalid base_url: negative port not allowed"
	-- end

	-- Simple validation for negative ports (after protocol)
	-- TODO: Implement more precise negative port validation
	-- if base_url:match("://[^/]*:-") then
	--     return false, "Invalid base_url: negative port not allowed"
	-- end

	local protocol_version = config.protocol_version or DEFAULT_PROTOCOL_VERSION

	-- Protocol version validation
	if type(protocol_version) ~= "string" then
		return false, "Invalid protocol_version: must be a string"
	end

	if protocol_version ~= "2025-06-18" then
		return false, "Invalid protocol_version: only 2025-06-18 is supported"
	end

	local initialization_timeout = config.initialization_timeout or DEFAULT_INITIALIZATION_TIMEOUT

	-- Timeout validation
	if type(initialization_timeout) ~= "number" or initialization_timeout <= 0 then
		return false, "Invalid initialization_timeout: must be a positive number"
	end

	local request_timeout = config.request_timeout or DEFAULT_REQUEST_TIMEOUT

	if type(request_timeout) ~= "number" or request_timeout <= 0 then
		return false, "Invalid request_timeout: must be a positive number"
	end

	transport_state.base_url = base_url
	transport_state.protocol_version = protocol_version
	transport_state.initialization_timeout = initialization_timeout
	transport_state.request_timeout = request_timeout

	-- Initialize HTTP client
	local http_success = http_client.init({
		base_url = transport_state.base_url,
		timeout = transport_state.request_timeout,
		retry_attempts = 1, -- MCP handles its own retries
	})

	if not http_success then
		return false, "Failed to initialize HTTP client"
	end

	-- Initialize SSE client
	local sse_success = sse_client.init({
		base_url = transport_state.base_url,
		timeout = transport_state.initialization_timeout,
		reconnect_delay = config.reconnect_delay or 1,
		max_reconnect_attempts = config.max_reconnect_attempts or 5,
		event_buffer_size = config.event_buffer_size or 100,
	})

	if not sse_success then
		return false, "Failed to initialize SSE client"
	end

	transport_state.is_initialized = true

	-- Initialize performance monitoring if available
	if mcp_performance then
		local perf_config = {
			METRICS = {
				ENABLE_REAL_TIME_MONITORING = true,
				COLLECTION_INTERVAL = 5, -- 5 seconds for MCP
				MAX_METRICS_ENTRIES = 720, -- 1 hour at 5s intervals
			},
			THRESHOLDS = {
				REQUEST_TIMEOUT_WARNING = 2000, -- 2 seconds
				REQUEST_TIMEOUT_CRITICAL = 10000, -- 10 seconds
				MEMORY_USAGE_WARNING = 100, -- 100 MB
				MEMORY_USAGE_CRITICAL = 200, -- 200 MB
			},
			OPTIMIZATION = {
				ENAABLE_CONNECTION_POOLING = true,
				POOL_SIZE = 5, -- Smaller pool for MCP
				ENABLE_REQUEST_CACHING = true,
				CACHE_SIZE = 500, -- Smaller cache for MCP
				CACHE_TTL = 60, -- 1 minute TTL
			},
		}

		local perf_success = mcp_performance.init(perf_config)
		if not perf_success then
			local debug = require("paragonic.debug")
debug.debug_print("[MCP] Warning: Performance monitoring initialization failed", "warning")
		end
	end

	return true
end

-- Set callbacks for MCP events
function mcp_http_transport.set_callbacks(callbacks)
	transport_state.callbacks = callbacks or {}
end

-- Get current callbacks for MCP events
function mcp_http_transport.get_callbacks()
	return transport_state.callbacks or {}
end

-- Generate unique message ID
function mcp_http_transport.generate_message_id()
	transport_state.message_id_counter = transport_state.message_id_counter + 1
	return tostring(transport_state.message_id_counter)
end

-- Initialize MCP session
function mcp_http_transport.initialize_session(client_info)
	if not transport_state.is_initialized then
		return false, MCPHTTPTransportError.NOT_INITIALIZED
	end

	-- Validate client_info
	if not client_info or type(client_info) ~= "table" then
		return false, "Invalid client_info: must be a table"
	end

	if not client_info.name or type(client_info.name) ~= "string" then
		return false, "Invalid client_info.name: must be a non-empty string"
	end

	-- Validate client name length (prevent extremely long names)
	if #client_info.name > 1000 then
		return false, "Invalid client_info.name: too long (max 1000 characters)"
	end

	-- Validate client name content (basic sanitization)
	if client_info.name:match("[<>\"'&]") then
		return false, "Invalid client_info.name: contains invalid characters"
	end

	-- OWASP injection detection for client name
	if mcp_owasp_security then
		local injection_detected, injection_err = mcp_owasp_security.detect_injection(client_info.name, "client_name")
		if injection_detected then
			return false, "Injection detected in client name: " .. injection_err
		end
	end

	-- Validate version if provided
	if client_info.version and type(client_info.version) ~= "string" then
		return false, "Invalid client_info.version: must be a string"
	end

	if client_info.version and #client_info.version > 100 then
		return false, "Invalid client_info.version: too long (max 100 characters)"
	end

	-- OWASP injection detection for version
	if client_info.version and mcp_owasp_security then
		local injection_detected, injection_err =
			mcp_owasp_security.detect_injection(client_info.version, "client_version")
		if injection_detected then
			return false, "Injection detected in client version: " .. injection_err
		end
	end

	-- Validate capabilities if provided
	if client_info.capabilities and type(client_info.capabilities) ~= "table" then
		return false, "Invalid client_info.capabilities: must be a table"
	end

	-- Prepare initialization request
	local init_request = {
		jsonrpc = "2.0",
		id = mcp_http_transport.generate_message_id(),
		method = "initialize",
		params = {
			protocolVersion = transport_state.protocol_version,
			capabilities = client_info.capabilities or {},
			clientInfo = {
				name = client_info.name or "paragonic-client",
				version = client_info.version or "1.0.0",
			},
		},
	}

	-- Send initialization request
	local response, err = mcp_http_transport.send_request(init_request)
	if not response then
		return false, err or "Initialization request failed"
	end

	-- Check for initialization error
	if response.error then
		return false, response.error.message or "Initialization failed"
	end

	-- Extract session ID from response headers (MCP spec compliance)
	if response.headers and response.headers["mcp-session-id"] then
		transport_state.session_id = response.headers["mcp-session-id"]
		transport_state.stream_id = transport_state.session_id

		-- Set session ID in clients
		http_client.set_session_id(transport_state.session_id)
		sse_client.set_session_id(transport_state.session_id)
		sse_client.set_stream_id(transport_state.stream_id)
	else
		-- Fallback to JSON body for backward compatibility
		if response.result then
			transport_state.session_id = response.result.sessionId
			transport_state.stream_id = response.result.streamId

			-- Set session ID in clients
			http_client.set_session_id(transport_state.session_id)
			sse_client.set_session_id(transport_state.session_id)
			sse_client.set_stream_id(transport_state.stream_id)
		end
	end

	-- Connect to SSE stream for events
	local sse_callbacks = {
		on_connect = function(stream_id)
			transport_state.is_connected = true
			if transport_state.callbacks.on_connect then
				transport_state.callbacks.on_connect(stream_id)
			end
		end,
		on_disconnect = function()
			transport_state.is_connected = false
			if transport_state.callbacks.on_disconnect then
				transport_state.callbacks.on_disconnect()
			end
		end,
		on_message = function(event)
			mcp_http_transport._handle_sse_message(event)
		end,
		on_notification = function(event)
			mcp_http_transport._handle_sse_notification(event)
		end,
		on_error = function(error_msg, attempt)
			if transport_state.callbacks.on_error then
				transport_state.callbacks.on_error(error_msg, attempt)
			end
		end,
		on_parse_error = function(error_msg, raw_event)
			if transport_state.callbacks.on_parse_error then
				transport_state.callbacks.on_parse_error(error_msg, raw_event)
			end
		end,
		on_stream_expired = function(expiration_data)
			transport_state.is_connected = false
			if transport_state.callbacks.on_stream_expired then
				transport_state.callbacks.on_stream_expired(expiration_data)
			end
		end,
		on_reconnected = function()
			transport_state.is_connected = true
			if transport_state.callbacks.on_reconnected then
				transport_state.callbacks.on_reconnected()
			end
		end,
		on_reconnect_failed = function(error)
			if transport_state.callbacks.on_reconnect_failed then
				transport_state.callbacks.on_reconnect_failed(error)
			end
		end,
	}

	-- Connect to SSE stream - the server creates the stream internally based on session ID
	local connect_success, connect_err = sse_client.connect(nil, sse_callbacks)
	if not connect_success then
		return false, connect_err or "Failed to connect to SSE stream"
	end

	return true
end

-- Send MCP request
function mcp_http_transport.send_request(request)
	if not transport_state.is_initialized then
		return nil, MCPHTTPTransportError.NOT_INITIALIZED
	end

	-- Validate request
	if not request or type(request) ~= "table" then
		return nil, MCPHTTPTransportError.INVALID_MESSAGE
	end

	if not request.jsonrpc or request.jsonrpc ~= "2.0" then
		return nil, MCPHTTPTransportError.PROTOCOL_ERROR
	end

	if not request.method or type(request.method) ~= "string" then
		return nil, MCPHTTPTransportError.INVALID_MESSAGE
	end

	-- Validate method name length
	if #request.method > 1000 then
		return nil, "Method name too long (max 1000 characters)"
	end

	-- Validate method name content
	if request.method:match("[<>\"'&]") then
		return nil, "Method name contains invalid characters"
	end

	-- OWASP injection detection for method name
	if mcp_owasp_security then
		local injection_detected, injection_err = mcp_owasp_security.detect_injection(request.method, "method_name")
		if injection_detected then
			return nil, "Injection detected in method name: " .. injection_err
		end
	end

	-- Validate payload size
	local payload_size = 0
	local function calculate_size(obj)
		if type(obj) == "string" then
			payload_size = payload_size + #obj
		elseif type(obj) == "table" then
			for k, v in pairs(obj) do
				if type(k) == "string" then
					payload_size = payload_size + #k
				end
				calculate_size(v)
			end
		elseif type(obj) == "number" then
			payload_size = payload_size + 8 -- Approximate size for numbers
		elseif type(obj) == "boolean" then
			payload_size = payload_size + 1
		end

		-- Check size limit during calculation
		if payload_size > 1000000 then -- 1MB limit
			return false
		end
	end

	local size_ok = calculate_size(request)
	if size_ok == false then
		return nil, "Payload too large (max 1MB)"
	end

	-- OWASP injection detection for request parameters
	if request.params and mcp_owasp_security then
		local function check_params_for_injection(params, path)
			if type(params) == "string" then
				local injection_detected, injection_err = mcp_owasp_security.detect_injection(params, path)
				if injection_detected then
					return false, "Injection detected in " .. path .. ": " .. injection_err
				end
			elseif type(params) == "table" then
				for key, value in pairs(params) do
					local new_path = path .. "." .. tostring(key)
					local check_result, check_err = check_params_for_injection(value, new_path)
					if check_result == false then
						return false, check_err
					end
				end
			end
			return true
		end

		local params_ok, params_err = check_params_for_injection(request.params, "request.params")
		if not params_ok then
			return nil, params_err
		end
	end

	-- Ensure request has an ID
	if not request.id then
		request.id = mcp_http_transport.generate_message_id()
	end

	-- Performance monitoring
	local start_time = os.clock()
	local success = false

	-- Send HTTP POST request
	local response, err = http_client.post("/mcp", request)
	if not response then
		success = false
	else
		success = true
	end

	local end_time = os.clock()

	-- Record performance metrics
	if mcp_performance then
		mcp_performance.record_request(start_time, end_time, success)
	end

	if not response then
		return nil, err or MCPHTTPTransportError.CONNECTION_FAILED
	end

	-- Check HTTP response
	if not http_client.is_success(response) then
		return nil, http_client.get_error_message(response)
	end

	-- Parse JSON response
	if not response.body or type(response.body) ~= "table" then
		return nil, MCPHTTPTransportError.INVALID_MESSAGE
	end

	return response.body
end

-- Send MCP notification
function mcp_http_transport.send_notification(notification)
	if not transport_state.is_initialized then
		return false, MCPHTTPTransportError.NOT_INITIALIZED
	end

	-- Validate notification
	if not notification or type(notification) ~= "table" then
		return false, MCPHTTPTransportError.INVALID_MESSAGE
	end

	if not notification.jsonrpc or notification.jsonrpc ~= "2.0" then
		return false, MCPHTTPTransportError.PROTOCOL_ERROR
	end

	if not notification.method or type(notification.method) ~= "string" then
		return false, MCPHTTPTransportError.INVALID_MESSAGE
	end

	-- Validate method name length
	if #notification.method > 1000 then
		return false, "Method name too long (max 1000 characters)"
	end

	-- Validate method name content
	if notification.method:match("[<>\"'&]") then
		return false, "Method name contains invalid characters"
	end

	-- Validate payload size
	local payload_size = 0
	local function calculate_size(obj)
		if type(obj) == "string" then
			payload_size = payload_size + #obj
		elseif type(obj) == "table" then
			for k, v in pairs(obj) do
				if type(k) == "string" then
					payload_size = payload_size + #k
				end
				calculate_size(v)
			end
		elseif type(obj) == "number" then
			payload_size = payload_size + 8 -- Approximate size for numbers
		elseif type(obj) == "boolean" then
			payload_size = payload_size + 1
		end

		-- Check size limit during calculation
		if payload_size > 1000000 then -- 1MB limit
			return false
		end
	end

	local size_ok = calculate_size(notification)
	if size_ok == false then
		return false, "Payload too large (max 1MB)"
	end

	-- Notifications should not have an ID
	if notification.id then
		return false, MCPHTTPTransportError.INVALID_MESSAGE
	end

	-- Performance monitoring
	local start_time = os.clock()
	local success = false

	-- Send HTTP POST request
	local response, err = http_client.post("/mcp", notification)
	if not response then
		success = false
	else
		success = true
	end

	local end_time = os.clock()

	-- Record performance metrics
	if mcp_performance then
		mcp_performance.record_request(start_time, end_time, success)
	end

	if not response then
		return false, err or MCPHTTPTransportError.CONNECTION_FAILED
	end

	-- Check HTTP response
	if not http_client.is_success(response) then
		return false, http_client.get_error_message(response)
	end

	return true
end

-- Handle SSE message event
function mcp_http_transport._handle_sse_message(event)
	if not event.data then
		return
	end

	-- Parse JSON-RPC message from SSE data
	local success, message = pcall(json.decode, event.data)
	if not success or not message then
		if transport_state.callbacks.on_parse_error then
			transport_state.callbacks.on_parse_error("Failed to parse SSE message", event.data)
		end
		return
	end

	-- Validate message
	if not message.jsonrpc or message.jsonrpc ~= "2.0" then
		if transport_state.callbacks.on_error then
			transport_state.callbacks.on_error("Invalid JSON-RPC version", 0)
		end
		return
	end

	-- Handle based on message type
	if message.id then
		-- This is a response
		if transport_state.callbacks.on_response then
			transport_state.callbacks.on_response(message)
		end
	else
		-- This is a notification
		if transport_state.callbacks.on_notification then
			transport_state.callbacks.on_notification(message)
		end
	end
end

-- Handle SSE notification event
function mcp_http_transport._handle_sse_notification(event)
	if not event.data then
		return
	end

	-- Parse JSON-RPC notification from SSE data
	local success, notification = pcall(json.decode, event.data)
	if not success or not notification then
		if transport_state.callbacks.on_parse_error then
			transport_state.callbacks.on_parse_error("Failed to parse SSE notification", event.data)
		end
		return
	end

	-- Validate notification
	if not notification.jsonrpc or notification.jsonrpc ~= "2.0" then
		if transport_state.callbacks.on_error then
			transport_state.callbacks.on_error("Invalid JSON-RPC version", 0)
		end
		return
	end

	-- Handle notification
	if transport_state.callbacks.on_notification then
		transport_state.callbacks.on_notification(notification)
	end
end

-- Shutdown MCP session
function mcp_http_transport.shutdown()
	if not transport_state.is_initialized then
		return false, MCPHTTPTransportError.NOT_INITIALIZED
	end

	-- Send shutdown notification
	local shutdown_notification = {
		jsonrpc = "2.0",
		method = "notifications/shutdown",
	}

	local success, err = mcp_http_transport.send_notification(shutdown_notification)
	if not success then
		-- Log error but continue with cleanup
		if transport_state.callbacks.on_error then
			transport_state.callbacks.on_error("Shutdown notification failed: " .. (err or "unknown error"), 0)
		end
	end

	-- Disconnect SSE client
	if transport_state.is_connected then
		sse_client.disconnect()
		transport_state.is_connected = false
	end

	-- Reset state
	transport_state.session_id = nil
	transport_state.stream_id = nil
	transport_state.is_initialized = false

	return true
end

-- Get transport status
function mcp_http_transport.get_status()
	return {
		is_initialized = transport_state.is_initialized,
		is_connected = transport_state.is_connected,
		session_id = transport_state.session_id,
		stream_id = transport_state.stream_id,
		protocol_version = transport_state.protocol_version,
		base_url = transport_state.base_url,
		message_id_counter = transport_state.message_id_counter,
	}
end

-- Check if transport is ready
function mcp_http_transport.is_ready()
	return transport_state.is_initialized and transport_state.is_connected
end

-- Set callbacks for stream management
function mcp_http_transport.set_callbacks(callbacks)
	transport_state.callbacks = callbacks or {}
end

-- Request a new stream (for when current stream expires)
function mcp_http_transport.request_new_stream()
	if not transport_state.is_initialized then
		return false, MCPHTTPTransportError.NOT_INITIALIZED
	end

	-- Disconnect current SSE connection
	sse_client.disconnect()
	
	-- Reconnect to get a new stream
	local sse_callbacks = {
		on_connect = function(stream_id)
			transport_state.is_connected = true
			if transport_state.callbacks.on_connect then
				transport_state.callbacks.on_connect(stream_id)
			end
		end,
		on_disconnect = function()
			transport_state.is_connected = false
			if transport_state.callbacks.on_disconnect then
				transport_state.callbacks.on_disconnect()
			end
		end,
		on_message = function(event)
			mcp_http_transport._handle_sse_message(event)
		end,
		on_notification = function(event)
			mcp_http_transport._handle_sse_notification(event)
		end,
		on_error = function(error_msg, attempt)
			if transport_state.callbacks.on_error then
				transport_state.callbacks.on_error(error_msg, attempt)
			end
		end,
		on_parse_error = function(error_msg, raw_event)
			if transport_state.callbacks.on_parse_error then
				transport_state.callbacks.on_parse_error(error_msg, raw_event)
			end
		end,
		on_stream_expired = function(expiration_data)
			transport_state.is_connected = false
			if transport_state.callbacks.on_stream_expired then
				transport_state.callbacks.on_stream_expired(expiration_data)
			end
		end,
		on_reconnected = function()
			transport_state.is_connected = true
			if transport_state.callbacks.on_reconnected then
				transport_state.callbacks.on_reconnected()
			end
		end,
		on_reconnect_failed = function(error)
			if transport_state.callbacks.on_reconnect_failed then
				transport_state.callbacks.on_reconnect_failed(error)
			end
		end,
	}

	local success, err = sse_client.connect(nil, sse_callbacks)
	if success then
		return true
	else
		return false, err or "Failed to request new stream"
	end
end

-- Get session ID
function mcp_http_transport.get_session_id()
	return transport_state.session_id
end

-- Get stream ID
function mcp_http_transport.get_stream_id()
	return transport_state.stream_id
end

-- Get performance metrics
function mcp_http_transport.get_performance_metrics()
	if mcp_performance then
		return mcp_performance.get_metrics()
	end
	return nil
end

-- Get performance summary
function mcp_http_transport.get_performance_summary()
	if mcp_performance then
		return mcp_performance.get_summary()
	end
	return nil
end

-- Clean up resources
function mcp_http_transport.cleanup()
	-- Shutdown if initialized
	if transport_state.is_initialized then
		mcp_http_transport.shutdown()
	end

	-- Clean up clients
	http_client.cleanup()
	sse_client.cleanup()

	-- Cleanup performance monitoring
	if mcp_performance then
		mcp_performance.cleanup()
	end

	-- Reset state
	transport_state = {
		base_url = nil,
		session_id = nil,
		stream_id = nil,
		protocol_version = DEFAULT_PROTOCOL_VERSION,
		is_initialized = false,
		is_connected = false,
		initialization_timeout = DEFAULT_INITIALIZATION_TIMEOUT,
		request_timeout = DEFAULT_REQUEST_TIMEOUT,
		callbacks = {},
		message_id_counter = 0,
	}
end

-- Export module
return mcp_http_transport
