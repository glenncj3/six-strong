class_name CombatGenerator
extends RefCounted
# CombatGenerator - Generates combat options for the combat phase
# Extracted from RunManager for Single Responsibility Principle
# Uses CombatOption typed class for better type safety


func generate_options(count: int) -> Array[CombatOption]:
	"""
	Generate random combat options (AI enemies or Player Ghosts).

	Args:
		count: Number of options to generate (usually 3)

	Returns:
		Array of CombatOption objects
	"""
	var options: Array[CombatOption] = []

	for i in range(count):
		var is_player_ghost = randf() > 0.5  # 50% chance of player ghost

		if is_player_ghost:
			options.append(_generate_player_ghost_option())
		else:
			options.append(_generate_ai_option())

	return options


func _generate_ai_option() -> CombatOption:
	"""Generate an AI enemy combat option."""
	var difficulty = GameConstants.COMBAT_DIFFICULTIES[randi() % GameConstants.COMBAT_DIFFICULTIES.size()]
	var difficulty_index = GameConstants.COMBAT_DIFFICULTIES.find(difficulty)

	var base_reward = GameConstants.AI_BASE_REWARD_GOLD + (difficulty_index * GameConstants.AI_REWARD_PER_DIFFICULTY)
	var xp_reward = base_reward + GameConstants.AI_BONUS_XP

	return CombatOption.create_ai(
		"AI Enemy (%s)" % difficulty,
		"Fight an AI-controlled enemy.",
		"res://assets/combat/ai_enemy.png",
		difficulty,
		base_reward,
		xp_reward
	)


func _generate_player_ghost_option() -> CombatOption:
	"""
	Generate a player ghost combat option.
	TODO: Replace with actual ghost team loading from server
	"""
	var rank = randi_range(1, 10)
	var base_reward = GameConstants.GHOST_BASE_REWARD_GOLD + (rank * GameConstants.GHOST_REWARD_PER_RANK)
	var xp_reward = base_reward + GameConstants.GHOST_BONUS_XP

	return CombatOption.create_ghost(
		"Player Ghost (Rank %d)" % rank,
		"Fight another player's team.",
		"res://assets/combat/player_ghost.png",
		rank,
		base_reward,
		xp_reward
	)


# =============================================================================
# COMPATIBILITY - Convert to/from Dictionary for existing code
# =============================================================================

func generate_options_as_dicts(count: int) -> Array:
	"""Generate options as dictionaries for backwards compatibility."""
	var options = generate_options(count)
	var result = []
	for option in options:
		result.append(option.to_dict())
	return result
