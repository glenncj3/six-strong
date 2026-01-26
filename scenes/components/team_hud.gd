extends Control
# TeamHUD - Persistent team tiles that stay visible during gameplay
# Lives on a CanvasLayer above the transition layer so it persists through scene changes
# Phase 5: Updated to display 2x3 character grid

const CharacterTileScene = preload("res://scenes/components/character_tile.tscn")
const CharacterInfoPanelScene = preload("res://scenes/components/character_info_panel.tscn")
const GridSlotScene = preload("res://scenes/components/grid_slot.tscn")

@onready var grid_container: VBoxContainer = $VBoxContainer/GridContainer
@onready var front_row: HBoxContainer = $VBoxContainer/GridContainer/FrontRow
@onready var back_row: HBoxContainer = $VBoxContainer/GridContainer/BackRow
@onready var info_panel_clip: Control = $VBoxContainer/InfoPanelClip

var _is_draft_mode: bool = false
var _visibility: HudVisibilityHelper = null
var info_panel: Node = null

# Grid slots: _slots[row][col]
var _slots: Array = []


func _ready() -> void:
	add_to_group("team_hud")  # Keep for backwards compatibility
	visible = false
	_visibility = HudVisibilityHelper.new(self)
	_create_grid_slots()
	_setup_info_panel()
	SceneManager.scene_loaded.connect(_on_scene_loaded)
	RunManager.draft_character_added.connect(_on_draft_character_added)


func _create_grid_slots() -> void:
	"""Create the 2x3 grid of slots."""
	_slots.clear()
	var slot_size = _get_slot_size()

	# Create front row (row 0)
	var front_row_slots: Array = []
	for col in range(GameConstants.GRID_COLS):
		var slot = GridSlotScene.instantiate()
		front_row.add_child(slot)
		slot.setup_slot(0, col, slot_size)
		slot.slot_clicked.connect(_on_slot_clicked)
		front_row_slots.append(slot)
	_slots.append(front_row_slots)

	# Create back row (row 1)
	var back_row_slots: Array = []
	for col in range(GameConstants.GRID_COLS):
		var slot = GridSlotScene.instantiate()
		back_row.add_child(slot)
		slot.setup_slot(1, col, slot_size)
		slot.slot_clicked.connect(_on_slot_clicked)
		back_row_slots.append(slot)
	_slots.append(back_row_slots)


func _setup_info_panel() -> void:
	# Fix info panel height to match slot height
	var slot_height = _get_slot_size().y
	info_panel_clip.custom_minimum_size = Vector2(0, slot_height)
	info_panel_clip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info_panel = CharacterInfoPanelScene.instantiate()
	info_panel_clip.add_child(info_panel)
	info_panel.set_anchors_preset(Control.PRESET_FULL_RECT)


# =============================================================================
# SCENE TRANSITIONS
# =============================================================================

func _on_scene_loaded(scene_path: String) -> void:
	if not _visibility.is_gameplay_scene(scene_path):
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
	if info_panel and info_panel.is_showing():
		info_panel.hide_panel()
	_clear_all_slots()
	# In draft mode, slots start as placeholders (dimmed)
	_set_all_slots_dimmed(true)


func _on_draft_character_added(char_instance: CharacterInstance) -> void:
	"""Handle draft character added signal from RunManager."""
	add_drafted_character(char_instance)


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
	if info_panel and info_panel.is_showing():
		info_panel.hide_panel()
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
# SLOT INTERACTION
# =============================================================================

func _on_slot_clicked(_row: int, _col: int, character: CharacterInstance) -> void:
	"""Handle slot click."""
	if character == null:
		# Empty slot clicked - could show context menu or do nothing
		return

	if info_panel.is_showing() and info_panel.current_char_instance == character:
		info_panel.hide_panel()
	else:
		info_panel.show_character(character)


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
	"""Calculate slot size based on available space."""
	var available_width = max(size.x, 688) - 24
	var spacing = 8 * (GameConstants.GRID_COLS - 1)
	var slot_width = floor((available_width - spacing) / float(GameConstants.GRID_COLS))
	slot_width = clamp(slot_width, 80, 150)
	return Vector2(slot_width, slot_width)


func refresh_display() -> void:
	"""Public method to refresh the grid display."""
	if _is_draft_mode:
		return
	_update_grid_display()
