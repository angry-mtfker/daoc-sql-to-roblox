# DAoC Roblox Experience - Enhanced Implementation Plan

## Task Overview
Implement a fully functional DAoC Roblox Experience with character creation, RNG weapon generation, inventory system with Roblox asset IDs, and a merchant NPC system.

---

## Phase 1: Data Foundation
### 1.1 RaceData.lua
- [ ] Parse race.sql from opendaoc-db-core
- [ ] Extract playable races (Briton, Elf, Highlander, Saracen, etc.)
- [ ] Define race bonuses/penalties (from resistance values)
- [ ] Starting locations per realm
- [ ] Race descriptions and lore
- [ ] Roblox asset IDs for race-specific appearances

### 1.2 ClassData.lua
- [ ] Parse classxspecialization.sql
- [ ] Class list for each realm (Albion/Midgard/Hibernia)
- [ ] Class abilities and specializations
- [ ] Class stat requirements
- [ ] Weapon proficiencies per class
- [ ] Roblox asset IDs for class-specific gear

### 1.3 RealmData.lua
- [ ] Realm information (Albion/Midgard/Hibernia)
- [ ] Starting zones per realm
- [ ] Realm-specific item templates
- [ ] Roblox asset IDs for realm visuals

---

## Phase 2: Character System
### 2.1 CharacterDataManager.lua
- [ ] Character data structure (name, race, class, realm, stats)
- [ ] DataStore integration for save/load
- [ ] Race/Class/Realm validation
- [ ] Starting equipment assignment
- [ ] Stat initialization based on race/class
- [ ] Experience and leveling system
- [ ] Character deletion functionality

### 2.2 CharacterCreationUI.lua
- [ ] Login screen with username input
- [ ] Realm selection (Albion/Midgard/Hibernia)
- [ ] Race selection with descriptions and bonuses
- [ ] Class selection based on realm
- [ ] Character preview with visual feedback
- [ ] Name validation (no profanity, length limits)
- [ ] Character creation confirmation

---

## Phase 3: Weapon System
### 3.1 WeaponData.lua
- [ ] Parse itemtemplate.sql for weapons
- [ ] Weapon categories (sword, axe, hammer, etc.)
- [ ] Weapon stats (damage, speed, range)
- [ ] Class restrictions per weapon
- [ ] Realm restrictions per weapon
- [ ] Roblox asset IDs for weapon models

### 3.2 RNGWeaponGenerator.lua
- [ ] Random weapon generation system
- [ ] Seed-based RNG for consistent results
- [ ] Class-appropriate weapon selection
- [ ] Realm-appropriate weapon selection
- [ ] Quality tiers (Common, Uncommon, Rare, Epic)
- [ ] Stat randomization within tiers
- [ ] Weapon naming generator
- [ ] Item level scaling based on character level

---

## Phase 4: Inventory System
### 4.1 InventoryPanel.lua
- [ ] Grid-based inventory UI
- [ ] Item slots (default 50 slots)
- [ ] Item drag-and-drop
- [ ] Item tooltips with stats
- [ ] Equip/Unequip functionality
- [ ] Item usage (consumables)
- [ ] Stack management
- [ ] Currency display (gold/silver/copper)

### 4.2 ItemIcons.lua
- [ ] Roblox asset ID mapping for items
- [ ] Category-based icon system
- [ ] Rarity color coding
- [ ] Dynamic icon loading
- [ ] Placeholder images for missing assets

---

## Phase 5: Merchant System
### 5.1 MerchantNPC.lua
- [ ] 3D NPC model with dialogue UI
- [ ] Load merchant model from Roblox assets
- [ ] Realm-specific merchant appearances
- [ ] Shop interface (ScreenGui)
- [ ] Buy/Sell functionality
- [ ] Currency exchange
- [ ] Inventory management for merchant

### 5.2 MerchantInventory.lua
- [ ] Class-appropriate item selection
- [ ] Realm-appropriate item selection
- [ ] Level-appropriate pricing
- [ ] Stock regeneration (restock intervals)
- [ ] Rare item rotation
- [ ] Reputation-based discounts

### 5.3 ShopUI.lua
- [ ] Shop panel with categories
- [ ] Item grid with icons
- [ ] Price display
- [ ] Buy quantity selector
- [ ] Sell value display
- [ ] Transaction confirmation

---

## Phase 6: Player HUD
### 6.1 PlayerHUD.lua
- [ ] Main HUD container
- [ ] Health bar (real-time updates)
- [ ] Mana bar (real-time updates)
- [ ] Experience bar and level display
- [ ] Mini-map component
- [ ] Realm/Class info display
- [ ] Target frame (for combat)
- [ ] Buff/Debuff icons

### 6.2 ActionBar.lua
- [ ] Hotkey bindings (1-9)
- [ ] Ability icons
- [ ] Cooldown visualization
- [ ] Drag-and-drop from spellbook
- [ ] Keybind configuration

---

## File Structure
```
DAoCConverterForRoblox/
├── Core/
│   ├── SQLParser.lua (existing)
│   ├── DataConverter.lua (existing)
│   ├── ExportManager.lua (existing)
│   └── DebugSystem.lua (existing)
├── Experience/
│   ├── GameManager.lua (update)
│   ├── CharacterDataManager.lua (new)
│   ├── RaceData.lua (new)
│   ├── ClassData.lua (new)
│   ├── RealmData.lua (new)
│   ├── WeaponData.lua (new)
│   ├── RNGWeaponGenerator.lua (new)
│   ├── MerchantNPC.lua (new)
│   ├── MerchantInventory.lua (new)
│   └── CharacterService.lua (new)
├── UI/
│   ├── CharacterCreationUI.lua (new)
│   ├── PlayerHUD.lua (new)
│   ├── ActionBar.lua (new)
│   ├── InventoryPanel.lua (new)
│   ├── ShopUI.lua (new)
│   ├── DebugPanel.lua (existing)
│   ├── PreviewPanel.lua (existing)
│   └── ProgressIndicator.lua (existing)
└── Assets/
    ├── WeaponModels/ (new)
    ├── MerchantModels/ (new)
    └── IconAssets/ (new)
```

---

## Success Criteria
1. ✅ Players must create a character before playing
2. ✅ Race selection shows proper descriptions and bonuses
3. ✅ Class selection based on DAoC class system
4. ✅ Realm selection with 3 choices (Albion/Midgard/Hibernia)
5. ✅ RNG weapon generation for each class
