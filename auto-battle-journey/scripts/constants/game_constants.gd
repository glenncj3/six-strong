class_name GameConstants
extends RefCounted
# GameConstants - Centralized game configuration values
# All magic numbers and tuning parameters should live here

# =============================================================================
# PROGRESSION CONSTANTS
# =============================================================================

# Account progression
const XP_PER_RANK := 100  # XP needed to rank up a character (persistent)
const XP_PER_LEVEL := 100  # XP needed to level up during a run

# Starting resources
const STARTING_GEMS := 1000
const STARTING_REROLL_TOKENS := 0
const STARTING_REPUTATION := 20

# =============================================================================
# ECONOMY CONSTANTS
# =============================================================================

# Character costs
const CHARACTER_UNLOCK_COST := 500  # Gems to unlock a new character in draft

# Run rewards
const VICTORY_GEM_REWARD := 100
const DEFEAT_GEM_REWARD := 25
const RUN_CHARACTER_XP_REWARD := 50  # XP awarded to each character at run end

# Combat rewards
const COMBAT_WIN_GOLD := 20
const COMBAT_WIN_XP := 30  # XP per character per combat win

# =============================================================================
# RUN CONSTANTS
# =============================================================================

# Win/loss conditions
const WINS_FOR_VICTORY := 10
const TEAM_SIZE := 3

# =============================================================================
# STAT NAMES
# =============================================================================

# Canonical stat names used throughout the system
const STAT_HEALTH := "health"
const STAT_ATTACK := "basic_attack_damage"
const STAT_SPEED := "speed"
const STAT_DEFENSE := "defense"
const STAT_INCOME := "income"

# All valid stat names (for validation)
const ALL_STATS := [
	STAT_HEALTH,
	STAT_ATTACK,
	STAT_SPEED,
	STAT_DEFENSE,
	STAT_INCOME
]

# Default stat values (used when creating new stat blocks)
static func get_default_stats() -> Dictionary:
	return {
		STAT_HEALTH: 0,
		STAT_ATTACK: 0,
		STAT_SPEED: 0,
		STAT_DEFENSE: 0,
		STAT_INCOME: 0
	}
