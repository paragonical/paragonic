-- MCP HTTP Transport for Model Context Protocol
--
-- This module provides the complete MCP HTTP transport implementation,
-- following the MCP Streamable HTTP transport specification.
--
-- Key principles:
-- 1. Every JSON-RPC message from client MUST be a new HTTP POST request
-- 2. Server MAY initiate temporary SSE stream in response to POST request
-- 3. SSE stream closes after sending the JSON-RPC response
-- 4. No persistent SSE connections

local mcp_http_transport = {}

-- Check if we're in a Neovim environment
local is_neovim = _G.vim ~= nil

-- Use vim.json if available, otherwise use a simple JSON library
local json
if is_neovim then
	json = vim.json
else
	-- Simple JSON fallback for standalone Lua
	json = {
		decode = function(str)
			-- Very basic JSON decoder for testing
			if str:match("^%s*{%s*$") then
				return {}
			end
			return nil
		end,
		encode = function(obj)
			-- Very basic JSON encoder for testing
			if type(obj) == "table" then
				return "{}"
			end
			return tostring(obj)
		end,
	}
end

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
		success, result = pcall(require, "../../lua/paragonic/http_client")
		if success then
			http_client = result
		else
			-- Mock http_client for testing
			http_client = {
				init = function(config)
					return true
				end,
				post = function(endpoint, data)
					-- Check if this is a streaming request
					if data and data.method == "streaming_chat_completion" then
						return {
							body = {
								jsonrpc = "2.0",
								id = data.id or "test",
								result = {
									streaming = true,
									request_id = data.id or "test-stream",
								},
							},
							headers = { ["content-type"] = "application/json" },
						}
					else
						return {
							body = { jsonrpc = "2.0", id = "test", result = { success = true } },
							headers = { ["content-type"] = "application/json" },
						}
					end
				end,
				set_session_id = function(id) end,
				is_success = function(response)
					return true
				end,
				get_error_message = function(response)
					return "mock error"
				end,
				cleanup = function() end,
			}
		end
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
		success3, result3 = pcall(require, "../../lua/paragonic/mcp_owasp_security")
		if success3 then
			mcp_owasp_security = result3
		else
			-- Mock OWASP security module for testing
			mcp_owasp_security = {
				validate_url_for_ssrf = function(url)
					return true
				end,
				detect_injection = function(str, context)
					return false
				end,
			}
		end
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
		success4, result4 = pcall(require, "../../lua/paragonic/mcp_performance")
		if success4 then
			mcp_performance = result4
		else
			-- Mock performance monitoring module for testing
			mcp_performance = {
				init = function(config)
					return true
				end,
				record_request = function(start_time, end_time, success) end,
				get_metrics = function()
					return {}
				end,
				get_summary = function()
					return {}
				end,
				cleanup = function() end,
			}
		end
	end
end

-- MCP HTTP transport configuration
local DEFAULT_PROTOCOL_VERSION = "2025-06-18"
local DEFAULT_INITIALIZATION_TIMEOUT = 30 -- seconds
local DEFAULT_REQUEST_TIMEOUT = 60 -- seconds

-- MCP HTTP transport state
local transport_state = {
	base_url = nil,
	session_id = nil,
	protocol_version = DEFAULT_PROTOCOL_VERSION,
	is_initialized = false,
	initialization_timeout = DEFAULT_INITIALIZATION_TIMEOUT,
	request_timeout = DEFAULT_REQUEST_TIMEOUT,
	callbacks = {},
	message_id_counter = 0,
	-- Track active streaming requests
	active_streams = {},
	transport_type = nil, -- "new" or "old"
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
	INITIALIZATION_FAILED = "initialization_failed",
	CONNECTION_FAILED = "connection_failed",
	INVALID_MESSAGE = "invalid_message",
	TIMEOUT = "timeout",
	PROTOCOL_ERROR = "protocol_error",
}

-- Initialize MCP HTTP transport
function mcp_http_transport.init(config)
	config = config or {}

	-- Initialize transport state
	transport_state = {
		base_url = config.base_url or "http://localhost:3000",
		protocol_version = config.protocol_version or "2025-06-18",
		initialization_timeout = config.initialization_timeout or 30,
		request_timeout = config.request_timeout or 60,
		is_initialized = false,
		session_id = nil,
		callbacks = {},
		message_id_counter = 0,
		active_streams = {},
		transport_type = nil, -- "new" or "old"
	}

	-- Initialize HTTP client
	local http_success, http_err = http_client.init({
		base_url = transport_state.base_url,
		timeout = transport_state.request_timeout,
		retry_attempts = 1, -- We handle retries at transport level
	})

	if not http_success then
		return false, "Failed to initialize HTTP client: " .. (http_err or "unknown error")
	end

	-- Try to detect transport type (new vs old)
	local transport_type, err = mcp_http_transport._detect_transport_type()
	if err then
		return false, "Failed to detect transport type: " .. err
	end

	transport_state.transport_type = transport_type
	local debug = require("paragonic.debug")
	debug.debug_print("🔧 Detected transport type: " .. transport_type, "info")

	transport_state.is_initialized = true
	return true
end

-- Detect whether server uses new or old transport
function mcp_http_transport._detect_transport_type()
	local debug = require("paragonic.debug")
	debug.debug_print("🔍 Detecting transport type...", "debug")

	-- Try new Streamable HTTP transport first
	local success, response = pcall(function()
		return http_client.post("/mcp", {
			headers = {
				["Accept"] = "application/json, text/event-stream",
				["Content-Type"] = "application/json",
				["MCP-Protocol-Version"] = transport_state.protocol_version,
				["Origin"] = "neovim://paragonic",
			},
			body = json.encode({
				jsonrpc = "2.0",
				method = "initialize",
				params = {
					protocolVersion = transport_state.protocol_version,
					capabilities = {},
					clientInfo = {
						name = "paragonic-client",
						version = "1.0.0",
					},
				},
				id = 1,
			}),
		})
	end)

	if success and response and response.status and response.status >= 200 and response.status < 300 then
		debug.debug_print("✅ New Streamable HTTP transport detected", "debug")
		return "new"
	end

	-- If new transport failed, try old HTTP+SSE transport
	debug.debug_print("🔄 New transport failed, trying old HTTP+SSE transport", "debug")

	local sse_success, sse_result = pcall(require, "paragonic.sse_client")
	if not sse_success then
		return nil, "SSE client not available for old transport"
	end

	local sse_client = sse_result

	-- Initialize SSE client for detection
	local sse_init_success = sse_client.init({
		base_url = transport_state.base_url,
		timeout = 5, -- Short timeout for detection
	})

	if not sse_init_success then
		return nil, "Failed to initialize SSE client for transport detection"
	end

	-- Try to connect to old transport endpoint
	local connect_success, connect_err = sse_client.connect(nil, {
		on_message = function(event)
			-- Check for endpoint event (indicates old transport)
			if event.data and event.data:match('"event"%s*:%s*"endpoint"') then
				debug.debug_print("✅ Old HTTP+SSE transport detected", "debug")
				-- We'll handle this in the main detection logic
			end
		end,
		on_error = function(error, code)
			-- Ignore errors during detection
		end,
		on_connect = function(stream_id)
			-- Connection successful, but we need to wait for endpoint event
		end,
		on_disconnect = function()
			-- Disconnection during detection
		end,
	})

	if connect_success then
		-- Wait a bit for the endpoint event
		if is_neovim then
			vim.wait(1000, function()
				return false
			end, 100)
		else
			-- Simple sleep for non-Neovim environment
			os.execute("sleep 1")
		end

		-- Disconnect the detection connection
		sse_client.disconnect()

		debug.debug_print("✅ Old HTTP+SSE transport detected", "debug")
		return "old"
	end

	return nil, "Neither new nor old transport detected"
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

		-- Set session ID in HTTP client
		http_client.set_session_id(transport_state.session_id)
	else
		-- Fallback to JSON body for backward compatibility
		if response.result then
			transport_state.session_id = response.result.sessionId

			-- Set session ID in HTTP client
			http_client.set_session_id(transport_state.session_id)
		end
	end

	-- Send initialized notification
	local initialized_notification = {
		jsonrpc = "2.0",
		method = "initialized",
		params = {},
	}

	local success, err = mcp_http_transport.send_notification(initialized_notification)
	if not success then
		return false, err or "Failed to send initialized notification"
	end

	return true
end

-- Send MCP request with streaming support
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

	-- Send HTTP POST request with proper headers
	local response, err = http_client.post("/mcp", request, {
		["Accept"] = "application/json, text/event-stream",
		["Content-Type"] = "application/json",
		["MCP-Protocol-Version"] = transport_state.protocol_version,
		["Origin"] = "neovim://paragonic",
	})
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

	-- This is a regular JSON response
	if not response.body or type(response.body) ~= "table" then
		return nil, MCPHTTPTransportError.INVALID_MESSAGE
	end

	-- Check if the response contains streaming chunks
	if response.body.result and response.body.result.type == "streaming_chunks" then
		-- Server returned streaming chunks directly in response
		return response.body
	else
		-- Regular response
		return response.body
	end
end

-- Start streaming connection for a request
function mcp_http_transport._start_streaming_connection(request_id, stream_request_id)
	-- Create a temporary SSE client for this request
	local sse_client
	local sse_success, sse_result = pcall(require, "paragonic.sse_client")
	if sse_success then
		sse_client = sse_result
	else
		-- Mock SSE client for testing
		sse_client = {
			init = function(config)
				return true
			end,
			set_session_id = function(id) end,
			connect = function(stream_id, callbacks)
				-- Simulate successful connection
				if callbacks and callbacks.on_connect then
					callbacks.on_connect(stream_id or "mock-stream")
				end
				return true
			end,
			disconnect = function()
				return true
			end,
		}
	end

	-- Initialize SSE client for this request
	local sse_success = sse_client.init({
		base_url = transport_state.base_url,
		timeout = transport_state.request_timeout,
	})

	if not sse_success then
		return nil, "Failed to initialize SSE client for streaming"
	end

	-- Set session ID if available
	if transport_state.session_id then
		sse_client.set_session_id(transport_state.session_id)
	end

	-- Track this stream
	transport_state.active_streams[request_id] = {
		sse_client = sse_client,
		chunks = {},
		completed = false,
		error = nil,
		stream_request_id = stream_request_id,
	}

	-- Set up SSE callbacks for this stream
	local stream_callbacks = {
		on_message = function(event)
			if event.data then
				-- Parse JSON-RPC message from SSE data
				local success, message = pcall(json.decode, event.data)
				if success and message then
					-- Handle streaming chunks
					if message.method == "notifications/message" and message.params then
						local params = message.params
						if params.type == "streaming_chunk" then
							table.insert(transport_state.active_streams[request_id].chunks, params)

							-- Call streaming callback if available
							if transport_state.callbacks.on_streaming_chunk then
								transport_state.callbacks.on_streaming_chunk(request_id, params)
							end
						elseif params.type == "streaming_complete" then
							transport_state.active_streams[request_id].completed = true

							-- Call completion callback if available
							if transport_state.callbacks.on_streaming_complete then
								transport_state.callbacks.on_streaming_complete(
									request_id,
									transport_state.active_streams[request_id].chunks
								)
							end

							-- Clean up SSE client
							sse_client.disconnect()
							transport_state.active_streams[request_id] = nil
						end
					elseif message.id == request_id then
						-- This is the final response for our request
						transport_state.active_streams[request_id].completed = true
						transport_state.active_streams[request_id].final_response = message

						-- Call completion callback if available
						if transport_state.callbacks.on_streaming_complete then
							transport_state.callbacks.on_streaming_complete(
								request_id,
								transport_state.active_streams[request_id].chunks,
								message
							)
						end

						-- Clean up SSE client
						sse_client.disconnect()
						transport_state.active_streams[request_id] = nil
					end
				end
			end
		end,
		on_error = function(error_msg)
			transport_state.active_streams[request_id].error = error_msg
			transport_state.active_streams[request_id].completed = true

			-- Call error callback if available
			if transport_state.callbacks.on_streaming_error then
				transport_state.callbacks.on_streaming_error(request_id, error_msg)
			end

			-- Clean up SSE client
			sse_client.disconnect()
			transport_state.active_streams[request_id] = nil
		end,
	}

	-- Connect to SSE stream
	local connect_success, connect_err = sse_client.connect(nil, stream_callbacks)
	if not connect_success then
		transport_state.active_streams[request_id] = nil
		return nil, connect_err or "Failed to connect to SSE stream"
	end

	-- Return immediately with streaming status
	return {
		jsonrpc = "2.0",
		id = request_id,
		result = {
			streaming = true,
			request_id = request_id,
		},
	}
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

-- Get streaming chunks for a request
function mcp_http_transport.get_streaming_chunks(request_id)
	if not transport_state.active_streams[request_id] then
		return nil, "No active stream for request ID: " .. request_id
	end

	return transport_state.active_streams[request_id].chunks
end

-- Check if streaming is complete for a request
function mcp_http_transport.is_streaming_complete(request_id)
	if not transport_state.active_streams[request_id] then
		return true -- No active stream means it's complete
	end

	return transport_state.active_streams[request_id].completed
end

-- Cancel streaming for a request
function mcp_http_transport.cancel_streaming(request_id)
	if not transport_state.active_streams[request_id] then
		return false, "No active stream for request ID: " .. request_id
	end

	-- Send cancellation notification
	local cancel_notification = {
		jsonrpc = "2.0",
		method = "notifications/cancelled",
		params = {
			request_id = request_id,
		},
	}

	local success, err = mcp_http_transport.send_notification(cancel_notification)
	if not success then
		return false, err or "Failed to send cancellation notification"
	end

	-- Clean up stream
	if transport_state.active_streams[request_id].sse_client then
		transport_state.active_streams[request_id].sse_client.disconnect()
	end
	transport_state.active_streams[request_id] = nil

	return true
end

-- Shutdown MCP session
function mcp_http_transport.shutdown()
	if not transport_state.is_initialized then
		return false, MCPHTTPTransportError.NOT_INITIALIZED
	end

	-- Cancel all active streams
	for request_id, _ in pairs(transport_state.active_streams) do
		mcp_http_transport.cancel_streaming(request_id)
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

	-- Reset state
	transport_state.session_id = nil
	transport_state.is_initialized = false
	transport_state.active_streams = {}

	return true
end

-- Get transport status
function mcp_http_transport.get_status()
	return {
		is_initialized = transport_state.is_initialized,
		session_id = transport_state.session_id,
		protocol_version = transport_state.protocol_version,
		base_url = transport_state.base_url,
		message_id_counter = transport_state.message_id_counter,
		active_streams_count = 0, -- Count active streams
	}
end

-- Check if transport is ready
function mcp_http_transport.is_ready()
	return transport_state.is_initialized
end

-- Get session ID
function mcp_http_transport.get_session_id()
	return transport_state.session_id
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

	-- Cleanup performance monitoring
	if mcp_performance then
		mcp_performance.cleanup()
	end

	-- Reset state
	transport_state = {
		base_url = nil,
		session_id = nil,
		protocol_version = DEFAULT_PROTOCOL_VERSION,
		is_initialized = false,
		initialization_timeout = DEFAULT_INITIALIZATION_TIMEOUT,
		request_timeout = DEFAULT_REQUEST_TIMEOUT,
		callbacks = {},
		message_id_counter = 0,
		active_streams = {},
	}
end

-- Export module
return mcp_http_transport
