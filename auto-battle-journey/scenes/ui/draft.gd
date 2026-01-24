extends Control
# Draft - Character selection UI for starting a run
# Uses DraftManager for business logic, this scene handles UI only

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
@onready var team_section = $TeamSection
@onready var team_title_label = $TeamSection/VBoxContainer/TitleLabel
@onready var team_tiles_container = $TeamSection/VBoxContainer/TilesContainer
@onready var info_panel_clip = $TeamSection/VBoxContainer/InfoPanelClip
@onready var confirm_button = $ConfirmButton
@onready var concede_confirm_dialog = $ConcedeConfirmDialog

# Preload scenes
const CharacterTileScene = preload("res://scenes/components/character_tile.tscn")
const CharacterInfoPanelScene = preload("res://scenes/components/character_info_panel.tscn")

# Draft manager handles business logic
var draft_manager: DraftManager = null

# UI state
var options_tiles_container: HBoxContainer = null
var character_tiles: Array = []  # References to option tiles
var select_buttons: Array = []  # SELECT buttons for each option
var buttons_container: HBoxContainer = null  # Container for SELECT/UNLOCK buttons below tiles
var info_panel: Node = null


var _concede_dialog_open: bool = false


func _ready() -> void:
	_setup_draft_manager()
	_apply_visual_styling()
	_setup_info_panel()

	confirm_button.pressed.connect(_on_confirm_pressed)
	concede_button.pressed.connect(_on_concede_button_pressed)
	concede_confirm_dialog.confirmed.connect(_on_concede_confirmed)
	concede_confirm_dialog.canceled.connect(_on_concede_dialog_closed)
	concede_confirm_dialog.close_requested.connect(_on_concede_dialog_closed)
	PlayerAccount.gems_changed.connect(_on_gems_changed)

	team_title_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	_add_placeholder_tiles()

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


func _setup_info_panel() -> void:
	info_panel = CharacterInfoPanelScene.instantiate()
	info_panel_clip.add_child(info_panel)
	info_panel.set_anchors_preset(Control.PRESET_FULL_RECT)


func _get_tile_size() -> float:
	var available_width = max(team_section.size.x, 688) - 24
	var tile_size = floor((available_width - 16) / 3.0)
	return max(tile_size, 180)


func _add_placeholder_tiles() -> void:
	"""Add invisible placeholder tiles to reserve space for team slots."""
	UIHelpers.clear_children(team_tiles_container)
	var tile_size = _get_tile_size()
	for i in range(GameConstants.TEAM_SIZE):
		var placeholder = CharacterTileScene.instantiate()
		team_tiles_container.add_child(placeholder)
		placeholder.custom_minimum_size = Vector2(tile_size, tile_size)
		placeholder.modulate.a = 0
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _setup_options_display() -> void:
	"""Create the options tiles container."""
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	options_display_container.add_child(vbox)

	options_tiles_container = HBoxContainer.new()
	options_tiles_container.alignment = BoxContainer.ALIGNMENT_CENTER
	options_tiles_container.add_theme_constant_override("separation", 8)
	vbox.add_child(options_tiles_container)

	buttons_container = HBoxContainer.new()
	buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_container.add_theme_constant_override("separation", 8)
	vbox.add_child(buttons_container)


# =============================================================================
# DRAFT MANAGER SIGNAL HANDLERS
# =============================================================================

func _on_options_generated(options: Array, instances: Array) -> void:
	"""Handle new options being generated by the draft manager."""
	_update_options_display(instances)


func _on_character_drafted(_char_data: Dictionary, _char_instance: CharacterInstance) -> void:
	"""Handle a character being drafted."""
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
	"""Update the options display with current character tiles."""
	if instances.size() == 0:
		return

	UIHelpers.clear_children(options_tiles_container)
	character_tiles.clear()

	var available_width = max(options_display_container.size.x, 688) - 24
	var tile_size = floor((available_width - 16) / 3.0)
	tile_size = max(tile_size, 180)

	for char_instance in instances:
		var tile = CharacterTileScene.instantiate()
		options_tiles_container.add_child(tile)
		tile.setup(char_instance, tile_size)
		tile.tile_clicked.connect(_on_tile_clicked)
		character_tiles.append(tile)

	_create_select_buttons()


func _create_select_buttons() -> void:
	"""Create SELECT/UNLOCK buttons below the character tiles."""
	select_buttons.clear()

	# Clear existing buttons
	for child in buttons_container.get_children():
		child.queue_free()

	if character_tiles.is_empty():
		return

	var current_options = draft_manager.current_options

	for i in range(min(character_tiles.size(), current_options.size())):
		var tile = character_tiles[i]
		var option = current_options[i]

		var button = Button.new()
		var tile_width = tile.custom_minimum_size.x
		button.custom_minimum_size = Vector2(tile_width, 44)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		if option["is_owned"]:
			button.text = "SELECT"
		else:
			button.text = "UNLOCK (%d)" % option["unlock_cost"]

		UIStyles.apply_button_styles(button)
		button.add_theme_font_size_override("font_size", 28)
		button.pressed.connect(_on_option_button_pressed.bind(i))

		buttons_container.add_child(button)
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


func _on_tile_clicked(char_instance: CharacterInstance) -> void:
	"""Handle tile click - show/hide info panel."""
	if info_panel.is_showing() and info_panel.current_char_instance == char_instance:
		info_panel.hide_panel()
	else:
		info_panel.show_character(char_instance)


func _update_team_display() -> void:
	"""Update the team display with drafted characters."""
	var drafted_instances = draft_manager.drafted_instances
	UIHelpers.clear_children(team_tiles_container)

	var tile_size = _get_tile_size()

	for char_instance in drafted_instances:
		var tile = CharacterTileScene.instantiate()
		team_tiles_container.add_child(tile)
		tile.setup(char_instance, tile_size)
		tile.tile_clicked.connect(_on_tile_clicked)

	# Fill remaining slots with invisible placeholders (use real tiles for correct height)
	for i in range(drafted_instances.size(), GameConstants.TEAM_SIZE):
		var placeholder = CharacterTileScene.instantiate()
		team_tiles_container.add_child(placeholder)
		placeholder.custom_minimum_size = Vector2(tile_size, tile_size)
		placeholder.modulate.a = 0
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE


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

	# Pause for 3 seconds (loading time) then auto-start the run
	await get_tree().create_timer(2.0).timeout
	_start_run()


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
	"""Start the run with drafted characters (legacy button handler)."""
	if not draft_manager.is_draft_complete():
		push_error("Draft: Must select exactly %d characters" % GameConstants.TEAM_SIZE)
		return
	_start_run()


func _start_run() -> void:
	"""Start the run with drafted characters."""
	print("Draft: Starting run with drafted team...")

	# Extract character IDs
	var char_ids = draft_manager.get_drafted_character_ids()

	print("Draft: Character IDs: %s" % str(char_ids))

	# Start run
	RunManager.start_new_run(char_ids)

	print("Draft: Run started, navigating to run_view...")

	# Navigate to run view using SceneManager
	SceneManager.go_to_run_view()
