#!/bin/bash
# RbxSyn CodeSync Start Script
# Starts the sync server for your codespace

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

echo "🚀 Starting RbxSyn CodeSync Server..."
echo ""

# Check if port is already in use
PORT=${PORT:-3000}
if lsof -Pi :${PORT} -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  Port ${PORT} is already in use!"
    echo "   The server might already be running."
    echo ""
    echo "💡 Check status: ./check-status.sh"
    echo "   Stop server: ./stop-sync.sh"
    exit 1
fi

# Get codespace URL if available
CODESPACE_URL=""
if [ -n "$CODESPACE_NAME" ]; then
    CODESPACE_URL="https://${CODESPACE_NAME}-${PORT}.app.github.dev"
fi

# Start the server
echo "📦 Starting server..."
npm start

echo ""
echo "✅ Server started successfully!"
echo ""
echo "🔗 URLs:"
echo "   Local:     http://localhost:${PORT}"
if [ -n "$CODESPACE_URL" ]; then
    echo "   Codespace: ${CODESPACE_URL}"
fi
echo ""
echo "📊 Health Check: http://localhost:${PORT}/health"
echo "📡 API Status:   http://localhost:${PORT}/api/status"
echo ""
echo "💡 Next steps:"
echo "   1. Open Roblox Studio"
echo "   2. Install RbxSynSyncPlugin.lua plugin"
echo "   3. Configure plugin with your codespace URL"
echo "   4. Click 'Sync Now' to test!"

