# Progression Systems

This document provides a comprehensive technical breakdown of the game's progression systems: Prestige, Fame, Player Level, and Item Upgrades.

## Overview

The game has **two isolated progression layers**:

| Layer | Scope | Persistence | Purpose |
|-------|-------|-------------|---------|
| **Account-level** | Across all runs | Persistent (saved) | Long-term meta-progression |
| **Run-level** | Single run only | Temporary | In-run power scaling |

Run-level progression feeds back into account-level **only at run end**.

---

## 1. Prestige System (Account-Level)

### Concept

Prestige is a **legacy-level** progression metric. Each legacy (e.g., House Stark, House Targaryen) has its own independent prestige level that persists across all runs.

### Implementation

**Primary File:** `scripts/managers/prestige_tracker.gd`

The `PrestigeTracker` class is a reusable component that handles prestige/fame tracking. It follows the Single Responsibility Principle and can be composed into any entity needing prestige tracking.

```gdscript
class_name PrestigeTracker
extends RefCounted

var _prestige: int = 1
var _fame: int = 0

const FAME_PER_PRESTIGE: int = 100
```

**Composition in LegacyData:** `scripts/data_classes/legacy_data.gd:32`

```gdscript
var prestige_tracker: PrestigeTracker  # Composition, not inheritance (DIP)
```

### Configuration

| Property | Value | Location |
|----------|-------|----------|
| Starting prestige | 1 | `prestige_tracker.gd:13` |
| Fame per prestige level | 100 | `prestige_tracker.gd:17` |
| Maximum prestige | Unlimited | No cap implemented |

### Key Functions

#### `PrestigeTracker.get_prestige() -> int`
**File:** `prestige_tracker.gd:24-26`

Returns the current prestige level.

```gdscript
func get_prestige() -> int:
    return _prestige
```

#### `PrestigeTracker.get_fame() -> int`
**File:** `prestige_tracker.gd:29-31`

Returns current fame (progress toward next prestige).

```gdscript
func get_fame() -> int:
    return _fame
```

#### `PrestigeTracker.get_fame_progress() -> float`
**File:** `prestige_tracker.gd:34-36`

Returns fame as a percentage (0.0 to 1.0) for UI progress bars.

```gdscript
func get_fame_progress() -> float:
    return float(_fame) / float(FAME_PER_PRESTIGE)
```

#### `PrestigeTracker.add_fame(amount: int) -> Dictionary`
**File:** `prestige_tracker.gd:43-83`

Core function that adds fame and processes prestige increases. Handles overflow (gaining multiple prestige levels at once).

```gdscript
func add_fame(amount: int) -> Dictionary:
    if amount <= 0:
        return {
            "prestige_increased": false,
            "new_prestige": _prestige,
            "overflow_fame": _fame,
            "levels_gained": 0
        }

    _fame += amount
    var result = {
        "prestige_increased": false,
        "new_prestige": _prestige,
        "levels_gained": 0
    }

    # Process prestige increases (handles overflow)
    while _fame >= FAME_PER_PRESTIGE:
        _fame -= FAME_PER_PRESTIGE
        _prestige += 1
        result.prestige_increased = true
        result.new_prestige = _prestige
        result.levels_gained += 1
        prestige_up.emit(_prestige)

    fame_changed.emit(_fame)
    result.overflow_fame = _fame
    return result
```

**Return Dictionary:**
| Key | Type | Description |
|-----|------|-------------|
| `prestige_increased` | bool | Whether any prestige was gained |
| `new_prestige` | int | Current prestige after operation |
| `overflow_fame` | int | Remaining fame after prestige increases |
| `levels_gained` | int | How many prestige levels were gained |

**Example:** Adding 250 fame at prestige 1 with 0 fame:
- Result: prestige 3, overflow_fame 50, levels_gained 2

### What Prestige Unlocks

When prestige increases, `LegacyData._apply_prestige_rewards()` processes the legacy's `prestige_rewards` array.

**File:** `legacy_data.gd:242-315`

```gdscript
func _apply_prestige_rewards(target_prestige: int) -> Dictionary:
    var unlocked_content = {
        "starting_characters": [],
        "starting_items": [],
        "characters": [],
        "items": [],
        "item_upgrades": [],
        "skills": [],
        "encounters": []
    }

    for reward in prestige_rewards:
        if reward.get("prestige", 0) == target_prestige:
            var unlocks = reward.get("unlocks", {})

            # Unlock starting characters
            for char_id in unlocks.get("starting_characters", []):
                if char_id not in unlocked_starting_characters:
                    unlocked_starting_characters.append(char_id)
                    unlocked_content.starting_characters.append(char_id)

            # ... similar for other unlock types ...

            # Add encounter weight bonus
            var weight_bonus = unlocks.get("encounter_weight_bonus", 0)
            if weight_bonus > 0:
                total_encounter_weight_bonus += weight_bonus

            break  # Found the matching prestige level

    return unlocked_content
```

**Unlock Categories:**

| Category | Array in LegacyData | Purpose |
|----------|---------------------|---------|
| `starting_characters` | `unlocked_starting_characters` | Characters available in draft |
| `starting_items` | `unlocked_starting_items` | Items for pre-run loadout |
| `characters` | `unlocked_characters` | Characters available during runs |
| `items` | `unlocked_items` | Items in run reward pools |
| `item_upgrades` | `unlocked_item_upgrades` | Upgrade drops (requires base item) |
| `skills` | `unlocked_skills` | Skills in run reward pools |
| `encounters` | `unlocked_encounters` | Legacy-specific unique encounters |
| `encounter_weight_bonus` | `total_encounter_weight_bonus` | Increases unique encounter frequency |

### Data Structure

**File:** `data/legacies/legacies.json`

```json
{
  "id": "legacy_house_stark",
  "name": "House Stark",
  "income": 15,
  "prestige_rewards": [
    {
      "prestige": 1,
      "unlocks": {
        "starting_characters": ["ST01"],
        "starting_items": [],
        "characters": ["ST01", "ST02", "ST03", "ST04", "ST05", "ST06", "ST07", "ST08", "ST09", "ST10"],
        "items": ["item_ice"],
        "skills": [],
        "encounters": ["castle_winterfell"]
      }
    },
    {
      "prestige": 2,
      "unlocks": {
        "starting_items": ["item_ice"],
        "item_upgrades": ["itemup_valyrian_ice"],
        "encounter_weight_bonus": 10
      }
    }
  ]
}
```

---

## 2. Fame System (Account-Level)

### Concept

Fame is the **progress currency toward the next prestige level**. It accumulates within each legacy's `PrestigeTracker` and is awarded only at run end.

### Fame Earning Formula

**File:** `scripts/managers/reward_calculator.gd:82-104`

```gdscript
static func calculate_legacy_fame_reward(victory: bool, wins: int) -> int:
    var base_fame = GameConstants.FAME_REWARD_BASE_DEFEAT  # 25
    if victory:
        base_fame = GameConstants.FAME_REWARD_BASE_VICTORY  # 75

    var win_bonus = wins * GameConstants.FAME_PER_WIN_BONUS  # wins * 5

    return base_fame + win_bonus
```

**Formula:**
```
Victory: 75 + (wins × 5)
Defeat:  25 + (wins × 5)
```

**Fame Reward Table:**

| Wins | Victory Fame | Defeat Fame |
|------|--------------|-------------|
| 0    | 75           | 25          |
| 1    | 80           | 30          |
| 2    | 85           | 35          |
| 3    | 90           | 40          |
| 4    | 95           | 45          |
| 5    | 100          | 50          |
| 6    | 105          | 55          |
| 7    | 110          | 60          |

### Fame Distribution

Fame is distributed **equally** to **all 3 drafted legacies** at run end.

**File:** `reward_calculator.gd:107-156`

```gdscript
static func distribute_fame_to_legacies(
    legacy_collection,  # LegacyCollection
    drafted_legacy_ids: Array,
    fame_per_legacy: int
) -> Array:
    var prestige_ups: Array = []

    for legacy_id in drafted_legacy_ids:
        var legacy = legacy_collection.get_legacy(legacy_id)
        if legacy == null:
            push_warning("RewardCalculator: Legacy not found: %s" % legacy_id)
            continue

        if not legacy.unlocked:
            push_warning("RewardCalculator: Cannot award fame to locked legacy: %s" % legacy_id)
            continue

        var old_prestige = legacy.get_prestige()
        var result = legacy_collection.add_legacy_fame(legacy_id, fame_per_legacy)

        if result.get("prestige_increased", false):
            prestige_ups.append({
                "legacy_id": legacy_id,
                "legacy_name": legacy.legacy_name,
                "old_prestige": old_prestige,
                "new_prestige": result.get("new_prestige", old_prestige + 1),
                "levels_gained": result.get("levels_gained", 1),
                "unlocked_content": result.get("unlocked_content", {})
            })

    return prestige_ups
```

**Return Array:** Contains one dictionary per legacy that gained prestige:

| Key | Type | Description |
|-----|------|-------------|
| `legacy_id` | String | ID of the legacy |
| `legacy_name` | String | Display name |
| `old_prestige` | int | Prestige before this run |
| `new_prestige` | int | Prestige after this run |
| `levels_gained` | int | Number of prestige levels gained |
| `unlocked_content` | Dictionary | What was unlocked (from `_apply_prestige_rewards`) |

### Fame → Prestige Conversion

Handled automatically by `PrestigeTracker.add_fame()`. When fame reaches 100:
1. Subtract 100 from fame
2. Increment prestige
3. Emit `prestige_up` signal
4. Repeat if fame still ≥ 100 (handles overflow)

---

## 3. Player Level System (Run-Level)

### Concept

Player level is a **run-wide** progression metric that resets each run. It gates when prestige-unlocked content becomes available during the current run.

### Implementation

**File:** `scripts/managers/progression_manager.gd`

```gdscript
class_name ProgressionManager
extends RefCounted

signal player_level_changed(new_level: int)

var player_level: int = 1
var player_xp: int = 0
```

### Configuration

| Property | Value | Location |
|----------|-------|----------|
| Starting level | 1 | `progression_manager.gd:18` |
| XP per level | 100 | `GameConstants.XP_PER_LEVEL` |
| Maximum level | 5 | `GameConstants.MAX_PLAYER_LEVEL` |

### XP Sources

**Combat Victory:** Base 30 XP (configurable per combat option)

**File:** `game_constants.gd:57`
```gdscript
const COMBAT_WIN_XP := 30
```

XP can also come from encounter rewards.

### Key Functions

#### `ProgressionManager.add_player_xp(amount: int) -> Result`
**File:** `progression_manager.gd:76-96`

Adds XP and processes level-ups. Returns a Result type for error handling.

```gdscript
func add_player_xp(amount: int):  # -> Result
    if amount <= 0:
        return Result.err(ErrorCodes.INVALID_XP_AMOUNT, "XP amount must be positive")
    if player_level >= GameConstants.MAX_PLAYER_LEVEL:
        return Result.err(ErrorCodes.MAX_LEVEL_REACHED, "Already at max level")

    player_xp += amount
    var leveled_up = false

    while player_xp >= GameConstants.XP_PER_LEVEL and player_level < GameConstants.MAX_PLAYER_LEVEL:
        player_xp -= GameConstants.XP_PER_LEVEL
        player_level += 1
        leveled_up = true

    if player_level >= GameConstants.MAX_PLAYER_LEVEL:
        player_xp = 0  # Clamp to 0 at max level

    if leveled_up:
        player_level_changed.emit(player_level)

    return Result.ok(leveled_up)
```

**Behavior:**
- Returns error if amount ≤ 0 or already at max level
- Processes multiple level-ups if XP exceeds threshold
- Clamps XP to 0 when reaching max level
- Emits `player_level_changed` signal on level-up

#### `ProgressionManager.get_xp_progress() -> float`
**File:** `progression_manager.gd:107-110`

Returns XP as a percentage (0.0 to 1.0) for UI progress bars.

```gdscript
func get_xp_progress() -> float:
    if player_level >= GameConstants.MAX_PLAYER_LEVEL:
        return 1.0
    return float(player_xp) / float(GameConstants.XP_PER_LEVEL)
```

#### `ProgressionManager.is_max_level() -> bool`
**File:** `progression_manager.gd:113-114`

```gdscript
func is_max_level() -> bool:
    return player_level >= GameConstants.MAX_PLAYER_LEVEL
```

### Level Progression Table

| Level | Total XP Required | Combat Wins Needed |
|-------|-------------------|-------------------|
| 1 | 0 | 0 |
| 2 | 100 | ~4 |
| 3 | 200 | ~7 |
| 4 | 300 | ~10 |
| 5 | 400 | ~14 |

*Combat wins needed assumes base 30 XP per win with no bonus XP from encounters.*

### What Player Level Gates

**Item Upgrades:** Each upgrade has a `level_requirement` field.

**File:** `data/items/item_upgrades.json`

```json
{
  "id": "itemup_vampiric_blade",
  "upgrades_item": "item_rusty_dagger",
  "level_requirement": 5
}
```

Upgrades only appear in reward pools when `player_level >= level_requirement`.

**Current Upgrade Level Requirements:**

| Upgrade | Base Item | Level Req |
|---------|-----------|-----------|
| itemup_iron_sword | item_battle_axe | 2 |
| itemup_arcane_staff | item_wooden_staff | 3 |
| itemup_shadow_cloak | item_cloak_of_shadows | 3 |
| itemup_flaming_sword | item_rusty_sword | 4 |
| itemup_plate_armor | item_chainmail | 4 |
| itemup_vampiric_blade | item_rusty_dagger | 5 |

---

## 4. Item Upgrade System (Run-Level)

### Concept

Items have a **replacement hierarchy**: base items can be upgraded to strictly superior versions during runs. Upgrades replace the base item 1-to-1.

### Data Structures

**Base Items:** `data/items/items.json`

```json
{
  "id": "item_rusty_sword",
  "name": "Rusty Sword",
  "description": "A weathered blade. Better than nothing.",
  "image_path": "res://assets/items/rusty_sword.png",
  "stat_modifiers": {},
  "slot": "weapon",
  "cost": 20
}
```

**Item Upgrades:** `data/items/item_upgrades.json`

```json
{
  "id": "itemup_flaming_sword",
  "name": "Flaming Sword",
  "description": "A blade wreathed in fire.",
  "image_path": "res://assets/items/flaming_sword.png",
  "upgrades_item": "item_rusty_sword",
  "stat_modifiers": {},
  "level_requirement": 4,
  "cost": 20,
  "element": "fire"
}
```

**Upgrade Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique identifier |
| `name` | String | Display name |
| `description` | String | Flavor text |
| `image_path` | String | Asset path |
| `upgrades_item` | String | ID of base item this replaces |
| `stat_modifiers` | Dictionary | Stat bonuses (e.g., `{"agility": 10}`) |
| `level_requirement` | int | Player level required to obtain |
| `cost` | int | Gold cost in shops |
| `element` | String | Element type for synergies |

### Key Functions

#### `PlayerInventory.replace_item_with_upgrade(base_item_id: String, upgrade_id: String) -> ItemInstance`
**File:** `scripts/managers/player_inventory.gd:113-144`

Replaces a base item with its upgrade. Returns the new upgrade instance or null if failed.

```gdscript
func replace_item_with_upgrade(base_item_id: String, upgrade_id: String) -> ItemInstance:
    # Verify player has base item
    if not has_item(base_item_id):
        return null

    # Remove base item
    remove_item(base_item_id)

    # Add upgrade
    var upgrade_item = ItemInstance.new(upgrade_id, true)  # true = is_upgrade
    add_item(upgrade_item)

    item_upgraded.emit(base_item_id, upgrade_item)
    return upgrade_item
```

**Behavior:**
1. Validates player owns the base item
2. Removes base item from inventory
3. Creates new `ItemInstance` with `is_upgrade = true`
4. Adds upgrade to inventory
5. Emits `item_upgraded` signal
6. Returns the upgrade instance (or null on failure)

### Upgrade Rules

1. **Prerequisite:** Must own the base item to receive its upgrade
2. **Replacement:** Upgrades replace base items 1-to-1 (not additive)
3. **Level Gating:** Upgrades only appear when player level meets `level_requirement`
4. **No Slot Limit:** Items accumulate in inventory (Slay the Spire style)
5. **Team-Wide:** Items apply to entire team, not individual characters

### Current Upgrade Chains

```
item_battle_axe      → itemup_iron_sword      (Level 2)
item_wooden_staff    → itemup_arcane_staff    (Level 3)
item_cloak_of_shadows → itemup_shadow_cloak   (Level 3)
item_rusty_sword     → itemup_flaming_sword   (Level 4)
item_chainmail       → itemup_plate_armor     (Level 4)
item_rusty_dagger    → itemup_vampiric_blade  (Level 5)
```

---

## 5. Complete Data Flow

### Account → Run Start

```
1. Player enters draft
   ↓
2. Selects 3 legacies
   ├─ Each legacy contributes:
   │  ├─ selected_starting_character_id → character pool
   │  ├─ income value → starting gold (summed)
   │  └─ unlocked_* arrays → merged content pools
   ↓
3. RunState initialized
   ├─ drafted_legacy_ids stored (for end-of-run fame)
   ├─ player_level = 1
   ├─ player_xp = 0
   └─ reputation = 10
```

### During Run

```
1. Encounter Phase
   ├─ Offer items/skills from merged legacy content pools
   ├─ Player level gates item upgrades
   └─ Complete 2 encounters per round
   ↓
2. Combat Phase
   ├─ Win: +20 gold, +30 XP (base values)
   │  └─ XP may trigger level-up
   └─ Loss: -reputation (equal to current round number)
   ↓
3. Repeat until:
   ├─ 7 wins (victory)
   └─ 0 reputation (defeat)
```

### Run End → Account

```
1. Calculate fame reward
   │  Victory: 75 + (wins × 5)
   │  Defeat:  25 + (wins × 5)
   ↓
2. Distribute fame equally to all 3 drafted legacies
   ↓
3. For each legacy:
   │  ├─ Add fame to PrestigeTracker
   │  └─ If fame ≥ 100:
   │     ├─ prestige++
   │     ├─ Apply prestige rewards
   │     └─ Unlock new content
   ↓
4. Calculate gem reward
   │  Victory: 100 + (wins × 5) + (reputation × 2)
   │  Defeat:  25 + (wins × 5)
   ↓
5. Save account state
   ↓
6. Display results screen
   └─ Show prestige-ups and unlocked content
```

---

## 6. Constants Reference

**File:** `scripts/constants/game_constants.gd`

### Progression Constants

```gdscript
# Account progression
const FAME_PER_PRESTIGE := 100

# Player level progression (per-run)
const XP_PER_LEVEL := 100
const MAX_PLAYER_LEVEL := 5

# Starting resources
const STARTING_GEMS := 1000
const STARTING_REROLL_TOKENS := 0
const STARTING_REPUTATION := 10
```

### Economy Constants

```gdscript
# Run rewards
const VICTORY_GEM_REWARD := 100
const DEFEAT_GEM_REWARD := 25

# Fame calculation
const FAME_REWARD_BASE_VICTORY := 75
const FAME_REWARD_BASE_DEFEAT := 25
const FAME_PER_WIN_BONUS := 5

# Gem bonuses
const GEMS_PER_WIN_BONUS := 5
const GEMS_PER_REPUTATION_BONUS := 2

# Combat rewards
const COMBAT_WIN_GOLD := 20
const COMBAT_WIN_XP := 30
```

### Run Constants

```gdscript
const WINS_FOR_VICTORY := 7
const ENCOUNTERS_PER_ROUND := 2
const LEGACY_UNLOCK_COST := 500
```

---

## 7. Signals Reference

### PrestigeTracker Signals

| Signal | Parameters | When Emitted |
|--------|------------|--------------|
| `fame_changed` | `new_fame: int` | After any fame change |
| `prestige_up` | `new_prestige: int` | Each prestige level gained |

### ProgressionManager Signals

| Signal | Parameters | When Emitted |
|--------|------------|--------------|
| `round_changed` | `new_round: int` | Round advances |
| `phase_changed` | `new_phase: String` | Phase changes (encounter/combat) |
| `player_level_changed` | `new_level: int` | Player levels up |

### PlayerInventory Signals

| Signal | Parameters | When Emitted |
|--------|------------|--------------|
| `item_upgraded` | `base_item_id: String, upgrade: ItemInstance` | Item replaced with upgrade |

---

## 8. Extending the Systems

### Adding New Prestige Rewards

1. Edit `data/legacies/legacies.json`
2. Add new entry to `prestige_rewards` array:

```json
{
  "prestige": 3,
  "unlocks": {
    "starting_items": ["item_legendary_sword"],
    "item_upgrades": ["itemup_legendary_upgrade"],
    "encounter_weight_bonus": 15
  }
}
```

### Adding New Item Upgrades

1. Add base item to `data/items/items.json` (if needed)
2. Add upgrade to `data/items/item_upgrades.json`:

```json
{
  "id": "itemup_new_upgrade",
  "name": "Upgraded Item",
  "upgrades_item": "item_base_item",
  "stat_modifiers": {"damage": 10},
  "level_requirement": 3,
  "cost": 25,
  "element": "fire"
}
```

3. Add upgrade ID to a legacy's `prestige_rewards.unlocks.item_upgrades` array

### Modifying Progression Curves

Edit constants in `scripts/constants/game_constants.gd`:

- **Faster prestige:** Decrease `FAME_PER_PRESTIGE`
- **More fame per run:** Increase `FAME_REWARD_BASE_*` or `FAME_PER_WIN_BONUS`
- **Faster leveling:** Decrease `XP_PER_LEVEL` or increase `COMBAT_WIN_XP`
- **Higher level cap:** Increase `MAX_PLAYER_LEVEL` (and add content for new levels)
