blo--[[
	DAoC Race Data Module
	=====================
	
	Contains race information extracted from DAoC database.
	Provides race bonuses, descriptions, and starting locations.
	
	Author: DAoC Converter Team
	Version: 1.0.0
--]]

local RaceData = {}

--================================================================================
-- RACE DEFINITIONS
--================================================================================

-- Playable races organized by realm
local PLAYABLE_RACES = {
	ALBION = {
		{
			ID = 1,
			Name = "Briton",
			Description = "The brave and stalwart people of the British Isles. Known for their versatility and adaptability in battle.",
			BonusDescription = "+3 Slash Resistance, +5 Spirit Resistance",
			Resistances = {
				Body = 0,
				Cold = 0,
				Crush = 2,
				Energy = 0,
				Heat = 0,
				Matter = 0,
				Natural = 0,
				Slash = 3,
				Spirit = 5,
				Thrust = 0,
			},
			StartingLocation = Vector3.new(-77500, 0, -65000), -- Cumbria
			Appearance = {
				BodyType = "Human",
				Height = 1.0,
				AssetID = 1087685, -- Briton character model
			},
			StatBonuses = {
				Strength = 0,
				Dexterity = 0,
				Constitution = 1,
				Intelligence = 0,
				Piety = 1,
			},
		},
		{
			ID = 2,
			Name = "Avalonian",
			Description = "Descendants of the ancient mage-priests. Their affinity for magic is legendary across the realms.",
			BonusDescription = "+3 Slash Resistance, +5 Spirit Resistance",
			Resistances = {
				Body = 0,
				Cold = 0,
				Crush = 2,
				Energy = 0,
				Heat = 0,
				Matter = 0,
				Natural = 0,
				Slash = 3,
				Spirit = 5,
				Thrust = 0,
			},
			StartingLocation = Vector3.new(-77500, 0, -65000), -- Cumbria
			Appearance = {
				BodyType = "Human",
				Height = 0.98,
				AssetID = 1087686, -- Avalonian character model
			},
			StatBonuses = {
				Strength = 0,
				Dexterity = 0,
				Constitution = 0,
				Intelligence = 2,
				Piety = 1,
			},
		},
		{
			ID = 3,
			Name = "Highlander",
			Description = "Fierce warriors from the Scottish Highlands. Their toughness and resilience are unmatched.",
			BonusDescription = "+5 Cold Resistance, +3 Crush Resistance",
			Resistances = {
				Body = 0,
				Cold = 5,
				Crush = 3,
				Energy = 0,
				Heat = 0,
				Matter = 0,
				Natural = 0,
				Slash = 2,
				Spirit = 0,
				Thrust = 0,
			},
			StartingLocation = Vector3.new(-77500, 0, -65000), -- Cumbria
			Appearance = {
				BodyType = "Human",
				Height = 1.05,
				AssetID = 1087687, -- Highlander character model
			},
			StatBonuses = {
				Strength = 2,
				Dexterity = 0,
				Constitution = 2,
				Intelligence = 0,
				Piety = 0,
			},
		},
		{
			ID = 4,
			Name = "Saracen",
			Description = "Mysterious warriors from distant deserts. Quick and nimble, they strike before their enemies can react.",
			BonusDescription = "+5 Heat Resistance, +2 Slash Resistance",
			Resistances = {
				Body = 0,
				Cold = 0,
				Crush = 0,
				Energy = 0,
				Heat = 5,
				Matter = 0,
				Natural = 0,
				Slash = 2,
				Spirit = 0,
				Thrust = 3,
			},
			StartingLocation = Vector3.new(-77500, 0, -65000), -- Cumbria
			Appearance = {
				BodyType = "Human",
				Height = 0.95,
				AssetID = 1087688, -- Saracen character model
			},
			StatBonuses = {
				Strength = 0,
				Dexterity = 2,
				Constitution = 0,
				Intelligence = 1,
				Piety = 0,
			},
		},
		{
			ID = 19,
			Name = "Albion Minotaur",
			Description = "Massive warriors with incredible strength. The chosen people of the smith-god.",
			BonusDescription = "+3 Cold Resistance, +4 Crush Resistance",
			Resistances = {
				Body = 0,
				Cold = 3,
				Crush = 4,
				Energy = 0,
				Heat = 3,
				Matter = 0,
				Natural = 0,
				Slash = 0,
				Spirit = 0,
				Thrust = 0,
			},
			StartingLocation = Vector3.new(-77500, 0, -65000), -- Cumbria
			Appearance = {
				BodyType = "Minotaur",
				Height = 1.4,
				AssetID = 1087689, -- Minotaur character model
			},
			StatBonuses = {
				Strength = 3,
				Dexterity = -1,
				Constitution = 3,
				Intelligence = -1,
				Piety = 0,
			},
		},
	},
	MIDGARD = {
		{
			ID = 5,
			Name = "Norseman",
			Description = "Hardy warriors from the frozen north. Their battle fury is legendary.",
			BonusDescription = "+5 Cold Resistance, +3 Slash Resistance",
			Resistances = {
				Body = 0,
				Cold = 5,
				Crush = 2,
				Energy = 0,
				Heat = 0,
				Matter = 0,
				Natural = 0,
				Slash = 3,
				Spirit = 0,
				Thrust = 0,
			},
			StartingLocation = Vector3.new(65000, 0, -65000), -- Jarnfast
			Appearance = {
				BodyType = "Human",
				Height = 1.05,
				AssetID = 1087690, -- Norseman character model
			},
			StatBonuses = {
				Strength = 2,
				Dexterity = 0,
				Constitution = 1,
				Intelligence = 0,
				Piety = 0,
			},
		},
		{
			ID = 6,
			Name = "Troll",
			Description = "Massive creatures with incredible regenerative abilities. Their strength is unmatched.",
			BonusDescription = "+5 Matter Resistance, +3 Slash Resistance",
			Resistances = {
				Body = 0,
				Cold = 0,
				Crush = 0,
				Energy = 0,
				Heat = 0,
				Matter = 5,
				Natural = 0,
				Slash = 3,
				Spirit = 0,
				Thrust = 2,
			},
			StartingLocation = Vector3.new(65000, 0, -65000), -- Jarnfast
			Appearance = {
				BodyType = "Troll",
				Height = 1.5,
				AssetID = 1087691, -- Troll character model
			},
			StatBonuses = {
				Strength = 3,
				Dexterity = 0,
				Constitution = 3,
				Intelligence = -2,
				Piety = -1,
			},
		},
		{
			ID = 7,
			Name = "Dwarf",
			Description = "Master craftspeople and stalwart defenders. Their resilience in battle is legendary.",
			BonusDescription = "+5 Body Resistance, +2 Slash Resistance",
			Resistances = {
				Body = 5,
				Cold = 0,
				Crush = 0,
				Energy = 0,
				Heat = 0,
				Matter = 0,
				Natural = 0,
				Slash = 2,
				Spirit = 0,
				Thrust = 3,
			},
			StartingLocation = Vector3.new(65000, 0, -65000), -- Jarnfast
			Appearance = {
				BodyType = "Dwarf",
				Height = 0.8,
				AssetID = 1087692, -- Dwarf character model
			},
			StatBonuses = {
				Strength = 1,
				Dexterity = 0,
				Constitution = 3,
				Intelligence = 0,
				Piety = 1,
			},
		},
		{
			ID = 8,
			Name = "Kobold",
			Description = "Small but cunning creatures. They excel at finding weaknesses in their enemies.",
			BonusDescription = "+5 Crush Resistance, +5 Energy Resistance",
			Resistances = {
				Body = 0,
				Cold = 0,
				Crush = 5,
				Energy = 5,
				Heat = 0,
				Matter = 0,
				Natural = 0,
				Slash = 0,
				Spirit = 0,
				Thrust = 0,
			},
			StartingLocation = Vector3.new(65000, 0, -65000), -- Jarnfast
			Appearance = {
				BodyType = "Kobold",
				Height = 0.7,
				AssetID = 1087693, -- Kobold character model
			},
			StatBonuses = {
				Strength = 0,
				Dexterity = 3,
				Constitution = 0,
				Intelligence = 1,
				Piety = 0,
			},
		},
		{
			ID = 20,
			Name = "Midgard Minotaur",
			Description = "Massive warriors with incredible strength. The chosen people of the smith-god.",
			BonusDescription = "+3 Cold Resistance, +4 Crush Resistance",
			Resistances = {
				Body = 0,
				Cold = 3,
				Crush = 4,
				Energy = 0,
				Heat = 3,
				Matter = 0,
				Natural = 0,
				Slash = 0,
				Spirit = 0,
				Thrust = 0,
			},
			StartingLocation = Vector3.new(65000, 0, -65000), -- Jarnfast
			Appearance = {
				BodyType = "Minotaur",
				Height = 1.4,
				AssetID = 1087694, -- Minotaur character model
			},
			StatBonuses = {
				Strength = 3,
				Dexterity = -1,
				Constitution = 3,
				Intelligence = -1,
				Piety = 0,
			},
		},
	},
	HIBERNIA = {
		{
			ID = 11,
			Name = "Elf",
			Description = "Ancient beings of grace and magical power. Their affinity for nature magic is unmatched.",
			BonusDescription = "+2 Slash Resistance, +5 Spirit Resistance",
			Resistances = {
				Body = 0,
				Cold = 0,
				Crush = 0,
				Energy = 0,
				Heat = 0,
				Matter = 0,
				Natural = 0,
				Slash = 2,
				Spirit = 5,
				Thrust = 3,
			},
			StartingLocation = Vector3.new(0, 0, 65000), -- Tir na Nog
			Appearance = {
				BodyType = "Elf",
				Height = 1.1,
				AssetID = 1087695, -- Elf character model
			},
			StatBonuses = {
				Strength = 0,
				Dexterity = 1,
				Constitution = 0,
				Intelligence = 2,
				Piety = 1,
			},
		},
		{
			ID = 12,
			Name = "Lurikeen",
			Description = "Swift and nimble forest dwellers. Their speed in battle is legendary.",
			BonusDescription = "+5 Crush Resistance, +5 Energy Resistance",
			Resistances = {
				Body = 0,
				Cold = 0,
				Crush = 5,
				Energy = 5,
				Heat = 0,
				Matter = 0,
				Natural = 0,
				Slash = 0,
				Spirit = 0,
				Thrust = 0,
			},
			StartingLocation = Vector3.new(0, 0, 65000), -- Tir na Nog
			Appearance = {
				BodyType = "Elf",
				Height = 0.85,
				AssetID = 1087696, -- Lurikeen character model
			},
			StatBonuses = {
				Strength = 0,
				Dexterity = 3,
				Constitution = 0,
				Intelligence = 1,
				Piety = 0,
			},
		},
		{
			ID = 9,
			Name = "Celt",
			Description = "Ancient warriors of the misty isles. Their connection to the Otherworld gives them unique powers.",
			BonusDescription = "+2 Crush Resistance, +3 Slash Resistance",
			Resistances = {
				Body = 0,
				Cold = 0,
				Crush = 2,
				Energy = 0,
				Heat = 0,
				Matter = 0,
				Natural = 0,
				Slash = 3,
				Spirit = 5,
				Thrust = 0,
			},
			StartingLocation = Vector3.new(0, 0, 65000), -- Tir na Nog
			Appearance = {
				BodyType = "Human",
				Height = 1.02,
				AssetID = 1087697, -- Celt character model
			},
			StatBonuses = {
				Strength = 1,
				Dexterity = 1,
				Constitution = 0,
				Intelligence = 0,
				Piety = 2,
			},
		},
		{
			ID = 10,
			Name = "Firbolg",
			Description = "Ancient giants with deep connection to nature. Their wisdom and strength are legendary.",
			BonusDescription = "+3 Crush Resistance, +5 Heat Resistance",
			Resistances = {
				Body = 0,
				Cold = 0,
				Crush = 3,
				Energy = 0,
				Heat = 5,
				Matter = 0,
				Natural = 0,
				Slash = 2,
				Spirit = 0,
				Thrust = 0,
			},
			StartingLocation = Vector3.new(0, 0, 65000), -- Tir na Nog
			Appearance = {
				BodyType = "Giant",
				Height = 1.3,
				AssetID = 1087698, -- Firbolg character model
			},
			StatBonuses = {
				Strength = 2,
				Dexterity = 0,
				Constitution = 2,
				Intelligence = 0,
				Piety = 1,
			},
		},
		{
			ID = 21,
			Name = "Hibernia Minotaur",
			Description = "Massive warriors with incredible strength. The chosen people of the smith-god.",
			BonusDescription = "+3 Cold Resistance, +4 Crush Resistance",
			Resistances = {
				Body = 0,
				Cold = 3,
				Crush = 4,
				Energy = 0,
				Heat = 3,
				Matter = 0,
				Natural = 0,
				Slash = 0,
				Spirit = 0,
				Thrust = 0,
			},
			StartingLocation = Vector3.new(0, 0, 65000), -- Tir na Nog
			Appearance = {
				BodyType = "Minotaur",
				Height = 1.4,
				AssetID = 1087699, -- Minotaur character model
			},
			StatBonuses = {
				Strength = 3,
				Dexterity = -1,
				Constitution = 3,
				Intelligence = -1,
				Piety = 0,
			},
		},
	},
}

-- All playable races (flat list)
local ALL_RACES = {}

for realm, races in pairs(PLAYABLE_RACES) do
	for _, race in ipairs(races) do
		race.Realm = realm
		table.insert(ALL_RACES, race)
	end
end

--================================================================================
-- PUBLIC API
--================================================================================

function RaceData.getRaceByName(name)
	for _, race in ipairs(ALL_RACES) do
		if race.Name == name then
			return race
		end
	end
	return nil
end

function RaceData.getRaceByID(id)
	for _, race in ipairs(ALL_RACES) do
		if race.ID == id then
			return race
		end
	end
	return nil
end

function RaceData.getRacesByRealm(realm)
	return PLAYABLE_RACES[realm] or {}
end

function RaceData.getAllRaces()
	return ALL_RACES
end

function RaceData.getPlayableRaces()
	return ALL_RACES
end

function RaceData.getRealmColors()
	return {
		ALBION = Color3.fromRGB(180, 180, 200), -- Silver/White
		MIDGARD = Color3.fromRGB(100, 140, 180), -- Blue/Ice
		HIBERNIA = Color3.fromRGB(80, 180, 100), -- Green
	}
end

function RaceData.getRaceStatBonuses(raceName)
	local race = RaceData.getRaceByName(raceName)
	if race then
		return race.StatBonuses
	end
	return {
		Strength = 0,
		Dexterity = 0,
		Constitution = 0,
		Intelligence = 0,
		Piety = 0,
	}
end

function RaceData.getRaceResistances(raceName)
	local race = RaceData.getRaceByName(raceName)
	if race then
		return race.Resistances
	end
	return {
		Body = 0,
		Cold = 0,
		Crush = 0,
		Energy = 0,
		Heat = 0,
		Matter = 0,
		Natural = 0,
		Slash = 0,
		Spirit = 0,
		Thrust = 0,
	}
end

function RaceData.getStartingLocation(raceName)
	local race = RaceData.getRaceByName(raceName)
	if race then
		return race.StartingLocation
	end
	return Vector3.new(0, 10, 0)
end

function RaceData.getAppearance(raceName)
	local race = RaceData.getRaceByName(raceName)
	if race then
		return race.Appearance
	end
	return {
		BodyType = "Human",
		Height = 1.0,
		AssetID = 1087685,
	}
end

--================================================================================
-- INITIALIZATION
--================================================================================

local function init()
	print("[RaceData] Initialized with " .. #ALL_RACES .. " playable races")
	
	for realm, races in pairs(PLAYABLE_RACES) do
		print(string.format("[RaceData] %s: %d races", realm, #races))
	end
end

init()

return RaceData

