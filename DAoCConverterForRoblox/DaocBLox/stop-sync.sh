#!/bin/bash
# RbxSyn CodeSync Stop Script
# Stops the sync server

PORT=${PORT:-3000}

echo "🛑 Stopping RbxSyn CodeSync server..."
echo ""

# Kill process on port
if lsof -Pi :${PORT} -sTCP:LISTEN -t >/dev/null 2>&1; then
    PID=$(lsof -t -i:${PORT})
    kill ${PID} 2>/dev/null || true
    
    # Wait for process to terminate
    sleep 1
    
    # Check if still running
    if lsof -Pi :${PORT} -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "⚠️  Force killing process..."
        kill -9 ${PID} 2>/dev/null || true
        sleep 1
    fi
    
    echo "✅ Server stopped successfully!"
else
    echo "ℹ️  No server found running on port ${PORT}"
fi

echo ""
echo "💡 To restart the server, run: ./start-sync.sh"

