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
		front_row_slots.append(slot)
	_slots.append(front_row_slots)

	# Create back row (row 1)
	var back_row_slots: Array = []
	for col in range(GameConstants.GRID_COLS):
		var slot = CharacterTileScene.instantiate()
		back_row.add_child(slot)
		slot.setup_slot(1, col, slot_size)
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
