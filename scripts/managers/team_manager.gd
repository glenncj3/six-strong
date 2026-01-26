class_name TeamManager
extends RefCounted
# TeamManager - Manages the team of characters during a run
# Extracted from RunManager for Single Responsibility Principle

var team: Array[CharacterInstance] = []


func clear() -> void:
	"""Clear all team members."""
	team.clear()


func add_character(char_instance: CharacterInstance) -> void:
	"""Add a character to the team."""
	team.append(char_instance)


func get_team() -> Array[CharacterInstance]:
	"""Get the current team."""
	return team


func get_size() -> int:
	"""Get team size."""
	return team.size()


func is_empty() -> bool:
	"""Check if team is empty."""
	return team.is_empty()


func get_character_by_index(index: int) -> CharacterInstance:
	"""Get a team member by index (0-2)."""
	if index >= 0 and index < team.size():
		return team[index]
	return null


func calculate_total_income() -> int:
	"""Calculate total income from all team members."""
	var total = 0
	for char_instance in team:
		total += char_instance.stats.get(GameConstants.STAT_INCOME, 0)
	return total


func get_summary() -> Dictionary:
	"""Get summary stats for the team."""
	var summary = {
		"total_health": 0,
		"max_health": 0,
		"total_mana": 0
	}

	if team.is_empty():
		return summary

	for char_instance in team:
		summary["total_health"] += char_instance.current_health
		summary["max_health"] += char_instance.max_health
		summary["total_mana"] += char_instance.mana

	return summary


# =============================================================================
# SERIALIZATION
# =============================================================================

func to_array() -> Array:
	"""Serialize team to array of dictionaries."""
	var result = []
	for char_instance in team:
		result.append(char_instance.to_dict())
	return result


func load_from_array(data: Array) -> void:
	"""Load team from array of dictionaries."""
	team.clear()
	for char_data in data:
		var char_instance = CharacterInstance.from_dict(char_data)
		team.append(char_instance)
