extends ClickablePanelBase
## CharacterTile - Simple square tile for character overview display
## Shows portrait and name in a compact square format
## Used in TeamDisplay overview mode

signal tile_clicked(char_instance: CharacterInstance)

@onready var margin_container: MarginContainer = $MarginContainer
@onready var vbox: VBoxContainer = $MarginContainer/VBoxContainer
@onready var portrait: TextureRect = $MarginContainer/VBoxContainer/Portrait
@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel

var char_instance: CharacterInstance = null


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
	tile_clicked.emit(char_instance)


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


func highlight(enabled: bool) -> void:
	"""Visually highlight the tile."""
	if enabled:
		modulate = Color(1.2, 1.2, 1.2)
	else:
		modulate = Color.WHITE
