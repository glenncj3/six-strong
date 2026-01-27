class_name CombatManager
extends Node
## Real-time combat manager. Drives the cooldown-based combat loop via _process(delta).

signal combat_started(state: CombatState)
signal combat_ended(winner: int, reason: String)
signal character_cooldown_triggered(character: CombatCharacter)
signal damage_dealt(source: CombatCharacter, target: CombatCharacter, amount: float, is_crit: bool)
signal damage_blocked(source: CombatCharacter, target: CombatCharacter)
signal damage_taken(target: CombatCharacter, amount: float, source: CombatCharacter)
signal character_died(character: CombatCharacter)
signal effect_applied(target: CombatCharacter, effect: CombatEffect)
signal effect_removed(target: CombatCharacter, effect: CombatEffect)
signal character_healed(target: CombatCharacter, amount: float, source: CombatCharacter)

var _state: CombatState = null


func get_state() -> CombatState:
	return _state


func initialize_combat(player_grid: CharacterGrid, opponent_grid: CharacterGrid) -> void:
	_state = CombatState.new()
	_state.board = CombatBoard.new()
	_state.elapsed_time = 0.0
	_state.combat_active = true
	_state.winner = null

	# Clone player characters
	for row in range(GameConstants.GRID_ROWS):
		for col in range(GameConstants.GRID_COLS):
			var ch = player_grid.get_character_at(row, col)
			if ch != null:
				var cc = CombatCharacter.create_from_character(ch, GameConstants.TEAM_PLAYER, row, col)
				_state.board.set_character_at(GameConstants.TEAM_PLAYER, row, col, cc)

	# Clone opponent characters
	for row in range(GameConstants.GRID_ROWS):
		for col in range(GameConstants.GRID_COLS):
			var ch = opponent_grid.get_character_at(row, col)
			if ch != null:
				var cc = CombatCharacter.create_from_character(ch, GameConstants.TEAM_OPPONENT, row, col)
				_state.board.set_character_at(GameConstants.TEAM_OPPONENT, row, col, cc)

	# Apply combat-start effects from items/skills
	for character in _state.board.get_all_living_characters():
		_apply_combat_start_effects(character)

	combat_started.emit(_state)


func _apply_combat_start_effects(_character: CombatCharacter) -> void:
	# TODO: Apply effects from items and skills equipped on the source character.
	# Each item/skill that grants combat effects should create CombatEffect instances
	# and apply them here via apply_effect().
	pass


func _process(delta: float) -> void:
	if _state == null or not _state.combat_active:
		return
	_update_combat(delta)


func _update_combat(delta: float) -> void:
	_state.elapsed_time += delta

	var all_living = _state.board.get_all_living_characters()
	for character in all_living:
		_update_character(character, delta)

	_update_effects(delta)
	_check_win_condition()


func _update_character(character: CombatCharacter, delta: float) -> void:
	if not character.has_speed():
		return

	character.cooldown_remaining -= delta
	if character.cooldown_remaining <= 0:
		_execute_character_action(character)
		character.cooldown_remaining = character.speed
		_decrement_cooldown_effects(character)


func _execute_character_action(character: CombatCharacter) -> void:
	character_cooldown_triggered.emit(character)

	# Process on_cooldown triggered effects
	_process_triggered_effects(character, "on_cooldown", {character = character})

	if character.has_damage():
		var target = CombatTargeting.select_enemy_target(character, _state.board)
		if target != null:
			_execute_damage(character, target, character.damage)


func _execute_damage(source: CombatCharacter, target: CombatCharacter, base_damage: float) -> void:
	# Block check
	if target.defend_rate > 0:
		if randf() < target.defend_rate:
			damage_blocked.emit(source, target)
			return

	# Crit check
	var final_damage = base_damage
	var is_crit = false
	if source.crit_chance > 0:
		if randf() < source.crit_chance:
			final_damage = base_damage * GameConstants.CRIT_MULTIPLIER
			is_crit = true

	_apply_damage(target, final_damage, source)
	damage_dealt.emit(source, target, final_damage, is_crit)


func _apply_damage(target: CombatCharacter, amount: float, source: CombatCharacter) -> void:
	if not target.is_alive:
		return

	target.health -= amount
	damage_taken.emit(target, amount, source)

	# Process on_damage_taken triggered effects
	_process_triggered_effects(target, "on_damage_taken", {target = target, amount = amount, source = source})

	if target.health <= 0:
		target.health = 0
		_kill_character(target)


func _kill_character(character: CombatCharacter) -> void:
	character.is_alive = false
	character_died.emit(character)

	# Process on_death triggers on the dying character itself
	_process_triggered_effects(character, "on_death", {character = character})

	# Process on_ally_death triggers for living allies
	for ally in _state.board.get_living_characters_on_team(character.team):
		_process_triggered_effects(ally, "on_ally_death", {dead_character = character})

	# Process on_enemy_death triggers for living enemies
	var enemy_team = GameConstants.TEAM_OPPONENT if character.team == GameConstants.TEAM_PLAYER else GameConstants.TEAM_PLAYER
	for enemy in _state.board.get_living_characters_on_team(enemy_team):
		_process_triggered_effects(enemy, "on_enemy_death", {dead_character = character})

	# Remove effects sourced from this character
	_remove_effects_from_source(character.id)

	# Clear effects on this character
	character.effects.clear()


func _check_win_condition() -> void:
	if _state == null or not _state.combat_active:
		return

	var player_alive = _state.board.has_living_characters(GameConstants.TEAM_PLAYER)
	var opponent_alive = _state.board.has_living_characters(GameConstants.TEAM_OPPONENT)

	# Check stalemate
	if player_alive and opponent_alive:
		if _is_stalemate():
			_state.combat_active = false
			_state.winner = GameConstants.WINNER_DRAW
			combat_ended.emit(GameConstants.WINNER_DRAW, "stalemate")
		return

	if player_alive and not opponent_alive:
		_state.combat_active = false
		_state.winner = GameConstants.TEAM_PLAYER
		combat_ended.emit(GameConstants.TEAM_PLAYER, "elimination")
	elif opponent_alive and not player_alive:
		_state.combat_active = false
		_state.winner = GameConstants.TEAM_OPPONENT
		combat_ended.emit(GameConstants.TEAM_OPPONENT, "elimination")
	elif not player_alive and not opponent_alive:
		_state.combat_active = false
		_state.winner = GameConstants.WINNER_DRAW
		combat_ended.emit(GameConstants.WINNER_DRAW, "mutual_kill")


func _is_stalemate() -> bool:
	for character in _state.board.get_all_living_characters():
		if character.has_damage() and character.has_speed():
			return false
		if _has_damage_dealing_effects(character):
			return false
	return true


func _has_damage_dealing_effects(character: CombatCharacter) -> bool:
	for effect in character.effects:
		if effect.effect_type == "triggered" and effect.trigger == "on_cooldown":
			return true
	return false


# =============================================================================
# EFFECT MANAGEMENT
# =============================================================================

func _update_effects(delta: float) -> void:
	for character in _get_all_characters():
		var to_remove: Array = []
		for effect in character.effects:
			if effect.duration_type == "seconds":
				effect.duration_value -= delta
				if effect.duration_value <= 0:
					to_remove.append(effect)
		for effect in to_remove:
			_remove_effect(character, effect)


func _decrement_cooldown_effects(character: CombatCharacter) -> void:
	var to_remove: Array = []
	for effect in character.effects:
		if effect.duration_type == "cooldowns":
			effect.duration_value -= 1
			if effect.duration_value <= 0:
				to_remove.append(effect)
	for effect in to_remove:
		_remove_effect(character, effect)


func apply_effect(target: CombatCharacter, effect_to_apply: CombatEffect) -> void:
	target.effects.append(effect_to_apply)
	if effect_to_apply.effect_type == "stat_modifier":
		target.recalculate_stats()
	effect_applied.emit(target, effect_to_apply)


func _remove_effect(target: CombatCharacter, effect_to_remove: CombatEffect) -> void:
	target.effects.erase(effect_to_remove)
	if effect_to_remove.effect_type == "stat_modifier":
		target.recalculate_stats()
	effect_removed.emit(target, effect_to_remove)


func _process_triggered_effects(character: CombatCharacter, trigger: String, data: Dictionary) -> void:
	for effect in character.effects:
		if effect.effect_type == "triggered" and effect.trigger == trigger:
			if effect.action.is_valid():
				effect.action.call(data)


func _remove_effects_from_source(source_id: String) -> void:
	# Remove effects on all characters that came from this source
	var all_chars = _get_all_characters()
	for character in all_chars:
		var to_remove: Array = []
		for effect in character.effects:
			if effect.source_id == source_id:
				to_remove.append(effect)
		for effect in to_remove:
			_remove_effect(character, effect)


func _get_all_characters() -> Array:
	var result: Array = []
	for ch in _state.board.player_characters:
		if ch != null:
			result.append(ch)
	for ch in _state.board.opponent_characters:
		if ch != null:
			result.append(ch)
	return result


func heal_character(target: CombatCharacter, amount: float, source: CombatCharacter) -> void:
	if not target.is_alive:
		return
	var actual = min(amount, target.max_health - target.health)
	target.health += actual

	# Process on_heal triggered effects
	_process_triggered_effects(target, "on_heal", {target = target, amount = actual, source = source})

	if actual > 0:
		character_healed.emit(target, actual, source)
