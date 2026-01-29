# Legacy System Refactor Plan

This document outlines a comprehensive, phased approach to refactoring the game from a character-centric architecture to the new Legacy-centric architecture.

---

## Executive Summary

**Scope**: Transform the game from "Characters are the center of progression" to "Legacies are the center of progression."

**Approach**: Build the Legacy system fresh rather than adapting the old Character system. The existing code provides a blueprint for patterns, but the old system will be excised completely.

**Key Changes**:
1. Legacies become the meta-progression anchor (prestige, fame, unlocks)
2. Characters become run-time acquisitions (like items currently are)
3. Items become player-level inventory (no character attachment)
4. Skills become one-shot effects (not passive modifiers)
5. Draft phase changes from drafting characters to drafting legacies
6. Character grid replaces fixed 3-character team (2x3, 6 slots max)

**Estimated Phases**: 8 phases, each independently testable

---

## SOLID/DRY Design Principles

This refactor adheres to SOLID principles throughout:

### Single Responsibility (SRP)
- **RunState** (new): Composite object owning run subsystems (grid, inventory, effects, pool)
- **RunManager**: Orchestrates run flow; delegates state to RunState
- **PrestigeTracker**: Extracted abstraction for prestige/fame mechanics (used by LegacyCollection)
- Each manager has one reason to change

### Open/Closed (OCP)
- **SkillEffectRegistry**: Register new effects without modifying handler code
- **EncounterRegistry**: Already follows this pattern; extend for legacy encounters
- New content types added via registration, not modification

### Liskov Substitution (LSP)
- No deep inheritance hierarchies; prefer composition
- Data classes (LegacyData, CharacterInstance) are value objects

### Interface Segregation (ISP)
- **ContentPool** interface: `pick_random(count, max_level) -> Array`
- Separate pool accessors if consumers need only one content type

### Dependency Inversion (DIP)
- Managers accept dependencies via constructor/init, not global lookups
- RunState injected into handlers via context objects

### DRY (Don't Repeat Yourself)
- **Level gating**: Centralized in RunPool; no other system filters by level
- **Content picking**: Single `RunPool.pick_random()` method for all content types
- **Prestige/fame logic**: Extracted to PrestigeTracker, reusable
- **Encounter weighting**: Single `calculate_weight()` function

---

## Phase 0: Preparation & Foundation

### 0.1 Create Prestige Tracker (DRY Extraction)

**Files to Create**:
- `scripts/managers/prestige_tracker.gd`

**Rationale**: Prestige/fame mechanics are reusable. Extract before building LegacyCollection.

```gdscript
class_name PrestigeTracker
extends RefCounted

## Tracks prestige and fame for any entity (Legacy, future systems)

signal fame_changed(new_fame: int)
signal prestige_up(new_prestige: int)

var _prestige: int = 1
var _fame: int = 0

const FAME_PER_PRESTIGE: int = 100

func get_prestige() -> int:
    return _prestige

func get_fame() -> int:
    return _fame

func add_fame(amount: int) -> Dictionary:
    ## Returns { prestige_increased: bool, new_prestige: int, overflow_fame: int }
    _fame += amount
    var result = { "prestige_increased": false, "new_prestige": _prestige }

    while _fame >= FAME_PER_PRESTIGE:
        _fame -= FAME_PER_PRESTIGE
        _prestige += 1
        result.prestige_increased = true
        result.new_prestige = _prestige
        prestige_up.emit(_prestige)

    fame_changed.emit(_fame)
    result.overflow_fame = _fame
    return result

func to_dict() -> Dictionary:
    return { "prestige": _prestige, "fame": _fame }

static func from_dict(data: Dictionary) -> PrestigeTracker:
    var tracker = PrestigeTracker.new()
    tracker._prestige = data.get("prestige", 1)
    tracker._fame = data.get("fame", 0)
    return tracker
```

### 0.2 Create Legacy Data Structure

**Files to Create**:
- `data/legacies/legacies.json` - Master legacy definitions

**Schema**:
```json
{
  "legacies": [
    {
      "id": "legacy_knight_order",
      "name": "Knight's Order",
      "description": "Stalwart defenders who protect the weak",
      "image_path": "res://assets/sprites/legacies/knight_order.png",
      "income": 15,
      "starting_character_options": ["knight_squire", "paladin"],
      "starting_item_options": ["shield_emblem"],
      "character_pool": ["knight_squire", "paladin", "crusader"],
      "item_pool": ["iron_sword", "plate_armor", "shield"],
      "skill_pool": ["defensive_stance", "rally_cry"],
      "unique_encounters": ["knight_tournament", "holy_blessing"],
      "prestige_rewards": [
        {
          "prestige": 1,
          "unlocks": {
            "starting_characters": ["knight_squire"],
            "starting_items": ["shield_emblem"],
            "characters": ["knight_squire"],
            "items": ["iron_sword"],
            "skills": [],
            "encounters": []
          }
        },
        {
          "prestige": 2,
          "unlocks": {
            "starting_characters": ["paladin"],
            "starting_items": [],
            "characters": ["paladin"],
            "items": ["plate_armor"],
            "skills": ["defensive_stance"],
            "encounters": ["knight_tournament"],
            "encounter_weight_bonus": 10
          }
        }
      ]
    }
  ]
}
```

**Key Schema Notes**:
- `starting_character_options`: All possible starting characters for this legacy
- `starting_item_options`: All possible starting items (optional; can be empty array)
- `prestige_rewards.unlocks.starting_characters`: Which starting character options unlock at each prestige
- `prestige_rewards.unlocks.starting_items`: Which starting item options unlock at each prestige
- `encounter_weight_bonus`: Adds to base weight (100) for this legacy's unique encounters
- Every legacy MUST have at least one starting character (unlocked at prestige 1)
- Starting items are OPTIONAL per legacy (empty array if none)
- Player selects ONE starting character and ONE starting item (if available) per legacy in Collection screen

**Files to Create**:
- `scripts/data_classes/legacy_data.gd` - Runtime legacy representation

```gdscript
class_name LegacyData
extends RefCounted

# Master data (from JSON)
var id: String
var name: String
var description: String
var image_path: String
var income: int
var starting_character_options: Array[String]  # All possible starting characters
var starting_item_options: Array[String]       # All possible starting items (can be empty)
var character_pool: Array[String]
var item_pool: Array[String]
var skill_pool: Array[String]
var unique_encounters: Array[String]
var prestige_rewards: Array[Dictionary]

# Account-level state (from save data)
var unlocked: bool
var prestige_tracker: PrestigeTracker  # Composition, not inheritance (DIP)
var selected_starting_character_id: String  # Player's chosen starter (required)
var selected_starting_item_id: String       # Player's chosen starting item (optional)
var unlocked_starting_characters: Array[String]
var unlocked_starting_items: Array[String]
var unlocked_characters: Array[String]
var unlocked_items: Array[String]
var unlocked_skills: Array[String]
var unlocked_encounters: Array[String]
var total_encounter_weight_bonus: int  # Accumulated from prestige rewards

func get_prestige() -> int:
    return prestige_tracker.get_prestige()

func get_fame() -> int:
    return prestige_tracker.get_fame()

func get_encounter_weight() -> int:
    ## Base 100 + accumulated bonuses from prestige
    return 100 + total_encounter_weight_bonus

func has_starting_item() -> bool:
    return starting_item_options.size() > 0

static func from_dict(master: Dictionary, account: Dictionary = {}) -> LegacyData:
    # ... factory method
```

### 0.3 Create Legacy Collection Manager

**Files to Create**:
- `scripts/managers/legacy_collection.gd`

**Responsibilities**:
- Load legacy data from JSON + account save data
- Track unlock state per legacy
- Delegate prestige/fame to each legacy's PrestigeTracker
- Handle prestige-up unlock propagation
- Track selected starting character AND starting item per legacy
- Persist to account save file

**Signals**:
```gdscript
signal legacy_unlocked(legacy_id: String)
signal legacy_prestige_up(legacy_id: String, new_prestige: int, unlocked_content: Dictionary)
signal legacy_fame_changed(legacy_id: String, new_fame: int)
signal starting_character_changed(legacy_id: String, character_id: String)
signal starting_item_changed(legacy_id: String, item_id: String)
```

### 0.3 Update GameData Autoload

**Files to Modify**:
- `autoloads/game_data.gd`

**Changes**:
- Add `_legacies: Dictionary` cache
- Add `get_legacy(id: String) -> Dictionary`
- Add `get_all_legacies() -> Array`
- Load legacies.json in `_ready()`

### 0.4 Update PlayerAccount Facade

**Files to Modify**:
- `autoloads/player_account.gd`

**Changes**:
- Add `_legacy_collection: LegacyCollection` member
- Add facade methods: `get_legacy_data()`, `award_legacy_fame()`, etc.
- Extend persistence schema to include legacy data

### 0.5 Update PlayerAccount for Clean Slate

**Files to Modify**:
- `autoloads/player_account.gd`

**Changes**:
- Detect old save format → ignore and create fresh account
- Add `format_version` to save schema
- Initialize default legacy state on fresh start

**Acceptance Criteria**:
- [ ] Legacy JSON loads without errors
- [ ] LegacyData class can be instantiated from JSON
- [ ] LegacyCollection can save/load account state
- [ ] PlayerAccount exposes legacy operations
- [ ] Old saves are ignored; fresh account created

---

## Phase 1: Character Simplification

### 1.1 Remove Meta-Progression from Character

**Files to Modify**:
- `data/characters/characters.json`
- `scripts/managers/character_collection.gd`
- `scripts/data_classes/character_instance.gd`

**JSON Schema Changes**:
```json
// REMOVE from character:
"prestige_rewards": [...],
"base_stats.income": ...,
"base_stats.startingItemSlots": ...,

// Character becomes simpler:
{
  "id": "warrior",
  "name": "Warrior",
  "description": "A stalwart fighter who leads the charge",
  "image_path": "res://assets/sprites/characters/warrior.png",
  "cost": 40,
  "level_requirement": 1,
  "base_stats": {
    "health": 100,
    "charges": 30,
    "defendRate": 15
  }
  // No income, no prestige_rewards, no itemSlots
}
```

**New Fields**:
- `cost`: Gold cost to purchase in shops/encounters (like items and skills)
- `level_requirement`: Minimum team level before this character can appear
- `description`: For display in shops and character info

**CharacterCollection Changes**:
- Remove prestige/fame tracking (moved to LegacyCollection)
- Remove equipment tracking (items go to player inventory)
- CharacterCollection becomes a simple registry of character definitions
- May be merged into GameData if too thin

**CharacterInstance Changes**:
- Remove: `equipped_items`, `equipped_item_upgrades`, `learned_skills`
- Remove: prestige-related stat calculations
- Keep: `level`, `experience`, `current_health`, base stats
- Add: `grid_position: Vector2i` (row, column in 2x3 grid)

### 1.2 Update StatCalculator

**Files to Modify**:
- `scripts/utils/stat_calculator.gd`

**Changes**:
- Remove item-based stat modifiers from character calculation
- Remove skill-based stat modifiers from character calculation
- Remove prestige stat boosts (prestige is on Legacy now)
- Character stats = base_stats + level bonuses only
- Items/skills will affect player/team-level stats separately

### 1.3 Update Character UI Components

**Files to Modify**:
- `scenes/components/character_card.tscn` / `.gd`
- `scenes/components/character_tile.tscn` / `.gd`
- `scenes/components/character_info_panel.tscn` / `.gd`

**Changes**:
- Remove item slot display
- Remove skill display
- Remove income display
- Remove prestige/fame display
- Simplify to: portrait, name, level, health/charges/defendRate

**Acceptance Criteria**:
- [ ] Characters no longer have income, prestige, fame
- [ ] Characters no longer have item slots or skill slots
- [ ] StatCalculator computes character stats without items/skills
- [ ] Character UI shows simplified data
- [ ] Existing encounters that reference character items gracefully handle removal

---

## Phase 2: Player-Level Item System

### 2.1 Create Player Inventory

**Files to Create**:
- `scripts/managers/player_inventory.gd`

**Responsibilities**:
- Store items acquired during run (no character attachment)
- No slot limit (accumulates like relics)
- Track item instances with their stat modifiers

**Data Structure**:
```gdscript
class_name PlayerInventory
extends RefCounted

var _items: Array[ItemInstance] = []

func add_item(item: ItemInstance) -> void
func remove_item(item_id: String) -> void
func get_all_items() -> Array[ItemInstance]
func get_total_stat_modifier(stat_name: String) -> int
```

### 2.2 Update ItemInstance

**Files to Modify**:
- `scripts/data_classes/item_instance.gd`

**Changes**:
- Remove character association
- Item is now standalone, owned by player

### 2.3 Update RunManager

**Files to Modify**:
- `autoloads/run_manager.gd`

**Changes**:
- Add `_player_inventory: PlayerInventory` member
- Add methods: `add_item_to_inventory()`, `get_player_items()`
- Persist inventory to run save file

### 2.4 Update Item-Related Encounters

**Files to Modify**:
- `scripts/encounters/handlers/*.gd` (shop, treasure_chest, etc.)

**Changes**:
- Items go to player inventory, not character
- Remove character selection for item acquisition
- Update UI to show "acquired item" without character destination

### 2.5 Apply Item Effects at Team Level

**Files to Create/Modify**:
- Create team-level stat calculation that includes player items
- Items provide bonuses to all characters or specific effects

**Acceptance Criteria**:
- [ ] PlayerInventory tracks items without character attachment
- [ ] Items persist in run save file
- [ ] Encounters add items to player inventory
- [ ] Item effects apply at player/team level
- [ ] UI shows player's item collection

---

## Phase 3: Skill System Rework

### 3.1 Redesign Skill Data Structure

**Files to Modify**:
- `data/skills/skills.json`

**Schema Changes**:
```json
// BEFORE (passive stat modifier):
{
  "id": "iron_will",
  "effects": [
    { "type": "stat_add", "stat": "health", "value": 20 }
  ]
}

// AFTER (one-shot effect):
{
  "id": "iron_will",
  "effect_type": "instant",  // or "lingering"
  "effect": {
    "type": "heal_team",
    "value": 50
  }
}

// Lingering example:
{
  "id": "fortune_blessing",
  "effect_type": "lingering",
  "effect": {
    "type": "next_character_stat_boost",
    "stat": "health",
    "value": 10
  },
  "duration": "next_character_acquired"
}
```

### 3.2 Create Skill Effect System (OCP-Compliant)

**Files to Create**:
- `scripts/skills/skill_effect_registry.gd` - Registry for effect handlers
- `scripts/skills/skill_context.gd` - Context passed to effect handlers
- `scripts/skills/effects/` - Individual effect implementations

**Pattern** (Registry, not match statement - follows OCP):
```gdscript
class_name SkillEffectRegistry
extends RefCounted

## Registry for skill effects. New effects are added via register(), not by
## modifying this class. Follows Open/Closed Principle.

# effect_type -> Callable(effect_data: Dictionary, context: SkillContext) -> void
var _handlers: Dictionary = {}

func register(effect_type: String, handler: Callable) -> void:
    _handlers[effect_type] = handler

func execute(skill_data: Dictionary, context: SkillContext) -> bool:
    var effect_type = skill_data.effect.type
    if not _handlers.has(effect_type):
        push_warning("Unknown skill effect type: %s" % effect_type)
        return false
    _handlers[effect_type].call(skill_data.effect, context)
    return true

func has_effect(effect_type: String) -> bool:
    return _handlers.has(effect_type)
```

**Effect Registration (in autoload or game init)**:
```gdscript
# Register all built-in effects
func _register_skill_effects(registry: SkillEffectRegistry) -> void:
    registry.register("heal_team", _effect_heal_team)
    registry.register("grant_gold", _effect_grant_gold)
    registry.register("grant_xp", _effect_grant_xp)
    registry.register("next_character_stat_boost", _effect_lingering_stat_boost)
    # New effects added here without modifying SkillEffectRegistry

func _effect_heal_team(effect_data: Dictionary, context: SkillContext) -> void:
    var amount = effect_data.get("value", 0)
    for character in context.run_state.grid.get_all_characters():
        character.heal(amount)

func _effect_grant_gold(effect_data: Dictionary, context: SkillContext) -> void:
    var amount = effect_data.get("value", 0)
    context.run_state.add_gold(amount)
```

### 3.3 Create Lingering Effect Tracker

**Files to Create**:
- `scripts/managers/lingering_effects.gd`

**Responsibilities**:
- Track effects that persist until triggered
- Check triggers: "next_character_acquired", "next_combat", etc.
- Apply effects when triggered
- Clear expired effects

### 3.4 Update Skill-Related Encounters

**Files to Modify**:
- `scripts/encounters/handlers/skill_trainer_handler.gd`
- `scripts/encounters/handlers/shop_handler.gd`

**Changes**:
- Skills execute immediately on acquisition
- No character assignment
- Show effect preview before purchase
- No skill cap (skills resolve and are gone)

### 3.5 Update RunManager for Lingering Effects

**Files to Modify**:
- `autoloads/run_manager.gd`

**Changes**:
- Add `_lingering_effects: LingeringEffects` member
- Hook triggers: character acquired, combat started, etc.
- Persist lingering effects to run save

**Acceptance Criteria**:
- [ ] Skills execute immediately on acquisition
- [ ] Skill effects resolve (heal, grant gold, etc.)
- [ ] Lingering effects track and trigger correctly
- [ ] Skill encounters show effect preview
- [ ] No skill accumulation on characters

---

## Phase 4: Draft Phase Overhaul

### 4.0 Create RunState Composite (SRP Fix)

**Rationale**: RunManager was accumulating too many responsibilities (inventory, grid, effects, pool). Extract a `RunState` composite that owns all run subsystems.

**Files to Create**:
- `scripts/managers/run_state.gd`

```gdscript
class_name RunState
extends RefCounted

## Composite object owning all run subsystems. RunManager orchestrates flow;
## RunState owns state. Follows Single Responsibility Principle.

var run_id: String
var current_round: int = 0
var current_phase: String = "encounter"
var reputation: int = 20
var wins: int = 0
var losses: int = 0
var current_gold: int = 0

# Subsystems (composition)
var grid: CharacterGrid
var inventory: PlayerInventory
var lingering_effects: LingeringEffects
var pool: RunPool
var drafted_legacy_ids: Array[String]

func _init() -> void:
    grid = CharacterGrid.new()
    inventory = PlayerInventory.new()
    lingering_effects = LingeringEffects.new()
    # pool set after draft completes

func add_gold(amount: int) -> void:
    current_gold += amount

func remove_gold(amount: int) -> bool:
    if current_gold >= amount:
        current_gold -= amount
        return true
    return false

func to_dict() -> Dictionary:
    return {
        "run_id": run_id,
        "current_round": current_round,
        "current_phase": current_phase,
        "reputation": reputation,
        "wins": wins,
        "losses": losses,
        "current_gold": current_gold,
        "grid": grid.to_dict(),
        "inventory": inventory.to_dict(),
        "lingering_effects": lingering_effects.to_dict(),
        "pool": pool.to_dict() if pool else {},
        "drafted_legacy_ids": drafted_legacy_ids
    }

static func from_dict(data: Dictionary) -> RunState:
    # ... factory method for save/load
```

**RunManager Changes**:
```gdscript
# BEFORE (bloated):
var _player_inventory: PlayerInventory
var _lingering_effects: LingeringEffects
var _run_pool: RunPool
var _grid: CharacterGrid

# AFTER (delegated):
var _run_state: RunState  # Single composite

func get_run_state() -> RunState:
    return _run_state
```

### 4.1 Create Legacy Draft Manager

**Files to Create**:
- `scripts/managers/legacy_draft_manager.gd`

**Responsibilities**:
- Generate 3 legacy options per draft round
- 2 from owned legacies + 1 random (costs gems if not owned)
- Track selections across 3 rounds
- Compute starting gold (sum of legacy incomes)
- Compute starting character(s) from legacy starting_character_id
- Compute starting item(s) from legacy starting_item_id

**Signals**:
```gdscript
signal draft_options_generated(options: Array[LegacyDraftOption])
signal legacy_drafted(legacy: LegacyData)
signal draft_completed(drafted_legacies: Array[LegacyData])
```

### 4.2 Create Run Pool Composer (DRY: Centralized Filtering)

**Files to Create**:
- `scripts/managers/run_pool.gd`

**Responsibilities**:
- Compose content pools from drafted legacies' unlocked content
- **Single source of truth for level gating** (no other system filters by level)
- **Single `pick_random()` method** for all content types (DRY)
- Handle duplicates (union of all legacy pools)
- Track encounter weights for legacy encounters

**Interface**:
```gdscript
class_name RunPool
extends RefCounted

enum ContentType { CHARACTER, ITEM, SKILL, ENCOUNTER }

# Internal pools (id -> level_requirement)
var _character_pool: Dictionary = {}  # { "knight": 1, "paladin": 3 }
var _item_pool: Dictionary = {}
var _skill_pool: Dictionary = {}
var _encounter_pool: Dictionary = {}  # { "knight_tournament": { "weight": 110, "level": 2 } }

static func from_legacies(legacies: Array[LegacyData], game_data: GameData) -> RunPool:
    var pool = RunPool.new()
    for legacy in legacies:
        pool._add_legacy_content(legacy, game_data)
    return pool

func _add_legacy_content(legacy: LegacyData, game_data: GameData) -> void:
    # Add unlocked content with level requirements from master data
    for char_id in legacy.unlocked_characters:
        var char_data = game_data.get_character(char_id)
        _character_pool[char_id] = char_data.get("level_requirement", 1)
    # ... similar for items, skills

    # Add encounters with calculated weight
    for enc_id in legacy.unlocked_encounters:
        var enc_data = game_data.get_encounter(enc_id)
        _encounter_pool[enc_id] = {
            "weight": legacy.get_encounter_weight(),  # 100 + prestige bonuses
            "level": enc_data.get("level_requirement", 1)
        }

## SINGLE method for picking content (DRY)
func pick_random(type: ContentType, count: int, max_level: int = 999) -> Array[String]:
    var pool = _get_pool_for_type(type)
    var available = pool.keys().filter(func(id): return pool[id] <= max_level)
    available.shuffle()
    return available.slice(0, min(count, available.size()))

func _get_pool_for_type(type: ContentType) -> Dictionary:
    match type:
        ContentType.CHARACTER: return _character_pool
        ContentType.ITEM: return _item_pool
        ContentType.SKILL: return _skill_pool
        ContentType.ENCOUNTER: return _encounter_pool
    return {}

## Encounter-specific: weighted random selection
func pick_weighted_encounters(count: int, max_level: int = 999) -> Array[String]:
    var available = []
    var weights = []
    for enc_id in _encounter_pool:
        var data = _encounter_pool[enc_id]
        if data.level <= max_level:
            available.append(enc_id)
            weights.append(data.weight)
    return _weighted_sample(available, weights, count)

func has_content(type: ContentType, id: String) -> bool:
    return _get_pool_for_type(type).has(id)

func get_all(type: ContentType, max_level: int = 999) -> Array[String]:
    var pool = _get_pool_for_type(type)
    return pool.keys().filter(func(id): return pool[id] <= max_level)
```

**EncounterFactory Changes** (Phase 6):
```gdscript
# BEFORE (duplicated filtering):
func pick_items(count: int, max_level: int) -> Array:
    var available = _filter_by_level(GameData.get_all_items(), max_level)
    # ... filtering logic duplicated

# AFTER (delegates to RunPool):
func pick_items(count: int, max_level: int) -> Array:
    return _run_pool.pick_random(RunPool.ContentType.ITEM, count, max_level)
```

### 4.3 Update Draft UI

**Files to Modify**:
- `scenes/ui/draft.tscn` / `draft.gd`

**Changes**:
- Display Legacy cards instead of Character cards
- Show: name, description, income, starting character/item preview
- Show unlock cost for non-owned legacies
- Show prestige level
- Update draft flow to use LegacyDraftManager

**Files to Create**:
- `scenes/components/legacy_card.tscn` / `.gd`

### 4.4 Update Run Initialization

**Files to Modify**:
- `autoloads/run_manager.gd`

**Changes**:
- `start_new_run(drafted_legacies: Array[LegacyData])`
- Create RunPool from drafted legacies
- Add starting characters to grid (from legacy starting_character_id)
- Add starting items to inventory (from legacy starting_item_id)
- Calculate starting gold from legacy incomes
- Store drafted legacy IDs for fame distribution at run end

**Acceptance Criteria**:
- [ ] Draft presents 3 legacy options per round
- [ ] Owned vs non-owned legacies distinguished
- [ ] Drafting a legacy adds its content to run pool
- [ ] Starting characters/items given on draft
- [ ] Starting gold = sum of legacy incomes
- [ ] Run pool queries filter by unlocks and level

---

## Phase 5: Character Grid System

### 5.1 Create Grid Manager

**Files to Create**:
- `scripts/managers/character_grid.gd`

**Responsibilities**:
- Manage 2x3 grid (6 slots)
- Track character placement (row, column)
- Handle drag-and-drop logic (swap, move to empty)
- Provide queries: `get_character_at(row, col)`, `get_all_characters()`

**Data Structure**:
```gdscript
class_name CharacterGrid
extends RefCounted

# Grid layout:
# [0,0] [0,1] [0,2]  <- Front row
# [1,0] [1,1] [1,2]  <- Back row

var _grid: Array[Array]  # 2x3, each cell is CharacterInstance or null

func place_character(character: CharacterInstance, row: int, col: int) -> bool
func remove_character(row: int, col: int) -> CharacterInstance
func swap_positions(from_row: int, from_col: int, to_row: int, to_col: int) -> void
func get_character_at(row: int, col: int) -> CharacterInstance
func get_all_characters() -> Array[CharacterInstance]
func get_empty_slots() -> Array[Vector2i]
func is_slot_empty(row: int, col: int) -> bool
```

### 5.2 Update TeamManager → Grid Integration

**Files to Modify**:
- `scripts/managers/team_manager.gd`

**Changes**:
- Replace `_team: Array[CharacterInstance]` with `_grid: CharacterGrid`
- Update `add_character()` to place in first empty slot
- Add `move_character()`, `swap_characters()`
- Update XP distribution to use grid.get_all_characters()
- Keep max team size at 6 (full grid)

### 5.3 Create Grid UI Component

**Files to Create**:
- `scenes/components/character_grid.tscn` / `.gd`

**Features**:
- 2x3 grid visual layout
- Each slot shows character card or empty placeholder
- Drag-and-drop support:
  - Drag character from slot
  - Drop on empty slot = move
  - Drop on occupied slot = swap
- Visual feedback (hover, drag, valid/invalid drop)

### 5.4 Update Run View for Grid

**Files to Modify**:
- `scenes/ui/run_view.tscn` / `run_view.gd`

**Changes**:
- Replace team panel with CharacterGrid component
- Wire up drag-and-drop events
- Update to show grid instead of horizontal character list

### 5.5 Update Character Acquisition

**Files to Modify**:
- Encounter handlers that give characters

**Changes**:
- When character is acquired, place in first empty grid slot
- If grid full, show replacement UI:
  - Display new character alongside current grid
  - Player taps a grid slot to replace that character
  - Replaced character is removed (not stored elsewhere)
  - Can cancel to decline the new character
- Update UI to show grid slot selection

**Files to Create**:
- `scenes/components/character_replacement_popup.tscn` / `.gd`

```gdscript
class_name CharacterReplacementPopup
extends ModalPopup

signal character_replaced(removed: CharacterInstance, slot: Vector2i)
signal replacement_cancelled

var _new_character: CharacterInstance
var _grid: CharacterGrid

func show_replacement(new_char: CharacterInstance, grid: CharacterGrid) -> void:
    _new_character = new_char
    _grid = grid
    _display_new_character()
    _display_grid_for_selection()
    show_modal()

func _on_slot_selected(row: int, col: int) -> void:
    var removed = _grid.remove_character(row, col)
    _grid.place_character(_new_character, row, col)
    character_replaced.emit(removed, Vector2i(row, col))
    hide_modal()

func _on_cancel_pressed() -> void:
    replacement_cancelled.emit()
    hide_modal()
```

**Acceptance Criteria**:
- [ ] CharacterGrid manages 2x3 slots
- [ ] Characters placed in grid on acquisition
- [ ] When grid full, replacement UI appears
- [ ] Player can select which character to replace
- [ ] Player can cancel (decline new character)
- [ ] Drag-and-drop works (move, swap)
- [ ] Run view shows grid layout
- [ ] Grid persists in run save file

---

## Phase 6: Encounter Pool Composition

### 6.1 Separate Base vs Legacy Encounters

**Files to Modify**:
- `data/encounters/encounter_types.json`

**Changes**:
- Add `"source": "base"` to existing encounters
- Legacy-unique encounters will have `"source": "legacy"`

**Files to Create**:
- `data/encounters/legacy_encounters.json` (optional, or inline in legacies.json)

### 6.2 Update EncounterFactory

**Files to Modify**:
- `autoloads/encounter_factory.gd`

**Changes**:
- Accept RunPool to filter available content
- Compose encounter pool: base encounters (weight 100) + legacy unique encounters
- Delegate content picking to RunPool (DRY)

**Encounter Weighting Formula**:
```
Base encounters: weight = 100 (fixed)
Legacy encounters: weight = 100 + (prestige_weight_bonuses)

Where prestige_weight_bonuses = sum of all encounter_weight_bonus values
from prestige_rewards the player has unlocked for that legacy.

Example:
- Legacy at prestige 3, with +10 bonus at prestige 2 and +10 at prestige 3
- Weight = 100 + 10 + 10 = 120
```

**New Methods**:
```gdscript
var _run_pool: RunPool

func set_run_pool(pool: RunPool) -> void:
    _run_pool = pool

func generate_encounter_options(count: int, max_level: int) -> Array[EncounterOption]:
    # Combine base encounters (always available) with legacy encounters (from pool)
    var base_encounters = _get_base_encounters(max_level)
    var legacy_encounters = _run_pool.get_all(RunPool.ContentType.ENCOUNTER, max_level)

    # Build weighted list
    var weighted_pool = []
    for enc in base_encounters:
        weighted_pool.append({ "id": enc.id, "weight": 100, "data": enc })
    for enc_id in legacy_encounters:
        var enc_data = GameData.get_encounter(enc_id)
        var weight = _run_pool.get_encounter_weight(enc_id)  # 100 + prestige bonuses
        weighted_pool.append({ "id": enc_id, "weight": weight, "data": enc_data })

    return _weighted_sample_encounters(weighted_pool, count)

# Content picking now delegates to RunPool (DRY)
func _pick_items_for_encounter(count: int, max_level: int) -> Array:
    return _run_pool.pick_random(RunPool.ContentType.ITEM, count, max_level)

func _pick_skills_for_encounter(count: int, max_level: int) -> Array:
    return _run_pool.pick_random(RunPool.ContentType.SKILL, count, max_level)

func _pick_characters_for_encounter(count: int, max_level: int) -> Array:
    return _run_pool.pick_random(RunPool.ContentType.CHARACTER, count, max_level)
```

### 6.3 Update Encounter Content Filtering

**Files to Modify**:
- `autoloads/encounter_factory.gd` - Generator functions

**Changes**:
- `pick_items()` filters by run pool
- `pick_skills()` filters by run pool
- `pick_characters()` (new) filters by run pool
- Level gating still applies

### 6.4 Create Character Shop Encounter

**Files to Create**:
- `scripts/encounters/handlers/character_shop_handler.gd`

**Features**:
- New base encounter type: "Character Shop"
- Displays 2-3 characters from run pool (level-gated)
- Each character shows: name, stats preview, cost (from character JSON)
- Player purchases with gold → character added to grid (or replacement popup if full)
- Architecture supports many variations (themed shops, discounted shops, etc.)

**Encounter Type Definition** (add to encounter_types.json):
```json
{
  "type": "character_shop",
  "name": "Mercenary Camp",
  "description": "Hire adventurers to join your party",
  "weight": 100,
  "source": "base",
  "generators": {
    "offerings": { "type": "pick_characters", "count": 3 }
  }
}
```

### 6.5 Update Existing Encounters for Character Rewards

**Files to Modify**:
- `scripts/encounters/handlers/treasure_chest_handler.gd`
- `scripts/encounters/handlers/gamble_handler.gd`
- `scripts/encounters/handlers/wheel_of_fortune_handler.gd`
- Other reward-granting encounters

**Changes**:
- Add character as possible reward type
- Use `pick_characters` generator (delegates to RunPool)
- Handle grid-full scenario (show replacement popup)
- Update reward preview to show character info

**Generator Addition** (in EncounterFactory):
```gdscript
func _pick_characters(params: Dictionary, context: Dictionary) -> Array:
    var count = params.get("count", 1)
    var max_level = context.get("max_level", 999)
    return _run_pool.pick_random(RunPool.ContentType.CHARACTER, count, max_level)
```

**Acceptance Criteria**:
- [ ] Base encounters always available
- [ ] Legacy encounters added when legacy drafted
- [ ] Prestige affects legacy encounter weighting
- [ ] Encounter content filtered by run pool
- [ ] Character shop encounter works
- [ ] Existing encounters can reward characters
- [ ] Grid-full replacement handled in all character acquisition paths

---

## Phase 7: Fame Distribution & End-of-Run

### 7.1 Update Run Results Logic

**Files to Modify**:
- `scripts/rewards/reward_calculator.gd`

**Changes**:
- Fame goes to drafted legacies (not characters)
- Split formula: fame per legacy based on run performance
- Trigger prestige-up on legacies when fame threshold reached

**New Methods**:
```gdscript
static func calculate_legacy_fame_reward(victory: bool, wins: int) -> int
static func distribute_fame_to_legacies(
    legacy_collection: LegacyCollection,
    drafted_legacy_ids: Array[String],
    fame_per_legacy: int
) -> Array[Dictionary]  # Returns prestige-up info
```

### 7.2 Update Run Results UI

**Files to Modify**:
- `scenes/ui/run_results.tscn` / `run_results.gd`

**Changes**:
- Show fame awarded to each drafted legacy
- Show prestige-up for legacies that crossed threshold
- Show newly unlocked content per legacy
- Remove character fame display

### 7.3 Update PlayerAccount End-of-Run

**Files to Modify**:
- `autoloads/player_account.gd`

**Changes**:
- `end_run()` distributes fame to legacies
- Triggers LegacyCollection prestige updates
- Persists updated legacy state

**Acceptance Criteria**:
- [ ] Fame awarded to drafted legacies at run end
- [ ] Prestige-up triggers when fame >= 100
- [ ] Newly unlocked content tracked and displayed
- [ ] Run results show legacy-centric rewards

---

## Phase 8: Collection & Main Menu Updates

### 8.1 Create Legacy Collection Screen

**Files to Create**:
- `scenes/ui/legacy_collection.tscn` / `legacy_collection.gd`

**Features**:
- Grid of owned legacies
- Legacy detail view:
  - Name, description, icon
  - Prestige level, fame progress
  - Unlocked content preview (characters, items, skills, encounters)
  - Income value
- Unlock new legacies with gems

### 8.2 Update Main Menu

**Files to Modify**:
- `scenes/ui/main_menu.tscn` / `main_menu.gd`

**Changes**:
- Replace "Characters" button with "Legacies"
- Navigate to legacy_collection instead of collection

### 8.3 Deprecate Old Collection Screen

**Files to Modify/Archive**:
- `scenes/ui/collection.tscn` / `collection.gd`

**Decision**: Archive or remove character-centric collection UI

### 8.4 Update Tutorial/Onboarding (if exists)

**Files to Modify**:
- Any tutorial or onboarding flows

**Changes**:
- Explain legacies instead of characters
- Guide player through legacy draft

**Acceptance Criteria**:
- [ ] Legacy collection screen shows all legacies
- [ ] Prestige/fame/unlocks visible per legacy
- [ ] Main menu navigates to legacy collection
- [ ] Old character collection deprecated

---

## Data Migration Strategy

### Clean Slate Approach

Game is unreleased. No migration needed.

**Behavior**:
- Old save files are ignored (not loaded)
- All players start fresh with default starting state
- Old `player_account.json` format simply won't parse; new format created

**Implementation**:
```gdscript
# In PlayerAccount._ready() or load function:
func _load_account() -> void:
    var data = JsonPersistence.load_json(SAVE_PATH)
    if data == null or not _is_valid_format(data):
        # Old/invalid format - start fresh
        _initialize_default_account()
        return
    _load_from_dict(data)

func _is_valid_format(data: Dictionary) -> bool:
    # New format has "legacies", old format has "characters"
    return data.has("legacies") and data.has("format_version")
```

**Default Starting State**:
- `format_version`: 2
- `gems`: 1000 (or whatever starting amount)
- `reroll_tokens`: 0
- `legacies`: All legacies at prestige 1, first starting character/item selected by default

---

## Testing Strategy

### Unit Tests (per phase)

Each phase should include tests for:
- Data loading (JSON → runtime objects)
- Manager state transitions
- Save/load roundtrip
- Edge cases (empty pools, max prestige, etc.)

### Integration Tests

- Full draft → run → end flow
- Legacy prestige-up during run results
- Content filtering with multiple legacies
- Grid drag-and-drop

### Manual Testing Checklist

- [ ] New player experience (no save data)
- [ ] Migrated player experience (old save)
- [ ] Draft all owned legacies
- [ ] Draft non-owned legacy (gem cost)
- [ ] Acquire characters during run
- [ ] Fill grid to 6 characters
- [ ] Complete run (victory)
- [ ] Complete run (defeat)
- [ ] Prestige-up rewards display

---

## Risk Mitigation

### High-Risk Areas

1. **Draft Phase Rewrite**: Core loop change; test thoroughly
2. **Grid UI**: New interaction pattern; usability testing needed
3. **Content Pool Composition**: Multiple legacies' content merging; edge cases

### Mitigation Strategies

1. **Old Repo Backup**: Original game preserved in separate repo if we need to reference
2. **Phase-by-Phase Testing**: Each phase tested in isolation before moving on
3. **Stub Content**: Use minimal test legacies/characters to validate architecture before full content
4. **Clean Break Benefits**: No compatibility concerns; can refactor aggressively

---

## Dependencies & Order

```
Phase 0 (Foundation)
    ↓
Phase 1 (Character Simplification)
    ↓
Phase 2 (Player Items) ←──┐
    ↓                     │
Phase 3 (Skills)          │ (can be parallel)
    ↓                     │
Phase 4 (Draft) ──────────┘
    ↓
Phase 5 (Grid)
    ↓
Phase 6 (Encounter Pool)
    ↓
Phase 7 (Fame Distribution)
    ↓
Phase 8 (Collection UI)
```

**Critical Path**: Phase 0 → Phase 1 → Phase 4 → Phase 5 → Phase 7

**Parallelizable**: Phase 2 and Phase 3 can proceed in parallel after Phase 1

---

## Constants Updates (GameConstants)

```gdscript
# NEW constants
const GRID_ROWS: int = 2
const GRID_COLS: int = 3
const MAX_GRID_CHARACTERS: int = 6  # replaces TEAM_SIZE
const LEGACY_UNLOCK_COST: int = 500  # replaces CHARACTER_UNLOCK_COST

# DEPRECATED constants
# const TEAM_SIZE: int = 3  # replaced by MAX_GRID_CHARACTERS
# const MAX_RUN_ITEMS: int = 6  # no limit now
# const MAX_RUN_SKILLS: int = 6  # skills are instant, no accumulation
```

---

## File Inventory Summary

### New Files to Create

| File | Phase | Purpose |
|------|-------|---------|
| `scripts/managers/prestige_tracker.gd` | 0 | Reusable prestige/fame logic (DRY) |
| `data/legacies/legacies.json` | 0 | Legacy definitions |
| `scripts/data_classes/legacy_data.gd` | 0 | Legacy runtime class |
| `scripts/managers/legacy_collection.gd` | 0 | Legacy account state |
| `scripts/managers/player_inventory.gd` | 2 | Player-level items |
| `scripts/skills/skill_effect_registry.gd` | 3 | Skill effect dispatcher (OCP) |
| `scripts/skills/skill_context.gd` | 3 | Context for skill handlers |
| `scripts/skills/effects/*.gd` | 3 | Individual effect implementations |
| `scripts/managers/lingering_effects.gd` | 3 | Lingering effect tracker |
| `scripts/managers/run_state.gd` | 4 | Run subsystem composite (SRP) |
| `scripts/managers/legacy_draft_manager.gd` | 4 | Legacy draft logic |
| `scripts/managers/run_pool.gd` | 4 | Content pool + filtering (DRY) |
| `scenes/components/legacy_card.tscn` | 4 | Legacy UI card |
| `scripts/managers/character_grid.gd` | 5 | 2x3 grid manager |
| `scenes/components/character_grid.tscn` | 5 | Grid UI component |
| `scenes/components/character_replacement_popup.tscn` | 5 | Grid-full replacement UI |
| `scripts/encounters/handlers/character_shop_handler.gd` | 6 | Character shop encounter |
| `data/encounters/encounter_types.json` (modify) | 6 | Add character_shop type |
| `scenes/ui/legacy_collection.tscn` | 8 | Legacy collection screen |

### Files to Modify (Major)

| File | Phase | Changes |
|------|-------|---------|
| `data/characters/characters.json` | 1 | Remove income, prestige_rewards |
| `scripts/managers/character_collection.gd` | 1 | Remove prestige/fame (or delete entirely) |
| `scripts/data_classes/character_instance.gd` | 1 | Remove equipment, add grid_position |
| `scripts/utils/stat_calculator.gd` | 1 | Remove item/skill stat mods from characters |
| `autoloads/game_data.gd` | 0 | Add legacy loading |
| `autoloads/player_account.gd` | 0, 7 | Add legacy facade, fame distribution |
| `autoloads/run_manager.gd` | 4 | Delegate to RunState composite (SRP fix) |
| `autoloads/encounter_factory.gd` | 6 | Delegate to RunPool (DRY), add weighting |
| `scenes/ui/draft.tscn` | 4 | Legacy draft UI |
| `scenes/ui/run_view.tscn` | 5 | Grid display |
| `scenes/ui/run_results.tscn` | 7 | Legacy fame display |
| `scenes/ui/main_menu.tscn` | 8 | Legacy collection link |

### Files to Delete/Archive (Old System Excision)

| File | Phase | Reason |
|------|-------|--------|
| `scripts/managers/character_collection.gd` | 1 | Replaced by LegacyCollection |
| `scripts/managers/draft_manager.gd` | 4 | Replaced by LegacyDraftManager |
| `scenes/ui/collection.tscn` | 8 | Replaced by legacy_collection.tscn |

---

## Resolved Design Decisions

1. **Build Fresh**: Legacy system is built from scratch; old character system will be excised completely. Existing code serves as blueprint for patterns only.

2. **Character Replacement**: When grid is full, player sees a replacement popup. They tap a grid slot to replace that character with the new one. Can cancel to decline.

3. **Starting Characters**: Every legacy MUST have at least one starting character. Prestige unlocks additional starting character OPTIONS. Player selects ONE active starting character per legacy in the Collection screen (pre-game, persists until changed).

4. **Starting Items**: Optional per legacy. Mirrors the character system—prestige unlocks options, player selects one, chosen in Collection screen. Architecture supports this even if not all legacies use it.

5. **Encounter Weighting Formula**: Base weight = 100. Certain prestige levels add +10 via `encounter_weight_bonus` in prestige_rewards. Weight = 100 + sum(unlocked bonuses).

6. **Save Migration**: Clean slate. Game is unreleased; no migration needed. Old saves ignored.

7. **Character Acquisition**:
   - New "Character Shop" base encounter type (with many variations planned)
   - Characters CAN appear as rewards in existing encounters (update handlers)
   - Characters have `cost` field in their JSON data (like items/skills)

8. **Item Effects**: Items can provide:
   - Team-wide stat bonuses ("+10 health to all characters")
   - Player-level effects ("+5 gold per combat win")
   - Triggered effects ("When a character dies, heal others for 20")
   - Architecture supports all; specific effects are content design

9. **Content Pool Deduplication**: Same content can appear in multiple legacies' pools. When composing run pool, duplicates are merged—one of everything, no duplicates.

10. **Fame Distribution**: Equally distributed to all 3 drafted legacies at run end.

11. **Draft Structure**: Same as old character draft:
    - 3 rounds, pick 1 legacy per round
    - Each round: 2 owned legacies + 1 random (costs 500 gems if not owned)
    - Reroll tokens work the same way

12. **Development Approach**: Clean break. Delete old system files as we build new. Game will be broken until refactor completes. Old game backed up in separate repo.

---

## Open Design Decisions

These are content design decisions, not architecture blockers:

1. **Legacy Content**: What are the actual legacies and their content? (Out of scope for architecture)
2. **Skill Effects**: What specific one-shot effects should skills have? (Content design)
3. **Character Costs**: How to balance character gold costs against rarity/power? (Balance tuning)

---

## Success Metrics

After refactor completion:

- [ ] All existing features work with new architecture
- [ ] Save migration succeeds for test accounts
- [ ] New player can complete full game loop
- [ ] Legacy prestige system functions correctly
- [ ] Grid drag-and-drop is responsive and intuitive
- [ ] No regressions in encounter system
- [ ] Performance is acceptable (load times, UI responsiveness)

---

## SOLID/DRY Compliance Summary

This plan was audited against SOLID principles and DRY. Here's how each is addressed:

### Single Responsibility Principle (SRP)

| Component | Single Responsibility |
|-----------|----------------------|
| `PrestigeTracker` | Tracks prestige/fame for any entity |
| `LegacyCollection` | Manages legacy account state |
| `RunState` | Owns run subsystems (grid, inventory, effects, pool) |
| `RunManager` | Orchestrates run flow (delegates state to RunState) |
| `CharacterGrid` | Manages 2x3 character placement |
| `PlayerInventory` | Manages player-level items |
| `LingeringEffects` | Tracks delayed skill effects |
| `RunPool` | Composes and queries content pools |
| `SkillEffectRegistry` | Dispatches skill effects to handlers |

### Open/Closed Principle (OCP)

| Extension Point | Mechanism |
|-----------------|-----------|
| Skill effects | `SkillEffectRegistry.register()` - add effects without modifying registry |
| Encounter types | `EncounterRegistry` (existing) - same pattern |
| Content types | `RunPool.ContentType` enum + `_get_pool_for_type()` - add types by extending enum |

### Liskov Substitution Principle (LSP)

- No deep inheritance hierarchies
- Prefer composition (e.g., `LegacyData` contains `PrestigeTracker`, doesn't extend it)
- Data classes are value objects with factory methods

### Interface Segregation Principle (ISP)

- `RunPool` provides focused query methods per content type
- Handlers receive only the context they need (`SkillContext`, `EncounterContext`)

### Dependency Inversion Principle (DIP)

- Managers accept dependencies via constructor/init, not global lookups
- `RunState` injected into handlers via context objects
- `PrestigeTracker` is a composition dependency, not inheritance

### DRY Compliance

| Concern | Single Location |
|---------|-----------------|
| Level gating | `RunPool.pick_random()` - all level filtering here |
| Content picking | `RunPool.pick_random()` - single method for all types |
| Prestige/fame logic | `PrestigeTracker` - reusable across entities |
| Encounter weighting | `LegacyData.get_encounter_weight()` + `RunPool` |
| Character replacement | `CharacterReplacementPopup` - single UI component |

### Violations Avoided

1. **RunManager bloat**: Prevented by extracting `RunState` composite
2. **Skill effect match statement**: Replaced with `SkillEffectRegistry`
3. **Duplicated level filtering**: Centralized in `RunPool`
4. **Prestige/fame duplication**: Extracted to `PrestigeTracker`
