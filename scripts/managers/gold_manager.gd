class_name GoldManager
extends RefCounted
## Manages gold state for a run. Extracted from RunState for SRP.

const ResultScript = preload("res://scripts/core/result.gd")
const ErrorCodesScript = preload("res://scripts/core/error_codes.gd")

signal gold_changed(new_gold: int)

var current_gold: int = 0
var starting_gold: int = 0


func reset() -> void:
	current_gold = 0
	starting_gold = 0


func set_starting_gold(amount: int) -> void:
	starting_gold = amount
	current_gold = amount


func add_gold(amount: int):
	if amount < 0:
		return ResultScript.err(ErrorCodesScript.INVALID_GOLD_AMOUNT, "Cannot add negative gold")
	current_gold += amount
	gold_changed.emit(current_gold)
	return ResultScript.ok(current_gold)


func spend_gold(amount: int):
	if amount < 0:
		return ResultScript.err(ErrorCodesScript.INVALID_GOLD_AMOUNT, "Cannot spend negative gold")
	if current_gold < amount:
		return ResultScript.err(ErrorCodesScript.INSUFFICIENT_GOLD, "Need %d gold, have %d" % [amount, current_gold])
	current_gold -= amount
	gold_changed.emit(current_gold)
	return ResultScript.ok(current_gold)


func can_afford(amount: int) -> bool:
	return current_gold >= amount


func to_dict() -> Dictionary:
	return {
		"current_gold": current_gold,
		"starting_gold": starting_gold
	}


func load_from_dict(data: Dictionary) -> void:
	current_gold = data.get("current_gold", 0)
	starting_gold = data.get("starting_gold", 0)
