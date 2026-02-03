# RbxSyn CodeSync - Roblox Studio Plugin Connection Guide

This guide will help you connect your Roblox Studio to your codespace using RbxSyn CodeSync.

## Prerequisites

- ✅ GitHub Codespace created
- ✅ Roblox Studio installed
- ✅ Node.js (included in codespace)

---

## Quick Start (5 minutes)

### Step 1: Start the Sync Server

In your codespace terminal:

```bash
cd DAoCConverterForRoblox/DaocBLox
./setup.sh
```

This will:
- Install npm dependencies
- Create necessary directories
- Generate configuration files
- Create startup scripts

### Step 2: Start the Server

```bash
./start-sync.sh
```

You should see output similar to:

```
🚀 Starting RbxSyn CodeSync Server...
✅ Server started successfully!
   Local URL: http://localhost:3000
   Codespace URL: https://your-codespace-name-3000.app.github.dev
```

**Important:** Copy your codespace URL from the terminal output!

### Step 3: Install Plugin in Roblox Studio

1. **Open Roblox Studio**
2. **Go to** `Plugins` → `Open Plugin Folder`
3. **Copy** the `RbxSynSyncPlugin.lua` file to your Plugins folder
4. **Restart** Roblox Studio
5. **Look for** a new toolbar button named "RbxSyn CodeSync"

### Step 4: Configure the Plugin

1. **Click** the "RbxSyn CodeSync" button in the toolbar
2. A dock widget will appear on the right side
3. **Enter your codespace URL** in the "Codespace URL" field:
   - Local development: `http://localhost:3000`
   - Codespace: `https://your-codespace-name-3000.app.github.dev`
4. **Click** "Enable Auto Sync" if you want automatic syncing
5. **Click** "Sync Now" to test the connection

---

## Detailed Setup

### Finding Your Codespace URL

**Option 1: From Terminal (Recommended)**
When you run `./start-sync.sh`, the URL is displayed in the terminal output.

**Option 2: From Browser**
1. Go to your GitHub Codespaces dashboard
2. Click on your codespace name
3. Look at the browser address bar
4. Change the port from 80 to 3000
5. Example: `https://your-name-abc123-3000.app.github.dev`

**Option 3: From VS Code**
1. Click the "Ports" tab in the terminal panel
2. Find port 3000
3. Right-click and select "Copy Local Address"

### Configuring Plugin Settings

The plugin stores settings in Roblox Studio. You can customize:

| Setting | Description | Default |
|---------|-------------|---------|
| `codespaceUrl` | Your codespace server URL | `http://localhost:3000` |
| `autoSync` | Enable automatic syncing | `true` |
| `syncInterval` | Auto-sync interval (seconds) | `30` |

### Manual Plugin Installation

If the automatic installation doesn't work:

1. **Create** a `Plugins` folder in your Roblox Studio directory:
   - Windows: `%localappdata%\Roblox\Plugins\`
   - Mac: `~/Library/Application Support/Roblox/Plugins/`

2. **Copy** `RbxSynSyncPlugin.lua` to this folder

3. **Restart** Roblox Studio

---

## Testing the Connection

### Method 1: Using the Plugin UI

1. Open the plugin (click toolbar button)
2. Click "Sync Now"
3. Watch the status updates:
   - ✅ "Collecting scripts..."
   - ✅ "Found X scripts..."
   - ✅ "Sync completed!"

### Method 2: Using curl (Terminal)

Check server status:

```bash
curl http://localhost:3000/api/status
```

Expected response:

```json
{
  "status": "online",
  "project": "DaocBLox",
  "lastSync": "2024-01-01T12:00:00.000Z",
  "totalScripts": 5,
  "uptime": 3600
}
```

### Method 3: Browser Test

Open in your browser:
- Local: `http://localhost:3000/health`
- Codespace: `https://your-codespace-3000.app.github.dev/health`

Expected response: `{"status":"healthy","timestamp":"..."}`

---

## Troubleshooting

### ❌ "Connection Failed" Error

**Possible causes and solutions:**

1. **Server not running**
   ```bash
   ./check-status.sh
   # If not running, start it:
   ./start-sync.sh
   ```

2. **Wrong URL**
   - Ensure you're using the correct codespace URL
   - Try the local URL: `http://localhost:3000`

3. **Port not forwarded**
   - In VS Code, go to Ports tab
   - Ensure port 3000 is "Public" or "Private"

4. **Firewall blocking**
   - Temporarily disable firewall
   - Or add exception for port 3000

### ❌ "Sync Failed: Unknown Error"

1. Check server logs:
   ```bash
   cat sync.log
   ```

2. Verify HttpService is enabled:
   - In Roblox Studio, go to Game Settings
   - Ensure "HTTP Requests" is enabled

3. Try manual sync:
   - Disable auto-sync
   - Click "Sync Now" manually

### ❌ Scripts Not Appearing

1. Check scripts are in supported services:
   - ServerScriptService
   - ReplicatedStorage
   - StarterGui
   - StarterPack
   - Workspace
   - Lighting

2. Verify scripts are Lua source containers:
   - Script
   - ModuleScript
   - LocalScript

3. Check file permissions:
   ```bash
   ls -la scripts/
   ```

### ❌ Plugin Button Not Appearing

1. **Restart Roblox Studio** completely
2. **Check** Plugin Folder location
3. **Verify** the file is named correctly:
   - `RbxSynSyncPlugin.lua` (NOT `.txt` or other)

### ❌ Changes Not Syncing

1. **Auto-sync debounce**: Changes take ~3 seconds to sync
2. **Manual sync**: Click "Sync Now" button
3. **Check** auto-sync is enabled in plugin settings

---

## Advanced Configuration

### HTTPS Setup (Production)

For production use with HTTPS:

1. Generate SSL certificates:
   ```bash
   openssl req -x509 -newkey rsa:4096 -keyout server.key -out server.crt -days 365 -nodes
   ```

2. Update `.env`:
   ```env
   HTTPS_ENABLED=true
   SSL_KEY_PATH=server.key
   SSL_CERT_PATH=server.crt
   ```

3. Restart the server:
   ```bash
   ./stop-sync.sh
   ./start-sync.sh
   ```

### API Authentication

To add API key authentication:

1. Edit `.env`:
   ```env
   API_KEY=your-secret-key-here
   ```

2. Update plugin URL to include key:
   ```
   http://localhost:3000?apiKey=your-secret-key-here
   ```

### Custom Sync Interval

Edit `.env`:
```env
SYNC_INTERVAL=60  # Sync every minute
```

Or change in plugin settings UI.

---

## File Structure

After setup, your directory will look like:

```
DaocBLox/
├── scripts/                    # Synced scripts directory
│   ├── ServerScriptService/
│   ├── ReplicatedStorage/
│   ├── StarterGui/
│   ├── StarterPack/
│   └── ...
├── .rbxsync-trash/            # Deleted scripts backup
│   └── manifest.json
├── server.js                   # Sync server
├── package.json                # Dependencies
├── .env                        # Configuration
├── setup.sh                    # Setup script
├── start-sync.sh              # Start server
├── stop-sync.sh               # Stop server
├── check-status.sh            # Check server status
├── RbxSynSyncPlugin.lua        # Roblox Studio plugin
└── README.md                   # This file
```

---

## API Reference

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/sync` | Sync scripts to codespace |
| GET | `/api/status` | Get sync status |
| GET | `/api/scripts` | List all synced scripts |
| GET | `/api/scripts/:name` | Get specific script |
| PUT | `/api/scripts/:name` | Update script |
| DELETE | `/api/scripts/:name` | Delete script |
| GET | `/api/export` | Export all scripts |
| GET | `/health` | Health check |

### Sync Request Format

```json
{
  "timestamp": 1234567890,
  "project": "DaocBLox",
  "version": "1.0.0",
  "scripts": [
    {
      "name": "MainScript",
      "path": "ServerScriptService/MainScript",
      "source": "-- Lua code",
      "className": "Script",
      "service": "ServerScriptService"
    }
  ]
}
```

---

## Getting Help

1. **Check logs**: `tail -f sync.log`
2. **Server status**: `./check-status.sh`
3. **Restart server**: `./stop-sync.sh && ./start-sync.sh`
4. **Reinstall**: `./setup.sh`

---

## Next Steps

Once connected, you can:

- ✅ Edit scripts in VS Code
- ✅ Sync changes to Roblox Studio
- ✅ Auto-sync on script changes
- ✅ Manage multiple scripts
- ✅ Track sync history

Happy coding! 🚀

