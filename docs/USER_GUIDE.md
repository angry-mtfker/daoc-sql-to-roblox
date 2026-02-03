# DAoC SQL to Roblox Converter - User Guide

## Overview

The DAoC SQL to Roblox Converter is a Roblox Studio plugin that allows you to convert DAoC (Dark Age of Camelot) SQL database files to Roblox Lua data formats. This enables you to use game data like abilities, spells, items, and NPC definitions in your Roblox games.

## Installation

### From Roblox Studio

1. Open Roblox Studio
2. Go to the "Plugins" tab
3. Click "Manage Plugins"
4. Click "Install Plugin" and select the `DAoCConverterForRoblox` folder
5. The plugin will appear in your installed plugins list

### Manual Installation

1. Copy the `DAoCConverterForRoblox` folder to your Roblox Studio plugins directory
2. The plugin will automatically load when you open Roblox Studio

## Getting Started

### Opening the Plugin

1. In Roblox Studio, go to the "Plugins" tab
2. Find "DAoC SQL to Roblox Converter" in the plugin toolbar
3. Click the button to open the converter panel

### The Interface

The converter interface consists of:

- **Drop Zone**: Drag and drop SQL files here, or click to browse
- **File List**: Shows queued files for conversion
- **Settings**: Configure output format and naming
- **Convert Button**: Start the conversion process
- **Progress Indicator**: Shows conversion progress

## Supported SQL Files

The plugin supports various DAoC SQL table types:

| Table Type | Description | Example Use |
|------------|-------------|-------------|
| `ability` | Character abilities and realm abilities | Combat skills, passive bonuses |
| `spell` | Spell definitions | Magic effects, buffs, debuffs |
| `itemtemplate` | Item definitions | Weapons, armor, consumables |
| `npctemplate` | NPC/creature templates | Enemies, merchants, quest givers |
| `mob` | Mobile entity definitions | Spawns, world objects |
| `style` | Combat styles | Style combinations, damage modifiers |
| `specialization` | Skill specializations | Class progression trees |

## Converting Files

### Step 1: Prepare Your SQL Files

1. Ensure your SQL files are from the DAoC database
2. Files should have the `.sql` extension
3. Each file should contain a single table definition

### Step 2: Import Files

**Method 1: Drag and Drop**
1. Open the DAoC Converter plugin
2. Drag your SQL files onto the drop zone
3. Files will be automatically added to the queue

**Method 2: Browse**
1. Click on the drop zone
2. Navigate to your SQL files
3. Select the files you want to convert

### Step 3: Configure Settings

Configure the output settings before converting:

| Setting | Description | Default |
|---------|-------------|---------|
| Output Format | Format for converted data (Modulescript) | Modulescript |
| Output Folder | Where to create the data modules | DAoCData |
| Pretty Print | Format output with indentation | Enabled |
| Auto Export | Automatically export after conversion | Enabled |

### Step 4: Convert

1. Review the files in the queue
2. Click "Convert Files" to start
3. Watch the progress indicator
4. Check the status for any errors

### Step 5: Access Converted Data

Converted data is stored in `ServerScriptService.DAoCData` as ModuleScripts. Each table becomes a ModuleScript with the following structure:

```lua
local ability = {}

-- Metadata
ability.Metadata = {
    TableName = "ability",
    RecordCount = 370,
    ColumnCount = 8,
    GeneratedAt = "2024-01-01 12:00:00",
}

-- Data records
ability.Data = {
    [1] = {
        AbilityID = 1,
        KeyName = "Augmented Strength",
        Name = "Augmented Strength",
        InternalID = 129,
        Description = "Increases Strength by the listed amount per level.",
        IconID = 0,
        Implementation = "DOL.GS.RealmAbilities.RAStrengthEnhancer",
        LastTimeRowUpdated = "2000-01-01 00:00:00",
    },
    -- ... more records
}

-- Helper functions
function ability.GetRecord(index)
    return self.Data[index]
end

function ability.GetRecordCount()
    return self.Data.RecordCount
end

function ability.FindByField(fieldName, value)
    local results = {}
    for i, record in ipairs(self.Data) do
        if record[fieldName] == value then
            table.insert(results, {index = i, record = record})
        end
    end
    return results
end

return ability
```

## Using Converted Data in Your Game

### Loading Data Modules

```lua
-- ServerScriptService
local ServerScriptService = game:GetService("ServerScriptService")

-- Load the ability data module
local abilityData = require(ServerScriptService.DAoCData.ability)

-- Access records
local firstAbility = abilityData.GetRecord(1)
print(firstAbility.Name)  -- "Augmented Strength"

-- Find abilities by field
local strengthAbilities = abilityData.FindByField("KeyName", "%Strength")
```

### Game Integration Examples

**Using Abilities:**
```lua
local abilityData = require(ServerScriptService.DAoCData.ability)

-- Find and use an ability
local ability = abilityData.FindByField("KeyName", "Sprint")[1]
if ability then
    local abilityRecord = ability.record
    print(string.format("Using ability: %s", abilityRecord.Name))
end
```

**Using Spells:**
```lua
local spellData = require(ServerScriptService.DAoCData.spell)

-- Find a spell by name
local healSpell = spellData.FindByField("Name", "Heal")[1]
if healSpell then
    local spell = healSpell.record
    print(string.format("Spell: %s, Power: %d, Range: %d", 
        spell.Name, spell.Power, spell.Range))
end
```

## Troubleshooting

### Common Issues

**"No files to convert"**
- Ensure your SQL files have the `.sql` extension
- Check that files are valid SQL files from DAoC database

**"Invalid parsed data"**
- The SQL file may be corrupted or in an unsupported format
- Check the file contents for errors

**Plugin not loading**
- Ensure all required files are present in the plugin folder
- Check the output console for error messages

### Getting Help

1. Check the debug panel for error details
2. Review the console output for warning messages
3. Ensure your SQL files follow the standard DAoC format

## Best Practices

1. **Backup your data**: Keep original SQL files as backup
2. **Test with small files**: Start with small SQL files before batch processing
3. **Use pretty print**: Enable for easier debugging
4. **Check converted data**: Verify a few records after conversion
5. **Version control**: Commit converted Lua files to source control

## Additional Resources

- **SQL Parser**: Handles CREATE TABLE and REPLACE INTO statements
- **Data Converter**: Converts SQL types to Lua types
- **Export Manager**: Creates properly formatted ModuleScripts
- **Debug System**: Built-in logging and error tracking

## Version History

- **1.0.0**: Initial release
  - Core SQL parsing functionality
  - Support for multiple table types
  - Drag-and-drop interface
  - ModuleScript export
  - Debug system integration

---

For more information about the DAoC SQL to Roblox Converter, check the README.md file or the source code in the `DAoCConverterForRoblox` folder.

