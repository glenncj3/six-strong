class_name RunState
extends RefCounted
## Composite object owning all run subsystems. RunManager orchestrates flow;
## RunState owns state. Follows Single Responsibility Principle.
##
## This class owns the core run data and all subsystems:
## - Character grid (Phase 5 - 2x3 grid managing character placement)
## - Player inventory (items)
## - Lingering effects (skill effects waiting for triggers)
## - Run pool (content available based on drafted legacies)

const CharacterGridScript = preload("res://scripts/managers/character_grid.gd")
const PlayerInventoryScript = preload("res://scripts/managers/player_inventory.gd")
const LingeringEffectsScript = preload("res://scripts/managers/lingering_effects.gd")
const RunPoolScript = preload("res://scripts/managers/run_pool.gd")
const GoldManagerScript = preload("res://scripts/managers/gold_manager.gd")
const ReputationManagerScript = preload("res://scripts/managers/reputation_manager.gd")

# =============================================================================
# CORE RUN DATA
# =============================================================================

var run_id: String = ""
var current_round: int = 1  # Runs start at round 1
var current_phase: String = "encounter"
var wins: int = 0
var losses: int = 0
var encounters_this_round: int = 0

# Extracted managers (Phase 2 refactor)
var gold_manager = null  # GoldManager instance
var reputation_manager = null  # ReputationManager instance

# Backward-compatible accessors
var reputation: int:
	get: return reputation_manager.reputation if reputation_manager else 20
	set(value):
		if reputation_manager:
			reputation_manager.reputation = value
var current_gold: int:
	get: return gold_manager.current_gold if gold_manager else 0
	set(value):
		if gold_manager:
			gold_manager.current_gold = value
var starting_gold: int:
	get: return gold_manager.starting_gold if gold_manager else 0
	set(value):
		if gold_manager:
			gold_manager.starting_gold = value

# Player level progression (gates what content is available from pools)
var player_level: int = 1
var player_xp: int = 0

# =============================================================================
# SUBSYSTEMS (Composition)
# =============================================================================

# Phase 5: CharacterGrid manages 2x3 character placement
var grid = null  # CharacterGridScript instance

# Backwards compatibility: team property maps to grid.get_all_characters()
var team: Array:
	get: return grid.get_all_characters() if grid else []
	set(value):
		# Migration support: if setting team directly, populate grid
		if grid:
			grid.clear()
			for character in value:
				grid.place_character_in_first_empty(character)

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
	grid = CharacterGridScript.new()
	inventory = PlayerInventoryScript.new()
	lingering_effects = LingeringEffectsScript.new()
	gold_manager = GoldManagerScript.new()
	reputation_manager = ReputationManagerScript.new()


func reset() -> void:
	"""Reset all state for a new run."""
	run_id = ""
	current_round = 1  # Runs start at round 1
	current_phase = "encounter"
	wins = 0
	losses = 0
	encounters_this_round = 0
	player_level = 1
	player_xp = 0
	gold_manager.reset()
	reputation_manager.reset()
	grid.clear()
	inventory.clear()
	lingering_effects.clear()
	pool = null
	drafted_legacy_ids.clear()


# =============================================================================
# GOLD OPERATIONS (delegated to GoldManager)
# =============================================================================

func add_gold(amount: int) -> void:
	"""Add gold to the run."""
	gold_manager.add_gold(amount)


func remove_gold(amount: int) -> bool:
	"""Remove gold from the run. Returns false if insufficient gold."""
	return gold_manager.spend_gold(amount).is_ok()


func spend_gold(amount: int) -> bool:
	"""Alias for remove_gold for backwards compatibility."""
	return remove_gold(amount)


# =============================================================================
# REPUTATION OPERATIONS (delegated to ReputationManager)
# =============================================================================

func lose_reputation(amount: int) -> void:
	"""Lose reputation, clamped to 0."""
	reputation_manager.lose_reputation(amount)


func is_defeated() -> bool:
	"""Check if reputation has reached 0."""
	return reputation_manager.is_defeated()


# =============================================================================
# PLAYER LEVEL PROGRESSION
# =============================================================================

func add_player_xp(amount: int) -> bool:
	"""
	Add XP to the player. Player level gates what content is available from pools.

	Args:
		amount: XP to add

	Returns:
		True if player leveled up, false otherwise
	"""
	if amount <= 0:
		return false

	# Already at max level
	if player_level >= GameConstants.MAX_PLAYER_LEVEL:
		return false

	player_xp += amount
	var leveled_up = false

	# Process level ups (can gain multiple levels from large XP gains)
	while player_xp >= GameConstants.XP_PER_LEVEL and player_level < GameConstants.MAX_PLAYER_LEVEL:
		player_xp -= GameConstants.XP_PER_LEVEL
		player_level += 1
		leveled_up = true

	# Cap XP at max level
	if player_level >= GameConstants.MAX_PLAYER_LEVEL:
		player_xp = 0

	return leveled_up


func get_player_level() -> int:
	"""Get current player level (1-5)."""
	return player_level


func get_player_xp() -> int:
	"""Get current XP progress toward next level."""
	return player_xp


func get_xp_progress() -> float:
	"""Get XP progress as percentage (0.0 to 1.0)."""
	if player_level >= GameConstants.MAX_PLAYER_LEVEL:
		return 1.0
	return float(player_xp) / float(GameConstants.XP_PER_LEVEL)


func is_max_level() -> bool:
	"""Check if player has reached maximum level."""
	return player_level >= GameConstants.MAX_PLAYER_LEVEL


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
# GRID MANAGEMENT (Phase 5)
# =============================================================================

func add_character(character: CharacterInstance) -> bool:
	"""
	Add a character to the grid in the first available slot.

	Returns:
		True if character was added, false if grid is full
	"""
	return grid.place_character_in_first_empty(character)


func add_character_at(character: CharacterInstance, row: int, col: int) -> bool:
	"""
	Add a character to a specific grid position.

	Returns:
		True if character was placed, false if slot is occupied or invalid
	"""
	return grid.place_character(character, row, col)


func remove_character(row: int, col: int) -> CharacterInstance:
	"""Remove a character from a specific grid position."""
	return grid.remove_character(row, col)


func remove_character_by_index(index: int) -> CharacterInstance:
	"""
	Remove a character by linear index (backwards compatibility).
	Index maps row-major: 0-2 = front row, 3-5 = back row
	"""
	@warning_ignore("integer_division")
	var row = index / GameConstants.GRID_COLS
	var col = index % GameConstants.GRID_COLS
	return grid.remove_character(row, col)


func swap_characters(from_row: int, from_col: int, to_row: int, to_col: int) -> bool:
	"""Swap characters between two grid positions."""
	return grid.swap_positions(from_row, from_col, to_row, to_col)


func get_character_at(row: int, col: int) -> CharacterInstance:
	"""Get character at a specific grid position."""
	return grid.get_character_at(row, col)


func get_team() -> Array:
	"""Get all characters in the grid (backwards compatible)."""
	return grid.get_all_characters()


func get_team_size() -> int:
	"""Get current number of characters in grid."""
	return grid.get_character_count()


func is_team_full() -> bool:
	"""Check if grid is at maximum capacity (6 characters)."""
	return grid.is_full()


func get_first_empty_slot() -> Vector2i:
	"""Get the first empty grid slot, or Vector2i(-1, -1) if full."""
	return grid.get_first_empty_slot()


func get_empty_slots() -> Array[Vector2i]:
	"""Get all empty grid slot positions."""
	return grid.get_empty_slots()


# =============================================================================
# SERIALIZATION
# =============================================================================

func to_dict() -> Dictionary:
	"""Serialize run state for saving."""
	return {
		"run_id": run_id,
		"current_round": current_round,
		"current_phase": current_phase,
		"reputation": reputation_manager.reputation,
		"wins": wins,
		"losses": losses,
		"current_gold": gold_manager.current_gold,
		"starting_gold": gold_manager.starting_gold,
		"encounters_this_round": encounters_this_round,
		"player_level": player_level,
		"player_xp": player_xp,
		"grid": grid.to_dict(),
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
	state.current_round = data.get("current_round", 1)  # Default to round 1
	state.current_phase = data.get("current_phase", "encounter")
	state.gold_manager.load_from_dict(data)
	state.reputation_manager.load_from_dict(data)
	state.wins = data.get("wins", 0)
	state.losses = data.get("losses", 0)
	state.encounters_this_round = data.get("encounters_this_round", 0)
	state.player_level = data.get("player_level", 1)
	state.player_xp = data.get("player_xp", 0)

	# Restore grid (Phase 5)
	var grid_data = data.get("grid", {})
	if not grid_data.is_empty():
		state.grid = CharacterGridScript.from_dict(grid_data)
	else:
		# Backwards compatibility: restore from team array
		var team_data = data.get("team", [])
		for char_data in team_data:
			var character = CharacterInstance.from_dict(char_data)
			if character:
				state.grid.place_character_in_first_empty(character)

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


# =============================================================================
# GRID ACCESS (Phase 5 additions)
# =============================================================================

func get_grid():
	"""Get the character grid directly. Returns CharacterGrid instance."""
	return grid


func get_front_row() -> Array[CharacterInstance]:
	"""Get all characters in the front row."""
	return grid.get_front_row()


func get_back_row() -> Array[CharacterInstance]:
	"""Get all characters in the back row."""
	return grid.get_back_row()
