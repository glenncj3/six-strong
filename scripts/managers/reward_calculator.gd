class_name RewardCalculator
extends RefCounted
# RewardCalculator - Handles reward and penalty calculations
# Extracted from RunManager for Single Responsibility Principle


static func calculate_combat_rewards(combat_data: Dictionary) -> Dictionary:
	"""
	Calculate rewards for a combat victory.

	Args:
		combat_data: The combat option data (or CombatOption.to_dict())

	Returns:
		Dictionary with "gold" and "xp" rewards
	"""
	return {
		"gold": combat_data.get("reward_gold", GameConstants.COMBAT_WIN_GOLD),
		"xp": combat_data.get("reward_xp", GameConstants.COMBAT_WIN_XP)
	}


static func calculate_reputation_loss(current_round: int) -> int:
	"""
	Calculate reputation loss on combat defeat.

	Args:
		current_round: Current round number (0-indexed)

	Returns:
		Reputation points to lose
	"""
	return current_round + 1  # +1 because displayed as 1-indexed


static func calculate_gem_reward(victory: bool, wins: int, reputation: int) -> int:
	"""
	Calculate gem reward based on performance.

	Args:
		victory: Whether the player won the run
		wins: Number of combat victories
		reputation: Remaining reputation (only counts for victory)

	Returns:
		Total gem reward
	"""
	var base_reward = GameConstants.DEFEAT_GEM_REWARD
	if victory:
		base_reward = GameConstants.VICTORY_GEM_REWARD

	var win_bonus = wins * GameConstants.GEMS_PER_WIN_BONUS

	var reputation_bonus = 0
	if victory:
		reputation_bonus = reputation * GameConstants.GEMS_PER_REPUTATION_BONUS

	return base_reward + win_bonus + reputation_bonus


static func calculate_character_fame_reward(victory: bool, wins: int) -> int:
	"""
	Calculate character fame based on performance.
	DEPRECATED: Use calculate_legacy_fame_reward() for new code.

	Args:
		victory: Whether the player won the run
		wins: Number of combat victories

	Returns:
		Fame reward per character
	"""
	var base_fame = GameConstants.FAME_REWARD_BASE_DEFEAT
	if victory:
		base_fame = GameConstants.FAME_REWARD_BASE_VICTORY

	var win_bonus = wins * GameConstants.FAME_PER_WIN_BONUS

	return base_fame + win_bonus


static func calculate_legacy_fame_reward(victory: bool, wins: int) -> int:
	"""
	Calculate legacy fame based on run performance.
	Fame is distributed equally to all 3 drafted legacies.

	Formula:
		Victory: 75 + (wins * 5)
		Defeat: 25 + (wins * 5)

	Args:
		victory: Whether the player won the run
		wins: Number of combat victories

	Returns:
		Fame reward per legacy
	"""
	var base_fame = GameConstants.FAME_REWARD_BASE_DEFEAT
	if victory:
		base_fame = GameConstants.FAME_REWARD_BASE_VICTORY

	var win_bonus = wins * GameConstants.FAME_PER_WIN_BONUS

	return base_fame + win_bonus


static func distribute_fame_to_legacies(
	legacy_collection,  # LegacyCollection
	drafted_legacy_ids: Array,
	fame_per_legacy: int
) -> Array:
	"""
	Distribute fame equally to all drafted legacies.

	Args:
		legacy_collection: LegacyCollection instance to award fame to
		drafted_legacy_ids: Array of legacy IDs that were drafted for this run
		fame_per_legacy: Fame amount to give each legacy

	Returns:
		Array of Dictionaries containing prestige-up info for each legacy that leveled:
		[{
			"legacy_id": String,
			"legacy_name": String,
			"old_prestige": int,
			"new_prestige": int,
			"levels_gained": int,
			"unlocked_content": Dictionary
		}, ...]
	"""
	var prestige_ups: Array = []

	for legacy_id in drafted_legacy_ids:
		var legacy = legacy_collection.get_legacy(legacy_id)
		if legacy == null:
			push_warning("RewardCalculator: Legacy not found: %s" % legacy_id)
			continue

		if not legacy.unlocked:
			push_warning("RewardCalculator: Cannot award fame to locked legacy: %s" % legacy_id)
			continue

		var old_prestige = legacy.get_prestige()
		var result = legacy_collection.add_legacy_fame(legacy_id, fame_per_legacy)

		if result.get("prestige_increased", false):
			prestige_ups.append({
				"legacy_id": legacy_id,
				"legacy_name": legacy.legacy_name,
				"old_prestige": old_prestige,
				"new_prestige": result.get("new_prestige", old_prestige + 1),
				"levels_gained": result.get("levels_gained", 1),
				"unlocked_content": result.get("unlocked_content", {})
			})

	return prestige_ups


static func apply_combat_victory_rewards(
	team_manager: TeamManager,
	gold_callback: Callable,
	combat_data: Dictionary
) -> Dictionary:
	"""
	Apply combat victory rewards to team and gold.

	Args:
		team_manager: TeamManager to distribute XP to
		gold_callback: Callable to add gold (e.g., RunManager.add_gold)
		combat_data: The combat option data

	Returns:
		Dictionary with applied "gold" and "xp" amounts
	"""
	var rewards = calculate_combat_rewards(combat_data)

	gold_callback.call(rewards["gold"])
	team_manager.distribute_experience(rewards["xp"])

	return rewards


