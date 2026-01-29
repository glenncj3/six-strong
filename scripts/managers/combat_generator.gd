class_name CombatGenerator
extends RefCounted
# CombatGenerator - Generates combat options for the combat phase
# Extracted from RunManager for Single Responsibility Principle
# Uses CombatOption typed class for better type safety

# Predefined enemy team templates: arrays of 6 character IDs
# Each template fills the 2x3 grid (front row [0-2], back row [3-5])
const ENEMY_TEAMS = [
	# --- Easy teams (3 characters, front row only) ---
	{"chars": ["ST01", "ST02", "ST03"]},
	{"chars": ["LA01", "LA02", "LA03"]},
	{"chars": ["TA01", "TA02", "TA03"]},
	{"chars": ["ST02", "LA01", "TA01"]},

	# --- Medium teams (4 characters, front row + 1 back) ---
	{"chars": ["ST05", "ST06", "ST07", "ST04"]},
	{"chars": ["LA05", "LA06", "LA07", "LA04"]},
	{"chars": ["TA05", "TA06", "TA07", "TA04"]},
	{"chars": ["ST05", "LA05", "TA05", "ST04"]},

	# --- Hard teams (6 characters, full grid) ---
	{"chars": ["ST08", "ST09", "ST10", "ST05", "ST06", "ST07"]},
	{"chars": ["LA08", "LA09", "LA10", "LA05", "LA06", "LA07"]},
	{"chars": ["TA08", "TA09", "TA10", "TA05", "TA06", "TA07"]},
	{"chars": ["ST10", "LA10", "TA10", "ST08", "LA08", "TA08"]},
]


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

	# Get colors based on difficulty
	var colors = GameConstants.get_combat_colors(difficulty)

	var option = CombatOption.create_ai(
		"AI Enemy (%s)" % difficulty,
		"Fight an AI-controlled enemy.",
		"res://assets/combat/ai_enemy.png",
		difficulty,
		base_reward,
		xp_reward,
		colors.bg,
		colors.hover,
		colors.pressed,
		colors.border
	)
	option.enemy_team = _build_enemy_team(difficulty_index)
	return option


func _generate_player_ghost_option() -> CombatOption:
	"""
	Generate a player ghost combat option.
	TODO: Replace with actual ghost team loading from server
	"""
	var prestige = randi_range(1, 10)
	var base_reward = GameConstants.GHOST_BASE_REWARD_GOLD + (prestige * GameConstants.GHOST_REWARD_PER_PRESTIGE)
	var xp_reward = base_reward + GameConstants.GHOST_BONUS_XP

	# Ghost uses amethyst purple
	var colors = GameConstants.get_ghost_combat_colors()
	var option = CombatOption.create_ghost(
		"Player Ghost (Prestige %d)" % prestige,
		"Fight another player's team.",
		"res://assets/combat/player_ghost.png",
		prestige,
		base_reward,
		xp_reward,
		colors.bg,
		colors.hover,
		colors.pressed,
		colors.border
	)
	# Scale team strength loosely with prestige (0=easy templates, 9=any)
	var strength = clampi(int(prestige / 3.0), 0, 2)
	option.enemy_team = _build_enemy_team(strength)
	return option


# =============================================================================
# ENEMY TEAM BUILDING
# =============================================================================

func _build_enemy_team(strength_tier: int) -> CharacterGrid:
	"""
	Build a 6-character enemy team from predefined templates.

	Args:
		strength_tier: 0 = Easy (generics preferred), 1 = Medium, 2 = Hard (any)

	Returns:
		A populated CharacterGrid with 6 characters
	"""
	if ENEMY_TEAMS.is_empty():
		push_warning("CombatGenerator: No enemy team templates defined")
		return CharacterGrid.new()

	# Pick template from appropriate tier (4 templates per tier)
	var templates_per_tier = 4
	var tier_start = clampi(strength_tier * templates_per_tier, 0, ENEMY_TEAMS.size() - templates_per_tier)
	var template = ENEMY_TEAMS[tier_start + (randi() % templates_per_tier)]
	var grid = CharacterGrid.new()

	for i in range(template["chars"].size()):
		var char_id = template["chars"][i]
		var character = CharacterInstance.from_master_data(char_id)
		if character == null:
			push_warning("CombatGenerator: Failed to create character %s" % char_id)
			continue

		# Place in grid: first GRID_COLS in front row, next GRID_COLS in back row
		@warning_ignore("integer_division")
		var row: int = i / GameConstants.GRID_COLS
		var col = i % GameConstants.GRID_COLS
		grid.place_character(character, row, col)

	return grid


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
