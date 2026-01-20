# SOLID/DRY Refactoring Plan

## Executive Summary

After reviewing the entire codebase, I found **15 issues** of varying severity. The codebase already shows good foundational work (StatCalculator, JsonPersistence, UIHelpers, GameConstants), but there are opportunities for improvement, particularly in the UI layer.

---

## Issues by Priority

### HIGH PRIORITY

#### Issue 1: Duplicated UI Panel Creation
**Files:** `encounter_select.gd:30-96`, `combat_select.gd:30-122`

Both files create option panels with nearly identical patterns:
- PanelContainer → MarginContainer → Content
- Same margin overrides (10px all sides)
- Same image setup (TextureRect with safe loading)
- Same button/label patterns

**Options:**
- [X] **A) Extract to UIHelpers** - Add `create_option_panel_base()` method  (Note: Verify the application's usefulness for both the contents of encounter panel selections as well the encounters themselves)
- [ ] **B) Create SelectionPanelBuilder** - New utility class for building selection UIs
- [ ] **C) Skip** - Accept duplication as acceptable for UI clarity

---

#### Issue 2: RunManager is a God Class (454 lines)
**File:** `run_manager.gd`

RunManager handles 5+ unrelated responsibilities:
1. Run state (round, phase)
2. Team management
3. Progression tracking (reputation, wins/losses)
4. Combat option generation
5. Rewards calculation

**Options:**
- [X] **A) Full decomposition** - Split into RunStateManager, TeamManager, CombatGenerator, RewardCalculator
- [ ] **B) Extract CombatGenerator only** - Move combat generation to `scripts/managers/combat_generator.gd`
- [ ] **C) Extract TeamManager only** - Move team-related methods to separate manager
- [ ] **D) Skip** - Keep as-is, complexity is manageable

---

### MEDIUM PRIORITY

#### Issue 3: Duplicated Shop Item/Skill Row Creation
**File:** `encounter_execute.gd:116-229`

`_create_shop_item_row()` and `_create_shop_skill_row()` are 95% identical:
- Same HBox setup
- Same icon creation (48x48 TextureRect)
- Same info VBox (name + description labels)
- Same buy button creation
- Same character selector

**Options:**
- [ ] **A) Unify into single method** - `_create_shop_row(data: Dictionary, data_type: String)`
- [X] **B) Extract to UIHelpers** - `UIHelpers.create_shop_row()`
- [ ] **C) Skip** - Keep separate for type-specific future customization

---

#### Issue 4: Hard-coded Encounter Types (Open/Closed Violation)
**File:** `encounter_execute.gd:27-42`

Match statement requires modification for each new encounter type:
```gdscript
match encounter_data["type"]:
    "shop": _setup_shop_encounter()
    "xp_reward": _setup_xp_reward_encounter()
    # Adding new type = modifying this file
```

**Options:**
- [ ] **A) Strategy pattern** - Each encounter type defines its own setup handler
- [X] **B) Data-driven factory** - Move setup logic to encounter type definitions
- [ ] **C) Skip** - Current approach is simple enough for limited encounter types

---

#### Issue 5: Magic Numbers Not in GameConstants
**Scattered across:** `encounter_execute.gd`, `run_view.gd`, `combat_select.gd`, `run_manager.gd`

Examples:
- `Vector2(48, 48)` icon sizes
- `Color(1.0, 0.84, 0.0)` gold color
- `Color(1.0, 0.5, 0.5)` error color
- `20 + (difficulty_index * 10)` reward calculations
- Reputation thresholds (5, 10) for color coding

**Options:**
- [X] **A) Full audit and extract** - Move ALL magic numbers to GameConstants
- [ ] **B) Extract only frequently used** - Focus on colors, icon sizes, reward formulas
- [ ] **C) Skip** - Current magic numbers are local and clear in context

---

#### Issue 6: Combat Generation Hard-coded in RunManager
**File:** `run_manager.gd:367-425`

AI and ghost combat options have hard-coded:
- Difficulty names ("Easy", "Medium", "Hard")
- Reward formulas (20 + difficulty_index * 10)
- Image paths
- Name/description strings

**Options:**
- [ ] **A) Move to data file** - Create `combat_options.json` like encounters
- [ ] **B) Create CombatFactory** - Mirror EncounterFactory pattern
- [ ] **C) Extract constants only** - Move formulas/strings to GameConstants
- [X] **D) Skip** - Combat system is stub; refactor when implementing real combat

---

#### Issue 7: Generic Dictionary Returns (Interface Segregation)
**Files:** `run_manager.gd`, `encounter_factory.gd`

Functions return untyped Dictionary objects:
```gdscript
func _generate_ai_combat_option() -> Dictionary:
    return {"type": "ai", "name": "...", ...}
```

Consumers only use subset of fields.

**Options:**
- [X] **A) Create typed classes** - `CombatOption`, `EncounterOption` data classes
- [ ] **B) Use Godot Resources** - Create `.tres` resource types
- [ ] **C) Skip** - Dictionary pattern is idiomatic GDScript, works fine

---

### LOW PRIORITY

#### Issue 8: Repeated Data Loading Pattern
**File:** `game_data.gd:44-80`

Five identical loading methods for characters, items, item_upgrades, skills, encounters.

**Options:**
- [X] **A) Extract helper** - `_load_data_collection(path, container_key, target_dict)`
- [ ] **B) Skip** - Explicit methods are clear and only run once at startup

---

#### Issue 9: Repeated Character Selector Creation
**File:** `encounter_execute.gd:232-239`

`_create_character_selector()` called in multiple places, could be reused elsewhere.

**Options:**
- [X] **A) Move to UIHelpers** - `UIHelpers.create_team_selector()`
- [ ] **B) Skip** - Only used in encounter_execute currently

---

#### Issue 10: Currency Display Could Be Component
**File:** `main_menu.gd:35-45`

Currency display logic (gems + reroll tokens) will likely be needed in multiple scenes.

**Options:**
- [X] **A) Create CurrencyDisplay component** - Reusable scene with auto-updating labels
- [ ] **B) Skip** - Only needed in main menu currently

---

#### Issue 11: Repeated Stat Display Formatting
**Files:** `character_card.gd`, `run_view.gd`, `character_details.gd`

Multiple places manually call `UIHelpers.format_stat()` for all 5 stats.

**Options:**
- [ ] **A) Create stats display helper** - `UIHelpers.populate_stat_labels(stats_dict, label_mapping)`
- [X] **B) Skip** - Pattern is clear and explicit

---

#### Issue 12: Components Directly Access GameData
**Files:** `item_slot.gd`, `skill_icon.gd`

Direct dependency on global GameData autoload.

**Options:**
- [ ] **A) Add optional data injection** - Like CharacterInstance pattern (line 37)
- [X] **B) Skip** - Autoloads are designed for global access in Godot

---

#### Issue 13: Repeated Signal Connection Pattern
**File:** `player_account.gd:103-118`

Four identical `if not signal.is_connected(): signal.connect()` blocks.

**Options:**
- [X] **A) Extract helper** - `_safe_connect(signal, handler)`
- [ ] **B) Skip** - Pattern is clear and only in one place

---

#### Issue 14: Inconsistent Texture Loading
**Files:** `item_slot.gd`, `skill_icon.gd`, others

Some places use `UIHelpers.set_texture_safe()`, others use manual `ResourceLoader.exists()` check.

**Options:**
- [X] **A) Standardize on UIHelpers.set_texture_safe()** - Replace all manual checks
- [ ] **B) Skip** - Inconsistency is minor

---

#### Issue 15: Emoji Strings Hardcoded
**Files:** `run_view.gd`, `main_menu.gd`

Emoji like "💎", "❤️", "⭐", "💰" scattered in format strings.

**Options:**
- [X] **A) Add to GameConstants** - `EMOJI_GEM = "💎"`, etc.
- [ ] **B) Skip** - Emoji are clear in context

---

## Recommended Implementation Order

If you approve changes, I recommend this sequence:

1. **Issue 5** (magic numbers) - Quick win, reduces technical debt
2. **Issue 3** (shop rows) - Clear DRY violation, straightforward fix
3. **Issue 1** (panel creation) - Clear DRY violation, medium effort
4. **Issue 2** (RunManager) - Largest impact, most effort
5. **Remaining LOW items** - As time permits

---

## What Looks Good (No Action Needed)

The codebase already demonstrates solid practices:
- `StatCalculator` - Excellent centralized stat logic
- `JsonPersistence` - Proper file I/O abstraction
- `UIHelpers` - Good utility extraction (expand it)
- `GameConstants` - Good foundation (needs more constants)
- `CurrencyManager` / `CharacterCollection` - Clean SRP split
- `CharacterInstance` dependency injection pattern
- Signal-based communication throughout

---

## Instructions

Please review each issue above and mark your choices:
- **[X]** for options you want implemented
- **[ ]** for options to skip

Reply with your selections and I'll implement the approved changes.
