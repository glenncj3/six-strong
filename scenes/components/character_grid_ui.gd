extends Control
class_name CharacterGridUI
## Visual representation of the 2x3 character grid.
## Displays characters in a grid layout with drag-and-drop support.
##
## Grid layout:
##   [0,0] [0,1] [0,2]  <- Front row
##   [1,0] [1,1] [1,2]  <- Back row

signal slot_clicked(row: int, col: int, character: CharacterInstance)
signal character_moved(from_pos: Vector2i, to_pos: Vector2i)
signal character_swapped(pos_a: Vector2i, pos_b: Vector2i)
signal layout_changed

const GridSlotScene = preload("res://scenes/components/grid_slot.tscn")

# Grid containers
@onready var grid_container: VBoxContainer = $GridContainer
@onready var front_row: HBoxContainer = $GridContainer/FrontRow
@onready var back_row: HBoxContainer = $GridContainer/BackRow

# Slot references: _slots[row][col]
var _slots: Array = []

# Drag state
var _drag_source_slot: GridSlot = null
var _is_dragging: bool = false

# Grid data reference
var _grid: CharacterGrid = null


func _ready() -> void:
	_create_slot_grid()


func _create_slot_grid() -> void:
	"""Create the 2x3 grid of slot nodes."""
	_slots.clear()

	# Calculate slot size based on available space
	var slot_size = _calculate_slot_size()

	# Create front row (row 0)
	var front_row_slots: Array = []
	for col in range(GameConstants.GRID_COLS):
		var slot = GridSlotScene.instantiate() as GridSlot
		front_row.add_child(slot)
		slot.setup_slot(0, col, slot_size)
		slot.slot_clicked.connect(_on_slot_clicked)
		front_row_slots.append(slot)
	_slots.append(front_row_slots)

	# Create back row (row 1)
	var back_row_slots: Array = []
	for col in range(GameConstants.GRID_COLS):
		var slot = GridSlotScene.instantiate() as GridSlot
		back_row.add_child(slot)
		slot.setup_slot(1, col, slot_size)
		slot.slot_clicked.connect(_on_slot_clicked)
		back_row_slots.append(slot)
	_slots.append(back_row_slots)


func _calculate_slot_size() -> Vector2:
	"""Calculate slot size to match legacy tile sizes (3 across)."""
	var slot_width = UIScaler.calculate_tile_size(size.x, GameConstants.GRID_COLS)
	return Vector2(slot_width, slot_width)


# =============================================================================
# GRID BINDING
# =============================================================================

func bind_grid(grid: CharacterGrid) -> void:
	"""Bind to a CharacterGrid data model and sync display."""
	# Disconnect from old grid
	if _grid and _grid.grid_changed.is_connected(_on_grid_changed):
		_grid.grid_changed.disconnect(_on_grid_changed)

	_grid = grid

	if _grid:
		_grid.grid_changed.connect(_on_grid_changed)
		_refresh_all_slots()


func unbind_grid() -> void:
	"""Unbind from grid data model."""
	if _grid and _grid.grid_changed.is_connected(_on_grid_changed):
		_grid.grid_changed.disconnect(_on_grid_changed)
	_grid = null
	_clear_all_slots()


func _on_grid_changed() -> void:
	"""Handle grid data changes."""
	_refresh_all_slots()
	layout_changed.emit()


func _refresh_all_slots() -> void:
	"""Refresh all slot displays from grid data."""
	if not _grid:
		_clear_all_slots()
		return

	for row in range(GameConstants.GRID_ROWS):
		for col in range(GameConstants.GRID_COLS):
			var slot = _get_slot(row, col)
			if slot:
				var character = _grid.get_character_at(row, col)
				slot.set_character(character)


func _clear_all_slots() -> void:
	"""Clear all slot displays."""
	for row in range(GameConstants.GRID_ROWS):
		for col in range(GameConstants.GRID_COLS):
			var slot = _get_slot(row, col)
			if slot:
				slot.set_character(null)


# =============================================================================
# SLOT INTERACTION
# =============================================================================

func _on_slot_clicked(row: int, col: int, character: CharacterInstance) -> void:
	"""Handle slot click - either start drag or emit click signal."""
	if _is_dragging:
		_handle_drop(row, col)
	elif character != null:
		# Could start drag here, for now just emit click
		slot_clicked.emit(row, col, character)
	else:
		slot_clicked.emit(row, col, null)


func start_drag(row: int, col: int) -> void:
	"""Start dragging a character from a slot."""
	var slot = _get_slot(row, col)
	if not slot or slot.is_empty():
		return

	_is_dragging = true
	_drag_source_slot = slot

	# Highlight valid drop targets
	_highlight_drop_targets(row, col)


func _handle_drop(to_row: int, to_col: int) -> void:
	"""Handle dropping a character on a slot."""
	if not _is_dragging or not _drag_source_slot:
		_end_drag()
		return

	var from_row = _drag_source_slot.row
	var from_col = _drag_source_slot.col

	# Clear drag state first
	_end_drag()

	# Same slot - no-op
	if from_row == to_row and from_col == to_col:
		return

	# Perform the move/swap
	if _grid:
		var to_slot = _get_slot(to_row, to_col)
		if to_slot.is_empty():
			# Move to empty slot
			if _grid.move_character(from_row, from_col, to_row, to_col):
				character_moved.emit(Vector2i(from_row, from_col), Vector2i(to_row, to_col))
		else:
			# Swap with occupied slot
			if _grid.swap_positions(from_row, from_col, to_row, to_col):
				character_swapped.emit(Vector2i(from_row, from_col), Vector2i(to_row, to_col))


func cancel_drag() -> void:
	"""Cancel current drag operation."""
	_end_drag()


func _end_drag() -> void:
	"""End drag operation and clear highlights."""
	_is_dragging = false
	_drag_source_slot = null

	# Clear all highlights
	for row in range(GameConstants.GRID_ROWS):
		for col in range(GameConstants.GRID_COLS):
			var slot = _get_slot(row, col)
			if slot:
				slot.set_drag_highlight(false)


func _highlight_drop_targets(from_row: int, from_col: int) -> void:
	"""Highlight valid drop target slots."""
	for row in range(GameConstants.GRID_ROWS):
		for col in range(GameConstants.GRID_COLS):
			if row == from_row and col == from_col:
				continue  # Don't highlight source
			var slot = _get_slot(row, col)
			if slot:
				# All slots are valid targets (empty = move, occupied = swap)
				slot.set_drag_highlight(true, true)


# =============================================================================
# UTILITY
# =============================================================================

func _get_slot(row: int, col: int) -> GridSlot:
	"""Get slot at position."""
	if row < 0 or row >= _slots.size():
		return null
	if col < 0 or col >= _slots[row].size():
		return null
	return _slots[row][col]


func get_slot_at(row: int, col: int) -> GridSlot:
	"""Public accessor for slot at position."""
	return _get_slot(row, col)


func resize_slots(new_size: Vector2) -> void:
	"""Resize all slots to new size."""
	for row in range(GameConstants.GRID_ROWS):
		for col in range(GameConstants.GRID_COLS):
			var slot = _get_slot(row, col)
			if slot:
				slot.custom_minimum_size = new_size


func set_interactive(enabled: bool) -> void:
	"""Enable/disable slot interaction."""
	for row in range(GameConstants.GRID_ROWS):
		for col in range(GameConstants.GRID_COLS):
			var slot = _get_slot(row, col)
			if slot:
				slot.set_clickable(enabled)


# =============================================================================
# DIRECT SLOT ACCESS (for replacement popup)
# =============================================================================

func set_slot_character(row: int, col: int, character: CharacterInstance) -> void:
	"""Directly set a slot's character display (without grid binding)."""
	var slot = _get_slot(row, col)
	if slot:
		slot.set_character(character)


func clear_slot(row: int, col: int) -> void:
	"""Clear a slot's display."""
	var slot = _get_slot(row, col)
	if slot:
		slot.set_character(null)


func highlight_slot(row: int, col: int, enabled: bool, is_valid: bool = true) -> void:
	"""Highlight a specific slot."""
	var slot = _get_slot(row, col)
	if slot:
		slot.set_drag_highlight(enabled, is_valid)


func highlight_all_slots(enabled: bool, is_valid: bool = true) -> void:
	"""Highlight all slots."""
	for row in range(GameConstants.GRID_ROWS):
		for col in range(GameConstants.GRID_COLS):
			var slot = _get_slot(row, col)
			if slot:
				slot.set_drag_highlight(enabled, is_valid)
