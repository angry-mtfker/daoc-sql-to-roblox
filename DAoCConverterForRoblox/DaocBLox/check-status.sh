#!/bin/bash
# RbxSyn CodeSync Status Check Script
# Checks if the sync server is running

PORT=${PORT:-3000}
LOCAL_URL="http://localhost:${PORT}"

echo "🔍 Checking RbxSyn CodeSync server status..."
echo ""

# Check if server is running
if curl -s "${LOCAL_URL}/health" > /dev/null 2>&1; then
    echo "✅ Server is RUNNING!"
    echo ""
    echo "📊 Server Status:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Get detailed status
    STATUS=$(curl -s "${LOCAL_URL}/api/status")
    echo "${STATUS}" | jq . 2>/dev/null || echo "${STATUS}"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🔗 URLs:"
    echo "   Local:     ${LOCAL_URL}"
    echo "   Health:     ${LOCAL_URL}/health"
    echo "   API:       ${LOCAL_URL}/api/status"
    echo "   Scripts:   ${LOCAL_URL}/api/scripts"
    echo ""
    echo "💡 Actions:"
    echo "   • Stop server: ./stop-sync.sh"
    echo "   • Open in browser: ${LOCAL_URL}"
    exit 0
else
    echo "❌ Server is NOT RUNNING!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "💡 To start the server, run:"
    echo "   ./start-sync.sh"
    echo ""
    echo "📋 Prerequisites:"
    echo "   1. Install dependencies: ./setup.sh"
    echo "   2. Configure environment: Edit .env file"
    echo "   3. Start server: ./start-sync.sh"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
fi

