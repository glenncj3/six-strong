extends Control
## CombatScene - Real-time automated combat between player and enemy teams.
## Uses CombatManager for cooldown-based combat and GridSlot components for display.

const MAX_LOG_LINES := 50
const GridSlotScene = preload("res://scenes/components/grid_slot.tscn")

var combat_data: Dictionary = {}
var _manager: CombatManager
var _player_grid: CharacterGrid
var _enemy_grid: CharacterGrid

# UI references (built in _ready)
var _enemy_grid_container: VBoxContainer
var _player_grid_container: VBoxContainer
var _log_container: VBoxContainer
var _log_scroll: ScrollContainer
var _result_overlay: Control
var _result_label: Label
var _continue_button: Button

# Slot displays: key = CombatCharacter, value = Dictionary with ui nodes
var _slot_displays: Dictionary = {}

# Map CombatCharacter -> source CharacterInstance for health restoration
var _combat_to_source: Dictionary = {}


func _ready() -> void:
	combat_data = SceneTransitionData.get_combat()
	if combat_data.is_empty():
		push_error("CombatScene: No combat data found!")
		return

	RunFlowController.combat_completed.connect(_on_combat_completed)

	_setup_combat()
	_build_ui()
	_start_combat()


func _exit_tree() -> void:
	if RunFlowController.combat_completed.is_connected(_on_combat_completed):
		RunFlowController.combat_completed.disconnect(_on_combat_completed)


# =============================================================================
# UI BUILDING
# =============================================================================

func _build_ui() -> void:
	# Background
	var bg_scene = load("res://scenes/components/abstract_background.tscn")
	var bg = bg_scene.instantiate()
	bg.layout_mode = 1
	add_child(bg)

	# Main layout
	var main_vbox = VBoxContainer.new()
	main_vbox.layout_mode = 1
	main_vbox.anchors_preset = Control.PRESET_FULL_RECT
	main_vbox.anchor_left = 0.02
	main_vbox.anchor_top = 0.02
	main_vbox.anchor_right = 0.98
	main_vbox.anchor_bottom = 0.98
	main_vbox.add_theme_constant_override("separation", 8)
	add_child(main_vbox)

	# Enemy section (top)
	_enemy_grid_container = _build_team_section(
		combat_data.get("name", "Enemy"),
		true
	)
	main_vbox.add_child(_enemy_grid_container)

	# Combat log (middle)
	_log_scroll = ScrollContainer.new()
	_log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_scroll.size_flags_stretch_ratio = 1.0
	_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_log_scroll)

	_log_container = VBoxContainer.new()
	_log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_container.add_theme_constant_override("separation", 4)
	_log_scroll.add_child(_log_container)

	# Player section (bottom)
	_player_grid_container = _build_team_section("Your Team", false)
	main_vbox.add_child(_player_grid_container)

	# Result overlay (hidden)
	_result_overlay = Control.new()
	_result_overlay.set("layout_mode", 1)
	_result_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_result_overlay.visible = false
	_result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_result_overlay)

	var overlay_bg = ColorRect.new()
	overlay_bg.layout_mode = 1
	overlay_bg.anchors_preset = Control.PRESET_FULL_RECT
	overlay_bg.color = Color(0, 0, 0, 0.7)
	_result_overlay.add_child(overlay_bg)

	var result_vbox = VBoxContainer.new()
	result_vbox.layout_mode = 1
	result_vbox.anchors_preset = Control.PRESET_CENTER
	result_vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	result_vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	result_vbox.custom_minimum_size = Vector2(400, 200)
	result_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	result_vbox.add_theme_constant_override("separation", 30)
	_result_overlay.add_child(result_vbox)

	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_HEADING)
	result_vbox.add_child(_result_label)

	_continue_button = Button.new()
	_continue_button.text = "Continue"
	_continue_button.custom_minimum_size = Vector2(200, 50)
	_continue_button.pressed.connect(_on_continue_pressed)
	UIStyles.setup_success_button(_continue_button)
	ButtonEffects.apply_effects(_continue_button)
	result_vbox.add_child(_continue_button)


func _build_team_section(team_name: String, is_enemy: bool) -> VBoxContainer:
	var section = VBoxContainer.new()
	section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	section.size_flags_stretch_ratio = 1.2
	section.add_theme_constant_override("separation", 4)

	var label = Label.new()
	label.text = team_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BODY)
	label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	section.add_child(label)

	var grid_box = VBoxContainer.new()
	grid_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_box.add_theme_constant_override("separation", 4)
	grid_box.alignment = BoxContainer.ALIGNMENT_CENTER
	section.add_child(grid_box)

	if is_enemy:
		grid_box.add_child(_build_row_container(GameConstants.ROW_BACK, is_enemy))
		grid_box.add_child(_build_row_container(GameConstants.ROW_FRONT, is_enemy))
	else:
		grid_box.add_child(_build_row_container(GameConstants.ROW_FRONT, is_enemy))
		grid_box.add_child(_build_row_container(GameConstants.ROW_BACK, is_enemy))

	return section


func _build_row_container(row: int, is_enemy: bool) -> HBoxContainer:
	var row_container = HBoxContainer.new()
	row_container.alignment = BoxContainer.ALIGNMENT_CENTER
	row_container.add_theme_constant_override("separation", 8)
	row_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var grid = _enemy_grid if is_enemy else _player_grid
	for col in range(GameConstants.GRID_COLS):
		var slot_wrapper = _build_slot_display(grid, row, col, is_enemy)
		row_container.add_child(slot_wrapper)

	return row_container


func _build_slot_display(grid: CharacterGrid, row: int, col: int, is_enemy: bool) -> Control:
	var wrapper = Control.new()
	wrapper.custom_minimum_size = Vector2(100, 120)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var slot: GridSlot = GridSlotScene.instantiate()
	slot.set("layout_mode", 1)
	slot.anchors_preset = Control.PRESET_FULL_RECT
	slot.anchor_bottom = 1.0
	slot.anchor_right = 1.0
	slot.setup_slot(row, col, Vector2(100, 120))
	wrapper.add_child(slot)

	var character = grid.get_character_at(row, col) if grid else null
	if character:
		slot.ready.connect(func(): slot.set_character(character), CONNECT_ONE_SHOT)
	else:
		slot.ready.connect(func(): slot.set_character(null), CONNECT_ONE_SHOT)

	# Health bar container
	var hp_container = VBoxContainer.new()
	hp_container.layout_mode = 1
	hp_container.anchors_preset = Control.PRESET_BOTTOM_WIDE
	hp_container.anchor_top = 0.78
	hp_container.anchor_bottom = 1.0
	hp_container.anchor_left = 0.05
	hp_container.anchor_right = 0.95
	hp_container.add_theme_constant_override("separation", 1)
	hp_container.alignment = BoxContainer.ALIGNMENT_END
	hp_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(hp_container)

	var hp_bar_bg = ColorRect.new()
	hp_bar_bg.custom_minimum_size = Vector2(0, 8)
	hp_bar_bg.color = Color("#222222")
	hp_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_container.add_child(hp_bar_bg)

	var hp_bar = ColorRect.new()
	hp_bar.custom_minimum_size = Vector2(0, 8)
	hp_bar.color = Color("#44AA44") if not is_enemy else Color("#AA4444")
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar_bg.add_child(hp_bar)

	var hp_label = Label.new()
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 10)
	hp_label.add_theme_color_override("font_color", Color("#CCCCCC"))
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_container.add_child(hp_label)

	# Store display info keyed by grid position for later lookup by CombatCharacter
	var team_idx = GameConstants.TEAM_OPPONENT if is_enemy else GameConstants.TEAM_PLAYER
	var pos_key = "%d_%d_%d" % [team_idx, row, col]
	_slot_displays[pos_key] = {
		"slot": slot,
		"hp_bar_bg": hp_bar_bg,
		"hp_bar": hp_bar,
		"hp_label": hp_label,
		"is_enemy": is_enemy,
		"wrapper": wrapper,
	}

	if character:
		_update_slot_hp(pos_key, character.current_health, character.max_health, true)
	else:
		hp_bar_bg.visible = false
		hp_label.text = ""

	return wrapper


func _update_slot_hp(pos_key: String, current_hp: float, max_hp: float, alive: bool) -> void:
	if not _slot_displays.has(pos_key):
		return
	var d = _slot_displays[pos_key]
	var hp_bar: ColorRect = d["hp_bar"]
	var hp_label: Label = d["hp_label"]
	var wrapper: Control = d["wrapper"]

	if alive and current_hp > 0:
		var ratio = current_hp / max(1.0, max_hp)
		hp_bar.set("layout_mode", 1)
		hp_bar.anchors_preset = Control.PRESET_FULL_RECT
		hp_bar.anchor_right = ratio
		hp_bar.visible = true
		hp_label.text = "%d/%d" % [int(current_hp), int(max_hp)]
		wrapper.modulate.a = 1.0
	else:
		hp_bar.visible = false
		hp_label.text = "DEAD"
		hp_label.add_theme_color_override("font_color", Color("#AA4444"))
		wrapper.modulate.a = 0.4


func _get_pos_key(character: CombatCharacter) -> String:
	return "%d_%d_%d" % [character.team, character.row, character.column]


# =============================================================================
# COMBAT LOGIC
# =============================================================================

func _setup_combat() -> void:
	_player_grid = RunManager.get_character_grid()

	if combat_data.has("enemy_team"):
		_enemy_grid = CharacterGrid.from_dict(combat_data["enemy_team"])
	else:
		_enemy_grid = CharacterGrid.new()
		push_warning("CombatScene: No enemy_team in combat data")

	_manager = CombatManager.new()
	add_child(_manager)


func _start_combat() -> void:
	# Connect signals before initializing
	_manager.damage_dealt.connect(_on_damage_dealt)
	_manager.damage_blocked.connect(_on_damage_blocked)
	_manager.character_died.connect(_on_character_died)
	_manager.combat_ended.connect(_on_combat_ended)

	_add_log_line("Combat begins!", GameConstants.COLOR_TEXT_LIGHT)
	_manager.initialize_combat(_player_grid, _enemy_grid)


func _on_damage_dealt(source: CombatCharacter, target: CombatCharacter, amount: float, is_crit: bool) -> void:
	var atk_name = source.character_name
	var def_name = target.character_name

	if is_crit:
		_add_log_line(
			"%s CRITS %s for %d damage!" % [atk_name, def_name, int(amount)],
			Color("#FFAA00")
		)
	else:
		_add_log_line(
			"%s attacks %s for %d damage." % [atk_name, def_name, int(amount)],
			GameConstants.COLOR_TEXT_LIGHT
		)

	_update_slot_hp(_get_pos_key(target), target.health, target.max_health, target.is_alive)


func _on_damage_blocked(source: CombatCharacter, target: CombatCharacter) -> void:
	_add_log_line(
		"%s attacks %s — BLOCKED!" % [source.character_name, target.character_name],
		Color("#8888CC")
	)


func _on_character_died(character: CombatCharacter) -> void:
	_add_log_line(
		"  %s has been defeated!" % character.character_name,
		Color("#CC4444")
	)
	_update_slot_hp(_get_pos_key(character), 0, character.max_health, false)


func _on_combat_ended(winner: int, _reason: String) -> void:
	# Restore player health after combat
	for ch in _player_grid.get_all_characters():
		ch.restore_full_health()

	if winner == GameConstants.TEAM_PLAYER:
		_add_log_line("VICTORY!", GameConstants.COLOR_SUCCESS)
		_result_label.text = "VICTORY!"
		_result_label.add_theme_color_override("font_color", GameConstants.COLOR_SUCCESS)
	elif winner == GameConstants.TEAM_OPPONENT:
		_add_log_line("DEFEAT...", GameConstants.COLOR_DANGER)
		_result_label.text = "DEFEAT"
		_result_label.add_theme_color_override("font_color", GameConstants.COLOR_DANGER)
	else:
		_add_log_line("DRAW", GameConstants.COLOR_WARNING)
		_result_label.text = "DRAW"
		_result_label.add_theme_color_override("font_color", GameConstants.COLOR_WARNING)

	# Show result after a delay
	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(func():
		if is_inside_tree():
			_result_overlay.visible = true
	)


func _add_log_line(text: String, color: Color) -> void:
	var label_node = Label.new()
	label_node.text = text
	label_node.add_theme_font_size_override("font_size", 13)
	label_node.add_theme_color_override("font_color", color)
	label_node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_container.add_child(label_node)

	while _log_container.get_child_count() > MAX_LOG_LINES:
		var old = _log_container.get_child(0)
		_log_container.remove_child(old)
		old.queue_free()

	# Scroll to bottom next frame
	get_tree().process_frame.connect(func():
		if is_inside_tree():
			_log_scroll.scroll_vertical = int(_log_scroll.get_v_scroll_bar().max_value)
	, CONNECT_ONE_SHOT)


func _on_continue_pressed() -> void:
	_continue_button.disabled = true
	var winner = _manager.get_state().winner if _manager.get_state() else GameConstants.TEAM_OPPONENT
	RunFlowController.complete_combat(winner, combat_data)


func _on_combat_completed(winner: int, run_over: bool) -> void:
	if run_over:
		SceneManager.go_to("run_results")
	else:
		SceneManager.go_to("run_view")
