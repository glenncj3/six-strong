extends Control
# Draft - Character selection for starting a run
# Uses two TeamDisplay panels for consistent UI:
# - Options panel: shows draftable characters
# - Team panel: shows already drafted characters

@onready var background: ColorRect = $Background
@onready var instruction_label = $MainContainer/VBoxContainer/TopSection/InstructionLabel
@onready var options_section = $MainContainer/VBoxContainer/ContentScroll/ContentContainer/OptionsSection
@onready var options_display_container = $MainContainer/VBoxContainer/ContentScroll/ContentContainer/OptionsSection/OptionsDisplayContainer
@onready var team_display_container = $TeamDisplayContainer
@onready var confirm_button = $MainContainer/VBoxContainer/BottomButtons/ConfirmButton
@onready var back_button = $BackButton

# Preload scenes
const TeamDisplayScene = preload("res://scenes/components/team_display.tscn")

# Draft state
var drafted_characters: Array = []  # Character data dictionaries
var drafted_instances: Array = []  # CharacterInstance objects for your team display
var current_options: Array = []  # Option dictionaries with char_data, is_owned, etc.
var option_instances: Array = []  # CharacterInstance objects for options display
var selection_count: int = 0

# UI state
var options_team_display: Node = null
var your_team_display: Node = null
var select_buttons: Array = []  # SELECT buttons for each option


func _ready() -> void:
	_apply_visual_styling()

	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)

	# Hide team display until characters are drafted
	team_display_container.visible = false

	_setup_options_display()
	_generate_options()
	_update_instruction()


func _apply_visual_styling() -> void:
	"""Apply fantasy aesthetic styling."""
	background.color = GameConstants.COLOR_BG_DARK

	UIStyles.apply_button_styles(confirm_button)
	UIStyles.apply_button_styles(back_button)

	instruction_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)


func _setup_options_display() -> void:
	"""Create the options TeamDisplay."""
	options_team_display = TeamDisplayScene.instantiate()
	options_display_container.add_child(options_team_display)
	# We'll set it up when options are generated


func _generate_options() -> void:
	"""Generate 3 unique character options (2 owned, 1 random)."""
	current_options.clear()
	option_instances.clear()

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
	for character in all_chars:
		var char_id = character.get("id", "")
		if char_id not in option_ids and char_id not in drafted_ids:
			random_char = character
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
			"prestige": 1,
			"fame": 0,
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

	# Create CharacterInstance objects for the options display
	for option in current_options:
		var char_instance = CharacterInstance.new(option["char_data"])
		option_instances.append(char_instance)

	# Update the options TeamDisplay
	_update_options_display()

	print("Draft: Generated %d unique options" % current_options.size())


func _update_options_display() -> void:
	"""Update the options TeamDisplay with current options."""
	if options_team_display and option_instances.size() > 0:
		# Connect to overview_shown signal to add buttons whenever tiles are created
		if not options_team_display.overview_shown.is_connected(_on_options_overview_shown):
			options_team_display.overview_shown.connect(_on_options_overview_shown)

		options_team_display.setup(option_instances, "AVAILABLE CHARACTERS")
		# Buttons will be added via the overview_shown signal


func _on_options_overview_shown() -> void:
	"""Add SELECT buttons when overview is shown (initial or returning from details)."""
	# Wait a frame for tiles to be fully ready
	await get_tree().process_frame
	_create_select_buttons()


func _create_select_buttons() -> void:
	"""Create SELECT buttons inside each character tile."""
	select_buttons.clear()

	if not options_team_display:
		return

	# Use TeamDisplay's character_tiles array directly
	var tiles = options_team_display.character_tiles

	if tiles.is_empty():
		return

	for i in range(min(tiles.size(), current_options.size())):
		var tile = tiles[i]
		var option = current_options[i]

		if not is_instance_valid(tile):
			continue

		# Get the VBoxContainer inside the tile
		var vbox = tile.get_node_or_null("MarginContainer/VBoxContainer")
		if not vbox:
			continue

		# Skip if button already exists (vbox normally has 2 children: Portrait and NameLabel)
		if vbox.get_child_count() > 2:
			continue

		# Add a spacer to push button to bottom
		var spacer = Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(spacer)

		# Create the button
		var button = Button.new()
		button.custom_minimum_size = Vector2(0, 36)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Set button text based on ownership
		if option["is_owned"]:
			button.text = "SELECT"
		else:
			button.text = "UNLOCK (%d)" % option["unlock_cost"]

		UIStyles.apply_button_styles(button)
		button.pressed.connect(_on_option_button_pressed.bind(i))

		vbox.add_child(button)
		select_buttons.append(button)


func _on_option_button_pressed(option_index: int) -> void:
	"""Handle SELECT/UNLOCK button press for an option."""
	if option_index < 0 or option_index >= current_options.size():
		return

	var option = current_options[option_index]

	# Check if owned or needs unlock
	if option["is_owned"]:
		_on_character_selected(option["char_data"])
	else:
		_on_unlock_and_select(option["char_data"], option["unlock_cost"])


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

	# Create a CharacterInstance for the team display
	var char_instance = CharacterInstance.new(char_data)
	drafted_instances.append(char_instance)

	selection_count += 1

	print("Draft: Selected %s (%d/%d)" % [char_id, selection_count, GameConstants.TEAM_SIZE])

	# Return options display to overview mode
	if options_team_display:
		options_team_display.refresh()

	_update_team_display()
	_update_instruction()

	if selection_count == GameConstants.TEAM_SIZE:
		_show_confirm_state()
	else:
		_generate_options()


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


func _update_team_display() -> void:
	"""Update the team display with drafted characters."""
	if drafted_instances.is_empty():
		team_display_container.visible = false
		return

	team_display_container.visible = true

	# Create team display if needed
	if your_team_display == null:
		your_team_display = TeamDisplayScene.instantiate()
		team_display_container.add_child(your_team_display)

	your_team_display.setup(drafted_instances, "YOUR TEAM")


func _update_instruction() -> void:
	"""Update instruction text."""
	if selection_count < GameConstants.TEAM_SIZE:
		instruction_label.text = "SELECT CHARACTER %d OF %d" % [selection_count + 1, GameConstants.TEAM_SIZE]
	else:
		instruction_label.text = "TEAM COMPLETE - READY TO START"
	print("Draft: Instruction updated to: %s" % instruction_label.text)


func _show_confirm_state() -> void:
	"""Show confirm state when team is complete."""
	print("Draft: Showing confirm state (team complete)")

	# Hide options section (display + buttons)
	options_section.visible = false

	# Show confirm button
	confirm_button.visible = true


func _on_reroll_pressed() -> void:
	"""Handle reroll button press (backend kept for future use)."""
	if PlayerAccount.spend_reroll_token():
		print("Draft: Rerolling options...")
		_generate_options()
	else:
		print("Draft: No reroll tokens available")


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
