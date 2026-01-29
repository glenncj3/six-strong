class_name StatResolver
extends RefCounted
## Shared utility for applying stat modifiers using the formula:
##   effective = (base + flat) * (1 + percent)
##
## Used by both CombatCharacter (combat effects) and CharacterInstance (grid bonuses).


static func apply(base_value: float, flat: float = 0.0, percent: float = 0.0) -> float:
	"""Apply modifiers to a base stat value."""
	return (base_value + flat) * (1.0 + percent)


static func collect_modifiers_from_effects(effects: Array) -> Dictionary:
	"""Collect flat and percent modifiers from CombatEffect arrays.
	Returns {stat_name: {flat: float, percent: float}}."""
	var result := {}
	for effect in effects:
		if effect.effect_type != "stat_modifier":
			continue
		var s = effect.stat
		if not result.has(s):
			result[s] = {"flat": 0.0, "percent": 0.0}
		if effect.modifier_type == "flat":
			result[s]["flat"] += effect.value
		elif effect.modifier_type == "percent":
			result[s]["percent"] += effect.value
	return result


static func resolve_stat(base_value: float, modifiers: Dictionary, stat_name: String) -> float:
	"""Resolve a single stat from a modifiers dictionary (as returned by collect_modifiers_from_effects or stat_bonuses)."""
	if not modifiers.has(stat_name):
		return base_value
	var mods = modifiers[stat_name]
	return apply(base_value, mods.get("flat", 0.0), mods.get("percent", 0.0))
