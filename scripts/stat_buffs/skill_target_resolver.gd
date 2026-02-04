class_name SkillTargetResolver
extends RefCounted
## Resolves target_mode + drop_target into actual CharacterInstance array.
## Used by stat buff effects to determine which characters receive modifications.
##
## Target modes describe WHAT gets affected, using the drop target as reference:
##   - "dropped": Only the dropped-on character
##   - "all": All team members (drop target ignored)
##   - "all_except_dropped": All except dropped-on character
##   - "row_of_dropped": Same row as dropped character
##   - "adjacent_to_dropped": Adjacent to dropped character
##
## Usage:
##   var targets = SkillTargetResolver.resolve("dropped", drop_target, context)

# Grid constants (matching CharacterGrid)
const ROWS := 2
const COLS := 3


# =============================================================================
# RESOLUTION
# =============================================================================

static func resolve(target_mode: String, drop_target, context) -> Array:
	"""
	Resolve target mode to actual characters.

	Args:
		target_mode: How to select targets ("dropped", "all", etc.)
		drop_target: CharacterInstance that was dropped on (may be null for "all")
		context: SkillContext with team access

	Returns:
		Array of CharacterInstance to affect
	"""
	var all_characters = context.get_all_characters()

	match target_mode:
		"dropped":
			return _resolve_dropped(drop_target)
		"all":
			return all_characters
		"all_except_dropped":
			return _resolve_all_except(drop_target, all_characters)
		"row_of_dropped":
			return _resolve_row(drop_target, all_characters)
		"adjacent_to_dropped":
			return _resolve_adjacent(drop_target, all_characters)
		_:
			push_warning("SkillTargetResolver: Unknown target_mode '%s', defaulting to dropped" % target_mode)
			return _resolve_dropped(drop_target)


static func _resolve_dropped(drop_target) -> Array:
	"""Return only the dropped-on character."""
	if drop_target == null:
		push_warning("SkillTargetResolver: 'dropped' mode requires a drop target")
		return []
	return [drop_target]


static func _resolve_all_except(drop_target, all_characters: Array) -> Array:
	"""Return all characters except the dropped-on one."""
	if drop_target == null:
		return all_characters
	var result: Array = []
	for character in all_characters:
		if character != drop_target:
			result.append(character)
	return result


static func _resolve_row(drop_target, all_characters: Array) -> Array:
	"""Return all characters in the same row as the dropped-on character."""
	if drop_target == null:
		push_warning("SkillTargetResolver: 'row_of_dropped' mode requires a drop target")
		return []

	if not drop_target.is_in_grid():
		# Character not in grid, just return the character itself
		return [drop_target]

	var target_row = drop_target.grid_position.x
	var result: Array = []

	for character in all_characters:
		if character.is_in_grid() and character.grid_position.x == target_row:
			result.append(character)

	return result


static func _resolve_adjacent(drop_target, all_characters: Array) -> Array:
	"""Return all characters adjacent to the dropped-on character."""
	if drop_target == null:
		push_warning("SkillTargetResolver: 'adjacent_to_dropped' mode requires a drop target")
		return []

	if not drop_target.is_in_grid():
		# Character not in grid, no adjacency
		return []

	var target_pos = drop_target.grid_position
	var adjacent_positions = _get_adjacent_positions(target_pos)
	var result: Array = []

	for character in all_characters:
		if character == drop_target:
			continue
		if character.is_in_grid() and character.grid_position in adjacent_positions:
			result.append(character)

	return result


static func _get_adjacent_positions(pos: Vector2i) -> Array[Vector2i]:
	"""Get all valid adjacent positions (orthogonal only)."""
	var candidates: Array[Vector2i] = [
		Vector2i(pos.x - 1, pos.y),  # Above
		Vector2i(pos.x + 1, pos.y),  # Below
		Vector2i(pos.x, pos.y - 1),  # Left
		Vector2i(pos.x, pos.y + 1),  # Right
	]

	var valid: Array[Vector2i] = []
	for candidate in candidates:
		if candidate.x >= 0 and candidate.x < ROWS and candidate.y >= 0 and candidate.y < COLS:
			valid.append(candidate)

	return valid


# =============================================================================
# DESCRIPTION
# =============================================================================

static func get_mode_description(target_mode: String) -> String:
	"""
	Get a human-readable description of a target mode.

	Args:
		target_mode: The target mode identifier

	Returns:
		Description string for UI display
	"""
	match target_mode:
		"dropped":
			return "target character"
		"all":
			return "all characters"
		"all_except_dropped":
			return "all other characters"
		"row_of_dropped":
			return "characters in the same row"
		"adjacent_to_dropped":
			return "adjacent characters"
		_:
			return target_mode


static func requires_drop_target(target_mode: String) -> bool:
	"""
	Check if a target mode requires a drop target.

	Args:
		target_mode: The target mode identifier

	Returns:
		True if the mode needs a drop target, false otherwise
	"""
	match target_mode:
		"all":
			return false
		_:
			return true
