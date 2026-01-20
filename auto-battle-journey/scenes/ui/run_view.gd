extends Control
# RunView - Main UI during an active run
# Uses UIHelpers for common UI operations and GameConstants for magic numbers

@onready var round_label = $TopBar/MarginContainer/VBoxContainer/RoundLabel
@onready var reputation_label = $TopBar/MarginContainer/VBoxContainer/StatsGrid/ReputationLabel
@onready var wins_label = $TopBar/MarginContainer/VBoxContainer/StatsGrid/WinsLabel
@onready var gold_label = $TopBar/MarginContainer/VBoxContainer/StatsGrid/GoldLabel

@onready var team_container = $TeamPanel/MarginContainer/VBoxContainer/TeamContainer
@onready var phase_label = $CenterPanel/MarginContainer/VBoxContainer/PhaseLabel
@onready var phase_description = $CenterPanel/MarginContainer/VBoxContainer/PhaseDescription
@onready var action_button = $CenterPanel/MarginContainer/VBoxContainer/ActionButton
@onready var menu_button = $MenuButton

# Preload scenes
const CharacterCardScene = preload("res://scenes/components/character_card.tscn")

# Phase tracking
enum Phase { ENCOUNTER, COMBAT }
var current_phase: Phase = Phase.ENCOUNTER


func _ready() -> void:
	print("RunView: Scene loaded, initializing...")

	# Connect signals
	RunManager.round_changed.connect(_on_round_changed)
	RunManager.reputation_changed.connect(_on_reputation_changed)
	RunManager.gold_changed.connect(_on_gold_changed)

	action_button.pressed.connect(_on_action_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)

	# Initialize display
	_update_all_displays()
	_setup_phase()

	print("RunView: Initialization complete")


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
	reputation_label.text = "❤️ %d/%d" % [rep, GameConstants.STARTING_REPUTATION]
	wins_label.text = "⭐ %d/%d" % [wins, GameConstants.WINS_FOR_VICTORY]
	gold_label.text = "💰 %d" % gold

	# Color code reputation
	if rep <= 5:
		reputation_label.modulate = Color.RED
	elif rep <= 10:
		reputation_label.modulate = Color.YELLOW
	else:
		reputation_label.modulate = Color.WHITE


func _update_team_display() -> void:
	"""Display all team members."""
	# Clear existing cards using UIHelpers
	UIHelpers.clear_children(team_container)

	# Add card for each team member
	var team = RunManager.get_team()
	for char_instance in team:
		var card = CharacterCardScene.instantiate()
		team_container.add_child(card)

		# Create temporary character data for display
		var display_data = {
			"id": char_instance.base_character_id,
			"rank": 1,  # Not relevant for runtime display
			"experience": char_instance.experience,
			"equipped_items": char_instance.equipped_items
		}

		card.setup(display_data, false)  # Don't calculate with items (already in stats)
		card.set_clickable(false)

		# Manually update stats from instance
		_update_card_with_runtime_stats(card, char_instance)


func _update_card_with_runtime_stats(card: Node, char_instance: CharacterInstance) -> void:
	"""Manually set card stats from CharacterInstance using runtime stats."""
	# Access the stat labels in the card
	var stats_container = card.get_node("MarginContainer/VBoxContainer/StatsContainer")

	# Update health to show current/max
	stats_container.get_node("HealthLabel").text = "HP %d/%d" % [char_instance.current_health, char_instance.max_health]
	stats_container.get_node("AttackLabel").text = UIHelpers.format_stat(GameConstants.STAT_ATTACK, char_instance.stats.get(GameConstants.STAT_ATTACK, 0))
	stats_container.get_node("DefenseLabel").text = UIHelpers.format_stat(GameConstants.STAT_DEFENSE, char_instance.stats.get(GameConstants.STAT_DEFENSE, 0))
	stats_container.get_node("SpeedLabel").text = UIHelpers.format_stat(GameConstants.STAT_SPEED, char_instance.stats.get(GameConstants.STAT_SPEED, 0))
	stats_container.get_node("IncomeLabel").text = UIHelpers.format_stat(GameConstants.STAT_INCOME, char_instance.stats.get(GameConstants.STAT_INCOME, 0))

	# Show level in name
	var name_label = card.get_node("MarginContainer/VBoxContainer/NameLabel")
	name_label.text = "%s (Lv.%d)" % [char_instance.get_character_name(), char_instance.level]


func _setup_phase() -> void:
	"""Setup UI for current phase."""
	match current_phase:
		Phase.ENCOUNTER:
			phase_label.text = "ENCOUNTER PHASE"
			phase_description.text = "Select an encounter to improve your team."
			action_button.text = "CHOOSE ENCOUNTER"
		Phase.COMBAT:
			phase_label.text = "COMBAT PHASE"
			phase_description.text = "Select a battle to fight."
			action_button.text = "CHOOSE COMBAT"


func _on_action_button_pressed() -> void:
	"""Handle phase action button."""
	match current_phase:
		Phase.ENCOUNTER:
			_start_encounter_phase()
		Phase.COMBAT:
			_start_combat_phase()


func _start_encounter_phase() -> void:
	"""Navigate to encounter selection."""
	print("RunView: Starting encounter phase...")
	# TODO: Navigate to encounter_select scene (Phase 5)
	print("RunView: Would navigate to encounter_select here")

	# For now, simulate completing encounter
	_simulate_encounter_completion()


func _start_combat_phase() -> void:
	"""Navigate to combat selection."""
	print("RunView: Starting combat phase...")
	# TODO: Navigate to combat_select scene (Phase 6)
	print("RunView: Would navigate to combat_select here")

	# For now, simulate completing combat
	_simulate_combat_completion()


func _simulate_encounter_completion() -> void:
	"""Temporary: Simulate completing an encounter."""
	print("RunView: Simulating encounter completion...")

	# Award some XP and gold
	var team = RunManager.get_team()
	if team.size() > 0:
		team[0].add_experience(30)
	RunManager.add_gold(10)

	# Save state
	RunManager.save_run_state()

	# Move to combat phase
	current_phase = Phase.COMBAT
	_setup_phase()
	_update_all_displays()


func _simulate_combat_completion() -> void:
	"""Temporary: Simulate completing combat."""
	print("RunView: Simulating combat completion...")

	# For now, always win
	RunManager.add_win()

	# Save state
	RunManager.save_run_state()

	# Advance round
	RunManager.advance_round()

	# Check if run is over
	if RunManager.is_run_over():
		_end_run()
		return

	# Move to next encounter phase
	current_phase = Phase.ENCOUNTER
	_setup_phase()
	_update_all_displays()


func _end_run() -> void:
	"""Run is over, show results."""
	print("RunView: Run is over!")

	var victory = RunManager.did_player_win()

	# TODO: Navigate to run_results scene (Phase 7)
	print("RunView: Would navigate to run_results here (Victory: %s)" % victory)

	# For now, end run and return to main menu
	RunManager.end_run(victory)
	SceneManager.go_to_main_menu()


func _on_menu_button_pressed() -> void:
	"""Open pause menu."""
	# TODO: Create pause menu with forfeit option
	print("RunView: Menu button pressed (pause menu not implemented)")


func _on_round_changed(_new_round: int) -> void:
	"""Handle round change signal."""
	_update_top_bar()


func _on_reputation_changed(_new_reputation: int) -> void:
	"""Handle reputation change signal."""
	_update_top_bar()


func _on_gold_changed(_new_gold: int) -> void:
	"""Handle gold change signal."""
	_update_top_bar()


# =============================================================================
# DEBUG CONTROLS
# =============================================================================
# Debug Keys:
# - E: Complete encounter phase
# - C: Complete combat phase
# - G: Add 50 gold
# - X: Add 50 XP to first character
# - L: Lose 5 reputation

func _input(event: InputEvent) -> void:
	"""Debug controls for testing."""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_E:  # Complete encounter phase
				if current_phase == Phase.ENCOUNTER:
					print("RunView: [DEBUG] Completing encounter phase")
					_simulate_encounter_completion()
			KEY_C:  # Complete combat phase
				if current_phase == Phase.COMBAT:
					print("RunView: [DEBUG] Completing combat phase")
					_simulate_combat_completion()
			KEY_G:  # Add gold
				print("RunView: [DEBUG] Adding 50 gold")
				RunManager.add_gold(50)
			KEY_X:  # Add XP to first character
				var team = RunManager.get_team()
				if team.size() > 0:
					print("RunView: [DEBUG] Adding 50 XP to first character")
					team[0].add_experience(50)
					_update_team_display()
			KEY_L:  # Lose reputation
				print("RunView: [DEBUG] Losing 5 reputation")
				RunManager.lose_reputation(5)
