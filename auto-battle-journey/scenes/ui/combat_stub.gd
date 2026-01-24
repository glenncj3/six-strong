extends Control
# CombatStub - Temporary combat scene for testing
# TODO: Replace with actual combat implementation

@onready var background = $Background
@onready var title_label = $MainContainer/Title
@onready var opponent_label = $MainContainer/OpponentLabel
@onready var stub_notice = $MainContainer/StubNotice
@onready var instruction_label = $MainContainer/InstructionLabel
@onready var win_button = $MainContainer/ButtonContainer/WinButton
@onready var lose_button = $MainContainer/ButtonContainer/LoseButton
@onready var result_label = $MainContainer/ResultLabel

var combat_data: Dictionary = {}


func _ready() -> void:
	_apply_visual_styling()

	win_button.pressed.connect(_on_win_pressed)
	lose_button.pressed.connect(_on_lose_pressed)

	result_label.text = ""

	# Get selected combat data from SceneManager
	combat_data = SceneManager.get_scene_data("selected_combat", {})
	if not combat_data.is_empty():
		_setup_display()
		_play_entrance_animations()
	else:
		push_error("CombatStub: No combat data found!")


func _apply_visual_styling() -> void:
	"""Apply consistent visual styling."""
	title_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_HEADING)
	title_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)

	opponent_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BODY)
	opponent_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)

	stub_notice.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)
	stub_notice.add_theme_color_override("font_color", GameConstants.COLOR_WARNING)

	instruction_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BODY)
	instruction_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_MUTED)

	result_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BUTTON_LARGE)
	result_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)

	UIStyles.setup_success_button(win_button)
	ButtonEffects.apply_effects(win_button)
	UIStyles.setup_danger_button(lose_button)
	ButtonEffects.apply_effects(lose_button)


func _play_entrance_animations() -> void:
	"""Play entrance animations."""
	AnimationManager.fade_in(title_label, GameConstants.ANIM_DURATION_NORMAL, 0.0)
	AnimationManager.fade_in(opponent_label, GameConstants.ANIM_DURATION_NORMAL, 0.1)
	AnimationManager.fade_in(win_button.get_parent(), GameConstants.ANIM_DURATION_NORMAL, 0.2)


func _setup_display() -> void:
	"""Setup the display with combat data."""
	opponent_label.text = "Opponent: %s" % combat_data["name"]


func _on_win_pressed() -> void:
	"""Handle victory."""
	win_button.disabled = true
	lose_button.disabled = true
	result_label.text = "VICTORY!"
	result_label.modulate = GameConstants.COLOR_SUCCESS
	await get_tree().create_timer(1.5).timeout
	RunManager.complete_combat(true, combat_data)


func _on_lose_pressed() -> void:
	"""Handle defeat."""
	win_button.disabled = true
	lose_button.disabled = true
	result_label.text = "DEFEAT..."
	result_label.modulate = GameConstants.COLOR_DANGER
	await get_tree().create_timer(1.5).timeout
	RunManager.complete_combat(false, combat_data)
