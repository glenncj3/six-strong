class_name CharacterManager
extends RefCounted
## Owns CharacterGrid and handles character acquisition, replacement, and swapping.
## Extracted from RunManager/RunState for SRP.

const ResultScript = preload("res://scripts/core/result.gd")
const ErrorCodesScript = preload("res://scripts/core/error_codes.gd")
const CharacterGridScript = preload("res://scripts/managers/character_grid.gd")

signal character_acquired(character: CharacterInstance)
signal grid_full_character_pending(character: CharacterInstance)
signal grid_changed

var _grid = null  # CharacterGrid instance
var _pending_character: CharacterInstance = null


func _init() -> void:
	_grid = CharacterGridScript.new()


func get_grid():
	"""Get the underlying CharacterGrid."""
	return _grid


# =============================================================================
# CHARACTER ACQUISITION
# =============================================================================

func acquire_character(char_id: String):
	"""
	Acquire a new character by ID. Places in grid or sets as pending.
	Returns Result with Dictionary containing placement info.
	"""
	var char_instance = CharacterInstance.from_master_data(char_id)
	if not char_instance:
		return ResultScript.err(ErrorCodesScript.INVALID_CHARACTER_ID, "Invalid character: %s" % char_id)

	if _grid.place_character_in_first_empty(char_instance):
		character_acquired.emit(char_instance)
		grid_changed.emit()
		return ResultScript.ok({"placed": true, "grid_full": false, "character": char_instance})
	else:
		_pending_character = char_instance
		grid_full_character_pending.emit(char_instance)
		return ResultScript.ok({"placed": false, "grid_full": true, "character": char_instance})


func add_character(character: CharacterInstance) -> bool:
	"""Add a character to the first empty slot. Returns true if placed."""
	var placed = _grid.place_character_in_first_empty(character)
	if placed:
		grid_changed.emit()
	return placed


func add_character_at(character: CharacterInstance, row: int, col: int) -> bool:
	"""Add a character at a specific grid position."""
	var placed = _grid.place_character(character, row, col)
	if placed:
		grid_changed.emit()
	return placed


# =============================================================================
# PENDING CHARACTER (replacement flow)
# =============================================================================

func get_pending_character() -> CharacterInstance:
	return _pending_character


func cancel_pending_character() -> void:
	_pending_character = null


func replace_character_at(row: int, col: int, new_character: CharacterInstance = null) -> CharacterInstance:
	"""Replace character at position. Uses pending character if new_character is null."""
	var char_to_place = new_character if new_character else _pending_character
	if not char_to_place:
		return null

	var removed = _grid.remove_character(row, col)
	if _grid.place_character(char_to_place, row, col):
		if char_to_place == _pending_character:
			_pending_character = null
		character_acquired.emit(char_to_place)
		grid_changed.emit()
	return removed


# =============================================================================
# GRID OPERATIONS
# =============================================================================

func remove_character(row: int, col: int) -> CharacterInstance:
	var removed = _grid.remove_character(row, col)
	if removed:
		grid_changed.emit()
	return removed


func swap_characters(from_row: int, from_col: int, to_row: int, to_col: int) -> bool:
	var result = _grid.swap_positions(from_row, from_col, to_row, to_col)
	if result:
		grid_changed.emit()
	return result


func get_character_at(row: int, col: int) -> CharacterInstance:
	return _grid.get_character_at(row, col)


func get_all_characters() -> Array:
	return _grid.get_all_characters()


func get_character_count() -> int:
	return _grid.get_character_count()


func is_full() -> bool:
	return _grid.is_full()


func get_first_empty_slot() -> Vector2i:
	return _grid.get_first_empty_slot()


func get_empty_slots() -> Array[Vector2i]:
	return _grid.get_empty_slots()


func get_front_row() -> Array:
	return _grid.get_front_row()


func get_back_row() -> Array:
	return _grid.get_back_row()


func clear() -> void:
	_grid.clear()
	_pending_character = null


# =============================================================================
# SERIALIZATION
# =============================================================================

func to_dict() -> Dictionary:
	return _grid.to_dict()


func load_from_dict(data: Dictionary) -> void:
	_grid = CharacterGridScript.from_dict(data)
