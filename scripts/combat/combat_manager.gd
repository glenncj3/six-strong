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


func _get_game_data() -> Node:
	var tree = get_tree()
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		var gd_node = tree.root.get_node_or_null("GameData")
		if gd_node:
			return gd_node
	push_warning("CombatManager: GameData autoload not available")
	return null


func _lookup_ability_ids(character_id: String) -> Array:
	var gd = _get_game_data()
	if gd == null:
		return ["attack_enemy"]
	var char_data: Dictionary = gd.get_character_by_id(character_id)
	# Support both "abilities" (array) and "ability" (single string, backward-compat)
	if char_data.has("abilities"):
		var result: Array = []
		for a in char_data["abilities"]:
			result.append(a)
		return result
	var single = char_data.get("ability", "attack_enemy")
	return [single]


func _get_status_effect_data(effect_id: String) -> Dictionary:
	var gd = _get_game_data()
	if gd == null:
		return {}
	return gd.get_status_effect(effect_id)


func _lookup_ability(ability_id: String) -> Dictionary:
	var gd = _get_game_data()
	if gd == null:
		return {}
	return gd.get_ability(ability_id)


func initialize_combat(player_grid: CharacterGrid, opponent_grid: CharacterGrid) -> void:
	TickActionRegistry.register_defaults()
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
				var aids = _lookup_ability_ids(ch.base_character_id)
				var cc = CombatCharacter.create_from_character(ch, GameConstants.TEAM_PLAYER, row, col, aids)
				_state.board.set_character_at(GameConstants.TEAM_PLAYER, row, col, cc)

	# Clone opponent characters
	for row in range(GameConstants.GRID_ROWS):
		for col in range(GameConstants.GRID_COLS):
			var ch = opponent_grid.get_character_at(row, col)
			if ch != null:
				var aids = _lookup_ability_ids(ch.base_character_id)
				var cc = CombatCharacter.create_from_character(ch, GameConstants.TEAM_OPPONENT, row, col, aids)
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
		var result = character.update(delta)
		if result["action_ready"]:
			_execute_character_action(character)
		for effect in result["expired_effects"]:
			if character.effects.has(effect):
				_remove_effect(character, effect)
		for effect in result["tick_events"]:
			if character.is_alive and character.effects.has(effect) and effect.on_tick.is_valid():
				var tick_context = {
					"character": character,
					"effect": effect,
					"manager_context": {
						"deal_damage": _execute_damage,
						"heal": heal_character,
						"apply_effect": apply_effect,
						"board": _state.board,
					}
				}
				effect.on_tick.call(tick_context)

	_check_win_condition()


func _execute_character_action(character: CombatCharacter) -> void:
	character_cooldown_triggered.emit(character)

	# Process on_cooldown triggered effects
	_process_triggered_effects(character, "on_cooldown", {character = character})

	for aid in character.ability_ids:
		var ability = _lookup_ability(aid)
		if not ability.is_empty():
			_execute_ability(character, ability)


func _execute_ability(character: CombatCharacter, ability: Dictionary) -> void:
	var context = {
		"board": _state.board,
		"deal_damage": _execute_damage,
		"heal": heal_character,
		"apply_effect": apply_effect,
		"get_status_effect": _get_status_effect_data,
	}
	AbilityExecutor.execute(character, ability, context)


func _execute_damage(source, target: CombatCharacter, base_damage: float) -> void:
	var result = DamageResolver.resolve(source, target, base_damage)

	if result.blocked:
		damage_blocked.emit(source, target)
		return

	# Shield absorption: absorb damage from attacks (source is a CombatCharacter)
	if source is CombatCharacter and target.has_effect("shield"):
		var shield_effect = target.get_effect("shield")
		var absorbed = min(shield_effect.stacks, result.damage)
		shield_effect.stacks -= absorbed
		result.damage -= absorbed
		if shield_effect.stacks <= 0:
			_remove_effect(target, shield_effect)
		if result.damage <= 0:
			return

	_apply_damage(target, result.damage, source)
	damage_dealt.emit(source, target, result.damage, result.is_crit)


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
		if effect.tick_interval > 0 and effect.tags.has("dot"):
			return true
	return false


# =============================================================================
# EFFECT MANAGEMENT
# =============================================================================


func apply_effect(target: CombatCharacter, effect_to_apply: CombatEffect) -> void:
	# Merge logic for status effects with effect_id
	if effect_to_apply.effect_id != "" and effect_to_apply.merge_behavior != "none":
		var existing = target.get_effect(effect_to_apply.effect_id)
		if existing != null:
			match effect_to_apply.merge_behavior:
				"add_stacks":
					existing.stacks += effect_to_apply.stacks
					if existing.max_stacks > 0:
						existing.stacks = min(existing.stacks, existing.max_stacks)
					effect_applied.emit(target, effect_to_apply)
					_process_triggered_effects(target, "on_" + effect_to_apply.effect_id, {target = target, effect = existing})
					return
				"refresh_duration":
					existing.duration_value = effect_to_apply.duration_value
					effect_applied.emit(target, effect_to_apply)
					_process_triggered_effects(target, "on_" + effect_to_apply.effect_id, {target = target, effect = existing})
					return
				"extend_duration":
					existing.duration_value += effect_to_apply.duration_value
					effect_applied.emit(target, effect_to_apply)
					_process_triggered_effects(target, "on_" + effect_to_apply.effect_id, {target = target, effect = existing})
					return

	target.effects.append(effect_to_apply)
	if effect_to_apply.effect_type == "stat_modifier" or effect_to_apply.continuous_modifier != "":
		target.recalculate_stats()
	effect_applied.emit(target, effect_to_apply)

	# Fire on_<effect_id> trigger if applicable
	if effect_to_apply.effect_id != "":
		_process_triggered_effects(target, "on_" + effect_to_apply.effect_id, {target = target, effect = effect_to_apply})


func _remove_effect(target: CombatCharacter, effect_to_remove: CombatEffect) -> void:
	target.effects.erase(effect_to_remove)
	if effect_to_remove.effect_type == "stat_modifier" or effect_to_remove.continuous_modifier != "":
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


func cleanse_effects_by_tag(target: CombatCharacter, tag: String) -> Array:
	var removed = target.cleanse_by_tag(tag)
	var needs_recalc = false
	for effect in removed:
		if effect.effect_type == "stat_modifier" or effect.continuous_modifier != "":
			needs_recalc = true
		effect_removed.emit(target, effect)
	if needs_recalc:
		target.recalculate_stats()
	return removed


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
