# Combat System Implementation Plan

This document describes the phased implementation of the combat system defined in `combat_system_design.md`.

---

## Phase 1: Data Foundation

**Goal:** Update the stat system and character data so combat stats exist and legacy stats are cleaned out.

### 1.1 Update stat_definitions.json

- Remove: `income`, `itemSlots`, `startingItemSlots`
- Rename: `defendRate` → `agility`
- Add: `speed`, `damage`, `crit_chance`

Final stat_definitions.json:
```json
[
  {"id": "health", "display_name": "HP", "default": 100, "description": "Character's maximum health points"},
  {"id": "charges", "display_name": "MP", "default": 5, "description": "Character's maximum charges points"},
  {"id": "agility", "display_name": "DEF", "default": 0, "description": "Percentage chance to block incoming damage (0.0-1.0)"},
  {"id": "speed", "display_name": "SPD", "default": null, "description": "Seconds between cooldown triggers (null = passive)"},
  {"id": "damage", "display_name": "DMG", "default": null, "description": "Base damage dealt on cooldown (null = no damage)"},
  {"id": "crit_chance", "display_name": "CRIT", "default": 0, "description": "Percentage chance to deal critical damage (0.0-1.0)"}
]
```

### 1.2 Update GameConstants stat constants

- Remove: `STAT_INCOME`, `STAT_ITEM_SLOTS`, `STAT_STARTING_ITEM_SLOTS` and all their references in `ALL_STATS`, `STAT_DISPLAY_NAMES`, `get_default_stats()`
- Rename: `STAT_agility` value from `"defendRate"` to `"agility"`
- Add: `STAT_SPEED := "speed"`, `STAT_DAMAGE := "damage"`, `STAT_CRIT_CHANCE := "crit_chance"`
- Update `ALL_STATS`, `STAT_DISPLAY_NAMES`, and `get_default_stats()` accordingly

### 1.3 Update characters.json

- Rename `defendRate` → `agility` in all character `base_stats`
- Add `speed` and `damage` values to all characters (design each character for combat identity)

Proposed character stat designs:

| Character | HP | Charges | DEF | SPD | DMG | CRIT | Identity |
|---|---|---|---|---|---|---|---|
| Brave Knight | 100 | 5 | 0.15 | 3.0 | 15 | 0.0 | Tanky, steady damage |
| Mystic Sage | 70 | 5 | 0.05 | 4.0 | 25 | 0.05 | Glass cannon, slow |
| Shadow Thief | 80 | 5 | 0.10 | 2.0 | 12 | 0.15 | Fast, high crit |
| Holy Priest | 90 | 5 | 0.10 | 3.5 | 8 | 0.0 | Support (low damage for now, will get healing effects later) |
| Forest Scout | 85 | 5 | 0.08 | 2.5 | 14 | 0.10 | Fast ranged |
| Raging Berserker | 110 | 5 | 0.05 | 2.0 | 20 | 0.10 | Fast, high damage, low defense |
| Divine Paladin | 105 | 5 | 0.20 | 3.5 | 12 | 0.0 | Very tanky, moderate damage |
| Dark Necromancer | 75 | 5 | 0.05 | 4.5 | 22 | 0.05 | Slowest, high damage |
| Zen Monk | 85 | 5 | 0.15 | 2.5 | 11 | 0.05 | Balanced, fast, defensive |
| Silent Assassin | 65 | 5 | 0.12 | 1.5 | 18 | 0.25 | Fastest, highest crit, fragile |
| Forest Warden | 95 | 5 | 0.12 | 3.0 | 10 | 0.0 | Tanky support |
| Beast Master | 80 | 5 | 0.08 | 2.5 | 16 | 0.05 | Balanced damage |
| War Chief | 105 | 5 | 0.10 | 3.0 | 14 | 0.05 | Tanky, steady |
| Shield Bearer | 120 | 5 | 0.25 | 4.0 | 6 | 0.0 | Maximum tank, minimal damage |
| Hired Soldier | 85 | 5 | 0.10 | 3.0 | 12 | 0.0 | Generic balanced |
| Hired Archer | 70 | 5 | 0.05 | 2.5 | 14 | 0.05 | Generic ranged |
| Hedge Wizard | 60 | 5 | 0.05 | 4.0 | 18 | 0.0 | Generic glass cannon |
| Traveling Medic | 75 | 5 | 0.08 | 3.5 | 6 | 0.0 | Generic support |
| Town Guard | 95 | 5 | 0.15 | 3.5 | 8 | 0.0 | Generic tank |
| Freelance Scout | 65 | 5 | 0.12 | 2.0 | 10 | 0.10 | Generic fast |

**Design notes:**
- Speed ranges from 1.5s (Assassin, fastest) to 4.5s (Necromancer, slowest)
- DPS = damage / speed. A ~30s combat means characters trigger roughly 7-20 times
- High-crit characters have lower base damage to compensate
- High-defense characters have lower damage/speed
- Support characters (Priest, Medic) have low damage now; will gain healing/buff effects later
- `agility` is now a float (0.0-1.0) instead of an integer percentage

### 1.4 Update StatCalculator

- Update `_get_base_stats()` to extract all combat stats: `health`, `charges`, `agility`, `speed`, `damage`, `crit_chance`
- Handle null defaults for `speed` and `damage` (character may not define them)
- Update `stats_to_string()` to include new stats

### 1.5 Update CharacterInstance

- Rename `agility` accessor to use new constant value `"agility"`
- Add accessors for `speed`, `damage`, `crit_chance`
- Handle null/absent stats gracefully (return null for speed/damage if not defined)

### 1.6 Update RunState / RunManager

- Remove `calculate_total_income()` from RunState (income is on legacies, not characters)
- Remove any character-stat-based income references in RunManager
- Verify starting gold calculation uses `legacy.income` only (already does in `start_new_run_with_legacies`)

### 1.7 Clean up remaining references

- Remove `STAT_INCOME`, `STAT_ITEM_SLOTS`, `STAT_STARTING_ITEM_SLOTS` from any code that references them
- Update any UI code displaying character stats to show new combat stats
- Run project validation to confirm no broken references

**Verification:** Project loads headless without errors. All existing tests pass.

---

## Phase 2: Core Combat Data Classes

**Goal:** Create the data classes needed for combat: `CombatCharacter`, `CombatEffect`, `CombatBoard`, `CombatState`.

### 2.1 Create CombatCharacter (scripts/combat/combat_character.gd)

```
class_name CombatCharacter
extends RefCounted
```

Properties:
- `id: String` (generated unique ID)
- `source_character_id: String`
- `health: float`, `max_health: float`
- `base_speed: float` (original speed, before modifiers)
- `base_damage: float` (original damage, before modifiers)
- `base_crit_chance: float`, `base_agility: float`
- `speed: float` (effective, recalculated from base + effects)
- `damage: float` (effective, recalculated from base + effects)
- `crit_chance: float`, `agility: float` (effective)
- `team: int`, `row: int`, `column: int`
- `is_alive: bool`, `cooldown_remaining: float`
- `effects: Array[CombatEffect]`

Methods:
- `static create_from_character(source: CharacterInstance, team: int, row: int, col: int) -> CombatCharacter`
- `recalculate_stats()` — recalculates effective stats from base + stat_modifier effects (using base-additive stacking)
- `has_speed() -> bool`, `has_damage() -> bool`
- `get_board_index() -> int` — returns `row * 3 + column`

### 2.2 Create CombatEffect (scripts/combat/combat_effect.gd)

```
class_name CombatEffect
extends RefCounted
```

Properties matching the design document Effect structure. Use a static counter for generating unique IDs.

Factory methods:
- `static create_stat_modifier(source_type, source_id, stat, value, modifier_type, duration_type, duration_value) -> CombatEffect`
- `static create_triggered(source_type, source_id, trigger, action, duration_type, duration_value) -> CombatEffect`

### 2.3 Create CombatBoard (scripts/combat/combat_board.gd)

```
class_name CombatBoard
extends RefCounted
```

Properties:
- `player_characters: Array` (size 6, nullable elements)
- `opponent_characters: Array` (size 6, nullable elements)

Methods:
- `get_character_at(team: int, row: int, column: int) -> CombatCharacter`
- `get_all_living_characters() -> Array[CombatCharacter]`
- `get_living_characters_on_team(team: int) -> Array[CombatCharacter]`
- `get_living_characters(team: int, row: int) -> Array[CombatCharacter]`
- `has_living_characters(team: int) -> bool`

### 2.4 Create CombatState (scripts/combat/combat_state.gd)

```
class_name CombatState
extends RefCounted
```

Properties:
- `board: CombatBoard`
- `elapsed_time: float`
- `combat_active: bool`
- `winner` (null, 0, 1, or 2)

**Verification:** Classes instantiate correctly. Unit tests for CombatCharacter creation from CharacterInstance and stat recalculation.

---

## Phase 3: Targeting System

**Goal:** Implement the targeting algorithms as a static utility.

### 3.1 Create CombatTargeting (scripts/combat/combat_targeting.gd)

```
class_name CombatTargeting
extends RefCounted
```

Static methods:
- `get_valid_enemy_targets(actor: CombatCharacter, board: CombatBoard) -> Array[CombatCharacter]`
- `get_valid_ally_targets(actor: CombatCharacter, board: CombatBoard, include_self: bool = false) -> Array[CombatCharacter]`
- `select_enemy_target(actor: CombatCharacter, board: CombatBoard) -> CombatCharacter` (or null)
- `select_ally_target(actor: CombatCharacter, board: CombatBoard, include_self: bool = false) -> CombatCharacter` (or null)
- `get_column_distance(col_a: int, col_b: int) -> int`

### 3.2 Unit tests

Test all targeting examples from the design document:
- Front row priority
- Nearest column selection
- Random tiebreaker (verify pool is correct, not the random selection itself)
- Back row fallback
- Ally targeting with self-exclusion

**Verification:** All targeting tests pass, covering every example in the design document.

---

## Phase 4: Combat Manager — Core Loop

**Goal:** Implement the CombatManager that runs the real-time combat loop.

### 4.1 Create CombatManager (scripts/combat/combat_manager.gd)

```
class_name CombatManager
extends Node
```

Signals:
- `combat_started(state: CombatState)`
- `combat_ended(winner: int, reason: String)`
- `character_cooldown_triggered(character: CombatCharacter)`
- `damage_dealt(source: CombatCharacter, target: CombatCharacter, amount: float, is_crit: bool)`
- `damage_blocked(source: CombatCharacter, target: CombatCharacter)`
- `damage_taken(target: CombatCharacter, amount: float, source: CombatCharacter)`
- `character_died(character: CombatCharacter)`
- `effect_applied(target: CombatCharacter, effect: CombatEffect)`
- `effect_removed(target: CombatCharacter, effect: CombatEffect)`
- `character_healed(target: CombatCharacter, amount: float, source: CombatCharacter)`

Core methods:
- `initialize_combat(player_grid: CharacterGrid, opponent_grid: CharacterGrid) -> void`
- `_process(delta)` — drives `_update_combat(delta)`
- `_update_combat(delta)` — update cooldowns, process actions, update effects, check win
- `_update_character(character: CombatCharacter, delta: float)`
- `_execute_character_action(character: CombatCharacter)`
- `_execute_damage(source: CombatCharacter, target: CombatCharacter, base_damage: float)`
- `_apply_damage(target: CombatCharacter, amount: float, source: CombatCharacter)`
- `_kill_character(character: CombatCharacter)`
- `_check_win_condition()`
- `_is_stalemate() -> bool`

Constants:
- `CRIT_MULTIPLIER = 2.0`

### 4.2 Effect processing methods on CombatManager

- `_update_effects(delta: float)` — tick seconds-based durations
- `_decrement_cooldown_effects(character: CombatCharacter)` — called after cooldown triggers
- `_apply_effect(target: CombatCharacter, effect: CombatEffect)`
- `_remove_effect(target: CombatCharacter, effect: CombatEffect)`
- `_remove_effects_from_source(source_id: String)`
- `_process_triggered_effects(character: CombatCharacter, trigger: String, data: Dictionary)`
- `_apply_max_health_change(character: CombatCharacter, amount: float, is_buff: bool)`

### 4.3 Unit tests

- Test combat initialization from two CharacterGrids
- Test cooldown processing (character acts after speed seconds)
- Test damage dealing (with and without crit/block)
- Test character death and cleanup
- Test win conditions: player win, opponent win, draw (mutual kill), draw (stalemate)
- Test effect application, duration tracking, and removal

**Verification:** CombatManager can run a full automated combat between two grids and produce a winner. Unit tests cover all core mechanics.

---

## Phase 5: Run Integration

**Goal:** Wire the combat system into the existing run flow, replacing the combat stub.

### 5.1 Update RunFlowController

- Update `complete_combat()` to accept `winner: int` (0, 1, or 2) instead of `won: bool`
- Handle draw outcome (winner == 2): no win, no loss, no reputation change
- Keep existing reward and progression logic for wins/losses

### 5.2 Update combat scene entry

- `combat_select.gd` currently transitions to `combat_stub`
- Create new combat scene (`combat_scene.tscn` / `combat_scene.gd`) that:
  - Receives combat data from SceneTransitionData
  - Creates opponent CharacterGrid from combat option data
  - Instantiates CombatManager as a child node
  - Calls `initialize_combat()` with player and opponent grids
  - Connects to CombatManager signals for UI updates
  - On `combat_ended`, calls `RunFlowController.complete_combat()`
- Update `combat_select.gd` to transition to the new `combat_scene` instead of `combat_stub`

### 5.3 Generate opponent teams

- Update `CombatGenerator` and `CombatOption` to include opponent team data:
  - AI opponents: Generate a CharacterGrid from random characters with difficulty-based stat scaling
  - Ghost opponents: Store a serialized CharacterGrid snapshot
- Add `opponent_team: Array` field to CombatOption (array of character IDs + grid positions)
- Create `OpponentBuilder` utility to construct a CharacterGrid from combat option data

### 5.4 Update SceneTransitionData

- Ensure combat data passed between scenes includes opponent team information

**Verification:** Full run loop works: encounter → combat select → real combat → results → next round. Combat stub is no longer used.

---

## Phase 6: Combat Visualization

**Goal:** Build the visual layer that displays combat state to the player.

### 6.1 Create CombatVisualizer (scripts/combat/combat_visualizer.gd)

A Control node that renders the combat state:
- **Board layout:** Two 2×3 grids (opponent top, player bottom) matching the design document visual
- **Character cards:** Show character name, health bar, cooldown bar
- **Damage numbers:** Floating numbers on hit (using existing FloatingNumberEffect or similar)
- **Death animation:** Fade out / shatter on character death
- **Crit/block indicators:** Visual feedback for crits and blocks

### 6.2 Character combat card

Minimal card for combat display:
- Character name/icon
- Health bar (current/max)
- Cooldown progress bar (fills up, triggers on full)
- Status effect icons (future)

### 6.3 Combat HUD

- Elapsed time display
- Team health summary bars
- Speed control (1x, 2x, skip) — optional for initial release

### 6.4 Victory/Defeat overlay

- Display winner announcement
- Show combat summary (damage dealt, characters surviving)
- "Continue" button to proceed to RunFlowController

**Verification:** Combat is visually watchable. Player can see characters acting on cooldowns, taking damage, dying, and the outcome.

---

## Phase 7: Polish & Balance

**Goal:** Tune the combat experience and handle edge cases.

### 7.1 Balance pass

- Tune character stats so combats last ~30 seconds on average
- Adjust speed/damage/health ratios across all characters
- Ensure generic characters are weaker than named characters
- Verify diverse team compositions feel different

### 7.2 Edge cases

- Empty grid slots (teams with < 6 characters)
- Teams with only passive characters (no speed/damage) — should stalemate quickly
- Very fast characters (ensure no infinite loops if speed approaches 0)
- Effect cleanup on combat end (no leaked references)

### 7.3 Combat log

- Add optional debug log that records every combat event with timestamps
- Useful for balance tuning and bug investigation

**Verification:** Combats feel good at ~30s. No crashes or hangs on edge cases.

---

## File Structure

All new combat files will live under `scripts/combat/`:

```
scripts/combat/
├── combat_character.gd      # Phase 2
├── combat_effect.gd         # Phase 2
├── combat_board.gd          # Phase 2
├── combat_state.gd          # Phase 2
├── combat_targeting.gd      # Phase 3
├── combat_manager.gd        # Phase 4
├── combat_visualizer.gd     # Phase 6
└── opponent_builder.gd      # Phase 5

scenes/ui/
├── combat_scene.tscn        # Phase 5 (replaces combat_stub.tscn)
└── combat_scene.gd          # Phase 5 (replaces combat_stub.gd)
```

---

## Dependencies Between Phases

```
Phase 1 (Data Foundation)
    ↓
Phase 2 (Data Classes)
    ↓
Phase 3 (Targeting)    Phase 4 (Combat Manager)
    ↓                       ↓
    └──────→ Phase 4 uses Phase 3
                ↓
           Phase 5 (Run Integration)
                ↓
           Phase 6 (Visualization)
                ↓
           Phase 7 (Polish)
```

Phases 3 and 4 can be developed in parallel (targeting is a dependency of the manager but can be stubbed). All other phases are sequential.

---

## What Is NOT In Scope

These are documented as expansion points in the design but are not part of this plan:

- Character innate abilities (custom per-character triggered effects)
- Item combat effects (items applying effects to characters at combat start)
- Skill combat effects (skills granting combat-only buffs)
- Type interactions and synergies
- Complex status effects (poison, stun, shield)
- Asynchronous PvP ghost recording/playback

These will be added in future phases once the core combat loop is stable and balanced.
