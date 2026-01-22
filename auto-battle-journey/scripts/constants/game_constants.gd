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
const FAME_PER_PRESTIGE := 100  # Fame needed to increase a character's prestige (persistent)
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
const RUN_CHARACTER_FAME_REWARD := 50  # Fame awarded to each character at run end

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
const STAT_MANA := "mana"
const STAT_INCOME := "income"
const STAT_DEFEND_RATE := "defendRate"
const STAT_ITEM_SLOTS := "itemSlots"
const STAT_STARTING_ITEM_SLOTS := "startingItemSlots"

# All valid stat names (for validation)
const ALL_STATS := [
	STAT_HEALTH,
	STAT_MANA,
	STAT_INCOME,
	STAT_DEFEND_RATE,
	STAT_ITEM_SLOTS,
	STAT_STARTING_ITEM_SLOTS
]

# Display abbreviations for stats (used in UI)
const STAT_DISPLAY_NAMES := {
	STAT_HEALTH: "HP",
	STAT_MANA: "MP",
	STAT_INCOME: "INC",
	STAT_DEFEND_RATE: "DEF%",
	STAT_ITEM_SLOTS: "SLOTS",
	STAT_STARTING_ITEM_SLOTS: "START"
}

# Default stat values (used when creating new stat blocks)
static func get_default_stats() -> Dictionary:
	return {
		STAT_HEALTH: 0,
		STAT_MANA: 0,
		STAT_INCOME: 0,
		STAT_DEFEND_RATE: 0,
		STAT_ITEM_SLOTS: 9,
		STAT_STARTING_ITEM_SLOTS: 0
	}

# =============================================================================
# CHARACTER CLASS TYPES
# =============================================================================

const CLASS_TYPE_WARRIOR := "warrior"
const CLASS_TYPE_MAGE := "mage"
const CLASS_TYPE_ROGUE := "rogue"
const CLASS_TYPE_CLERIC := "cleric"
const CLASS_TYPE_RANGER := "ranger"
const CLASS_TYPE_BERSERKER := "berserker"
const CLASS_TYPE_PALADIN := "paladin"
const CLASS_TYPE_NECROMANCER := "necromancer"
const CLASS_TYPE_MONK := "monk"
const CLASS_TYPE_ASSASSIN := "assassin"

const ALL_CLASS_TYPES := [
	CLASS_TYPE_WARRIOR,
	CLASS_TYPE_MAGE,
	CLASS_TYPE_ROGUE,
	CLASS_TYPE_CLERIC,
	CLASS_TYPE_RANGER,
	CLASS_TYPE_BERSERKER,
	CLASS_TYPE_PALADIN,
	CLASS_TYPE_NECROMANCER,
	CLASS_TYPE_MONK,
	CLASS_TYPE_ASSASSIN
]

const CLASS_TYPE_DISPLAY_NAMES := {
	CLASS_TYPE_WARRIOR: "Warrior",
	CLASS_TYPE_MAGE: "Mage",
	CLASS_TYPE_ROGUE: "Rogue",
	CLASS_TYPE_CLERIC: "Cleric",
	CLASS_TYPE_RANGER: "Ranger",
	CLASS_TYPE_BERSERKER: "Berserker",
	CLASS_TYPE_PALADIN: "Paladin",
	CLASS_TYPE_NECROMANCER: "Necromancer",
	CLASS_TYPE_MONK: "Monk",
	CLASS_TYPE_ASSASSIN: "Assassin"
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
const COLOR_GHOST_PRESTIGE := Color("#6A3A8A")
const COLOR_HIGHLIGHT := Color("#FFD54F")

# Reputation color thresholds
const REPUTATION_CRITICAL_THRESHOLD := 5
const REPUTATION_WARNING_THRESHOLD := 10

# Combat difficulty colors
const COLOR_DIFFICULTY_EASY := Color("#2A7A4A")    # Emerald green
const COLOR_DIFFICULTY_MEDIUM := Color("#D9A621") # Gold
const COLOR_DIFFICULTY_HARD := Color("#8A2A3A")   # Ruby red

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
const GHOST_REWARD_PER_PRESTIGE := 5
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

# =============================================================================
# SKILL STAT NAMES
# =============================================================================

# Core skill stats
const SKILL_STAT_DAMAGE := "damage"
const SKILL_STAT_SPEED := "speed"
const SKILL_STAT_CRIT := "crit"

# Buff stats (improve self or other skills/items)
const SKILL_STAT_DAMAGE_BUFF := "damageBuff"
const SKILL_STAT_SPEED_BUFF := "speedBuff"
const SKILL_STAT_CRIT_BUFF := "critBuff"

# Character bonus
const SKILL_STAT_BONUS_MANA := "bonusMana"

# All valid skill stats (for validation)
const ALL_SKILL_STATS := [
	SKILL_STAT_DAMAGE,
	SKILL_STAT_SPEED,
	SKILL_STAT_CRIT,
	SKILL_STAT_DAMAGE_BUFF,
	SKILL_STAT_SPEED_BUFF,
	SKILL_STAT_CRIT_BUFF,
	SKILL_STAT_BONUS_MANA
]

# Display names for skill stats (used in UI)
const SKILL_STAT_DISPLAY_NAMES := {
	SKILL_STAT_DAMAGE: "DMG",
	SKILL_STAT_SPEED: "SPD",
	SKILL_STAT_CRIT: "CRIT",
	SKILL_STAT_DAMAGE_BUFF: "+DMG",
	SKILL_STAT_SPEED_BUFF: "+SPD",
	SKILL_STAT_CRIT_BUFF: "+CRIT",
	SKILL_STAT_BONUS_MANA: "+MP"
}

# Element types (synergy flags for skills and items)
const ELEMENT_TYPE_FIRE := "fire"
const ELEMENT_TYPE_ICE := "ice"
const ELEMENT_TYPE_LIGHTNING := "lightning"
const ELEMENT_TYPE_EARTH := "earth"
const ELEMENT_TYPE_HOLY := "holy"
const ELEMENT_TYPE_SHADOW := "shadow"

const ALL_ELEMENT_TYPES := [
	ELEMENT_TYPE_FIRE,
	ELEMENT_TYPE_ICE,
	ELEMENT_TYPE_LIGHTNING,
	ELEMENT_TYPE_EARTH,
	ELEMENT_TYPE_HOLY,
	ELEMENT_TYPE_SHADOW
]

const ELEMENT_TYPE_DISPLAY_NAMES := {
	ELEMENT_TYPE_FIRE: "Fire",
	ELEMENT_TYPE_ICE: "Ice",
	ELEMENT_TYPE_LIGHTNING: "Lightning",
	ELEMENT_TYPE_EARTH: "Earth",
	ELEMENT_TYPE_HOLY: "Holy",
	ELEMENT_TYPE_SHADOW: "Shadow"
}

# Default skill stat values (used when creating skill stat blocks)
static func get_default_skill_stats() -> Dictionary:
	return {
		SKILL_STAT_DAMAGE: 0,
		SKILL_STAT_SPEED: 0.0,
		SKILL_STAT_CRIT: 0,
		SKILL_STAT_DAMAGE_BUFF: 0,
		SKILL_STAT_SPEED_BUFF: 0.0,
		SKILL_STAT_CRIT_BUFF: 0,
		SKILL_STAT_BONUS_MANA: 0
	}

# =============================================================================
# ITEM STAT NAMES
# =============================================================================

# Item stats (type uses ALL_ELEMENT_TYPES for synergies)
const ITEM_STAT_SPEED := "speed"
const ITEM_STAT_DAMAGE_BUFF := "damageBuff"
const ITEM_STAT_SPEED_BUFF := "speedBuff"
const ITEM_STAT_CRIT_BUFF := "critBuff"
const ITEM_STAT_BONUS_MANA := "bonusMana"

# All valid item stats (for validation)
const ALL_ITEM_STATS := [
	ITEM_STAT_SPEED,
	ITEM_STAT_DAMAGE_BUFF,
	ITEM_STAT_SPEED_BUFF,
	ITEM_STAT_CRIT_BUFF,
	ITEM_STAT_BONUS_MANA
]

# Display names for item stats (used in UI)
const ITEM_STAT_DISPLAY_NAMES := {
	ITEM_STAT_SPEED: "SPD",
	ITEM_STAT_DAMAGE_BUFF: "+DMG",
	ITEM_STAT_SPEED_BUFF: "+SPD",
	ITEM_STAT_CRIT_BUFF: "+CRIT",
	ITEM_STAT_BONUS_MANA: "+MP"
}

# Default item stat values (used when creating item stat blocks)
static func get_default_item_stats() -> Dictionary:
	return {
		ITEM_STAT_SPEED: 0.0,
		ITEM_STAT_DAMAGE_BUFF: 0,
		ITEM_STAT_SPEED_BUFF: 0.0,
		ITEM_STAT_CRIT_BUFF: 0,
		ITEM_STAT_BONUS_MANA: 0
	}
