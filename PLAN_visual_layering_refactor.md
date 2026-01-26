# Visual Layering System Refactor Plan

## Overview

This plan addresses inconsistencies and fragility in the game's visual layering and popup systems. The changes are designed to be incremental, backward-compatible, and safe to implement without breaking existing functionality.

---

## Phase 1: Add Layer Constants (Low Risk)

**Goal**: Centralize layer values for documentation and future consistency.

### Changes

**File**: `scripts/constants/game_constants.gd`

Add after line 511 (after TransitionType enum):

```gdscript
# =============================================================================
# VISUAL LAYER CONSTANTS (CanvasLayer values)
# =============================================================================

# Layer hierarchy (higher = renders on top):
#   0-99:   Gameplay content (scenes loaded into SceneContainer)
#   100:    Scene transitions (fade, wipe, etc.)
#   150:    Persistent HUD (RunHUD, TeamHUD)
#   200:    Modal popups (reserved for future ModalLayer)
#   250:    Tooltips (reserved for future TooltipLayer)

const LAYER_GAMEPLAY := 0
const LAYER_TRANSITION := 100
const LAYER_HUD := 150
const LAYER_MODAL := 200       # Reserved for Phase 4
const LAYER_TOOLTIP := 250     # Reserved for future use
```

### Validation
- Run project headless to verify no syntax errors
- Existing code continues to work (no behavioral changes)

---

## Phase 2: Fix RewardClaimPopup Parent Restoration (Medium Risk)

**Goal**: Ensure popup properly cleans up after itself.

### Changes

**File**: `scenes/components/reward_claim_popup.gd`

**2a. Update `hide_popup()` method** (lines 275-283):

```gdscript
func hide_popup() -> void:
    """Hide the popup and clean up overlay."""
    visible = false

    # Remove overlay
    if _overlay and is_instance_valid(_overlay):
        _overlay.queue_free()
        _overlay = null

    # Restore to original parent if valid (allows reuse without reparenting issues)
    if _original_parent and is_instance_valid(_original_parent):
        reparent(_original_parent)
        _original_parent = null
```

**2b. Add cleanup on tree exit** (add after `_ready()`):

```gdscript
func _exit_tree() -> void:
    """Clean up overlay when popup is removed from tree."""
    if _overlay and is_instance_valid(_overlay):
        _overlay.queue_free()
        _overlay = null
```

### Validation
- Test treasure chest encounter: claim item, verify no orphaned nodes
- Test shop encounter: purchase item, verify popup closes cleanly
- Test wheel of fortune: claim reward, verify cleanup
- Check scene tree in debugger after popup closes

---

## Phase 3: Standardize Popup Instantiation Pattern (Medium Risk)

**Goal**: Make all encounter UIs use the same popup pattern for consistency.

### Changes

**File**: `scripts/encounters/types/treasure_chest_encounter_ui.gd`

**3a. Update `_show_reward_popup()` method** (lines 143-166):

Change line 149 from:
```gdscript
_main_container.add_child(_reward_popup)
```
To:
```gdscript
# Add directly to scene root - popup will manage its own positioning
var scene_root = Engine.get_main_loop().current_scene
scene_root.add_child(_reward_popup)
```

**File**: `scripts/encounters/types/skill_trainer_encounter_ui.gd`

Apply same pattern - verify popup is added to scene_root, not _main_container.

**File**: `scripts/encounters/types/wheel_of_fortune_encounter_ui.gd`

Verify popup instantiation follows same pattern.

### Validation
- Test each encounter type to verify popups appear correctly
- Verify popups center properly on screen
- Verify overlay dims entire screen (not just container)

---

## Phase 4: Create Modal Base Class (Low Risk)

**Goal**: Provide reusable foundation for future modal popups.

### Changes

**New File**: `scripts/components/modal_popup.gd`

```gdscript
class_name ModalPopup
extends PanelContainer
## Base class for modal popup windows.
## Handles overlay creation, reparenting, input blocking, and cleanup.

signal popup_opened
signal popup_closed

var _overlay: ColorRect = null
var _original_parent: Node = null


func _ready() -> void:
    visible = false


func _exit_tree() -> void:
    _cleanup_overlay()


func show_modal() -> void:
    """Show the popup as a modal overlay on top of everything."""
    _original_parent = get_parent()

    var scene_root = get_tree().current_scene
    if not scene_root:
        push_error("ModalPopup: No current scene found")
        return

    # Create dimming overlay
    _overlay = ColorRect.new()
    _overlay.color = Color(0, 0, 0, 0.5)
    _overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    _overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    scene_root.add_child(_overlay)

    # Reparent popup to scene root
    reparent(scene_root)

    # Center the popup
    _center_popup()

    visible = true
    move_to_front()
    popup_opened.emit()


func hide_modal() -> void:
    """Hide the popup and clean up."""
    visible = false
    _cleanup_overlay()

    # Restore to original parent
    if _original_parent and is_instance_valid(_original_parent):
        reparent(_original_parent)
        _original_parent = null

    popup_closed.emit()


func _center_popup() -> void:
    """Center popup on screen. Override for custom positioning."""
    set_anchors_preset(Control.PRESET_CENTER)
    anchor_left = 0.5
    anchor_top = 0.5
    anchor_right = 0.5
    anchor_bottom = 0.5
    offset_left = -size.x / 2
    offset_top = -size.y / 2
    offset_right = size.x / 2
    offset_bottom = size.y / 2


func _cleanup_overlay() -> void:
    """Remove overlay if it exists."""
    if _overlay and is_instance_valid(_overlay):
        _overlay.queue_free()
        _overlay = null
```

### Validation
- Create simple test popup extending ModalPopup
- Verify show_modal/hide_modal work correctly
- Verify overlay blocks input behind popup

---

## Phase 5: Refactor RewardClaimPopup to Use ModalPopup (Medium Risk)

**Goal**: Have RewardClaimPopup extend the standardized base class.

### Changes

**File**: `scenes/components/reward_claim_popup.gd`

**5a. Change class inheritance** (line 1):

From:
```gdscript
extends PanelContainer
```
To:
```gdscript
extends ModalPopup
```

**5b. Update `_show_popup()` method** (lines 240-272):

Replace entire method with:
```gdscript
func _show_popup() -> void:
    """Show the popup as a modal overlay on top of everything."""
    show_modal()
```

**5c. Update `hide_popup()` method** (lines 275-283):

Replace entire method with:
```gdscript
func hide_popup() -> void:
    """Hide the popup and clean up overlay."""
    hide_modal()
```

**5d. Remove redundant member variables** (lines 24-25):

Remove these lines (now inherited from ModalPopup):
```gdscript
var _overlay: ColorRect = null
var _original_parent: Node = null
```

**5e. Override `_center_popup()` to use fixed offsets** (add method):

```gdscript
func _center_popup() -> void:
    """Center popup with fixed size for reward display."""
    set_anchors_preset(Control.PRESET_CENTER)
    anchor_left = 0.5
    anchor_top = 0.5
    anchor_right = 0.5
    anchor_bottom = 0.5
    offset_left = -160
    offset_top = -200
    offset_right = 160
    offset_bottom = 200
    grow_horizontal = Control.GROW_DIRECTION_BOTH
    grow_vertical = Control.GROW_DIRECTION_BOTH
```

### Validation
- Test all encounter types that use RewardClaimPopup
- Verify overlay appears and blocks input
- Verify popup centers correctly
- Verify cleanup on close

---

## Phase 6: Deprecate or Update DetailPopup (Low Risk)

**Goal**: Either remove unused code or bring it up to standard.

### Option A: Remove (Recommended if truly unused)

Delete these files:
- `scenes/components/detail_popup.gd`
- `scenes/components/detail_popup.tscn`

### Option B: Update to use ModalPopup

If keeping for future use, apply same refactor as Phase 5:
- Change to `extends ModalPopup`
- Replace `_show_popup()` with `show_modal()`
- Add `hide_popup()` that calls `hide_modal()`

### Validation
- If removed: verify no broken references
- If updated: test showing/hiding popup

---

## Phase 7: Add ModalLayer for Future Extensibility (Low Risk)

**Goal**: Create dedicated CanvasLayer for modals that need guaranteed top positioning.

### Changes

**File**: `scenes/main.tscn`

Add after TransitionLayer (around line 146):

```
[node name="ModalLayer" type="CanvasLayer" parent="."]
layer = 200
visible = false
```

**Note**: This layer is initially hidden and reserved for future use. The current reparent-to-scene-root approach works well. This layer would be used if:
- Multiple modals need guaranteed stacking order
- Modals need to appear above scene transitions
- Complex tooltip systems are added

### Validation
- Run project to verify no visual changes
- Verify layer exists in scene tree

---

## Phase 8: Document Layering Architecture (No Risk)

**Goal**: Add documentation for future developers.

### Changes

**File**: `CLAUDE.md`

Add new section after "## Mobile UI Design":

```markdown
## Visual Layering Architecture

The game uses CanvasLayers for major visual separation:

| Layer | Constant | Purpose |
|-------|----------|---------|
| 0 | LAYER_GAMEPLAY | Main scene content |
| 100 | LAYER_TRANSITION | Fade/wipe transitions |
| 150 | LAYER_HUD | Persistent RunHUD, TeamHUD |
| 200 | LAYER_MODAL | Reserved for modal popups |
| 250 | LAYER_TOOLTIP | Reserved for tooltips |

### Popup Pattern

Modal popups should extend `ModalPopup` base class which handles:
- Dimming overlay creation
- Reparenting to scene root
- Input blocking
- Proper cleanup on close

Example:
```gdscript
extends ModalPopup

func show_my_popup() -> void:
    # Setup content...
    show_modal()

func on_close_pressed() -> void:
    hide_modal()
```
```

---

## Implementation Order

| Phase | Risk | Dependencies | Estimated Scope |
|-------|------|--------------|-----------------|
| 1 | Low | None | 1 file, add constants |
| 2 | Medium | None | 1 file, fix method |
| 3 | Medium | Phase 2 | 3 files, standardize pattern |
| 4 | Low | Phase 1 | 1 new file |
| 5 | Medium | Phase 4 | 1 file, refactor class |
| 6 | Low | Phase 5 | 1-2 files, remove or update |
| 7 | Low | Phase 1 | 1 file, add node |
| 8 | None | All | Documentation only |

**Recommended approach**: Implement phases 1-2 first, test thoroughly, then proceed with 3-5. Phases 6-8 can be done independently.

---

## Rollback Plan

Each phase is isolated. If issues arise:
- Phase 1: Remove constants (no code depends on them yet)
- Phase 2: Revert `hide_popup()` changes
- Phase 3: Revert parent node changes
- Phase 4: Delete new file (nothing depends on it yet)
- Phase 5: Revert inheritance change, restore original methods
- Phase 6: Restore deleted files from git
- Phase 7: Remove ModalLayer node
- Phase 8: Revert documentation

---

## Testing Checklist

After each phase, verify:
- [ ] Project loads without errors (headless validation)
- [ ] Main menu displays correctly
- [ ] Draft phase works
- [ ] Shop encounter: purchase item with popup
- [ ] Treasure chest encounter: claim item with popup
- [ ] Skill trainer encounter: learn skill with popup
- [ ] Wheel of fortune: claim reward with popup
- [ ] Concede dialog: shows and dismisses correctly
- [ ] Scene transitions work
- [ ] No orphaned nodes in scene tree after popup closes
