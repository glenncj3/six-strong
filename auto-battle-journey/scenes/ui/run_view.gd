extends Control
# RunView - Main UI during an active run
# Header bar and concede are handled by the persistent RunHUD

const CharacterTileScene = preload("res://scenes/components/character_tile.tscn")
const CharacterInfoPanelScene = preload("res://scenes/components/character_info_panel.tscn")

@onready var background = $Background
@onready var team_container = $TeamContainer
@onready var title_label = $TeamContainer/VBoxContainer/TitleLabel
@onready var tiles_container = $TeamContainer/VBoxContainer/TilesContainer
@onready var info_panel_clip = $TeamContainer/VBoxContainer/InfoPanelClip
@onready var options_panel = $OptionsPanel

var info_panel: Node = null


func _ready() -> void:
	print("RunView: Scene loaded, initializing...")

	background.color = GameConstants.COLOR_BG_DARK
	title_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)

	_setup_info_panel()

	RunManager.phase_changed.connect(_on_phase_changed)

	_update_team_display()
	_setup_phase()
	_play_entrance_animations()

	print("RunView: Initialization complete")


func _setup_info_panel() -> void:
	info_panel = CharacterInfoPanelScene.instantiate()
	info_panel_clip.add_child(info_panel)
	info_panel.set_anchors_preset(Control.PRESET_FULL_RECT)


func _play_entrance_animations() -> void:
	AnimationManager.fade_in(team_container, GameConstants.ANIM_DURATION_NORMAL, 0.0)
	AnimationManager.fade_in(options_panel, GameConstants.ANIM_DURATION_NORMAL, 0.1)


func _exit_tree() -> void:
	if RunManager.phase_changed.is_connected(_on_phase_changed):
		RunManager.phase_changed.disconnect(_on_phase_changed)


func _update_team_display() -> void:
	var team = RunManager.get_team()
	UIHelpers.clear_children(tiles_container)

	var available_width = max(team_container.size.x, 688) - 24
	var tile_size = floor((available_width - 16) / 3.0)
	tile_size = max(tile_size, 180)

	for char_instance in team:
		var tile = CharacterTileScene.instantiate()
		tiles_container.add_child(tile)
		tile.setup(char_instance, tile_size)
		tile.tile_clicked.connect(_on_tile_clicked)


func _on_tile_clicked(char_instance: CharacterInstance) -> void:
	if info_panel.is_showing() and info_panel.current_char_instance == char_instance:
		info_panel.hide_panel()
	else:
		info_panel.show_character(char_instance)


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
