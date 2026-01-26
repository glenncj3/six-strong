extends ClickablePanelBase
class_name GridSlot
## A single slot in the character grid.
## Can display a character or be empty (placeholder).
## Supports drag-and-drop for character repositioning.

signal slot_clicked(row: int, col: int, character: CharacterInstance)
@warning_ignore("unused_signal")  # Reserved for future drag-and-drop
signal drag_started(row: int, col: int, character: CharacterInstance)
@warning_ignore("unused_signal")  # Reserved for future drag-and-drop
signal drop_received(row: int, col: int, from_row: int, from_col: int)

const SLOT_BORDER_WIDTH := 3

@onready var content_margin: MarginContainer = $ContentMargin
@onready var portrait: TextureRect = $ContentMargin/Portrait
@onready var border_overlay: Panel = $BorderOverlay
@onready var name_label: Label = $ContentMargin/NameMargin/NameLabel
@onready var highlight_rect: ColorRect = $HighlightRect

var row: int = -1
var col: int = -1
var character: CharacterInstance = null
var _is_drag_target: bool = false
var _is_valid_drop_target: bool = false


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
	slot_clicked.emit(row, col, character)


# =============================================================================
# SETUP
# =============================================================================

func setup_slot(slot_row: int, slot_col: int, slot_size: Vector2) -> void:
	"""Configure the slot's position and size."""
	row = slot_row
	col = slot_col
	custom_minimum_size = slot_size


func set_character(char_instance: CharacterInstance) -> void:
	"""Set a character to display in this slot."""
	character = char_instance

	if character == null:
		_clear_display()
		return

	# Get character data
	var char_master = GameData.get_character_by_id(character.base_character_id)
	if char_master.is_empty():
		push_error("GridSlot: Character master data not found: %s" % character.base_character_id)
		_clear_display()
		return

	# Show character
	portrait.visible = true
	UIHelpers.set_texture_safe(portrait, char_master.get("image_path", ""))
	name_label.visible = true
	name_label.text = char_master.get("name", "?")

	# Update border to gold
	_set_border_color(GameConstants.COLOR_BORDER_GOLD)

	# Update styles for occupied slot
	var normal = StyleBoxFlat.new()
	normal.bg_color = GameConstants.COLOR_PANEL_DARK
	normal.set_corner_radius_all(UIStyles.CORNER_RADIUS_MEDIUM)
	var hover = normal.duplicate()
	hover.bg_color = GameConstants.COLOR_PANEL_DARK.lightened(0.15)
	var pressed = normal.duplicate()
	pressed.bg_color = GameConstants.COLOR_PANEL_DARK.darkened(0.1)
	setup_styles({"normal": normal, "hover": hover, "pressed": pressed})


func _clear_display() -> void:
	"""Show empty placeholder state."""
	character = null
	portrait.visible = false
	name_label.visible = false

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
