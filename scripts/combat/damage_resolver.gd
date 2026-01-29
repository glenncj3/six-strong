class_name DamageResolver
extends RefCounted
## Static utility for resolving damage: block check, crit check, final damage calc.


static func resolve(source, target: CombatCharacter, base_damage: float) -> Dictionary:
	# Null source (e.g. poison tick): skip block/crit, return raw damage
	if source == null:
		return {blocked = false, damage = base_damage, is_crit = false}

	# Crit check
	var final_damage = base_damage
	var is_crit = false
	if source.crit_chance > 0:
		if randf() < source.crit_chance:
			final_damage = base_damage * GameConstants.CRIT_MULTIPLIER
			is_crit = true

	# Dodge check — reduces damage by 90%, but crits cannot be dodged
	var dodged = false
	if not is_crit and target.agility > 0:
		if randf() < target.agility:
			dodged = true
			final_damage *= (1.0 - GameConstants.DODGE_DAMAGE_REDUCTION)

	return {blocked = dodged, damage = final_damage, is_crit = is_crit}
