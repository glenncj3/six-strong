extends PanelContainer
# CharacterTile - Simple square tile for character overview display
# Shows portrait and name in a compact square format
# Used in TeamDisplay overview mode

signal tile_clicked(char_instance: CharacterInstance)

@onready var margin_container: MarginContainer = $MarginContainer
@onready var vbox: VBoxContainer = $MarginContainer/VBoxContainer
@onready var portrait: TextureRect = $MarginContainer/VBoxContainer/Portrait
@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel

var char_instance: CharacterInstance = null
var clickable: bool = true


func _ready() -> void:
	gui_input.connect(_on_gui_input)
	UIStyles.apply_panel_style(self, UIStyles.create_dark_panel())


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


func set_clickable(enabled: bool) -> void:
	"""Enable or disable click interaction."""
	clickable = enabled
	mouse_filter = MOUSE_FILTER_STOP if enabled else MOUSE_FILTER_IGNORE


func _on_gui_input(event: InputEvent) -> void:
	if not clickable:
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			tile_clicked.emit(char_instance)


func highlight(enabled: bool) -> void:
	"""Visually highlight the tile."""
	if enabled:
		modulate = Color(1.2, 1.2, 1.2)
	else:
		modulate = Color.WHITE
