class_name CombatGenerator
extends RefCounted
# CombatGenerator - Generates combat options for the combat phase
# Extracted from RunManager for Single Responsibility Principle
# Uses CombatOption typed class for better type safety

# Predefined enemy team templates: arrays of 6 character IDs
# Each template fills the 2x3 grid (front row [0-2], back row [3-5])
const ENEMY_TEAMS = [
	# Balanced - knight front, mage back
	{
		"name": "Iron Vanguard",
		"chars": ["char_warrior_001", "char_paladin_001", "char_shieldbearer_001",
				  "char_mage_001", "char_ranger_001", "char_cleric_001"]
	},
	# Aggressive - berserkers and assassins
	{
		"name": "Blood Reavers",
		"chars": ["char_berserker_001", "char_warchief_001", "char_monk_001",
				  "char_assassin_001", "char_necromancer_001", "char_rogue_001"]
	},
	# Defensive - tanks front, support back
	{
		"name": "Stone Wall",
		"chars": ["char_shieldbearer_001", "char_paladin_001", "char_warden_001",
				  "char_cleric_001", "char_generic_healer", "char_generic_guard"]
	},
	# Speed - fast strikers
	{
		"name": "Shadow Fangs",
		"chars": ["char_rogue_001", "char_assassin_001", "char_monk_001",
				  "char_ranger_001", "char_generic_scout", "char_beastmaster_001"]
	},
	# Magic heavy
	{
		"name": "Arcane Circle",
		"chars": ["char_warden_001", "char_monk_001", "char_paladin_001",
				  "char_mage_001", "char_necromancer_001", "char_generic_mage"]
	},
	# Mercenary rabble - all generics
	{
		"name": "Hired Blades",
		"chars": ["char_generic_soldier", "char_generic_guard", "char_generic_scout",
				  "char_generic_archer", "char_generic_mage", "char_generic_healer"]
	},
	# Warlord's army
	{
		"name": "Warlord's Host",
		"chars": ["char_warchief_001", "char_berserker_001", "char_warrior_001",
				  "char_generic_soldier", "char_generic_archer", "char_beastmaster_001"]
	},
	# Nature's wrath
	{
		"name": "Wild Hunt",
		"chars": ["char_beastmaster_001", "char_warden_001", "char_ranger_001",
				  "char_monk_001", "char_generic_scout", "char_rogue_001"]
	},
	# Dark forces
	{
		"name": "Cult of Shadows",
		"chars": ["char_necromancer_001", "char_assassin_001", "char_rogue_001",
				  "char_generic_mage", "char_generic_scout", "char_monk_001"]
	},
	# Holy crusade
	{
		"name": "Sacred Order",
		"chars": ["char_paladin_001", "char_warrior_001", "char_shieldbearer_001",
				  "char_cleric_001", "char_warden_001", "char_generic_healer"]
	},
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
	var template = ENEMY_TEAMS[randi() % ENEMY_TEAMS.size()]
	var grid = CharacterGrid.new()

	for i in range(template["chars"].size()):
		var char_id = template["chars"][i]
		var character = CharacterInstance.from_master_data(char_id)
		if character == null:
			push_warning("CombatGenerator: Failed to create character %s" % char_id)
			continue

		# Scale stats by strength tier
		if strength_tier > 0:
			var multiplier = 1.0 + (strength_tier * 0.15)
			for stat_key in character.stats:
				if stat_key == GameConstants.STAT_DEFEND_RATE or stat_key == GameConstants.STAT_CRIT_CHANCE:
					continue  # Don't scale rate-based stats
				character.stats[stat_key] = int(character.stats[stat_key] * multiplier)
			character.current_health = character.stats.get(GameConstants.STAT_HEALTH, character.current_health)

		# Place in grid: first GRID_COLS in front row, next GRID_COLS in back row
		var row = int(i / GameConstants.GRID_COLS)
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
