class_name ProgressionManager
extends RefCounted
## Owns round, phase, wins, losses, player XP/level progression.
## Extracted from RunState for SRP.

signal round_changed(new_round: int)
signal phase_changed(new_phase: String)
signal player_level_changed(new_level: int)

const PHASE_ENCOUNTER = "encounter"
const PHASE_COMBAT = "combat"

var current_round: int = 1
var current_phase: String = PHASE_ENCOUNTER
var encounters_this_round: int = 0
var wins: int = 0
var losses: int = 0
var player_level: int = 1
var player_xp: int = 0


func reset() -> void:
	current_round = 1
	current_phase = PHASE_ENCOUNTER
	encounters_this_round = 0
	wins = 0
	losses = 0
	player_level = 1
	player_xp = 0


# =============================================================================
# ROUND AND PHASE
# =============================================================================

func advance_round() -> void:
	current_round += 1
	current_phase = PHASE_ENCOUNTER
	encounters_this_round = 0
	round_changed.emit(current_round)
	phase_changed.emit(current_phase)


func set_phase(phase: String) -> void:
	current_phase = phase
	phase_changed.emit(current_phase)


func complete_encounter() -> void:
	encounters_this_round += 1
	if encounters_this_round >= GameConstants.ENCOUNTERS_PER_ROUND:
		current_phase = PHASE_COMBAT
	phase_changed.emit(current_phase)


# =============================================================================
# WIN/LOSS TRACKING
# =============================================================================

func add_win() -> void:
	wins += 1


func add_loss() -> void:
	losses += 1


func is_victory() -> bool:
	return wins >= GameConstants.WINS_FOR_VICTORY


# =============================================================================
# PLAYER LEVEL PROGRESSION
# =============================================================================

func add_player_xp(amount: int):  # -> Result
	if amount <= 0:
		return Result.err(ErrorCodes.INVALID_XP_AMOUNT, "XP amount must be positive")
	if player_level >= GameConstants.MAX_PLAYER_LEVEL:
		return Result.err(ErrorCodes.MAX_LEVEL_REACHED, "Already at max level")

	player_xp += amount
	var leveled_up = false

	while player_xp >= GameConstants.XP_PER_LEVEL and player_level < GameConstants.MAX_PLAYER_LEVEL:
		player_xp -= GameConstants.XP_PER_LEVEL
		player_level += 1
		leveled_up = true

	if player_level >= GameConstants.MAX_PLAYER_LEVEL:
		player_xp = 0

	if leveled_up:
		player_level_changed.emit(player_level)

	return Result.ok(leveled_up)


func get_player_level() -> int:
	return player_level


func get_player_xp() -> int:
	return player_xp


func get_xp_progress() -> float:
	if player_level >= GameConstants.MAX_PLAYER_LEVEL:
		return 1.0
	return float(player_xp) / float(GameConstants.XP_PER_LEVEL)


func is_max_level() -> bool:
	return player_level >= GameConstants.MAX_PLAYER_LEVEL


# =============================================================================
# SERIALIZATION
# =============================================================================

func to_dict() -> Dictionary:
	return {
		"current_round": current_round,
		"current_phase": current_phase,
		"encounters_this_round": encounters_this_round,
		"wins": wins,
		"losses": losses,
		"player_level": player_level,
		"player_xp": player_xp
	}


func load_from_dict(data: Dictionary) -> void:
	current_round = data.get("current_round", 1)
	current_phase = data.get("current_phase", PHASE_ENCOUNTER)
	encounters_this_round = data.get("encounters_this_round", 0)
	wins = data.get("wins", 0)
	losses = data.get("losses", 0)
	player_level = data.get("player_level", 1)
	player_xp = data.get("player_xp", 0)
