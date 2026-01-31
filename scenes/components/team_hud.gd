extends Control
# TeamHUD - Persistent team tiles that stay visible during gameplay
# Lives on a CanvasLayer above the transition layer so it persists through scene changes

const CharacterTileScene = preload("res://scenes/components/character_tile.tscn")

@onready var grid_container: VBoxContainer = $GridContainer
@onready var front_row: HBoxContainer = $GridContainer/FrontRow
@onready var back_row: HBoxContainer = $GridContainer/BackRow

var _is_draft_mode: bool = false
var _visibility: HudVisibilityHelper = null

# Grid slots: _slots[row][col]
var _slots: Array = []

# Drag-and-drop state
var _is_dragging: bool = false
var _drag_source_row: int = -1
var _drag_source_col: int = -1
var _drag_preview: Control = null


func _ready() -> void:
	add_to_group("team_hud")  # Keep for backwards compatibility
	visible = false
	_visibility = HudVisibilityHelper.new(self)
	_create_grid_slots()
	SceneManager.scene_loaded.connect(_on_scene_loaded)
	RunManager.character_acquired.connect(_on_character_acquired)


func _create_grid_slots() -> void:
	"""Create the 2x3 grid of slots."""
	_slots.clear()
	var slot_size = _get_slot_size()

	# Create front row (row 0)
	var front_row_slots: Array = []
	for col in range(GameConstants.GRID_COLS):
		var slot = CharacterTileScene.instantiate()
		front_row.add_child(slot)
		slot.setup_slot(0, col, slot_size)
		slot.drag_started.connect(_on_slot_drag_started)
		front_row_slots.append(slot)
	_slots.append(front_row_slots)

	# Create back row (row 1)
	var back_row_slots: Array = []
	for col in range(GameConstants.GRID_COLS):
		var slot = CharacterTileScene.instantiate()
		back_row.add_child(slot)
		slot.setup_slot(1, col, slot_size)
		slot.drag_started.connect(_on_slot_drag_started)
		back_row_slots.append(slot)
	_slots.append(back_row_slots)


# =============================================================================
# SCENE TRANSITIONS
# =============================================================================

func _on_scene_loaded(scene_path: String) -> void:
	if not _visibility.is_gameplay_scene(scene_path):
		if visible:
			_visibility.fade_out()
		return

	if scene_path == "res://scenes/ui/combat_scene.tscn":
		# Combat scene renders its own grid with HP bars
		if visible:
			_visibility.fade_out()
		return

	if scene_path == "res://scenes/ui/draft.tscn":
		reset_for_draft()
		if not visible:
			_visibility.fade_in()
		else:
			visible = true
	elif RunManager.is_run_active:
		_enter_run_mode()
		if not visible:
			_visibility.fade_in()
		else:
			visible = true
	else:
		visible = false


# =============================================================================
# DRAFT MODE
# =============================================================================

func reset_for_draft() -> void:
	_is_draft_mode = true
	_clear_all_slots()
	# In draft mode, slots start as placeholders (dimmed)
	_set_all_slots_dimmed(true)


func _on_character_acquired(char_instance: CharacterInstance) -> void:
	"""Handle character acquired signal from RunManager (draft or run-time)."""
	if _is_draft_mode:
		add_drafted_character(char_instance)
	else:
		_update_grid_display()


func add_drafted_character(char_instance: CharacterInstance) -> void:
	"""Add a drafted character to the first empty slot."""
	if not _is_draft_mode:
		return

	# Find the first empty slot
	for row in range(GameConstants.GRID_ROWS):
		for col in range(GameConstants.GRID_COLS):
			var slot = _get_slot(row, col)
			if slot and slot.is_empty():
				slot.set_character(char_instance)
				slot.modulate.a = 1.0
				AnimationManager.fade_in(slot, 0.2)
				return


func _clear_all_slots() -> void:
	"""Clear all slot displays."""
	for row in range(GameConstants.GRID_ROWS):
		for col in range(GameConstants.GRID_COLS):
			var slot = _get_slot(row, col)
			if slot:
				slot.set_character(null)


func _set_all_slots_dimmed(dimmed: bool) -> void:
	"""Set all slots to dimmed (placeholder) state."""
	for row in range(GameConstants.GRID_ROWS):
		for col in range(GameConstants.GRID_COLS):
			var slot = _get_slot(row, col)
			if slot:
				if dimmed:
					slot.modulate.a = 0.3
				else:
					slot.modulate.a = 1.0


# =============================================================================
# RUN MODE
# =============================================================================

func _enter_run_mode() -> void:
	_is_draft_mode = false
	_set_all_slots_dimmed(false)
	_update_grid_display()


func _update_grid_display() -> void:
	"""Update grid display from RunManager's current state."""
	var run_state = RunManager.get_run_state()
	if not run_state:
		_clear_all_slots()
		return

	var grid = run_state.get_grid()
	if not grid:
		_clear_all_slots()
		return

	# Update each slot from grid data
	for row in range(GameConstants.GRID_ROWS):
		for col in range(GameConstants.GRID_COLS):
			var slot = _get_slot(row, col)
			if slot:
				var character = grid.get_character_at(row, col)
				slot.set_character(character)


# =============================================================================
# HELPERS
# =============================================================================

func _get_slot(row: int, col: int):
	"""Get slot at position."""
	if row < 0 or row >= _slots.size():
		return null
	if col < 0 or col >= _slots[row].size():
		return null
	return _slots[row][col]


func _get_slot_size() -> Vector2:
	"""Calculate slot size to match legacy tile sizes (3 across)."""
	var slot_width = UIScaler.calculate_tile_size(size.x, GameConstants.GRID_COLS)
	return Vector2(slot_width, slot_width)


func refresh_display() -> void:
	"""Public method to refresh the grid display."""
	if _is_draft_mode:
		return
	_update_grid_display()


# =============================================================================
# DRAG AND DROP
# =============================================================================

func _on_slot_drag_started(slot_row: int, slot_col: int, _character: CharacterInstance) -> void:
	if _is_draft_mode or _is_dragging:
		return

	_is_dragging = true
	_drag_source_row = slot_row
	_drag_source_col = slot_col

	# Dim source slot
	var source_slot = _get_slot(slot_row, slot_col)
	if source_slot:
		source_slot.modulate.a = 0.3

	# Create floating preview
	_create_drag_preview(source_slot)

	# Highlight other slots as drop targets
	_set_drop_highlights(true)


func _create_drag_preview(source_slot: CharacterTile) -> void:
	_drag_preview = CharacterTileScene.instantiate()
	# Add to self (TeamHUD is on a CanvasLayer already at layer 150)
	add_child(_drag_preview)
	var slot_size = _get_slot_size()
	_drag_preview.setup_slot(_drag_source_row, _drag_source_col, slot_size)
	_drag_preview.set_character(source_slot.character)
	_drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_preview.modulate.a = 0.85
	_drag_preview.scale = Vector2(1.05, 1.05)
	# Position at current touch/mouse position
	_drag_preview.position = get_global_mouse_position() - slot_size / 2.0


func _input(event: InputEvent) -> void:
	if not _is_dragging:
		return

	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		var pos = event.position if event is InputEventScreenDrag else event.global_position
		if _drag_preview:
			var slot_size = _get_slot_size()
			_drag_preview.position = pos - slot_size / 2.0

	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_finish_drag(event.global_position)

	elif event is InputEventScreenTouch and not event.pressed:
		_finish_drag(event.position)


func _finish_drag(drop_position: Vector2) -> void:
	var target_slot = _get_slot_at_position(drop_position)

	if target_slot and not (target_slot.row == _drag_source_row and target_slot.col == _drag_source_col):
		# Perform swap (works for both occupied and empty target slots)
		var run_state = RunManager.get_run_state()
		if run_state:
			var grid = run_state.get_grid()
			if grid:
				grid.swap_positions(_drag_source_row, _drag_source_col, target_slot.row, target_slot.col)

	# Clean up
	_cancel_drag()
	_update_grid_display()


func _cancel_drag() -> void:
	# Restore source slot opacity
	var source_slot = _get_slot(_drag_source_row, _drag_source_col)
	if source_slot:
		source_slot.modulate.a = 1.0

	# Remove preview
	if _drag_preview:
		_drag_preview.queue_free()
		_drag_preview = null

	# Clear highlights
	_set_drop_highlights(false)

	_is_dragging = false
	_drag_source_row = -1
	_drag_source_col = -1


func _set_drop_highlights(enabled: bool) -> void:
	for row_idx in range(GameConstants.GRID_ROWS):
		for col_idx in range(GameConstants.GRID_COLS):
			if enabled and row_idx == _drag_source_row and col_idx == _drag_source_col:
				continue
			var slot = _get_slot(row_idx, col_idx)
			if slot:
				slot.set_drag_highlight(enabled, true)


func _get_slot_at_position(global_pos: Vector2) -> CharacterTile:
	for row_idx in range(GameConstants.GRID_ROWS):
		for col_idx in range(GameConstants.GRID_COLS):
			var slot = _get_slot(row_idx, col_idx)
			if slot and slot.get_global_rect().has_point(global_pos):
				return slot
	return null
