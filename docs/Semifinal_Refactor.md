# Semifinal Refactor Plan

Implementation guide for remaining SOLID/DRY improvements. All architectural decisions resolved.

**Decisions made:**
- Dependency injection: Leave as-is (Godot-idiomatic singletons, expand integration tests instead)
- Game flow: Extract `RunFlowController` autoload
- GameConstants: Keep as single file

---

## Phase 1: Dead Code & DRY Cleanup

Low-risk changes that reduce noise before structural work.

### 1.1 Remove Dead RewardCalculator Methods

**Files:** `scripts/managers/reward_calculator.gd`

Verify that `calculate_run_end_rewards` (line 36) and `apply_run_end_rewards` (line 124) have zero callers (RunManager uses `calculate_gem_reward` + `calculate_character_fame_reward` instead). Delete both methods.

### 1.2 Move RewardCalculator Magic Numbers to GameConstants

**Files:** `scripts/managers/reward_calculator.gd`, `scripts/constants/game_constants.gd`

Move these inline values to GameConstants:
- `base_fame = 25` / `75` → `FAME_REWARD_BASE_DEFEAT` / `FAME_REWARD_BASE_VICTORY`
- `wins * 5` → `FAME_PER_WIN_BONUS = 5`, `GEMS_PER_WIN_BONUS = 5`
- `reputation * 2` → `GEMS_PER_REPUTATION_BONUS = 2`

### 1.3 Consolidate Buy Handlers

**Files:** `scenes/ui/encounter_execute.gd`

Extract a shared helper from the near-identical `_on_buy_item` and `_on_buy_skill`:

```gdscript
func _handle_purchase(content_id: String, cost: int, char_selector: OptionButton, button: Button, action: Callable, success_text: String) -> void:
    var char_index = char_selector.selected - 1
    var result = RunManager.attempt_purchase(cost, char_index, func(ci): return action.call(ci, content_id))
    if result["success"]:
        button.disabled = true
        button.text = success_text
        _update_gold_label()
```

Then `_on_buy_item` becomes:
```gdscript
func _on_buy_item(item_id, cost, selector, button):
    _handle_purchase(item_id, cost, selector, button, CharacterInstance.equip_item_upgrade, "PURCHASED")
```

### 1.4 Audit and Remove Backwards-Compat Wrappers

**Files:** Multiple

Search for all callers of:
- `CombatGenerator.generate_options_as_dicts` — if all callers can use `generate_options`, delete it
- `CharacterCollection.to_array` — check if anything uses it beyond `to_dict` (which already handles this internally)

Migrate callers to typed APIs, then delete the wrappers.

---

## Phase 2: RunManager Decomposition

Extract game flow orchestration into a new `RunFlowController` autoload. RunManager becomes pure state management.

### 2.1 Create RunFlowController

**New file:** `autoloads/run_flow_controller.gd`

**Responsibilities:**
- Owns the encounter → combat → round → end-of-run flow
- Handles SceneManager transitions
- Applies end-of-run rewards (calls into RunManager and PlayerAccount)
- Emits the `combat_completed` signal

**Skeleton:**
```gdscript
extends Node
# RunFlowController - Orchestrates run flow and scene transitions
# RunManager handles state; this class handles "what happens next"

signal combat_completed(won: bool, is_run_over: bool)

func complete_combat(won: bool, combat_data: Dictionary) -> void:
    """Complete a combat and handle all post-combat logic."""
    if won:
        RunManager.apply_combat_rewards(true, combat_data)
        RunManager.add_win()
    else:
        RunManager.apply_combat_rewards(false, combat_data)
        RunManager.add_loss()

    RunManager.save_run_state()

    var run_over = RunManager.is_run_over()
    if run_over:
        var victory = RunManager.did_player_win()
        var reward_data = RunManager.end_run(victory)
        SceneManager.set_scene_data("run_results", reward_data)
    else:
        RunManager.advance_round()

    combat_completed.emit(won, run_over)
```

### 2.2 Register Autoload

**File:** `project.godot`

Add `RunFlowController` to the autoload list, ordered after `RunManager` and `SceneManager`.

### 2.3 Strip Orchestration from RunManager

**File:** `autoloads/run_manager.gd`

- Delete `complete_combat` method (lines 463-489)
- Remove the `combat_completed` signal (line 11)
- Remove `SceneManager` usage from `end_run` — it should only clear state and return reward data (which it mostly already does, but verify no SceneManager calls remain)
- Verify `end_run` still returns the reward Dictionary without triggering navigation

### 2.4 Update Scene Scripts

**File:** `scenes/ui/combat_stub.gd`

Change combat completion calls from `RunManager.complete_combat(won, combat_data)` to `RunFlowController.complete_combat(won, combat_data)`.

If the scene was connecting to `RunManager.combat_completed`, connect to `RunFlowController.combat_completed` instead.

---

## Phase 3: Verification

### 3.1 Confirm RunManager is Pure State

After Phase 2, `run_manager.gd` should have:
- No `SceneManager` references
- No scene navigation logic
- No `combat_completed` signal
- Only state mutation, getters, persistence, and delegation to TeamManager/CombatGenerator

### 3.2 Run Existing Tests

```
"C:\Program Files\Godot\Godot_v4.5.1-stable_win64.exe" --headless --script res://tests/test_character_card_hover.gd --path "C:\Users\glenn\Dev\auto-battle-journey\auto-battle-journey"
```

### 3.3 Validate Project Loads

```
"C:\Program Files\Godot\Godot_v4.5.1-stable_win64.exe" --headless --path "C:\Users\glenn\Dev\auto-battle-journey\auto-battle-journey" --quit
```

---

## Implementation Checklist

| # | Task | Scope |
|---|------|-------|
| 1 | Remove dead RewardCalculator methods (1.1) | 1 file, ~30 lines deleted |
| 2 | Move magic numbers to GameConstants (1.2) | 2 files, ~10 lines |
| 3 | Consolidate buy handlers (1.3) | 1 file, ~15 lines |
| 4 | Audit/remove wrappers (1.4) | 2-4 files |
| 5 | Create RunFlowController (2.1) | 1 new file, ~30 lines |
| 6 | Register autoload (2.2) | project.godot |
| 7 | Strip orchestration from RunManager (2.3) | 1 file, ~30 lines removed |
| 8 | Update scene callers (2.4) | 1-2 files |
| 9 | Verification (3.1-3.3) | Run tests + headless load |

---

## Out of Scope

- **Dependency injection** — Singleton coupling accepted as Godot-idiomatic
- **GameConstants splitting** — Single file with sections is navigable at this scale
- **Notify pattern deduplication** — 8 lines across 2 classes doesn't warrant abstraction
- **CombatGenerator extensibility** — Premature for a stubbed system
- **Reward type registry** — Over-engineering for 3 branches
- **RunManager interface narrowing** — 25 methods acceptable at this scale
- **UIHelpers deprecation** — Convenience facade has value
