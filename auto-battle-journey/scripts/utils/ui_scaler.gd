class_name UIScaler
extends RefCounted
# UIScaler - Viewport-relative sizing utility
# Converts percentages to pixels based on design resolution (720x1280)

# =============================================================================
# DESIGN CONSTANTS (sourced from GameConstants)
# =============================================================================

const DESIGN_WIDTH: float = GameConstants.DESIGN_WIDTH
const DESIGN_HEIGHT: float = GameConstants.DESIGN_HEIGHT

# =============================================================================
# CARD SIZE VARIANTS
# =============================================================================

enum CardSize {
	NORMAL,  # ~200x280 - Full display in collection
	SMALL,   # ~100x140 - Team preview, selection displays
	MINI     # ~80x110  - Compact lists, thumbnails
}

# =============================================================================
# VIEWPORT PERCENTAGE FUNCTIONS
# =============================================================================

static func vw(percent: float) -> float:
	"""Convert viewport width percentage to pixels."""
	return (percent / 100.0) * DESIGN_WIDTH


static func vh(percent: float) -> float:
	"""Convert viewport height percentage to pixels."""
	return (percent / 100.0) * DESIGN_HEIGHT


static func vmin(percent: float) -> float:
	"""Convert percentage of smaller viewport dimension to pixels."""
	return (percent / 100.0) * min(DESIGN_WIDTH, DESIGN_HEIGHT)


static func vmax(percent: float) -> float:
	"""Convert percentage of larger viewport dimension to pixels."""
	return (percent / 100.0) * max(DESIGN_WIDTH, DESIGN_HEIGHT)


# =============================================================================
# COMPONENT SIZE GETTERS
# =============================================================================

static func get_character_card_size(variant: CardSize = CardSize.NORMAL) -> Vector2:
	"""
	Get character card size for the specified variant.

	Args:
		variant: CardSize enum value

	Returns:
		Vector2 with width and height in pixels
	"""
	match variant:
		CardSize.NORMAL:
			# ~27.8% width, ~21.9% height
			return Vector2(vw(27.8), vh(21.9))
		CardSize.SMALL:
			# ~13.9% width, ~10.9% height
			return Vector2(vw(13.9), vh(10.9))
		CardSize.MINI:
			# ~11.1% width, ~8.6% height
			return Vector2(vw(11.1), vh(8.6))
		_:
			return Vector2(200, 280)


static func get_item_slot_size(compact: bool = false) -> Vector2:
	"""
	Get item slot size.

	Args:
		compact: If true, returns smaller size without label space

	Returns:
		Vector2 with width and height in pixels
	"""
	if compact:
		# Icon only, no label - ~8% width, ~5% height
		return Vector2(vw(8), vh(5))
	# Full with label - ~10% width, ~7% height
	return Vector2(vw(10), vh(7))


static func get_item_icon_size(compact: bool = false) -> float:
	"""Get item icon size in pixels."""
	if compact:
		return vw(7)  # ~50px
	return vw(7.8)  # ~56px


static func get_skill_icon_size(compact: bool = false) -> Vector2:
	"""
	Get skill icon component size.

	Args:
		compact: If true, returns smaller size without label space

	Returns:
		Vector2 with width and height in pixels
	"""
	if compact:
		# Icon only - ~7% width, ~4% height
		return Vector2(vw(7), vh(4))
	# Full with label - ~7.8% width, ~5.5% height
	return Vector2(vw(7.8), vh(5.5))


static func get_skill_image_size() -> float:
	"""Get skill icon image size in pixels (~40px)."""
	return vw(5.5)


# =============================================================================
# LAYOUT HELPERS
# =============================================================================

static func get_section_max_height(section_name: String) -> float:
	"""
	Get maximum height for a named section (for character details screen).

	Args:
		section_name: "skills", "items", "equipment", "stats", "topbar"

	Returns:
		Maximum height in pixels
	"""
	match section_name:
		"topbar":
			return vh(9.4)   # ~120px
		"stats":
			return vh(10.2)  # ~130px
		"equipment":
			return vh(7.8)   # ~100px
		"items":
			return vh(11.7)  # ~150px
		"skills":
			return vh(15.6)  # ~200px
		_:
			return vh(10)


static func get_draft_option_height() -> float:
	"""Get height for draft option panels (~20% viewport)."""
	return vh(20)  # ~256px


static func get_option_panel_height() -> float:
	"""Get height for encounter/combat option panels (~10% viewport)."""
	return vh(10)  # ~128px - fits 3 panels without scrollbar


static func get_option_info_max_height() -> float:
	"""
	Get maximum height for the info section inside option panels.
	Accounts for panel height minus margins and padding.
	Panel: 154px, margins: ~20px total = ~134px available.
	Subtract button height (40px) and spacing = ~90px for info content.
	"""
	return vh(7)  # ~90px


static func get_button_height(size: String = "normal") -> float:
	"""
	Get button height.

	Args:
		size: "small", "normal", "large"

	Returns:
		Button height in pixels
	"""
	match size:
		"small":
			return vh(3.1)  # ~40px
		"normal":
			return vh(3.9)  # ~50px
		"large":
			return vh(4.7)  # ~60px
		_:
			return vh(3.9)


# =============================================================================
# GRID CALCULATIONS
# =============================================================================

static func get_grid_columns_for_width(item_width: float, container_width: float, spacing: float = 8.0) -> int:
	"""
	Calculate how many columns fit in a container.

	Args:
		item_width: Width of each item
		container_width: Available container width
		spacing: Space between items

	Returns:
		Number of columns that fit
	"""
	if item_width <= 0:
		return 1
	var available = container_width + spacing
	var item_with_spacing = item_width + spacing
	return max(1, int(available / item_with_spacing))


static func get_items_grid_columns() -> int:
	"""Get recommended columns for item grid (4 columns for 720px width)."""
	return 4


static func get_skills_grid_columns() -> int:
	"""Get recommended columns for skills grid (5 columns for 720px width)."""
	return 5
