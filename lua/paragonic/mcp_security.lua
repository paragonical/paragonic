-- MCP Security Module
--
-- This module provides comprehensive security measures for the MCP
-- HTTP transport implementation.

local mcp_security = {}

-- Security configuration
local SECURITY_CONFIG = {
	-- Input validation limits
	MAX_METHOD_LENGTH = 1000,
	MAX_CLIENT_NAME_LENGTH = 1000,
	MAX_CLIENT_VERSION_LENGTH = 100,
	MAX_PAYLOAD_SIZE = 1000000, -- 1MB

	-- Rate limiting
	MAX_REQUESTS_PER_MINUTE = 1000,
	MAX_CONNECTIONS_PER_IP = 10,

	-- Timeout limits
	MIN_TIMEOUT = 1,
	MAX_TIMEOUT = 3600, -- 1 hour

	-- Allowed protocols
	ALLOWED_PROTOCOLS = { "http", "https" },
	BLOCKED_PROTOCOLS = { "ftp", "file", "javascript", "data" },

	-- Allowed protocol versions
	ALLOWED_PROTOCOL_VERSIONS = { "2025-06-18" },

	-- Allowed transport types
	ALLOWED_TRANSPORT_TYPES = { "auto", "http", "tcp" },

	-- Security headers
	SECURITY_HEADERS = {
		["X-Content-Type-Options"] = "nosniff",
		["X-Frame-Options"] = "DENY",
		["X-XSS-Protection"] = "1; mode=block",
		["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains",
	},
}

-- Rate limiting state
local rate_limit_state = {
	requests = {},
	connections = {},
}

-- Input sanitization patterns
local SANITIZATION_PATTERNS = {
	-- HTML/XML injection
	html_tags = "[<>\"'&]",

	-- SQL injection patterns
	sql_injection = "([';]%s*DROP%s+TABLE|[';]%s*DELETE%s+FROM|[';]%s*INSERT%s+INTO|[';]%s*UPDATE%s+SET)",

	-- JavaScript injection
	javascript_injection = "(javascript:|data:text/html|vbscript:|onload=|onerror=|onclick=)",

	-- Command injection
	command_injection = "([;&|`$(){}]|%s+&&%s+|%s+||%s+)",
}

-- Validate URL security
function mcp_security.validate_url(url)
	if not url or type(url) ~= "string" then
		return false, "URL must be a non-empty string"
	end

	-- Check for dangerous protocols
	for _, protocol in ipairs(SECURITY_CONFIG.BLOCKED_PROTOCOLS) do
		if url:match("^" .. protocol .. "://") then
			return false, "Dangerous protocol not allowed: " .. protocol
		end
	end

	-- Check for allowed protocols
	local has_allowed_protocol = false
	for _, protocol in ipairs(SECURITY_CONFIG.ALLOWED_PROTOCOLS) do
		if url:match("^" .. protocol .. "://") then
			has_allowed_protocol = true
			break
		end
	end

	if not has_allowed_protocol then
		return false, "URL must start with http:// or https://"
	end

	-- Validate port if present
	local port_match = url:match(":(%d+)/?")
	if port_match then
		local port = tonumber(port_match)
		if port <= 0 or port > 65535 then
			return false, "Port must be between 1 and 65535"
		end
	end

	-- Check for negative ports (more specific pattern)
	-- This regex is too broad, removing for now
	-- if url:match("://[^/]*:-%d+") then
	--     return false, "Port must be between 1 and 65535"
	-- end

	-- Check for injection patterns
	for pattern_name, pattern in pairs(SANITIZATION_PATTERNS) do
		if url:match(pattern) then
			return false, "URL contains potentially dangerous content: " .. pattern_name
		end
	end

	return true
end

-- Validate protocol version
function mcp_security.validate_protocol_version(version)
	if not version or type(version) ~= "string" then
		return false, "Protocol version must be a string"
	end

	for _, allowed_version in ipairs(SECURITY_CONFIG.ALLOWED_PROTOCOL_VERSIONS) do
		if version == allowed_version then
			return true
		end
	end

	return false, "Unsupported protocol version: " .. version
end

-- Validate timeout values
function mcp_security.validate_timeout(timeout, timeout_name)
	if type(timeout) ~= "number" then
		return false, timeout_name .. " must be a number"
	end

	if timeout < SECURITY_CONFIG.MIN_TIMEOUT then
		return false, timeout_name .. " must be at least " .. SECURITY_CONFIG.MIN_TIMEOUT .. " seconds"
	end

	if timeout > SECURITY_CONFIG.MAX_TIMEOUT then
		return false, timeout_name .. " must be at most " .. SECURITY_CONFIG.MAX_TIMEOUT .. " seconds"
	end

	return true
end

-- Validate transport type
function mcp_security.validate_transport_type(transport_type)
	if not transport_type or type(transport_type) ~= "string" then
		return false, "Transport type must be a string"
	end

	for _, allowed_type in ipairs(SECURITY_CONFIG.ALLOWED_TRANSPORT_TYPES) do
		if transport_type == allowed_type then
			return true
		end
	end

	return false, "Invalid transport type: " .. transport_type
end

-- Validate client information
function mcp_security.validate_client_info(client_info)
	if not client_info or type(client_info) ~= "table" then
		return false, "Client info must be a table"
	end

	-- Validate name
	if not client_info.name or type(client_info.name) ~= "string" or #client_info.name == 0 then
		return false, "Client name must be a non-empty string"
	end

	if #client_info.name > SECURITY_CONFIG.MAX_CLIENT_NAME_LENGTH then
		return false, "Client name too long (max " .. SECURITY_CONFIG.MAX_CLIENT_NAME_LENGTH .. " characters)"
	end

	-- Check for injection patterns in name
	for pattern_name, pattern in pairs(SANITIZATION_PATTERNS) do
		if client_info.name:match(pattern) then
			return false, "Client name contains potentially dangerous content: " .. pattern_name
		end
	end

	-- Validate version if provided
	if client_info.version then
		if type(client_info.version) ~= "string" then
			return false, "Client version must be a string"
		end

		if #client_info.version > SECURITY_CONFIG.MAX_CLIENT_VERSION_LENGTH then
			return false, "Client version too long (max " .. SECURITY_CONFIG.MAX_CLIENT_VERSION_LENGTH .. " characters)"
		end
	end

	-- Validate capabilities if provided
	if client_info.capabilities and type(client_info.capabilities) ~= "table" then
		return false, "Client capabilities must be a table"
	end

	return true
end

-- Validate JSON-RPC message
function mcp_security.validate_jsonrpc_message(message, message_type)
	if not message or type(message) ~= "table" then
		return false, "Message must be a table"
	end

	-- Validate JSON-RPC version
	if not message.jsonrpc or message.jsonrpc ~= "2.0" then
		return false, "Invalid JSON-RPC version"
	end

	-- Validate method
	if not message.method or type(message.method) ~= "string" then
		return false, "Method must be a non-empty string"
	end

	if #message.method > SECURITY_CONFIG.MAX_METHOD_LENGTH then
		return false, "Method name too long (max " .. SECURITY_CONFIG.MAX_METHOD_LENGTH .. " characters)"
	end

	-- Check for injection patterns in method
	for pattern_name, pattern in pairs(SANITIZATION_PATTERNS) do
		if message.method:match(pattern) then
			return false, "Method name contains potentially dangerous content: " .. pattern_name
		end
	end

	-- Validate ID for requests
	if message_type == "request" then
		if message.id and type(message.id) ~= "string" and type(message.id) ~= "number" then
			return false, "Request ID must be a string or number"
		end
	end

	-- Validate that notifications don't have ID
	if message_type == "notification" and message.id then
		return false, "Notifications must not have an ID"
	end

	-- Validate payload size
	local payload_size = mcp_security.calculate_payload_size(message)
	if payload_size > SECURITY_CONFIG.MAX_PAYLOAD_SIZE then
		return false, "Payload too large (max " .. SECURITY_CONFIG.MAX_PAYLOAD_SIZE .. " bytes)"
	end

	return true
end

-- Calculate payload size
function mcp_security.calculate_payload_size(obj)
	local size = 0

	if type(obj) == "string" then
		size = size + #obj
	elseif type(obj) == "number" then
		size = size + 8 -- Approximate size for numbers
	elseif type(obj) == "boolean" then
		size = size + 1
	elseif type(obj) == "table" then
		for k, v in pairs(obj) do
			if type(k) == "string" then
				size = size + #k
			end
			size = size + mcp_security.calculate_payload_size(v)

			-- Check size limit during calculation
			if size > SECURITY_CONFIG.MAX_PAYLOAD_SIZE then
				return size
			end
		end
	end

	return size
end

-- Sanitize error messages
function mcp_security.sanitize_error_message(error_msg)
	if not error_msg or type(error_msg) ~= "string" then
		return "Unknown error"
	end

	-- Remove sensitive information
	local sanitized = error_msg
		:gsub("password[%s]*=.*", "password=***")
		:gsub("token[%s]*=.*", "token=***")
		:gsub("key[%s]*=.*", "key=***")
		:gsub("secret[%s]*=.*", "secret=***")
		:gsub("auth[%s]*=.*", "auth=***")

	-- Remove potential injection patterns
	for pattern_name, pattern in pairs(SANITIZATION_PATTERNS) do
		sanitized = sanitized:gsub(pattern, "[REMOVED]")
	end

	return sanitized
end

-- Rate limiting
function mcp_security.check_rate_limit(identifier, limit_type)
	local now = os.time()
	local key = identifier .. "_" .. limit_type

	if not rate_limit_state[limit_type] then
		rate_limit_state[limit_type] = {}
	end

	if not rate_limit_state[limit_type][key] then
		rate_limit_state[limit_type][key] = {}
	end

	local entries = rate_limit_state[limit_type][key]

	-- Remove old entries
	for i = #entries, 1, -1 do
		if now - entries[i] > 60 then -- 1 minute window
			table.remove(entries, i)
		end
	end

	-- Check limit
	local limit = limit_type == "requests" and SECURITY_CONFIG.MAX_REQUESTS_PER_MINUTE
		or SECURITY_CONFIG.MAX_CONNECTIONS_PER_IP
	if #entries >= limit then
		return false, "Rate limit exceeded for " .. limit_type
	end

	-- Add current request
	table.insert(entries, now)
	return true
end

-- Clean up rate limiting state
function mcp_security.cleanup_rate_limits()
	rate_limit_state = {
		requests = {},
		connections = {},
	}
end

-- Get security headers
function mcp_security.get_security_headers()
	return SECURITY_CONFIG.SECURITY_HEADERS
end

-- Validate configuration
function mcp_security.validate_config(config)
	local errors = {}

	-- Validate base URL
	if config.base_url then
		local valid, err = mcp_security.validate_url(config.base_url)
		if not valid then
			table.insert(errors, "base_url: " .. err)
		end
	end

	-- Validate protocol version
	if config.protocol_version then
		local valid, err = mcp_security.validate_protocol_version(config.protocol_version)
		if not valid then
			table.insert(errors, "protocol_version: " .. err)
		end
	end

	-- Validate timeouts
	if config.initialization_timeout then
		local valid, err = mcp_security.validate_timeout(config.initialization_timeout, "initialization_timeout")
		if not valid then
			table.insert(errors, "initialization_timeout: " .. err)
		end
	end

	if config.request_timeout then
		local valid, err = mcp_security.validate_timeout(config.request_timeout, "request_timeout")
		if not valid then
			table.insert(errors, "request_timeout: " .. err)
		end
	end

	-- Validate transport type
	if config.transport_type then
		local valid, err = mcp_security.validate_transport_type(config.transport_type)
		if not valid then
			table.insert(errors, "transport_type: " .. err)
		end
	end

	if #errors > 0 then
		return false, table.concat(errors, "; ")
	end

	return true
end

-- Export module
return mcp_security
