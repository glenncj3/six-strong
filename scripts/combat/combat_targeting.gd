class_name CombatTargeting
extends RefCounted
## Static targeting utilities for combat.


static func get_valid_enemy_targets(actor: CombatCharacter, board: CombatBoard) -> Array:
	var enemy_team = GameConstants.TEAM_OPPONENT if actor.team == GameConstants.TEAM_PLAYER else GameConstants.TEAM_PLAYER

	# Front row priority
	var front = board.get_living_characters(enemy_team, GameConstants.ROW_FRONT)
	var back = board.get_living_characters(enemy_team, GameConstants.ROW_BACK)

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


static func select_enemy_target(actor: CombatCharacter, board: CombatBoard) -> CombatCharacter:
	var targets = get_valid_enemy_targets(actor, board)
	if targets.is_empty():
		return null
	return targets[randi() % targets.size()]


static func get_valid_ally_targets(actor: CombatCharacter, board: CombatBoard, include_self: bool = false) -> Array:
	var front = board.get_living_characters(actor.team, GameConstants.ROW_FRONT)
	var back = board.get_living_characters(actor.team, GameConstants.ROW_BACK)

	if not include_self:
		front = front.filter(func(ch): return ch != actor)
		back = back.filter(func(ch): return ch != actor)

	var target_pool: Array
	if front.size() > 0:
		target_pool = front
	elif back.size() > 0:
		target_pool = back
	else:
		return []

	var min_dist := GameConstants.MAX_GRID_CHARACTERS + 1
	for ch in target_pool:
		var dist = abs(ch.column - actor.column)
		if dist < min_dist:
			min_dist = dist

	var result: Array = []
	for ch in target_pool:
		if abs(ch.column - actor.column) == min_dist:
			result.append(ch)
	return result


static func select_ally_target(actor: CombatCharacter, board: CombatBoard, include_self: bool = false) -> CombatCharacter:
	var targets = get_valid_ally_targets(actor, board, include_self)
	if targets.is_empty():
		return null
	return targets[randi() % targets.size()]


static func get_column_distance(col_a: int, col_b: int) -> int:
	return abs(col_a - col_b)
