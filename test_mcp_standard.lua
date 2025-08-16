-- Test script for MCP standard-compliant HTTP transport
-- This script tests the new implementation that follows the MCP standard

local mcp = require("lua.paragonic.mcp_http_transport")

print("🧪 Testing MCP Standard-Compliant HTTP Transport")
print("=" .. string.rep("=", 50))

-- Test 1: Initialize transport
print("\n📋 Test 1: Initialize transport")
local success, err = mcp.init({
	base_url = "http://localhost:3000",
	protocol_version = "2025-06-18",
	initialization_timeout = 30,
	request_timeout = 60,
})

if success then
	print("✅ Transport initialization successful")
else
	print("❌ Transport initialization failed: " .. tostring(err))
	os.exit(1)
end

-- Test 2: Initialize session
print("\n📋 Test 2: Initialize session")
local session_success, session_err = mcp.initialize_session({
	name = "test-client",
	version = "1.0.0",
	capabilities = { tools = {}, resources = {}, notifications = {} },
})

if session_success then
	print("✅ Session initialization successful")
	local status = mcp.get_status()
	print("📊 Session ID: " .. (status.session_id or "none"))
	print("📊 Protocol version: " .. status.protocol_version)
else
	print("❌ Session initialization failed: " .. tostring(session_err))
	os.exit(1)
end

-- Test 3: Send a simple request
print("\n📋 Test 3: Send simple request")
local request = {
	jsonrpc = "2.0",
	id = "test-1",
	method = "tools/list",
	params = {}
}

local response, req_err = mcp.send_request(request)
if response then
	print("✅ Request successful")
	if response.result then
		print("📊 Response has result")
	elseif response.error then
		print("⚠️ Response has error: " .. (response.error.message or "unknown"))
	end
else
	print("❌ Request failed: " .. tostring(req_err))
end

-- Test 4: Send a notification
print("\n📋 Test 4: Send notification")
local notification = {
	jsonrpc = "2.0",
	method = "notifications/ping",
	params = { message = "test ping" }
}

local notif_success, notif_err = mcp.send_notification(notification)
if notif_success then
	print("✅ Notification sent successfully")
else
	print("❌ Notification failed: " .. tostring(notif_err))
end

-- Test 5: Test streaming request (if supported)
print("\n📋 Test 5: Test streaming request")
local streaming_request = {
	jsonrpc = "2.0",
	id = "test-stream-1",
	method = "streaming_chat_completion",
	params = {
		model = "deepseek-r1:1.5b",
		message = "Hello, this is a test message",
		chunk_size = 50
	}
}

local stream_response, stream_err = mcp.send_request(streaming_request)
if stream_response then
	print("✅ Streaming request initiated")
	if stream_response.result and stream_response.result.streaming then
		print("📊 Streaming request ID: " .. stream_response.result.request_id)
		
		-- Wait a bit for streaming to complete
		print("⏳ Waiting for streaming to complete...")
		local max_wait = 10 -- seconds
		local wait_time = 0
		while wait_time < max_wait do
			if mcp.is_streaming_complete(stream_response.result.request_id) then
				print("✅ Streaming completed")
				break
			end
			os.execute("sleep 0.5")
			wait_time = wait_time + 0.5
		end
		
		if wait_time >= max_wait then
			print("⚠️ Streaming timeout")
		end
	else
		print("📝 Regular response received (not streaming)")
	end
else
	print("❌ Streaming request failed: " .. tostring(stream_err))
end

-- Test 6: Cleanup
print("\n📋 Test 6: Cleanup")
local cleanup_success = mcp.shutdown()
if cleanup_success then
	print("✅ Cleanup successful")
else
	print("❌ Cleanup failed")
end

print("\n🎉 MCP Standard Transport Test Complete!")
print("=" .. string.rep("=", 50))
