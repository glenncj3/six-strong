# Refactor Plan: SOLID/DRY & UI/UX Efficiency

## Phase 1: Dead Code Removal & Cleanup
*Low risk, immediate clarity gains. No behavioral changes.*

### 1.1 Remove Unused Constants from `GameConstants`
Remove the following dead constants that are never referenced outside their definition:
- `SCREEN_MARGIN`, `SCREEN_MARGIN_SMALL`
- `CHARACTER_CARD_WIDTH`, `CHARACTER_CARD_HEIGHT`, `CHARACTER_CARD_SMALL_WIDTH`, `CHARACTER_CARD_SMALL_HEIGHT`
- `ITEM_SLOT_WIDTH`, `ITEM_SLOT_HEIGHT`, `ITEM_ICON_SIZE`
- `SKILL_ICON_WIDTH`, `SKILL_ICON_HEIGHT`, `SKILL_ICON_IMAGE_SIZE`
- `ENCOUNTER_IMAGE_SIZE`
- `COLOR_GHOST_PRESTIGE`
- `PARTICLE_RATE_SUBTLE`, `PARTICLE_RATE_NORMAL`, `PARTICLE_RATE_INTENSE`
- `CARD_TILT_DEGREES`
- `GLOW_COLOR_RARE`, `GLOW_COLOR_UNCOMMON`, `GLOW_COLOR_COMMON`

### 1.2 Remove Duplicate Color Definitions
Replace duplicate color constants with aliases:
```gdscript
# Before (7 pairs of duplicates):
const COLOR_EMERALD := Color("#2A7A4A")
const COLOR_SUCCESS := Color("#2A7A4A")  # separate Color object

# After:
const COLOR_EMERALD := Color("#2A7A4A")
const COLOR_SUCCESS := COLOR_EMERALD  # alias, same object
const COLOR_DIFFICULTY_EASY := COLOR_EMERALD

const COLOR_RUBY := Color("#8A2A3A")
const COLOR_ERROR := COLOR_RUBY
const COLOR_DANGER := COLOR_RUBY

const COLOR_AMETHYST := Color("#6A3A8A")

const COLOR_GOLD := Color("#D9A621")
const COLOR_WARNING := COLOR_GOLD

const COLOR_TEXT_GOLD := Color("#FFD54F")
const COLOR_HIGHLIGHT := COLOR_TEXT_GOLD

const COLOR_TEXT_MUTED := Color("#B8A88A")
const COLOR_MUTED := COLOR_TEXT_MUTED
```

### 1.3 Remove Dead Functions
- `ui_styles.gd` — `create_transparent_panel()` (never called)
- `ui_panel_factory.gd` — `_add_encounter_labels()` and `_get_encounter_reward_preview()` (unreachable)
- `ui_panel_factory.gd` — `create_option_panel_base()` and `add_option_panel_labels()` (verify no callers, then remove)

### 1.4 Fix `UIScaler.get_skill_image_size()` No-Op Branch
```gdscript
# Before:
static func get_skill_image_size(compact: bool = false) -> float:
    if compact:
        return vw(5.5)  # same value!
    return vw(5.5)

# After — either give compact a real value or remove the parameter:
static func get_skill_image_size() -> float:
    return vw(5.5)
```

### 1.5 Remove Duplicate `DESIGN_WIDTH` / `DESIGN_HEIGHT` in `UIScaler`
Have `UIScaler` reference `GameConstants.DESIGN_WIDTH` and `GameConstants.DESIGN_HEIGHT` (cast to float) instead of declaring its own copies.

### 1.6 Remove Debug `print()` Statements
Remove or gate behind a debug flag all raw `print()` calls across:
- `draft.gd` (7 calls)
- `run_view.gd` (4 calls)
- `main_menu.gd` (5 calls)
- `encounter_execute.gd` (12 calls)
- `run_results.gd` (1 call)
- `collection.gd` (1 call)

**Decision — How to handle debug logging:**

- [X] **Option A: Remove all prints** — Delete them entirely. They're development artifacts and the game is past that stage.
- [ ] **Option B: Debug flag** — Add a `const DEBUG := false` to `GameConstants` and wrap prints in `if GameConstants.DEBUG:`. Keeps them available for future debugging.
- [ ] **Option C: Logger utility** — Create a small `Logger` autoload with `Logger.debug()`, `Logger.warn()`, `Logger.error()` that can be globally toggled. More structured but adds a file.

---

## Phase 2: DRY Utilities & Helper Extraction
*Create shared helpers that later phases will depend on.*

### 2.1 Add `UIStyles.style_label()` Helper
Eliminates the most widespread DRY violation (dozens of repeated two-line blocks):
```gdscript
# In ui_styles.gd:
static func style_label(label: Label, font_size: int, color: Color = GameConstants.COLOR_TEXT_LIGHT) -> void:
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
```
Then replace all occurrences in `combat_stub.gd`, `run_results.gd`, `draft.gd`, `encounter_execute.gd`, `character_details.gd`, and other files.

### 2.2 Add `UIStyles.apply_text_shadow()` Helper
```gdscript
static func apply_text_shadow(label: Label, shadow_color: Color = Color(0, 0, 0, 0.7), offset: Vector2 = Vector2(1, 2)) -> void:
    label.add_theme_color_override("font_shadow_color", shadow_color)
    label.add_theme_constant_override("shadow_offset_x", int(offset.x))
    label.add_theme_constant_override("shadow_offset_y", int(offset.y))
```
Replace the 3 duplicated instances in `ui_panel_factory.gd`.

### 2.3 Add `UIStyles.set_margin_all()` Helper
```gdscript
static func set_margin_all(container: MarginContainer, margin: int) -> void:
    container.add_theme_constant_override("margin_left", margin)
    container.add_theme_constant_override("margin_right", margin)
    container.add_theme_constant_override("margin_top", margin)
    container.add_theme_constant_override("margin_bottom", margin)
```
Replace the 5+ instances across `ui_panel_factory.gd`, `character_card.gd`, `compactable_icon_base.gd`.

### 2.4 Use Godot Built-in `set_corner_radius_all()` / `set_border_width_all()`
Replace manual 4-line corner/border setting in:
- `ui_styles.gd` — `create_panel_style()`, `create_transparent_panel()`, `create_progress_bar_fill()`
- `run_hud.gd` — `_style_concede_button()`

### 2.5 Add Tile Size Calculator Utility
```gdscript
# In UIScaler or UIHelpers:
static func calculate_tile_size(container_width: float, columns: int, margin: float = 24.0, spacing: float = 16.0, min_size: float = 180.0, fallback_width: float = 688.0) -> float:
    var available_width = max(container_width, fallback_width) - margin
    var tile_size = floor((available_width - spacing) / float(columns))
    return max(tile_size, min_size)
```
Replace duplicated formulas in `draft.gd:258-261`, `collection.gd:83-85`, `select_screen_base.gd:62-64`.

### 2.6 Replace Magic Numbers in `ui_panel_factory.gd`
Replace hardcoded values with existing constants:
| Line | Current | Replacement |
|------|---------|-------------|
| 278 | `"font_size", 32` | `GameConstants.FONT_SIZE_REWARD` |
| 285, 312, 336 | `"font_size", 24` | `GameConstants.FONT_SIZE_HEADING` |
| 76, 172 | `"font_size", 20` | New constant: `GameConstants.FONT_SIZE_LABEL` or use closest existing |
| 227 | `"separation", 12` | `GameConstants.SHOP_ROW_SEPARATION` |

Add new constants for remaining magic numbers:
```gdscript
const BUY_BUTTON_SIZE := Vector2(80, 40)
const SHADOW_OFFSET := Vector2(1, 2)
const SPACER_HEIGHT_SMALL := 5
```

### 2.7 Fix Inconsistent Color Application
Standardize on `add_theme_color_override("font_color", color)` for Label text coloring instead of `label.modulate = color`. Update `UIContainerHelpers.create_label()` (line 91) and any callers using `modulate`.

### 2.8 Consolidate `EncounterFactory._gen_pick_items` / `_gen_pick_skills`
```gdscript
func _gen_pick_from_pool(params: Dictionary, pool: Array, min_cost: int, max_cost: int) -> Array:
    var count = randi_range(
        int(_resolve_value(params.get("count_min", 1))),
        int(_resolve_value(params.get("count_max", 3)))
    )
    pool.shuffle()
    var result = []
    for i in range(mini(count, pool.size())):
        result.append({"id": pool[i]["id"], "cost": randi_range(min_cost, max_cost)})
    return result
```

### 2.9 Consolidate `TransitionManager` Duplications
- Merge `_set_dissolve_progress` / `_set_wipe_progress` into a single `_set_shader_progress()`
- Cache wipe shader like dissolve shader is cached
- Extract a `_create_standard_tween()` helper for the repeated 4-line tween setup

### 2.10 Remove Duplicate `OptionPanelType` Enum in `UIHelpers`
Have `UIHelpers.create_option_panel()` accept `UIPanelFactory.OptionPanelType` directly instead of re-declaring and mapping its own enum.

---

## Phase 3: SRP Fixes — Move Logic to Proper Locations
*Correct responsibility violations. Business logic out of UI, UI concerns out of managers.*

### 3.1 Extract Reward Application from `run_results.gd`

**Decision — Where should reward application live?**

- [X] **Option A: In `RunManager.end_run()`** — RunManager already handles run lifecycle. Add a `_apply_end_of_run_rewards()` method that calculates and applies gems/fame, then passes the results as data to the scene. Keeps reward timing tied to run lifecycle.
- [ ] **Option B: New `RunRewardService` class** — A standalone static utility called by `RunManager.end_run()`. Cleaner separation, but adds a file for a small amount of logic.

Either way, `_display_rewards()` becomes purely a render function receiving pre-calculated data.

### 3.2 Extract Game State Mutations from `EncounterUIFactory`
Move all state-mutating calls out of the UI factory:
- `RunManager.add_gold()` — move to encounter handler callbacks
- `char_instance.heal()` — move to encounter handler callbacks
- `char_instance.learn_skill()` — move to encounter handler callbacks
- `RunManager.spend_gold()` / `RunManager.add_gold()` (gamble) — move to encounter handler

The UI factory should only return UI nodes. State mutations should happen via callbacks passed into the factory, or the factory should emit signals that handlers respond to.

**Decision — Callback approach:**

- [ ] **Option A: Callable parameters** — Pass `on_purchase: Callable`, `on_reward: Callable` into factory methods. The handler provides the implementation. Minimal new architecture.
- [X] **Option B: Signal-based** — Factory emits signals like `item_purchased(item_id, cost)`, `gold_rewarded(amount)`. Handlers connect and respond. More decoupled but more indirection.

### 3.3 Extract Purchase Logic from `encounter_execute.gd`
Create a shared purchase helper (in `RunManager` or a utility):
```gdscript
static func attempt_purchase(cost: int, team: Array, char_index: int, action: Callable) -> Dictionary:
    # Returns {success: bool, error: String}
    if char_index < 0:
        return {success = false, error = "no_character_selected"}
    if not RunManager.spend_gold(cost):
        return {success = false, error = "insufficient_gold"}
    var char_instance = team[char_index]
    if not action.call(char_instance):
        RunManager.add_gold(cost)  # refund
        return {success = false, error = "action_failed"}
    return {success = true, error = ""}
```

### 3.4 Remove Scene Navigation from `RunManager.complete_combat()`
Replace direct `SceneManager.go_to()` calls with a signal:
```gdscript
signal combat_completed(won: bool, run_ended: bool)

func complete_combat(won: bool, combat_data: Dictionary) -> void:
    apply_combat_rewards(won, combat_data)
    if won: add_win() else: add_loss()
    var run_ended = (reputation <= 0 or wins >= GameConstants.WINS_TO_VICTORY)
    combat_completed.emit(won, run_ended)
```
The scene (or main.gd) connects to this signal and handles navigation.

### 3.5 Move UI Colors out of `CombatGenerator`
Replace inline color literals with `GameConstants` references:
```gdscript
# Before:
Color("#2A7A4A")  # hardcoded

# After:
GameConstants.COLOR_EMERALD
```
Move the difficulty-to-color mapping to `GameConstants`:
```gdscript
const DIFFICULTY_COLORS := {
    "Easy": {bg = COLOR_EMERALD, hover = COLOR_EMERALD.lightened(0.15), ...},
    "Medium": {bg = COLOR_GOLD_DARK, ...},
    "Hard": {bg = COLOR_RUBY, ...}
}
```

### 3.6 Move Scene Navigation out of `RunHud._on_concede_confirmed()`
The HUD should emit a signal; the scene or RunManager handles the transition:
```gdscript
signal concede_requested()

func _on_concede_confirmed() -> void:
    concede_requested.emit()
```

### 3.7 Move `_capture_team_data()` from `RunHud` to `RunManager`
Rename to `RunManager.get_team_summary() -> Array` since it's data extraction from run state.

---

## Phase 4: Consolidation — Shared Base Classes & Component Reuse
*Reduce structural duplication with proper inheritance and composition.*

### 4.1 Use `CurrencyDisplay` Component Everywhere
Replace the duplicated currency setup in `main_menu.gd`, `collection.gd`, and `run_results.gd` with the existing `CurrencyDisplay` component (either as a scene instance or programmatically added).

### 4.2 Extract `PersistentHudBase` Class

**Decision — Implementation approach:**

- [ ] **Option A: Base class** — Create `PersistentHudBase` extending `Control` with shared `_fade_in()`, `_fade_out()`, `_kill_tween()`, `_on_scene_loaded()` template. `TeamHud` and `RunHud` extend it. Clean inheritance but couples them to one hierarchy.
- [X] **Option B: Composition via helper** — Create a `HudVisibilityHelper` class that both HUDs instantiate. Contains fade logic and scene-matching. More flexible, works with any node type.

Either way, `GAMEPLAY_SCENES` moves to `GameConstants`.

### 4.3 Move `highlight()` into `ClickablePanelBase`
```gdscript
# In clickable_panel_base.gd:
const HIGHLIGHT_MODULATE := Color(1.2, 1.2, 1.2)

func highlight(enabled: bool) -> void:
    modulate = HIGHLIGHT_MODULATE if enabled else Color.WHITE
```
Remove from `character_card.gd` and `character_tile.gd`. Update `item_slot.gd` to use the same approach (it currently uses `GameConstants.COLOR_HIGHLIGHT` which is a different color — this is likely a bug).

**Decision — Highlight color for `item_slot.gd`:**

- [X] **Option A: Use brightened modulate (`Color(1.2, 1.2, 1.2)`)** — Consistent with cards/tiles. Makes the slot slightly brighter. This is a "selection glow" effect.
- [ ] **Option B: Keep item_slot using `COLOR_HIGHLIGHT` (`#FFD54F` gold tint)** — Different visual intent (gold tint vs brightness). If items should feel distinct from characters, keep it separate but rename for clarity.

### 4.4 Move `_init_styles()` Default into `ClickablePanelBase`
Since both `character_card.gd` and `character_tile.gd` use the identical style setup, make it the default in the base class (subclasses can override if needed).

### 4.5 Consolidate `character_tile.gd` Dual Setup Methods
Unify `setup()` and `setup_from_data()`:
```gdscript
func setup(character_instance: CharacterInstance, tile_size: float) -> void:
    _apply_sizing(tile_size)
    _apply_character_data(character_instance.base_character_id, character_instance.get_character_name())
    char_instance = character_instance

func setup_from_data(character_data: Dictionary, tile_size: float) -> void:
    _apply_sizing(tile_size)
    _apply_character_data(character_data.get("id", ""), character_data.get("name", ""))
    char_data = character_data
```
Extract shared sizing and display into private helpers.

### 4.6 Consolidate `character_info_panel.gd` Grid Population
Replace `_populate_items_grid()` and `_populate_skills_grid()` with:
```gdscript
func _populate_icon_grid(grid: GridContainer, icon_paths: Array[String], max_slots: int) -> void:
    UIHelpers.clear_children(grid)
    for i in range(max_slots):
        var slot = _create_icon_slot()
        if i < icon_paths.size() and icon_paths[i] != "":
            UIHelpers.set_texture_safe(slot.get_child(0), icon_paths[i])
        grid.add_child(slot)
```

### 4.7 Consolidate `character_card.gd` Size Application
Extract the repeated margin-setting into the helper from 2.3, and remove the redundant `name_label` font size override (set to 20 in all three size methods — if it's always 20, set it once).

### 4.8 Eliminate Button-Disable Duplication in `EncounterUIFactory`
```gdscript
static func _disable_all_buttons(container: Control) -> void:
    for child in container.get_children():
        if child is Button:
            child.disabled = true
        elif child is Container:
            _disable_all_buttons(child)  # recursive
```

### 4.9 Fix `run_results.gd` Fragile Parent Chain
Replace `rounds_label.get_parent().get_parent().get_parent()` with proper `@onready` references to the panel nodes.

### 4.10 Fix `draft.gd` Scene Tree Path Coupling
Replace `get_tree().root.get_node_or_null("Main/HUDLayer/TeamHUD")` with signals:
```gdscript
# In draft.gd:
signal character_drafted(char_instance: CharacterInstance)
signal draft_gold_updated(gold: int)

# Connected by main.gd or the HUD listens to RunManager signals
```

---

## Phase 5: Architectural Cleanup
*Lower priority structural improvements.*

### 5.1 Address `GameData` Repeated Accessor Pattern

**Decision — How to handle the 4x get/has/get_all pattern:**

- [X] **Option A: Generic accessor** — Add a `_get_from_collection(collection_name, id)` method and a registry of collections. Reduces boilerplate but adds indirection.
- [ ] **Option B: Keep as-is** — The explicit methods provide clear autocomplete and type hints. The repetition is annoying but not harmful. Only 4 data types exist.

### 5.2 Address `RunManager` Save Pattern

**Decision — How to handle repeated `save_run_state()` calls:**

- [ ] **Option A: Dirty flag + deferred save** — Set `_dirty = true` in mutators, save on `_process()` or `_notification(NOTIFICATION_WM_CLOSE_REQUEST)`. Batches saves, reduces I/O.
- [X] **Option B: Property setters** — Use `set(value)` functions that auto-save. Same frequency as current but centralizes the call.
- [ ] **Option C: Keep as-is** — Explicit saves are predictable and debuggable. The repetition is minor since each mutator is small.

### 5.3 Address Facade Classes (`UIHelpers`, `EncounterHandlers`)

**Decision — What to do with pure-delegation facades:**

- [ ] **Option A: Remove facades, update callers** — Direct callers to the specialized classes (`UIPanelFactory`, `UIContainerHelpers`, `EncounterRegistry`). Removes indirection.
- [X] **Option B: Keep as convenience APIs** — They provide a single import point. Mark them as intentional facades with a doc comment. No code change needed.

### 5.4 Fix `main_menu.gd` Inconsistent `ButtonEffects` Usage
Replace `ButtonEffectsScript = preload(...)` with direct `ButtonEffects.apply_effects()` usage, matching all other files.

### 5.5 Address `SceneManager` Convenience Wrappers
Remove `go_to_main_menu()`, `go_to_collection()`, `go_to_draft()`, `go_to_run_view()` — they're trivial wrappers over `go_to(name)` with inconsistent coverage (only 4 of 10 scenes).

### 5.6 Fix Anchor-Based Magic Offsets in `ui_panel_factory.gd`
Replace the 4 magic offset values (`-18, -10, -13, -5`) for rewards label positioning with a `MarginContainer` anchored to bottom-right, using named margin constants.

### 5.7 Standardize Container Setup with Utilities
Add `UIContainerHelpers.create_hbox_container(separation, alignment)` to match the existing `create_vbox_container()`. Replace manual `HBoxContainer` setup in `draft.gd` and elsewhere.

### 5.8 Address `AnimationManager` Minor Issues
- Extract `_ensure_centered_pivot(node)` helper for the 7 repeated `pivot_offset = size / 2` lines
- Make `shake()` and `error_shake()` use `_create_tween()` for consistency
- Have `error_shake()` call `shake()` with specific parameters

### 5.9 Move Inline Shaders to `.gdshader` Files
Extract the shader code strings from `transition_manager.gd` into proper `dissolve.gdshader` and `wipe.gdshader` resource files.

### 5.10 Fix `EncounterFactory` Duplicate Data Loading
Remove the independent `JsonPersistence.load_json("encounter_types.json")` call and instead read from `GameData.get_all_encounter_types()` (add this accessor if needed).

---

## Execution Notes

- Each phase builds on the previous — complete phases in order
- Within a phase, items can generally be done in any order
- After each phase, run the game to verify no regressions
- Phase 1 is pure deletion/simplification — safest to start with
- Phase 2 creates the utilities that Phase 3 and 4 depend on
- Phase 3 may require updating tests if any exist for the affected logic
- Phase 4 involves inheritance changes — test component behavior carefully
- Phase 5 items are independent quality-of-life improvements
