class_name CombatTargeting
extends RefCounted
## Static targeting utilities for combat.


static func resolve_targets(source: CombatCharacter, board: CombatBoard, target_mode: String) -> Array:
	match target_mode:
		"self":
			return [source]
		"enemy_single":
			var t = select_enemy_target(source, board)
			return [t] if t != null else []
		"enemy_frontline":
			var enemy_team = GameConstants.get_enemy_team(source.team)
			return _get_row_priority_targets(board, enemy_team)
		"enemy_all":
			var enemy_team = GameConstants.get_enemy_team(source.team)
			return board.get_living_characters_on_team(enemy_team)
		"ally_single":
			var t = select_ally_target(source, board, false)
			return [t] if t != null else []
		"ally_frontline":
			return _get_row_priority_targets(board, source.team)
		"ally_all":
			return board.get_living_characters_on_team(source.team)
		_:
			push_warning("CombatTargeting: Unknown target_mode '%s'" % target_mode)
			return []


static func get_valid_enemy_targets(actor: CombatCharacter, board: CombatBoard) -> Array:
	var enemy_team = GameConstants.get_enemy_team(actor.team)
	return _get_priority_targets(actor, board, enemy_team)


static func select_enemy_target(actor: CombatCharacter, board: CombatBoard) -> CombatCharacter:
	var targets = get_valid_enemy_targets(actor, board)
	if targets.is_empty():
		return null
	return targets[randi() % targets.size()]


static func get_valid_ally_targets(actor: CombatCharacter, board: CombatBoard, include_self: bool = false) -> Array:
	var exclude: Array = [] if include_self else [actor]
	return _get_priority_targets(actor, board, actor.team, exclude)


static func select_ally_target(actor: CombatCharacter, board: CombatBoard, include_self: bool = false) -> CombatCharacter:
	var targets = get_valid_ally_targets(actor, board, include_self)
	if targets.is_empty():
		return null
	return targets[randi() % targets.size()]


static func get_column_distance(col_a: int, col_b: int) -> int:
	return abs(col_a - col_b)


static func _get_row_priority_targets(board: CombatBoard, team: int) -> Array:
	var front = board.get_living_characters(team, GameConstants.ROW_FRONT)
	return front if front.size() > 0 else board.get_living_characters(team, GameConstants.ROW_BACK)


static func _get_priority_targets(actor: CombatCharacter, board: CombatBoard, team: int, exclude: Array = []) -> Array:
	var front = board.get_living_characters(team, GameConstants.ROW_FRONT)
	var back = board.get_living_characters(team, GameConstants.ROW_BACK)

	if exclude.size() > 0:
		front = front.filter(func(ch): return ch not in exclude)
		back = back.filter(func(ch): return ch not in exclude)

	var target_pool: Array
	if front.size() > 0:
		target_pool = front
	elif back.size() > 0:
		target_pool = back
	else:
		return []

	# Find minimum column distance
	var min_dist := GameConstants.MAX_GRID_CHARACTERS + 1
	for ch in target_pool:
		var dist = abs(ch.column - actor.column)
		if dist < min_dist:
			min_dist = dist

	# Return all at minimum distance
	var result: Array = []
	for ch in target_pool:
		if abs(ch.column - actor.column) == min_dist:
			result.append(ch)
	return result
