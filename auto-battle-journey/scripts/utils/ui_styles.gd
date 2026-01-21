class_name UIStyles
extends RefCounted
# UIStyles - StyleBox factory for consistent panel/button styling
# Provides pre-configured styles with borders, shadows, and rounded corners

# =============================================================================
# STYLE CONSTANTS
# =============================================================================

const CORNER_RADIUS_SMALL := 4
const CORNER_RADIUS_MEDIUM := 8
const CORNER_RADIUS_LARGE := 12

const BORDER_WIDTH_THIN := 1
const BORDER_WIDTH_NORMAL := 2
const BORDER_WIDTH_THICK := 3

const SHADOW_OFFSET := Vector2(2, 2)
const SHADOW_SIZE := 4

# =============================================================================
# PANEL STYLES
# =============================================================================

static func create_panel_style(
	bg_color: Color = GameConstants.COLOR_PANEL_DARK,
	border_color: Color = GameConstants.COLOR_BORDER_GOLD,
	border_width: int = BORDER_WIDTH_NORMAL,
	corner_radius: int = CORNER_RADIUS_MEDIUM,
	with_shadow: bool = true
) -> StyleBoxFlat:
	"""
	Create a styled panel background.

	Args:
		bg_color: Background fill color
		border_color: Border color
		border_width: Border thickness in pixels
		corner_radius: Corner rounding in pixels
		with_shadow: Whether to add drop shadow

	Returns:
		Configured StyleBoxFlat
	"""
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color

	# Corner radius
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius

	# Border
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.border_color = border_color

	# Shadow
	if with_shadow:
		style.shadow_color = Color(0, 0, 0, 0.3)
		style.shadow_offset = SHADOW_OFFSET
		style.shadow_size = SHADOW_SIZE

	return style


static func create_dark_panel() -> StyleBoxFlat:
	"""Create a dark panel with gold border (for main containers)."""
	return create_panel_style(
		GameConstants.COLOR_PANEL_DARK,
		GameConstants.COLOR_BORDER_GOLD,
		BORDER_WIDTH_NORMAL,
		CORNER_RADIUS_MEDIUM,
		true
	)


static func create_warm_panel() -> StyleBoxFlat:
	"""Create a warm brown panel with gold border (for elevated content)."""
	return create_panel_style(
		GameConstants.COLOR_PANEL_WARM,
		GameConstants.COLOR_BORDER_GOLD,
		BORDER_WIDTH_NORMAL,
		CORNER_RADIUS_MEDIUM,
		true
	)


static func create_card_panel(rarity: String = "common") -> StyleBoxFlat:
	"""
	Create a character card panel with rarity-based border.

	Args:
		rarity: "common", "uncommon", "rare", "epic", "legendary"

	Returns:
		Styled panel with appropriate border color
	"""
	var border_color = get_rarity_color(rarity)
	return create_panel_style(
		GameConstants.COLOR_PANEL_DARK,
		border_color,
		BORDER_WIDTH_NORMAL,
		CORNER_RADIUS_MEDIUM,
		true
	)


static func create_subtle_panel() -> StyleBoxFlat:
	"""Create a subtle panel with silver border (for secondary content)."""
	return create_panel_style(
		GameConstants.COLOR_BG_MEDIUM,
		GameConstants.COLOR_BORDER_SILVER,
		BORDER_WIDTH_THIN,
		CORNER_RADIUS_SMALL,
		false
	)


static func create_transparent_panel(border_color: Color = GameConstants.COLOR_BORDER_GOLD) -> StyleBoxFlat:
	"""Create a transparent panel with only a border (for overlays)."""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)

	style.corner_radius_top_left = CORNER_RADIUS_MEDIUM
	style.corner_radius_top_right = CORNER_RADIUS_MEDIUM
	style.corner_radius_bottom_left = CORNER_RADIUS_MEDIUM
	style.corner_radius_bottom_right = CORNER_RADIUS_MEDIUM

	style.border_width_left = BORDER_WIDTH_THIN
	style.border_width_right = BORDER_WIDTH_THIN
	style.border_width_top = BORDER_WIDTH_THIN
	style.border_width_bottom = BORDER_WIDTH_THIN
	style.border_color = border_color

	return style


# =============================================================================
# BUTTON STYLES
# =============================================================================

static func create_button_normal() -> StyleBoxFlat:
	"""Create normal state button style."""
	return create_panel_style(
		GameConstants.COLOR_SAPPHIRE,
		GameConstants.COLOR_BORDER_GOLD,
		BORDER_WIDTH_NORMAL,
		CORNER_RADIUS_MEDIUM,
		true
	)


static func create_button_hover() -> StyleBoxFlat:
	"""Create hover state button style."""
	return create_panel_style(
		GameConstants.COLOR_SAPPHIRE_LIGHT,
		GameConstants.COLOR_GOLD,
		BORDER_WIDTH_NORMAL,
		CORNER_RADIUS_MEDIUM,
		true
	)


static func create_button_pressed() -> StyleBoxFlat:
	"""Create pressed state button style."""
	var style = create_panel_style(
		GameConstants.COLOR_SAPPHIRE_DARK,
		GameConstants.COLOR_BORDER_GOLD,
		BORDER_WIDTH_NORMAL,
		CORNER_RADIUS_MEDIUM,
		false  # No shadow when pressed
	)
	return style


static func create_button_disabled() -> StyleBoxFlat:
	"""Create disabled state button style."""
	return create_panel_style(
		GameConstants.COLOR_BG_LIGHT,
		GameConstants.COLOR_BORDER_SILVER,
		BORDER_WIDTH_THIN,
		CORNER_RADIUS_MEDIUM,
		false
	)


static func apply_button_styles(button: Button) -> void:
	"""
	Apply full fantasy button styling to a button.

	Args:
		button: The Button node to style
	"""
	button.add_theme_stylebox_override("normal", create_button_normal())
	button.add_theme_stylebox_override("hover", create_button_hover())
	button.add_theme_stylebox_override("pressed", create_button_pressed())
	button.add_theme_stylebox_override("disabled", create_button_disabled())
	button.add_theme_stylebox_override("focus", create_button_normal())

	# Text colors
	button.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	button.add_theme_color_override("font_hover_color", GameConstants.COLOR_TEXT_GOLD)
	button.add_theme_color_override("font_pressed_color", GameConstants.COLOR_TEXT_LIGHT)
	button.add_theme_color_override("font_disabled_color", GameConstants.COLOR_DISABLED)
	button.add_theme_color_override("font_focus_color", GameConstants.COLOR_TEXT_LIGHT)


# =============================================================================
# SPECIAL STYLES
# =============================================================================

static func create_separator_style() -> StyleBoxFlat:
	"""Create a styled horizontal separator."""
	var style = StyleBoxFlat.new()
	style.bg_color = GameConstants.COLOR_BORDER_GOLD
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	return style


static func create_progress_bar_bg() -> StyleBoxFlat:
	"""Create progress bar background style."""
	return create_panel_style(
		GameConstants.COLOR_BG_LIGHT,
		GameConstants.COLOR_BORDER_SILVER,
		BORDER_WIDTH_THIN,
		CORNER_RADIUS_SMALL,
		false
	)


static func create_progress_bar_fill(color: Color = GameConstants.COLOR_GOLD) -> StyleBoxFlat:
	"""Create progress bar fill style."""
	var style = StyleBoxFlat.new()
	style.bg_color = color

	style.corner_radius_top_left = CORNER_RADIUS_SMALL
	style.corner_radius_top_right = CORNER_RADIUS_SMALL
	style.corner_radius_bottom_left = CORNER_RADIUS_SMALL
	style.corner_radius_bottom_right = CORNER_RADIUS_SMALL

	return style


static func apply_progress_bar_styles(progress_bar: ProgressBar, fill_color: Color = GameConstants.COLOR_GOLD) -> void:
	"""
	Apply fantasy styling to a progress bar.

	Args:
		progress_bar: The ProgressBar node to style
		fill_color: Color for the fill portion
	"""
	progress_bar.add_theme_stylebox_override("background", create_progress_bar_bg())
	progress_bar.add_theme_stylebox_override("fill", create_progress_bar_fill(fill_color))


# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

static func get_rarity_color(rarity: String) -> Color:
	"""
	Get border color for a rarity level.

	Args:
		rarity: "common", "uncommon", "rare", "epic", "legendary"

	Returns:
		Appropriate color from GameConstants
	"""
	match rarity.to_lower():
		"common":
			return GameConstants.COLOR_RARITY_COMMON
		"uncommon":
			return GameConstants.COLOR_RARITY_UNCOMMON
		"rare":
			return GameConstants.COLOR_RARITY_RARE
		"epic":
			return GameConstants.COLOR_RARITY_EPIC
		"legendary":
			return GameConstants.COLOR_RARITY_LEGENDARY
		_:
			return GameConstants.COLOR_BORDER_SILVER


static func apply_panel_style(panel: PanelContainer, style: StyleBoxFlat = null) -> void:
	"""
	Apply a style to a PanelContainer.

	Args:
		panel: The PanelContainer to style
		style: StyleBoxFlat to apply (defaults to dark panel)
	"""
	if style == null:
		style = create_dark_panel()
	panel.add_theme_stylebox_override("panel", style)


static func apply_text_color(control: Control, color: Color = GameConstants.COLOR_TEXT_LIGHT) -> void:
	"""
	Apply text color to a control (Label or RichTextLabel).

	Args:
		control: The control to style
		color: Text color to apply
	"""
	if control is Label:
		control.add_theme_color_override("font_color", color)
	elif control is RichTextLabel:
		control.add_theme_color_override("default_color", color)


# =============================================================================
# CLICKABLE PANEL STYLES
# =============================================================================

static func create_clickable_panel_styles(
	normal_color: Color,
	hover_color: Color,
	pressed_color: Color,
	border_color: Color = GameConstants.COLOR_PANEL_BORDER_NORMAL,
	hover_border_color: Color = GameConstants.COLOR_PANEL_BORDER_HOVER
) -> Dictionary:
	"""
	Create a set of styles for clickable panels (normal, hover, pressed states).

	Args:
		normal_color: Background color for normal state
		hover_color: Background color for hover state
		pressed_color: Background color for pressed state
		border_color: Border color for normal/pressed states
		hover_border_color: Border color for hover state

	Returns:
		Dictionary with "normal", "hover", "pressed" StyleBoxFlat entries
	"""
	var normal_style = create_panel_style(
		normal_color,
		border_color,
		BORDER_WIDTH_NORMAL,
		CORNER_RADIUS_MEDIUM,
		true
	)

	var hover_style = create_panel_style(
		hover_color,
		hover_border_color,
		BORDER_WIDTH_NORMAL,
		CORNER_RADIUS_MEDIUM,
		true
	)

	var pressed_style = create_panel_style(
		pressed_color,
		border_color,
		BORDER_WIDTH_NORMAL,
		CORNER_RADIUS_MEDIUM,
		false  # No shadow when pressed
	)

	return {
		"normal": normal_style,
		"hover": hover_style,
		"pressed": pressed_style
	}


static func get_combat_panel_styles(combat_type: String, difficulty: String = "") -> Dictionary:
	"""
	Get clickable panel styles for a combat option based on type and difficulty.

	Args:
		combat_type: "ai" or "ghost"
		difficulty: For AI combats: "Easy", "Medium", "Hard"

	Returns:
		Dictionary with "normal", "hover", "pressed" StyleBoxFlat entries
	"""
	if combat_type == "ghost":
		return create_clickable_panel_styles(
			GameConstants.COLOR_COMBAT_GHOST_NORMAL,
			GameConstants.COLOR_COMBAT_GHOST_HOVER,
			GameConstants.COLOR_COMBAT_GHOST_PRESSED
		)

	# AI combat - based on difficulty
	match difficulty:
		"Easy":
			return create_clickable_panel_styles(
				GameConstants.COLOR_COMBAT_EASY_NORMAL,
				GameConstants.COLOR_COMBAT_EASY_HOVER,
				GameConstants.COLOR_COMBAT_EASY_PRESSED
			)
		"Medium":
			return create_clickable_panel_styles(
				GameConstants.COLOR_COMBAT_MEDIUM_NORMAL,
				GameConstants.COLOR_COMBAT_MEDIUM_HOVER,
				GameConstants.COLOR_COMBAT_MEDIUM_PRESSED
			)
		"Hard":
			return create_clickable_panel_styles(
				GameConstants.COLOR_COMBAT_HARD_NORMAL,
				GameConstants.COLOR_COMBAT_HARD_HOVER,
				GameConstants.COLOR_COMBAT_HARD_PRESSED
			)
		_:
			# Default to medium for unknown difficulty
			return create_clickable_panel_styles(
				GameConstants.COLOR_COMBAT_MEDIUM_NORMAL,
				GameConstants.COLOR_COMBAT_MEDIUM_HOVER,
				GameConstants.COLOR_COMBAT_MEDIUM_PRESSED
			)


static func get_encounter_panel_styles(encounter_type: String) -> Dictionary:
	"""
	Get clickable panel styles for an encounter option based on type.

	Args:
		encounter_type: "shop", "xp_reward", "gold_reward", "health_restore",
		                "skill_trainer", "gamble", "elite_challenge"

	Returns:
		Dictionary with "normal", "hover", "pressed" StyleBoxFlat entries
	"""
	match encounter_type:
		"shop":
			return create_clickable_panel_styles(
				GameConstants.COLOR_ENCOUNTER_SHOP_NORMAL,
				GameConstants.COLOR_ENCOUNTER_SHOP_HOVER,
				GameConstants.COLOR_ENCOUNTER_SHOP_PRESSED
			)
		"xp_reward":
			return create_clickable_panel_styles(
				GameConstants.COLOR_ENCOUNTER_XP_NORMAL,
				GameConstants.COLOR_ENCOUNTER_XP_HOVER,
				GameConstants.COLOR_ENCOUNTER_XP_PRESSED
			)
		"gold_reward":
			return create_clickable_panel_styles(
				GameConstants.COLOR_ENCOUNTER_GOLD_NORMAL,
				GameConstants.COLOR_ENCOUNTER_GOLD_HOVER,
				GameConstants.COLOR_ENCOUNTER_GOLD_PRESSED
			)
		"health_restore":
			return create_clickable_panel_styles(
				GameConstants.COLOR_ENCOUNTER_HEALTH_NORMAL,
				GameConstants.COLOR_ENCOUNTER_HEALTH_HOVER,
				GameConstants.COLOR_ENCOUNTER_HEALTH_PRESSED
			)
		"skill_trainer":
			return create_clickable_panel_styles(
				GameConstants.COLOR_ENCOUNTER_SKILL_NORMAL,
				GameConstants.COLOR_ENCOUNTER_SKILL_HOVER,
				GameConstants.COLOR_ENCOUNTER_SKILL_PRESSED
			)
		"gamble":
			return create_clickable_panel_styles(
				GameConstants.COLOR_ENCOUNTER_GAMBLE_NORMAL,
				GameConstants.COLOR_ENCOUNTER_GAMBLE_HOVER,
				GameConstants.COLOR_ENCOUNTER_GAMBLE_PRESSED
			)
		"elite_challenge":
			return create_clickable_panel_styles(
				GameConstants.COLOR_ENCOUNTER_ELITE_NORMAL,
				GameConstants.COLOR_ENCOUNTER_ELITE_HOVER,
				GameConstants.COLOR_ENCOUNTER_ELITE_PRESSED
			)
		_:
			# Default to shop style for unknown types
			return create_clickable_panel_styles(
				GameConstants.COLOR_ENCOUNTER_SHOP_NORMAL,
				GameConstants.COLOR_ENCOUNTER_SHOP_HOVER,
				GameConstants.COLOR_ENCOUNTER_SHOP_PRESSED
			)
