class_name RunState
extends RefCounted
## Composite object owning all run subsystems. RunManager orchestrates flow;
## RunState owns state. Follows Single Responsibility Principle.
##
## This class owns the core run data and all subsystems:
## - Character grid (Phase 5 - stubbed as simple array for now)
## - Player inventory (items)
## - Lingering effects (skill effects waiting for triggers)
## - Run pool (content available based on drafted legacies)

const PlayerInventoryScript = preload("res://scripts/managers/player_inventory.gd")
const LingeringEffectsScript = preload("res://scripts/managers/lingering_effects.gd")
const RunPoolScript = preload("res://scripts/managers/run_pool.gd")

# =============================================================================
# CORE RUN DATA
# =============================================================================

var run_id: String = ""
var current_round: int = 0
var current_phase: String = "encounter"
var reputation: int = 20
var wins: int = 0
var losses: int = 0
var current_gold: int = 0
var starting_gold: int = 0
var encounters_this_round: int = 0

# =============================================================================
# SUBSYSTEMS (Composition)
# =============================================================================

# CharacterGrid will be created in Phase 5 - for now use simple array via TeamManager
# var grid: CharacterGrid
var team: Array = []  # Array of CharacterInstance (stub for Phase 5 grid)

var inventory  # PlayerInventoryScript instance
var lingering_effects  # LingeringEffectsScript instance
var pool = null  # RunPoolScript instance - Set after draft completes

# =============================================================================
# LEGACY TRACKING
# =============================================================================

# IDs of the 3 drafted legacies (for fame distribution at run end)
var drafted_legacy_ids: Array[String] = []


# =============================================================================
# INITIALIZATION
# =============================================================================

func _init() -> void:
	inventory = PlayerInventoryScript.new()
	lingering_effects = LingeringEffectsScript.new()
	reputation = GameConstants.STARTING_REPUTATION


func reset() -> void:
	"""Reset all state for a new run."""
	run_id = ""
	current_round = 0
	current_phase = "encounter"
	reputation = GameConstants.STARTING_REPUTATION
	wins = 0
	losses = 0
	current_gold = 0
	starting_gold = 0
	encounters_this_round = 0
	team.clear()
	inventory.clear()
	lingering_effects.clear()
	pool = null
	drafted_legacy_ids.clear()


# =============================================================================
# GOLD OPERATIONS
# =============================================================================

func add_gold(amount: int) -> void:
	"""Add gold to the run."""
	current_gold += amount


func remove_gold(amount: int) -> bool:
	"""
	Remove gold from the run.

	Returns:
		True if gold was removed, false if insufficient gold
	"""
	if current_gold >= amount:
		current_gold -= amount
		return true
	return false


func spend_gold(amount: int) -> bool:
	"""Alias for remove_gold for backwards compatibility."""
	return remove_gold(amount)


# =============================================================================
# REPUTATION OPERATIONS
# =============================================================================

func lose_reputation(amount: int) -> void:
	"""Lose reputation, clamped to 0."""
	reputation = max(0, reputation - amount)


func is_defeated() -> bool:
	"""Check if reputation has reached 0."""
	return reputation <= 0


# =============================================================================
# WIN/LOSS TRACKING
# =============================================================================

func add_win() -> void:
	"""Record a combat victory."""
	wins += 1


func add_loss() -> void:
	"""Record a combat loss."""
	losses += 1


func is_victory() -> bool:
	"""Check if player has won the run."""
	return wins >= GameConstants.WINS_FOR_VICTORY


func is_run_over() -> bool:
	"""Check if run is over (victory or defeat)."""
	return is_victory() or is_defeated()


# =============================================================================
# PHASE AND ROUND MANAGEMENT
# =============================================================================

func advance_round() -> void:
	"""Advance to the next round."""
	current_round += 1
	current_phase = "encounter"
	encounters_this_round = 0


func set_phase(phase: String) -> void:
	"""Set the current phase."""
	current_phase = phase


func complete_encounter() -> void:
	"""Mark an encounter as complete."""
	encounters_this_round += 1
	if encounters_this_round >= GameConstants.ENCOUNTERS_PER_ROUND:
		current_phase = "combat"


# =============================================================================
# TEAM MANAGEMENT (Stub for Phase 5 Grid)
# =============================================================================

func add_character(character: CharacterInstance) -> bool:
	"""
	Add a character to the team.

	Returns:
		True if character was added, false if team is full
	"""
	if team.size() >= GameConstants.MAX_GRID_CHARACTERS:
		return false
	team.append(character)
	return true


func remove_character(index: int) -> CharacterInstance:
	"""Remove a character from the team by index."""
	if index < 0 or index >= team.size():
		return null
	var character = team[index]
	team.remove_at(index)
	return character


func get_team() -> Array:
	"""Get all characters in the team."""
	return team


func get_team_size() -> int:
	"""Get current team size."""
	return team.size()


func is_team_full() -> bool:
	"""Check if team is at maximum capacity."""
	return team.size() >= GameConstants.MAX_GRID_CHARACTERS


# =============================================================================
# SERIALIZATION
# =============================================================================

func to_dict() -> Dictionary:
	"""Serialize run state for saving."""
	var team_data: Array = []
	for character in team:
		team_data.append(character.to_dict())

	return {
		"run_id": run_id,
		"current_round": current_round,
		"current_phase": current_phase,
		"reputation": reputation,
		"wins": wins,
		"losses": losses,
		"current_gold": current_gold,
		"starting_gold": starting_gold,
		"encounters_this_round": encounters_this_round,
		"team": team_data,
		"inventory": inventory.to_dict(),
		"lingering_effects": lingering_effects.to_dict(),
		"pool": pool.to_dict() if pool else {},
		"drafted_legacy_ids": Array(drafted_legacy_ids)
	}


static func from_dict(data: Dictionary):
	"""Create RunState from saved data."""
	var script = load("res://scripts/managers/run_state.gd")
	var state = script.new()

	state.run_id = data.get("run_id", "")
	state.current_round = data.get("current_round", 0)
	state.current_phase = data.get("current_phase", "encounter")
	state.reputation = data.get("reputation", GameConstants.STARTING_REPUTATION)
	state.wins = data.get("wins", 0)
	state.losses = data.get("losses", 0)
	state.current_gold = data.get("current_gold", 0)
	state.starting_gold = data.get("starting_gold", 0)
	state.encounters_this_round = data.get("encounters_this_round", 0)

	# Restore team
	var team_data = data.get("team", [])
	for char_data in team_data:
		var character = CharacterInstance.from_dict(char_data)
		if character:
			state.team.append(character)

	# Restore inventory
	var inventory_data = data.get("inventory", {})
	if inventory_data.has("items"):
		state.inventory = PlayerInventoryScript.from_dict(inventory_data)

	# Restore lingering effects
	var effects_data = data.get("lingering_effects", {})
	if effects_data.has("effects"):
		state.lingering_effects = LingeringEffectsScript.from_dict(effects_data)

	# Restore pool
	var pool_data = data.get("pool", {})
	if not pool_data.is_empty():
		state.pool = RunPoolScript.from_dict(pool_data)

	# Restore drafted legacy IDs
	var legacy_ids = data.get("drafted_legacy_ids", [])
	for id in legacy_ids:
		state.drafted_legacy_ids.append(id)

	return state


# =============================================================================
# UTILITY
# =============================================================================

func calculate_total_income() -> int:
	"""Calculate total income from all team members (legacy system uses legacy income instead)."""
	# Note: In the legacy system, starting gold comes from legacy incomes, not character incomes
	# This method is kept for backwards compatibility
	var total = 0
	for character in team:
		total += character.stats.get(GameConstants.STAT_INCOME, 0)
	return total
