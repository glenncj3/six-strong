extends Control
# Draft - Character selection UI for starting a run
# Uses DraftManager for business logic, this scene handles UI only
# Header bar is handled by the persistent RunHUD
# Team tiles are handled by the persistent TeamHUD

@onready var background: ColorRect = $Background
@onready var instruction_label = $MainContainer/VBoxContainer/InstructionLabel
@onready var options_section = $MainContainer/VBoxContainer/ContentScroll/ContentContainer/OptionsSection
@onready var options_display_container = $MainContainer/VBoxContainer/ContentScroll/ContentContainer/OptionsSection/OptionsDisplayContainer
@onready var confirm_button = $ConfirmButton

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
var options_info_panel: Node = null  # Local info panel for option tiles (drops down)


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
	draft_manager = DraftManager.new()
	draft_manager.options_generated.connect(_on_options_generated)
	draft_manager.character_drafted.connect(_on_character_drafted)
	draft_manager.draft_complete.connect(_on_draft_complete)


func _apply_visual_styling() -> void:
	UIStyles.apply_button_styles(confirm_button)


func _setup_options_display() -> void:
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

	# Info panel that drops down below option tiles
	# Height matches tile size; width matches TeamHUD panel (4% anchors = ~13px extra per side)
	var tile_height = _get_tile_size()
	var info_margin = MarginContainer.new()
	info_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_margin.custom_minimum_size = Vector2(0, tile_height)
	info_margin.add_theme_constant_override("margin_left", 13)
	info_margin.add_theme_constant_override("margin_right", 13)
	vbox.add_child(info_margin)

	var info_panel_clip = Control.new()
	info_panel_clip.clip_contents = true
	info_panel_clip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_margin.add_child(info_panel_clip)

	options_info_panel = CharacterInfoPanelScene.instantiate()
	options_info_panel.slide_down = true
	info_panel_clip.add_child(options_info_panel)
	options_info_panel.set_anchors_preset(Control.PRESET_FULL_RECT)


# =============================================================================
# DRAFT MANAGER SIGNAL HANDLERS
# =============================================================================

func _on_options_generated(options: Array, instances: Array) -> void:
	_update_options_display(instances)


func _on_character_drafted(_char_data: Dictionary, char_instance: CharacterInstance) -> void:
	_update_instruction()
	_update_run_hud_gold()

	# Notify TeamHUD about the drafted character
	var team_hud = get_tree().root.get_node_or_null("Main/HUDLayer/TeamHUD")
	if team_hud:
		team_hud.add_drafted_character(char_instance)

	if not draft_manager.is_draft_complete():
		draft_manager.generate_options()


func _on_draft_complete(_team: Array) -> void:
	_show_confirm_state()


func _update_run_hud_gold() -> void:
	var total_gold := 0
	for char_instance in draft_manager.drafted_instances:
		total_gold += char_instance.income
	var run_hud = get_tree().root.get_node_or_null("Main/HUDLayer/RunHUD")
	if run_hud:
		run_hud.update_draft_gold(total_gold)


# =============================================================================
# UI UPDATES
# =============================================================================

func _update_options_display(instances: Array) -> void:
	if instances.size() == 0:
		return

	# Hide info panel from previous options
	if options_info_panel and options_info_panel.is_showing():
		options_info_panel.hide_panel()

	UIHelpers.clear_children(options_tiles_container)
	character_tiles.clear()

	var tile_size = _get_tile_size()

	for char_instance in instances:
		var tile = CharacterTileScene.instantiate()
		options_tiles_container.add_child(tile)
		tile.setup(char_instance, tile_size)
		tile.tile_clicked.connect(_on_option_tile_clicked)
		character_tiles.append(tile)

	_create_select_buttons()


func _create_select_buttons() -> void:
	select_buttons.clear()

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

		UIStyles.setup_button(button, GameConstants.FONT_SIZE_BUTTON_LARGE)
		button.pressed.connect(_on_option_button_pressed.bind(i))

		buttons_container.add_child(button)
		select_buttons.append(button)


func _on_option_tile_clicked(char_instance: CharacterInstance) -> void:
	if not options_info_panel:
		return
	if options_info_panel.is_showing() and options_info_panel.current_char_instance == char_instance:
		options_info_panel.hide_panel()
	else:
		options_info_panel.show_character(char_instance)


func _on_option_button_pressed(option_index: int) -> void:
	var option = draft_manager.get_option_at(option_index)
	if option.is_empty():
		return

	if option["is_owned"]:
		draft_manager.select_character(option["char_data"])
	else:
		draft_manager.unlock_and_select(option["char_data"], option["unlock_cost"])


func _update_instruction() -> void:
	if not draft_manager.is_draft_complete():
		instruction_label.text = "SELECT CHARACTER %d OF %d" % [
			draft_manager.get_current_selection_number(),
			GameConstants.TEAM_SIZE
		]
	else:
		instruction_label.text = "TEAM COMPLETE - READY TO START"
	print("Draft: Instruction updated to: %s" % instruction_label.text)


func _show_confirm_state() -> void:
	print("Draft: Showing confirm state (team complete)")

	options_section.visible = false

	await get_tree().create_timer(2.0).timeout
	_start_run()


# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_reroll_pressed() -> void:
	if PlayerAccount.spend_reroll_token():
		print("Draft: Rerolling options...")
		draft_manager.generate_options()
	else:
		print("Draft: No reroll tokens available")


func _on_confirm_pressed() -> void:
	if not draft_manager.is_draft_complete():
		push_error("Draft: Must select exactly %d characters" % GameConstants.TEAM_SIZE)
		return
	_start_run()


func _start_run() -> void:
	print("Draft: Starting run with drafted team...")

	var char_ids = draft_manager.get_drafted_character_ids()

	print("Draft: Character IDs: %s" % str(char_ids))

	RunManager.start_new_run(char_ids)

	print("Draft: Run started, navigating to run_view...")

	SceneManager.go_to_run_view()


func _get_tile_size() -> float:
	var available_width = max(options_display_container.size.x, 688) - 24
	var tile_size = floor((available_width - 16) / float(GameConstants.TEAM_SIZE))
	return max(tile_size, 180)
