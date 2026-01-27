class_name CombatCharacter
extends RefCounted
## Combat instance of a character. Cloned from CharacterInstance at combat start.
## All combat modifications happen here and are discarded after combat.

static var _next_id: int = 0

# Identity
var id: String = ""
var source_character_id: String = ""
var character_name: String = ""

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

# Effects
var effects: Array = []  # Array of CombatEffect


static func create_from_character(source: CharacterInstance, p_team: int, p_row: int, p_col: int) -> CombatCharacter:
	_next_id += 1
	var cc = CombatCharacter.new()
	cc.id = "cc_%d" % _next_id
	cc.source_character_id = source.base_character_id
	cc.character_name = source.get_character_name()

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
			# Buff: increase current health by the same amount
			health += diff
		else:
			# Debuff: cap current health at new max
			if health > max_health:
				health = max_health


func has_speed() -> bool:
	return speed > 0.0


func has_damage() -> bool:
	return damage > 0.0


func get_board_index() -> int:
	return row * GameConstants.GRID_COLS + column
