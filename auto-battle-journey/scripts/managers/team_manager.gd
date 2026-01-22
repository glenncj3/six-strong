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
		total += char_instance.income
	return total


func distribute_experience(xp: int) -> void:
	"""Distribute XP to all team members."""
	for char_instance in team:
		char_instance.add_experience(xp)


func get_summary() -> Dictionary:
	"""Get summary stats for the team."""
	var summary = {
		"total_health": 0,
		"max_health": 0,
		"average_level": 0.0,
		"total_mana": 0
	}

	if team.is_empty():
		return summary

	for char_instance in team:
		summary["total_health"] += char_instance.current_health
		summary["max_health"] += char_instance.max_health
		summary["average_level"] += char_instance.level
		summary["total_mana"] += char_instance.mana

	summary["average_level"] /= team.size()

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
