extends Control
# Draft - Character selection for starting a run
# Refactored to use SceneManager, UIHelpers, and GameConstants

@onready var instruction_label = $MainContainer/TopSection/InstructionLabel
@onready var selected_display = $MainContainer/TopSection/SelectedDisplay
@onready var options_container = $MainContainer/OptionsContainer
@onready var reroll_button = $MainContainer/BottomButtons/RerollButton
@onready var confirm_button = $MainContainer/BottomButtons/ConfirmButton
@onready var back_button = $BackButton

# Preload scenes
const CharacterCardScene = preload("res://scenes/components/character_card.tscn")

# Draft state
var drafted_characters: Array = []
var current_options: Array = []
var selection_count: int = 0


func _ready() -> void:
	# Debug: verify all node references
	print("Draft: Node check - instruction_label: %s" % (instruction_label != null))
	print("Draft: Node check - confirm_button: %s" % (confirm_button != null))
	print("Draft: Node check - reroll_button: %s" % (reroll_button != null))

	reroll_button.pressed.connect(_on_reroll_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)

	confirm_button.visible = false

	_generate_options()
	_update_instruction()
	_update_reroll_button()


func _generate_options() -> void:
	"""Generate 3 unique character options (2 owned, 1 random)."""
	# Clear existing options using UIHelpers
	UIHelpers.clear_children(options_container)
	current_options.clear()

	# Get IDs of already drafted characters
	var drafted_ids: Array[String] = []
	for char_data in drafted_characters:
		drafted_ids.append(char_data.get("id", ""))

	# Get owned characters (excluding already drafted)
	var owned_chars = PlayerAccount.get_unlocked_characters()
	var available_owned: Array = []
	for char_data in owned_chars:
		if char_data.get("id", "") not in drafted_ids:
			available_owned.append(char_data)

	# Get all characters for random option
	var all_chars = GameData.get_all_characters()

	if available_owned.size() < 2:
		push_error("Draft: Not enough available owned characters")
		return

	# Shuffle owned pool
	available_owned.shuffle()

	# Track which character IDs we've added to options
	var option_ids: Array[String] = []

	# Generate 2 owned options
	for i in range(2):
		if available_owned.size() > 0:
			var char_data = available_owned.pop_front()
			current_options.append({
				"char_data": char_data,
				"is_owned": true,
				"unlock_cost": 0
			})
			option_ids.append(char_data.get("id", ""))

	# Generate 1 random option (must be unique from the 2 owned options)
	all_chars.shuffle()
	var random_char = null
	for char in all_chars:
		var char_id = char.get("id", "")
		if char_id not in option_ids and char_id not in drafted_ids:
			random_char = char
			break

	if random_char == null:
		push_error("Draft: Could not find unique random character")
		return

	var random_char_id = random_char.get("id", "")
	var is_owned = PlayerAccount.is_character_unlocked(random_char_id)

	# Get character data
	var random_char_data = null
	if is_owned:
		random_char_data = PlayerAccount.get_character_data(random_char_id)
	else:
		# Create temporary data for display
		random_char_data = {
			"id": random_char_id,
			"unlocked": false,
			"rank": 1,
			"experience": 0,
			"equipped_items": [],
			"unlocked_items": [],
			"unlocked_item_upgrades": [],
			"unlocked_skills": []
		}

	current_options.append({
		"char_data": random_char_data,
		"is_owned": is_owned,
		"unlock_cost": GameConstants.CHARACTER_UNLOCK_COST
	})

	# Create UI for each option
	for option in current_options:
		_create_option_panel(option)

	print("Draft: Generated %d unique options" % current_options.size())


func _create_option_panel(option: Dictionary) -> void:
	"""Create a selectable character option panel."""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 300)
	options_container.add_child(panel)

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	# Character card
	var card = CharacterCardScene.instantiate()
	vbox.add_child(card)
	card.setup(option["char_data"], true)
	card.set_clickable(false)

	# Select/Unlock button
	var button = Button.new()
	vbox.add_child(button)

	var char_id = option["char_data"].get("id", "")

	if option["is_owned"]:
		button.text = "SELECT"
		button.pressed.connect(_on_character_selected.bind(option["char_data"]))
	else:
		button.text = "UNLOCK (%d gems)" % option["unlock_cost"]
		button.pressed.connect(_on_unlock_and_select.bind(option["char_data"], option["unlock_cost"]))

	# Disable button if character already drafted
	if _is_character_drafted(char_id):
		button.disabled = true
		button.text = "SELECTED"


func _is_character_drafted(char_id: String) -> bool:
	"""Check if character is already in drafted array."""
	for char_data in drafted_characters:
		if char_data.get("id", "") == char_id:
			return true
	return false


func _on_character_selected(char_data: Dictionary) -> void:
	"""Handle selecting an owned character."""
	var char_id = char_data.get("id", "")

	if _is_character_drafted(char_id):
		print("Draft: Character already selected")
		return

	if drafted_characters.size() >= GameConstants.TEAM_SIZE:
		print("Draft: Already have %d characters" % GameConstants.TEAM_SIZE)
		return

	drafted_characters.append(char_data)
	selection_count += 1

	print("Draft: Selected %s (%d/%d)" % [char_id, selection_count, GameConstants.TEAM_SIZE])

	_update_selected_display()
	_update_instruction()

	if selection_count == GameConstants.TEAM_SIZE:
		_show_confirm_button()
	else:
		_regenerate_options()


func _on_unlock_and_select(char_data: Dictionary, cost: int) -> void:
	"""Handle unlocking and selecting a character."""
	if drafted_characters.size() >= GameConstants.TEAM_SIZE:
		print("Draft: Already have %d characters" % GameConstants.TEAM_SIZE)
		return

	var char_id = char_data.get("id", "")

	# Attempt to unlock
	var success = PlayerAccount.unlock_character(char_id, cost)
	if not success:
		print("Draft: Failed to unlock character (not enough gems)")
		return

	# Now select the newly unlocked character
	var unlocked_char_data = PlayerAccount.get_character_data(char_id)
	_on_character_selected(unlocked_char_data)


func _update_selected_display() -> void:
	"""Update the display showing drafted characters."""
	# Clear existing using UIHelpers
	UIHelpers.clear_children(selected_display)

	# Add card for each drafted character
	for char_data in drafted_characters:
		var card = CharacterCardScene.instantiate()
		selected_display.add_child(card)
		card.setup(char_data, true)
		card.set_clickable(false)
		card.custom_minimum_size = Vector2(100, 160)


func _update_instruction() -> void:
	"""Update instruction text."""
	if selection_count < GameConstants.TEAM_SIZE:
		instruction_label.text = "SELECT CHARACTER %d OF %d" % [selection_count + 1, GameConstants.TEAM_SIZE]
	else:
		instruction_label.text = "TEAM COMPLETE - READY TO START"
	print("Draft: Instruction updated to: %s" % instruction_label.text)


func _regenerate_options() -> void:
	"""Regenerate options after a selection."""
	_generate_options()


func _show_confirm_button() -> void:
	"""Show the confirm button when team is complete."""
	print("Draft: Showing confirm button (team complete)")

	# Hide the options section entirely
	var options_title = $MainContainer/OptionsTitle
	if options_title:
		options_title.visible = false
	options_container.visible = false

	# Hide reroll, show confirm
	reroll_button.visible = false
	confirm_button.visible = true

	# Make the confirm button expand to fill center
	confirm_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	print("Draft: confirm_button.visible = %s" % confirm_button.visible)


func _on_reroll_pressed() -> void:
	"""Handle reroll button press."""
	if PlayerAccount.spend_reroll_token():
		print("Draft: Rerolling options...")
		_generate_options()
		_update_reroll_button()
	else:
		print("Draft: No reroll tokens available")


func _update_reroll_button() -> void:
	"""Update reroll button text with token count."""
	var tokens = PlayerAccount.get_reroll_tokens()
	reroll_button.text = "REROLL (%d tokens)" % tokens
	reroll_button.disabled = (tokens == 0)


func _on_confirm_pressed() -> void:
	"""Start the run with drafted characters."""
	if drafted_characters.size() != GameConstants.TEAM_SIZE:
		push_error("Draft: Must select exactly %d characters" % GameConstants.TEAM_SIZE)
		return

	print("Draft: Starting run with drafted team...")

	# Extract character IDs
	var char_ids = []
	for char_data in drafted_characters:
		char_ids.append(char_data.get("id", ""))

	print("Draft: Character IDs: %s" % str(char_ids))

	# Start run
	RunManager.start_new_run(char_ids)

	print("Draft: Run started, navigating to run_view...")

	# Navigate to run view using SceneManager
	SceneManager.go_to_run_view()


func _on_back_pressed() -> void:
	"""Return to main menu."""
	SceneManager.go_to_main_menu()
