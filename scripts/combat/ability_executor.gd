class_name AbilityExecutor
extends RefCounted
## Strategy registry for ability execution. Maps targeting types to callable strategies.

static var _strategies: Dictionary = {}
static var _registered: bool = false


static func register(targeting: String, strategy: Callable) -> void:
	_strategies[targeting] = strategy


static func has_strategy(targeting: String) -> bool:
	return _strategies.has(targeting)


static func execute(targeting: String, source: CombatCharacter, ability: Dictionary, context: Dictionary) -> void:
	if not _strategies.has(targeting):
		push_warning("AbilityExecutor: No strategy registered for targeting '%s'" % targeting)
		return
	_strategies[targeting].call(source, ability, context)


static func register_defaults() -> void:
	if _registered:
		return
	_registered = true
	register("enemy_single", _strategy_enemy_single)
	register("enemy_all", _strategy_enemy_all)
	register("enemy_frontline", _strategy_enemy_frontline)
	register("ally_single", _strategy_ally_single)
	register("ally_all", _strategy_ally_all)
	register("enemy_single_apply_effect", _strategy_enemy_single_apply_effect)
	register("enemy_frontline_apply_effect", _strategy_enemy_frontline_apply_effect)
	register("enemy_all_apply_effect", _strategy_enemy_all_apply_effect)
	register("self_apply_effect", _strategy_self_apply_effect)
	register("ally_single_apply_effect", _strategy_ally_single_apply_effect)
	register("ally_frontline_apply_effect", _strategy_ally_frontline_apply_effect)
	register("ally_all_apply_effect", _strategy_ally_all_apply_effect)


static func _get_enemy_targets(source: CombatCharacter, board: CombatBoard) -> Array:
	var enemy_team = GameConstants.TEAM_OPPONENT if source.team == GameConstants.TEAM_PLAYER else GameConstants.TEAM_PLAYER
	return board.get_living_characters_on_team(enemy_team)


static func _get_ally_targets(source: CombatCharacter, board: CombatBoard) -> Array:
	return board.get_living_characters_on_team(source.team)


static func _strategy_enemy_single(source: CombatCharacter, ability: Dictionary, context: Dictionary) -> void:
	if not source.has_damage():
		return
	var multiplier = ability.get("damage_multiplier", 1.0)
	var board: CombatBoard = context["board"]
	var deal_damage: Callable = context["deal_damage"]
	var target = CombatTargeting.select_enemy_target(source, board)
	if target != null:
		deal_damage.call(source, target, source.damage * multiplier)


static func _strategy_enemy_all(source: CombatCharacter, ability: Dictionary, context: Dictionary) -> void:
	if not source.has_damage():
		return
	var multiplier = ability.get("damage_multiplier", 1.0)
	var board: CombatBoard = context["board"]
	var deal_damage: Callable = context["deal_damage"]
	var targets = _get_enemy_targets(source, board)
	for target in targets:
		deal_damage.call(source, target, source.damage * multiplier)


static func _strategy_enemy_frontline(source: CombatCharacter, ability: Dictionary, context: Dictionary) -> void:
	if not source.has_damage():
		return
	var multiplier = ability.get("damage_multiplier", 1.0)
	var board: CombatBoard = context["board"]
	var deal_damage: Callable = context["deal_damage"]
	var enemy_team = GameConstants.TEAM_OPPONENT if source.team == GameConstants.TEAM_PLAYER else GameConstants.TEAM_PLAYER
	var front = board.get_living_characters(enemy_team, GameConstants.ROW_FRONT)
	var targets = front if front.size() > 0 else board.get_living_characters(enemy_team, GameConstants.ROW_BACK)
	for target in targets:
		deal_damage.call(source, target, source.damage * multiplier)


static func _strategy_ally_single(source: CombatCharacter, ability: Dictionary, context: Dictionary) -> void:
	var heal_from = ability.get("heal_from", "")
	var heal_value = source.get_stat_value(heal_from) if heal_from != "" else ability.get("heal_value", 0.0)
	var board: CombatBoard = context["board"]
	var heal: Callable = context["heal"]
	var target = CombatTargeting.select_ally_target(source, board, true)
	if target != null:
		heal.call(target, heal_value, source)


static func _strategy_ally_all(source: CombatCharacter, ability: Dictionary, context: Dictionary) -> void:
	var heal_from = ability.get("heal_from", "")
	var heal_value = source.get_stat_value(heal_from) if heal_from != "" else ability.get("heal_value", 0.0)
	var board: CombatBoard = context["board"]
	var heal: Callable = context["heal"]
	var allies = _get_ally_targets(source, board)
	for ally in allies:
		heal.call(ally, heal_value, source)


static func _strategy_enemy_single_apply_effect(source: CombatCharacter, ability: Dictionary, context: Dictionary) -> void:
	var board: CombatBoard = context["board"]
	var apply_effect: Callable = context["apply_effect"]
	var get_status_effect: Callable = context["get_status_effect"]

	var target = CombatTargeting.select_enemy_target(source, board)
	if target == null:
		return

	# Apply status effect
	var effect_id = ability.get("applies_effect", "")
	if effect_id == "":
		return
	var template = get_status_effect.call(effect_id)
	if template.is_empty():
		return

	var overrides = {}
	var stacks_from = ability.get("stacks_from", "")
	if stacks_from != "":
		overrides["stacks"] = int(source.get_stat_value(stacks_from))
	var duration_from = ability.get("duration_from", "")
	if duration_from != "":
		overrides["duration_value"] = source.get_stat_value(duration_from)

	var effect = StatusEffectFactory.create_from_template(template, source.id, overrides)
	apply_effect.call(target, effect)


static func _strategy_self_apply_effect(source: CombatCharacter, ability: Dictionary, context: Dictionary) -> void:
	var apply_effect: Callable = context["apply_effect"]
	var get_status_effect: Callable = context["get_status_effect"]

	var effect_id = ability.get("applies_effect", "")
	if effect_id == "":
		return
	var template = get_status_effect.call(effect_id)
	if template.is_empty():
		return

	var overrides = {}
	var stacks_from = ability.get("stacks_from", "")
	if stacks_from != "":
		overrides["stacks"] = int(source.get_stat_value(stacks_from))
	var duration_from = ability.get("duration_from", "")
	if duration_from != "":
		overrides["duration_value"] = source.get_stat_value(duration_from)

	var effect = StatusEffectFactory.create_from_template(template, source.id, overrides)
	apply_effect.call(source, effect)


static func _strategy_ally_single_apply_effect(source: CombatCharacter, ability: Dictionary, context: Dictionary) -> void:
	var board: CombatBoard = context["board"]
	var apply_effect: Callable = context["apply_effect"]
	var get_status_effect: Callable = context["get_status_effect"]

	var target = CombatTargeting.select_ally_target(source, board, false)
	if target == null:
		return

	var effect_id = ability.get("applies_effect", "")
	if effect_id == "":
		return
	var template = get_status_effect.call(effect_id)
	if template.is_empty():
		return

	var overrides = {}
	var stacks_from = ability.get("stacks_from", "")
	if stacks_from != "":
		overrides["stacks"] = int(source.get_stat_value(stacks_from))
	var duration_from = ability.get("duration_from", "")
	if duration_from != "":
		overrides["duration_value"] = source.get_stat_value(duration_from)

	var effect = StatusEffectFactory.create_from_template(template, source.id, overrides)
	apply_effect.call(target, effect)


static func _build_effect_overrides(source: CombatCharacter, ability: Dictionary) -> Dictionary:
	var overrides = {}
	var stacks_from = ability.get("stacks_from", "")
	if stacks_from != "":
		overrides["stacks"] = int(source.get_stat_value(stacks_from))
	var duration_from = ability.get("duration_from", "")
	if duration_from != "":
		overrides["duration_value"] = source.get_stat_value(duration_from)
	return overrides


static func _apply_effect_to_targets(source: CombatCharacter, ability: Dictionary, context: Dictionary, targets: Array) -> void:
	var apply_effect: Callable = context["apply_effect"]
	var get_status_effect: Callable = context["get_status_effect"]

	var effect_id = ability.get("applies_effect", "")
	if effect_id == "":
		return
	var template = get_status_effect.call(effect_id)
	if template.is_empty():
		return

	var overrides = _build_effect_overrides(source, ability)
	for target in targets:
		var effect = StatusEffectFactory.create_from_template(template, source.id, overrides)
		apply_effect.call(target, effect)


static func _strategy_enemy_frontline_apply_effect(source: CombatCharacter, ability: Dictionary, context: Dictionary) -> void:
	var board: CombatBoard = context["board"]
	var enemy_team = GameConstants.TEAM_OPPONENT if source.team == GameConstants.TEAM_PLAYER else GameConstants.TEAM_PLAYER
	var front = board.get_living_characters(enemy_team, GameConstants.ROW_FRONT)
	var targets = front if front.size() > 0 else board.get_living_characters(enemy_team, GameConstants.ROW_BACK)
	_apply_effect_to_targets(source, ability, context, targets)


static func _strategy_enemy_all_apply_effect(source: CombatCharacter, ability: Dictionary, context: Dictionary) -> void:
	var board: CombatBoard = context["board"]
	var targets = _get_enemy_targets(source, board)
	_apply_effect_to_targets(source, ability, context, targets)


static func _strategy_ally_frontline_apply_effect(source: CombatCharacter, ability: Dictionary, context: Dictionary) -> void:
	var board: CombatBoard = context["board"]
	var front = board.get_living_characters(source.team, GameConstants.ROW_FRONT)
	var targets = front if front.size() > 0 else board.get_living_characters(source.team, GameConstants.ROW_BACK)
	_apply_effect_to_targets(source, ability, context, targets)


static func _strategy_ally_all_apply_effect(source: CombatCharacter, ability: Dictionary, context: Dictionary) -> void:
	var board: CombatBoard = context["board"]
	var targets = _get_ally_targets(source, board)
	_apply_effect_to_targets(source, ability, context, targets)
