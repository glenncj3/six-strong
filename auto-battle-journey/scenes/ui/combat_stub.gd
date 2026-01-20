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
	else:
		push_error("CombatStub: No combat data found!")


func _setup_display() -> void:
	"""Setup the display with combat data."""
	opponent_label.text = "Opponent: %s" % combat_data["name"]


func _on_win_pressed() -> void:
	"""Handle victory."""
	print("CombatStub: Player chose VICTORY")

	# Disable buttons
	win_button.disabled = true
	lose_button.disabled = true

	# Show result
	result_label.text = "VICTORY!"
	result_label.modulate = Color.GREEN

	# Apply rewards
	RunManager.apply_combat_rewards(true, combat_data)
	RunManager.add_win()

	# Save state
	RunManager.save_run_state()

	# Wait a moment then proceed
	await get_tree().create_timer(1.5).timeout
	_complete_combat()


func _on_lose_pressed() -> void:
	"""Handle defeat."""
	print("CombatStub: Player chose DEFEAT")

	# Disable buttons
	win_button.disabled = true
	lose_button.disabled = true

	# Show result
	result_label.text = "DEFEAT..."
	result_label.modulate = Color.RED

	# Apply penalties
	RunManager.apply_combat_rewards(false, combat_data)
	RunManager.add_loss()

	# Save state
	RunManager.save_run_state()

	# Wait a moment then proceed
	await get_tree().create_timer(1.5).timeout
	_complete_combat()


func _complete_combat() -> void:
	"""Complete combat and check if run is over."""
	# Check if run is over
	if RunManager.is_run_over():
		_end_run()
	else:
		# Advance to next round
		RunManager.advance_round()

		# Return to run view (next round, encounter phase)
		SceneManager.go_to("run_view")


func _end_run() -> void:
	"""Run is over, navigate to results."""
	var victory = RunManager.did_player_win()

	print("CombatStub: Run is over! Victory: %s" % victory)

	# TODO: Navigate to run_results scene (Phase 7)
	print("CombatStub: Would navigate to run_results here")

	# For now, end run and return to main menu
	RunManager.end_run(victory)
	SceneManager.go_to_main_menu()
