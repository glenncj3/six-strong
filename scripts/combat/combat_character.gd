class_name CombatCharacter
extends RefCounted
## Combat instance of a character. Cloned from CharacterInstance at combat start.
## All combat modifications happen here and are discarded after combat.

static var _next_id: int = 0

# Identity
var id: String = ""
var source_character_id: String = ""
var character_name: String = ""
var ability_ids: Array = []  # Array of String

# Health
var health: float = 0.0
var max_health: float = 0.0
var base_max_health: float = 0.0

# Base stats (before modifiers)
var base_speed: float = 0.0
var base_damage: float = 0.0
var base_crit_chance: float = 0.0
var base_defend_rate: float = 0.0

# Effective stats (recalculated from base + effects)
var speed: float = 0.0
var damage: float = 0.0
var crit_chance: float = 0.0
var defend_rate: float = 0.0

# Positioning
var team: int = GameConstants.TEAM_PLAYER
var row: int = GameConstants.ROW_FRONT
var column: int = 0

# State
var is_alive: bool = true
var cooldown_remaining: float = 0.0

# Timing
var tick_rate_multiplier: float = 1.0

# Extra stats (poison_value, haste_value, etc.)
var extra_stats: Dictionary = {}

# Effects
var effects: Array = []  # Array of CombatEffect


static func create_from_character(source: CharacterInstance, p_team: int, p_row: int, p_col: int, p_ability_ids: Array = ["attack_enemy"]) -> CombatCharacter:
	_next_id += 1
	var cc = CombatCharacter.new()
	cc.id = "cc_%d" % _next_id
	cc.source_character_id = source.base_character_id
	cc.character_name = source.get_character_name()
	cc.ability_ids = p_ability_ids

	cc.base_max_health = float(source.max_health)
	cc.max_health = cc.base_max_health
	cc.health = float(source.current_health)

	cc.base_speed = float(source.stats.get(GameConstants.STAT_SPEED, 0))
	cc.base_damage = float(source.stats.get(GameConstants.STAT_DAMAGE, 0))
	cc.base_crit_chance = float(source.stats.get(GameConstants.STAT_CRIT_CHANCE, 0))
	cc.base_defend_rate = float(source.stats.get(GameConstants.STAT_DEFEND_RATE, 0))

	cc.speed = cc.base_speed
	cc.damage = cc.base_damage
	cc.crit_chance = cc.base_crit_chance
	cc.defend_rate = cc.base_defend_rate

	cc.team = p_team
	cc.row = p_row
	cc.column = p_col
	cc.is_alive = cc.health > 0
	cc.cooldown_remaining = cc.speed

	# Copy extra stats not mapped to base fields
	var mapped_stats = [GameConstants.STAT_HEALTH, GameConstants.STAT_SPEED,
		GameConstants.STAT_DAMAGE, GameConstants.STAT_CRIT_CHANCE,
		GameConstants.STAT_DEFEND_RATE]
	for key in source.stats:
		if key not in mapped_stats:
			cc.extra_stats[key] = source.stats[key]

	return cc


func recalculate_stats() -> void:
	# Collect flat and percent modifiers per stat
	var flat_mods := {}
	var pct_mods := {}

	for effect in effects:
		if effect.effect_type != "stat_modifier":
			continue
		var s = effect.stat
		if effect.modifier_type == "flat":
			flat_mods[s] = flat_mods.get(s, 0.0) + effect.value
		elif effect.modifier_type == "percent":
			pct_mods[s] = pct_mods.get(s, 0.0) + effect.value

	# Apply: base + flat, then * (1 + sum_of_percents)
	var base_plus_flat_speed = base_speed + flat_mods.get("speed", 0.0)
	speed = base_plus_flat_speed * (1.0 + pct_mods.get("speed", 0.0))

	var base_plus_flat_damage = base_damage + flat_mods.get("damage", 0.0)
	damage = base_plus_flat_damage * (1.0 + pct_mods.get("damage", 0.0))

	var base_plus_flat_crit = base_crit_chance + flat_mods.get("crit_chance", 0.0)
	crit_chance = base_plus_flat_crit * (1.0 + pct_mods.get("crit_chance", 0.0))

	var base_plus_flat_def = base_defend_rate + flat_mods.get("defend_rate", 0.0)
	defend_rate = base_plus_flat_def * (1.0 + pct_mods.get("defend_rate", 0.0))

	# Recalculate max_health from stable base
	var flat_hp = flat_mods.get("health", 0.0)
	var pct_hp = pct_mods.get("health", 0.0)
	var new_max = (base_max_health + flat_hp) * (1.0 + pct_hp)
	if new_max != max_health:
		var diff = new_max - max_health
		max_health = new_max
		if diff > 0:
			health += diff
		else:
			if health > max_health:
				health = max_health

	# Recalculate tick_rate_multiplier from continuous_modifier effects
	var new_tick_rate = 1.0
	for effect in effects:
		if effect.continuous_modifier == "cooldown_tick_rate":
			new_tick_rate *= effect.continuous_value
	tick_rate_multiplier = new_tick_rate


func has_speed() -> bool:
	return speed > 0.0


func has_damage() -> bool:
	return damage > 0.0


func get_stat_value(stat_name: String) -> float:
	match stat_name:
		"health": return health
		"max_health": return max_health
		"speed": return speed
		"damage": return damage
		"crit_chance": return crit_chance
		"defend_rate": return defend_rate
	return float(extra_stats.get(stat_name, 0.0))


func get_board_index() -> int:
	return row * GameConstants.GRID_COLS + column


func has_effect(p_effect_id: String) -> bool:
	for effect in effects:
		if effect.effect_id == p_effect_id:
			return true
	return false


func get_effect(p_effect_id: String) -> CombatEffect:
	for effect in effects:
		if effect.effect_id == p_effect_id:
			return effect
	return null


func get_effects_by_tag(tag: String) -> Array:
	var result: Array = []
	for effect in effects:
		if effect.tags.has(tag):
			result.append(effect)
	return result


func get_stacks(p_effect_id: String) -> int:
	var effect = get_effect(p_effect_id)
	if effect != null:
		return effect.stacks
	return 0


func cleanse_by_tag(tag: String) -> Array:
	var removed: Array = []
	var remaining: Array = []
	for effect in effects:
		if effect.tags.has(tag):
			removed.append(effect)
		else:
			remaining.append(effect)
	effects = remaining
	return removed


func update(delta: float) -> Dictionary:
	var result = {"action_ready": false, "expired_effects": [], "tick_events": []}
	if not has_speed():
		return result

	var effective_delta = delta * tick_rate_multiplier

	cooldown_remaining -= effective_delta
	if cooldown_remaining <= 0:
		result["action_ready"] = true
		cooldown_remaining = speed

		# Decrement cooldown-type effect durations
		var to_expire: Array = []
		for effect in effects:
			if effect.duration_type == "cooldowns":
				effect.duration_value -= 1
				if effect.duration_value <= 0:
					to_expire.append(effect)
		result["expired_effects"].append_array(to_expire)

	# Decrement seconds-type effect durations (use raw delta, not affected by tick rate)
	var seconds_expired: Array = []
	for effect in effects:
		if effect.duration_type == "seconds":
			effect.duration_value -= delta
			if effect.duration_value <= 0:
				seconds_expired.append(effect)
	result["expired_effects"].append_array(seconds_expired)

	# Process tick events for effects with tick_interval > 0
	for effect in effects:
		if effect.tick_interval > 0:
			effect.tick_elapsed += effective_delta
			while effect.tick_elapsed >= effect.tick_interval:
				effect.tick_elapsed -= effect.tick_interval
				result["tick_events"].append(effect)

	return result
