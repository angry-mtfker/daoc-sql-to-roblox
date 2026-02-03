--[[
	DAoC Data Converter Module
	===========================
	
	This module handles the conversion of parsed SQL data to Roblox Lua formats.
	It performs data type mapping, validation, and formatting for output.
	
	Supported conversions:
	- SQL data types to Lua types
	- String escaping and sanitization
	- Boolean conversion
	- Numeric validation
	- Table structure generation
	
	Author: DAoC Converter Team
	Version: 1.0.0
--]]

local DataConverter = {}

--================================================================================
-- TYPE MAPPING CONSTANTS
--================================================================================

local SQL_TO_LUA_TYPES = {
	-- Integer types
	["INT"] = "number",
	["INTEGER"] = "number",
	["TINYINT"] = "number",
	["SMALLINT"] = "number",
	["MEDIUMINT"] = "number",
	["BIGINT"] = "number",
	
	-- Floating point types
	["FLOAT"] = "number",
	["DOUBLE"] = "number",
	["DECIMAL"] = "number",
	["NUMERIC"] = "number",
	
	-- String types
	["VARCHAR"] = "string",
	["CHAR"] = "string",
	["TEXT"] = "string",
	["TINYTEXT"] = "string",
	["MEDIUMTEXT"] = "string",
	["LONGTEXT"] = "string",
	
	-- Date/Time types (converted to strings)
	["DATE"] = "string",
	["TIME"] = "string",
	["DATETIME"] = "string",
	["TIMESTAMP"] = "string",
	
	-- Boolean types
	["BOOL"] = "boolean",
	["BOOLEAN"] = "boolean",
	
	-- Binary types (converted to strings)
	["BLOB"] = "string",
	["TINYBLOB"] = "string",
	["MEDIUMBLOB"] = "string",
	["LONGBLOB"] = "string",
}

--================================================================================
-- UTILITY FUNCTIONS
--================================================================================

local function log(message, logType)
	local timestamp = DateTime.now():FormatLocalTime("yyyy-mm-dd HH:MM:ss", "en-us")
	local prefix = "[Data Converter] "
	
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

local function sanitizeString(str)
	if not str or type(str) ~= "string" then return "" end
	
	-- Remove or replace problematic characters
	str = str:gsub("\\", "\\\\")  -- Escape backslashes first
	str = str:gsub("\"", "\\\"")  -- Escape quotes
	str = str:gsub("'", "\\'")    -- Escape single quotes
	str = str:gsub("\n", "\\n")   -- Escape newlines
	str = str:gsub("\r", "\\r")   -- Escape carriage returns
	str = str:gsub("\t", "\\t")   -- Escape tabs
	
	-- Remove null bytes and other control characters
	str = str:gsub("%z", "")
	str = str:gsub("[\0-\31]", "")
	
	return str
end

local function deepCopy(t)
	if type(t) ~= "table" then return t end
	local copy = {}
	for k, v in pairs(t) do
		copy[k] = deepCopy(v)
	end
	return copy
end

--================================================================================
-- DATA CONVERSION FUNCTIONS
--================================================================================

function DataConverter.convertTableData(parsedData, options)
	if not parsedData or not parsedData.records then
		log("Invalid parsed data provided", "error")
		return nil
	end
	
	log(string.format("Converting table data for %s (%d records)", parsedData.tableName, parsedData.rowCount))
	
	local convertedData = {
		tableName = parsedData.tableName,
		columns = deepCopy(parsedData.columns),
		rowCount = parsedData.rowCount,
		data = {},
		conversionStats = {
			totalRecords = parsedData.rowCount,
			convertedRecords = 0,
			errors = 0,
		}
	}
	
	-- Convert each record
	for i, record in ipairs(parsedData.records) do
		local convertedRecord = DataConverter.convertRecord(record, parsedData.columns, options)
		
		if convertedRecord then
			table.insert(convertedData.data, convertedRecord)
			convertedData.conversionStats.convertedRecords = convertedData.conversionStats.convertedRecords + 1
		else
			convertedData.conversionStats.errors = convertedData.conversionStats.errors + 1
		end
	end
	
	log(string.format("Conversion complete: %d/%d records converted", 
		convertedData.conversionStats.convertedRecords, 
		convertedData.conversionStats.totalRecords))
	
	return convertedData
end

function DataConverter.convertRecord(record, columns, options)
	if not record then return nil end
	
	local convertedRecord = {}
	local hasErrors = false
	
	-- Convert each field in the record
	for i, value in ipairs(record) do
		local column = columns[i]
		if column then
			local fieldName = column.name
			local convertedValue = DataConverter.convertValue(value, column, options)
			convertedRecord[fieldName] = convertedValue
		else
			log(string.format("No column definition for field %d", i), "error")
			hasErrors = true
		end
	end
	
	return hasErrors and nil or convertedRecord
end

function DataConverter.convertValue(value, column, options)
	if value == nil then
		-- Handle NULL values
		if column and column.notNull then
			-- For NOT NULL columns, provide default values
			return DataConverter.getDefaultValue(column)
		else
			return nil
		end
	end
	
	local valueType = type(value)
	
	-- Convert based on SQL column type
	if column and column.type then
		local luaType = SQL_TO_LUA_TYPES[column.type]
		
		if luaType == "number" then
			if valueType == "number" then
				return value
			elseif valueType == "string" then
				local num = tonumber(value)
				return num or 0
			else
				return 0
			end
		elseif luaType == "string" then
			if valueType == "string" then
				return sanitizeString(value)
			else
				return tostring(value)
			end
		elseif luaType == "boolean" then
			if valueType == "boolean" then
				return value
			elseif valueType == "number" then
				return value ~= 0
			elseif valueType == "string" then
				local lower = value:lower()
				return lower == "true" or lower == "1" or lower == "yes"
			else
				return false
			end
		end
	end
	
	-- Fallback conversion based on Lua type
	if valueType == "string" then
		return sanitizeString(value)
	elseif valueType == "number" then
		return value
	elseif valueType == "boolean" then
		return value
	else
		return tostring(value)
	end
end

function DataConverter.getDefaultValue(column)
	if not column then return nil end
	
	-- Return explicit default if specified
	if column.default ~= nil then
		return column.default
	end
	
	-- Return type-appropriate defaults
	local luaType = SQL_TO_LUA_TYPES[column.type] or "string"
	
	if luaType == "number" then
		return 0
	elseif luaType == "boolean" then
		return false
	elseif luaType == "string" then
		return ""
	else
		return nil
	end
end

--================================================================================
-- LUA CODE GENERATION
--================================================================================

function DataConverter.generateLuaTable(convertedData, options)
	if not convertedData or not convertedData.data then
		log("Invalid converted data provided", "error")
		return ""
	end
	
	options = options or {}
	local prettyPrint = options.prettyPrint ~= false
	local indentSize = prettyPrint and 4 or 0
	
	log(string.format("Generating Lua table for %s", convertedData.tableName))
	
	local lines = {}
	local indent = string.rep(" ", indentSize)
	
	-- Header comments
	table.insert(lines, "--[[")
	table.insert(lines, string.format("    %s Data - Converted from DAoC SQL", convertedData.tableName))
	table.insert(lines, string.format("    Generated: %s", DateTime.now():FormatLocalTime("yyyy-mm-dd HH:MM:ss", "en-us")))
	table.insert(lines, string.format("    Records: %d", convertedData.rowCount))
	table.insert(lines, string.format("    Source: DAoC SQL to Roblox Converter v1.0.0"))
	table.insert(lines, "--]]")
	table.insert(lines, "")
	
	-- Module return statement
	table.insert(lines, "return {")
	
	-- Generate data entries
	for i, record in ipairs(convertedData.data) do
		table.insert(lines, string.format("%s[%d] = {", indent, i))
		
		-- Sort keys for consistent output
		local keys = {}
		for k in pairs(record) do
			table.insert(keys, k)
		end
		table.sort(keys)
		
		-- Generate key-value pairs
		for j, key in ipairs(keys) do
			local value = record[key]
			local valueStr = DataConverter.formatLuaValue(value, prettyPrint)
			
			local line = string.format("%s%s%s = %s", 
				indent, indent, key, valueStr)
			
			if j < #keys then
				line = line .. ","
			end
			
			table.insert(lines, line)
		end
		
		local closing = string.format("%s},", indent)
		if i == #convertedData.data then
			closing = string.format("%s}", indent)
		end
		table.insert(lines, closing)
	end
	
	table.insert(lines, "}")
	
	local result = table.concat(lines, prettyPrint and "\n" or "")
	log(string.format("Generated Lua table with %d lines", #lines))
	
	return result
end

function DataConverter.formatLuaValue(value, prettyPrint)
	if value == nil then
		return "nil"
	elseif type(value) == "string" then
		-- Escape the string for Lua
		local escaped = value:gsub("\\", "\\\\")
		escaped = escaped:gsub("\"", "\\\"")
		escaped = escaped:gsub("\n", "\\n")
		escaped = escaped:gsub("\r", "\\r")
		escaped = escaped:gsub("\t", "\\t")
		return string.format("\"%s\"", escaped)
	elseif type(value) == "number" then
		-- Handle special number cases
		if value == math.huge then
			return "math.huge"
		elseif value == -math.huge then
			return "-math.huge"
		elseif value ~= value then -- NaN check
			return "0/0"
		else
			return tostring(value)
		end
	elseif type(value) == "boolean" then
		return tostring(value)
	elseif type(value) == "table" then
		-- Simple table serialization (for nested data)
		local parts = {}
		for k, v in pairs(value) do
			local keyStr = type(k) == "string" and string.format("\"%s\"", k) or tostring(k)
			local valueStr = DataConverter.formatLuaValue(v, prettyPrint)
			table.insert(parts, string.format("%s = %s", keyStr, valueStr))
		end
		return string.format("{%s}", table.concat(parts, ", "))
	else
		-- Fallback for other types
		return string.format("\"%s\"", tostring(value))
	end
end

--================================================================================
-- VALIDATION FUNCTIONS
--================================================================================

function DataConverter.validateConvertedData(convertedData)
	local errors = {}
	
	if not convertedData then
		table.insert(errors, "Converted data is nil")
		return errors
	end
	
	if not convertedData.data or #convertedData.data == 0 then
		table.insert(errors, "No data records found")
	end
	
	if not convertedData.tableName or convertedData.tableName == "" then
		table.insert(errors, "Invalid table name")
	end
	
	-- Check for data consistency
	local firstRecord = convertedData.data[1]
	if firstRecord then
		local expectedKeys = {}
		for k in pairs(firstRecord) do
			table.insert(expectedKeys, k)
		end
		table.sort(expectedKeys)
		
		for i, record in ipairs(convertedData.data) do
			local recordKeys = {}
			for k in pairs(record) do
				table.insert(recordKeys, k)
			end
			table.sort(recordKeys)
			
			if #recordKeys ~= #expectedKeys then
				table.insert(errors, string.format("Record %d has different number of fields", i))
			else
				for j, key in ipairs(expectedKeys) do
					if recordKeys[j] ~= key then
						table.insert(errors, string.format("Record %d has mismatched field names", i))
						break
					end
				end
			end
		end
	end
	
	return errors
end

--================================================================================
-- STATISTICS FUNCTIONS
--================================================================================

function DataConverter.generateConversionStats(convertedData)
	local stats = {
		tableName = convertedData.tableName,
		totalRecords = convertedData.rowCount,
		convertedRecords = #convertedData.data,
		errorRecords = convertedData.conversionStats.errors,
		columns = #convertedData.columns,
	}
	
	-- Calculate data type distribution
	stats.dataTypes = {}
	for _, record in ipairs(convertedData.data) do
		for key, value in pairs(record) do
			local valueType = type(value)
			stats.dataTypes[valueType] = (stats.dataTypes[valueType] or 0) + 1
		end
	end
	
	return stats
end

return DataConverter
