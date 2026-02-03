--[[
	DAoC SQL to Roblox Converter - Main Plugin
	============================================
	
	This is the main entry point for the DAoC SQL to Roblox Converter plugin.
	The plugin enables drag-and-drop conversion of DAoC SQL database files
	to Roblox Lua data formats.
	
	Supported SQL files:
	- ability.sql
	- spell.sql
	- itemtemplate.sql
	- npctemplate.sql
	- mob.sql
	- And many more...
	
	Features:
	- Drag-and-drop SQL file import
	- Automatic table detection
	- SQL to Lua conversion
	- ModuleScript generation
	- Progress tracking
	- Error handling
	- Debug system with comprehensive logging
	
	Author: DAoC Converter Team
	Version: 1.0.0
--]]

-- Services
local PluginGuiService = game:GetService("PluginGuiService")
local HttpService = game:GetService("HttpService")
local StudioService = game:GetService("StudioService")
local Selection = game:GetService("Selection")

-- Constants
local PLUGIN_NAME = "DAoC SQL to Roblox Converter"
local PLUGIN_ID = "daoc-sql-to-roblox-converter"
local VERSION = "1.0.0"

-- Plugin state
local plugin = nil
local pluginGui = nil
local toolbar = nil
local mainFrame = nil
local dropZone = nil
local fileList = {}
local convertedData = {}
local isProcessing = false
local debugPanelUI = nil

-- Configuration
local config = {
	outputFormat = "Modulescript",  -- "Modulescript", "JSON", "Table"
	autoExport = true,
	prettyPrint = true,
	maxRowsPerFile = 1000,
	outputFolder = "DAoCData",
	enableDebugPanel = true,
}

-- Core modules (loaded on demand)
local SQLParser = nil
local DataConverter = nil
local ExportManager = nil
local DebugSystem = nil

--================================================================================
-- DEBUG SYSTEM INTEGRATION
--================================================================================

local function initDebugSystem()
	-- Load DebugSystem module
	local debugSuccess, debugModule = pcall(function()
		return require(script.Core.DebugSystem)
	end)
	
	if debugSuccess and debugModule then
		DebugSystem = debugModule
		
		-- Initialize with config
		DebugSystem.init({
			logLevel = config.enableDebugPanel and 2 or 3,  -- INFO if debug panel enabled, WARN otherwise
			enableConsoleOutput = true,
			enableWarningOutput = true,
			maxErrorHistory = 100,
			enablePerformanceTracking = config.enableDebugPanel,
			showTimestamps = true,
		})
		
		-- Register for error events
		DebugSystem.registerEvent("onError", function(data)
			-- Update UI if debug panel exists
			if debugPanelUI then
				debugPanelUI.refresh()
			end
		end)
		
		DebugSystem.info("DebugSystem initialized successfully")
		return true
	else
		warn("[DAoC Converter] Failed to load DebugSystem, using fallback logging")
		return false
	end
end

-- Fallback logging function when DebugSystem is not available
local function fallbackLog(message, logType)
	local timestamp = DateTime.now():FormatLocalTime("yyyy-mm-dd HH:MM:ss", "en-us")
	local prefix = "[DAoC Converter] "
	
	if logType == "error" then
		warn(prefix .. "[ERROR] " .. message)
	elseif logType == "success" then
		print(prefix .. "[SUCCESS] " .. message)
	else
		print(prefix .. message)
	end
end

-- Unified logging function
local function log(message, logType, context)
	if DebugSystem and DebugSystem._initialized then
		if logType == "error" then
			DebugSystem.error(message, context)
		elseif logType == "success" then
			DebugSystem.info(message .. " [SUCCESS]", context)
		elseif logType == "warn" then
			DebugSystem.warn(message, context)
		else
			DebugSystem.info(message, context)
		end
	else
		fallbackLog(message, logType)
	end
end

--================================================================================
-- UTILITY FUNCTIONS
--================================================================================

local function deepCopy(t)
	if type(t) ~= "table" then return t end
	local copy = {}
	for k, v in pairs(t) do
		copy[k] = deepCopy(v)
	end
	return copy
end

local function sanitizeString(str)
	if not str or type(str) ~= "string" then return "" end
	-- Remove escape sequences and normalize
	str = str:gsub("\\n", "\n")
	str = str:gsub("\\t", "\t")
	str = str:gsub("\\'", "'")
	str = str:gsub('\\"', '"')
	str = str:gsub("\\\\", "\\")
	-- Escape special Lua characters
	str = str:gsub("]", "\\]")
	str = str:gsub("[", "\\[")
	str = str:gsub("{", "\\{")
	str = str:gsub("}", "\\}")
	return str
end

local function trackFileError(fileEntry, errorMessage, errorType)
	-- Track the error through DebugSystem
	if DebugSystem then
		DebugSystem.error(errorMessage, {
			fileName = fileEntry and fileEntry.name or "unknown",
			tableName = fileEntry and fileEntry.tableName or "unknown",
			errorType = errorType or "unknown",
		})
	end
	
	-- Update file entry status
	if fileEntry then
		fileEntry.status = "error"
		fileEntry.error = errorMessage
		fileEntry.errorType = errorType
	end
end

--================================================================================
-- CORE MODULE LOADERS
--================================================================================

local function loadCoreModules()
	log("Loading core modules...")
	
	-- Start performance tracking
	if DebugSystem then
		DebugSystem.performanceMark("loadCoreModules")
	end
	
	local loadErrors = {}
	
	-- Load SQL Parser
	local parserSuccess, parserModule = pcall(function()
		return require(script.Core.SQLParser)
	end)
	
	if parserSuccess and parserModule then
		SQLParser = parserModule
		log("SQL Parser loaded successfully")
	else
		log("Creating SQL Parser module (inline fallback)...")
		SQLParser = {
			parseFile = function(content, tableName)
				local records = {}
				local columns = {}
				
				-- Parse column names from CREATE TABLE statement
				local colMatch = content:match("CREATE TABLE.-%(([^;]+)%)")
				if colMatch then
					for col in colMatch:gmatch("`([^`]+)`") do
						table.insert(columns, col)
					end
				end
				
				-- Parse REPLACE INTO statements
				local valuesStart = content:find("VALUES", 1, true)
				
				if valuesStart then
					local dataPart = content:sub(valuesStart + 6)
					local startPos = 1
					
					while true do
						local tupleStart, tupleEnd = dataPart:find("%(", startPos)
						if not tupleStart then break end
						
						-- Find matching closing parenthesis
						local depth = 1
						local currentPos = tupleEnd + 1
						while depth > 0 and currentPos <= #dataPart do
							local char = dataPart:sub(currentPos, currentPos)
							if char == "(" then
								depth = depth + 1
							elseif char == ")" then
								depth = depth - 1
							end
							currentPos = currentPos + 1
						end
						
						if depth == 0 then
							local tuple = dataPart:sub(tupleStart, currentPos - 1)
							local record = SQLParser.parseValues(tuple, columns)
							if record then
								table.insert(records, record)
							end
							startPos = currentPos
						else
							break
						end
					end
				end
				
				return {
					tableName = tableName,
					columns = columns,
					records = records,
					rowCount = #records,
				}
			end,
			
			parseValues = function(tuple, columns)
				if not tuple or not columns then return nil end
				
				tuple = tuple:match("%((.+)%)") or tuple
				
				local values = {}
				local currentValue = ""
				local inString = false
				local stringChar = nil
				local depth = 0
				
				for i = 1, #tuple do
					local char = tuple:sub(i, i)
					
					if not inString then
						if char == "'" or char == '"' then
							inString = true
							stringChar = char
							currentValue = currentValue .. char
						elseif char == "(" then
							depth = depth + 1
							currentValue = currentValue .. char
						elseif char == ")" then
							depth = depth - 1
							currentValue = currentValue .. char
						elseif char == "," and depth == 0 then
							table.insert(values, currentValue:trim())
							currentValue = ""
						else
							currentValue = currentValue .. char
						end
					else
						currentValue = currentValue .. char
						if char == stringChar then
							if tuple:sub(i + 1, i + 1) ~= stringChar then
								inString = false
							end
						end
					end
				end
				
				if #currentValue > 0 then
					table.insert(values, currentValue:trim())
				end
				
				local record = {}
				for i, colName in ipairs(columns) do
					local rawValue = values[i] or "NULL"
					record[colName] = SQLParser.convertValue(rawValue)
				end
				
				return record
			end,
			
			convertValue = function(rawValue)
				if rawValue == "NULL" or rawValue == "null" then
					return nil
				elseif rawValue:match("^'.*'$") or rawValue:match('^".*"$') then
					local str = rawValue:sub(2, #rawValue - 1)
					str = str:gsub("\\n", "\n")
					str = str:gsub("\\t", "\t")
					str = str:gsub("\\'", "'")
					str = str:gsub('\\"', '"')
					str = str:gsub("\\\\", "\\")
					return str
				elseif rawValue:match("^%d+$") then
					return tonumber(rawValue)
				elseif rawValue:match("^%d+%.%d+$") then
					return tonumber(rawValue)
				elseif rawValue:match("^[+-]?%d+%.?%d*[eE][+-]?%d+$") then
					return tonumber(rawValue)
				else
					local num = tonumber(rawValue)
					if num then return num else return rawValue end
				end
			end,
		}
	end
	
	-- Load Data Converter
	local converterSuccess, converterModule = pcall(function()
		return require(script.Core.DataConverter)
	end)
	
	if converterSuccess and converterModule then
		DataConverter = converterModule
		log("Data Converter loaded successfully")
	else
    log("Creating Data Converter module (inline fallback)...", "warn")
    DataConverter = {
        convertTableData = function(parsedData, options)
            if not parsedData or not parsedData.records then
                log("Invalid parsed data provided", "error")
                return nil
            end
            -- Basic conversion: return parsedData with converted values
            local converted = {
                tableName = parsedData.tableName,
                columns = parsedData.columns,
                rowCount = parsedData.rowCount,
                data = {},
            }
            for i, record in ipairs(parsedData.records) do
                local convertedRecord = {}
                for j, value in ipairs(record) do
                    convertedRecord[j] = value -- basic, no conversion
                end
                table.insert(converted.data, convertedRecord)
            end
            return converted
        end,
        generateLuaTable = function(convertedData, options)
            if not convertedData or not convertedData.data then
                return ""
            end
            local lines = {}
            table.insert(lines, "return {")
            for i, record in ipairs(convertedData.data) do
                table.insert(lines, "  [" .. i .. "] = {")
                for j, value in ipairs(record) do
                    local formatted = tostring(value)
                    if type(value) == "string" then
                        formatted = '"' .. value:gsub('"', '\\"') .. '"'
                    end
                    table.insert(lines, "    " .. formatted .. ",")
                end
                table.insert(lines, "  },")
            end
            table.insert(lines, "}")
            return table.concat(lines, "\n")
        end,
    }
	end
	
	-- Load Export Manager
	success, exporterModule = pcall(function()
		return require(script.Core.ExportManager)
	end)
	
	if success and exporterModule then
		ExportManager = exporterModule
		log("Export Manager loaded successfully", "success")
	else
		log("Creating Export Manager module...")
		ExportManager = {
			exportData = function(convertedData, options, outputPath)
				local success, result = pcall(function()
					local outputFolder = options.outputFolder or "DAoCData"
					
					-- Create output folder if it doesn't exist
					local folder = game:GetService("ServerScriptService"):FindFirstChild(outputFolder)
					if not folder then
						folder = Instance.new("Folder")
						folder.Name = outputFolder
						folder.Parent = game:GetService("ServerScriptService")
					end
					
					-- Generate Lua code
					local luaCode = DataConverter.generateLuaTable(convertedData, options)
					
					-- Create Modulescript
					local moduleName = convertedData.tableName:gsub("%W+", "_")
					
					local existingScript = folder:FindFirstChild(moduleName)
					if existingScript and existingScript:IsA("ModuleScript") then
						existingScript:Destroy()
					end
					
					local module = Instance.new("ModuleScript")
					module.Name = moduleName
					module.Source = luaCode
					module.Parent = folder
					
					return {
						success = true,
						path = outputPath or ("ServerScriptService." .. outputFolder .. "." .. moduleName),
						scriptName = moduleName,
					}
				end)
				
				if success then
					return result
				else
					log("Export failed: " .. tostring(result), "error")
					return { success = false, error = tostring(result) }
				end
			end,
			
			exportToString = function(convertedData, options)
				return DataConverter.generateLuaTable(convertedData, options)
			end,
		}
	end
	
	log("All core modules loaded", "success")
end

--================================================================================
-- UI CREATION
--================================================================================

local function createPluginUI()
	log("Creating plugin UI...")
	
	-- Create toolbar button
	toolbar = plugin:CreateToolbar(PLUGIN_NAME)
	
	local button = toolbar:CreateButton(
		"daoc-converter",
		"Convert DAoC SQL to Roblox",
		"rbxassetid://14847308401",  -- Replace with actual icon
		"DAoC SQL Converter"
	)
	
	button.ClickableWhenViewportHidden = true
	
	-- Create dockable plugin GUI
	pluginGui = plugin:CreateDockWidgetPluginGui(
		PLUGIN_ID,
		DockWidgetPluginGuiInfo.new(
			Enum.InitialDockState.Right,  -- Dock to right side
			false,                        -- Not override enabled
			true,                         -- Refresh rate
			400,                          -- Initial width
			500,                          -- Initial height
			300,                          -- Min width
			400                           -- Min height
		)
	)
	
	pluginGui.Title = PLUGIN_NAME
	pluginGui.Name = "DAoCConverterWidget"
	
	-- Create main frame
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.Position = UDim2.new(0, 0, 0, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	mainFrame.Parent = pluginGui
	
	-- Create title label
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -20, 0, 30)
	titleLabel.Position = UDim2.new(0, 10, 0, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 18
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = "DAoC SQL to Roblox Converter"
	titleLabel.Parent = mainFrame
	
	-- Create drop zone
	dropZone = Instance.new("Frame")
	dropZone.Name = "DropZone"
	dropZone.Size = UDim2.new(1, -20, 0, 120)
	dropZone.Position = UDim2.new(0, 10, 0, 50)
	dropZone.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
	dropZone.BorderColor3 = Color3.fromRGB(100, 100, 100)
	dropZone.BorderSizePixel = 2
	dropZone.Parent = mainFrame
	
	-- Add drop zone label
	local dropLabel = Instance.new("TextLabel")
	dropLabel.Name = "DropLabel"
	dropLabel.Size = UDim2.new(1, 0, 1, 0)
	dropLabel.Position = UDim2.new(0, 0, 0, 0)
	dropLabel.BackgroundTransparency = 1
	dropLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	dropLabel.TextSize = 14
	dropLabel.Font = Enum.Font.SourceSans
	dropLabel.TextXAlignment = Enum.TextXAlignment.Center
	dropLabel.TextYAlignment = Enum.TextYAlignment.Center
	dropLabel.Text = "Drag and drop SQL files here\nor click to browse"
	dropLabel.Parent = dropZone
	
	-- Create file list container
	local fileListContainer = Instance.new("Frame")
	fileListContainer.Name = "FileListContainer"
	fileListContainer.Size = UDim2.new(1, -20, 0, 100)
	fileListContainer.Position = UDim2.new(0, 10, 0, 180)
	fileListContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	fileListContainer.BorderColor3 = Color3.fromRGB(60, 60, 60)
	fileListContainer.Parent = mainFrame
	
	-- Create file list title
	local fileListTitle = Instance.new("TextLabel")
	fileListTitle.Name = "Title"
	fileListTitle.Size = UDim2.new(1, -10, 0, 20)
	fileListTitle.Position = UDim2.new(0, 5, 0, 5)
	fileListTitle.BackgroundTransparency = 1
	fileListTitle.TextColor3 = Color3.fromRGB(180, 180, 180)
	fileListTitle.TextSize = 12
	fileListTitle.Font = Enum.Font.SourceSansBold
	fileListTitle.TextXAlignment = Enum.TextXAlignment.Left
	fileListTitle.Text = "Queued Files:"
	fileListTitle.Parent = fileListContainer
	
	-- Create settings section
	local settingsFrame = Instance.new("Frame")
	settingsFrame.Name = "SettingsFrame"
	settingsFrame.Size = UDim2.new(1, -20, 0, 80)
	settingsFrame.Position = UDim2.new(0, 10, 0, 290)
	settingsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	settingsFrame.Parent = mainFrame
	
	-- Create convert button
	local convertButton = Instance.new("TextButton")
	convertButton.Name = "ConvertButton"
	convertButton.Size = UDim2.new(0, 160, 0, 35)
	convertButton.Position = UDim2.new(0, 10, 0, 380)
	convertButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	convertButton.BorderColor3 = Color3.fromRGB(70, 170, 70)
	convertButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	convertButton.TextSize = 14
	convertButton.Font = Enum.Font.SourceSansBold
	convertButton.Text = "Convert Files"
	convertButton.Parent = mainFrame
	
	-- Create clear button
	local clearButton = Instance.new("TextButton")
	clearButton.Name = "ClearButton"
	clearButton.Size = UDim2.new(0, 80, 0, 35)
	clearButton.Position = UDim2.new(0, 180, 0, 380)
	clearButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	clearButton.BorderColor3 = Color3.fromRGB(170, 70, 70)
	clearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	clearButton.TextSize = 14
	clearButton.Font = Enum.Font.SourceSans
	clearButton.Text = "Clear"
	clearButton.Parent = mainFrame
	
	-- Create status label
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, -20, 0, 25)
	statusLabel.Position = UDim2.new(0, 10, 0, 425)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	statusLabel.TextSize = 12
	statusLabel.Font = Enum.Font.SourceSans
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Text = "Ready - Drag SQL files to convert"
	statusLabel.Parent = mainFrame
	
	-- Create progress bar background
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(1, -20, 0, 15)
	progressBg.Position = UDim2.new(0, 10, 0, 460)
	progressBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	progressBg.Parent = mainFrame
	
	-- Create progress bar fill
	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.Position = UDim2.new(0, 0, 0, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
	progressFill.Parent = progressBg
	
	-- Store references
	mainFrame.ConvertButton = convertButton
	mainFrame.ClearButton = clearButton
	mainFrame.DropZone = dropZone
	mainFrame.StatusLabel = statusLabel
	mainFrame.ProgressFill = progressFill
	mainFrame.FileListContainer = fileListContainer
	
	log("Plugin UI created successfully", "success")
	
	return button
end

--================================================================================
-- FILE HANDLING
--================================================================================

local function addFileToQueue(filePath, fileContent)
	local fileName = filePath:match("([^/\\]+)$") or filePath
	local tableName = fileName:gsub("%.sql$", ""):gsub("%W+", "_")
	
	-- Parse the SQL content
	local parsedData = SQLParser.parseFile(fileContent, tableName)
	
	local fileEntry = {
		path = filePath,
		name = fileName,
		tableName = tableName,
		parsedData = parsedData,
		status = "queued",  -- "queued", "converting", "completed", "error"
	}
	
	table.insert(fileList, fileEntry)
	log(string.format("Added file to queue: %s (%d records)", fileName, parsedData.rowCount))
	
	return fileEntry
end

local function clearFileQueue()
	fileList = {}
	convertedData = {}
	log("File queue cleared")
end

local function updateStatus(message, progress)
	if progress then
		local maxProgress = 370
		local fillWidth = math.min(maxProgress, maxProgress * progress)
		mainFrame.ProgressFill.Size = UDim2.new(0, fillWidth, 1, 0)
	end
	
	mainFrame.StatusLabel.Text = message or "Ready"
end

--================================================================================
-- CONVERSION LOGIC
--================================================================================

local function convertFiles()
	if #fileList == 0 then
		updateStatus("No files to convert", 0)
		return
	end
	
	if isProcessing then
		updateStatus("Already processing...", 0)
		return
	end
	
	isProcessing = true
	updateStatus("Starting conversion...", 0)
	
	for i, fileEntry in ipairs(fileList) do
		fileEntry.status = "converting"
		
		local progress = (i - 1) / #fileList
		updateStatus(string.format("Converting %s...", fileEntry.name), progress)
		
		-- Convert the parsed data
		local options = {
			prettyPrint = config.prettyPrint,
			outputFormat = config.outputFormat,
			outputFolder = config.outputFolder,
		}
		
		local converted = DataConverter.convertTableData(fileEntry.parsedData, options)
		
		if converted then
			-- Export to Roblox
			if config.autoExport then
				local exportResult = ExportManager.exportData(converted, options)
				
				if exportResult.success then
					fileEntry.status = "completed"
					fileEntry.exportedPath = exportResult.path
					log(string.format("Exported %s to %s", fileEntry.name, exportResult.path), "success")
				else
					fileEntry.status = "error"
					fileEntry.error = exportResult.error
					log(string.format("Export failed for %s: %s", fileEntry.name, exportResult.error), "error")
				end
			else
				-- Just store the converted data
				fileEntry.convertedData = converted
				fileEntry.status = "completed"
			end
		else
			fileEntry.status = "error"
			fileEntry.error = "Conversion failed"
			log(string.format("Conversion failed for %s", fileEntry.name), "error")
		end
		
		-- Update progress
		progress = i / #fileList
		updateStatus(string.format("Processed %d/%d files", i, #fileList), progress)
	end
	
	isProcessing = false
	updateStatus(string.format("Conversion complete! %d files processed", #fileList), 1)
	
	-- Fire completion event
	log("All files converted successfully!", "success")
end

--================================================================================
-- PLUGIN LIFECYCLE
--================================================================================

local function init(pluginObj)
	plugin = pluginObj
	
	log("Initializing DAoC SQL to Roblox Converter v" .. VERSION)
	
	-- Load core modules
	loadCoreModules()
	
	-- Create UI
	local button = createPluginUI()
	
	-- Connect button click
	button.Click:Connect(function()
		pluginGui.Enabled = not pluginGui.Enabled
	end)
	
	-- Connect convert button
	mainFrame.ConvertButton.MouseButton1Click:Connect(function()
		convertFiles()
	end)
	
	-- Connect clear button
	mainFrame.ClearButton.MouseButton1Click:Connect(function()
		clearFileQueue()
		updateStatus("Queue cleared", 0)
	end)
	
	-- Connect drop zone events
	dropZone.MouseEnter:Connect(function()
		dropZone.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
		dropZone.BorderColor3 = Color3.fromRGB(150, 150, 150)
	end)
	
	dropZone.MouseLeave:Connect(function()
		dropZone.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
		dropZone.BorderColor3 = Color3.fromRGB(100, 100, 100)
	end)
	
	-- Note: Full drag-and-drop support requires additional implementation
	-- with PluginGui drag and drop APIs
	
	log("Plugin initialized successfully!", "success")
end

-- Initialize when loaded
local success, err = pcall(init, plugin)

if not success then
	log("Plugin initialization failed: " .. tostring(err), "error")
end

-- Export for use by other modules
return {
	plugin = plugin,
	pluginGui = pluginGui,
	convertFiles = convertFiles,
	addFileToQueue = addFileToQueue,
	clearFileQueue = clearFileQueue,
	updateStatus = updateStatus,
}

