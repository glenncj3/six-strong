class_name AbilityExecutor
extends RefCounted
## Strategy registry for ability execution. Maps targeting types to callable strategies.

static var _strategies: Dictionary = {}


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
	register("enemy_single", _strategy_enemy_single)
	register("enemy_all", _strategy_enemy_all)
	register("ally_single", _strategy_ally_single)
	register("ally_all", _strategy_ally_all)
	register("self_buff", _strategy_self_buff)
	register("enemy_random_multi", _strategy_enemy_random_multi)


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
	var enemy_team = GameConstants.TEAM_OPPONENT if source.team == GameConstants.TEAM_PLAYER else GameConstants.TEAM_PLAYER
	var targets = board.get_living_characters_on_team(enemy_team)
	for target in targets:
		deal_damage.call(source, target, source.damage * multiplier)


static func _strategy_ally_single(source: CombatCharacter, ability: Dictionary, context: Dictionary) -> void:
	var heal_multiplier = ability.get("heal_multiplier", 1.0)
	var board: CombatBoard = context["board"]
	var heal: Callable = context["heal"]
	var target = CombatTargeting.select_ally_target(source, board, true)
	if target != null:
		heal.call(target, source.damage * heal_multiplier, source)


static func _strategy_ally_all(source: CombatCharacter, ability: Dictionary, context: Dictionary) -> void:
	var heal_multiplier = ability.get("heal_multiplier", 1.0)
	var board: CombatBoard = context["board"]
	var heal: Callable = context["heal"]
	var allies = board.get_living_characters_on_team(source.team)
	for ally in allies:
		heal.call(ally, source.damage * heal_multiplier, source)


static func _strategy_self_buff(source: CombatCharacter, ability: Dictionary, context: Dictionary) -> void:
	var apply_effect: Callable = context["apply_effect"]
	var stat = ability.get("buff_stat", "damage")
	var value = ability.get("buff_value", 0.0)
	var modifier_type = ability.get("buff_modifier_type", "flat")
	var duration_type = ability.get("buff_duration_type", "combat")
	var duration_value = ability.get("buff_duration_value", 0.0)
	var effect = CombatEffect.create_stat_modifier("ability", source.id, stat, value, modifier_type, duration_type, duration_value)
	apply_effect.call(source, effect)


static func _strategy_enemy_random_multi(source: CombatCharacter, ability: Dictionary, context: Dictionary) -> void:
	if not source.has_damage():
		return
	var multiplier = ability.get("damage_multiplier", 1.0)
	var hit_count = ability.get("hit_count", 3)
	var board: CombatBoard = context["board"]
	var deal_damage: Callable = context["deal_damage"]
	var enemy_team = GameConstants.TEAM_OPPONENT if source.team == GameConstants.TEAM_PLAYER else GameConstants.TEAM_PLAYER
	for i in range(hit_count):
		var targets = board.get_living_characters_on_team(enemy_team)
		if targets.is_empty():
			break
		var target = targets[randi() % targets.size()]
		deal_damage.call(source, target, source.damage * multiplier)
