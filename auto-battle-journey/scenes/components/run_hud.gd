extends Control
# RunHUD - Persistent header bar that stays visible during active runs
# Lives on a CanvasLayer below the transition layer so it fades naturally with scenes

@onready var header_bar = $HeaderBar
@onready var round_label = $HeaderBar/MarginContainer/HBoxContainer/LeftSection/RoundLabel
@onready var wins_label = $HeaderBar/MarginContainer/HBoxContainer/CenterSection/WinsLabel
@onready var reputation_label = $HeaderBar/MarginContainer/HBoxContainer/CenterSection/ReputationLabel
@onready var gold_label = $HeaderBar/MarginContainer/HBoxContainer/CenterSection/GoldLabel
@onready var concede_button = $HeaderBar/MarginContainer/HBoxContainer/RightSection/ConcedeButton
@onready var concede_confirm_dialog = $ConcedeConfirmDialog

const RUN_SCENES: Array[String] = [
	"res://scenes/ui/run_view.tscn",
	"res://scenes/ui/encounter_execute.tscn",
	"res://scenes/ui/combat_stub.tscn",
]

var _concede_dialog_open: bool = false


func _ready() -> void:
	visible = false

	_apply_visual_styling()

	concede_button.pressed.connect(_on_concede_button_pressed)
	concede_confirm_dialog.confirmed.connect(_on_concede_confirmed)
	concede_confirm_dialog.canceled.connect(_on_concede_dialog_closed)
	concede_confirm_dialog.close_requested.connect(_on_concede_dialog_closed)

	RunManager.round_changed.connect(_on_stats_changed)
	RunManager.reputation_changed.connect(_on_stats_changed)
	RunManager.gold_changed.connect(_on_stats_changed)
	SceneManager.scene_loaded.connect(_on_scene_loaded)


func _apply_visual_styling() -> void:
	round_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)
	wins_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	reputation_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	gold_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	_style_concede_button()


func _style_concede_button() -> void:
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


func _update_stats() -> void:
	var round_num = RunManager.get_round()
	var rep = RunManager.get_reputation()
	var wins = RunManager.get_wins()
	var gold = RunManager.get_gold()

	round_label.text = "ROUND %d" % (round_num + 1)
	reputation_label.text = "%s %d" % [GameConstants.EMOJI_HEART, rep]
	wins_label.text = "%s %d/%d" % [GameConstants.EMOJI_STAR, wins, GameConstants.WINS_FOR_VICTORY]
	gold_label.text = "%s %d" % [GameConstants.EMOJI_GOLD, gold]

	if rep <= GameConstants.REPUTATION_CRITICAL_THRESHOLD:
		reputation_label.modulate = Color.RED
	elif rep <= GameConstants.REPUTATION_WARNING_THRESHOLD:
		reputation_label.modulate = Color.YELLOW
	else:
		reputation_label.modulate = Color.WHITE


func _on_stats_changed(_value = null) -> void:
	if visible:
		_update_stats()


func _on_scene_loaded(scene_path: String) -> void:
	# Fires while screen is still black (between fade-out and fade-in)
	if scene_path in RUN_SCENES and RunManager.is_run_active:
		_update_stats()
		visible = true
	else:
		visible = false


func _on_concede_button_pressed() -> void:
	_concede_dialog_open = true
	concede_confirm_dialog.popup_centered()


func _on_concede_confirmed() -> void:
	if not _concede_dialog_open:
		return
	_concede_dialog_open = false

	SceneManager.set_scene_data("run_results", {
		"round": RunManager.get_round(),
		"wins": RunManager.get_wins(),
		"losses": RunManager.get_losses(),
		"gold": RunManager.get_gold(),
		"reputation": RunManager.get_reputation(),
		"starting_gold": RunManager.starting_gold,
		"victory": false,
		"team": _capture_team_data()
	})
	SceneManager.go_to("run_results")


func _on_concede_dialog_closed() -> void:
	_concede_dialog_open = false


func _capture_team_data() -> Array:
	var team_data = []
	for char_instance in RunManager.get_team():
		team_data.append({
			"id": char_instance.base_character_id,
			"name": char_instance.get_character_name(),
			"level": char_instance.level
		})
	return team_data
