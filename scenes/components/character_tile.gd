extends ClickablePanelBase
## CharacterTile - Simple square tile for character overview display
## Shows portrait and name in a compact square format

signal tile_clicked(char_instance: CharacterInstance)
signal tile_clicked_data(char_data: Dictionary)

const TILE_BORDER_WIDTH := 4

@onready var content_margin: MarginContainer = $ContentMargin
@onready var portrait: TextureRect = $ContentMargin/Portrait
@onready var border_overlay: Panel = $BorderOverlay
@onready var name_label: Label = $ContentMargin/NameMargin/NameLabel

var char_instance: CharacterInstance = null
var char_data: Dictionary = {}  # For collection mode (dictionary-based)


func _init_default_styles() -> void:
	# Borderless panel - the border is drawn by BorderOverlay on top of the portrait
	var normal = StyleBoxFlat.new()
	normal.bg_color = GameConstants.COLOR_PANEL_DARK
	normal.set_corner_radius_all(UIStyles.CORNER_RADIUS_MEDIUM)
	var hover = normal.duplicate()
	hover.bg_color = GameConstants.COLOR_PANEL_DARK.lightened(0.15)
	var pressed = normal.duplicate()
	pressed.bg_color = GameConstants.COLOR_PANEL_DARK.darkened(0.1)
	setup_styles({"normal": normal, "hover": hover, "pressed": pressed})


func _on_ready() -> void:
	UIHelpers.set_children_mouse_filter_ignore(self)
	UIStyles.set_margin_all(content_margin, TILE_BORDER_WIDTH)
	_setup_border_overlay()


func _setup_border_overlay() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.set_border_width_all(TILE_BORDER_WIDTH)
	style.border_color = GameConstants.COLOR_BORDER_GOLD
	style.set_corner_radius_all(UIStyles.CORNER_RADIUS_MEDIUM)
	border_overlay.add_theme_stylebox_override("panel", style)


func _handle_click() -> void:
	if char_instance:
		tile_clicked.emit(char_instance)
	elif not char_data.is_empty():
		tile_clicked_data.emit(char_data)


func setup(character_instance: CharacterInstance, tile_size: float) -> void:
	"""Configure the tile with a character instance."""
	char_instance = character_instance
	char_data = {}
	var char_master = _configure_display(char_instance.base_character_id, tile_size)
	if char_master.is_empty():
		return
	name_label.text = char_instance.get_character_name()


func setup_from_data(character_data: Dictionary, tile_size: float) -> void:
	"""Configure the tile with character dictionary data (for Collection)."""
	char_data = character_data
	char_instance = null
	var char_id = char_data.get("id", "")
	var char_master = _configure_display(char_id, tile_size)
	if char_master.is_empty():
		return
	name_label.text = char_master.get("name", "Unknown")


func _configure_display(char_id: String, tile_size: float) -> Dictionary:
	"""Configure tile size and portrait. Returns master data (empty on failure)."""
	custom_minimum_size = Vector2(tile_size, tile_size)

	var char_master = GameData.get_character_by_id(char_id)
	if char_master.is_empty():
		push_error("CharacterTile: Character master data not found: %s" % char_id)
		return {}

	UIHelpers.set_texture_safe(portrait, char_master.get("image_path", ""))
	return char_master
