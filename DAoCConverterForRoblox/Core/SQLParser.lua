--[[
	DAoC SQL Parser Module
	=======================
	
	This module handles parsing of DAoC SQL files, specifically:
	- CREATE TABLE statements for column definitions
	- REPLACE INTO / INSERT INTO statements for data rows
	- Data type conversion and validation
	
	Supported SQL features:
	- Basic CREATE TABLE syntax
	- REPLACE INTO statements
	- INSERT INTO statements
	- String literals with escape sequences
	- NULL values
	- Numeric values (int, float)
	- Boolean values
	
	Author: DAoC Converter Team
	Version: 1.0.0
--]]

local SQLParser = {}

--================================================================================
-- UTILITY FUNCTIONS
--================================================================================

local function trim(str)
	if not str then return "" end
	return str:gsub("^%s+", ""):gsub("%s+$", "")
end

local function split(str, delimiter)
	local result = {}
	local from = 1
	local delim_from, delim_to = string.find(str, delimiter, from)
	while delim_from do
		table.insert(result, string.sub(str, from, delim_from - 1))
		from = delim_to + 1
		delim_from, delim_to = string.find(str, delimiter, from)
	end
	table.insert(result, string.sub(str, from))
	return result
end

local function log(message, logType)
	local timestamp = DateTime.now():FormatLocalTime("yyyy-mm-dd HH:MM:ss", "en-us")
	local prefix = "[SQL Parser] "
	
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

--================================================================================
-- COLUMN PARSING
--================================================================================

function SQLParser.parseColumnDefinitions(createTableStatement)
	-- Extract column definitions from CREATE TABLE statement
	local columns = {}
	
	-- Find the column definition block
	local colBlock = createTableStatement:match("CREATE TABLE.-%(([^;]+)%)")
	if not colBlock then
		log("Could not find column definitions in CREATE TABLE statement", "error")
		return columns
	end
	
	-- Split by commas, but be careful about nested parentheses
	local colDefs = SQLParser.splitColumns(colBlock)
	
	for _, colDef in ipairs(colDefs) do
		local column = SQLParser.parseColumnDefinition(colDef)
		if column then
			table.insert(columns, column)
		end
	end
	
	log(string.format("Parsed %d columns from CREATE TABLE statement", #columns))
	return columns
end

function SQLParser.splitColumns(colBlock)
	local columns = {}
	local current = ""
	local depth = 0
	local inString = false
	local stringChar = nil
	
	for i = 1, #colBlock do
		local char = colBlock:sub(i, i)
		
		if not inString then
			if char == "'" or char == '"' then
				inString = true
				stringChar = char
			elseif char == "(" then
				depth = depth + 1
			elseif char == ")" then
				depth = depth - 1
			elseif char == "," and depth == 0 then
				-- End of column definition
				local trimmed = trim(current)
				if #trimmed > 0 then
					table.insert(columns, trimmed)
				end
				current = ""
				goto continue
			end
		else
			if char == stringChar then
				-- Check for escaped quote
				if colBlock:sub(i + 1, i + 1) ~= stringChar then
					inString = false
				end
			end
		end
		
		current = current .. char
		::continue::
	end
	
	-- Add the last column
	local trimmed = trim(current)
	if #trimmed > 0 then
		table.insert(columns, trimmed)
	end
	
	return columns
end

function SQLParser.parseColumnDefinition(colDef)
	-- Parse a single column definition like: `AbilityID` int(11) NOT NULL AUTO_INCREMENT
	local column = {}
	
	-- Extract column name (between backticks)
	local colName = colDef:match("`([^`]+)`")
	if not colName then
		return nil
	end
	
	column.name = colName
	
	-- Extract data type
	local typeMatch = colDef:match("`[^`]+`%s+([^%s%(]+)")
	if typeMatch then
		column.type = typeMatch:upper()
		
		-- Extract size for types like VARCHAR(255), INT(11)
		local sizeMatch = colDef:match("%((%d+)%)")
		if sizeMatch then
			column.size = tonumber(sizeMatch)
		end
	end
	
	-- Check for NOT NULL
	if colDef:find("NOT NULL") then
		column.notNull = true
	end
	
	-- Check for AUTO_INCREMENT
	if colDef:find("AUTO_INCREMENT") then
		column.autoIncrement = true
	end
	
	-- Check for DEFAULT value
	local defaultMatch = colDef:match("DEFAULT%s+([^,%s]+)")
	if defaultMatch then
		column.default = SQLParser.convertValue(defaultMatch)
	end
	
	return column
end

--================================================================================
-- DATA PARSING
--================================================================================

function SQLParser.parseFile(content, tableName)
	log(string.format("Parsing SQL file for table: %s", tableName or "unknown"))
	
	local parsedData = {
		tableName = tableName or "unknown",
		columns = {},
		records = {},
		rowCount = 0,
	}
	
	-- Parse column definitions
	local createTableMatch = content:match("CREATE TABLE[^;]+;")
	if createTableMatch then
		parsedData.columns = SQLParser.parseColumnDefinitions(createTableMatch)
	end
	
	-- Parse data rows
	local dataRows = SQLParser.parseDataRows(content)
	parsedData.records = dataRows
	parsedData.rowCount = #dataRows
	
	log(string.format("Parsed %d records for table %s", #dataRows, tableName))
	
	return parsedData
end

function SQLParser.parseDataRows(content)
	local records = {}
	
	-- Find VALUES section
	local valuesStart = content:find("VALUES", 1, true)
	if not valuesStart then
		log("No VALUES section found in SQL content", "error")
		return records
	end
	
	local dataPart = content:sub(valuesStart + 6)
	
	-- Parse individual value tuples
	local tuplePattern = "%(([^()]*)%)"
	local startPos = 1
	
	while true do
		local tupleStart, tupleEnd = dataPart:find("%(", startPos)
		if not tupleStart then break end
		
		-- Find matching closing parenthesis (handle nested parentheses)
		local depth = 1
		local currentPos = tupleEnd + 1
		local tupleContent = "("
		
		while depth > 0 and currentPos <= #dataPart do
			local char = dataPart:sub(currentPos, currentPos)
			tupleContent = tupleContent .. char
			
			if char == "(" then
				depth = depth + 1
			elseif char == ")" then
				depth = depth - 1
			end
			
			currentPos = currentPos + 1
		end
		
		if depth == 0 then
			-- Parse the tuple
			local record = SQLParser.parseValueTuple(tupleContent)
			if record then
				table.insert(records, record)
			end
			
			startPos = currentPos
		else
			break
		end
	end
	
	return records
end

function SQLParser.parseValueTuple(tuple)
	-- Remove outer parentheses
	local content = tuple:match("%((.+)%)")
	if not content then return nil end
	
	local values = {}
	local currentValue = ""
	local inString = false
	local stringChar = nil
	local depth = 0
	
	for i = 1, #content do
		local char = content:sub(i, i)
		
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
				-- End of value
				table.insert(values, trim(currentValue))
				currentValue = ""
			else
				currentValue = currentValue .. char
			end
		else
			currentValue = currentValue .. char
			if char == stringChar then
				-- Check for escaped quote
				if content:sub(i + 1, i + 1) ~= stringChar then
					inString = false
				end
			end
		end
	end
	
	-- Add the last value
	if #currentValue > 0 then
		table.insert(values, trim(currentValue))
	end
	
	-- Convert values to appropriate types
	local record = {}
	for i, rawValue in ipairs(values) do
		record[i] = SQLParser.convertValue(rawValue)
	end
	
	return record
end

function SQLParser.convertValue(rawValue)
	if not rawValue or rawValue == "" then
		return nil
	end
	
	-- Handle NULL values
	if rawValue:upper() == "NULL" then
		return nil
	end
	
	-- Handle string literals
	if rawValue:match("^'.*'$") or rawValue:match('^".*"$') then
		local str = rawValue:sub(2, #rawValue - 1)
		-- Unescape common escape sequences
		str = str:gsub("\\n", "\n")
		str = str:gsub("\\t", "\t")
		str = str:gsub("\\r", "\r")
		str = str:gsub("\\'", "'")
		str = str:gsub('\\"', '"')
		str = str:gsub("\\\\", "\\")
		return str
	end
	
	-- Handle numeric values
	if rawValue:match("^%-?%d+$") then
		return tonumber(rawValue)
	end
	
	if rawValue:match("^%-?%d+%.%d+$") then
		return tonumber(rawValue)
	end
	
	if rawValue:match("^%-?%d+%.?%d*[eE][+-]?%d+$") then
		return tonumber(rawValue)
	end
	
	-- Handle boolean-like values
	if rawValue:upper() == "TRUE" or rawValue:upper() == "FALSE" then
		return rawValue:upper() == "TRUE"
	end
	
	-- Try to convert to number as fallback
	local num = tonumber(rawValue)
	if num then
		return num
	end
	
	-- Return as string if nothing else matches
	return rawValue
end

--================================================================================
-- VALIDATION FUNCTIONS
--================================================================================

function SQLParser.validateParsedData(parsedData)
	local errors = {}
	
	-- Check if we have columns
	if not parsedData.columns or #parsedData.columns == 0 then
		table.insert(errors, "No columns found in CREATE TABLE statement")
	end
	
	-- Check if we have records
	if not parsedData.records or #parsedData.records == 0 then
		table.insert(errors, "No data records found")
		return errors -- Early return if no records
	end
	
	-- Check record consistency
	local expectedColumns = #parsedData.columns
	for i, record in ipairs(parsedData.records) do
		local recordColumns = 0
		for _ in pairs(record) do
			recordColumns = recordColumns + 1
		end
		
		if recordColumns ~= expectedColumns then
			table.insert(errors, string.format("Record %d has %d columns, expected %d", i, recordColumns, expectedColumns))
		end
	end
	
	return errors
end

--================================================================================
-- EXPORT FUNCTIONS
--================================================================================

function SQLParser.getColumnNames(parsedData)
	local names = {}
	for _, column in ipairs(parsedData.columns) do
		table.insert(names, column.name)
	end
	return names
end

function SQLParser.getColumnTypes(parsedData)
	local types = {}
	for _, column in ipairs(parsedData.columns) do
		types[column.name] = column.type
	end
	return types
end

return SQLParser
