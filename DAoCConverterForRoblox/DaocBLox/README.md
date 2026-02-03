# DaocBLox - RbxSyn CodeSync Plugin

This is a Roblox Studio plugin that enables real-time synchronization between your Roblox Studio project and your GitHub Codespace using RbxSyn.

## 🚀 Quick Start

### 1. Setup the Codespace

```bash
cd DAoCConverterForRoblox/DaocBLox
./setup.sh
```

This will:
- Install npm dependencies
- Create necessary directories
- Generate configuration files
- Create startup scripts

### 2. Start the Server

```bash
./start-sync.sh
```

You'll see output like:
```
╔═══════════════════════════════════════════════════════════╗
║          🚀 RbxSyn CodeSync Server Started!              ║
╠═══════════════════════════════════════════════════════════╣
║  Local URL:      http://localhost:3000                    ║
║  Codespace URL:  https://your-name-abc123-3000.app.github.dev║
╚═══════════════════════════════════════════════════════════╝
```

### 3. Install Plugin in Roblox Studio

1. Copy `RbxSynSyncPlugin.lua` to your Roblox Studio Plugins folder
2. Restart Roblox Studio
3. Click the "RbxSyn CodeSync" toolbar button
4. Enter your codespace URL
5. Click "Sync Now"

## 📁 Project Structure

```
DaocBLox/
├── scripts/                    # Synced scripts
│   ├── ServerScriptService/
│   ├── ReplicatedStorage/
│   ├── StarterGui/
│   ├── StarterPack/
│   └── ...
├── .rbxsync-trash/            # Deleted scripts
├── server.js                  # Sync server
├── package.json               # Dependencies
├── sync-config.json          # Sync configuration
├── .env                      # Environment variables
├── setup.sh                  # Setup script
├── start-sync.sh             # Start server
├── stop-sync.sh              # Stop server
├── check-status.sh           # Check status
├── RbxSynSyncPlugin.lua      # Roblox Studio plugin
└── CONNECTION_GUIDE.md       # Detailed guide
```

## 🔧 Commands

| Command | Description |
|---------|-------------|
| `./setup.sh` | Install dependencies & setup |
| `./start-sync.sh` | Start the sync server |
| `./stop-sync.sh` | Stop the sync server |
| `./check-status.sh` | Check if server is running |

## 📖 Documentation

- [CONNECTION_GUIDE.md](CONNECTION_GUIDE.md) - Detailed connection guide
- [sync-config.json](sync-config.json) - Sync configuration reference

## 🔗 URLs

- **Local:** `http://localhost:3000`
- **API:** `http://localhost:3000/api/status`
- **Health:** `http://localhost:3000/health`

## ⚙️ Configuration

Edit `.env` or `sync-config.json` to customize:

```env
PORT=3000
SYNC_INTERVAL=30
ENABLE_AUTO_SYNC=true
```

## 📝 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/sync` | Sync scripts |
| GET | `/api/status` | Get status |
| GET | `/api/scripts` | List scripts |
| GET | `/api/export` | Export all |
| GET | `/health` | Health check |

## 🛠️ Troubleshooting

- **Server not running?** Run `./start-sync.sh`
- **Connection failed?** Check `./check-status.sh`
- **Need help?** See [CONNECTION_GUIDE.md](CONNECTION_GUIDE.md)

## 📄 License

MIT License

