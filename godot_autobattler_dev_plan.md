# Godot 4 Auto-Battler - Development Plan

## Game Overview
A roguelike auto-battler inspired by The Bazaar, featuring character collection, meta-progression, and asynchronous PvP. Players draft 3 characters per run, navigate encounters to improve their team, and battle through 10 combat rounds.

---

## Core Systems Architecture

### 1. Data Layer (Pure GDScript Classes)
All game data managed through singleton autoloads that handle persistence and runtime state.

### 2. UI Layer (Control Nodes)
Scene-based UI screens that read from and write to the data layer.

### 3. Runtime Layer (Data Classes)
Instanced character/item/skill data for active runs, separate from account progression.

---

## Project Structure

```
res://
├── autoloads/
│   ├── game_data.gd              # Master data loader (characters, items, skills)
│   ├── player_account.gd          # Player progression, unlocks, currencies
│   ├── run_manager.gd             # Active run state, save/load mid-run
│   └── encounter_factory.gd       # Generates encounters dynamically
├── data/
│   ├── characters/
│   │   └── characters.json        # Master character definitions
│   ├── items/
│   │   ├── items.json             # Starting items
│   │   └── item_upgrades.json     # In-run item upgrades
│   ├── skills/
│   │   └── skills.json            # All skills in game
│   └── encounters/
│       └── encounter_types.json   # Encounter templates
├── scenes/
│   ├── main.tscn                  # Entry point, handles scene transitions
│   ├── ui/
│   │   ├── main_menu.tscn
│   │   ├── collection.tscn
│   │   ├── character_details.tscn
│   │   ├── draft.tscn
│   │   ├── run_view.tscn          # Main run UI (encounters + combat)
│   │   ├── encounter_select.tscn
│   │   ├── encounter_execute.tscn
│   │   ├── combat_select.tscn
│   │   ├── combat_stub.tscn       # Win/Loss buttons for testing
│   │   └── run_results.tscn
│   └── components/
│       ├── character_card.tscn    # Reusable character display
│       ├── item_slot.tscn
│       ├── skill_icon.tscn
│       └── reward_display.tscn
├── scripts/
│   ├── data_classes/
│   │   ├── character_instance.gd  # Runtime character data
│   │   ├── item_instance.gd
│   │   ├── skill_instance.gd
│   │   └── encounter_instance.gd
│   └── encounters/
│       ├── base_encounter.gd      # Abstract base class
│       ├── shop_encounter.gd
│       ├── xp_reward_encounter.gd
│       └── minigame_encounter.gd  # Extensible minigame base
├── assets/
│   ├── characters/
│   ├── items/
│   ├── skills/
│   └── ui/
└── saves/
    ├── player_account.json        # TODO: Replace with cloud service
    └── active_run.json            # Mid-run save state
```

---

## Data Schemas

### Character Master Data (characters.json)
```json
{
  "characters": [
    {
      "id": "char_warrior_001",
      "name": "Brave Knight",
      "image_path": "res://assets/characters/knight.png",
      "base_stats": {
        "basic_attack_damage": 10,
        "speed": 5,
        "defense": 8,
        "health": 100,
        "income": 3
      },
      "rank_rewards": [
        {
          "rank": 1,
          "rewards": [
            {"type": "item", "id": "item_rusty_sword"},
            {"type": "skill", "id": "skill_slash"}
          ]
        },
        {
          "rank": 2,
          "stat_boost": {"basic_attack_damage": 2},
          "rewards": [
            {"type": "item_upgrade", "id": "itemup_iron_sword"},
            {"type": "skill", "id": "skill_shield_bash", "level_requirement": 3}
          ]
        }
      ]
    }
  ]
}
```

### Item Master Data (items.json)
```json
{
  "items": [
    {
      "id": "item_rusty_sword",
      "name": "Rusty Sword",
      "description": "A weathered blade. Better than nothing.",
      "image_path": "res://assets/items/rusty_sword.png",
      "stat_modifiers": {
        "basic_attack_damage": 3
      },
      "slot": "weapon"
    }
  ]
}
```

### Item Upgrade Master Data (item_upgrades.json)
```json
{
  "item_upgrades": [
    {
      "id": "itemup_flaming_sword",
      "name": "Flaming Sword",
      "description": "Replaces equipped weapon with burning fury.",
      "image_path": "res://assets/items/flaming_sword.png",
      "replaces_slot": "weapon",
      "stat_modifiers": {
        "basic_attack_damage": 15
      },
      "level_requirement": 4
    }
  ]
}
```

### Skill Master Data (skills.json)
```json
{
  "skills": [
    {
      "id": "skill_sword_mastery",
      "name": "Sword Mastery",
      "description": "Increases attack damage by 20%.",
      "image_path": "res://assets/skills/sword_mastery.png",
      "effects": [
        {
          "type": "stat_multiply",
          "stat": "basic_attack_damage",
          "value": 1.2
        }
      ],
      "level_requirement": 5
    }
  ]
}
```

### Encounter Type Data (encounter_types.json)
```json
{
  "encounter_types": [
    {
      "type": "shop",
      "name": "Traveling Merchant",
      "description": "Buy items and upgrades with gold.",
      "image_path": "res://assets/encounters/merchant.png",
      "script_path": "res://scripts/encounters/shop_encounter.gd"
    },
    {
      "type": "minigame_memory",
      "name": "Memory Challenge",
      "description": "Match pairs to earn XP.",
      "image_path": "res://assets/encounters/memory_game.png",
      "script_path": "res://scripts/encounters/minigame_encounter.gd",
      "rewards": {
        "xp_range": [50, 150],
        "gold_range": [10, 30]
      }
    }
  ]
}
```

### Player Account Data (player_account.json)
```json
{
  "player_id": "player_12345",
  "currencies": {
    "gems": 1000,
    "reroll_tokens": 0
  },
  "characters": [
    {
      "id": "char_warrior_001",
      "unlocked": true,
      "rank": 3,
      "experience": 450,
      "equipped_items": ["item_rusty_sword"],
      "unlocked_items": ["item_rusty_sword", "item_rusty_shield"],
      "unlocked_item_upgrades": ["itemup_iron_sword"],
      "unlocked_skills": ["skill_slash", "skill_shield_bash"]
    }
  ],
  "unlocked_character_ids": [
    "char_warrior_001",
    "char_mage_001",
    "char_rogue_001",
    "char_cleric_001",
    "char_ranger_001"
  ]
}
```

### Active Run Data (active_run.json)
```json
{
  "run_id": "run_67890",
  "round": 3,
  "reputation": 17,
  "wins": 2,
  "losses": 1,
  "starting_gold": 9,
  "current_gold": 45,
  "team": [
    {
      "base_character_id": "char_warrior_001",
      "level": 3,
      "experience": 120,
      "current_health": 85,
      "max_health": 100,
      "equipped_items": ["item_rusty_sword"],
      "equipped_item_upgrades": [],
      "learned_skills": ["skill_slash"]
    }
  ],
  "encounter_history": [
    {"round": 1, "type": "shop", "choices_made": ["bought_health_potion"]},
    {"round": 1, "type": "combat", "result": "win"},
    {"round": 2, "type": "xp_reward", "choices_made": ["char_0_received_50xp"]},
    {"round": 2, "type": "combat", "result": "win"}
  ]
}
```

---

## Autoload Singletons

### game_data.gd
**Purpose**: Load and cache all master data (characters, items, skills, encounters)

**Key Methods**:
- `func load_all_data()` - Called on game start
- `func get_character_by_id(id: String) -> Dictionary`
- `func get_item_by_id(id: String) -> Dictionary`
- `func get_skill_by_id(id: String) -> Dictionary`
- `func get_encounter_types() -> Array`
- `func get_all_characters() -> Array`

**Notes**:
- Pure data provider, no game state
- All data immutable after loading

---

### player_account.gd
**Purpose**: Manage player progression, unlocks, and currencies

**Key Methods**:
- `func save_account()` - Write to local JSON (TODO: Cloud sync)
- `func load_account()` - Read from local JSON
- `func get_unlocked_characters() -> Array[Dictionary]`
- `func unlock_character(char_id: String, cost: int) -> bool`
- `func unlock_content_for_character(char_id: String, content_type: String, content_id: String, cost: int) -> bool`
- `func equip_item(char_id: String, item_id: String)`
- `func unequip_item(char_id: String, item_id: String)`
- `func add_character_experience(char_id: String, xp: int)` - May rank up
- `func spend_gems(amount: int) -> bool`
- `func add_gems(amount: int)`
- `func spend_reroll_token() -> bool`
- `func add_reroll_token()`

**State**:
- Player currencies
- Character collection with unlock/equip state
- Rank progression

**Notes**:
- TODO: Replace save/load with cloud API calls
- Signal emissions for UI updates (e.g., `character_ranked_up`)

---

### run_manager.gd
**Purpose**: Manage active run state, instanced team, save/load mid-run

**Key Methods**:
- `func start_new_run(drafted_chars: Array[String])`
- `func save_run_state()` - Auto-save after encounter/combat
- `func load_run_state() -> bool` - Returns true if resume available
- `func end_run(victory: bool)` - Award rewards, clear run state
- `func get_team() -> Array[CharacterInstance]`
- `func get_round() -> int`
- `func get_reputation() -> int`
- `func lose_reputation(amount: int)`
- `func add_win()`
- `func add_loss()`
- `func is_run_over() -> bool` - Check win/loss conditions
- `func add_gold(amount: int)`
- `func spend_gold(amount: int) -> bool`
- `func generate_encounter_options(count: int) -> Array[EncounterInstance]`
- `func generate_combat_options(count: int) -> Array[Dictionary]` # Stub for now
- `func apply_encounter_rewards(rewards: Dictionary)`

**State**:
- Current team (Array of CharacterInstance)
- Round count, reputation, wins, losses
- Gold, encounter history

**Notes**:
- CharacterInstance objects are runtime clones
- TODO: Ghost player system for async PvP (serialize team comps)

---

### encounter_factory.gd
**Purpose**: Dynamically generate encounter instances based on templates

**Key Methods**:
- `func create_encounter(type: String, round: int, team_state: Array) -> EncounterInstance`
- `func get_weighted_encounter_types(round: int) -> Array[String]` - Difficulty scaling

**Notes**:
- Extensible design: Each encounter type has its own script
- Can apply rules like "no duplicate encounter types in a row"

---

## Data Classes (scripts/data_classes/)

### CharacterInstance (character_instance.gd)
**Extends**: RefCounted

**Properties**:
```gdscript
var base_character_id: String
var level: int = 1
var experience: int = 0
var current_health: int
var max_health: int
var basic_attack_damage: int
var speed: int
var defense: int
var income: int
var equipped_items: Array[ItemInstance] = []
var equipped_item_upgrades: Array[ItemInstance] = []
var learned_skills: Array[SkillInstance] = []
```

**Methods**:
- `func _init(char_data: Dictionary)` - Clone from account character
- `func calculate_stats()` - Apply items/skills to base stats
- `func add_experience(xp: int)` - May level up
- `func learn_skill(skill: SkillInstance)`
- `func equip_item_upgrade(item_upgrade: ItemInstance)` - Replaces slot
- `func take_damage(amount: int)`
- `func heal(amount: int)`
- `func to_dict() -> Dictionary` - For serialization
- `static func from_dict(data: Dictionary) -> CharacterInstance` - For deserialization

---

### ItemInstance (item_instance.gd)
**Extends**: RefCounted

**Properties**:
```gdscript
var item_id: String
var name: String
var description: String
var image_path: String
var stat_modifiers: Dictionary # {"basic_attack_damage": 5, "health": 20}
var slot: String # "weapon", "armor", "accessory"
```

**Methods**:
- `func _init(item_data: Dictionary)`
- `func to_dict() -> Dictionary`

---

### SkillInstance (skill_instance.gd)
**Extends**: RefCounted

**Properties**:
```gdscript
var skill_id: String
var name: String
var description: String
var image_path: String
var effects: Array[Dictionary] # [{"type": "stat_multiply", "stat": "basic_attack_damage", "value": 1.2}]
```

**Methods**:
- `func _init(skill_data: Dictionary)`
- `func apply_effects(character: CharacterInstance)`
- `func to_dict() -> Dictionary`

---

### EncounterInstance (encounter_instance.gd)
**Extends**: RefCounted

**Properties**:
```gdscript
var encounter_type: String
var name: String
var description: String
var image_path: String
var script_instance: BaseEncounter # Actual encounter logic
```

**Methods**:
- `func _init(encounter_data: Dictionary)`
- `func execute(team: Array[CharacterInstance]) -> Dictionary` # Returns rewards

---

## Encounter System (scripts/encounters/)

### BaseEncounter (base_encounter.gd)
**Extends**: RefCounted
**Abstract base class for all encounters**

**Methods**:
- `func get_ui_scene() -> PackedScene` - Returns custom UI for this encounter
- `func execute(team: Array[CharacterInstance]) -> Dictionary` - Override in subclasses
- `func can_afford(cost: Dictionary) -> bool` - Check gold/resources

**Returns**: Dictionary with structure:
```gdscript
{
  "xp_awards": [{"character_index": 0, "amount": 50}],
  "gold_award": 20,
  "items_awarded": [{"character_index": 1, "item_id": "item_health_potion"}],
  "skills_awarded": [{"character_index": 0, "skill_id": "skill_dodge"}],
  "item_upgrades_awarded": [{"character_index": 2, "item_upgrade_id": "itemup_flaming_sword"}],
  "health_changes": [{"character_index": 0, "amount": -10}],
  "gold_spent": 30
}
```

---

### ShopEncounter (shop_encounter.gd)
**Extends**: BaseEncounter

**Logic**:
- Generate 3-6 random purchasable items/skills/upgrades
- Player selects character and item to purchase
- Deduct gold, award item to character

---

### XPRewardEncounter (xp_reward_encounter.gd)
**Extends**: BaseEncounter

**Logic**:
- Fixed or random XP amount
- Player selects which character(s) receive XP
- May have a choice: "50 XP to one character" vs "20 XP to all"

---

### MinigameEncounter (minigame_encounter.gd)
**Extends**: BaseEncounter
**Extensible base for minigames**

**Subclass Examples**:
- Memory matching
- Dice rolls
- Quick-time events
- Puzzle solving

**Design**: Each minigame has its own UI scene and reward calculation

---

## Scene Breakdown

### main.tscn
**Node Structure**:
```
Main (Node)
├── SceneContainer (Node) # Holds current scene
└── TransitionLayer (CanvasLayer) # Fade in/out
```

**Script (main.gd)**:
- `func _ready()` - Load autoloads, check for resume run
- `func change_scene(scene_path: String)`
- `func resume_run()` if active_run.json exists

---

### ui/main_menu.tscn
**Node Structure**:
```
MainMenu (Control)
├── Background (TextureRect)
├── Title (Label)
├── ButtonContainer (VBoxContainer)
│   ├── PlayButton (Button)
│   ├── CollectionButton (Button)
│   ├── SettingsButton (Button)
│   └── QuitButton (Button)
└── CurrencyDisplay (HBoxContainer)
    ├── GemsLabel (Label)
    └── RerollTokensLabel (Label)
```

**Script**:
- Update currency display on `_ready()`
- `_on_play_pressed()` - Check for resume or start draft
- `_on_collection_pressed()` - Open collection screen

---

### ui/collection.tscn
**Node Structure**:
```
Collection (Control)
├── CharacterList (ScrollContainer)
│   └── CharacterGrid (GridContainer)
│       └── CharacterCard (x N) # Instanced
├── CharacterDetailsPanel (Panel)
│   └── CharacterDetails (instance of character_details.tscn)
└── BackButton (Button)
```

**Script**:
- Populate grid with unlocked characters
- On character clicked, show details panel
- Handle equip/unequip item actions

---

### ui/character_details.tscn
**Node Structure**:
```
CharacterDetails (Panel)
├── Portrait (TextureRect)
├── NameLabel (Label)
├── StatsContainer (VBoxContainer)
│   ├── HealthLabel
│   ├── AttackLabel
│   ├── DefenseLabel
│   ├── SpeedLabel
│   └── IncomeLabel
├── RankProgressBar (ProgressBar)
├── ItemSlots (HBoxContainer)
│   └── ItemSlot (x 3) # weapon, armor, accessory
├── SkillsContainer (GridContainer)
│   └── SkillIcon (x N) # Only unlocked skills
└── EquipmentToggle (OptionButton) # "Equipped" / "All Unlocked"
```

**Script**:
- Display character stats with item bonuses calculated
- Show rank progress and next rank rewards
- Allow item equip/unequip via drag-drop or click
- Gem cost to unlock new items/skills displayed

---

### ui/draft.tscn
**Node Structure**:
```
Draft (Control)
├── InstructionLabel (Label) # "Select Character 1 of 3"
├── SelectedCharacters (HBoxContainer) # Shows drafted chars
│   └── CharacterCard (x 0-3) # Grow as drafted
├── OptionContainer (HBoxContainer)
│   └── DraftOption (x 3) # CharacterCard + Unlock/Select buttons
├── RerollButton (Button)
└── ConfirmButton (Button) # Only visible when 3 selected
```

**Script**:
- Generate 3 options: 2 from player collection, 1 random (may be locked)
- On reroll: Spend token, regenerate options
- On select: Add to drafted array, increment selection count
- When 3 drafted: Show confirm button
- On confirm: Pass to `RunManager.start_new_run()`

---

### ui/run_view.tscn
**Main run UI, shows team and current round info**

**Node Structure**:
```
RunView (Control)
├── TopBar (HBoxContainer)
│   ├── RoundLabel (Label) # "Round 3"
│   ├── ReputationLabel (Label) # "Reputation: 17/20"
│   ├── WinsLabel (Label) # "Wins: 2"
│   └── GoldLabel (Label) # "Gold: 45"
├── TeamDisplay (HBoxContainer)
│   └── CharacterCard (x 3) # Runtime characters
├── PhaseContainer (VBoxContainer)
│   ├── PhaseLabel (Label) # "Encounter Phase" or "Combat Phase"
│   └── ActionButton (Button) # "Choose Encounter" or "Choose Combat"
└── MenuButton (Button) # Pause menu
```

**Script**:
- Display current run state
- On action button: Open encounter_select.tscn or combat_select.tscn
- Update after each phase completes

---

### ui/encounter_select.tscn
**Node Structure**:
```
EncounterSelect (Control)
├── Title (Label) # "Choose an Encounter"
├── OptionsContainer (HBoxContainer)
│   └── EncounterOption (x 3) # Custom cards
│       ├── Image (TextureRect)
│       ├── Name (Label)
│       ├── Type (Label)
│       ├── Description (Label)
│       └── SelectButton (Button)
└── BackButton (Button)
```

**Script**:
- Get 3 encounter options from `RunManager.generate_encounter_options(3)`
- On select: Load encounter_execute.tscn with selected encounter

---

### ui/encounter_execute.tscn
**Dynamic scene, changes based on encounter type**

**Node Structure**:
```
EncounterExecute (Control)
├── EncounterUI (Control) # Loaded from encounter's get_ui_scene()
└── ConfirmButton (Button) # "Complete Encounter"
```

**Script**:
- Load custom UI from `EncounterInstance.script_instance.get_ui_scene()`
- Player interacts with encounter
- On confirm: Call `EncounterInstance.execute(team)`, get rewards
- Pass rewards to `RunManager.apply_encounter_rewards()`
- Auto-save run state
- Return to run_view.tscn

---

### ui/combat_select.tscn
**Node Structure**:
```
CombatSelect (Control)
├── Title (Label) # "Choose a Battle"
├── OptionsContainer (VBoxContainer)
│   └── CombatOption (x 3)
│       ├── Image (TextureRect)
│       ├── Name (Label)
│       ├── Type (Label) # "AI" or "Player Ghost"
│       ├── Description (Label)
│       ├── DifficultyLabel (Label) # AI only
│       ├── RankLabel (Label) # Ghost only
│       ├── RewardLabel (Label)
│       └── SelectButton (Button)
└── BackButton (Button)
```

**Script**:
- Get 3 combat options from `RunManager.generate_combat_options(3)`
- On select: Load combat_stub.tscn

---

### ui/combat_stub.tscn
**Temporary combat scene for testing**

**Node Structure**:
```
CombatStub (Control)
├── Label (Label) # "Combat happens here (stub)"
├── WinButton (Button)
└── LoseButton (Button)
```

**Script**:
- On win: `RunManager.add_win()`, award XP/gold
- On lose: `RunManager.add_loss()`, `RunManager.lose_reputation(round)`
- Check `RunManager.is_run_over()`
- If over: Load run_results.tscn
- Else: Return to run_view.tscn
- Auto-save run state

**TODO**: Replace with actual combat system

---

### ui/run_results.tscn
**Node Structure**:
```
RunResults (Control)
├── ResultLabel (Label) # "VICTORY" or "DEFEAT"
├── StatsContainer (VBoxContainer)
│   ├── RoundsLabel
│   ├── WinsLabel
│   ├── LossesLabel
│   └── FinalGoldLabel
├── RewardsContainer (VBoxContainer)
│   ├── GemsLabel # "Gems Earned: 50"
│   └── CharacterXPLabels (x 3) # XP toward rank
└── ContinueButton (Button) # Back to main menu
```

**Script**:
- Display run results
- Award gems (placeholder)
- Award character rank XP to account characters
- Clear run state via `RunManager.end_run(victory)`
- On continue: Return to main_menu.tscn

---

## Development Phases

### Phase 1: Foundation (Days 1-2)
**Goal**: Data loading, account system, main menu

**Tasks**:
1. Create project structure (folders, autoloads)
2. Implement `GameData` singleton
   - Load characters.json, items.json, skills.json
   - Test with print statements
3. Implement `PlayerAccount` singleton
   - Create default account with 5 unlocked characters
   - Save/load to JSON
   - Currency management
4. Create `main.tscn` with scene management
5. Create `main_menu.tscn`
   - Display currencies
   - Navigation buttons (Collection, Play)
6. Create placeholder JSON files with 2-3 characters, items, skills

**Deliverable**: Can launch game, see main menu, currencies persist

---

### Phase 2: Collection & Character Management (Days 3-4)
**Goal**: View and equip characters

**Tasks**:
1. Create `CharacterCard` component
   - Display portrait, name, stats
   - Reusable across all screens
2. Create `collection.tscn`
   - Grid of owned characters
   - Select to view details
3. Create `character_details.tscn`
   - Show all stats, rank progress
   - Item equip/unequip system
   - Display unlocked items/skills only
4. Implement item equip logic in `PlayerAccount`
5. Add more test data (5+ characters, 10+ items)

**Deliverable**: Can browse collection, equip items, see stat changes

---

### Phase 3: Draft System (Days 5-6)
**Goal**: Character selection for runs

**Tasks**:
1. Create `draft.tscn`
   - Generate 3 options (2 owned, 1 random)
   - Show unlock cost for unowned
   - Reroll token system
2. Implement draft logic
   - Track selected characters
   - Validate selections (no duplicates)
3. Implement `RunManager.start_new_run()`
   - Clone CharacterInstance from account data
   - Calculate starting gold (sum of income)
   - Initialize run state
4. Test draft → run start flow

**Deliverable**: Can draft 3 characters, run initializes

---

### Phase 4: Run Infrastructure (Days 7-9)
**Goal**: Run loop, save/load, core UI

**Tasks**:
1. Create `CharacterInstance` class
   - Full stat calculation with items/skills
   - Serialization for save/load
2. Create `ItemInstance` and `SkillInstance` classes
3. Implement `RunManager` save/load
   - Auto-save after each phase
   - Load on game start if exists
4. Create `run_view.tscn`
   - Display team, round, reputation, gold
   - Phase transition buttons
5. Test run state persistence (close game mid-run, reopen)

**Deliverable**: Can start run, see team, game saves mid-run

---

### Phase 5: Encounter System (Days 10-13)
**Goal**: Modular encounter framework

**Tasks**:
1. Create `EncounterFactory` singleton
   - Generate random encounter options
   - Weight by round number
2. Create `BaseEncounter` abstract class
3. Create `encounter_select.tscn`
   - Show 3 options with art, description
4. Create `encounter_execute.tscn`
   - Dynamic UI loading
5. Implement 3 encounter types:
   - **ShopEncounter**: Buy items/skills
   - **XPRewardEncounter**: Award XP
   - **MinigameEncounter**: Simple dice roll or button mash
6. Create custom UI scenes for each encounter type
7. Implement reward application in `RunManager`
   - XP → may level up character
   - Items/skills → add to CharacterInstance
   - Gold → add to run state

**Deliverable**: Can complete encounters, rewards applied, run progresses

---

### Phase 6: Combat Stub (Days 14-15)
**Goal**: Combat selection and stub results

**Tasks**:
1. Create `combat_select.tscn`
   - 3 options with name, type, difficulty, rewards
2. Create `combat_stub.tscn`
   - Win/Loss buttons
3. Implement combat result logic
   - Win: Award XP/gold, increment wins
   - Loss: Lose reputation equal to round
4. Check win/loss conditions
   - 10 wins = victory
   - 0 reputation = defeat
5. Trigger run end when conditions met

**Deliverable**: Can enter combat, choose outcome, run ends appropriately

---

### Phase 7: Run Results & Loop Closure (Days 16-17)
**Goal**: Complete the run loop

**Tasks**:
1. Create `run_results.tscn`
   - Display stats, rewards
2. Implement `RunManager.end_run(victory)`
   - Award gems (placeholder)
   - Award character rank XP to account
   - May rank up characters
   - Clear active run save
3. Test full loop:
   - Draft → Encounters → Combat → Results → Main Menu

**Deliverable**: Full run loop functional, can repeat runs

---

### Phase 8: Polish & Extensibility (Days 18-20)
**Goal**: UI polish, testing, documentation

**Tasks**:
1. Add more encounter types (2-3 more minigames)
2. Add more test content (10+ characters, 20+ items, 15+ skills)
3. UI improvements:
   - Visual feedback for XP gain, level up
   - Animations for transitions
   - Sound effects (optional)
4. Bug fixing and balance tuning
5. Add developer tools:
   - Debug menu to add gems/tokens
   - Skip to specific round
6. Write README.md with:
   - How to add new characters/items/skills
   - How to create new encounter types
   - TODO notes for combat system and cloud integration

**Deliverable**: Polished prototype ready for combat implementation

---

## Critical Design Notes for Claude Code

### Extensibility Focus
- **Encounters**: Each type is a separate script extending `BaseEncounter`. Adding new encounters = create new script + add to `encounter_types.json`
- **Rewards**: Generic reward dictionary structure allows any combination of XP, gold, items, skills, health changes
- **Data-driven**: All content in JSON. No hardcoding character stats or items in code

### Serialization Strategy
- `CharacterInstance`, `ItemInstance`, `SkillInstance` all have `to_dict()` and `from_dict()` for save/load
- Run state saved after every encounter/combat to prevent progress loss

### Account vs Run Separation
- **Account data**: Persistent, edited via `PlayerAccount` singleton
- **Run data**: Temporary, managed by `RunManager`, deleted after run ends
- **Character instances**: Cloned at run start, never modify account characters during run

### UI Component Reuse
- `CharacterCard`: Used in collection, draft, run view
- Signals for interaction (e.g., `character_selected`, `item_equipped`)

### Cloud Integration (TODO)
- Replace `PlayerAccount.save_account()` and `load_account()` with API calls
- Add authentication flow before main menu
- Ghost player system: POST team composition after each run, GET random ghost for combat

### Combat System Placeholder
- `combat_stub.tscn` is explicitly temporary
- When implementing combat:
  - Create `CombatManager` singleton
  - Define combat rules (turn order, damage calculation)
  - Create `combat_scene.tscn` with animated battle
  - Replace stub scene with real combat

---

## Testing Checklist

### Phase 1
- [ ] Game launches without errors
- [ ] Main menu displays
- [ ] Currencies (gems, tokens) display correctly
- [ ] Currencies persist after closing game

### Phase 2
- [ ] Collection shows all unlocked characters
- [ ] Character details show correct stats
- [ ] Equipping item updates stats immediately
- [ ] Unequipping item reverts stats
- [ ] Rank progress bar displays correctly

### Phase 3
- [ ] Draft shows 2 owned + 1 random character
- [ ] Can reroll options (if tokens available)
- [ ] Can select 3 different characters
- [ ] Confirm button appears after 3 selections
- [ ] Run starts with correct team

### Phase 4
- [ ] Run view shows correct team, round, reputation, gold
- [ ] Can close game mid-run and resume
- [ ] Resume loads exact team state (health, XP, items)

### Phase 5
- [ ] 3 encounter options appear
- [ ] Encounter UI loads correctly
- [ ] XP reward levels up character
- [ ] Shop purchase deducts gold and adds item
- [ ] Character stats update after gaining items

### Phase 6
- [ ] 3 combat options appear
- [ ] Win button awards XP/gold
- [ ] Loss button reduces reputation
- [ ] 10 wins triggers victory screen
- [ ] 0 reputation triggers defeat screen

### Phase 7
- [ ] Results screen shows correct stats
- [ ] Character rank XP awarded to account
- [ ] Run state deleted after results
- [ ] Can start new run immediately

### Phase 8
- [ ] At least 5 different encounter types
- [ ] 10+ characters with unique stats
- [ ] All UI transitions smooth
- [ ] No error messages in console

---

## File Generation Order for Claude Code

When building with Claude Code, generate files in this order to maintain dependencies:

1. **Data Files**:
   - `data/characters/characters.json`
   - `data/items/items.json`
   - `data/items/item_upgrades.json`
   - `data/skills/skills.json`
   - `data/encounters/encounter_types.json`

2. **Data Classes**:
   - `scripts/data_classes/item_instance.gd`
   - `scripts/data_classes/skill_instance.gd`
   - `scripts/data_classes/character_instance.gd`
   - `scripts/data_classes/encounter_instance.gd`

3. **Autoloads** (add to Project Settings after creation):
   - `autoloads/game_data.gd`
   - `autoloads/player_account.gd`
   - `autoloads/run_manager.gd`
   - `autoloads/encounter_factory.gd`

4. **Encounter Scripts**:
   - `scripts/encounters/base_encounter.gd`
   - `scripts/encounters/shop_encounter.gd`
   - `scripts/encounters/xp_reward_encounter.gd`
   - `scripts/encounters/minigame_encounter.gd`

5. **UI Components**:
   - `scenes/components/character_card.tscn` (+ script)
   - `scenes/components/item_slot.tscn` (+ script)
   - `scenes/components/skill_icon.tscn` (+ script)

6. **Main Scenes**:
   - `scenes/main.tscn` (+ script)
   - `scenes/ui/main_menu.tscn` (+ script)
   - `scenes/ui/collection.tscn` (+ script)
   - `scenes/ui/character_details.tscn` (+ script)
   - `scenes/ui/draft.tscn` (+ script)
   - `scenes/ui/run_view.tscn` (+ script)
   - `scenes/ui/encounter_select.tscn` (+ script)
   - `scenes/ui/encounter_execute.tscn` (+ script)
   - `scenes/ui/combat_select.tscn` (+ script)
   - `scenes/ui/combat_stub.tscn` (+ script)
   - `scenes/ui/run_results.tscn` (+ script)

7. **Encounter UI Scenes**:
   - `scenes/ui/encounters/shop_ui.tscn` (+ script)
   - `scenes/ui/encounters/xp_reward_ui.tscn` (+ script)
   - `scenes/ui/encounters/minigame_ui.tscn` (+ script)

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│                   AUTOLOADS                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────┐  │
│  │  GameData    │  │PlayerAccount │  │RunManager│  │
│  │(Master Data) │  │(Progression) │  │(Run State│  │
│  └──────────────┘  └──────────────┘  └──────────┘  │
│         │                 │                 │        │
│         └─────────────────┴─────────────────┘        │
│                           │                          │
└───────────────────────────┼──────────────────────────┘
                            │
                            ▼
         ┌──────────────────────────────────┐
         │         UI SCENES                │
         │  ┌────────────┐  ┌────────────┐  │
         │  │ MainMenu   │  │Collection  │  │
         │  └────────────┘  └────────────┘  │
         │  ┌────────────┐  ┌────────────┐  │
         │  │   Draft    │  │  RunView   │  │
         │  └────────────┘  └────────────┘  │
         │  ┌────────────┐  ┌────────────┐  │
         │  │ Encounter  │  │  Combat    │  │
         │  │   Select   │  │   Select   │  │
         │  └────────────┘  └────────────┘  │
         └──────────────────────────────────┘
                            │
                            ▼
         ┌──────────────────────────────────┐
         │      RUNTIME INSTANCES           │
         │  ┌──────────────────────────┐    │
         │  │  CharacterInstance (x3)  │    │
         │  │  ├─ ItemInstance        │    │
         │  │  ├─ SkillInstance       │    │
         │  │  └─ Stats (calculated)  │    │
         │  └──────────────────────────┘    │
         │  ┌──────────────────────────┐    │
         │  │  EncounterInstance       │    │
         │  │  └─ BaseEncounter script │    │
         │  └──────────────────────────┘    │
         └──────────────────────────────────┘
                            │
                            ▼
         ┌──────────────────────────────────┐
         │     PERSISTENCE LAYER            │
         │  ┌────────────────────────────┐  │
         │  │  player_account.json       │  │
         │  │  (TODO: Cloud API)         │  │
         │  └────────────────────────────┘  │
         │  ┌────────────────────────────┐  │
         │  │  active_run.json           │  │
         │  │  (Mid-run save/load)       │  │
         │  └────────────────────────────┘  │
         └──────────────────────────────────┘
```

---

## Summary

This plan provides a complete roadmap for building a functional auto-battler prototype in Godot 4 using Claude Code. The architecture is:

- **Modular**: Encounters, characters, items, skills all extensible via JSON and scripts
- **Persistent**: Account progression and mid-run saves
- **Testable**: Combat stub allows full loop testing without combat implementation
- **Cloud-ready**: Designed for easy migration to cloud backend

Follow the phases sequentially, testing each deliverable before moving to the next. The file generation order ensures no dependency issues. All TODO comments in code should reference future cloud integration and combat system implementation.

**Total estimated development time**: 15-20 days for a working prototype with polished UI and 3-5 encounter types.
