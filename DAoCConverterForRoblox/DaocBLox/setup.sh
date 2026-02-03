#!/bin/bash

# RbxSyn CodeSync Setup Script
# This script sets up the RbxSyn plugin server for your codespace

set -e

echo "🚀 Setting up RbxSyn CodeSync for your codespace..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Change to script directory
cd "$(dirname "$0")"

echo "📦 Installing dependencies..."
npm install
echo ""

# Create necessary directories
echo "📁 Creating directory structure..."
mkdir -p scripts
mkdir -p .rbxsync-trash
mkdir -p ServerScriptService
mkdir -p ReplicatedStorage
mkdir -p StarterGui
mkdir -p StarterPack
mkdir -p ServerStorage
mkdir -p Lighting
mkdir -p SoundService
mkdir -p StarterPlayer
mkdir -p Workspace
echo ""

# Create environment file if it doesn't exist
if [ ! -f .env ]; then
    echo "⚙️  Creating environment configuration..."
    cat > .env << EOF
# RbxSyn CodeSync Configuration
PORT=3000
NODE_ENV=development
# For production, set to true
HTTPS_ENABLED=false
# SSL certificate paths (required if HTTPS_ENABLED=true)
SSL_KEY_PATH=server.key
SSL_CERT_PATH=server.crt
# Sync settings
SYNC_INTERVAL=30
ENABLE_AUTO_SYNC=true
# Authentication (optional)
API_KEY=
EOF
    echo "   ✅ Created .env file"
    echo ""
else
    echo "ℹ️  .env file already exists, skipping creation"
    echo ""
fi

# Generate a plugin manifest
echo "📝 Creating plugin manifest..."
cat > RbxSynSyncPlugin.plugin.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<PluginManifest Version="1">
    <Metadata>
        <Name>RbxSyn CodeSync</Name>
        <Description>Sync Roblox scripts using RbxSyn</Description>
        with your codespace <Author>DAoC Converter Team</Author>
        <Version>1.0.0</Version>
        <Website>https://github.com/yourusername/daoc-sql-to-roblox</Website>
    </Metadata>
    <Settings>
        <Configuration>
            <Item Name="codespaceUrl" Type="String" Default="http://localhost:3000"/>
            <Item Name="autoSync" Type="Bool" Default="true"/>
            <Item Name="syncInterval" Type="Number" Default="30"/>
        </Configuration>
    </Settings>
    <Permissions>
        <HttpRequest Url="*" Type="Write"/>
        <HttpRequest Url="*" Type="Read"/>
    </Permissions>
</PluginManifest>
echo "   ✅ Created plugin manifest"
echo ""

# Create startup script
echo "🔧 Creating startup scripts..."
cat > start-sync.sh << 'EOF'
#!/bin/bash
# Start the RbxSyn CodeSync server

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

echo "🚀 Starting RbxSyn CodeSync Server..."
echo ""

# Check if port is already in use
if lsof -Pi :${PORT:-3000} -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  Port ${PORT:-3000} is already in use!"
    echo "   The server might already be running."
    echo "   URL: http://localhost:${PORT:-3000}"
    exit 1
fi

# Start the server
npm start

echo ""
echo "✅ Server started successfully!"
echo "   Local URL: http://localhost:${PORT:-3000}"
echo "   Codespace URL will be displayed after startup"
EOF

chmod +x start-sync.sh
echo "   ✅ Created start-sync.sh"
echo ""

# Create status check script
cat > check-status.sh << 'EOF'
#!/bin/bash
# Check if the RbxSyn server is running

PORT=${PORT:-3000}
URL="http://localhost:$PORT"

echo "🔍 Checking RbxSyn CodeSync server status..."
echo ""

if curl -s "$URL/health" > /dev/null 2>&1; then
    echo "✅ Server is running!"
    echo ""
    echo "📊 Status:"
    curl -s "$URL/api/status" | jq . 2>/dev/null || curl -s "$URL/api/status"
    echo ""
    echo "🔗 URLs:"
    echo "   Local: $URL"
    echo "   Health: $URL/health"
    echo "   API: $URL/api/status"
    exit 0
else
    echo "❌ Server is not running!"
    echo ""
    echo "💡 To start the server, run:"
    echo "   ./start-sync.sh"
    exit 1
fi
EOF

chmod +x check-status.sh
echo "   ✅ Created check-status.sh"
echo ""

# Create stop script
cat > stop-sync.sh << 'EOF'
#!/bin/bash
# Stop the RbxSyn CodeSync server

PORT=${PORT:-3000}

echo "🛑 Stopping RbxSyn CodeSync server..."

# Kill process on port
if lsof -Pi :${PORT:-3000} -sTCP:LISTEN -t >/dev/null 2>&1; then
    kill $(lsof -t -i:${PORT:-3000}) 2>/dev/null || true
    echo "✅ Server stopped!"
else
    echo "⚠️  No server found running on port ${PORT:-3000}"
fi
EOF

chmod +x stop-sync.sh
echo "   ✅ Created stop-sync.sh"
echo ""

# Print setup summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Quick Start:"
echo "   1. Start the server: ./start-sync.sh"
echo "   2. Check status: ./check-status.sh"
echo "   3. Open Roblox Studio and install the plugin"
echo ""
echo "🔗 Server URLs (after starting):"
echo "   Local:     http://localhost:3000"
echo "   Codespace: https://your-codespace-url-3000.app.github.dev"
echo ""
echo "📁 Files created:"
echo "   • start-sync.sh   - Start the sync server"
echo "   • stop-sync.sh    - Stop the sync server"
echo "   • check-status.sh - Check server status"
echo "   • .env            - Environment configuration"
echo "   • scripts/        - Synced scripts directory"
echo ""
echo "📖 Next Steps:"
echo "   1. Start the server with: ./start-sync.sh"
echo "   2. Copy the codespace URL from the terminal"
echo "   3. Install RbxSynSyncPlugin.lua in Roblox Studio"
echo "   4. Configure the plugin with your codespace URL"
echo "   5. Click 'Sync Now' to test the connection!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

