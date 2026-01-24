extends Node
# RunManager Singleton
# Manages active run state - now delegates to focused managers
# Refactored to follow Single Responsibility Principle

signal run_started
signal round_changed(new_round: int)
signal reputation_changed(new_reputation: int)
signal gold_changed(new_gold: int)
signal phase_changed(new_phase: String)

# Save file path
const SAVE_PATH = "user://active_run.json"

# Phase constants
const PHASE_ENCOUNTER = "encounter"
const PHASE_COMBAT = "combat"

# Run state
var is_run_active: bool = false
var run_id: String = ""

# Focused managers (Single Responsibility Principle)
var _team_manager: TeamManager = TeamManager.new()
var _combat_generator: CombatGenerator = CombatGenerator.new()

# Progression (kept in RunManager as it's core run state)
var current_round: int = 0
var current_phase: String = PHASE_ENCOUNTER
var encounters_this_round: int = 0
var reputation: int = GameConstants.STARTING_REPUTATION
var wins: int = 0
var losses: int = 0
var starting_gold: int = 0
var current_gold: int = 0

# History (for statistics)
var encounter_history: Array = []


func _ready() -> void:
	# Check for existing run on startup
	pass  # Will be called by main scene


func has_active_run() -> bool:
	"""Check if there's a saved run to resume."""
	return JsonPersistence.file_exists(SAVE_PATH)


func start_new_run(drafted_character_ids: Array) -> void:
	"""
	Start a new run with drafted characters.

	Args:
		drafted_character_ids: Array of character IDs from PlayerAccount
	"""
	if drafted_character_ids.size() != GameConstants.TEAM_SIZE:
		push_error("RunManager: Must draft exactly %d characters" % GameConstants.TEAM_SIZE)
		return

	# Generate run ID
	run_id = "run_%d" % Time.get_unix_time_from_system()

	# Initialize team via TeamManager
	_team_manager.clear()
	starting_gold = 0

	for char_id in drafted_character_ids:
		var char_data = PlayerAccount.get_character_data(char_id)
		if char_data.is_empty():
			push_error("RunManager: Character data not found: %s" % char_id)
			continue

		# Create runtime instance
		var char_instance = CharacterInstance.new(char_data)
		_team_manager.add_character(char_instance)

	# Calculate starting gold from team income
	starting_gold = _team_manager.calculate_total_income()

	# Initialize run state
	current_round = 0
	current_phase = PHASE_ENCOUNTER
	encounters_this_round = 0
	reputation = GameConstants.STARTING_REPUTATION
	wins = 0
	losses = 0
	current_gold = starting_gold
	encounter_history.clear()
	is_run_active = true

	# Save initial state
	save_run_state()

	run_started.emit()


func save_run_state() -> void:
	"""Save current run state to file."""
	if not is_run_active:
		return

	var save_data = {
		"run_id": run_id,
		"round": current_round,
		"phase": current_phase,
		"encounters_this_round": encounters_this_round,
		"reputation": reputation,
		"wins": wins,
		"losses": losses,
		"starting_gold": starting_gold,
		"current_gold": current_gold,
		"team": _team_manager.to_array(),
		"encounter_history": encounter_history
	}

	JsonPersistence.save_json(SAVE_PATH, save_data)


func load_run_state() -> bool:
	"""Load run state from file, returns true if successful."""
	var save_data = JsonPersistence.load_json(SAVE_PATH)
	if save_data == null:
		return false

	# Restore run state
	run_id = save_data.get("run_id", "")
	current_round = save_data.get("round", 0)
	current_phase = save_data.get("phase", PHASE_ENCOUNTER)
	encounters_this_round = save_data.get("encounters_this_round", 0)
	reputation = save_data.get("reputation", GameConstants.STARTING_REPUTATION)
	wins = save_data.get("wins", 0)
	losses = save_data.get("losses", 0)
	starting_gold = save_data.get("starting_gold", 0)
	current_gold = save_data.get("current_gold", 0)
	encounter_history = save_data.get("encounter_history", [])

	# Restore team via TeamManager
	_team_manager.load_from_array(save_data.get("team", []))

	is_run_active = true

	return true


func end_run(victory: bool) -> void:
	"""
	End the current run and clear state.
	Note: Rewards should be applied BEFORE calling this (in run_results).

	Args:
		victory: True if player won (10 combats), false if defeated (0 reputation)
	"""
	# Clear run state
	_clear_run_state()


func _clear_run_state() -> void:
	"""Clear all run state and delete save file."""
	is_run_active = false
	run_id = ""
	_team_manager.clear()
	current_round = 0
	current_phase = PHASE_ENCOUNTER
	encounters_this_round = 0
	reputation = GameConstants.STARTING_REPUTATION
	wins = 0
	losses = 0
	starting_gold = 0
	current_gold = 0
	encounter_history.clear()

	# Delete save file
	JsonPersistence.delete_file(SAVE_PATH)


# =============================================================================
# GETTERS - Delegated to TeamManager where appropriate
# =============================================================================

func get_team() -> Array[CharacterInstance]:
	return _team_manager.get_team()


func get_round() -> int:
	return current_round


func get_reputation() -> int:
	return reputation


func get_wins() -> int:
	return wins


func get_losses() -> int:
	return losses


func get_gold() -> int:
	return current_gold


func get_phase() -> String:
	return current_phase


func is_encounter_phase() -> bool:
	return current_phase == PHASE_ENCOUNTER


func is_combat_phase() -> bool:
	return current_phase == PHASE_COMBAT


# =============================================================================
# RUN PROGRESSION
# =============================================================================

func advance_round() -> void:
	"""Move to next round (after encounter + combat)."""
	current_round += 1
	current_phase = PHASE_ENCOUNTER
	encounters_this_round = 0
	round_changed.emit(current_round)
	phase_changed.emit(current_phase)
	save_run_state()


func set_phase(phase: String) -> void:
	"""Set the current phase."""
	if phase != PHASE_ENCOUNTER and phase != PHASE_COMBAT:
		push_error("RunManager: Invalid phase: %s" % phase)
		return
	current_phase = phase
	phase_changed.emit(current_phase)
	save_run_state()


func complete_encounter() -> void:
	"""Complete encounter phase. Switches to combat after ENCOUNTERS_PER_ROUND encounters."""
	encounters_this_round += 1
	if encounters_this_round >= GameConstants.ENCOUNTERS_PER_ROUND:
		current_phase = PHASE_COMBAT
	phase_changed.emit(current_phase)
	save_run_state()


func add_gold(amount: int) -> void:
	"""Add gold (from combat rewards, etc.)."""
	current_gold += amount
	gold_changed.emit(current_gold)
	save_run_state()


func spend_gold(amount: int) -> bool:
	"""Spend gold (returns false if not enough)."""
	if current_gold >= amount:
		current_gold -= amount
		gold_changed.emit(current_gold)
		save_run_state()
		return true
	return false


func add_win() -> void:
	"""Record a combat victory (rewards handled by apply_combat_rewards)."""
	wins += 1
	save_run_state()


func add_loss() -> void:
	"""Record a combat loss."""
	losses += 1
	save_run_state()


func lose_reputation(amount: int) -> void:
	"""Lose reputation (from combat loss)."""
	reputation = max(0, reputation - amount)
	reputation_changed.emit(reputation)
	save_run_state()


func is_run_over() -> bool:
	"""Check if run is over (win or loss condition met)."""
	if wins >= GameConstants.WINS_FOR_VICTORY:
		return true  # Victory
	if reputation <= 0:
		return true  # Defeat
	return false


func did_player_win() -> bool:
	"""Check if player won (only valid if is_run_over() is true)."""
	return wins >= GameConstants.WINS_FOR_VICTORY


# =============================================================================
# UTILITY METHODS - Delegated to TeamManager
# =============================================================================

func get_phase_name() -> String:
	"""Get current phase name for display."""
	return current_phase


func get_team_summary() -> Dictionary:
	"""Get summary stats for the team."""
	return _team_manager.get_summary()


func get_character_by_index(index: int) -> CharacterInstance:
	"""Get a team member by index (0-2)."""
	return _team_manager.get_character_by_index(index)


# =============================================================================
# COMBAT GENERATION - Delegated to CombatGenerator
# =============================================================================

func generate_combat_options(count: int) -> Array:
	"""
	Generate random combat options (AI enemies or Player Ghosts).
	Returns dictionaries for backwards compatibility.

	Args:
		count: Number of options to generate (usually 3)

	Returns:
		Array of combat option dictionaries
	"""
	return _combat_generator.generate_options_as_dicts(count)


func generate_combat_options_typed(count: int) -> Array[CombatOption]:
	"""
	Generate random combat options as typed CombatOption objects.

	Args:
		count: Number of options to generate (usually 3)

	Returns:
		Array of CombatOption objects
	"""
	return _combat_generator.generate_options(count)


# =============================================================================
# REWARDS - Delegated to RewardCalculator
# =============================================================================

func apply_combat_rewards(won: bool, combat_data: Dictionary) -> void:
	"""
	Apply combat rewards or penalties.

	Args:
		won: True if player won, false if lost
		combat_data: The combat option data
	"""
	if won:
		RewardCalculator.apply_combat_victory_rewards(_team_manager, add_gold, combat_data)
	else:
		# Lose reputation equal to round number
		var reputation_loss = RewardCalculator.calculate_reputation_loss(current_round)
		lose_reputation(reputation_loss)


func complete_combat(won: bool, combat_data: Dictionary) -> void:
	"""
	Complete a combat and handle all post-combat logic.
	This is the single entry point any combat scene should call when combat ends.

	Args:
		won: True if player won, false if lost
		combat_data: The combat option dictionary
	"""
	if won:
		apply_combat_rewards(true, combat_data)
		add_win()
	else:
		apply_combat_rewards(false, combat_data)
		add_loss()

	save_run_state()

	if is_run_over():
		SceneManager.go_to("run_results")
	else:
		advance_round()
		SceneManager.go_to("run_view")
