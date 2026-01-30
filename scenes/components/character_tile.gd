extends ClickablePanelBase
class_name CharacterTile
## A character display tile that can be used standalone or as a grid slot.
## Can display a character or be empty (placeholder).
## Supports grid positioning and drag-and-drop for character repositioning.

signal slot_clicked(row: int, col: int, character: CharacterInstance)
signal tile_clicked_data(char_data: Dictionary)
@warning_ignore("unused_signal")  # Reserved for future drag-and-drop
signal drag_started(row: int, col: int, character: CharacterInstance)
@warning_ignore("unused_signal")  # Reserved for future drag-and-drop
signal drop_received(row: int, col: int, from_row: int, from_col: int)

const SLOT_BORDER_WIDTH := 3
const STAT_ICON_SIZE := 18
const STAT_FONT_SIZE := 12

const TOP_STATS := [
	{"key": "damage", "icon": "res://assets/sprites/icons/icon_damage.Png"},
	{"key": "heal_value", "icon": "res://assets/sprites/icons/icon_heal.Png"},
	{"key": "shield_value", "icon": "res://assets/sprites/icons/icon_shield.Png"},
	{"key": "burn_value", "icon": "res://assets/sprites/icons/icon_burn.Png"},
	{"key": "poison_value", "icon": "res://assets/sprites/icons/icon_poison.Png"},
]
const BOTTOM_STATS := [
	{"key": "charges", "icon": "res://assets/sprites/icons/icon_charges.Png"},
	{"key": "multistrike_value", "icon": "res://assets/sprites/icons/icon_multistrike.Png"},
	{"key": "speed", "icon": "res://assets/sprites/icons/icon_speed.Png"},
]

@onready var content_margin: MarginContainer = $ContentMargin
@onready var portrait: TextureRect = $ContentMargin/Portrait
@onready var border_overlay: Panel = $BorderOverlay
@onready var name_label: Label = $ContentMargin/NameMargin/NameLabel
@onready var highlight_rect: ColorRect = $HighlightRect

var row: int = -1
var col: int = -1
var character: CharacterInstance = null
var char_data: Dictionary = {}  # For collection mode (dictionary-based)
var _is_drag_target: bool = false
var _is_valid_drop_target: bool = false
var _stat_badges: Dictionary = {}  # key -> HBoxContainer badge
var _top_stats_container: HBoxContainer
var _bottom_stats_container: HBoxContainer


func _init_default_styles() -> void:
	# Empty slot style
	var normal = StyleBoxFlat.new()
	normal.bg_color = GameConstants.COLOR_PANEL_DARK.darkened(0.2)
	normal.set_corner_radius_all(UIStyles.CORNER_RADIUS_MEDIUM)
	var hover = normal.duplicate()
	hover.bg_color = GameConstants.COLOR_PANEL_DARK
	var pressed = normal.duplicate()
	pressed.bg_color = GameConstants.COLOR_PANEL_DARK.darkened(0.3)
	setup_styles({"normal": normal, "hover": hover, "pressed": pressed})


func _on_ready() -> void:
	UIHelpers.set_children_mouse_filter_ignore(self)
	UIStyles.set_margin_all(content_margin, SLOT_BORDER_WIDTH)
	_setup_border_overlay()
	_setup_highlight()
	_build_stat_containers()
	_clear_display()


func _setup_border_overlay() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.set_border_width_all(SLOT_BORDER_WIDTH)
	style.border_color = GameConstants.COLOR_BORDER_GOLD.darkened(0.3)
	style.set_corner_radius_all(UIStyles.CORNER_RADIUS_MEDIUM)
	border_overlay.add_theme_stylebox_override("panel", style)


func _setup_highlight() -> void:
	highlight_rect.visible = false
	highlight_rect.color = Color(0.3, 0.8, 0.3, 0.3)


func _handle_click() -> void:
	if not char_data.is_empty():
		tile_clicked_data.emit(char_data)
	slot_clicked.emit(row, col, character)


# =============================================================================
# SETUP
# =============================================================================

func setup_slot(slot_row: int, slot_col: int, slot_size: Vector2) -> void:
	"""Configure the slot's position and size."""
	row = slot_row
	col = slot_col
	custom_minimum_size = slot_size


func setup(character_instance: CharacterInstance, tile_size: float) -> void:
	"""Configure as a standalone tile with a character instance."""
	character = character_instance
	char_data = {}
	custom_minimum_size = Vector2(tile_size, tile_size)

	if character == null:
		_clear_display()
		return

	var char_master = GameData.get_character_by_id(character.base_character_id)
	if char_master.is_empty():
		push_error("CharacterTile: Character master data not found: %s" % character.base_character_id)
		_clear_display()
		return

	_apply_character_display(char_master)
	name_label.text = character.get_character_name()


func setup_from_data(character_data: Dictionary, tile_size: float) -> void:
	"""Configure with character dictionary data (for Collection)."""
	char_data = character_data
	character = null
	custom_minimum_size = Vector2(tile_size, tile_size)

	var char_id = char_data.get("id", "")
	var char_master = GameData.get_character_by_id(char_id)
	if char_master.is_empty():
		push_error("CharacterTile: Character master data not found: %s" % char_id)
		_clear_display()
		return

	_apply_character_display(char_master)
	name_label.text = char_master.get("name", "Unknown")


func set_character(char_instance: CharacterInstance) -> void:
	"""Set a character to display in this slot."""
	character = char_instance

	if character == null:
		_clear_display()
		return

	# Get character data
	var char_master = GameData.get_character_by_id(character.base_character_id)
	if char_master.is_empty():
		push_error("CharacterTile: Character master data not found: %s" % character.base_character_id)
		_clear_display()
		return

	_apply_character_display(char_master)
	name_label.text = char_master.get("name", "?")


func _apply_character_display(char_master: Dictionary) -> void:
	"""Apply character visuals from master data."""
	# Try to load image, fall back to display_color
	var image_path = char_master.get("image_path", "")
	var image_loaded = false
	if not image_path.is_empty():
		image_loaded = UIHelpers.set_texture_safe(portrait, image_path)

	portrait.visible = image_loaded
	name_label.visible = true

	# Update stat icons
	var base_stats = char_master.get("base_stats", {})
	_update_stat_icons(base_stats)

	# Update border to gold
	_set_border_color(GameConstants.COLOR_BORDER_GOLD)

	# Determine background color
	var bg_color = GameConstants.COLOR_PANEL_DARK
	if not image_loaded:
		var display_color_str = char_master.get("display_color", "")
		if not display_color_str.is_empty():
			bg_color = Color(display_color_str)

	# Update styles for occupied slot
	var normal = StyleBoxFlat.new()
	normal.bg_color = bg_color
	normal.set_corner_radius_all(UIStyles.CORNER_RADIUS_MEDIUM)
	var hover = normal.duplicate()
	hover.bg_color = bg_color.lightened(0.15)
	var pressed = normal.duplicate()
	pressed.bg_color = bg_color.darkened(0.1)
	setup_styles({"normal": normal, "hover": hover, "pressed": pressed})


func _build_stat_containers() -> void:
	_top_stats_container = _create_stat_row(TOP_STATS)
	_top_stats_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_bottom_stats_container = _create_stat_row(BOTTOM_STATS)
	_bottom_stats_container.size_flags_vertical = Control.SIZE_SHRINK_END
	content_margin.add_child(_top_stats_container)
	content_margin.add_child(_bottom_stats_container)


func _create_stat_row(stat_defs: Array) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	for stat_def in stat_defs:
		var badge = _create_stat_badge(stat_def.key, stat_def.icon)
		row.add_child(badge)
	return row


func _create_stat_badge(stat_key: String, icon_path: String) -> HBoxContainer:
	var badge = HBoxContainer.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_constant_override("separation", 1)
	badge.visible = false

	var icon = TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(STAT_ICON_SIZE, STAT_ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex = load(icon_path)
	if tex:
		icon.texture = tex
	badge.add_child(icon)

	var label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", STAT_FONT_SIZE)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(label)

	_stat_badges[stat_key] = {"container": badge, "label": label}
	return badge


func _update_stat_icons(stats: Dictionary) -> void:
	for stat_key in _stat_badges:
		var val = stats.get(stat_key, 0)
		var badge_data = _stat_badges[stat_key]
		if val is float:
			val = int(val)
		badge_data.container.visible = val > 0
		badge_data.label.text = str(val)


func _hide_all_stat_icons() -> void:
	for stat_key in _stat_badges:
		_stat_badges[stat_key].container.visible = false


func _clear_display() -> void:
	"""Show empty placeholder state."""
	character = null
	portrait.visible = false
	name_label.visible = false
	_hide_all_stat_icons()

	# Update border to dim
	_set_border_color(GameConstants.COLOR_BORDER_GOLD.darkened(0.5))


func _set_border_color(color: Color) -> void:
	var style = border_overlay.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		var new_style = style.duplicate()
		new_style.border_color = color
		border_overlay.add_theme_stylebox_override("panel", new_style)


# =============================================================================
# DRAG AND DROP
# =============================================================================

func set_drag_highlight(enabled: bool, is_valid: bool = true) -> void:
	"""Show/hide drag target highlight."""
	_is_drag_target = enabled
	_is_valid_drop_target = is_valid

	highlight_rect.visible = enabled
	if enabled:
		if is_valid:
			highlight_rect.color = Color(0.3, 0.8, 0.3, 0.4)  # Green for valid
		else:
			highlight_rect.color = Color(0.8, 0.3, 0.3, 0.4)  # Red for invalid


func is_empty() -> bool:
	"""Check if slot has no character."""
	return character == null


func has_character() -> bool:
	"""Check if slot has a character."""
	return character != null


func get_position_vector() -> Vector2i:
	"""Get slot position as Vector2i."""
	return Vector2i(row, col)
