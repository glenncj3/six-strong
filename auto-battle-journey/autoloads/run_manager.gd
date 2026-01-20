extends Node
# RunManager Singleton
# Manages active run state, team, progression, and save/load
# Refactored to use JsonPersistence and GameConstants

signal run_started
signal round_changed(new_round: int)
signal reputation_changed(new_reputation: int)
signal gold_changed(new_gold: int)

# Save file path
const SAVE_PATH = "user://active_run.json"

# Run state
var is_run_active: bool = false
var run_id: String = ""

# Team
var team: Array[CharacterInstance] = []

# Progression
var current_round: int = 0
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

	print("RunManager: Starting new run with characters: %s" % str(drafted_character_ids))

	# Generate run ID
	run_id = "run_%d" % Time.get_unix_time_from_system()

	# Initialize team
	team.clear()
	starting_gold = 0

	for char_id in drafted_character_ids:
		var char_data = PlayerAccount.get_character_data(char_id)
		if char_data.is_empty():
			push_error("RunManager: Character data not found: %s" % char_id)
			continue

		# Create runtime instance
		var char_instance = CharacterInstance.new(char_data)
		team.append(char_instance)

		# Add income to starting gold
		starting_gold += char_instance.income

	# Initialize run state
	current_round = 0
	reputation = GameConstants.STARTING_REPUTATION
	wins = 0
	losses = 0
	current_gold = starting_gold
	encounter_history.clear()
	is_run_active = true

	print("RunManager: Run started with %d characters, starting gold: %d" % [team.size(), starting_gold])

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
		"reputation": reputation,
		"wins": wins,
		"losses": losses,
		"starting_gold": starting_gold,
		"current_gold": current_gold,
		"team": [],
		"encounter_history": encounter_history
	}

	# Serialize team
	for char_instance in team:
		save_data["team"].append(char_instance.to_dict())

	if JsonPersistence.save_json(SAVE_PATH, save_data):
		print("RunManager: Run state saved (Round %d, Reputation %d)" % [current_round, reputation])


func load_run_state() -> bool:
	"""Load run state from file, returns true if successful."""
	var save_data = JsonPersistence.load_json(SAVE_PATH)
	if save_data == null:
		return false

	# Restore run state
	run_id = save_data.get("run_id", "")
	current_round = save_data.get("round", 0)
	reputation = save_data.get("reputation", GameConstants.STARTING_REPUTATION)
	wins = save_data.get("wins", 0)
	losses = save_data.get("losses", 0)
	starting_gold = save_data.get("starting_gold", 0)
	current_gold = save_data.get("current_gold", 0)
	encounter_history = save_data.get("encounter_history", [])

	# Restore team
	team.clear()
	for char_data in save_data.get("team", []):
		var char_instance = CharacterInstance.from_dict(char_data)
		team.append(char_instance)

	is_run_active = true

	print("RunManager: Run state loaded (Round %d, %d characters)" % [current_round, team.size()])
	return true


func end_run(victory: bool) -> void:
	"""
	End the current run and award rewards.

	Args:
		victory: True if player won, false if defeated
	"""
	print("RunManager: Ending run - %s" % ("VICTORY" if victory else "DEFEAT"))

	# Award character rank XP
	for char_instance in team:
		PlayerAccount.add_character_experience(
			char_instance.base_character_id,
			GameConstants.RUN_CHARACTER_XP_REWARD
		)

	# Award gems based on outcome
	if victory:
		PlayerAccount.add_gems(GameConstants.VICTORY_GEM_REWARD)
	else:
		PlayerAccount.add_gems(GameConstants.DEFEAT_GEM_REWARD)

	# Clear run state
	_clear_run_state()

	print("RunManager: Run ended, rewards distributed")


func _clear_run_state() -> void:
	"""Clear all run state and delete save file."""
	is_run_active = false
	run_id = ""
	team.clear()
	current_round = 0
	reputation = GameConstants.STARTING_REPUTATION
	wins = 0
	losses = 0
	starting_gold = 0
	current_gold = 0
	encounter_history.clear()

	# Delete save file
	JsonPersistence.delete_file(SAVE_PATH)
	print("RunManager: Run save file deleted")


# =============================================================================
# GETTERS
# =============================================================================

func get_team() -> Array[CharacterInstance]:
	return team


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


# =============================================================================
# RUN PROGRESSION
# =============================================================================

func advance_round() -> void:
	"""Move to next round (after encounter + combat)."""
	current_round += 1
	round_changed.emit(current_round)
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
	"""Record a combat victory."""
	wins += 1
	# Award gold and XP
	add_gold(GameConstants.COMBAT_WIN_GOLD)
	for char_instance in team:
		char_instance.add_experience(GameConstants.COMBAT_WIN_XP)
	save_run_state()


func add_loss() -> void:
	"""Record a combat loss."""
	losses += 1
	save_run_state()


func lose_reputation(amount: int) -> void:
	"""Lose reputation (from combat loss)."""
	reputation = max(0, reputation - amount)
	reputation_changed.emit(reputation)
	print("RunManager: Lost %d reputation (now %d)" % [amount, reputation])
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
# UTILITY METHODS
# =============================================================================

func get_phase_name() -> String:
	"""Get current phase name for display."""
	# Even rounds = encounter, odd rounds = combat
	# Round 0 starts with encounter
	var phase_index = current_round % 2
	if phase_index == 0:
		return "encounter"
	else:
		return "combat"


func get_team_summary() -> Dictionary:
	"""Get summary stats for the team."""
	var summary = {
		"total_health": 0,
		"max_health": 0,
		"average_level": 0.0,
		"total_attack": 0
	}

	if team.is_empty():
		return summary

	for char_instance in team:
		summary["total_health"] += char_instance.current_health
		summary["max_health"] += char_instance.max_health
		summary["average_level"] += char_instance.level
		summary["total_attack"] += char_instance.basic_attack_damage

	summary["average_level"] /= team.size()

	return summary


func get_character_by_index(index: int) -> CharacterInstance:
	"""Get a team member by index (0-2)."""
	if index >= 0 and index < team.size():
		return team[index]
	return null
