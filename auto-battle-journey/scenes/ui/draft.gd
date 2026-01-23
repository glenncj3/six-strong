extends Control
# Draft - Character selection UI for starting a run
# Uses DraftManager for business logic, this scene handles UI only
# Uses two TeamDisplay panels for consistent UI:
# - Options panel: shows draftable characters
# - Team panel: shows already drafted characters

@onready var background: ColorRect = $Background
@onready var header_bar = $HeaderBar
@onready var title_label = $HeaderBar/MarginContainer/HBoxContainer/LeftSection/TitleLabel
@onready var wins_label = $HeaderBar/MarginContainer/HBoxContainer/CenterSection/WinsLabel
@onready var reputation_label = $HeaderBar/MarginContainer/HBoxContainer/CenterSection/ReputationLabel
@onready var gold_label = $HeaderBar/MarginContainer/HBoxContainer/CenterSection/GoldLabel
@onready var gems_label = $HeaderBar/MarginContainer/HBoxContainer/CenterSection/GemsLabel
@onready var concede_button = $HeaderBar/MarginContainer/HBoxContainer/RightSection/ConcedeButton
@onready var instruction_label = $MainContainer/VBoxContainer/InstructionLabel
@onready var options_section = $MainContainer/VBoxContainer/ContentScroll/ContentContainer/OptionsSection
@onready var options_display_container = $MainContainer/VBoxContainer/ContentScroll/ContentContainer/OptionsSection/OptionsDisplayContainer
@onready var team_display_container = $TeamDisplayContainer
@onready var confirm_button = $MainContainer/VBoxContainer/BottomButtons/ConfirmButton
@onready var concede_confirm_dialog = $ConcedeConfirmDialog

# Preload scenes
const TeamDisplayScene = preload("res://scenes/components/team_display.tscn")

# Draft manager handles business logic
var draft_manager: DraftManager = null

# UI state
var options_team_display: Node = null
var your_team_display: Node = null
var select_buttons: Array = []  # SELECT buttons for each option


var _concede_dialog_open: bool = false


func _ready() -> void:
	_setup_draft_manager()
	_apply_visual_styling()

	confirm_button.pressed.connect(_on_confirm_pressed)
	concede_button.pressed.connect(_on_concede_button_pressed)
	concede_confirm_dialog.confirmed.connect(_on_concede_confirmed)
	concede_confirm_dialog.canceled.connect(_on_concede_dialog_closed)
	concede_confirm_dialog.close_requested.connect(_on_concede_dialog_closed)
	PlayerAccount.gems_changed.connect(_on_gems_changed)

	# Hide team display until characters are drafted
	team_display_container.visible = false

	_setup_options_display()
	draft_manager.generate_options()
	_update_instruction()
	_update_header_stats()
	_play_entrance_animations()


func _exit_tree() -> void:
	if PlayerAccount.gems_changed.is_connected(_on_gems_changed):
		PlayerAccount.gems_changed.disconnect(_on_gems_changed)


func _play_entrance_animations() -> void:
	"""Play entrance animations."""
	AnimationManager.fade_in(header_bar, GameConstants.ANIM_DURATION_NORMAL, 0.0)
	AnimationManager.fade_in(options_section, GameConstants.ANIM_DURATION_NORMAL, 0.1)


func _setup_draft_manager() -> void:
	"""Create and connect to the draft manager."""
	draft_manager = DraftManager.new()
	draft_manager.options_generated.connect(_on_options_generated)
	draft_manager.character_drafted.connect(_on_character_drafted)
	draft_manager.draft_complete.connect(_on_draft_complete)


func _apply_visual_styling() -> void:
	"""Apply fantasy aesthetic styling."""
	background.color = GameConstants.COLOR_BG_DARK

	UIStyles.apply_button_styles(confirm_button)

	# Header stat labels
	title_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)
	reputation_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	wins_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	gold_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	gems_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)

	# Concede button styling
	_style_concede_button()


func _style_concede_button() -> void:
	"""Style the concede button as a compact red square with white X."""
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = GameConstants.COLOR_RUBY
	normal_style.corner_radius_top_left = UIStyles.CORNER_RADIUS_SMALL
	normal_style.corner_radius_top_right = UIStyles.CORNER_RADIUS_SMALL
	normal_style.corner_radius_bottom_left = UIStyles.CORNER_RADIUS_SMALL
	normal_style.corner_radius_bottom_right = UIStyles.CORNER_RADIUS_SMALL

	var hover_style = normal_style.duplicate()
	hover_style.bg_color = GameConstants.COLOR_RUBY.lightened(0.15)

	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = GameConstants.COLOR_RUBY.darkened(0.2)

	concede_button.add_theme_stylebox_override("normal", normal_style)
	concede_button.add_theme_stylebox_override("hover", hover_style)
	concede_button.add_theme_stylebox_override("pressed", pressed_style)
	concede_button.add_theme_stylebox_override("focus", normal_style)
	concede_button.add_theme_color_override("font_color", Color.WHITE)
	concede_button.add_theme_color_override("font_hover_color", Color.WHITE)
	concede_button.add_theme_color_override("font_pressed_color", GameConstants.COLOR_TEXT_LIGHT)
	concede_button.add_theme_font_size_override("font_size", 16)


func _setup_options_display() -> void:
	"""Create the options TeamDisplay."""
	options_team_display = TeamDisplayScene.instantiate()
	options_display_container.add_child(options_team_display)
	# We'll set it up when options are generated


# =============================================================================
# DRAFT MANAGER SIGNAL HANDLERS
# =============================================================================

func _on_options_generated(options: Array, instances: Array) -> void:
	"""Handle new options being generated by the draft manager."""
	_update_options_display(instances)


func _on_character_drafted(_char_data: Dictionary, _char_instance: CharacterInstance) -> void:
	"""Handle a character being drafted."""
	# Return options display to overview mode
	if options_team_display:
		options_team_display.refresh()

	_update_team_display()
	_update_instruction()
	_update_header_stats()

	if not draft_manager.is_draft_complete():
		draft_manager.generate_options()


func _on_draft_complete(_team: Array) -> void:
	"""Handle draft completion."""
	_show_confirm_state()


func _update_header_stats() -> void:
	"""Update header bar stats, including gold from drafted characters' income."""
	wins_label.text = "%s 0/%d" % [GameConstants.EMOJI_STAR, GameConstants.WINS_FOR_VICTORY]
	reputation_label.text = "%s %d" % [GameConstants.EMOJI_HEART, GameConstants.STARTING_REPUTATION]
	var total_gold := 0
	for char_instance in draft_manager.drafted_instances:
		total_gold += char_instance.income
	gold_label.text = "%s %d" % [GameConstants.EMOJI_GOLD, total_gold]
	gems_label.text = "%s %d" % [GameConstants.EMOJI_GEM, PlayerAccount.get_gems()]


# =============================================================================
# UI UPDATES
# =============================================================================

func _update_options_display(instances: Array) -> void:
	"""Update the options TeamDisplay with current options."""
	if options_team_display and instances.size() > 0:
		# Connect to overview_shown signal to add buttons whenever tiles are created
		if not options_team_display.overview_shown.is_connected(_on_options_overview_shown):
			options_team_display.overview_shown.connect(_on_options_overview_shown)

		options_team_display.setup(instances, "AVAILABLE CHARACTERS")
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

	var current_options = draft_manager.current_options

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
	var option = draft_manager.get_option_at(option_index)
	if option.is_empty():
		return

	# Check if owned or needs unlock
	if option["is_owned"]:
		draft_manager.select_character(option["char_data"])
	else:
		draft_manager.unlock_and_select(option["char_data"], option["unlock_cost"])


func _update_team_display() -> void:
	"""Update the team display with drafted characters."""
	var drafted_instances = draft_manager.drafted_instances

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
	if not draft_manager.is_draft_complete():
		instruction_label.text = "SELECT CHARACTER %d OF %d" % [
			draft_manager.get_current_selection_number(),
			GameConstants.TEAM_SIZE
		]
	else:
		instruction_label.text = "TEAM COMPLETE - READY TO START"
	print("Draft: Instruction updated to: %s" % instruction_label.text)


func _show_confirm_state() -> void:
	"""Show confirm state when team is complete."""
	print("Draft: Showing confirm state (team complete)")

	# Hide options section (display + buttons)
	options_section.visible = false

	# Hide gems (only relevant during draft picks)
	gems_label.visible = false

	# Show confirm button
	confirm_button.visible = true


# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_concede_button_pressed() -> void:
	"""Show concede confirmation dialog."""
	_concede_dialog_open = true
	concede_confirm_dialog.popup_centered()


func _on_concede_confirmed() -> void:
	"""Handle confirmed concede - return to main menu."""
	if not _concede_dialog_open:
		return
	_concede_dialog_open = false
	SceneManager.go_to_main_menu()


func _on_concede_dialog_closed() -> void:
	"""Handle dialog closed without confirmation."""
	_concede_dialog_open = false


func _on_gems_changed(new_amount: int) -> void:
	"""Update gems display when gems are spent."""
	gems_label.text = "%s %d" % [GameConstants.EMOJI_GEM, new_amount]


func _on_reroll_pressed() -> void:
	"""Handle reroll button press (backend kept for future use)."""
	if PlayerAccount.spend_reroll_token():
		print("Draft: Rerolling options...")
		draft_manager.generate_options()
	else:
		print("Draft: No reroll tokens available")


func _on_confirm_pressed() -> void:
	"""Start the run with drafted characters."""
	if not draft_manager.is_draft_complete():
		push_error("Draft: Must select exactly %d characters" % GameConstants.TEAM_SIZE)
		return

	print("Draft: Starting run with drafted team...")

	# Extract character IDs
	var char_ids = draft_manager.get_drafted_character_ids()

	print("Draft: Character IDs: %s" % str(char_ids))

	# Start run
	RunManager.start_new_run(char_ids)

	print("Draft: Run started, navigating to run_view...")

	# Navigate to run view using SceneManager
	SceneManager.go_to_run_view()
