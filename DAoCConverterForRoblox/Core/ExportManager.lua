--[[
	DAoC Export Manager Module
	===========================
	
	This module handles exporting converted DAoC data to Roblox formats.
	It creates Modulescripts, handles file organization, and manages
	the export process with progress tracking and error handling.
	
	Supported export formats:
	- Roblox Modulescripts (.lua files)
	- Organized folder structure
	- Automatic naming and organization
	
	Author: DAoC Converter Team
	Version: 1.0.0
--]]

local ExportManager = {}

--================================================================================
-- CONSTANTS AND CONFIGURATION
--================================================================================

local DEFAULT_EXPORT_FOLDER = "DAoCData"
local MAX_MODULE_NAME_LENGTH = 50
local RESERVED_LUA_KEYWORDS = {
	["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true,
	["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true,
	["function"] = true, ["if"] = true, ["in"] = true, ["local"] = true,
	["nil"] = true, ["not"] = true, ["or"] = true, ["repeat"] = true,
	["return"] = true, ["then"] = true, ["true"] = true, ["until"] = true,
	["while"] = true
}

--================================================================================
-- UTILITY FUNCTIONS
--================================================================================

local function log(message, logType)
	local timestamp = DateTime.now():FormatLocalTime("yyyy-mm-dd HH:MM:ss", "en-us")
	local prefix = "[Export Manager] "
	
	if logType == "error" then
		prefix = prefix .. "[ERROR] "
		warn(prefix .. message)
	elseif logType == "success" then
		prefix = prefix .. "[SUCCESS] "
		print(prefix .. message)
	else
		print(prefix .. message)
	end
end

local function sanitizeModuleName(name)
	if not name or name == "" then return "UnknownTable" end
	
	-- Remove file extension if present
	name = name:gsub("%.sql$", ""):gsub("%.lua$", "")
	
	-- Replace invalid characters with underscores
	name = name:gsub("[^%w_]", "_")
	
	-- Remove leading/trailing underscores
	name = name:gsub("^_+", ""):gsub("_+$", "")
	
	-- Ensure it doesn't start with a number
	if name:match("^%d") then
		name = "_" .. name
	end
	
	-- Check for reserved keywords
	if RESERVED_LUA_KEYWORDS[name:lower()] then
		name = name .. "_Table"
	end
	
	-- Truncate if too long
	if #name > MAX_MODULE_NAME_LENGTH then
		name = name:sub(1, MAX_MODULE_NAME_LENGTH - 3) .. "..."
	end
	
	-- Ensure it's not empty after sanitization
	if name == "" then
		name = "Table_" .. tostring(tick()):gsub("%.", "_")
	end
	
	return name
end

local function createFolderStructure(baseFolder, subFolders)
	local currentFolder = baseFolder
	
	for _, folderName in ipairs(subFolders) do
		local existingFolder = currentFolder:FindFirstChild(folderName)
		if not existingFolder or not existingFolder:IsA("Folder") then
			if existingFolder then
				existingFolder:Destroy()
			end
			local newFolder = Instance.new("Folder")
			newFolder.Name = folderName
			newFolder.Parent = currentFolder
			currentFolder = newFolder
		else
			currentFolder = existingFolder
		end
	end
	
	return currentFolder
end

--================================================================================
-- EXPORT FUNCTIONS
--================================================================================

function ExportManager.exportData(convertedData, options, outputPath)
	if not convertedData or not convertedData.data then
		log("Invalid converted data provided", "error")
		return { success = false, error = "Invalid converted data" }
	end
	
	options = options or {}
	local outputFolder = options.outputFolder or DEFAULT_EXPORT_FOLDER
	local outputFormat = options.outputFormat or "Modulescript"
	
	log(string.format("Exporting %s to Roblox (%s format)", convertedData.tableName, outputFormat))
	
	local success, result = pcall(function()
		-- Determine export location
		local exportLocation = ExportManager.getExportLocation(outputFolder)
		
		-- Generate module name
		local moduleName = sanitizeModuleName(convertedData.tableName)
		
		-- Generate Lua code
		local luaCode = ExportManager.generateModuleCode(convertedData, options)
		
		-- Create the Modulescript
		local moduleScript = ExportManager.createModuleScript(exportLocation, moduleName, luaCode)
		
		-- Return success information
		return {
			success = true,
			moduleName = moduleName,
			path = exportLocation:GetFullName() .. "." .. moduleName,
			script = moduleScript,
			recordCount = convertedData.rowCount,
		}
	end)
	
	if success then
		log(string.format("Successfully exported %s (%d records)", result.moduleName, result.recordCount), "success")
		return result
	else
		local errorMsg = "Export failed: " .. tostring(result)
		log(errorMsg, "error")
		return { success = false, error = errorMsg }
	end
end

function ExportManager.exportToString(convertedData, options)
	if not convertedData then
		return ""
	end
	
	options = options or {}
	return ExportManager.generateModuleCode(convertedData, options)
end

function ExportManager.getExportLocation(outputFolder)
	-- Default to ServerScriptService for data modules
	local baseLocation = game:GetService("ServerScriptService")
	
	-- Create or find the output folder
	local exportFolder = baseLocation:FindFirstChild(outputFolder)
	if not exportFolder then
		exportFolder = Instance.new("Folder")
		exportFolder.Name = outputFolder
		exportFolder.Parent = baseLocation
		log(string.format("Created export folder: %s", outputFolder))
	end
	
	return exportFolder
end

function ExportManager.createModuleScript(parentFolder, moduleName, sourceCode)
	-- Remove existing script if it exists
	local existingScript = parentFolder:FindFirstChild(moduleName)
	if existingScript and existingScript:IsA("ModuleScript") then
		existingScript:Destroy()
	end
	
	-- Create new Modulescript
	local moduleScript = Instance.new("ModuleScript")
	moduleScript.Name = moduleName
	moduleScript.Source = sourceCode
	moduleScript.Parent = parentFolder
	
	log(string.format("Created Modulescript: %s", moduleName))
	
	return moduleScript
end

--================================================================================
-- CODE GENERATION
--================================================================================

function ExportManager.generateModuleCode(convertedData, options)
	options = options or {}
	local prettyPrint = options.prettyPrint ~= false
	local includeMetadata = options.includeMetadata ~= false
	
	local lines = {}
	local indent = prettyPrint and "    " or ""
	
	-- Header comments
	if includeMetadata then
		table.insert(lines, "--[[")
		table.insert(lines, string.format("    %s Data Module", convertedData.tableName))
		table.insert(lines, string.format("    Auto-generated by DAoC SQL to Roblox Converter"))
		table.insert(lines, string.format("    Generated: %s", DateTime.now():FormatLocalTime("yyyy-mm-dd HH:MM:ss", "en-us")))
		table.insert(lines, string.format("    Records: %d", convertedData.rowCount))
		table.insert(lines, string.format("    Columns: %d", #convertedData.columns))
		table.insert(lines, "--]]")
		table.insert(lines, "")
	end
	
	-- Module structure
	table.insert(lines, "local " .. convertedData.tableName .. " = {}")
	table.insert(lines, "")
	
	-- Add metadata if requested
	if includeMetadata then
		table.insert(lines, "-- Module metadata")
		table.insert(lines, convertedData.tableName .. ".Metadata = {")
		table.insert(lines, indent .. "TableName = \"" .. convertedData.tableName .. "\",")
		table.insert(lines, indent .. "RecordCount = " .. convertedData.rowCount .. ",")
		table.insert(lines, indent .. "ColumnCount = " .. #convertedData.columns .. ",")
		table.insert(lines, indent .. "GeneratedAt = \"" .. DateTime.now():FormatLocalTime("yyyy-mm-dd HH:MM:ss", "en-us") .. "\",")
		table.insert(lines, "}")
		table.insert(lines, "")
	end
	
	-- Data table
	table.insert(lines, "-- Converted data")
	table.insert(lines, convertedData.tableName .. ".Data = {")
	
	-- Generate data entries
	for i, record in ipairs(convertedData.data) do
		table.insert(lines, indent .. "[" .. i .. "] = {")
		
		-- Sort keys for consistent output
		local keys = {}
		for k in pairs(record) do
			table.insert(keys, k)
		end
		table.sort(keys)
		
		-- Generate key-value pairs
		for j, key in ipairs(keys) do
			local value = record[key]
			local valueStr = ExportManager.formatLuaValue(value)
			
			local line = indent .. indent .. key .. " = " .. valueStr
			if j < #keys then
				line = line .. ","
			end
			table.insert(lines, line)
		end
		
		local closing = indent .. "},"
		if i == #convertedData.data then
			closing = indent .. "}"
		end
		table.insert(lines, closing)
	end
	
	table.insert(lines, "}")
	table.insert(lines, "")
	
	-- Helper functions
	table.insert(lines, "-- Helper functions")
	table.insert(lines, "function " .. convertedData.tableName .. ".GetRecord(index)")
	table.insert(lines, indent .. "return self.Data[index]")
	table.insert(lines, "end")
	table.insert(lines, "")
	
	table.insert(lines, "function " .. convertedData.tableName .. ".GetRecordCount()")
	table.insert(lines, indent .. "return " .. convertedData.rowCount)
	table.insert(lines, "end")
	table.insert(lines, "")
	
	table.insert(lines, "function " .. convertedData.tableName .. ".FindByField(fieldName, value)")
	table.insert(lines, indent .. "local results = {}")
	table.insert(lines, indent .. "for i, record in ipairs(self.Data) do")
	table.insert(lines, indent .. indent .. "if record[fieldName] == value then")
	table.insert(lines, indent .. indent .. indent .. "table.insert(results, {index = i, record = record})")
	table.insert(lines, indent .. indent .. "end")
	table.insert(lines, indent .. "end")
	table.insert(lines, indent .. "return results")
	table.insert(lines, "end")
	table.insert(lines, "")
	
	-- Return statement
	table.insert(lines, "return " .. convertedData.tableName)
	
	-- Join lines
	local separator = prettyPrint and "\n" or ""
	return table.concat(lines, separator)
end

function ExportManager.formatLuaValue(value)
	if value == nil then
		return "nil"
	elseif type(value) == "string" then
		-- Escape special characters
		local escaped = value:gsub("\\", "\\\\")
		escaped = escaped:gsub("\"", "\\\"")
		escaped = escaped:gsub("\n", "\\n")
		escaped = escaped:gsub("\r", "\\r")
		escaped = escaped:gsub("\t", "\\t")
		return "\"" .. escaped .. "\""
	elseif type(value) == "number" then
		if value == math.huge then
			return "math.huge"
		elseif value == -math.huge then
			return "-math.huge"
		elseif value ~= value then -- NaN
			return "0/0"
		else
			return tostring(value)
		end
	elseif type(value) == "boolean" then
		return tostring(value)
	elseif type(value) == "table" then
		-- Simple table serialization
		local parts = {}
		for k, v in pairs(value) do
			local keyStr = type(k) == "string" and ("\"" .. k .. "\"") or tostring(k)
			local valueStr = ExportManager.formatLuaValue(v)
			table.insert(parts, keyStr .. " = " .. valueStr)
		end
		return "{" .. table.concat(parts, ", ") .. "}"
	else
		return "\"" .. tostring(value) .. "\""
	end
end

--================================================================================
-- BATCH EXPORT FUNCTIONS
--================================================================================

function ExportManager.exportMultipleTables(tableList, options, progressCallback)
	if not tableList or #tableList == 0 then
		return { success = false, error = "No tables to export" }
	end
	
	options = options or {}
	local results = {
		success = true,
		exportedTables = {},
		failedTables = {},
		totalTables = #tableList,
	}
	
	log(string.format("Starting batch export of %d tables", #tableList))
	
	for i, convertedData in ipairs(tableList) do
		if progressCallback then
			progressCallback(i, #tableList, convertedData.tableName)
		end
		
		local exportResult = ExportManager.exportData(convertedData, options)
		
		if exportResult.success then
			table.insert(results.exportedTables, exportResult)
		else
			table.insert(results.failedTables, {
				tableName = convertedData.tableName,
				error = exportResult.error
			})
			results.success = false
		end
	end
	
	log(string.format("Batch export complete: %d successful, %d failed", 
		#results.exportedTables, #results.failedTables))
	
	return results
end

--================================================================================
-- VALIDATION FUNCTIONS
--================================================================================

function ExportManager.validateExportLocation(location)
	if not location or not location:IsA("Folder") then
		return false, "Invalid export location"
	end
	
	-- Check if we can create scripts in this location
	local testScript = Instance.new("ModuleScript")
	testScript.Name = "ExportTest"
	
	local success = pcall(function()
		testScript.Parent = location
	end)
	
	if success then
		testScript:Destroy()
		return true
	else
		return false, "Cannot create scripts in export location"
	end
end

function ExportManager.validateModuleName(name)
	if not name or name == "" then
		return false, "Module name cannot be empty"
	end
	
	if name:match("^%d") then
		return false, "Module name cannot start with a number"
	end
	
	if RESERVED_LUA_KEYWORDS[name:lower()] then
		return false, "Module name cannot be a Lua reserved keyword"
	end
	
	if #name > MAX_MODULE_NAME_LENGTH then
		return false, "Module name is too long"
	end
	
	return true
end

--================================================================================
-- CLEANUP FUNCTIONS
--================================================================================

function ExportManager.cleanupExportFolder(folderName)
	local baseLocation = game:GetService("ServerScriptService")
	local exportFolder = baseLocation:FindFirstChild(folderName)
	
	if exportFolder then
		local success = pcall(function()
			exportFolder:Destroy()
		end)
		
		if success then
			log(string.format("Cleaned up export folder: %s", folderName))
			return true
		else
			log(string.format("Failed to cleanup export folder: %s", folderName), "error")
			return false
		end
	end
	
	return true -- Folder didn't exist, so cleanup is successful
end

return ExportManager
