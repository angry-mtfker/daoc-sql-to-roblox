# DAoC Roblox Experience - Implementation TODO

## Task Overview
Implement all necessary components to make the DAoC Roblox Experience fully functional and playable with a forced login screen, character creation based on races/classes/realms, and a complete player UI.

---

## Phase 1: Character Creation System
- [ ] 1.1 Create CharacterCreationUI.lua
  - [ ] Race selection panel with descriptions
  - [ ] Class selection based on DAoC classes
  - [ ] Realm selection (Albion/Midgard/Hibernia)
  - [ ] Character preview with visual feedback
  - [ ] Validation and character creation flow

- [ ] 1.2 Create CharacterDataManager.lua
  - [ ] Character data structure
  - [ ] Save/Load functionality
  - [ ] Race/Class/Realm validation
  - [ ] Starting equipment assignment
  - [ ] Stat initialization based on race/class

---

## Phase 2: Player HUD System
- [ ] 2.1 Create PlayerHUD.lua
  - [ ] Main HUD container
  - [ ] Health bar with real-time updates
  - [ ] Mana bar with real-time updates
  - [ ] Experience bar and level display
  - [ ] Mini-map component
  - [ ] Inventory panel
  - [ ] Abilities hotbar
  - [ ] Realm/Class info display
  - [ ] Target frame (for combat)

- [ ] 2.2 Create ActionBar.lua
  - [ ] Hotkey bindings
  - [ ] Ability icons
  - [ ] Cooldown visualization
  - [ ] Drag-and-drop support

- [ ] 2.3 Create InventoryPanel.lua
  - [ ] Grid-based inventory
  - [ ] Item tooltips
  - [ ] Equip/Unequip functionality
  - [ ] Item usage

---

## Phase 3: Game Manager Integration
- [ ] 3.1 Update GameManager.lua
  - [ ] Integrate CharacterCreationUI on join
  - [ ] Connect HUD to player data
  - [ ] Implement character spawn system
  - [ ] Add death/respawn logic
  - [ ] Level up system
  - [ ] Experience gain system

- [ ] 3.2 Create CharacterService.lua
  - [ ] Character creation events
  - [ ] Character loading
  - [ ] Character deletion
  - [ ] Multiple character support

---

## Phase 4: Data Integration
- [ ] 4.1 Create RaceData.lua
  - [ ] Race list from race.sql
  - [ ] Race bonuses/penalties
  - [ ] Starting locations per realm

- [ ] 4.2 Create ClassData.lua
  - [ ] Class list from classxspecialization.sql
  - [ ] Class abilities
  - [ ] Class stats

- [ ] 4.3 Create RealmData.lua
  - [ ] Realm information
  - [ ] Realm starting zones
  - [ ] Realm-specific content

---

## Phase 5: UI Polish
- [ ] 5.1 Theme System
  - [ ] Realm-specific color schemes
  - [ ] Consistent UI styling
  - [ ] Accessibility options

- [ ] 5.2 Animations
  - [ ] Smooth bar transitions
  - [ ] Panel open/close animations
  - [ ] Damage number effects
  - [ ] Level up celebration

---

## File Structure
```
DAoCConverterForRoblox/
├── Experience/
│   ├── GameManager.lua (update)
│   ├── CharacterService.lua (new)
│   ├── CharacterDataManager.lua (new)
│   ├── RaceData.lua (new)
│   ├── ClassData.lua (new)
│   └── RealmData.lua (new)
└── UI/
    ├── CharacterCreationUI.lua (new)
    ├── PlayerHUD.lua (new)
    ├── ActionBar.lua (new)
    ├── InventoryPanel.lua (new)
    ├── DebugPanel.lua (existing)
    ├── PreviewPanel.lua (existing)
    └── ProgressIndicator.lua (existing)
```

---

## Success Criteria
1. ✅ Players must create a character before playing
2. ✅ Race selection shows proper descriptions and bonuses
3. ✅ Class selection based on DAoC class system
4. ✅ Realm selection with 3 choices (Albion/Midgard/Hibernia)
5. ✅ Full HUD with health, mana, XP bars
6. ✅ Functional inventory system
7. ✅ Abilities hotbar
8. ✅ Mini-map navigation
9. ✅ Character data persistence
10. ✅ Level progression system

---

## Implementation Order
1. CharacterCreationUI.lua - Core login/creation flow
2. CharacterDataManager.lua - Data management
3. PlayerHUD.lua - Main interface
4. RaceData.lua - Race information
5. ClassData.lua - Class information
6. RealmData.lua - Realm information
7. CharacterService.lua - Service layer
8. Update GameManager.lua - Integration
9. ActionBar.lua - Ability bar
10. InventoryPanel.lua - Inventory system

