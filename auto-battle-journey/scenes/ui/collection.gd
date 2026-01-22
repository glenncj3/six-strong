extends Control
# Collection - Browse and manage character collection
# Portrait mobile layout with full-screen details overlay
# Uses CharacterTile in rows of 3, same as TeamDisplay

@onready var background = $Background
@onready var title_label = $MainContainer/VBoxContainer/Title
@onready var character_list: VBoxContainer = $MainContainer/VBoxContainer/CharacterListScroll/CharacterList
@onready var character_details_panel: Panel = $CharacterDetailsPanel
@onready var details_background = $CharacterDetailsPanel/DetailsBackground
@onready var details_content: Control = $CharacterDetailsPanel/DetailsMargin/DetailsContainer/DetailsContent
@onready var details_title = $CharacterDetailsPanel/DetailsMargin/DetailsContainer/DetailsTitle
@onready var close_details_button: Button = $CharacterDetailsPanel/CloseDetailsButton
@onready var back_button: Button = $BackButton

# Preload scenes
const CharacterTileScene = preload("res://scenes/components/character_tile.tscn")
const CharacterDetailsScene = preload("res://scenes/ui/character_details.tscn")

var character_details_instance: Node = null
var selected_character_id: String = ""
var character_tiles: Array = []  # References to tile nodes


func _ready() -> void:
	_apply_visual_styling()

	back_button.pressed.connect(_on_back_pressed)
	close_details_button.pressed.connect(_on_close_details_pressed)

	# Hide details panel initially
	character_details_panel.visible = false

	_populate_character_list()


func _apply_visual_styling() -> void:
	"""Apply fantasy aesthetic styling."""
	# Backgrounds
	background.color = GameConstants.COLOR_BG_DARK
	details_background.color = GameConstants.COLOR_BG_DARK

	# Title styling
	title_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	details_title.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)

	# Button styling
	UIStyles.apply_button_styles(back_button)
	UIStyles.apply_button_styles(close_details_button)


func _populate_character_list() -> void:
	"""Create character tiles in rows of 3, like TeamDisplay."""
	# Clear existing tiles
	UIHelpers.clear_children(character_list)
	character_tiles.clear()

	# Get unlocked characters
	var unlocked_chars = PlayerAccount.get_unlocked_characters()

	print("Collection: Displaying %d characters" % unlocked_chars.size())

	# Calculate tile size (same logic as TeamDisplay)
	var available_width = max(size.x, 680) - 32  # Account for margins
	var tile_size = floor((available_width - 16) / 3.0)  # 16 = spacing between tiles
	tile_size = max(tile_size, 180)  # Minimum tile size

	# Create rows of 3 tiles
	var current_row: HBoxContainer = null
	var tiles_in_row = 0

	for i in range(unlocked_chars.size()):
		# Create new row every 3 tiles
		if tiles_in_row == 0:
			current_row = HBoxContainer.new()
			current_row.alignment = BoxContainer.ALIGNMENT_CENTER
			current_row.add_theme_constant_override("separation", 8)
			character_list.add_child(current_row)

		var char_data = unlocked_chars[i]
		var tile = CharacterTileScene.instantiate()
		current_row.add_child(tile)
		tile.setup_from_data(char_data, tile_size)
		tile.tile_clicked_data.connect(_on_character_tile_clicked)
		character_tiles.append(tile)

		tiles_in_row += 1
		if tiles_in_row >= 3:
			tiles_in_row = 0


func _on_character_tile_clicked(char_data: Dictionary) -> void:
	"""Handle character tile selection - show details overlay."""
	_select_character(char_data.get("id", ""))


func _select_character(char_id: String) -> void:
	"""Display details for selected character in full-screen overlay."""
	selected_character_id = char_id

	# Get character data
	var char_data = PlayerAccount.get_character_data(char_id)
	if char_data.is_empty():
		push_error("Collection: Character data not found: %s" % char_id)
		return

	# Clear existing details
	if character_details_instance:
		character_details_instance.queue_free()

	# Create new details panel
	character_details_instance = CharacterDetailsScene.instantiate()
	details_content.add_child(character_details_instance)
	character_details_instance.display_character(char_data)

	# Show the details overlay
	character_details_panel.visible = true

	# Hide main back button when showing details
	back_button.visible = false

	# Highlight selected tile
	_highlight_selected_tile()


func _on_close_details_pressed() -> void:
	"""Close the details overlay and return to grid view."""
	character_details_panel.visible = false
	back_button.visible = true


func _highlight_selected_tile() -> void:
	"""Highlight the currently selected character tile."""
	for tile in character_tiles:
		var tile_id = tile.char_data.get("id", "")
		tile.highlight(tile_id == selected_character_id)


func refresh_display() -> void:
	"""Refresh the entire collection display."""
	_populate_character_list()
	if not selected_character_id.is_empty():
		_select_character(selected_character_id)


func _on_back_pressed() -> void:
	"""Return to main menu."""
	print("Collection: Back button pressed")
	SceneManager.go_to_main_menu()
