class_name StatCalculator
extends RefCounted
# StatCalculator - Single source of truth for all stat calculations
# Eliminates duplicate stat calculation logic across the codebase

# =============================================================================
# MAIN CALCULATION METHODS
# =============================================================================

static func calculate_character_stats(
	char_master: Dictionary,
	char_data: Dictionary,
	include_items: bool = true
) -> Dictionary:
	"""
	Calculate full stats for a character from account data.
	Used by UI components (CharacterCard, CharacterDetails).

	Args:
		char_master: Master character data from GameData
		char_data: Player's character data from PlayerAccount
		include_items: Whether to include equipped item modifiers

	Returns:
		Dictionary with all stat values
	"""
	var stats = _get_base_stats(char_master)

	# Apply rank stat boosts
	_apply_rank_boosts(stats, char_master, char_data.get("rank", 1))

	# Apply equipped items if requested
	if include_items and char_data.has("equipped_items"):
		for item_id in char_data["equipped_items"]:
			var item_data = GameData.get_item_by_id(item_id)
			_apply_stat_modifiers(stats, item_data.get("stat_modifiers", {}))

	return stats


static func calculate_runtime_stats(
	char_master: Dictionary,
	char_data: Dictionary,
	equipped_items: Array,
	equipped_upgrades: Array = [],
	learned_skills: Array = []
) -> Dictionary:
	"""
	Calculate full stats for a character instance during a run.
	Includes items, upgrades, and skills.

	Args:
		char_master: Master character data from GameData
		char_data: Player's character data (for rank)
		equipped_items: Array of equipped item IDs
		equipped_upgrades: Array of equipped item upgrade IDs
		learned_skills: Array of learned skill IDs

	Returns:
		Dictionary with all stat values
	"""
	var stats = _get_base_stats(char_master)

	# Apply rank stat boosts
	_apply_rank_boosts(stats, char_master, char_data.get("rank", 1))

	# Apply equipped items
	for item_id in equipped_items:
		var item_data = GameData.get_item_by_id(item_id)
		_apply_stat_modifiers(stats, item_data.get("stat_modifiers", {}))

	# Apply item upgrades
	for upgrade_id in equipped_upgrades:
		var upgrade_data = GameData.get_item_upgrade_by_id(upgrade_id)
		_apply_stat_modifiers(stats, upgrade_data.get("stat_modifiers", {}))

	# Apply skill effects (must be last as some may be multiplicative)
	for skill_id in learned_skills:
		var skill_data = GameData.get_skill_by_id(skill_id)
		_apply_skill_effects(stats, skill_data.get("effects", []))

	return stats


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
		push_warning("StatCalculator: Unknown stat '%s'" % stat_name)
		return

	if multiply:
		stats[stat_name] = int(stats[stat_name] * value)
	else:
		stats[stat_name] += int(value)


static func _apply_stat_modifiers(stats: Dictionary, modifiers: Dictionary) -> void:
	"""Apply a dictionary of stat modifiers (additive)."""
	for stat_name in modifiers:
		apply_modifier(stats, stat_name, modifiers[stat_name], false)


static func _apply_skill_effects(stats: Dictionary, effects: Array) -> void:
	"""Apply skill effects which can be additive or multiplicative."""
	for effect in effects:
		var effect_type = effect.get("type", "stat_add")
		var stat_name = effect.get("stat", "")
		var value = effect.get("value", 0)

		match effect_type:
			"stat_add":
				apply_modifier(stats, stat_name, value, false)
			"stat_multiply":
				apply_modifier(stats, stat_name, value, true)


# =============================================================================
# HELPER METHODS
# =============================================================================

static func _get_base_stats(char_master: Dictionary) -> Dictionary:
	"""Extract base stats from master data."""
	var base = char_master.get("base_stats", {})
	return {
		GameConstants.STAT_HEALTH: base.get(GameConstants.STAT_HEALTH, 0),
		GameConstants.STAT_ATTACK: base.get(GameConstants.STAT_ATTACK, 0),
		GameConstants.STAT_SPEED: base.get(GameConstants.STAT_SPEED, 0),
		GameConstants.STAT_DEFENSE: base.get(GameConstants.STAT_DEFENSE, 0),
		GameConstants.STAT_INCOME: base.get(GameConstants.STAT_INCOME, 0)
	}


static func _apply_rank_boosts(stats: Dictionary, char_master: Dictionary, current_rank: int) -> void:
	"""Apply all rank boosts up to and including current rank."""
	if not char_master.has("rank_rewards"):
		return

	for rank_reward in char_master["rank_rewards"]:
		if rank_reward.get("rank", 0) <= current_rank:
			if rank_reward.has("stat_boost"):
				_apply_stat_modifiers(stats, rank_reward["stat_boost"])


static func clone_stats(stats: Dictionary) -> Dictionary:
	"""Create a deep copy of a stats dictionary."""
	return stats.duplicate(true)


static func stats_to_string(stats: Dictionary) -> String:
	"""Format stats for display/debugging."""
	return "HP:%d ATK:%d DEF:%d SPD:%d INC:%d" % [
		stats.get(GameConstants.STAT_HEALTH, 0),
		stats.get(GameConstants.STAT_ATTACK, 0),
		stats.get(GameConstants.STAT_DEFENSE, 0),
		stats.get(GameConstants.STAT_SPEED, 0),
		stats.get(GameConstants.STAT_INCOME, 0)
	]
