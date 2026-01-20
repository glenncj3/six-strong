extends Control
# Collection - Browse and manage character collection
# Portrait mobile layout with full-screen details overlay

@onready var character_grid: GridContainer = $MainContainer/VBoxContainer/CharacterListScroll/CharacterGrid
@onready var character_details_panel: Panel = $CharacterDetailsPanel
@onready var details_content: Control = $CharacterDetailsPanel/DetailsMargin/DetailsContainer/DetailsContent
@onready var close_details_button: Button = $CharacterDetailsPanel/CloseDetailsButton
@onready var back_button: Button = $BackButton

# Preload scenes
const CharacterCardScene = preload("res://scenes/components/character_card.tscn")
const CharacterDetailsScene = preload("res://scenes/ui/character_details.tscn")

var character_details_instance: Node = null
var selected_character_id: String = ""


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	close_details_button.pressed.connect(_on_close_details_pressed)

	# Hide details panel initially
	character_details_panel.visible = false

	_populate_character_grid()


func _populate_character_grid() -> void:
	"""Create character cards for all unlocked characters."""
	# Clear existing cards using UIHelpers
	UIHelpers.clear_children(character_grid)

	# Get unlocked characters
	var unlocked_chars = PlayerAccount.get_unlocked_characters()

	print("Collection: Displaying %d characters" % unlocked_chars.size())

	# Create a card for each character
	for char_data in unlocked_chars:
		var card = CharacterCardScene.instantiate()
		character_grid.add_child(card)

		# Setup card with equipped items
		card.setup(char_data, true)

		# Connect click signal
		card.card_clicked.connect(_on_character_card_clicked)


func _on_character_card_clicked(char_data: Dictionary) -> void:
	"""Handle character card selection - show details overlay."""
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

	# Highlight selected card
	_highlight_selected_card()


func _on_close_details_pressed() -> void:
	"""Close the details overlay and return to grid view."""
	character_details_panel.visible = false
	back_button.visible = true


func _highlight_selected_card() -> void:
	"""Highlight the currently selected character card."""
	for card in character_grid.get_children():
		var card_id = card.character_data.get("id", "")
		card.highlight(card_id == selected_character_id)


func refresh_display() -> void:
	"""Refresh the entire collection display."""
	_populate_character_grid()
	if not selected_character_id.is_empty():
		_select_character(selected_character_id)


func _on_back_pressed() -> void:
	"""Return to main menu."""
	print("Collection: Back button pressed")
	SceneManager.go_to_main_menu()
