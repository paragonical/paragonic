#!/bin/bash

# MCP Direct Method Test Script
# This script tests calling streaming_chat_completion directly as a method

set -e

echo "🚀 Starting MCP Direct Method Test..."

# Clean up any existing processes
echo "🧹 Cleaning up existing processes..."
pkill -f "cargo run --bin paragonic" || true
pkill -f "curl.*localhost:3000" || true

# Create log directories
mkdir -p /tmp/paragonic_test

# Start the server
echo "🖥️  Starting Paragonic server..."
cargo run --bin paragonic > /tmp/paragonic_test/server.log 2>&1 &
SERVER_PID=$!

# Wait for server to start
echo "⏳ Waiting for server to start..."
sleep 5

# Check if server is running
if ! curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo "❌ Server failed to start. Check /tmp/paragonic_test/server.log"
    exit 1
fi

echo "✅ Server started successfully (PID: $SERVER_PID)"

# Start SSE monitoring in background
echo "📡 Starting SSE monitoring..."
curl -N -H "Accept: text/event-stream" \
     -H "mcp-protocol-version: 2025-06-18" \
     -H "origin: neovim://paragonic" \
     --max-time 60 \
     http://localhost:3000/mcp > /tmp/paragonic_test/sse.log 2>&1 &
SSE_PID=$!

# Wait for SSE connection to establish
echo "⏳ Waiting for SSE connection to establish..."
sleep 3

# Send MCP streaming chat completion request directly as a method
echo "📤 Sending MCP streaming chat completion request (direct method)..."
curl -s -X POST \
     -H "Content-Type: application/json" \
     -H "mcp-protocol-version: 2025-06-18" \
     -H "origin: neovim://paragonic" \
     http://localhost:3000/mcp \
     -d '{
       "jsonrpc": "2.0",
       "id": 456,
       "method": "streaming_chat_completion",
       "params": {
         "message": "hello world",
         "model": "deepseek-r1:1.5b",
         "_meta": {
           "progressToken": "test_direct_method_456"
         }
       }
     }' > /tmp/paragonic_test/response.json

echo "📥 Received initial response:"
cat /tmp/paragonic_test/response.json | jq '.' 2>/dev/null || cat /tmp/paragonic_test/response.json

# Wait for SSE events to be captured
echo "⏳ Waiting for SSE events to be captured..."
sleep 10

# Stop SSE monitoring
echo "🛑 Stopping SSE monitoring..."
kill $SSE_PID 2>/dev/null || true

# Display captured SSE events
echo ""
echo "📡 Captured SSE Events:"
echo "========================"
if [ -s /tmp/paragonic_test/sse.log ]; then
    cat /tmp/paragonic_test/sse.log
else
    echo "No SSE events captured"
fi

# Analyze the results
echo ""
echo "🔍 Analysis:"
echo "============"

# Check if initial response is proper MCP format
if grep -q '"jsonrpc": "2.0"' /tmp/paragonic_test/response.json; then
    echo "✅ Initial response uses proper MCP format (jsonrpc: 2.0)"
else
    echo "❌ Initial response does NOT use proper MCP format"
fi

# Check if SSE events use proper MCP format
if grep -q '"jsonrpc": "2.0"' /tmp/paragonic_test/sse.log; then
    echo "✅ SSE notifications use proper MCP format (jsonrpc: 2.0)"
else
    echo "❌ SSE notifications do NOT use proper MCP format"
fi

# Count progress notifications
PROGRESS_COUNT=$(grep -c '"method": "notifications/progress"' /tmp/paragonic_test/sse.log || echo "0")
echo "📊 Progress notifications captured: $PROGRESS_COUNT"

# Count message notifications
MESSAGE_COUNT=$(grep -c '"method": "notifications/message"' /tmp/paragonic_test/sse.log || echo "0")
echo "📨 Message notifications captured: $MESSAGE_COUNT"

# Count heartbeats
HEARTBEAT_COUNT=$(grep -c "event: heartbeat" /tmp/paragonic_test/sse.log || echo "0")
echo "💓 Heartbeat events captured: $HEARTBEAT_COUNT"

# Check for progressToken consistency
if grep -q "test_direct_method_456" /tmp/paragonic_test/sse.log; then
    echo "✅ ProgressToken consistency verified"
else
    echo "❌ ProgressToken consistency issue detected"
fi

echo ""
echo "📁 Log files:"
echo "  Server log: /tmp/paragonic_test/server.log"
echo "  SSE log: /tmp/paragonic_test/sse.log"
echo "  Response: /tmp/paragonic_test/response.json"

# Clean up
echo ""
echo "🧹 Cleaning up..."
kill $SERVER_PID 2>/dev/null || true
pkill -f "curl.*localhost:3000" 2>/dev/null || true

echo "✅ Test completed!"
