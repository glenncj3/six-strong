extends ClickablePanelBase
## CharacterTile - Simple square tile for character overview display
## Shows portrait and name in a compact square format
## Used in TeamDisplay overview mode

signal tile_clicked(char_instance: CharacterInstance)
signal tile_clicked_data(char_data: Dictionary)

@onready var margin_container: MarginContainer = $MarginContainer
@onready var vbox: VBoxContainer = $MarginContainer/VBoxContainer
@onready var portrait: TextureRect = $MarginContainer/VBoxContainer/Portrait
@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel

var char_instance: CharacterInstance = null
var char_data: Dictionary = {}  # For collection mode (dictionary-based)


func _on_ready() -> void:
	UIHelpers.set_children_mouse_filter_ignore(self)
	_init_styles()


func _init_styles() -> void:
	var styles = UIStyles.create_clickable_panel_styles(
		GameConstants.COLOR_PANEL_DARK,
		GameConstants.COLOR_PANEL_DARK.lightened(0.15),
		GameConstants.COLOR_PANEL_DARK.darkened(0.1)
	)
	setup_styles(styles)


func _handle_click() -> void:
	if char_instance:
		tile_clicked.emit(char_instance)
	elif not char_data.is_empty():
		tile_clicked_data.emit(char_data)


func setup(character_instance: CharacterInstance, tile_size: float) -> void:
	"""
	Configure the tile with a character instance.

	Args:
		character_instance: The CharacterInstance to display
		tile_size: Width and height of the tile in pixels
	"""
	char_instance = character_instance

	# Set tile size (square)
	custom_minimum_size = Vector2(tile_size, tile_size)

	# Calculate portrait size (tile minus margins and label space)
	var margin = 8
	var label_height = 20
	var portrait_size = tile_size - (margin * 2) - label_height
	portrait.custom_minimum_size = Vector2(portrait_size, portrait_size)

	# Get master data for portrait
	var char_master = GameData.get_character_by_id(char_instance.base_character_id)
	if char_master.is_empty():
		push_error("CharacterTile: Character master data not found: %s" % char_instance.base_character_id)
		return

	# Set portrait
	UIHelpers.set_texture_safe(portrait, char_master.get("image_path", ""))

	# Set name with level
	name_label.text = "%s (Lv.%d)" % [char_instance.get_character_name(), char_instance.level]


func setup_from_data(character_data: Dictionary, tile_size: float) -> void:
	"""
	Configure the tile with character dictionary data (for Collection).

	Args:
		character_data: Player's character data dictionary
		tile_size: Width and height of the tile in pixels
	"""
	char_data = character_data
	char_instance = null  # Clear instance mode

	# Set tile size (square)
	custom_minimum_size = Vector2(tile_size, tile_size)

	# Calculate portrait size (tile minus margins and label space)
	var margin = 8
	var label_height = 20
	var portrait_size = tile_size - (margin * 2) - label_height
	portrait.custom_minimum_size = Vector2(portrait_size, portrait_size)

	# Get master data for portrait and name
	var char_master = GameData.get_character_by_id(char_data.get("id", ""))
	if char_master.is_empty():
		push_error("CharacterTile: Character master data not found: %s" % char_data.get("id", ""))
		return

	# Set portrait
	UIHelpers.set_texture_safe(portrait, char_master.get("image_path", ""))

	# Set name (no level in collection mode)
	name_label.text = char_master.get("name", "Unknown")


func highlight(enabled: bool) -> void:
	"""Visually highlight the tile."""
	if enabled:
		modulate = Color(1.2, 1.2, 1.2)
	else:
		modulate = Color.WHITE
