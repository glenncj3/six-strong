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
# COLOR CONSTANTS - FANTASY AESTHETIC (Hearthstone-inspired)
# =============================================================================

# --- Background Colors ---
const COLOR_BG_DARK := Color("#1E1C2E")       # Dark purple-black (main background)
const COLOR_BG_MEDIUM := Color("#292438")     # Medium purple (secondary areas)
const COLOR_BG_LIGHT := Color("#383148")      # Light purple (tertiary/hover)

# --- Panel Colors ---
const COLOR_PANEL_DARK := Color("#2E2420")    # Mahogany (panel backgrounds)
const COLOR_PANEL_WARM := Color("#3D2E24")    # Warm brown (elevated panels)

# --- Accent Colors ---
const COLOR_GOLD := Color("#D9A621")          # Primary gold accent
const COLOR_SILVER := Color("#BFC4D1")        # Silver accent
const COLOR_SAPPHIRE := Color("#2D5A8A")      # Button background
const COLOR_SAPPHIRE_LIGHT := Color("#3D6A9A") # Button hover
const COLOR_SAPPHIRE_DARK := Color("#1D4A7A") # Button pressed
const COLOR_EMERALD := Color("#2A7A4A")       # Success/health
const COLOR_RUBY := Color("#8A2A3A")          # Danger/damage
const COLOR_AMETHYST := Color("#6A3A8A")      # Magic/special

# --- Text Colors ---
const COLOR_TEXT_LIGHT := Color("#F2EBD9")    # Warm parchment (primary text)
const COLOR_TEXT_MUTED := Color("#B8A88A")    # Muted tan (secondary text)
const COLOR_TEXT_GOLD := Color("#FFD54F")     # Golden highlight text

# --- Border Colors ---
const COLOR_BORDER_GOLD := Color("#B88726")   # Antique gold borders
const COLOR_BORDER_SILVER := Color("#8A8A9A") # Tarnished silver borders

# --- Rarity Colors ---
const COLOR_RARITY_COMMON := Color("#9A9A9A")     # Gray
const COLOR_RARITY_UNCOMMON := Color("#4A8A4A")  # Green
const COLOR_RARITY_RARE := Color("#4A6AAA")      # Blue
const COLOR_RARITY_EPIC := Color("#8A4A9A")      # Purple
const COLOR_RARITY_LEGENDARY := Color("#D9A621") # Gold

# --- Legacy Color Constants (for compatibility) ---
const COLOR_SUCCESS := Color("#2A7A4A")
const COLOR_ERROR := Color("#8A2A3A")
const COLOR_DANGER := Color("#8A2A3A")
const COLOR_WARNING := Color("#D9A621")
const COLOR_DISABLED := Color("#6A6A6A")
const COLOR_MUTED := Color("#B8A88A")
const COLOR_GHOST_RANK := Color("#6A3A8A")
const COLOR_HIGHLIGHT := Color("#FFD54F")

# Reputation color thresholds
const REPUTATION_CRITICAL_THRESHOLD := 5
const REPUTATION_WARNING_THRESHOLD := 10

# Combat difficulty colors
const COLOR_DIFFICULTY_EASY := Color("#2A7A4A")    # Emerald green
const COLOR_DIFFICULTY_MEDIUM := Color("#D9A621") # Gold
const COLOR_DIFFICULTY_HARD := Color("#8A2A3A")   # Ruby red

# =============================================================================
# CLICKABLE PANEL COLORS - Normal/Hover/Pressed states
# =============================================================================

# Combat panel colors by type/difficulty
const COLOR_COMBAT_EASY_NORMAL := Color("#2A7A4A")    # Emerald green
const COLOR_COMBAT_EASY_HOVER := Color("#3A9A5A")
const COLOR_COMBAT_EASY_PRESSED := Color("#1A6A3A")

const COLOR_COMBAT_MEDIUM_NORMAL := Color("#8A6A21")  # Gold-brown
const COLOR_COMBAT_MEDIUM_HOVER := Color("#AA8A41")
const COLOR_COMBAT_MEDIUM_PRESSED := Color("#6A4A01")

const COLOR_COMBAT_HARD_NORMAL := Color("#8A2A3A")    # Ruby red
const COLOR_COMBAT_HARD_HOVER := Color("#AA4A5A")
const COLOR_COMBAT_HARD_PRESSED := Color("#6A1A2A")

const COLOR_COMBAT_GHOST_NORMAL := Color("#6A3A8A")   # Amethyst purple
const COLOR_COMBAT_GHOST_HOVER := Color("#8A5AAA")
const COLOR_COMBAT_GHOST_PRESSED := Color("#4A1A6A")

# Encounter panel colors by type
const COLOR_ENCOUNTER_SHOP_NORMAL := Color("#5A4A3A")    # Warm brown (commerce)
const COLOR_ENCOUNTER_SHOP_HOVER := Color("#7A6A5A")
const COLOR_ENCOUNTER_SHOP_PRESSED := Color("#3A2A1A")

const COLOR_ENCOUNTER_XP_NORMAL := Color("#2D5A8A")      # Sapphire blue (growth)
const COLOR_ENCOUNTER_XP_HOVER := Color("#4D7AAA")
const COLOR_ENCOUNTER_XP_PRESSED := Color("#1D4A7A")

const COLOR_ENCOUNTER_GOLD_NORMAL := Color("#8A7A21")    # Gold (wealth)
const COLOR_ENCOUNTER_GOLD_HOVER := Color("#AA9A41")
const COLOR_ENCOUNTER_GOLD_PRESSED := Color("#6A5A01")

const COLOR_ENCOUNTER_HEALTH_NORMAL := Color("#2A7A4A")  # Emerald green (life)
const COLOR_ENCOUNTER_HEALTH_HOVER := Color("#4A9A6A")
const COLOR_ENCOUNTER_HEALTH_PRESSED := Color("#1A5A3A")

const COLOR_ENCOUNTER_SKILL_NORMAL := Color("#6A3A8A")   # Amethyst purple (magic)
const COLOR_ENCOUNTER_SKILL_HOVER := Color("#8A5AAA")
const COLOR_ENCOUNTER_SKILL_PRESSED := Color("#4A1A6A")

const COLOR_ENCOUNTER_GAMBLE_NORMAL := Color("#8A2A3A")  # Ruby red (risk)
const COLOR_ENCOUNTER_GAMBLE_HOVER := Color("#AA4A5A")
const COLOR_ENCOUNTER_GAMBLE_PRESSED := Color("#6A1A2A")

const COLOR_ENCOUNTER_ELITE_NORMAL := Color("#8A5A2A")   # Warm orange (challenge)
const COLOR_ENCOUNTER_ELITE_HOVER := Color("#AA7A4A")
const COLOR_ENCOUNTER_ELITE_PRESSED := Color("#6A3A1A")

# Border colors for clickable panels
const COLOR_PANEL_BORDER_NORMAL := Color("#B88726")      # Gold border
const COLOR_PANEL_BORDER_HOVER := Color("#D9A621")       # Brighter gold on hover

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
