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
signal character_healed(target: CombatCharacter, amount: float, source: CombatCharacter, is_crit: bool)
signal ability_used(source: CombatCharacter, ability: Dictionary, targets: Array)
signal shield_absorbed(target: CombatCharacter, amount: float, shield_remaining: float)

var _state: CombatState = null
var _game_data: Node = null
var _ability_cache: Dictionary = {}
var _ability_overrides: Dictionary = {}  # character_id -> {ability_id -> {params}}
var _triggered_ability_defs: Dictionary = {}  # character_id -> Array[Dictionary]
var _effect_manager: EffectManager = EffectManager.new()


func get_state() -> CombatState:
	return _state


func _get_game_data() -> Node:
	if _game_data != null:
		return _game_data
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
	var gd = _game_data
	if gd == null:
		gd = _get_game_data()
	if gd == null:
		return ["attack_enemy"]
	var char_data: Dictionary = gd.get_character_by_id(character_id)
	if char_data.has("abilities"):
		var result: Array = []
		var overrides: Dictionary = {}
		var triggered_defs: Array = []
		for entry in char_data["abilities"]:
			var parsed = GridBonusCalculator.parse_ability_entry(entry)
			var aid = parsed.get("id", "")
			# Inline triggered ability (no id, has trigger field)
			if aid.is_empty() and parsed.get("type", "") == "triggered":
				triggered_defs.append(parsed)
				continue
			if aid.is_empty():
				continue
			result.append(aid)
			if parsed.size() > 1:
				overrides[aid] = parsed
		if not overrides.is_empty():
			_ability_overrides[character_id] = overrides
		if not triggered_defs.is_empty():
			_triggered_ability_defs[character_id] = triggered_defs
		return result
	return ["attack_enemy"]


func _get_status_effect_data(effect_id: String) -> Dictionary:
	var gd = _game_data
	if gd == null:
		gd = _get_game_data()
	if gd == null:
		return {}
	return gd.get_status_effect(effect_id)


func _lookup_ability(ability_id: String) -> Dictionary:
	if _ability_cache.has(ability_id):
		return _ability_cache[ability_id]
	var gd = _game_data
	if gd == null:
		gd = _get_game_data()
	if gd == null:
		return {}
	var ability = gd.get_ability(ability_id)
	if not ability.is_empty():
		_ability_cache[ability_id] = ability
	return ability


func initialize_combat(player_grid: CharacterGrid, opponent_grid: CharacterGrid) -> void:
	TickActionRegistry.register_defaults()
	_game_data = _get_game_data()
	_ability_cache.clear()
	_ability_overrides.clear()
	_triggered_ability_defs.clear()
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


func _apply_combat_start_effects(character: CombatCharacter) -> void:
	# Apply passive ability effects
	var char_overrides = _ability_overrides.get(character.source_character_id, {})
	for aid in character.ability_ids:
		var ability = _lookup_ability(aid)
		if ability.is_empty() or ability.get("type", "") != "passive":
			continue
		var params = char_overrides.get(aid, {})
		var passive_id = ability.get("passive_effect", "")
		match passive_id:
			"buff_adjacent_attack":
				_apply_buff_adjacent_attack(character, ability, params)

	# Apply inline triggered abilities (on_ally_crit, etc.)
	var triggered_defs = _triggered_ability_defs.get(character.source_character_id, [])
	for ability_def in triggered_defs:
		var trigger = ability_def.get("trigger", "")
		if trigger.is_empty():
			continue
		_apply_triggered_ability(character, ability_def, trigger)


func _apply_buff_adjacent_attack(source: CombatCharacter, ability: Dictionary, params: Dictionary = {}) -> void:
	var buff_stat = ability.get("buff_stat", "attack_damage_bonus")
	var mod_type = ability.get("buff_modifier_type", "percent")
	var buff_value = float(params.get("buff_value", ability.get("default_buff_value", 0)))
	if buff_value == 0.0:
		return
	var allies = _state.board.get_adjacent_allies(source)
	for ally in allies:
		var effect = CombatEffect.create_stat_modifier(
			"character", source.id, buff_stat, buff_value, mod_type, "combat"
		)
		effect.tags = ["buff"]
		apply_effect(ally, effect)


func _apply_triggered_ability(source: CombatCharacter, ability: Dictionary, trigger: String) -> void:
	var target_mode = ability.get("target_mode", "self")
	var require_category = ability.get("require_ability_category", "")
	var action_type = ability.get("action", "buff_stat")  # Default to buff_stat for backwards compatibility

	var action = func(data: Dictionary) -> void:
		var targets = CombatTargeting.resolve_targets(source, _state.board, target_mode)
		if require_category != "":
			targets = _filter_targets_by_ability_category(targets, require_category)
		_execute_triggered_action(source, ability, action_type, targets, data)

	var effect = CombatEffect.create_triggered(
		"character", source.id, trigger, action, "combat"
	)
	effect.tags = ["triggered"]
	apply_effect(source, effect)


func _execute_triggered_action(source: CombatCharacter, ability: Dictionary, action_type: String, targets: Array, _data: Dictionary) -> void:
	match action_type:
		"buff_stat":
			_triggered_action_buff_stat(source, ability, targets)
		"deal_damage":
			_triggered_action_deal_damage(source, ability, targets)
		"heal":
			_triggered_action_heal(source, ability, targets)
		"apply_effect":
			_triggered_action_apply_effect(source, ability, targets)


func _triggered_action_buff_stat(source: CombatCharacter, ability: Dictionary, targets: Array) -> void:
	var buff_stat = ability.get("buff_stat", "")
	var mod_type = ability.get("buff_modifier_type", "flat")
	var buff_value = float(ability.get("buff_value", 0))
	if buff_stat.is_empty():
		return
	for target in targets:
		var effect = CombatEffect.create_stat_modifier(
			"character", source.id, buff_stat, buff_value, mod_type, "permanent"
		)
		effect.tags = ["buff"]
		apply_effect(target, effect)


func _triggered_action_deal_damage(source: CombatCharacter, ability: Dictionary, targets: Array) -> void:
	var damage_value: float
	var damage_from = ability.get("damage_from", "")
	if damage_from != "":
		damage_value = source.get_stat_value(damage_from)
	else:
		damage_value = float(ability.get("damage_value", 0))
	if damage_value <= 0:
		return
	for target in targets:
		_execute_damage(source, target, damage_value)


func _triggered_action_heal(source: CombatCharacter, ability: Dictionary, targets: Array) -> void:
	var heal_value: float
	var heal_from = ability.get("heal_from", "")
	if heal_from != "":
		heal_value = source.get_stat_value(heal_from)
	else:
		heal_value = float(ability.get("heal_value", 0))
	if heal_value <= 0:
		return
	for target in targets:
		heal_character(target, heal_value, source, false)


func _triggered_action_apply_effect(source: CombatCharacter, ability: Dictionary, targets: Array) -> void:
	var effect_id = ability.get("applies_effect", "")
	if effect_id == "":
		return
	var template = _get_status_effect_data(effect_id)
	if template.is_empty():
		return
	var overrides = _build_triggered_effect_overrides(source, ability)
	for target in targets:
		var effect = StatusEffectFactory.create_from_template(template, source.id, overrides)
		apply_effect(target, effect)


func _build_triggered_effect_overrides(source: CombatCharacter, ability: Dictionary) -> Dictionary:
	var overrides = {}
	var stacks_from = ability.get("stacks_from", "")
	if stacks_from != "":
		overrides["stacks"] = int(source.get_stat_value(stacks_from))
	var duration_from = ability.get("duration_from", "")
	if duration_from != "":
		overrides["duration_value"] = source.get_stat_value(duration_from)
	return overrides


func _filter_targets_by_ability_category(targets: Array, category: String) -> Array:
	var result: Array = []
	for target in targets:
		if _character_has_ability_category(target, category):
			result.append(target)
	return result


func _character_has_ability_category(character: CombatCharacter, category: String) -> bool:
	for aid in character.ability_ids:
		var ability = _lookup_ability(aid)
		if not ability.is_empty() and ability.get("category", "") == category:
			return true
	return false


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

	# Check if any characters waiting for charges now have charges
	for character in all_living:
		if character.waiting_for_charge and character.charges != 0:
			character.waiting_for_charge = false
			character.cooldown_remaining = character.speed
			if character.charges > 0:
				character.charges -= 1
			_execute_character_action(character)

	_check_win_condition()


func _execute_character_action(character: CombatCharacter) -> void:
	character_cooldown_triggered.emit(character)

	# Process on_cooldown triggered effects
	_process_triggered_effects(character, "on_cooldown", {character = character})

	# Process on_front_ally_strike for back-row ally when front-row character acts
	if character.row == GameConstants.ROW_FRONT:
		var back_ally = _state.board.get_character_at(character.team, GameConstants.ROW_BACK, character.column)
		if back_ally and back_ally.is_alive:
			_process_triggered_effects(back_ally, "on_front_ally_strike", {
				front_ally = character,
				character = back_ally
			})

	for aid in character.ability_ids:
		var ability = _lookup_ability(aid)
		if not ability.is_empty():
			_execute_ability(character, ability)

	var multistrike_count = int(character.get_stat_value("multistrike_value"))
	for _strike in range(multistrike_count):
		if not character.is_alive:
			break
		for aid in character.ability_ids:
			var ability = _lookup_ability(aid)
			if not ability.is_empty():
				_execute_ability(character, ability)


func _execute_ability(character: CombatCharacter, ability: Dictionary) -> void:
	if ability.get("type", "") in ["passive", "triggered"]:
		return
	var context = {
		"board": _state.board,
		"deal_damage": _execute_damage,
		"heal": heal_character,
		"apply_effect": apply_effect,
		"get_status_effect": _get_status_effect_data,
	}
	var target_mode = ability.get("target_mode", "enemy_single")
	var targets = CombatTargeting.resolve_targets(character, _state.board, target_mode)
	if not targets.is_empty():
		ability_used.emit(character, ability, targets)
	AbilityExecutor.execute(character, ability, context)


func _execute_damage(source, target: CombatCharacter, base_damage: float, damage_type: String = "") -> void:
	var result = DamageResolver.resolve(source, target, base_damage)

	if result.blocked:
		damage_blocked.emit(source, target)

	# Shield absorption: absorb damage from attacks and burn (but not poison)
	var is_shieldable = source is CombatCharacter or damage_type == "burn"
	if is_shieldable and target.has_effect("shield"):
		var shield_effect = target.get_effect("shield")
		var absorbed = min(shield_effect.stacks, result.damage)
		shield_effect.stacks -= absorbed
		result.damage -= absorbed
		shield_absorbed.emit(target, absorbed, shield_effect.stacks)
		if shield_effect.stacks <= 0:
			_remove_effect(target, shield_effect)
		if result.damage <= 0:
			return

	_apply_damage(target, result.damage, source)
	damage_dealt.emit(source, target, result.damage, result.is_crit)

	# Process on_ally_crit triggers for all living allies of the source
	if result.is_crit and source is CombatCharacter:
		for ally in _state.board.get_living_characters_on_team(source.team):
			_process_triggered_effects(ally, "on_ally_crit", {source = source, target = target})


func _apply_damage(target: CombatCharacter, amount: float, source: CombatCharacter) -> void:
	if not target.is_alive:
		return

	target.health -= amount
	_state.last_damage_time = _state.elapsed_time
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
	var enemy_team = GameConstants.get_enemy_team(character.team)
	for enemy in _state.board.get_living_characters_on_team(enemy_team):
		_process_triggered_effects(enemy, "on_enemy_death", {dead_character = character})

	# Clear effects on this character
	character.effects.clear()


func _check_win_condition() -> void:
	if _state == null or not _state.combat_active:
		return

	var player_alive = _state.board.has_living_characters(GameConstants.TEAM_PLAYER)
	var opponent_alive = _state.board.has_living_characters(GameConstants.TEAM_OPPONENT)

	# Check stalemate: draw if no damage dealt for 10 seconds
	if player_alive and opponent_alive:
		if _state.elapsed_time - _state.last_damage_time >= 10.0:
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



# =============================================================================
# EFFECT MANAGEMENT
# =============================================================================


func apply_effect(target: CombatCharacter, effect_to_apply: CombatEffect) -> void:
	var result = _effect_manager.apply_effect(target, effect_to_apply)
	effect_applied.emit(target, effect_to_apply)
	if result.trigger_id != "":
		var active_effect: CombatEffect
		if result.merged:
			active_effect = target.get_effect(result.trigger_id)
			_effect_manager.process_triggered_effects(target, "on_" + result.trigger_id, {target = target, effect = active_effect})
		else:
			active_effect = effect_to_apply
			_effect_manager.process_triggered_effects(target, "on_" + result.trigger_id, {target = target, effect = active_effect})

		# Process on_ally_<effect_id> triggers for all living allies
		for ally in _state.board.get_living_characters_on_team(target.team):
			_process_triggered_effects(ally, "on_ally_" + result.trigger_id, {target = target, effect = active_effect})

		# Process on_enemy_<effect_id> triggers for all living enemies
		var enemy_team = GameConstants.get_enemy_team(target.team)
		for enemy in _state.board.get_living_characters_on_team(enemy_team):
			_process_triggered_effects(enemy, "on_enemy_" + result.trigger_id, {target = target, effect = active_effect})

		# Invoke on_apply callback if present
		if active_effect != null and active_effect.on_apply.is_valid():
			var apply_context = {
				"character": target,
				"effect": active_effect,
				"manager_context": {
					"deal_damage": _execute_damage,
					"heal": heal_character,
					"apply_effect": apply_effect,
					"board": _state.board,
				}
			}
			active_effect.on_apply.call(apply_context)


func _remove_effect(target: CombatCharacter, effect_to_remove: CombatEffect) -> void:
	_effect_manager.remove_effect(target, effect_to_remove)
	effect_removed.emit(target, effect_to_remove)


func _process_triggered_effects(character: CombatCharacter, trigger: String, data: Dictionary) -> void:
	_effect_manager.process_triggered_effects(character, trigger, data)


func _remove_effects_from_source(source_id: String) -> void:
	var all_chars = _get_all_characters()
	var removed_pairs = _effect_manager.remove_effects_from_source(source_id, all_chars)
	for pair in removed_pairs:
		effect_removed.emit(pair.target, pair.effect)


func cleanse_effects_by_tag(target: CombatCharacter, tag: String) -> Array:
	var removed = _effect_manager.cleanse_effects_by_tag(target, tag)
	for effect in removed:
		effect_removed.emit(target, effect)
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


func heal_character(target: CombatCharacter, amount: float, source: CombatCharacter, is_crit: bool = false) -> void:
	if not target.is_alive:
		return
	var actual = min(amount, target.max_health - target.health)
	target.health += actual

	# Process on_heal triggered effects
	_process_triggered_effects(target, "on_heal", {target = target, amount = actual, source = source})

	if actual > 0:
		character_healed.emit(target, actual, source, is_crit)

	# Process on_ally_crit triggers for heal crits
	if is_crit and source is CombatCharacter:
		for ally in _state.board.get_living_characters_on_team(source.team):
			_process_triggered_effects(ally, "on_ally_crit", {source = source, target = target})
