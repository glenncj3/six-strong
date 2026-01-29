class_name AbilityExecutor
extends RefCounted
## Executes abilities by resolving targets then applying actions inferred from ability fields.


static func execute(source: CombatCharacter, ability: Dictionary, context: Dictionary) -> void:
	var target_mode = ability.get("target_mode", "enemy_single")
	var board: CombatBoard = context["board"]
	var targets = CombatTargeting.resolve_targets(source, board, target_mode)
	if targets.is_empty():
		return

	# Determine action from ability fields
	if ability.has("applies_effect"):
		_apply_effect_to_targets(source, ability, context, targets)
	elif ability.has("heal_from") or ability.has("heal_value"):
		_heal_targets(source, ability, context, targets)
	elif ability.has("damage_multiplier"):
		_damage_targets(source, ability, context, targets)


static func _damage_targets(source: CombatCharacter, ability: Dictionary, context: Dictionary, targets: Array) -> void:
	if not source.has_damage():
		return
	var multiplier = ability.get("damage_multiplier", 1.0)
	var category = ability.get("category", "")

	# Apply category-specific damage bonuses from effects
	if category == "attack":
		var bonus = _get_effect_stat_bonus(source, "attack_damage_bonus")
		multiplier *= (1.0 + bonus)

	var deal_damage: Callable = context["deal_damage"]
	for target in targets:
		deal_damage.call(source, target, source.damage * multiplier)


static func _heal_targets(source: CombatCharacter, ability: Dictionary, context: Dictionary, targets: Array) -> void:
	var heal_from = ability.get("heal_from", "")
	var heal_value = source.get_stat_value(heal_from) if heal_from != "" else ability.get("heal_value", 0.0)
	var heal: Callable = context["heal"]
	for target in targets:
		heal.call(target, heal_value, source)


static func _get_effect_stat_bonus(character: CombatCharacter, stat_name: String) -> float:
	## Sums percent modifier values for a custom stat from the character's effects.
	var total := 0.0
	for effect in character.effects:
		if effect.effect_type == "stat_modifier" and effect.stat == stat_name:
			if effect.modifier_type == "percent":
				total += effect.value
	return total


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
