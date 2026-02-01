class_name ReputationManager
extends RefCounted
## Manages reputation state for a run. Extracted from RunState for SRP.

const ResultScript = preload("res://scripts/core/result.gd")
const ErrorCodesScript = preload("res://scripts/core/error_codes.gd")

signal reputation_changed(new_reputation: int)

var reputation: int = 20


func reset() -> void:
	reputation = GameConstants.STARTING_REPUTATION


func lose_reputation(amount: int):
	if amount < 0:
		return ResultScript.err(ErrorCodesScript.INVALID_REPUTATION_AMOUNT, "Cannot lose negative reputation")
	if reputation <= 0:
		return ResultScript.err(ErrorCodesScript.ALREADY_DEFEATED, "Already defeated")
	reputation = max(0, reputation - amount)
	reputation_changed.emit(reputation)
	return ResultScript.ok(reputation)


func is_defeated() -> bool:
	return reputation <= 0


func to_dict() -> Dictionary:
	return {"reputation": reputation}


func load_from_dict(data: Dictionary) -> void:
	reputation = data.get("reputation", GameConstants.STARTING_REPUTATION)
