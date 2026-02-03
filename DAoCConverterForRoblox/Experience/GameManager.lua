--[[
	DAoC Experience - Game Manager
	==============================
	
	Main game manager for the Roblox DAoC experience.
	Loads converted DAoC SQL data and manages game systems.
	
	Author: DAoC Converter Team
	Version: 1.0.0
--]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Game Configuration
local CONFIG = {
	autoSaveInterval = 60,
	startingHealth = 100,
	startingMana = 50,
	respawnTime = 5,
	dayLength = 120,
}

local GameManager = {
	_initialized = false,
	_players = {},
	_dataModules = {},
}

--================================================================================
-- INITIALIZATION
--================================================================================

function GameManager.init()
	if GameManager._initialized then return end
	
	print("[GameManager] Initializing DAoC Experience...")
	
	GameManager.loadDataModules()
	GameManager.setupPlayerHandlers()
	GameManager.setupGameEvents()
	GameManager.startGameLoop()
	
	GameManager._initialized = true
	print("[GameManager] DAoC Experience initialized!")
end

function GameManager.loadDataModules()
	print("[GameManager] Loading converted DAoC data...")
	
	local dataFolder = game:GetService("ServerScriptService"):FindFirstChild("DAoCData")
	
	if dataFolder then
		for _, module in ipairs(dataFolder:GetChildren()) do
			if module:IsA("ModuleScript") then
				local success, data = pcall(function()
					return require(module)
				end)
				
				if success and data then
					GameManager._dataModules[module.Name] = data
					local recordCount = data.Metadata and data.Metadata.RecordCount or #data.Data
					print(string.format("[GameManager] Loaded %s: %d records", module.Name, recordCount))
				end
			end
		end
	else
		warn("[GameManager] DAoCData folder not found. Run the converter plugin first!")
	end
end

--================================================================================
-- PLAYER SYSTEM
--================================================================================

function GameManager.setupPlayerHandlers()
	Players.PlayerAdded:Connect(function(player)
		GameManager.onPlayerJoined(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		GameManager.onPlayerLeft(player)
	end)
	
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			GameManager.onCharacterSpawned(player, character)
		end)
	end)
end

function GameManager.onPlayerJoined(player)
	print(string.format("[GameManager] %s joined the game", player.Name))
	
	GameManager._players[player.UserId] = {
		name = player.Name,
		character = nil,
		stats = {
			health = CONFIG.startingHealth,
			maxHealth = CONFIG.startingHealth,
			mana = CONFIG.startingMana,
			level = 1,
			experience = 0,
		},
		inventory = {},
		position = Vector3.new(0, 10, 0),
	}
	
	GameManager.spawnPlayer(player)
end

function GameManager.onPlayerLeft(player)
	print(string.format("[GameManager] %s left the game", player.Name))
	GameManager._players[player.UserId] = nil
end

function GameManager.onCharacterSpawned(player, character)
	if GameManager._players[player.UserId] then
		GameManager._players[player.UserId].character = character
	end
	GameManager.createHealthBar(character)
end

function GameManager.spawnPlayer(player)
	local spawnPos = Vector3.new(0, 10, 0)
	pcall(function() player:LoadCharacter() end)
	
	task.wait(0.5)
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		character.HumanoidRootPart.CFrame = CFrame.new(spawnPos)
	end
end

--================================================================================
-- HEALTH SYSTEM
--================================================================================

function GameManager.createHealthBar(character)
	if not character or not character:FindFirstChild("Humanoid") then return end
	
	local healthBar = Instance.new("BillboardGui")
	healthBar.Name = "DAoCHealthBar"
	healthBar.Adornee = character.Head
	healthBar.Size = UDim2.new(0, 100, 0, 20)
	healthBar.AlwaysOnTop = true
	healthBar.MaxDistance = 50
	healthBar.StudsOffset = Vector3.new(0, 2, 0)
	healthBar.Parent = character
	
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	bg.BorderSizePixel = 0
	bg.Parent = healthBar
	
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.Position = UDim2.new(0, 0, 0, 0)
	fill.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
	fill.BorderSizePixel = 0
	fill.Parent = bg
end

function GameManager.modifyHealth(player, amount)
	if not GameManager._players[player.UserId] then return 0 end
	
	local data = GameManager._players[player.UserId]
	data.stats.health = math.max(0, math.min(data.stats.maxHealth, data.stats.health + amount))
	
	GameManager.updateHealthBar(player)
	
	if data.stats.health <= 0 then
		GameManager.handleDeath(player)
	end
	
	return data.stats.health
end

function GameManager.updateHealthBar(player)
	if not GameManager._players[player.UserId] then return end
	
	local data = GameManager._players[player.UserId]
	local character = player.Character
	if not character then return end
	
	local healthBar = character:FindFirstChild("DAoCHealthBar")
	if not healthBar then return end
	
	local bg = healthBar:FindFirstChild("Frame")
	if not bg then return end
	
	local fill = bg:FindFirstChild("Fill")
	if not fill then return end
	
	local percent = data.stats.health / data.stats.maxHealth
	fill.Size = UDim2.new(percent, 0, 1, 0)
	
	if percent > 0.5 then
		fill.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
	elseif percent > 0.25 then
		fill.BackgroundColor3 = Color3.fromRGB(200, 200, 50)
	else
		fill.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	end
end

function GameManager.handleDeath(player)
	print(string.format("[GameManager] %s died", player.Name))
	
	task.delay(CONFIG.respawnTime, function()
		GameManager.spawnPlayer(player)
		if GameManager._players[player.UserId] then
			GameManager._players[player.UserId].stats.health = CONFIG.startingHealth
		end
	end)
end

--================================================================================
-- ABILITY SYSTEM
--================================================================================

function GameManager.useAbility(player, abilityName)
	if not GameManager._players[player.UserId] then return false end
	
	local abilityData = nil
	
	if GameManager._dataModules.ability and GameManager._dataModules.ability.Data then
		for _, ability in ipairs(GameManager._dataModules.ability.Data) do
			if ability.Name == abilityName or ability.AbilityID == abilityName then
				abilityData = ability
				break
			end
		end
	end
	
	if not abilityData then return false end
	
	local playerData = GameManager._players[player.UserId]
	
	if playerData.stats.mana < (abilityData.ManaCost or 0) then return false end
	
	playerData.stats.mana = playerData.stats.mana - (abilityData.ManaCost or 0)
	
	GameManager.executeAbilityEffect(player, abilityData)
	
	return true
end

function GameManager.executeAbilityEffect(player, abilityData)
	local character = player.Character
	if not character then return end
	
	local targetType = abilityData.TargetType or "Self"
	
	if targetType == "Self" then
		if abilityData.HealthBonus then
			GameManager.modifyHealth(player, abilityData.HealthBonus)
		end
	elseif targetType == "Enemy" then
		local target = GameManager.findTarget(character, abilityData.Range or 30)
		if target then
			local damage = abilityData.Damage or 10
			GameManager.modifyHealth(target, -damage)
			GameManager.showDamageNumber(target.Character, damage)
		end
	elseif targetType == "Area" then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			GameManager.applyAreaEffect(hrp.Position, abilityData)
		end
	end
end

function GameManager.findTarget(caster, range)
	local casterPos = caster.HumanoidRootPart.Position
	local closestDist = range
	local closestTarget = nil
	
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= caster.Parent and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (p.Character.HumanoidRootPart.Position - casterPos).Magnitude
			if dist < closestDist then
				closestTarget = p
				closestDist = dist
			end
		end
	end
	
	return closestTarget
end

function GameManager.applyAreaEffect(centerPos, abilityData)
	local effect = Instance.new("Part")
	effect.Size = Vector3.new(10, 1, 10)
	effect.Position = centerPos
	effect.Anchored = true
	effect.CanCollide = false
	effect.Transparency = 0.5
	effect.BrickColor = BrickColor.new("Bright red")
	effect.Parent = workspace
	
	local tween = TweenService:Create(effect, TweenInfo.new(1), {Transparency = 1})
	tween.Completed:Connect(function() effect:Destroy() end)
	tween:Play()
	
	local range = abilityData.AreaRadius or 10
	local damage = abilityData.Damage or 10
	
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (p.Character.HumanoidRootPart.Position - centerPos).Magnitude
			if dist <= range then
				GameManager.modifyHealth(p, -damage)
			end
		end
	end
end

function GameManager.showDamageNumber(character, amount)
	local head = character:FindFirstChild("Head")
	if not head then return end
	
	local bg = Instance.new("BillboardGui")
	bg.Adornee = head
	bg.Size = UDim2.new(0, 50, 0, 30)
	bg.AlwaysOnTop = true
	bg.MaxDistance = 30
	bg.StudsOffset = Vector3.new(0, 2, 0)
	bg.Parent = character
	
	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.fromRGB(255, 50, 50)
	text.TextSize = 24
	text.Font = Enum.Font.SourceSansBold
	text.Text = "-" .. tostring(amount)
	text.Parent = bg
	
	local tween = TweenService:Create(text, TweenInfo.new(1), {
		Position = UDim2.new(0, 0, 0, -2),
		TextTransparency = 1,
	})
	tween.Completed:Connect(function() bg:Destroy() end)
	tween:Play()
end

--================================================================================
-- ITEM SYSTEM
--================================================================================

function GameManager.addItem(player, itemId, quantity)
	if not GameManager._players[player.UserId] then return false end
	
	local itemData = nil
	
	if GameManager._dataModules.itemtemplate and GameManager._dataModules.itemtemplate.Data then
		for _, item in ipairs(GameManager._dataModules.itemtemplate.Data) do
			if item.ItemTemplateID == itemId or item.ID == itemId then
				itemData = item
				break
			end
		end
	end
	
	if not itemData then return false end
	
	local inventory = GameManager._players[player.UserId].inventory
	if not inventory[itemId] then
		inventory[itemId] = { item = itemData, quantity = 0 }
	end
	inventory[itemId].quantity = inventory[itemId].quantity + quantity
	
	return true
end

--================================================================================
-- GAME LOOP
--================================================================================

function GameManager.startGameLoop()
	task.spawn(function()
		while true do
			GameManager.gameUpdate()
			task.wait(1)
		end
	end)
	
	task.spawn(function()
		while true do
			task.wait(CONFIG.autoSaveInterval)
			for _, p in ipairs(Players:GetPlayers()) do
				print(string.format("[GameManager] Auto-saved %s", p.Name))
			end
		end
	end)
end

function GameManager.gameUpdate()
	for _, p in ipairs(Players:GetPlayers()) do
		if GameManager._players[p.UserId] then
			local data = GameManager._players[p.UserId]
			if data.stats.mana < 100 then
				data.stats.mana = math.min(100, data.stats.mana + 1)
			end
		end
	end
	
	local lighting = game:GetService("Lighting")
	local timeOfDay = (tick() / CONFIG.dayLength) % 1
	
	if timeOfDay < 0.25 then
		lighting.Ambient = Color3.fromRGB(100, 100, 120)
	elseif timeOfDay < 0.5 then
		lighting.Ambient = Color3.fromRGB(150, 150, 170)
	elseif timeOfDay < 0.75 then
		lighting.Ambient = Color3.fromRGB(120, 100, 100)
	else
		lighting.Ambient = Color3.fromRGB(60, 60, 80)
	end
end

--================================================================================
-- GAME EVENTS
--================================================================================

function GameManager.setupGameEvents()
	local rs = ReplicatedStorage:FindFirstChild("DAoCEvents")
	if not rs then
		rs = Instance.new("Folder")
		rs.Name = "DAoCEvents"
		rs.Parent = ReplicatedStorage
		
		local useAbility = Instance.new("RemoteFunction")
		useAbility.Name = "UseAbility"
		useAbility.Parent = rs
		
		local useItem = Instance.new("RemoteFunction")
		useItem.Name = "UseItem"
		useItem.Parent = rs
	end
	
	local useAbility = rs:FindFirstChild("UseAbility")
	if useAbility then
		useAbility.OnServerInvoke = function(player, abilityName)
			return GameManager.useAbility(player, abilityName)
		end
	end
end

--================================================================================
-- PUBLIC API
--================================================================================

function GameManager.getPlayerData(player)
	return GameManager._players[player.UserId]
end

function GameManager.getDataModule(name)
	return GameManager._dataModules[name]
end

function GameManager.getAllDataModules()
	return GameManager._dataModules
end

-- Initialize
GameManager.init()

return GameManager

