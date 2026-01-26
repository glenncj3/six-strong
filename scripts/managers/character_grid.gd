class_name CharacterGrid
extends RefCounted
## Manages a 2x3 grid of characters (6 slots max).
## Grid layout:
##   [0,0] [0,1] [0,2]  <- Front row (row 0)
##   [1,0] [1,1] [1,2]  <- Back row (row 1)
##
## Characters track their own grid_position. This manager owns the grid state
## and ensures consistency between the grid and character positions.

# =============================================================================
# SIGNALS
# =============================================================================

signal character_placed(character: CharacterInstance, row: int, col: int)
signal character_removed(character: CharacterInstance, row: int, col: int)
signal characters_swapped(char_a: CharacterInstance, pos_a: Vector2i, char_b: CharacterInstance, pos_b: Vector2i)
signal grid_changed

# =============================================================================
# CONSTANTS
# =============================================================================

const ROWS := GameConstants.GRID_ROWS  # 2
const COLS := GameConstants.GRID_COLS  # 3
const MAX_CHARACTERS := GameConstants.MAX_GRID_CHARACTERS  # 6

# =============================================================================
# STATE
# =============================================================================

# 2D array: _grid[row][col] = CharacterInstance or null
var _grid: Array = []


# =============================================================================
# INITIALIZATION
# =============================================================================

func _init() -> void:
	_initialize_empty_grid()


func _initialize_empty_grid() -> void:
	"""Create empty 2x3 grid."""
	_grid.clear()
	for row in range(ROWS):
		var row_array: Array = []
		for col in range(COLS):
			row_array.append(null)
		_grid.append(row_array)


func clear() -> void:
	"""Remove all characters from the grid."""
	for row in range(ROWS):
		for col in range(COLS):
			var character = _grid[row][col]
			if character:
				character.clear_grid_position()
			_grid[row][col] = null
	grid_changed.emit()


# =============================================================================
# PLACEMENT OPERATIONS
# =============================================================================

func place_character(character: CharacterInstance, row: int, col: int) -> bool:
	"""
	Place a character in a specific grid slot.

	Args:
		character: The character to place
		row: Grid row (0 = front, 1 = back)
		col: Grid column (0-2)

	Returns:
		True if placement succeeded, false if slot is occupied or invalid
	"""
	if not _is_valid_position(row, col):
		push_error("CharacterGrid: Invalid position (%d, %d)" % [row, col])
		return false

	if not is_slot_empty(row, col):
		push_warning("CharacterGrid: Slot (%d, %d) is already occupied" % [row, col])
		return false

	# If character was previously placed elsewhere, remove from old position
	if character.is_in_grid():
		var old_pos = character.grid_position
		if _grid[old_pos.x][old_pos.y] == character:
			_grid[old_pos.x][old_pos.y] = null

	# Place in new position
	_grid[row][col] = character
	character.set_grid_position(row, col)

	character_placed.emit(character, row, col)
	grid_changed.emit()
	return true


func place_character_in_first_empty(character: CharacterInstance) -> bool:
	"""
	Place a character in the first available empty slot.

	Returns:
		True if placement succeeded, false if grid is full
	"""
	var slot = get_first_empty_slot()
	if slot == Vector2i(-1, -1):
		return false
	return place_character(character, slot.x, slot.y)


func remove_character(row: int, col: int) -> CharacterInstance:
	"""
	Remove a character from a grid slot.

	Args:
		row: Grid row (0-1)
		col: Grid column (0-2)

	Returns:
		The removed character, or null if slot was empty
	"""
	if not _is_valid_position(row, col):
		push_error("CharacterGrid: Invalid position (%d, %d)" % [row, col])
		return null

	var character = _grid[row][col]
	if character == null:
		return null

	_grid[row][col] = null
	character.clear_grid_position()

	character_removed.emit(character, row, col)
	grid_changed.emit()
	return character


func remove_character_instance(character: CharacterInstance) -> bool:
	"""
	Remove a specific character from the grid wherever it is.

	Returns:
		True if character was found and removed, false otherwise
	"""
	if not character.is_in_grid():
		return false

	var pos = character.grid_position
	if _is_valid_position(pos.x, pos.y) and _grid[pos.x][pos.y] == character:
		remove_character(pos.x, pos.y)
		return true

	# Character thinks it's in grid but isn't at expected position - search for it
	for row in range(ROWS):
		for col in range(COLS):
			if _grid[row][col] == character:
				remove_character(row, col)
				return true

	return false


func swap_positions(from_row: int, from_col: int, to_row: int, to_col: int) -> bool:
	"""
	Swap characters between two positions. Works even if one slot is empty.

	Args:
		from_row, from_col: First position
		to_row, to_col: Second position

	Returns:
		True if swap succeeded, false if positions are invalid
	"""
	if not _is_valid_position(from_row, from_col) or not _is_valid_position(to_row, to_col):
		push_error("CharacterGrid: Invalid swap positions")
		return false

	if from_row == to_row and from_col == to_col:
		return true  # Same position, no-op

	var char_a = _grid[from_row][from_col]
	var char_b = _grid[to_row][to_col]

	# Perform swap
	_grid[from_row][from_col] = char_b
	_grid[to_row][to_col] = char_a

	# Update character positions
	if char_a:
		char_a.set_grid_position(to_row, to_col)
	if char_b:
		char_b.set_grid_position(from_row, from_col)

	characters_swapped.emit(char_a, Vector2i(from_row, from_col), char_b, Vector2i(to_row, to_col))
	grid_changed.emit()
	return true


func move_character(from_row: int, from_col: int, to_row: int, to_col: int) -> bool:
	"""
	Move a character to an empty slot.

	Returns:
		True if move succeeded, false if destination is occupied or invalid
	"""
	if not _is_valid_position(from_row, from_col) or not _is_valid_position(to_row, to_col):
		push_error("CharacterGrid: Invalid move positions")
		return false

	if not is_slot_empty(to_row, to_col):
		return false  # Use swap_positions if destination is occupied

	var character = _grid[from_row][from_col]
	if character == null:
		return false  # Nothing to move

	_grid[from_row][from_col] = null
	_grid[to_row][to_col] = character
	character.set_grid_position(to_row, to_col)

	character_placed.emit(character, to_row, to_col)
	grid_changed.emit()
	return true


# =============================================================================
# QUERY OPERATIONS
# =============================================================================

func get_character_at(row: int, col: int) -> CharacterInstance:
	"""Get the character at a specific position, or null if empty."""
	if not _is_valid_position(row, col):
		return null
	return _grid[row][col]


func get_all_characters() -> Array[CharacterInstance]:
	"""Get all characters in the grid (in row-major order)."""
	var characters: Array[CharacterInstance] = []
	for row in range(ROWS):
		for col in range(COLS):
			var character = _grid[row][col]
			if character != null:
				characters.append(character)
	return characters


func get_front_row() -> Array[CharacterInstance]:
	"""Get all characters in the front row (row 0)."""
	var characters: Array[CharacterInstance] = []
	for col in range(COLS):
		var character = _grid[0][col]
		if character != null:
			characters.append(character)
	return characters


func get_back_row() -> Array[CharacterInstance]:
	"""Get all characters in the back row (row 1)."""
	var characters: Array[CharacterInstance] = []
	for col in range(COLS):
		var character = _grid[1][col]
		if character != null:
			characters.append(character)
	return characters


func get_empty_slots() -> Array[Vector2i]:
	"""Get all empty slot positions."""
	var empty: Array[Vector2i] = []
	for row in range(ROWS):
		for col in range(COLS):
			if _grid[row][col] == null:
				empty.append(Vector2i(row, col))
	return empty


func get_first_empty_slot() -> Vector2i:
	"""
	Get the first empty slot position (row-major order).

	Returns:
		Vector2i position, or Vector2i(-1, -1) if grid is full
	"""
	for row in range(ROWS):
		for col in range(COLS):
			if _grid[row][col] == null:
				return Vector2i(row, col)
	return Vector2i(-1, -1)


func is_slot_empty(row: int, col: int) -> bool:
	"""Check if a slot is empty."""
	if not _is_valid_position(row, col):
		return false
	return _grid[row][col] == null


func is_full() -> bool:
	"""Check if all grid slots are occupied."""
	return get_character_count() >= MAX_CHARACTERS


func is_empty() -> bool:
	"""Check if the grid has no characters."""
	return get_character_count() == 0


func get_character_count() -> int:
	"""Get the number of characters in the grid."""
	var count = 0
	for row in range(ROWS):
		for col in range(COLS):
			if _grid[row][col] != null:
				count += 1
	return count


func has_character(character: CharacterInstance) -> bool:
	"""Check if a specific character is in the grid."""
	for row in range(ROWS):
		for col in range(COLS):
			if _grid[row][col] == character:
				return true
	return false


# =============================================================================
# SERIALIZATION
# =============================================================================

func to_dict() -> Dictionary:
	"""Serialize grid to dictionary for saving."""
	var grid_data: Array = []
	for row in range(ROWS):
		var row_data: Array = []
		for col in range(COLS):
			var character = _grid[row][col]
			if character:
				row_data.append(character.to_dict())
			else:
				row_data.append(null)
		grid_data.append(row_data)

	return {
		"grid": grid_data,
		"rows": ROWS,
		"cols": COLS
	}


static func from_dict(data: Dictionary, game_data = null):
	"""Deserialize grid from dictionary (for loading saves)."""
	var script = load("res://scripts/managers/character_grid.gd")
	var grid = script.new()

	var grid_data = data.get("grid", [])
	var rows = mini(data.get("rows", ROWS), ROWS)
	var cols = mini(data.get("cols", COLS), COLS)

	for row in range(rows):
		if row >= grid_data.size():
			break
		var row_data = grid_data[row]
		for col in range(cols):
			if col >= row_data.size():
				break
			var char_data = row_data[col]
			if char_data != null and char_data is Dictionary:
				var character = CharacterInstance.from_dict(char_data, game_data)
				if character:
					grid._grid[row][col] = character
					character.set_grid_position(row, col)

	return grid


# =============================================================================
# HELPERS
# =============================================================================

func _is_valid_position(row: int, col: int) -> bool:
	"""Check if a position is within grid bounds."""
	return row >= 0 and row < ROWS and col >= 0 and col < COLS


func get_grid_dimensions() -> Vector2i:
	"""Get grid dimensions (rows, cols)."""
	return Vector2i(ROWS, COLS)
