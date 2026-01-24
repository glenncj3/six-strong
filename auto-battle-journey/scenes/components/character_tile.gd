extends ClickablePanelBase
## CharacterTile - Simple square tile for character overview display
## Shows portrait and name in a compact square format

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
	name_label.text = "%s (Lv.%d)" % [char_instance.get_character_name(), char_instance.level]


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
	var portrait_size = tile_size - 36  # 8px margins * 2 + 20px label
	portrait.custom_minimum_size = Vector2(portrait_size, portrait_size)

	var char_master = GameData.get_character_by_id(char_id)
	if char_master.is_empty():
		push_error("CharacterTile: Character master data not found: %s" % char_id)
		return {}

	UIHelpers.set_texture_safe(portrait, char_master.get("image_path", ""))
	return char_master
