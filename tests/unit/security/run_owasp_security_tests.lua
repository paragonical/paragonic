-- OWASP Security Module Tests
--
-- Tests for the OWASP-compliant security enhancement module

-- Simple test runner
local function run_tests()
	local tests = {}
	local passed = 0
	local failed = 0

	-- Custom assertion functions
	local function assert_true(condition, message)
		if not condition then
			error("ASSERTION FAILED: " .. (message or "expected true"))
		end
	end

	local function assert_false(condition, message)
		if condition then
			error("ASSERTION FAILED: " .. (message or "expected false"))
		end
	end

	local function assert_equal(expected, actual, message)
		if expected ~= actual then
			error(
				"ASSERTION FAILED: "
					.. (message or string.format("expected %s, got %s", tostring(expected), tostring(actual)))
			)
		end
	end

	local function assert_not_nil(value, message)
		if value == nil then
			error("ASSERTION FAILED: " .. (message or "expected non-nil value"))
		end
	end

	local function assert_nil(value, message)
		if value ~= nil then
			error("ASSERTION FAILED: " .. (message or "expected nil value"))
		end
	end

	local function assert_table(value, message)
		if type(value) ~= "table" then
			error("ASSERTION FAILED: " .. (message or "expected table"))
		end
	end

	local function assert_string(value, message)
		if type(value) ~= "string" then
			error("ASSERTION FAILED: " .. (message or "expected string"))
		end
	end

	-- Test function wrapper
	local function test(name, test_func)
		table.insert(tests, { name = name, func = test_func })
	end

	-- Load the OWASP security module
	local mcp_owasp_security
	local success, err = pcall(function()
		mcp_owasp_security = require("../../lua/paragonic/mcp_owasp_security")
	end)

	if not success then
		-- Fallback for different require paths
		success, err = pcall(function()
			mcp_owasp_security = require("lua.paragonic.mcp_owasp_security")
		end)
	end

	if not success then
		print("ERROR: Could not load mcp_owasp_security module: " .. tostring(err))
		return
	end

	print("Running OWASP Security Module Tests...")
	print("=====================================")

	-- A01:2021 – Broken Access Control Tests
	test("A01: Check access control with valid client", function()
		local success, err = mcp_owasp_security.check_access_control("192.168.1.100", "session123")
		assert_true(success, "Access control should allow valid client")
		assert_nil(err, "No error should be returned for valid client")
	end)

	test("A01: Check access control with locked IP", function()
		-- First, record failed attempts to lock the IP
		for i = 1, 5 do
			mcp_owasp_security.record_failed_attempt("192.168.1.200")
		end

		local success, err = mcp_owasp_security.check_access_control("192.168.1.200", "session123")
		assert_false(success, "Access control should deny locked IP")
		assert_not_nil(err, "Error should be returned for locked IP")
		assert_true(err:find("locked"), "Error should mention lockout")
	end)

	test("A01: Record failed attempt", function()
		local client_ip = "192.168.1.300"
		mcp_owasp_security.record_failed_attempt(client_ip)

		-- Check that failed attempt was recorded
		local success, err = mcp_owasp_security.check_access_control(client_ip, "session123")
		assert_true(success, "Single failed attempt should not lock IP")
	end)

	-- A03:2021 – Injection Prevention Tests
	test("A03: Detect SQL injection patterns", function()
		local sql_injections = {
			"UNION SELECT * FROM users",
			"INSERT INTO users VALUES",
			"UPDATE users SET password",
			"DELETE FROM users WHERE",
			"DROP TABLE users",
			"CREATE TABLE malicious",
			"ALTER TABLE users ADD",
			"EXEC xp_cmdshell",
			"EXECUTE sp_executesql",
		}

		for _, injection in ipairs(sql_injections) do
			local detected, err = mcp_owasp_security.detect_injection(injection, "method")
			assert_true(detected, "Should detect SQL injection: " .. injection)
			assert_true(err:find("SQL injection"), "Should return SQL injection error")
		end
	end)

	test("A03: Detect NoSQL injection patterns", function()
		local nosql_injections = {
			"$where: { $ne: null }",
			"$ne: 0",
			"$gt: 100",
			"$lt: 50",
			"$regex: /.*/",
			"$in: [1,2,3]",
			"$nin: [4,5,6]",
			"$exists: true",
		}

		for _, injection in ipairs(nosql_injections) do
			local detected, err = mcp_owasp_security.detect_injection(injection, "params")
			assert_true(detected, "Should detect NoSQL injection: " .. injection)
			assert_true(err:find("NoSQL injection"), "Should return NoSQL injection error")
		end
	end)

	test("A03: Detect command injection patterns", function()
		local command_injections = {
			"ls; cat /etc/passwd",
			"echo hello && rm -rf /",
			"ping 127.0.0.1 || exit",
			"| wc -l",
			"& dir",
			"; whoami",
		}

		for _, injection in ipairs(command_injections) do
			local detected, err = mcp_owasp_security.detect_injection(injection, "command")
			assert_true(detected, "Should detect command injection: " .. injection)
			assert_true(err:find("Command injection"), "Should return command injection error")
		end
	end)

	test("A03: Detect LDAP injection patterns", function()
		local ldap_injections = {
			"(uid=*)",
			"(cn=*)",
			"*)(uid=*))(|(uid=*",
			"|(uid=*)",
			"&(uid=*)",
			"!(uid=*)",
			"/(uid=*)",
		}

		for _, injection in ipairs(ldap_injections) do
			local detected, err = mcp_owasp_security.detect_injection(injection, "filter")
			assert_true(detected, "Should detect LDAP injection: " .. injection)
			assert_true(err:find("LDAP injection"), "Should return LDAP injection error")
		end
	end)

	test("A03: Allow safe input", function()
		local safe_inputs = {
			"hello world",
			"user123",
			"normal_method_name",
			"valid_parameter_value",
			"safe_command",
		}

		for _, input in ipairs(safe_inputs) do
			local detected = mcp_owasp_security.detect_injection(input, "safe")
			assert_false(detected, "Should not detect injection in safe input: " .. input)
		end
	end)

	-- A05:2021 – Security Misconfiguration Tests
	test("A05: Get enhanced security headers", function()
		local headers = mcp_owasp_security.get_enhanced_security_headers()
		assert_table(headers, "Should return table of headers")

		-- Check for required security headers
		local required_headers = {
			"X-Content-Type-Options",
			"X-Frame-Options",
			"X-XSS-Protection",
			"Strict-Transport-Security",
			"Content-Security-Policy",
			"Referrer-Policy",
			"Permissions-Policy",
			"X-Permitted-Cross-Domain-Policies",
			"Cross-Origin-Embedder-Policy",
			"Cross-Origin-Opener-Policy",
			"Cross-Origin-Resource-Policy",
			"X-Request-ID",
			"X-Runtime",
		}

		for _, header in ipairs(required_headers) do
			assert_not_nil(headers[header], "Should include header: " .. header)
		end
	end)

	test("A05: Validate CORS origin", function()
		local valid_origins = {
			"https://localhost:3000",
			"https://127.0.0.1:3000",
		}

		for _, origin in ipairs(valid_origins) do
			local valid = mcp_owasp_security.validate_cors_origin(origin)
			assert_true(valid, "Should allow valid origin: " .. origin)
		end

		local invalid_origins = {
			"http://localhost:3000", -- HTTP not HTTPS
			"https://malicious.com",
			"https://localhost:8080", -- Different port
			nil,
		}

		for _, origin in ipairs(invalid_origins) do
			local valid = mcp_owasp_security.validate_cors_origin(origin)
			assert_false(valid, "Should reject invalid origin: " .. tostring(origin))
		end
	end)

	-- A07:2021 – Identification and Authentication Failures Tests
	test("A07: Validate password strength", function()
		local valid_passwords = {
			"StrongPass123!",
			"ComplexP@ssw0rd",
			"Secure#Pass1",
		}

		for _, password in ipairs(valid_passwords) do
			local valid, err = mcp_owasp_security.validate_password_strength(password)
			assert_true(valid, "Should accept strong password: " .. password)
			assert_nil(err, "No error for strong password")
		end

		local invalid_passwords = {
			{ password = "weak", reason = "too short" },
			{ password = "nouppercase123!", reason = "no uppercase" },
			{ password = "NOLOWERCASE123!", reason = "no lowercase" },
			{ password = "NoNumbers!", reason = "no numbers" },
			{ password = "NoSpecial123", reason = "no special chars" },
		}

		for _, test_case in ipairs(invalid_passwords) do
			local valid, err = mcp_owasp_security.validate_password_strength(test_case.password)
			assert_false(valid, "Should reject weak password: " .. test_case.password)
			assert_not_nil(err, "Should return error for weak password")
		end
	end)

	test("A07: Generate secure session ID", function()
		local session_id = mcp_owasp_security.generate_secure_session_id()
		assert_string(session_id, "Should return string session ID")
		assert_equal(32, #session_id, "Session ID should be 32 characters")

		-- Check it contains only alphanumeric characters
		assert_true(session_id:match("^[A-Za-z0-9]+$"), "Session ID should be alphanumeric")
	end)

	-- A09:2021 – Security Logging and Monitoring Failures Tests
	test("A09: Log security event", function()
		local event_data = {
			client_ip = "192.168.1.100",
			user_id = "user123",
			action = "login_attempt",
		}

		mcp_owasp_security.log_security_event("AUTHENTICATION_FAILURE", event_data)

		-- Check that event was logged (we can't easily test the internal state,
		-- but we can verify the function doesn't error)
		local metrics = mcp_owasp_security.get_security_metrics()
		assert_table(metrics, "Should return metrics table")
		assert_true(metrics.total_events > 0, "Should have logged events")
	end)

	test("A09: Get event severity", function()
		local high_severity = {
			"SQL_INJECTION_ATTEMPT",
			"NOSQL_INJECTION_ATTEMPT",
			"COMMAND_INJECTION_ATTEMPT",
			"LDAP_INJECTION_ATTEMPT",
			"IP_LOCKOUT",
		}

		for _, event_type in ipairs(high_severity) do
			local severity = mcp_owasp_security.get_event_severity(event_type)
			assert_equal("HIGH", severity, "Should be high severity: " .. event_type)
		end

		local medium_severity = {
			"AUTHENTICATION_FAILURE",
			"AUTHORIZATION_FAILURE",
			"RATE_LIMIT_EXCEEDED",
		}

		for _, event_type in ipairs(medium_severity) do
			local severity = mcp_owasp_security.get_event_severity(event_type)
			assert_equal("MEDIUM", severity, "Should be medium severity: " .. event_type)
		end
	end)

	-- A10:2021 – Server-Side Request Forgery (SSRF) Protection Tests
	test("A10: Validate URL for SSRF - blocked hosts", function()
		local blocked_hosts = {
			"http://0.0.0.0:8080",
			"http://169.254.169.254/latest/meta-data",
			"https://169.254.170.2/api",
		}

		for _, url in ipairs(blocked_hosts) do
			local valid, err = mcp_owasp_security.validate_url_for_ssrf(url)
			assert_false(valid, "Should block SSRF attempt: " .. url)
			assert_true(err:find("blocked host") or err:find("Access to blocked host"), "Should mention blocked host")
		end
	end)

	test("A10: Validate URL for SSRF - blocked ports", function()
		local blocked_ports = {
			"http://example.com:22/api",
			"https://api.example.com:23/data",
			"http://service.com:25/email",
			"https://dns.com:53/query",
			"http://web.com:80/page",
			"https://mail.com:143/inbox",
			"https://secure.com:993/mail",
			"https://pop.com:995/messages",
		}

		for _, url in ipairs(blocked_ports) do
			local valid, err = mcp_owasp_security.validate_url_for_ssrf(url)
			assert_false(valid, "Should block SSRF attempt: " .. url)
			assert_true(err:find("blocked port") or err:find("Access to blocked port"), "Should mention blocked port")
		end
	end)

	test("A10: Validate URL for SSRF - allowed URLs", function()
		local allowed_urls = {
			"https://api.example.com:443/data",
			"http://service.com:8080/api",
			"https://web.com:8443/page",
			"https://api.github.com/v3/users",
			"http://127.0.0.1:3000/mcp",
			"https://localhost:3000/api",
			"http://::1:8080/test",
		}

		for _, url in ipairs(allowed_urls) do
			local valid, err = mcp_owasp_security.validate_url_for_ssrf(url)
			assert_true(valid, "Should allow valid URL: " .. url)
			assert_nil(err, "No error for valid URL")
		end
	end)

	-- Utility function tests
	test("Utility: Generate request ID", function()
		local request_id = mcp_owasp_security.generate_request_id()
		assert_string(request_id, "Should return string request ID")
		assert_equal(16, #request_id, "Request ID should be 16 characters")
		assert_true(request_id:match("^[A-Za-z0-9]+$"), "Request ID should be alphanumeric")
	end)

	test("Utility: Sanitize log data", function()
		local test_data = {
			username = "john_doe",
			password = "secret123",
			token = "abc123",
			email = "john@example.com",
			api_key = "xyz789",
			normal_field = "safe_value",
		}

		local sanitized = mcp_owasp_security.sanitize_log_data(test_data)
		assert_table(sanitized, "Should return table")
		assert_equal("***REDACTED***", sanitized.password, "Should redact password")
		assert_equal("***REDACTED***", sanitized.token, "Should redact token")
		assert_equal("***REDACTED***", sanitized.api_key, "Should redact api_key")
		assert_equal("john_doe", sanitized.username, "Should not redact username")
		assert_equal("safe_value", sanitized.normal_field, "Should not redact normal field")
	end)

	test("Utility: Get security metrics", function()
		local metrics = mcp_owasp_security.get_security_metrics()
		assert_table(metrics, "Should return metrics table")
		assert_not_nil(metrics.total_events, "Should have total_events")
		assert_not_nil(metrics.locked_ips, "Should have locked_ips")
		assert_not_nil(metrics.failed_attempts, "Should have failed_attempts")
		assert_not_nil(metrics.active_sessions, "Should have active_sessions")
	end)

	test("Utility: Cleanup expired data", function()
		-- This test verifies the function doesn't error
		mcp_owasp_security.cleanup_expired_data()
		-- No assertions needed as we're just testing it doesn't crash
	end)

	-- Run all tests
	for i, test_case in ipairs(tests) do
		local success, err = pcall(test_case.func)
		if success then
			print("✓ " .. test_case.name)
			passed = passed + 1
		else
			print("✗ " .. test_case.name .. " - " .. tostring(err))
			failed = failed + 1
		end
	end

	print("=====================================")
	print(string.format("Tests completed: %d passed, %d failed", passed, failed))

	if failed > 0 then
		os.exit(1)
	end
end

-- Run the tests
run_tests()
