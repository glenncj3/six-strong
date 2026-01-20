class_name GameConstants
extends RefCounted
# GameConstants - Centralized game configuration values
# All magic numbers and tuning parameters should live here

# =============================================================================
# SCREEN / MOBILE CONSTANTS (Portrait 9:16)
# =============================================================================

const DESIGN_WIDTH := 720
const DESIGN_HEIGHT := 1280

# UI margins for mobile (smaller for portrait mode)
const SCREEN_MARGIN := 16
const SCREEN_MARGIN_SMALL := 8

# Component sizes optimized for portrait mobile
const CHARACTER_CARD_WIDTH := 200
const CHARACTER_CARD_HEIGHT := 280
const CHARACTER_CARD_SMALL_WIDTH := 100
const CHARACTER_CARD_SMALL_HEIGHT := 140

const ITEM_SLOT_WIDTH := 72
const ITEM_SLOT_HEIGHT := 90
const ITEM_ICON_SIZE := 56

const SKILL_ICON_WIDTH := 56
const SKILL_ICON_HEIGHT := 70
const SKILL_ICON_IMAGE_SIZE := 40

# Font sizes for mobile
const FONT_SIZE_TITLE := 48
const FONT_SIZE_HEADING := 24
const FONT_SIZE_BODY := 18
const FONT_SIZE_SMALL := 14
const FONT_SIZE_TINY := 12

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


# =============================================================================
# UI CONSTANTS
# =============================================================================

# Icon sizes used in shop rows, encounter panels, etc.
const SHOP_ICON_SIZE := 48
const ENCOUNTER_IMAGE_SIZE := 180
const COMBAT_IMAGE_SIZE := 100

# Standard margins and spacing
const PANEL_MARGIN := 10
const CONTENT_SEPARATION := 8
const SHOP_ROW_SEPARATION := 12

# Font sizes for dynamic UI
const FONT_SIZE_REWARD := 32
const FONT_SIZE_GOLD_DISPLAY := 20

# =============================================================================
# COLOR CONSTANTS
# =============================================================================

const COLOR_GOLD := Color(1.0, 0.84, 0.0)
const COLOR_SUCCESS := Color(0.3, 1.0, 0.3)
const COLOR_ERROR := Color(1.0, 0.5, 0.5)
const COLOR_DANGER := Color(1.0, 0.3, 0.3)
const COLOR_WARNING := Color(1.0, 0.7, 0.3)
const COLOR_DISABLED := Color(0.7, 0.7, 0.7)
const COLOR_MUTED := Color(0.8, 0.8, 0.8)
const COLOR_GHOST_RANK := Color(0.5, 0.5, 1.0)
const COLOR_HIGHLIGHT := Color(1.3, 1.3, 1.0)

# Reputation color thresholds
const REPUTATION_CRITICAL_THRESHOLD := 5
const REPUTATION_WARNING_THRESHOLD := 10

# =============================================================================
# EMOJI CONSTANTS
# =============================================================================

const EMOJI_GEM := "💎"
const EMOJI_REROLL := "🎫"
const EMOJI_HEART := "❤️"
const EMOJI_STAR := "⭐"
const EMOJI_GOLD := "💰"

# =============================================================================
# COMBAT CONSTANTS
# =============================================================================

# Difficulty settings
const COMBAT_DIFFICULTIES := ["Easy", "Medium", "Hard"]

# Base rewards for combat
const AI_BASE_REWARD_GOLD := 20
const AI_REWARD_PER_DIFFICULTY := 10
const AI_BONUS_XP := 10
const GHOST_BASE_REWARD_GOLD := 25
const GHOST_REWARD_PER_RANK := 5
const GHOST_BONUS_XP := 15

# =============================================================================
# ENCOUNTER CONSTANTS
# =============================================================================

# Shop inventory generation
const SHOP_MIN_ITEMS := 2
const SHOP_MAX_ITEMS := 4
const SHOP_MIN_SKILLS := 1
const SHOP_MAX_SKILLS := 2
const SHOP_ITEM_MIN_COST := 10
const SHOP_ITEM_MAX_COST := 30
const SHOP_SKILL_MIN_COST := 15
const SHOP_SKILL_MAX_COST := 40

# XP reward range
const XP_REWARD_MIN := 30
const XP_REWARD_MAX := 80

# Gold reward range
const GOLD_REWARD_MIN := 20
const GOLD_REWARD_MAX := 50

# Health restore
const HEALTH_RESTORE_PERCENTAGE := 0.5

# Scaling per round
const ROUND_SCALE_FACTOR := 0.1
