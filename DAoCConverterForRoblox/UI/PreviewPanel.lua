--[[
	Preview Panel Module
	====================
	
	UI panel for previewing converted SQL data before export.
	Displays sample records, allows field selection, and provides
	pagination for large datasets.
	
	Features:
	- Sample record preview with field selection
	- Pagination for large datasets
	- Column visibility toggle
	- Search/filter within preview
	- Data statistics display
	
	Author: DAoC Converter Team
	Version: 1.0.0
--]]

local PreviewPanel = {}

--================================================================================
-- CONSTANTS
================================================================================

local PANEL_COLORS = {
	background = Color3.fromRGB(30, 30, 35),
	border = Color3.fromRGB(60, 60, 60),
	header = Color3.fromRGB(45, 45, 50),
	text = Color3.fromRGB(220, 220, 220),
	textSecondary = Color3.fromRGB(150, 150, 150),
	highlight = Color3.fromRGB(70, 130, 180),
	rowEven = Color3.fromRGB(35, 35, 40),
	rowOdd = Color3.fromRGB(40, 40, 45),
	success = Color3.fromRGB(100, 200, 100),
	warning = Color3.fromRGB(255, 200, 50),
	error = Color3.fromRGB(255, 100, 100),
}

local PREVIEW_CONFIG = {
	defaultPageSize = 10,
	maxPageSize = 50,
	truncateLength = 100,
}

--================================================================================
-- UTILITY FUNCTIONS
================================================================================

local function log(message, logType)
	local prefix = "[PreviewPanel] "
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
		button.BackgroundColor3 = Color3.new(math.min(color.R + 0.15, 1), math.min(color.G + 0.15, 1), math.min(color.B + 0.15, 1))
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

local function createTextBox(parent, name, placeholder, size, position)
	local textBox = Instance.new("TextBox")
	textBox.Name = name
	textBox.Size = size
	textBox.Position = position
	textBox.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	textBox.BorderColor3 = PANEL_COLORS.border
	textBox.TextColor3 = PANEL_COLORS.text
	textBox.TextSize = 11
	textBox.Font = Enum.Font.SourceSans
	textBox.PlaceholderText = placeholder or "Enter text..."
	textBox.Text = ""
	textBox.Parent = parent
	return textBox
end

--================================================================================
-- UI CREATION
================================================================================

function PreviewPanel.create(parentFrame, options)
	options = options or {}
	
	local panelWidth = 380
	local panelHeight = 300
	
	local panel = Instance.new("Frame")
	panel.Name = "PreviewPanel"
	panel.Size = UDim2.new(0, panelWidth, 0, panelHeight)
	panel.Position = UDim2.new(0, 10, 0, 10)
	panel.BackgroundColor3 = PANEL_COLORS.background
	panel.BorderColor3 = PANEL_COLORS.border
	panel.Visible = false
	panel.Parent = parentFrame
	
	-- Header section
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 30)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundColor3 = PANEL_COLORS.header
	header.BorderColor3 = PANEL_COLORS.border
	header.Parent = panel
	
	local titleLabel = createTextLabel(header, "Title", "Data Preview", 
		UDim2.new(1, -80, 1, 0), UDim2.new(0, 10, 0, 0), PANEL_COLORS.text, 14)
	titleLabel.Font = Enum.Font.SourceSansBold
	
	-- Toggle button
	local toggleButton = createTextButton(header, "ToggleBtn", "▼", 
		UDim2.new(0, 25, 0, 22), UDim2.new(1, -30, 0, 4), PANEL_COLORS.header, PANEL_COLORS.text)
	toggleButton.TextSize = 12
	
	-- Info bar with record count
	local infoBar = Instance.new("Frame")
	infoBar.Name = "InfoBar"
	infoBar.Size = UDim2.new(1, -10, 0, 25)
	infoBar.Position = UDim2.new(0, 5, 0, 35)
	infoBar.BackgroundColor3 = PANEL_COLORS.background
	infoBar.BorderColor3 = PANEL_COLORS.border
	infoBar.Parent = panel
	
	local tableNameLabel = createTextLabel(infoBar, "TableName", "No data loaded", 
		UDim2.new(0, 150, 1, 0), UDim2.new(0, 5, 0, 0), PANEL_COLORS.highlight, 12)
	tableNameLabel.Font = Enum.Font.SourceSansBold
	
	local recordCountLabel = createTextLabel(infoBar, "RecordCount", "0 records", 
		UDim2.new(0, 100, 1, 0), UDim2.new(0, 160, 0, 0), PANEL_COLORS.textSecondary, 11)
	
	local pageLabel = createTextLabel(infoBar, "PageLabel", "Page: 0/0", 
		UDim2.new(0, 80, 1, 0), UDim2.new(1, -90, 0, 0), PANEL_COLORS.textSecondary, 11)
	
	-- Search/filter section
	local searchFrame = Instance.new("Frame")
	searchFrame.Name = "SearchFrame"
	searchFrame.Size = UDim2.new(1, -10, 0, 30)
	searchFrame.Position = UDim2.new(0, 5, 0, 65)
	searchFrame.BackgroundTransparency = 1
	searchFrame.Parent = panel
	
	local searchBox = createTextBox(searchFrame, "SearchBox", "Search records...", 
		UDim2.new(0, 200, 0, 25), UDim2.new(0, 0, 0, 0))
	
	-- Column filter dropdown (simplified as buttons)
	local filterBtn = createTextButton(searchFrame, "FilterBtn", "Columns ▼", 
		UDim2.new(0, 80, 0, 25), UDim2.new(0, 210, 0, 0), PANEL_COLORS.header, PANEL_COLORS.text)
	
	-- Page size selector
	local pageSizeLabel = createTextLabel(searchFrame, "Label", "Rows:", 
		UDim2.new(0, 40, 0, 20), UDim2.new(1, -130, 0, 0), PANEL_COLORS.textSecondary, 11)
	
	local pageSizeBox = createTextBox(searchFrame, "PageSize", "10", 
		UDim2.new(0, 40, 0, 22), UDim2.new(1, -85, 0, 0))
	pageSizeBox.Text = "10"
	pageSizeBox.ClearTextOnFocus = false
	
	-- Data table container
	local tableFrame = Instance.new("Frame")
	tableFrame.Name = "TableFrame"
	tableFrame.Size = UDim2.new(1, -10, 0, 160)
	tableFrame.Position = UDim2.new(0, 5, 0, 100)
	tableFrame.BackgroundColor3 = PANEL_COLORS.background
	tableFrame.BorderColor3 = PANEL_COLORS.border
	tableFrame.Parent = panel
	
	-- Column headers
	local headerRow = Instance.new("Frame")
	headerRow.Name = "HeaderRow"
	headerRow.Size = UDim2.new(1, 0, 0, 25)
	headerRow.Position = UDim2.new(0, 0, 0, 0)
	headerRow.BackgroundColor3 = PANEL_COLORS.header
	headerRow.BorderColor3 = PANEL_COLORS.border
	headerRow.Parent = tableFrame
	
	-- Data scrolling frame
	local dataScroller = createScrollingFrame(tableFrame, "DataScroller", 
		UDim2.new(1, 0, 1, -25), UDim2.new(0, 0, 0, 25))
	
	-- Data container with list layout
	local dataContainer = Instance.new("Frame")
	dataContainer.Name = "DataContainer"
	dataContainer.Size = UDim2.new(1, 0, 0, 0)
	dataContainer.Position = UDim2.new(0, 0, 0, 0)
	dataContainer.BackgroundTransparency = 1
	dataContainer.Parent = dataScroller
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Name = "DataListLayout"
	listLayout.Padding = UDim.new(0, 1)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = dataContainer
	
	-- Pagination controls
	local paginationFrame = Instance.new("Frame")
	paginationFrame.Name = "PaginationFrame"
	paginationFrame.Size = UDim2.new(1, -10, 0, 35)
	paginationFrame.Position = UDim2.new(0, 5, 0, 265)
	paginationFrame.BackgroundTransparency = 1
	paginationFrame.Parent = panel
	
	local prevBtn = createTextButton(paginationFrame, "PrevBtn", "◄ Prev", 
		UDim2.new(0, 70, 0, 25), UDim2.new(0, 0, 0, 0), PANEL_COLORS.header, PANEL_COLORS.text)
	
	local nextBtn = createTextButton(paginationFrame, "NextBtn", "Next ►", 
		UDim2.new(0, 70, 0, 25), UDim2.new(0, 80, 0, 0), PANEL_COLORS.header, PANEL_COLORS.text)
	
	local firstBtn = createTextButton(paginationFrame, "FirstBtn", "« First", 
		UDim2.new(0, 60, 0, 25), UDim2.new(0, 160, 0, 0), PANEL_COLORS.header, PANEL_COLORS.text)
	
	local lastBtn = createTextButton(paginationFrame, "LastBtn", "Last »", 
		UDim2.new(0, 60, 0, 25), UDim2.new(0, 230, 0, 0), PANEL_COLORS.header, PANEL_COLORS.text)
	
	-- State management
	local state = {
		data = nil,
		filteredData = nil,
		currentPage = 1,
		pageSize = PREVIEW_CONFIG.defaultPageSize,
		columns = {},
		visibleColumns = {},
		searchTerm = "",
		isExpanded = true,
		columnButtons = {},
	}
	
	-- Helper function to truncate text
	local function truncateText(text, maxLength)
		if not text or type(text) ~= "string" then return tostring(text or "nil") end
		if #text <= maxLength then return text end
		return text:sub(1, maxLength - 3) .. "..."
	end
	
	-- Helper function to format cell value
	local function formatCellValue(value)
		if value == nil then
			return "nil"
		elseif type(value) == "string" then
			return string.format('"%s"', truncateText(value, PREVIEW_CONFIG.truncateLength))
		elseif type(value) == "boolean" then
			return tostring(value)
		elseif type(value) == "number" then
			return tostring(value)
		else
			return truncateText(tostring(value), PREVIEW_CONFIG.truncateLength)
		end
	end
	
	-- Helper function to create column header
	local function createColumnHeader(parent, colName, width, position)
		local header = Instance.new("Frame")
		header.Name = "ColHeader_" .. colName
		header.Size = UDim2.new(0, width, 1, 0)
		header.Position = position
		header.BackgroundColor3 = PANEL_COLORS.header
		header.BorderColor3 = PANEL_COLORS.border
		header.Parent = parent
		
		local label = createTextLabel(header, "Label", colName, 
			UDim2.new(1, -4, 1, 0), UDim2.new(0, 2, 0, 0), PANEL_COLORS.text, 10)
		label.TextXAlignment = Enum.TextXAlignment.Left
		
		return header
	end
	
	-- Helper function to create data row
	local function createDataRow(parent, record, rowIndex, position)
		local isEven = rowIndex % 2 == 0
		local row = Instance.new("Frame")
		row.Name = "DataRow_" .. rowIndex
		row.Size = UDim2.new(1, 0, 0, 22)
		row.Position = position
		row.BackgroundColor3 = isEven and PANEL_COLORS.rowEven or PANEL_COLORS.rowOdd
		row.BorderColor3 = PANEL_COLORS.border
		row.Parent = parent
		
		local colIndex = 1
		for _, colName in ipairs(state.columns) do
			if state.visibleColumns[colName] then
				local cellWidth = 100  -- Default width
				local value = record[colName]
				
				local cell = Instance.new("Frame")
				cell.Name = "Cell_" .. colName
				cell.Size = UDim2.new(0, cellWidth, 1, 0)
				cell.Position = UDim2.new((colIndex - 1) * cellWidth, 0, 0, 0)
				cell.BackgroundTransparency = 1
				cell.Parent = row
				
				local label = createTextLabel(cell, "Value", formatCellValue(value), 
					UDim2.new(1, -4, 1, 0), UDim2.new(0, 2, 0, 0), PANEL_COLORS.text, 10)
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.TextTruncate = Enum.TextTruncate.AtEnd
				
				colIndex = colIndex + 1
			end
		end
		
		return row
	end
	
	-- Update preview display
	local function updatePreview()
		if not state.data or not state.data.records then
			tableNameLabel.Text = "No data loaded"
			recordCountLabel.Text = "0 records"
			pageLabel.Text = "Page: 0/0"
			
			-- Clear existing rows
			for _, child in ipairs(dataContainer:GetChildren()) do
				if child.Name:sub(1, 7) == "DataRow" then
					child:Destroy()
				end
			end
			return
		end
		
		local tableName = state.data.tableName or "Unknown"
		tableNameLabel.Text = tableName
		
		local totalRecords = #state.filteredData
		recordCountLabel.Text = totalRecords .. " records"
		
		local totalPages = math.ceil(totalRecords / state.pageSize)
		if totalPages == 0 then totalPages = 1 end
		
		state.currentPage = math.min(state.currentPage, totalPages)
		pageLabel.Text = string.format("Page: %d/%d", state.currentPage, totalPages)
		
		-- Clear existing rows
		for _, child in ipairs(dataContainer:GetChildren()) do
			if child.Name:sub(1, 7) == "DataRow" then
				child:Destroy()
			end
		end
		
		-- Calculate start and end indices for current page
		local startIndex = (state.currentPage - 1) * state.pageSize + 1
		local endIndex = math.min(startIndex + state.pageSize - 1, totalRecords)
		
		-- Create data rows
		for i = startIndex, endIndex do
			local record = state.filteredData[i]
			if record then
				createDataRow(dataContainer, record, i - startIndex + 1, 
					UDim2.new(0, 0, 0, (i - startIndex) * 23))
			end
		end
		
		-- Update canvas size
		local rowCount = endIndex - startIndex + 1
		dataScroller.CanvasSize = UDim2.new(0, 0, 0, rowCount * 23)
		
		-- Update button states
		prevBtn.AutoButtonColor = state.currentPage > 1
		nextBtn.AutoButtonColor = state.currentPage < totalPages
		firstBtn.AutoButtonColor = state.currentPage > 1
		lastBtn.AutoButtonColor = state.currentPage < totalPages
		
		prevBtn.BackgroundColor3 = state.currentPage > 1 and PANEL_COLORS.header or PANEL_COLORS.border
		nextBtn.BackgroundColor3 = state.currentPage < totalPages and PANEL_COLORS.header or PANEL_COLORS.border
		firstBtn.BackgroundColor3 = state.currentPage > 1 and PANEL_COLORS.header or PANEL_COLORS.border
		lastBtn.BackgroundColor3 = state.currentPage < totalPages and PANEL_COLORS.header or PANEL_COLORS.border
	end
	
	-- Filter data based on search term
	local function filterData()
		if not state.data or not state.data.records then
			state.filteredData = {}
			return
		end
		
		if state.searchTerm == "" then
			state.filteredData = state.data.records
		else
			state.filteredData = {}
			local searchLower = state.searchTerm:lower()
			
			for _, record in ipairs(state.data.records) do
				local matches = false
				for _, colName in ipairs(state.columns) do
					local value = record[colName]
					if value and tostring(value):lower():find(searchLower, 1, true) then
						matches = true
						break
					end
				end
				if matches then
					table.insert(state.filteredData, record)
				end
			end
		end
		
		state.currentPage = 1
		updatePreview()
	end
	
	-- Event handlers
	toggleButton.MouseButton1Click:Connect(function()
		state.isExpanded = not state.isExpanded
		panel.Size = UDim2.new(0, panelWidth, 0, state.isExpanded and panelHeight or 30)
		toggleButton.Text = state.isExpanded and "▼" or "▶"
		infoBar.Visible = state.isExpanded
		searchFrame.Visible = state.isExpanded
		tableFrame.Visible = state.isExpanded
		paginationFrame.Visible = state.isExpanded
	end)
	
	prevBtn.MouseButton1Click:Connect(function()
		if state.currentPage > 1 then
			state.currentPage = state.currentPage - 1
			updatePreview()
		end
	end)
	
	nextBtn.MouseButton1Click:Connect(function()
		local totalPages = math.ceil(#state.filteredData / state.pageSize)
		if state.currentPage < totalPages then
			state.currentPage = state.currentPage + 1
			updatePreview()
		end
	end)
	
	firstBtn.MouseButton1Click:Connect(function()
		state.currentPage = 1
		updatePreview()
	end)
	
	lastBtn.MouseButton1Click:Connect(function()
		local totalPages = math.ceil(#state.filteredData / state.pageSize)
		state.currentPage = totalPages
		updatePreview()
	end)
	
	searchBox.FocusLost:Connect(function()
		state.searchTerm = searchBox.Text
		filterData()
	end)
	
	pageSizeBox.FocusLost:Connect(function()
		local newSize = tonumber(pageSizeBox.Text)
		if newSize and newSize > 0 and newSize <= PREVIEW_CONFIG.maxPageSize then
			state.pageSize = newSize
			state.currentPage = 1
			updatePreview()
		else
			pageSizeBox.Text = tostring(state.pageSize)
		end
	end)
	
	-- Return panel interface
	local panelInterface = {
		panel = panel,
		state = state,
		
		-- Load data for preview
		loadData = function(convertedData)
			if not convertedData or not convertedData.data then
				log("Invalid data provided", "error")
				return false
			end
			
			state.data = convertedData
			state.filteredData = convertedData.data
			state.currentPage = 1
			state.searchTerm = ""
			searchBox.Text = ""
			
			-- Extract column names from first record
			state.columns = {}
			state.visibleColumns = {}
			
			if convertedData.data[1] then
				for key in pairs(convertedData.data[1]) do
					table.insert(state.columns, key)
					state.visibleColumns[key] = true
				end
				table.sort(state.columns)
			end
			
			pageSizeBox.Text = tostring(state.pageSize)
			updatePreview()
			log(string.format("Loaded %d records for preview", #convertedData.data))
			return true
		end,
		
		-- Clear preview
		clear = function()
			state.data = nil
			state.filteredData = {}
			state.columns = {}
			state.visibleColumns = {}
			state.currentPage = 1
			state.searchTerm = ""
			searchBox.Text = ""
			updatePreview()
		end,
		
		-- Refresh display
		refresh = function()
			updatePreview()
		end,
		
		-- Set page size
		setPageSize = function(size)
			size = math.max(1, math.min(size, PREVIEW_CONFIG.maxPageSize))
			state.pageSize = size
			state.currentPage = 1
			pageSizeBox.Text = tostring(size)
			updatePreview()
		end,
		
		-- Get statistics
		getStats = function()
			return {
				totalRecords = state.data and #state.data.data or 0,
				filteredRecords = #state.filteredData,
				currentPage = state.currentPage,
				totalPages = math.ceil(#state.filteredData / state.pageSize),
				pageSize = state.pageSize,
				columns = #state.columns,
			}
		end,
		
		-- Toggle panel visibility
		toggle = function()
			toggleButton.MouseButton1Click:Fire()
		end,
		
		-- Show panel
		show = function()
			panel.Visible = true
		end,
		
		-- Hide panel
		hide = function()
			panel.Visible = false
		end,
	}
	
	return panelInterface
end

--================================================================================
-- COLUMN SELECTION DROPDOWN
================================================================================

function PreviewPanel.createColumnDropdown(parent, anchorPosition, columns, onColumnToggle)
	local dropdown = Instance.new("Frame")
	dropdown.Name = "ColumnDropdown"
	dropdown.Size = UDim2.new(0, 150, 0, 0)
	dropdown.Position = anchorPosition
	dropdown.BackgroundColor3 = PANEL_COLORS.background
	dropdown.BorderColor3 = PANEL_COLORS.border
	dropdown.Visible = false
	dropdown.Parent = parent
	
	local header = createTextLabel(dropdown, "Header", "Visible Columns", 
		UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0), PANEL_COLORS.text, 11)
	header.Font = Enum.Font.SourceSansBold
	
	-- Create checkbox for each column
	local yOffset = 25
	for _, colName in ipairs(columns) do
		local row = Instance.new("Frame")
		row.Name = "ColumnRow_" .. colName
		row.Size = UDim2.new(1, 0, 0, 20)
		row.Position = UDim2.new(0, 0, 0, yOffset)
		row.BackgroundTransparency = 1
		row.Parent = dropdown
		
		-- Checkbox
		local checkbox = Instance.new("Frame")
		checkbox.Name = "Checkbox"
		checkbox.Size = UDim2.new(0, 15, 0, 15)
		checkbox.Position = UDim2.new(0, 5, 0, 2)
		checkbox.BackgroundColor3 = PANEL_COLORS.header
		checkbox.BorderColor3 = PANEL_COLORS.border
		checkbox.Parent = row
		
		-- Check mark (visible when selected)
		local checkmark = Instance.new("TextLabel")
		checkmark.Name = "Checkmark"
		checkmark.Size = UDim2.new(1, 0, 1, 0)
		checkmark.Position = UDim2.new(0, 0, 0, 0)
		checkmark.BackgroundTransparency = 1
		checkmark.TextColor3 = PANEL_COLORS.success
		checkmark.TextSize = 12
		checkmark.Font = Enum.Font.SourceSansBold
		checkmark.Text = "✓"
		checkmark.Visible = true
		checkmark.Parent = checkbox
		
		-- Column name label
		local label = createTextLabel(row, "Label", colName, 
			UDim2.new(1, -30, 1, 0), UDim2.new(0, 25, 0, 0), PANEL_COLORS.text, 10)
		label.TextXAlignment = Enum.TextXAlignment.Left
		
		-- Click to toggle
		checkbox.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				checkmark.Visible = not checkmark.Visible
				if onColumnToggle then
					onColumnToggle(colName, checkmark.Visible)
				end
			end
		end)
		
		yOffset = yOffset + 22
	end
	
	dropdown.Size = UDim2.new(0, 150, 0, yOffset + 5)
	
	return dropdown
end

return PreviewPanel

