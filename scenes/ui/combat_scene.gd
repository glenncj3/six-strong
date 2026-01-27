extends Control
## CombatScene - Automated combat between player and enemy teams.
## Replaces combat_stub with real auto-battle visualization.

const TURN_DELAY := 0.8  # seconds between turns
const MAX_LOG_LINES := 50

var combat_data: Dictionary = {}
var _engine: CombatEngine
var _player_grid: CharacterGrid
var _enemy_grid: CharacterGrid
var _combat_running := false

# UI references (built in _ready)
var _enemy_grid_container: VBoxContainer
var _player_grid_container: VBoxContainer
var _log_container: VBoxContainer
var _log_scroll: ScrollContainer
var _result_overlay: Control
var _result_label: Label
var _continue_button: Button

# Slot displays: key = CharacterInstance, value = Dictionary with ui nodes
var _slot_displays: Dictionary = {}


func _ready() -> void:
	combat_data = SceneTransitionData.get_combat()
	if combat_data.is_empty():
		push_error("CombatScene: No combat data found!")
		return

	RunFlowController.combat_completed.connect(_on_combat_completed)

	_build_ui()
	_setup_combat()
	_start_combat()


func _exit_tree() -> void:
	if RunFlowController.combat_completed.is_connected(_on_combat_completed):
		RunFlowController.combat_completed.disconnect(_on_combat_completed)


# =============================================================================
# UI BUILDING
# =============================================================================

func _build_ui() -> void:
	"""Build the combat UI programmatically."""
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
	_result_overlay.layout_mode = 1
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
	"""Build a team display section with label and 2x3 grid of character slots."""
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

	# Build 2x3 grid: for enemies, back row on top; for player, front row on top
	var grid_box = VBoxContainer.new()
	grid_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_box.add_theme_constant_override("separation", 4)
	grid_box.alignment = BoxContainer.ALIGNMENT_CENTER
	section.add_child(grid_box)

	if is_enemy:
		# Enemy: back row (row 1) on top, front row (row 0) closer to center
		grid_box.add_child(_build_row_container(1, is_enemy))
		grid_box.add_child(_build_row_container(0, is_enemy))
	else:
		# Player: front row (row 0) on top (closer to center), back row (row 1) below
		grid_box.add_child(_build_row_container(0, is_enemy))
		grid_box.add_child(_build_row_container(1, is_enemy))

	return section


func _build_row_container(row: int, is_enemy: bool) -> HBoxContainer:
	"""Build a row of 3 character slot displays."""
	var row_container = HBoxContainer.new()
	row_container.alignment = BoxContainer.ALIGNMENT_CENTER
	row_container.add_theme_constant_override("separation", 8)
	row_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var grid = _enemy_grid if is_enemy else _player_grid
	for col in range(3):
		var slot = _build_slot_display(grid, row, col, is_enemy)
		row_container.add_child(slot)

	return row_container


func _build_slot_display(grid: CharacterGrid, row: int, col: int, is_enemy: bool) -> PanelContainer:
	"""Build a single character slot display."""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(100, 80)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color("#2A2A3A")
	stylebox.corner_radius_top_left = 6
	stylebox.corner_radius_top_right = 6
	stylebox.corner_radius_bottom_left = 6
	stylebox.corner_radius_bottom_right = 6
	stylebox.border_width_bottom = 2
	stylebox.border_width_top = 2
	stylebox.border_width_left = 2
	stylebox.border_width_right = 2
	stylebox.border_color = Color("#444466")
	panel.add_theme_stylebox_override("panel", stylebox)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	vbox.add_child(name_label)

	# Health bar background
	var hp_bar_bg = ColorRect.new()
	hp_bar_bg.custom_minimum_size = Vector2(80, 10)
	hp_bar_bg.color = Color("#333333")
	vbox.add_child(hp_bar_bg)

	var hp_bar = ColorRect.new()
	hp_bar.custom_minimum_size = Vector2(80, 10)
	hp_bar.color = Color("#44AA44") if not is_enemy else Color("#AA4444")
	hp_bar_bg.add_child(hp_bar)

	var hp_label = Label.new()
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 11)
	hp_label.add_theme_color_override("font_color", Color("#AAAAAA"))
	vbox.add_child(hp_label)

	var character = grid.get_character_at(row, col) if grid else null
	var display = {
		"panel": panel,
		"name_label": name_label,
		"hp_bar_bg": hp_bar_bg,
		"hp_bar": hp_bar,
		"hp_label": hp_label,
		"stylebox": stylebox,
		"is_enemy": is_enemy,
	}

	if character:
		_slot_displays[character] = display
		_update_slot_display(character)
	else:
		name_label.text = "Empty"
		hp_label.text = ""
		hp_bar.visible = false
		panel.modulate.a = 0.3

	return panel


func _update_slot_display(character: CharacterInstance) -> void:
	"""Update a slot's visual to reflect current character state."""
	if not _slot_displays.has(character):
		return
	var d = _slot_displays[character]
	var name_label: Label = d["name_label"]
	var hp_bar: ColorRect = d["hp_bar"]
	var hp_bar_bg: ColorRect = d["hp_bar_bg"]
	var hp_label: Label = d["hp_label"]
	var panel: PanelContainer = d["panel"]
	var stylebox: StyleBoxFlat = d["stylebox"]

	name_label.text = character.get_character_name()
	if character.is_alive():
		var ratio = float(character.current_health) / max(1, character.max_health)
		hp_bar.custom_minimum_size.x = hp_bar_bg.custom_minimum_size.x * ratio
		hp_label.text = "%d/%d" % [character.current_health, character.max_health]
		panel.modulate.a = 1.0
	else:
		hp_bar.custom_minimum_size.x = 0
		hp_label.text = "DEAD"
		hp_label.add_theme_color_override("font_color", Color("#AA4444"))
		panel.modulate.a = 0.4
		stylebox.border_color = Color("#662222")


# =============================================================================
# COMBAT LOGIC
# =============================================================================

func _setup_combat() -> void:
	"""Initialize grids and engine."""
	_player_grid = RunManager.get_character_grid()

	# Reconstruct enemy grid from combat data
	if combat_data.has("enemy_team"):
		_enemy_grid = CharacterGrid.from_dict(combat_data["enemy_team"])
	else:
		_enemy_grid = CharacterGrid.new()
		push_warning("CombatScene: No enemy_team in combat data")

	_engine = CombatEngine.new()
	_engine.start(_player_grid, _enemy_grid)


func _start_combat() -> void:
	"""Begin the turn-by-turn combat loop."""
	_combat_running = true
	_add_log_line("Combat begins!", GameConstants.COLOR_TEXT_LIGHT)
	await get_tree().create_timer(0.5).timeout
	_run_combat_loop()


func _run_combat_loop() -> void:
	"""Step through combat turns with delays."""
	while not _engine.is_combat_over() and is_inside_tree():
		var result = _engine.execute_next_turn()
		if result.is_empty():
			break
		_process_turn_result(result)
		await get_tree().create_timer(TURN_DELAY).timeout

	if is_inside_tree():
		_on_combat_finished()


func _process_turn_result(result: Dictionary) -> void:
	"""Update UI for a single turn result."""
	var attacker: CharacterInstance = result["attacker"]
	var defender: CharacterInstance = result["defender"]
	var dmg: int = result["damage"]
	var was_crit: bool = result["was_crit"]
	var was_blocked: bool = result["was_blocked"]
	var defender_died: bool = result["defender_died"]

	var atk_name = attacker.get_character_name()
	var def_name = defender.get_character_name()

	if was_blocked:
		_add_log_line(
			"%s attacks %s — BLOCKED!" % [atk_name, def_name],
			Color("#8888CC")
		)
	elif was_crit:
		_add_log_line(
			"%s CRITS %s for %d damage!" % [atk_name, def_name, dmg],
			Color("#FFAA00")
		)
	else:
		_add_log_line(
			"%s attacks %s for %d damage." % [atk_name, def_name, dmg],
			GameConstants.COLOR_TEXT_LIGHT
		)

	if defender_died:
		_add_log_line(
			"  %s has been defeated!" % def_name,
			Color("#CC4444")
		)

	# Update health displays
	_update_slot_display(defender)
	_update_slot_display(attacker)


func _add_log_line(text: String, color: Color) -> void:
	"""Add a line to the combat log."""
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_container.add_child(label)

	# Trim old lines
	while _log_container.get_child_count() > MAX_LOG_LINES:
		var old = _log_container.get_child(0)
		_log_container.remove_child(old)
		old.queue_free()

	# Scroll to bottom
	await get_tree().process_frame
	if is_inside_tree():
		_log_scroll.scroll_vertical = int(_log_scroll.get_v_scroll_bar().max_value)


func _on_combat_finished() -> void:
	"""Show result overlay."""
	_combat_running = false
	var won = _engine.did_player_win()

	if won:
		_add_log_line("VICTORY!", GameConstants.COLOR_SUCCESS)
		_result_label.text = "VICTORY!"
		_result_label.add_theme_color_override("font_color", GameConstants.COLOR_SUCCESS)
	else:
		_add_log_line("DEFEAT...", GameConstants.COLOR_DANGER)
		_result_label.text = "DEFEAT"
		_result_label.add_theme_color_override("font_color", GameConstants.COLOR_DANGER)

	# Restore player health after combat
	for ch in _player_grid.get_all_characters():
		ch.restore_full_health()

	await get_tree().create_timer(1.0).timeout
	if is_inside_tree():
		_result_overlay.visible = true


func _on_continue_pressed() -> void:
	"""Trigger post-combat flow."""
	_continue_button.disabled = true
	var won = _engine.did_player_win()
	RunFlowController.complete_combat(won, combat_data)


func _on_combat_completed(_won: bool, run_over: bool) -> void:
	"""Handle navigation after combat is processed."""
	if run_over:
		SceneManager.go_to("run_results")
	else:
		SceneManager.go_to("run_view")
