--[[
	DAoC Debug System Module
	========================
	
	Centralized debugging and error handling system for the DAoC SQL to Roblox Converter.
	Provides structured logging, error tracking, performance monitoring, and UI feedback.
	
	Features:
	- Multiple log levels (DEBUG, INFO, WARN, ERROR, CRITICAL)
	- Error event system for UI integration
	- Performance tracking
	- Error history buffer
	- Debug mode toggle
	- Session-based error reporting
	
	Author: DAoC Converter Team
	Version: 1.0.0
--]]

local DebugSystem = {}

--================================================================================
-- CONSTANTS AND CONFIGURATION
--================================================================================

local LOG_LEVELS = {
	DEBUG = 1,
	INFO = 2,
	WARN = 3,
	ERROR = 4,
	CRITICAL = 5,
}

local LOG_LEVEL_NAMES = {
	[1] = "DEBUG",
	[2] = "INFO",
	[3] = "WARN",
	[4] = "ERROR",
	[5] = "CRITICAL",
}

local DEFAULT_CONFIG = {
	logLevel = LOG_LEVELS.INFO,
	enableConsoleOutput = true,
	enableWarningOutput = true,
	maxErrorHistory = 100,
	enablePerformanceTracking = false,
	showTimestamps = true,
}

--================================================================================
-- STATE MANAGEMENT
--================================================================================

DebugSystem._config = table.clone(DEFAULT_CONFIG)
DebugSystem._errorHistory = {}
DebugSystem._eventCallbacks = {}
DebugSystem._performanceMarks = {}
DebugSystem._sessionId = nil
DebugSystem._initialized = false
DebugSystem._errorCount = {
	total = 0,
	warnings = 0,
	errors = 0,
	critical = 0,
}

--================================================================================
-- INITIALIZATION
--================================================================================

function DebugSystem.init(options)
	if DebugSystem._initialized then
		DebugSystem.warn("DebugSystem already initialized")
		return
	end
	
	DebugSystem._config = table.merge(DebugSystem._config, options or {})
	DebugSystem._sessionId = tostring(tick()):gsub("%.", "_")
	DebugSystem._errorHistory = {}
	DebugSystem._errorCount = {
		total = 0,
		warnings = 0,
		errors = 0,
		critical = 0,
	}
	
	DebugSystem._initialized = true
	
	DebugSystem.info(string.format("DebugSystem initialized (Session: %s)", DebugSystem._sessionId))
end

function DebugSystem.reset()
	DebugSystem._errorHistory = {}
	DebugSystem._performanceMarks = {}
	DebugSystem._sessionId = tostring(tick()):gsub("%.", "_")
	DebugSystem._errorCount = {
		total = 0,
		warnings = 0,
		errors = 0,
		critical = 0,
	}
	
	DebugSystem.info("DebugSystem reset complete")
end

--================================================================================
-- CONFIGURATION
--================================================================================

function DebugSystem.setLogLevel(level)
	if type(level) == "string" then
		level = LOG_LEVELS[level:upper()] or LOG_LEVELS.INFO
	end
	DebugSystem._config.logLevel = level
end

function DebugSystem.getLogLevel()
	return LOG_LEVEL_NAMES[DebugSystem._config.logLevel] or "UNKNOWN"
end

function DebugSystem.setConfig(key, value)
	if DebugSystem._config[key] ~= nil then
		DebugSystem._config[key] = value
	end
end

function DebugSystem.getConfig(key)
	return DebugSystem._config[key]
end

--================================================================================
-- CORE LOGGING FUNCTIONS
--================================================================================

function DebugSystem.debug(message, context)
	DebugSystem._log(LOG_LEVELS.DEBUG, message, context)
end

function DebugSystem.info(message, context)
	DebugSystem._log(LOG_LEVELS.INFO, message, context)
end

function DebugSystem.warn(message, context)
	DebugSystem._log(LOG_LEVELS.WARN, message, context)
end

function DebugSystem.error(message, context)
	DebugSystem._log(LOG_LEVELS.ERROR, message, context)
end

function DebugSystem.critical(message, context)
	DebugSystem._log(LOG_LEVELS.CRITICAL, message, context)
end

function DebugSystem._log(level, message, context)
	if level < DebugSystem._config.logLevel then
		return
	end
	
	local timestamp = DebugSystem._config.showTimestamps 
		and DateTime.now():FormatLocalTime("yyyy-mm-dd HH:MM:ss", "en-us")
		or ""
	
	local levelName = LOG_LEVEL_NAMES[level] or "UNKNOWN"
	local prefix = "[DAoC-DBG]"
	
	if timestamp ~= "" then
		prefix = string.format("%s [%s] [%s]", prefix, timestamp, levelName)
	else
		prefix = string.format("%s [%s]", prefix, levelName)
	end
	
	local fullMessage = message
	if context then
		if type(context) == "table" then
			local contextStr = DebugSystem._formatContext(context)
			fullMessage = string.format("%s | Context: %s", message, contextStr)
		else
			fullMessage = string.format("%s | %s", message, tostring(context))
		end
	end
	
	-- Console output
	if DebugSystem._config.enableConsoleOutput then
		if level >= LOG_LEVELS.ERROR then
			warn(prefix .. " " .. fullMessage)
		else
			print(prefix .. " " .. fullMessage)
		end
	end
	
	-- Warning output
	if level == LOG_LEVELS.WARN and DebugSystem._config.enableWarningOutput then
		warn(prefix .. " " .. fullMessage)
	end
	
	-- Track error counts
	if level >= LOG_LEVELS.WARN then
		DebugSystem._errorCount.total = DebugSystem._errorCount.total + 1
		if level == LOG_LEVELS.WARN then
			DebugSystem._errorCount.warnings = DebugSystem._errorCount.warnings + 1
		elseif level == LOG_LEVELS.ERROR then
			DebugSystem._errorCount.errors = DebugSystem._errorCount.errors + 1
		elseif level == LOG_LEVELS.CRITICAL then
			DebugSystem._errorCount.critical = DebugSystem._errorCount.critical + 1
		end
		
		-- Add to error history
		DebugSystem._addToHistory({
			level = levelName,
			message = fullMessage,
			timestamp = timestamp,
			context = context,
			sessionId = DebugSystem._sessionId,
		})
		
		-- Fire event callbacks
		DebugSystem._fireEvent("onLog", {
			level = levelName,
			message = message,
			context = context,
			timestamp = timestamp,
		})
		
		if level >= LOG_LEVELS.ERROR then
			DebugSystem._fireEvent("onError", {
				level = levelName,
				message = message,
				context = context,
				timestamp = timestamp,
			})
		end
	end
end

function DebugSystem._formatContext(context)
	local parts = {}
	for k, v in pairs(context) do
		local valueStr
		if type(v) == "table" then
			valueStr = "{table}"
		elseif type(v) == "string" then
			valueStr = string.format('"%s"', v)
		else
			valueStr = tostring(v)
		end
		table.insert(parts, string.format("%s=%s", tostring(k), valueStr))
	end
	return table.concat(parts, ", ")
end

--================================================================================
-- ERROR HISTORY
--================================================================================

function DebugSystem._addToHistory(entry)
	local maxHistory = DebugSystem._config.maxErrorHistory
	
	if #DebugSystem._errorHistory >= maxHistory then
		table.remove(DebugSystem._errorHistory, 1)
	end
	
	table.insert(DebugSystem._errorHistory, entry)
end

function DebugSystem.getErrorHistory(filterLevel, limit)
	local history = DebugSystem._errorHistory
	local result = {}
	
	for i, entry in ipairs(history) do
		if not filterLevel or entry.level == filterLevel then
			table.insert(result, entry)
			if limit and #result >= limit then
				break
			end
		end
	end
	
	return result
end

function DebugSystem.getErrorCount()
	return table.clone(DebugSystem._errorCount)
end

function DebugSystem.clearErrorHistory()
	DebugSystem._errorHistory = {}
	DebugSystem._errorCount = {
		total = 0,
		warnings = 0,
		errors = 0,
		critical = 0,
	}
end

--================================================================================
-- EVENT SYSTEM
--================================================================================

function DebugSystem.registerEvent(eventName, callback)
	if not DebugSystem._eventCallbacks[eventName] then
		DebugSystem._eventCallbacks[eventName] = {}
	end
	table.insert(DebugSystem._eventCallbacks[eventName], callback)
end

function DebugSystem.unregisterEvent(eventName, callback)
	if DebugSystem._eventCallbacks[eventName] then
		for i, cb in ipairs(DebugSystem._eventCallbacks[eventName]) do
			if cb == callback then
				table.remove(DebugSystem._eventCallbacks[eventName], i)
				return
			end
		end
	end
end

function DebugSystem._fireEvent(eventName, data)
	if DebugSystem._eventCallbacks[eventName] then
		for _, callback in ipairs(DebugSystem._eventCallbacks[eventName]) do
			-- Fire in protected call to prevent cascading errors
			local success, err = pcall(function()
				callback(data)
			end)
			if not success then
				print(string.format("[DebugSystem] Event callback error: %s", tostring(err)))
			end
		end
	end
end

--================================================================================
-- PERFORMANCE TRACKING
--================================================================================

function DebugSystem.performanceMark(name)
	if not DebugSystem._config.enablePerformanceTracking then
		return
	end
	
	DebugSystem._performanceMarks[name] = {
		start = tick(),
		markers = {},
	}
end

function DebugSystem.performanceMarkStep(name, stepName)
	if not DebugSystem._config.enablePerformanceTracking then
		return
	end
	
	if DebugSystem._performanceMarks[name] then
		table.insert(DebugSystem._performanceMarks[name].markers, {
			name = stepName,
			time = tick() - DebugSystem._performanceMarks[name].start,
		})
	end
end

function DebugSystem.performanceEnd(name)
	if not DebugSystem._config.enablePerformanceTracking then
		return nil
	end
	
	if DebugSystem._performanceMarks[name] then
		local mark = DebugSystem._performanceMarks[name]
		mark.endTime = tick()
		mark.totalTime = mark.endTime - mark.startTime
		
		-- Fire performance event
		DebugSystem._fireEvent("onPerformance", {
			name = name,
			totalTime = mark.totalTime,
			markers = mark.markers,
		})
		
		return mark
	end
	
	return nil
end

function DebugSystem.getPerformanceReport()
	return table.clone(DebugSystem._performanceMarks)
end

--================================================================================
-- SAFE EXECUTION
--================================================================================

function DebugSystem.safeExecute(funcName, func, ...)
	local args = {...}
	local success, result = pcall(func, unpack(args))
	
	if success then
		return {
			success = true,
			result = result,
		}
	else
		DebugSystem.error(string.format("Safe execution failed: %s", funcName), {
			error = result,
			argsCount = #args,
		})
		
		return {
			success = false,
			error = result,
		}
	end
end

--================================================================================
-- VALIDATION HELPERS
--================================================================================

function DebugSystem.validateTable(t, expectedSchema, sourceName)
	if not t or type(t) ~= "table" then
		DebugSystem.warn(string.format("Validation failed: %s is not a table", sourceName or "input"))
		return false
	end
	
	if expectedSchema then
		local missingFields = {}
		local unexpectedFields = {}
		
		-- Check for required fields
		for fieldName, fieldType in pairs(expectedSchema) do
			if t[fieldName] == nil then
				if fieldType ~= "optional" then
					table.insert(missingFields, fieldName)
				end
			else
				-- Type check
				if fieldType ~= "any" and type(t[fieldName]) ~= fieldType then
					DebugSystem.warn(string.format("Field type mismatch: %s expected %s, got %s",
						fieldName, fieldType, type(t[fieldName])))
				end
			end
		end
		
		if #missingFields > 0 then
			DebugSystem.warn(string.format("Missing required fields in %s: %s",
				sourceName or "table", table.concat(missingFields, ", ")))
			return false
		end
	end
	
	return true
end

function DebugSystem.assert(condition, message, context)
	if not condition then
		DebugSystem.error(message or "Assertion failed", context)
		return false
	end
	return true
end

--================================================================================
-- EXPORT FOR EXTERNAL USE
--================================================================================

function DebugSystem.createScopedLogger(scopeName)
	return {
		debug = function(msg, ctx) DebugSystem.debug(string.format("[%s] %s", scopeName, msg), ctx) end,
		info = function(msg, ctx) DebugSystem.info(string.format("[%s] %s", scopeName, msg), ctx) end,
		warn = function(msg, ctx) DebugSystem.warn(string.format("[%s] %s", scopeName, msg), ctx) end,
		error = function(msg, ctx) DebugSystem.error(string.format("[%s] %s", scopeName, msg), ctx) end,
		critical = function(msg, ctx) DebugSystem.critical(string.format("[%s] %s", scopeName, msg), ctx) end,
	}
end

--================================================================================
-- REPORT GENERATION
--================================================================================

function DebugSystem.generateReport()
	local report = {
		sessionId = DebugSystem._sessionId,
		timestamp = DateTime.now():FormatLocalTime("yyyy-mm-dd HH:MM:ss", "en-us"),
		config = table.clone(DebugSystem._config),
		errorCounts = DebugSystem.getErrorCount(),
		recentErrors = DebugSystem.getErrorHistory(nil, 20),
		performanceData = DebugSystem.getPerformanceReport(),
	}
	
	return report
end

function DebugSystem.printReport()
	local report = DebugSystem.generateReport()
	
	print("=== DAoC Debug Report ===")
	print(string.format("Session: %s", report.sessionId))
	print(string.format("Time: %s", report.timestamp))
	print(string.format("Errors: %d total, %d warnings, %d errors, %d critical",
		report.errorCounts.total,
		report.errorCounts.warnings,
		report.errorCounts.errors,
		report.errorCounts.critical))
	
	if #report.recentErrors > 0 then
		print("\nRecent Errors:")
		for i, entry in ipairs(report.recentErrors) do
			print(string.format("  [%s] %s", entry.level, entry.message))
		end
	end
	
	print("=========================")
end

-- Initialize with default config
DebugSystem.init()

return DebugSystem

