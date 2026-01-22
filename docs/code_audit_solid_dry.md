# SOLID/DRY Code Audit Report

**Project**: auto-battle-journey
**Date**: 2026-01-21
**Scope**: GDScript codebase analysis for SOLID and DRY principle adherence

---

## Executive Summary

The codebase demonstrates solid architectural foundations with signal-based communication, factory patterns (UIStyles), and data-driven design (encounter registry). However, several opportunities exist to reduce code duplication and improve maintainability.

### Key Metrics
- **DRY Violations**: 5 critical patterns (~530 duplicated lines)
- **SOLID Violations**: 8 issues across SRP, OCP, and DIP
- **Autoload Dependencies**: 480 direct references across 34 files

### Priority Recommendation
Focus on DRY violations first - they provide the best return on investment with lower risk. SOLID improvements (especially DIP) require more architectural changes and should be approached incrementally.

---

## DRY Violations

### DRY-1: Mouse Interaction Pattern Duplication (CRITICAL)

**Severity**: High
**Estimated Savings**: ~80 lines
**Risk Level**: Low

**Files Affected**:
- `scenes/components/character_card.gd` (lines 62-84, 134-144)
- `scenes/components/character_tile.gd` (lines 39-61, 112-124)
- `scenes/components/clickable_option_panel.gd` (lines 35-72)

**Problem**: Three files contain nearly identical implementations of:
- `_on_mouse_entered()` / `_on_mouse_exited()`
- `_apply_state_style()`
- `_on_gui_input()` for click handling
- `_is_hovered` / `_is_pressed` state variables

**Current Pattern** (repeated in each file):
```gdscript
var _is_hovered: bool = false
var _is_pressed: bool = false

func _on_mouse_entered() -> void:
    _is_hovered = true
    _apply_state_style()

func _on_mouse_exited() -> void:
    _is_hovered = false
    _is_pressed = false
    _apply_state_style()

func _apply_state_style() -> void:
    if _styles.is_empty():
        return
    var style: StyleBoxFlat
    if _is_pressed and _is_hovered:
        style = _styles.get("pressed", _styles.get("normal"))
    elif _is_hovered:
        style = _styles.get("hover", _styles.get("normal"))
    else:
        style = _styles.get("normal")
    if style:
        add_theme_stylebox_override("panel", style)
```

**Recommended Solutions**:

- [X] **Option A: Base Class (Recommended)**
  Create `ClickablePanelBase` class that `character_card.gd`, `character_tile.gd`, and `clickable_option_panel.gd` extend:
  ```gdscript
  class_name ClickablePanelBase
  extends PanelContainer

  var _styles: Dictionary = {}
  var _is_hovered: bool = false
  var _is_pressed: bool = false
  var clickable: bool = true

  func _setup_mouse_interaction() -> void:
      mouse_entered.connect(_on_mouse_entered)
      mouse_exited.connect(_on_mouse_exited)

  func _on_mouse_entered() -> void:
      _is_hovered = true
      _apply_state_style()

  # ... etc
  ```

- [ ] **Option B: Composition with Helper Node**
  Create `MouseInteractionHelper` node that can be attached to any PanelContainer:
  ```gdscript
  class_name MouseInteractionHelper
  extends Node

  signal clicked(data: Dictionary)
  @export var target: PanelContainer
  ```

- [ ] **Option C: Keep Current (No Change)**
  Accept duplication for simplicity and explicit control per component.

---

### DRY-2: Mouse Filter Propagation Pattern (HIGH)

**Severity**: High
**Estimated Savings**: ~60 lines
**Risk Level**: Low

**Files Affected**:
- `scenes/components/character_card.gd` (lines 39-50)
- `scenes/components/character_tile.gd` (lines 64-71)
- `scenes/components/skill_icon.gd` (lines 19-26)
- `scenes/components/item_slot.gd` (lines 26-33)

**Problem**: Four files contain nearly identical `_set_children_mouse_filter_ignore()` functions that set all child controls to `MOUSE_FILTER_IGNORE` to allow parent hover events.

**Current Pattern** (repeated in each file):
```gdscript
func _set_children_mouse_filter_ignore() -> void:
    margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
    # ... specific children vary
```

**Recommended Solutions**:

- [X] **Option A: UIHelpers Static Function (Recommended)**
  Add recursive utility to `UIHelpers`:
  ```gdscript
  static func set_children_mouse_filter_ignore(parent: Control, recursive: bool = true) -> void:
      for child in parent.get_children():
          if child is Control:
              child.mouse_filter = Control.MOUSE_FILTER_IGNORE
              if recursive:
                  set_children_mouse_filter_ignore(child, true)
  ```
  Usage: `UIHelpers.set_children_mouse_filter_ignore(self)`

- [ ] **Option B: Scene-level Setting**
  Configure mouse_filter in .tscn files instead of code (requires manual scene edits).

- [ ] **Option C: Keep Current (No Change)**
  Explicit per-component control is maintainable for small number of components.

---

### DRY-3: Option Panel Creation Duplication (HIGH)

**Severity**: High
**Estimated Savings**: ~100 lines
**Risk Level**: Medium

**Files Affected**:
- `scripts/utils/ui_helpers.gd` lines 434-536 (`create_combat_option_panel`)
- `scripts/utils/ui_helpers.gd` lines 564-648 (`create_encounter_option_panel`)

**Problem**: These two functions are ~90% identical. They both create:
- ClickableOptionPanel with styles
- HBoxContainer with image and info section
- Name, type, description labels
- Only differ in: type-specific labels (difficulty vs reward preview)

**Shared Structure** (duplicated):
```gdscript
var panel = ClickableOptionPanel.new()
panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
panel.clip_contents = true
# ... 50+ identical lines of setup ...
var name_label = Label.new()
info_vbox.add_child(name_label)
name_label.text = data.get("name", "Unknown")
# ... etc
```

**Recommended Solutions**:

- [X] **Option A: Unified Function with Type Parameter (Recommended)**
  ```gdscript
  enum OptionPanelType { COMBAT, ENCOUNTER }

  static func create_option_panel(
      data: Dictionary,
      panel_type: OptionPanelType,
      on_select: Callable
  ) -> ClickableOptionPanel:
      var panel = _create_option_panel_base(data, on_select)

      match panel_type:
          OptionPanelType.COMBAT:
              _add_combat_specific_labels(panel, data)
          OptionPanelType.ENCOUNTER:
              _add_encounter_specific_labels(panel, data)

      return panel
  ```

- [ ] **Option B: Strategy Pattern**
  Create `OptionPanelStrategy` classes for combat vs encounter with shared base.

- [ ] **Option C: Keep Current (No Change)**
  Two similar functions are acceptable for explicit readability.

---

### DRY-4: Compact Mode Logic Duplication (MEDIUM)

**Severity**: Medium
**Estimated Savings**: ~50 lines
**Risk Level**: Low

**Files Affected**:
- `scenes/components/skill_icon.gd` (lines 53-91)
- `scenes/components/item_slot.gd` (lines 99-137)

**Problem**: Both files have nearly identical `set_compact()` functions that:
- Toggle label visibility
- Adjust margin constants (2px vs 4px)
- Adjust icon sizes
- Apply panel styling

**Current Pattern** (in both files):
```gdscript
func set_compact(enabled: bool) -> void:
    is_compact = enabled
    if enabled:
        custom_minimum_size = compact_size
        margin_container.add_theme_constant_override("margin_left", 2)
        # ... 3 more margins
        icon.custom_minimum_size = Vector2(size, size)
        label.visible = false
        vbox.add_theme_constant_override("separation", 0)
    else:
        # ... inverse logic
    UIStyles.apply_panel_style(self, UIStyles.create_subtle_panel())
```

**Recommended Solutions**:

- [X] **Option A: Shared Base Class (Recommended)**
  Create `CompactableIconBase` that both extend:
  ```gdscript
  class_name CompactableIconBase
  extends PanelContainer

  var is_compact: bool = false

  func set_compact(enabled: bool) -> void:
      is_compact = enabled
      _apply_compact_style(enabled)

  func _get_compact_size() -> Vector2:
      return Vector2.ZERO  # Override in subclass

  func _get_normal_size() -> Vector2:
      return Vector2.ZERO  # Override in subclass
  ```

- [ ] **Option B: UIHelpers Static Function**
  ```gdscript
  static func apply_compact_mode(
      panel: PanelContainer,
      enabled: bool,
      compact_size: Vector2,
      normal_size: Vector2,
      margin_container: MarginContainer,
      icon: TextureRect,
      label: Label,
      vbox: VBoxContainer
  ) -> void:
  ```

- [ ] **Option C: Keep Current (No Change)**
  Only 2 files affected; duplication is manageable.

---

### DRY-5: Select Screen Pattern Duplication (MEDIUM)

**Severity**: Medium
**Estimated Savings**: ~40 lines
**Risk Level**: Low

**Files Affected**:
- `scenes/ui/encounter_select.gd` (54 lines)
- `scenes/ui/combat_select.gd` (54 lines)

**Problem**: These files are nearly identical (~95% same code). They both:
- Set up team display identically
- Clear and generate options
- Create option panels from arrays
- Handle selection by storing data and navigating

**Differences** (only these lines differ):
```gdscript
# encounter_select.gd
encounter_options = EncounterFactory.generate_encounter_options(3)
var panel = UIHelpers.create_encounter_option_panel(encounter_data, _on_encounter_selected)
SceneManager.set_scene_data("selected_encounter", encounter_data)
SceneManager.go_to("encounter_execute")

# combat_select.gd
combat_options = RunManager.generate_combat_options(3)
var panel = UIHelpers.create_combat_option_panel(combat_data, _on_combat_selected)
SceneManager.set_scene_data("selected_combat", combat_data)
SceneManager.go_to("combat_stub")
```

**Recommended Solutions**:

- [X] **Option A: Generic SelectScreen Base Class (Recommended)**
  ```gdscript
  class_name SelectScreenBase
  extends Control

  func _get_option_generator() -> Callable:
      return Callable()  # Override

  func _create_option_panel(data: Dictionary) -> Control:
      return null  # Override

  func _get_data_key() -> String:
      return ""  # Override

  func _get_next_scene() -> String:
      return ""  # Override
  ```

- [ ] **Option B: Single Configurable Scene**
  Use one `option_select.gd` with exported configuration variables.

- [ ] **Option C: Keep Current (No Change)**
  Two separate screens maintain explicit control and are easy to understand.

---

## SOLID Violations

### SRP-1: UIHelpers Has Too Many Responsibilities (HIGH)

**Severity**: High
**Current Size**: 771 lines
**Files**: `scripts/utils/ui_helpers.gd`

**Problem**: UIHelpers handles:
1. Container management (create_vbox, clear_children)
2. Label/spacer creation
3. Texture loading
4. Formatting (currency, stats)
5. Shop row creation
6. Combat option panel creation
7. Encounter option panel creation
8. Team display population
9. Team selector creation

**Recommended Solutions**:

- [X] **Option A: Split by Domain (Recommended)**
  - `UIContainerHelpers` - Container utilities
  - `UIFormattingHelpers` - Text/number formatting
  - `UIPanelFactory` - Option panel creation
  - `UITeamDisplay` - Team display logic (or keep in component)

- [ ] **Option B: Split by Usage Pattern**
  - `UIHelpers` - Generic utilities (current lines 1-250)
  - `OptionPanelBuilder` - Panel creation (current lines 350-650)
  - Move team display to its own scene/component

- [ ] **Option C: Keep Current (No Change)**
  Single utility class is common pattern in game development.

---

### SRP-2: EncounterHandlers Mixes Registry and UI Creation (MEDIUM)

**Severity**: Medium
**Current Size**: 498 lines
**Files**: `scripts/encounters/encounter_handlers.gd`

**Problem**: EncounterHandlers is responsible for:
1. Handler registration/registry
2. UI creation for each encounter type
3. Event handling callbacks
4. Game state modifications (awarding gold, XP, etc.)

**Recommended Solutions**:

- [X] **Option A: Separate UI and Logic (Recommended)**
  - `EncounterRegistry` - Registration and lookup only
  - `EncounterUIFactory` - UI creation functions
  - Individual handler classes if needed for complex encounters

- [ ] **Option B: Handler Classes**
  Create individual classes per encounter type that implement a common interface:
  ```gdscript
  class_name ShopEncounterHandler
  extends EncounterHandlerBase

  func create_ui(data: Dictionary, context: Dictionary) -> Control:
      # ...
  ```

- [ ] **Option C: Keep Current (No Change)**
  Current pattern is data-driven and extensible via `register()`.

---

### SRP-3: Draft Screen Has Multiple Responsibilities (LOW)

**Severity**: Low
**Current Size**: 371 lines
**Files**: `scenes/ui/draft.gd`

**Problem**: Draft handles:
1. Option generation logic
2. UI display and updates
3. Character selection logic
4. Team display management
5. Unlock flow

This is borderline acceptable for a scene controller but could be improved.

**Recommended Solutions**:

- [X] **Option A: Extract DraftManager (Recommended)**
  Move draft logic (option generation, selection state) to a manager class:
  ```gdscript
  class_name DraftManager

  signal options_generated(options: Array)
  signal character_drafted(char_data: Dictionary)
  signal draft_complete(team: Array)

  func generate_options() -> Array: ...
  func select_character(char_data: Dictionary) -> bool: ...
  ```

- [ ] **Option B: Keep Current (No Change)**
  Scene scripts commonly contain this level of logic in Godot.

---

### OCP-1: Hardcoded Encounter Type Handling (MEDIUM)

**Severity**: Medium
**Files**: `scripts/utils/ui_helpers.gd` (lines 651-681)

**Problem**: `_get_encounter_reward_preview()` uses a match statement for encounter types:
```gdscript
match encounter_type:
    "shop":
        return "%d items, %d skills" % [item_count, skill_count]
    "xp_reward":
        return "+%d XP" % data.get("xp_amount", 0)
    # ... etc
```

Adding new encounter types requires modifying this function.

**Recommended Solutions**:

- [X] **Option A: Move to Encounter Data (Recommended)**
  Add `reward_preview` field to encounter definitions:
  ```json
  {
    "type": "shop",
    "reward_preview_template": "{item_count} items, {skill_count} skills"
  }
  ```

- [ ] **Option B: Handler Registry**
  Add `get_reward_preview` callback to `EncounterHandlers`:
  ```gdscript
  register("shop", {
      "create_ui": _create_shop_ui,
      "get_reward_preview": _get_shop_preview,
      "immediate_complete": true
  })
  ```

- [ ] **Option C: Keep Current (No Change)**
  Match statement is readable and encounter types change infrequently.

---

### OCP-2: Hardcoded Stat Formatting (LOW)

**Severity**: Low
**Files**: `scripts/utils/ui_helpers.gd` (lines 230-249)

**Problem**: `format_stat()` uses hardcoded dictionary for stat abbreviations:
```gdscript
var short_names = {
    GameConstants.STAT_HEALTH: "HP",
    GameConstants.STAT_ATTACK: "ATK",
    # ...
}
```

**Recommended Solutions**:

- [X] **Option A: Move to GameConstants (Recommended)**
  ```gdscript
  # In GameConstants
  const STAT_DISPLAY_NAMES = {
      STAT_HEALTH: "HP",
      STAT_ATTACK: "ATK",
      # ...
  }
  ```

- [ ] **Option B: Keep Current (No Change)**
  Stats rarely change; inline definition is acceptable.

---

### DIP-1: Direct Autoload Dependencies (LOW-MEDIUM)

**Severity**: Low to Medium (depends on testing needs)
**Current Count**: 480 references across 34 files

**Problem**: UI components directly reference autoloads:
- `RunManager.get_team()`
- `PlayerAccount.get_unlocked_characters()`
- `GameData.get_character_by_id()`
- `SceneManager.go_to()`
- `GameConstants.COLOR_*`

This makes components harder to test in isolation and creates tight coupling.

**Most Coupled Files**:
| File | Autoload References |
|------|---------------------|
| ui_helpers.gd | 55 |
| encounter_handlers.gd | 48 |
| run_view.gd | 45 |
| draft.gd | 23 |
| combat_stub.gd | 20 |

**Recommended Solutions**:

- [X] **Option A: Dependency Injection for Components (Recommended)**
  Pass dependencies to components via setup functions:
  ```gdscript
  # Instead of
  func setup(char_id: String) -> void:
      var data = GameData.get_character_by_id(char_id)

  # Use
  func setup(char_data: Dictionary) -> void:
      # Caller provides the data
  ```

- [ ] **Option B: Service Locator Pattern**
  Create a `Services` autoload that provides interfaces:
  ```gdscript
  var data_provider: DataProviderInterface
  var scene_navigation: SceneNavigationInterface
  ```

- [ ] **Option C: Keep Current (No Change)**
  Autoloads are idiomatic in Godot; this is a common pattern.
  Only address if unit testing becomes a priority.

---

## Architecture Strengths (Preserve These)

### 1. Signal-Based Communication
The codebase correctly uses signals for decoupling:
- `card_clicked`, `tile_clicked`, `panel_clicked` signals
- Components don't directly call parent methods

### 2. UIStyles Factory Pattern
`UIStyles` provides consistent styling through factory methods:
- `create_clickable_panel_styles()`
- `create_card_panel()`
- `apply_button_styles()`

### 3. Data-Driven Encounter Registry
`EncounterHandlers` uses a registry pattern that allows:
- Runtime registration of new encounter types
- Separation of handler lookup from handler definition

### 4. Consistent Serialization
Character and run data use `to_dict()` / `from_dict()` patterns for save/load.

### 5. Centralized Constants
`GameConstants` provides single source of truth for colors, sizes, and stat names.

---

## Prioritized Remediation Phases

### Phase 1: Quick Wins (Low Risk, High Value)
- [ ] **DRY-2**: Add `UIHelpers.set_children_mouse_filter_ignore()` (~30 min)
- [ ] **OCP-2**: Move stat display names to `GameConstants` (~15 min)
- [ ] **DRY-3**: Unify option panel creation functions (~1-2 hours)

### Phase 2: Component Refactoring (Medium Risk, High Value)
- [ ] **DRY-1**: Create `ClickablePanelBase` class (~2-3 hours)
- [ ] **DRY-4**: Create `CompactableIconBase` class (~1-2 hours)
- [ ] **DRY-5**: Create `SelectScreenBase` class (~1-2 hours)

### Phase 3: Architectural Improvements (Higher Risk, Long-term Value)
- [ ] **SRP-1**: Split UIHelpers into domain-specific utilities (~3-4 hours)
- [ ] **SRP-2**: Separate EncounterHandlers registry from UI (~2-3 hours)
- [ ] **OCP-1**: Data-driven reward previews (~1-2 hours)

### Phase 4: Future Consideration (Address When Needed)
- [ ] **DIP-1**: Add dependency injection to components
- [ ] **SRP-3**: Extract DraftManager from draft.gd

---

## Implementation Details

### Creating ClickablePanelBase (DRY-1)

**New File**: `scripts/components/clickable_panel_base.gd`

```gdscript
class_name ClickablePanelBase
extends PanelContainer
## Base class for PanelContainers with hover/click interaction.
## Provides consistent mouse interaction across components.

signal panel_clicked(data: Variant)

var _styles: Dictionary = {}
var _is_hovered: bool = false
var _is_pressed: bool = false
var _click_data: Variant = null
var clickable: bool = true


func _ready() -> void:
    if clickable:
        _setup_mouse_interaction()
    _on_ready()


func _on_ready() -> void:
    ## Override in subclass for additional initialization
    pass


func _setup_mouse_interaction() -> void:
    gui_input.connect(_on_gui_input)
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)


func setup_styles(styles: Dictionary, click_data: Variant = null) -> void:
    _styles = styles
    _click_data = click_data
    _apply_state_style()


func _on_mouse_entered() -> void:
    if not clickable:
        return
    _is_hovered = true
    _apply_state_style()


func _on_mouse_exited() -> void:
    _is_hovered = false
    _is_pressed = false
    _apply_state_style()


func _apply_state_style() -> void:
    if _styles.is_empty() or not clickable:
        return

    var style: StyleBoxFlat
    if _is_pressed and _is_hovered:
        style = _styles.get("pressed", _styles.get("normal"))
    elif _is_hovered:
        style = _styles.get("hover", _styles.get("normal"))
    else:
        style = _styles.get("normal")

    if style:
        add_theme_stylebox_override("panel", style)


func _on_gui_input(event: InputEvent) -> void:
    if not clickable:
        return

    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _is_pressed = true
                _apply_state_style()
            else:
                if _is_pressed and _is_hovered:
                    _handle_click()
                _is_pressed = false
                _apply_state_style()


func _handle_click() -> void:
    ## Override in subclass if needed
    panel_clicked.emit(_click_data)


func set_clickable(enabled: bool) -> void:
    clickable = enabled
    mouse_filter = MOUSE_FILTER_STOP if enabled else MOUSE_FILTER_IGNORE

    if enabled and not mouse_entered.is_connected(_on_mouse_entered):
        _setup_mouse_interaction()
    elif not enabled:
        if mouse_entered.is_connected(_on_mouse_entered):
            mouse_entered.disconnect(_on_mouse_entered)
            mouse_exited.disconnect(_on_mouse_exited)

    _apply_state_style()
```

**Migration for character_card.gd**:
```gdscript
# Change
extends PanelContainer
# To
extends ClickablePanelBase

# Remove these (now in base class):
# - var _styles, _is_hovered, _is_pressed
# - _on_mouse_entered(), _on_mouse_exited()
# - _apply_state_style()
# - Most of _on_gui_input()

# Override _handle_click() instead:
func _handle_click() -> void:
    card_clicked.emit(character_data)
```

---

### Adding UIHelpers.set_children_mouse_filter_ignore (DRY-2)

**Add to**: `scripts/utils/ui_helpers.gd`

```gdscript
static func set_children_mouse_filter_ignore(parent: Control, recursive: bool = true) -> void:
    """
    Set all child Control nodes to MOUSE_FILTER_IGNORE.
    Use this to allow parent panels to receive hover events.

    Args:
        parent: The parent Control whose children should be modified
        recursive: If true, also process children of children (default: true)
    """
    for child in parent.get_children():
        if child is Control:
            child.mouse_filter = Control.MOUSE_FILTER_IGNORE
            if recursive:
                set_children_mouse_filter_ignore(child, true)
```

**Migration for affected files**:
```gdscript
# Replace
func _set_children_mouse_filter_ignore() -> void:
    margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    # ... etc

# With
func _ready() -> void:
    UIHelpers.set_children_mouse_filter_ignore(self)
```

---

### Unifying Option Panel Creation (DRY-3)

**Modify**: `scripts/utils/ui_helpers.gd`

```gdscript
enum OptionPanelType { COMBAT, ENCOUNTER }

static func create_option_panel(
    data: Dictionary,
    panel_type: OptionPanelType,
    on_select: Callable
) -> ClickableOptionPanel:
    """
    Create an option panel for combat or encounter selection.

    Args:
        data: Option data dictionary
        panel_type: COMBAT or ENCOUNTER
        on_select: Callback when panel is clicked

    Returns:
        Configured ClickableOptionPanel
    """
    var panel = ClickableOptionPanel.new()
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    panel.clip_contents = true

    # Common style setup
    var bg_color = Color(data.get("bg_color", "#3D2E24"))
    var hover_color = Color(data.get("hover_color", "#5D4E44"))
    var pressed_color = Color(data.get("pressed_color", "#2D1E14"))
    var border_color = Color(data.get("border_color", "#B88726"))

    var styles = UIStyles.create_clickable_panel_styles(bg_color, hover_color, pressed_color, border_color)
    panel.setup(data, styles)

    if on_select.is_valid():
        panel.panel_clicked.connect(on_select)

    # Common structure
    var hbox = HBoxContainer.new()
    panel.add_child(hbox)
    hbox.add_theme_constant_override("separation", 12)

    # Image section
    var margin = _create_option_image_section(data)
    hbox.add_child(margin)

    # Info section
    var info_vbox = _create_option_info_section(data)
    hbox.add_child(info_vbox)

    # Type-specific labels
    match panel_type:
        OptionPanelType.COMBAT:
            _add_combat_labels(info_vbox, data)
        OptionPanelType.ENCOUNTER:
            _add_encounter_labels(info_vbox, data)

    return panel


static func _create_option_image_section(data: Dictionary) -> MarginContainer:
    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", GameConstants.PANEL_MARGIN)
    margin.add_theme_constant_override("margin_right", GameConstants.PANEL_MARGIN)
    margin.add_theme_constant_override("margin_top", GameConstants.PANEL_MARGIN)
    margin.add_theme_constant_override("margin_bottom", GameConstants.PANEL_MARGIN)

    var image = TextureRect.new()
    margin.add_child(image)
    image.custom_minimum_size = Vector2(GameConstants.COMBAT_IMAGE_SIZE, GameConstants.COMBAT_IMAGE_SIZE)
    image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
    image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    set_texture_safe(image, data.get("image_path", ""))

    return margin


static func _create_option_info_section(data: Dictionary) -> VBoxContainer:
    var info_vbox = VBoxContainer.new()
    info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info_vbox.add_theme_constant_override("separation", 4)

    # Name
    var name_label = Label.new()
    info_vbox.add_child(name_label)
    name_label.text = data.get("name", "Unknown")
    name_label.add_theme_font_size_override("font_size", 20)

    # Type
    var type_label = Label.new()
    info_vbox.add_child(type_label)
    type_label.text = "[%s]" % data.get("type", "").to_upper().replace("_", " ")
    type_label.modulate = GameConstants.COLOR_DISABLED
    type_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)

    # Description
    var desc_label = Label.new()
    info_vbox.add_child(desc_label)
    desc_label.text = data.get("description", "")
    desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)
    desc_label.max_lines_visible = 2

    return info_vbox


static func _add_combat_labels(info_vbox: VBoxContainer, data: Dictionary) -> void:
    if data.get("type") == "ai":
        var diff_label = Label.new()
        info_vbox.add_child(diff_label)
        diff_label.text = "Difficulty: %s" % data.get("difficulty", "Unknown")
        diff_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)
        diff_label.modulate = get_difficulty_color(data.get("difficulty", ""))
    elif data.get("type") == "ghost":
        var prestige_label = Label.new()
        info_vbox.add_child(prestige_label)
        prestige_label.text = "Player Prestige: %d" % data.get("prestige", 0)
        prestige_label.modulate = GameConstants.COLOR_GHOST_PRESTIGE
        prestige_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)

    var reward_label = Label.new()
    info_vbox.add_child(reward_label)
    reward_label.text = "Rewards: +%d Gold  +%d XP" % [
        data.get("reward_gold", 0),
        data.get("reward_xp", 0)
    ]
    reward_label.modulate = GameConstants.COLOR_SUCCESS
    reward_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)


static func _add_encounter_labels(info_vbox: VBoxContainer, data: Dictionary) -> void:
    var reward_label = Label.new()
    info_vbox.add_child(reward_label)
    reward_label.text = _get_encounter_reward_preview(data)
    reward_label.modulate = GameConstants.COLOR_SUCCESS
    reward_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)


# Keep existing functions as aliases for backwards compatibility
static func create_combat_option_panel(combat_data: Dictionary, on_select: Callable) -> ClickableOptionPanel:
    return create_option_panel(combat_data, OptionPanelType.COMBAT, on_select)


static func create_encounter_option_panel(encounter_data: Dictionary, on_select: Callable) -> ClickableOptionPanel:
    return create_option_panel(encounter_data, OptionPanelType.ENCOUNTER, on_select)
```

---

## User Action Required

Please review this document and:
1. Mark checkboxes `[x]` for options you want to implement
2. Add comments for any clarifications needed
3. Prioritize which items to tackle first

Once reviewed, implementation can proceed based on your selections.
