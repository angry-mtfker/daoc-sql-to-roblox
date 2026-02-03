const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path');
const os = require('os');

// Load configuration
let config;
try {
    const configPath = path.join(__dirname, 'sync-config.json');
    if (fs.existsSync(configPath)) {
        config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    } else {
        config = {};
    }
} catch (e) {
    console.warn('Warning: Could not load sync-config.json, using defaults');
    config = {};
}

// Load environment variables
const PORT = process.env.PORT || config.server?.port || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';
const HTTPS_ENABLED = process.env.HTTPS_ENABLED === 'true' || config.server?.httpsEnabled || false;
const LOG_LEVEL = process.env.LOG_LEVEL || config.server?.logLevel || 'info';
const API_KEY = process.env.API_KEY || config.server?.apiKey || null;

const app = express();

// Logging utility
function log(level, message, data = null) {
    const timestamp = new Date().toISOString();
    const logEntry = `[${timestamp}] [${level.toUpperCase()}] ${message}`;
    
    if (data) {
        console.log(logEntry, data);
    } else {
        console.log(logEntry);
    }
    
    // Write to log file
    if (config.logging?.enabled !== false && config.logging?.file) {
        const logPath = path.join(__dirname, config.logging.file);
        fs.appendFileSync(logPath, logEntry + '\n');
    }
}

// Get codespace URL
function getCodespaceUrl() {
    // Check environment variables
    if (process.env.CODESPACE_NAME) {
        return `https://${process.env.CODESPACE_NAME}-${PORT}.app.github.dev`;
    }
    if (process.env.GITPOD_WORKSPACE_URL) {
        const url = process.env.GITPOD_WORKSPACE_URL.replace('https://', `https://${PORT}-`);
        return url;
    }
    // Fallback to localhost
    return `http://localhost:${PORT}`;
}

// Middleware
app.use(cors());
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '50mb' }));

// Store synced scripts
let syncedScripts = [];
let lastSync = null;

// Create scripts directory if it doesn't exist
const scriptsDir = config.fileManagement?.scriptsDir || 'scripts';
const scriptsDirPath = path.join(__dirname, scriptsDir);
if (!fs.existsSync(scriptsDirPath)) {
    fs.mkdirSync(scriptsDirPath, { recursive: true });
}

// Create trash directory if it doesn't exist
const trashDirName = config.fileManagement?.trashDir || '.rbxsync-trash';
const trashDir = path.join(__dirname, trashDirName);
if (!fs.existsSync(trashDir)) {
    fs.mkdirSync(trashDir, { recursive: true });
}

// Initialize manifest file
const manifestPath = path.join(trashDir, 'manifest.json');
if (!fs.existsSync(manifestPath)) {
    fs.writeFileSync(manifestPath, JSON.stringify({
        deletedScripts: [],
        lastSync: null
    }, null, 2));
}

// Helper function to get service directories
function getServiceDirectories() {
    return config.services?.include || [
        'ServerScriptService',
        'ReplicatedStorage',
        'StarterGui',
        'StarterPack',
        'ServerStorage',
        'Lighting',
        'SoundService',
        'StarterPlayer',
        'Workspace'
    ];
}

// Helper function to ensure directory exists
function ensureDirectory(dirPath) {
    if (!fs.existsSync(dirPath)) {
        fs.mkdirSync(dirPath, { recursive: true });
    }
}

// Helper function to save script to file
function saveScriptToFile(script) {
    const serviceDir = path.join(scriptsDirPath, script.service);
    ensureDirectory(serviceDir);

    // Sanitize filename
    const filename = script.name.replace(/[^a-zA-Z0-9-_]/g, '_');
    const filePath = path.join(serviceDir, `${filename}.lua`);

    const scriptData = {
        name: script.name,
        path: script.path,
        source: script.source,
        className: script.className,
        service: script.service,
        syncedAt: new Date().toISOString()
    };

    fs.writeFileSync(filePath, JSON.stringify(scriptData, null, 2));
    return filePath;
}

// Helper function to delete script file
function deleteScriptFile(scriptName, service) {
    const filename = scriptName.replace(/[^a-zA-Z0-9-_]/g, '_');
    const filePath = path.join(scriptsDirPath, service, `${filename}.lua`);
    
    if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
        
        // Update manifest
        let manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
        manifest.deletedScripts.push({
            name: scriptName,
            service: service,
            deletedAt: new Date().toISOString()
        });
        manifest.lastSync = new Date().toISOString();
        fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));
        
        return true;
    }
    return false;
}

// Authentication middleware
function authenticate(req, res, next) {
    if (!API_KEY) {
        return next();
    }
    
    const apiKey = req.headers['x-api-key'] || req.query.apiKey;
    
    if (apiKey !== API_KEY) {
        return res.status(401).json({
            success: false,
            error: 'Unauthorized - Invalid API key'
        });
    }
    
    next();
}

// Apply authentication to sync endpoints
app.use('/api/sync', authenticate);
app.use('/api/scripts', authenticate);

// GET /api/status - Get sync status
app.get('/api/status', (req, res) => {
    // Count synced scripts
    let totalScripts = 0;
    const services = getServiceDirectories();
    
    try {
        services.forEach(service => {
            const serviceDir = path.join(scriptsDirPath, service);
            if (fs.existsSync(serviceDir)) {
                const files = fs.readdirSync(serviceDir);
                totalScripts += files.filter(f => f.endsWith('.lua')).length;
            }
        });
    } catch (e) {
        totalScripts = syncedScripts.length;
    }
    
    res.json({
        status: 'online',
        project: config.project || 'DaocBLox',
        version: config.version || '1.0.0',
        lastSync: lastSync,
        totalScripts: totalScripts,
        uptime: process.uptime(),
        codespaceUrl: getCodespaceUrl(),
        environment: NODE_ENV,
        config: {
            autoSync: config.sync?.autoSync || true,
            syncInterval: config.sync?.intervalSeconds || 30
        }
    });
});

// POST /api/sync - Sync scripts from Roblox Studio to codespace
app.post('/api/sync', (req, res) => {
    try {
        const { timestamp, project, version, scripts } = req.body;

        log('info', `Received sync request at ${new Date(timestamp).toISOString()}`);
        log('info', `Project: ${project}, Version: ${version}`);
        log('info', `Scripts to sync: ${scripts.length}`);

        let synced = 0;
        let skipped = 0;

        // Create service directories
        const services = getServiceDirectories();
        services.forEach(service => {
            ensureDirectory(path.join(scriptsDirPath, service));
        });

        // Process each script
        scripts.forEach(script => {
            if (script.source && script.className) {
                // Save script to file
                saveScriptToFile(script);
                
                // Update synced scripts array
                const existingIndex = syncedScripts.findIndex(s => s.name === script.name && s.path === script.path);
                if (existingIndex >= 0) {
                    syncedScripts[existingIndex] = script;
                } else {
                    syncedScripts.push(script);
                }
                
                synced++;
                log('debug', `Synced: ${script.name} (${script.className})`);
            } else {
                skipped++;
                log('debug', `Skipped: ${script.name} - missing source or className`);
            }
        });

        lastSync = new Date().toISOString();

        res.json({
            success: true,
            synced: synced,
            skipped: skipped,
            totalScripts: scripts.length,
            timestamp: lastSync,
            codespaceUrl: getCodespaceUrl()
        });

    } catch (error) {
        log('error', 'Sync error:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// GET /api/scripts - List all synced scripts
app.get('/api/scripts', (req, res) => {
    try {
        const scriptsList = [];
        
        const services = getServiceDirectories();
        services.forEach(service => {
            const serviceDir = path.join(scriptsDirPath, service);
            if (fs.existsSync(serviceDir)) {
                const files = fs.readdirSync(serviceDir);
                files.forEach(file => {
                    if (file.endsWith('.lua')) {
                        const filePath = path.join(serviceDir, file);
                        try {
                            const scriptData = JSON.parse(fs.readFileSync(filePath, 'utf8'));
                            scriptsList.push(scriptData);
                        } catch (e) {
                            log('warn', `Failed to parse script: ${file}`);
                        }
                    }
                });
            }
        });

        res.json({
            success: true,
            scripts: scriptsList,
            total: scriptsList.length
        });
    } catch (error) {
        log('error', 'Error listing scripts:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// GET /api/scripts/:name - Get specific script content
app.get('/api/scripts/:name', (req, res) => {
    try {
        const scriptName = req.params.name;
        
        const services = getServiceDirectories();
        let foundScript = null;

        for (const service of services) {
            const filename = scriptName.replace(/[^a-zA-Z0-9-_]/g, '_');
            const filePath = path.join(scriptsDirPath, service, `${filename}.lua`);
            
            if (fs.existsSync(filePath)) {
                foundScript = JSON.parse(fs.readFileSync(filePath, 'utf8'));
                break;
            }
        }

        if (foundScript) {
            res.json({
                success: true,
                script: foundScript
            });
        } else {
            res.status(404).json({
                success: false,
                error: 'Script not found'
            });
        }
    } catch (error) {
        log('error', 'Error getting script:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// PUT /api/scripts/:name - Update script from codespace
app.put('/api/scripts/:name', authenticate, (req, res) => {
    try {
        const scriptName = req.params.name;
        const { source } = req.body;

        // Find the script
        const services = getServiceDirectories();
        let scriptPath = null;
        let scriptService = null;

        for (const service of services) {
            const filename = scriptName.replace(/[^a-zA-Z0-9-_]/g, '_');
            const potentialPath = path.join(scriptsDirPath, service, `${filename}.lua`);
            
            if (fs.existsSync(potentialPath)) {
                scriptPath = potentialPath;
                scriptService = service;
                break;
            }
        }

        if (scriptPath) {
            const scriptData = JSON.parse(fs.readFileSync(scriptPath, 'utf8'));
            scriptData.source = source;
            scriptData.syncedAt = new Date().toISOString();
            
            fs.writeFileSync(scriptPath, JSON.stringify(scriptData, null, 2));

            log('info', `Updated script: ${scriptName}`);

            res.json({
                success: true,
                script: scriptData
            });
        } else {
            res.status(404).json({
                success: false,
                error: 'Script not found'
            });
        }
    } catch (error) {
        log('error', 'Error updating script:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// DELETE /api/scripts/:name - Delete a synced script
app.delete('/api/scripts/:name', authenticate, (req, res) => {
    try {
        const scriptName = req.params.name;
        const { service } = req.query;

        if (!service) {
            res.status(400).json({
                success: false,
                error: 'Service parameter is required'
            });
            return;
        }

        const deleted = deleteScriptFile(scriptName, service);

        if (deleted) {
            // Remove from syncedScripts array
            syncedScripts = syncedScripts.filter(s => !(s.name === scriptName && s.service === service));

            log('info', `Deleted script: ${scriptName} from ${service}`);

            res.json({
                success: true,
                message: 'Script deleted successfully'
            });
        } else {
            res.status(404).json({
                success: false,
                error: 'Script not found'
            });
        }
    } catch (error) {
        log('error', 'Error deleting script:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// GET /api/export - Export all scripts as JSON
app.get('/api/export', (req, res) => {
    try {
        const exportData = {
            project: config.project || 'DaocBLox',
            version: config.version || '1.0.0',
            exportedAt: new Date().toISOString(),
            scripts: []
        };

        const services = getServiceDirectories();
        services.forEach(service => {
            const serviceDir = path.join(scriptsDirPath, service);
            if (fs.existsSync(serviceDir)) {
                const files = fs.readdirSync(serviceDir);
                files.forEach(file => {
                    if (file.endsWith('.lua')) {
                        const filePath = path.join(serviceDir, file);
                        try {
                            const scriptData = JSON.parse(fs.readFileSync(filePath, 'utf8'));
                            exportData.scripts.push(scriptData);
                        } catch (e) {
                            log('warn', `Failed to parse script: ${file}`);
                        }
                    }
                });
            }
        });

        res.json(exportData);
    } catch (error) {
        log('error', 'Error exporting scripts:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// GET /api/config - Get sync configuration
app.get('/api/config', (req, res) => {
    res.json({
        success: true,
        config: {
            project: config.project,
            version: config.version,
            sync: config.sync,
            services: config.services,
            fileManagement: config.fileManagement
        }
    });
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

// Root endpoint - show server info
app.get('/', (req, res) => {
    res.json({
        name: 'RbxSyn CodeSync Server',
        version: '1.0.0',
        status: 'running',
        project: config.project || 'DaocBLox',
        endpoints: {
            status: '/api/status',
            sync: '/api/sync',
            scripts: '/api/scripts',
            export: '/api/export',
            config: '/api/config',
            health: '/health'
        },
        codespaceUrl: getCodespaceUrl()
    });
});

// Start server
const server = app.listen(PORT, () => {
    console.log('');
    console.log('╔═══════════════════════════════════════════════════════════╗');
    console.log('║          🚀 RbxSyn CodeSync Server Started!              ║');
    console.log('╠═══════════════════════════════════════════════════════════╣');
    console.log(`║  Local URL:      http://localhost:${PORT}                    ║`);
    console.log(`║  Codespace URL:  ${getCodespaceUrl().padEnd(48)}║`);
    console.log('╠═══════════════════════════════════════════════════════════╣');
    console.log('║  Endpoints:                                                ║');
    console.log('║    • POST   /api/sync     - Sync scripts                 ║');
    console.log('║    • GET    /api/status    - Get sync status             ║');
    console.log('║    • GET    /api/scripts   - List all scripts            ║');
    console.log('║    • GET    /api/export    - Export all scripts          ║');
    console.log('║    • GET    /health        - Health check                ║');
    console.log('╚═══════════════════════════════════════════════════════════╝');
    console.log('');
    log('info', 'Server started successfully');
});

// Graceful shutdown
process.on('SIGTERM', () => {
    log('info', 'SIGTERM signal received: closing HTTP server');
    server.close(() => {
        log('info', 'HTTP server closed');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    log('info', 'SIGINT signal received: closing HTTP server');
    server.close(() => {
        log('info', 'HTTP server closed');
        process.exit(0);
    });
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
    log('error', 'Uncaught Exception:', error);
});

process.on('unhandledRejection', (reason, promise) => {
    log('error', 'Unhandled Rejection at:', promise, 'reason:', reason);
});

