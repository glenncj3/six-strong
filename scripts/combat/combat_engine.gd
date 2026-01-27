class_name CombatEngine
extends RefCounted
## Pure logic engine for auto-battle combat.
## Takes two CharacterGrids, simulates turn-based combat step by step.

signal turn_executed(result: Dictionary)
signal combat_finished(player_won: bool)

var _player_grid: CharacterGrid
var _enemy_grid: CharacterGrid
var _turn_order: Array = []  # Array of {character, is_player}
var _current_turn_index: int = 0
var _is_finished: bool = false
var _player_won: bool = false


func start(player_grid: CharacterGrid, enemy_grid: CharacterGrid) -> void:
	_player_grid = player_grid
	_enemy_grid = enemy_grid
	_is_finished = false
	_player_won = false
	_current_turn_index = 0
	_build_turn_order()


func _build_turn_order() -> void:
	"""Build turn order from all living characters sorted by speed (descending)."""
	_turn_order.clear()
	for ch in _player_grid.get_all_characters():
		if ch.is_alive():
			_turn_order.append({"character": ch, "is_player": true})
	for ch in _enemy_grid.get_all_characters():
		if ch.is_alive():
			_turn_order.append({"character": ch, "is_player": false})
	_turn_order.sort_custom(func(a, b): return a["character"].speed > b["character"].speed)


func execute_next_turn() -> Dictionary:
	"""Execute one turn. Returns result dict or empty if combat is over."""
	if _is_finished:
		return {}

	# Skip dead characters and find next living one
	var entry = _find_next_living()
	if entry.is_empty():
		_finish_combat()
		return {}

	var attacker: CharacterInstance = entry["character"]
	var is_player: bool = entry["is_player"]
	var target_grid = _enemy_grid if is_player else _player_grid

	# Pick target: front row first, then back row, random within row
	var target = _pick_target(target_grid)
	if target == null:
		# No targets = combat over
		_finish_combat()
		return {}

	# Calculate damage
	var was_blocked = randf() * 100.0 < target.defend_rate
	var was_crit = not was_blocked and randf() * 100.0 < attacker.crit_chance
	var final_damage = 0
	if not was_blocked:
		final_damage = attacker.damage
		if was_crit:
			final_damage = int(final_damage * 1.5)

	target.take_damage(final_damage)
	var defender_died = not target.is_alive()

	var result = {
		"attacker": attacker,
		"attacker_is_player": is_player,
		"defender": target,
		"damage": final_damage,
		"was_crit": was_crit,
		"was_blocked": was_blocked,
		"defender_died": defender_died,
	}

	turn_executed.emit(result)

	# Check win/loss
	if _all_dead(_enemy_grid):
		_player_won = true
		_is_finished = true
		combat_finished.emit(true)
	elif _all_dead(_player_grid):
		_player_won = false
		_is_finished = false  # will be set in next call
		_is_finished = true
		combat_finished.emit(false)

	return result


func _find_next_living() -> Dictionary:
	"""Find the next living character in turn order, rebuilding if needed."""
	# If we've gone through everyone, rebuild for next round
	if _current_turn_index >= _turn_order.size():
		_build_turn_order()
		_current_turn_index = 0

	while _current_turn_index < _turn_order.size():
		var entry = _turn_order[_current_turn_index]
		_current_turn_index += 1
		if entry["character"].is_alive():
			return entry

	# Everyone dead - shouldn't normally reach here
	return {}


func _pick_target(grid: CharacterGrid) -> CharacterInstance:
	"""Pick a target: living front row first (random), then back row."""
	var front = grid.get_front_row().filter(func(c): return c.is_alive())
	if front.size() > 0:
		return front[randi() % front.size()]
	var back = grid.get_back_row().filter(func(c): return c.is_alive())
	if back.size() > 0:
		return back[randi() % back.size()]
	return null


func _all_dead(grid: CharacterGrid) -> bool:
	for ch in grid.get_all_characters():
		if ch.is_alive():
			return false
	return true


func _finish_combat() -> void:
	if _is_finished:
		return
	_player_won = not _all_dead(_player_grid)
	_is_finished = true
	combat_finished.emit(_player_won)


func is_combat_over() -> bool:
	return _is_finished


func did_player_win() -> bool:
	return _player_won
