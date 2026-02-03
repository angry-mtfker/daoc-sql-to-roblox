--[[
	Debug Panel Module
	==================
	
	UI panel for displaying debug information, error history, and performance metrics
	for the DAoC SQL to Roblox Converter plugin.
	
	Features:
	- Error log display with filtering
	- Performance metrics view
	- Real-time error updates via events
	- Clear error history functionality
	- Log level configuration
	
	Author: DAoC Converter Team
	Version: 1.0.0
--]]

local DebugPanel = {}

--================================================================================
-- CONSTANTS
--================================================================================

local PANEL_COLORS = {
	background = Color3.fromRGB(30, 30, 35),
	border = Color3.fromRGB(60, 60, 60),
	header = Color3.fromRGB(45, 45, 50),
	text = Color3.fromRGB(220, 220, 220),
	textSecondary = Color3.fromRGB(150, 150, 150),
	debug = Color3.fromRGB(100, 150, 255),
	info = Color3.fromRGB(100, 200, 100),
	warn = Color3.fromRGB(255, 200, 50),
	error = Color3.fromRGB(255, 100, 100),
	critical = Color3.fromRGB(200, 50, 200),
}

local LOG_LEVELS = {
	{ name = "DEBUG", color = PANEL_COLORS.debug },
	{ name = "INFO", color = PANEL_COLORS.info },
	{ name = "WARN", color = PANEL_COLORS.warn },
	{ name = "ERROR", color = PANEL_COLORS.error },
	{ name = "CRITICAL", color = PANEL_COLORS.critical },
}

--================================================================================
-- UTILITY FUNCTIONS
--================================================================================

local function log(message, logType)
	local prefix = "[DebugPanel] "
	if logType == "error" then
		warn(prefix .. message)
	else
		print(prefix .. message)
	end
end

local function createScrollingFrame(parent, name, size, position)
	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Name = name
	scrollingFrame.Size = size
	scrollingFrame.Position = position
	scrollingFrame.BackgroundTransparency = 1
	scrollingFrame.BorderSizePixel = 0
	scrollingFrame.ScrollBarThickness = 6
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollingFrame.Parent = parent
	return scrollingFrame
end

local function createTextButton(parent, name, text, size, position, color, textColor)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.BorderColor3 = PANEL_COLORS.border
	button.TextColor3 = textColor or PANEL_COLORS.text
	button.TextSize = 11
	button.Font = Enum.Font.SourceSans
	button.Text = text
	button.Parent = parent
	
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = Color3.new(color.R + 0.1, color.G + 0.1, color.B + 0.1)
	end)
	
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = color
	end)
	
	return button
end

local function createTextLabel(parent, name, text, size, position, color, fontSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.TextColor3 = color or PANEL_COLORS.text
	label.TextSize = fontSize or 12
	label.Font = Enum.Font.SourceSans
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Text = text
	label.Parent = parent
	return label
end

--================================================================================
-- UI CREATION
--================================================================================

function DebugPanel.create(parentFrame, debugSystem)
	if not debugSystem then
		log("DebugSystem not provided", "error")
		return nil
	end
	
	local panelWidth = 350
	local panelHeight = 300
	
	local panel = Instance.new("Frame")
	panel.Name = "DebugPanel"
	panel.Size = UDim2.new(0, panelWidth, 0, panelHeight)
	panel.Position = UDim2.new(0, 10, 0, 510)
	panel.BackgroundColor3 = PANEL_COLORS.background
	panel.BorderColor3 = PANEL_COLORS.border
	panel.Visible = false
	panel.Parent = parentFrame
	
	-- Header with toggle button
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 25)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundColor3 = PANEL_COLORS.header
	header.BorderColor3 = PANEL_COLORS.border
	header.Parent = panel
	
	local headerLabel = createTextLabel(header, "Title", "Debug Console", UDim2.new(1, -60, 1, 0), UDim2.new(0, 5, 0, 0), PANEL_COLORS.text, 14)
	headerLabel.Font = Enum.Font.SourceSansBold
	
	-- Toggle button
	local toggleButton = createTextButton(header, "ToggleBtn", "▼", UDim2.new(0, 25, 0, 20), UDim2.new(1, -30, 0, 2), PANEL_COLORS.header, PANEL_COLORS.text)
	toggleButton.TextSize = 12
	
	-- Error summary section
	local summaryFrame = Instance.new("Frame")
	summaryFrame.Name = "SummaryFrame"
	summaryFrame.Size = UDim2.new(1, -10, 0, 30)
	summaryFrame.Position = UDim2.new(0, 5, 0, 30)
	summaryFrame.BackgroundTransparency = 1
	summaryFrame.Parent = panel
	
	local errorCountLabel = createTextLabel(summaryFrame, "ErrorCount", "Errors: 0 | Warnings: 0", 
		UDim2.new(0, 200, 1, 0), UDim2.new(0, 0, 0, 0), PANEL_COLORS.text, 11)
	errorCountLabel.Name = "SummaryLabel"
	
	-- Clear button
	local clearButton = createTextButton(summaryFrame, "ClearBtn", "Clear", UDim2.new(0, 50, 0, 20), 
		UDim2.new(1, -55, 0, 5), PANEL_COLORS.border, PANEL_COLORS.text)
	
	-- Filter dropdown placeholder (simplified as buttons)
	local filterFrame = Instance.new("Frame")
	filterFrame.Name = "FilterFrame"
	filterFrame.Size = UDim2.new(1, -10, 0, 25)
	filterFrame.Position = UDim2.new(0, 5, 0, 60)
	filterFrame.BackgroundTransparency = 1
	filterFrame.Parent = panel
	
	createTextLabel(filterFrame, "FilterLabel", "Filter:", UDim2.new(0, 40, 0, 20), UDim2.new(0, 0, 0, 0), PANEL_COLORS.textSecondary, 11)
	
	local allBtn = createTextButton(filterFrame, "FilterAll", "All", UDim2.new(0, 35, 0, 18), UDim2.new(0, 40, 0, 2), PANEL_COLORS.header, PANEL_COLORS.text)
	local errorBtn = createTextButton(filterFrame, "FilterError", "Error", UDim2.new(0, 45, 0, 18), UDim2.new(0, 80, 0, 2), PANEL_COLORS.error, PANEL_COLORS.text)
	local warnBtn = createTextButton(filterFrame, "FilterWarn", "Warn", UDim2.new(0, 45, 0, 18), UDim2.new(0, 130, 0, 2), PANEL_COLORS.warn, PANEL_COLORS.text)
	
	-- Log display area
	local logFrame = Instance.new("Frame")
	logFrame.Name = "LogFrame"
	logFrame.Size = UDim2.new(1, -10, 0, 175)
	logFrame.Position = UDim2.new(0, 5, 0, 90)
	logFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	logFrame.BorderColor3 = PANEL_COLORS.border
	logFrame.Parent = panel
	
	-- Scrolling frame for logs
	local logScroller = createScrollingFrame(logFrame, "LogScroller", UDim2.new(1, -4, 1, -4), UDim2.new(0, 2, 0, 2))
	
	-- Log entries container
	local logContainer = Instance.new("Frame")
	logContainer.Name = "LogContainer"
	logContainer.Size = UDim2.new(1, 0, 0, 0)
	logContainer.Position = UDim2.new(0, 0, 0, 0)
	logContainer.BackgroundTransparency = 1
	logContainer.Parent = logScroller
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Name = "LogListLayout"
	listLayout.Padding = UDim.new(0, 2)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = logContainer
	
	-- State management
	local state = {
		debugSystem = debugSystem,
		currentFilter = nil,
		isExpanded = true,
		logEntries = {},
	}
	
	-- Event connections
	toggleButton.MouseButton1Click:Connect(function()
		state.isExpanded = not state.isExpanded
		panel.Size = UDim2.new(0, panelWidth, 0, state.isExpanded and panelHeight or 30)
		toggleButton.Text = state.isExpanded and "▼" or "▶"
		logScroller.Visible = state.isExpanded
		summaryFrame.Visible = state.isExpanded
		filterFrame.Visible = state.isExpanded
	end)
	
	clearButton.MouseButton1Click:Connect(function()
		debugSystem.clearErrorHistory()
		DebugPanel.refresh(panel)
	end)
	
	-- Filter buttons
	allBtn.MouseButton1Click:Connect(function()
		state.currentFilter = nil
		DebugPanel.refresh(panel)
	end)
	
	errorBtn.MouseButton1Click:Connect(function()
		state.currentFilter = "ERROR"
		DebugPanel.refresh(panel)
	end)
	
	warnBtn.MouseButton1Click:Connect(function()
		state.currentFilter = "WARN"
		DebugPanel.refresh(panel)
	end)
	
	-- Register for debug events
	debugSystem.registerEvent("onLog", function(data)
		if state.isExpanded then
			DebugPanel.addLogEntry(panel, data)
			DebugPanel.updateSummary(panel)
		end
	end)
	
	-- Initial refresh
	DebugPanel.refresh(panel)
	
	return {
		panel = panel,
		state = state,
		refresh = function() DebugPanel.refresh(panel) end,
		toggle = function() 
			toggleButton.MouseButton1Click:Fire()
		end,
	}
end

--================================================================================
-- LOG ENTRY MANAGEMENT
--================================================================================

function DebugPanel.addLogEntry(panel, logData)
	local logContainer = panel.LogFrame.LogScroller.LogContainer
	
	local entryFrame = Instance.new("Frame")
	entryFrame.Name = "LogEntry"
	entryFrame.Size = UDim2.new(1, 0, 0, 18)
	entryFrame.BackgroundTransparency = 1
	entryFrame.LayoutOrder = #logContainer:GetChildren()
	
	-- Get color based on level
	local color = PANEL_COLORS.info
	for _, level in ipairs(LOG_LEVELS) do
		if level.name == logData.level then
			color = level.color
			break
		end
	end
	
	-- Level indicator
	local levelLabel = createTextLabel(entryFrame, "Level", logData.level, UDim2.new(0, 50, 1, 0), 
		UDim2.new(0, 0, 0, 0), color, 9)
	levelLabel.Font = Enum.Font.SourceSansBold
	
	-- Message
	local message = logData.message
	if #message > 50 then
		message = message:sub(1, 47) .. "..."
	end
	
	local messageLabel = createTextLabel(entryFrame, "Message", message, UDim2.new(1, -55, 1, 0), 
		UDim2.new(55, 0, 0, 0), PANEL_COLORS.text, 10)
	
	entryFrame.Parent = logContainer
	
	-- Auto-scroll
	local logScroller = panel.LogFrame.LogScroller
	if logScroller.CanvasSize.Y.Offset < logContainer.AbsoluteSize.Y then
		logScroller.CanvasSize = UDim2.new(0, 0, 0, logContainer.AbsoluteSize.Y)
	end
end

function DebugPanel.clearEntries(panel)
	local logContainer = panel.LogFrame.LogScroller.LogContainer
	
	for _, child in ipairs(logContainer:GetChildren()) do
		if child.Name == "LogEntry" then
			child:Destroy()
		end
	end
end

--================================================================================
-- REFRESH AND UPDATE
--================================================================================

function DebugPanel.refresh(panel)
	local debugSystem = panel.state.debugSystem
	local filter = panel.state.currentFilter
	
	-- Clear existing entries
	DebugPanel.clearEntries(panel)
	
	-- Get error history
	local history = debugSystem.getErrorHistory(filter, 50)
	
	-- Add log entries
	for _, entry in ipairs(history) do
		DebugPanel.addLogEntry(panel, {
			level = entry.level,
			message = entry.message,
			timestamp = entry.timestamp,
		})
	end
	
	-- Update summary
	DebugPanel.updateSummary(panel)
end

function DebugPanel.updateSummary(panel)
	local debugSystem = panel.state.debugSystem
	local counts = debugSystem.getErrorCount()
	
	local summaryLabel = panel.SummaryFrame.SummaryLabel
	summaryLabel.Text = string.format("Errors: %d | Warnings: %d | Total: %d", 
		counts.errors, counts.warnings, counts.total)
	
	-- Update color based on severity
	if counts.critical > 0 then
		summaryLabel.TextColor3 = PANEL_COLORS.critical
	elseif counts.errors > 0 then
		summaryLabel.TextColor3 = PANEL_COLORS.error
	elseif counts.warnings > 0 then
		summaryLabel.TextColor3 = PANEL_COLORS.warn
	else
		summaryLabel.TextColor3 = PANEL_COLORS.info
	end
end

--================================================================================
-- INTEGRATION
--================================================================================

function DebugPanel.connectToPlugin(debugPanelUI, pluginInterface)
	-- Connect to plugin events for automatic refreshing
	if pluginInterface.onError then
		pluginInterface.onError = function(errorData)
			if debugPanelUI and debugPanelUI.state then
				debugPanelUI.refresh()
			end
		end
	end
end

return DebugPanel

