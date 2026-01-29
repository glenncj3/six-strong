class_name StatCalculator
extends RefCounted
# StatCalculator - Single source of truth for all stat calculations
# Phase 1 Refactor: Simplified to remove item/skill/prestige modifiers
# Characters now have stats = base_stats only (items/skills handled separately)

# =============================================================================
# MAIN CALCULATION METHODS
# =============================================================================

static func calculate_character_base_stats(char_master: Dictionary) -> Dictionary:
	"""
	Calculate base stats for a character from master data.
	Phase 1: No items, skills, or prestige modifiers - just base stats.

	Args:
		char_master: Master character data from GameData

	Returns:
		Dictionary with all stat values
	"""
	return _get_base_stats(char_master)


static func calculate_character_stats(
	char_master: Dictionary,
	_char_data: Dictionary = {},
	_include_items: bool = false
) -> Dictionary:
	"""
	Calculate full stats for a character.
	Phase 1: Simplified - ignores char_data and include_items parameters.
	Kept for backwards compatibility with existing UI code.

	Args:
		char_master: Master character data from GameData
		_char_data: IGNORED (kept for API compatibility)
		_include_items: IGNORED (kept for API compatibility)

	Returns:
		Dictionary with all stat values (base stats only)
	"""
	# Phase 1: Items/skills/prestige are no longer on characters
	return _get_base_stats(char_master)


# =============================================================================
# STAT MODIFICATION METHODS (Data-Driven)
# =============================================================================

static func apply_modifier(stats: Dictionary, stat_name: String, value: float, multiply: bool = false) -> void:
	"""
	Apply a single stat modifier. Data-driven - works with any stat name.

	Args:
		stats: Stats dictionary to modify (mutated in place)
		stat_name: Name of the stat to modify
		value: Value to add or multiply by
		multiply: If true, multiply instead of add
	"""
	if not stats.has(stat_name):
		# Initialize stat if not present (allows dynamic stats)
		stats[stat_name] = 0

	if multiply:
		stats[stat_name] = int(stats[stat_name] * value)
	else:
		stats[stat_name] += int(value)


static func apply_stat_modifiers(stats: Dictionary, modifiers: Dictionary) -> void:
	"""Apply a dictionary of stat modifiers (additive)."""
	for stat_name in modifiers:
		apply_modifier(stats, stat_name, modifiers[stat_name], false)


# =============================================================================
# HELPER METHODS
# =============================================================================

static func _get_base_stats(char_master: Dictionary) -> Dictionary:
	"""
	Extract base stats from master data.
	Returns all stats defined in base_stats (health, charges, speed, damage, etc.).
	"""
	var base = char_master.get("base_stats", {})
	return base.duplicate(true)


static func clone_stats(stats: Dictionary) -> Dictionary:
	"""Create a deep copy of a stats dictionary."""
	return stats.duplicate(true)


static func stats_to_string(stats: Dictionary) -> String:
	"""Format stats for display/debugging."""
	return "HP:%d MP:%d DEF%%:%d SPD:%d DMG:%d CRIT%%:%d" % [
		stats.get(GameConstants.STAT_HEALTH, 0),
		stats.get(GameConstants.STAT_CHARGES, 0),
		stats.get(GameConstants.STAT_agility, 0),
		stats.get(GameConstants.STAT_SPEED, 0),
		stats.get(GameConstants.STAT_DAMAGE, 0),
		stats.get(GameConstants.STAT_CRIT_CHANCE, 0)
	]


# =============================================================================
# LEVEL BONUS CALCULATION
# =============================================================================

static func calculate_level_bonus(base_stats: Dictionary, level: int) -> Dictionary:
	"""
	Calculate stats with level bonuses applied.

	Args:
		base_stats: Base stats dictionary
		level: Character level (1+)

	Returns:
		New stats dictionary with level bonuses applied
	"""
	var stats = clone_stats(base_stats)

	# Apply level bonuses (simple: +5 health per level after 1)
	if level > 1:
		var bonus_health = (level - 1) * 5
		stats[GameConstants.STAT_HEALTH] = stats.get(GameConstants.STAT_HEALTH, 0) + bonus_health

	return stats
