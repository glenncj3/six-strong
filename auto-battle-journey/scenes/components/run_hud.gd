extends Control
# RunHUD - Persistent header bar that stays visible during gameplay
# Lives on a CanvasLayer above the transition layer so it persists through scene changes

@onready var header_bar = $HeaderBar
@onready var content_container = $HeaderBar/MarginContainer
@onready var round_label = $HeaderBar/MarginContainer/HBoxContainer/LeftSection/RoundLabel
@onready var wins_label = $HeaderBar/MarginContainer/HBoxContainer/CenterSection/WinsLabel
@onready var reputation_label = $HeaderBar/MarginContainer/HBoxContainer/CenterSection/ReputationLabel
@onready var gold_label = $HeaderBar/MarginContainer/HBoxContainer/CenterSection/GoldLabel
@onready var gems_label = $HeaderBar/MarginContainer/HBoxContainer/CenterSection/GemsLabel
@onready var concede_button = $HeaderBar/MarginContainer/HBoxContainer/RightSection/ConcedeButton
@onready var concede_confirm_dialog = $ConcedeConfirmDialog
@onready var dialog_panel = $ConcedeConfirmDialog/DialogPanel
@onready var dialog_title = $ConcedeConfirmDialog/DialogPanel/DialogContent/DialogTitle
@onready var dialog_cancel_button = $ConcedeConfirmDialog/DialogPanel/DialogContent/ButtonContainer/CancelButton
@onready var dialog_confirm_button = $ConcedeConfirmDialog/DialogPanel/DialogContent/ButtonContainer/ConfirmButton
@onready var dialog_overlay = $ConcedeConfirmDialog/Overlay

const GAMEPLAY_SCENES: Array[String] = [
	"res://scenes/ui/draft.tscn",
	"res://scenes/ui/run_view.tscn",
	"res://scenes/ui/encounter_execute.tscn",
	"res://scenes/ui/combat_stub.tscn",
]

const FADE_DURATION := 0.3
const CROSSFADE_DURATION := 0.15

var _concede_dialog_open: bool = false
var _is_draft_mode: bool = false
var _header_tween: Tween = null


func _ready() -> void:
	visible = false

	_apply_visual_styling()

	concede_button.pressed.connect(_on_concede_button_pressed)
	dialog_confirm_button.pressed.connect(_on_concede_confirmed)
	dialog_cancel_button.pressed.connect(_on_concede_dialog_closed)
	dialog_overlay.gui_input.connect(_on_overlay_input)

	RunManager.round_changed.connect(_on_stats_changed)
	RunManager.reputation_changed.connect(_on_stats_changed)
	RunManager.gold_changed.connect(_on_stats_changed)
	PlayerAccount.gems_changed.connect(_on_gems_changed)
	SceneManager.scene_loaded.connect(_on_scene_loaded)


func _apply_visual_styling() -> void:
	round_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)
	wins_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	reputation_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	gold_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	gems_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	_style_concede_button()
	_style_concede_dialog()


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


func _style_concede_dialog() -> void:
	UIStyles.apply_panel_style(dialog_panel, UIStyles.create_dark_panel())

	dialog_title.add_theme_font_size_override("font_size", 32)
	dialog_title.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)

	UIStyles.setup_button(dialog_cancel_button)
	ButtonEffects.apply_effects(dialog_cancel_button)
	UIStyles.setup_danger_button(dialog_confirm_button)
	ButtonEffects.apply_effects(dialog_confirm_button)


# =============================================================================
# TRANSITION ANIMATIONS
# =============================================================================

func _kill_tween() -> void:
	if _header_tween and _header_tween.is_valid():
		_header_tween.kill()
	_header_tween = null


func _fade_in_header() -> void:
	_kill_tween()
	header_bar.modulate.a = 0.0
	visible = true
	_header_tween = create_tween()
	_header_tween.set_ease(Tween.EASE_OUT)
	_header_tween.set_trans(Tween.TRANS_CUBIC)
	_header_tween.tween_property(header_bar, "modulate:a", 1.0, FADE_DURATION)


func _fade_out_header() -> void:
	_kill_tween()
	_header_tween = create_tween()
	_header_tween.set_ease(Tween.EASE_IN)
	_header_tween.set_trans(Tween.TRANS_CUBIC)
	_header_tween.tween_property(header_bar, "modulate:a", 0.0, FADE_DURATION)
	_header_tween.tween_callback(func(): visible = false)


func _crossfade_to_run_mode() -> void:
	_kill_tween()
	_header_tween = create_tween()
	_header_tween.set_ease(Tween.EASE_IN_OUT)
	_header_tween.set_trans(Tween.TRANS_CUBIC)

	# Fade out content (bar panel stays)
	_header_tween.tween_property(content_container, "modulate:a", 0.0, CROSSFADE_DURATION)

	# Update content at midpoint
	_header_tween.tween_callback(func():
		_is_draft_mode = false
		gems_label.visible = false
		_update_stats()
	)

	# Fade in new content
	_header_tween.tween_property(content_container, "modulate:a", 1.0, CROSSFADE_DURATION)


# =============================================================================
# MODE MANAGEMENT
# =============================================================================

func _enter_draft_mode() -> void:
	_is_draft_mode = true
	content_container.modulate.a = 1.0
	round_label.text = "RECRUIT!"
	wins_label.text = "%s 0/%d" % [GameConstants.EMOJI_STAR, GameConstants.WINS_FOR_VICTORY]
	reputation_label.text = "%s %d" % [GameConstants.EMOJI_HEART, GameConstants.STARTING_REPUTATION]
	reputation_label.modulate = Color.WHITE
	gold_label.text = "%s 0" % GameConstants.EMOJI_GOLD
	gems_label.text = "%s %d" % [GameConstants.EMOJI_GEM, PlayerAccount.get_gems()]
	gems_label.visible = true


func _enter_run_mode() -> void:
	_is_draft_mode = false
	content_container.modulate.a = 1.0
	gems_label.visible = false
	_update_stats()


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


## Update gold display during draft (called by draft scene as characters are selected)
func update_draft_gold(amount: int) -> void:
	if _is_draft_mode:
		gold_label.text = "%s %d" % [GameConstants.EMOJI_GOLD, amount]


func _on_stats_changed(_value = null) -> void:
	if visible and not _is_draft_mode:
		_update_stats()


func _on_gems_changed(new_amount: int) -> void:
	if visible and _is_draft_mode:
		gems_label.text = "%s %d" % [GameConstants.EMOJI_GEM, new_amount]


# =============================================================================
# SCENE TRANSITIONS
# =============================================================================

func _on_scene_loaded(scene_path: String) -> void:
	if scene_path not in GAMEPLAY_SCENES:
		if visible:
			_fade_out_header()
		return

	if scene_path == "res://scenes/ui/draft.tscn":
		_enter_draft_mode()
		if not visible:
			_fade_in_header()
		else:
			visible = true
	elif RunManager.is_run_active:
		if visible and _is_draft_mode:
			_crossfade_to_run_mode()
		else:
			_enter_run_mode()
			if not visible:
				_fade_in_header()
			else:
				visible = true
	else:
		visible = false


# =============================================================================
# CONCEDE HANDLING
# =============================================================================

func _on_concede_button_pressed() -> void:
	_concede_dialog_open = true
	concede_confirm_dialog.visible = true


func _on_concede_confirmed() -> void:
	if not _concede_dialog_open:
		return
	_concede_dialog_open = false
	concede_confirm_dialog.visible = false

	if _is_draft_mode:
		SceneManager.go_to_main_menu()
	else:
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


func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_concede_dialog_closed()


func _on_concede_dialog_closed() -> void:
	_concede_dialog_open = false
	concede_confirm_dialog.visible = false


func _capture_team_data() -> Array:
	var team_data = []
	for char_instance in RunManager.get_team():
		team_data.append({
			"id": char_instance.base_character_id,
			"name": char_instance.get_character_name(),
			"level": char_instance.level
		})
	return team_data
