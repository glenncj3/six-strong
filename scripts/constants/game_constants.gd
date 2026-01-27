class_name GameConstants
extends RefCounted
# GameConstants - Centralized game configuration values
# All magic numbers and tuning parameters should live here

# =============================================================================
# SCREEN / MOBILE CONSTANTS (Portrait 9:16)
# =============================================================================

const DESIGN_WIDTH := 720
const DESIGN_HEIGHT := 1280

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

# Player level progression (per-run)
const XP_PER_LEVEL := 100  # XP needed to level up during a run
const MAX_PLAYER_LEVEL := 5  # Maximum player level (gates all content at this level)

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

# Performance-based reward scaling
const FAME_REWARD_BASE_VICTORY := 75
const FAME_REWARD_BASE_DEFEAT := 25
const FAME_PER_WIN_BONUS := 5
const GEMS_PER_WIN_BONUS := 5
const GEMS_PER_REPUTATION_BONUS := 2

# Combat rewards
const COMBAT_WIN_GOLD := 20
const COMBAT_WIN_XP := 30  # XP per character per combat win

# =============================================================================
# RUN CONSTANTS
# =============================================================================

# Win/loss conditions
const WINS_FOR_VICTORY := 10
const TEAM_SIZE := 3  # DEPRECATED: Use MAX_GRID_CHARACTERS for Phase 5+
const DRAFT_OPTIONS_PER_PICK := 3
const DRAFT_OWNED_OPTIONS := 2  # Remaining filled by random
const ENCOUNTERS_PER_ROUND := 1  # How many encounters occur before each combat

# Per-character run limits (DEPRECATED: Skills are instant, items unlimited)
const MAX_RUN_ITEMS := 6
const MAX_RUN_SKILLS := 6

# =============================================================================
# CHARACTER GRID CONSTANTS (Phase 5)
# =============================================================================

const GRID_ROWS := 2  # Front row and back row
const GRID_COLS := 3  # 3 characters per row
const MAX_GRID_CHARACTERS := 6  # GRID_ROWS * GRID_COLS - replaces TEAM_SIZE

# =============================================================================
# LEGACY SYSTEM CONSTANTS (Phase 4)
# =============================================================================

const LEGACY_UNLOCK_COST := 500  # Gems to unlock a legacy during draft

# =============================================================================
# STAT NAMES
# =============================================================================
# DEPRECATED: Prefer using StatRegistry for data-driven stat definitions.
# These constants are kept for backwards compatibility.
# Use: StatRegistry.get_all_stat_ids(), StatRegistry.get_display_name(), etc.

# Canonical stat names used throughout the system
const STAT_HEALTH := "health"
const STAT_MANA := "mana"
const STAT_INCOME := "income"
const STAT_DEFEND_RATE := "defendRate"
const STAT_ITEM_SLOTS := "itemSlots"
const STAT_STARTING_ITEM_SLOTS := "startingItemSlots"

# All valid stat names (for validation)
# DEPRECATED: Use StatRegistry.get_all_stat_ids() instead
const ALL_STATS := [
	STAT_HEALTH,
	STAT_MANA,
	STAT_INCOME,
	STAT_DEFEND_RATE,
	STAT_ITEM_SLOTS,
	STAT_STARTING_ITEM_SLOTS
]

# Display abbreviations for stats (used in UI)
# DEPRECATED: Use StatRegistry.get_display_name(stat_id) instead
const STAT_DISPLAY_NAMES := {
	STAT_HEALTH: "HP",
	STAT_MANA: "MP",
	STAT_INCOME: "INC",
	STAT_DEFEND_RATE: "DEF%",
	STAT_ITEM_SLOTS: "SLOTS",
	STAT_STARTING_ITEM_SLOTS: "START"
}

# Default stat values (used when creating new stat blocks)
# DEPRECATED: Use StatRegistry.get_default_stats() instead
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
# DEPRECATED: Prefer using ClassRegistry for data-driven class definitions.
# These constants are kept for backwards compatibility.
# Use: ClassRegistry.get_all_class_ids(), ClassRegistry.get_display_name(), etc.

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

# DEPRECATED: Use ClassRegistry.get_all_class_ids() instead
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

# DEPRECATED: Use ClassRegistry.get_display_name(class_id) instead
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
const COMBAT_IMAGE_SIZE := 100

# Standard margins and spacing
const PANEL_MARGIN := 10
const CONTENT_SEPARATION := 8
const SHOP_ROW_SEPARATION := 12

# Button sizing
const BUTTON_HEIGHT_STANDARD := 50
const BUTTON_WIDTH_STANDARD := 280
const BUTTON_WIDTH_SMALL := 150
const FONT_SIZE_BUTTON := 24
const FONT_SIZE_BUTTON_LARGE := 28

# Font sizes for dynamic UI
const FONT_SIZE_REWARD := 32
const FONT_SIZE_GOLD_DISPLAY := 20

# =============================================================================
# COLOR CONSTANTS - FANTASY AESTHETIC (Hearthstone-inspired)
# =============================================================================

# --- Background Colors ---
const COLOR_BG_DARK := Color("#4A3D34")       # Dark warm brown (main background)
const COLOR_BG_MEDIUM := Color("#6B5A4D")     # Medium taupe (secondary areas)
const COLOR_BG_LIGHT := Color("#8A7565")      # Light taupe (tertiary/hover)

# --- Panel Colors ---
const COLOR_PANEL_DARK := Color("#2E2420")    # Mahogany (panel backgrounds)
const COLOR_PANEL_WARM := Color("#3D2E24")    # Warm brown (elevated panels)

# --- Accent Colors ---
const COLOR_GOLD := Color("#D9A621")          # Primary gold accent
const COLOR_SILVER := Color("#BFC4D1")        # Silver accent
const COLOR_SAPPHIRE := Color("#2D5A8A")      # Button background
const COLOR_SAPPHIRE_LIGHT := Color("#3D6A9A") # Button hover
const COLOR_SAPPHIRE_DARK := Color("#1D4A7A") # Button pressed
const COLOR_BUTTON_SUCCESS := Color("#2A6A3A")       # Green button background
const COLOR_BUTTON_SUCCESS_LIGHT := Color("#3A7A4A") # Green button hover
const COLOR_BUTTON_SUCCESS_DARK := Color("#1A5A2A")  # Green button pressed
const COLOR_BUTTON_DANGER := Color("#6A2A3A")        # Red button background
const COLOR_BUTTON_DANGER_LIGHT := Color("#7A3A4A")  # Red button hover
const COLOR_BUTTON_DANGER_DARK := Color("#5A1A2A")   # Red button pressed
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

# --- Semantic Color Aliases ---
const COLOR_SUCCESS := COLOR_EMERALD
const COLOR_ERROR := COLOR_RUBY
const COLOR_DANGER := COLOR_RUBY
const COLOR_WARNING := COLOR_GOLD
const COLOR_DISABLED := Color("#6A6A6A")
const COLOR_MUTED := COLOR_TEXT_MUTED
const COLOR_HIGHLIGHT := COLOR_TEXT_GOLD

# --- Tile Selection Colors ---
const COLOR_TILE_SELECTED := Color(0.6, 1.0, 0.6)   # Green tint for selected tiles
const COLOR_TILE_DIMMED := Color(0.5, 0.5, 0.5)     # Gray tint for unselected tiles

# Reputation color thresholds
const REPUTATION_CRITICAL_THRESHOLD := 5
const REPUTATION_WARNING_THRESHOLD := 10

# Combat difficulty colors (aliases)
const COLOR_DIFFICULTY_EASY := COLOR_EMERALD
const COLOR_DIFFICULTY_MEDIUM := COLOR_GOLD
const COLOR_DIFFICULTY_HARD := COLOR_RUBY

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

# Combat panel colors per difficulty
static func get_combat_colors(difficulty: String) -> Dictionary:
	match difficulty:
		"Easy":
			return {"bg": COLOR_EMERALD, "hover": Color("#3A9A5A"), "pressed": Color("#1A6A3A"), "border": COLOR_BORDER_GOLD}
		"Medium":
			return {"bg": Color("#8A6A21"), "hover": Color("#AA8A41"), "pressed": Color("#6A4A01"), "border": COLOR_BORDER_GOLD}
		"Hard":
			return {"bg": COLOR_RUBY, "hover": Color("#AA4A5A"), "pressed": Color("#6A1A2A"), "border": COLOR_BORDER_GOLD}
		_:
			return {"bg": COLOR_PANEL_WARM, "hover": Color("#5D4E44"), "pressed": Color("#2D1E14"), "border": COLOR_BORDER_GOLD}

static func get_ghost_combat_colors() -> Dictionary:
	return {"bg": COLOR_AMETHYST, "hover": Color("#8A5AAA"), "pressed": Color("#4A1A6A"), "border": COLOR_BORDER_GOLD}

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
# WHEEL OF FORTUNE CONSTANTS
# =============================================================================

const WHEEL_SPIN_DURATION := 2.5       # Total spin time in seconds
const WHEEL_MAX_SPEED := 1080.0        # Degrees per second (3 rotations/sec)
const WHEEL_DECEL_DURATION := 1.2      # Slowdown phase duration
const WHEEL_BOUNCE_OVERSHOOT := 5.0    # Degrees past target
const WHEEL_BOUNCE_DURATION := 0.3     # Settle time after bounce
const WHEEL_SPINUP_DURATION := 0.3     # Time to reach max speed

# Wheel configuration
const WHEEL_SEGMENT_COUNT := 6         # Number of segments on wheel
const WHEEL_SPIN_AGAIN_COST := 30      # Gold cost for extra spin
const WHEEL_SIZE := 300                # Wheel diameter in pixels

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

# =============================================================================
# ANIMATION CONSTANTS
# =============================================================================

# Animation timing durations
const ANIM_DURATION_INSTANT := 0.1
const ANIM_DURATION_FAST := 0.2
const ANIM_DURATION_NORMAL := 0.3
const ANIM_DURATION_SLOW := 0.5
const ANIM_DURATION_DRAMATIC := 0.8

# Standard easing and transition types
const ANIM_EASE_STANDARD := Tween.EASE_OUT
const ANIM_TRANS_STANDARD := Tween.TRANS_CUBIC
const ANIM_TRANS_BOUNCE := Tween.TRANS_BACK

# Cascade animation delay between elements
const CASCADE_DELAY := 0.05

# =============================================================================
# VISUAL EFFECT CONSTANTS
# =============================================================================

# Button interaction scaling
const HOVER_SCALE := 1.03
const PRESS_SCALE := 0.95

# Card interaction effects
const CARD_HOVER_LIFT := 4.0
const CARD_HOVER_SCALE := 1.05

# =============================================================================
# GLOW COLORS (for rarity-based effects)
# =============================================================================

const GLOW_COLOR_LEGENDARY := Color("#FFD700")
const GLOW_COLOR_EPIC := Color("#9932CC")

# =============================================================================
# SCREEN SHAKE CONSTANTS
# =============================================================================

const SHAKE_INTENSITY_MICRO := 2.0
const SHAKE_INTENSITY_LIGHT := 5.0
const SHAKE_INTENSITY_MEDIUM := 10.0
const SHAKE_INTENSITY_HEAVY := 20.0
const SHAKE_DURATION_SHORT := 0.1
const SHAKE_DURATION_NORMAL := 0.2
const SHAKE_DURATION_LONG := 0.4

# =============================================================================
# TRANSITION TYPES
# =============================================================================

enum TransitionType {
	FADE,          # Default fade to black, fade in
	SLIDE_LEFT,    # Slide out left, slide in from right
	SLIDE_RIGHT,   # Slide out right, slide in from left
	SLIDE_UP,      # Slide out up, slide in from bottom
	SLIDE_DOWN,    # Slide out down, slide in from top
	SCALE,         # Scale down old, scale up new
	DISSOLVE,      # Particle-based dissolve effect
	WIPE_RADIAL,   # Radial wipe from center
	WIPE_HORIZONTAL # Horizontal wipe
}

# =============================================================================
# VISUAL LAYER CONSTANTS (CanvasLayer values)
# =============================================================================

# Layer hierarchy (higher = renders on top):
#   0-99:   Gameplay content (scenes loaded into SceneContainer)
#   100:    Scene transitions (fade, wipe, etc.)
#   150:    Persistent HUD (RunHUD, TeamHUD)
#   200:    Modal popups (reserved for future ModalLayer)
#   250:    Tooltips (reserved for future use)

const LAYER_GAMEPLAY := 0
const LAYER_TRANSITION := 100
const LAYER_HUD := 150
const LAYER_MODAL := 200
const LAYER_TOOLTIP := 250

# =============================================================================
# OVERLAY & SHADOW COLORS (Phase 1 Constants Centralization)
# =============================================================================

const COLOR_OVERLAY_DIM := Color(0, 0, 0, 0.5)       # Modal/popup dim overlay
const COLOR_SHADOW_LIGHT := Color(0, 0, 0, 0.3)     # Light shadow (panel shadows)
const COLOR_SHADOW_DARK := Color(0, 0, 0, 0.7)      # Dark shadow (text shadows)
const COLOR_PLACEHOLDER_TEXT := Color(0.7, 0.7, 0.7) # Gray placeholder text
const COLOR_HIGHLIGHT_TINT := Color(1.2, 1.2, 1.2)  # Brightened highlight modulate
const COLOR_CRITICAL_HIT := Color(1.0, 0.3, 0.3)    # Critical hit damage color

# =============================================================================
# FLOATING NUMBER ANIMATION CONSTANTS
# =============================================================================

const FLOAT_CRITICAL_PEAK_SCALE := 1.5              # Peak scale for critical hits
const FLOAT_CRITICAL_RISE_DISTANCE := 70.0          # Rise distance for critical hits
const FLOAT_CRITICAL_DURATION := 1.2                # Duration for critical hit animation

# =============================================================================
# ENCOUNTER TILE LAYOUT CONSTANTS
# =============================================================================

const ENCOUNTER_TILE_MARGIN := 48.0                 # Margin for tile size calculation
const ENCOUNTER_TILE_SPACING := 8.0                 # Spacing between tiles
const ENCOUNTER_TILE_MIN_SIZE := 180.0              # Minimum tile size

# =============================================================================
# MODAL POPUP CONSTANTS
# =============================================================================

const MODAL_FALLBACK_HALF_SIZE := 150.0             # Fallback half-size when popup has no size
