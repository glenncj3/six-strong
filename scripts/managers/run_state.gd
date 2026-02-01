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
const CharacterManagerScript = preload("res://scripts/managers/character_manager.gd")
const PlayerInventoryScript = preload("res://scripts/managers/player_inventory.gd")
const InventoryManagerScript = preload("res://scripts/managers/inventory_manager.gd")
const LingeringEffectsScript = preload("res://scripts/managers/lingering_effects.gd")
const SkillManagerScript = preload("res://scripts/managers/skill_manager.gd")
const RunPoolScript = preload("res://scripts/managers/run_pool.gd")
const GoldManagerScript = preload("res://scripts/managers/gold_manager.gd")
const ReputationManagerScript = preload("res://scripts/managers/reputation_manager.gd")
const ProgressionManagerScript = preload("res://scripts/managers/progression_manager.gd")

# =============================================================================
# CORE RUN DATA
# =============================================================================

var run_id: String = ""

# Extracted managers
var progression_manager = null  # ProgressionManager instance
var gold_manager = null  # GoldManager instance
var reputation_manager = null  # ReputationManager instance

# Backward-compatible accessors for progression fields
var current_round: int:
	get: return progression_manager.current_round if progression_manager else 1
	set(value):
		if progression_manager: progression_manager.current_round = value
var current_phase: String:
	get: return progression_manager.current_phase if progression_manager else "encounter"
	set(value):
		if progression_manager: progression_manager.current_phase = value
var wins: int:
	get: return progression_manager.wins if progression_manager else 0
	set(value):
		if progression_manager: progression_manager.wins = value
var losses: int:
	get: return progression_manager.losses if progression_manager else 0
	set(value):
		if progression_manager: progression_manager.losses = value
var encounters_this_round: int:
	get: return progression_manager.encounters_this_round if progression_manager else 0
	set(value):
		if progression_manager: progression_manager.encounters_this_round = value
var player_level: int:
	get: return progression_manager.player_level if progression_manager else 1
	set(value):
		if progression_manager: progression_manager.player_level = value
var player_xp: int:
	get: return progression_manager.player_xp if progression_manager else 0
	set(value):
		if progression_manager: progression_manager.player_xp = value

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

# =============================================================================
# SUBSYSTEMS (Composition)
# =============================================================================

# Phase 4 refactor: CharacterManager owns the grid
var character_manager = null  # CharacterManager instance

# Backward-compatible grid accessor
var grid:
	get: return character_manager.get_grid() if character_manager else null

# Backwards compatibility: team property maps to grid.get_all_characters()
var team: Array:
	get: return character_manager.get_all_characters() if character_manager else []
	set(value):
		if character_manager:
			character_manager.clear()
			for character in value:
				character_manager.add_character(character)

var inventory_manager = null  # InventoryManager instance
var inventory:  # Backward-compatible accessor to underlying PlayerInventory
	get: return inventory_manager.get_inventory() if inventory_manager else null
var skill_manager = null  # SkillManager instance
var lingering_effects:  # Backward-compatible accessor
	get: return skill_manager.get_lingering_effects() if skill_manager else null
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
	progression_manager = ProgressionManagerScript.new()
	gold_manager = GoldManagerScript.new()
	reputation_manager = ReputationManagerScript.new()
	character_manager = CharacterManagerScript.new()
	inventory_manager = InventoryManagerScript.new()
	skill_manager = SkillManagerScript.new()


func reset() -> void:
	"""Reset all state for a new run."""
	run_id = ""
	progression_manager.reset()
	gold_manager.reset()
	reputation_manager.reset()
	character_manager.clear()
	inventory_manager.clear()
	skill_manager.clear()
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
# PROGRESSION (delegated to ProgressionManager)
# =============================================================================

func add_player_xp(amount: int) -> bool:
	return progression_manager.add_player_xp(amount)

func get_player_level() -> int:
	return progression_manager.get_player_level()

func get_player_xp() -> int:
	return progression_manager.get_player_xp()

func get_xp_progress() -> float:
	return progression_manager.get_xp_progress()

func is_max_level() -> bool:
	return progression_manager.is_max_level()

func add_win() -> void:
	progression_manager.add_win()

func add_loss() -> void:
	progression_manager.add_loss()

func is_victory() -> bool:
	return progression_manager.is_victory()

func is_run_over() -> bool:
	return is_victory() or is_defeated()

func advance_round() -> void:
	progression_manager.advance_round()

func set_phase(phase: String) -> void:
	progression_manager.set_phase(phase)

func complete_encounter() -> void:
	progression_manager.complete_encounter()


# =============================================================================
# GRID MANAGEMENT (delegated to CharacterManager)
# =============================================================================

func add_character(character: CharacterInstance) -> bool:
	return character_manager.add_character(character)

func add_character_at(character: CharacterInstance, row: int, col: int) -> bool:
	return character_manager.add_character_at(character, row, col)

func remove_character(row: int, col: int) -> CharacterInstance:
	return character_manager.remove_character(row, col)

func remove_character_by_index(index: int) -> CharacterInstance:
	@warning_ignore("integer_division")
	var row = index / GameConstants.GRID_COLS
	var col = index % GameConstants.GRID_COLS
	return character_manager.remove_character(row, col)

func swap_characters(from_row: int, from_col: int, to_row: int, to_col: int) -> bool:
	return character_manager.swap_characters(from_row, from_col, to_row, to_col)

func get_character_at(row: int, col: int) -> CharacterInstance:
	return character_manager.get_character_at(row, col)

func get_team() -> Array:
	return character_manager.get_all_characters()

func get_team_size() -> int:
	return character_manager.get_character_count()

func is_team_full() -> bool:
	return character_manager.is_full()

func get_first_empty_slot() -> Vector2i:
	return character_manager.get_first_empty_slot()

func get_empty_slots() -> Array[Vector2i]:
	return character_manager.get_empty_slots()


# =============================================================================
# SERIALIZATION
# =============================================================================

func to_dict() -> Dictionary:
	"""Serialize run state for saving."""
	var prog = progression_manager.to_dict()
	prog["run_id"] = run_id
	prog["reputation"] = reputation_manager.reputation
	prog["current_gold"] = gold_manager.current_gold
	prog["starting_gold"] = gold_manager.starting_gold
	prog["grid"] = character_manager.to_dict()
	prog["inventory"] = inventory_manager.to_dict()
	prog["lingering_effects"] = skill_manager.to_dict()
	prog["pool"] = pool.to_dict() if pool else {}
	prog["drafted_legacy_ids"] = Array(drafted_legacy_ids)
	return prog


static func from_dict(data: Dictionary):
	"""Create RunState from saved data."""
	var script = load("res://scripts/managers/run_state.gd")
	var state = script.new()

	state.run_id = data.get("run_id", "")
	state.progression_manager.load_from_dict(data)
	state.gold_manager.load_from_dict(data)
	state.reputation_manager.load_from_dict(data)

	# Restore grid via CharacterManager
	var grid_data = data.get("grid", {})
	if not grid_data.is_empty():
		state.character_manager.load_from_dict(grid_data)
	else:
		# Backwards compatibility: restore from team array
		var team_data = data.get("team", [])
		for char_data in team_data:
			var character = CharacterInstance.from_dict(char_data)
			if character:
				state.character_manager.add_character(character)

	# Restore inventory
	var inventory_data = data.get("inventory", {})
	if inventory_data.has("items"):
		state.inventory_manager.load_from_dict(inventory_data)

	# Restore lingering effects via SkillManager
	var effects_data = data.get("lingering_effects", {})
	if effects_data.has("effects"):
		state.skill_manager.load_from_dict(effects_data)

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
	return character_manager.get_grid() if character_manager else null


func get_front_row() -> Array[CharacterInstance]:
	"""Get all characters in the front row."""
	return character_manager.get_front_row()


func get_back_row() -> Array[CharacterInstance]:
	"""Get all characters in the back row."""
	return character_manager.get_back_row()
