# Auto-Battler Roguelike

A roguelike auto-battler game built in Godot 4, featuring character collection, meta-progression, and asynchronous PvP.

## Game Overview

Players draft a team of 3 characters and navigate through encounters to improve their team, then battle through combat rounds. Win 10 combats for victory, or lose all reputation for defeat.

## How to Play

### Main Menu
- **PLAY**: Start a new run or resume an existing one
- **COLLECTION**: View and manage your character collection
- **QUIT**: Exit the game

### Character Collection
- View all unlocked characters
- Equip starting items for future runs
- See rank progression and unlocked content
- Unlock new items/skills with gems

### Draft Phase
- Choose from 3 character options
- 2 from your collection, 1 random (may require gems to unlock)
- Use reroll tokens to regenerate options
- Build a team of 3 characters

### Run Loop
Each round consists of:
1. **Encounter Phase**: Choose from 3 encounters to improve your team
2. **Combat Phase**: Choose from 3 battles to fight

### Encounter Types
- **Shop**: Buy items and skills with gold
- **Training Dummy**: Gain XP for one character
- **Treasure Chest**: Instant gold reward
- **Healing Fountain**: Restore team health
- **Skill Trainer**: Learn a skill for free
- **Gambler**: Risk gold for big rewards
- **Elite Challenge**: High rewards for all characters

### Combat
- Choose from AI enemies (Easy/Medium/Hard) or Player Ghosts
- Currently stubbed with win/lose buttons for testing
- Victory: Gain gold and XP
- Defeat: Lose reputation equal to round number

### Victory/Defeat
- **Victory**: Win 10 combats
- **Defeat**: Reach 0 reputation
- Earn gems and character rank XP based on performance

## Debug Controls

### Main Menu
- **D**: Open debug menu
- **T**: Add reroll token

### During Run
- **E**: Complete encounter (if in encounter phase)
- **C**: Complete combat (if in combat phase)
- **G**: Add 50 gold
- **X**: Add 50 XP to first character
- **L**: Lose 5 reputation

## Project Structure

```
res://
├── autoloads/              # Singleton managers
│   ├── game_data.gd        # Master data loading
│   ├── player_account.gd   # Player progression (facade)
│   ├── run_manager.gd      # Active run state
│   ├── scene_manager.gd    # Scene transitions and data passing
│   └── encounter_factory.gd # Encounter generation
├── scripts/
│   ├── constants/
│   │   └── game_constants.gd   # Centralized magic numbers
│   ├── utils/
│   │   ├── stat_calculator.gd  # Single source for stat calculations
│   │   ├── json_persistence.gd # Unified JSON load/save
│   │   └── ui_helpers.gd       # Common UI utilities
│   ├── managers/
│   │   ├── currency_manager.gd     # Focused currency handling
│   │   └── character_collection.gd # Character collection with O(1) lookups
│   ├── data_classes/       # Runtime data classes
│   └── encounters/
│       └── encounter_handlers.gd # Registry-based encounter UI handlers
├── data/                   # JSON game data
│   ├── characters/
│   ├── items/
│   ├── skills/
│   └── encounters/
├── scenes/                 # Godot scenes
│   ├── main.tscn
│   ├── ui/                 # UI screens
│   └── components/         # Reusable components
├── assets/                 # Images and art
└── saves/                  # Save files (user://)
```

## Extending the Game

### Adding New Characters

1. Add character data to `data/characters/characters.json`
2. Create placeholder image in `assets/characters/`
3. Characters automatically appear in drafts and can be unlocked

```json
{
  "id": "char_new_001",
  "name": "New Character",
  "image_path": "res://assets/characters/new.png",
  "base_stats": {
    "basic_attack_damage": 10,
    "speed": 5,
    "defense": 5,
    "health": 100,
    "income": 3
  },
  "rank_rewards": [
    {
      "rank": 1,
      "rewards": [{"type": "item", "id": "item_starter"}]
    }
  ]
}
```

### Adding New Items

1. Add item data to `data/items/items.json` or `item_upgrades.json`
2. Create placeholder image in `assets/items/`
3. Reference item ID in character rank_rewards

```json
{
  "id": "item_new",
  "name": "New Item",
  "description": "Description here.",
  "image_path": "res://assets/items/new.png",
  "stat_modifiers": {"basic_attack_damage": 5},
  "slot": "weapon"
}
```

### Adding New Skills

1. Add skill data to `data/skills/skills.json`
2. Create placeholder image in `assets/skills/`
3. Reference skill ID in character rank_rewards

```json
{
  "id": "skill_new",
  "name": "New Skill",
  "description": "Effect description.",
  "image_path": "res://assets/skills/new.png",
  "effects": [
    {"type": "stat_add", "stat": "basic_attack_damage", "value": 5}
  ],
  "level_requirement": 2
}
```

Effect types:
- `stat_add`: Add flat value to stat
- `stat_multiply`: Multiply stat by value

### Adding New Encounter Types

The encounter system uses a **registry pattern** for extensibility:

**Step 1: Add to Factory Weights** (`autoloads/encounter_factory.gd`)
```gdscript
var encounter_weights: Dictionary = {
    # ... existing types ...
    "new_type": 0.5  # Weight controls frequency
}
```

**Step 2: Add Generation Logic** (in `_create_encounter_data()`)
```gdscript
"new_type":
    encounter_data["name"] = "New Encounter"
    encounter_data["description"] = "Description here."
    encounter_data["image_path"] = "res://assets/encounters/new.png"
    encounter_data["data"] = {
        "custom_field": some_value
    }
```

**Step 3: Register Handler** (`scripts/encounters/encounter_handlers.gd`)
```gdscript
# In _register_default_handlers():
register("new_type", {
    "create_ui": _create_new_type_ui,
    "immediate_complete": false  # true if no user interaction needed
})
```

**Step 4: Implement Handler**
```gdscript
static func _create_new_type_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
    var vbox = VBoxContainer.new()
    # Build UI...
    var on_complete = context.get("on_encounter_complete", Callable())
    # Call on_complete.call() when encounter is done
    return vbox
```

**Step 5: Add Reward Preview** (`scenes/ui/encounter_select.gd`)
```gdscript
# In _get_reward_preview():
"new_type":
    return "Preview text here"
```

### Implementing Real Combat

The combat system is currently stubbed. To implement:

1. Create `CombatManager` singleton in `autoloads/`
2. Define combat rules (turn order, damage calculation, abilities)
3. Create `combat_scene.tscn` with animated battle
4. Replace `combat_stub.tscn` with real combat scene
5. Update `combat_select.gd` to use `SceneManager.go_to("combat_scene")`

Key considerations:
- Use `StatCalculator` for all damage/stat calculations (single source of truth)
- Characters have stats via dictionary: `GameConstants.STAT_ATTACK`, `STAT_SPEED`, etc.
- Use `StatCalculator.apply_modifier()` for skill effects during combat
- Skills may provide passive bonuses or active abilities
- Combat is fully automated (no player input during fight)
- Use `SceneManager.set_scene_data()` to pass combat results back

### Cloud Integration

Save/load is designed for easy cloud migration using `JsonPersistence`:

1. In `player_account.gd` (via `CurrencyManager` and `CharacterCollection`):
   - Replace `JsonPersistence.save_json()` with API POST
   - Replace `JsonPersistence.load_json()` with API GET
   - The facade pattern makes this change minimal
2. Add authentication flow before main menu
3. For ghost players:
   - POST team composition after each run
   - GET random ghost teams for combat options

## Known Limitations

- Combat is stubbed (win/lose buttons only)
- No animations or sound effects
- Basic UI styling
- No settings menu
- Ghost players are randomly generated (not real player data)

## Future Enhancements

- [ ] Implement actual combat system
- [ ] Add cloud save/load
- [ ] Real async PvP with ghost players
- [ ] Animations and visual effects
- [ ] Sound effects and music
- [ ] Settings menu
- [ ] More encounter types (minigames)
- [ ] Character abilities in combat
- [ ] Achievement system
- [ ] Daily challenges

## Technical Notes

- Godot 4.x required
- All game data in JSON for easy modification (loaded via `JsonPersistence`)
- Runtime character instances are clones (don't modify account data)
- Auto-save after every encounter and combat
- Modular encounter system for easy expansion

**Architecture patterns used:**
- `StatCalculator`: Single source of truth for stat calculations (DRY)
- `GameConstants`: Centralized magic numbers (no scattered literals)
- `UIHelpers`: Common UI operations (clear_children, set_texture_safe, format_stat)
- `SceneManager`: Clean scene transitions with data passing
- `PlayerAccount` facade: Delegates to `CurrencyManager` + `CharacterCollection` (SRP)
- `EncounterHandlers`: Registry pattern for encounter UI (OCP)
- Dictionary-based stats: Open for extension without code changes

## Generating Placeholder Assets

Run `scripts/generate_placeholders.gd` from the Godot Editor:
1. Open the script
2. Go to **Script > Run** (Ctrl+Shift+X)
3. Refresh the FileSystem dock to see new images

## Content Summary

- **Characters**: 10 unique classes with different stats and playstyles
- **Items**: 13 base items + 6 item upgrades
- **Skills**: 12 skills with various effects
- **Encounter Types**: 7 different encounter experiences

## Credits

Built as a prototype inspired by The Bazaar and other auto-battler roguelikes.
