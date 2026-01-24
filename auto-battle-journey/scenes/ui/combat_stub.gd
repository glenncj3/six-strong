extends Control
# CombatStub - Temporary combat scene for testing
# TODO: Replace with actual combat implementation

@onready var title_label = $MainContainer/Title
@onready var opponent_label = $MainContainer/OpponentLabel
@onready var win_button = $MainContainer/ButtonContainer/WinButton
@onready var lose_button = $MainContainer/ButtonContainer/LoseButton
@onready var result_label = $MainContainer/ResultLabel

var combat_data: Dictionary = {}


func _ready() -> void:
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
	result_label.modulate = Color.GREEN
	await get_tree().create_timer(1.5).timeout
	RunManager.complete_combat(true, combat_data)


func _on_lose_pressed() -> void:
	"""Handle defeat."""
	win_button.disabled = true
	lose_button.disabled = true
	result_label.text = "DEFEAT..."
	result_label.modulate = Color.RED
	await get_tree().create_timer(1.5).timeout
	RunManager.complete_combat(false, combat_data)
