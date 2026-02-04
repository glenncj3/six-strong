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
var base_agility: float = 0.0

# Effective stats (recalculated from base + effects)
var speed: float = 0.0
var damage: float = 0.0
var crit_chance: float = 0.0
var agility: float = 0.0

# Positioning
var team: int = GameConstants.TEAM_PLAYER
var row: int = GameConstants.ROW_FRONT
var column: int = 0

# State
var is_alive: bool = true
var cooldown_remaining: float = 0.0
var charges: int = -1  # -1 = unlimited, 0 = waiting for charge, >0 = charges remaining
var waiting_for_charge: bool = false  # True when cooldown finished but no charges available

# Timing
var tick_rate_multiplier: float = 1.0

# Extra stats (poison_value, haste_value, etc.)
var extra_stats: Dictionary = {}
var base_extra_stats: Dictionary = {}

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

	cc.base_speed = float(source.stats.get("speed", 0))
	cc.base_damage = float(source.stats.get("damage", 0))
	cc.base_crit_chance = float(source.stats.get("crit_chance", 0))
	cc.base_agility = float(source.stats.get("agility", 0))

	cc.speed = cc.base_speed
	cc.damage = cc.base_damage
	cc.crit_chance = cc.base_crit_chance
	cc.agility = cc.base_agility

	cc.team = p_team
	cc.row = p_row
	cc.column = p_col
	cc.is_alive = cc.health > 0
	cc.cooldown_remaining = cc.speed

	# Set charges from source stats (-1 means unlimited)
	var source_charges = source.stats.get("charges", -1)
	cc.charges = source_charges if source_charges >= 0 else -1

	# Copy extra stats not mapped to base fields
	var mapped_stats = ["health", "speed",
		"damage", "crit_chance",
		"agility"]
	for key in source.stats:
		if key not in mapped_stats:
			cc.extra_stats[key] = source.stats[key]
			if key != "charges":
				cc.base_extra_stats[key] = source.stats[key]

	return cc


func recalculate_stats() -> void:
	# Collect modifiers from combat effects
	var mods := StatResolver.collect_modifiers_from_effects(effects)

	# Apply to each stat
	var stat_map := {
		"speed": "base_speed",
		"damage": "base_damage",
		"crit_chance": "base_crit_chance",
		"agility": "base_agility",
	}
	for stat_name in stat_map:
		var base_val: float = get(stat_map[stat_name])
		set(stat_name, StatResolver.resolve_stat(base_val, mods, stat_name))

	# Recalculate max_health (special: adjusts current health)
	var new_max = StatResolver.resolve_stat(base_max_health, mods, "health")
	if new_max != max_health:
		var diff = new_max - max_health
		max_health = new_max
		if diff > 0:
			health += diff
		else:
			if health > max_health:
				health = max_health

	# Recalculate extra stats (burn_value, heal_value, etc.) — skip charges
	for key in base_extra_stats:
		extra_stats[key] = StatResolver.resolve_stat(float(base_extra_stats[key]), mods, key)

	# Recalculate tick_rate_multiplier from continuous_modifier effects
	var new_tick_rate = 1.0
	for effect in effects:
		if effect.continuous_modifier == "cooldown_tick_rate":
			new_tick_rate *= effect.continuous_value
	tick_rate_multiplier = new_tick_rate


func has_charges() -> bool:
	return charges != 0


func add_charges(amount: int) -> void:
	if charges == -1:
		return  # Unlimited, nothing to do
	charges += amount


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
		"agility": return agility
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

	# Decrement seconds-type effect durations (use raw delta, not affected by tick rate)
	# This happens regardless of whether the character has speed
	var seconds_expired: Array = []
	for effect in effects:
		if effect.duration_type == "seconds":
			effect.duration_value -= delta
			if effect.duration_value <= 0:
				seconds_expired.append(effect)
	result["expired_effects"].append_array(seconds_expired)

	# Process tick events for effects with tick_interval > 0
	# DoT ticks use raw delta so poison ticks at constant rate regardless of haste/slow
	for effect in effects:
		if effect.tick_interval > 0:
			effect.tick_elapsed += delta
			while effect.tick_elapsed >= effect.tick_interval:
				effect.tick_elapsed -= effect.tick_interval
				result["tick_events"].append(effect)

	# Cooldown processing requires speed > 0
	if not has_speed():
		return result

	var effective_delta = delta * tick_rate_multiplier

	cooldown_remaining -= effective_delta
	if cooldown_remaining <= 0:
		if charges == 0:
			# No charges available - stop cooldown and wait
			cooldown_remaining = 0.0
			waiting_for_charge = true
		else:
			result["action_ready"] = true
			cooldown_remaining = speed
			if charges > 0:
				charges -= 1

		# Decrement cooldown-type effect durations
		var to_expire: Array = []
		for effect in effects:
			if effect.duration_type == "cooldowns":
				effect.duration_value -= 1
				if effect.duration_value <= 0:
					to_expire.append(effect)
		result["expired_effects"].append_array(to_expire)

	return result
