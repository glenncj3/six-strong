extends Control
## Draft - Legacy selection UI for starting a run
## Uses LegacyDraftManager for business logic, this scene handles UI only
## Header bar is handled by the persistent RunHUD
## Team tiles will show starting characters from drafted legacies

@onready var background: ColorRect = $Background
@onready var instruction_label = $MainContainer/VBoxContainer/InstructionLabel
@onready var options_section = $MainContainer/VBoxContainer/ContentScroll/ContentContainer/OptionsSection
@onready var options_display_container = $MainContainer/VBoxContainer/ContentScroll/ContentContainer/OptionsSection/OptionsDisplayContainer
@onready var confirm_button = $ConfirmButton

# Preload scenes
const LegacyTileScene = preload("res://scenes/components/legacy_tile.tscn")

# Draft manager handles business logic
var draft_manager: LegacyDraftManager = null

# UI state
var options_tiles_container: HBoxContainer = null
var legacy_tiles: Array = []  # References to option tiles
var select_buttons: Array = []  # SELECT buttons for each option


func _ready() -> void:
	_setup_draft_manager()
	_apply_visual_styling()

	confirm_button.pressed.connect(_on_confirm_pressed)

	_setup_options_display()
	draft_manager.generate_options()
	_update_instruction()
	_update_run_hud_gold()
	_play_entrance_animations()


func _play_entrance_animations() -> void:
	AnimationManager.fade_in(options_section, GameConstants.ANIM_DURATION_NORMAL, 0.1)


func _setup_draft_manager() -> void:
	draft_manager = LegacyDraftManager.new()
	draft_manager.draft_options_generated.connect(_on_options_generated)
	draft_manager.legacy_drafted.connect(_on_legacy_drafted)
	draft_manager.draft_completed.connect(_on_draft_complete)
	draft_manager.generation_failed.connect(_on_generation_failed)


func _apply_visual_styling() -> void:
	UIStyles.apply_button_styles(confirm_button)


func _setup_options_display() -> void:
	options_tiles_container = HBoxContainer.new()
	options_tiles_container.alignment = BoxContainer.ALIGNMENT_CENTER
	options_tiles_container.add_theme_constant_override("separation", 8)
	options_display_container.add_child(options_tiles_container)


# =============================================================================
# DRAFT MANAGER SIGNAL HANDLERS
# =============================================================================

func _on_options_generated(options: Array) -> void:
	_update_options_display(options)


func _on_legacy_drafted(legacy: LegacyData) -> void:
	_update_instruction()
	_update_run_hud_gold()

	# Notify HUDs about the starting character via RunManager signal
	var starting_char_id = legacy.selected_starting_character_id
	if not starting_char_id.is_empty():
		var char_instance = CharacterInstance.from_master_data(starting_char_id)
		if char_instance:
			RunManager.notify_draft_character_added(char_instance)

	if not draft_manager.is_draft_complete():
		draft_manager.generate_options()


func _on_draft_complete(_drafted_legacies: Array) -> void:
	_show_confirm_state()


func _on_generation_failed(error_message: String) -> void:
	"""Handle draft option generation failure."""
	push_error("Draft: Generation failed - %s" % error_message)
	instruction_label.text = "ERROR: %s" % error_message
	instruction_label.add_theme_color_override("font_color", GameConstants.COLOR_DANGER)


func _update_run_hud_gold() -> void:
	var total_gold = draft_manager.calculate_starting_gold()
	# Notify HUDs about gold change via RunManager signal
	RunManager.notify_draft_gold_updated(total_gold)


# =============================================================================
# UI UPDATES
# =============================================================================

func _update_options_display(options: Array) -> void:
	if options.size() == 0:
		return

	UIHelpers.clear_children(options_tiles_container)
	legacy_tiles.clear()

	var tile_size = _get_tile_size()

	var current_options = draft_manager.current_options

	for i in range(options.size()):
		var option = options[i]
		var legacy: LegacyData = option["legacy"]

		var column = VBoxContainer.new()
		column.add_theme_constant_override("separation", 8)
		options_tiles_container.add_child(column)

		var tile = LegacyTileScene.instantiate()
		column.add_child(tile)
		tile.setup(legacy, tile_size)
		legacy_tiles.append(tile)

		# Create select button directly under the tile
		var button = Button.new()
		button.custom_minimum_size = Vector2(0, 44)
		button.size_flags_horizontal = Control.SIZE_FILL

		if i < current_options.size() and current_options[i]["is_owned"]:
			button.text = "SELECT"
		elif i < current_options.size():
			button.text = "UNLOCK (%d)" % current_options[i]["unlock_cost"]

		UIStyles.setup_button(button, GameConstants.FONT_SIZE_BUTTON_LARGE)
		button.pressed.connect(_on_option_button_pressed.bind(i))
		column.add_child(button)
		select_buttons.append(button)



func _on_option_button_pressed(option_index: int) -> void:
	var option = draft_manager.get_option_at(option_index)
	if option.is_empty():
		return

	var legacy: LegacyData = option["legacy"]

	if option["is_owned"]:
		draft_manager.select_legacy(legacy)
	else:
		draft_manager.unlock_and_select(legacy, option["unlock_cost"])


func _update_instruction() -> void:
	if not draft_manager.is_draft_complete():
		instruction_label.text = "SELECT LEGACY %d OF %d" % [
			draft_manager.get_current_selection_number(),
			draft_manager.get_total_rounds()
		]
	else:
		instruction_label.text = "Legacies Selected!"


func _show_confirm_state() -> void:
	options_section.visible = false

	await get_tree().create_timer(2.0).timeout
	_start_run()


# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_reroll_pressed() -> void:
	if PlayerAccount.spend_reroll_token():
		draft_manager.generate_options()


func _on_confirm_pressed() -> void:
	if not draft_manager.is_draft_complete():
		push_error("Draft: Must select exactly %d legacies" % draft_manager.get_total_rounds())
		return
	_start_run()


func _start_run() -> void:
	var drafted_legacies = draft_manager.get_drafted_legacies()
	RunManager.start_new_run_with_legacies(drafted_legacies)

	SceneManager.go_to("run_view")


func _get_tile_size() -> float:
	return UIScaler.calculate_tile_size(options_display_container.size.x, GameConstants.TEAM_SIZE)
