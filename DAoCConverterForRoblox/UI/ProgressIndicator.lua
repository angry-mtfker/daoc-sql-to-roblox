--[[
	Progress Indicator Module
	=========================
	
	This module creates a progress indicator for the DAoC SQL to Roblox
	Converter plugin. It shows conversion progress, file processing status,
	and provides visual feedback during long operations.
	
	Features:
	- Progress bar with percentage
	- Status text updates
	- File-by-file progress tracking
	- Error state indication
	- Completion animations
	
	Author: DAoC Converter Team
	Version: 1.0.0
--]]

local ProgressIndicator = {}

--================================================================================
-- CONSTANTS
--================================================================================

local COLORS = {
	background = Color3.fromRGB(50, 50, 50),
	fill = Color3.fromRGB(50, 180, 50),
	fillError = Color3.fromRGB(180, 50, 50),
	text = Color3.fromRGB(220, 220, 220),
	textSecondary = Color3.fromRGB(150, 150, 150),
	border = Color3.fromRGB(100, 100, 100),
}

local PROGRESS_STATES = {
	IDLE = "idle",
	PROCESSING = "processing",
	COMPLETED = "completed",
	ERROR = "error",
}

--================================================================================
-- UTILITY FUNCTIONS
--================================================================================

local function log(message, logType)
	local timestamp = DateTime.now():FormatLocalTime("yyyy-mm-dd HH:MM:ss", "en-us")
	local prefix = "[Progress] "
	
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

local function createTextLabel(parent, name, text, size, position, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.TextColor3 = color or COLORS.text
	label.TextSize = textSize or 12
	label.Font = Enum.Font.SourceSans
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Text = text
	label.Parent = parent
	return label
end

local function animateProgress(fillBar, targetWidth, duration)
	local tweenService = game:GetService("TweenService")
	local tweenInfo = TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	
	local tween = tweenService:Create(fillBar, tweenInfo, {Size = UDim2.new(0, targetWidth, 1, 0)})
	tween:Play()
	
	return tween
end

--================================================================================
-- UI CREATION
--================================================================================

function ProgressIndicator.create(parentFrame)
	local indicator = Instance.new("Frame")
	indicator.Name = "ProgressIndicator"
	indicator.Size = UDim2.new(1, -20, 0, 80)
	indicator.Position = UDim2.new(0, 10, 0, 420)
	indicator.BackgroundTransparency = 1
	indicator.Parent = parentFrame
	
	-- Progress bar background
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(1, 0, 0, 20)
	progressBg.Position = UDim2.new(0, 0, 0, 0)
	progressBg.BackgroundColor3 = COLORS.background
	progressBg.BorderColor3 = COLORS.border
	progressBg.Parent = indicator
	
	-- Progress bar fill
	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.Position = UDim2.new(0, 0, 0, 0)
	progressFill.BackgroundColor3 = COLORS.fill
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBg
	
	-- Progress text (percentage)
	local progressText = createTextLabel(indicator, "ProgressText", "0%", UDim2.new(0, 40, 0, 20), UDim2.new(1, -45, 0, 0), 12, COLORS.text)
	progressText.TextXAlignment = Enum.TextXAlignment.Right
	
	-- Status text
	local statusText = createTextLabel(indicator, "StatusText", "Ready", UDim2.new(1, 0, 0, 15), UDim2.new(0, 0, 0, 25), 12, COLORS.textSecondary)
	
	-- File progress text
	local fileText = createTextLabel(indicator, "FileText", "", UDim2.new(1, 0, 0, 15), UDim2.new(0, 0, 0, 40), 10, COLORS.textSecondary)
	
	-- Time remaining text
	local timeText = createTextLabel(indicator, "TimeText", "", UDim2.new(1, 0, 0, 15), UDim2.new(0, 0, 0, 55), 10, COLORS.textSecondary)
	
	-- State management
	local state = {
		currentState = PROGRESS_STATES.IDLE,
		progress = 0,
		totalFiles = 0,
		processedFiles = 0,
		startTime = 0,
		currentFile = "",
	}
	
	-- Return interface
	return {
		indicator = indicator,
		state = state,
		setProgress = function(progress, status, fileName)
			ProgressIndicator.setProgress(indicator, progress, status, fileName)
		end,
		setState = function(newState)
			ProgressIndicator.setState(indicator, newState)
		end,
		reset = function()
			ProgressIndicator.reset(indicator)
		end,
		startBatch = function(totalFiles)
			ProgressIndicator.startBatch(indicator, totalFiles)
		end,
		updateFileProgress = function(processed, total, currentFile)
			ProgressIndicator.updateFileProgress(indicator, processed, total, currentFile)
		end,
	}
end

--================================================================================
-- PROGRESS UPDATES
--================================================================================

function ProgressIndicator.setProgress(indicator, progress, status, fileName)
	local progressBg = indicator.ProgressBg
	local progressFill = progressBg.ProgressFill
	local progressText = indicator.ProgressText
	local statusText = indicator.StatusText
	local fileText = indicator.FileText
	
	-- Clamp progress to 0-1
	progress = math.clamp(progress or 0, 0, 1)
	
	-- Update progress bar
	local maxWidth = progressBg.AbsoluteSize.X
	local targetWidth = maxWidth * progress
	animateProgress(progressFill, targetWidth)
	
	-- Update text
	progressText.Text = string.format("%.0f%%", progress * 100)
	statusText.Text = status or "Processing..."
	fileText.Text = fileName and ("Current: " .. fileName) or ""
	
	-- Update state
	local state = indicator.Parent -- Assuming indicator is child of main frame with state
	if state and state.state then
		state.state.progress = progress
		state.state.currentFile = fileName or ""
	end
	
	log(string.format("Progress updated: %.1f%% - %s", progress * 100, status or "unknown"))
end

function ProgressIndicator.setState(indicator, newState)
	local progressFill = indicator.ProgressBg.ProgressFill
	local statusText = indicator.StatusText
	
	local state = indicator.Parent
	if state and state.state then
		state.state.currentState = newState
	end
	
	if newState == PROGRESS_STATES.IDLE then
		progressFill.BackgroundColor3 = COLORS.fill
		statusText.Text = "Ready"
		statusText.TextColor3 = COLORS.textSecondary
	elseif newState == PROGRESS_STATES.PROCESSING then
		progressFill.BackgroundColor3 = COLORS.fill
		statusText.Text = "Processing..."
		statusText.TextColor3 = COLORS.text
	elseif newState == PROGRESS_STATES.COMPLETED then
		progressFill.BackgroundColor3 = COLORS.fill
		statusText.Text = "Completed!"
		statusText.TextColor3 = Color3.fromRGB(50, 180, 50)
		
		-- Completion animation
		local tweenService = game:GetService("TweenService")
		local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
		local tween = tweenService:Create(statusText, tweenInfo, {TextSize = 14})
		tween:Play()
		
		wait(0.5)
		tween = tweenService:Create(statusText, tweenInfo, {TextSize = 12})
		tween:Play()
		
	elseif newState == PROGRESS_STATES.ERROR then
		progressFill.BackgroundColor3 = COLORS.fillError
		statusText.Text = "Error occurred"
		statusText.TextColor3 = COLORS.fillError
	end
	
	log("State changed to: " .. newState)
end

function ProgressIndicator.reset(indicator)
	local progressFill = indicator.ProgressBg.ProgressFill
	local progressText = indicator.ProgressText
	local statusText = indicator.StatusText
	local fileText = indicator.FileText
	local timeText = indicator.TimeText
	
	-- Reset progress bar
	animateProgress(progressFill, 0, 0.2)
	
	-- Reset text
	progressText.Text = "0%"
	statusText.Text = "Ready"
	statusText.TextColor3 = COLORS.textSecondary
	fileText.Text = ""
	timeText.Text = ""
	
	-- Reset state
	local state = indicator.Parent
	if state and state.state then
		state.state.currentState = PROGRESS_STATES.IDLE
		state.state.progress = 0
		state.state.totalFiles = 0
		state.state.processedFiles = 0
		state.state.startTime = 0
		state.state.currentFile = ""
	end
	
	log("Progress indicator reset")
end

function ProgressIndicator.startBatch(indicator, totalFiles)
	local state = indicator.Parent
	if state and state.state then
		state.state.totalFiles = totalFiles
		state.state.processedFiles = 0
		state.state.startTime = tick()
	end
	
	ProgressIndicator.setState(indicator, PROGRESS_STATES.PROCESSING)
	log(string.format("Started batch processing of %d files", totalFiles))
end

function ProgressIndicator.updateFileProgress(indicator, processed, total, currentFile)
	local progress = processed / total
	local status = string.format("Processing file %d/%d", processed, total)
	
	ProgressIndicator.setProgress(indicator, progress, status, currentFile)
	
	-- Update state
	local state = indicator.Parent
	if state and state.state then
		state.state.processedFiles = processed
		state.state.currentFile = currentFile or ""
		
		-- Estimate time remaining
		local elapsed = tick() - state.state.startTime
		local rate = processed / elapsed
		local remaining = (total - processed) / rate
		
		if remaining > 0 and remaining < 3600 then -- Only show if less than 1 hour
			local timeText = indicator.TimeText
			local minutes = math.floor(remaining / 60)
			local seconds = math.floor(remaining % 60)
			timeText.Text = string.format("~%d:%02d remaining", minutes, seconds)
		end
	end
	
	if processed >= total then
		ProgressIndicator.setState(indicator, PROGRESS_STATES.COMPLETED)
	end
end

--================================================================================
-- INTEGRATION HELPERS
--================================================================================

function ProgressIndicator.connectToPlugin(progressUI, pluginInterface)
	-- Connect conversion progress updates
	if pluginInterface.onProgressUpdate then
		pluginInterface.onProgressUpdate = function(progress, status, fileName)
			progressUI.setProgress(progress, status, fileName)
		end
	end
	
	-- Connect batch start
	if pluginInterface.onBatchStart then
		pluginInterface.onBatchStart = function(totalFiles)
			progressUI.startBatch(totalFiles)
		end
	end
	
	-- Connect file progress
	if pluginInterface.onFileProgress then
		pluginInterface.onFileProgress = function(processed, total, currentFile)
			progressUI.updateFileProgress(processed, total, currentFile)
		end
	end
	
	-- Connect completion
	if pluginInterface.onConversionComplete then
		pluginInterface.onConversionComplete = function(success, errorMsg)
			if success then
				progressUI.setState(PROGRESS_STATES.COMPLETED)
			else
				progressUI.setState(PROGRESS_STATES.ERROR)
				local statusText = progressUI.indicator.StatusText
				statusText.Text = errorMsg or "Conversion failed"
			end
		end
	end
end

--================================================================================
-- ANIMATION HELPERS
--================================================================================

function ProgressIndicator.pulseError(indicator)
	local progressFill = indicator.ProgressBg.ProgressFill
	local tweenService = game:GetService("TweenService")
	
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local tween1 = tweenService:Create(progressFill, tweenInfo, {BackgroundColor3 = Color3.fromRGB(255, 100, 100)})
	local tween2 = tweenService:Create(progressFill, tweenInfo, {BackgroundColor3 = COLORS.fillError})
	
	tween1:Play()
	wait(0.3)
	tween2:Play()
end

function ProgressIndicator.showCompletionEffect(indicator)
	local progressFill = indicator.ProgressBg.ProgressFill
	local tweenService = game:GetService("TweenService")
	
	-- Flash effect
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local originalColor = progressFill.BackgroundColor3
	
	for i = 1, 3 do
		local tween1 = tweenService:Create(progressFill, tweenInfo, {BackgroundColor3 = Color3.fromRGB(100, 255, 100)})
		local tween2 = tweenService:Create(progressFill, tweenInfo, {BackgroundColor3 = originalColor})
		
		tween1:Play()
		wait(0.2)
		tween2:Play()
		wait(0.2)
	end
end

return ProgressIndicator
