extends Control
# RunView - Main UI during an active run
# Header bar and concede are handled by the persistent RunHUD

@onready var background = $Background
@onready var team_display = $TeamDisplay
@onready var options_panel = $OptionsPanel


func _ready() -> void:
	print("RunView: Scene loaded, initializing...")

	background.color = GameConstants.COLOR_BG_DARK

	RunManager.phase_changed.connect(_on_phase_changed)

	_update_team_display()
	_setup_phase()
	_play_entrance_animations()

	print("RunView: Initialization complete")


func _play_entrance_animations() -> void:
	AnimationManager.fade_in(team_display, GameConstants.ANIM_DURATION_NORMAL, 0.0)
	AnimationManager.fade_in(options_panel, GameConstants.ANIM_DURATION_NORMAL, 0.1)


func _exit_tree() -> void:
	if RunManager.phase_changed.is_connected(_on_phase_changed):
		RunManager.phase_changed.disconnect(_on_phase_changed)


func _update_team_display() -> void:
	var team = RunManager.get_team()
	team_display.setup(team, "YOUR TEAM")


func _setup_phase() -> void:
	var options_container = options_panel.get_options_container()
	UIHelpers.clear_children(options_container)

	if RunManager.is_encounter_phase():
		_generate_encounter_options()
	else:
		_generate_combat_options()


func _generate_encounter_options() -> void:
	var options_container = options_panel.get_options_container()
	UIHelpers.clear_children(options_container)

	var encounter_options = EncounterFactory.generate_encounter_options(3)

	for encounter_data in encounter_options:
		var panel = UIHelpers.create_encounter_option_panel(encounter_data, _on_encounter_selected)
		options_container.add_child(panel)


func _on_encounter_selected(encounter_data: Dictionary) -> void:
	print("RunView: Selected encounter %s" % encounter_data["name"])
	SceneManager.set_scene_data("selected_encounter", encounter_data)
	SceneManager.go_to("encounter_execute")


func _generate_combat_options() -> void:
	var options_container = options_panel.get_options_container()
	UIHelpers.clear_children(options_container)

	var combat_options = RunManager.generate_combat_options(3)

	for combat_data in combat_options:
		var panel = UIHelpers.create_combat_option_panel(combat_data, _on_combat_selected)
		options_container.add_child(panel)


func _on_combat_selected(combat_data: Dictionary) -> void:
	print("RunView: Selected combat %s" % combat_data["name"])
	SceneManager.set_scene_data("selected_combat", combat_data)
	SceneManager.go_to("combat_stub")


func _on_phase_changed(_new_phase: String) -> void:
	_setup_phase()
