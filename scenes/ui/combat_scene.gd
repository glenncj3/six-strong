extends Control
## CombatScene - Real-time automated combat between player and enemy teams.
## Uses CombatManager for cooldown-based combat and CharacterTile components for display.
## Player grid matches TeamHUD positioning; enemy grid mirrors at top.
## Combat log output goes to console via print().

const CharacterTileScene = preload("res://scenes/components/character_tile.tscn")
const CombatVFXScript = preload("res://scripts/effects/combat_vfx.gd")

var combat_data: Dictionary = {}
var _manager: CombatManager
var _player_grid: CharacterGrid
var _enemy_grid: CharacterGrid
var _combat_vfx: RefCounted

# UI references
var _enemy_label: Label
var _result_overlay: Control
var _result_label: Label
var _continue_button: Button

# Slot displays: key = "team_row_col", value = Dictionary with ui nodes
var _slot_displays: Dictionary = {}



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

	# Enemy label (between header and enemy grid)
	_enemy_label = Label.new()
	_enemy_label.text = combat_data.get("name", "Enemy")
	_enemy_label.set("layout_mode", 1)
	_enemy_label.anchors_preset = -1
	_enemy_label.anchor_left = 0.04
	_enemy_label.anchor_top = 0.06
	_enemy_label.anchor_right = 0.96
	_enemy_label.anchor_bottom = 0.10
	_enemy_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_enemy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_enemy_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BODY)
	_enemy_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	add_child(_enemy_label)

	# Enemy grid: anchored at top, mirroring player grid position
	# Player TeamHUD is at: left=0.04, top=0.55, right=0.96, bottom=0.90
	# Enemy mirrors at:     left=0.04, top=0.10, right=0.96, bottom=0.45
	var enemy_grid_control = _build_grid_control(0.04, 0.10, 0.96, 0.45, true)
	add_child(enemy_grid_control)

	# Player grid: matches TeamHUD anchors exactly
	var player_grid_control = _build_grid_control(0.04, 0.55, 0.96, 0.90, false)
	add_child(player_grid_control)

	# Result overlay (hidden)
	_build_result_overlay()


func _build_grid_control(a_left: float, a_top: float, a_right: float, a_bottom: float, is_enemy: bool) -> Control:
	var container = Control.new()
	container.layout_mode = 1
	container.anchors_preset = -1
	container.anchor_left = a_left
	container.anchor_top = a_top
	container.anchor_right = a_right
	container.anchor_bottom = a_bottom
	container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	container.grow_vertical = Control.GROW_DIRECTION_BOTH
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vbox = VBoxContainer.new()
	vbox.layout_mode = 1
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.add_theme_constant_override("separation", 36)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(vbox)

	# Enemy: back row first (visually farther), then front row
	# Player: front row first, then back row
	if is_enemy:
		vbox.add_child(_build_row_container(GameConstants.ROW_BACK, is_enemy))
		vbox.add_child(_build_row_container(GameConstants.ROW_FRONT, is_enemy))
	else:
		vbox.add_child(_build_row_container(GameConstants.ROW_FRONT, is_enemy))
		vbox.add_child(_build_row_container(GameConstants.ROW_BACK, is_enemy))

	return container


func _build_row_container(row: int, is_enemy: bool) -> HBoxContainer:
	var row_container = HBoxContainer.new()
	row_container.alignment = BoxContainer.ALIGNMENT_CENTER
	row_container.add_theme_constant_override("separation", 8)
	row_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var grid = _enemy_grid if is_enemy else _player_grid
	for col_idx in range(GameConstants.GRID_COLS):
		var slot_wrapper = _build_slot_display(grid, row, col_idx, is_enemy)
		row_container.add_child(slot_wrapper)

	return row_container


func _build_slot_display(grid: CharacterGrid, row: int, col: int, is_enemy: bool) -> Control:
	# Calculate slot size the same way TeamHUD does
	var screen_width = get_viewport().get_visible_rect().size.x
	var grid_width = screen_width * 0.92  # 0.96 - 0.04 = 0.92 of screen
	var slot_width = UIScaler.calculate_tile_size(grid_width, GameConstants.GRID_COLS)
	var slot_size = Vector2(slot_width, slot_width)

	var slot: CharacterTile = CharacterTileScene.instantiate()
	slot.setup_slot(row, col, slot_size)

	var character = grid.get_character_at(row, col) if grid else null
	if character:
		slot.ready.connect(func(): slot.set_character(character), CONNECT_ONE_SHOT)
	else:
		slot.ready.connect(func(): slot.set_character(null), CONNECT_ONE_SHOT)

	# Store display info
	var team_idx = GameConstants.TEAM_OPPONENT if is_enemy else GameConstants.TEAM_PLAYER
	var pos_key = "%d_%d_%d" % [team_idx, row, col]
	_slot_displays[pos_key] = {
		"slot": slot,
		"is_enemy": is_enemy,
	}

	if character:
		var pk = pos_key
		var hp = character.current_health
		var mhp = character.max_health
		slot.ready.connect(func(): _update_slot_hp(pk, hp, mhp, true), CONNECT_ONE_SHOT)

	return slot


func _build_result_overlay() -> void:
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


func _update_slot_hp(pos_key: String, current_hp: float, max_hp: float, alive: bool) -> void:
	if not _slot_displays.has(pos_key):
		return
	var slot: CharacterTile = _slot_displays[pos_key]["slot"]

	if alive and current_hp > 0:
		slot.update_health_bar(int(current_hp), int(max_hp))
		slot.modulate.a = 1.0
	else:
		slot.update_health_bar(0, int(max_hp))
		slot.modulate.a = 0.4


func _get_pos_key(character: CombatCharacter) -> String:
	return "%d_%d_%d" % [character.team, character.row, character.column]


func _update_slot_stats(combat_char: CombatCharacter) -> void:
	var pos_key = _get_pos_key(combat_char)
	if not _slot_displays.has(pos_key):
		return
	var slot: CharacterTile = _slot_displays[pos_key]["slot"]
	slot.update_stats_from_combat(combat_char)


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
	_manager.damage_dealt.connect(_on_damage_dealt)
	_manager.damage_blocked.connect(_on_damage_blocked)
	_manager.character_died.connect(_on_character_died)
	_manager.combat_ended.connect(_on_combat_ended)
	_manager.ability_used.connect(_on_ability_used)
	_manager.effect_applied.connect(_on_effect_applied)
	_manager.effect_removed.connect(_on_effect_removed)
	_manager.character_healed.connect(_on_character_healed)
	_manager.shield_absorbed.connect(_on_shield_absorbed)

	# VFX system
	_combat_vfx = CombatVFXScript.new()
	_combat_vfx.connect_to_manager(_manager, _slot_displays, self)

	print("[Combat] Battle begins!")
	_manager.initialize_combat(_player_grid, _enemy_grid)


func _get_team_label(character: CombatCharacter) -> String:
	if character.team == GameConstants.TEAM_PLAYER:
		return "[Player]"
	return "[Enemy]"


func _on_damage_dealt(source: CombatCharacter, target: CombatCharacter, amount: float, is_crit: bool) -> void:
	var tgt_label = _get_team_label(target)

	if source == null:
		print("[Combat] %s %s takes %d damage." % [tgt_label, target.character_name, int(amount)])
	elif is_crit:
		print("[Combat] %s %s CRITS %s %s for %d damage!" % [_get_team_label(source), source.character_name, tgt_label, target.character_name, int(amount)])
	else:
		print("[Combat] %s %s attacks %s %s for %d damage." % [_get_team_label(source), source.character_name, tgt_label, target.character_name, int(amount)])

	_update_slot_hp(_get_pos_key(target), target.health, target.max_health, target.is_alive)
	if source:
		_update_slot_stats(source)


func _on_damage_blocked(source: CombatCharacter, target: CombatCharacter) -> void:
	if source == null:
		return
	print("[Combat] %s %s attacks %s %s — DODGED!" % [_get_team_label(source), source.character_name, _get_team_label(target), target.character_name])


func _on_ability_used(source: CombatCharacter, ability: Dictionary, targets: Array) -> void:
	var ability_name = ability.get("id", "unknown")
	var target_names = []
	for t in targets:
		target_names.append(t.character_name)
	print("[Combat] %s %s uses [%s] → %s" % [_get_team_label(source), source.character_name, ability_name, ", ".join(target_names)])
	_update_slot_stats(source)
	for t in targets:
		_update_slot_stats(t)


func _on_effect_applied(target: CombatCharacter, effect: CombatEffect) -> void:
	var effect_name = effect.effect_id if effect.effect_id != "" else effect.stat
	var detail = ""
	if effect.effect_type == "status" and effect.stacks > 0:
		detail = " (%d stacks)" % effect.stacks
	elif effect.effect_type == "stat_modifier":
		var sign_str = "+" if effect.value >= 0 else ""
		if effect.modifier_type == "percent":
			detail = " (%s%d%% %s)" % [sign_str, int(effect.value * 100), effect.stat]
		else:
			detail = " (%s%d %s)" % [sign_str, int(effect.value), effect.stat]
	print("[Combat] %s %s gains effect [%s]%s" % [_get_team_label(target), target.character_name, effect_name, detail])
	_update_slot_stats(target)


func _on_effect_removed(target: CombatCharacter, effect: CombatEffect) -> void:
	var effect_name = effect.effect_id if effect.effect_id != "" else effect.stat
	print("[Combat] %s %s loses effect [%s]" % [_get_team_label(target), target.character_name, effect_name])
	_update_slot_stats(target)


func _on_character_healed(target: CombatCharacter, amount: float, source: CombatCharacter) -> void:
	if source:
		print("[Combat] %s %s heals %s %s for %d HP" % [_get_team_label(source), source.character_name, _get_team_label(target), target.character_name, int(amount)])
	else:
		print("[Combat] %s %s heals for %d HP" % [_get_team_label(target), target.character_name, int(amount)])


func _on_shield_absorbed(target: CombatCharacter, amount: float, shield_remaining: float) -> void:
	print("[Combat] %s %s SHIELD absorbs %d damage (%d shield remaining)" % [_get_team_label(target), target.character_name, int(amount), int(shield_remaining)])


func _on_character_died(character: CombatCharacter) -> void:
	print("[Combat] %s %s has been defeated!" % [_get_team_label(character), character.character_name])
	_update_slot_hp(_get_pos_key(character), 0, character.max_health, false)


func _on_combat_ended(winner: int, _reason: String) -> void:
	# Restore player health after combat
	for ch in _player_grid.get_all_characters():
		ch.restore_full_health()

	if winner == GameConstants.TEAM_PLAYER:
		print("[Combat] VICTORY!")
		_result_label.text = "VICTORY!"
		_result_label.add_theme_color_override("font_color", GameConstants.COLOR_SUCCESS)
	elif winner == GameConstants.TEAM_OPPONENT:
		print("[Combat] DEFEAT...")
		_result_label.text = "DEFEAT"
		_result_label.add_theme_color_override("font_color", GameConstants.COLOR_DANGER)
	else:
		print("[Combat] DRAW")
		_result_label.text = "DRAW"
		_result_label.add_theme_color_override("font_color", GameConstants.COLOR_WARNING)

	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(func():
		if is_inside_tree():
			_result_overlay.visible = true
	)


func _on_continue_pressed() -> void:
	_continue_button.disabled = true
	var winner = _manager.get_state().winner if _manager.get_state() else GameConstants.TEAM_OPPONENT
	RunFlowController.complete_combat(winner, combat_data)


func _on_combat_completed(_winner: int, run_over: bool) -> void:
	if run_over:
		SceneManager.go_to("run_results")
	else:
		SceneManager.go_to("run_view")
