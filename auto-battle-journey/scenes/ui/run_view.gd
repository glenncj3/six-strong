extends Control
# RunView - Main UI during an active run
# Uses UIHelpers for common UI operations and GameConstants for magic numbers
# Updated with fantasy aesthetic styling

@onready var background = $Background
@onready var top_bar = $TopBar
@onready var round_label = $TopBar/MarginContainer/HBoxContainer/LeftSection/RoundLabel
@onready var reputation_label = $TopBar/MarginContainer/HBoxContainer/StatsContainer/ReputationLabel
@onready var wins_label = $TopBar/MarginContainer/HBoxContainer/StatsContainer/WinsLabel
@onready var gold_label = $TopBar/MarginContainer/HBoxContainer/StatsContainer/GoldLabel

@onready var team_display = $TeamDisplay
@onready var options_panel = $OptionsPanel
@onready var concede_button = $TopBar/MarginContainer/HBoxContainer/RightSection/ConcedeButton
@onready var concede_confirm_dialog = $ConcedeConfirmDialog

var _concede_dialog_open: bool = false



func _ready() -> void:
	print("RunView: Scene loaded, initializing...")

	# Apply visual styling
	_apply_visual_styling()

	# Connect signals
	RunManager.round_changed.connect(_on_round_changed)
	RunManager.reputation_changed.connect(_on_reputation_changed)
	RunManager.gold_changed.connect(_on_gold_changed)
	RunManager.phase_changed.connect(_on_phase_changed)

	concede_button.pressed.connect(_on_concede_button_pressed)
	concede_confirm_dialog.confirmed.connect(_on_concede_confirmed)
	concede_confirm_dialog.canceled.connect(_on_concede_dialog_closed)
	concede_confirm_dialog.close_requested.connect(_on_concede_dialog_closed)

	# Initialize display
	_update_all_displays()
	_setup_phase()
	_play_entrance_animations()

	print("RunView: Initialization complete")


func _play_entrance_animations() -> void:
	"""Play entrance animations."""
	AnimationManager.fade_in(top_bar, GameConstants.ANIM_DURATION_NORMAL, 0.0)
	AnimationManager.fade_in(team_display, GameConstants.ANIM_DURATION_NORMAL, 0.1)
	AnimationManager.fade_in(options_panel, GameConstants.ANIM_DURATION_NORMAL, 0.15)


func _apply_visual_styling() -> void:
	"""Apply fantasy aesthetic styling."""
	# Background
	background.color = GameConstants.COLOR_BG_DARK

	# Top bar panel styling (Panel uses "panel" stylebox)
	top_bar.add_theme_stylebox_override("panel", UIStyles.create_warm_panel())

	# Round label - gold, left-aligned
	round_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)

	# Stat labels - light parchment
	reputation_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	wins_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	gold_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)

	# Concede button - small red square with white X
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


func _exit_tree() -> void:
	"""Clean up signal connections when scene is freed (Issue 3 fallback)."""
	# Disconnect from RunManager signals to prevent callbacks to freed nodes
	if RunManager.round_changed.is_connected(_on_round_changed):
		RunManager.round_changed.disconnect(_on_round_changed)
	if RunManager.reputation_changed.is_connected(_on_reputation_changed):
		RunManager.reputation_changed.disconnect(_on_reputation_changed)
	if RunManager.gold_changed.is_connected(_on_gold_changed):
		RunManager.gold_changed.disconnect(_on_gold_changed)
	if RunManager.phase_changed.is_connected(_on_phase_changed):
		RunManager.phase_changed.disconnect(_on_phase_changed)


func _update_all_displays() -> void:
	"""Update all UI elements with current run state."""
	_update_top_bar()
	_update_team_display()


func _update_top_bar() -> void:
	"""Update round, reputation, wins, gold display (compact mobile format)."""
	var round_num = RunManager.get_round()
	var rep = RunManager.get_reputation()
	var wins = RunManager.get_wins()
	var gold = RunManager.get_gold()

	round_label.text = "ROUND %d" % (round_num + 1)  # Display as 1-indexed
	reputation_label.text = "%s %d" % [GameConstants.EMOJI_HEART, rep]
	wins_label.text = "%s %d/%d" % [GameConstants.EMOJI_STAR, wins, GameConstants.WINS_FOR_VICTORY]
	gold_label.text = "%s %d" % [GameConstants.EMOJI_GOLD, gold]

	# Color code reputation
	if rep <= GameConstants.REPUTATION_CRITICAL_THRESHOLD:
		reputation_label.modulate = Color.RED
	elif rep <= GameConstants.REPUTATION_WARNING_THRESHOLD:
		reputation_label.modulate = Color.YELLOW
	else:
		reputation_label.modulate = Color.WHITE


func _update_team_display() -> void:
	"""Setup the team display component with current team."""
	var team = RunManager.get_team()
	team_display.setup(team, "YOUR TEAM")


func _setup_phase() -> void:
	"""Setup UI for current phase."""
	var options_container = options_panel.get_options_container()
	UIHelpers.clear_children(options_container)

	if RunManager.is_encounter_phase():
		_generate_encounter_options()
	else:
		_generate_combat_options()


func _generate_encounter_options() -> void:
	"""Generate and display 3 encounter options directly in run_view."""
	var options_container = options_panel.get_options_container()
	UIHelpers.clear_children(options_container)

	var encounter_options = EncounterFactory.generate_encounter_options(3)

	for encounter_data in encounter_options:
		var panel = UIHelpers.create_encounter_option_panel(encounter_data, _on_encounter_selected)
		options_container.add_child(panel)


func _on_encounter_selected(encounter_data: Dictionary) -> void:
	"""Handle encounter selection - go directly to encounter execution."""
	print("RunView: Selected encounter %s" % encounter_data["name"])

	# Store selected encounter data for next scene
	SceneManager.set_scene_data("selected_encounter", encounter_data)

	# Navigate directly to encounter execution
	SceneManager.go_to("encounter_execute")


func _generate_combat_options() -> void:
	"""Generate and display 3 combat options directly in run_view."""
	var options_container = options_panel.get_options_container()
	UIHelpers.clear_children(options_container)

	var combat_options = RunManager.generate_combat_options(3)

	for combat_data in combat_options:
		var panel = UIHelpers.create_combat_option_panel(combat_data, _on_combat_selected)
		options_container.add_child(panel)


func _on_combat_selected(combat_data: Dictionary) -> void:
	"""Handle combat selection - go directly to combat."""
	print("RunView: Selected combat %s" % combat_data["name"])

	# Store selected combat data for next scene
	SceneManager.set_scene_data("selected_combat", combat_data)

	# Navigate directly to combat
	SceneManager.go_to("combat_stub")


func _on_concede_button_pressed() -> void:
	"""Show concede confirmation dialog."""
	_concede_dialog_open = true
	concede_confirm_dialog.popup_centered()


func _on_concede_confirmed() -> void:
	"""Handle confirmed concede - treat as defeat."""
	# Safety check - only proceed if we intentionally opened the dialog
	if not _concede_dialog_open:
		return

	_concede_dialog_open = false

	# Store run data for results screen (same as defeat)
	SceneManager.set_scene_data("run_results", {
		"round": RunManager.get_round(),
		"wins": RunManager.get_wins(),
		"losses": RunManager.get_losses(),
		"gold": RunManager.get_gold(),
		"reputation": RunManager.get_reputation(),
		"starting_gold": RunManager.starting_gold,
		"victory": false,  # Concede is treated as defeat
		"team": _capture_team_data()
	})

	# Navigate to results screen
	SceneManager.go_to("run_results")


func _on_concede_dialog_closed() -> void:
	"""Handle dialog closed without confirmation (canceled or X button)."""
	_concede_dialog_open = false


func _capture_team_data() -> Array:
	"""Capture team data for results screen."""
	var team_data = []
	for char_instance in RunManager.get_team():
		team_data.append({
			"id": char_instance.base_character_id,
			"name": char_instance.get_character_name(),
			"level": char_instance.level
		})
	return team_data


func _on_round_changed(_new_round: int) -> void:
	"""Handle round change signal."""
	_update_top_bar()


func _on_reputation_changed(_new_reputation: int) -> void:
	"""Handle reputation change signal."""
	_update_top_bar()


func _on_gold_changed(new_gold: int) -> void:
	"""Handle gold change signal with visual feedback."""
	var old_text = gold_label.text
	_update_top_bar()

	# Spawn gold particle burst at gold label position
	if gold_label.is_inside_tree():
		var burst = ParticlePresets.create_gold_burst(6)
		burst.position = gold_label.global_position + gold_label.size / 2
		get_tree().root.add_child(burst)
		burst.emitting = true


func _on_phase_changed(_new_phase: String) -> void:
	"""Handle phase change signal."""
	_setup_phase()
