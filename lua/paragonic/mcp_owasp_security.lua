-- MCP OWASP Security Enhancement Module
-- 
-- This module implements OWASP Top 10 security measures and best practices
-- for the MCP HTTP transport implementation.

local mcp_owasp_security = {}

-- OWASP Security Configuration
local OWASP_CONFIG = {
    -- A01:2021 – Broken Access Control
    ACCESS_CONTROL = {
        MAX_SESSIONS_PER_CLIENT = 5,
        SESSION_TIMEOUT = 3600, -- 1 hour
        MAX_FAILED_ATTEMPTS = 5,
        LOCKOUT_DURATION = 900, -- 15 minutes
    },
    
    -- A02:2021 – Cryptographic Failures
    CRYPTO = {
        MIN_TLS_VERSION = "1.2",
        REQUIRED_CIPHERS = {"TLS_AES_256_GCM_SHA384", "TLS_CHACHA20_POLY1305_SHA256"},
        FORBIDDEN_CIPHERS = {"NULL", "EXPORT", "DES", "3DES", "RC4"},
        HASH_ALGORITHMS = {"SHA256", "SHA384", "SHA512"},
    },
    
    -- A03:2021 – Injection
    INJECTION_PREVENTION = {
        -- SQL Injection patterns
        SQL_PATTERNS = {
            "UNION.*SELECT",
            "INSERT.*INTO",
            "UPDATE.*SET",
            "DELETE.*FROM",
            "DROP.*TABLE",
            "CREATE.*TABLE",
            "ALTER.*TABLE",
            "EXEC.*%(",
            "EXECUTE.*%(",
            "xp_cmdshell",
            "sp_executesql",
        },
        
        -- NoSQL Injection patterns
        NOSQL_PATTERNS = {
            "%$where",
            "%$ne",
            "%$gt",
            "%$lt",
            "%$regex",
            "%$in",
            "%$nin",
            "%$exists",
        },
        
        -- Command Injection patterns
        COMMAND_PATTERNS = {
            "[;&|`$(){}]",
            "%s+&&%s+",
            "%s+||%s+",
            "\\|%s*[a-zA-Z]",
            "&%s*[a-zA-Z]",
            ";%s*[a-zA-Z]",
        },
        
        -- LDAP Injection patterns (more specific)
        LDAP_PATTERNS = {
            "%(%w*%=",
            "%)%s*%(",
            "%*%s*%)",
            "%|%s*%(",
            "&%s*%(",
            "!%s*%(",
            "%/%s*%(",
        },
    },
    
    -- A04:2021 – Insecure Design
    SECURE_DESIGN = {
        MAX_REQUEST_SIZE = 1048576, -- 1MB
        MAX_HEADER_SIZE = 8192, -- 8KB
        MAX_HEADERS_COUNT = 50,
        REQUEST_TIMEOUT = 30, -- seconds
        IDLE_TIMEOUT = 300, -- seconds
    },
    
    -- A05:2021 – Security Misconfiguration
    SECURITY_CONFIG = {
        -- Security headers
        SECURITY_HEADERS = {
            ["X-Content-Type-Options"] = "nosniff",
            ["X-Frame-Options"] = "DENY",
            ["X-XSS-Protection"] = "1; mode=block",
            ["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains; preload",
            ["Content-Security-Policy"] = "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';",
            ["Referrer-Policy"] = "strict-origin-when-cross-origin",
            ["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()",
            ["X-Permitted-Cross-Domain-Policies"] = "none",
            ["Cross-Origin-Embedder-Policy"] = "require-corp",
            ["Cross-Origin-Opener-Policy"] = "same-origin",
            ["Cross-Origin-Resource-Policy"] = "same-origin",
        },
        
        -- CORS configuration
        CORS_CONFIG = {
            ALLOWED_ORIGINS = {"https://localhost:3000", "https://127.0.0.1:3000"},
            ALLOWED_METHODS = {"GET", "POST", "DELETE"},
            ALLOWED_HEADERS = {"Content-Type", "Authorization", "X-Requested-With"},
            MAX_AGE = 86400, -- 24 hours
        },
    },
    
    -- A06:2021 – Vulnerable and Outdated Components
    COMPONENT_SECURITY = {
        MIN_PROTOCOL_VERSION = "2025-06-18",
        DEPRECATED_VERSIONS = {"2025-06-17", "2025-06-16"},
        REQUIRED_FEATURES = {"secure_transport", "input_validation", "rate_limiting"},
    },
    
    -- A07:2021 – Identification and Authentication Failures
    AUTH_SECURITY = {
        PASSWORD_POLICY = {
            MIN_LENGTH = 12,
            REQUIRE_UPPERCASE = true,
            REQUIRE_LOWERCASE = true,
            REQUIRE_NUMBERS = true,
            REQUIRE_SPECIAL = true,
            MAX_AGE = 90, -- days
            HISTORY_SIZE = 5,
        },
        
        SESSION_SECURITY = {
            SESSION_ID_LENGTH = 32,
            SESSION_ID_ENTROPY = 256,
            REGENERATE_ON_PRIVILEGE_CHANGE = true,
            INVALIDATE_ON_LOGOUT = true,
        },
    },
    
    -- A08:2021 – Software and Data Integrity Failures
    INTEGRITY = {
        SIGNATURE_VERIFICATION = true,
        CHECKSUM_VALIDATION = true,
        ALLOWED_SIGNERS = {"paragonic", "mcp-org"},
        SIGNATURE_ALGORITHMS = {"RS256", "ES256", "PS256"},
    },
    
    -- A09:2021 – Security Logging and Monitoring Failures
    LOGGING = {
        LOG_LEVELS = {"ERROR", "WARN", "INFO", "DEBUG"},
        SENSITIVE_FIELDS = {"password", "token", "key", "secret", "auth"},
        AUDIT_EVENTS = {
            "authentication",
            "authorization",
            "data_access",
            "configuration_change",
            "security_event",
        },
        RETENTION_PERIOD = 90, -- days
    },
    
    -- A10:2021 – Server-Side Request Forgery (SSRF)
    SSRF_PROTECTION = {
        BLOCKED_HOSTS = {
            "127.0.0.1",
            "localhost",
            "0.0.0.0",
            "::1",
            "169.254.169.254", -- AWS metadata
            "169.254.170.2",   -- AWS metadata
        },
        
        BLOCKED_PORTS = {
            22,   -- SSH
            23,   -- Telnet
            25,   -- SMTP
            53,   -- DNS
            80,   -- HTTP (if not intended)
            143,  -- IMAP
            993,  -- IMAPS
            995,  -- POP3S
        },
        
        ALLOWED_PROTOCOLS = {"http", "https"},
    },
}

-- Security state tracking
local security_state = {
    failed_attempts = {},
    locked_ips = {},
    session_tokens = {},
    audit_log = {},
}

-- OWASP A01:2021 – Broken Access Control
function mcp_owasp_security.check_access_control(client_ip, session_id)
    -- Check if IP is locked out
    if security_state.locked_ips[client_ip] then
        local lockout_time = security_state.locked_ips[client_ip]
        if os.time() - lockout_time < OWASP_CONFIG.ACCESS_CONTROL.LOCKOUT_DURATION then
            return false, "IP address is temporarily locked due to multiple failed attempts"
        else
            -- Remove lockout after duration expires
            security_state.locked_ips[client_ip] = nil
            security_state.failed_attempts[client_ip] = 0
        end
    end
    
    -- Check session limits
    local session_count = 0
    for _, session in pairs(security_state.session_tokens) do
        if session.client_ip == client_ip then
            session_count = session_count + 1
        end
    end
    
    if session_count >= OWASP_CONFIG.ACCESS_CONTROL.MAX_SESSIONS_PER_CLIENT then
        return false, "Maximum sessions per client exceeded"
    end
    
    return true
end

function mcp_owasp_security.record_failed_attempt(client_ip)
    security_state.failed_attempts[client_ip] = (security_state.failed_attempts[client_ip] or 0) + 1
    
    if security_state.failed_attempts[client_ip] >= OWASP_CONFIG.ACCESS_CONTROL.MAX_FAILED_ATTEMPTS then
        security_state.locked_ips[client_ip] = os.time()
        mcp_owasp_security.log_security_event("IP_LOCKOUT", {
            client_ip = client_ip,
            reason = "Multiple failed attempts",
            attempts = security_state.failed_attempts[client_ip]
        })
    end
end

-- OWASP A03:2021 – Injection Prevention
function mcp_owasp_security.detect_injection(input, input_type)
    if not input or type(input) ~= "string" then
        return false, nil
    end
    
    local input_lower = input:lower()
    
    -- Check LDAP injection patterns first (more specific)
    for _, pattern in ipairs(OWASP_CONFIG.INJECTION_PREVENTION.LDAP_PATTERNS) do
        if input_lower:match(pattern:lower()) then
            mcp_owasp_security.log_security_event("LDAP_INJECTION_ATTEMPT", {
                input_type = input_type,
                pattern = pattern,
                input_preview = input:sub(1, 100)
            })
            return true, "LDAP injection pattern detected"
        end
    end
    
    -- Check SQL injection patterns
    for _, pattern in ipairs(OWASP_CONFIG.INJECTION_PREVENTION.SQL_PATTERNS) do
        if input_lower:match(pattern:lower()) then
            mcp_owasp_security.log_security_event("SQL_INJECTION_ATTEMPT", {
                input_type = input_type,
                pattern = pattern,
                input_preview = input:sub(1, 100)
            })
            return true, "SQL injection pattern detected"
        end
    end
    
    -- Check NoSQL injection patterns
    for _, pattern in ipairs(OWASP_CONFIG.INJECTION_PREVENTION.NOSQL_PATTERNS) do
        if input_lower:match(pattern:lower()) then
            mcp_owasp_security.log_security_event("NOSQL_INJECTION_ATTEMPT", {
                input_type = input_type,
                pattern = pattern,
                input_preview = input:sub(1, 100)
            })
            return true, "NoSQL injection pattern detected"
        end
    end
    
    -- Check command injection patterns last (most general)
    for _, pattern in ipairs(OWASP_CONFIG.INJECTION_PREVENTION.COMMAND_PATTERNS) do
        if input_lower:match(pattern:lower()) then
            mcp_owasp_security.log_security_event("COMMAND_INJECTION_ATTEMPT", {
                input_type = input_type,
                pattern = pattern,
                input_preview = input:sub(1, 100)
            })
            return true, "Command injection pattern detected"
        end
    end
    
    return false, nil
end

-- OWASP A05:2021 – Security Misconfiguration
function mcp_owasp_security.get_enhanced_security_headers()
    local headers = {}
    
    -- Copy base security headers
    for header, value in pairs(OWASP_CONFIG.SECURITY_CONFIG.SECURITY_HEADERS) do
        headers[header] = value
    end
    
    -- Add dynamic headers
    headers["X-Request-ID"] = mcp_owasp_security.generate_request_id()
    headers["X-Runtime"] = tostring(os.time())
    
    return headers
end

function mcp_owasp_security.validate_cors_origin(origin)
    if not origin then
        return false
    end
    
    for _, allowed_origin in ipairs(OWASP_CONFIG.SECURITY_CONFIG.CORS_CONFIG.ALLOWED_ORIGINS) do
        if origin == allowed_origin then
            return true
        end
    end
    
    return false
end

-- OWASP A07:2021 – Identification and Authentication Failures
function mcp_owasp_security.validate_password_strength(password)
    if not password or type(password) ~= "string" then
        return false, "Password must be a string"
    end
    
    local policy = OWASP_CONFIG.AUTH_SECURITY.PASSWORD_POLICY
    
    if #password < policy.MIN_LENGTH then
        return false, "Password too short (minimum " .. policy.MIN_LENGTH .. " characters)"
    end
    
    if policy.REQUIRE_UPPERCASE and not password:match("%u") then
        return false, "Password must contain uppercase letter"
    end
    
    if policy.REQUIRE_LOWERCASE and not password:match("%l") then
        return false, "Password must contain lowercase letter"
    end
    
    if policy.REQUIRE_NUMBERS and not password:match("%d") then
        return false, "Password must contain number"
    end
    
    if policy.REQUIRE_SPECIAL and not password:match("[%p%c]") then
        return false, "Password must contain special character"
    end
    
    return true
end

function mcp_owasp_security.generate_secure_session_id()
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local session_id = ""
    
    for i = 1, OWASP_CONFIG.AUTH_SECURITY.SESSION_SECURITY.SESSION_ID_LENGTH do
        local random_index = math.random(1, #charset)
        session_id = session_id .. charset:sub(random_index, random_index)
    end
    
    return session_id
end

-- OWASP A09:2021 – Security Logging and Monitoring Failures
function mcp_owasp_security.log_security_event(event_type, event_data)
    local log_entry = {
        timestamp = os.time(),
        event_type = event_type,
        event_data = event_data,
        severity = mcp_owasp_security.get_event_severity(event_type)
    }
    
    table.insert(security_state.audit_log, log_entry)
    
    -- Keep only recent logs
    if #security_state.audit_log > 1000 then
        table.remove(security_state.audit_log, 1)
    end
    
    -- Log to console for now (in production, use proper logging)
    local json_string = "{}"
    if vim and vim.json then
        json_string = vim.json.encode(event_data)
    else
        -- Fallback JSON encoding for non-Neovim environments
        json_string = string.format("{event_type='%s', timestamp=%d}", event_type, log_entry.timestamp)
    end
    print(string.format("[SECURITY] %s: %s", event_type, json_string))
end

function mcp_owasp_security.get_event_severity(event_type)
    local severity_map = {
        -- High severity
        ["SQL_INJECTION_ATTEMPT"] = "HIGH",
        ["NOSQL_INJECTION_ATTEMPT"] = "HIGH",
        ["COMMAND_INJECTION_ATTEMPT"] = "HIGH",
        ["LDAP_INJECTION_ATTEMPT"] = "HIGH",
        ["IP_LOCKOUT"] = "HIGH",
        
        -- Medium severity
        ["AUTHENTICATION_FAILURE"] = "MEDIUM",
        ["AUTHORIZATION_FAILURE"] = "MEDIUM",
        ["RATE_LIMIT_EXCEEDED"] = "MEDIUM",
        
        -- Low severity
        ["CONFIGURATION_CHANGE"] = "LOW",
        ["DATA_ACCESS"] = "LOW",
    }
    
    return severity_map[event_type] or "INFO"
end

-- OWASP A10:2021 – Server-Side Request Forgery (SSRF) Protection
function mcp_owasp_security.validate_url_for_ssrf(url)
    if not url or type(url) ~= "string" then
        return false, "Invalid URL"
    end
    
    -- Extract host and port (handle IPv6 addresses)
    local host_match = url:match("://([^:/%[%]]+)")
    local port_match = url:match(":(%d+)/?")
    
    -- Handle IPv6 addresses in brackets
    if not host_match then
        host_match = url:match("://%[([^%]]+)%]")
    end
    
    -- Handle IPv6 addresses without brackets
    if not host_match then
        host_match = url:match("://([%x:]+)")
    end
    
    if not host_match then
        return false, "Invalid URL format"
    end
    
    -- Check blocked hosts
    for _, blocked_host in ipairs(OWASP_CONFIG.SSRF_PROTECTION.BLOCKED_HOSTS) do
        if host_match == blocked_host then
            mcp_owasp_security.log_security_event("SSRF_ATTEMPT", {
                host = host_match,
                reason = "Blocked host",
                url_preview = url:sub(1, 100)
            })
            return false, "Access to blocked host attempted"
        end
    end
    
    -- Check blocked ports
    if port_match then
        local port = tonumber(port_match)
        for _, blocked_port in ipairs(OWASP_CONFIG.SSRF_PROTECTION.BLOCKED_PORTS) do
            if port == blocked_port then
                mcp_owasp_security.log_security_event("SSRF_ATTEMPT", {
                    host = host_match,
                    port = port,
                    reason = "Blocked port",
                    url_preview = url:sub(1, 100)
                })
                return false, "Access to blocked port attempted"
            end
        end
    end
    
    return true
end

-- Utility functions
function mcp_owasp_security.generate_request_id()
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local request_id = ""
    
    for i = 1, 16 do
        local random_index = math.random(1, #charset)
        request_id = request_id .. charset:sub(random_index, random_index)
    end
    
    return request_id
end

function mcp_owasp_security.sanitize_log_data(data)
    if type(data) ~= "table" then
        return data
    end
    
    local sanitized = {}
    for key, value in pairs(data) do
        local should_sanitize = false
        for _, sensitive_field in ipairs(OWASP_CONFIG.LOGGING.SENSITIVE_FIELDS) do
            if key:lower():find(sensitive_field:lower()) then
                should_sanitize = true
                break
            end
        end
        
        if should_sanitize then
            sanitized[key] = "***REDACTED***"
        else
            sanitized[key] = value
        end
    end
    
    return sanitized
end

function mcp_owasp_security.get_security_metrics()
    local metrics = {
        total_events = #security_state.audit_log,
        locked_ips = 0,
        failed_attempts = 0,
        active_sessions = 0,
    }
    
    -- Count locked IPs
    for _ in pairs(security_state.locked_ips) do
        metrics.locked_ips = metrics.locked_ips + 1
    end
    
    -- Count total failed attempts
    for _, count in pairs(security_state.failed_attempts) do
        metrics.failed_attempts = metrics.failed_attempts + count
    end
    
    -- Count active sessions
    for _ in pairs(security_state.session_tokens) do
        metrics.active_sessions = metrics.active_sessions + 1
    end
    
    return metrics
end

function mcp_owasp_security.cleanup_expired_data()
    local current_time = os.time()
    
    -- Clean up expired sessions
    for session_id, session in pairs(security_state.session_tokens) do
        if current_time - session.created_at > OWASP_CONFIG.ACCESS_CONTROL.SESSION_TIMEOUT then
            security_state.session_tokens[session_id] = nil
        end
    end
    
    -- Clean up old audit logs
    local cutoff_time = current_time - (OWASP_CONFIG.LOGGING.RETENTION_PERIOD * 24 * 3600)
    for i = #security_state.audit_log, 1, -1 do
        if security_state.audit_log[i].timestamp < cutoff_time then
            table.remove(security_state.audit_log, i)
        end
    end
end

-- Export module
return mcp_owasp_security
