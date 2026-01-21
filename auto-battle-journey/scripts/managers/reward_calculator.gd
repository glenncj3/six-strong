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


static func calculate_run_end_rewards(victory: bool) -> Dictionary:
	"""
	Calculate basic rewards at end of run (legacy method).

	Args:
		victory: Whether the player won the run

	Returns:
		Dictionary with "gems" and "character_fame" rewards
	"""
	return {
		"gems": GameConstants.VICTORY_GEM_REWARD if victory else GameConstants.DEFEAT_GEM_REWARD,
		"character_fame": GameConstants.RUN_CHARACTER_FAME_REWARD
	}


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

	# Bonus for wins (5 per win)
	var win_bonus = wins * 5

	# Bonus for remaining reputation (victory only, 2 per reputation)
	var reputation_bonus = 0
	if victory:
		reputation_bonus = reputation * 2

	return base_reward + win_bonus + reputation_bonus


static func calculate_character_fame_reward(victory: bool, wins: int) -> int:
	"""
	Calculate character fame based on performance.

	Args:
		victory: Whether the player won the run
		wins: Number of combat victories

	Returns:
		Fame reward per character
	"""
	var base_fame = 25
	if victory:
		base_fame = 75

	# Bonus for wins (5 per win)
	var win_bonus = wins * 5

	return base_fame + win_bonus


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

	print("RewardCalculator: Victory! Awarded %d gold, %d XP per character" % [rewards["gold"], rewards["xp"]])

	return rewards


static func apply_run_end_rewards(
	team_manager: TeamManager,
	victory: bool
) -> void:
	"""
	Apply end-of-run rewards to characters and player account.

	Args:
		team_manager: TeamManager with team to reward
		victory: Whether the player won
	"""
	var rewards = calculate_run_end_rewards(victory)

	# Award character fame (for prestige progression)
	for char_instance in team_manager.get_team():
		PlayerAccount.add_character_fame(
			char_instance.base_character_id,
			rewards["character_fame"]
		)

	# Award gems
	PlayerAccount.add_gems(rewards["gems"])

	print("RewardCalculator: Run ended - Awarded %d gems, %d fame per character" % [rewards["gems"], rewards["character_fame"]])
