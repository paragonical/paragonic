-- Tests for HTTP client module
local http_client = require("paragonic.http_client")

-- Test utilities
local function create_test_server()
    -- Mock server for testing
    return {
        base_url = "http://localhost:3000",
        responses = {},
        requests = {},
    }
end

local function mock_curl_response(status_code, body)
    -- Mock curl response for testing
    local temp_file = "/tmp/paragonic_response"
    vim.fn.writefile({body or ""}, temp_file)
    return status_code
end

-- Test suite
describe("HTTP Client", function()
    before_each(function()
        -- Clean up before each test
        http_client.cleanup()
        vim.fn.delete("/tmp/paragonic_response")
    end)
    
    after_each(function()
        -- Clean up after each test
        http_client.cleanup()
        vim.fn.delete("/tmp/paragonic_response")
    end)
    
    describe("Initialization", function()
        it("should initialize with default config", function()
            local success = http_client.init()
            assert.is_true(success)
            
            -- Check default values
            assert.is_equal("http://localhost:3000", http_client.build_request("GET", "/test").url)
        end)
        
        it("should initialize with custom config", function()
            local config = {
                base_url = "http://test-server:8080",
                timeout = 60,
                retry_attempts = 5,
                retry_delay = 2,
                headers = {
                    ["X-Custom-Header"] = "test-value"
                }
            }
            
            local success = http_client.init(config)
            assert.is_true(success)
            
            local request = http_client.build_request("GET", "/test")
            assert.is_equal("http://test-server:8080/test", request.url)
            assert.is_equal("test-value", request.headers["X-Custom-Header"])
        end)
        
        it("should handle invalid config gracefully", function()
            local success = http_client.init("invalid")
            assert.is_true(success) -- Should use defaults
        end)
    end)
    
    describe("Session Management", function()
        it("should set and get session ID", function()
            http_client.init()
            
            local session_id = "test-session-123"
            local success, err = http_client.set_session_id(session_id)
            assert.is_true(success)
            assert.is_nil(err)
            
            assert.is_equal(session_id, http_client.get_session_id())
        end)
        
        it("should reject invalid session ID", function()
            http_client.init()
            
            local success, err = http_client.set_session_id(nil)
            assert.is_false(success)
            assert.is_equal("Invalid session ID", err)
            
            local success2, err2 = http_client.set_session_id(123)
            assert.is_false(success2)
            assert.is_equal("Invalid session ID", err2)
        end)
        
        it("should include session ID in requests", function()
            http_client.init()
            http_client.set_session_id("test-session")
            
            local request = http_client.build_request("GET", "/test")
            assert.is_equal("test-session", request.headers["Mcp-Session-Id"])
        end)
    end)
    
    describe("Request Building", function()
        before_each(function()
            http_client.init()
        end)
        
        it("should build GET request correctly", function()
            local request, err = http_client.build_request("GET", "/test")
            assert.is_nil(err)
            assert.is_equal("GET", request.method)
            assert.is_equal("http://localhost:3000/test", request.url)
            assert.is_nil(request.data)
        end)
        
        it("should build POST request with data", function()
            local data = {key = "value", number = 123}
            local request, err = http_client.build_request("POST", "/test", data)
            assert.is_nil(err)
            assert.is_equal("POST", request.method)
            assert.is_equal("http://localhost:3000/test", request.url)
            assert.is_not_nil(request.data)
            assert.is_string(request.data)
        end)
        
        it("should handle URL construction correctly", function()
            -- Test with trailing slash in base URL
            http_client.init({base_url = "http://localhost:3000/"})
            local request = http_client.build_request("GET", "test")
            assert.is_equal("http://localhost:3000/test", request.url)
            
            -- Test with leading slash in endpoint
            local request2 = http_client.build_request("GET", "/test")
            assert.is_equal("http://localhost:3000/test", request2.url)
        end)
        
        it("should include custom headers", function()
            local custom_headers = {
                ["X-Test-Header"] = "test-value",
                ["Authorization"] = "Bearer token123"
            }
            
            local request = http_client.build_request("GET", "/test", nil, custom_headers)
            assert.is_equal("test-value", request.headers["X-Test-Header"])
            assert.is_equal("Bearer token123", request.headers["Authorization"])
        end)
        
        it("should reject invalid HTTP method", function()
            local request, err = http_client.build_request(nil, "/test")
            assert.is_nil(request)
            assert.is_equal("Invalid HTTP method", err)
        end)
        
        it("should reject invalid endpoint", function()
            local request, err = http_client.build_request("GET", nil)
            assert.is_nil(request)
            assert.is_equal("Invalid endpoint", err)
        end)
    end)
    
    describe("Response Handling", function()
        it("should identify successful responses", function()
            local success_response = {status_code = 200}
            local created_response = {status_code = 201}
            local no_content_response = {status_code = 204}
            
            assert.is_true(http_client.is_success(success_response))
            assert.is_true(http_client.is_success(created_response))
            assert.is_true(http_client.is_success(no_content_response))
        end)
        
        it("should identify client errors", function()
            local bad_request = {status_code = 400}
            local unauthorized = {status_code = 401}
            local not_found = {status_code = 404}
            
            assert.is_true(http_client.is_client_error(bad_request))
            assert.is_true(http_client.is_client_error(unauthorized))
            assert.is_true(http_client.is_client_error(not_found))
        end)
        
        it("should identify server errors", function()
            local internal_error = {status_code = 500}
            local bad_gateway = {status_code = 502}
            local service_unavailable = {status_code = 503}
            
            assert.is_true(http_client.is_server_error(internal_error))
            assert.is_true(http_client.is_server_error(bad_gateway))
            assert.is_true(http_client.is_server_error(service_unavailable))
        end)
        
        it("should extract error messages", function()
            local response_with_error = {
                status_code = 400,
                body = {error = "Bad request"}
            }
            
            local response_without_error = {
                status_code = 500
            }
            
            local no_response = nil
            
            assert.is_equal("Bad request", http_client.get_error_message(response_with_error))
            assert.is_equal("HTTP 500", http_client.get_error_message(response_without_error))
            assert.is_equal("No response received", http_client.get_error_message(no_response))
        end)
    end)
    
    describe("HTTP Methods", function()
        before_each(function()
            http_client.init()
        end)
        
        it("should provide POST method", function()
            local data = {test = "data"}
            local response, err = http_client.post("/test", data)
            
            -- Should fail in test environment (no server)
            assert.is_nil(response)
            assert.is_not_nil(err)
        end)
        
        it("should provide GET method", function()
            local response, err = http_client.get("/test")
            
            -- Should fail in test environment (no server)
            assert.is_nil(response)
            assert.is_not_nil(err)
        end)
        
        it("should provide DELETE method", function()
            local response, err = http_client.delete("/test")
            
            -- Should fail in test environment (no server)
            assert.is_nil(response)
            assert.is_not_nil(err)
        end)
    end)
    
    describe("Error Handling", function()
        before_each(function()
            http_client.init()
        end)
        
        it("should handle connection failures", function()
            -- Test with invalid URL
            http_client.init({base_url = "http://invalid-server:9999"})
            local response, err = http_client.get("/test")
            
            assert.is_nil(response)
            assert.is_not_nil(err)
        end)
        
        it("should handle timeouts", function()
            -- Test with very short timeout
            http_client.init({timeout = 1})
            local response, err = http_client.get("/test")
            
            assert.is_nil(response)
            assert.is_not_nil(err)
        end)
    end)
    
    describe("Cleanup", function()
        it("should clean up resources", function()
            http_client.init()
            http_client.set_session_id("test-session")
            
            -- Verify state is set
            assert.is_not_nil(http_client.get_session_id())
            
            -- Clean up
            http_client.cleanup()
            
            -- Verify state is reset
            assert.is_nil(http_client.get_session_id())
        end)
    end)
end)
