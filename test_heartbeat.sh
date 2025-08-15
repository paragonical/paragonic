#!/bin/bash

# MCP Heartbeat Test Script
# This script tests the heartbeat format to ensure it uses MCP notifications/message

set -e

echo "🚀 Starting MCP Heartbeat Test..."

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
     --max-time 30 \
     http://localhost:3000/mcp > /tmp/paragonic_test/sse.log 2>&1 &
SSE_PID=$!

# Wait for heartbeats to be captured
echo "⏳ Waiting for heartbeats to be captured..."
sleep 15

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

# Check if heartbeats use proper MCP format
if grep -q 'notifications/message' /tmp/paragonic_test/sse.log; then
    echo "✅ Heartbeats use proper MCP notifications/message format"
else
    echo "❌ Heartbeats do NOT use proper MCP format"
fi

# Check if heartbeats have jsonrpc field
if grep -q 'jsonrpc.*2.0' /tmp/paragonic_test/sse.log; then
    echo "✅ Heartbeats include jsonrpc: 2.0 field"
else
    echo "❌ Heartbeats missing jsonrpc: 2.0 field"
fi

# Count heartbeats
HEARTBEAT_COUNT=$(grep -c 'type.*heartbeat' /tmp/paragonic_test/sse.log || echo "0")
echo "💓 Heartbeat events captured: $HEARTBEAT_COUNT"

# Check for heartbeat message
if grep -q 'SSE connection heartbeat' /tmp/paragonic_test/sse.log; then
    echo "✅ Heartbeat includes proper message field"
else
    echo "❌ Heartbeat missing proper message field"
fi

# Check for timestamp and stream_id
if grep -q '"timestamp"' /tmp/paragonic_test/sse.log && grep -q '"stream_id"' /tmp/paragonic_test/sse.log; then
    echo "✅ Heartbeat includes timestamp and stream_id"
else
    echo "❌ Heartbeat missing timestamp or stream_id"
fi

echo ""
echo "📁 Log files:"
echo "  Server log: /tmp/paragonic_test/server.log"
echo "  SSE log: /tmp/paragonic_test/sse.log"

# Clean up
echo ""
echo "🧹 Cleaning up..."
kill $SERVER_PID 2>/dev/null || true
pkill -f "curl.*localhost:3000" 2>/dev/null || true

echo "✅ Test completed!"
